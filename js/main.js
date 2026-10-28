/**
 * NUTORA — Main Storefront Application Logic
 * Pure Vanilla JavaScript
 */

// Initial Seed Data for Prototype View (connected to Supabase in Phase 3/4)
const DEMO_PRODUCTS = [
  {
    id: 'prod-001',
    name: 'Classic Homemade Peanut Butter',
    category: 'Homemade Peanut Butter',
    categorySlug: 'peanut-butter',
    price: 520,
    originalPrice: 580,
    weight: '400g Jar',
    rating: 5.0,
    reviewCount: 38,
    image: 'assets/images/products/peanut-butter-classic.jpg',
    badge: 'HOMEMADE',
    inStock: true,
    tag: 'bestseller',
    description: 'Slow-roasted premium peanuts, Sundarban wild honey, and natural Himalayan pink salt.'
  },
  {
    id: 'prod-002',
    name: 'Sundarban Wildflower Raw Honey',
    category: 'Organic Honey',
    categorySlug: 'honey',
    price: 780,
    originalPrice: 850,
    weight: '500g Glass Jar',
    rating: 4.9,
    reviewCount: 42,
    image: 'assets/images/products/sundarban-raw-honey.jpg',
    badge: 'RAW & UNFILTERED',
    inStock: true,
    tag: 'bestseller',
    description: '100% natural raw mangrove forest honey with rich floral notes.'
  },
  {
    id: 'prod-003',
    name: 'Pure Bilona Danedar Cow Ghee',
    category: 'Pure Ghee',
    categorySlug: 'ghee',
    price: 980,
    originalPrice: 1100,
    weight: '450g Glass Jar',
    rating: 5.0,
    reviewCount: 29,
    image: 'assets/images/products/bilona-cow-ghee.jpg',
    badge: 'TRADITIONAL BILONA',
    inStock: true,
    tag: 'ghee',
    description: 'Crafted from cultured curd, slow-simmered for authentic golden grains and nutty aroma.'
  },
  {
    id: 'prod-004',
    name: 'Traditional Bogra Mishti Doi',
    category: 'Mishti Doi',
    categorySlug: 'mishti-doi',
    price: 320,
    originalPrice: null,
    weight: '500g Earthen Pot',
    rating: 4.9,
    reviewCount: 51,
    image: 'assets/images/products/mishti-doi.jpg',
    badge: 'AUTHENTIC CLAY POT',
    inStock: true,
    tag: 'fresh',
    description: 'Thick, creamy caramelized curd prepared in porous clay pots for natural sweetness.'
  },
  {
    id: 'prod-005',
    name: 'Kachi Ghani Cold-Pressed Mustard Oil',
    category: 'Natural Pantry',
    categorySlug: 'pantry',
    price: 420,
    originalPrice: null,
    weight: '1 Litre Glass Bottle',
    rating: 4.8,
    reviewCount: 19,
    image: 'assets/images/products/mustard-oil.jpg',
    badge: 'COLD PRESSED',
    inStock: true,
    tag: 'pantry',
    description: 'First press of finest black mustard seeds with traditional sharp pungency.'
  },
  {
    id: 'prod-006',
    name: 'Tok-Jhal-Misti Homemade Mango Pickle',
    category: 'Traditional Homemade Foods',
    categorySlug: 'homemade',
    price: 360,
    originalPrice: 400,
    weight: '400g Glass Jar',
    rating: 5.0,
    reviewCount: 34,
    image: 'assets/images/products/mango-achar.jpg',
    badge: 'MOM\'S RECIPE',
    inStock: true,
    tag: 'homemade',
    description: 'Sun-cured tender green mango slices seasoned with roasted panch phoron spices.'
  },
  {
    id: 'prod-007',
    name: 'Pure Himalayan Pink Rock Salt',
    category: 'Natural Pantry',
    categorySlug: 'pantry',
    price: 180,
    originalPrice: null,
    weight: '500g Pack',
    rating: 4.8,
    reviewCount: 15,
    image: 'assets/images/products/himalayan-pink-salt.jpg',
    badge: 'UNREFINED',
    inStock: true,
    tag: 'pantry',
    description: 'Natural mineral-rich unrefined pink crystals ground for daily healthy cooking.'
  },
  {
    id: 'prod-008',
    name: 'Nutora Heritage Festive Gift Box',
    category: 'Gift Boxes',
    categorySlug: 'gifts',
    price: 2450,
    originalPrice: 2700,
    weight: '4 Artisanal Jars Set',
    rating: 5.0,
    reviewCount: 12,
    image: 'assets/images/products/heritage-gift-box.jpg',
    badge: 'PREMIUM HAMPER',
    inStock: true,
    tag: 'bestseller',
    description: 'Handcrafted wooden box containing Peanut Butter, Honey, Ghee, and Achar with wooden dipper.'
  }
];

