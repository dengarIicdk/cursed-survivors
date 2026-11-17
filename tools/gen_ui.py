"""Icons, UI 9-patch frames, effect textures and the painted menu backdrop."""

import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from artlib import (
    INK, INK_SOFT, P, S, SS, add_glow, circle, d, darker, ell, finalize, lighter, limb,
    line, mix, new, outline, poly, radial, rrect, save, shade_volume,
)

ICON = 64


def _icon_canvas():
    return new(ICON, ICON)


def _gem(im, cx, cy, r, color):
    poly(im, [(cx, cy - r), (cx + r * 0.8, cy), (cx, cy + r), (cx - r * 0.8, cy)], color)
    poly(im, [(cx, cy - r), (cx + r * 0.8, cy), (cx, cy + r * 0.5)], lighter(color, 1.4))


def ic_bloodstone():
    im = _icon_canvas()
    _gem(im, 32, 34, 22, P["blood"])
    for i in range(3):
        poly(im, [(28 + i * 4, 48), (30 + i * 4, 58), (32 + i * 4, 48)], P["blood_dk"])
    add_glow(im, 32, 34, 20, P["magenta"], 0.5)
    return outline(im, 2.2)


def ic_iron_heart():
    im = _icon_canvas()
    st = P["steel"]
    circle(im, 24, 26, 13, st)
    circle(im, 40, 26, 13, st)
    poly(im, [(11, 30), (53, 30), (32, 56)], st)
    circle(im, 24, 22, 6, P["steel_lt"])
    rrect(im, (28, 20, 36, 46), 2, P["gold_dk"])
    return outline(im, 2.4)


def ic_boots():
    im = _icon_canvas()
    for x in (14, 32):
        poly(im, [(x, 14), (x + 14, 14), (x + 14, 40), (x + 22, 46), (x + 22, 52), (x - 4, 52), (x - 4, 40)], (108, 74, 52, 255))
        poly(im, [(x + 2, 18), (x + 10, 18), (x + 10, 40), (x + 2, 40)], (140, 100, 70, 255))
        poly(im, [(x, 48), (x + 20, 48), (x + 20, 52), (x - 4, 52)], (62, 44, 34, 255))
    # speed streaks
    for i, y in enumerate((20, 30, 40)):
        line(im, (44, y), (58, y), P["teal"], 2)
    im = outline(im, 2.2)
    add_glow(im, 50, 30, 16, P["teal"], 0.3)
    return im


def ic_grimoire():
    im = _icon_canvas()
    poly(im, [(10, 14), (34, 18), (34, 54), (10, 50)], P["violet_dk"])
    poly(im, [(36, 18), (58, 14), (58, 50), (36, 54)], P["violet"])
    poly(im, [(13, 18), (32, 22), (32, 50), (13, 46)], P["bone"])
    poly(im, [(38, 22), (55, 18), (55, 46), (38, 50)], P["bone"])
    line(im, (18, 28), (28, 30), P["blood_dk"], 2)
    line(im, (18, 36), (28, 38), P["blood_dk"], 2)
    circle(im, 46, 32, 6, P["violet_lt"])
    circle(im, 46, 32, 3, P["magenta"])
    im = outline(im, 2.2)
    add_glow(im, 46, 32, 14, P["magenta"], 0.45)
    return im


def ic_cloak():
    im = _icon_canvas()
    poly(im, [(32, 10), (54, 26), (58, 56), (32, 48), (6, 56), (10, 26)], (44, 52, 74, 255))
    poly(im, [(32, 16), (46, 28), (48, 50), (32, 44), (16, 50), (18, 28)], (68, 82, 110, 255))
    poly(im, [(26, 20), (38, 20), (36, 30), (28, 30)], (12, 8, 18, 255))
    circle(im, 29, 25, 2, P["teal"])
    circle(im, 35, 25, 2, P["teal"])
    return outline(im, 2.2)


