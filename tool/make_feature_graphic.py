"""Play Store feature graphic (1024x500): python3 tool/make_feature_graphic.py

Uses store/icon_512.png and store/screenshots/raw/{2_result,4_compare}.png.
"""
import math

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
MF = '/opt/flutter-sdk/flutter/bin/cache/artifacts/material_fonts'
NOTO = '/usr/share/fonts/truetype/noto'
RED, DEEP = (0xD0, 0x12, 0x30), (0x5E, 0x06, 0x14)
YELLOW, INK = (0xFD, 0xB9, 0x13), (0x2B, 0x1B, 0x17)


def font(name, size, base=MF):
    return ImageFont.truetype(f'{base}/{name}', size, layout_engine=ImageFont.Layout.RAQM)


# Diagonal red gradient.
grad = Image.new('RGB', (W, H))
px = grad.load()
for y in range(H):
    for x in range(W):
        t = min(1, max(0, x / W * 0.55 + y / H * 0.45))
        px[x, y] = tuple(int(RED[i] + (DEEP[i] - RED[i]) * t) for i in range(3))
img = grad.convert('RGBA')

# Warm golden glow behind the phones, soft rings and fine diagonal lines.
glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
g = ImageDraw.Draw(glow)
g.ellipse((560, 10, 1010, 470), fill=(*YELLOW, 120))
img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(90)))
deco = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(deco)
for cx, cy, r, a in [(1000, -30, 210, 22), (-60, 540, 200, 16), (470, -120, 160, 10)]:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, a))
for cx, cy, r in [(790, 250, 250), (790, 250, 205)]:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 34), width=2)
for k in range(-H, W, 26):
    d.line((k, H, k + H, 0), fill=(255, 255, 255, 7), width=1)
img = Image.alpha_composite(img, deco)


def phone(path, w):
    """Screenshot in a dark rounded phone frame."""
    h = int(w * 16 / 9)
    shot = Image.open(path).convert('RGB').resize((w, h), Image.LANCZOS)
    pad, r = 9, 26
    ph = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(ph).rounded_rectangle((0, 0, w + 2 * pad - 1, h + 2 * pad - 1), r, fill=(18, 18, 22))
    m = Image.new('L', (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), r - 8, fill=255)
    ph.paste(shot, (pad, pad), m)
    return ph


def place(base, ph, center, angle):
    """Rotate [ph], drop a shadow and paste it centred on [center]."""
    rot = ph.rotate(angle, resample=Image.BICUBIC, expand=True)
    sh = Image.new('RGBA', rot.size, (0, 0, 0, 0))
    sh.putalpha(rot.getchannel('A').point(lambda a: int(a * 0.45)))
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    x, y = center[0] - rot.width // 2, center[1] - rot.height // 2
    layer.paste(sh, (x + 10, y + 16), sh)
    base = Image.alpha_composite(base, layer.filter(ImageFilter.GaussianBlur(14)))
    base.alpha_composite(rot, (x, y)) if x >= 0 and y >= 0 else base.paste(rot, (x, y), rot)
    return base


img = place(img, phone('store/screenshots/raw/4_compare.png', 214), (705, 285), 9)
img = place(img, phone('store/screenshots/raw/2_result.png', 236), (868, 262), -6)

# Left: icon, name, tagline, features, languages.
d = ImageDraw.Draw(img)
icon = Image.open('store/icon_512.png').convert('RGBA').resize((108, 108), Image.LANCZOS)
# White tile behind the icon so the red icon stands out on the red background.
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((42, 36, 170, 164), 34, fill=(0, 0, 0, 110))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(10)))
tile = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(tile).rounded_rectangle((38, 28, 166, 156), 34, fill='white')
img = Image.alpha_composite(img, tile)
im = Image.new('L', (108, 108), 0)
ImageDraw.Draw(im).rounded_rectangle((0, 0, 107, 107), 26, fill=255)
img.paste(icon, (48, 38), im)
d = ImageDraw.Draw(img)
d.text((188, 52), 'Post Office savings', font=font('Roboto-Medium.ttf', 24), fill=(*YELLOW, 255))
d.text((188, 82), 'Every scheme. One app.', font=font('Roboto-Medium.ttf', 24), fill='white')

