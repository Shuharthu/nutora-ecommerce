import glob

pages = [
    'index.html', 'shop.html', 'product.html', 'cart.html', 'checkout.html',
    'login.html', 'register.html', 'account.html', 'about.html', 'contact.html',
    'faq.html', 'shipping-policy.html', 'refund-policy.html', 'privacy-policy.html', 'terms.html'
]

old_footer_pattern = '<a href="refund-policy.html">Return & Refund</a>'
new_footer_pattern = '<a href="refund-policy.html">Return & Refund</a>\n          <a href="admin/login.html" style="color: var(--color-warm-gold); font-size: 0.8rem; border: 1px solid rgba(244,195,79,0.3); padding: 2px 8px; border-radius: 4px; text-decoration: none;">🔒 Staff Portal</a>'

updated = 0
for p in pages:
    try:
        with open(p, 'r', encoding='utf-8') as f:
            c = f.read()

        if 'Staff Portal' not in c and old_footer_pattern in c:
            c = c.replace(old_footer_pattern, new_footer_pattern)
            with open(p, 'w', encoding='utf-8') as f:
                f.write(c)
            updated += 1
            print(f"Added Staff Portal link to {p}")
    except Exception as e:
        print(f"Error updating {p}: {e}")

# Also update login.html with the admin switch prompt
with open('login.html', 'r', encoding='utf-8') as f:
    login_html = f.read()

target_login = '''      <div style="text-align: center; margin-top: 24px; font-size: 0.9rem; color: var(--color-muted-text);">
        Don't have an account yet? <a href="register.html" style="color: var(--color-forest-green); font-weight: 700;">Join Mother's Kitchen &rarr;</a>
      </div>'''

replacement_login = '''      <div style="text-align: center; margin-top: 24px; font-size: 0.9rem; color: var(--color-muted-text);">
        Don't have an account yet? <a href="register.html" style="color: var(--color-forest-green); font-weight: 700;">Join Mother's Kitchen &rarr;</a>
      </div>

      <div style="text-align: center; margin-top: 18px; padding-top: 16px; border-top: 1px dashed var(--color-light-border); font-size: 0.84rem;">
        <span style="color: var(--color-muted-text);">Store Administrator or Staff?</span>
        <a href="admin/login.html" style="color: var(--color-forest-green); font-weight: 700; display: block; margin-top: 4px;">
          🔒 Access Kitchen Admin Portal &rarr;
        </a>
      </div>'''

if 'Access Kitchen Admin Portal' not in login_html and target_login in login_html:
    login_html = login_html.replace(target_login, replacement_login)
    with open('login.html', 'w', encoding='utf-8') as f:
        f.write(login_html)
    print("Added Admin Portal link in login.html")

print(f"Completed! Total footer updates: {updated}")
