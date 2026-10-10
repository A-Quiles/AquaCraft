"""Genera todo el audio del juego de forma procedural (sin samples de terceros).

    python3 tools/gen_audio.py      → assets/audio/*.wav (efectos) y *.ogg (música y ambiente en bucle)

Necesita numpy y ffmpeg (con libvorbis) para los .ogg.
"""
import os
import subprocess
import wave

import numpy as np

SR = 22050
OUT = "assets/audio"
rng = np.random.default_rng(7)


def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, a=0.005, d=0.2):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-t / d)


def lowpass(x, cut):
    # Filtro de un polo (suave, sin fase rara): suficiente para ruido y mezcla.
    a = np.exp(-2 * np.pi * cut / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cut):
    return x - lowpass(x, cut)


def note(f, sec, bright=0.3, decay=0.6, a=0.005):
    t = t_axis(sec)
    w = np.sin(2 * np.pi * f * t) + bright * np.sin(4 * np.pi * f * t) * np.exp(-t / (decay * 0.4)) \
        + 0.08 * np.sin(6 * np.pi * f * t) * np.exp(-t / (decay * 0.2))
    return w * env(len(t), a, decay)


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def save_wav(name, x, peak=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def save_ogg(name, x, peak=0.7):
    save_wav("_tmp", x, peak)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", f"{OUT}/_tmp.wav", "-c:a", "libvorbis", "-q:a", "3",
                    f"{OUT}/{name}.ogg"], check=True)
    os.remove(f"{OUT}/_tmp.wav")


def fold(buf, length):
    """Bucle perfecto: lo que sobresale del final se suma al principio."""
    out = buf[:length].copy()
    tail = buf[length:]
    out[:len(tail)] += tail
    return out


# ───────────────────────── Efectos ─────────────────────────

def plop():
    t = t_axis(0.22)
    f = 520 * np.exp(-t * 14) + 160
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env(len(t), 0.002, 0.07) + 0.15 * lowpass(rng.normal(0, 1, len(t)), 1800) * env(len(t), 0.001, 0.02)


def bubble():
    t = t_axis(0.12)
    f = 380 + 2600 * t
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.002, 0.035)


def squeak():
    t = t_axis(0.22)
    n = rng.normal(0, 1, len(t))
    band = highpass(lowpass(n, 2600), 900)
    tone = 0.4 * np.sin(2 * np.pi * (1300 + 200 * np.sin(t * 40)) * t)
    return (band + tone) * np.sin(np.pi * t / t[-1]) ** 2


def slurp():
    t = t_axis(0.45)
    n = lowpass(rng.normal(0, 1, len(t)), 700)
    wob = 0.6 + 0.4 * np.sin(2 * np.pi * 9 * t)
    gurgle = sum(np.sin(2 * np.pi * (180 + 90 * k) * t + k) * np.exp(-((t - 0.08 * k) ** 2) / 0.002) for k in range(1, 5))
    return (n * wob + 0.3 * gurgle) * np.sin(np.pi * t / t[-1])


def coin():
    a = note(midi(83), 0.5, 0.2, 0.25)
    b = note(midi(88), 0.6, 0.2, 0.35)
    out = np.zeros(int(SR * 0.7))
    out[:len(a)] += a
    out[int(SR * 0.07):int(SR * 0.07) + len(b)] += b
    return out


def arpeggio(notes, step, tail, decay=0.5, bright=0.25):
    out = np.zeros(int(SR * (step * len(notes) + tail)))
    for i, m in enumerate(notes):
        x = note(midi(m), tail, bright, decay)
        s = int(SR * step * i)
        out[s:s + len(x)] += x
    return out


def hatch():
    crack = highpass(rng.normal(0, 1, int(SR * 0.05)), 2000) * env(int(SR * 0.05), 0.001, 0.01)
    chirp = arpeggio([84, 88, 91], 0.07, 0.4, 0.2)
    out = np.zeros(len(chirp) + int(SR * 0.08))
    out[:len(crack)] += crack
    out[int(SR * 0.08):] += chirp
    return out


def click():
    t = t_axis(0.04)
    return np.sin(2 * np.pi * 1500 * t) * env(len(t), 0.001, 0.008)


def error():
    a = note(midi(57), 0.18, 0.1, 0.06)
    out = np.zeros(int(SR * 0.32))
    out[:len(a)] += a
    out[int(SR * 0.13):int(SR * 0.13) + len(a)] += note(midi(53), 0.18, 0.1, 0.06)
    return out


