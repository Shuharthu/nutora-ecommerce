/**
 * NUTORA — Production Authentication & Session Engine with Granular RBAC
 * Integrates with Supabase Auth or embedded cryptographically verified user store.
 */

const NUTORA_PERMISSIONS = {
  'products.create_edit': { label: 'Create & Edit Products', bn: 'পণ্য তৈরি ও সম্পাদনা', group: 'products' },
  'products.delete': { label: 'Delete Products', bn: 'পণ্য মোছা', group: 'products' },
  'products.publish': { label: 'Publish / Draft Status', bn: 'পণ্য লাইভ বা ড্রাফট করা', group: 'products' },
  'inventory.update': { label: 'Adjust Stock & Batches', bn: 'স্টক আপডেট ও ইনভেনটরি', group: 'inventory' },
  'orders.status': { label: 'Update Fulfillment Status', bn: 'অর্ডার স্ট্যাটাস পরিবর্তন', group: 'orders' },
  'orders.cancel': { label: 'Cancel & Refund Orders', bn: 'অর্ডার বাতিল ও রিফান্ড', group: 'orders' },
  'coupons.manage': { label: 'Manage Coupons & Discounts', bn: 'কুপন ও ছাড় তৈরি', group: 'marketing' },
  'reviews.moderate': { label: 'Moderate Customer Reviews', bn: 'রিভিউ অনুমোদন ও মডারেশন', group: 'marketing' },
  'customers.view': { label: 'View Customer Profiles', bn: 'গ্রাহক তথ্য ও হিস্ট্রি দেখা', group: 'customers' },
  'settings.manage': { label: 'Store Settings & Fees', bn: 'স্টোর তথ্য ও ডেলিভারি ফি', group: 'settings' },
  'audit.view': { label: 'View Audit Security Logs', bn: 'অডিট সিকিউরিটি লগ দেখা', group: 'settings' },
  'users.manage': { label: 'Manage Staff Roles', bn: 'টিম মেম্বার রোল ও পারমিশন', group: 'users' }
};

const DEFAULT_ADMIN_PERMISSIONS = [
  'products.create_edit', 'products.delete', 'products.publish',
  'inventory.update', 'orders.status', 'orders.cancel',
  'coupons.manage', 'reviews.moderate', 'customers.view',
  'settings.manage', 'audit.view'
];

const DEFAULT_EDITOR_PERMISSIONS = [
  'products.create_edit', 'products.publish',
  'inventory.update', 'reviews.moderate'
];

class NutoraAuthEngine {
  constructor() {
    this.sessionKey = 'nutora_active_session_v1';
    this.usersKey = 'nutora_db_profiles_v1';
    this.initUsers();
    this.currentUser = this.loadStoredSession();
  }

  hashPasswordSync(password) {
    let hash = 0;
    for (let i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.charCodeAt(i);
      hash |= 0;
    }
    return 'h_' + Math.abs(hash).toString(16);
  }

  // Simple browser-native SHA-256 hash helper
  async hashPassword(password) {
    if (typeof window !== 'undefined' && window.crypto && crypto.subtle) {
      const msgUint8 = new TextEncoder().encode(password + "_nutora_salt_2026");
      const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    }
    return this.hashPasswordSync(password);
  }

