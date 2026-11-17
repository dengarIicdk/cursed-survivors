"""Generates heroes, enemies and props for Cursed Survivors.

Everything is painted from primitives at 3x supersampling, shaded with a
vertical light ramp, then wrapped in one dark cartoon contour.
"""

import os

from PIL import Image, ImageDraw, ImageFilter

from artlib import (
    INK, INK_SOFT, P, S, SS, add_glow, circle, d, darker, ell, finalize, inner_glow,
    lighter, limb, line, mix, new, outline, poly, rrect, save, shade_volume, shadow_sprite,
)

OUT_W = 128
H = 128


def _eyes(img, cx, cy, dx, r, color, glow=6.0):
    circle(img, cx - dx, cy, r, color)
    circle(img, cx + dx, cy, r, color)
    if glow > 0:
        add_glow(img, cx - dx, cy, glow, color, 0.55)
        add_glow(img, cx + dx, cy, glow, color, 0.55)


# ---------------------------------------------------------------- heroes

def hexblade() -> Image.Image:
    im = new(OUT_W, H)
    robe = P["violet"]
    robe_d = P["violet_dk"]
    # cloak billowing behind
    poly(im, [(64, 62), (92, 78), (100, 118), (74, 122), (56, 122), (30, 116), (36, 78)], robe_d)
    # staff
    line(im, (100, 22), (104, 120), (74, 54, 40, 255), 3.4)
    circle(im, 100, 22, 9, P["magenta"])
    circle(im, 100, 22, 5, P["violet_lt"])
    # legs
    limb(im, [(56, 100), (52, 117)], 6, robe_d)
    limb(im, [(72, 100), (76, 117)], 6, robe_d)
    # torso robe
    poly(im, [(46, 62), (82, 62), (88, 104), (64, 112), (40, 104)], robe)
    poly(im, [(46, 62), (82, 62), (84, 74), (44, 74)], P["violet_lt"]
         if False else mix(robe, P["violet_lt"], 0.45))
    # belt
    rrect(im, (44, 84, 84, 92), 3, P["gold"], INK_SOFT, 1)
    # sleeves
    limb(im, [(50, 68), (38, 88), (44, 96)], 7, robe)
    limb(im, [(78, 68), (92, 84)], 7, robe)
    circle(im, 44, 96, 5, P["skin"])
    circle(im, 92, 84, 5, P["skin"])
    # hood + face
    poly(im, [(64, 20), (88, 42), (86, 66), (42, 66), (40, 42)], P["violet_dk"])
    ell(im, (46, 30, 82, 66), (12, 6, 20, 255))
    _eyes(im, 64, 48, 7, 2.6, P["magenta"], 7)
    poly(im, [(40, 44), (88, 44), (84, 34), (64, 24), (44, 34)], mix(robe, P["violet_lt"], 0.3))
    shade_volume(im, 1.18, 0.72)
    im = outline(im, 2.4)
    add_glow(im, 100, 22, 14, P["magenta"], 0.75)
    add_glow(im, 64, 48, 12, P["magenta"], 0.3)
    return finalize(im, OUT_W, H)


def ironclad() -> Image.Image:
    im = new(OUT_W, H)
    st, st_d, st_l = P["steel"], P["steel_dk"], P["steel_lt"]
    # cape
    poly(im, [(64, 58), (94, 74), (98, 116), (64, 120), (30, 116), (34, 74)], P["blood_dk"])
    # legs
    rrect(im, (48, 96, 60, 118), 4, st_d)
    rrect(im, (68, 96, 80, 118), 4, st_d)
    rrect(im, (46, 112, 62, 119), 2, st)
    rrect(im, (66, 112, 82, 119), 2, st)
    # torso
    rrect(im, (44, 60, 84, 100), 7, st)
    poly(im, [(52, 64), (76, 64), (74, 86), (64, 96), (54, 86)], st_l)
    rrect(im, (44, 88, 84, 96), 2, P["gold_dk"])
    circle(im, 64, 84, 5, P["gold"])
    # shoulders
    circle(im, 42, 68, 11, st, INK_SOFT, 1)
    circle(im, 86, 68, 11, st, INK_SOFT, 1)
    # shield
    poly(im, [(28, 74), (40, 70), (44, 100), (34, 112), (24, 100)], st_d)
    poly(im, [(30, 78), (38, 75), (40, 98), (34, 106), (28, 98)], mix(st, P["gold"], 0.25))
    circle(im, 34, 90, 4, P["gold"])
    # sword
    line(im, (98, 34), (102, 104), st_l, 3.2)
    line(im, (88, 62), (104, 58), P["gold_dk"], 3)
    circle(im, 102, 106, 3.4, P["gold"])
    # helm
    rrect(im, (50, 26, 78, 62), 8, st)
    rrect(im, (54, 40, 74, 50), 3, (14, 10, 20, 255))
    _eyes(im, 64, 45, 6, 2.2, P["teal"], 5)
    poly(im, [(50, 28), (46, 14), (56, 24)], st_l)
    poly(im, [(78, 28), (82, 14), (72, 24)], st_l)
    shade_volume(im, 1.2, 0.68)
    im = outline(im, 2.4)
    add_glow(im, 64, 45, 8, P["teal"], 0.25)
    return finalize(im, OUT_W, H)


