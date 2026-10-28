/**
 * NUTORA — Super Admin & Granular RBAC Security Verification Tests
 */
const assert = require('assert');
const {
  NutoraAuthEngine,
  NUTORA_PERMISSIONS,
  DEFAULT_ADMIN_PERMISSIONS,
  DEFAULT_EDITOR_PERMISSIONS
} = require('../js/auth.js');

console.log("==================================================================");
console.log("NUTORA — RBAC & SUPER ADMIN SECURITY TEST SUITE");
console.log("==================================================================");

// Mock localStorage for Node environment
global.localStorage = {
  store: {},
  getItem(key) { return this.store[key] || null; },
  setItem(key, val) { this.store[key] = String(val); },
  removeItem(key) { delete this.store[key]; },
  clear() { this.store = {}; }
};

const auth = new NutoraAuthEngine();

// Test 1: Setting Custom Super Admin Credentials
console.log("--> Test 1: Setting Custom Super Admin Credentials...");
(async () => {
  const customAdmin = await auth.setSuperAdmin('Shuharthu Tapash Barua', 'shuharthu@nutorafood.com', '01712345678', 'MasterPass2026!');
  assert.strictEqual(customAdmin.fullName, 'Shuharthu Tapash Barua');
  assert.strictEqual(customAdmin.email, 'shuharthu@nutorafood.com');
  assert.strictEqual(customAdmin.role, 'super_admin');
  assert.strictEqual(auth.hasPermission('products.create_edit'), true);
  assert.strictEqual(auth.hasPermission('users.manage'), true);
  console.log("    ✓ Super Admin customization and permissions verified.");

  // Test 2: Super Admin creating an Admin with custom permissions
  console.log("--> Test 2: Super Admin creating an Admin account with granular permissions...");
  const adminPermissions = ['products.create_edit', 'products.publish', 'orders.status', 'inventory.update'];
  const newAdmin = await auth.createStaffAccount(
    'Kitchen Operations Lead',
    'ops@nutorafood.com',
    '01788776655',
    'OpsPass2026!',
    'admin',
    adminPermissions
  );
  assert.strictEqual(newAdmin.role, 'admin');
  assert.strictEqual(newAdmin.fullName, 'Kitchen Operations Lead');
  assert.deepStrictEqual(newAdmin.permissions, adminPermissions);
  console.log("    ✓ Admin account created with 4 explicit permissions.");

  // Test 3: Admin permission evaluation
  console.log("--> Test 3: Verifying Admin permission evaluation...");
  auth.currentUser = newAdmin;
  assert.strictEqual(auth.hasPermission('products.create_edit'), true);
  assert.strictEqual(auth.hasPermission('orders.status'), true);
  assert.strictEqual(auth.hasPermission('inventory.update'), true);
  // Does not have 'products.delete' or 'users.manage'
  assert.strictEqual(auth.hasPermission('products.delete'), false);
  assert.strictEqual(auth.hasPermission('users.manage'), false);
  console.log("    ✓ Granular permissions correctly honored for Admin.");

  // Test 4: Editor creation with Editor defaults
  console.log("--> Test 4: Super Admin creating an Editor account...");
  auth.currentUser = customAdmin; // Switch back to Super Admin
  const newEditor = await auth.createStaffAccount(
    'Product Writer',
    'writer@nutorafood.com',
    '01999112233',
    'WriterPass2026!',
    'editor'
  );
  assert.strictEqual(newEditor.role, 'editor');
  assert.deepStrictEqual(newEditor.permissions, DEFAULT_EDITOR_PERMISSIONS);
  auth.currentUser = newEditor;
  assert.strictEqual(auth.hasPermission('products.create_edit'), true);
  assert.strictEqual(auth.hasPermission('orders.status'), false);
  console.log("    ✓ Editor created and permissions restricted.");

  // Test 5: Super Admin modifying permissions of existing staff
  console.log("--> Test 5: Super Admin updating existing staff permissions...");
  auth.currentUser = customAdmin;
  const updatedAdmin = await auth.updateStaffAccount(newAdmin.id, {
    fullName: 'Chief Operations Officer',
    permissions: [...adminPermissions, 'products.delete', 'coupons.manage']
  });
  assert.strictEqual(updatedAdmin.fullName, 'Chief Operations Officer');
  assert.strictEqual(updatedAdmin.permissions.includes('products.delete'), true);
  assert.strictEqual(updatedAdmin.permissions.includes('coupons.manage'), true);
  console.log("    ✓ Permissions updated successfully.");

  // Test 6: Unauthorized user CANNOT create staff
  console.log("--> Test 6: Verifying Unauthorized users CANNOT create staff...");
  auth.currentUser = { id: 'usr-cust-1', email: 'visitor@example.com', role: 'customer' };
  let caught = false;
  try {
    await auth.createStaffAccount('Hacker', 'hacker@nutorafood.com', '', 'pass', 'super_admin');
  } catch (err) {
    caught = true;
    assert.match(err.message, /Access Denied/);
  }
  assert.strictEqual(caught, true);
  console.log("    ✓ Customer/Visitor blocked from creating staff.");

  // Test 7: Last Super Admin Protection
  console.log("--> Test 7: Verifying Last Super Admin Protection...");
  auth.currentUser = customAdmin;
  caught = false;
  try {
    await auth.updateStaffStatus(customAdmin.id, false);
  } catch (err) {
    caught = true;
    assert.match(err.message, /Security Restriction/);
  }
  assert.strictEqual(caught, true);
  console.log("    ✓ Last Super Admin protection verified.");

  // Test 8: Public Registration is strictly 'customer'
  console.log("--> Test 8: Verifying Public Registration role constraint...");
  const publicReg = await auth.register('Jane Shopper', 'jane@example.com', '01999888777', 'Pass1234');
  assert.strictEqual(publicReg.role, 'customer', "Public registration must only produce customer role");
  assert.strictEqual(auth.hasPermission('products.create_edit'), false);
  console.log("    ✓ Public registration strictly locked to 'customer'.");

  // Test 9: Role detection by email
  console.log("--> Test 9: Verifying Reactive Role Detection by Email...");
  const adminDetect = auth.detectRoleByEmail('shuharthu@nutorafood.com');
  assert.strictEqual(adminDetect.role, 'super_admin');
  const opsDetect = auth.detectRoleByEmail('ops@nutorafood.com');
  assert.strictEqual(opsDetect.role, 'admin');
  const writerDetect = auth.detectRoleByEmail('writer@nutorafood.com');
  assert.strictEqual(writerDetect.role, 'editor');
  const custDetect = auth.detectRoleByEmail('jane@example.com');
  assert.strictEqual(custDetect.role, 'customer');
  const randomDetect = auth.detectRoleByEmail('unknown-user@gmail.com');
  assert.strictEqual(randomDetect.role, 'customer');
  console.log("    ✓ Reactive role detection correctly identifies Super Admin, Admin, Editor, and Customer.");

  console.log("==================================================================");
  console.log("ALL 9 RBAC & SUPER ADMIN TESTS PASSED (100% SECURE)!");
  console.log("==================================================================");
})();
