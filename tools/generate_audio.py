#!/usr/bin/env python3
"""Procedurally generates every sound and music track used by Frostwood.

Run:  python3 tools/generate_audio.py
Needs numpy + scipy, and ffmpeg (libvorbis) for the .ogg music/ambience loops.
Output goes to assets/audio/.
"""
import os
import subprocess
import wave

import numpy as np
from scipy import signal

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
rng = np.random.default_rng(1337)


# ---------------------------------------------------------------- helpers
def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def note_hz(name):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
             "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    midi = 12 * (octave + 1) + names[pitch]
    return 440.0 * 2 ** ((midi - 69) / 12)


def env_adsr(n, a, d, s, r, sr=SR):
    a, d, r = int(a * sr), int(d * sr), int(r * sr)
    sus = max(n - a - d - r, 0)
    e = np.concatenate([
        np.linspace(0, 1, a, endpoint=False),
        np.linspace(1, s, d, endpoint=False),
        np.full(sus, s),
        np.linspace(s, 0, r),
    ])
    if len(e) < n:
        e = np.pad(e, (0, n - len(e)))
    return e[:n]


def exp_decay(n, tau, sr=SR):
    return np.exp(-np.arange(n) / (tau * sr))


def lowpass(x, fc, order=2, sr=SR):
    b, a = signal.butter(order, min(fc / (sr / 2), 0.99), "low")
    return signal.lfilter(b, a, x)


def highpass(x, fc, order=2, sr=SR):
    b, a = signal.butter(order, max(fc / (sr / 2), 0.0001), "high")
    return signal.lfilter(b, a, x)


def bandpass(x, lo, hi, order=2, sr=SR):
    b, a = signal.butter(order, [lo / (sr / 2), min(hi / (sr / 2), 0.99)], "band")
    return signal.lfilter(b, a, x)


def noise(n):
    return rng.uniform(-1, 1, n)


def brown_noise(n):
    w = rng.normal(0, 1, n)
    b = np.cumsum(w)
    b = highpass(b, 15)
    return b / (np.max(np.abs(b)) + 1e-9)


def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def fade(x, fin=0.003, fout=0.02, sr=SR):
    x = x.copy()
    a, b = int(fin * sr), int(fout * sr)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def reverb_ir(dur, decay, sr=SR, bright=6000, stereo_seed=0):
    n = int(dur * sr)
    r = np.random.default_rng(99 + stereo_seed)
    ir = r.normal(0, 1, n) * np.exp(-np.arange(n) / (decay * sr))
    ir = lowpass(ir, bright)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def add_reverb(x, wet=0.3, dur=2.5, decay=0.8, circular=False):
    ir = reverb_ir(dur, decay)
    if circular:
        n = len(x)
        irp = np.zeros(n)
        irp[:min(n, len(ir))] = ir[:n]
        y = np.real(np.fft.ifft(np.fft.fft(x) * np.fft.fft(irp)))
        return x * (1 - wet) + y * wet
    y = signal.fftconvolve(x, ir)[: len(x) + len(ir) - 1]
    xx = np.pad(x, (0, len(y) - len(x)))
    return xx * (1 - wet) + y * wet


def write_wav(name, x, sr=SR):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    return path


def write_ogg(name, x, sr=SR, quality=5):
    tmp = write_wav("_tmp_" + name, x, sr)
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis",
                    "-q:a", str(quality), dst], check=True)
    os.remove(tmp)


# ---------------------------------------------------------------- instruments
def karplus(freq, dur, bright=0.5, decay=0.996, sr=SR):
    """Plucked string (kantele-like) via Karplus-Strong."""
    n = int(dur * sr)
    period = int(sr / freq)
    buf = lowpass(rng.uniform(-1, 1, period), 1500 + bright * 6000)
    out = np.zeros(n)
    buf = list(buf)
    idx = 0
    for i in range(n):
        nxt = (idx + 1) % period
        v = decay * 0.5 * (buf[idx] + buf[nxt])
        out[i] = buf[idx]
        buf[idx] = v
        idx = nxt
    out = out * env_adsr(n, 0.002, 0.05, 1.0, 0.3)
    # body resonance
    body = bandpass(out, 180, 2500)
    return normalize(out * 0.6 + body * 0.4, 1.0)


