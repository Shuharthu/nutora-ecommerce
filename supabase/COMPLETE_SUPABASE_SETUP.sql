-- ============================================================================
-- NUTORA E-COMMERCE PLATFORM — MASTER COMPLETE SUPABASE SETUP
-- Project Ref: xsyfymsejwqvkjukhxpf
-- Instructions: Copy this ENTIRE file, paste into Supabase Dashboard -> SQL Editor, and click 'RUN'.
-- It will create:
--   1. All 20 database tables & relational constraints
--   2. Granular Row Level Security (RLS) policies
--   3. Business logic functions, triggers & auto-profile creation
--   4. Default system roles, 13 permissions, categories & authentic seed products
-- ============================================================================



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: supabase/migrations/001_initial_schema.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ============================================================================
-- NUTORA E-COMMERCE PLATFORM — MASTER DATABASE SCHEMA
-- Migration: 001_initial_schema.sql
-- Database: Supabase PostgreSQL (Supports RLS & Auth integration)
-- ============================================================================

-- Enable essential extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. USER ROLES & PERMISSIONS (RBAC)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID NOT NULL REFERENCES public.user_roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (role_id, permission_id)
);

-- ----------------------------------------------------------------------------
-- 2. USER PROFILES
-- Extends Supabase auth.users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role_id UUID REFERENCES public.user_roles(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3. PRODUCT CATALOG: CATEGORIES, PRODUCTS, IMAGES, VARIANTS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    image_url TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    sku TEXT UNIQUE NOT NULL,
    short_description TEXT,
    description TEXT,
    ingredients TEXT,
    allergen_info TEXT,
    storage_instructions TEXT,
    weight_volume TEXT NOT NULL,
    base_price NUMERIC(12, 2) NOT NULL CHECK (base_price >= 0),
    sale_price NUMERIC(12, 2) CHECK (sale_price IS NULL OR sale_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMPTZ,
    seo_title TEXT,
    seo_description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sku TEXT UNIQUE NOT NULL,
    weight_volume TEXT NOT NULL,
    price_adjustment NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 4. CARTS & CART ITEMS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID NOT NULL REFERENCES public.carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(cart_id, product_id, variant_id)
);

-- ----------------------------------------------------------------------------
-- 5. CUSTOMER ADDRESSES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    division TEXT NOT NULL,
    district TEXT NOT NULL,
    upazila TEXT NOT NULL,
    street_address TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 6. COUPONS & PROMOTIONS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value NUMERIC(12, 2) NOT NULL CHECK (discount_value > 0),
    min_order_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (min_order_amount >= 0),
    max_discount_amount NUMERIC(12, 2) CHECK (max_discount_amount IS NULL OR max_discount_amount >= 0),
    usage_limit INT CHECK (usage_limit IS NULL OR usage_limit > 0),
    used_count INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 7. ORDERS & HISTORICAL ORDER ITEMS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT,
    delivery_division TEXT NOT NULL,
    delivery_district TEXT NOT NULL,
    delivery_upazila TEXT NOT NULL,
    delivery_address TEXT NOT NULL,
    delivery_instructions TEXT,
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    shipping_fee NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (shipping_fee >= 0),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    order_status TEXT NOT NULL DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    payment_method TEXT NOT NULL DEFAULT 'cod' CHECK (payment_method IN ('cod', 'online_sslcommerz', 'bkash_manual')),
    coupon_id UUID REFERENCES public.coupons(id) ON DELETE SET NULL,
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL,
    product_name_snapshot TEXT NOT NULL,
    sku_snapshot TEXT NOT NULL,
    weight_snapshot TEXT NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    total_price NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    discount_applied NUMERIC(12, 2) NOT NULL CHECK (discount_applied >= 0),
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(coupon_id, order_id)
);