def ic_lantern():
    im = _icon_canvas()
    line(im, (32, 6), (32, 16), P["steel_dk"], 3)
    rrect(im, (18, 16, 46, 48), 4, (52, 46, 40, 255))
    rrect(im, (22, 20, 42, 44), 3, (255, 226, 158, 255))
    circle(im, 32, 33, 7, (255, 244, 208, 255))
    rrect(im, (14, 48, 50, 55), 3, P["steel_dk"])
    for x in (26, 32, 38):
        line(im, (x, 18), (x, 20), P["steel_dk"], 1.4)
    im = outline(im, 2.2)
    add_glow(im, 32, 33, 22, P["ember"], 0.6)
    return im


def ic_ring():
    im = _icon_canvas()
    circle(im, 32, 38, 20, P["gold_dk"])
    circle(im, 32, 38, 14, (16, 12, 22, 255))
    poly(im, [(32, 6), (42, 18), (32, 30), (22, 18)], P["magenta"])
    poly(im, [(32, 8), (38, 17), (32, 22)], P["violet_lt"])
    im = outline(im, 2.2)
    add_glow(im, 32, 18, 14, P["magenta"], 0.5)
    return im


def ic_feather():
    im = _icon_canvas()
    poly(im, [(18, 56), (30, 22), (46, 10), (52, 16), (44, 34), (24, 54)], P["ember"])
    poly(im, [(22, 52), (34, 26), (46, 16), (40, 30), (26, 50)], P["ember_lt"])
    line(im, (18, 58), (50, 14), P["ember_dk"], 2)
    for i in range(4):
        line(im, (30 + i * 4, 40 - i * 6), (38 + i * 4, 34 - i * 6), P["ember_dk"], 1.4)
    im = outline(im, 2.2)
    add_glow(im, 32, 34, 18, P["ember"], 0.45)
    return im


def ic_hourglass():
    im = _icon_canvas()
    poly(im, [(16, 10), (48, 10), (48, 16), (34, 30), (34, 34), (48, 48), (48, 54), (16, 54), (16, 48), (30, 34), (30, 30), (16, 16)], (198, 220, 232, 235))
    rrect(im, (12, 6, 52, 12), 2, P["gold_dk"])
    rrect(im, (12, 52, 52, 58), 2, P["gold_dk"])
    poly(im, [(20, 40), (44, 40), (32, 52)], P["teal"])
    poly(im, [(19, 14), (45, 14), (32, 26)], P["teal"])
    im = outline(im, 2.2)
    add_glow(im, 32, 36, 18, P["teal"], 0.35)
    return im


def ic_crown():
    im = _icon_canvas()
    poly(im, [(8, 46), (12, 16), (24, 30), (32, 10), (40, 30), (52, 16), (56, 46)], P["gold"])
    poly(im, [(12, 44), (16, 22), (26, 34), (32, 18), (38, 34), (48, 22), (52, 44)], P["gold_dk"])
    for x, c in ((32, P["magenta"]), (18, P["teal"]), (46, P["teal"])):
        circle(im, x, 26 if x == 32 else 34, 4, c)
    rrect(im, (8, 44, 56, 54), 3, P["gold_dk"])
    im = outline(im, 2.2)
    add_glow(im, 32, 30, 18, P["gold"], 0.4)
    return im


def ic_arcane_orb():
    im = _icon_canvas()
    circle(im, 32, 32, 16, P["violet"])
    circle(im, 32, 32, 10, P["violet_lt"])
    circle(im, 28, 26, 5, (240, 226, 255, 255))
    for a in range(0, 360, 45):
        r = math.radians(a)
        circle(im, 32 + 22 * math.cos(r), 32 + 22 * math.sin(r), 3, P["magenta"])
    im = outline(im, 2.2)
    add_glow(im, 32, 32, 24, P["magenta"], 0.65)
    return im


