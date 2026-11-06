"""Tiny numpy synth used to render the rhythm-sync samples."""
import numpy as np
from scipy import signal

SR = 44100
rng = np.random.default_rng(7)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12)


NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5,
        'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}


def n(name):
    """'A4' -> midi"""
    p, o = name[:-1], int(name[-1])
    return 12 * (o + 1) + NOTE[p]


def t_(dur):
    return np.arange(int(dur * SR)) / SR


def lp(x, fc, order=2):
    b, a = signal.butter(order, min(fc, SR * 0.45) / (SR / 2), 'low')
    return signal.lfilter(b, a, x)


def hp(x, fc, order=2):
    b, a = signal.butter(order, fc / (SR / 2), 'high')
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], 'band')
    return signal.lfilter(b, a, x)


def saw(f, t, detune=0.0):
    ph = (f * (1 + detune) * t + rng.random()) % 1.0
    return 2 * ph - 1


def adsr(t, a, d, s, r, length):
    e = np.ones_like(t) * s
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / d
    m = t >= length
    e[m] = s * np.exp(-(t[m] - length) / max(r, 1e-3))
    return e


# ---------------- instruments ----------------

def kick(v=1.0):
    t = t_(0.5)
    f = 48 + 110 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    body = np.sin(ph) * np.exp(-t * 7)
    click = hp(rng.standard_normal(len(t)), 2000) * np.exp(-t * 300) * 0.3
    return v * np.tanh(1.6 * (body + click))


def snare(v=1.0):
    t = t_(0.35)
    noise = bp(rng.standard_normal(len(t)), 1200, 7000) * np.exp(-t * 16)
    tone = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 25)
    return v * (0.55 * noise + 0.5 * tone)


def clap(v=1.0):
    t = t_(0.4)
    e = np.zeros_like(t)
    for d in (0, 0.011, 0.022):
        m = t >= d
        e[m] += np.exp(-(t[m] - d) * 90)
    e += 0.6 * np.exp(-t * 14)
    return v * bp(rng.standard_normal(len(t)), 900, 5000) * e * 0.6


def hat(v=1.0, open_=False):
    t = t_(0.3 if open_ else 0.08)
    x = hp(rng.standard_normal(len(t)), 7500, 3) * np.exp(-t * (12 if open_ else 60))
    return v * x * 0.5


def bass(m, dur, v=1.0, cut=900):
    t = t_(dur + 0.3)
    f = mtof(m)
    x = 0.6 * saw(f, t) + 0.6 * saw(f, t, 0.004) + 0.7 * np.sin(2 * np.pi * f / 2 * t)
    fenv = cut * (0.35 + 0.65 * np.exp(-t * 9))
    # crude time-varying LP via two fixed filters crossfaded
    y = lp(x, cut) * np.exp(-t * 2) + lp(x, cut * 0.35) * (1 - np.exp(-t * 2))
    return v * y * adsr(t, 0.004, 0.08, 0.8, 0.05, dur) * 0.5


def pad(ms, dur, v=1.0, cut=1800):
    t = t_(dur + 3.0)
    x = np.zeros_like(t)
    for m in ms:
        f = mtof(m)
        for d in (-0.006, 0.0, 0.0065):
            x += saw(f, t, d)
    x = lp(x, cut, 2) / (3 * len(ms))
    return v * x * adsr(t, 0.35, 0.3, 0.8, 0.9, dur)


def pluck(m, v=1.0, bright=1.0, dur=0.35):
    """muted synth pluck (enemy 'call')"""
    t = t_(dur + 0.4)
    f = mtof(m)
    x = saw(f, t) + 0.5 * np.sin(2 * np.pi * f * t)
    y = lp(x, 900 + 2600 * bright) * np.exp(-t * 9)
    return v * y * 0.45


def bell(m, v=1.0, ratio=3.5, index=3.2, decay=2.2, dur=2.2):
    """FM bell - icy / crystalline"""
    t = t_(dur)
    f = mtof(m)
    I = index * np.exp(-t * 6) + 0.4
    mod = I * np.sin(2 * np.pi * f * ratio * t)
    x = np.sin(2 * np.pi * f * t + mod)
    x += 0.25 * np.sin(2 * np.pi * 2 * f * t + 0.5 * mod) * np.exp(-t * 4)
    att = np.minimum(1, t / 0.002)
    return v * x * np.exp(-t * decay) * att * 0.5


def ice_hit(m, v=1.0):
    """glassy ting + tiny shimmer noise"""
    x = bell(m, 1.0, ratio=3.5, index=2.6, decay=2.6, dur=1.6)
    x[:len(x)] += 0.35 * bell(m + 12, 1.0, ratio=1.41, index=1.2, decay=5, dur=1.6)
    t = t_(1.6)
    x += bp(rng.standard_normal(len(t)), 5000, 12000) * np.exp(-t * 45) * 0.08
    return v * x * 0.8


def fire_hit(m, v=1.0):
    """warm brassy pluck + low thump + crackle"""
    t = t_(1.2)
    f = mtof(m)
    x = saw(f, t) + saw(f, t, 0.005) + 0.6 * saw(f / 2, t)
    cut_hi = lp(x, 4200) * np.exp(-t * 10)
    cut_lo = lp(x, 900) * (1 - np.exp(-t * 10))
    tone = (cut_hi + cut_lo) * np.exp(-t * 3.2) * 0.32
    ft = 70 + 90 * np.exp(-t * 30)
    thump = np.sin(2 * np.pi * np.cumsum(ft) / SR) * np.exp(-t * 14) * 0.6
    crack = bp(rng.standard_normal(len(t)), 2500, 9000) * np.exp(-t * 35) * 0.25
    return v * np.tanh(1.3 * (tone + thump + crack))


