"""Icons for the class-specific weapons added in the arsenal rework."""

import os
import sys

from PIL import Image, ImageFilter

import gen_ui as G
from artlib import (P, add_glow, circle, d, finalize, line, new, outline, poly, radial)


def ic_sword_splash():
    im = G._icon_canvas()
    # motion arc behind the blade
    for i, a in enumerate((120, 80, 40)):
        d(im).arc([G.S(6 + i), G.S(6 + i), G.S(58 - i), G.S(58 - i)], start=-55, end=95,
                  fill=(255, 240, 215, a), width=G.S(3 - i * 0.5))
    # blade
    poly(im, [(20, 50), (36, 12), (44, 20), (26, 54)], P["steel_lt"])
    poly(im, [(36, 12), (44, 20), (40, 22), (34, 15)], (255, 255, 255, 235))
    line(im, (16, 46), (30, 56), P["blood_dk"], 4)
    line(im, (24, 54), (18, 60), (64, 42, 30, 255), 3)
    im = outline(im, 2.0)
    add_glow(im, 36, 26, 20, (255, 196, 150), 0.55)
    return im


def ic_shield_bash():
    im = G._icon_canvas()
    poly(im, [(32, 8), (52, 16), (50, 40), (32, 58), (14, 40), (12, 16)], P["steel_lt"])
    poly(im, [(32, 12), (47, 18), (45, 38), (32, 52), (19, 38), (17, 18)], (128, 96, 168, 255))
    line(im, (32, 14), (32, 50), (240, 236, 255, 200), 2)
    line(im, (18, 32), (46, 32), (240, 236, 255, 200), 2)
    # impact burst
    for ang in (0, 45, 90, 135, 180, 225, 270, 315):
        import math
        a = math.radians(ang)
        line(im, (32 + 14 * math.cos(a), 32 + 14 * math.sin(a)),
             (32 + 23 * math.cos(a), 32 + 23 * math.sin(a)), (255, 236, 200, 230), 2)
    im = outline(im, 2.2)
    add_glow(im, 32, 32, 24, (180, 200, 255), 0.6)
    return im


def ic_chaos_bolt():
    im = G._icon_canvas()
    circle(im, 32, 32, 20, (96, 40, 140, 210))
    poly(im, [(38, 8), (20, 32), (31, 32), (24, 58), (48, 26), (35, 26)], P["violet"])
    poly(im, [(36, 12), (27, 29), (34, 29), (29, 48)], (240, 212, 255, 255))
    im = outline(im, 2.2)
    add_glow(im, 32, 32, 26, P["violet"], 0.85)
    return im


def _dagger_template():
    im = new(64, 64)
    poly(im, [(32, 8), (36, 31), (28, 31)], P["steel_lt"])
    poly(im, [(32, 11), (34, 29), (30, 29)], (250, 252, 255, 235))
    line(im, (23, 32), (41, 32), (170, 138, 100, 255), 3.4)
    poly(im, [(29.5, 32), (34.5, 32), (34, 44), (30, 44)], (82, 56, 42, 255))
    circle(im, 32, 46, 2.8, P["blood_dk"])
    return im


def ic_fan_of_knives():
    im = G._icon_canvas()
    tmpl = _dagger_template()
    for angle in (-42, 0, 42):
        rot = tmpl.rotate(angle, resample=Image.BICUBIC, center=(32, 46))
        im.alpha_composite(rot)
    im = outline(im, 1.8)
    add_glow(im, 32, 28, 22, (120, 200, 255), 0.5)
    return im


def ic_frost_nova():
    im = G._icon_canvas()
    import math
    for ang in range(0, 360, 60):
        a = math.radians(ang)
        line(im, (32, 32), (32 + 24 * math.cos(a), 32 + 24 * math.sin(a)),
             (190, 240, 255, 230), 2)
        for s in (-1, 1):
            b1 = math.radians(ang + s * 30)
            line(im, (32 + 14 * math.cos(a), 32 + 14 * math.sin(a)),
                 (32 + 14 * math.cos(a) + 8 * math.cos(b1),
                  32 + 14 * math.sin(a) + 8 * math.sin(b1)), (200, 245, 255, 210), 1)
    circle(im, 32, 32, 6, (240, 252, 255, 255))
    d(im).ellipse([G.S(4), G.S(4), G.S(60), G.S(60)], outline=P["teal"], width=G.S(1.4))
    im = outline(im, 1.8)
    add_glow(im, 32, 32, 26, P["teal"], 0.8)
    return im


ICONS = {
    "sword_splash": ic_sword_splash,
    "shield_bash": ic_shield_bash,
    "chaos_bolt": ic_chaos_bolt,
    "fan_of_knives": ic_fan_of_knives,
    "frost_nova": ic_frost_nova,
}


def main(root):
    out = os.path.join(root, "assets", "ui", "icons")
    os.makedirs(out, exist_ok=True)
    for name, fn in ICONS.items():
        fn().save(os.path.join(out, name + ".png"))
        print("icon", name)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "..")