// Cart State Manager
class CartStore {
  constructor() {
    this.storageKey = 'nutora_cart_v1';
    this.items = this.load();
  }

  load() {
    try {
      const data = localStorage.getItem(this.storageKey);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.warn('Could not load cart from storage', e);
      return [];
    }
  }

  save() {
    try {
      localStorage.setItem(this.storageKey, JSON.stringify(this.items));
    } catch (e) {
      console.warn('Could not save cart', e);
    }
    this.notify();
  }

  addItem(product, quantity = 1) {
    const existing = this.items.find(item => item.id === product.id);
    if (existing) {
      existing.quantity += quantity;
    } else {
      this.items.push({
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
        weight: product.weight,
        quantity: quantity
      });
    }
    this.save();
  }

  updateQuantity(id, delta) {
    const item = this.items.find(i => i.id === id);
    if (!item) return;
    item.quantity += delta;
    if (item.quantity <= 0) {
      this.removeItem(id);
    } else {
      this.save();
    }
  }

  removeItem(id) {
    this.items = this.items.filter(i => i.id !== id);
    this.save();
  }

  getTotalCount() {
    return this.items.reduce((sum, item) => sum + item.quantity, 0);
  }

  getSubtotal() {
    return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }

  notify() {
    document.dispatchEvent(new CustomEvent('nutora:cart-updated', { detail: this }));
  }
}

// Global Cart Instance
const cart = new CartStore();

// Notification Toast Utility
function showToast(message, icon = '✓') {
  let container = document.getElementById('toastContainer');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toastContainer';
    container.className = 'toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `<span>${icon}</span> <span>${message}</span>`;
  container.appendChild(toast);

  // Trigger animation
  requestAnimationFrame(() => toast.classList.add('show'));

  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, 3200);
}

// Render Products Grid
function renderProducts(filter = 'all') {
  const grid = document.getElementById('productsGrid');
  if (!grid) return;

  const filtered = filter === 'all'
    ? DEMO_PRODUCTS
    : filter === 'bestseller'
      ? DEMO_PRODUCTS.filter(p => p.tag === 'bestseller')
      : DEMO_PRODUCTS.filter(p => p.categorySlug === filter || p.tag === filter);

  grid.innerHTML = filtered.map(product => `
    <article class="product-card" data-id="${product.id}">
      <div class="product-media-wrapper">
        <div class="product-badge-group">
          ${product.badge ? `<span class="product-sale-pill">${product.badge}</span>` : ''}
          <span class="product-origin-pill">Mother's Kitchen</span>
        </div>
        <img src="${product.image}" alt="${product.name}" class="product-card-img" loading="lazy" />
      </div>
      <div class="product-card-body">
        <span class="product-category-name">${product.category}</span>
        <h3 class="product-title">${product.name}</h3>
        <p class="product-weight">${product.weight}</p>
        
        <div class="product-rating">
          <span class="stars">★★★★★</span>
          <span class="review-count">(${product.reviewCount} kitchen reviews)</span>
        </div>

        <div class="product-card-footer">
          <div class="price-box">
            <span class="price-current">৳${product.price}</span>
            ${product.originalPrice ? `<span class="price-original">৳${product.originalPrice}</span>` : ''}
          </div>
          <button class="btn-add-cart" onclick="handleAddToCart('${product.id}')" aria-label="Add ${product.name} to cart">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <path d="M16 10a4 4 0 0 1-8 0"></path>
            </svg>
            Add to Basket
          </button>
        </div>
      </div>
    </article>
  `).join('');
}

// Add to Cart handler
window.handleAddToCart = function(productId) {
  const product = DEMO_PRODUCTS.find(p => p.id === productId);
  if (!product) return;

  cart.addItem(product, 1);
  showToast(`Added ${product.name} to your basket!`, '🌿');
  openCartDrawer();
};

