"""Step 2 of tool/import_icon.py: square store icon and adaptive layers."""
import sys
from PIL import Image, ImageDraw, ImageFilter
S = sys.argv[1]
r = Image.open(f'{S}/rounded_1024.png')
rgb = r.convert('RGB'); px = rgb.load()
def avg(box):
    x0, y0, x1, y1 = box; n = 0; s = [0, 0, 0]
    for y in range(y0, y1, 4):
        for x in range(x0, x1, 4):
            p = px[x, y]
            if p[0] > 120 and p[1] < 70:  # red only
                s = [s[i] + p[i] for i in range(3)]; n += 1
    return tuple(v // n for v in s)
top = avg((300, 40, 724, 90)); bot = avg((300, 934, 724, 984))
print('top', top, 'bottom', bot)
def grad(size):
    g = Image.new('RGB', (size, size)); gp = g.load()
    for y in range(size):
        t = y / (size - 1); c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(size): gp[x, y] = c
    return g
sq = grad(1024).convert('RGBA'); sq.alpha_composite(r)
sq.convert('RGB').save(f'{S}/square_1024.png')
C = 432
bg = grad(C)
side = int(C * 0.70)
art = sq.convert('RGB').resize((side, side), Image.LANCZOS).convert('RGBA')
fe = Image.new('L', (side, side), 0)
ImageDraw.Draw(fe).rounded_rectangle((8, 8, side - 9, side - 9), side // 5, fill=255)
art.putalpha(fe.filter(ImageFilter.GaussianBlur(7)))
fg = Image.new('RGBA', (C, C), (0, 0, 0, 0)); fg.alpha_composite(art, ((C - side) // 2, (C - side) // 2))
bg.save(f'{S}/adaptive_bg.png'); fg.save(f'{S}/adaptive_fg.png')
comb = bg.convert('RGBA'); comb.alpha_composite(fg)
v = int(C * 72 / 108); o = (C - v) // 2
vis = comb.crop((o, o, o + v, o + v)).resize((432, 432), Image.LANCZOS)
m = Image.new('L', (432, 432), 0); ImageDraw.Draw(m).ellipse((0, 0, 431, 431), fill=255)
circ = Image.new('RGBA', (432, 432), (255, 255, 255, 0)); circ.paste(vis, (0, 0), m)
out = Image.new('RGBA', (512 + 20 + 432 + 20 + 96 + 10 + 48, 512), 'white')
out.alpha_composite(sq.resize((512, 512), Image.LANCZOS), (0, 0))
out.alpha_composite(circ, (532, 40))
out.alpha_composite(r.resize((96, 96), Image.LANCZOS), (984, 0))
out.alpha_composite(r.resize((48, 48), Image.LANCZOS), (1090, 0))
out.save(f'{S}/preview3.png')
