"""Play Store feature graphic (1024x500): python3 tool/make_feature_graphic.py

Uses store/icon_512.png and store/screenshots/en/2_result.png.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
MF = '/opt/flutter-sdk/flutter/bin/cache/artifacts/material_fonts'
TOP, BOT = (0xC8, 0x10, 0x2E), (0x7A, 0x0A, 0x1C)


def font(name, size):
    return ImageFont.truetype(f'{MF}/{name}', size)


grad = Image.new('RGB', (W, H))
px = grad.load()
for y in range(H):
    for x in range(W):
        t = x / W * 0.6 + y / H * 0.4
        px[x, y] = tuple(int(TOP[i] + (BOT[i] - TOP[i]) * t) for i in range(3))
img = grad.convert('RGBA')
ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(ov)
for cx, cy, r, a in [(980, -40, 230, 26), (620, 560, 200, 18), (-40, 520, 160, 16)]:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, a))
img = Image.alpha_composite(img, ov)
icon = Image.open('store/icon_512.png').convert('RGBA').resize((150, 150), Image.LANCZOS)
frame = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(frame).rounded_rectangle((52, 62, 218, 228), 40, fill='white')
img = Image.alpha_composite(img, frame)
mask = Image.new('L', (150, 150), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 149, 149), 33, fill=255)
img.paste(icon, (60, 70), mask)
d = ImageDraw.Draw(img)
d.text((60, 250), 'PO Calculator', font=font('Roboto-Black.ttf', 76), fill='white')
d.text((62, 345), 'Post Office interest calculator', font=font('Roboto-Medium.ttf', 34),
       fill=(255, 255, 255, 225))
pill = '11 Indian languages · Works offline'
f = font('Roboto-Medium.ttf', 26)
w = d.textlength(pill, font=f)
d.rounded_rectangle((60, 405, 60 + w + 40, 451), 23, fill=(0xFD, 0xB9, 0x13))
d.text((80, 411), pill, font=f, fill=(0x26, 0x1A, 0x1A))
shot = Image.open('store/screenshots/en/2_result.png').convert('RGB').resize((246, 437), Image.LANCZOS)
phone = Image.new('RGBA', (266, 457), (0, 0, 0, 0))
ImageDraw.Draw(phone).rounded_rectangle((0, 0, 265, 456), 28, fill=(20, 20, 24))
sm = Image.new('L', (246, 437), 0)
ImageDraw.Draw(sm).rounded_rectangle((0, 0, 245, 436), 20, fill=255)
phone.paste(shot, (10, 10), sm)
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((712, 40, 978, 497), 28, fill=(0, 0, 0, 110))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(14)))
img.alpha_composite(phone, (700, 24))
img.convert('RGB').save('store/feature_graphic.png')
print('store/feature_graphic.png', img.size)
