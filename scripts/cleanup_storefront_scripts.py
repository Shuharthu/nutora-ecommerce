import glob

# Remove db-modal script tag from all storefront html files
storefront_files = glob.glob("*.html")
for f in storefront_files:
    with open(f, 'r', encoding='utf-8') as fp:
        content = fp.read()
    
    # Remove db-modal.js
    if '<script src="js/db-modal.js"></script>' in content:
        content = content.replace('  <script src="js/db-modal.js"></script>\n', '')
        content = content.replace('<script src="js/db-modal.js"></script>\n', '')
        content = content.replace('<script src="js/db-modal.js"></script>', '')
    
    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(content)

print("Removed db-modal.js from storefront pages.")
