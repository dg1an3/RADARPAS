"""Two-stage UMAP layout of the callable embeddings for the Three.js viewer.

Stage 1: 768D nomic embeddings -> {5, 8, 11}D (saved to umap_projections/ for
         the viewer's proximity kernel, as in semantic_notes/src/umap_sweep.py)
Stage 2: 5D -> 3D and 2D, plus a haversine 2D fit mapped onto a sphere, as in
         semantic_notes/src/umap_5d_to_3d.py, then ball-warped and written to
         umap_3d_viewer/data.json as
         [{name, description, category, kind, software, module, ..., x,y,z,
           x2,y2, xs,ys,zs, salience, v5, v8, v11}]

Salience comes from extract_callables.py: software nodes 1.0, modules 0.75,
callables 0.25-0.7 by body length. UMAP packs 3,000+ nodes into tight clumps
(median nearest-neighbour gap 0.18 on a 100-unit ball), so a kd-tree
relaxation (`relax`, --spacing) pushes overlapping nodes apart to roughly the
uniform-packing spacing, giving salient nodes more room; it replaces the
O(N^2) salience_space of the timeline pipeline (still available via
--salience-space for small runs).
"""
import argparse
import json
from pathlib import Path

import numpy as np
import umap

HERE = Path(__file__).resolve().parent
EMB_NPY = HERE / "callables_embeddings.npy"
EMB_JSON = HERE / "callables_embeddings.json"
PROJ_DIR = HERE / "umap_projections"
OUT_DIR = HERE / "umap_3d_viewer"

SEED = 42
SCALE = 100.0
SPHERE_WARP = 0.6
DIMS = (5, 8, 11)

ap = argparse.ArgumentParser()
ap.add_argument("--n-neighbors-hd", type=int, default=30, help="stage 1 (768D -> 5/8/11D) locality")
ap.add_argument("--n-neighbors", type=int, default=60, help="stage 2 (5D -> 3D/2D) locality")
ap.add_argument("--min-dist-hd", type=float, default=0.1)
ap.add_argument("--with-768", action="store_true", help="embed the raw 768D vectors in data.json (large)")
ap.add_argument("--salience-space", type=float, default=0.0, help="strength of pairwise salience relaxation (0=off)")
ap.add_argument("--min-dist", type=float, default=0.5, help="stage 2 UMAP min_dist (3D); 2D uses 1.5x")
ap.add_argument("--spacing", type=float, default=1.0,
                help="kd-tree relaxation: minimum spacing as a multiple of the uniform-packing spacing (0=off)")
ap.add_argument("--reuse-hd", action="store_true", help="skip stage 1 and reuse umap_projections/*.npy")
args = ap.parse_args()


def norm_scale(Y):
    Y = Y - Y.mean(axis=0)
    return Y / (np.abs(Y).max() or 1.0) * SCALE


def ball_warp(Y, strength):
    """Rank-remap radii toward a uniform d-ball so the cloud has no empty core."""
    d = Y.shape[1]
    V = Y - Y.mean(axis=0)
    r = np.linalg.norm(V, axis=1)
    dirs = V / np.maximum(r, 1e-9)[:, None]
    ranks = r.argsort().argsort()
    target = ((ranks + 0.5) / len(r)) ** (1.0 / d)
    rn = r / r.max()
    new_rn = (1.0 - strength) * rn + strength * target
    return dirs * (new_rn * SCALE)[:, None]