def wraithborn() -> Image.Image:
    im = new(OUT_W, H)
    cl = (52, 78, 96, 255)
    cl_d = (26, 40, 58, 255)
    # cloak
    poly(im, [(64, 44), (96, 72), (92, 120), (64, 112), (36, 120), (32, 72)], cl_d)
    lim = mix(cl, cl_d, 0.4)
    poly(im, [(50, 60), (80, 60), (86, 100), (64, 110), (42, 100)], lim)
    # legs
    limb(im, [(56, 100), (52, 118)], 5, cl_d)
    limb(im, [(72, 100), (76, 118)], 5, cl_d)
    # belt + scarf
    rrect(im, (44, 84, 84, 90), 2, P["teal_dk"])
    poly(im, [(46, 66), (86, 66), (92, 80), (64, 88), (38, 80)], P["teal_dk"])
    # arms + daggers
    limb(im, [(48, 68), (34, 86)], 6, lim)
    limb(im, [(80, 68), (96, 84)], 6, lim)
    poly(im, [(26, 92), (34, 72), (40, 78), (36, 98)], P["steel_lt"])
    poly(im, [(104, 90), (96, 70), (90, 76), (94, 96)], P["steel_lt"])
    # hood
    poly(im, [(64, 16), (88, 40), (84, 64), (44, 64), (40, 40)], cl)
    ell(im, (48, 30, 80, 62), (10, 6, 16, 255))
    _eyes(im, 64, 46, 7, 2.6, P["teal"], 8)
    shade_volume(im, 1.14, 0.7)
    im = outline(im, 2.4)
    add_glow(im, 64, 46, 14, P["teal"], 0.35)
    return finalize(im, OUT_W, H)


def stormcaller() -> Image.Image:
    im = new(OUT_W, H)
    robe = (72, 96, 140, 255)
    robe_d = (38, 52, 92, 255)
    # totem staff
    line(im, (100, 18), (104, 120), (92, 68, 40, 255), 3.6)
    poly(im, [(94, 18), (108, 10), (104, 26), (96, 30)], P["gold"])
    circle(im, 102, 14, 6, P["teal"])
    # robe
    poly(im, [(48, 62), (80, 62), (88, 108), (64, 116), (40, 108)], robe)
    poly(im, [(48, 62), (80, 62), (80, 72), (48, 72)], mix(robe, (180, 210, 255, 255), 0.4))
    poly(im, [(58, 74), (70, 74), (72, 104), (64, 110), (56, 104)], robe_d)
    # feathers on shoulders
    for i, x in enumerate((44, 40, 48)):
        poly(im, [(x, 62), (x - 8, 40 + i * 4), (x + 4, 58)], P["teal"])
    for i, x in enumerate((84, 88, 80)):
        poly(im, [(x, 62), (x + 8, 40 + i * 4), (x - 4, 58)], P["teal"])
    # arms
    limb(im, [(50, 68), (38, 88)], 7, robe)
    limb(im, [(78, 68), (92, 88)], 7, robe)
    circle(im, 38, 88, 5, P["skin"])
    circle(im, 92, 88, 5, P["skin"])
    # mask head
    poly(im, [(64, 22), (86, 40), (82, 64), (46, 64), (42, 40)], P["bone"])
    ell(im, (48, 34, 80, 62), (16, 12, 24, 255))
    _eyes(im, 64, 48, 7, 2.8, P["teal"], 8)
    poly(im, [(50, 58), (78, 58), (74, 66), (54, 66)], P["bone_dk"])
    # headdress
    for i in range(5):
        x = 46 + i * 9
        poly(im, [(x, 30), (x + 4, 8 + i % 2 * 6), (x + 8, 30)], P["teal_dk"])
    shade_volume(im, 1.16, 0.7)
    im = outline(im, 2.4)
    add_glow(im, 102, 14, 16, P["teal"], 0.7)
    return finalize(im, OUT_W, H)


# ---------------------------------------------------------------- enemies