def ic_blade_aura():
    im = _icon_canvas()
    for a in range(0, 360, 60):
        r = math.radians(a)
        x0, y0 = 32 + 20 * math.cos(r), 32 + 20 * math.sin(r)
        x1, y1 = 32 + 30 * math.cos(r), 32 + 30 * math.sin(r)
        line(im, (x0, y0), (x1, y1), P["gold"], 4)
    circle(im, 32, 32, 15, (255, 226, 150, 120))
    poly(im, [(32, 14), (38, 32), (32, 50), (26, 32)], P["steel_lt"])
    im = outline(im, 2.2)
    add_glow(im, 32, 32, 22, P["gold"], 0.5)
    return im


def ic_daggers():
    im = _icon_canvas()
    poly(im, [(18, 54), (24, 20), (30, 54)], P["steel_lt"])
    poly(im, [(36, 54), (42, 16), (48, 54)], P["steel_lt"])
    line(im, (16, 42), (32, 42), P["blood_dk"], 3)
    line(im, (34, 38), (50, 38), P["blood_dk"], 3)
    poly(im, [(22, 54), (26, 58), (30, 54)], (60, 40, 30, 255))
    poly(im, [(40, 54), (44, 58), (48, 54)], (60, 40, 30, 255))
    im = outline(im, 2.0)
    add_glow(im, 32, 34, 18, P["violet"], 0.4)
    return im


def ic_lightning():
    im = _icon_canvas()
    poly(im, [(38, 6), (20, 34), (30, 34), (24, 58), (46, 26), (34, 26)], P["teal"])
    poly(im, [(36, 10), (26, 30), (33, 30), (28, 46)], (215, 255, 250, 255))
    im = outline(im, 2.2)
    add_glow(im, 32, 32, 22, P["teal"], 0.7)
    return im


ICONS = {
    "bloodstone": ic_bloodstone, "iron_heart": ic_iron_heart, "quicksilver_boots": ic_boots,
    "grimoire": ic_grimoire, "shadow_cloak": ic_cloak, "soul_lantern": ic_lantern,
    "cursed_ring": ic_ring, "phoenix_feather": ic_feather, "time_shard": ic_hourglass,
    "leech_crown": ic_crown, "arcane_orbs": ic_arcane_orb, "blade_aura": ic_blade_aura,
    "shadow_daggers": ic_daggers, "lightning_chain": ic_lightning,
}


# ---------------------------------------------------------------- 9-patch frames

def frame(path, size, fill_top, fill_bot, border, glow, corner=22, inner=True):
    im = new(size, size)
    w, h = size, size
    # body gradient
    body = Image.new("RGBA", im.size, (0, 0, 0, 0))
    grad = Image.new("RGBA", (1, im.size[1]))
    px = grad.load()
    for y in range(im.size[1]):
        t = y / (im.size[1] - 1)
        px[0, y] = tuple(int(fill_top[i] + (fill_bot[i] - fill_top[i]) * t) for i in range(4))
    grad = grad.resize(im.size, Image.BILINEAR)
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [S(1.2), S(1.2), S(w - 1.2), S(h - 1.2)], radius=S(corner), fill=255)
    body.paste(grad, (0, 0), mask)
    # border
    brd = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(brd).rounded_rectangle(
        [S(1.4), S(1.4), S(w - 1.4), S(h - 1.4)], radius=S(corner),
        outline=border, width=S(1.6))
    if inner:
        ImageDraw.Draw(brd).rounded_rectangle(
            [S(4.2), S(4.2), S(w - 4.2), S(h - 4.2)], radius=S(corner - 3),
            outline=(255, 255, 255, 26), width=S(1.0))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(body)
    if glow:
        g = brd.filter(ImageFilter.GaussianBlur(S(2.2)))
        out.alpha_composite(g)
    out.alpha_composite(brd)
    im = out
    # corner studs
    for x, y in ((corner * 0.55, corner * 0.55), (w - corner * 0.55, corner * 0.55),
                 (corner * 0.55, h - corner * 0.55), (w - corner * 0.55, h - corner * 0.55)):
        circle(im, x, y, 1.9, border)
    finalize(im, w, h).save(path)


