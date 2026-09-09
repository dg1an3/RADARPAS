"""Synthesize a header comment for every node in callables.json that has none.

About a fifth of the archive's callables (and some modules) carry no comment,
so their embedding is built from signature and raw code alone. This pass asks
a local ollama code model for the one- or two-sentence header comment the
routine is missing, given its software blurb, module, signature, body and the
static call-graph summaries (what it calls / what calls it), and writes it back
as the node's `description` with `description_source = "synthesized"`. The
description line of the embedded `text` is filled in too, so embed_callables.py
re-embeds exactly the nodes that gained a comment.

Results are cached in synth_cache.json keyed by node id + hash of the text as
extract_callables.py produced it (i.e. with the description still empty), so
re-running the pipeline keeps existing syntheses and only asks about new or
changed nodes.

Usage:
  python synthesize_comments.py                 # fill every missing description
  python synthesize_comments.py --limit 20      # first 20 only (try a model)
  python synthesize_comments.py --model qwen2.5-coder:7b
  python synthesize_comments.py --dry-run       # print prompts / answers, write nothing
"""
import argparse
import hashlib
import json
import re
import time
import urllib.request
from pathlib import Path
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")   # cp437 box characters in old headers

OLLAMA_URL = "http://localhost:11434/api/generate"
DEFAULT_MODEL = "qwen3-coder:30b"
HERE = Path(__file__).resolve().parent
NODES = HERE / "callables.json"
CACHE = HERE / "synth_cache.json"
BODY_CHARS = 2500       # of the body shown to the model
MAX_DESC = 300          # same cap extract_callables.py applies to source comments

ap = argparse.ArgumentParser()
ap.add_argument("--model", default=DEFAULT_MODEL)
ap.add_argument("--limit", type=int, default=0, help="stop after this many syntheses (0 = all)")
ap.add_argument("--dry-run", action="store_true")
ap.add_argument("--redo", action="store_true", help="ignore the cache and synthesize again")
args = ap.parse_args()


def text_hash(s: str) -> str:
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:16]


def generate(prompt: str) -> str:
    payload = json.dumps({"model": args.model, "prompt": prompt, "stream": False, "keep_alive": "30m",
                          "options": {"temperature": 0.2, "num_predict": 160}}).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=600) as r:
        return json.load(r)["response"]


def clean(answer: str) -> str:
    """Strip comment delimiters, quotes and chatter the model may wrap the comment in."""
    a = answer.strip()
    a = re.sub(r"<think>.*?</think>", "", a, flags=re.S).strip()
    a = re.sub(r"^```\w*\s*|\s*```$", "", a).strip()
    a = re.sub(r"^\(\*+\s*|\s*\*+\)$|^/\*+\s*|\s*\*+/$|^\{\s*|\s*\}$|^///?\s*|^#\s*|^\"\"\"\s*|\s*\"\"\"$", "", a).strip()
    a = re.sub(r"^(Header comment|Comment|Description)\s*:\s*", "", a, flags=re.I)
    a = a.strip("\"'` ")
    a = re.sub(r"\s+", " ", a)
    a = re.sub(r"^((This|The) )?(procedure|function|method|routine|module|code|class)\s+", "", a, flags=re.I)
    if a and a[0].islower():
        a = a[0].upper() + a[1:]
    if len(a) > MAX_DESC:        # cut at the last sentence end that fits, else the last word
        head = a[:MAX_DESC]
        cut = max(head.rfind(". "), head.rfind("; "))
        a = head[:cut + 1] if cut > 80 else head.rsplit(" ", 1)[0].rstrip(",;:") + "..."
    return a


def body_of(node: dict) -> str:
    """The code part of the embedded text (after the blank line that ends the header block)."""
    parts = node["text"].split("\n\n", 1)
    return parts[1] if len(parts) > 1 else ""


def file_head(node: dict, n_lines=60, n_chars=2000) -> str:
    """Opening lines of the module's source file: declarations and comments the
    extractor did not keep, so the model sees real evidence for a module that
    has few or no procedures."""
    path = HERE.parent / node["file"]
    if not path.is_file():
        return ""
    raw = path.read_bytes()[:8000]
    if path.suffix.lower() in (".pas", ".inc", ".mod", ".def", ".asm", ".bas"):
        text = raw.decode("cp437", errors="replace")
    else:
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            text = raw.decode("cp1252", errors="replace")
    return "\n".join(text.splitlines()[:n_lines])[:n_chars]


