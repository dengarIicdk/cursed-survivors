"""Installer artwork for Inno Setup: the tall wizard panel and the small corner logo.

Run from tools/:  python gen_installer_art.py ..
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "..")
OUT = os.path.join(ROOT, "installer")
os.makedirs(OUT, exist_ok=True)

W, H = 164, 314
SS = 4
FONT_DIR = os.path.join(ROOT, "assets", "fonts")


def font(name, size):
    path = os.path.join(FONT_DIR, name)
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (1, size[1]))
    d = ImageDraw.Draw(img)
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        d.point((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img.resize(size, Image.BILINEAR)


def radial_glow(size, cx, cy, r, color, power=1.8):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 26
    for i in range(steps, 0, -1):
        t = i / steps
        rr = r * t
        a = int(color[3] * (1.0 - t) ** power)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(color[0], color[1], color[2], a))
    return layer


def main():
    w, h = W * SS, H * SS
    img = vertical_gradient((w, h), (30, 14, 46), (8, 5, 14)).convert("RGBA")
    img = Image.alpha_composite(img, radial_glow((w, h), w * 0.5, h * 0.34, w * 1.15, (140, 80, 200, 120)))
    img = Image.alpha_composite(img, radial_glow((w, h), w * 0.5, h * 0.95, w * 1.3, (140, 26, 44, 110)))

    d = ImageDraw.Draw(img, "RGBA")

    # hooded silhouette at the top
    cx, cy = w * 0.5, h * 0.30
    hood = [
        (cx, cy - h * 0.115),
        (cx + w * 0.20, cy - h * 0.085),
        (cx + w * 0.25, cy + h * 0.010),
        (cx + w * 0.32, cy + h * 0.115),
        (cx + w * 0.20, cy + h * 0.175),
        (cx - w * 0.20, cy + h * 0.175),
        (cx - w * 0.32, cy + h * 0.115),
        (cx - w * 0.25, cy + h * 0.010),
        (cx - w * 0.20, cy - h * 0.085),
    ]
    d.polygon(hood, fill=(40, 21, 58, 255))
    d.line(hood + [hood[0]], fill=(126, 84, 162, 255), width=int(w * 0.012), joint="curve")

    face = [
        (cx, cy - h * 0.088),
        (cx + w * 0.13, cy - h * 0.058),
        (cx + w * 0.15, cy + h * 0.007),
        (cx, cy + h * 0.050),
        (cx - w * 0.15, cy + h * 0.007),
        (cx - w * 0.13, cy - h * 0.058),
    ]
    d.polygon(face, fill=(11, 6, 19, 255))
    for sx in (-1, 1):
        ex = cx + sx * w * 0.062
        ey = cy - h * 0.030
        d.ellipse([ex - w * 0.034, ey - h * 0.011, ex + w * 0.034, ey + h * 0.011],
                  fill=(255, 62, 72, 255))
    img = Image.alpha_composite(img, radial_glow((w, h), int(cx), int(cy - h * 0.03),
                                                 int(w * 0.34), (255, 70, 80, 150)))
    d = ImageDraw.Draw(img, "RGBA")

    # a thin closing ring around the figure
    rr = w * 0.40
    ring_box = [cx - rr, cy - rr * 0.94, cx + rr, cy + rr * 1.06]
    seg = 22
    for i in range(seg):
        if i % 6 == 4:
            continue
        d.arc(ring_box, (i / seg) * 360 + 3, ((i + 1) / seg) * 360 - 3,
              fill=(172, 44, 56, 190), width=int(w * 0.022))

    title_font = font("PirataOne-Regular.ttf", int(h * 0.072))
    small_font = font("Almendra-Bold.ttf", int(h * 0.030))
    gold = (222, 196, 156, 255)
    dim = (176, 156, 190, 255)

    def centre_text(text, fnt, y, fill):
        bbox = d.textbbox((0, 0), text, font=fnt)
        d.text(((w - (bbox[2] - bbox[0])) / 2, y), text, font=fnt, fill=fill)

    centre_text("CURSED", title_font, h * 0.55, (255, 243, 216, 255))
    centre_text("SURVIVORS", title_font, h * 0.635, (255, 243, 216, 255))
    d.line([(w * 0.22, h * 0.725), (w * 0.78, h * 0.725)], fill=(168, 128, 84, 200), width=int(w * 0.008))
    centre_text("ВЫЖИВИ В НОЧИ", small_font, h * 0.755, gold)
    centre_text("BREAK THE RING", small_font, h * 0.795, dim)
    centre_text("1.0", small_font, h * 0.90, (150, 128, 160, 255))

    panel = img.resize((W, H), Image.LANCZOS)
    # Inno wants 24-bit BMP
    panel.convert("RGB").save(os.path.join(OUT, "wizard.bmp"), "BMP")
    print("wrote", os.path.join(OUT, "wizard.bmp"), panel.size)

    # small logo, 55x55 as Inno expects for the corner
    logo = Image.open(os.path.join(ROOT, "assets", "icon.png")).convert("RGB")
    logo.resize((55, 55), Image.LANCZOS).save(os.path.join(OUT, "small.bmp"), "BMP")
    print("wrote", os.path.join(OUT, "small.bmp"))


if __name__ == "__main__":
    main()
