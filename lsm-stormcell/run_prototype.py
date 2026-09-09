"""Run the LSM storm cell analysis prototype end to end.

Generates synthetic E300 picture sequences (lsm_stormcell.e300_frames), scores
the classical RADARPAS two-marker method (Analysis.DrawMarkers, automated with
connected-component detection) and a liquid state machine readout on the same
held-out sequences, and prints both side by side.

    python run_prototype.py                       # defaults: 400 train / 120 test, 2000 neurons
    python run_prototype.py --neurons 1200 --train 200 --test 60
    python run_prototype.py --show                # also print one picture as ASCII

Writes results.json next to this file.
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import numpy as np

from lsm_stormcell.analysis import LSMStormAnalyzer, classical_nowcast, evaluate
from lsm_stormcell.e300_frames import GRID_W, make_sequence, pool_frame
from lsm_stormcell.encoding import num_inputs
from lsm_stormcell.reservoir import LSMParams

HERE = Path(__file__).resolve().parent


def ascii_frame(frame: np.ndarray) -> str:
    g = pool_frame(frame)
    chars = " .:#"
    return "\n".join("".join(chars[min(3, int(v * 3.99))] for v in row) for row in g)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--train", type=int, default=400)
    ap.add_argument("--test", type=int, default=120)
    ap.add_argument("--frames", type=int, default=10, help="pictures observed per sequence")
    ap.add_argument("--horizon", type=int, default=3, help="nowcast lead, in pictures (5 min each)")
    ap.add_argument("--neurons", type=int, default=2600,
                    help="reservoir size; the first 1920 (960 without --no-onset) are input neurons")
    ap.add_argument("--mean-weight", type=float, default=0.02)
    ap.add_argument("--beta", type=float, default=0.05, help="presynaptic degree (mean in-degree / N)")
    ap.add_argument("--threshold", type=float, default=2.0)
    ap.add_argument("--leak", type=float, default=0.002)
    ap.add_argument("--trace-tau", type=float, default=8.0)
    ap.add_argument("--steps-per-frame", type=int, default=8)
    ap.add_argument("--no-onset", action="store_true", help="disable onset (growth) input channels")
    ap.add_argument("--hidden-only", action="store_true", help="read out hidden neurons only (exclude input neurons)")
    ap.add_argument("--rf-sigma", type=float, default=2.5, help="input receptive field width in grid cells (0 = hard grid)")
    ap.add_argument("--max-cells", type=int, default=1, help="cells per sequence (1..max); the dominant one is the target")
    ap.add_argument("--ridge-alpha", type=float, default=0.0, help="ridge penalty; 0 = choose by CV")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--show", action="store_true")
    args = ap.parse_args()

    rng = np.random.default_rng(args.seed)
    t0 = time.time()
    train = [make_sequence(rng, args.frames, max_cells=args.max_cells, horizon=args.horizon) for _ in range(args.train)]
    test = [make_sequence(rng, args.frames, max_cells=args.max_cells, horizon=args.horizon) for _ in range(args.test)]
    print(f"generated {len(train)} train / {len(test)} test sequences of {args.frames} pictures "
          f"({time.time() - t0:.1f}s)")
    if args.show:
        s = test[0]
        print(f"\nlast picture of test sequence 0 ({GRID_W}-column pooled view):")
        print(ascii_frame(s.frames[-1]))
        print(f"dominant cell: x={s.labels['x']:.1f} y={s.labels['y']:.1f} km, "
              f"{s.labels['speed']:.0f} km/h toward {s.labels['direction']:.0f} deg\n")

    t0 = time.time()
    classical = evaluate([classical_nowcast(s) for s in test], test)
    print(f"classical two-marker method scored ({time.time() - t0:.1f}s)")

    n_in = num_inputs(not args.no_onset)
    if args.neurons < n_in + 300:  # inputs occupy the first neurons; keep a hidden pool for the readout
        print(f"--neurons {args.neurons} is below the {n_in} input neurons + 300 hidden; using {n_in + 300}")
        args.neurons = n_in + 300
    params = LSMParams(num_neurons=args.neurons, membrane_threshold=args.threshold,
                       leak_coefficient=args.leak, presynaptic_degree=args.beta,
                       mean_weight=args.mean_weight, trace_tau=args.trace_tau, seed=args.seed)
    lsm = LSMStormAnalyzer(params, steps_per_frame=args.steps_per_frame,
                           onset_channels=not args.no_onset, ridge_alpha=args.ridge_alpha,
                           readout_inputs=not args.hidden_only, rf_sigma=args.rf_sigma, seed=args.seed)
    print(f"reservoir: {params.num_neurons} neurons, {lsm.reservoir.num_inputs} inputs, "
          f"mean in-degree {lsm.reservoir.mean_in_degree:.1f}")
    t0 = time.time()
    lsm.fit(train)
    t_fit = time.time() - t0
    t0 = time.time()
    lsm_scores = evaluate(lsm.predict(test), test)
    t_pred = time.time() - t0
    print(f"LSM fit {t_fit:.1f}s, predict {t_pred:.1f}s, mean spikes/sequence {lsm.mean_spikes:.0f}")

    rows = [("detected fraction", "detected", "{:.2f}"),
            ("position MAE (km)", "position_mae_km", "{:.1f}"),
            ("speed MAE (km/h)", "speed_mae_kmh", "{:.1f}"),
            ("direction MAE (deg)", "direction_mae_deg", "{:.1f}"),
            (f"nowcast +{args.horizon * 5} min MAE (km)", "nowcast_mae_km", "{:.1f}"),
            ("persistence nowcast MAE (km)", "persistence_nowcast_mae_km", "{:.1f}"),
            ("motion octant accuracy", "octant_accuracy", "{:.2f}")]
    print(f"\n{'metric':34} {'classical':>10} {'LSM':>10}")
    for label, key, fmt in rows:
        print(f"{label:34} {fmt.format(classical[key]):>10} {fmt.format(lsm_scores[key]):>10}")

    out = dict(args=vars(args), reservoir=dict(num_inputs=lsm.reservoir.num_inputs,
               mean_in_degree=lsm.reservoir.mean_in_degree, mean_spikes=lsm.mean_spikes),
               classical=classical, lsm=lsm_scores, fit_seconds=t_fit, predict_seconds=t_pred)
    (HERE / "results.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(f"\nwrote {HERE / 'results.json'}")


if __name__ == "__main__":
    main()
