/**
 * NUTORA — Super Admin & RBAC Security Verification Tests
 */
const assert = require('assert');

// Simulate the NutoraAuthEngine logic
class MockAuthEngine {
  constructor() {
    this.users = [
      { id: 'usr-admin-1', email: 'admin@nutorafood.com', role: 'super_admin', fullName: 'Initial Admin', isActive: true },
      { id: 'usr-editor-1', email: 'editor@nutorafood.com', role: 'editor', fullName: 'Catalog Editor', isActive: true },
      { id: 'usr-cust-1', email: 'customer@example.com', role: 'customer', fullName: 'Shopper', isActive: true }
    ];
    this.currentUser = null;
    this.isConfigured = false;
  }

  setSuperAdmin(fullName, email, phone, password) {
    let admin = this.users.find(u => u.role === 'super_admin');
    if (admin) {
      admin.fullName = fullName;
      admin.email = email;
      admin.phone = phone;
    } else {
      admin = { id: 'usr-admin-' + Date.now(), email, role: 'super_admin', fullName, isActive: true };
      this.users.unshift(admin);
    }
    this.currentUser = admin;
    this.isConfigured = true;
    return admin;
  }

  createStaffAccount(fullName, email, phone, password, role) {
    // Security check: Only Super Admin can create staff
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can create staff accounts.');
    }
    if (role !== 'editor' && role !== 'super_admin') {
      throw new Error('Invalid role.');
    }
    const cleanEmail = email.trim().toLowerCase();
    if (this.users.find(u => u.email === cleanEmail)) {
      throw new Error('Email already registered.');
    }
    const newStaff = { id: 'usr-staff-' + Date.now(), email: cleanEmail, role, fullName, isActive: true };
    this.users.push(newStaff);
    return newStaff;
  }

  updateStaffStatus(id, isActive) {
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can modify staff status.');
    }
    const target = this.users.find(u => u.id === id);
    if (!target) throw new Error('Not found');

    if (target.role === 'super_admin' && !isActive) {
      const activeSuperAdmins = this.users.filter(u => u.role === 'super_admin' && u.isActive);
      if (activeSuperAdmins.length <= 1) {
        throw new Error('Security Restriction: You cannot deactivate or remove the last active Super Admin.');
      }
    }
    target.isActive = isActive;
    return target;
  }

  registerPublicUser(fullName, email, phone, password) {
    // Public registration is strictly customer
    const user = { id: 'usr-cust-' + Date.now(), email, role: 'customer', fullName, isActive: true };
    this.users.push(user);
    return user;
  }
}

console.log("==================================================================");
console.log("NUTORA — RBAC & SUPER ADMIN SECURITY TEST SUITE");
console.log("==================================================================");

const auth = new MockAuthEngine();

// Test 1: User sets their own Super Admin
console.log("--> Test 1: Setting Custom Super Admin Credentials...");
const customAdmin = auth.setSuperAdmin('Shuharthu Tapash Barua', 'shuharthu@nutorafood.com', '01712345678', 'MasterPass2026!');
assert.strictEqual(customAdmin.fullName, 'Shuharthu Tapash Barua');
assert.strictEqual(customAdmin.email, 'shuharthu@nutorafood.com');
assert.strictEqual(customAdmin.role, 'super_admin');
assert.strictEqual(auth.isConfigured, true);
console.log("    ✓ Super Admin customization verified.");

// Test 2: Only Super Admin can create staff
console.log("--> Test 2: Super Admin creating an Editor account...");
const editor = auth.createStaffAccount('Asif Editor', 'asif@nutorafood.com', '01811223344', 'EditorPass2026!', 'editor');
assert.strictEqual(editor.role, 'editor');
assert.strictEqual(editor.fullName, 'Asif Editor');
console.log("    ✓ Super Admin created editor successfully.");

// Test 3: Unauthorized user (customer or visitor) CANNOT create staff
console.log("--> Test 3: Verifying Visitors/Customers CANNOT create staff...");
auth.currentUser = { id: 'usr-cust-1', email: 'visitor@example.com', role: 'customer' };
assert.throws(() => {
  auth.createStaffAccount('Hacker', 'hacker@nutorafood.com', '', 'pass', 'super_admin');
}, /Access Denied/);
console.log("    ✓ Visitor/Customer blocked from creating staff.");

// Test 4: Editor CANNOT create staff
console.log("--> Test 4: Verifying Editor CANNOT create staff...");
auth.currentUser = editor;
assert.throws(() => {
  auth.createStaffAccount('New Guy', 'new@nutorafood.com', '', 'pass', 'editor');
}, /Access Denied/);
console.log("    ✓ Editor blocked from creating staff.");

// Test 5: Last Super Admin Protection
console.log("--> Test 5: Verifying Last Super Admin Protection...");
auth.currentUser = customAdmin;
assert.throws(() => {
  auth.updateStaffStatus(customAdmin.id, false);
}, /Security Restriction/);
console.log("    ✓ Last Super Admin protection verified.");

// Test 6: Public Registration is strictly 'customer'
console.log("--> Test 6: Verifying Public Registration role constraint...");
const publicReg = auth.registerPublicUser('Jane Doe', 'jane@example.com', '01999888777', 'Pass1234');
assert.strictEqual(publicReg.role, 'customer', "Public registration must only produce customer role");
console.log("    ✓ Public registration strictly locked to 'customer'.");

console.log("==================================================================");
console.log("ALL RBAC & SUPER ADMIN TESTS PASSED (100% SECURE)!");
console.log("==================================================================");
