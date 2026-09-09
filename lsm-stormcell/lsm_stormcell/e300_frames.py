"""E300 radar picture model and synthetic storm cell sequences.

The Ellason E300 delivers a picture to RADARPAS one line at a time as two bit
planes (E300Interface.GetLine in radar/19921228 RADAR MOD/E300INTE.DEF):

    LineNum   0..479 by 2  (each transmitted line paints two screen lines)
    RedBitMap  1280 pixels = 160 bytes
    GrnBitMap  1280 pixels = 160 bytes

so a picture is 240 x 1280 with a 2-bit intensity per pixel, here taken as
level = 2*red + green in {0,1,2,3} (clear, light, moderate, heavy echo).

Geometry follows the RADARPAS Analysis module (ANALYSIS.MOD, DrawMarkers):
screen dx is scaled by CurrRange/256 and dy by CurrRange*48/35/256, i.e. one
E300 range unit spans 256 screen columns and the display has a 48:35 pixel
aspect ratio. We keep those constants so speed/direction estimates are in the
same units the terminal printed.

This module provides:
  * StormCell / StormSequence: moving, growing/decaying Gaussian echoes
  * render_frame(): a 240 x 1280 2-bit E300 picture for a set of cells
  * planes_from_frame() / frame_from_planes(): the red/green bit-plane form
  * pool_frame(): mean-pool a picture down to the reservoir input grid
  * make_sequence(): a random multi-frame storm sequence with labels
"""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

PIC_H, PIC_W = 240, 1280            # E300 picture, lines x pixels
GRID_H, GRID_W = 24, 40             # reservoir input grid (10 x 32 pixel cells)
KM_PER_COL = 100.0 / 256.0          # CurrRange=100 km across 256 screen columns (DrawMarkers)
ASPECT_Y = 48.0 / 35.0              # screen pixel aspect from DrawMarkers
KM_PER_ROW = KM_PER_COL * ASPECT_Y * (PIC_W / 640.0) / (PIC_H / 350.0)  # EGA 640x350 -> picture grid
FRAME_MINUTES = 5.0                 # picture interval
LEVEL_THRESH = (0.18, 0.45, 0.75)   # echo fraction -> level 1, 2, 3


@dataclass
class StormCell:
    x: float                 # km east of the radar (frame origin at left edge)
    y: float                 # km north (frame origin at bottom edge)
    vx: float                # km/h
    vy: float                # km/h
    radius: float            # km, 1-sigma
    peak: float              # 0..1
    growth: float = 0.0      # peak change per frame

    def step(self, rng: np.random.Generator, jitter: float = 0.4):
        dt = FRAME_MINUTES / 60.0
        self.x += self.vx * dt + rng.normal(0, jitter) * dt
        self.y += self.vy * dt + rng.normal(0, jitter) * dt
        self.peak = float(np.clip(self.peak + self.growth, 0.05, 1.0))
        self.radius = float(np.clip(self.radius * (1.0 + 0.02 * self.growth * 10), 2.0, 40.0))


@dataclass
class StormSequence:
    frames: np.ndarray                     # (T, PIC_H, PIC_W) uint8 levels 0..3
    cells: list[list[StormCell]]           # per-frame cell states
    labels: dict = field(default_factory=dict)


def frame_extent_km() -> tuple[float, float]:
    return PIC_W * KM_PER_COL, PIC_H * KM_PER_ROW


def render_frame(cells: list[StormCell], rng: np.random.Generator | None = None,
                 noise: float = 0.02) -> np.ndarray:
    """Quantised E300 picture (PIC_H, PIC_W) for the given cells."""
    wkm, hkm = frame_extent_km()
    xs = (np.arange(PIC_W) + 0.5) * KM_PER_COL
    ys = hkm - (np.arange(PIC_H) + 0.5) * KM_PER_ROW       # row 0 is the top line
    X, Y = np.meshgrid(xs, ys)
    echo = np.zeros((PIC_H, PIC_W), dtype=np.float32)
    for c in cells:
        g = c.peak * np.exp(-((X - c.x) ** 2 + (Y - c.y) ** 2) / (2.0 * c.radius ** 2))
        np.maximum(echo, g, out=echo)
    if rng is not None and noise > 0:
        echo += rng.random(echo.shape).astype(np.float32) * noise
    lvl = np.zeros_like(echo, dtype=np.uint8)
    for k, th in enumerate(LEVEL_THRESH, start=1):
        lvl[echo >= th] = k
    return lvl


