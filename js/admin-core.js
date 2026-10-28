/**
 * NUTORA — Unified Administrative Core Engine
 * Enforces Role-Based Access Control (RBAC), Mobile Sidebar,
 * and Super Admin Credentials Management across all /admin/ pages.
 */

class NutoraAdminCore {
  constructor() {
    this.init();
  }

  init() {
    // 1. Enforce RBAC security
    if (!this.enforceSecurity()) return;

    // 2. Setup UI elements once DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.setupAdminUI());
    } else {
      this.setupAdminUI();
    }
  }

  enforceSecurity() {
    const user = nutoraAuth.currentUser;
    const isSetup = nutoraAuth.isSuperAdminConfigured();

    // Not logged in or not staff
    if (!user || (user.role !== 'super_admin' && user.role !== 'editor')) {
      if (!isSetup) {
        window.location.href = 'setup.html';
        return false;
      }
      window.location.href = 'login.html';
      return false;
    }

    // Role-specific route protection: Only Super Admin can access users.html
    const isUsersPage = window.location.pathname.includes('users.html');
    if (isUsersPage && user.role !== 'super_admin') {
      alert('Access Denied: Only Super Admin has authority to manage staff roles.');
      window.location.href = 'index.html';
      return false;
    }

    return true;
  }

  setupAdminUI() {
    this.updateSidebarUserPill();
    this.injectMobileSidebar();
    this.injectSuperAdminModal();
    this.enhanceTopbar();
  }

  updateSidebarUserPill() {
    const user = nutoraAuth.currentUser;
    if (!user) return;

    const userPill = document.querySelector('.admin-user-pill');
    if (userPill) {
      const isSuper = user.role === 'super_admin';
      userPill.innerHTML = `
        <div style="flex-grow: 1; min-width: 0; padding-right: 8px;">
          <div style="font-size: 0.85rem; font-weight: 700; color: #FFF9EB; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            ${user.fullName || 'Admin User'}
          </div>
          <div style="font-size: 0.74rem; color: #B2ACA0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            ${user.email}
          </div>
          <div style="display: flex; gap: 6px; align-items: center; margin-top: 6px;">
            <span class="badge ${isSuper ? 'badge-gold' : 'badge-green'}" style="font-size: 0.65rem; padding: 2px 8px;">
              ${user.role.toUpperCase()}
            </span>
            ${isSuper ? `
              <button onclick="window.nutoraAdmin.openSuperAdminModal()" title="Customize Super Admin Credentials" style="background: none; border: none; color: var(--color-warm-gold); font-size: 0.85rem; cursor: pointer; padding: 0 4px;">
                ⚙️ Edit
              </button>
            ` : ''}
          </div>
        </div>
        <a href="../index.html" title="View Storefront" style="color: var(--color-warm-gold); font-size: 1.25rem; flex-shrink: 0; text-decoration: none;">🌐</a>
      `;
    }

    // Hide User Roles link in sidebar if logged in as Editor
    if (user.role === 'editor') {
      const usersNav = document.querySelector('.admin-nav a[href*="users.html"]');
      if (usersNav) {
        usersNav.style.display = 'none';
      }
    }
  }

  injectMobileSidebar() {
    const topbar = document.querySelector('.admin-topbar');
    const sidebar = document.querySelector('.admin-sidebar');
    if (!topbar || !sidebar) return;

    // Mobile Hamburger Button
    if (!document.getElementById('adminMobileToggle')) {
      const toggleBtn = document.createElement('button');
      toggleBtn.id = 'adminMobileToggle';
      toggleBtn.className = 'admin-mobile-toggle';
      toggleBtn.setAttribute('aria-label', 'Toggle navigation menu');
      toggleBtn.innerHTML = '☰';
      toggleBtn.onclick = () => this.toggleMobileSidebar();
      topbar.insertBefore(toggleBtn, topbar.firstChild);
    }

    // Mobile Backdrop
    if (!document.getElementById('adminSidebarBackdrop')) {
      const backdrop = document.createElement('div');
      backdrop.id = 'adminSidebarBackdrop';
      backdrop.className = 'admin-sidebar-backdrop';
      backdrop.onclick = () => this.closeMobileSidebar();
      document.body.appendChild(backdrop);
    }
  }

  toggleMobileSidebar() {
    const sidebar = document.querySelector('.admin-sidebar');
    const backdrop = document.getElementById('adminSidebarBackdrop');
    if (sidebar && backdrop) {
      const isOpen = sidebar.classList.toggle('mobile-open');
      backdrop.classList.toggle('active', isOpen);
    }
  }

  closeMobileSidebar() {
    const sidebar = document.querySelector('.admin-sidebar');
    const backdrop = document.getElementById('adminSidebarBackdrop');
    if (sidebar) sidebar.classList.remove('mobile-open');
    if (backdrop) backdrop.classList.remove('active');
  }

  enhanceTopbar() {
    const topbar = document.querySelector('.admin-topbar');
    if (!topbar) return;

    // Check if right actions wrapper exists
    let actions = topbar.querySelector('.admin-topbar-actions');
    if (!actions) {
      const existingDiv = topbar.querySelector('div:last-child');
      if (existingDiv && existingDiv !== topbar.firstElementChild) {
        actions = existingDiv;
        actions.className = 'admin-topbar-actions';
      }
    }

    const user = nutoraAuth.currentUser;
    const isSuper = user && user.role === 'super_admin';

    if (actions) {
      actions.style.display = 'flex';
      actions.style.gap = '10px';
      actions.style.alignItems = 'center';
      actions.style.flexWrap = 'wrap';

      // Ensure Profile button and Sign Out exist
      actions.innerHTML = `
        ${isSuper ? `
          <button onclick="window.nutoraAdmin.openSuperAdminModal()" class="btn btn-gold btn-sm" style="display: inline-flex; align-items: center; gap: 6px;">
            <span>👑</span>
            <span>Super Admin Settings</span>
          </button>
        ` : ''}
        <a href="../shop.html" target="_blank" class="btn btn-secondary btn-sm">Storefront ↗</a>
        <button onclick="window.nutoraAdmin.logout()" class="btn btn-outline btn-sm">Sign Out</button>
      `;
    }
  }

  injectSuperAdminModal() {
    if (document.getElementById('superAdminModal')) return;

    const modal = document.createElement('div');
    modal.id = 'superAdminModal';
    modal.className = 'admin-modal-overlay';
    modal.innerHTML = `
      <div class="admin-modal" style="max-width: 500px;">
        <div class="admin-modal-header" style="background: var(--color-deep-green); color: white; border-radius: var(--radius-lg) var(--radius-lg) 0 0;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 1.4rem;">👑</span>
            <div>
              <h3 style="color: #FFF9EB; font-size: 1.15rem; margin: 0;">Super Admin Credentials</h3>
              <span style="font-size: 0.76rem; color: var(--color-warm-gold);">মাস্টার অ্যাডমিন প্রোফাইল কনফিগারেশন</span>
            </div>
          </div>
          <button onclick="window.nutoraAdmin.closeSuperAdminModal()" style="font-size: 1.5rem; color: #FFF9EB; background: none; border: none; cursor: pointer;">&times;</button>
        </div>

        <form onsubmit="window.nutoraAdmin.handleSaveSuperAdmin(event)">
          <div class="admin-modal-body">
            <div id="superAdminModalAlert" style="display: none; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; font-size: 0.85rem;"></div>

            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 0.84rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">Full Name (নাম) *</label>
              <input type="text" id="samName" required class="newsletter-input" style="width: 100%; border-radius: 6px;" placeholder="e.g. Shuharthu Tapash Barua">
            </div>

            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 0.84rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">Master Admin Email (ইমেইল) *</label>
              <input type="email" id="samEmail" required class="newsletter-input" style="width: 100%; border-radius: 6px;" placeholder="e.g. admin@nutorafood.com">
            </div>

            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 0.84rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">Phone Number (ফোন)</label>
              <input type="tel" id="samPhone" class="newsletter-input" style="width: 100%; border-radius: 6px;" placeholder="e.g. 01712345678">
            </div>

            <div style="margin-bottom: 16px;">
              <label style="display: block; font-size: 0.84rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">
                New Master Password (নতুন পাসওয়ার্ড — পরিবর্তন না করতে চাইলে খালি রাখুন)
              </label>
              <input type="password" id="samPassword" minlength="8" class="newsletter-input" style="width: 100%; border-radius: 6px;" placeholder="••••••••">
            </div>

            <p style="font-size: 0.78rem; color: var(--color-muted-text); margin: 0; line-height: 1.4;">
              🛡️ সংরক্ষিত তথ্য: এই পাসওয়ার্ড দিয়ে কেবলমাত্র আপনি সুপার অ্যাডমিন হিসেবে প্রবেশ করতে পারবেন।
            </p>
          </div>

          <div class="admin-modal-footer">
            <button type="button" onclick="window.nutoraAdmin.closeSuperAdminModal()" class="btn btn-secondary btn-sm">Cancel</button>
            <button type="submit" id="btnSaveSuperAdmin" class="btn btn-primary btn-sm">Save Super Admin</button>
          </div>
        </form>
      </div>
    `;
    document.body.appendChild(modal);
  }

  openSuperAdminModal() {
    const user = nutoraAuth.currentUser;
    if (!user) return;

    document.getElementById('samName').value = user.fullName || '';
    document.getElementById('samEmail').value = user.email || '';
    document.getElementById('samPhone').value = user.phone || '';
    document.getElementById('samPassword').value = '';

    const alertBox = document.getElementById('superAdminModalAlert');
    if (alertBox) alertBox.style.display = 'none';

    document.getElementById('superAdminModal').classList.add('active');
  }

  closeSuperAdminModal() {
    const modal = document.getElementById('superAdminModal');
    if (modal) modal.classList.remove('active');
  }

  async handleSaveSuperAdmin(e) {
    e.preventDefault();
    const btn = document.getElementById('btnSaveSuperAdmin');
    const alertBox = document.getElementById('superAdminModalAlert');

    const name = document.getElementById('samName').value.trim();
    const email = document.getElementById('samEmail').value.trim();
    const phone = document.getElementById('samPhone').value.trim();
    const password = document.getElementById('samPassword').value;

    try {
      btn.disabled = true;
      btn.textContent = 'Updating...';

      await nutoraAuth.setSuperAdmin(name, email, phone, password);

      alertBox.style.display = 'block';
      alertBox.style.background = '#E8F5E9';
      alertBox.style.color = '#2E7D32';
      alertBox.style.border = '1px solid #C8E6C9';
      alertBox.textContent = '✓ Super Admin credentials updated successfully!';

      this.updateSidebarUserPill();

      setTimeout(() => {
        this.closeSuperAdminModal();
        btn.disabled = false;
        btn.textContent = 'Save Super Admin';
      }, 1000);
    } catch (err) {
      alertBox.style.display = 'block';
      alertBox.style.background = '#FFEBEE';
      alertBox.style.color = '#C62828';
      alertBox.style.border = '1px solid #FFCDD2';
      alertBox.textContent = err.message || 'Update failed.';
      btn.disabled = false;
      btn.textContent = 'Save Super Admin';
    }
  }

  async logout() {
    await nutoraAuth.logout();
    window.location.href = 'login.html';
  }
}

// Global instance
window.nutoraAdmin = new NutoraAdminCore();
