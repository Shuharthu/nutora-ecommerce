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
