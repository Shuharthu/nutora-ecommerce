import subprocess
import os

chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
targets = [
    ('preview-live-homepage.png', '1440,2400', 'http://localhost:3000/index.html'),
    ('preview-live-shop.png', '1440,1600', 'http://localhost:3000/shop.html'),
    ('preview-live-product.png', '1440,1400', 'http://localhost:3000/product.html?id=44444444-4444-4444-4444-444444444401'),
]

for filename, size, url in targets:
    out_img = os.path.abspath(filename)
    cmd = [
        chrome_path,
        '--headless=new',
        '--disable-gpu',
        '--no-sandbox',
        f'--screenshot={out_img}',
        f'--window-size={size}',
        url
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(out_img):
        print(f'Captured {filename} ({os.path.getsize(out_img)} bytes)')
    else:
        print(f'Failed {filename}')
