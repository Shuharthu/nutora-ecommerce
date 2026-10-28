import glob
import re

storefront_pages = [
    'index.html', 'shop.html', 'product.html', 'cart.html', 'checkout.html',
    'login.html', 'register.html', 'account.html', 'about.html', 'contact.html',
    'faq.html', 'shipping-policy.html', 'refund-policy.html', 'privacy-policy.html', 'terms.html'
]

replacements = [
    ('href="#" style="color: #B2ACA0;">Privacy Policy</a>', 'href="privacy-policy.html">Privacy Policy</a>'),
    ('href="#">Privacy Policy</a>', 'href="privacy-policy.html">Privacy Policy</a>'),
    ('href="#" style="color: #B2ACA0;">Terms & Conditions</a>', 'href="terms.html">Terms & Conditions</a>'),
    ('href="#">Terms & Conditions</a>', 'href="terms.html">Terms & Conditions</a>'),
    ('href="#" style="color: #B2ACA0;">Shipping Policy</a>', 'href="shipping-policy.html">Shipping Policy</a>'),
    ('href="#">Shipping Policy</a>', 'href="shipping-policy.html">Shipping Policy</a>'),
    ('href="#" style="color: #B2ACA0;">Return & Refund</a>', 'href="refund-policy.html">Return & Refund</a>'),
    ('href="#">Return & Refund</a>', 'href="refund-policy.html">Return & Refund</a>'),
    ('href="#">About Us</a>', 'href="about.html">About Us</a>'),
    ('href="#">Contact</a>', 'href="contact.html">Contact</a>'),
    ('href="#">FAQ</a>', 'href="faq.html">FAQ</a>'),
]

updated_count = 0
for p in storefront_pages:
    try:
        with open(p, 'r', encoding='utf-8') as f:
            content = f.read()
        
        orig_content = content
        for old, new in replacements:
            content = content.replace(old, new)
            
        if content != orig_content:
            with open(p, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated links in {p}")
            updated_count += 1
        else:
            print(f"Already clean: {p}")
    except Exception as e:
        print(f"Error checking {p}: {e}")

print(f"Total pages updated: {updated_count}")
