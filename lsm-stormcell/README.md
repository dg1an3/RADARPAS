# LSM StormCell

Prototype that performs RADARPAS storm cell analysis with a **liquid state
machine** (LSM): a fixed reservoir of leaky integrate-and-fire spiking neurons on
a small-world graph, read out by a linear model.

The reservoir follows Ruggero Freddi's
[LSM-Robustness](https://github.com/RuggeroFreddi/LSM-Robustness) implementation
(paper: *Bridging Theory and Practice in Crafting Robust Spiking Reservoirs*,
[arXiv:2604.06395](https://arxiv.org/html/2604.06395)), which builds on Maass,
Natschlaeger and Markram's original LSM. `lsm_stormcell/reservoir.py` is an
independent re-implementation of that model with the same dynamics and parameter
names (membrane threshold, log-normal leak, refractory period, input current
amplitude, presynaptic degree beta, Watts-Strogatz rewiring probability, mean
synaptic weight with a variation coefficient, exponential spike trace with
`trace_tau`), vectorised with a sparse matrix-vector product.

## What it analyses

The 1992 RADARPAS terminal (`radar/19921228 RADAR MOD/ANALYSIS.MOD`) tracked a
storm cell by letting the operator drop markers on successive pictures; the
`DrawMarkers` procedure differenced the last two markers, scaled by
`CurrRange/256` and the 48:35 pixel aspect, and printed the cell's speed and
direction. `Analyze` was left as an empty stub.

This prototype fills in that stub:

| stage | module | what it does |
|---|---|---|
| picture model | `e300_frames.py` | 240 x 1280 two-bit E300 pictures (red/green bit planes as delivered by `E300Interface.GetLine`), synthetic moving/growing storm cells, mean-pooling to a 24 x 40 input grid |
| spike encoding | `encoding.py` | rate coding of echo intensity per grid cell over 8 reservoir steps per picture, plus onset channels where echo grew |
| reservoir | `reservoir.py` | LIF small-world reservoir, liquid state = spike traces at the end of the last three pictures + recent spike counts |
| readout | `analysis.py` | ridge regression for the dominant cell's position, velocity and position 15 minutes ahead; logistic regression for its motion octant |
| baseline | `analysis.py` | `classical_nowcast`: connected-component cell detection plus the `DrawMarkers` two-marker difference, extrapolated |

Both methods are scored on the same held-out sequences: position, speed and
direction error, nowcast error against the true future position, and the
persistence (no-motion) nowcast for reference.

## Running

```bash
cd lsm-stormcell
pip install numpy scipy scikit-learn
python run_prototype.py --show               # 400 train / 120 test, 2000 neurons
python run_prototype.py --neurons 1200 --train 100 --test 40   # quicker
```

Results are printed as a table and written to `results.json`. Defaults on
2026-09-07 (600 train / 120 test single-cell sequences, 2600 neurons, mean
weight 0.02, receptive-field sigma 2.5, readouts at 4 pictures, ridge alpha by CV):

| metric | classical two-marker | LSM readout |
|---|---|---|
| detected fraction | 0.82 | 1.00 |
| position MAE (km) | 0.1 | 10.6 |
| speed MAE (km/h) | 7.1 | 15.9 |
| direction MAE (deg) | 15.8 | 19.9 |
| nowcast +15 min MAE (km) | 0.4 | 15.5 |
| persistence nowcast MAE (km) | 11.0 | 11.0 |
| motion octant accuracy | 0.84 | 0.65 |

On clean synthetic Gaussian cells the classical centroid method is nearly
exact, so the LSM is behind it; direction is the one quantity the reservoir
recovers at comparable accuracy. Position error is about one input grid cell
(12.5 x 15.6 km). What made the linear readout work at all: per-sample L1
normalisation of each liquid state block (a centroid is then linear in the
features), overlapping Gaussian receptive fields on the input grid, readout
times spread over the whole sequence, and a mean synaptic weight low enough
(0.02) that the reservoir does not saturate. Multi-cell sequences
(`--max-cells 3`) defeat a global linear readout; per-cell attention or a
nonlinear readout would be the next step.

## Feeding real pictures

`e300_frames.decode_getline_stream` rebuilds a picture from the
`(LineNum, RedBitMap, GrnBitMap)` records that `E300Interface.GetLine` returns,
so a logged E300 download can be pushed through the same `pool_frame` and
`encode_sequence` path. The historical `.RDR` files in `radar/` are Turbo
Pascal screen dumps rather than GetLine logs and are not decoded here.
