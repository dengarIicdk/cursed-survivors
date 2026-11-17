"""Props for the Infernal Depths map: ice crystals, basalt spikes, magma vents.

Run from the tools folder:  python gen_depths.py ..
Writes into assets/sprites/props/depths/.
"""

import os
import sys

from PIL import Image

from artlib import (
    INK_SOFT, P, add_glow, circle, finalize, inner_glow, lighter, line, mix, new,
    outline, poly, shade_volume,
)

ICE = (126, 206, 236, 255)
ICE_LT = (196, 240, 255, 255)
ICE_DK = (54, 116, 158, 255)
BASALT = (74, 78, 96, 255)
BASALT_LT = (112, 120, 142, 255)
BASALT_DK = (40, 42, 58, 255)
MAGMA = (255, 138, 58, 255)
MAGMA_LT = (255, 214, 140, 255)


def crystal(kind: int) -> Image.Image:
    im = new(80, 104)
    if kind == 0:
        poly(im, [(40, 6), (58, 42), (52, 96), (30, 98), (24, 44)], ICE)
        poly(im, [(38, 12), (46, 44), (42, 92), (34, 92), (32, 44)], ICE_LT)
        poly(im, [(58, 42), (72, 70), (62, 96), (52, 96)], ICE_DK)
    elif kind == 1:
        poly(im, [(26, 30), (44, 12), (52, 54), (34, 96), (16, 70)], ICE)
        poly(im, [(38, 20), (44, 52), (32, 88)], ICE_LT)
        poly(im, [(58, 46), (74, 74), (60, 98), (48, 92)], ICE_DK)
    else:
        for i, (x, h) in enumerate([(24, 52), (40, 78), (56, 46)]):
            top = 96 - h
            poly(im, [(x - 12, 98), (x, top), (x + 12, 98)], ICE if i != 1 else ICE_DK)
            poly(im, [(x - 4, 98), (x, top + 10), (x + 3, 98)], ICE_LT)
    add_glow(im, 40, 60, 34, ICE, 0.35)
    shade_volume(im, 1.18, 0.72)
    return finalize(outline(im, 2.0, INK_SOFT), 80, 104)


def stalagmite() -> Image.Image:
    im = new(64, 96)
    poly(im, [(12, 94), (30, 12), (40, 18), (54, 94)], BASALT)
    poly(im, [(28, 20), (34, 22), (40, 92), (30, 92)], BASALT_LT)
    poly(im, [(44, 52), (58, 94), (42, 94)], BASALT_DK)
    for y in (44, 62, 78):
        line(im, (20 + y // 12, y), (46, y - 4), BASALT_DK, 1.6)
    shade_volume(im, 1.12, 0.7)
    return finalize(outline(im, 1.8, INK_SOFT), 64, 96)


def magma_vent() -> Image.Image:
    im = new(88, 56)
    poly(im, [(6, 52), (18, 24), (44, 14), (72, 22), (84, 52)], BASALT_DK)
    poly(im, [(18, 50), (30, 28), (56, 22), (72, 34), (76, 50)], BASALT)
    # glowing fissure
    poly(im, [(34, 48), (40, 30), (48, 24), (56, 32), (50, 48)], MAGMA)
    poly(im, [(40, 46), (44, 32), (48, 30), (50, 40), (46, 46)], MAGMA_LT)
    line(im, (14, 44), (30, 36), MAGMA, 2.2)
    line(im, (62, 38), (78, 46), MAGMA, 2.0)
    add_glow(im, 46, 36, 30, MAGMA, 0.5)
    inner_glow(im, 46, 34, 18, MAGMA_LT, 0.35)
    shade_volume(im, 1.1, 0.78)
    return finalize(outline(im, 1.6, INK_SOFT), 88, 56)


def ice_bones() -> Image.Image:
    im = new(60, 40)
    for x, y, r in [(16, 26, 5), (30, 30, 4), (44, 26, 5)]:
        circle(im, x, y, r, mix(ICE, (230, 240, 255, 255), 0.5))
    line(im, (10, 32), (48, 34), mix(ICE_DK, BASALT, 0.4), 3)
    add_glow(im, 30, 30, 20, ICE, 0.25)
    return finalize(outline(im, 1.6, INK_SOFT), 60, 40)


def main() -> None:
    root = sys.argv[1] if len(sys.argv) > 1 else ".."
    out = os.path.join(root, "assets", "sprites", "props", "depths")
    os.makedirs(out, exist_ok=True)
    for i in range(3):
        crystal(i).save(os.path.join(out, f"crystal_{i}.png"))
    stalagmite().save(os.path.join(out, "stalagmite.png"))
    magma_vent().save(os.path.join(out, "magma_vent.png"))
    ice_bones().save(os.path.join(out, "ice_bones.png"))
    print("depths props done")


if __name__ == "__main__":
    main()