# ───────────────────────── Bucles ─────────────────────────

def ambience(sec=12.0):
    n = int(SR * sec)
    hum = lowpass(np.cumsum(rng.normal(0, 1, n)) * 0.02, 300)
    hum -= np.mean(hum)
    hum = hum / (np.max(np.abs(hum)) + 1e-9) * 0.35
    buf = np.zeros(n + SR)
    buf[:n] += hum
    for _ in range(int(sec * 6)):
        b = bubble() * rng.uniform(0.1, 0.35)
        s = int(rng.uniform(0, n))
        buf[s:s + len(b)] += b
    return fold(buf, n)


def music():
    """Lo-fi tranquilo: 72 BPM, 16 compases (Fmaj7 Em7 Dm7 Cmaj7 ×4), piano eléctrico, bajo, escobillas y melodía."""
    bpm = 72
    beat = 60 / bpm
    bars = 16
    n = int(SR * beat * 4 * bars)
    buf = np.zeros(n + SR * 4)
    chords = [[53, 57, 60, 64], [52, 55, 59, 62], [50, 53, 57, 60], [48, 52, 55, 59]]
    roots = [41, 40, 38, 36]
    scale = [60, 62, 64, 67, 69, 72, 74, 76]
    swing = beat * 0.12

    def put(x, sec, gain):
        s = int(sec * SR)
        e = min(len(buf), s + len(x))
        buf[s:e] += x[:e - s] * gain

    for bar in range(bars):
        t0 = bar * beat * 4
        ch = chords[bar % 4]
        # Piano eléctrico: acorde en el 1 y un eco suave en el "y" del 3.
        for k, m in enumerate(ch):
            put(note(midi(m), beat * 4, 0.35, 1.4, 0.01), t0 + k * 0.012, 0.16)
            put(note(midi(m + 12), beat * 2, 0.2, 0.6, 0.01), t0 + beat * 2.5 + swing, 0.05)
        # Bajo
        for b, off in [(0, 0.0), (1, 2.0), (0, 3.5)]:
            put(note(midi(roots[bar % 4] + 12 * b * 0 + (7 if off == 3.5 else 0)), beat * 1.2, 0.05, 0.5, 0.01), t0 + beat * off, 0.42)
        # Batería suave
        for bt in range(4):
            kt = t_axis(0.3)
            if bt in (0, 2):
                put(np.sin(2 * np.pi * np.cumsum(55 + 70 * np.exp(-kt * 30)) / SR) * env(len(kt), 0.002, 0.12), t0 + bt * beat, 0.5)
            else:
                sn = lowpass(rng.normal(0, 1, int(SR * 0.25)), 3000) * env(int(SR * 0.25), 0.003, 0.07)
                put(sn, t0 + bt * beat, 0.16)
            for half in (0, 1):
                hh = highpass(rng.normal(0, 1, int(SR * 0.05)), 5000) * env(int(SR * 0.05), 0.001, 0.015)
                put(hh, t0 + bt * beat + half * (beat / 2 + swing), 0.05 if half else 0.08)
        # Melodía: frases sueltas de pentatónica, más presentes en la segunda mitad.
        if bar % 2 == 1 or bar >= 8:
            for e in range(8):
                if rng.random() < (0.35 if bar < 8 else 0.5):
                    m = scale[rng.integers(0, len(scale))]
                    put(note(midi(m + 12), beat * 1.5, 0.15, 0.45), t0 + e * beat / 2 + (swing if e % 2 else 0), 0.12)
    # Crujido de vinilo
    for _ in range(int(bars * 6)):
        put(highpass(rng.normal(0, 1, 60), 3000) * 0.5, rng.uniform(0, n / SR), 0.08)
    out = fold(buf, n)
    return lowpass(out, 5200)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("plop", plop), ("bubble", bubble), ("squeak", squeak), ("slurp", slurp), ("coin", coin),
                     ("chime", lambda: arpeggio([72, 76, 79, 84], 0.08, 0.6)), ("levelup", lambda: arpeggio([72, 76, 79, 84, 88, 91], 0.09, 0.9, 0.6)),
                     ("hatch", hatch), ("click", click), ("error", error)]:
        save_wav(name, fn())
    save_ogg("ambience", ambience(), 0.5)
    save_ogg("music", music(), 0.7)
    print("audio OK:", sorted(os.listdir(OUT)))
