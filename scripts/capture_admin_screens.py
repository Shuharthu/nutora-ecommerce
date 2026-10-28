import subprocess
import os
import json
import time

chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
user_data_dir = os.path.abspath('tmp_chrome_profile')

# We can launch a node puppeteer script if puppeteer is installed, or use python playwright/selenium if available,
# or create a bridge page that sets localStorage and redirects to /admin/users.html!

# Let's write an auth-bridge.html in root that logs in as Super Admin and redirects to target
bridge_html = """
<!DOCTYPE html>
<html>
<head>
  <script src="js/auth.js"></script>
</head>
<body>
  <script>
    (async () => {
      await nutoraAuth.setSuperAdmin('Shuharthu Tapash Barua', 'admin@nutorafood.com', '01712345678', 'admin123');
      const target = new URLSearchParams(window.location.search).get('target') || '/admin/users.html';
      window.location.href = target;
    })();
  </script>
</body>
</html>
"""
with open('auth-bridge.html', 'w', encoding='utf-8') as f:
    f.write(bridge_html)

targets = [
    ('preview-admin-users.png', '1440,1100', 'http://localhost:3000/auth-bridge.html?target=/admin/users.html'),
    ('preview-admin-products.png', '1440,1100', 'http://localhost:3000/auth-bridge.html?target=/admin/products.html'),
]

for filename, size, url in targets:
    out_img = os.path.abspath(filename)
    cmd = [
        chrome_path,
        '--headless=new',
        '--disable-gpu',
        '--no-sandbox',
        f'--user-data-dir={user_data_dir}',
        f'--screenshot={out_img}',
        f'--window-size={size}',
        '--virtual-time-budget=4000',
        url
    ]
    subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(out_img):
        print(f"Captured {filename} ({os.path.getsize(out_img)} bytes)")
    else:
        print(f"Failed {filename}")

# Clean up bridge
if os.path.exists('auth-bridge.html'):
    os.remove('auth-bridge.html')