// Cart Drawer Controller
function initCartDrawer() {
  const cartBtn = document.getElementById('cartBtn');
  const drawer = document.getElementById('cartDrawer');
  const overlay = document.getElementById('cartDrawerOverlay');
  const closeBtn = document.getElementById('closeCartDrawer');

  window.openCartDrawer = function() {
    drawer?.classList.add('active');
    overlay?.classList.add('active');
    document.body.style.overflow = 'hidden';
    renderCartDrawerItems();
  };

  window.closeCartDrawer = function() {
    drawer?.classList.remove('active');
    overlay?.classList.remove('active');
    document.body.style.overflow = '';
  };

  cartBtn?.addEventListener('click', (e) => {
    e.preventDefault();
    window.openCartDrawer();
  });

  closeBtn?.addEventListener('click', window.closeCartDrawer);
  overlay?.addEventListener('click', window.closeCartDrawer);

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') window.closeCartDrawer();
  });

  // Listen to cart updates
  document.addEventListener('nutora:cart-updated', () => {
    updateCartUI();
    renderCartDrawerItems();
  });

  updateCartUI();
}

function updateCartUI() {
  const countBadge = document.getElementById('cartCount');
  if (countBadge) {
    countBadge.textContent = cart.getTotalCount();
  }
}

function renderCartDrawerItems() {
  const container = document.getElementById('cartDrawerItems');
  const subtotalEl = document.getElementById('cartDrawerSubtotal');
  if (!container) return;

  if (cart.items.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 48px 16px; color: var(--color-muted-text);">
        <div style="font-size: 2.8rem; margin-bottom: 12px; color: var(--color-honey-gold);">🧺</div>
        <p style="font-size: 1.1rem; font-weight: 600; color: var(--color-deep-green);">Your basket is empty</p>
        <p style="font-size: 0.9rem; margin-top: 6px;">Add freshly handcrafted jars from mother's kitchen!</p>
      </div>
    `;
    if (subtotalEl) subtotalEl.textContent = '৳0';
    return;
  }

  container.innerHTML = cart.items.map(item => `
    <div style="display: flex; gap: 14px; margin-bottom: 16px; padding-bottom: 16px; border-bottom: 1px solid var(--color-light-border); align-items: center;">
      <img src="${item.image}" alt="${item.name}" style="width: 60px; height: 60px; border-radius: 8px; object-fit: cover; background: #FFF9EB;">
      <div style="flex-grow: 1;">
        <h4 style="font-size: 0.95rem; font-weight: 700; color: var(--color-deep-green); margin-bottom: 4px;">${item.name}</h4>
        <div style="font-size: 0.82rem; color: var(--color-muted-text); margin-bottom: 8px;">${item.weight} • ৳${item.price} each</div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <button onclick="cart.updateQuantity('${item.id}', -1)" style="width: 26px; height: 26px; border-radius: 4px; border: 1px solid var(--color-light-border); display: flex; align-items: center; justify-content: center; font-weight: bold; background: white;">-</button>
          <span style="font-size: 0.9rem; font-weight: 700; min-width: 20px; text-align: center;">${item.quantity}</span>
          <button onclick="cart.updateQuantity('${item.id}', 1)" style="width: 26px; height: 26px; border-radius: 4px; border: 1px solid var(--color-light-border); display: flex; align-items: center; justify-content: center; font-weight: bold; background: white;">+</button>
        </div>
      </div>
      <div style="text-align: right;">
        <div style="font-weight: 800; color: var(--color-forest-green); font-size: 1.05rem;">৳${item.price * item.quantity}</div>
        <button onclick="cart.removeItem('${item.id}')" style="color: #C0392B; font-size: 0.78rem; text-decoration: underline; margin-top: 8px; cursor: pointer;">Remove</button>
      </div>
    </div>
  `).join('');

  if (subtotalEl) {
    subtotalEl.textContent = `৳${cart.getSubtotal()}`;
  }
}

// Filter Tabs initialization
function initFilterTabs() {
  const tabs = document.querySelectorAll('.filter-tab');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const filter = tab.getAttribute('data-filter') || 'all';
      renderProducts(filter);
    });
  });
}

// Newsletter subscription form
function initNewsletter() {
  const form = document.getElementById('newsletterForm');
  form?.addEventListener('submit', (e) => {
    e.preventDefault();
    const input = form.querySelector('input');
    if (input && input.value) {
      showToast('Welcome to the Nutora Kitchen Family! 🍯', '🎉');
      input.value = '';
    }
  });
}

// Sticky header shadow
function initHeaderScroll() {
  const header = document.querySelector('.site-header');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 20) {
      header?.classList.add('is-scrolled');
    } else {
      header?.classList.remove('is-scrolled');
    }
  });
}

// Document Ready
document.addEventListener('DOMContentLoaded', () => {
  renderProducts('all');
  initCartDrawer();
  initFilterTabs();
  initNewsletter();
  initHeaderScroll();
});