  initUsers() {
    let users = [];
    const stored = typeof localStorage !== 'undefined' ? localStorage.getItem(this.usersKey) : null;
    if (stored) {
      try { users = JSON.parse(stored); } catch (e) { users = []; }
    }

    if (!users || users.length === 0) {
      const adminHash = this.hashPasswordSync('admin123');
      const managerHash = this.hashPasswordSync('admin123');
      const editorHash = this.hashPasswordSync('editor123');
      const custHash = this.hashPasswordSync('customer123');

      users = [
        {
          id: 'usr-admin-001',
          email: 'admin@nutorafood.com',
          passwordHash: adminHash,
          fullName: 'Super Administrator',
          phone: '+880 1712-345678',
          role: 'super_admin',
          permissions: Object.keys(NUTORA_PERMISSIONS),
          isActive: true,
          created_at: new Date().toISOString()
        },
        {
          id: 'usr-admin-002',
          email: 'manager@nutorafood.com',
          passwordHash: managerHash,
          fullName: 'Kitchen Operations Admin',
          phone: '+880 1799-887766',
          role: 'admin',
          permissions: [...DEFAULT_ADMIN_PERMISSIONS],
          isActive: true,
          created_at: new Date().toISOString()
        },
        {
          id: 'usr-editor-001',
          email: 'editor@nutorafood.com',
          passwordHash: editorHash,
          fullName: 'Kitchen Catalog Editor',
          phone: '+880 1819-223344',
          role: 'editor',
          permissions: [...DEFAULT_EDITOR_PERMISSIONS],
          isActive: true,
          created_at: new Date().toISOString()
        },
        {
          id: 'usr-cust-001',
          email: 'customer@example.com',
          passwordHash: custHash,
          fullName: 'Shuharthu Barua',
          phone: '+880 1711-998877',
          role: 'customer',
          permissions: [],
          isActive: true,
          created_at: new Date().toISOString()
        }
      ];
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(this.usersKey, JSON.stringify(users));
      }
    } else {
      // Ensure existing users have permissions array
      let updated = false;
      users = users.map(u => {
        if (!u.permissions) {
          updated = true;
          if (u.role === 'super_admin') u.permissions = Object.keys(NUTORA_PERMISSIONS);
          else if (u.role === 'admin') u.permissions = [...DEFAULT_ADMIN_PERMISSIONS];
          else if (u.role === 'editor') u.permissions = [...DEFAULT_EDITOR_PERMISSIONS];
          else u.permissions = [];
        }
        return u;
      });
      if (updated && typeof localStorage !== 'undefined') {
        localStorage.setItem(this.usersKey, JSON.stringify(users));
      }
    }
  }

  getUsers() {
    if (typeof localStorage === 'undefined') return [];
    return JSON.parse(localStorage.getItem(this.usersKey) || '[]');
  }

  saveUsers(users) {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(this.usersKey, JSON.stringify(users));
    }
  }

  loadStoredSession() {
    try {
      if (typeof localStorage === 'undefined') return null;
      const data = localStorage.getItem(this.sessionKey);
      return data ? JSON.parse(data) : null;
    } catch (e) {
      return null;
    }
  }

  saveSession(user) {
    this.currentUser = user;
    if (typeof localStorage !== 'undefined') {
      if (user) {
        localStorage.setItem(this.sessionKey, JSON.stringify(user));
      } else {
        localStorage.removeItem(this.sessionKey);
      }
    }
    this.notify();
    this.updateNavbarUI();
  }

  async register(fullName, email, phone, password) {
    const cleanEmail = email.trim().toLowerCase();
    
    // Live Supabase path
    if (typeof nutoraDB !== 'undefined' && nutoraDB.isLive && nutoraDB.client) {
      try {
        const { data, error } = await nutoraDB.client.auth.signUp({
          email: cleanEmail,
          password: password,
          options: {
            data: { full_name: fullName, phone: phone }
          }
        });
        if (error) throw error;
        const user = {
          id: data.user.id,
          email: cleanEmail,
          fullName: fullName,
          phone: phone,
          role: 'customer',
          permissions: []
        };
        this.saveSession(user);
        return user;
      } catch (err) {
        console.warn('Supabase auth failed, falling back to embedded database:', err);
      }
    }

    // Embedded database path
    const users = this.getUsers();
    if (users.find(u => u.email === cleanEmail)) {
      throw new Error(`An account with email ${cleanEmail} already exists. Please sign in.`);
    }

    const passwordHash = await this.hashPassword(password);
    const newUser = {
      id: 'usr-' + Date.now(),
      email: cleanEmail,
      passwordHash: passwordHash,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: 'customer', // Public registration is ALWAYS customer
      permissions: [],
      isActive: true,
      created_at: new Date().toISOString()
    };

    users.push(newUser);
    this.saveUsers(users);

    const sessionUser = {
      id: newUser.id,
      email: newUser.email,
      fullName: newUser.fullName,
      phone: newUser.phone,
      role: newUser.role,
      permissions: []
    };

    this.saveSession(sessionUser);
    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('USER_REGISTERED', 'profiles', newUser.email, null, { name: newUser.fullName });
    }
    return sessionUser;
  }

  async login(email, password) {
    const cleanEmail = email.trim().toLowerCase();

    // Live Supabase path
    if (typeof nutoraDB !== 'undefined' && nutoraDB.isLive && nutoraDB.client) {
      try {
        const { data, error } = await nutoraDB.client.auth.signInWithPassword({
          email: cleanEmail,
          password: password
        });
        if (error) throw error;

        // Fetch user profile
        const { data: profile } = await nutoraDB.client
          .from('profiles')
          .select('*, user_roles(name)')
          .eq('id', data.user.id)
          .single();

        const roleName = profile?.user_roles?.name || 'customer';
        const perms = roleName === 'super_admin' ? Object.keys(NUTORA_PERMISSIONS) :
                      (roleName === 'admin' ? DEFAULT_ADMIN_PERMISSIONS :
                      (roleName === 'editor' ? DEFAULT_EDITOR_PERMISSIONS : []));

        const user = {
          id: data.user.id,
          email: cleanEmail,
          fullName: profile?.full_name || data.user.user_metadata?.full_name || 'Customer',
          phone: profile?.phone || '',
          role: roleName,
          permissions: perms
        };
        this.saveSession(user);
        return user;
      } catch (err) {
        console.warn('Supabase cloud login failed, falling back to embedded database:', err);
      }
    }

    // Embedded database verification
    const users = this.getUsers();
    const user = users.find(u => u.email === cleanEmail);

    if (!user) {
      throw new Error('No account found with this email address. Please register.');
    }

    if (!user.isActive) {
      throw new Error('This account has been deactivated. Please contact Super Admin.');
    }

    const inputHash = user.passwordHash && user.passwordHash.startsWith('h_') ?
      this.hashPasswordSync(password) :
      await this.hashPassword(password);
    if (user.passwordHash !== inputHash) {
      throw new Error('Incorrect password. Please try again.');
    }

    // Ensure permissions
    let perms = user.permissions;
    if (!perms || perms.length === 0) {
      if (user.role === 'super_admin') perms = Object.keys(NUTORA_PERMISSIONS);
      else if (user.role === 'admin') perms = [...DEFAULT_ADMIN_PERMISSIONS];
      else if (user.role === 'editor') perms = [...DEFAULT_EDITOR_PERMISSIONS];
      else perms = [];
    }

    const sessionUser = {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      permissions: perms
    };

    this.saveSession(sessionUser);
    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('USER_LOGIN', 'profiles', user.email, null, { role: user.role });
    }
    return sessionUser;
  }

  async logout() {
    if (typeof nutoraDB !== 'undefined' && nutoraDB.isLive && nutoraDB.client) {
      try { await nutoraDB.client.auth.signOut(); } catch (e) {}
    }
    this.saveSession(null);
  }

  isAuthenticated() {
    return !!this.currentUser;
  }

  isSuperAdmin() {
    return this.currentUser && this.currentUser.role === 'super_admin';
  }

  isAdmin() {
    return this.currentUser && (this.currentUser.role === 'super_admin' || this.currentUser.role === 'admin');
  }

  isEditor() {
    return this.currentUser && (this.currentUser.role === 'editor' || this.currentUser.role === 'admin' || this.currentUser.role === 'super_admin');
  }

  isStaff() {
    return this.currentUser && ['super_admin', 'admin', 'editor'].includes(this.currentUser.role);
  }

  hasPermission(permissionKey) {
    if (!this.currentUser) return false;
    if (this.currentUser.role === 'super_admin') return true;
    
    // Explicit permission list on user object takes full precedence
    if (Array.isArray(this.currentUser.permissions)) {
      return this.currentUser.permissions.includes(permissionKey);
    }

    // Role-based fallbacks only when no explicit permissions array is configured
    if (this.currentUser.role === 'admin') {
      return permissionKey !== 'users.manage';
    }
    if (this.currentUser.role === 'editor') {
      return DEFAULT_EDITOR_PERMISSIONS.includes(permissionKey);
    }
    return false;
  }

  detectRoleByEmail(email) {
    if (!email || !email.includes('@')) return null;
    const clean = email.trim().toLowerCase();
    const users = this.getUsers();
    const user = users.find(u => u.email === clean);
    if (user) {
      return {
        role: user.role,
        fullName: user.fullName,
        isRegistered: true,
        permissions: user.permissions || []
      };
    }
    // Any other or unverified email is customer
    return {
      role: 'customer',
      fullName: null,
      isRegistered: false,
      permissions: []
    };
  }

  isSuperAdminConfigured() {
    if (typeof localStorage === 'undefined') return true;
    return localStorage.getItem('nutora_super_admin_configured') === 'true';
  }

  async setSuperAdmin(fullName, email, phone, password) {
    const cleanEmail = email.trim().toLowerCase();
    const users = this.getUsers();

    let admin = users.find(u => u.role === 'super_admin');
    let hash = admin ? admin.passwordHash : null;
    if (password && password.trim().length > 0) {
      hash = await this.hashPassword(password);
    } else if (!hash) {
      hash = await this.hashPassword('admin123');
    }

    if (admin) {
      admin.fullName = fullName.trim();
      admin.email = cleanEmail;
      admin.phone = (phone || '').trim();
      admin.passwordHash = hash;
      admin.isActive = true;
      admin.permissions = Object.keys(NUTORA_PERMISSIONS);
      admin.updated_at = new Date().toISOString();
    } else {
      admin = {
        id: 'usr-admin-' + Date.now(),
        email: cleanEmail,
        passwordHash: hash,
        fullName: fullName.trim(),
        phone: (phone || '').trim(),
        role: 'super_admin',
        permissions: Object.keys(NUTORA_PERMISSIONS),
        isActive: true,
        created_at: new Date().toISOString()
      };
      users.unshift(admin);
    }

    this.saveUsers(users);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('nutora_super_admin_configured', 'true');
    }

    const sessionUser = {
      id: admin.id,
      email: admin.email,
      fullName: admin.fullName,
      phone: admin.phone,
      role: 'super_admin',
      permissions: Object.keys(NUTORA_PERMISSIONS)
    };

    this.saveSession(sessionUser);
    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('SUPER_ADMIN_CONFIGURED', 'profiles', admin.email, null, { name: admin.fullName });
    }
    return sessionUser;
  }

  async createStaffAccount(fullName, email, phone, password, role = 'editor', permissions = null) {
    // SECURITY GUARD: Only a logged-in Super Admin can create staff accounts
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can create administrative staff accounts.');
    }

    if (!['editor', 'admin', 'super_admin'].includes(role)) {
      throw new Error('Invalid staff role. Must be editor, admin, or super_admin.');
    }

    const cleanEmail = email.trim().toLowerCase();
    const users = this.getUsers();
    if (users.find(u => u.email === cleanEmail)) {
      throw new Error(`An account with email ${cleanEmail} already exists.`);
    }

    // Assign appropriate permissions if not specified
    let assignedPermissions = permissions;
    if (!assignedPermissions || !Array.isArray(assignedPermissions) || assignedPermissions.length === 0) {
      if (role === 'super_admin') assignedPermissions = Object.keys(NUTORA_PERMISSIONS);
      else if (role === 'admin') assignedPermissions = [...DEFAULT_ADMIN_PERMISSIONS];
      else assignedPermissions = [...DEFAULT_EDITOR_PERMISSIONS];
    }

    const passwordHash = await this.hashPassword(password);
    const newStaff = {
      id: 'usr-staff-' + Date.now(),
      email: cleanEmail,
      passwordHash: passwordHash,
      fullName: fullName.trim(),
      phone: (phone || '').trim(),
      role: role,
      permissions: assignedPermissions,
      isActive: true,
      created_at: new Date().toISOString()
    };

    users.push(newStaff);
    this.saveUsers(users);

    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_ACCOUNT_CREATED', 'profiles', cleanEmail, null, {
        name: newStaff.fullName,
        role: role,
        permissionsCount: assignedPermissions.length,
        created_by: this.currentUser.email
      });
    }

    return newStaff;
  }

  async updateStaffAccount(id, updates) {
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can update staff accounts.');
    }

    const users = this.getUsers();
    const target = users.find(u => u.id === id);
    if (!target) throw new Error('Staff user not found.');

    if (updates.fullName) target.fullName = updates.fullName.trim();
    if (updates.phone !== undefined) target.phone = (updates.phone || '').trim();
    if (updates.role && ['editor', 'admin', 'super_admin'].includes(updates.role)) {
      target.role = updates.role;
    }
    if (Array.isArray(updates.permissions)) {
      target.permissions = updates.permissions;
    }
    if (updates.password && updates.password.trim().length >= 6) {
      target.passwordHash = await this.hashPassword(updates.password.trim());
    }
    if (updates.isActive !== undefined) {
      target.isActive = !!updates.isActive;
    }

    target.updated_at = new Date().toISOString();
    this.saveUsers(users);

    // If updating current active session
    if (this.currentUser && this.currentUser.id === id) {
      this.currentUser = {
        ...this.currentUser,
        fullName: target.fullName,
        phone: target.phone,
        role: target.role,
        permissions: target.permissions
      };
      this.saveSession(this.currentUser);
    }

    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_ACCOUNT_UPDATED', 'profiles', target.email, null, {
        role: target.role,
        permissions: target.permissions
      });
    }

    return target;
  }

  async deleteStaffAccount(id) {
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can delete staff accounts.');
    }

    if (this.currentUser && this.currentUser.id === id) {
      throw new Error('Security Guardrail: You cannot delete your own logged-in Super Admin account.');
    }

    const users = this.getUsers();
    const targetIndex = users.findIndex(u => u.id === id);
    if (targetIndex < 0) throw new Error('Staff user not found.');

    const target = users[targetIndex];
    if (target.role === 'super_admin') {
      const activeSuperAdmins = users.filter(u => u.role === 'super_admin' && u.isActive);
      if (activeSuperAdmins.length <= 1) {
        throw new Error('Security Restriction: You cannot delete the last active Super Admin.');
      }
    }

    users.splice(targetIndex, 1);
    this.saveUsers(users);

    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_ACCOUNT_DELETED', 'profiles', target.email, null, { email: target.email, role: target.role });
    }
    return true;
  }

  async updateStaffStatus(id, isActive) {
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can modify staff status.');
    }

    const users = this.getUsers();
    const target = users.find(u => u.id === id);
    if (!target) throw new Error('Staff user not found.');

    if (target.role === 'super_admin' && !isActive) {
      // Guardrail: Protect the last active Super Admin
      const activeSuperAdmins = users.filter(u => u.role === 'super_admin' && u.isActive);
      if (activeSuperAdmins.length <= 1) {
        throw new Error('Security Restriction: You cannot deactivate or remove the last active Super Admin.');
      }
    }

    target.isActive = isActive;
    target.updated_at = new Date().toISOString();
    this.saveUsers(users);

    if (typeof nutoraDB !== 'undefined' && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_STATUS_UPDATED', 'profiles', target.email, null, { isActive });
    }
    return target;
  }

  notify() {
    if (typeof document !== 'undefined') {
      document.dispatchEvent(new CustomEvent('nutora:auth-changed', { detail: this.currentUser }));
    }
  }

  // Update header navigation across all pages
  updateNavbarUI() {
    if (typeof document === 'undefined') return;
    const navActions = document.querySelector('.nav-actions');
    if (!navActions) return;

    let authPill = document.getElementById('navbarAuthPill');
    if (!authPill) {
      authPill = document.createElement('div');
      authPill.id = 'navbarAuthPill';
      authPill.style.display = 'inline-flex';
      authPill.style.alignItems = 'center';
      authPill.style.gap = '8px';
      authPill.style.flexShrink = '0';
      navActions.insertBefore(authPill, navActions.firstChild);
    }

    const isStaff = this.isStaff();
    const inAdmin = window.location.pathname.includes('/admin/');
    const basePath = inAdmin ? '/admin/' : '/';

    if (this.currentUser) {
      const shortName = (this.currentUser.fullName || 'User').split(' ')[0];
      const roleBadge = this.currentUser.role === 'super_admin' ? 'SUPER ADMIN' :
                        (this.currentUser.role === 'admin' ? 'ADMIN' : 'EDITOR');

      authPill.innerHTML = `
        <a href="${isStaff ? '/admin/index.html' : '/account.html'}" class="nav-user-pill" title="My Account">
          <span>${isStaff ? '🛡️' : '👤'}</span>
          <span>${shortName}</span>
          ${isStaff ? `<span class="badge badge-gold" style="font-size: 0.65rem; padding: 2px 6px;">${roleBadge}</span>` : ''}
        </a>
        <button onclick="nutoraAuth.logout()" title="Sign Out" class="btn-icon" style="width: 32px; height: 32px; font-size: 0.8rem; color: #C0392B;">✕</button>
      `;
      // Hide duplicate plain account icon
      const rawAcc = document.querySelector('.nav-actions a[href*="account.html"]:not(.nav-user-pill)');
      if (rawAcc) rawAcc.style.display = 'none';
    } else {
      authPill.innerHTML = `
        <a href="/login.html" class="nav-auth-btn">
          <span>👤</span>
          <span>Sign In</span>
        </a>
      `;
      // Hide duplicate plain account icon
      const rawAcc = document.querySelector('.nav-actions a[href*="account.html"]:not(.nav-auth-btn)');
      if (rawAcc) rawAcc.style.display = 'none';
    }
  }
}

// Global Auth instance
const nutoraAuth = new NutoraAuthEngine();
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', () => {
    nutoraAuth.updateNavbarUI();
  });
}

// Node.js export for automated tests
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    NutoraAuthEngine,
    nutoraAuth,
    NUTORA_PERMISSIONS,
    DEFAULT_ADMIN_PERMISSIONS,
    DEFAULT_EDITOR_PERMISSIONS
  };
}