def relax(Y, sal, spacing_mult, iters=80, seed=SEED):
    """Push apart nodes closer than a minimum spacing, using a kd-tree so it
    scales to thousands of nodes (the O(N^2) salience_space below does not).

    The spacing is derived from uniform packing of N points in a ball/disk of
    radius SCALE, scaled by spacing_mult; each node's share of it grows with
    salience (software > module > callable), so salient nodes hold more room.
    Salient nodes move less. Local UMAP structure is kept; only overlaps move."""
    if spacing_mult <= 0:
        return Y
    from scipy.spatial import cKDTree
    rng = np.random.default_rng(seed)
    Y = Y.astype(np.float64).copy()
    n, d = Y.shape
    vol = (4.0 / 3.0 * np.pi * SCALE ** 3) if d == 3 else (np.pi * SCALE ** 2)
    base = (vol / n) ** (1.0 / d) * spacing_mult
    r = 0.5 * base * (0.6 + 0.8 * sal)               # per-node exclusion radius
    mob = 1.0 / (0.25 + sal)
    mob /= mob.max()
    Y += rng.normal(0, 1e-3, Y.shape)                 # break exact ties
    rmax = 2 * r.max()
    for it in range(iters):
        pairs = cKDTree(Y).query_pairs(rmax, output_type="ndarray")
        if len(pairs) == 0:
            break
        i, j = pairs[:, 0], pairs[:, 1]
        diff = Y[i] - Y[j]
        dist = np.linalg.norm(diff, axis=1)
        overlap = (r[i] + r[j]) - dist
        m = overlap > 0
        if not m.any():
            break
        i, j, diff, dist, overlap = i[m], j[m], diff[m], dist[m], overlap[m]
        unit = diff / np.maximum(dist, 1e-9)[:, None]
        push = unit * (overlap * 0.5)[:, None] * 0.7
        disp = np.zeros_like(Y)
        np.add.at(disp, i, push * mob[i, None])
        np.add.at(disp, j, -push * mob[j, None])
        Y += disp
    Y -= Y.mean(axis=0)
    # rescale by the 99th-percentile radius (not the max) so a few pushed-out
    # outliers do not shrink the whole cloud, then clip them to the ball
    rad = np.linalg.norm(Y, axis=1)
    Y *= SCALE / (float(np.percentile(rad, 99)) or 1.0)
    rad = np.linalg.norm(Y, axis=1)
    over = rad > SCALE
    Y[over] *= (SCALE / rad[over])[:, None]
    return Y


def salience_space(Y, sal, strength, iters=60):
    if strength <= 0:
        return Y
    Y = Y.astype(np.float64).copy()
    d0 = np.linalg.norm(Y[:, None, :] - Y[None, :, :], axis=2)
    np.fill_diagonal(d0, np.inf)
    base = float(np.median(d0.min(axis=1)))
    r = 0.5 * base * (0.5 + 1.7 * sal) * strength
    mob = 1.0 / (0.25 + sal)
    mob = mob / mob.max()
    for _ in range(iters):
        diff = Y[:, None, :] - Y[None, :, :]
        dist = np.linalg.norm(diff, axis=2)
        np.fill_diagonal(dist, np.inf)
        overlap = np.clip((r[:, None] + r[None, :]) - dist, 0.0, None)
        with np.errstate(invalid="ignore", divide="ignore"):
            unit = diff / dist[:, :, None]
        unit[~np.isfinite(unit)] = 0.0
        Y += (unit * (overlap * 0.5)[:, :, None]).sum(axis=1) * mob[:, None] * 0.6
    Y -= Y.mean(axis=0)
    return Y / (float(np.linalg.norm(Y, axis=1).max()) or 1.0) * SCALE


