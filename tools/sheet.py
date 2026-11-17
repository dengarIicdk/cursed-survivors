import os, sys
from PIL import Image, ImageDraw
root = ".."
files = []
for sub in ("heroes", "enemies", "props", "fx"):
    d = os.path.join(root, "assets/sprites", sub)
    for f in sorted(os.listdir(d)):
        files.append(os.path.join(d, f))
cols, cell = 7, 170
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGBA", (cols*cell, rows*cell), (26, 20, 34, 255))
dr = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGBA")
    im.thumbnail((cell-20, cell-34), Image.LANCZOS)
    x = (i % cols)*cell + (cell-im.width)//2
    y = (i // cols)*cell + 6
    sheet.alpha_composite(im, (x, y))
    dr.text(((i % cols)*cell + 6, (i // cols)*cell + cell - 24), os.path.basename(f)[:-4], fill=(220,210,230,255))
out = os.path.expanduser("~/.tmp_shots/sheet.png")
sheet.save(out)
print(out, sheet.size)
