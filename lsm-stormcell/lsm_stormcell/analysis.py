"""Storm cell analysis: the classical RADARPAS approach and the LSM readout.

Classical (Analysis.DrawMarkers / Analyze in the 1992 Modula-2 terminal):
the operator dropped markers on the storm cell in successive pictures; the
terminal differenced the last two markers, scaled dX by CurrRange/256 and dY
by CurrRange*48/35/256, and printed Speed = sqrt(dX^2+dY^2) and
Dir = ATan(dX/dY). `classical_nowcast` automates that with connected-component
cell detection (scipy.ndimage.label) standing in for the operator's marker.

LSM: a spiking reservoir (reservoir.py) consumes the spike-encoded picture
sequence; a ridge regression readout on the liquid state predicts the dominant
cell's position, velocity and its position `horizon` frames ahead; the motion
octant is derived from the decoded velocity. Both approaches are scored with
the same metrics by `evaluate`.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy import ndimage
from sklearn.linear_model import Ridge, RidgeCV

from .e300_frames import FRAME_MINUTES, KM_PER_COL, KM_PER_ROW, PIC_H, StormSequence, speed_dir
from .encoding import encode_sequence, num_inputs, readout_times
from .reservoir import LSMParams, Reservoir

TARGETS = ("x", "y", "vx", "vy", "x_future", "y_future")


# -- classical -----------------------------------------------------------------
@dataclass
class DetectedCell:
    x: float
    y: float
    area_km2: float
    mean_level: float


def detect_cells(frame: np.ndarray, min_level: int = 2, min_pixels: int = 60) -> list[DetectedCell]:
    """Connected components of moderate-or-heavier echo, centroids in km."""
    mask = frame >= min_level
    lab, n = ndimage.label(mask)
    cells = []
    if n == 0:
        return cells
    idx = np.arange(1, n + 1)
    sizes = ndimage.sum(mask, lab, idx)
    coms = ndimage.center_of_mass(mask, lab, idx)
    means = ndimage.mean(frame.astype(np.float32), lab, idx)
    for size, (r, c), m in zip(sizes, coms, means):
        if size < min_pixels:
            continue
        cells.append(DetectedCell(x=(c + 0.5) * KM_PER_COL, y=(PIC_H - r - 0.5) * KM_PER_ROW,
                                  area_km2=float(size) * KM_PER_COL * KM_PER_ROW, mean_level=float(m)))
    return sorted(cells, key=lambda d: -d.area_km2 * d.mean_level)


def marker_velocity(prev: DetectedCell, cur: DetectedCell) -> tuple[float, float]:
    """DrawMarkers' two-marker difference as a velocity in km/h."""
    dt_h = FRAME_MINUTES / 60.0
    return (cur.x - prev.x) / dt_h, (cur.y - prev.y) / dt_h