-- ----------------------------------------------------------------------------
-- 8. PAYMENTS & GATEWAY INTEGRATION
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    payment_method TEXT NOT NULL,
    transaction_id TEXT UNIQUE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'BDT',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'refunded')),
    gateway_response JSONB,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 9. WISHLISTS & GENUINE REVIEWS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    comment TEXT NOT NULL,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 10. STORE SETTINGS & IMMUTABLE AUDIT LOGS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.store_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    old_values JSONB,
    new_values JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 11. INDEXES FOR PERFORMANCE & QUERY OPTIMIZATION
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_featured ON public.products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_images_product ON public.product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON public.orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(order_status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON public.payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_tx ON public.payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: supabase/migrations/002_security_rls.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ============================================================================
-- NUTORA E-COMMERCE PLATFORM — ROW LEVEL SECURITY (RLS) & POLICIES
-- Migration: 002_security_rls.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. HELPER SECURITY FUNCTIONS
-- ----------------------------------------------------------------------------

-- Get role name of the current authenticated user
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ur.name
  FROM public.profiles p
  JOIN public.user_roles ur ON p.role_id = ur.id
  WHERE p.id = auth.uid();
$$;

-- Check if current user is Super Admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.user_roles ur ON p.role_id = ur.id
    WHERE p.id = auth.uid() AND ur.name = 'super_admin' AND p.is_active = TRUE
  );
$$;

-- Check if current user is Editor or Super Admin
CREATE OR REPLACE FUNCTION public.is_editor_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.user_roles ur ON p.role_id = ur.id
    WHERE p.id = auth.uid() AND ur.name IN ('super_admin', 'editor') AND p.is_active = TRUE
  );
$$;

-- Check granular permission code for the authenticated user
CREATE OR REPLACE FUNCTION public.has_permission(perm_code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    JOIN public.user_roles ur ON p.role_id = ur.id
    JOIN public.role_permissions rp ON ur.id = rp.role_id
    JOIN public.permissions perm ON rp.permission_id = perm.id
    WHERE p.id = auth.uid() 
      AND p.is_active = TRUE
      AND (ur.name = 'super_admin' OR perm.code = perm_code)
  );
$$;

-- ----------------------------------------------------------------------------
-- 2. ENABLE RLS ON ALL TABLES
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 3. RLS POLICIES FOR USER ROLES & PERMISSIONS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Super admin can manage roles" ON public.user_roles;
CREATE POLICY "Super admin can manage roles"
    ON public.user_roles FOR ALL
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read roles" ON public.user_roles;
CREATE POLICY "Authenticated users can read roles"
    ON public.user_roles FOR SELECT
    TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Super admin can manage permissions" ON public.permissions;
CREATE POLICY "Super admin can manage permissions"
    ON public.permissions FOR ALL
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read permissions" ON public.permissions;
CREATE POLICY "Authenticated users can read permissions"
    ON public.permissions FOR SELECT
    TO authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "Super admin can manage role_permissions" ON public.role_permissions;
CREATE POLICY "Super admin can manage role_permissions"
    ON public.role_permissions FOR ALL
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read role_permissions" ON public.role_permissions;
CREATE POLICY "Authenticated users can read role_permissions"
    ON public.role_permissions FOR SELECT
    TO authenticated
    USING (TRUE);

-- ----------------------------------------------------------------------------
-- 4. RLS POLICIES FOR PROFILES
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid() OR public.is_super_admin());

DROP POLICY IF EXISTS "Users can update their own personal info" ON public.profiles;
CREATE POLICY "Users can update their own personal info"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid() OR public.is_super_admin())
    WITH CHECK (
        -- Regular customers/editors cannot escalate role or status
        (id = auth.uid() AND (role_id IS NOT DISTINCT FROM (SELECT role_id FROM public.profiles WHERE id = auth.uid())))
        OR public.is_super_admin()
    );

DROP POLICY IF EXISTS "Super admin can insert profiles" ON public.profiles;
CREATE POLICY "Super admin can insert profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (id = auth.uid() OR public.is_super_admin());

-- ----------------------------------------------------------------------------
-- 5. RLS POLICIES FOR CATEGORIES & PRODUCTS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Anyone can view active categories" ON public.categories;
CREATE POLICY "Anyone can view active categories"
    ON public.categories FOR SELECT
    USING (is_active = TRUE OR public.is_editor_or_admin());

DROP POLICY IF EXISTS "Staff can insert categories" ON public.categories;
CREATE POLICY "Staff can insert categories"
    ON public.categories FOR INSERT
    WITH CHECK (public.has_permission('products.create'));