def shambling_corpse() -> Image.Image:
    im = new(OUT_W, H)
    skin, skin_d = P["rot"], P["rot_dk"]
    # legs
    limb(im, [(56, 98), (50, 118)], 6, skin_d)
    limb(im, [(72, 98), (78, 118)], 6, skin_d)
    # torso (hunched)
    poly(im, [(48, 70), (80, 66), (84, 102), (64, 106), (44, 100)], skin)
    # torn shirt
    poly(im, [(48, 70), (80, 66), (80, 86), (70, 92), (64, 84), (56, 92), (48, 86)], (94, 92, 108, 255))
    # arms reaching forward
    limb(im, [(52, 76), (34, 84), (22, 78)], 6, skin)
    limb(im, [(78, 74), (96, 82), (108, 76)], 6, skin)
    circle(im, 22, 78, 4, skin)
    circle(im, 108, 76, 4, skin)
    # head, jaw open
    ell(im, (50, 34, 80, 68), skin)
    poly(im, [(54, 60), (76, 60), (72, 72), (58, 72)], (12, 8, 18, 255))
    poly(im, [(58, 44), (70, 44), (72, 52), (56, 52)], (24, 16, 30, 255))
    _eyes(im, 64, 46, 6, 2.4, (216, 64, 64, 255), 6)
    # hair strands
    for i in range(4):
        line(im, (54 + i * 6, 36), (50 + i * 6, 26), skin_d, 2)
    # wounds
    line(im, (58, 84), (66, 94), P["blood"], 2.4)
    shade_volume(im, 1.12, 0.7)
    return finalize(outline(im, 2.3), OUT_W, H)


def bat_swarm() -> Image.Image:
    im = new(OUT_W, H)
    body = P["violet_dk"]
    wing = (74, 44, 108, 255)
    # wings
    poly(im, [(60, 62), (30, 34), (8, 46), (22, 60), (10, 70), (34, 70), (56, 74)], wing)
    poly(im, [(68, 62), (98, 34), (120, 46), (106, 60), (118, 70), (94, 70), (72, 74)], wing)
    poly(im, [(60, 62), (36, 44), (20, 50), (32, 62), (24, 68), (40, 68), (56, 72)],
         mix(wing, P["violet"], 0.4))
    poly(im, [(68, 62), (92, 44), (108, 50), (96, 62), (104, 68), (88, 68), (72, 72)],
         mix(wing, P["violet"], 0.4))
    # body
    ell(im, (54, 50, 74, 84), body)
    # ears
    poly(im, [(56, 52), (50, 34), (62, 48)], body)
    poly(im, [(72, 52), (78, 34), (66, 48)], body)
    _eyes(im, 64, 62, 5, 2.2, P["blood"], 6)
    poly(im, [(58, 70), (70, 70), (64, 76)], P["bone"])
    shade_volume(im, 1.1, 0.66)
    return finalize(outline(im, 2.2), OUT_W, H)


def armored_knight() -> Image.Image:
    im = new(OUT_W, H)
    st, st_d = P["steel"], P["steel_dk"]
    m = (86, 92, 108, 255)
    # legs
    rrect(im, (50, 94, 62, 120), 3, st_d)
    rrect(im, (68, 94, 80, 120), 3, st_d)
    # torso
    rrect(im, (44, 56, 84, 98), 6, m)
    poly(im, [(52, 60), (76, 60), (72, 82), (64, 90), (56, 82)], P["steel_lt"])
    # shoulder spikes
    circle(im, 42, 64, 10, m)
    circle(im, 86, 64, 10, m)
    poly(im, [(32, 62), (24, 44), (44, 58)], st_d)
    poly(im, [(96, 62), (104, 44), (84, 58)], st_d)
    # shield
    poly(im, [(26, 72), (42, 68), (44, 98), (34, 112), (22, 98)], (54, 46, 66, 255))
    poly(im, [(29, 76), (39, 73), (40, 96), (34, 104), (26, 96)], P["blood_dk"])
    # mace arm
    line(im, (88, 74), (104, 96), st_d, 5)
    circle(im, 106, 100, 8, st)
    for a in range(0, 360, 60):
        import math
        line(im, (106, 100), (106 + 10 * math.cos(math.radians(a)), 100 + 10 * math.sin(math.radians(a))), st_d, 2.6)
    # helm
    rrect(im, (48, 22, 80, 60), 7, m)
    rrect(im, (52, 36, 76, 48), 3, (10, 8, 14, 255))
    _eyes(im, 64, 42, 7, 2.2, P["blood"], 6)
    poly(im, [(64, 22), (64, 8), (74, 20)], P["gold_dk"])
    shade_volume(im, 1.14, 0.66)
    return finalize(outline(im, 2.4), OUT_W, H)


