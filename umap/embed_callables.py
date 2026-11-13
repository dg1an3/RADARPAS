"""Embed every node in callables.json via ollama (nomic-embed-text).

Mirror of semantic_notes/src/embed_projects.py: one node = one embedding of
its `text` field (software / module / callable header, comment, body excerpt).
Results go to callables_embeddings.json (name, category, description, dim,
embedding, plus the node metadata) and a flat callables_embeddings.npy matrix
in the same order, which umap_layout.py consumes.

Embeddings are cached in embed_cache.json keyed by node id + text hash, so
re-running after extract_callables.py picks up new/changed nodes only.
"""
import argparse
import hashlib
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np

OLLAMA_URL = "http://localhost:11434/api/embed"   # batched endpoint; truncates to the model context
MODEL = "nomic-embed-text"
BATCH = 64

HERE = Path(__file__).resolve().parent
# --variant nobody reads callables_nobody.json (see strip_bodies.py) and writes
# callables_embeddings_nobody.*; the cache is shared since it keys on id + text hash.
_ap = argparse.ArgumentParser()
_ap.add_argument("--variant", default="", help="suffix of callables_<variant>.json to embed")
_args = _ap.parse_args()
SFX = f"_{_args.variant}" if _args.variant else ""
IN_JSON = HERE / f"callables{SFX}.json"
OUT_JSON = HERE / f"callables_embeddings{SFX}.json"
OUT_NPY = HERE / f"callables_embeddings{SFX}.npy"
CACHE = HERE / "embed_cache.json"
META_KEYS = ("id", "kind", "software", "module", "language", "signature",
             "lines", "snapshots", "first", "last", "file", "line", "salience", "variants",
             "description_source", "calls_summary", "callers_summary", "uses_modules", "used_by_modules")


def embed_batch(texts: list[str]) -> list[list[float]]:
    """Embed a batch via ollama /api/embed (truncate=true clips over-long prompts
    to the model context instead of failing). On a 500 halve the texts and retry."""
    while True:
        payload = json.dumps({"model": MODEL, "input": texts, "truncate": True}).encode()
        req = urllib.request.Request(OLLAMA_URL, data=payload,
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=600) as resp:
                return json.load(resp)["embeddings"]
        except urllib.error.HTTPError as e:
            if e.code == 500 and max(map(len, texts)) > 400:
                texts = [t[: len(t) // 2] for t in texts]
                print(f"    ollama 500; retrying batch with halved texts")
                time.sleep(0.3)
            else:
                raise


def text_hash(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:16]


def main() -> None:
    nodes = json.loads(IN_JSON.read_text(encoding="utf-8"))
    cache = json.loads(CACHE.read_text(encoding="utf-8")) if CACHE.exists() else {}
    todo = [nd for nd in nodes
            if not (cache.get(nd["id"]) and cache[nd["id"]]["hash"] == text_hash(nd["text"]))]
    print(f"{len(nodes)} nodes; {len(nodes) - len(todo)} cached; embedding {len(todo)} with {MODEL} "
          f"in batches of {BATCH}", flush=True)

    t0 = time.time()
    for b in range(0, len(todo), BATCH):
        chunk = todo[b:b + BATCH]
        vecs = embed_batch([nd["text"] for nd in chunk])
        for nd, vec in zip(chunk, vecs):
            cache[nd["id"]] = {"hash": text_hash(nd["text"]), "embedding": vec}
        done = b + len(chunk)
        if (b // BATCH) % 10 == 0 or done == len(todo):
            CACHE.write_text(json.dumps(cache), encoding="utf-8")
            rate = done / max(time.time() - t0, 1e-6)
            print(f"  [{done:4d}/{len(todo)}] {chunk[-1]['name'][:48]:48} [{chunk[-1]['category']}]  "
                  f"{rate:.1f}/s", flush=True)

    records, vectors = [], []
    for nd in nodes:
        vec = cache[nd["id"]]["embedding"]
        rec = {"name": nd["name"], "category": nd["category"],
               "description": nd["description"] or nd["signature"], "dim": len(vec)}
        rec.update({k: nd.get(k) for k in META_KEYS})
        rec["embedding"] = vec
        records.append(rec)
        vectors.append(vec)
    hits = len(nodes) - len(todo)

    CACHE.write_text(json.dumps(cache), encoding="utf-8")
    OUT_JSON.write_text(json.dumps(records), encoding="utf-8")
    np.save(OUT_NPY, np.array(vectors, dtype=np.float32))
    print(f"\nWrote {OUT_JSON.name} and {OUT_NPY.name}  shape={np.array(vectors).shape}  "
          f"(cache hits {hits}, embedded {len(nodes) - hits}, {time.time() - t0:.0f}s)")
    cats = {}
    for r in records:
        cats[r["category"]] = cats.get(r["category"], 0) + 1
    for c, n in sorted(cats.items(), key=lambda kv: -kv[1]):
        print(f"  {n:4d}  {c}")


if __name__ == "__main__":
    main()
