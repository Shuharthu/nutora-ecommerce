/**
 * NUTORA — Production Authentication & Session Engine
 * Integrates with Supabase Auth or embedded cryptographically verified user store.
 */

class NutoraAuthEngine {
  constructor() {
    this.sessionKey = 'nutora_active_session_v1';
    this.usersKey = 'nutora_db_profiles_v1';
    this.initUsers();
    this.currentUser = this.loadStoredSession();
  }

  // Simple browser-native SHA-256 hash helper
  async hashPassword(password) {
    if (window.crypto && crypto.subtle) {
      const msgUint8 = new TextEncoder().encode(password + "_nutora_salt_2026");
      const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    }
    // Fallback simple hash for older runtimes
    let hash = 0;
    for (let i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.charCodeAt(i);
      hash |= 0;
    }
    return 'h_' + Math.abs(hash).toString(16);
  }

  async initUsers() {
    if (!localStorage.getItem(this.usersKey)) {
      const adminHash = await this.hashPassword('admin123');
      const editorHash = await this.hashPassword('editor123');
      const custHash = await this.hashPassword('customer123');

      const initialUsers = [
        {
          id: 'usr-admin-001',
          email: 'admin@nutorafood.com',
          passwordHash: adminHash,
          fullName: 'Super Administrator',
          phone: '+880 1712-345678',
          role: 'super_admin',
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
          isActive: true,
          created_at: new Date().toISOString()
        }
      ];
      localStorage.setItem(this.usersKey, JSON.stringify(initialUsers));
    }
  }

  getUsers() {
    return JSON.parse(localStorage.getItem(this.usersKey) || '[]');
  }

  saveUsers(users) {
    localStorage.setItem(this.usersKey, JSON.stringify(users));
  }

  loadStoredSession() {
    try {
      const data = localStorage.getItem(this.sessionKey);
      return data ? JSON.parse(data) : null;
    } catch (e) {
      return null;
    }
  }

  saveSession(user) {
    this.currentUser = user;
    if (user) {
      localStorage.setItem(this.sessionKey, JSON.stringify(user));
    } else {
      localStorage.removeItem(this.sessionKey);
    }
    this.notify();
    this.updateNavbarUI();
  }

  async register(fullName, email, phone, password) {
    const cleanEmail = email.trim().toLowerCase();
    
    // Live Supabase path
    if (nutoraDB.isLive && nutoraDB.client) {
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
          role: 'customer'
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
      role: newUser.role
    };

    this.saveSession(sessionUser);
    nutoraDB.recordAudit('USER_REGISTERED', 'profiles', newUser.email, null, { name: newUser.fullName });
    return sessionUser;
  }

  async login(email, password) {
    const cleanEmail = email.trim().toLowerCase();

    // Live Supabase path
    if (nutoraDB.isLive && nutoraDB.client) {
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
        const user = {
          id: data.user.id,
          email: cleanEmail,
          fullName: profile?.full_name || data.user.user_metadata?.full_name || 'Customer',
          phone: profile?.phone || '',
          role: roleName
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
      throw new Error('This account has been deactivated. Please contact support.');
    }

    const inputHash = await this.hashPassword(password);
    if (user.passwordHash !== inputHash) {
      throw new Error('Incorrect password. Please try again.');
    }

    const sessionUser = {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role
    };

    this.saveSession(sessionUser);
    nutoraDB.recordAudit('USER_LOGIN', 'profiles', user.email, null, { role: user.role });
    return sessionUser;
  }

  async logout() {
    if (nutoraDB.isLive && nutoraDB.client) {
      try { await nutoraDB.client.auth.signOut(); } catch (e) {}
    }
    this.saveSession(null);
  }

  isAuthenticated() {
    return !!this.currentUser;
  }

  isAdmin() {
    return this.currentUser && this.currentUser.role === 'super_admin';
  }

  isEditor() {
    return this.currentUser && (this.currentUser.role === 'editor' || this.currentUser.role === 'super_admin');
  }

  isSuperAdminConfigured() {
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
      admin.updated_at = new Date().toISOString();
    } else {
      admin = {
        id: 'usr-admin-' + Date.now(),
        email: cleanEmail,
        passwordHash: hash,
        fullName: fullName.trim(),
        phone: (phone || '').trim(),
        role: 'super_admin',
        isActive: true,
        created_at: new Date().toISOString()
      };
      users.unshift(admin);
    }

    this.saveUsers(users);
    localStorage.setItem('nutora_super_admin_configured', 'true');

    const sessionUser = {
      id: admin.id,
      email: admin.email,
      fullName: admin.fullName,
      phone: admin.phone,
      role: 'super_admin'
    };

    this.saveSession(sessionUser);
    if (window.nutoraDB && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('SUPER_ADMIN_CONFIGURED', 'profiles', admin.email, null, { name: admin.fullName });
    }
    return sessionUser;
  }