def soft_pad(freqs, dur, attack=1.2, release=1.5, sr=SR):
    t = t_axis(dur, sr)
    x = np.zeros_like(t)
    for f in freqs:
        for det in (-0.25, 0.0, 0.3):
            ff = f * 2 ** (det / 12 / 4)
            ph = rng.uniform(0, 2 * np.pi)
            x += np.sin(2 * np.pi * ff * t + ph)
            x += 0.35 * np.sin(2 * np.pi * 2 * ff * t + ph)
            x += 0.12 * np.sin(2 * np.pi * 3 * ff * t + ph)
    x *= env_adsr(len(t), attack, 0.5, 0.85, release)
    return x / (len(freqs) * 4)


def flute(freq, dur, sr=SR):
    t = t_axis(dur, sr)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.4, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vib) / sr
    x = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    breath = bandpass(noise(len(t)), freq, freq * 4) * 0.15
    x = (x + breath) * env_adsr(len(t), 0.12, 0.2, 0.8, 0.35)
    return x


def horn(freq, dur, sr=SR):
    """Lur / birch-bark horn."""
    t = t_axis(dur, sr)
    bend = freq * (1 - 0.03 * np.exp(-t / 0.15))
    ph = 2 * np.pi * np.cumsum(bend) / sr
    x = signal.sawtooth(ph) * 0.6 + np.sin(ph)
    x = lowpass(x, 900)
    x *= env_adsr(len(t), 0.25, 0.3, 0.8, 0.8)
    return x


def frame_drum(dur=0.7, sr=SR):
    t = t_axis(dur, sr)
    f = 70 + 50 * np.exp(-t / 0.03)
    ph = 2 * np.pi * np.cumsum(f) / sr
    body = np.sin(ph) * exp_decay(len(t), 0.18)
    skin = lowpass(noise(len(t)), 1800) * exp_decay(len(t), 0.02) * 0.4
    return body + skin


def place(buf, x, start_s, gain=1.0, circular=True):
    s = int(start_s * SR)
    n = len(x)
    if circular:
        idx = (np.arange(n) + s) % len(buf)
        np.add.at(buf, idx, x * gain)
    else:
        e = min(len(buf), s + n)
        buf[s:e] += x[: e - s] * gain


