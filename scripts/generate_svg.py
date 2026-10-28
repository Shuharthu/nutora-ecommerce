import base64
import os

with open('assets/brand/favicon-192.png', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode('utf-8')

svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192" width="100%" height="100%">
  <defs>
    <clipPath id="circleClip">
      <circle cx="96" cy="96" r="94" />
    </clipPath>
  </defs>
  <image href="data:image/png;base64,{b64}" x="0" y="0" width="192" height="192" clip-path="url(#circleClip)" />
</svg>'''

with open('assets/brand/nutora-icon.svg', 'w', encoding='utf-8') as f:
    f.write(svg_content)

print('Saved nutora-icon.svg successfully!')
