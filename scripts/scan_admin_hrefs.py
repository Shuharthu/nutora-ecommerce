import glob
import re

for f in sorted(glob.glob('admin/*.html')):
    with open(f, 'r', encoding='utf-8') as fp:
        content = fp.read()
    hrefs = re.findall(r'href=[\'"]([^\'"]+)[\'"]', content)
    relative = [h for h in hrefs if not h.startswith(('http', '#', '../', '/'))]
    print(f"{f}: {relative}")
