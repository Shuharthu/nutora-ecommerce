/**
 * NUTORA — Database & Auth Configuration Engine
 * Configurable within the Admin Panel
 */

function initDatabaseModal() {
  // Do NOT inject modal into public storefront pages
  if (!window.location.pathname.includes('/admin/')) {
    return;
  }

  if (document.getElementById('dbConfigModal')) return;

  const modalHtml = `
    <div id="dbConfigModal" style="display: none; position: fixed; inset: 0; background: rgba(16, 53, 35, 0.7); backdrop-filter: blur(4px); z-index: 99999; align-items: center; justify-content: center; padding: 20px;">
      <div style="background: white; border-radius: 18px; max-width: 600px; width: 100%; box-shadow: 0 16px 40px rgba(0,0,0,0.3); border: 1px solid var(--color-light-border); overflow: hidden;">
        <div style="background: var(--color-deep-green); color: white; padding: 20px 24px; display: flex; align-items: center; justify-content: space-between;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 1.4rem;">🗄️</span>
            <div>
              <h3 style="color: #FFF9EB; font-size: 1.15rem; margin: 0;">Supabase Database & Authentication Engine</h3>
              <span style="font-size: 0.78rem; color: var(--color-warm-gold);">PostgreSQL Cloud Synchronization</span>
            </div>
          </div>
          <button onclick="closeDbModal()" style="font-size: 1.5rem; color: #FFF9EB; background: none; border: none; cursor: pointer;">&times;</button>
        </div>

        <div style="padding: 24px;">
          <div id="dbStatusBanner" style="padding: 14px 18px; border-radius: 8px; margin-bottom: 20px; display: flex; align-items: center; justify-content: space-between; background: #E8F5E9; border: 1px solid #C8E6C9;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <span id="dbStatusDot" style="width: 12px; height: 12px; border-radius: 50%; background: #2E7D32; display: inline-block;"></span>
              <div>
                <strong id="dbStatusTitle" style="color: #1B5E20; font-size: 0.95rem;">Database Active: Embedded Store</strong>
                <div id="dbStatusSub" style="font-size: 0.8rem; color: #2E7D32;">All 20 tables & Auth active with persistent local storage</div>
              </div>
            </div>
            <span id="dbModeBadge" class="badge badge-green" style="font-size: 0.72rem;">READY</span>
          </div>

          <h4 style="color: var(--color-deep-green); font-size: 1rem; margin-bottom: 10px;">Connect to Your Supabase Cloud Project</h4>
          <p style="font-size: 0.84rem; color: var(--color-muted-text); margin-bottom: 16px;">
            Enter your credentials from Supabase Dashboard > Project Settings > API:
          </p>

          <div style="margin-bottom: 12px;">
            <label style="display: block; font-size: 0.82rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">Supabase Project URL</label>
            <input type="url" id="inputSupabaseUrl" class="newsletter-input" style="width: 100%; border-radius: 6px; font-size: 0.88rem;" placeholder="https://your-project.supabase.co">
          </div>

          <div style="margin-bottom: 16px;">
            <label style="display: block; font-size: 0.82rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">Supabase Public Anon Key</label>
            <input type="text" id="inputSupabaseKey" class="newsletter-input" style="width: 100%; border-radius: 6px; font-size: 0.88rem;" placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...">
          </div>

          <div style="display: flex; gap: 10px; margin-bottom: 24px;">
            <button onclick="saveSupabaseCredentials()" class="btn btn-primary btn-sm" style="flex-grow: 1;">Connect & Sync Supabase</button>
            <button onclick="clearSupabaseCredentials()" class="btn btn-secondary btn-sm">Use Local DB</button>
          </div>
        </div>

        <div style="padding: 16px 24px; border-top: 1px solid var(--color-light-border); background: #FAF8F2; display: flex; justify-content: flex-end;">
          <button onclick="closeDbModal()" class="btn btn-primary btn-sm">Close</button>
        </div>
      </div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', modalHtml);
}

function openDbModal() {
  const modal = document.getElementById('dbConfigModal');
  if (!modal) return;
  modal.style.display = 'flex';

  const urlInput = document.getElementById('inputSupabaseUrl');
  const keyInput = document.getElementById('inputSupabaseKey');
  if (urlInput) urlInput.value = nutoraDB.supabaseUrl || '';
  if (keyInput) keyInput.value = nutoraDB.supabaseKey || '';
}

function closeDbModal() {
  const modal = document.getElementById('dbConfigModal');
  if (modal) modal.style.display = 'none';
}

async function saveSupabaseCredentials() {
  const url = document.getElementById('inputSupabaseUrl').value.trim();
  const key = document.getElementById('inputSupabaseKey').value.trim();

  if (!url || !key) {
    alert('Please enter both Supabase Project URL and Anon Public Key.');
    return;
  }

  const res = await nutoraDB.saveConfig(url, key);
  alert(res.mode === 'cloud' ? '✓ Connected to Supabase Cloud!' : 'Credentials saved.');
  closeDbModal();
}

function clearSupabaseCredentials() {
  nutoraDB.saveConfig('', '');
  alert('Switched back to embedded local database engine.');
  closeDbModal();
}

document.addEventListener('DOMContentLoaded', initDatabaseModal);
