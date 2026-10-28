-- ============================================================================
-- NUTORA E-COMMERCE PLATFORM — SEED DATA
-- Database: Supabase PostgreSQL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SEED SYSTEM ROLES
-- ----------------------------------------------------------------------------
INSERT INTO public.user_roles (id, name, description, is_system) VALUES
('11111111-1111-1111-1111-111111111101', 'super_admin', 'Full administrative authority over all store operations, users, orders, and configurations.', TRUE),
('11111111-1111-1111-1111-111111111102', 'editor', 'Catalog management, inventory updates, and authorized product content drafting.', TRUE),
('11111111-1111-1111-1111-111111111103', 'customer', 'Store customer with account management, order history, and reviews.', TRUE)
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- ----------------------------------------------------------------------------
-- 2. SEED PERMISSIONS
-- ----------------------------------------------------------------------------
INSERT INTO public.permissions (id, code, name, module) VALUES
('22222222-2222-2222-2222-222222222201', 'products.create', 'Create Products', 'Catalog'),
('22222222-2222-2222-2222-222222222202', 'products.edit', 'Edit Products', 'Catalog'),
('22222222-2222-2222-2222-222222222203', 'products.publish', 'Publish Products', 'Catalog'),
('22222222-2222-2222-2222-222222222204', 'products.delete', 'Archive/Delete Products', 'Catalog'),
('22222222-2222-2222-2222-222222222205', 'inventory.update', 'Manage Inventory & Stock', 'Catalog'),
('22222222-2222-2222-2222-222222222206', 'orders.manage', 'View & Update Orders', 'Orders'),
('22222222-2222-2222-2222-222222222207', 'orders.refund', 'Issue Refunds & Cancel Orders', 'Orders'),
('22222222-2222-2222-2222-222222222208', 'coupons.manage', 'Manage Coupons & Promotions', 'Marketing'),
('22222222-2222-2222-2222-222222222209', 'reviews.moderate', 'Moderate Customer Reviews', 'Catalog'),
('22222222-2222-2222-2222-222222222210', 'content.manage', 'Manage Banners & Homepage Content', 'Content'),
('22222222-2222-2222-2222-222222222211', 'users.manage', 'Invite & Manage Admin Users', 'Users'),
('22222222-2222-2222-2222-222222222212', 'settings.manage', 'Manage Store & Gateway Settings', 'Settings'),
('22222222-2222-2222-2222-222222222213', 'audit.view', 'View Immutable Audit Logs', 'Security')
ON CONFLICT (code) DO NOTHING;

-- Grant ALL permissions to Super Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT '11111111-1111-1111-1111-111111111101', id FROM public.permissions
ON CONFLICT DO NOTHING;

