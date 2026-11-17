"""Generate the Cursed Survivors app icon (PNG + multi-size ICO).

Run from tools/:  python gen_icon.py ..
"""
import os
import sys
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "..")
SS = 4  # supersample factor
BASE = 512
S = BASE * SS


def vgrad(size, top, bottom):
    img = Image.new("RGB", (1, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        d.point((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img.resize((size, size), Image.BILINEAR)


def radial(cx, cy, r, inner, size=S):
    """Soft radial glow as an RGBA layer."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 24
    for i in range(steps, 0, -1):
        t = i / steps
        rr = r * t
        a = int(inner[3] * (1.0 - t) ** 1.7)
        col = (inner[0], inner[1], inner[2], a)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
    return layer


def main():
    # --- background plate -------------------------------------------------
    bg = vgrad(S, (26, 12, 44), (9, 6, 16)).convert("RGBA")
    glow = radial(int(S * 0.5), int(S * 0.44), int(S * 0.52),
                  (150, 90, 210, 150))
    bg = Image.alpha_composite(bg, glow)
    bg = Image.alpha_composite(bg, radial(int(S * 0.5), int(S * 0.95), int(S * 0.55),
                                          (120, 20, 40, 130)))

    # rounded corners mask
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.16), fill=255)
    plate = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    plate.paste(bg, (0, 0), mask)

    d = ImageDraw.Draw(plate, "RGBA")

    # --- the closing ring -------------------------------------------------
    cx, cy = S * 0.5, S * 0.60
    ring_r = S * 0.34
    ring_w = int(S * 0.035)
    # drawn as dashes so it reads as "bodies", not a decal
    seg = 26
    for i in range(seg):
        if i % 5 == 3:
            continue
        a0 = (i / seg) * 360 + 4
        a1 = ((i + 1) / seg) * 360 - 4
        box = [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r]
        d.arc(box, a0, a1, fill=(176, 44, 56, 235), width=ring_w)
    # a brighter leading edge
    d.arc([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
          248, 292, fill=(226, 96, 96, 255), width=int(ring_w * 1.15))

    # --- the hood ---------------------------------------------------------
    hood = [
        (cx, cy - S * 0.34),
        (cx + S * 0.15, cy - S * 0.28),
        (cx + S * 0.185, cy - S * 0.09),
        (cx + S * 0.215, cy + S * 0.10),
        (cx + S * 0.145, cy + S * 0.30),
        (cx - S * 0.145, cy + S * 0.30),
        (cx - S * 0.215, cy + S * 0.10),
        (cx - S * 0.185, cy - S * 0.09),
        (cx - S * 0.15, cy - S * 0.28),
    ]
    d.polygon(hood, fill=(38, 20, 56, 255))
    d.line(hood + [hood[0]], fill=(132, 88, 168, 255), width=int(S * 0.014), joint="curve")

    # face void, slightly darker than the hood
    face = [
        (cx, cy - S * 0.26),
        (cx + S * 0.098, cy - S * 0.17),
        (cx + S * 0.112, cy + S * 0.02),
        (cx, cy + S * 0.13),
        (cx - S * 0.112, cy + S * 0.02),
        (cx - S * 0.098, cy - S * 0.17),
    ]
    d.polygon(face, fill=(12, 6, 20, 255))
    d.line(face + [face[0]], fill=(96, 58, 128, 200), width=int(S * 0.008), joint="curve")

    # eyes
    eye_y = cy - S * 0.10
    for sx in (-1, 1):
        ex = cx + sx * S * 0.048
        d.ellipse([ex - S * 0.026, eye_y - S * 0.016, ex + S * 0.026, eye_y + S * 0.016],
                  fill=(255, 64, 72, 255))
        d.ellipse([ex - S * 0.011, eye_y - S * 0.007, ex + S * 0.011, eye_y + S * 0.007],
                  fill=(255, 214, 214, 255))
    eye_glow = radial(int(cx), int(eye_y), int(S * 0.16), (255, 60, 70, 190))
    plate = Image.alpha_composite(plate, eye_glow)

    # small gold clasp at the throat, the only warm accent on the cloak
    d.polygon([(cx - S * 0.030, cy + S * 0.135),
               (cx + S * 0.030, cy + S * 0.135),
               (cx + S * 0.018, cy + S * 0.185),
               (cx - S * 0.018, cy + S * 0.185)],
              fill=(214, 172, 100, 235))

    # --- downscale and export --------------------------------------------
    out = plate.resize((BASE, BASE), Image.LANCZOS)
    png_path = os.path.join(ROOT, "assets", "icon.png")
    out.save(png_path)

    ico_path = os.path.join(ROOT, "assets", "icon.ico")
    out.save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48),
                              (64, 64), (128, 128), (256, 256)])
    print("wrote", png_path)
    print("wrote", ico_path)


if __name__ == "__main__":
    main()
