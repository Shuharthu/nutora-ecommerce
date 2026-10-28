import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

os.makedirs('assets/images/products', exist_ok=True)
os.makedirs('assets/images/hero', exist_ok=True)

logo_img = Image.open('assets/brand/nutora-logo.png').convert('RGBA')

def create_product_image(filename, title, subtitle, bg_color1, bg_color2, jar_color, accent_color, badge_text="100% NATURAL"):
    width, height = 800, 800
    img = Image.new('RGB', (width, height), bg_color1)
    draw = ImageDraw.Draw(img)
    
    # Soft radial/gradient background
    for y in range(height):
        ratio = y / height
        r = int(bg_color1[0] * (1 - ratio) + bg_color2[0] * ratio)
        g = int(bg_color1[1] * (1 - ratio) + bg_color2[1] * ratio)
        b = int(bg_color1[2] * (1 - ratio) + bg_color2[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
        
    # Subtle kitchen/table wooden base
    table_y = 580
    wood_top = (212, 185, 148)
    wood_bottom = (175, 142, 102)
    for y in range(table_y, height):
        ratio = (y - table_y) / (height - table_y)
        r = int(wood_top[0] * (1 - ratio) + wood_bottom[0] * ratio)
        g = int(wood_top[1] * (1 - ratio) + wood_bottom[1] * ratio)
        b = int(wood_top[2] * (1 - ratio) + wood_bottom[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
        
    # Table edge highlight line
    draw.line([(0, table_y), (width, table_y)], fill=(235, 215, 185), width=3)
    draw.line([(0, table_y+3), (width, table_y+3)], fill=(150, 115, 75), width=2)
    
    # Jar Shadow on the table
    shadow = Image.new('RGBA', (width, height), (0,0,0,0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([230, 560, 570, 630], fill=(60, 40, 25, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.paste(Image.composite(shadow, Image.new('RGBA', (width, height), (0,0,0,0)), shadow), (0,0), shadow)
    
    # Draw Jar container (artisan glass jar / ceramic pot)
    jar_x1, jar_y1, jar_x2, jar_y2 = 260, 240, 540, 590
    
    # Jar glass body
    jar_mask = Image.new('RGBA', (width, height), (0,0,0,0))
    j_draw = ImageDraw.Draw(jar_mask)
    
    # Rounded jar body
    j_draw.rounded_rectangle([jar_x1, jar_y1+60, jar_x2, jar_y2], radius=40, fill=jar_color + (255,))
    
    # Jar lid (golden brass / rustic wood)
    lid_y1, lid_y2 = jar_y1, jar_y1 + 55
    j_draw.rounded_rectangle([jar_x1 - 15, lid_y1, jar_x2 + 15, lid_y2], radius=14, fill=accent_color + (255,))
    # Lid ribbed ridges
    for lx in range(jar_x1 - 10, jar_x2 + 10, 18):
        j_draw.line([(lx, lid_y1+6), (lx, lid_y2-6)], fill=(255, 255, 255, 70), width=3)
    
    # Jar neck ring
    j_draw.rounded_rectangle([jar_x1 + 10, lid_y2, jar_x2 - 10, jar_y1 + 75], radius=8, fill=(180, 140, 60, 255))
    
    # Natural twine / jute rope tied around neck
    j_draw.line([(jar_x1, lid_y2 + 8), (jar_x2, lid_y2 + 8)], fill=(160, 120, 75, 255), width=6)
    
    # Paste jar
    img.paste(jar_mask, (0, 0), jar_mask)
    
    # Glass gloss highlights
    gloss = Image.new('RGBA', (width, height), (0,0,0,0))
    g_draw = ImageDraw.Draw(gloss)
    g_draw.rounded_rectangle([jar_x1 + 18, jar_y1 + 80, jar_x1 + 45, jar_y2 - 25], radius=12, fill=(255, 255, 255, 75))
    g_draw.rounded_rectangle([jar_x2 - 35, jar_y1 + 85, jar_x2 - 20, jar_y2 - 30], radius=8, fill=(255, 255, 255, 45))
    gloss = gloss.filter(ImageFilter.GaussianBlur(4))
    img.paste(gloss, (0, 0), gloss)
    
    # Product Label on the Jar
    label_x1, label_y1, label_x2, label_y2 = jar_x1 + 25, jar_y1 + 110, jar_x2 - 25, jar_y2 - 50
    lbl_img = Image.new('RGBA', (width, height), (0,0,0,0))
    l_draw = ImageDraw.Draw(lbl_img)
    
    # Cream textured label
    l_draw.rounded_rectangle([label_x1, label_y1, label_x2, label_y2], radius=16, fill=(254, 251, 240, 250), outline=(217, 154, 36, 255), width=3)
    
    # Small NUTORA brand stamp on label
    nutora_small = logo_img.resize((100, 100), Image.Resampling.LANCZOS)
    lbl_img.paste(nutora_small, (int((width - 100)/2), label_y1 + 12), nutora_small)
    
    # Badge banner on label
    l_draw.rounded_rectangle([label_x1 + 20, label_y1 + 118, label_x2 - 20, label_y1 + 148], radius=6, fill=(23, 69, 47, 255))
    
    img.paste(lbl_img, (0,0), lbl_img)
    
    # Top natural badge
    badge = Image.new('RGBA', (width, height), (0,0,0,0))
    b_draw = ImageDraw.Draw(badge)
    b_draw.rounded_rectangle([50, 50, 230, 95], radius=22, fill=(23, 69, 47, 230), outline=(217, 154, 36, 255), width=2)
    b_draw.ellipse([60, 62, 82, 84], fill=(217, 154, 36, 255))
    img.paste(badge, (0,0), badge)
    
    # Draw text cleanly with default PIL font or fallback
    final_draw = ImageDraw.Draw(img)
    final_draw.text((95, 63), badge_text, fill=(255, 249, 235))
    
    # Center text on label
    # Label center is 400
    final_draw.text((width//2 - 60, label_y1 + 124), "NUTORA SELECT", fill=(244, 195, 79))
    
    # Product Title in label
    words = title.split()
    y_off = label_y1 + 165
    for w in words[:3]:
        final_draw.text((width//2 - len(w)*5, y_off), w.upper(), fill=(40, 40, 33))
        y_off += 24
        
    final_draw.text((width//2 - len(subtitle)*4, label_y2 - 32), subtitle, fill=(116, 109, 96))
    
    # Save optimized JPEG
    out_path = os.path.join('assets/images/products', filename)
    img.save(out_path, format='JPEG', quality=92, optimize=True)
    print(f'Generated {out_path}')

# Create the 8 essential demo products
create_product_image('peanut-butter-classic.jpg', 'Classic Peanut Butter', '400g • Creamy & Rich', (255, 249, 235), (242, 230, 205), (200, 125, 45), (180, 120, 30), 'HOMEMADE')
create_product_image('sundarban-raw-honey.jpg', 'Sundarban Raw Honey', '500g • 100% Pure Forest', (255, 249, 235), (245, 232, 195), (218, 140, 20), (217, 154, 36), 'RAW & PURE')
create_product_image('bilona-cow-ghee.jpg', 'Pure Bilona Cow Ghee', '450g • Danedar Aromatic', (255, 249, 235), (248, 235, 200), (235, 175, 45), (185, 130, 25), 'TRADITIONAL')
create_product_image('mishti-doi.jpg', 'Bogra Mishti Doi', '500g • Clay Pot Sweet Curd', (255, 249, 235), (238, 225, 205), (195, 135, 95), (130, 80, 45), 'AUTHENTIC')
create_product_image('mustard-oil.jpg', 'Kachi Ghani Mustard Oil', '1 Litre • Cold Pressed', (255, 249, 235), (240, 230, 195), (190, 145, 15), (23, 69, 47), 'COLD PRESSED')
create_product_image('mango-achar.jpg', 'Tok Jhal Misti Mango Pickle', '400g • Homemade Achar', (255, 249, 235), (245, 220, 190), (170, 70, 25), (190, 90, 30), 'MOM\'S RECIPE')
create_product_image('himalayan-pink-salt.jpg', 'Himalayan Pink Salt', '500g • Mineral Rich Fine', (255, 249, 235), (245, 228, 225), (220, 150, 140), (180, 110, 100), 'UNREFINED')
create_product_image('heritage-gift-box.jpg', 'Heritage Wooden Gift Box', 'Assorted 4-Jar Hamper', (255, 249, 235), (235, 220, 195), (110, 65, 38), (217, 154, 36), 'GIFT BOX')