# ---------------------------------------------------------------- music
def compose(kind):
    bpm = {"menu": 66, "day": 76, "night": 56}[kind]
    beat = 60 / bpm
    bar = beat * 4
    bars = 16
    total = bar * bars
    buf = np.zeros(int(total * SR))

    if kind == "night":
        prog = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A"] * 2
    elif kind == "day":
        prog = ["Dm", "C", "Bb", "C", "Dm", "F", "C", "Dm",
                "Bb", "F", "Gm", "A", "Dm", "C", "Bb", "Dm"]
    else:
        prog = ["Dm", "Bb", "F", "C", "Dm", "Gm", "Bb", "A"] * 2

    chords = {
        "Dm": ["D3", "A3", "D4", "F4"], "Bb": ["Bb2", "F3", "Bb3", "D4"],
        "F": ["F2", "C3", "A3", "C4"], "C": ["C3", "G3", "C4", "E4"],
        "Gm": ["G2", "D3", "G3", "Bb3"], "A": ["A2", "E3", "A3", "C#4"],
    }
    # chord pads
    for i, ch in enumerate(prog):
        pad = soft_pad([note_hz(n) for n in chords[ch]], bar + 1.6,
                       attack=1.0 if kind != "night" else 1.8, release=1.6)
        place(buf, pad, i * bar, 0.55 if kind != "night" else 0.5)

    # drone on D + A
    t = np.arange(len(buf)) / SR
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * t / total * 4)
    drone = (np.sin(2 * np.pi * note_hz("D2") * t) * 0.6 +
             np.sin(2 * np.pi * note_hz("A2") * t) * 0.3 +
             np.sin(2 * np.pi * note_hz("D3") * t + 1) * 0.15) * swell
    buf += drone * (0.16 if kind != "night" else 0.22)

    # melody on D minor pentatonic
    scale = ["D4", "F4", "G4", "A4", "C5", "D5", "F5", "G5", "A5"]
    chord_tone_idx = {"Dm": [0, 3, 5], "Bb": [1, 5, 6], "F": [1, 4, 6], "C": [4, 2, 7],
                      "Gm": [2, 6, 1], "A": [3, 8, 5]}
    mrng = np.random.default_rng({"menu": 7, "day": 21, "night": 3}[kind])
    pos = 3
    for i, ch in enumerate(prog):
        if kind == "night" and i % 2 == 1 and mrng.random() < 0.5:
            continue
        if kind == "menu" and i in (0, 8):
            continue  # breathing room
        steps = 8
        step_len = bar / steps
        density = {"menu": 0.42, "day": 0.55, "night": 0.22}[kind]
        for s in range(steps):
            if s == 0:
                pos = int(mrng.choice(chord_tone_idx[ch]))
            elif mrng.random() > density:
                continue
            else:
                pos = int(np.clip(pos + mrng.choice([-2, -1, -1, 1, 1, 2]), 0, len(scale) - 1))
            f = note_hz(scale[pos])
            start = i * bar + s * step_len
            if kind == "day":
                n = karplus(f, 2.2, bright=0.6)
                place(buf, n, start, 0.30)
            elif kind == "menu":
                n = karplus(f, 2.8, bright=0.45, decay=0.997)
                place(buf, n, start, 0.30)
            else:
                n = karplus(f * 2 if mrng.random() < 0.3 else f, 3.0, bright=0.3, decay=0.998)
                place(buf, n, start, 0.22)

    # flute / horn phrases
    if kind == "menu":
        for start_bar, notes in [(4, ["A4", "C5", "D5", "C5", "A4"]),
                                 (12, ["D5", "F5", "G5", "F5", "D5", "C5", "D5"])]:
            tpos = start_bar * bar
            for k, nn in enumerate(notes):
                d = beat * (1.5 if k == len(notes) - 1 else 0.75)
                place(buf, flute(note_hz(nn), d + 0.3), tpos, 0.22)
                tpos += d
    if kind == "night":
        for start_bar in (2, 10):
            place(buf, horn(note_hz("D3"), bar * 1.2), start_bar * bar, 0.25)
            place(buf, horn(note_hz("A3"), bar * 0.8), start_bar * bar + bar * 0.6, 0.15)
    if kind == "day":
        drum = frame_drum()
        for i in range(bars):
            if i < 2:
                continue
            for b in (0, 2.5, 3) if i % 4 == 3 else (0, 2):
                place(buf, drum, i * bar + b * beat, 0.35)
        for start_bar, notes in [(8, ["D5", "C5", "A4", "G4", "A4"])]:
            tpos = start_bar * bar
            for k, nn in enumerate(notes):
                d = beat * (2 if k == len(notes) - 1 else 1)
                place(buf, flute(note_hz(nn), d + 0.3), tpos, 0.18)
                tpos += d

    # wind bed for atmosphere
    wind = lowpass(brown_noise(len(buf)), 700) * (0.5 + 0.5 * np.sin(2 * np.pi * t / total * 3))
    buf += wind * 0.05

    buf = add_reverb(buf, wet=0.38, dur=3.5, decay=1.2, circular=True)
    buf = highpass(buf, 30)
    return normalize(buf, 0.8)


# ---------------------------------------------------------------- ambience
def loop_noise(dur, fn):
    """Make a seamlessly looping noise texture by cross-fading the ends."""
    n = int(dur * SR)
    xf = int(1.0 * SR)
    x = fn(n + xf)
    w = np.linspace(0, 1, xf)
    x[:xf] = x[:xf] * w + x[n:n + xf] * (1 - w)
    return x[:n]


def wind_loop():
    def gen(n):
        b = brown_noise(n)
        t = np.arange(n) / SR
        lfo = 0.55 + 0.3 * np.sin(2 * np.pi * t / 7.3) + 0.15 * np.sin(2 * np.pi * t / 3.1 + 1)
        low = lowpass(b, 500) * lfo
        gust = bandpass(noise(n), 500, 1800) * np.clip(np.sin(2 * np.pi * t / 11 + 2), 0, 1) ** 3 * 0.18
        whistle = bandpass(noise(n), 900, 1000, order=2) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 5.7)) * 0.6
        return low + gust + whistle
    return normalize(loop_noise(24, gen), 0.7)