-- Grant standard permissions to Editor
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT '11111111-1111-1111-1111-111111111102', id FROM public.permissions
WHERE code IN ('products.create', 'products.edit', 'products.publish', 'inventory.update', 'content.manage')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. SEED STORE SETTINGS
-- ----------------------------------------------------------------------------
INSERT INTO public.store_settings (key, value, description) VALUES
('store_info', '{
    "name": "NUTORA",
    "tagline": "Straight Out of Mother''s Kitchen",
    "currency_code": "BDT",
    "currency_symbol": "৳",
    "phone": "+880 1712-345678",
    "email": "hello@nutorafood.com",
    "address": "Banani, Dhaka - 1213, Bangladesh"
}'::jsonb, 'General brand and contact information'),
('shipping_config', '{
    "dhaka_fee": 70.00,
    "outside_dhaka_fee": 130.00,
    "free_shipping_threshold_dhaka": 1500.00,
    "estimated_delivery_dhaka": "24-48 Hours",
    "estimated_delivery_outside": "3-5 Days"
}'::jsonb, 'Standard delivery fee configuration for Bangladesh'),
('payment_methods', '{
    "cod_enabled": true,
    "sslcommerz_enabled": false,
    "bkash_manual_enabled": true
}'::jsonb, 'Active payment gateway configuration')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ----------------------------------------------------------------------------
-- 4. SEED PRODUCT CATEGORIES
-- ----------------------------------------------------------------------------
INSERT INTO public.categories (id, name, slug, description, display_order, is_active) VALUES
('33333333-3333-3333-3333-333333333301', 'Organic Honey', 'organic-honey', 'Raw, unprocessed honey harvested from wild mangrove forests and seasonal blossoms.', 1, TRUE),
('33333333-3333-3333-3333-333333333302', 'Homemade Peanut Butter', 'homemade-peanut-butter', 'Freshly roasted peanuts churned slowly in small batches with pure honey and pink salt.', 2, TRUE),
('33333333-3333-3333-3333-333333333303', 'Pure Ghee', 'pure-ghee', 'Traditional Bilona cow ghee crafted from fermented curd with golden granular texture.', 3, TRUE),
('33333333-3333-3333-3333-333333333304', 'Mishti Doi', 'mishti-doi', 'Authentic Bogra sweet curd slow-fermented in porous earthenware pots.', 4, TRUE),
('33333333-3333-3333-3333-333333333305', 'Traditional Homemade Foods', 'traditional-homemade-foods', 'Heritage Bengali achars, chutneys, and savory specialties made from Mom''s recipes.', 5, TRUE),
('33333333-3333-3333-3333-333333333306', 'Natural Pantry', 'natural-pantry', 'Cold-pressed oils, unrefined Himalayan pink salt, and whole organic seeds.', 6, TRUE),
('33333333-3333-3333-3333-333333333307', 'Gift Boxes', 'gift-boxes', 'Handcrafted festive hampers and wooden gift crates of wholesome home-cooked delicacies.', 7, TRUE)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- ----------------------------------------------------------------------------
-- 5. SEED PRODUCTS
-- ----------------------------------------------------------------------------
INSERT INTO public.products (
    id, category_id, name, slug, sku, short_description, description,
    ingredients, allergen_info, storage_instructions, weight_volume,
    base_price, sale_price, stock_quantity, is_featured, status, published_at
) VALUES
(
    '44444444-4444-4444-4444-444444444401',
    '33333333-3333-3333-3333-333333333302',
    'Classic Homemade Peanut Butter',
    'classic-homemade-peanut-butter',
    'NUT-PB-CLS-400',
    'Creamy, slow-roasted peanuts sweetened with raw forest honey and Himalayan pink salt.',
    'Our signature peanut butter is prepared right in mother''s kitchen. We roast premium locally harvested peanuts to golden perfection, then stone-grind them slowly in small batches. Never contains hydrogenated oils, palm fat, artificial stabilizers, or refined sugar.',
    '100% Roasted Peanuts, Sundarban Raw Wild Honey, Himalayan Pink Rock Salt.',
    'Contains Peanuts. Produced in a home kitchen that handles mustard and sesame.',
    'Store at cool room temperature. Natural oil separation is normal; stir well before scooping.',
    '400g Glass Jar',
    580.00, 520.00, 85, TRUE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444402',
    '33333333-3333-3333-3333-333333333301',
    'Sundarban Wildflower Raw Honey',
    'sundarban-wildflower-raw-honey',
    'NUT-HNY-SND-500',
    '100% pure raw wildflower nectar gathered from mangrove forests of the Sundarbans.',
    'Collected responsibly by traditional Mauals in the Sundarban mangrove belts. Unheated, unpasteurized, and unfiltered through micro-sieves so that natural pollen, floral enzymes, and antioxidant properties remain intact.',
    '100% Pure Raw Mangrove Wildflower Honey.',
    'None.',
    'Store at room temperature in a dry place. Do not refrigerate. Raw honey may naturally crystallize over time.',
    '500g Glass Jar',
    850.00, 780.00, 60, TRUE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444403',
    '33333333-3333-3333-3333-333333333303',
    'Pure Bilona Danedar Cow Ghee',
    'pure-bilona-danedar-cow-ghee',
    'NUT-GHE-BIL-450',
    'Traditional Bilona Danedar Cow Ghee churned from cultured whole milk curd.',
    'Crafted according to the ancient Ayurvedic Bilona method: fresh grass-fed cow milk is cultured into curd, churned with wooden churners to extract makkhan, then slow-simmered over low firewood flames until aromatic golden granular crystals emerge.',
    '100% Cultured Cow Milk Butter Fat (Ghee).',
    'Dairy (Lactose-free due to complete clarified separation).',
    'Keep in an airtight jar in a cool, dark kitchen cupboard. Use a clean dry spoon.',
    '450g Glass Jar',
    1100.00, 980.00, 45, TRUE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444404',
    '33333333-3333-3333-3333-333333333304',
    'Traditional Bogra Mishti Doi',
    'traditional-bogra-mishti-doi',
    'NUT-DOI-BGR-500',
    'Authentic Bogra sweet curd slow-fermented in porous unglazed earthenware pots.',
    'Prepared with thick cow milk reduced slowly over firewood with sugarcane jaggery and natural caramelized milk solids, then fermented overnight in clay pots that absorb excess whey moisture to produce a velvety, thick sliceable texture.',
    'Full Cream Cow Milk, Natural Sugarcane Jaggery, Live Lactic Curd Culture.',
    'Contains Milk.',
    'Keep refrigerated between 2°C to 4°C. Consume within 7 days of delivery.',
    '500g Clay Pot',
    320.00, NULL, 30, TRUE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444405',
    '33333333-3333-3333-3333-333333333306',
    'Kachi Ghani Cold-Pressed Mustard Oil',
    'kachi-ghani-cold-pressed-mustard-oil',
    'NUT-OIL-MST-1000',
    'First-press cold extracted oil from premium black mustard seeds.',
    'Slowly crushed at room temperature without synthetic solvent extraction or high-heat bleaching. Retains high allyl isothiocyanate pungency, natural aroma, and rich fatty acid profile.',
    '100% Pure Cold-Pressed Black Mustard Seeds.',
    'Mustard.',
    'Store in a cool dry pantry away from direct sunlight.',
    '1 Litre Glass Bottle',
    420.00, NULL, 75, FALSE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444406',
    '33333333-3333-3333-3333-333333333305',
    'Tok-Jhal-Misti Homemade Mango Pickle',
    'tok-jhal-misti-homemade-mango-pickle',
    'NUT-ACH-MNG-400',
    'Sun-cured raw mango slices in mustard oil, roasted panch phoron, and molasses.',
    'Tender green mangoes hand-sliced and sun-dried on rooftop mats, seasoned with mother''s secret roasted panch phoron spices, kachi ghani mustard oil, dry red chillies, and pure date molasses.',
    'Raw Green Mangoes, Cold-Pressed Mustard Oil, Panch Phoron Spices, Date Molasses, Salt, Turmeric, Dried Red Chillies.',
    'Contains Mustard.',
    'Ensure pickle remains submerged under a thin layer of mustard oil. Use dry spoon.',
    '400g Glass Jar',
    400.00, 360.00, 50, TRUE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444407',
    '33333333-3333-3333-3333-333333333306',
    'Pure Himalayan Pink Rock Salt',
    'pure-himalayan-pink-rock-salt',
    'NUT-SLT-HIM-500',
    'Fine mineral-rich unrefined rock salt ground for wholesome everyday cooking.',
    'Mined from pristine ancient Himalayan salt deposits, unbleached, free of anti-caking chemical agents, containing over 84 trace minerals.',
    '100% Natural Himalayan Pink Rock Salt.',
    'None.',
    'Store in an airtight ceramic or glass container away from moisture.',
    '500g Pack',
    180.00, NULL, 120, FALSE, 'published', now()
),
(
    '44444444-4444-4444-4444-444444444408',
    '33333333-3333-3333-3333-333333333307',
    'Nutora Heritage Festive Gift Box',
    'nutora-heritage-festive-gift-box',
    'NUT-GFT-HER-001',
    'Handcrafted wooden crate with 4 artisan jars and handcrafted wooden honey dipper.',
    'An exquisite gift for family celebrations, Eid, Puja, or corporate gifting. Contains 1x Peanut Butter (400g), 1x Sundarban Raw Honey (500g), 1x Danedar Ghee (450g), and 1x Mango Achar (400g) in a laser-engraved reusable pinewood box.',
    'Assorted homemade pantry delicacies.',
    'See individual jar labels.',
    'Store in a cool dry pantry.',
    '4 Artisanal Jars Set',
    2700.00, 2450.00, 25, TRUE, 'published', now()
)
ON CONFLICT (slug) DO UPDATE SET
    base_price = EXCLUDED.base_price,
    sale_price = EXCLUDED.sale_price,
    stock_quantity = EXCLUDED.stock_quantity;

