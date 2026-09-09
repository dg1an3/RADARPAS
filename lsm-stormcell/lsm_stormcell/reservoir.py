"""Liquid state machine reservoir: leaky integrate-and-fire spiking neurons on a
small-world graph.

The neuron model, topology and trace readout follow Ruggero Freddi's
LSM-Robustness implementation (https://github.com/RuggeroFreddi/LSM-Robustness,
"Bridging Theory and Practice in Crafting Robust Spiking Reservoirs"), which in
turn follows Maass, Natschlaeger & Markram (2002). This is an independent
re-implementation of that model with the same dynamics and parameter names:

  * membrane potential  m_i(t+1) = (1 - leak_i) * (m_i(t) + I_in + sum_j W_ji s_j(t))
  * spike when m_i >= membrane_threshold and the neuron is not refractory;
    then m_i := 0 and the neuron is silent for refractory_period steps
  * per-neuron leak drawn log-normally around leak_coefficient (CV 0.5)
  * input spikes inject current_amplitude into the first num_inputs neurons
  * synapses: Watts-Strogatz small-world ring (k = presynaptic_degree * N,
    rewiring probability small_world_p), each undirected edge given one random
    direction, weight ~ Normal(mean_weight, |mean_weight| * weight_cv)
  * liquid state: exponentially decaying spike trace, tau = trace_tau, read at
    chosen times, plus per-neuron spike counts over the last window

Propagation uses a sparse matrix-vector product instead of a Python loop over
spiking neurons, so a 1500-neuron reservoir runs a 100-step sequence in a few
milliseconds.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy.sparse import csr_matrix


@dataclass
class LSMParams:
    num_neurons: int = 1500
    membrane_threshold: float = 2.0
    leak_coefficient: float = 0.002
    refractory_period: int = 2
    current_amplitude: float = 2.0
    presynaptic_degree: float = 0.05      # beta: mean in-degree = beta * N
    small_world_p: float = 0.2            # Watts-Strogatz rewiring probability
    mean_weight: float = 0.02
    weight_cv: float = 0.2                # weight std = |mean| * cv
    trace_tau: float = 8.0
    leak_cv: float = 0.5
    seed: int | None = 42

    def __post_init__(self):
        if not 0 <= self.leak_coefficient < 1:
            raise ValueError("leak_coefficient must be in [0, 1)")
        if self.refractory_period <= 0:
            raise ValueError("refractory_period must be positive")
        if not 0 <= self.small_world_p <= 1:
            raise ValueError("small_world_p must be in [0, 1]")
        if self.trace_tau <= 0:
            raise ValueError("trace_tau must be > 0")


def watts_strogatz_edges(n: int, k: int, p: float, rng: np.random.Generator) -> np.ndarray:
    """Undirected edge list (m, 2) of a Watts-Strogatz ring lattice with rewiring.

    Each node links to its k/2 nearest neighbours on each side of the ring; every
    edge is then rewired to a uniformly random non-self target with probability p
    (duplicates are dropped)."""
    k = max(2, int(k) // 2 * 2)
    src = np.repeat(np.arange(n), k // 2)
    off = np.tile(np.arange(1, k // 2 + 1), n)
    dst = (src + off) % n
    rewire = rng.random(src.size) < p
    dst = dst.copy()
    dst[rewire] = rng.integers(0, n, rewire.sum())
    keep = src != dst
    edges = np.stack([src[keep], dst[keep]], axis=1)
    lo, hi = edges.min(axis=1), edges.max(axis=1)
    return np.unique(np.stack([lo, hi], axis=1), axis=0)


class Reservoir:
    """Spiking reservoir. Inputs occupy neurons [0, num_inputs)."""

    def __init__(self, params: LSMParams, num_inputs: int):
        self.p = params
        self.n = params.num_neurons
        self.num_inputs = num_inputs
        if num_inputs > self.n:
            raise ValueError("num_inputs exceeds num_neurons")
        self.rng = np.random.default_rng(params.seed)
        self.W = self._build_weights()
        self.WT = self.W.T.tocsr()                      # post <- pre for fast matvec
        self.leak_factor = 1.0 - self._leak_vector()
        self.mem0 = self.rng.uniform(0.0, params.membrane_threshold, self.n).astype(np.float32)
        self.trace_decay = np.float32(np.exp(-1.0 / params.trace_tau))
        self.mean_in_degree = float(self.W.getnnz(axis=0).mean())

    # -- construction ---------------------------------------------------------
    def _leak_vector(self) -> np.ndarray:
        m = self.p.leak_coefficient
        if m <= 0:
            return np.zeros(self.n, dtype=np.float32)
        s = m * self.p.leak_cv
        sigma2 = np.log(1.0 + s * s / (m * m))
        mu = np.log(m) - 0.5 * sigma2
        return self.rng.lognormal(mu, np.sqrt(sigma2), self.n).astype(np.float32)

    def _build_weights(self) -> csr_matrix:
        k = max(2, int(round(self.p.presynaptic_degree * self.n)))
        edges = watts_strogatz_edges(self.n, k, self.p.small_world_p, self.rng)
        flip = self.rng.random(edges.shape[0]) < 0.5
        pre = np.where(flip, edges[:, 0], edges[:, 1])
        post = np.where(flip, edges[:, 1], edges[:, 0])
        w = self.rng.normal(self.p.mean_weight, abs(self.p.mean_weight) * self.p.weight_cv,
                            pre.size).astype(np.float32)
        W = csr_matrix((w, (pre, post)), shape=(self.n, self.n), dtype=np.float32)
        W.setdiag(0.0)
        W.eliminate_zeros()
        W.sort_indices()
        return W

    # -- simulation -----------------------------------------------------------
    def simulate(self, input_spikes: np.ndarray, readout_times: list[int] | None = None,
                 count_window: int = 16) -> dict:
        """Run the reservoir on input_spikes (num_inputs, T) of 0/1.

        Returns dict(spikes=(T, N) int8, trace_at={t: trace vector}, counts=(N,)
        spike counts over the last count_window steps, tot_spikes=int). The
        membrane potentials are reset to the same initial state for every call,
        as in Freddi's MEMBRANE_RESET=true setting."""
        inp = np.asarray(input_spikes)
        if inp.ndim != 2 or inp.shape[0] != self.num_inputs:
            raise ValueError(f"input_spikes must be ({self.num_inputs}, T)")
        T = inp.shape[1]
        N, Nin = self.n, self.num_inputs
        thr = np.float32(self.p.membrane_threshold)
        amp = np.float32(self.p.current_amplitude)
        refr_len = self.p.refractory_period + 1
        readout_times = set(readout_times or [T - 1])

        mem = self.mem0.copy()
        refr = np.zeros(N, dtype=np.int32)
        trace = np.zeros(N, dtype=np.float32)
        spikes = np.zeros((T, N), dtype=np.int8)
        trace_at = {}
        tot = 0
        for t in range(T):
            np.maximum(refr - 1, 0, out=refr)
            mem[:Nin] += amp * inp[:, t]
            firing = (mem >= thr) & (refr == 0)
            spikes[t] = firing
            tot += int(firing.sum())
            trace *= self.trace_decay
            trace[firing] += 1.0
            mem[firing] = 0.0
            refr[firing] = refr_len
            mem *= self.leak_factor
            if tot:
                mem += self.WT @ firing.astype(np.float32)
            if t in readout_times:
                trace_at[t] = trace.copy()
        counts = spikes[max(0, T - count_window):].sum(axis=0).astype(np.float32)
        return dict(spikes=spikes, trace_at=trace_at, counts=counts, tot_spikes=tot)

    def liquid_state(self, input_spikes: np.ndarray, readout_times: list[int],
                     count_window: int = 16) -> np.ndarray:
        """Feature vector for a readout: traces at each readout time (hidden
        neurons only) followed by recent spike counts."""
        r = self.simulate(input_spikes, readout_times, count_window)
        hid = slice(self.num_inputs, self.n)
        parts = [r["trace_at"][t][hid] for t in sorted(readout_times)]
        parts.append(r["counts"][hid])
        return np.concatenate(parts)
