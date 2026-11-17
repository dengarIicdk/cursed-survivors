"""Ambient wildlife sprites: crows, rats, moths and lost souls.

Run from the tools folder:  python gen_wildlife.py ..
Writes into assets/sprites/wildlife/.
"""

import os
import sys

from PIL import Image

from artlib import (
    INK, INK_SOFT, add_glow, circle, finalize, line, mix, new, outline, poly,
    shade_volume, S, SS,
)

BLACK = (38, 32, 46, 255)
BLACK_LT = (72, 62, 84, 255)
BEAK = (196, 156, 88, 255)
FUR = (86, 78, 74, 255)
FUR_LT = (118, 108, 100, 255)
MOTH = (255, 226, 150, 255)
WISP = (150, 236, 220, 255)


def crow(open_wings: bool) -> Image.Image:
    im = new(64, 56)
    body = poly(im, [(30, 20), (44, 30), (46, 42), (30, 46), (18, 38), (20, 26)], BLACK)
    # head + beak
    circle(im, 44, 22, 8, BLACK)
    poly(im, [(50, 20), (60, 23), (50, 26)], BEAK)
    circle(im, 46, 20, 2, (196, 60, 60, 255))
    # tail
    poly(im, [(20, 38), (6, 48), (14, 34)], BLACK_LT)
    if open_wings:
        poly(im, [(30, 26), (10, 6), (4, 16), (26, 32)], BLACK_LT)
        poly(im, [(36, 26), (54, 4), (60, 14), (40, 32)], BLACK_LT)
    else:
        poly(im, [(26, 30), (18, 44), (30, 38)], BLACK_LT)
    shade_volume(im, 1.25, 0.7)
    return finalize(outline(im, 1.6, INK), 64, 56)


def rat() -> Image.Image:
    im = new(48, 32)
    poly(im, [(14, 22), (32, 16), (40, 22), (30, 28), (16, 28)], FUR)
    circle(im, 36, 20, 6, FUR_LT)
    circle(im, 34, 17, 3, FUR_LT)
    circle(im, 40, 20, 1.4, (24, 18, 20, 255))
    line(im, (14, 24), (2, 18), FUR_LT, 2)
    line(im, (16, 27), (10, 30), FUR, 2)
    shade_volume(im, 1.2, 0.72)
    return finalize(outline(im, 1.3, INK), 48, 32)


def moth() -> Image.Image:
    im = new(24, 24)
    circle(im, 8, 11, 6, MOTH)
    circle(im, 16, 11, 6, MOTH)
    circle(im, 12, 12, 2.6, (255, 255, 240, 255))
    add_glow(im, 12, 12, 10, MOTH, 0.75)
    return finalize(im, 24, 24)


def lost_soul() -> Image.Image:
    im = new(40, 48)
    poly(im, [(20, 4), (30, 18), (28, 34), (20, 44), (12, 34), (10, 18)], WISP)
    circle(im, 17, 18, 2.4, (255, 255, 255, 220))
    circle(im, 24, 18, 2.4, (255, 255, 255, 220))
    add_glow(im, 20, 22, 18, WISP, 0.55)
    return finalize(im, 40, 48)


def main() -> None:
    root = sys.argv[1] if len(sys.argv) > 1 else ".."
    out = os.path.join(root, "assets", "sprites", "wildlife")
    os.makedirs(out, exist_ok=True)
    crow(False).save(os.path.join(out, "crow_perched.png"))
    crow(True).save(os.path.join(out, "crow_flying.png"))
    rat().save(os.path.join(out, "rat.png"))
    moth().save(os.path.join(out, "moth.png"))
    lost_soul().save(os.path.join(out, "wisp.png"))
    print("wildlife done")


if __name__ == "__main__":
    main()
