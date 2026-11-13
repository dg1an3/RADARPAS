# Archive UMAP: software, modules and callables

A semantic map of every piece of software in this archive, down to the
individual procedure. Same pipeline as the `semantic_notes` timeline and
projects maps: ollama `nomic-embed-text` embeddings, a 768D -> {5, 8, 11}D
UMAP stage, a 5D -> 3D / 2D / sphere stage, and the Three.js viewer with
spreading activation.

Nodes come in three tiers so activation can flow software -> module -> callable:

| tier | count | salience | text that is embedded |
|---|---|---|---|
| software | one per family (RADARPAS, SSM, theWheel, EEVORG, CogMap, EGALib & Math, GDEM, BQ Tournament, TURING, Pic-Analysis, SIGNAL, Browsee, HackRF NOAA, LSM StormCell) | 1.0 | blurb + module list |
| module | Pascal unit / Modula-2 module / C++, Java, F#, Python file | 0.75 | header comment, imports, procedure list |
| callable | procedure, function, method, assembly PROC | 0.25-0.7 by length | signature, comment, body excerpt |

Vendor library source that shipped inside the snapshots is left out: a file
whose header carries a TopSpeed / Jensen & Partners, Logitech Modula-2 library,
PMI Repertoire or Borland copyright banner is skipped (`VENDOR_RX` in
`extract_callables.py`), so the Modula-2 standard library (Lib, Str, FIO, IO,
Graph, Storage, Process, SYSTEM, MATHLIB, AsmLib, ASCII, TimeDate, CRC,
LowLevel, MemCompress) does not appear as nodes. The check is on the copyright
notice, not the module name, so the author's own modules that reuse a library
name (the 1988 `Storage.def`, `Windows.def`) stay.

The same routine appears in many dated snapshots (RADARPAS has 24); it is one
node carrying the list of snapshots it was seen in and the longest body found.
Version variants that moved between modules are collapsed too: callables with
the same class-qualified name in the same software whose bodies share at least
half their identifier tokens become one node (labelled `Name xN`, with the other
modules and years in the hover text), and a module whose callables were nearly
all absorbed by another is folded into it when it carries a version suffix
(rs2, SWEEP3, UTILITY2) or never coexists with the target in a snapshot. Same-
named routines with different bodies (every `main`, `Init` in unrelated
modules, MFC `AssertValid` in different classes) stay separate.

## Pipeline

```bash
cd umap
python extract_callables.py      # walk the archive -> callables.json (with the static call graph)
python synthesize_comments.py    # ollama qwen3-coder writes the header comments that are missing (cached)
python embed_callables.py        # ollama nomic-embed-text -> callables_embeddings.{json,npy} (cached)
python umap_layout.py            # -> umap_projections/*.npy, umap_3d_viewer/data.json
cd umap_3d_viewer && python serve.py 8777   # http://localhost:8777/
```

The viewer is also hosted on Firebase (project `radarpas-umap`, config in
`firebase.json` / `.firebaserc`; only `index.html` and `data.json` are
uploaded). After a relayout, publish the new `data.json` with:

```bash
firebase deploy --only hosting        # -> https://radarpas-umap.web.app
```

`embed_callables.py` caches by node id and text hash in `embed_cache.json`,
so re-running after adding a project only embeds the new nodes.

### Variant without procedure bodies

A callable's embedded text is its header block (name, signature, header comment,
call-graph summaries) followed by a blank line and the procedure body, cut at
3500 characters. To see how the map looks when only the header block is
embedded:

```bash
python strip_bodies.py                     # callables.json -> callables_nobody.json (bodies dropped)
python embed_callables.py --variant nobody # -> callables_embeddings_nobody.{json,npy} (shared cache)
python umap_layout.py --variant nobody     # -> umap_projections_nobody/, umap_3d_viewer/data_nobody.json
```

then open `http://localhost:8777/?data=nobody`. The default map and its files
are untouched; `?data=<name>` loads `data_<name>.json` for any variant.

The viewer shows the exact embedded text of the node under the mouse (the
"hover: embedded text" checkbox turns it off); `umap_layout.py` copies it into
`data.json` as `text`.

## Call graph and synthesized comments

`extract_callables.py` derives a static call graph by name: a callable whose
body mentions the name of another callable in the same software (and language;
assembly routines are callable from anything) calls it, resolved to the same
module first, then to a module the caller imports, then to any match with at
most three candidates. Keywords that double as routine names (`BEGIN` is a PROC
in SWEEP.ASM) are ignored. Each callable node carries `calls` / `callers` and
two one-line summaries grouped by module, e.g.

    Calls: 3 in Graphics (GotoXY, Line, SetPlane) and 1 in CDScrn (Message)
    Called by: 6 in this module (MoveArea, PopVideoState, PutPicture, +3 more)

which are embedded with the node and shown in the viewer's readout when a node
is activated. Module nodes carry `uses_modules` / `used_by_modules` the same way.

About 460 nodes have no source comment at all. `synthesize_comments.py` asks a
local ollama code model (default `qwen3-coder:30b`, about 2 s per node once
loaded) for the missing one- or two-sentence header comment, given the software
blurb, signature, body, call summaries and, for modules, the head of the source
file. The result becomes the node's `description` (marked
`description_source: "synthesized"`, shown with a leading `~` in the viewer) and
fills the description line of the embedded text. `synth_cache.json` keys on node
id plus the text hash, so re-running only asks about new or changed nodes;
`--dry-run --limit N` previews prompts and answers, `--redo` regenerates.

`umap_layout.py --with-768` also stores the raw 768D vectors per node for the
viewer's full-latent proximity kernel (about 20 MB of JSON at this node count).

## Files

- `extract_callables.py` -- language heuristics for Turbo Pascal, Modula-2 (.MOD/.DEF), x86 assembly, C/C++, Java, F#, Python, BASIC (module only)
- `synthesize_comments.py` -- ollama-written header comments for nodes that have none (`synth_cache.json`)
- `embed_callables.py` -- embeddings, mirrors `semantic_notes/src/embed_projects.py`
- `umap_layout.py` -- both UMAP stages, mirrors `umap_sweep.py` + `umap_5d_to_3d.py`
- `umap_3d_viewer/` -- `index.html` (copied from the projects viewer, palette keyed by software), `serve.py`, `data.json`

The viewer has a phone layout: a touch device with a small screen (or `?mobile`
on any device; `?desktop` forces the full layout) starts flat in 2D with
salience activation on, no VR button, the legend folded behind a button, and
the density, proximity-space and cascade controls removed.
