import subprocess
import os

chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
url = "http://localhost:3000/index.html"

targets = [
    ("preview-desktop.png", "1440,3400"),
    ("preview-hero.png", "1440,950"),
    ("preview-mobile.png", "412,1800"),
]

for filename, size in targets:
    out_img = os.path.abspath(filename)
    cmd = [
        chrome_path,
        "--headless=new",
        "--disable-gpu",
        "--no-sandbox",
        f"--screenshot={out_img}",
        f"--window-size={size}",
        url
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(out_img):
        print(f"Captured {filename} ({os.path.getsize(out_img)} bytes)")
    else:
        print(f"Failed {filename}")
