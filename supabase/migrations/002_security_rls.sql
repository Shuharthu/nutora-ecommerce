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