def ghost() -> Image.Image:
    im = new(OUT_W, H)
    body = (208, 226, 246, 232)
    edge = (150, 178, 208, 220)
    # body sheet
    poly(im, [(64, 20), (92, 40), (96, 78), (104, 96), (92, 92), (86, 104), (74, 94),
              (64, 106), (54, 94), (42, 104), (36, 92), (24, 96), (32, 78), (36, 40)], body)
    # inner shading
    poly(im, [(64, 30), (82, 46), (84, 78), (76, 88), (64, 96), (52, 88), (44, 78), (46, 46)], edge)
    poly(im, [(64, 36), (76, 48), (78, 76), (70, 84), (64, 88), (58, 84), (50, 76), (52, 48)], (236, 244, 255, 210))
    # arms
    poly(im, [(36, 56), (18, 66), (22, 74), (38, 70)], body)
    poly(im, [(92, 56), (110, 66), (106, 74), (90, 70)], body)
    # face
    ell(im, (44, 36, 84, 68), (16, 12, 24, 255))
    _eyes(im, 64, 50, 8, 3.0, P["teal"], 9)
    ell(im, (58, 58, 70, 68), (24, 18, 32, 255))
    shade_volume(im, 1.05, 0.86)
    im = outline(im, 2.0)
    add_glow(im, 64, 52, 22, P["teal"], 0.25)
    return finalize(im, OUT_W, H)


def exploding_imp() -> Image.Image:
    im = new(OUT_W, H)
    body = (206, 66, 52, 255)
    body_d = (140, 34, 34, 255)
    # wings
    poly(im, [(50, 62), (28, 44), (16, 56), (34, 66), (48, 70)], body_d)
    poly(im, [(78, 62), (100, 44), (112, 56), (94, 66), (80, 70)], body_d)
    # legs
    limb(im, [(56, 96), (50, 114)], 5, body_d)
    limb(im, [(72, 96), (78, 114)], 5, body_d)
    # body
    ell(im, (46, 56, 82, 102), body)
    poly(im, [(56, 92), (72, 92), (68, 102), (60, 102)], body_d)
    # arms
    limb(im, [(50, 68), (36, 84)], 5, body)
    limb(im, [(78, 68), (92, 84)], 5, body)
    # head
    ell(im, (48, 32, 80, 64), body)
    poly(im, [(50, 36), (42, 18), (58, 32)], (52, 20, 24, 255))
    poly(im, [(78, 36), (86, 18), (70, 32)], (52, 20, 24, 255))
    _eyes(im, 64, 46, 7, 2.8, P["ember_lt"], 8)
    poly(im, [(56, 56), (72, 56), (64, 64)], (24, 8, 12, 255))
    # fuse spark above head
    line(im, (64, 30), (70, 18), P["steel_dk"], 2)
    circle(im, 71, 16, 3.4, P["ember_lt"])
    shade_volume(im, 1.12, 0.7)
    im = outline(im, 2.2)
    add_glow(im, 71, 16, 10, P["ember"], 0.85)
    return finalize(im, OUT_W, H)


def necromancer() -> Image.Image:
    im = new(OUT_W, H)
    robe = (84, 50, 122, 255)
    robe_d = (48, 26, 74, 255)
    # robe
    poly(im, [(64, 46), (94, 74), (96, 120), (64, 114), (32, 120), (34, 74)], robe_d)
    poly(im, [(50, 60), (78, 60), (86, 104), (64, 112), (42, 104)], robe)
    # staff with green orb
    line(im, (96, 20), (100, 120), (60, 44, 36, 255), 3.4)
    circle(im, 96, 20, 9, P["rot"])
    circle(im, 94, 18, 4, P["rot_lt"])
    # arms
    limb(im, [(48, 68), (34, 90)], 6, robe)
    limb(im, [(80, 68), (92, 86)], 6, robe)
    # hood
    poly(im, [(64, 14), (88, 40), (84, 66), (44, 66), (40, 40)], robe_d)
    ell(im, (46, 28, 82, 66), (12, 8, 18, 255))
    # skull face
    ell(im, (52, 34, 76, 58), P["bone"])
    ell(im, (55, 42, 62, 49), (16, 10, 22, 255))
    ell(im, (66, 42, 73, 49), (16, 10, 22, 255))
    _eyes(im, 64, 46, 5.5, 1.8, P["rot_lt"], 5)
    poly(im, [(58, 53), (70, 53), (64, 59)], P["bone_dk"])
    shade_volume(im, 1.14, 0.68)
    im = outline(im, 2.4)
    add_glow(im, 96, 20, 16, P["rot"], 0.7)
    return finalize(im, OUT_W, H)