# ---------------------------------------------------------------- fx textures

def fx_textures(folder):
    os.makedirs(folder, exist_ok=True)
    # soft dust / spark
    for name, size, color in [
        ("dust", 32, (255, 236, 210, 255)),
        ("spark", 24, (255, 226, 160, 255)),
        ("glow", 64, (255, 255, 255, 255)),
    ]:
        im = radial(size * SS, color, 1.8)
        im.save(os.path.join(folder, f"{name}.png"))
    # blood splat
    rnd = random.Random(7)
    im = new(48, 48)
    for i in range(9):
        a = rnd.uniform(0, math.tau)
        r = rnd.uniform(2, 16)
        circle(im, 24 + r * math.cos(a), 24 + r * math.sin(a), rnd.uniform(2.5, 5.5), P["blood"])
    circle(im, 24, 24, 10, P["blood_dk"])
    finalize(im, 48, 48).save(os.path.join(folder, "blood.png"))
    # slash arc
    im = new(96, 96)
    for i in range(3):
        d(im).arc([S(14 + i * 4), S(14 + i * 4), S(82 - i * 4), S(82 - i * 4)],
                  start=-60, end=70, fill=(255, 255, 255, 235 - i * 60), width=S(3 - i * 0.6))
    im = im.filter(ImageFilter.GaussianBlur(S(0.6)))
    finalize(im, 96, 96).save(os.path.join(folder, "slash.png"))
    # soft cloud blob for lightning storm
    im = radial(64 * SS, (180, 200, 255, 210), 1.3)
    im.save(os.path.join(folder, "cloud.png"))
    # ring for shockwaves
    im = new(128, 128)
    d(im).ellipse([S(6), S(6), S(122), S(122)], outline=(255, 255, 255, 230), width=S(4))
    im = im.filter(ImageFilter.GaussianBlur(S(1.4)))
    finalize(im, 128, 128).save(os.path.join(folder, "ring.png"))


# ---------------------------------------------------------------- menu backdrop

