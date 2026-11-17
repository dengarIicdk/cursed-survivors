"""Shared painting helpers for Cursed Survivors' procedural art set.

Art is authored on a supersampled canvas (SS times the output size) and
downsampled with LANCZOS, which gives the smooth cartoon edges of the
Vampire Survivors look. Every sprite gets a single dark contour computed
from the union alpha, so limbs never show internal seams.
"""

from PIL import Image, ImageDraw, ImageFilter, ImageChops

SS = 3  # supersampling factor

INK = (24, 16, 30, 255)
INK_SOFT = (44, 30, 56, 255)

P = {
    # purples / night
    "night": (26, 18, 38, 255),
    "violet": (108, 62, 158, 255),
    "violet_lt": (162, 112, 214, 255),
    "violet_dk": (62, 34, 96, 255),
    "magenta": (214, 72, 128, 255),
    "blood": (178, 32, 62, 255),
    "blood_dk": (112, 20, 44, 255),
    "teal": (86, 224, 206, 255),
    "teal_dk": (32, 128, 128, 255),
    # bone / metal / cloth
    "bone": (238, 228, 202, 255),
    "bone_dk": (186, 172, 142, 255),
    "steel": (160, 172, 190, 255),
    "steel_dk": (96, 108, 130, 255),
    "steel_lt": (208, 220, 236, 255),
    "gold": (242, 196, 84, 255),
    "gold_dk": (172, 124, 36, 255),
    # flesh / rot
    "skin": (226, 178, 146, 255),
    "skin_dk": (176, 122, 96, 255),
    "rot": (124, 156, 86, 255),
    "rot_dk": (74, 100, 56, 255),
    "rot_lt": (166, 196, 118, 255),
    # fire / glows
    "ember": (255, 138, 58, 255),
    "ember_dk": (190, 62, 26, 255),
    "ember_lt": (255, 206, 122, 255),
    "shadow": (30, 20, 44, 255),
}


def S(v: float) -> int:
    return int(round(v * SS))


def new(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finalize(img: Image.Image, w: int, h: int) -> Image.Image:
    return img.resize((w, h), Image.LANCZOS)


def rgb(c):
    return tuple(c[:3])


def darker(c, f=0.68):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), c[3] if len(c) > 3 else 255)


def lighter(c, f=1.25):
    return (
        min(255, int(c[0] * f)),
        min(255, int(c[1] * f)),
        min(255, int(c[2] * f)),
        c[3] if len(c) > 3 else 255,
    )


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def d(img):
    return ImageDraw.Draw(img)


def ell(img, box, fill, outline=None, width=0):
    x0, y0, x1, y1 = [S(v) for v in box]
    d(img).ellipse([x0, y0, x1, y1], fill=fill, outline=outline, width=S(width) if outline else 0)


def circle(img, cx, cy, r, fill, outline=None, width=0):
    ell(img, (cx - r, cy - r, cx + r, cy + r), fill, outline, width)


def poly(img, pts, fill, outline=None, width=0):
    p = [(S(x), S(y)) for x, y in pts]
    d(img).polygon(p, fill=fill)
    if outline:
        d(img).line(p + [p[0]], fill=outline, width=max(1, S(width)), joint="curve")


def rrect(img, box, r, fill, outline=None, width=0):
    x0, y0, x1, y1 = [S(v) for v in box]
    d(img).rounded_rectangle(
        [x0, y0, x1, y1], radius=S(r), fill=fill,
        outline=outline, width=S(width) if outline else 0,
    )


def line(img, p1, p2, color, w, caps=True):
    (x1, y1), (x2, y2) = (S(p1[0]), S(p1[1])), (S(p2[0]), S(p2[1]))
    d(img).line([x1, y1, x2, y2], fill=color, width=S(w))
    if caps:
        r = S(w) / 2.0
        for x, y in ((x1, y1), (x2, y2)):
            d(img).ellipse([x - r, y - r, x + r, y + r], fill=color)


def limb(img, pts, w, color):
    for i in range(len(pts) - 1):
        line(img, pts[i], pts[i + 1], color, w)


def vgrad(w, h, top, bottom):
    """Vertical gradient image of RGBA colors top -> bottom (supersampled size)."""
    g = Image.new("RGBA", (1, h), (0, 0, 0, 0))
    px = g.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4))
    return g.resize((w, h), Image.BILINEAR)


def radial(size, color, power=1.6):
    """Radial glow sprite: color at the centre fading to transparent."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = size / 2.0
    for y in range(size):
        for x in range(size):
            dist = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            a = max(0.0, 1.0 - dist) ** power
            px[x, y] = (color[0], color[1], color[2], int(255 * a * (color[3] / 255)))
    return img


def add_glow(img, cx, cy, radius, color, alpha=1.0):
    """Additive radial glow drawn in output pixels."""
    r = S(radius)
    g = radial(r * 2, (color[0], color[1], color[2], int(255 * alpha)))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    layer.paste(g, (S(cx) - r, S(cy) - r), g)
    img.alpha_composite(layer)


def shade_volume(img, top=1.16, bottom=0.74, offset=0):
    """Multiply a vertical light ramp onto the sprite for cartoon volume."""
    w, h = img.size
    ramp = Image.new("L", (1, h))
    px = ramp.load()
    for y in range(h):
        t = min(1.0, max(0.0, (y - offset) / max(1, h - offset)))
        px[0, y] = int(255 * (bottom + (top - bottom) * (1.0 - t)))
    ramp = ramp.resize((w, h), Image.BILINEAR).convert("RGB")
    rgbimg = img.convert("RGB")
    out = ImageChops.multiply(rgbimg, ramp).convert("RGBA")
    out.putalpha(img.getchannel("A"))
    img.paste(out, (0, 0))


def inner_glow(img, cx, cy, radius, color, alpha=0.5):
    """Soft light blob clipped to the existing silhouette."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    r = S(radius)
    g = radial(r * 2, (color[0], color[1], color[2], int(255 * alpha)))
    layer.paste(g, (S(cx) - r, S(cy) - r), g)
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), img.getchannel("A")))
    img.alpha_composite(layer)


def outline(img, width=2.4, color=INK, extra_soft=True):
    """Wrap the union silhouette in a dark contour (the cartoon ink look)."""
    a = img.getchannel("A")
    size = S(width) * 2 + 1
    grown = a.filter(ImageFilter.MaxFilter(size))
    if extra_soft:
        grown = grown.filter(ImageFilter.GaussianBlur(S(0.35)))
    sil = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sil.paste(Image.new("RGBA", img.size, color), (0, 0), grown)
    sil.alpha_composite(img)
    return sil


def shadow_sprite(w=56, h=18, alpha=110):
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    d(img).ellipse([0, 0, img.size[0] - 1, img.size[1] - 1], fill=(8, 4, 14, alpha))
    img = img.filter(ImageFilter.GaussianBlur(S(1.6)))
    return finalize(img, w, h)


def save(img, path, w, h):
    finalize(img, w, h).save(path)