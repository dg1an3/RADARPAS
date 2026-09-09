"""Extract modules and callables (procedures / functions / methods) from the archive.

Walks every dated snapshot directory under each software family, parses the
source files it finds (Turbo Pascal, TopSpeed Modula-2, x86 assembly, C/C++,
Java, F#, Python) with lightweight line-based heuristics, and emits one node
per unique (software, module, callable). The same routine appears in many
snapshots (RADARPAS alone has 24); duplicates are folded into a single node
that carries the list of snapshots it was seen in and the longest body found.

Version variants are collapsed (collapse_variants): callables with the same
(class-qualified) name in the same software whose bodies share >= 50% of their
identifier tokens are one node (the longest body represents it; the others are
listed under `variants`), and a module whose callables were nearly all absorbed
by another module is folded into it when it is a versioned name of the target
(rs2 -> rs, SWEEP3 -> SWEEP2, UTILITY2 -> UTILITY) or never coexists with it
in a snapshot (RADAR / E300_Radar_Terminal -> Radar_Terminal).

Three tiers of node are produced, so the viewer can propagate activation
software -> module -> callable:
  kind = "software"  one per software family (RADARPAS, SSM, theWheel, ...)
  kind = "module"    one per source module (Pascal unit / M2 module / C++ or Java file)
  kind = "procedure" | "function" | "method" | "asm"   one per callable

Output: umap/callables.json  [{id, name, category, kind, software, module,
        language, signature, description, text, lines, snapshots, first, last,
        file, salience}]
The `text` field is what gets embedded (see embed_callables.py).

A static call graph is derived by name: a callable's body mentioning the name
of another callable in the same software counts as a call, resolved to the same
module first, then to a module the caller imports (Modula-2), then to any
unambiguous match. Each callable node carries `calls` / `callers` (display
names) and one-line `calls_summary` / `callers_summary` sentences grouped by
module, which are embedded too; module nodes carry `uses_modules` /
`used_by_modules`. Nodes without a source comment get one synthesized later by
synthesize_comments.py.
"""
import json
import math
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent / "callables.json"

# family directory -> software label (category in the viewer)
FAMILY = {
    "radar": "RADARPAS", "ssm": "SSM", "thewheel": "theWheel",
    "eevorg": "EEVORG", "eevorg-java": "EEVORG", "cogmap": "CogMap",
    "egalib-math": "EGALib & Math", "gdem": "GDEM", "gdem-eme": "GDEM",
    "bqtourn": "BQ Tournament", "misc": None,  # misc resolved per snapshot
    # modern additions (no dated snapshot dirs; whole tree is one snapshot)
    "hackrf-noaa": "HackRF NOAA", "lsm-stormcell": "LSM StormCell",
}
UNDATED = {"hackrf-noaa": "2026xxxx", "lsm-stormcell": "20260907"}
# misc/<snapshot> -> software label
MISC = {
    "TURING": "TURING", "Pic-Analysis": "Pic-Analysis",
    "Docs w Some Source Code": "RADARPAS", "SIGNAL": "SIGNAL",
    "browsee": "Browsee", "Eevorg.NET": "EEVORG",
}
SOFTWARE_BLURB = {
    "RADARPAS": "Commercial weather radar terminal for the Ellason E300/E250 systems (1985-1992). "
                "Turbo Pascal monolith evolving into modular TopSpeed Modula-2 with x86 assembly ISRs; "
                "EGA graphics, RS-232 modem link, sweep display, auto-download, map overlays, storm cell analysis.",
    "SSM": "Spreadsheet Management System (1986-1997): custom spreadsheet engine with formula "
           "evaluation, accounts payable/receivable and inventory applications; Pascal, Modula-2, later C++/Windows.",
    "theWheel": "Knowledge visualization using spreading activation networks and visual graph browsing "
                "(1997-2000); C++/MFC, CoolDraw rendering, wlXxx and oItem object models.",
    "EEVORG": "Cellular automata / artificial life research exploring the edge of chaos (entropy 0.5) "
              "with genetic algorithms (1993-2007); C++ Windows (Winorg), Java port, later .NET.",
    "CogMap": "Cognitive Map (1996): web-based knowledge mapping experiments (REFMAP, PSIPHYS, COGMAP, Orbis); C++.",
    "EGALib & Math": "Custom EGA graphics library, Pascal/Modula-2 examples, fractal generators "
                     "(FRACGEN/FRACPLOT, JULIAB) and AUTOMATA (1987-1993).",
    "GDEM": "Graphical Data Entry Manager (1984-1985): map digitizing tools for radar overlays, "
            "bearing/range coordinate entry; BASIC and Turbo Pascal, EME variant.",
    "BQ Tournament": "Bible quiz tournament bracket and scoring software (1988), Turbo Pascal.",
    "TURING": "Turing machine simulator samples (1985), Pascal and C.",
    "Pic-Analysis": "Image analysis tools (1989), Modula-2.",
    "SIGNAL": "Signal processing / synthesis experiment with filter nodes (1996), C++.",
    "Browsee": "Web browsing experiment (2000), C++/MFC document-view.",
    "HackRF NOAA": "HackRF One software-defined-radio receiver for NOAA APT weather satellite images "
                   "(2026, F#): FM demodulation, APT sync/line decoding, satellite pass tracking, "
                   "image reconstruction and compression. A modern sibling of the RADARPAS weather receiver.",
    "LSM StormCell": "Prototype liquid state machine (reservoir of leaky integrate-and-fire spiking neurons, "
                     "after Maass/Natschlaeger/Markram and Ruggero Freddi's implementation) that reads "
                     "RADARPAS radar map frames and performs storm cell analysis: cell detection, "
                     "tracking, speed/direction estimation and short-range nowcasting (2026, Python).",
}