def menu_background(path, w=1280, h=720):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    px = im.load()
    # sky gradient: deep indigo -> violet near horizon
    top = (14, 10, 26)
    mid = (48, 22, 62)
    hor = (118, 46, 92)
    for y in range(h):
        t = y / (h - 1)
        if t < 0.62:
            k = t / 0.62
            c = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.62) / 0.38
            c = tuple(int(mid[i] + (hor[i] - mid[i]) * k) for i in range(3))
        for x in range(w):
            px[x, y] = (*c, 255)
    dr = ImageDraw.Draw(im, "RGBA")

    # stars
    rnd = random.Random(11)
    for _ in range(220):
        x, y = rnd.randrange(w), rnd.randrange(0, int(h * 0.55))
        a = rnd.randint(40, 190)
        s = rnd.choice([0, 0, 1])
        dr.point([(x, y)], fill=(230, 230, 255, a))
        if s:
            dr.point([(x + 1, y), (x, y + 1)], fill=(230, 230, 255, max(20, a - 90)))

    # moon
    mx, my, mr = 940, 190, 92
    glow = radial(mr * 6, (255, 226, 200, 150), 2.4).resize((mr * 12, mr * 12), Image.LANCZOS)
    im.alpha_composite(glow, (mx - mr * 6, my - mr * 6))
    dr.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=(248, 240, 218, 255))
    dr.ellipse([mx - mr + 18, my - mr + 26, mx + mr - 30, my + mr - 8], fill=(236, 226, 202, 255))
    for cx, cy, cr in [(mx - 30, my - 20, 16), (mx + 26, my + 30, 12), (mx + 8, my - 42, 9)]:
        dr.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(222, 210, 188, 255))

    # bats
    def bat(x, y, s):
        dr.polygon([(x, y), (x - s, y - s * 0.8), (x - s * 1.8, y - s * 0.2),
                    (x - s * 0.7, y + s * 0.2), (x, y + s * 0.4)], fill=(18, 12, 26, 235))
        dr.polygon([(x, y), (x + s, y - s * 0.8), (x + s * 1.8, y - s * 0.2),
                    (x + s * 0.7, y + s * 0.2), (x, y + s * 0.4)], fill=(18, 12, 26, 235))

    for bx, by, bs in [(300, 150, 9), (340, 180, 6), (560, 120, 7), (1120, 300, 6),
                       (200, 240, 5), (700, 90, 5)]:
        bat(bx, by, bs)

    # distant hills
    dr.polygon([(0, 470), (220, 380), (430, 450), (640, 360), (900, 440), (1120, 380),
                (1280, 450), (1280, 720), (0, 720)], fill=(30, 18, 40, 255))
    # cathedral silhouette
    cx = 250
    dr.polygon([(cx - 120, 470), (cx - 120, 330), (cx - 96, 300), (cx - 70, 330),
                (cx - 70, 250), (cx - 44, 200), (cx - 18, 250), (cx - 18, 330),
                (cx + 10, 300), (cx + 34, 330), (cx + 34, 380), (cx + 90, 380),
                (cx + 90, 470)], fill=(24, 14, 34, 255))
    dr.polygon([(cx - 44, 200), (cx - 30, 150), (cx - 18, 200)], fill=(24, 14, 34, 255))
    for wx_, wy_ in [(cx - 60, 360), (cx - 60, 410), (cx + 40, 400), (cx - 10, 350)]:
        dr.ellipse([wx_ - 7, wy_ - 12, wx_ + 7, wy_ + 12], fill=(196, 46, 70, 210))
        dr.ellipse([wx_ - 3, wy_ - 6, wx_ + 3, wy_ + 6], fill=(255, 158, 150, 230))
    # ruins / arches
    for ax in (1180, 1210):
        dr.rectangle([ax, 400, ax + 16, 480], fill=(24, 14, 34, 255))
        dr.pieslice([ax - 4, 370, ax + 20, 420], 180, 360, fill=(24, 14, 34, 255))

    # ground hill
    dr.polygon([(0, 560), (160, 520), (420, 548), (700, 508), (980, 536), (1280, 500),
                (1280, 720), (0, 720)], fill=(22, 14, 30, 255))
    dr.polygon([(0, 620), (300, 590), (640, 612), (960, 584), (1280, 600), (1280, 720), (0, 720)],
               fill=(16, 10, 24, 255))

    # gravestones + trees silhouettes
    def stone(x, y, ww, hh, tilt=0):
        dr.rounded_rectangle([x - ww, y - hh, x + ww, y], radius=ww * 0.8,
                             fill=(20, 13, 28, 255))
        if tilt:
            dr.rectangle([x - 3, y - hh * 0.4, x + 3, y - hh * 0.1], fill=(14, 9, 20, 255))

    def tree(x, y, scale=1.0):
        dr.polygon([(x - 8 * scale, y), (x - 4 * scale, y - 110 * scale), (x + 2 * scale, y - 150 * scale),
                    (x + 7 * scale, y - 108 * scale), (x + 9 * scale, y)], fill=(14, 9, 20, 255))
        for ang, ln in [(-1.9, 62), (-1.2, 48), (-0.5, 56), (0.3, 40), (-2.4, 34)]:
            x0, y0 = x, y - 92 * scale
            x1 = x0 + math.cos(ang) * ln * scale
            y1 = y0 + math.sin(ang) * ln * scale
            dr.line([(x0, y0), (x1, y1)], fill=(14, 9, 20, 255), width=int(5 * scale))
            dr.line([(x1, y1), (x1 + math.cos(ang - 0.4) * 26 * scale,
                               y1 + math.sin(ang - 0.4) * 26 * scale)], fill=(14, 9, 20, 255),
                    width=int(3 * scale))

    for sx, sy, sw, sh in [(140, 640, 16, 54), (250, 668, 12, 40), (360, 620, 20, 66),
                           (470, 660, 14, 44), (760, 650, 18, 58), (880, 676, 12, 38),
                           (1020, 630, 22, 70), (1150, 668, 15, 46)]:
        stone(sx, sy, sw, sh)
    for tx, ty, ts in [(60, 700, 1.35), (600, 690, 1.1), (830, 700, 1.25), (1230, 690, 1.0)]:
        tree(tx, ty, ts)

    # fog bands
    fog = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog, "RGBA")
    for i in range(9):
        y = 470 + i * 24
        fd.ellipse([-200 + i * 40, y - 40, 400 + i * 60, y + 40], fill=(150, 110, 190, 16))
        fd.ellipse([600 - i * 30, y - 30, 1400 - i * 50, y + 30], fill=(170, 130, 210, 14))
    fog = fog.filter(ImageFilter.GaussianBlur(24))
    im.alpha_composite(fog)

    # hero silhouette in the centre foreground
    hx, hy = 892, 690
    dr.ellipse([hx - 46, hy - 12, hx + 46, hy + 14], fill=(8, 5, 14, 170))
    dr.polygon([(hx - 22, hy), (hx - 16, hy - 74), (hx + 14, hy - 74), (hx + 24, hy)],
               fill=(10, 6, 16, 255))
    dr.ellipse([hx - 17, hy - 108, hx + 13, hy - 78], fill=(10, 6, 16, 255))
    dr.polygon([(hx - 20, hy - 96), (hx - 26, hy - 66), (hx - 8, hy - 74)], fill=(10, 6, 16, 255))
    dr.polygon([(hx + 16, hy - 96), (hx + 22, hy - 66), (hx + 4, hy - 74)], fill=(10, 6, 16, 255))
    # glowing blade
    # lantern glow instead of a blade so nothing cuts across the UI
    lantern = radial(120, (255, 176, 116, 90), 2.0)
    im.alpha_composite(lantern, (hx + 44 - 60, hy - 96 - 60))
    dr.ellipse([hx + 40, hy - 102, hx + 49, hy - 93], fill=(255, 208, 150, 225))

    # vignette
    vig = Image.new("L", (w, h), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-w * 0.25, -h * 0.35, w * 1.25, h * 1.35], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGBA", (w, h), (6, 3, 12, 255))
    dark.putalpha(Image.eval(vig, lambda v: int((255 - v) * 0.85)))
    im.alpha_composite(dark)

    im.convert("RGB").save(path, quality=92)