def bird_chirp():
    d = rng.uniform(0.08, 0.18)
    t = t_axis(d)
    f0 = rng.uniform(2800, 4200)
    f = f0 + rng.uniform(-900, 900) * np.sin(np.pi * t / d)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.sin(np.pi * t / d) ** 2


def forest_day_loop():
    n = int(30 * SR)
    buf = np.zeros(n)
    # sparse birdsong phrases
    for _ in range(16):
        start = rng.uniform(0, 30)
        reps = rng.integers(2, 6)
        gap = rng.uniform(0.1, 0.22)
        g = rng.uniform(0.15, 0.4)
        for r in range(reps):
            place(buf, bird_chirp(), start + r * gap, g)
    # woodpecker once
    for k in range(10):
        click = bandpass(noise(int(0.012 * SR)), 900, 2600) * exp_decay(int(0.012 * SR), 0.003)
        place(buf, click, 17 + k * 0.055, 0.6)
    buf = add_reverb(buf, wet=0.45, dur=2.0, decay=0.6, circular=True)
    return normalize(buf, 0.5)


def fire_loop():
    def gen(n):
        rumble = lowpass(brown_noise(n), 300) * 0.5
        hiss = bandpass(noise(n), 2000, 7000) * 0.05
        crack = np.zeros(n)
        for _ in range(int(n / SR * 14)):
            p = rng.integers(0, n - 2000)
            ln = rng.integers(80, 900)
            crack[p:p + ln] += noise(ln) * exp_decay(ln, 0.002) * rng.uniform(0.2, 1)
        crack = highpass(crack, 900)
        return rumble + hiss + crack
    return normalize(loop_noise(6, gen), 0.8)


# ---------------------------------------------------------------- sfx
def sfx_chop():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * (110 + 60 * np.exp(-t / 0.02)) * t) * exp_decay(n, 0.06)
    wood = bandpass(noise(n), 300, 1400) * exp_decay(n, 0.04)
    ring = np.sin(2 * np.pi * 420 * t) * exp_decay(n, 0.05) * 0.4
    crack = highpass(noise(n), 2500) * exp_decay(n, 0.006) * 0.6
    return fade(normalize(thump + wood + ring + crack))


def sfx_mine():
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    x = sum(a * np.sin(2 * np.pi * f * t) * exp_decay(n, d) for f, a, d in
            [(1250, 1, 0.12), (2730, 0.6, 0.07), (3950, 0.4, 0.05), (5300, 0.2, 0.03)])
    click = highpass(noise(n), 3000) * exp_decay(n, 0.004)
    thud = lowpass(noise(n), 400) * exp_decay(n, 0.03) * 2
    return fade(normalize(x * 0.5 + click + thud))


def sfx_swing():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    x = noise(n)
    sweep = np.zeros(n)
    # time-varying bandpass by chunked filtering
    chunks = 10
    for c in range(chunks):
        a, b = c * n // chunks, (c + 1) * n // chunks
        fc = 600 + 2400 * np.sin(np.pi * c / chunks)
        sweep[a:b] = bandpass(x, fc * 0.7, fc * 1.3)[a:b]
    return fade(normalize(sweep * np.sin(np.pi * t / t[-1]) ** 2, 0.6), 0.01, 0.05)


def sfx_bow():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 190 - 40 * (t / t[-1])
    ph = 2 * np.pi * np.cumsum(f) / SR
    twang = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * signal.sawtooth(3 * ph)) * exp_decay(n, 0.09)
    snap = highpass(noise(n), 1500) * exp_decay(n, 0.008)
    whoosh = bandpass(noise(n), 1200, 4000) * np.sin(np.pi * np.clip(t / 0.3, 0, 1)) * 0.25
    return fade(normalize(twang * 0.7 + snap + whoosh))


def sfx_arrow_hit():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    thunk = np.sin(2 * np.pi * (160 + 200 * np.exp(-t / 0.01)) * t) * exp_decay(n, 0.04)
    wobble = np.sin(2 * np.pi * 38 * t) * np.sin(2 * np.pi * 900 * t) * exp_decay(n, 0.08) * 0.3
    return fade(normalize(thunk + wobble + lowpass(noise(n), 1200) * exp_decay(n, 0.01)))


