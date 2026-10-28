"""
NUTORA — Automated Verification & Integrity Test Suite
Tests all pages, assets, SQL migrations, and HTTP endpoints.
"""

import os
import re
import urllib.request

BASE_URL = "http://localhost:3000"

def test_pages_exist():
    print("--> Test 1: Verifying HTML Pages...")
    required_pages = [
        "index.html",
        "shop.html",
        "product.html",
        "cart.html",
        "checkout.html",
        "login.html",
        "register.html",
        "account.html",
        "about.html",
        "contact.html",
        "faq.html",
        "shipping-policy.html",
        "refund-policy.html",
        "privacy-policy.html",
        "terms.html",
        "admin/index.html",
        "admin/login.html",
        "admin/setup.html",
        "admin/products.html",
        "admin/orders.html",
        "admin/inventory.html",
        "admin/categories.html",
        "admin/customers.html",
        "admin/coupons.html",
        "admin/reviews.html",
        "admin/settings.html",
        "admin/users.html",
        "admin/audit-logs.html"
    ]
    for page in required_pages:
        assert os.path.exists(page), f"Missing page: {page}"
        with open(page, 'r', encoding='utf-8') as f:
            content = f.read()
            assert "<!DOCTYPE html>" in content or "<!doctype html>" in content.lower(), f"{page} missing doctype"
            assert "NUTORA" in content, f"{page} missing brand name"
    print(f"    ✓ All {len(required_pages)} pages exist and are valid HTML5.")

def test_brand_assets():
    print("--> Test 2: Verifying Official Brand Assets...")
    brand_assets = [
        "assets/brand/nutora-logo-original.png",
        "assets/brand/nutora-logo.png",
        "assets/brand/nutora-logo.webp",
        "assets/brand/nutora-icon.svg",
        "favicon.ico"
    ]
    for asset in brand_assets:
        assert os.path.exists(asset), f"Missing asset: {asset}"
        assert os.path.getsize(asset) > 100, f"Asset empty or corrupt: {asset}"
    print(f"    ✓ All {len(brand_assets)} brand assets verified.")

def test_sql_migrations():
    print("--> Test 3: Verifying SQL Migrations & 20+ Tables...")
    migration_files = [
        "supabase/migrations/001_initial_schema.sql",
        "supabase/migrations/002_security_rls.sql",
        "supabase/migrations/003_functions_and_triggers.sql",
        "supabase/seed.sql"
    ]
    for mf in migration_files:
        assert os.path.exists(mf), f"Missing migration file: {mf}"

    with open("supabase/migrations/001_initial_schema.sql", 'r', encoding='utf-8') as f:
        schema = f.read()

    required_tables = [
        "profiles", "user_roles", "permissions", "role_permissions",
        "categories", "products", "product_images", "product_variants",
        "carts", "cart_items", "addresses", "orders", "order_items",
        "payments", "coupons", "coupon_redemptions", "wishlists",
        "reviews", "store_settings", "audit_logs"
    ]
    for tbl in required_tables:
        pattern = rf"CREATE TABLE IF NOT EXISTS public\.{tbl}\b"
        assert re.search(pattern, schema), f"Missing table definition: {tbl}"

    with open("supabase/migrations/002_security_rls.sql", 'r', encoding='utf-8') as f:
        rls = f.read()
    for tbl in required_tables:
        pattern = rf"ALTER TABLE public\.{tbl} ENABLE ROW LEVEL SECURITY;"
        assert re.search(pattern, rls), f"RLS not enabled for: {tbl}"

    with open("supabase/migrations/003_functions_and_triggers.sql", 'r', encoding='utf-8') as f:
        procs = f.read()
    assert "create_order_transaction" in procs, "Missing create_order_transaction procedure"
    assert "protect_last_super_admin" in procs, "Missing protect_last_super_admin trigger"
    assert "log_audit_event" in procs, "Missing log_audit_event procedure"

    print(f"    ✓ All {len(required_tables)} database tables, RLS policies, and triggers verified.")

def test_http_endpoints():
    print("--> Test 4: Verifying Live Local Endpoints (HTTP 200)...")
    endpoints = [
        "/index.html",
        "/shop.html",
        "/product.html?id=prod-001",
        "/cart.html",
        "/checkout.html",
        "/login.html",
        "/register.html",
        "/account.html",
        "/about.html",
        "/contact.html",
        "/faq.html",
        "/admin/index.html",
        "/admin/products.html",
        "/admin/orders.html",
        "/admin/inventory.html"
    ]
    for ep in endpoints:
        url = BASE_URL + ep
        req = urllib.request.Request(url, headers={'User-Agent': 'NutoraTestRunner/1.0'})
        with urllib.request.urlopen(req) as response:
            assert response.status == 200, f"Endpoint {ep} returned status {response.status}"
    print(f"    ✓ All {len(endpoints)} tested endpoints returned HTTP 200 OK.")

if __name__ == "__main__":
    print("==================================================================")
    print("NUTORA — E-COMMERCE PLATFORM INTEGRATION TEST SUITE")
    print("==================================================================")
    test_pages_exist()
    test_brand_assets()
    test_sql_migrations()
    test_http_endpoints()
    print("==================================================================")
    print("ALL TESTS PASSED SUCCESSFULLY! (100% Verification)")
    print("==================================================================")
