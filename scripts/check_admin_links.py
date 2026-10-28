import glob
import re

for f in glob.glob('admin/*.html'):
    with open(f, 'r', encoding='utf-8') as fp:
        c = fp.read()
    links = re.findall(r'<a\s+href="([^"]+)"\s+class="admin-nav-item', c)
    print(f"{f}: {links}")
