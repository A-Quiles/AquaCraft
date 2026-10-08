"""Genera las texturas procedurales de assets/textures (todas tileables).

    python3 tools/gen_textures.py

caustics.png  red de cáusticas (Voronoi F2-F1 en un toro)
noise.png     R/G/B = tres ruidos fbm independientes
bubble.png    burbuja con brillo
dot.png       punto suave (motas, destellos)
"""
import numpy as np
from PIL import Image
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "textures"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(7)
N = 256


def caustics(cells=7):
    gy, gx = np.mgrid[0:cells, 0:cells]
    pts = (np.stack([gx, gy], -1) + 0.05 + rng.random((cells, cells, 2)) * 0.9).reshape(-1, 2) / cells
    # vecinos en el toro
    offs = np.array([[dx, dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1)], dtype=float)
    allp = (pts[None, :, :] + offs[:, None, :]).reshape(-1, 2)
    ys, xs = np.mgrid[0:N, 0:N] / N
    d = np.sqrt((xs[..., None] - allp[:, 0]) ** 2 + (ys[..., None] - allp[:, 1]) ** 2)
    d.sort(axis=-1)
    edge = (d[..., 1] - d[..., 0]) * cells
    v = np.clip(1.0 - edge / 0.35, 0, 1) ** 2.2
    return v


def fbm(octaves=5, base=4):
    out = np.zeros((N, N))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        f = base * 2 ** o
        grid = rng.random((f, f))
        ys, xs = np.mgrid[0:N, 0:N] * f / N
        x0, y0 = xs.astype(int), ys.astype(int)
        tx, ty = xs - x0, ys - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        x1, y1 = (x0 + 1) % f, (y0 + 1) % f
        a, b = grid[y0, x0], grid[y0, x1]
        c, d = grid[y1, x0], grid[y1, x1]
        out += amp * ((a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty)
        total += amp
        amp *= 0.5
    out /= total
    return (out - out.min()) / (out.max() - out.min())


def save(arr, name, mode="L"):
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), mode).save(OUT / name, optimize=True)


save(caustics(), "caustics.png")
save(np.stack([fbm(5, 4), fbm(4, 8), fbm(3, 16)], -1), "noise.png", "RGB")

# burbuja 48 px: aro + brillo
s = 48
ys, xs = (np.mgrid[0:s, 0:s] + 0.5) / s * 2 - 1
r = np.sqrt(xs ** 2 + ys ** 2)
ring = np.clip(1 - np.abs(r - 0.82) / 0.13, 0, 1) ** 1.5
fill = np.clip(1 - r, 0, 1) * 0.18
spec = np.clip(1 - np.sqrt((xs + 0.35) ** 2 + (ys + 0.38) ** 2) / 0.22, 0, 1)
alpha = np.clip(ring * 0.85 + fill + spec, 0, 1) * (r < 0.97)
rgba = np.stack([np.full_like(alpha, 0.92), np.full_like(alpha, 0.98), np.ones_like(alpha), alpha], -1)
Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(OUT / "bubble.png", optimize=True)

# punto suave 32 px
s = 32
ys, xs = (np.mgrid[0:s, 0:s] + 0.5) / s * 2 - 1
a = np.clip(1 - np.sqrt(xs ** 2 + ys ** 2), 0, 1) ** 2
rgba = np.stack([np.ones_like(a)] * 3 + [a], -1)
Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(OUT / "dot.png", optimize=True)
print("ok", sorted(p.name for p in OUT.iterdir()))