def shadow_drake() -> Image.Image:
    im = new(OUT_W, H)
    body = (56, 32, 88, 255)
    body_l = (86, 52, 124, 255)
    wing = (44, 22, 70, 255)
    # wings (large, spread)
    poly(im, [(58, 58), (26, 26), (4, 40), (18, 54), (6, 66), (32, 66), (52, 70)], wing)
    poly(im, [(70, 58), (102, 26), (124, 40), (110, 54), (122, 66), (96, 66), (76, 70)], wing)
    poly(im, [(58, 58), (32, 34), (16, 44), (30, 56), (20, 62), (38, 62), (54, 68)], body_l)
    poly(im, [(70, 58), (96, 34), (112, 44), (98, 56), (108, 62), (90, 62), (74, 68)], body_l)
    # body
    ell(im, (52, 52, 78, 96), body)
    # tail
    poly(im, [(70, 84), (98, 96), (104, 108), (88, 100), (70, 92)], body)
    poly(im, [(100, 104), (112, 112), (104, 114)], body_l)
    # neck + head
    poly(im, [(52, 60), (34, 40), (44, 32), (60, 54)], body)
    ell(im, (26, 26, 50, 46), body)
    poly(im, [(26, 30), (10, 22), (24, 38)], body_l)  # snout
    _eyes(im, 36, 34, 6, 2.2, P["magenta"], 8)
    poly(im, [(42, 26), (46, 14), (50, 28)], body_l)
    # legs
    limb(im, [(56, 88), (48, 106), (40, 112)], 5, body)
    limb(im, [(74, 88), (82, 106), (90, 112)], 5, body)
    shade_volume(im, 1.1, 0.66)
    im = outline(im, 2.2)
    add_glow(im, 36, 34, 14, P["magenta"], 0.5)
    return finalize(im, OUT_W, H)


def giant_troll() -> Image.Image:
    im = new(OUT_W, H)
    skin = (110, 150, 78, 255)
    skin_d = (66, 100, 50, 255)
    skin_l = (146, 186, 108, 255)
    # legs
    rrect(im, (42, 88, 62, 122), 8, skin_d)
    rrect(im, (68, 88, 88, 122), 8, skin_d)
    # torso
    poly(im, [(38, 54), (90, 54), (96, 96), (64, 106), (30, 96)], skin)
    poly(im, [(52, 62), (76, 62), (78, 88), (64, 96), (50, 88)], skin_l)
    # belt of bones
    rrect(im, (32, 88, 96, 96), 3, (86, 66, 48, 255))
    for i in range(4):
        circle(im, 44 + i * 14, 92, 3.4, P["bone"])
    # arms
    limb(im, [(38, 62), (20, 84), (24, 102)], 10, skin)
    limb(im, [(90, 62), (108, 82), (104, 100)], 10, skin)
    circle(im, 24, 103, 8, skin_l)
    circle(im, 104, 101, 8, skin_l)
    # club
    poly(im, [(106, 104), (120, 60), (126, 66), (112, 108)], (92, 68, 44, 255))
    ell(im, (108, 40, 128, 68), (108, 84, 56, 255))
    # head
    ell(im, (40, 22, 88, 62), skin)
    ell(im, (46, 30, 82, 56), skin_l)
    _eyes(im, 64, 38, 9, 3.0, P["ember_lt"], 7)
    poly(im, [(52, 48), (76, 48), (72, 58), (56, 58)], (26, 14, 18, 255))
    poly(im, [(50, 46), (56, 56), (58, 48)], P["bone"])
    poly(im, [(78, 46), (72, 56), (70, 48)], P["bone"])
    # tusks
    poly(im, [(44, 40), (32, 30), (44, 34)], P["bone"])
    poly(im, [(84, 40), (96, 30), (84, 34)], P["bone"])
    # hair tuft
    for i in range(4):
        poly(im, [(48 + i * 11, 24), (50 + i * 11, 10), (56 + i * 11, 24)], (64, 48, 30, 255))
    shade_volume(im, 1.16, 0.66)
    im = outline(im, 2.6)
    add_glow(im, 64, 38, 10, P["ember"], 0.25)
    return finalize(im, OUT_W, H)


