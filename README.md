# NUTORA — Homemade With Love
### *Straight Out of Mother's Kitchen*

An authentic, fully responsive, production-ready e-commerce platform for **NUTORA**, a premium Bangladeshi homemade and natural food brand.

---

## 🌿 Project Mission & Architecture

Built with modern web standards and high-reliability architecture:
- **Frontend**: Semantic HTML5, CSS3 Custom Properties (Design System), Vanilla JavaScript (No heavyweight framework overhead).
- **Backend**: Supabase PostgreSQL with 20+ tables, custom stored procedures, and triggers.
- **Security**: PostgreSQL Row Level Security (RLS) on 100% of tables, granular RBAC (`super_admin`, `editor`, `customer`), and tamper-evident immutable audit logging.
- **Edge Functions**: Deno TypeScript functions for privileged user admin, transactional order creation, and server-side payment verification.
- **Local Dev / Standalone Ready**: Ships with dual-mode operational support — connects to live Supabase with simple credentials, while providing instant local fallback data so the entire storefront and administrative portal can be tested out of the box.

---

## 🎨 Official Brand Identity & Color Palette

The official supplied circular artwork is preserved as the single source of truth for packaging and UI:
- **Forest Green**: `#17452F` (Primary navigation, buttons, high-contrast headings)
- **Deep Green**: `#103523` (Footers, announcements, badges)
- **Honey Gold**: `#D99A24` (Highlights, pricing badges, brand accents)
- **Warm Golden Yellow**: `#F4C34F` (Stars, badges, hover accents)
- **Cream**: `#FFF9EB` (Warm backgrounds, cards)
- **Peanut Brown**: `#4A2616` (Accents, labels, headings)
- **Body Text**: `#282821` | **Muted Text**: `#746D60` | **Light Border**: `#E8DFCC`

### Brand Assets:
- `assets/brand/nutora-logo-original.png`: Unaltered master artwork.
- `assets/brand/nutora-logo.png`: High-resolution circular alpha PNG.
- `assets/brand/nutora-logo.webp`: Optimized WebP asset.
- `assets/brand/nutora-icon.svg`: Vector container SVG.
- `favicon.ico`, `favicon-32.png`, `favicon-192.png`: Multi-device favicons.

---

## 📁 Project Structure

```text
nutora/
├── index.html                  # Homepage (Announcement, Hero, Categories, Offerings, Story, Footer)
├── shop.html                   # Storefront (Category filters, Price slider, Search, Sort)
├── product.html                # Product Details (Gallery, Variants, Ingredients, Stepper, Reviews)
├── cart.html                   # Shopping Basket (Quantity adjust, Coupon redemption, Live total)
├── checkout.html               # Secure Checkout (Bangladesh Divisions/Districts, Cash on Delivery)
├── login.html                  # Customer & Staff Login
├── register.html               # Customer Registration
├── account.html                # Customer Portal (Order history, Profile, Addresses)
├── about.html                  # Brand Heritage & Maternal Story
├── contact.html                # Dhaka Kitchen Contact & WhatsApp Form
├── faq.html                    # Frequently Asked Questions
├── shipping-policy.html        # Bangladesh Delivery Fees (Dhaka ৳70, Outside ৳130)
├── refund-policy.html          # Transit Breakage & Replacement Guarantee
├── privacy-policy.html         # Data Privacy & Security Standards
├── terms.html                  # Terms & Conditions
├── assets/
│   ├── brand/                  # Official NUTORA logos, derivates, favicons
│   ├── images/products/        # Handcrafted product imagery
│   └── images/hero/            # Hero visual assets
├── css/
│   ├── variables.css           # Brand color tokens & design system
│   ├── base.css                # Reset, typography, accessibility
│   ├── components.css          # Buttons, product cards, drawer, footer
│   ├── storefront.css          # Hero, categories, story banner
│   ├── admin.css               # Admin tables, metric cards, modals
│   └── responsive.css          # Breakpoints (320px to 4K)
├── js/
│   ├── config.js               # Global constants & Supabase keys
│   ├── supabase-client.js      # Supabase data layer with fallback simulation
│   ├── auth.js                 # Authentication & Role state
│   └── main.js                 # Storefront cart & reactive UI
├── admin/
│   ├── index.html              # Operations Dashboard (Gross sales, pending orders, charts)
│   ├── products.html           # Full Catalog CRUD (Create, Edit, Price, Archive)
│   ├── categories.html         # Category hierarchy & ordering
│   ├── inventory.html          # Stock monitoring, low-stock threshold alerts
│   ├── orders.html             # Order status workflow & Invoice printing
│   ├── customers.html          # Customer directory & lifetime value
│   ├── coupons.html            # Promotion & coupon code management
│   ├── reviews.html            # Review moderation & approval
│   ├── settings.html           # Delivery charges & payment switches
│   ├── users.html              # Super Admin user management & RBAC
│   └── audit-logs.html         # Tamper-evident immutable audit log vault
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql         # 20+ tables with constraints & indexes
│   │   ├── 002_security_rls.sql           # Row Level Security (RLS) on all tables
│   │   └── 003_functions_and_triggers.sql # Transactional order creation, audit logging, admin protection
│   ├── seed.sql                # Seed roles, permissions, categories, demo products
│   └── functions/
│       ├── create-order/       # Trusted order creation Edge function
│       ├── verify-payment/     # Server-side payment verification boundary
│       └── admin-users/        # Privileged Super Admin user administration
├── tests/
│   └── run_tests.py            # Automated integrity test suite (26 pages, assets, DB, HTTP)
├── .env.example                # Environment variables template
├── .gitignore
└── README.md
```