DROP POLICY IF EXISTS "Staff can update categories" ON public.categories;
CREATE POLICY "Staff can update categories"
    ON public.categories FOR UPDATE
    USING (public.has_permission('products.edit'));

DROP POLICY IF EXISTS "Super admin can delete categories" ON public.categories;
CREATE POLICY "Super admin can delete categories"
    ON public.categories FOR DELETE
    USING (public.is_super_admin());

-- Products
DROP POLICY IF EXISTS "Public can view published products" ON public.products;
CREATE POLICY "Public can view published products"
    ON public.products FOR SELECT
    USING (status = 'published' OR public.is_editor_or_admin());

DROP POLICY IF EXISTS "Staff can insert products" ON public.products;
CREATE POLICY "Staff can insert products"
    ON public.products FOR INSERT
    WITH CHECK (public.has_permission('products.create'));

DROP POLICY IF EXISTS "Staff can update products" ON public.products;
CREATE POLICY "Staff can update products"
    ON public.products FOR UPDATE
    USING (public.has_permission('products.edit'));

DROP POLICY IF EXISTS "Super admin can delete products" ON public.products;
CREATE POLICY "Super admin can delete products"
    ON public.products FOR DELETE
    USING (public.is_super_admin());

-- Product Images & Variants
DROP POLICY IF EXISTS "Public can view images of published products" ON public.product_images;
CREATE POLICY "Public can view images of published products"
    ON public.product_images FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.products p 
            WHERE p.id = product_id AND (p.status = 'published' OR public.is_editor_or_admin())
        )
    );

DROP POLICY IF EXISTS "Staff can manage product images" ON public.product_images;
CREATE POLICY "Staff can manage product images"
    ON public.product_images FOR ALL
    USING (public.has_permission('products.edit'));

DROP POLICY IF EXISTS "Public can view active variants of published products" ON public.product_variants;
CREATE POLICY "Public can view active variants of published products"
    ON public.product_variants FOR SELECT
    USING (
        is_active = TRUE AND EXISTS (
            SELECT 1 FROM public.products p 
            WHERE p.id = product_id AND (p.status = 'published' OR public.is_editor_or_admin())
        )
    );

DROP POLICY IF EXISTS "Staff can manage product variants" ON public.product_variants;
CREATE POLICY "Staff can manage product variants"
    ON public.product_variants FOR ALL
    USING (public.has_permission('inventory.update'));

-- ----------------------------------------------------------------------------
-- 6. RLS POLICIES FOR CARTS & CART ITEMS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can manage own cart" ON public.carts;
CREATE POLICY "Users can manage own cart"
    ON public.carts FOR ALL
    USING (user_id = auth.uid() OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can manage own cart items" ON public.cart_items;
CREATE POLICY "Users can manage own cart items"
    ON public.cart_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.carts c
            WHERE c.id = cart_id AND (c.user_id = auth.uid() OR c.user_id IS NULL)
        )
    );

-- ----------------------------------------------------------------------------
-- 7. RLS POLICIES FOR ADDRESSES
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can manage their own addresses" ON public.addresses;
CREATE POLICY "Users can manage their own addresses"
    ON public.addresses FOR ALL
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Staff can view customer addresses for orders" ON public.addresses;
CREATE POLICY "Staff can view customer addresses for orders"
    ON public.addresses FOR SELECT
    USING (public.is_editor_or_admin());

-- ----------------------------------------------------------------------------
-- 8. RLS POLICIES FOR COUPONS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Anyone can view active coupons to validate" ON public.coupons;
CREATE POLICY "Anyone can view active coupons to validate"
    ON public.coupons FOR SELECT
    USING (is_active = TRUE OR public.is_editor_or_admin());

DROP POLICY IF EXISTS "Super admin can manage coupons" ON public.coupons;
CREATE POLICY "Super admin can manage coupons"
    ON public.coupons FOR ALL
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Users can view their coupon redemptions" ON public.coupon_redemptions;
CREATE POLICY "Users can view their coupon redemptions"
    ON public.coupon_redemptions FOR SELECT
    USING (user_id = auth.uid() OR public.is_editor_or_admin());