def planes_from_frame(frame: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Red and green bit planes packed as bytes, (PIC_H, 160) each, MSB first."""
    red = (frame >> 1) & 1
    grn = frame & 1
    return np.packbits(red, axis=1), np.packbits(grn, axis=1)


def frame_from_planes(red_bytes: np.ndarray, grn_bytes: np.ndarray) -> np.ndarray:
    red = np.unpackbits(red_bytes, axis=1)[:, :PIC_W]
    grn = np.unpackbits(grn_bytes, axis=1)[:, :PIC_W]
    return (2 * red + grn).astype(np.uint8)


def decode_getline_stream(records: list[tuple[int, bytes, bytes]]) -> np.ndarray:
    """Rebuild a picture from (LineNum, RedBitMap, GrnBitMap) tuples as delivered
    by E300Interface.GetLine (LineNum = 0..479 by 2)."""
    red = np.zeros((PIC_H, PIC_W // 8), dtype=np.uint8)
    grn = np.zeros_like(red)
    for line_num, rb, gb in records:
        r = line_num // 2
        if 0 <= r < PIC_H:
            red[r, :len(rb)] = np.frombuffer(rb, dtype=np.uint8)[: PIC_W // 8]
            grn[r, :len(gb)] = np.frombuffer(gb, dtype=np.uint8)[: PIC_W // 8]
    return frame_from_planes(red, grn)


def pool_frame(frame: np.ndarray) -> np.ndarray:
    """Mean-pool a (PIC_H, PIC_W) level picture to (GRID_H, GRID_W) in [0, 1]."""
    bh, bw = PIC_H // GRID_H, PIC_W // GRID_W
    f = frame[: GRID_H * bh, : GRID_W * bw].astype(np.float32) / 3.0
    return f.reshape(GRID_H, bh, GRID_W, bw).mean(axis=(1, 3))


def dominant_cell_state(cells: list[StormCell]) -> StormCell:
    return max(cells, key=lambda c: c.peak * c.radius ** 2)


def speed_dir(vx: float, vy: float) -> tuple[float, float]:
    """Speed (km/h) and direction of motion in degrees clockwise from north,
    matching the ATan(dX/dY) convention in DrawMarkers."""
    speed = float(np.hypot(vx, vy))
    ang = float(np.degrees(np.arctan2(vx, vy))) % 360.0
    return speed, ang


def make_sequence(rng: np.random.Generator, n_frames: int = 10, n_cells: int | None = None,
                  horizon: int = 3, max_cells: int = 1) -> StormSequence:
    """Random storm sequence. Labels describe the dominant cell at the last
    observed frame and its true position `horizon` frames later (the nowcast
    target)."""
    wkm, hkm = frame_extent_km()
    n_cells = n_cells or int(rng.integers(1, max_cells + 1))
    speed = rng.uniform(15.0, 70.0)                     # km/h, shared steering flow
    heading = rng.uniform(0.0, 360.0)
    vx0, vy0 = speed * np.sin(np.radians(heading)), speed * np.cos(np.radians(heading))
    cells = []
    for _ in range(n_cells):
        cells.append(StormCell(
            x=rng.uniform(0.2 * wkm, 0.8 * wkm), y=rng.uniform(0.2 * hkm, 0.8 * hkm),
            vx=vx0 + rng.normal(0, 4.0), vy=vy0 + rng.normal(0, 4.0),
            radius=rng.uniform(4.0, 14.0), peak=rng.uniform(0.5, 1.0),
            growth=rng.normal(0.0, 0.03)))
    frames, states = [], []
    total = n_frames + horizon
    for t in range(total):
        states.append([StormCell(**vars(c)) for c in cells])
        if t < n_frames:
            frames.append(render_frame(cells, rng))
        for c in cells:
            c.step(rng)
    dom_idx = max(range(n_cells), key=lambda i: states[n_frames - 1][i].peak * states[n_frames - 1][i].radius ** 2)
    now = states[n_frames - 1][dom_idx]
    fut = states[n_frames - 1 + horizon][dom_idx]
    spd, ang = speed_dir(now.vx, now.vy)
    labels = dict(x=now.x, y=now.y, vx=now.vx, vy=now.vy, speed=spd, direction=ang,
                  x_future=fut.x, y_future=fut.y, n_cells=n_cells, horizon=horizon,
                  octant=int(((ang + 22.5) % 360) // 45))
    return StormSequence(np.stack(frames), states[:n_frames], labels)