def sfx_step(seed):
    r = np.random.default_rng(seed)
    n = int(0.16 * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    # snow crunch = many tiny grains
    for _ in range(60):
        p = r.integers(0, int(n * 0.8))
        ln = r.integers(20, 160)
        g = r.uniform(0.2, 1) * np.exp(-p / (0.05 * SR))
        x[p:p + ln] += r.uniform(-1, 1, ln) * g
    x = bandpass(x, 700, 6500)
    body = lowpass(r.uniform(-1, 1, n), 350) * exp_decay(n, 0.03) * 0.7
    return fade(normalize((x + body) * np.clip(t / 0.01, 0, 1), 0.7))


def sfx_pickup():
    out = []
    for f, d in ((880, 0.07), (1318, 0.12)):
        t = t_axis(d)
        out.append((np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * exp_decay(len(t), d / 2.5))
    return fade(normalize(add_reverb(np.concatenate(out), 0.2, 0.6, 0.15), 0.5))


def sfx_eat():
    n = int(0.6 * SR)
    x = np.zeros(n)
    for k in range(3):
        p = int((0.05 + k * 0.17) * SR)
        ln = int(0.09 * SR)
        x[p:p + ln] += bandpass(noise(ln), 800, 5000) * exp_decay(ln, 0.025)
    return fade(normalize(x, 0.6))


def sfx_craft():
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k in range(3):
        p = int(k * 0.14 * SR)
        ln = int(0.12 * SR)
        x[p:p + ln] += sfx_chop()[:ln] * 0.6
    tc = t_axis(0.6)
    chime = sum(np.sin(2 * np.pi * f * tc) for f in (1046, 1568, 2093)) * exp_decay(len(tc), 0.2)
    place(x, chime * 0.25, 0.35, circular=False)
    return fade(normalize(add_reverb(x, 0.2, 0.8, 0.2)[:n]))


def sfx_hurt():
    n = int(0.4 * SR)
    t = np.arange(n) / SR
    f = 220 * np.exp(-t / 0.5)
    ph = 2 * np.pi * np.cumsum(f) / SR
    grunt = bandpass(signal.sawtooth(ph), 300, 1500) * env_adsr(n, 0.01, 0.1, 0.6, 0.2)
    thud = np.sin(2 * np.pi * 80 * t) * exp_decay(n, 0.05)
    return fade(normalize(grunt * 0.7 + thud))


def sfx_howl():
    d = 3.2
    t = t_axis(d)
    f = np.interp(t, [0, 0.5, 2.2, 3.2], [380, 620, 600, 360])
    f = f * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + 0.3 * np.sin(2 * ph) + 0.1 * np.sin(3 * ph)
    x += bandpass(noise(len(t)), 500, 1500) * 0.08
    x *= env_adsr(len(t), 0.4, 0.3, 0.8, 1.2)
    return normalize(add_reverb(x, 0.5, 3.0, 1.0), 0.8)


def sfx_growl():
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    am = 0.5 + 0.5 * np.sin(2 * np.pi * 28 * t)
    g = lowpass(noise(n), 600) * am * env_adsr(n, 0.05, 0.1, 0.8, 0.2)
    snap = highpass(noise(n), 2000) * exp_decay(n, 0.01) * np.roll(np.r_[np.zeros(int(0.45 * SR)), np.ones(n - int(0.45 * SR))], 0)
    return fade(normalize(g + snap * 0.8))


def sfx_animal_die():
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    f = 500 * np.exp(-t / 0.3)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = bandpass(signal.sawtooth(ph), 300, 2500) * env_adsr(n, 0.01, 0.1, 0.5, 0.25)
    return fade(normalize(x + lowpass(noise(n), 300) * exp_decay(n, 0.05), 0.7))


def sfx_tree_fall():
    """Wood fibres creak and snap, branches whoosh down, then a heavy thud muffled by snow.
    The impact lands at ~0.95 s to match the in-game falling animation."""
    r = np.random.default_rng(77)
    d = 2.8
    n = int(d * SR)
    x = np.zeros(n)

    # 1) creak: stick-slip friction. Irregular impulses excite wooden body resonances.
    cn = int(0.95 * SR)
    imp = np.zeros(cn)
    tpos = 0.02
    while tpos < 0.9:
        rate = 18 + 30 * (tpos / 0.9) ** 1.5          # friction speeds up as the trunk gives way
        tpos += (1.0 / rate) * r.uniform(0.6, 1.4)
        i = int(tpos * SR)
        if i < cn:
            imp[i] += r.uniform(0.4, 1.0)
    body = np.zeros(cn)
    for f, q, g in ((340, 18, 1.0), (610, 14, 0.7), (1150, 10, 0.45), (2100, 8, 0.25)):
        b, a = signal.iirpeak(f / (SR / 2), q)
        body += signal.lfilter(b, a, imp) * g
    ct = np.arange(cn) / SR
    creak_env = np.clip(ct / 0.25, 0, 1) * (0.5 + 0.5 * ct / 0.95)
    x[:cn] += normalize(lowpass(body, 2400, order=4)) * creak_env * 0.5
    # a couple of sharp fibre snaps
    for st in (0.62, 0.81, 0.9):
        ln = int(0.03 * SR)
        snap = highpass(r.uniform(-1, 1, ln), 1800) * exp_decay(ln, 0.006)
        place(x, snap * 0.25, st, circular=False)

    # 2) whoosh of the crown sweeping through the air, plus needle rustle
    wn = int(0.55 * SR)
    wt = np.arange(wn) / SR
    w = r.uniform(-1, 1, wn)
    sweep = np.zeros(wn)
    for c in range(12):
        a0, a1 = c * wn // 12, (c + 1) * wn // 12
        fc = 350 + 1300 * (c / 11) ** 1.5
        sweep[a0:a1] = bandpass(w, fc * 0.6, fc * 1.5)[a0:a1]
    rustle = highpass(r.uniform(-1, 1, wn), 3500) * (r.uniform(0, 1, wn) > 0.985) * 3
    whoosh = (sweep + rustle * 0.3) * (wt / wt[-1]) ** 2
    place(x, normalize(whoosh) * 0.35, 0.42, circular=False)

    # 3) impact into deep snow at 0.95 s
    p0 = int(0.95 * SR)
    ln = n - p0
    it = np.arange(ln) / SR
    f = 42 + 40 * np.exp(-it / 0.05)
    thud = np.sin(2 * np.pi * np.cumsum(f) / SR) * exp_decay(ln, 0.28) * 0.5
    poof = lowpass(r.uniform(-1, 1, ln), 450, order=4) * exp_decay(ln, 0.3) * 0.9
    crunch = np.zeros(ln)
    for _ in range(70):
        q = int(abs(r.normal(0, 0.12)) * SR)
        k = r.integers(40, 300)
        if q + k < ln:
            crunch[q:q + k] += r.uniform(-1, 1, k) * exp_decay(k, 0.002) * r.uniform(0.2, 1)
    crunch = bandpass(crunch, 700, 3500) * 0.15
    settle = bandpass(r.uniform(-1, 1, ln), 2500, 9000) * np.clip(it / 0.15, 0, 1) * exp_decay(ln, 0.5) * 0.04
    x[p0:] += thud + poof + crunch + settle
    return fade(normalize(add_reverb(x, 0.22, 1.6, 0.45)[:n], 0.9), 0.002, 0.2)


def sfx_level_up():
    x = np.zeros(int(2.2 * SR))
    for k, nn in enumerate(("D4", "F4", "A4", "D5", "F5")):
        place(x, karplus(note_hz(nn), 1.8, bright=0.6), k * 0.09, 0.5, circular=False)
    tc = t_axis(1.6)
    shimmer = sum(np.sin(2 * np.pi * f * tc) * a for f, a in ((1175, 0.5), (1760, 0.35), (2349, 0.2)))
    shimmer *= env_adsr(len(tc), 0.25, 0.3, 0.6, 0.9)
    place(x, shimmer * 0.25, 0.4, circular=False)
    return fade(normalize(add_reverb(x, 0.35, 2.0, 0.6)[:len(x)], 0.75))


def sfx_waypoint():
    t = t_axis(0.5)
    x = np.sin(2 * np.pi * 1320 * t) * exp_decay(len(t), 0.12) + 0.5 * np.sin(2 * np.pi * 1980 * t) * exp_decay(len(t), 0.08)
    return fade(normalize(add_reverb(x, 0.3, 0.8, 0.25)[:len(t)], 0.5))


def sfx_page():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    x = bandpass(noise(n), 1500, 7000) * np.sin(np.pi * t / t[-1]) ** 3
    return fade(normalize(x, 0.4))


def sfx_place():
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * (90 + 80 * np.exp(-t / 0.02)) * t) * exp_decay(n, 0.07)
    x += lowpass(noise(n), 2000) * exp_decay(n, 0.03) * 0.6
    return fade(normalize(x))


def sfx_ui_hover():
    t = t_axis(0.05)
    x = np.sin(2 * np.pi * 1400 * t) * exp_decay(len(t), 0.012)
    return fade(normalize(x, 0.35), 0.001, 0.01)


def sfx_ui_click():
    t = t_axis(0.12)
    x = np.sin(2 * np.pi * 700 * t) * exp_decay(len(t), 0.03) + \
        0.6 * np.sin(2 * np.pi * 1050 * t) * exp_decay(len(t), 0.02)
    x += highpass(noise(len(t)), 3000) * exp_decay(len(t), 0.003) * 0.4
    return fade(normalize(x, 0.5))


def sfx_dawn():
    x = np.zeros(int(4.5 * SR))
    place(x, horn(note_hz("D3"), 2.0), 0, 0.6, circular=False)
    place(x, horn(note_hz("A3"), 2.6), 1.2, 0.5, circular=False)
    place(x, horn(note_hz("D4"), 1.8), 2.4, 0.4, circular=False)
    return normalize(add_reverb(x, 0.45, 3.0, 1.0), 0.7)


def sfx_game_over():
    x = np.zeros(int(6 * SR))
    pad = soft_pad([note_hz(n) for n in ("D2", "A2", "D3", "F3")], 5.0, 0.3, 2.5)
    place(x, pad, 0, 1.0, circular=False)
    for k, nn in enumerate(("A4", "F4", "D4")):
        place(x, karplus(note_hz(nn), 2.5, 0.3), 0.3 + k * 0.6, 0.4, circular=False)
    return normalize(add_reverb(x, 0.45, 3.0, 1.2), 0.75)


def sfx_ignite():
    n = int(0.8 * SR)
    t = np.arange(n) / SR
    whoosh = lowpass(noise(n), 1500) * np.clip(t / 0.15, 0, 1) * exp_decay(n, 0.25)
    return fade(normalize(whoosh + fire_loop()[:n] * 0.4))


SFX = {
    "chop": sfx_chop, "mine": sfx_mine, "swing": sfx_swing, "bow": sfx_bow,
    "arrow_hit": sfx_arrow_hit, "pickup": sfx_pickup, "eat": sfx_eat,
    "craft": sfx_craft, "hurt": sfx_hurt, "howl": sfx_howl, "growl": sfx_growl,
    "animal_die": sfx_animal_die, "tree_fall": sfx_tree_fall, "place": sfx_place,
    "ui_hover": sfx_ui_hover, "ui_click": sfx_ui_click, "dawn": sfx_dawn,
    "game_over": sfx_game_over, "ignite": sfx_ignite, "level_up": sfx_level_up,
    "waypoint": sfx_waypoint, "page": sfx_page,
}


def main(only=None):
    """Generate everything, or only the named sounds (e.g. `generate_audio.py tree_fall`)."""
    os.makedirs(OUT, exist_ok=True)
    if not only:
        print("music...")
        for k in ("menu", "day", "night"):
            write_ogg("music_" + k, compose(k))
        print("ambience...")
        write_ogg("amb_wind", wind_loop())
        write_ogg("amb_forest", forest_day_loop())
        write_ogg("amb_fire", fire_loop())
        for i in range(4):
            write_wav("step%d" % i, sfx_step(100 + i))
    print("sfx...")
    for k, fn in SFX.items():
        if not only or k in only:
            write_wav(k, fn())
    print("done ->", OUT)


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