-- Seed Product Images
INSERT INTO public.product_images (product_id, image_url, alt_text, display_order, is_primary) VALUES
('44444444-4444-4444-4444-444444444401', 'assets/images/products/peanut-butter-classic.jpg', 'NUTORA Classic Homemade Peanut Butter Jar', 1, TRUE),
('44444444-4444-4444-4444-444444444402', 'assets/images/products/sundarban-raw-honey.jpg', 'NUTORA Sundarban Wildflower Raw Honey Jar', 1, TRUE),
('44444444-4444-4444-4444-444444444403', 'assets/images/products/bilona-cow-ghee.jpg', 'NUTORA Pure Bilona Danedar Cow Ghee Jar', 1, TRUE),
('44444444-4444-4444-4444-444444444404', 'assets/images/products/mishti-doi.jpg', 'NUTORA Traditional Bogra Mishti Doi Clay Pot', 1, TRUE),
('44444444-4444-4444-4444-444444444405', 'assets/images/products/mustard-oil.jpg', 'NUTORA Cold Pressed Kachi Ghani Mustard Oil Bottle', 1, TRUE),
('44444444-4444-4444-4444-444444444406', 'assets/images/products/mango-achar.jpg', 'NUTORA Tok-Jhal-Misti Mango Pickle Jar', 1, TRUE),
('44444444-4444-4444-4444-444444444407', 'assets/images/products/himalayan-pink-salt.jpg', 'NUTORA Himalayan Pink Rock Salt', 1, TRUE),
('44444444-4444-4444-4444-444444444408', 'assets/images/products/heritage-gift-box.jpg', 'NUTORA Heritage Festive Wooden Gift Box', 1, TRUE)
ON CONFLICT DO NOTHING;