def lich_king() -> Image.Image:
    im = new(OUT_W, H)
    robe = (40, 60, 76, 255)
    robe_d = (22, 34, 48, 255)
    flame = P["teal"]
    # robe
    poly(im, [(64, 40), (98, 70), (102, 122), (64, 116), (26, 122), (30, 70)], robe_d)
    poly(im, [(48, 58), (80, 58), (88, 106), (64, 114), (40, 106)], robe)
    # rib cage hint
    for i in range(3):
        line(im, (54, 70 + i * 9), (74, 70 + i * 9), P["bone_dk"], 2)
    # staff
    line(im, (100, 16), (104, 120), (58, 50, 70, 255), 4)
    circle(im, 100, 16, 11, flame)
    circle(im, 100, 16, 6, (210, 255, 250, 255))
    # arms
    limb(im, [(46, 66), (30, 90)], 7, robe)
    limb(im, [(82, 66), (94, 88)], 7, robe)
    # skull
    ell(im, (48, 22, 80, 56), P["bone"])
    ell(im, (52, 30, 60, 40), (12, 8, 16, 255))
    ell(im, (68, 30, 76, 40), (12, 8, 16, 255))
    _eyes(im, 64, 35, 7, 2.8, flame, 9)
    poly(im, [(56, 44), (72, 44), (64, 52)], (20, 14, 22, 255))
    for i in range(5):
        line(im, (56 + i * 4, 44), (56 + i * 4, 50), P["bone"], 1.4)
    # crown
    poly(im, [(46, 24), (50, 8), (58, 18), (64, 4), (70, 18), (78, 8), (82, 24), (64, 28)], P["gold"])
    circle(im, 64, 16, 3, P["magenta"])
    # shoulder skulls
    circle(im, 40, 62, 8, P["bone_dk"])
    circle(im, 88, 62, 8, P["bone_dk"])
    shade_volume(im, 1.1, 0.64)
    im = outline(im, 2.6)
    add_glow(im, 100, 16, 20, flame, 0.9)
    add_glow(im, 64, 35, 14, flame, 0.35)
    return finalize(im, OUT_W, H)


# ---------------------------------------------------------------- pickups

def xp_gem(color, size=40) -> Image.Image:
    im = new(size, size)
    c = size / 2
    poly(im, [(c, 4), (c + size * 0.30, c - 2), (c, size - 4), (c - size * 0.30, c - 2)], color)
    poly(im, [(c, 4), (c + size * 0.30, c - 2), (c, c + 2)], lighter(color, 1.45))
    poly(im, [(c, size - 4), (c - size * 0.30, c - 2), (c - size * 0.08, c + 2)], darker(color, 0.75))
    im = outline(im, 1.6, INK)
    add_glow(im, c, c, size * 0.46, color, 0.5)
    return finalize(im, size, size)


def heart_pickup() -> Image.Image:
    im = new(40, 40)
    circle(im, 15, 15, 8, P["blood"])
    circle(im, 25, 15, 8, P["blood"])
    poly(im, [(7.5, 18), (32.5, 18), (20, 33)], P["blood"])
    circle(im, 14, 13, 3, (240, 140, 160, 255))
    im = outline(im, 2.0, INK)
    add_glow(im, 20, 18, 16, P["blood"], 0.45)
    return finalize(im, 40, 40)


def soul_coin() -> Image.Image:
    im = new(32, 32)
    circle(im, 16, 16, 12, P["gold"])
    circle(im, 16, 16, 8, P["gold_dk"])
    circle(im, 16, 16, 5, (12, 8, 20, 255))
    im = outline(im, 1.8, INK)
    add_glow(im, 16, 16, 12, P["gold"], 0.4)
    return finalize(im, 32, 32)


# ---------------------------------------------------------------- props

def gravestone(kind: int) -> Image.Image:
    im = new(64, 80)
    stone = (108, 104, 126, 255)
    stone_l = (146, 142, 164, 255)
    stone_d = (72, 68, 90, 255)
    if kind == 0:
        rrect(im, (14, 22, 50, 74), 12, stone)
        rrect(im, (18, 26, 34, 50), 8, stone_l)
        line(im, (24, 40), (40, 40), stone_d, 2)
        line(im, (24, 48), (40, 48), stone_d, 2)
    elif kind == 1:
        poly(im, [(32, 8), (40, 24), (56, 26), (44, 40), (48, 58), (32, 50), (16, 58), (20, 40), (8, 26), (24, 24)], stone)
        poly(im, [(32, 14), (36, 26), (28, 30)], stone_l)
    elif kind == 2:
        rrect(im, (26, 14, 38, 64), 2, stone)
        rrect(im, (12, 26, 52, 38), 2, stone)
        rrect(im, (18, 64, 46, 74), 3, stone_d)
    else:
        rrect(im, (10, 30, 54, 74), 6, stone_d)
        rrect(im, (14, 34, 50, 70), 4, stone)
        circle(im, 32, 46, 7, stone_d)
        line(im, (32, 53), (32, 64), stone_d, 2)
    # moss
    for i in range(4):
        circle(im, 16 + i * 11, 68 + (i % 2) * 3, 4, mix(P["rot_dk"], stone, 0.3))
    shade_volume(im, 1.14, 0.72)
    return finalize(outline(im, 2.0, INK_SOFT), 64, 80)