-- ----------------------------------------------------------------------------
-- 9. RLS POLICIES FOR ORDERS & ORDER ITEMS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Customers can view only their own orders" ON public.orders;
CREATE POLICY "Customers can view only their own orders"
    ON public.orders FOR SELECT
    USING (user_id = auth.uid() OR public.has_permission('orders.manage'));

DROP POLICY IF EXISTS "Order creation allowed via trusted procedure" ON public.orders;
CREATE POLICY "Order creation allowed via trusted procedure"
    ON public.orders FOR INSERT
    WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

DROP POLICY IF EXISTS "Staff can update order status" ON public.orders;
CREATE POLICY "Staff can update order status"
    ON public.orders FOR UPDATE
    USING (public.has_permission('orders.manage'));

DROP POLICY IF EXISTS "Customers can view only their order items" ON public.order_items;
CREATE POLICY "Customers can view only their order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_id AND (o.user_id = auth.uid() OR public.has_permission('orders.manage'))
        )
    );

-- ----------------------------------------------------------------------------
-- 10. RLS POLICIES FOR PAYMENTS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Customers can view payment status of their own order" ON public.payments;
CREATE POLICY "Customers can view payment status of their own order"
    ON public.payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_id AND (o.user_id = auth.uid() OR public.has_permission('orders.manage'))
        )
    );

DROP POLICY IF EXISTS "Staff with permission can manage payments" ON public.payments;
CREATE POLICY "Staff with permission can manage payments"
    ON public.payments FOR ALL
    USING (public.has_permission('orders.refund') OR public.is_super_admin());

-- ----------------------------------------------------------------------------
-- 11. RLS POLICIES FOR WISHLISTS & REVIEWS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can manage their own wishlist" ON public.wishlists;
CREATE POLICY "Users can manage their own wishlist"
    ON public.wishlists FOR ALL
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Public can view approved reviews" ON public.reviews;
CREATE POLICY "Public can view approved reviews"
    ON public.reviews FOR SELECT
    USING (is_approved = TRUE OR user_id = auth.uid() OR public.is_editor_or_admin());

DROP POLICY IF EXISTS "Verified customers can submit reviews" ON public.reviews;
CREATE POLICY "Verified customers can submit reviews"
    ON public.reviews FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Super admin can moderate reviews" ON public.reviews;
CREATE POLICY "Super admin can moderate reviews"
    ON public.reviews FOR UPDATE
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Super admin can delete reviews" ON public.reviews;
CREATE POLICY "Super admin can delete reviews"
    ON public.reviews FOR DELETE
    USING (public.is_super_admin());

-- ----------------------------------------------------------------------------
-- 12. RLS POLICIES FOR STORE SETTINGS & AUDIT LOGS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public can read general store settings" ON public.store_settings;
CREATE POLICY "Public can read general store settings"
    ON public.store_settings FOR SELECT
    USING (TRUE);

DROP POLICY IF EXISTS "Super admin can manage store settings" ON public.store_settings;
CREATE POLICY "Super admin can manage store settings"
    ON public.store_settings FOR ALL
    USING (public.is_super_admin());

DROP POLICY IF EXISTS "Only Super Admin can view audit logs" ON public.audit_logs;
CREATE POLICY "Only Super Admin can view audit logs"
    ON public.audit_logs FOR SELECT
    USING (public.is_super_admin());

-- Immutable audit logs: No one can UPDATE or DELETE audit records
DROP POLICY IF EXISTS "No update on audit logs" ON public.audit_logs;
CREATE POLICY "No update on audit logs"
    ON public.audit_logs FOR UPDATE
    USING (FALSE);

DROP POLICY IF EXISTS "No delete on audit logs" ON public.audit_logs;
CREATE POLICY "No delete on audit logs"
    ON public.audit_logs FOR DELETE
    USING (FALSE);


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: supabase/migrations/003_functions_and_triggers.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ============================================================================
-- NUTORA E-COMMERCE PLATFORM — PROCEDURES, TRIGGERS & BUSINESS LOGIC
-- Migration: 003_functions_and_triggers.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. AUTO-CREATE USER PROFILE ON AUTH.USERS SIGNUP (SAFE BOOTSTRAP)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    default_role_id UUID;
BEGIN
    -- Public signup ALWAYS assigns 'customer' role
    SELECT id INTO default_role_id FROM public.user_roles WHERE name = 'customer';
    
    INSERT INTO public.profiles (id, full_name, phone, role_id, is_active)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Nutora Customer'),
        NEW.raw_user_meta_data->>'phone',
        default_role_id,
        TRUE
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        updated_at = now();

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 2. PREVENT ACCIDENTAL REMOVAL OR DEMOTION OF LAST ACTIVE SUPER ADMIN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_last_super_admin()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    super_admin_role_id UUID;
    active_super_admin_count INT;