-- Seed Product Variants
INSERT INTO public.product_variants (product_id, name, sku, weight_volume, price_adjustment, stock_quantity, is_active) VALUES
('44444444-4444-4444-4444-444444444401', 'Regular 400g Jar', 'NUT-PB-CLS-400', '400g', 0.00, 50, TRUE),
('44444444-4444-4444-4444-444444444401', 'Family Size 800g Jar', 'NUT-PB-CLS-800', '800g', 460.00, 35, TRUE),
('44444444-4444-4444-4444-444444444402', 'Standard 500g Glass Jar', 'NUT-HNY-SND-500', '500g', 0.00, 40, TRUE),
('44444444-4444-4444-4444-444444444402', 'Grand 1kg Glass Jar', 'NUT-HNY-SND-1000', '1kg', 700.00, 20, TRUE),
('44444444-4444-4444-4444-444444444403', 'Standard 450g Jar', 'NUT-GHE-BIL-450', '450g', 0.00, 30, TRUE),
('44444444-4444-4444-4444-444444444403', 'Grand 900g Jar', 'NUT-GHE-BIL-900', '900g', 920.00, 15, TRUE)
ON CONFLICT (sku) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. SEED SAMPLE COUPONS
-- ----------------------------------------------------------------------------
INSERT INTO public.coupons (code, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, is_active) VALUES
('MOMSLOVE10', 'percentage', 10.00, 500.00, 200.00, 500, TRUE),
('KITCHEN50', 'fixed', 50.00, 600.00, NULL, 200, TRUE)
ON CONFLICT (code) DO NOTHING;