def boom(m, v=1.0):
    """taiko-ish fire drum, tuned to midi m"""
    t = t_(0.9)
    f0 = mtof(m)
    f = f0 * (1 + 0.8 * np.exp(-t * 25))
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 6)
    body2 = np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR) * np.exp(-t * 9) * 0.3
    skin = bp(rng.standard_normal(len(t)), 150, 1500) * np.exp(-t * 40) * 0.6
    crack = bp(rng.standard_normal(len(t)), 3000, 9000) * np.exp(-t * 50) * 0.2
    return v * np.tanh(1.8 * (body + body2 + skin + crack)) * 0.9


def ting(m, v=1.0):
    """bright metallic ice tick"""
    t = t_(0.8)
    f = mtof(m)
    x = np.zeros_like(t)
    for k, a, d in ((1, 1, 9), (2.76, 0.5, 14), (5.4, 0.3, 20), (8.93, 0.2, 28)):
        x += a * np.sin(2 * np.pi * f * k * t) * np.exp(-t * d)
    x += hp(rng.standard_normal(len(t)), 6000) * np.exp(-t * 60) * 0.4
    return v * x * 0.35


def thud(v=1.0):
    """dull 'miss' sound"""
    t = t_(0.5)
    f = 55 + 40 * np.exp(-t * 20)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    x += lp(rng.standard_normal(len(t)), 400) * np.exp(-t * 18) * 0.8
    return v * np.tanh(2 * x) * 0.8


def riser(dur, v=1.0):
    t = t_(dur)
    x = hp(rng.standard_normal(len(t)), 2000) * (t / dur) ** 2
    return v * x * 0.2


# ---------------- mixing ----------------

class Mix:
    def __init__(self, dur):
        self.L = np.zeros(int(dur * SR) + SR * 4)
        self.R = np.zeros_like(self.L)
        self.dur = dur

    def add(self, x, at, pan=0.0, gain=1.0):
        k = min(int(0.008 * SR), x.shape[-1])
        x = x.copy()
        x[..., -k:] *= np.linspace(1, 0, k)
        if x.ndim == 2:  # already stereo
            l, r = x[0], x[1]
        else:
            a = (pan + 1) * np.pi / 4
            l, r = x * np.cos(a) * 1.414, x * np.sin(a) * 1.414
        i = int(round(at * SR))
        if i < 0:
            l, r, i = l[-i:], r[-i:], 0
        k = min(len(l), len(self.L) - i)
        if k <= 0:
            return
        self.L[i:i + k] += gain * l[:k]
        self.R[i:i + k] += gain * r[:k]

    def stereo(self):
        return np.stack([self.L, self.R])


def reverb(st, wet=0.22, length=2.2, tone=5000):
    t = t_(length)
    out = []
    for ch in range(2):
        ir = rng.standard_normal(len(t)) * np.exp(-t * 3.2 / length * 2)
        ir = lp(ir, tone)
        ir[: int(0.012 * SR)] = 0
        ir /= np.sqrt((ir ** 2).sum())
        out.append(signal.fftconvolve(st[ch], ir)[: st.shape[1]])
    return st + wet * np.stack(out)


def duck(st, kick_times, depth=0.55, rel=0.16):
    g = np.ones(st.shape[1])
    tt = np.arange(st.shape[1]) / SR
    for k in kick_times:
        i = int(k * SR)
        j = min(len(g), i + int(rel * 5 * SR))
        g[i:j] = np.minimum(g[i:j], 1 - depth * np.exp(-(tt[i:j] - k) / rel))
    return st * g


def sweep_lp(st, cutoff_fn, block=256):
    """time-varying low-pass; cutoff_fn(t)->Hz"""
    out = np.zeros_like(st)
    zi = [np.zeros(2), np.zeros(2)]
    for s in range(0, st.shape[1], block):
        fc = cutoff_fn(s / SR)
        if fc >= 18000:
            out[:, s:s + block] = st[:, s:s + block]
            zi = [np.zeros(2), np.zeros(2)]
            continue
        b, a = signal.butter(2, fc / (SR / 2), 'low')
        for ch in range(2):
            if not zi[ch].any():
                zi[ch] = signal.lfilter_zi(b, a) * st[ch, s]
            out[ch, s:s + block], zi[ch] = signal.lfilter(b, a, st[ch, s:s + block], zi=zi[ch])
    return out


def master(st, dur, fade_in=0.02, fade_out=1.5, target=-14.0):
    st = np.stack([hp(c, 28) for c in st[:, : int(dur * SR)]])
    t = np.arange(st.shape[1]) / SR
    g = np.minimum(1, t / max(fade_in, 1e-3)) * np.clip((dur - t) / fade_out, 0, 1)
    st = st * g
    rms = np.sqrt((st ** 2).mean())
    st = st * (10 ** (target / 20) / max(rms, 1e-9))
    st = np.tanh(st * 1.1) / np.tanh(1.1)
    pk = np.abs(st).max()
    if pk > 0.97:
        st *= 0.97 / pk
    return st
