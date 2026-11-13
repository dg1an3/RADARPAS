"""Write callables_<variant>.json: the same nodes as callables.json with the
procedure body removed from each callable's embedded `text`, so the map can be
built from the header block alone (name, signature, header comment, call-graph
summaries). Module and software nodes carry no code and are left unchanged.

The header block is everything before the first blank line, the same split
synthesize_comments.py uses (see body_of there).

Usage:
  python strip_bodies.py                 # -> callables_nobody.json
  python embed_callables.py --variant nobody
  python umap_layout.py --variant nobody # -> umap_3d_viewer/data_nobody.json
  # viewer: http://localhost:8777/?data=nobody
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

ap = argparse.ArgumentParser()
ap.add_argument("--variant", default="nobody", help="suffix for the output file")
args = ap.parse_args()

nodes = json.loads((HERE / "callables.json").read_text(encoding="utf-8"))
stripped = 0
for nd in nodes:
    if nd["kind"] in ("software", "module"):
        continue
    head, _, body = nd["text"].partition("\n\n")
    if body:
        stripped += 1
    nd["text"] = head
out = HERE / f"callables_{args.variant}.json"
out.write_text(json.dumps(nodes, indent=1, ensure_ascii=False), encoding="utf-8")
print(f"wrote {out.name}: {len(nodes)} nodes, bodies removed from {stripped}")
