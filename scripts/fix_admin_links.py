import glob
import re

admin_files = [
    'index.html', 'products.html', 'categories.html', 'inventory.html',
    'orders.html', 'customers.html', 'coupons.html', 'reviews.html',
    'users.html', 'settings.html', 'audit-logs.html', 'setup.html', 'login.html'
]

for html_path in sorted(glob.glob('admin/*.html')):
    with open(html_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace relative links inside href="..."
    for af in admin_files:
        # href="af" -> href="/admin/af"
        content = re.sub(rf'href=["\']{af}["\']', f'href="/admin/{af}"', content)
        # href="af#something" -> href="/admin/af#something"
        content = re.sub(rf'href=["\']{af}#([^"\']*)["\']', rf'href="/admin/{af}#\1"', content)

    # Replace ../shop.html and ../index.html
    content = content.replace('href="../shop.html"', 'href="/shop.html"')
    content = content.replace('href="../index.html"', 'href="/index.html"')

    # In products.html and inventory.html, add products-data.js if not present
    if 'products.html' in html_path or 'inventory.html' in html_path:
        if 'products-data.js' not in content:
            content = content.replace(
                '<script src="../js/config.js"></script>',
                '<script src="../js/products-data.js"></script>\n  <script src="../js/config.js"></script>'
            )

    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Updated links in {html_path}")