def prompt_for(node: dict, blurb: str) -> str:
    kind = node["kind"]
    if kind == "module":
        what = f"the {node['language']} module {node['name']} ({node['file']})"
        detail = (body_of(node)[:BODY_CHARS]     # imports, calls into / used by, procedure list
                  + "\n\nStart of the source file:\n" + file_head(node))
        ask = ("Write the header comment this module is missing: one or two sentences saying what the "
               "module provides and its role in the program, judging only from its name, imports, "
               "procedure list and the source shown.")
    else:
        what = f"the {node['language']} {kind} {node['name']} in module {node['module']}"
        detail = f"{node['signature']}\n\n{body_of(node)[:BODY_CHARS]}"
        ask = ("Write the header comment this routine is missing: one or two sentences saying what it does "
               "and its role, judging only from the code. Mention what it works with (screen, serial port, "
               "file, data structure) when that is clear.")
    links = ""
    if node.get("calls_summary"):
        links += f"It calls: {node['calls_summary']}\n"
    if node.get("callers_summary"):
        links += f"It is called by: {node['callers_summary']}\n"
    return (f"You are documenting {what}, part of {node['software']}: {blurb}\n\n"
            f"{links}\n{detail}\n\n{ask} At most 40 words, concrete and terse like a source header "
            "comment; say what it actually does, not that it is 'essential' or 'provides functionality'. "
            "If the source shown is too thin to tell, say what can be seen and nothing more. "
            "Plain prose, no code, no markdown, do not restate the name, do not say which language it "
            "is in, do not start with 'This'. Reply with the comment only.")


def main():
    nodes = json.loads(NODES.read_text(encoding="utf-8"))
    blurbs = {n["software"]: n["description"] for n in nodes if n["kind"] == "software"}
    cache = {} if args.redo or not CACHE.exists() else json.loads(CACHE.read_text(encoding="utf-8"))
    todo = [n for n in nodes if n["kind"] != "software" and not n["description"]]
    print(f"{len(nodes)} nodes; {len(todo)} without a description")

    done = hits = 0
    t0 = time.time()
    for n in todo:
        key, h = n["id"], text_hash(n["text"])
        hit = cache.get(key)
        if hit and hit["hash"] == h and not args.dry_run:
            desc = hit["description"]
            hits += 1
        else:
            if args.limit and done >= args.limit:
                continue
            prompt = prompt_for(n, blurbs.get(n["software"], ""))
            try:
                desc = clean(generate(prompt))
            except Exception as e:      # ollama down / model missing: leave the node as is
                print(f"  ! {n['name']}: {e}")
                break
            done += 1
            if args.dry_run:
                print(f"----- {n['id']}\n{prompt}\n>>> {desc}\n")
            else:
                cache[key] = {"hash": h, "description": desc, "model": args.model}
                if done % 10 == 0:
                    CACHE.write_text(json.dumps(cache, indent=0), encoding="utf-8")
                rate = done / max(time.time() - t0, 1e-6)
                print(f"  [{done:4d}] {n['name'][:40]:40} {desc[:70]:70} {rate:.2f}/s", flush=True)
        if not desc or args.dry_run:
            continue
        n["description"] = desc
        n["description_source"] = "synthesized"
        lines = n["text"].split("\n")
        if len(lines) > 2 and lines[2] == "":     # the empty description slot extract left
            lines[2] = desc
            n["text"] = "\n".join(lines)

    if not args.dry_run:
        CACHE.write_text(json.dumps(cache, indent=0), encoding="utf-8")
        NODES.write_text(json.dumps(nodes, indent=1, ensure_ascii=False), encoding="utf-8")
    left = sum(1 for n in nodes if n["kind"] != "software" and not n["description"])
    print(f"synthesized {done} ({hits} from cache) with {args.model} in {time.time() - t0:.0f}s; "
          f"{left} nodes still without a description")


if __name__ == "__main__":
    main()
