import glob
import re

admin_files = glob.glob('admin/*.html')

for filepath in admin_files:
    filename = filepath.replace('\\', '/').split('/')[-1]
    if filename in ['login.html', 'setup.html', 'users.html']:
        continue  # Already custom crafted

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Ensure admin-core.js is included
    if 'admin-core.js' not in content:
        # Insert admin-core.js after auth.js
        if 'src="../js/auth.js"></script>' in content:
            content = content.replace(
                'src="../js/auth.js"></script>',
                'src="../js/auth.js"></script>\n  <script src="../js/admin-core.js"></script>'
            )
        elif 'src="../js/config.js"></script>' in content:
            content = content.replace(
                'src="../js/config.js"></script>',
                'src="../js/config.js"></script>\n  <script src="../js/supabase-client.js"></script>\n  <script src="../js/auth.js"></script>\n  <script src="../js/admin-core.js"></script>'
            )
        else:
            # Insert before </body>
            content = content.replace(
                '</body>',
                '  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>\n  <script src="../js/config.js"></script>\n  <script src="../js/supabase-client.js"></script>\n  <script src="../js/auth.js"></script>\n  <script src="../js/admin-core.js"></script>\n</body>'
            )

    # Remove any auto-login demo functions
    content = re.sub(r'function checkAdminAuth\(\) \{.*?\}\s*', '', content, flags=re.DOTALL)
    content = content.replace('checkAdminAuth();', '')

    # Wrap <table class="admin-table"> with <div class="admin-table-container"> if not already wrapped
    if '<table class="admin-table">' in content and '<div class="admin-table-container">' not in content:
        content = content.replace(
            '<table class="admin-table">',
            '<div class="admin-table-container">\n          <table class="admin-table">'
        )
        content = content.replace(
            '</table>',
            '</table>\n        </div>'
        )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Updated {filename}")

print("All admin pages updated successfully.")