def dead_tree() -> Image.Image:
    im = new(112, 128)
    bark = (78, 62, 66, 255)
    bark_l = (110, 90, 90, 255)
    # trunk
    poly(im, [(50, 124), (46, 82), (36, 44), (48, 46), (58, 84), (64, 124)], bark)
    poly(im, [(52, 120), (50, 86), (44, 52), (50, 56), (56, 88), (60, 120)], bark_l)
    # branches
    limb(im, [(52, 70), (30, 48), (14, 40)], 5, bark)
    limb(im, [(56, 62), (80, 40), (96, 30)], 5, bark)
    limb(im, [(50, 52), (38, 26), (34, 12)], 4, bark)
    limb(im, [(58, 54), (72, 24), (88, 14)], 4, bark)
    limb(im, [(58, 78), (84, 66), (102, 62)], 3.4, bark)
    limb(im, [(48, 88), (26, 80), (10, 82)], 3.4, bark)
    # roots
    poly(im, [(46, 118), (22, 126), (46, 124)], bark)
    poly(im, [(64, 118), (88, 126), (66, 124)], bark)
    shade_volume(im, 1.1, 0.78)
    return finalize(outline(im, 1.8, INK_SOFT), 112, 128)


def bone_pile() -> Image.Image:
    im = new(56, 40)
    for i, (x, y, r) in enumerate([(18, 26, 5), (30, 30, 5), (42, 26, 5)]):
        circle(im, x, y, r, P["bone"])
    limb(im, [(10, 32), (46, 34)], 3, P["bone_dk"])
    limb(im, [(14, 22), (40, 18)], 3, P["bone"])
    for i, (x, y) in enumerate([(20, 20), (34, 20)]):
        circle(im, x, y, 6, P["bone"])
        circle(im, x - 2, y, 1.6, (16, 12, 22, 255))
        circle(im, x + 2, y, 1.6, (16, 12, 22, 255))
    shade_volume(im, 1.1, 0.78)
    return finalize(outline(im, 1.8, INK_SOFT), 56, 40)


def candle_cluster() -> Image.Image:
    im = new(48, 56)
    wax = (232, 220, 190, 255)
    for i, (x, y0, h) in enumerate([(14, 30, 18), (24, 24, 26), (34, 34, 14)]):
        rrect(im, (x - 3, y0, x + 3, y0 + h), 2, wax)
        poly(im, [(x, y0 - 8), (x + 3, y0 - 1), (x - 3, y0 - 1)], P["ember_lt"])
    rrect(im, (6, 48, 42, 54), 2, (70, 54, 40, 255))
    im = outline(im, 1.8, INK_SOFT)
    add_glow(im, 24, 16, 18, P["ember"], 0.75)
    return finalize(im, 48, 56)


def broken_fence() -> Image.Image:
    im = new(96, 64)
    wood = (92, 74, 62, 255)
    wood_l = (120, 100, 84, 255)
    for x in (14, 46, 78):
        poly(im, [(x - 5, 60), (x - 3, 12), (x + 3, 8), (x + 5, 60)], wood)
        poly(im, [(x - 2, 58), (x - 1, 16), (x + 1, 14), (x + 2, 58)], wood_l)
    limb(im, [(8, 26), (88, 22)], 4, wood)
    limb(im, [(8, 44), (56, 40)], 4, wood_l)
    shade_volume(im, 1.1, 0.76)
    return finalize(outline(im, 1.8, INK_SOFT), 96, 64)


def cursed_urn() -> Image.Image:
    im = new(48, 56)
    clay = (86, 58, 70, 255)
    clay_l = (118, 82, 92, 255)
    ell(im, (10, 18, 38, 50), clay)
    rrect(im, (14, 8, 34, 20), 3, clay_l)
    ell(im, (12, 24, 26, 40), clay_l)
    line(im, (18, 40), (30, 44), P["gold_dk"], 2)
    shade_volume(im, 1.12, 0.74)
    return finalize(outline(im, 1.8, INK_SOFT), 48, 56)


