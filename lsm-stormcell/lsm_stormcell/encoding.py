"""Spike encoding of E300 picture sequences for the reservoir.

Each cell of the pooled GRID_H x GRID_W picture drives one input neuron. A
frame is presented for `steps_per_frame` reservoir time steps; at every step
the neuron fires a Bernoulli spike with probability max_rate * intensity, i.e.
rate coding of echo intensity (the same scheme as the trajectory dataset in
Freddi's LSM-Robustness, where a binary frame is shown for a fixed number of
steps). Optional onset channels fire once where the echo grew since the last
frame, which gives the liquid an explicit motion cue.
"""
from __future__ import annotations

import numpy as np
from scipy.ndimage import gaussian_filter

from .e300_frames import GRID_H, GRID_W, pool_frame

NUM_RATE_INPUTS = GRID_H * GRID_W


def num_inputs(onset_channels: bool) -> int:
    return NUM_RATE_INPUTS * (2 if onset_channels else 1)


def receptive_fields(grid: np.ndarray, sigma: float) -> np.ndarray:
    """Overlapping Gaussian receptive fields over the pooled picture (population
    coding): each input neuron responds to echo within ~sigma grid cells of its
    centre, so a storm drives a graded patch of neurons rather than a few
    isolated ones and its position is smoothly decodable by a linear readout."""
    if sigma <= 0:
        return grid
    g = gaussian_filter(grid, sigma=sigma, mode="constant")
    peak = float(g.max())
    return g / peak * float(grid.max()) if peak > 0 else g


def encode_sequence(frames: np.ndarray, rng: np.random.Generator, steps_per_frame: int = 8,
                    max_rate: float = 0.5, onset_channels: bool = True,
                    rf_sigma: float = 1.5) -> np.ndarray:
    """(num_inputs, T) uint8 spike raster for a (n_frames, PIC_H, PIC_W) sequence."""
    grids = np.stack([receptive_fields(pool_frame(f), rf_sigma) for f in frames])  # (F, GRID_H, GRID_W)
    F = grids.shape[0]
    T = F * steps_per_frame
    rate = grids.reshape(F, -1)                                  # (F, 960)
    out = np.zeros((num_inputs(onset_channels), T), dtype=np.uint8)
    for f in range(F):
        sl = slice(f * steps_per_frame, (f + 1) * steps_per_frame)
        p = np.clip(rate[f] * max_rate, 0.0, 1.0)
        out[:NUM_RATE_INPUTS, sl] = rng.random((NUM_RATE_INPUTS, steps_per_frame)) < p[:, None]
        if onset_channels and f > 0:
            grew = (rate[f] - rate[f - 1]) > 0.08
            out[NUM_RATE_INPUTS:, f * steps_per_frame] = grew
    return out


def readout_times(n_frames: int, steps_per_frame: int, k: int = 4) -> list[int]:
    """Reservoir steps at which the trace is sampled: the end of k pictures spread
    evenly from the first to the last, so the readout sees the cell's displacement
    over the whole sequence (velocity = difference of decoded positions)."""
    frames = sorted({int(round(f)) for f in np.linspace(1, n_frames, k)})
    return [f * steps_per_frame - 1 for f in frames]