def classical_nowcast(seq: StormSequence) -> dict:
    """Detect the dominant cell in the last two pictures, difference the
    centroids (the DrawMarkers method) and extrapolate `horizon` frames."""
    horizon = seq.labels["horizon"]
    cur = detect_cells(seq.frames[-1])
    prev = detect_cells(seq.frames[-2])
    if not cur:
        return dict(x=np.nan, y=np.nan, vx=0.0, vy=0.0, speed=0.0, direction=0.0,
                    x_future=np.nan, y_future=np.nan, octant=0)
    c = cur[0]
    if prev:  # nearest previous cell to the current dominant one
        p = min(prev, key=lambda d: (d.x - c.x) ** 2 + (d.y - c.y) ** 2)
        vx, vy = marker_velocity(p, c)
    else:
        vx, vy = 0.0, 0.0
    dt_h = horizon * FRAME_MINUTES / 60.0
    spd, ang = speed_dir(vx, vy)
    return dict(x=c.x, y=c.y, vx=vx, vy=vy, speed=spd, direction=ang,
                x_future=c.x + vx * dt_h, y_future=c.y + vy * dt_h,
                octant=int(((ang + 22.5) % 360) // 45))


# -- liquid state machine ---------------------------------------------------------
class LSMStormAnalyzer:
    FEATURE_GAIN = 100.0   # puts the L1-normalised features on a unit-ish scale for ridge

    def __init__(self, params: LSMParams | None = None, steps_per_frame: int = 8,
                 max_rate: float = 1.0, onset_channels: bool = True, readout_k: int = 4,
                 ridge_alpha: float = 0.0, readout_inputs: bool = True, rf_sigma: float = 2.5,
                 seed: int = 0):
        self.params = params or LSMParams()
        self.readout_inputs = readout_inputs
        self.rf_sigma = rf_sigma
        self.steps_per_frame = steps_per_frame
        self.max_rate = max_rate
        self.onset_channels = onset_channels
        self.readout_k = readout_k
        self.rng = np.random.default_rng(seed)
        self.reservoir = Reservoir(self.params, num_inputs(onset_channels))
        # ridge_alpha <= 0 -> pick alpha by leave-one-out CV over a log grid
        self.reg = Ridge(alpha=ridge_alpha) if ridge_alpha > 0 else RidgeCV(alphas=np.logspace(0, 4, 9))
        self.spikes_per_seq: list[int] = []

    def features(self, seq: StormSequence) -> np.ndarray:
        raster = encode_sequence(seq.frames, self.rng, self.steps_per_frame, self.max_rate,
                                 self.onset_channels, self.rf_sigma)
        times = readout_times(seq.frames.shape[0], self.steps_per_frame, self.readout_k)
        r = self.reservoir.simulate(raster, times, count_window=self.steps_per_frame * 2)
        self.spikes_per_seq.append(r["tot_spikes"])
        # liquid state = every neuron's trace (input neurons included, as in Maass's
        # formulation) at each readout time, plus recent spike counts. Each block is
        # L1-normalised per sample so the readout sees an activation *distribution*:
        # a cell's centroid is then linear in the features regardless of its size or
        # intensity, and velocity is the difference between two readout times.
        sl = slice(0 if self.readout_inputs else self.reservoir.num_inputs, self.reservoir.n)
        parts = [r["trace_at"][t][sl] for t in times] + [r["counts"][sl]]
        return np.concatenate([p / (p.sum() + 1e-6) for p in parts])

    def fit(self, seqs: list[StormSequence]) -> "LSMStormAnalyzer":
        X = np.stack([self.features(s) for s in seqs])
        Y = np.array([[s.labels[k] for k in TARGETS] for s in seqs])
        self.reg.fit(X * self.FEATURE_GAIN, Y)
        return self

    def predict(self, seqs: list[StormSequence]) -> list[dict]:
        X = np.stack([self.features(s) for s in seqs])
        Y = self.reg.predict(X * self.FEATURE_GAIN)
        out = []
        for y in Y:
            d = dict(zip(TARGETS, map(float, y)))
            d["speed"], d["direction"] = speed_dir(d["vx"], d["vy"])
            # motion octant from the decoded velocity, as the classical method does
            d["octant"] = int(((d["direction"] + 22.5) % 360) // 45)
            out.append(d)
        return out

    @property
    def mean_spikes(self) -> float:
        return float(np.mean(self.spikes_per_seq)) if self.spikes_per_seq else 0.0


# -- scoring -----------------------------------------------------------------------
def circular_error(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    d = np.abs(a - b) % 360.0
    return np.minimum(d, 360.0 - d)


def evaluate(preds: list[dict], seqs: list[StormSequence]) -> dict:
    lab = {k: np.array([s.labels[k] for s in seqs], dtype=float) for k in
           ("x", "y", "speed", "direction", "x_future", "y_future", "octant")}
    prd = {k: np.array([p[k] for p in preds], dtype=float) for k in lab}
    ok = np.isfinite(prd["x"])
    pos = np.hypot(prd["x"] - lab["x"], prd["y"] - lab["y"])
    now = np.hypot(prd["x_future"] - lab["x_future"], prd["y_future"] - lab["y_future"])
    persist = np.hypot(lab["x"] - lab["x_future"], lab["y"] - lab["y_future"])  # "no motion" nowcast
    return dict(
        n=int(len(seqs)), detected=float(ok.mean()),
        position_mae_km=float(np.nanmean(pos)),
        speed_mae_kmh=float(np.nanmean(np.abs(prd["speed"] - lab["speed"]))),
        direction_mae_deg=float(np.nanmean(circular_error(prd["direction"], lab["direction"]))),
        nowcast_mae_km=float(np.nanmean(now)),
        persistence_nowcast_mae_km=float(np.mean(persist)),
        octant_accuracy=float(np.mean(prd["octant"] == lab["octant"])),
    )