def make_all(root: str):
    sp = os.path.join(root, "assets", "sprites")
    heroes = os.path.join(sp, "heroes")
    enemies = os.path.join(sp, "enemies")
    props = os.path.join(sp, "props")
    fx = os.path.join(sp, "fx")
    for folder in (heroes, enemies, props, fx):
        os.makedirs(folder, exist_ok=True)

    for name, fn in [
        ("hexblade", hexblade), ("ironclad", ironclad),
        ("wraithborn", wraithborn), ("stormcaller", stormcaller),
    ]:
        fn().save(os.path.join(heroes, f"{name}.png"))

    for name, fn in [
        ("shambling_corpse", shambling_corpse), ("bat_swarm", bat_swarm),
        ("armored_knight", armored_knight), ("ghost", ghost),
        ("exploding_imp", exploding_imp), ("necromancer", necromancer),
        ("shadow_drake", shadow_drake), ("giant_troll", giant_troll),
        ("lich_king", lich_king),
    ]:
        fn().save(os.path.join(enemies, f"{name}.png"))

    xp_gem((86, 208, 255, 255)).save(os.path.join(fx, "gem_blue.png"))
    xp_gem((126, 240, 130, 255)).save(os.path.join(fx, "gem_green.png"))
    xp_gem((255, 122, 176, 255)).save(os.path.join(fx, "gem_pink.png"))
    heart_pickup().save(os.path.join(fx, "heart.png"))
    soul_coin().save(os.path.join(fx, "soul_coin.png"))
    shadow_sprite(64, 20, 120).save(os.path.join(fx, "shadow.png"))
    orb_sprite((136, 84, 236, 255), (206, 150, 255, 255)).save(os.path.join(fx, "orb.png"))
    orb_sprite((236, 60, 190, 255), (255, 190, 240, 255)).save(os.path.join(fx, "orb_chaos.png"))
    dagger_sprite().save(os.path.join(fx, "dagger.png"))
    blade_sprite().save(os.path.join(fx, "blade.png"))
    bolt_sprite().save(os.path.join(fx, "bolt.png"))

    for i in range(4):
        gravestone(i).save(os.path.join(props, f"gravestone_{i}.png"))
    dead_tree().save(os.path.join(props, "dead_tree.png"))
    bone_pile().save(os.path.join(props, "bones.png"))
    candle_cluster().save(os.path.join(props, "candles.png"))
    broken_fence().save(os.path.join(props, "fence.png"))
    cursed_urn().save(os.path.join(props, "urn.png"))
    print("sprites done")


# ---------------------------------------------------------------- weapon fx

def orb_sprite(color, ring_color) -> Image.Image:
    im = new(64, 64)
    circle(im, 32, 32, 13, color)
    circle(im, 28, 27, 6, lighter(color, 1.7))
    circle(im, 38, 37, 4, darker(color, 0.6))
    im = outline(im, 1.4, INK)
    # orbiting ring
    d(im).ellipse([S(9), S(20), S(55), S(44)], outline=ring_color, width=S(1.6))
    add_glow(im, 32, 32, 26, color, 0.8)
    return finalize(im, 64, 64)


def dagger_sprite() -> Image.Image:
    im = new(48, 20)
    poly(im, [(6, 10), (28, 4), (44, 10), (28, 16)], P["steel_lt"])
    poly(im, [(6, 10), (28, 8), (40, 10), (28, 12)], (250, 250, 255, 255))
    rrect(im, (2, 5, 8, 15), 2, (86, 58, 44, 255))
    poly(im, [(26, 3), (44, 10), (26, 9)], P["violet_lt"])
    im = outline(im, 1.4, INK)
    add_glow(im, 30, 10, 14, P["violet"], 0.5)
    return finalize(im, 48, 20)


def blade_sprite() -> Image.Image:
    im = new(64, 32)
    poly(im, [(58, 16), (30, 5), (10, 10), (22, 16), (10, 22), (30, 27)], P["steel_lt"])
    poly(im, [(56, 16), (32, 10), (16, 12), (30, 16), (16, 20), (32, 22)], (250, 252, 255, 255))
    circle(im, 12, 16, 5, P["gold"])
    im = outline(im, 1.4, INK)
    add_glow(im, 34, 16, 18, P["gold"], 0.55)
    return finalize(im, 64, 32)


def bolt_sprite() -> Image.Image:
    im = new(48, 64)
    poly(im, [(28, 2), (10, 30), (22, 30), (16, 62), (40, 26), (26, 26), (36, 2)], P["teal"])
    poly(im, [(28, 6), (16, 27), (24, 27), (20, 48), (32, 27), (25, 27)], (235, 255, 252, 255))
    im = outline(im, 1.2, INK)
    add_glow(im, 24, 32, 26, P["teal"], 0.8)
    return finalize(im, 48, 64)


if __name__ == "__main__":
    import sys
    make_all(sys.argv[1] if len(sys.argv) > 1 else "..")
