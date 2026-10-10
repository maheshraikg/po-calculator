"""PO Calculator icon: postal red tile, gold ₹ coin with % badge, growth bars.

Regenerate: python3 tool/make_icon.py <out_dir> (needs Pillow and the
Flutter SDK Roboto fonts).
"""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

MF = '/opt/flutter-sdk/flutter/bin/cache/artifacts/material_fonts'
RED, DEEP = (0xC8, 0x10, 0x2E), (0x8E, 0x0B, 0x20)
GOLD, GOLD_D, GOLD_L = (0xFD, 0xB9, 0x13), (0xE0, 0x96, 0x00), (0xFF, 0xD5, 0x5A)
WHITE = (255, 255, 255)
N = 4096  # draw big, scale down for smooth edges
u = N / 1024


def gradient(size, c1, c2):
    g = Image.new('RGB', (size, size))
    px = g.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
    return g


def background():
    small = gradient(256, RED, DEEP).resize((N, N), Image.BICUBIC)
    bg = small.convert('RGBA')
    # faint envelope (post office hint), drawn on its own layer and blended
    ov = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    ex0, ey0, ex1, ey1 = 170 * u, 230 * u, 854 * u, 720 * u
    d.rounded_rectangle((ex0, ey0, ex1, ey1), 46 * u, fill=(255, 255, 255, 22))
    d.line([(ex0 + 30 * u, ey0 + 30 * u), (512 * u, 500 * u), (ex1 - 30 * u, ey0 + 30 * u)],
           fill=(255, 255, 255, 34), width=int(24 * u), joint='curve')
    return Image.alpha_composite(bg, ov)


def foreground(scale=1.0):
    """Coin, % badge, bars and arrow on transparent, centred."""
    fg = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg, 'RGBA')
    def S(v): return v * u * scale
    cx, cy = N / 2, N / 2
    def P(x, y): return (cx + S(x - 512), cy + S(y - 512))
    # rising bars behind, bottom right
    for i, (x, h) in enumerate([(610, 120), (690, 190), (770, 270)]):
        x0, y1 = P(x, 760)
        x1, y0 = P(x + 58, 760 - h)
        d.rounded_rectangle((x0, y0, x1, y1), S(12), fill=WHITE if i == 2 else (255, 255, 255, 215))
    # growth arrow
    d.line([P(560, 650), P(660, 560), P(730, 600), P(845, 455)], fill=GOLD, width=int(S(30)), joint='curve')
    ax, ay = P(865, 430)
    d.polygon([(ax, ay), P(800, 445), P(855, 505)], fill=GOLD)
    # coin shadow
    sh = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((*P(232, 262), *P(612, 642)), fill=(60, 0, 10, 110))
    fg = Image.alpha_composite(fg, sh.filter(ImageFilter.GaussianBlur(S(18))))
    d = ImageDraw.Draw(fg, 'RGBA')
    # coin
    d.ellipse((*P(212, 232), *P(592, 612)), fill=GOLD_D)
    d.ellipse((*P(222, 238), *P(582, 598)), fill=GOLD)
    d.ellipse((*P(262, 278), *P(542, 558)), outline=GOLD_L, width=int(S(10)))
    # rupee
    f = ImageFont.truetype(f'{MF}/Roboto-Black.ttf', int(S(250)))
    d.text(P(402, 422), '₹', font=f, fill=WHITE, anchor='mm')
    # % badge
    bx, by, r = 545, 255, 78
    d.ellipse((*P(bx - r, by - r), *P(bx + r, by + r)), fill=WHITE)
    d.ellipse((*P(bx - r + 10, by - r + 10), *P(bx + r - 10, by + r - 10)), fill=RED)
    fp = ImageFont.truetype(f'{MF}/Roboto-Black.ttf', int(S(100)))
    d.text(P(bx, by + 4), '%', font=fp, fill=WHITE, anchor='mm')
    return fg


def tile(size, radius_frac=0.22):
    bg = background()
    img = Image.alpha_composite(bg, foreground())
    mask = Image.new('L', (N, N), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, N - 1, N - 1), int(N * radius_frac), fill=255)
    out = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out.resize((size, size), Image.LANCZOS)


if __name__ == '__main__':
    out = sys.argv[1]
    tile(1024).save(f'{out}/icon_1024.png')
    # Play Store icon: full square, Play rounds the corners itself
    tile(512, radius_frac=0).convert('RGB').save(f'{out}/icon_512.png')
    # adaptive icon layers (108dp canvas, art inside the 66dp safe zone)
    background().convert('RGB').resize((432, 432), Image.LANCZOS).save(f'{out}/adaptive_bg.png')
    foreground(scale=0.9).resize((432, 432), Image.LANCZOS).save(f'{out}/adaptive_fg.png')