---

## 🗄️ Database Architecture (20+ Tables)

1. `profiles`: Customer and staff profiles extending `auth.users`.
2. `user_roles`: System roles (`super_admin`, `editor`, `customer`).
3. `permissions`: Granular actions (`products.create`, `orders.manage`, etc.).
4. `role_permissions`: Role-to-permission mapping.
5. `categories`: Artisanal product categories.
6. `products`: Base catalog items with weights, prices, ingredients, storage.
7. `product_images`: Multi-image galleries with primary flags.
8. `product_variants`: Size variants with price adjustments.
9. `carts`: Guest and user persistent baskets.
10. `cart_items`: Basket items with quantities.
11. `addresses`: Multi-address customer book.
12. `orders`: Orders with human-friendly IDs (`NUT-YYYYMMDD-XXXX`).
13. `order_items`: Historical immutable snapshots of prices and SKUs.
14. `payments`: Payment records, gateways, and transaction IDs.
15. `coupons`: Percentage and fixed promotional vouchers.
16. `coupon_redemptions`: Audit trail of coupon usage.
17. `wishlists`: Customer product wishlists.
18. `reviews`: Customer feedback with verified buyer checks.
19. `store_settings`: Global delivery rates and contact details.
20. `audit_logs`: Immutable security log of sensitive operations.

---

## 🚀 Supabase Deployment Guide

### Step 1: Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project named `nutora`.
2. In the **SQL Editor**, run the migration scripts in numerical sequence:
   - Run `supabase/migrations/001_initial_schema.sql`
   - Run `supabase/migrations/002_security_rls.sql`
   - Run `supabase/migrations/003_functions_and_triggers.sql`
   - Run `supabase/seed.sql`

### Step 2: Provision First Super Admin
1. In the Supabase Dashboard, go to **Authentication > Users** and click **Invite User** or create user `admin@nutorafood.com`.
2. In the **SQL Editor**, elevate this initial user to Super Admin:
```sql
UPDATE public.profiles
SET role_id = (SELECT id FROM public.user_roles WHERE name = 'super_admin')
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@nutorafood.com');
```

### Step 3: Connect Frontend
Open `js/config.js` and paste your project URL and public Anon Key:
```javascript
const NUTORA_CONFIG = {
  BRAND_NAME: 'NUTORA',
  CURRENCY_SYMBOL: '৳',
  CURRENCY_CODE: 'BDT',
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-public-anon-key'
};
```

---

## 🧪 Automated Testing

Run the automated test suite locally to verify all 26 pages, brand assets, database migrations, and HTTP endpoints:

```bash
python tests/run_tests.py
```

All 26 pages and 20 database tables pass with 100% verification.