# ---------------------------------------------------------------- bars & hud

def bar_texture(path, w, h, top, bottom, border, gloss=True, corner=None):
    im = new(w, h)
    c = corner if corner is not None else h / 2.0
    grad = Image.new("RGBA", (1, im.size[1]))
    px = grad.load()
    for y in range(im.size[1]):
        t = y / (im.size[1] - 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4))
    grad = grad.resize(im.size, Image.BILINEAR)
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [S(1), S(1), S(w - 1), S(h - 1)], radius=S(c), fill=255)
    im.paste(grad, (0, 0), mask)
    if gloss:
        gl = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(gl).rounded_rectangle(
            [S(2.5), S(2.0), S(w - 2.5), S(h * 0.55)], radius=S(c * 0.8),
            fill=(255, 255, 255, 46))
        gl.putalpha(ImageChops.multiply(gl.getchannel("A"), mask))
        im.alpha_composite(gl)
    ImageDraw.Draw(im).rounded_rectangle(
        [S(1), S(1), S(w - 1), S(h - 1)], radius=S(c), outline=border, width=S(1.3))
    finalize(im, w, h).save(path)


def hud_icons(folder):
    os.makedirs(folder, exist_ok=True)
    # skull
    im = new(32, 32)
    ell(im, (6, 4, 26, 24), P["bone"])
    poly(im, [(9, 22), (23, 22), (21, 29), (11, 29)], P["bone_dk"])
    circle(im, 12, 14, 4, (18, 12, 24, 255))
    circle(im, 20, 14, 4, (18, 12, 24, 255))
    poly(im, [(15, 19), (17, 19), (16, 22)], (18, 12, 24, 255))
    finalize(outline(im, 1.6), 32, 32).save(os.path.join(folder, "skull.png"))
    # clock
    im = new(32, 32)
    circle(im, 16, 17, 11, P["gold_dk"])
    circle(im, 16, 17, 8, (250, 238, 210, 255))
    line(im, (16, 17), (16, 11), (30, 20, 34, 255), 2)
    line(im, (16, 17), (21, 19), (30, 20, 34, 255), 2)
    poly(im, [(12, 3), (20, 3), (18, 7), (14, 7)], P["gold"])
    finalize(outline(im, 1.6), 32, 32).save(os.path.join(folder, "clock.png"))
    # level star
    im = new(32, 32)
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 13 if i % 2 == 0 else 6
        pts.append((16 + r * math.cos(a), 17 + r * math.sin(a)))
    poly(im, pts, P["violet_lt"])
    poly(im, [(16, 5), (19, 15), (16, 18), (13, 15)], (240, 226, 255, 255))
    finalize(outline(im, 1.6), 32, 32).save(os.path.join(folder, "star.png"))


