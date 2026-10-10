"""Turn a designed icon (store/icon_source.png, square with white corners)
into the app and store icons. Step 1 of 2; finish_icon.py is step 2.

Usage: copy store/icon_source.png to <dir>/src.png, then
  python3 tool/import_icon.py <dir> && python3 tool/finish_icon.py <dir>
"""
import sys
from PIL import Image, ImageDraw, ImageFilter
S = sys.argv[1]
im = Image.open(f'{S}/src.png').convert('RGB')
x0, y0, x1, y1 = 9, 3, 1243, 1240
px = im.load()
def red(p): return p[0] > 150 and p[1] < 90 and p[2] < 90
# corner radius from the top-left diagonal
d = next(i for i in range(400) if red(px[x0 + i, y0 + i]))
r = int(d / (1 - 2 ** -0.5))
print('diag', d, 'radius', r)
tile = im.crop((x0, y0, x1 + 1, y1 + 1)).resize((1024, 1024), Image.LANCZOS)
rr = int(r * 1024 / (x1 - x0))
mask = Image.new('L', (4096, 4096), 0)
ImageDraw.Draw(mask).rounded_rectangle((8, 8, 4087, 4087), rr * 4, fill=255)
mask = mask.resize((1024, 1024), Image.LANCZOS)
rounded = tile.convert('RGBA'); rounded.putalpha(mask)
rounded.save(f'{S}/rounded_1024.png')
# full square for Play: fill the corners with blurred edge colour
fill = tile.filter(ImageFilter.GaussianBlur(60))
base = Image.new('RGB', (1024, 1024), (205, 12, 30))
base.paste(fill, (0, 0))
sq = base.copy(); sq.paste(tile, (0, 0), mask)
sq.save(f'{S}/square_1024.png')
print('done', rr)
