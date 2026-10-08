"""Compone las capturas de Google Play (1080×1920) con titular encima.

    1) Renderiza las capturas del juego (ver README: `-- demo=N open=... shot=sN.png night=0`)
    2) python3 tools/compose_screenshots.py <carpeta_con_s1..s5.png>
"""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC = sys.argv[1] if len(sys.argv) > 1 else "."
CAPS = [("Tu acuario cozy", "siempre vivo, de día y de noche"),
        ("Cría peces únicos", "genética, mutaciones y 5 rarezas"),
        ("Limpia con el dedo", "agua clara, peces felices"),
        ("Un mercado enorme", "peces exóticos cada día"),
        ("Hasta 1000 litros", "decora el acuario de tus sueños")]
W, H = 1080, 1920
title = ImageFont.truetype("assets/fonts/Fredoka.ttf", 92)
title.set_variation_by_axes([600, 100])
sub = ImageFont.truetype("assets/fonts/Nunito.ttf", 46)
sub.set_variation_by_axes([800])

for i, (t, st) in enumerate(CAPS):
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        k = y / H
        d.line([(0, y), (W, y)], fill=(int(18 + 20 * k), int(126 - 66 * k), int(146 - 56 * k)))
    shot = Image.open(f"{SRC}/s{i + 1}.png").convert("RGB")
    sc = 0.82
    sw, sh = int(W * sc), int(H * sc)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius=48, fill=255)
    x, y = (W - sw) // 2, H - sh - 40
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([x, y + 14, x + sw, y + sh + 14], radius=48, fill=110)
    bg.paste((5, 25, 35), (0, 0), shadow.filter(ImageFilter.GaussianBlur(18)))
    bg.paste(shot, (x, y), mask)
    d = ImageDraw.Draw(bg)
    d.text((W // 2 + 3, 104), t, font=title, fill=(8, 50, 64), anchor="mm")
    d.text((W // 2, 98), t, font=title, fill="white", anchor="mm")
    d.text((W // 2, 196), st, font=sub, fill=(214, 250, 246), anchor="mm")
    bg.save(f"store/screenshots/{i + 1}.png", optimize=True)
print("ok")