d.text((46, 168), 'PO Calculator', font=font('Roboto-Black.ttf', 70), fill='white')
d.text((49, 252), 'Interest, maturity, tax & forms — in seconds',
       font=font('Roboto-Medium.ttf', 24), fill=(255, 236, 236))

chips = ['13 schemes', 'Compare', 'Tax by year']
glass = Image.new('RGBA', (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glass)
x, y = 48, 300
f = font('Roboto-Bold.ttf', 19)
spots = []
for c in chips:
    w = d.textlength(c, font=f)
    gd.rounded_rectangle((x, y, x + w + 44, y + 40), 20, fill=(255, 255, 255, 38),
                         outline=(255, 255, 255, 120), width=1)
    spots.append((x, c))
    x += w + 54
img = Image.alpha_composite(img, glass)
d = ImageDraw.Draw(img)
for x, c in spots:
    d.ellipse((x + 13, y + 14, x + 25, y + 26), fill=YELLOW)
    d.text((x + 32, y + 9), c, font=f, fill='white')

# Language strip: each name in its own script.
langs = [('English', 'Roboto-Bold.ttf', MF), ('ಕನ್ನಡ', 'NotoSansKannada-Bold.ttf', NOTO),
         ('हिन्दी', 'NotoSansDevanagari-Bold.ttf', NOTO), ('தமிழ்', 'NotoSansTamil-Bold.ttf', NOTO),
         ('తెలుగు', 'NotoSansTelugu-Bold.ttf', NOTO)]
y = 368
fs = [font(n, 22, base) for _, n, base in langs]
more = '+6'
fm = font('Roboto-Black.ttf', 22)
total = sum(d.textlength(t, font=f) for (t, _, _), f in zip(langs, fs)) + 22 * len(langs) + d.textlength(more, font=fm)
d.rounded_rectangle((48, y, 48 + total + 36, y + 50), 25, fill=YELLOW)
x = 66
for (t, _, _), f in zip(langs, fs):
    d.text((x, y + 9 if f is not fs[0] else y + 12), t, font=f, fill=INK)
    x += d.textlength(t, font=f) + 10
    d.ellipse((x - 1, y + 23, x + 4, y + 28), fill=(*INK, 160))
    x += 12
d.text((x, y + 12), more, font=fm, fill=(0xA0, 0x0C, 0x24))

d.text((50, 440), '11 Indian languages  ·  Free  ·  No internet needed',
       font=font('Roboto-Medium.ttf', 19), fill=(255, 220, 220))

# Floating "interest earned" badge over the phones.
badge = Image.new('RGBA', (W, H), (0, 0, 0, 0))
b = ImageDraw.Draw(badge)
bx, by, bw, bh = 620, 384, 196, 74
b.rounded_rectangle((bx + 4, by + 8, bx + bw + 4, by + bh + 8), 20, fill=(0, 0, 0, 90))
badge = badge.filter(ImageFilter.GaussianBlur(8))
b = ImageDraw.Draw(badge)
b.rounded_rectangle((bx, by, bx + bw, by + bh), 20, fill='white')
b.ellipse((bx + 12, by + 15, bx + 56, by + 59), fill=(0x1B, 0x8A, 0x3C))
# Up arrow inside the green circle.
cx, cy = bx + 34, by + 37
b.polygon([(cx, cy - 13), (cx - 11, cy + 1), (cx + 11, cy + 1)], fill='white')
b.rectangle((cx - 4, cy, cx + 4, cy + 12), fill='white')
b.text((bx + 66, by + 12), 'Interest earned', font=font('Roboto-Medium.ttf', 16), fill=(110, 100, 98))
b.text((bx + 66, by + 32), '+₹1,92,840', font=font('Roboto-Black.ttf', 27), fill=INK)
img = Image.alpha_composite(img, badge)

img.convert('RGB').save('store/feature_graphic.png')
print('store/feature_graphic.png', img.size)