  async createStaffAccount(fullName, email, phone, password, role = 'editor') {
    // SECURITY GUARD: Only a logged-in Super Admin can create staff accounts
    if (!this.currentUser || this.currentUser.role !== 'super_admin') {
      throw new Error('Access Denied: Only Super Admin can create administrative staff accounts.');
    }

    if (role !== 'editor' && role !== 'super_admin') {
      throw new Error('Invalid staff role. Must be editor or super_admin.');
    }

    const cleanEmail = email.trim().toLowerCase();
    const users = this.getUsers();
    if (users.find(u => u.email === cleanEmail)) {
      throw new Error(`An account with email ${cleanEmail} already exists.`);
    }

    const passwordHash = await this.hashPassword(password);
    const newStaff = {
      id: 'usr-staff-' + Date.now(),
      email: cleanEmail,
      passwordHash: passwordHash,
      fullName: fullName.trim(),
      phone: (phone || '').trim(),
      role: role,
      isActive: true,
      created_at: new Date().toISOString()
    };

    users.push(newStaff);
    this.saveUsers(users);

    if (window.nutoraDB && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_ACCOUNT_CREATED', 'profiles', cleanEmail, null, {
        name: newStaff.fullName,
        role: role,
        created_by: this.currentUser.email
      });
    }

    return newStaff;
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

    if (window.nutoraDB && nutoraDB.recordAudit) {
      nutoraDB.recordAudit('STAFF_STATUS_UPDATED', 'profiles', target.email, null, { isActive });
    }
    return target;
  }

  notify() {
    document.dispatchEvent(new CustomEvent('nutora:auth-changed', { detail: this.currentUser }));
  }

  // Update header navigation across all pages
  updateNavbarUI() {
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

    const isStaff = this.currentUser && (this.currentUser.role === 'super_admin' || this.currentUser.role === 'editor');
    const inAdmin = window.location.pathname.includes('/admin/');
    const basePath = inAdmin ? '../' : '';

    if (this.currentUser) {
      const shortName = (this.currentUser.fullName || 'User').split(' ')[0];
      authPill.innerHTML = `
        <a href="${isStaff ? basePath + 'admin/index.html' : basePath + 'account.html'}" class="nav-user-pill" title="My Account">
          <span>${isStaff ? '🛡️' : '👤'}</span>
          <span>${shortName}</span>
          ${isStaff ? `<span class="badge badge-gold" style="font-size: 0.65rem; padding: 2px 6px;">ADMIN</span>` : ''}
        </a>
        <button onclick="nutoraAuth.logout()" title="Sign Out" class="btn-icon" style="width: 32px; height: 32px; font-size: 0.8rem; color: #C0392B;">✕</button>
      `;
      // Hide duplicate plain account icon
      const rawAcc = document.querySelector('.nav-actions a[href*="account.html"]:not(.nav-user-pill)');
      if (rawAcc) rawAcc.style.display = 'none';
    } else {
      authPill.innerHTML = `
        <a href="${basePath}login.html" class="nav-auth-btn">
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
document.addEventListener('DOMContentLoaded', () => {
  nutoraAuth.updateNavbarUI();
});