BEGIN
    SELECT id INTO super_admin_role_id FROM public.user_roles WHERE name = 'super_admin';

    -- Check if target user was a super admin
    IF OLD.role_id = super_admin_role_id THEN
        -- If operation is DELETE or role change or deactivation
        IF (TG_OP = 'DELETE') OR (TG_OP = 'UPDATE' AND (NEW.role_id != super_admin_role_id OR NEW.is_active = FALSE)) THEN
            SELECT count(*) INTO active_super_admin_count
            FROM public.profiles
            WHERE role_id = super_admin_role_id AND is_active = TRUE AND id != OLD.id;

            IF active_super_admin_count < 1 THEN
                RAISE EXCEPTION 'Action aborted: Cannot remove, demote, or deactivate the last active Super Admin!';
            END IF;
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_last_super_admin ON public.profiles;
CREATE TRIGGER trg_protect_last_super_admin
    BEFORE UPDATE OR DELETE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_last_super_admin();

-- ----------------------------------------------------------------------------
-- 3. AUDIT LOGGING HELPER & TRIGGER
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_audit_event(
    p_action TEXT,
    p_entity_type TEXT,
    p_entity_id TEXT,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_email TEXT;
BEGIN
    SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;

    INSERT INTO public.audit_logs (user_id, user_email, action, entity_type, entity_id, old_values, new_values)
    VALUES (v_user_id, v_email, p_action, p_entity_type, p_entity_id, p_old_values, p_new_values);
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. SECURE TRANSACTIONAL ORDER CREATION (SERVER-SIDE PRICE RECALCULATION)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_order_transaction(
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_customer_email TEXT,
    p_division TEXT,
    p_district TEXT,
    p_upazila TEXT,
    p_address TEXT,
    p_instructions TEXT,
    p_payment_method TEXT,
    p_coupon_code TEXT,
    p_items JSONB, -- Array of objects: [{ "product_id": "...", "variant_id": "...", "quantity": 1 }]
    p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order_id UUID := gen_random_uuid();
    v_order_number TEXT;
    v_user_id UUID := auth.uid();
    v_subtotal NUMERIC(12, 2) := 0.00;
    v_discount NUMERIC(12, 2) := 0.00;
    v_shipping NUMERIC(12, 2) := 70.00; -- Default Dhaka shipping
    v_total NUMERIC(12, 2) := 0.00;
    
    v_coupon_id UUID := NULL;
    v_coupon_type TEXT;
    v_coupon_val NUMERIC(12, 2);
    v_coupon_min NUMERIC(12, 2);
    v_coupon_max NUMERIC(12, 2);
    v_coupon_limit INT;
    v_coupon_used INT;
    
    v_item RECORD;
    v_product RECORD;
    v_variant RECORD;
    v_unit_price NUMERIC(12, 2);
    v_item_total NUMERIC(12, 2);
    v_item_name TEXT;
    v_item_sku TEXT;
    v_item_weight TEXT;
BEGIN
    -- Idempotency check: if key already processed, return existing order
    IF p_idempotency_key IS NOT NULL THEN
        SELECT id, order_number, total_amount INTO v_order_id, v_order_number, v_total
        FROM public.orders
        WHERE idempotency_key = p_idempotency_key;
        
        IF FOUND THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'order_id', v_order_id,
                'order_number', v_order_number,
                'total_amount', v_total,
                'message', 'Existing order retrieved via idempotency key.'
            );
        END IF;
        v_order_id := gen_random_uuid();
    END IF;

    -- Generate human-friendly order number: NUT-YYYYMMDD-XXXX
    v_order_number := 'NUT-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text), 1, 4));

    -- Calculate shipping based on division
    IF lower(p_division) = 'dhaka' THEN
        v_shipping := 70.00;
    ELSE
        v_shipping := 130.00;
    END IF;

    -- Validate items array
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Order must contain at least one item.';
    END IF;

    -- Loop through items, recalculate pricing and check stock
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id UUID, variant_id UUID, quantity INT)
    LOOP
        IF v_item.quantity <= 0 THEN
            RAISE EXCEPTION 'Item quantity must be greater than zero.';
        END IF;

        -- Fetch and lock product
        SELECT * INTO v_product FROM public.products WHERE id = v_item.product_id FOR UPDATE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product with ID % not found.', v_item.product_id;
        END IF;

        IF v_product.status != 'published' THEN
            RAISE EXCEPTION 'Product % is currently unavailable.', v_product.name;
        END IF;

        -- Determine base price (apply sale price if lower)
        v_unit_price := COALESCE(v_product.sale_price, v_product.base_price);
        v_item_name := v_product.name;
        v_item_sku := v_product.sku;
        v_item_weight := v_product.weight_volume;

        -- Check variant if specified
        IF v_item.variant_id IS NOT NULL THEN
            SELECT * INTO v_variant FROM public.product_variants WHERE id = v_item.variant_id FOR UPDATE;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Variant not found for product %.', v_product.name;
            END IF;
            IF v_variant.stock_quantity < v_item.quantity THEN
                RAISE EXCEPTION 'Insufficient stock for variant % of % (Available: %)', v_variant.name, v_product.name, v_variant.stock_quantity;
            END IF;
            v_unit_price := v_unit_price + v_variant.price_adjustment;
            v_item_name := v_item_name || ' (' || v_variant.name || ')';
            v_item_sku := v_variant.sku;
            v_item_weight := v_variant.weight_volume;

            -- Deduct variant stock
            UPDATE public.product_variants
            SET stock_quantity = stock_quantity - v_item.quantity
            WHERE id = v_item.variant_id;
        ELSE
            IF v_product.stock_quantity < v_item.quantity THEN
                RAISE EXCEPTION 'Insufficient stock for % (Available: %)', v_product.name, v_product.stock_quantity;
            END IF;

            -- Deduct product stock
            UPDATE public.products
            SET stock_quantity = stock_quantity - v_item.quantity
            WHERE id = v_item.product_id;
        END IF;

        v_item_total := v_unit_price * v_item.quantity;
        v_subtotal := v_subtotal + v_item_total;
    END LOOP;

    -- Free shipping threshold check (e.g. over ৳1,500 in Dhaka)
    IF v_subtotal >= 1500.00 AND lower(p_division) = 'dhaka' THEN
        v_shipping := 0.00;
    END IF;

    -- Validate coupon if provided
    IF p_coupon_code IS NOT NULL AND trim(p_coupon_code) != '' THEN
        SELECT id, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, used_count
        INTO v_coupon_id, v_coupon_type, v_coupon_val, v_coupon_min, v_coupon_max, v_coupon_limit, v_coupon_used
        FROM public.coupons
        WHERE code = upper(trim(p_coupon_code))
          AND is_active = TRUE
          AND valid_from <= now()
          AND (valid_until IS NULL OR valid_until >= now())
        FOR UPDATE;

        IF FOUND THEN
            IF v_coupon_limit IS NOT NULL AND v_coupon_used >= v_coupon_limit THEN
                v_coupon_id := NULL; -- Limit reached, ignore coupon
            ELSIF v_subtotal < v_coupon_min THEN
                v_coupon_id := NULL; -- Minimum order not met
            ELSE
                IF v_coupon_type = 'percentage' THEN
                    v_discount := (v_subtotal * (v_coupon_val / 100.00));
                    IF v_coupon_max IS NOT NULL AND v_discount > v_coupon_max THEN
                        v_discount := v_coupon_max;
                    END IF;
                ELSE
                    v_discount := LEAST(v_coupon_val, v_subtotal);
                END IF;

                -- Increment coupon usage
                UPDATE public.coupons SET used_count = used_count + 1 WHERE id = v_coupon_id;
            END IF;
        END IF;
    END IF;

    v_total := (v_subtotal - v_discount) + v_shipping;

    -- Insert Order
    INSERT INTO public.orders (
        id, order_number, user_id, customer_name, customer_phone, customer_email,
        delivery_division, delivery_district, delivery_upazila, delivery_address, delivery_instructions,
        subtotal, discount_amount, shipping_fee, total_amount, order_status, payment_status,
        payment_method, coupon_id, idempotency_key
    ) VALUES (
        v_order_id, v_order_number, v_user_id, p_customer_name, p_customer_phone, p_customer_email,
        p_division, p_district, p_upazila, p_address, p_instructions,
        v_subtotal, v_discount, v_shipping, v_total, 'pending', 'pending',
        p_payment_method, v_coupon_id, p_idempotency_key
    );

    -- Insert Order Items with snapshots
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id UUID, variant_id UUID, quantity INT)
    LOOP
        SELECT * INTO v_product FROM public.products WHERE id = v_item.product_id;
        v_unit_price := COALESCE(v_product.sale_price, v_product.base_price);
        v_item_name := v_product.name;
        v_item_sku := v_product.sku;
        v_item_weight := v_product.weight_volume;

        IF v_item.variant_id IS NOT NULL THEN
            SELECT * INTO v_variant FROM public.product_variants WHERE id = v_item.variant_id;
            v_unit_price := v_unit_price + v_variant.price_adjustment;
            v_item_name := v_item_name || ' (' || v_variant.name || ')';
            v_item_sku := v_variant.sku;
            v_item_weight := v_variant.weight_volume;
        END IF;

        INSERT INTO public.order_items (
            order_id, product_id, variant_id, product_name_snapshot,
            sku_snapshot, weight_snapshot, unit_price, quantity, total_price
        ) VALUES (
            v_order_id, v_item.product_id, v_item.variant_id, v_item_name,
            v_item_sku, v_item_weight, v_unit_price, v_item.quantity, (v_unit_price * v_item.quantity)
        );
    END LOOP;

    -- Record coupon redemption if valid
    IF v_coupon_id IS NOT NULL AND v_discount > 0 THEN
        INSERT INTO public.coupon_redemptions (coupon_id, order_id, user_id, discount_applied)
        VALUES (v_coupon_id, v_order_id, v_user_id, v_discount);
    END IF;

    -- Return JSON response
    RETURN jsonb_build_object(
        'success', TRUE,
        'order_id', v_order_id,
        'order_number', v_order_number,
        'subtotal', v_subtotal,
        'discount', v_discount,
        'shipping', v_shipping,
        'total_amount', v_total,
        'payment_method', p_payment_method
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. ORDER STATUS TRANSITION & INVENTORY RESTORATION ON CANCELLATION
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_order_status(
    p_order_id UUID,
    p_new_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
BEGIN
    IF NOT public.has_permission('orders.manage') THEN
        RAISE EXCEPTION 'Access denied: insufficient privileges to change order status.';
    END IF;

    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found.';
    END IF;

    -- If transitioning to cancelled, restore product stock
    IF p_new_status = 'cancelled' AND v_order.order_status != 'cancelled' THEN
        FOR v_item IN SELECT * FROM public.order_items WHERE order_id = p_order_id
        LOOP
            IF v_item.variant_id IS NOT NULL THEN
                UPDATE public.product_variants
                SET stock_quantity = stock_quantity + v_item.quantity
                WHERE id = v_item.variant_id;
            ELSIF v_item.product_id IS NOT NULL THEN
                UPDATE public.products
                SET stock_quantity = stock_quantity + v_item.quantity
                WHERE id = v_item.product_id;
            END IF;
        END LOOP;
    END IF;

    -- Update order status
    UPDATE public.orders
    SET order_status = p_new_status, updated_at = now()
    WHERE id = p_order_id;

    -- Audit log
    PERFORM public.log_audit_event(
        'ORDER_STATUS_CHANGED',
        'orders',
        p_order_id::text,
        jsonb_build_object('status', v_order.order_status),
        jsonb_build_object('status', p_new_status)
    );

    RETURN jsonb_build_object('success', TRUE, 'new_status', p_new_status);
END;
$$;


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- FILE: supabase/seed.sql
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

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
