import os
from PIL import Image, ImageDraw, ImageFilter

logo = Image.open('assets/brand/nutora-logo.png').convert('RGBA')

# Create 1200x800 Hero Showcase Composition
w, h = 1200, 800
canvas = Image.new('RGBA', (w, h), (255, 249, 235, 255))
draw = ImageDraw.Draw(canvas)

# Warm subtle gradient
for y in range(h):
    ratio = y / h
    r = int(255 * (1 - ratio * 0.08))
    g = int(249 * (1 - ratio * 0.12))
    b = int(235 * (1 - ratio * 0.20))
    draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

# Soft decorative golden bokeh circles in background
bokeh = Image.new('RGBA', (w, h), (0,0,0,0))
b_draw = ImageDraw.Draw(bokeh)
b_draw.ellipse([80, 60, 320, 300], fill=(244, 195, 79, 35))
b_draw.ellipse([780, 100, 1100, 420], fill=(217, 154, 36, 40))
b_draw.ellipse([500, 400, 950, 850], fill=(23, 69, 47, 25))
bokeh = bokeh.filter(ImageFilter.GaussianBlur(60))
canvas = Image.alpha_composite(canvas, bokeh)

# Place the official Nutora logo prominently in the center-right or center
logo_size = 560
logo_resized = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)

# Shadow behind the logo
shadow = Image.new('RGBA', (w, h), (0,0,0,0))
s_draw = ImageDraw.Draw(shadow)
cx, cy = 600, 390
s_draw.ellipse([cx - 260, cy - 230, cx + 260, cy + 290], fill=(23, 69, 47, 60))
shadow = shadow.filter(ImageFilter.GaussianBlur(30))
canvas = Image.alpha_composite(canvas, shadow)

# Paste the logo
canvas.paste(logo_resized, (cx - logo_size//2, cy - logo_size//2), logo_resized)

# Save
canvas.convert('RGB').save('assets/images/hero/hero-showcase.jpg', format='JPEG', quality=95, optimize=True)
print('Saved hero-showcase.jpg')