def bars(root):
    ui = os.path.join(root, "assets", "ui")
    bar_texture(os.path.join(ui, "bar_back.png"), 64, 28, (26, 18, 36, 255), (14, 9, 20, 255),
                (92, 58, 112, 255))
    bar_texture(os.path.join(ui, "bar_hp.png"), 64, 24, (240, 96, 120, 255), (140, 20, 48, 255),
                (255, 196, 206, 150))
    bar_texture(os.path.join(ui, "bar_xp.png"), 64, 18, (150, 250, 238, 255), (40, 150, 190, 255),
                (200, 255, 250, 130))
    bar_texture(os.path.join(ui, "bar_boss.png"), 64, 22, (236, 90, 150, 255), (110, 16, 60, 255),
                (255, 190, 220, 150))
    hud_icons(os.path.join(ui, "hud"))


def make_all(root):
    icons_dir = os.path.join(root, "assets", "ui", "icons")
    frame_dir = os.path.join(root, "assets", "ui", "frames")
    fx_dir = os.path.join(root, "assets", "sprites", "fx")
    os.makedirs(icons_dir, exist_ok=True)
    os.makedirs(frame_dir, exist_ok=True)

    for name, fn in ICONS.items():
        fn().save(os.path.join(icons_dir, f"{name}.png"))

    frame(os.path.join(frame_dir, "panel.png"), 80, (28, 20, 40, 244), (18, 12, 28, 244),
          (150, 84, 176, 255), True, corner=16)
    frame(os.path.join(frame_dir, "card.png"), 80, (38, 24, 54, 250), (22, 14, 34, 250),
          (176, 96, 200, 255), True, corner=14)
    frame(os.path.join(frame_dir, "button.png"), 72, (46, 28, 66, 255), (30, 18, 44, 255),
          (122, 74, 152, 255), False, corner=10)
    frame(os.path.join(frame_dir, "button_hover.png"), 72, (78, 42, 104, 255), (48, 26, 66, 255),
          (242, 196, 84, 255), True, corner=10)
    frame(os.path.join(frame_dir, "button_active.png"), 72, (28, 16, 40, 255), (20, 12, 30, 255),
          (214, 72, 128, 255), False, corner=10)
    fx_textures(fx_dir)
    bars(root)
    menu_background(os.path.join(root, "assets", "ui", "menu_background.png"))
    print("ui done")


if __name__ == "__main__":
    import sys
    make_all(sys.argv[1] if len(sys.argv) > 1 else "..")