import glob

files = glob.glob("*.html")
for f in files:
    with open(f, 'r', encoding='utf-8') as fp:
        content = fp.read()
    
    # Check if supabase CDN is loaded
    if "cdn.jsdelivr.net/npm/@supabase/supabase-js" not in content:
        content = content.replace(
            '<script src="js/config.js"></script>',
            '<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>\n  <script src="js/config.js"></script>'
        )
    
    # Check if db-modal is loaded
    if "js/db-modal.js" not in content and "js/auth.js" in content:
        content = content.replace(
            '<script src="js/auth.js"></script>',
            '<script src="js/auth.js"></script>\n  <script src="js/db-modal.js"></script>'
        )

    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(content)

admin_files = glob.glob("admin/*.html")
for f in admin_files:
    with open(f, 'r', encoding='utf-8') as fp:
        content = fp.read()
    
    if "cdn.jsdelivr.net/npm/@supabase/supabase-js" not in content:
        content = content.replace(
            '<script src="../js/config.js"></script>',
            '<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>\n  <script src="../js/config.js"></script>'
        )

    if "../js/db-modal.js" not in content and "../js/auth.js" in content:
        content = content.replace(
            '<script src="../js/auth.js"></script>',
            '<script src="../js/auth.js"></script>\n  <script src="../js/db-modal.js"></script>'
        )

    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(content)

print("Injected Supabase & DB Modal scripts across all HTML files successfully.")