PAS_EXT = {".pas", ".inc"}
M2_EXT = {".mod", ".def"}
ASM_EXT = {".asm"}
C_EXT = {".cpp", ".c", ".cxx"}
JAVA_EXT = {".java"}
BAS_EXT = {".bas"}
FS_EXT = {".fs"}
PY_EXT = {".py"}
SRC_EXT = PAS_EXT | M2_EXT | ASM_EXT | C_EXT | JAVA_EXT | BAS_EXT | FS_EXT | PY_EXT

MAX_TEXT = 3500          # chars of embedded text per node (nomic ctx is 2048 tokens)

# Vendor library source that shipped inside the snapshots (TopSpeed/JPI and
# Logitech Modula-2 libraries, PMI Repertoire, Borland's LISTT) is not the
# author's work and only adds standard-library noise to the map. A file whose
# header carries one of these banners is skipped outright. The check is on the
# copyright / library banner, not the module name, so the author's own modules
# that reuse a library name (the 1988 Storage.def "For E300 Radar Terminal",
# Windows.def) survive.
VENDOR_RX = re.compile(
    r"Jensen\s*&\s*Partners"                    # TopSpeed Modula-2 (JPI)
    r"|MODULA-2(?:/86)?\s+Library"                # Logitech library banner
    r"|\(\*\s*Abbreviation:"                      # Logitech definition modules
    r"|\bREPERTOIRE\b"                           # PMI Repertoire
    r"|Copyri\w+[^\n]{0,40}\b(?:Borland|Logitech)\b", re.I)   # incl. the 'Copyrigth' misspelling
VENDOR_HEAD = 2500       # bytes of the file head the banner must appear in


def vendor_banner(text: str):
    """The vendor banner text if the file head carries one, else None."""
    m = VENDOR_RX.search(text[:VENDOR_HEAD])
    return m.group(0) if m else None
SNAP_RE = re.compile(r"^(\d{4})(\d{2}|xx)(\d{2}|xx)(?:[ -]|$)")


def read_src(path: Path) -> str:
    raw = path.read_bytes()
    if path.suffix.lower() in PAS_EXT | M2_EXT | ASM_EXT | BAS_EXT:
        return raw.decode("cp437", errors="replace")
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace")


def snapshot_of(rel: Path):
    """(snapshot dir name, yyyymmdd-ish date string) for a file path relative to a family."""
    top = rel.parts[0] if len(rel.parts) > 1 else ""
    m = SNAP_RE.match(top)
    if m:
        return top, m.group(1) + m.group(2) + m.group(3)
    if top == "1985-EME":
        return top, "1985xxxx"
    return None, None


def software_for(family: str, snap: str):
    sw = FAMILY[family]
    if sw is None:  # misc
        for key, label in MISC.items():
            if snap and key.lower() in snap.lower():
                return label
        return "Misc"
    return sw


# -- comment helpers ---------------------------------------------------------
PAS_COMMENT = re.compile(r"\(\*(.*?)\*\)|\{(.*?)\}", re.S)
C_COMMENT = re.compile(r"/\*(.*?)\*/|//([^\n]*)", re.S)
FS_COMMENT = re.compile(r"\(\*(.*?)\*\)|//([^\n]*)", re.S)
PY_COMMENT = re.compile(r'"""(.*?)"""|#([^\n]*)', re.S)


