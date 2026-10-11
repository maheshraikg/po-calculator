"""Play Store screenshots with headlines: python3 tool/make_store_screenshots.py [--tablet]

Reads the raw app screens in store/screenshots/raw/ (made by
tool/screenshots/store_test.dart) and writes 1080x1920 images to
store/screenshots/en/: a headline, a short line and the screen in a phone.
"""
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --tablet: tablet-size app screens (raw_tablet/) in a tablet frame, to tablet/.
TABLET = '--tablet' in sys.argv

W, H = 1080, 1920
MF = '/opt/flutter-sdk/flutter/bin/cache/artifacts/material_fonts'
NOTO = '/usr/share/fonts/truetype/noto'
RED, DEEP = (0xD0, 0x12, 0x30), (0x5E, 0x06, 0x14)
YELLOW, INK = (0xFD, 0xB9, 0x13), (0x2B, 0x1B, 0x17)

# (raw file, headline with the *highlighted* words, line under it)
SLIDES = [
    ('1_home', 'All Post Office\n*schemes* in one app', 'Latest rates for all 13 savings schemes'),
    ('2_result', 'Know your\n*maturity amount*', 'Interest, maturity date and growth in seconds'),
    ('3_suggestions', 'Smart *suggestions*\nto earn more', 'Put MIS interest into an RD, find a better scheme'),
    ('4_compare', 'Compare *every*\nscheme', 'See the highest return for your amount'),
    ('5_accounts', 'Track your\n*accounts*', 'Maturity countdown and reminders'),
    ('6_rd_rebate', 'Tools for\n*post office staff*', 'RD rebate, service charges, eligibility'),
    ('7_forms', 'Official forms\nin *one tap*', 'Download, or send to a customer on WhatsApp'),
    ('8_languages', 'Use it in\n*your language*', None),
]


def font(name, size, base=MF):
    return ImageFont.truetype(f'{base}/{name}', size, layout_engine=ImageFont.Layout.RAQM)


def background(dark):
    top, bot = (DEEP, RED) if dark else (RED, DEEP)
    g = Image.new('RGB', (1, H))
    for y in range(H):
        t = y / H
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    img = g.resize((W, H)).convert('RGBA')
    deco = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(deco)
    for cx, cy, r, a in [(1020, 120, 260, 22), (40, 1060, 300, 14), (980, 1500, 220, 12)]:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, a))
    for k in range(-H, W, 34):
        d.line((k, H, k + H, 0), fill=(255, 255, 255, 6), width=1)
    img = Image.alpha_composite(img, deco)
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((140, 760, 940, 1600), fill=(*YELLOW, 95))
    return Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(120)))


def headline(d, text, y):
    """Centred lines; *words* in yellow."""
    f = font('Roboto-Black.ttf', 84)
    for line in text.split('\n'):
        parts = line.split('*')
        total = sum(d.textlength(p, font=f) for p in parts)
        x = (W - total) / 2
        for i, p in enumerate(parts):
            d.text((x, y), p, font=f, fill=YELLOW if i % 2 else 'white')
            x += d.textlength(p, font=f)
        y += 100
    return y


def phone(path, top):
    sw = 860 if TABLET else 800
    shot = Image.open(path).convert('RGB')
    sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    pad, r = (30, 44) if TABLET else (18, 64)
    pw, ph = sw + 2 * pad, sh + 2 * pad
    frame = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, pw - 1, ph - 1), r, fill=(16, 16, 20))
    fd.rounded_rectangle((3, 3, pw - 4, ph - 4), r - 3, outline=(70, 70, 78), width=2)
    m = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw - 1, sh - 1), r - 16, fill=255)
    frame.paste(shot, (pad, pad), m)
    x = (W - pw) // 2
    layer = Image.new('RGBA', (W, H + ph), (0, 0, 0, 0))
    shadow = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((0, 0, pw - 1, ph - 1), r, fill=(0, 0, 0, 120))
    layer.paste(shadow, (x + 6, top + 26), shadow)
    layer = layer.filter(ImageFilter.GaussianBlur(26))
    layer.alpha_composite(frame, (x, top))
    return layer.crop((0, 0, W, H))


def languages(d, y):
    names = [('English', 'Roboto-Bold.ttf', MF), ('ಕನ್ನಡ', 'NotoSansKannada-Bold.ttf', NOTO),
             ('हिन्दी', 'NotoSansDevanagari-Bold.ttf', NOTO), ('தமிழ்', 'NotoSansTamil-Bold.ttf', NOTO),
             ('తెలుగు', 'NotoSansTelugu-Bold.ttf', NOTO), ('বাংলা', 'NotoSansBengali-Bold.ttf', NOTO),
             ('मराठी', 'NotoSansDevanagari-Bold.ttf', NOTO), ('ગુજરાતી', 'NotoSansGujarati-Bold.ttf', NOTO),
             ('മലയാളം', 'NotoSansMalayalam-Bold.ttf', NOTO), ('ଓଡ଼ିଆ', 'NotoSansOriya-Bold.ttf', NOTO),
             ('ਪੰਜਾਬੀ', 'NotoSansGurmukhi-Bold.ttf', NOTO)]
    rows = [names[:4], names[4:8], names[8:]]
    for row in rows:
        fs = [font(n, 34, b) for _, n, b in row]
        ws = [d.textlength(t, font=f) + 44 for (t, _, _), f in zip(row, fs)]
        x = (W - sum(ws) - 14 * (len(row) - 1)) / 2
        for (t, _, _), f, w in zip(row, fs, ws):
            d.rounded_rectangle((x, y, x + w, y + 58), 29, fill=YELLOW)
            d.text((x + w / 2, y + 29), t, font=f, fill=INK, anchor='mm')
            x += w + 14
        y += 72
    return y


for i, (name, title, sub) in enumerate(SLIDES):
    img = background(dark=i % 2 == 1)
    d = ImageDraw.Draw(img)
    y = headline(d, title, 96)
    if sub:
        f = font('Roboto-Medium.ttf', 40)
        d.text((W / 2, y + 30), sub, font=f, fill=(255, 228, 228), anchor='mm')
        y += 70
    else:
        y = languages(d, y + 6) - 10
    d.rounded_rectangle((W / 2 - 50, y + 8, W / 2 + 50, y + 16), 4, fill=YELLOW)
    raw, out = ('raw_tablet', 'tablet') if TABLET else ('raw', 'en')
    img = Image.alpha_composite(img, phone(f'store/screenshots/{raw}/{name}.png', y + 60))
    img.convert('RGB').save(f'store/screenshots/{out}/{name}.png')
    print(f'store/screenshots/{out}/{name}.png')