def main():
    X = np.load(EMB_NPY).astype(np.float64)
    recs = json.loads(EMB_JSON.read_text(encoding="utf-8"))
    n = len(recs)
    assert X.shape[0] == n, (X.shape, n)
    print(f"{n} nodes x {X.shape[1]}D")

    PROJ_DIR.mkdir(exist_ok=True)
    HD = {}
    for d in DIMS:
        path = PROJ_DIR / f"umap_{d}d.npy"
        if args.reuse_hd and path.exists():
            HD[f"v{d}"] = np.load(path).astype(np.float64)
            continue
        print(f"  stage 1: 768D -> {d}D (n_neighbors={args.n_neighbors_hd}) ...")
        Y = umap.UMAP(n_components=d, n_neighbors=args.n_neighbors_hd, min_dist=args.min_dist_hd,
                      metric="cosine", random_state=SEED).fit_transform(X)
        np.save(path, Y.astype(np.float32))
        HD[f"v{d}"] = Y
    X5 = HD["v5"]

    def fit(dim, min_dist):
        Y = umap.UMAP(n_components=dim, n_neighbors=args.n_neighbors, min_dist=min_dist,
                      metric="euclidean", random_state=SEED).fit_transform(X5)
        return norm_scale(Y)

    sal = np.array([r.get("salience", 0.4) for r in recs], dtype=np.float64)
    print("  stage 2: 5D -> 3D ...")
    Y3 = relax(ball_warp(fit(3, args.min_dist), SPHERE_WARP), sal, args.spacing)
    print("  stage 2: 5D -> 2D ...")
    Y2 = relax(ball_warp(fit(2, args.min_dist * 1.5), SPHERE_WARP), sal, args.spacing)
    print("  stage 2: 5D -> sphere (haversine) ...")
    YS = umap.UMAP(n_components=2, output_metric="haversine", n_neighbors=args.n_neighbors,
                   min_dist=0.15, random_state=SEED).fit_transform(X5)
    th, ph = YS[:, 0], YS[:, 1]
    YS = np.column_stack([SCALE * np.sin(th) * np.cos(ph), SCALE * np.sin(th) * np.sin(ph),
                          SCALE * np.cos(th)])
    if args.spacing > 0:  # relax on the sphere surface too, re-projecting to the shell
        for _ in range(3):
            YS = relax(YS, sal, args.spacing * 0.8, iters=30)
            YS = YS / np.linalg.norm(YS, axis=1, keepdims=True) * SCALE

    if args.salience_space > 0:
        print("  salience relaxation ...")
        Y3 = salience_space(Y3, sal, args.salience_space)
        Y2 = salience_space(Y2, sal, args.salience_space)

    data = []
    for i, r in enumerate(recs):
        rec = {k: r.get(k) for k in ("name", "description", "category", "id", "kind", "software",
                                     "module", "language", "signature", "lines", "first", "last",
                                     "file", "line", "description_source", "calls_summary",
                                     "callers_summary", "uses_modules", "used_by_modules")}
        rec["snapshots"] = len(r.get("snapshots") or [])
        variants = r.get("variants") or []
        rec["n_variants"] = 1 + len(variants)
        rec["variants"] = [f"{v['module']} ({v['first'][:4]}-{v['last'][:4]})" for v in variants]
        if variants:  # mark collapsed version variants in the label and hover text
            rec["name"] = f"{rec['name']} x{rec['n_variants']}"
            rec["description"] = (rec["description"] or "") + " | also: " + ", ".join(rec["variants"][:6])
        rec.update(x=round(float(Y3[i, 0]), 3), y=round(float(Y3[i, 1]), 3), z=round(float(Y3[i, 2]), 3),
                   x2=round(float(Y2[i, 0]), 3), y2=round(float(Y2[i, 1]), 3),
                   xs=round(float(YS[i, 0]), 3), ys=round(float(YS[i, 1]), 3), zs=round(float(YS[i, 2]), 3),
                   salience=round(float(sal[i]), 3))
        for k, V in HD.items():
            rec[k] = [round(float(x), 4) for x in V[i]]
        if args.with_768:
            rec["v768"] = [round(float(x), 3) for x in X[i]]
        data.append(rec)

    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / "data.json"
    out.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    cats = sorted({d["category"] for d in data})
    print(f"wrote {out} ({len(data)} nodes, {len(cats)} categories, {out.stat().st_size / 1e6:.1f} MB)")
    for c in cats:
        print(f"  {sum(d['category'] == c for d in data):5d}  {c}")


if __name__ == "__main__":
    main()