def clean_comment(s: str) -> str:
    s = re.sub(r"[\*\-=_#~/]{3,}", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _first_group(m):
    return next(g for g in m.groups() if g is not None)


def preceding_comment(lines, idx, rx, window=8) -> str:
    """Comment text in the `window` lines immediately above header line idx."""
    chunk = "\n".join(lines[max(0, idx - window):idx])
    found = [clean_comment(_first_group(m)) for m in rx.finditer(chunk)]
    found = [f for f in found if len(f) > 3]
    return found[-1] if found else ""


def inner_comment(body: str, rx) -> str:
    for m in rx.finditer(body):
        t = clean_comment(_first_group(m))
        if len(t) > 12:
            return t
    return ""


def head_comment(lines, rx, n=30) -> str:
    m = rx.search("\n".join(lines[:n]))
    return clean_comment(_first_group(m))[:300] if m else ""


# -- per-language parsers: return (module_name, module_desc, [callable dicts]) --
PAS_HDR = re.compile(r"^\s*(procedure|function)\s+([A-Za-z_][A-Za-z_0-9]*)", re.I)
PAS_MOD = re.compile(r"^\s*(program|unit)\s+([A-Za-z_][A-Za-z_0-9]*)", re.I)
M2_HDR = re.compile(r"^\s*PROCEDURE\s+([A-Za-z_][A-Za-z_0-9]*)")
M2_MOD = re.compile(r"^\s*(?:IMPLEMENTATION\s+|DEFINITION\s+)?MODULE\s+([A-Za-z_][A-Za-z_0-9]*)")
ASM_HDR = re.compile(r"^\s*([A-Za-z_@$?][A-Za-z_0-9@$?]*)\s+PROC\b", re.I)


def _make(name, kind, sig, desc, body, line, decl_only=False):
    return dict(name=name, kind=kind, signature=sig[:300], description=desc[:300],
                body=body, line=line, decl_only=decl_only)


def parse_pascal_like(text, hdr_rx, mod_rx, kind_from_hdr, stem, is_def=False):
    lines = text.splitlines()
    mod_name, mod_desc = stem, ""
    for i, ln in enumerate(lines[:60]):
        m = mod_rx.match(ln)
        if m:
            mod_name = m.group(m.lastindex)
            mod_desc = preceding_comment(lines, i, PAS_COMMENT, 12) or inner_comment(
                "\n".join(lines[i:i + 15]), PAS_COMMENT)
            break
    heads = [(i, m) for i, m in ((i, hdr_rx.match(ln)) for i, ln in enumerate(lines)) if m]
    out = []
    for n, (i, m) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        if is_def:  # definition modules: signature + nearby comment only
            end = min(end, i + 8)
        body = "\n".join(lines[i:end]).rstrip()
        sig = re.sub(r"\s+", " ", lines[i].strip())
        j = i
        while (j - i < 4 and j + 1 < len(lines)
               and not re.search(r"[;)]\s*(:\s*\w+\s*;)?\s*(\(\*.*\*\)|\{.*\})?\s*$", lines[j])):
            j += 1
            sig += " " + lines[j].strip()
        name = m.group(m.lastindex)
        desc = preceding_comment(lines, i, PAS_COMMENT) or inner_comment(body, PAS_COMMENT)
        decl_only = is_def or bool(re.search(r"\bforward\s*;", sig, re.I))
        out.append(_make(name, kind_from_hdr(m), sig, desc, body, i + 1, decl_only))
    return mod_name, mod_desc[:300], out


C_KEYWORDS = {"if", "for", "while", "switch", "return", "else", "do", "catch", "sizeof",
              "defined", "case", "new", "delete", "throw", "try"}
C_HDR = re.compile(
    r"^([A-Za-z_][\w:<>,\*&\s~]*?)\s*\b((?:[A-Za-z_]\w*::)*~?[A-Za-z_]\w*|(?:[A-Za-z_]\w*::)*operator\s*[^\s(]+)"
    r"\s*\(([^;{}]*)\)\s*(const)?\s*(?::\s*[^{]*)?\s*(\{)?\s*$")
C_CTOR = re.compile(r"^((?:[A-Za-z_]\w*::)+~?[A-Za-z_]\w*)\s*\(([^;{}]*)\)\s*(?::\s*[^{]*)?\s*(\{)?\s*$")


def parse_c(text, stem):
    lines = text.splitlines()
    heads = []
    for i, ln in enumerate(lines):
        s = ln.rstrip()
        if not s or s[0] in "#/* \t}{":
            continue
        m = C_HDR.match(s)
        name = None
        if m:
            if m.group(1).strip() in C_KEYWORDS:
                continue
            name = m.group(2)
        else:
            m = C_CTOR.match(s)
            if m:
                name = m.group(1)
        if not name:
            continue
        base = name.split("::")[-1].lstrip("~")
        if base in C_KEYWORDS or (base.isupper() and len(base) > 3):  # MFC macros
            continue
        if "{" not in "\n".join(lines[i:i + 4]):  # definition, not prototype/call
            continue
        heads.append((i, name, re.sub(r"\s+", " ", s)))
    out = []
    for n, (i, name, sig) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        body = "\n".join(lines[i:end]).rstrip()
        desc = preceding_comment(lines, i, C_COMMENT) or inner_comment(body, C_COMMENT)
        out.append(_make(name, "method" if "::" in name else "function", sig, desc, body, i + 1))
    return stem, head_comment(lines, C_COMMENT), out


JAVA_HDR = re.compile(
    r"^\s*((?:public|private|protected|static|final|synchronized|abstract|native)\s+)*"
    r"(?:[\w<>\[\], ]+\s+)?([A-Za-z_]\w*)\s*\(([^)]*)\)\s*(?:throws [\w., ]+)?\s*\{\s*$")
JAVA_CLASS = re.compile(r"^\s*(?:public\s+|abstract\s+|final\s+)*(?:class|interface)\s+([A-Za-z_]\w*)")


def parse_java(text, stem):
    lines = text.splitlines()
    cls = next((m.group(1) for m in map(JAVA_CLASS.match, lines) if m), stem)
    heads = []
    for i, ln in enumerate(lines):
        m = JAVA_HDR.match(ln)
        if m and m.group(2) not in C_KEYWORDS | {"class", "interface"}:
            heads.append((i, f"{cls}.{m.group(2)}", re.sub(r"\s+", " ", ln.strip())))
    out = []
    for n, (i, name, sig) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        body = "\n".join(lines[i:end]).rstrip()
        desc = preceding_comment(lines, i, C_COMMENT) or inner_comment(body, C_COMMENT)
        out.append(_make(name, "method", sig, desc, body, i + 1))
    return cls, head_comment(lines, C_COMMENT), out


FS_MOD = re.compile(r"^\s*module\s+([\w.]+)")
FS_HDR = re.compile(r"^(\s*)(?:let|and)\s+(?:rec\s+|inline\s+|private\s+)*([A-Za-z_]\w*)\s*(?:\(|[A-Za-z_(]|:)")
FS_MEMBER = re.compile(r"^(\s*)(?:static\s+)?member\s+(?:this\.|_\.)?([A-Za-z_]\w*)")
FS_TYPE = re.compile(r"^\s*(?:and|type)\s+([A-Za-z_]\w*)")


def parse_fsharp(text, stem):
    lines = text.splitlines()
    mod = next((m.group(1).split(".")[-1] for m in map(FS_MOD.match, lines[:20]) if m), stem)
    heads = []
    cur_type = None
    for i, ln in enumerate(lines):
        t = FS_TYPE.match(ln)
        if t:
            cur_type = t.group(1)
        m = FS_HDR.match(ln)
        if m and len(m.group(1)) <= 4 and "=" in ln and not ln.strip().startswith("let mutable"):
            heads.append((i, m.group(2), re.sub(r"\s+", " ", ln.strip())))
            continue
        m = FS_MEMBER.match(ln)
        if m and cur_type:
            heads.append((i, f"{cur_type}.{m.group(2)}", re.sub(r"\s+", " ", ln.strip())))
    out = []
    for n, (i, name, sig) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        body = "\n".join(lines[i:end]).rstrip()
        desc = preceding_comment(lines, i, FS_COMMENT) or inner_comment(body, FS_COMMENT)
        out.append(_make(name, "function", sig, desc, body, i + 1))
    return mod, head_comment(lines, FS_COMMENT), out


PY_HDR = re.compile(r"^(\s*)(?:async\s+)?def\s+([A-Za-z_]\w*)\s*\(")
PY_CLASS = re.compile(r"^class\s+([A-Za-z_]\w*)")


def parse_python(text, stem):
    lines = text.splitlines()
    heads = []
    cls = None
    for i, ln in enumerate(lines):
        c = PY_CLASS.match(ln)
        if c:
            cls = c.group(1)
        m = PY_HDR.match(ln)
        if m:
            ind = len(m.group(1))
            if ind == 0:
                cls = None
            if ind > 4:
                continue  # nested helpers
            name = f"{cls}.{m.group(2)}" if cls and ind else m.group(2)
            heads.append((i, name, re.sub(r"\s+", " ", ln.strip())))
    out = []
    for n, (i, name, sig) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        body = "\n".join(lines[i:end]).rstrip()
        desc = inner_comment(body, PY_COMMENT) or preceding_comment(lines, i, PY_COMMENT)
        out.append(_make(name, "method" if "." in name else "function", sig, desc, body, i + 1))
    return stem, head_comment(lines, PY_COMMENT), out


def parse_asm(text, stem):
    lines = text.splitlines()
    heads = [(i, m.group(1)) for i, m in ((i, ASM_HDR.match(ln)) for i, ln in enumerate(lines)) if m]

    def comments(chunk):
        return [c for c in (clean_comment(x) for x in re.findall(r";([^\n]*)", chunk)) if len(c) > 6]
    out = []
    for n, (i, name) in enumerate(heads):
        end = heads[n + 1][0] if n + 1 < len(heads) else len(lines)
        body = "\n".join(lines[i:end]).rstrip()
        cm = comments("\n".join(lines[max(0, i - 6):i + 6]))
        out.append(_make(name, "asm", lines[i].strip(), cm[0] if cm else "", body, i + 1))
    cm = comments("\n".join(lines[:20]))
    return stem, (cm[0] if cm else "")[:300], out


def parse_basic(text, stem):
    lines = text.splitlines()
    rems = [r for r in (clean_comment(x) for x in re.findall(r"REM\s*([^\n]*)", "\n".join(lines[:12]))) if len(r) > 3]
    return stem, " ".join(rems)[:300], []


def parse_file(path: Path):
    ext = path.suffix.lower()
    text = read_src(path)
    stem = path.stem
    if ext in PAS_EXT:
        return "Turbo Pascal", parse_pascal_like(text, PAS_HDR, PAS_MOD, lambda m: m.group(1).lower(), stem)
    if ext in M2_EXT:
        return "Modula-2", parse_pascal_like(text, M2_HDR, M2_MOD, lambda m: "procedure", stem,
                                             is_def=(ext == ".def"))
    if ext in ASM_EXT:
        return "x86 Assembly", parse_asm(text, stem)
    if ext in C_EXT:
        return "C++", parse_c(text, stem)
    if ext in JAVA_EXT:
        return "Java", parse_java(text, stem)
    if ext in FS_EXT:
        return "F#", parse_fsharp(text, stem)
    if ext in PY_EXT:
        return "Python", parse_python(text, stem)
    if ext in BAS_EXT:
        return "BASIC", parse_basic(text, stem)
    return None, None


# -- variant collapsing ---------------------------------------------------------
VARIANT_JACCARD = 0.5    # token-set overlap above which same-named callables are one routine
MODULE_FOLD = 0.8        # fraction of a module's callables absorbed elsewhere to fold the module
TOKEN_RE = re.compile(r"[A-Za-z_]\w+")


def group_name(name: str) -> str:
    """Grouping key for variant detection: the full lowercased name. Class-
    qualified names (C++ Class::Method, Java/Python Class.method) keep their
    class, so MFC boilerplate such as AssertValid/Dump/Serialize in different
    classes is not treated as one routine; Pascal/Modula-2 names carry no
    module prefix, so the same procedure in a renamed module still matches."""
    return name.lower()


def module_stem(name: str) -> str:
    """rs2 -> rs, SWEEP2-2 -> sweep, UTILITY2 -> utility: version suffixes stripped."""
    return re.sub(r"[-_]?\d+([-_]\d+)?$", "", name.lower())


def token_set(body: str) -> frozenset:
    return frozenset(t.lower() for t in TOKEN_RE.findall(body))


def jaccard(a: frozenset, b: frozenset) -> float:
    return len(a & b) / max(1, len(a | b))


def collapse_variants(calls: dict, mods: dict) -> tuple[dict, dict]:
    """Merge version variants: same software, same callable name (class/module
    prefix ignored) and body token overlap >= VARIANT_JACCARD, clustered by
    single linkage. The variant with the longest body represents the cluster;
    the others survive as its `variants` list (module, file, snapshot range).
    Returns (calls, folded) where folded maps (sw, modkey) -> (sw, modkey) for
    modules whose callables were >= MODULE_FOLD absorbed by one other module."""
    groups = defaultdict(list)
    for key, c in calls.items():
        groups[(key[0], group_name(c["name"]))].append(key)
    merged, absorbed_into = {}, {}          # key -> representative key
    for _, keys in groups.items():
        if len(keys) == 1:
            continue
        toks = {k: token_set(calls[k]["body"]) for k in keys}
        parent = {k: k for k in keys}

        def find(k):
            while parent[k] != k:
                parent[k] = parent[parent[k]]
                k = parent[k]
            return k
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                if jaccard(toks[a], toks[b]) >= VARIANT_JACCARD:
                    parent[find(a)] = find(b)
        clusters = defaultdict(list)
        for k in keys:
            clusters[find(k)].append(k)
        for members in clusters.values():
            if len(members) < 2:
                continue
            rep = max(members, key=lambda k: (not calls[k]["decl_only"], calls[k]["lines"]))
            for k in members:
                if k != rep:
                    absorbed_into[k] = rep
    out = {}
    for key, c in calls.items():
        if key in absorbed_into:
            continue
        c = dict(c)
        c["variants"] = []
        out[key] = c
    for key, rep in absorbed_into.items():
        c, r = calls[key], out[rep]
        r["snapshots"] |= c["snapshots"]
        r["variants"].append(dict(module=c["module"], file=c["file"], line=c["line"],
                                  first=min(c["snapshots"]), last=max(c["snapshots"]), lines=c["lines"]))
        if len(c["description"]) > len(r["description"]):
            r["description"] = c["description"]
    # fold modules whose members were (almost) all absorbed into one other module
    per_mod = defaultdict(lambda: defaultdict(int))
    for key, rep in absorbed_into.items():
        per_mod[(key[0], key[1])][(rep[0], rep[1])] += 1
    counts = defaultdict(int)
    for key in calls:
        counts[(key[0], key[1])] += 1
    folded = {}
    for mod, targets in per_mod.items():
        tgt, n = max(targets.items(), key=lambda kv: kv[1])
        if tgt == mod or counts[mod] == 0 or n < MODULE_FOLD * counts[mod]:
            continue
        # a module is a *version* of the target if its name is the target's name
        # plus a version suffix, or if the two never coexist in a snapshot;
        # same-snapshot clones with unrelated names (AccountsPayable vs
        # AccountsReceivable) are siblings and keep their own module node
        same_stem = module_stem(mods[mod]["name"]) == module_stem(mods[tgt]["name"])
        coexist = bool(mods[mod]["snapshots"] & mods[tgt]["snapshots"])
        if same_stem or not coexist:
            folded[mod] = tgt
    # resolve chains a -> b -> c
    for mod in list(folded):
        seen = {mod}
        while folded[mod] in folded and folded[mod] not in seen:
            seen.add(folded[mod])
            folded[mod] = folded[folded[mod]]
    return out, folded


# -- static call graph by name ---------------------------------------------------
MAX_AMBIGUOUS = 3        # give up resolving a name with more same-software candidates than this
SUMMARY_NAMES = 4        # callee/caller names listed per module in the summary sentence
# identifiers that are keywords in one language but a PROC / routine name in another
# (SWEEP.ASM has a PROC called BEGIN, which every Pascal body would otherwise "call")
CALL_STOPWORDS = {"begin", "end", "var", "type", "const", "procedure", "function", "module", "if",
                  "then", "else", "elsif", "while", "for", "do", "repeat", "until", "loop", "exit",
                  "return", "with", "case", "of", "and", "or", "not", "div", "mod", "in", "is",
                  "nil", "true", "false", "new", "delete", "this", "self", "class", "struct",
                  "public", "private", "static", "void", "int", "char", "long", "short", "float",
                  "double", "unsigned", "let", "def", "import", "from", "export", "qualified",
                  "array", "record", "set", "pointer", "to", "by", "implementation", "definition"}


def base_name(name: str) -> str:
    """Class::Method / Class.method -> method; Pascal names are already bare."""
    return name.split("::")[-1].split(".")[-1].lstrip("~")


def build_call_graph(calls: dict, mods: dict):
    """Fill `calls` / `callers` (sets of callable keys) on every callable record."""
    index = defaultdict(list)            # (sw, base name lower) -> [keys]
    for key, c in calls.items():
        b = base_name(c["name"]).lower()
        if len(b) > 2:
            index[(key[0], b)].append(key)
    imports = {}                          # (sw, modkey) -> set of imported module names (lower)
    for mkey, m in mods.items():
        imports[mkey] = {x.strip().lower() for x in m["imports"].split(",") if x.strip()}
    for key, c in calls.items():
        c["calls"], c["callers"] = set(), set()
    for key, c in calls.items():
        sw, modkey = key[0], key[1]
        body = c["body"].split("\n", 1)[1] if "\n" in c["body"] else ""   # skip own header
        seen = set()
        for tok in TOKEN_RE.findall(body):
            t = tok.lower()
            if t in seen:
                continue
            seen.add(t)
            if t in CALL_STOPWORDS:
                continue
            # same language only, except that assembly routines are callable from anything
            cands = [k for k in index.get((sw, t), ()) if k != key
                     and (calls[k]["language"] == c["language"] or calls[k]["language"] == "x86 Assembly")]
            if not cands:
                continue
            same = [k for k in cands if k[1] == modkey]
            if same:
                chosen = same
            else:
                imported = [k for k in cands if mods[(sw, k[1])]["name"].lower() in imports.get((sw, modkey), ())]
                chosen = imported or (cands if len(cands) <= MAX_AMBIGUOUS else [])
            for k in chosen:
                c["calls"].add(k)
                calls[k]["callers"].add(key)


ROLE_JUNK = re.compile(r"C R E A T E D|\bCreated\b|\bAuthor\b|\bVersion\b|\bRelease\b|Copyri|\(C\)|"
                       r"implementation file|Defines the class behaviors|standard includes|Last Edit|"
                       r"\bEDITED\b|\bIMPORT\b|^include\b|[=;{}$]|^\W", re.I)


def short_desc(desc: str, n=60) -> str:
    """The role of a module in a few words, for the 'in general terms' summaries:
    the first clause of its header comment, or '' when that comment is a
    file-name banner, copyright line or creation stamp rather than prose."""
    d = re.sub(r"^\S+\.(cpp|cxx|c|h|java|py|fs|pas|mod|def|asm)\b\s*:?\s*", "", desc.strip(), flags=re.I)
    d = re.sub(r"^[\s*]+", "", d)
    d = re.split(r"[.;:]\s|\s-\s|\s\*\s|\s@", d, 1)[0].strip()
    if not d or ROLE_JUNK.search(d) or len(d.split()) < 2 or not re.search(r"[A-Za-z]{3}", d):
        return ""
    if len(d) > n:
        d = d[:n].rsplit(" ", 1)[0] + "..."
    return d


def summarize_links(keys, calls: dict, mods: dict, own_mod: str) -> str:
    """'3 in Graphics (screen drawing: FillArea, GotoXY, SetWindow) and 1 in Locator (CursorOn)'"""
    by_mod = defaultdict(list)
    for k in sorted(keys):
        by_mod[(k[0], k[1])].append(calls[k]["name"])
    parts = []
    for mkey, names in sorted(by_mod.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        m = mods[mkey]
        where = "this module" if m["name"] == own_mod else m["name"]
        shown = ", ".join(base_name(n) for n in names[:SUMMARY_NAMES])
        if len(names) > SUMMARY_NAMES:
            shown += f", +{len(names) - SUMMARY_NAMES} more"
        role = short_desc(m["description"]) if m["name"] != own_mod else ""
        parts.append(f"{len(names)} in {where} ({role + ': ' if role else ''}{shown})")
    if len(parts) > 1:
        return ", ".join(parts[:-1]) + " and " + parts[-1]
    return parts[0] if parts else ""


def salience_for(kind: str, lines: int) -> float:
    if kind == "software":
        return 1.0
    if kind == "module":
        return 0.75
    return round(0.25 + 0.45 * min(1.0, math.log1p(lines) / math.log1p(150)), 3)


def main():
    mods = {}      # (sw, modkey) -> record
    calls = {}     # (sw, modkey, namekey) -> record
    n_files = 0
    vendor_skipped = defaultdict(int)   # file name -> count of vendor-library copies skipped
    for fam in FAMILY:
        base = ROOT / fam
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in SRC_EXT:
                continue
            if any(p in ("bin", "obj", "__pycache__", "node_modules", ".venv") for p in path.parts):
                continue
            rel = path.relative_to(base)
            snap, date = snapshot_of(rel)
            if snap is None:
                if fam == "gdem":
                    snap, date = "GDEM (1984)", "1984xxxx"
                elif fam in UNDATED:
                    snap, date = fam, UNDATED[fam]
                else:
                    continue  # modern stubs / models at family top level
            sw = software_for(fam, snap)
            banner = vendor_banner(read_src(path))
            if banner:
                vendor_skipped[path.name.upper()] += 1
                continue
            lang, parsed = parse_file(path)
            if parsed is None:
                continue
            n_files += 1
            mod_name, mod_desc, items = parsed
            modkey = mod_name.lower()
            relfile = str(path.relative_to(ROOT)).replace("\\", "/")
            mrec = mods.get((sw, modkey))
            if mrec is None:
                mrec = mods[(sw, modkey)] = dict(
                    name=mod_name, software=sw, language=lang, description="",
                    snapshots=set(), files=set(), imports="")
            mrec["snapshots"].add(date)
            mrec["files"].add(relfile)
            if len(mod_desc) > len(mrec["description"]):
                mrec["description"] = mod_desc
            if not mrec["imports"] and lang == "Modula-2":
                imps = re.findall(r"^\s*(?:FROM\s+(\w+)\s+IMPORT|IMPORT\s+([\w, ]+);)", read_src(path), re.M)
                names = sorted({(a or b).strip() for a, b in imps if (a or b)})
                mrec["imports"] = ", ".join(names)[:300]
            for it in items:
                key = (sw, modkey, it["name"].lower())
                crec = calls.get(key)
                body_lines = it["body"].count("\n") + 1
                if crec is None:
                    crec = calls[key] = dict(
                        name=it["name"], software=sw, module=mod_name, language=lang,
                        kind=it["kind"], signature=it["signature"], description=it["description"],
                        body="", lines=0, snapshots=set(), file=relfile, line=it["line"],
                        decl_only=True)
                crec["snapshots"].add(date)
                if len(it["description"]) > len(crec["description"]):
                    crec["description"] = it["description"]
                prefer = (not it["decl_only"] and crec["decl_only"]) or \
                         (it["decl_only"] == crec["decl_only"] and body_lines > crec["lines"])
                if prefer:
                    crec.update(body=it["body"], lines=body_lines, file=relfile, line=it["line"],
                                decl_only=it["decl_only"], language=lang,
                                signature=it["signature"] or crec["signature"])

    print(f"skipped {sum(vendor_skipped.values())} vendor-library files: "
          + ", ".join(f"{n} x{c}" if c > 1 else n for n, c in sorted(vendor_skipped.items())))
    n_raw = len(calls)
    calls, folded = collapse_variants(calls, mods)
    print(f"collapsed {n_raw - len(calls)} variant callables into {sum(1 for c in calls.values() if c['variants'])} "
          f"multi-variant nodes; folding {len(folded)} variant modules")
    for src, dst in folded.items():
        m, t = mods[src], mods[dst]
        t["snapshots"] |= m["snapshots"]
        t["files"] |= m["files"]
        t.setdefault("variants", []).append(dict(module=m["name"], first=min(m["snapshots"]), last=max(m["snapshots"])))
        if len(m["description"]) > len(t["description"]):
            t["description"] = m["description"]
        del mods[src]
    # callables still keyed under a folded module move to the module they folded into
    for key in list(calls):
        if (key[0], key[1]) in folded:
            c = calls.pop(key)
            dst = folded[(key[0], key[1])]
            c["module"] = mods[dst]["name"]
            calls[(dst[0], dst[1], key[2])] = c

    build_call_graph(calls, mods)
    mod_uses = defaultdict(set)      # (sw, modkey) -> modules it calls into
    mod_used_by = defaultdict(set)
    for key, c in calls.items():
        for k in c["calls"]:
            if k[1] != key[1]:
                mod_uses[(key[0], key[1])].add(mods[(k[0], k[1])]["name"])
                mod_used_by[(k[0], k[1])].add(mods[(key[0], key[1])]["name"])
    n_edges = sum(len(c["calls"]) for c in calls.values())
    print(f"call graph: {n_edges} edges; {sum(1 for c in calls.values() if c['callers'])} callables have a caller")

    nodes = []
    # software tier
    for sw in sorted({m["software"] for m in mods.values()}):
        sw_mods = [m for m in mods.values() if m["software"] == sw]
        snaps = sorted({s for m in sw_mods for s in m["snapshots"]})
        blurb = SOFTWARE_BLURB.get(sw, "")
        modlist = ", ".join(sorted(m["name"] for m in sw_mods))[:800]
        nodes.append(dict(
            id=f"sw:{sw}", name=sw, category=sw, kind="software", software=sw, module="",
            language="", signature="", description=blurb,
            text=f"{sw}\n\n{blurb}\n\nModules: {modlist}",
            lines=0, snapshots=snaps, first=snaps[0] if snaps else "",
            last=snaps[-1] if snaps else "", file="", salience=1.0))
    # module tier
    for (sw, modkey), m in sorted(mods.items()):
        snaps = sorted(m["snapshots"])
        members = sorted(c["name"] for k, c in calls.items() if k[0] == sw and k[1] == modkey)
        uses = sorted(mod_uses.get((sw, modkey), ()))
        used_by = sorted(mod_used_by.get((sw, modkey), ()))
        text = (f"{sw} module {m['name']} ({m['language']})\n\n{m['description']}\n\n"
                + (f"Imports: {m['imports']}\n\n" if m["imports"] else "")
                + (f"Calls into modules: {', '.join(uses)}\n\n" if uses else "")
                + (f"Used by modules: {', '.join(used_by)}\n\n" if used_by else "")
                + f"Procedures: {', '.join(members)}")
        nodes.append(dict(
            id=f"mod:{sw}:{m['name']}", name=m["name"], category=sw, kind="module",
            software=sw, module=m["name"], language=m["language"], signature="",
            description=m["description"], text=text[:MAX_TEXT], lines=0,
            snapshots=snaps, first=snaps[0], last=snaps[-1],
            file=sorted(m["files"])[0], salience=salience_for("module", 0),
            imports=[x.strip() for x in m["imports"].split(",") if x.strip()],
            uses_modules=uses, used_by_modules=used_by,
            variants=m.get("variants", []), n_variants=1 + len(m.get("variants", []))))
    # callable tier
    for (sw, modkey, _), c in sorted(calls.items()):
        snaps = sorted(c["snapshots"])
        disp = c["name"] if ("::" in c["name"] or "." in c["name"]) else f"{c['module']}.{c['name']}"
        calls_sum = summarize_links(c["calls"], calls, mods, c["module"])
        callers_sum = summarize_links(c["callers"], calls, mods, c["module"])
        text = (f"{sw} / {c['module']} / {c['name']} ({c['language']} {c['kind']})\n"
                f"{c['signature']}\n{c['description']}\n"
                + (f"Calls: {calls_sum}\n" if calls_sum else "")
                + (f"Called by: {callers_sum}\n" if callers_sum else "")
                + f"\n{c['body']}")
        nodes.append(dict(
            id=f"fn:{sw}:{c['module']}:{c['name']}", name=disp, category=sw, kind=c["kind"],
            software=sw, module=c["module"], language=c["language"], signature=c["signature"],
            description=c["description"], text=text[:MAX_TEXT], lines=c["lines"],
            snapshots=snaps, first=snaps[0], last=snaps[-1], file=c["file"], line=c["line"],
            salience=salience_for(c["kind"], c["lines"]),
            calls=sorted(calls[k]["name"] for k in c["calls"]),
            callers=sorted(calls[k]["name"] for k in c["callers"]),
            calls_summary=calls_sum, callers_summary=callers_sum,
            variants=c["variants"], n_variants=1 + len(c["variants"])))

    OUT.write_text(json.dumps(nodes, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"parsed {n_files} source files -> {len(nodes)} nodes -> {OUT}")
    by_sw = defaultdict(lambda: defaultdict(int))
    for nd in nodes:
        by_sw[nd["software"]][nd["kind"]] += 1
    print(f"{'software':16} {'modules':>8} {'callables':>10}")
    for sw, kinds in sorted(by_sw.items(), key=lambda kv: -sum(kv[1].values())):
        ncall = sum(v for k, v in kinds.items() if k not in ("software", "module"))
        print(f"{sw:16} {kinds['module']:8d} {ncall:10d}")
    lang = defaultdict(int)
    for nd in nodes:
        if nd["kind"] not in ("software", "module"):
            lang[nd["language"]] += 1
    print("callables by language:", dict(lang))
    nodesc = sum(1 for nd in nodes if not nd["description"] and nd["kind"] != "software")
    print(f"nodes without a description: {nodesc}")
    multi = [nd for nd in nodes if nd.get("n_variants", 1) > 1]
    print(f"nodes with variants: {len(multi)} (max {max((nd['n_variants'] for nd in multi), default=1)} variants)")


if __name__ == "__main__":
    main()
