#!/bin/bash
set -e
BASE=~/workspace
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎓  ProveRank Store — STUDENT STORE PAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p $BASE/frontend/app/dashboard/store

# ─────────────────────────────────────────
# CREATE: Student Store page.tsx
# ─────────────────────────────────────────
cat > $BASE/frontend/app/dashboard/store/page.tsx << 'ENDOFFILE'
'use client';
import { useState, useEffect, useCallback } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com';

// ── Helpers ──────────────────────────────────────
const tok = () => (typeof window !== 'undefined' ? localStorage.getItem('pr_token') || '' : '');
const hdr = () => ({ 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}` });
const fmtPrice   = (n: number) => '₹' + n.toLocaleString('en-IN');
const fmtDate    = (d: string | Date) => new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
const disc       = (orig: number, sale: number) => Math.round(((orig - sale) / orig) * 100);

// ── Status helpers ───────────────────────────────
const STATUS_STEPS: Record<string, number> = {
  pending: 0, confirmed: 1, packed: 2, shipped: 3, out_for_delivery: 4, delivered: 5
};
const STATUS_LABEL: Record<string, string> = {
  pending: 'Order Placed', confirmed: 'Confirmed', packed: 'Packed', shipped: 'Shipped',
  out_for_delivery: 'Out for Delivery', delivered: 'Delivered',
  cancelled: 'Cancelled', return_requested: 'Return Requested', returned: 'Returned', refunded: 'Refunded'
};

// ── Design tokens ────────────────────────────────
const GLASS  = 'backdrop-blur-md bg-white/[0.04] border border-white/[0.08] rounded-2xl';
const GLASS2 = 'backdrop-blur-sm bg-white/[0.02] border border-white/[0.06] rounded-xl';
const BTN_P  = 'px-5 py-3 rounded-xl font-semibold text-sm transition-all duration-200 bg-gradient-to-r from-blue-600 to-cyan-500 text-white hover:from-blue-500 hover:to-cyan-400 hover:shadow-lg hover:shadow-blue-500/30 active:scale-95';
const BTN_S  = 'px-5 py-3 rounded-xl font-semibold text-sm transition-all duration-200 bg-white/5 border border-white/10 text-white/70 hover:bg-white/10 hover:text-white active:scale-95';
const INP    = 'w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-white/30 focus:outline-none focus:border-blue-400/60 focus:bg-white/8 text-sm transition-all';
const SEL    = 'w-full bg-[#060d1f] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-blue-400/60 text-sm';

// ── Toast ────────────────────────────────────────
function Toast({ msg, type, onClose }: { msg: string; type: 'success' | 'error' | 'info'; onClose: () => void }) {
  useEffect(() => { const t = setTimeout(onClose, 3200); return () => clearTimeout(t); }, [onClose]);
  return (
    <div className="fixed top-5 left-1/2 -translate-x-1/2 z-[9999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl text-sm font-medium text-white"
      style={{ background: type === 'success' ? 'linear-gradient(135deg,#16a34a,#059669)' : type === 'error' ? 'linear-gradient(135deg,#dc2626,#b91c1c)' : 'linear-gradient(135deg,#2563eb,#0ea5e9)', boxShadow: '0 8px 32px rgba(0,0,0,0.4)', backdropFilter: 'blur(16px)', border: '1px solid rgba(255,255,255,0.15)' }}>
      <span>{type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}</span>
      <span>{msg}</span>
    </div>
  );
}

// ── Star Rating ──────────────────────────────────
function Stars({ n, size = 14 }: { n: number; size?: number }) {
  return (
    <span className="inline-flex gap-0.5">
      {[1,2,3,4,5].map(i => (
        <svg key={i} width={size} height={size} viewBox="0 0 24 24" fill={i <= n ? '#fbbf24' : 'none'} stroke={i <= n ? '#fbbf24' : '#4b5563'} strokeWidth="2">
          <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" />
        </svg>
      ))}
    </span>
  );
}

// ── Product Card ─────────────────────────────────
function ProductCard({ product, onView, onAddToCart, onWishlist, wishlistIds }: any) {
  const [adding, setAdding] = useState(false);
  const isWished = wishlistIds.includes(product._id);
  const pct = disc(product.originalPrice, product.price);

  const handleAdd = async (e: React.MouseEvent) => {
    e.stopPropagation();
    setAdding(true);
    await onAddToCart(product._id);
    setAdding(false);
  };

  return (
    <div onClick={() => onView(product)} className={`${GLASS} overflow-hidden cursor-pointer group transition-all duration-300 hover:border-blue-500/30 hover:shadow-xl hover:shadow-blue-500/10 hover:-translate-y-1`}>
      <div className="relative overflow-hidden">
        {product.images?.[0]?.url ? (
          <img src={product.images[0].url} alt={product.name} className="w-full h-44 object-cover transition-transform duration-500 group-hover:scale-105" />
        ) : (
          <div className="w-full h-44 flex items-center justify-center text-5xl" style={{ background: 'linear-gradient(135deg, rgba(37,99,235,0.15), rgba(14,165,233,0.08))' }}>📚</div>
        )}
        {/* Badges */}
        <div className="absolute top-2 left-2 flex flex-col gap-1">
          {product.isBestSeller && <span className="text-xs px-2 py-0.5 rounded-full font-bold text-black" style={{ background: 'linear-gradient(90deg,#f59e0b,#ef4444)' }}>🔥 Bestseller</span>}
          {product.isNew && !product.isBestSeller && <span className="text-xs px-2 py-0.5 rounded-full font-bold text-white" style={{ background: 'linear-gradient(90deg,#10b981,#0ea5e9)' }}>✨ New</span>}
        </div>
        {pct > 0 && <div className="absolute top-2 right-10 bg-red-500 text-white text-xs px-2 py-0.5 rounded-full font-bold">{pct}% off</div>}
        {/* Wishlist btn */}
        <button onClick={e => { e.stopPropagation(); onWishlist(product._id); }}
          className="absolute top-2 right-2 w-7 h-7 flex items-center justify-center rounded-full bg-black/40 backdrop-blur-sm border border-white/10 transition-all hover:scale-110">
          <svg width="14" height="14" viewBox="0 0 24 24" fill={isWished ? '#ef4444' : 'none'} stroke={isWished ? '#ef4444' : 'white'} strokeWidth="2">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </button>
        {/* Out of stock overlay */}
        {product.stock === 0 && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center">
            <span className="bg-red-500/80 text-white text-xs px-3 py-1.5 rounded-full font-bold">Out of Stock</span>
          </div>
        )}
      </div>
      <div className="p-4">
        <p className="text-xs text-blue-400 mb-1 font-medium">{product.category} • {product.subject}</p>
        <p className="text-white font-semibold text-sm mb-1 line-clamp-2 leading-snug">{product.name}</p>
        {product.author && <p className="text-white/40 text-xs mb-2">by {product.author}</p>}
        <div className="flex items-center gap-1.5 mb-3">
          <Stars n={Math.round(product.ratings?.average || 0)} size={11} />
          <span className="text-white/30 text-xs">({product.ratings?.count || 0})</span>
        </div>
        <div className="flex items-center gap-2 mb-3">
          <span className="text-lg font-black text-white">{fmtPrice(product.price)}</span>
          {product.originalPrice > product.price && <span className="text-white/30 line-through text-xs">{fmtPrice(product.originalPrice)}</span>}
        </div>
        <div className="flex items-center gap-1 mb-3">
          {product.deliveryCharge === 0
            ? <span className="text-green-400 text-xs font-medium">🚚 Free Delivery</span>
            : <span className="text-white/40 text-xs">🚚 +₹{product.deliveryCharge} delivery</span>}
        </div>
        <button onClick={handleAdd} disabled={adding || product.stock === 0}
          className={`w-full py-2.5 rounded-xl text-sm font-semibold transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed ${product.stock > 0 ? 'bg-gradient-to-r from-blue-600 to-cyan-500 text-white hover:from-blue-500 hover:to-cyan-400 hover:shadow-lg hover:shadow-blue-500/20 active:scale-95' : 'bg-white/5 text-white/30 border border-white/10'}`}>
          {adding ? '⏳ Adding...' : product.stock > 0 ? '🛒 Add to Cart' : 'Out of Stock'}
        </button>
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════
export default function StorePage() {
  // View state
  const [view, setView] = useState<'store' | 'product' | 'cart' | 'checkout' | 'orders' | 'wishlist' | 'order_detail'>('store');
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' | 'info' } | null>(null);
  const showToast = (msg: string, type: 'success' | 'error' | 'info' = 'success') => setToast({ msg, type });

  // Store data
  const [products, setProducts]     = useState<any[]>([]);
  const [featured, setFeatured]     = useState<any[]>([]);
  const [totalProducts, setTotal]   = useState(0);
  const [loading, setLoading]       = useState(true);
  const [page, setPage]             = useState(1);

  // Filters
  const [search, setSearch]         = useState('');
  const [catFilter, setCat]         = useState('');
  const [subFilter, setSub]         = useState('');
  const [classFilter, setClass]     = useState('');
  const [sortBy, setSort]           = useState('newest');

  // Cart
  const [cart, setCart]             = useState<any>({ items: [], total: 0, subtotal: 0, deliveryCharge: 0, couponDiscount: 0, itemCount: 0 });
  const [cartLoading, setCartLoading] = useState(false);
  const [couponInput, setCouponInput] = useState('');

  // Checkout
  const [checkoutStep, setCheckoutStep] = useState(0); // 0:address, 1:payment, 2:confirm
  const [address, setAddress] = useState({ fullName:'', phone:'', addressLine1:'', addressLine2:'', city:'', state:'', pincode:'', landmark:'' });
  const [payMethod, setPayMethod] = useState('COD');
  const [buyerNotes, setBuyerNotes] = useState('');
  const [placing, setPlacing] = useState(false);

  // Product detail
  const [selectedProduct, setSelectedProduct] = useState<any>(null);
  const [productReviews, setProductReviews]   = useState<any[]>([]);
  const [myRating, setMyRating] = useState(0);
  const [myReviewTitle, setMyReviewTitle] = useState('');
  const [myReviewBody, setMyReviewBody]   = useState('');

  // Orders
  const [orders, setOrders]         = useState<any[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);

  // Wishlist
  const [wishlist, setWishlist]     = useState<any[]>([]);
  const [wishlistIds, setWishlistIds] = useState<string[]>([]);

  // ── Load products ───────────────────────────────
  const loadProducts = useCallback(() => {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), limit: '12', sort: sortBy });
    if (search)    params.set('search', search);
    if (catFilter) params.set('category', catFilter);
    if (subFilter) params.set('subject', subFilter);
    if (classFilter) params.set('classLevel', classFilter);
    fetch(`${API}/api/store/products?${params}`)
      .then(r => r.json())
      .then(d => { setProducts(d.products || []); setTotal(d.total || 0); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [page, search, catFilter, subFilter, classFilter, sortBy]);

  useEffect(() => { loadProducts(); }, [loadProducts]);

  useEffect(() => {
    fetch(`${API}/api/store/products/featured`).then(r => r.json()).then(d => setFeatured(d.products || []));
    if (tok()) {
      loadCart();
      loadWishlist();
    }
  }, []);

  const loadCart = () => {
    if (!tok()) return;
    fetch(`${API}/api/store/cart`, { headers: hdr() }).then(r => r.json()).then(d => setCart(d)).catch(() => {});
  };
  const loadWishlist = () => {
    if (!tok()) return;
    fetch(`${API}/api/store/wishlist`, { headers: hdr() })
      .then(r => r.json())
      .then(d => { setWishlist(d.products || []); setWishlistIds((d.products || []).map((p: any) => p._id)); });
  };
  const loadOrders = () => {
    if (!tok()) return;
    fetch(`${API}/api/store/orders`, { headers: hdr() }).then(r => r.json()).then(d => setOrders(d.orders || []));
  };

  // ── Cart actions ────────────────────────────────
  const addToCart = async (productId: string, qty = 1) => {
    if (!tok()) { showToast('Please login to add items', 'error'); return; }
    setCartLoading(true);
    try {
      const r = await fetch(`${API}/api/store/cart/add`, { method: 'POST', headers: hdr(), body: JSON.stringify({ productId, quantity: qty }) });
      const d = await r.json();
      if (r.ok) { setCart(d.cart); showToast('Added to cart! 🛒'); }
      else showToast(d.message, 'error');
    } catch { showToast('Failed to add', 'error'); }
    setCartLoading(false);
  };

  const updateQty = async (productId: string, qty: number) => {
    const r = await fetch(`${API}/api/store/cart/update`, { method: 'PUT', headers: hdr(), body: JSON.stringify({ productId, quantity: qty }) });
    const d = await r.json();
    if (r.ok) setCart(d.cart);
    else showToast(d.message, 'error');
  };

  const removeItem = async (productId: string) => {
    const r = await fetch(`${API}/api/store/cart/remove/${productId}`, { method: 'DELETE', headers: hdr() });
    const d = await r.json();
    if (r.ok) setCart(d.cart);
  };

  const applyCoupon = async () => {
    if (!couponInput.trim()) return;
    const r = await fetch(`${API}/api/store/coupon/apply`, { method: 'POST', headers: hdr(), body: JSON.stringify({ couponCode: couponInput }) });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) loadCart();
  };

  const removeCoupon = async () => {
    await fetch(`${API}/api/store/coupon/remove`, { method: 'POST', headers: hdr() });
    setCouponInput(''); loadCart();
  };

  // ── Wishlist ────────────────────────────────────
  const toggleWishlist = async (productId: string) => {
    if (!tok()) { showToast('Please login', 'error'); return; }
    const r = await fetch(`${API}/api/store/wishlist/toggle/${productId}`, { method: 'POST', headers: hdr() });
    const d = await r.json();
    if (r.ok) { showToast(d.message); loadWishlist(); }
  };

  // ── Product detail ──────────────────────────────
  const viewProduct = async (product: any) => {
    setSelectedProduct(product);
    setView('product');
    try {
      const r = await fetch(`${API}/api/store/products/${product._id}`);
      const d = await r.json();
      setSelectedProduct(d.product);
      setProductReviews(d.reviews || []);
    } catch {}
  };

  // ── Submit review ────────────────────────────────
  const submitReview = async () => {
    if (!myRating) { showToast('Please select a rating', 'error'); return; }
    const r = await fetch(`${API}/api/store/products/${selectedProduct._id}/review`, {
      method: 'POST', headers: hdr(),
      body: JSON.stringify({ rating: myRating, title: myReviewTitle, body: myReviewBody })
    });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) { setMyRating(0); setMyReviewTitle(''); setMyReviewBody(''); viewProduct(selectedProduct); }
  };

  // ── Place order ──────────────────────────────────
  const placeOrder = async () => {
    setPlacing(true);
    try {
      const r = await fetch(`${API}/api/store/orders/create`, {
        method: 'POST', headers: hdr(),
        body: JSON.stringify({ shippingAddress: address, paymentMethod: payMethod, buyerNotes })
      });
      const d = await r.json();
      if (r.ok) {
        showToast(`Order placed! ID: ${d.orderId} 🎉`);
        setCart({ items: [], total: 0, subtotal: 0, deliveryCharge: 0, couponDiscount: 0, itemCount: 0 });
        setCheckoutStep(0);
        loadOrders();
        setView('orders');
      } else showToast(d.message, 'error');
    } catch { showToast('Failed to place order', 'error'); }
    setPlacing(false);
  };

  // ── Cancel order ─────────────────────────────────
  const cancelOrder = async (orderId: string, reason: string) => {
    const r = await fetch(`${API}/api/store/orders/${orderId}/cancel`, { method: 'POST', headers: hdr(), body: JSON.stringify({ reason }) });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) { loadOrders(); setView('orders'); }
  };

  const setA = (k: string, v: string) => setAddress(p => ({ ...p, [k]: v }));

  // ══════════════════════════════════════════════════
  // RENDER
  // ══════════════════════════════════════════════════
  return (
    <div className="min-h-screen text-white pb-16"
      style={{ background: 'radial-gradient(ellipse 120% 60% at 50% -10%, rgba(37,99,235,0.12) 0%, transparent 70%), linear-gradient(180deg, #030710 0%, #060d1f 100%)' }}>

      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* ── TOP BAR ── */}
      <div className="sticky top-0 z-40 px-4 lg:px-8 py-4" style={{ background: 'rgba(3,7,16,0.85)', backdropFilter: 'blur(20px)', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {view !== 'store' && (
              <button onClick={() => { setView('store'); setSelectedProduct(null); setCheckoutStep(0); }} className="w-9 h-9 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center hover:bg-white/10 transition-all">
                <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
              </button>
            )}
            <div>
              <h1 className="text-lg font-black tracking-tight text-white" style={{ fontFamily: "'Playfair Display', serif" }}>
                <span style={{ background: 'linear-gradient(90deg,#60a5fa,#22d3ee)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>Prove</span>
                <span className="text-white">Store</span>
              </h1>
              <p className="text-xs text-white/30 leading-none">Study Materials</p>
            </div>
          </div>
          <nav className="flex items-center gap-1">
            {[
              { id: 'store', label: '🏪 Store' },
              { id: 'wishlist', label: '❤️', onClick: () => { loadWishlist(); setView('wishlist'); } },
              { id: 'orders', label: '📦', onClick: () => { loadOrders(); setView('orders'); } },
              { id: 'cart', label: '', onClick: () => setView('cart') }
            ].map(item => (
              item.id === 'cart' ? (
                <button key="cart" onClick={() => setView('cart')}
                  className="relative flex items-center gap-2 px-3 py-2 rounded-xl bg-gradient-to-r from-blue-600/30 to-cyan-500/20 border border-blue-500/30 text-white hover:from-blue-600/50 transition-all">
                  <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
                    <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                  </svg>
                  {cart.itemCount > 0 && (
                    <span className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-blue-500 text-white text-xs flex items-center justify-center font-bold">{cart.itemCount}</span>
                  )}
                  <span className="text-sm font-semibold hidden sm:block">{fmtPrice(cart.total || 0)}</span>
                </button>
              ) : (
                <button key={item.id} onClick={item.onClick || (() => setView(item.id as any))}
                  className={`px-3 py-2 rounded-xl text-sm font-medium transition-all ${view === item.id ? 'bg-blue-600/30 text-blue-300 border border-blue-500/30' : 'text-white/50 hover:text-white hover:bg-white/5'}`}>
                  {item.label}
                </button>
              )
            ))}
          </nav>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 lg:px-8 py-6">

        {/* ══════════════════════════════════════════
            STORE VIEW
        ══════════════════════════════════════════ */}
        {view === 'store' && (
          <div>
            {/* Hero Banner */}
            <div className="rounded-3xl mb-8 overflow-hidden relative"
              style={{ background: 'linear-gradient(135deg, rgba(37,99,235,0.25) 0%, rgba(14,165,233,0.15) 50%, rgba(139,92,246,0.1) 100%)', border: '1px solid rgba(96,165,250,0.2)', padding: '40px 32px' }}>
              <div className="absolute inset-0 overflow-hidden">
                <div className="absolute -top-8 -right-8 w-64 h-64 rounded-full opacity-10" style={{ background: 'radial-gradient(circle, #60a5fa 0%, transparent 70%)' }} />
                <div className="absolute -bottom-12 -left-8 w-48 h-48 rounded-full opacity-10" style={{ background: 'radial-gradient(circle, #22d3ee 0%, transparent 70%)' }} />
              </div>
              <div className="relative flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
                <div>
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium mb-4" style={{ background: 'rgba(96,165,250,0.15)', border: '1px solid rgba(96,165,250,0.3)', color: '#93c5fd' }}>
                    ✨ Official NCERT Books & Study Material
                  </div>
                  <h2 className="text-3xl lg:text-4xl font-black text-white mb-3 leading-tight" style={{ fontFamily: "'Playfair Display', serif" }}>
                    Everything You Need<br />
                    <span style={{ background: 'linear-gradient(90deg,#60a5fa,#22d3ee)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>to Crack NEET</span>
                  </h2>
                  <p className="text-white/50 text-sm max-w-md">Books, Notes, Stationery — delivered to your door. Official NCERT + premium study materials at student-friendly prices.</p>
                </div>
                <div className="flex flex-col gap-3">
                  <div className="flex items-center gap-3 text-sm text-white/60">
                    <span className="w-8 h-8 rounded-xl bg-green-500/20 flex items-center justify-center">🚚</span> Free delivery above ₹499
                  </div>
                  <div className="flex items-center gap-3 text-sm text-white/60">
                    <span className="w-8 h-8 rounded-xl bg-blue-500/20 flex items-center justify-center">↩️</span> 7-day easy returns
                  </div>
                  <div className="flex items-center gap-3 text-sm text-white/60">
                    <span className="w-8 h-8 rounded-xl bg-purple-500/20 flex items-center justify-center">🔒</span> Secure COD & UPI payment
                  </div>
                </div>
              </div>
            </div>

            {/* Featured Strip */}
            {featured.length > 0 && (
              <div className="mb-8">
                <div className="flex items-center gap-2 mb-4">
                  <span className="text-yellow-400">⭐</span>
                  <h3 className="text-base font-bold text-white">Featured Products</h3>
                </div>
                <div className="flex gap-4 overflow-x-auto pb-2">
                  {featured.map((p: any) => (
                    <div key={p._id} onClick={() => viewProduct(p)} className="flex-shrink-0 w-48 cursor-pointer group"
                      style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 16, padding: 12, transition: 'all 0.2s' }}>
                      {p.images?.[0]?.url
                        ? <img src={p.images[0].url} alt={p.name} className="w-full h-28 object-cover rounded-xl mb-3 group-hover:scale-105 transition-transform duration-300" />
                        : <div className="w-full h-28 rounded-xl mb-3 flex items-center justify-center text-3xl" style={{ background: 'rgba(37,99,235,0.1)' }}>📚</div>}
                      <p className="text-white text-xs font-semibold line-clamp-2 mb-1">{p.name}</p>
                      <p className="text-blue-400 text-sm font-bold">{fmtPrice(p.price)}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Search & Filters */}
            <div className={`${GLASS} p-4 mb-6`}>
              <div className="flex flex-col sm:flex-row gap-3 mb-3">
                <div className="relative flex-1">
                  <svg className="absolute left-3 top-1/2 -translate-y-1/2 text-white/30" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
                  <input value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} placeholder="Search books, notes, stationery..."
                    className="w-full bg-white/5 border border-white/10 rounded-xl pl-10 pr-4 py-3 text-white placeholder-white/30 focus:outline-none focus:border-blue-400/60 text-sm" />
                </div>
                <select value={sortBy} onChange={e => setSort(e.target.value)} className={SEL} style={{ width: 'auto', minWidth: 140 }}>
                  <option value="newest">Newest First</option>
                  <option value="price_asc">Price: Low → High</option>
                  <option value="price_desc">Price: High → Low</option>
                  <option value="rating">Top Rated</option>
                  <option value="popular">Most Popular</option>
                </select>
              </div>
              <div className="flex gap-2 flex-wrap">
                {/* Category */}
                {['','Books','Notes','Stationery','Combo Pack','Other'].map(c => (
                  <button key={c} onClick={() => { setCat(c); setPage(1); }}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${catFilter === c ? 'bg-blue-600 text-white' : 'bg-white/5 text-white/50 border border-white/10 hover:bg-white/10'}`}>
                    {c || 'All'}
                  </button>
                ))}
                <div className="w-px bg-white/10 mx-1" />
                {/* Subject */}
                {['','Physics','Chemistry','Biology','Mathematics'].map(s => (
                  <button key={s} onClick={() => { setSub(s); setPage(1); }}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${subFilter === s ? 'bg-cyan-600 text-white' : 'bg-white/5 text-white/50 border border-white/10 hover:bg-white/10'}`}>
                    {s || 'All Subjects'}
                  </button>
                ))}
                <div className="w-px bg-white/10 mx-1" />
                {/* Class */}
                {['','Class 11','Class 12','Both'].map(cl => (
                  <button key={cl} onClick={() => { setClass(cl); setPage(1); }}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${classFilter === cl ? 'bg-purple-600 text-white' : 'bg-white/5 text-white/50 border border-white/10 hover:bg-white/10'}`}>
                    {cl || 'All Classes'}
                  </button>
                ))}
              </div>
            </div>

            {/* Products Grid */}
            <p className="text-white/30 text-xs mb-4">{totalProducts} products found</p>
            {loading ? (
              <div className="flex items-center justify-center py-24">
                <div className="w-12 h-12 rounded-full border-2 border-blue-500 border-t-transparent animate-spin" />
              </div>
            ) : products.length === 0 ? (
              <div className={`${GLASS} p-16 text-center`}>
                <div className="text-6xl mb-4">📭</div>
                <p className="text-white/50 text-lg font-medium">No products found</p>
                <p className="text-white/30 text-sm mt-1">Try adjusting your filters</p>
                <button onClick={() => { setSearch(''); setCat(''); setSub(''); setClass(''); setPage(1); }} className={`${BTN_S} mt-4`}>Clear Filters</button>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                {products.map(p => (
                  <ProductCard key={p._id} product={p} onView={viewProduct} onAddToCart={addToCart} onWishlist={toggleWishlist} wishlistIds={wishlistIds} />
                ))}
              </div>
            )}

            {/* Pagination */}
            {totalProducts > 12 && (
              <div className="flex justify-center items-center gap-3 mt-8">
                <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page===1} className={`${BTN_S} disabled:opacity-30`}>← Prev</button>
                <span className="text-white/40 text-sm">Page {page} of {Math.ceil(totalProducts/12)}</span>
                <button onClick={() => setPage(p => p+1)} disabled={page>=Math.ceil(totalProducts/12)} className={`${BTN_S} disabled:opacity-30`}>Next →</button>
              </div>
            )}

            {/* NCERT Fact Strip */}
            <div className="mt-10 rounded-2xl p-5 text-center" style={{ background: 'linear-gradient(135deg, rgba(37,99,235,0.08), rgba(14,165,233,0.05))', border: '1px solid rgba(96,165,250,0.12)' }}>
              <p className="text-xs text-blue-400 font-medium mb-1">📖 Did you know?</p>
              <p className="text-white/60 text-sm">NCERT Biology Class 11 has 22 chapters. NEET 2024 had <span className="text-white font-semibold">90 biology questions</span> — all based directly on NCERT text.</p>
            </div>
          </div>
        )}

        {/* ══════════════════════════════════════════
            PRODUCT DETAIL VIEW
        ══════════════════════════════════════════ */}
        {view === 'product' && selectedProduct && (
          <div className="max-w-4xl mx-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
              {/* Images */}
              <div>
                {selectedProduct.images?.[0]?.url ? (
                  <img src={selectedProduct.images[0].url} alt={selectedProduct.name} className="w-full h-72 lg:h-96 object-cover rounded-2xl mb-3" />
                ) : (
                  <div className="w-full h-72 rounded-2xl flex items-center justify-center text-7xl" style={{ background: 'linear-gradient(135deg, rgba(37,99,235,0.15), rgba(14,165,233,0.08))' }}>📚</div>
                )}
                {selectedProduct.images?.length > 1 && (
                  <div className="flex gap-2">
                    {selectedProduct.images.map((img: any, i: number) => (
                      <img key={i} src={img.url} alt={img.alt} className="w-16 h-16 object-cover rounded-xl border border-white/10 cursor-pointer hover:border-blue-400/50" />
                    ))}
                  </div>
                )}
              </div>
              {/* Info */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-xs px-2 py-1 rounded-full bg-blue-500/20 text-blue-300 font-medium">{selectedProduct.category}</span>
                  <span className="text-xs px-2 py-1 rounded-full bg-cyan-500/20 text-cyan-300 font-medium">{selectedProduct.subject}</span>
                  <span className="text-xs px-2 py-1 rounded-full bg-purple-500/20 text-purple-300 font-medium">{selectedProduct.classLevel}</span>
                </div>
                <h1 className="text-2xl font-black text-white mb-1 leading-tight" style={{ fontFamily: "'Playfair Display', serif" }}>{selectedProduct.name}</h1>
                {selectedProduct.author && <p className="text-white/40 text-sm mb-3">by {selectedProduct.author} • {selectedProduct.publisher} • {selectedProduct.edition}</p>}

                <div className="flex items-center gap-3 mb-4">
                  <Stars n={Math.round(selectedProduct.ratings?.average || 0)} />
                  <span className="text-white/50 text-sm">{selectedProduct.ratings?.average?.toFixed(1) || '0.0'} ({selectedProduct.ratings?.count || 0} reviews)</span>
                </div>

                <div className="flex items-end gap-3 mb-2">
                  <span className="text-4xl font-black text-white">{fmtPrice(selectedProduct.price)}</span>
                  {selectedProduct.originalPrice > selectedProduct.price && (
                    <>
                      <span className="text-white/30 line-through text-xl">{fmtPrice(selectedProduct.originalPrice)}</span>
                      <span className="bg-green-500/20 text-green-300 px-2 py-1 rounded-lg text-sm font-bold">{disc(selectedProduct.originalPrice, selectedProduct.price)}% off</span>
                    </>
                  )}
                </div>

                {selectedProduct.deliveryCharge === 0
                  ? <p className="text-green-400 text-sm font-medium mb-4">🚚 Free Delivery</p>
                  : <p className="text-white/40 text-sm mb-4">🚚 Delivery: ₹{selectedProduct.deliveryCharge}</p>}

                <p className={`text-sm font-medium mb-4 ${selectedProduct.stock > 10 ? 'text-green-400' : selectedProduct.stock > 0 ? 'text-yellow-400' : 'text-red-400'}`}>
                  {selectedProduct.stock > 10 ? `✓ In Stock (${selectedProduct.stock} available)` : selectedProduct.stock > 0 ? `⚠ Only ${selectedProduct.stock} left!` : '✕ Out of Stock'}
                </p>

                <div className="flex gap-3 mb-6">
                  <button onClick={() => addToCart(selectedProduct._id)} disabled={selectedProduct.stock === 0 || cartLoading}
                    className={`${BTN_P} flex-1 disabled:opacity-50`}>
                    🛒 Add to Cart
                  </button>
                  <button onClick={() => toggleWishlist(selectedProduct._id)}
                    className={`${BTN_S} ${wishlistIds.includes(selectedProduct._id) ? 'border-red-500/40 text-red-400' : ''}`}>
                    {wishlistIds.includes(selectedProduct._id) ? '❤️' : '🤍'}
                  </button>
                </div>

                {/* Specs */}
                {selectedProduct.specifications?.length > 0 && (
                  <div className={`${GLASS2} p-4 mb-4`}>
                    <p className="text-xs text-white/40 font-semibold mb-2 uppercase tracking-wider">Specifications</p>
                    <div className="grid grid-cols-2 gap-2">
                      {selectedProduct.specifications.map((s: any, i: number) => (
                        <div key={i} className="flex gap-2 text-xs">
                          <span className="text-white/30">{s.key}</span>
                          <span className="text-white/70 font-medium">{s.value}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Return policy */}
                <div className="flex gap-4 text-xs text-white/40">
                  <span>↩️ {selectedProduct.returnPolicy}</span>
                  <span>🕐 {selectedProduct.deliveryTime}</span>
                </div>
              </div>
            </div>

            {/* Description */}
            <div className={`${GLASS} p-6 mb-6`}>
              <h3 className="font-bold text-white mb-3">About this Product</h3>
              <p className="text-white/60 text-sm leading-relaxed">{selectedProduct.description}</p>
              {selectedProduct.features?.length > 0 && (
                <ul className="mt-4 space-y-2">
                  {selectedProduct.features.map((f: string, i: number) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-white/60">
                      <span className="text-blue-400 mt-0.5">✓</span> {f}
                    </li>
                  ))}
                </ul>
              )}
            </div>

            {/* Reviews */}
            <div className={`${GLASS} p-6`}>
              <h3 className="font-bold text-white mb-4">Reviews ({productReviews.length})</h3>
              {productReviews.map((r: any, i: number) => (
                <div key={i} className={`${GLASS2} p-4 mb-3`}>
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <div className="flex items-center gap-2">
                        <Stars n={r.rating} size={12} />
                        {r.isVerifiedPurchase && <span className="text-green-300 text-xs bg-green-500/15 px-1.5 py-0.5 rounded">✓ Verified</span>}
                      </div>
                      <p className="text-white text-sm font-semibold mt-1">{r.title}</p>
                      <p className="text-white/40 text-xs">{r.student?.name} • {fmtDate(r.createdAt)}</p>
                    </div>
                  </div>
                  <p className="text-white/60 text-sm">{r.body}</p>
                  {r.adminReply && (
                    <div className="mt-3 bg-blue-500/10 border border-blue-500/20 rounded-xl p-3">
                      <p className="text-blue-300 text-xs font-semibold mb-1">ProveRank Response</p>
                      <p className="text-white/60 text-xs">{r.adminReply}</p>
                    </div>
                  )}
                </div>
              ))}

              {/* Write Review */}
              {tok() && (
                <div className={`${GLASS2} p-4 mt-4`}>
                  <p className="text-sm font-semibold text-white mb-3">Write a Review</p>
                  <div className="flex gap-2 mb-3">
                    {[1,2,3,4,5].map(n => (
                      <button key={n} onClick={() => setMyRating(n)} className="text-2xl transition-transform hover:scale-110">
                        <span style={{ color: n <= myRating ? '#fbbf24' : '#374151' }}>★</span>
                      </button>
                    ))}
                  </div>
                  <input value={myReviewTitle} onChange={e => setMyReviewTitle(e.target.value)} placeholder="Review title" className={`${INP} mb-2`} />
                  <textarea value={myReviewBody} onChange={e => setMyReviewBody(e.target.value)} rows={3} placeholder="Share your experience..." className={`${INP} resize-none mb-3`} />
                  <button onClick={submitReview} className={BTN_P}>Submit Review</button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ══════════════════════════════════════════
            CART VIEW
        ══════════════════════════════════════════ */}
        {view === 'cart' && (
          <div className="max-w-3xl mx-auto">
            <h2 className="text-2xl font-black text-white mb-6" style={{ fontFamily: "'Playfair Display', serif" }}>🛒 Your Cart</h2>
            {cart.items?.length === 0 ? (
              <div className={`${GLASS} p-16 text-center`}>
                <div className="text-6xl mb-4">🛒</div>
                <p className="text-white/50 text-lg font-medium">Cart is empty</p>
                <p className="text-white/30 text-sm mt-1">Add some books to get started!</p>
                <button onClick={() => setView('store')} className={`${BTN_P} mt-5`}>Browse Store</button>
              </div>
            ) : (
              <>
                <div className="space-y-3 mb-5">
                  {cart.items?.map((item: any) => (
                    <div key={item.product._id} className={`${GLASS} p-4 flex gap-4 items-start`}>
                      {item.product.images?.[0]?.url
                        ? <img src={item.product.images[0].url} alt={item.product.name} className="w-16 h-20 object-cover rounded-xl flex-shrink-0" />
                        : <div className="w-16 h-20 rounded-xl flex items-center justify-center text-2xl flex-shrink-0" style={{ background: 'rgba(37,99,235,0.1)' }}>📚</div>}
                      <div className="flex-1 min-w-0">
                        <p className="text-white font-semibold text-sm line-clamp-2 mb-1">{item.product.name}</p>
                        <p className="text-white/40 text-xs mb-2">{item.product.category}</p>
                        <p className="text-white font-bold">{fmtPrice(item.product.price)}</p>
                      </div>
                      <div className="flex flex-col items-end gap-2">
                        <div className="flex items-center gap-2 bg-white/5 rounded-xl border border-white/10 p-1">
                          <button onClick={() => updateQty(item.product._id, item.quantity - 1)} className="w-7 h-7 rounded-lg bg-white/10 flex items-center justify-center hover:bg-white/20 text-white font-bold">−</button>
                          <span className="text-white font-bold w-8 text-center text-sm">{item.quantity}</span>
                          <button onClick={() => updateQty(item.product._id, item.quantity + 1)} className="w-7 h-7 rounded-lg bg-white/10 flex items-center justify-center hover:bg-white/20 text-white font-bold">+</button>
                        </div>
                        <p className="text-green-300 font-bold text-sm">{fmtPrice(item.product.price * item.quantity)}</p>
                        <button onClick={() => removeItem(item.product._id)} className="text-red-400/60 hover:text-red-400 text-xs transition-colors">Remove</button>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Coupon */}
                <div className={`${GLASS} p-4 mb-4`}>
                  <p className="text-xs text-white/40 mb-2 font-medium uppercase tracking-wider">Have a Coupon?</p>
                  {cart.couponCode ? (
                    <div className="flex items-center justify-between bg-green-500/10 border border-green-500/30 rounded-xl px-4 py-2">
                      <span className="text-green-300 font-mono font-bold">{cart.couponCode} applied! -₹{cart.couponDiscount}</span>
                      <button onClick={removeCoupon} className="text-red-400 text-xs hover:text-red-300">Remove</button>
                    </div>
                  ) : (
                    <div className="flex gap-2">
                      <input value={couponInput} onChange={e => setCouponInput(e.target.value.toUpperCase())} placeholder="Enter coupon code" className={`${INP} flex-1`} />
                      <button onClick={applyCoupon} className={`${BTN_P} whitespace-nowrap`}>Apply</button>
                    </div>
                  )}
                </div>

                {/* Bill Summary */}
                <div className={`${GLASS} p-5 mb-5`}>
                  <p className="font-bold text-white mb-3">Bill Summary</p>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between text-white/60"><span>Subtotal</span><span>{fmtPrice(cart.subtotal)}</span></div>
                    <div className="flex justify-between text-white/60"><span>Delivery</span><span>{cart.deliveryCharge > 0 ? fmtPrice(cart.deliveryCharge) : <span className="text-green-400">Free</span>}</span></div>
                    {cart.couponDiscount > 0 && <div className="flex justify-between text-green-400"><span>Coupon Discount</span><span>-{fmtPrice(cart.couponDiscount)}</span></div>}
                    <div className="flex justify-between text-white font-black text-lg border-t border-white/10 pt-2 mt-2">
                      <span>Total</span><span>{fmtPrice(cart.total)}</span>
                    </div>
                  </div>
                </div>

                <button onClick={() => setView('checkout')} className={`${BTN_P} w-full py-4 text-base`}>Proceed to Checkout →</button>
              </>
            )}
          </div>
        )}

        {/* ══════════════════════════════════════════
            CHECKOUT VIEW
        ══════════════════════════════════════════ */}
        {view === 'checkout' && (
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-black text-white mb-6" style={{ fontFamily: "'Playfair Display', serif" }}>Checkout</h2>

            {/* Steps */}
            <div className="flex items-center gap-2 mb-8">
              {['Delivery Address','Payment','Review Order'].map((step, i) => (
                <div key={i} className="flex items-center gap-2 flex-1">
                  <div className={`flex items-center gap-2 ${i <= checkoutStep ? 'text-blue-400' : 'text-white/20'}`}>
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border-2 ${i < checkoutStep ? 'bg-blue-600 border-blue-600 text-white' : i === checkoutStep ? 'border-blue-400 text-blue-400' : 'border-white/20 text-white/20'}`}>
                      {i < checkoutStep ? '✓' : i+1}
                    </div>
                    <span className="text-xs font-medium hidden sm:block">{step}</span>
                  </div>
                  {i < 2 && <div className={`flex-1 h-px ${i < checkoutStep ? 'bg-blue-500' : 'bg-white/10'}`} />}
                </div>
              ))}
            </div>

            {/* Step 0: Address */}
            {checkoutStep === 0 && (
              <div className={`${GLASS} p-6`}>
                <h3 className="font-bold text-white mb-4">Delivery Address</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">Full Name *</label>
                    <input value={address.fullName} onChange={e => setA('fullName', e.target.value)} placeholder="Your name" className={INP} />
                  </div>
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">Phone Number *</label>
                    <input value={address.phone} onChange={e => setA('phone', e.target.value)} placeholder="10-digit mobile" maxLength={10} className={INP} />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="text-xs text-white/40 mb-1 block">Address Line 1 *</label>
                    <input value={address.addressLine1} onChange={e => setA('addressLine1', e.target.value)} placeholder="House/Flat no., Street, Colony" className={INP} />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="text-xs text-white/40 mb-1 block">Address Line 2</label>
                    <input value={address.addressLine2} onChange={e => setA('addressLine2', e.target.value)} placeholder="Area, Locality (optional)" className={INP} />
                  </div>
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">City *</label>
                    <input value={address.city} onChange={e => setA('city', e.target.value)} placeholder="City" className={INP} />
                  </div>
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">State *</label>
                    <select value={address.state} onChange={e => setA('state', e.target.value)} className={SEL}>
                      <option value="">Select State</option>
                      {['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Delhi','Jammu & Kashmir','Ladakh'].map(s => <option key={s}>{s}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">Pincode *</label>
                    <input value={address.pincode} onChange={e => setA('pincode', e.target.value)} placeholder="6-digit pincode" maxLength={6} className={INP} />
                  </div>
                  <div>
                    <label className="text-xs text-white/40 mb-1 block">Landmark</label>
                    <input value={address.landmark} onChange={e => setA('landmark', e.target.value)} placeholder="Near landmark (optional)" className={INP} />
                  </div>
                </div>
                <button onClick={() => {
                  if (!address.fullName || !address.phone || !address.addressLine1 || !address.city || !address.state || !address.pincode) {
                    showToast('Please fill all required fields', 'error'); return;
                  }
                  if (!address.phone.match(/^[6-9]\d{9}$/)) { showToast('Invalid phone number', 'error'); return; }
                  setCheckoutStep(1);
                }} className={`${BTN_P} w-full mt-5 py-4`}>Continue to Payment →</button>
              </div>
            )}

            {/* Step 1: Payment */}
            {checkoutStep === 1 && (
              <div className={`${GLASS} p-6`}>
                <h3 className="font-bold text-white mb-4">Select Payment Method</h3>
                <div className="space-y-3 mb-5">
                  {[
                    { id: 'COD', label: 'Cash on Delivery', desc: 'Pay when your order arrives', icon: '💵' },
                    { id: 'UPI', label: 'UPI Payment', desc: 'GPay, PhonePe, Paytm, BHIM', icon: '📱' },
                  ].map(pm => (
                    <div key={pm.id} onClick={() => setPayMethod(pm.id)}
                      className={`flex items-center gap-4 p-4 rounded-xl border cursor-pointer transition-all ${payMethod === pm.id ? 'border-blue-500/60 bg-blue-500/10' : 'border-white/10 bg-white/3 hover:bg-white/5'}`}>
                      <span className="text-2xl">{pm.icon}</span>
                      <div className="flex-1">
                        <p className="text-white font-semibold text-sm">{pm.label}</p>
                        <p className="text-white/40 text-xs">{pm.desc}</p>
                      </div>
                      <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${payMethod === pm.id ? 'border-blue-400 bg-blue-500' : 'border-white/20'}`}>
                        {payMethod === pm.id && <div className="w-2 h-2 rounded-full bg-white" />}
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mb-4">
                  <label className="text-xs text-white/40 mb-1 block">Order Notes (optional)</label>
                  <textarea value={buyerNotes} onChange={e => setBuyerNotes(e.target.value)} rows={2} placeholder="Any special instructions..." className={`${INP} resize-none`} />
                </div>
                <div className="flex gap-3">
                  <button onClick={() => setCheckoutStep(0)} className={`${BTN_S} flex-1`}>← Back</button>
                  <button onClick={() => setCheckoutStep(2)} className={`${BTN_P} flex-1`}>Review Order →</button>
                </div>
              </div>
            )}

            {/* Step 2: Review & Confirm */}
            {checkoutStep === 2 && (
              <div className="space-y-4">
                {/* Order summary */}
                <div className={`${GLASS} p-5`}>
                  <p className="font-bold text-white mb-3">Order Summary</p>
                  {cart.items?.map((item: any, i: number) => (
                    <div key={i} className="flex justify-between items-center py-2 border-b border-white/5 text-sm">
                      <span className="text-white/70">{item.product.name} × {item.quantity}</span>
                      <span className="text-white font-semibold">{fmtPrice(item.product.price * item.quantity)}</span>
                    </div>
                  ))}
                  <div className="mt-3 space-y-1 text-sm">
                    <div className="flex justify-between text-white/50"><span>Subtotal</span><span>{fmtPrice(cart.subtotal)}</span></div>
                    <div className="flex justify-between text-white/50"><span>Delivery</span><span>{cart.deliveryCharge > 0 ? fmtPrice(cart.deliveryCharge) : 'Free'}</span></div>
                    {cart.couponDiscount > 0 && <div className="flex justify-between text-green-400"><span>Coupon</span><span>-{fmtPrice(cart.couponDiscount)}</span></div>}
                    <div className="flex justify-between font-black text-white text-lg border-t border-white/10 pt-2"><span>Total</span><span>{fmtPrice(cart.total)}</span></div>
                  </div>
                </div>
                {/* Address review */}
                <div className={`${GLASS} p-4`}>
                  <p className="text-xs text-white/40 mb-2 font-medium uppercase tracking-wider">Delivering to</p>
                  <p className="text-white font-semibold">{address.fullName} • {address.phone}</p>
                  <p className="text-white/50 text-sm">{address.addressLine1}, {address.addressLine2}</p>
                  <p className="text-white/50 text-sm">{address.city}, {address.state} — {address.pincode}</p>
                </div>
                {/* Payment review */}
                <div className={`${GLASS} p-4`}>
                  <p className="text-xs text-white/40 mb-2 font-medium uppercase tracking-wider">Payment</p>
                  <p className="text-white font-semibold">{payMethod === 'COD' ? '💵 Cash on Delivery' : '📱 UPI Payment'}</p>
                </div>
                <div className="flex gap-3">
                  <button onClick={() => setCheckoutStep(1)} className={`${BTN_S} flex-1`}>← Back</button>
                  <button onClick={placeOrder} disabled={placing} className={`${BTN_P} flex-1 py-4 disabled:opacity-50`}>
                    {placing ? '⏳ Placing...' : `🎉 Place Order — ${fmtPrice(cart.total)}`}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ══════════════════════════════════════════
            ORDERS VIEW
        ══════════════════════════════════════════ */}
        {view === 'orders' && !selectedOrder && (
          <div className="max-w-2xl mx-auto">
            <h2 className="text-2xl font-black text-white mb-6" style={{ fontFamily: "'Playfair Display', serif" }}>📦 My Orders</h2>
            {orders.length === 0 ? (
              <div className={`${GLASS} p-16 text-center`}>
                <div className="text-6xl mb-4">📦</div>
                <p className="text-white/50 text-lg font-medium">No orders yet</p>
                <button onClick={() => setView('store')} className={`${BTN_P} mt-5`}>Start Shopping</button>
              </div>
            ) : (
              <div className="space-y-4">
                {orders.map((order: any) => {
                  const step = STATUS_STEPS[order.status];
                  const isCancelled = ['cancelled','return_requested','returned','refunded'].includes(order.status);
                  return (
                    <div key={order._id} className={`${GLASS} p-5 cursor-pointer hover:border-blue-500/30 transition-all`} onClick={() => setSelectedOrder(order)}>
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <p className="font-mono text-blue-300 text-sm font-bold">{order.orderId}</p>
                          <p className="text-white/40 text-xs">{fmtDate(order.createdAt)} • {order.items?.length} item{order.items?.length !== 1 ? 's' : ''}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-white font-black">{fmtPrice(order.pricing?.total || 0)}</p>
                          <span className={`text-xs px-2 py-0.5 rounded-full ${isCancelled ? 'bg-red-500/20 text-red-300' : 'bg-blue-500/20 text-blue-300'}`}>{STATUS_LABEL[order.status] || order.status}</span>
                        </div>
                      </div>
                      {!isCancelled && (
                        <div className="flex items-center gap-0 mb-2">
                          {['pending','confirmed','packed','shipped','out_for_delivery','delivered'].map((s, i) => (
                            <div key={s} className="flex items-center flex-1">
                              <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${i <= (step ?? -1) ? 'bg-blue-500' : 'bg-white/15'}`} />
                              {i < 5 && <div className={`h-0.5 flex-1 ${i < (step ?? -1) ? 'bg-blue-500' : 'bg-white/10'}`} />}
                            </div>
                          ))}
                        </div>
                      )}
                      <p className="text-white/50 text-xs mt-1 line-clamp-1">
                        {order.items?.map((i: any) => i.name).join(', ')}
                      </p>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Order Detail */}
        {view === 'orders' && selectedOrder && (
          <div className="max-w-2xl mx-auto">
            <div className="flex items-center gap-3 mb-6">
              <button onClick={() => setSelectedOrder(null)} className="w-9 h-9 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center">
                <svg width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
              </button>
              <div>
                <h2 className="text-xl font-black text-white">Order {selectedOrder.orderId}</h2>
                <p className="text-white/40 text-xs">{fmtDate(selectedOrder.createdAt)}</p>
              </div>
            </div>

            {/* Tracking timeline */}
            {!['cancelled','returned','refunded'].includes(selectedOrder.status) && (
              <div className={`${GLASS} p-5 mb-4`}>
                <p className="text-xs text-white/40 font-semibold mb-4 uppercase tracking-wider">Order Tracking</p>
                <div className="relative">
                  <div className="absolute left-3 top-0 bottom-0 w-px bg-white/10" />
                  {['Order Placed','Confirmed','Packed','Shipped','Out for Delivery','Delivered'].map((label, i) => {
                    const step = STATUS_STEPS[selectedOrder.status] ?? -1;
                    const done  = i <= step;
                    const curr  = i === step;
                    return (
                      <div key={i} className="flex items-start gap-4 mb-4 last:mb-0 relative">
                        <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center text-xs flex-shrink-0 z-10 ${done ? 'bg-blue-600 border-blue-600 text-white' : 'bg-[#060d1f] border-white/20 text-white/20'}`}>
                          {done ? '✓' : ''}
                        </div>
                        <div>
                          <p className={`text-sm font-medium ${done ? 'text-white' : 'text-white/30'}`}>{label}</p>
                          {curr && selectedOrder.trackingNumber && (
                            <p className="text-xs text-blue-400 mt-0.5">Tracking: {selectedOrder.trackingNumber} {selectedOrder.courierName && `(${selectedOrder.courierName})`}</p>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Items */}
            <div className={`${GLASS} p-5 mb-4`}>
              <p className="text-xs text-white/40 mb-3 font-semibold uppercase tracking-wider">Items Ordered</p>
              {selectedOrder.items?.map((item: any, i: number) => (
                <div key={i} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                  {item.image ? <img src={item.image} alt={item.name} className="w-12 h-14 object-cover rounded-xl" /> : <div className="w-12 h-14 rounded-xl bg-white/5 flex items-center justify-center">📚</div>}
                  <div className="flex-1">
                    <p className="text-white text-sm font-medium">{item.name}</p>
                    <p className="text-white/40 text-xs">Qty: {item.quantity} × {fmtPrice(item.price)}</p>
                  </div>
                  <p className="text-white font-semibold">{fmtPrice(item.price * item.quantity)}</p>
                </div>
              ))}
              <div className="mt-3 pt-2 border-t border-white/10 flex justify-between">
                <span className="text-white/50 text-sm">Total</span>
                <span className="text-white font-black">{fmtPrice(selectedOrder.pricing?.total || 0)}</span>
              </div>
            </div>

            {/* Address + Payment */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
              <div className={`${GLASS} p-4`}>
                <p className="text-xs text-white/40 mb-2 font-semibold uppercase tracking-wider">Delivery Address</p>
                <p className="text-white text-sm font-medium">{selectedOrder.shippingAddress?.fullName}</p>
                <p className="text-white/50 text-xs">{selectedOrder.shippingAddress?.phone}</p>
                <p className="text-white/50 text-xs mt-1">{selectedOrder.shippingAddress?.addressLine1}</p>
                <p className="text-white/50 text-xs">{selectedOrder.shippingAddress?.city}, {selectedOrder.shippingAddress?.state} — {selectedOrder.shippingAddress?.pincode}</p>
              </div>
              <div className={`${GLASS} p-4`}>
                <p className="text-xs text-white/40 mb-2 font-semibold uppercase tracking-wider">Payment</p>
                <p className="text-white text-sm font-medium">{selectedOrder.payment?.method}</p>
                <p className={`text-xs font-semibold mt-1 ${selectedOrder.payment?.status === 'paid' ? 'text-green-400' : selectedOrder.payment?.status === 'pending' ? 'text-yellow-400' : 'text-red-400'}`}>{selectedOrder.payment?.status}</p>
              </div>
            </div>

            {/* Cancel button */}
            {['pending','confirmed'].includes(selectedOrder.status) && (
              <button onClick={() => { if (confirm('Cancel this order?')) cancelOrder(selectedOrder._id, 'Cancelled by student'); }}
                className="w-full py-3 rounded-xl border border-red-500/30 text-red-400 hover:bg-red-500/10 transition-all text-sm font-semibold">
                Cancel Order
              </button>
            )}
          </div>
        )}

        {/* ══════════════════════════════════════════
            WISHLIST VIEW
        ══════════════════════════════════════════ */}
        {view === 'wishlist' && (
          <div className="max-w-4xl mx-auto">
            <h2 className="text-2xl font-black text-white mb-6" style={{ fontFamily: "'Playfair Display', serif" }}>❤️ Wishlist</h2>
            {wishlist.length === 0 ? (
              <div className={`${GLASS} p-16 text-center`}>
                <div className="text-6xl mb-4">🤍</div>
                <p className="text-white/50 text-lg font-medium">Your wishlist is empty</p>
                <button onClick={() => setView('store')} className={`${BTN_P} mt-5`}>Browse Store</button>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
                {wishlist.map(p => (
                  <ProductCard key={p._id} product={p} onView={viewProduct} onAddToCart={addToCart} onWishlist={toggleWishlist} wishlistIds={wishlistIds} />
                ))}
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ Student Store page.tsx created"

# ─────────────────────────────────────────
# PATCH: Add Store to StudentShell nav
# ─────────────────────────────────────────
node << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');

// Find StudentShell file
const candidates = [
  'frontend/app/dashboard/StudentShell.tsx',
  'frontend/app/dashboard/layout.tsx',
  'frontend/components/StudentShell.tsx',
  'frontend/components/layouts/StudentShell.tsx',
  'frontend/app/dashboard/StudentLayout.tsx',
];
let shellFile = null;
for (const c of candidates) {
  const p = path.join(process.env.HOME, 'workspace', c);
  if (fs.existsSync(p)) { shellFile = p; break; }
}
if (!shellFile) {
  // Search recursively for a file with 'StudentShell' in name
  const { execSync } = require('child_process');
  try {
    const result = execSync('find ' + path.join(process.env.HOME, 'workspace/frontend') + ' -name "*Shell*" -o -name "*shell*" 2>/dev/null | head -5').toString().trim();
    if (result) shellFile = result.split('\n')[0];
  } catch {}
}
if (!shellFile) {
  console.log('⚠️  StudentShell file not found. Manually add to nav:');
  console.log('   { href: "/dashboard/store", label: "Store", icon: "🛒" }');
  process.exit(0);
}

let content = fs.readFileSync(shellFile, 'utf-8');
console.log('Found StudentShell at:', shellFile);

const storeNavLink = `{ href: '/dashboard/store', label: 'Store', icon: '🛒' }`;
const storeNavLink2 = `{ href: "/dashboard/store", label: "Store", icon: "🛒" }`;
const storeNavLabel = `Store`;

if (content.includes('/dashboard/store')) {
  console.log('ℹ️  Store nav already present');
  process.exit(0);
}

// Try various nav patterns
const patterns = [
  // Pattern: { href: '/dashboard/results' or similar
  { search: "href: '/dashboard/results'",  replace: `href: '/dashboard/store', label: 'Store', icon: '🛒' },\n          { href: '/dashboard/results'` },
  { search: 'href: "/dashboard/results"',  replace: `href: "/dashboard/store", label: "Store", icon: "🛒" },\n          { href: "/dashboard/results"` },
  // Pattern: add before logout or profile or settings
  { search: "href: '/dashboard/profile'",  replace: `href: '/dashboard/store', label: 'Store', icon: '🛒' },\n          { href: '/dashboard/profile'` },
  { search: 'href: "/dashboard/profile"',  replace: `href: "/dashboard/store", label: "Store", icon: "🛒" },\n          { href: "/dashboard/profile"` },
  // Pattern: add before settings
  { search: "href: '/dashboard/settings'", replace: `href: '/dashboard/store', label: 'Store', icon: '🛒' },\n          { href: '/dashboard/settings'` },
  { search: 'href: "/dashboard/settings"', replace: `href: "/dashboard/store", label: "Store", icon: "🛒" },\n          { href: "/dashboard/settings"` },
];

let patched = false;
for (const p of patterns) {
  if (content.includes(p.search)) {
    content = content.replace(p.search, p.replace);
    patched = true;
    console.log('✅ Store nav link inserted before:', p.search);
    break;
  }
}

if (!patched) {
  // Fallback: look for any href: '/dashboard/' pattern and add before the last one
  const regex = /(href:\s*['"]\/dashboard\/[^'"]+['"]\s*,?\s*label:\s*['"][^'"]+['"])/g;
  const matches = [...content.matchAll(regex)];
  if (matches.length) {
    const lastMatch = matches[matches.length - 1];
    const insertPos = lastMatch.index;
    const newNavItem = `href: '/dashboard/store', label: 'Store', icon: '🛒' },\n          { `;
    content = content.slice(0, insertPos) + newNavItem + content.slice(insertPos);
    patched = true;
    console.log('✅ Store nav link inserted (regex fallback)');
  }
}

if (patched) {
  fs.writeFileSync(shellFile, content);
  console.log('✅ StudentShell patched successfully');
} else {
  console.log('⚠️  Could not auto-patch. Add manually to nav array:');
  console.log('   { href: "/dashboard/store", label: "Store", icon: "🛒" }');
}
ENDOFFILE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅  STUDENT STORE PAGE SETUP COMPLETE!"
echo ""
echo "📄 Files Created:"
echo "   frontend/app/dashboard/store/page.tsx"
echo ""
echo "🔧 StudentShell patched to include Store nav"
echo ""
echo "🎨 Student Store Features:"
echo "   ✓ Hero banner with NEET-focused copy"
echo "   ✓ Featured products carousel"
echo "   ✓ Search + Category/Subject/Class filters"
echo "   ✓ Sort by price/rating/newest/popular"
echo "   ✓ Product cards with wishlist, add-to-cart"
echo "   ✓ Product detail page with reviews"
echo "   ✓ Cart with coupon support"
echo "   ✓ 3-step checkout (Address→Payment→Confirm)"
echo "   ✓ Order tracking with visual timeline"
echo "   ✓ My Orders + Order detail"
echo "   ✓ Wishlist management"
echo "   ✓ Write & view product reviews"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
