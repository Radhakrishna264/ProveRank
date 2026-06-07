'use client';
import { useState, useEffect, useCallback } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com';

// ── Helpers ──────────────────────────────────────
const tok = () => (typeof window !== 'undefined' ? localStorage.getItem('pr_token') || '' : '');
const hdr = () => ({ 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}` });
const fmtPrice = (n: number) => '₹' + n.toLocaleString('en-IN');
const fmtDate  = (d: string | Date) => new Date(d).toLocaleDateString('en-IN', { day:'numeric', month:'short', year:'numeric' });

const STATUS_COLORS: Record<string, string> = {
  pending: 'bg-yellow-500/20 text-yellow-300 border border-yellow-500/30',
  confirmed: 'bg-blue-500/20 text-blue-300 border border-blue-500/30',
  packed: 'bg-purple-500/20 text-purple-300 border border-purple-500/30',
  shipped: 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30',
  out_for_delivery: 'bg-orange-500/20 text-orange-300 border border-orange-500/30',
  delivered: 'bg-green-500/20 text-green-300 border border-green-500/30',
  cancelled: 'bg-red-500/20 text-red-300 border border-red-500/30',
  return_requested: 'bg-pink-500/20 text-pink-300 border border-pink-500/30',
  returned: 'bg-gray-500/20 text-gray-300 border border-gray-500/30',
  refunded: 'bg-teal-500/20 text-teal-300 border border-teal-500/30',
};

const GLASS = 'bg-white/5 border border-white/10 backdrop-blur-sm rounded-2xl';
const BTN   = 'px-4 py-2 rounded-xl font-semibold text-sm transition-all duration-200';
const INP   = 'w-full bg-white/5 border border-white/15 rounded-xl px-4 py-3 text-white placeholder-white/30 focus:outline-none focus:border-blue-400 text-sm';
const SEL   = 'w-full bg-[#0a0f1e] border border-white/15 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-blue-400 text-sm';

// ── Toast ────────────────────────────────────────
function Toast({ msg, type, onClose }: { msg: string; type: 'success'|'error'|'info'; onClose: () => void }) {
  useEffect(() => { const t = setTimeout(onClose, 3500); return () => clearTimeout(t); }, [onClose]);
  const bg = type === 'success' ? 'bg-green-500' : type === 'error' ? 'bg-red-500' : 'bg-blue-500';
  return (
    <div className={`fixed top-6 right-6 z-[9999] flex items-center gap-3 ${bg} text-white px-5 py-3 rounded-2xl shadow-2xl animate-bounce`} style={{ animationDuration: '0.3s', animationIterationCount: 1 }}>
      <span>{type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}</span>
      <span className="text-sm font-medium">{msg}</span>
      <button onClick={onClose} className="ml-2 opacity-70 hover:opacity-100">×</button>
    </div>
  );
}

// ══════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════
export default function StoreAdminTab() {
  const [view, setView]     = useState<'dashboard'|'products'|'orders'|'coupons'|'inventory'|'reviews'>('dashboard');
  const [toast, setToast]   = useState<{ msg: string; type: 'success'|'error'|'info' } | null>(null);
  const showToast = (msg: string, type: 'success'|'error'|'info' = 'success') => setToast({ msg, type });

  return (
    <div className="min-h-screen text-white p-4 lg:p-6" style={{ background: 'transparent' }}>
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* ── Header ── */}
      <div className={`${GLASS} p-5 mb-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4`}>
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl" style={{ background: 'linear-gradient(135deg, #1d4ed8, #0ea5e9)' }}>🛒</div>
          <div>
            <h1 className="text-2xl font-bold text-white tracking-tight">ProveRank Store</h1>
            <p className="text-white/50 text-sm">Physical Study Material Management</p>
          </div>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {(['dashboard','products','orders','coupons','inventory','reviews'] as const).map(v => (
            <button key={v} onClick={() => setView(v)}
              className={`${BTN} capitalize ${view === v ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/20' : 'bg-white/5 text-white/60 hover:bg-white/10 border border-white/10'}`}>
              {v === 'dashboard' ? '📊' : v === 'products' ? '📦' : v === 'orders' ? '🚚' : v === 'coupons' ? '🎟️' : v === 'inventory' ? '🗄️' : '⭐'} {v}
            </button>
          ))}
        </div>
      </div>

      {/* ── Views ── */}
      {view === 'dashboard'  && <StoreDashboard showToast={showToast} />}
      {view === 'products'   && <ProductsManager showToast={showToast} />}
      {view === 'orders'     && <OrdersManager showToast={showToast} />}
      {view === 'coupons'    && <CouponsManager showToast={showToast} />}
      {view === 'inventory'  && <InventoryView showToast={showToast} />}
      {view === 'reviews'    && <ReviewsManager showToast={showToast} />}
    </div>
  );
}

// ══════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════
function StoreDashboard({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [data, setData]       = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState(false);

  useEffect(() => {
    fetch(`${API}/api/admin/store/analytics`, { headers: hdr() })
      .then(r => r.json()).then(setData).catch(() => showToast('Failed to load analytics', 'error'))
      .finally(() => setLoading(false));
  }, []);

  const seedProducts = async () => {
    setSeeding(true);
    try {
      const r = await fetch(`${API}/api/admin/store/seed`, { method: 'POST', headers: hdr(), body: JSON.stringify({}) });
      const d = await r.json();
      showToast(d.message, r.ok ? 'success' : 'error');
    } catch { showToast('Seed failed', 'error'); }
    setSeeding(false);
  };

  if (loading) return <div className="flex items-center justify-center h-64"><div className="w-10 h-10 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" /></div>;

  const ov = data?.overview || {};
  const stats = [
    { label: 'Total Products', value: ov.totalProducts || 0, sub: `${ov.activeProducts || 0} active`, icon: '📦', color: '#3b82f6' },
    { label: 'Total Orders',   value: ov.totalOrders || 0,   sub: `${ov.pendingOrders || 0} pending`, icon: '🚚', color: '#8b5cf6' },
    { label: 'Revenue (Paid)', value: fmtPrice(ov.totalRevenue || 0), sub: `${ov.deliveredOrders || 0} delivered`, icon: '💰', color: '#10b981' },
    { label: 'Out of Stock',   value: ov.outOfStock || 0, sub: 'products', icon: '⚠️', color: '#f59e0b' },
  ];

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s, i) => (
          <div key={i} className={`${GLASS} p-5`}>
            <div className="flex items-center justify-between mb-3">
              <span className="text-2xl">{s.icon}</span>
              <span className="text-xs text-white/40 font-medium uppercase tracking-wider">{s.label}</span>
            </div>
            <p className="text-2xl font-bold text-white mb-1">{s.value}</p>
            <p className="text-xs text-white/40">{s.sub}</p>
          </div>
        ))}
      </div>

      {/* Revenue Chart (30 days) */}
      <div className={`${GLASS} p-6`}>
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-white">Revenue — Last 30 Days</h3>
          <span className="text-xs text-white/40">Daily breakdown</span>
        </div>
        {data?.revenue30d?.length ? (
          <div className="flex items-end gap-1 h-32 overflow-x-auto">
            {data.revenue30d.map((d: any, i: number) => {
              const maxRev = Math.max(...data.revenue30d.map((x: any) => x.revenue));
              const h = maxRev ? Math.max(4, (d.revenue / maxRev) * 100) : 4;
              return (
                <div key={i} className="flex flex-col items-center gap-1 min-w-[20px] group">
                  <div className="relative">
                    <div className="w-4 rounded-t-sm bg-blue-500 transition-all" style={{ height: `${h}%`, minHeight: 4 }} />
                    <div className="absolute bottom-full mb-1 left-1/2 -translate-x-1/2 bg-black text-white text-xs px-2 py-1 rounded hidden group-hover:block whitespace-nowrap z-10">
                      {d._id}<br />₹{d.revenue} • {d.orders} orders
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : <p className="text-white/30 text-center py-8">No revenue data yet — seed products and create test orders</p>}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Products */}
        <div className={`${GLASS} p-5`}>
          <h3 className="text-base font-bold text-white mb-4">🏆 Top Selling Products</h3>
          {data?.topProducts?.length ? data.topProducts.map((p: any, i: number) => (
            <div key={i} className="flex items-center gap-3 py-3 border-b border-white/5 last:border-0">
              <span className="text-xl font-black text-white/20 w-6">{i+1}</span>
              {p.image && <img src={p.image} alt={p.name} className="w-10 h-10 rounded-lg object-cover" />}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-white truncate">{p.name}</p>
                <p className="text-xs text-white/40">{p.totalSold} sold • {fmtPrice(p.revenue)}</p>
              </div>
            </div>
          )) : <p className="text-white/30 text-sm text-center py-6">No sales data yet</p>}
        </div>

        {/* Orders by Status */}
        <div className={`${GLASS} p-5`}>
          <h3 className="text-base font-bold text-white mb-4">📊 Orders by Status</h3>
          {data?.ordersByStatus?.length ? data.ordersByStatus.map((s: any, i: number) => (
            <div key={i} className="flex items-center justify-between py-2">
              <span className={`px-3 py-1 rounded-full text-xs font-semibold ${STATUS_COLORS[s._id] || 'bg-white/10 text-white/60'}`}>{s._id}</span>
              <span className="text-white font-bold">{s.count}</span>
            </div>
          )) : <p className="text-white/30 text-sm text-center py-6">No orders yet</p>}
        </div>
      </div>

      {/* Low Stock Alert */}
      {data?.lowStockProducts?.length > 0 && (
        <div className={`${GLASS} p-5 border-yellow-500/30`}>
          <h3 className="text-base font-bold text-yellow-300 mb-3">⚠️ Low Stock Alert</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {data.lowStockProducts.map((p: any, i: number) => (
              <div key={i} className="flex items-center justify-between bg-yellow-500/10 rounded-xl px-4 py-2">
                <span className="text-sm text-white">{p.name}</span>
                <span className="text-yellow-300 font-bold">{p.stock} left</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recent Orders */}
      <div className={`${GLASS} p-5`}>
        <h3 className="text-base font-bold text-white mb-4">🕐 Recent Orders</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-white/40 text-xs border-b border-white/10">
                <th className="text-left pb-3 font-medium">Order ID</th>
                <th className="text-left pb-3 font-medium">Student</th>
                <th className="text-left pb-3 font-medium">Amount</th>
                <th className="text-left pb-3 font-medium">Status</th>
                <th className="text-left pb-3 font-medium">Date</th>
              </tr>
            </thead>
            <tbody>
              {data?.recentOrders?.length ? data.recentOrders.map((o: any, i: number) => (
                <tr key={i} className="border-b border-white/5 hover:bg-white/3 transition-colors">
                  <td className="py-3 font-mono text-blue-300 text-xs">{o.orderId}</td>
                  <td className="py-3 text-white/80">{o.student?.name || 'Unknown'}</td>
                  <td className="py-3 text-green-300 font-semibold">{fmtPrice(o.pricing?.total || 0)}</td>
                  <td className="py-3"><span className={`px-2 py-1 rounded-full text-xs ${STATUS_COLORS[o.status] || ''}`}>{o.status}</span></td>
                  <td className="py-3 text-white/40 text-xs">{fmtDate(o.createdAt)}</td>
                </tr>
              )) : (
                <tr><td colSpan={5} className="text-center py-8 text-white/30">No orders yet</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Seed Button */}
      <div className={`${GLASS} p-5`}>
        <h3 className="text-base font-bold text-white mb-2">🌱 Seed Initial Products</h3>
        <p className="text-white/40 text-sm mb-4">Add the 2 default NCERT books (Biology + Physics Class 11) to the store.</p>
        <button onClick={seedProducts} disabled={seeding} className={`${BTN} bg-green-600 hover:bg-green-500 text-white disabled:opacity-50`}>
          {seeding ? 'Seeding...' : '🌱 Seed NCERT Books'}
        </button>
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════
// PRODUCTS MANAGER
// ══════════════════════════════════════════════════
function ProductsManager({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading]   = useState(true);
  const [total, setTotal]       = useState(0);
  const [page, setPage]         = useState(1);
  const [search, setSearch]     = useState('');
  const [catFilter, setCatFilter] = useState('');
  const [editing, setEditing]   = useState<any>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<any>({
    name:'', description:'', shortDescription:'', category:'Books', subject:'Biology',
    classLevel:'Class 11', examType:'NEET', price:'', originalPrice:'', stock:'',
    author:'NCERT', publisher:'NCERT', edition:'2024 Edition', language:'English',
    pages:'', weight:'', isbn:'', deliveryTime:'3-5 business days',
    returnPolicy:'7 days return policy', deliveryCharge:'49', freeDeliveryAbove:'499',
    isFeatured:false, isNew:true, isBestSeller:false,
    images: [{ url:'', alt:'', isPrimary:true }],
    features:[''], tags:''
  });

  const loadProducts = useCallback(() => {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), limit:'12', ...(search && { search }), ...(catFilter && { category: catFilter }) });
    fetch(`${API}/api/admin/store/products?${params}`, { headers: hdr() })
      .then(r => r.json()).then(d => { setProducts(d.products || []); setTotal(d.total || 0); })
      .catch(() => showToast('Failed to load products', 'error'))
      .finally(() => setLoading(false));
  }, [page, search, catFilter]);

  useEffect(() => { loadProducts(); }, [loadProducts]);

  const openCreate = () => {
    setEditing(null);
    setForm({
      name:'', description:'', shortDescription:'', category:'Books', subject:'Biology',
      classLevel:'Class 11', examType:'NEET', price:'', originalPrice:'', stock:'',
      author:'NCERT', publisher:'NCERT', edition:'2024 Edition', language:'English',
      pages:'', weight:'', isbn:'', deliveryTime:'3-5 business days',
      returnPolicy:'7 days return policy', deliveryCharge:'49', freeDeliveryAbove:'499',
      isFeatured:false, isNew:true, isBestSeller:false,
      images: [{ url:'', alt:'', isPrimary:true }], features:[''], tags:''
    });
    setShowForm(true);
  };

  const openEdit = (p: any) => {
    setEditing(p);
    setForm({
      ...p,
      tags: p.tags?.join(', ') || '',
      features: p.features?.length ? p.features : [''],
      images: p.images?.length ? p.images : [{ url:'', alt:'', isPrimary:true }]
    });
    setShowForm(true);
  };

  const saveProduct = async () => {
    const payload = {
      ...form,
      price: parseFloat(form.price), originalPrice: parseFloat(form.originalPrice),
      stock: parseInt(form.stock), pages: parseInt(form.pages) || undefined,
      weight: parseInt(form.weight) || undefined,
      deliveryCharge: parseFloat(form.deliveryCharge) || 49,
      freeDeliveryAbove: parseFloat(form.freeDeliveryAbove) || 499,
      tags: form.tags.split(',').map((t: string) => t.trim()).filter(Boolean),
      features: form.features.filter((f: string) => f.trim()),
      images: form.images.filter((img: any) => img.url)
    };
    const url    = editing ? `${API}/api/admin/store/products/${editing._id}` : `${API}/api/admin/store/products`;
    const method = editing ? 'PUT' : 'POST';
    try {
      const r = await fetch(url, { method, headers: hdr(), body: JSON.stringify(payload) });
      const d = await r.json();
      if (r.ok) { showToast(d.message); setShowForm(false); loadProducts(); }
      else showToast(d.message, 'error');
    } catch { showToast('Save failed', 'error'); }
  };

  const deleteProduct = async (id: string) => {
    if (!confirm('Delete this product?')) return;
    const r = await fetch(`${API}/api/admin/store/products/${id}`, { method: 'DELETE', headers: hdr() });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) loadProducts();
  };

  const toggleField = async (id: string, field: string) => {
    await fetch(`${API}/api/admin/store/products/${id}/toggle`, { method: 'PATCH', headers: hdr(), body: JSON.stringify({ field }) });
    loadProducts();
  };

  const setF = (k: string, v: any) => setForm((prev: any) => ({ ...prev, [k]: v }));
  const setFeature = (i: number, v: string) => {
    const f = [...form.features]; f[i] = v;
    setForm((prev: any) => ({ ...prev, features: f }));
  };
  const setImage = (i: number, k: string, v: string) => {
    const imgs = [...form.images]; imgs[i] = { ...imgs[i], [k]: v };
    setForm((prev: any) => ({ ...prev, images: imgs }));
  };

  const discountPercent = form.originalPrice && form.price
    ? Math.round(((parseFloat(form.originalPrice) - parseFloat(form.price)) / parseFloat(form.originalPrice)) * 100) : 0;

  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className={`${GLASS} p-4 flex flex-col sm:flex-row gap-3 items-start sm:items-center justify-between`}>
        <div className="flex gap-2 flex-1 flex-wrap">
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search products..." className={`${INP} flex-1 min-w-48`} />
          <select value={catFilter} onChange={e => setCatFilter(e.target.value)} className={SEL} style={{ width:'auto' }}>
            <option value="">All Categories</option>
            {['Books','Notes','Stationery','Lab Equipment','Combo Pack','Digital','Other'].map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <button onClick={openCreate} className={`${BTN} bg-blue-600 hover:bg-blue-500 text-white whitespace-nowrap`}>+ Add Product</button>
      </div>

      <p className="text-white/40 text-sm">{total} products found</p>

      {/* Product Grid */}
      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" /></div>
      ) : products.length === 0 ? (
        <div className={`${GLASS} p-12 text-center`}>
          <p className="text-4xl mb-3">📦</p>
          <p className="text-white/50">No products found. Add your first product!</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {products.map(p => (
            <div key={p._id} className={`${GLASS} overflow-hidden group`}>
              <div className="relative">
                {p.images?.[0]?.url ? (
                  <img src={p.images[0].url} alt={p.name} className="w-full h-40 object-cover" />
                ) : (
                  <div className="w-full h-40 bg-white/5 flex items-center justify-center text-4xl">📚</div>
                )}
                <div className="absolute top-2 left-2 flex gap-1 flex-wrap">
                  {p.isFeatured   && <span className="bg-yellow-500 text-black text-xs px-2 py-0.5 rounded-full font-bold">⭐ Featured</span>}
                  {p.isBestSeller && <span className="bg-orange-500 text-white text-xs px-2 py-0.5 rounded-full font-bold">🔥 Best</span>}
                  {p.isNew        && <span className="bg-green-500 text-white text-xs px-2 py-0.5 rounded-full font-bold">✨ New</span>}
                </div>
                {p.discountPercent > 0 && (
                  <div className="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded-full font-bold">{p.discountPercent}% OFF</div>
                )}
              </div>
              <div className="p-4">
                <p className="font-semibold text-white text-sm mb-1 line-clamp-1">{p.name}</p>
                <p className="text-xs text-white/40 mb-2">{p.category} • {p.subject} • {p.classLevel}</p>
                <div className="flex items-center gap-2 mb-3">
                  <span className="text-green-300 font-bold">{fmtPrice(p.price)}</span>
                  {p.originalPrice > p.price && <span className="text-white/30 line-through text-xs">{fmtPrice(p.originalPrice)}</span>}
                </div>
                <div className="flex items-center justify-between mb-3">
                  <span className={`text-xs px-2 py-1 rounded-full ${p.stock > 10 ? 'bg-green-500/20 text-green-300' : p.stock > 0 ? 'bg-yellow-500/20 text-yellow-300' : 'bg-red-500/20 text-red-300'}`}>
                    {p.stock > 0 ? `${p.stock} in stock` : 'Out of stock'}
                  </span>
                  <span className={`text-xs px-2 py-1 rounded-full ${p.isActive ? 'bg-blue-500/20 text-blue-300' : 'bg-gray-500/20 text-gray-300'}`}>{p.isActive ? 'Active' : 'Inactive'}</span>
                </div>
                {/* Quick toggles */}
                <div className="flex gap-1 mb-3">
                  {['isFeatured','isNew','isBestSeller','isActive'].map(field => (
                    <button key={field} onClick={() => toggleField(p._id, field)}
                      className={`text-xs px-2 py-1 rounded-lg flex-1 border transition-colors ${p[field] ? 'bg-blue-600/30 border-blue-500/50 text-blue-300' : 'bg-white/5 border-white/10 text-white/30'}`}
                      title={`Toggle ${field}`}>
                      {field === 'isFeatured' ? '⭐' : field === 'isNew' ? '✨' : field === 'isBestSeller' ? '🔥' : '✓'}
                    </button>
                  ))}
                </div>
                <div className="flex gap-2">
                  <button onClick={() => openEdit(p)} className={`${BTN} bg-white/10 hover:bg-white/20 text-white flex-1 text-xs`}>Edit</button>
                  <button onClick={() => deleteProduct(p._id)} className={`${BTN} bg-red-500/20 hover:bg-red-500/40 text-red-300 flex-1 text-xs`}>Delete</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination */}
      {total > 12 && (
        <div className="flex justify-center gap-2">
          <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page===1} className={`${BTN} bg-white/5 text-white/60 disabled:opacity-30`}>← Prev</button>
          <span className="px-4 py-2 text-white/50 text-sm">{page} / {Math.ceil(total/12)}</span>
          <button onClick={() => setPage(p => p+1)} disabled={page>=Math.ceil(total/12)} className={`${BTN} bg-white/5 text-white/60 disabled:opacity-30`}>Next →</button>
        </div>
      )}

      {/* Product Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 overflow-y-auto p-4">
          <div className="max-w-3xl mx-auto" style={{ background: '#0a0f1e', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 24, padding: 24 }}>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-white">{editing ? 'Edit Product' : 'Add New Product'}</h2>
              <button onClick={() => setShowForm(false)} className="text-white/40 hover:text-white text-2xl">×</button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Product Name *</label>
                <input value={form.name} onChange={e => setF('name', e.target.value)} placeholder="e.g. NCERT Biology Class 11" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Category *</label>
                <select value={form.category} onChange={e => setF('category', e.target.value)} className={SEL}>
                  {['Books','Notes','Stationery','Lab Equipment','Combo Pack','Digital','Other'].map(c => <option key={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Subject</label>
                <select value={form.subject} onChange={e => setF('subject', e.target.value)} className={SEL}>
                  {['Physics','Chemistry','Biology','Mathematics','All Subjects','Other'].map(s => <option key={s}>{s}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Class Level</label>
                <select value={form.classLevel} onChange={e => setF('classLevel', e.target.value)} className={SEL}>
                  {['Class 11','Class 12','Both','All'].map(c => <option key={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Exam Type</label>
                <select value={form.examType} onChange={e => setF('examType', e.target.value)} className={SEL}>
                  {['NEET','JEE','Both','All'].map(e => <option key={e}>{e}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Sale Price (₹) *</label>
                <input type="number" value={form.price} onChange={e => setF('price', e.target.value)} placeholder="199" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Original Price (₹) *</label>
                <input type="number" value={form.originalPrice} onChange={e => setF('originalPrice', e.target.value)} placeholder="350" className={INP} />
              </div>
              {discountPercent > 0 && (
                <div className="sm:col-span-2">
                  <span className="text-green-300 text-sm font-semibold">✓ Discount: {discountPercent}% off</span>
                </div>
              )}
              <div>
                <label className="text-xs text-white/40 mb-1 block">Stock Quantity *</label>
                <input type="number" value={form.stock} onChange={e => setF('stock', e.target.value)} placeholder="100" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Delivery Charge (₹)</label>
                <input type="number" value={form.deliveryCharge} onChange={e => setF('deliveryCharge', e.target.value)} placeholder="49" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Free Delivery Above (₹)</label>
                <input type="number" value={form.freeDeliveryAbove} onChange={e => setF('freeDeliveryAbove', e.target.value)} placeholder="499" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Author</label>
                <input value={form.author} onChange={e => setF('author', e.target.value)} placeholder="NCERT" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Publisher</label>
                <input value={form.publisher} onChange={e => setF('publisher', e.target.value)} placeholder="NCERT" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Edition</label>
                <input value={form.edition} onChange={e => setF('edition', e.target.value)} placeholder="2024 Edition" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">ISBN</label>
                <input value={form.isbn} onChange={e => setF('isbn', e.target.value)} placeholder="978-..." className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Pages</label>
                <input type="number" value={form.pages} onChange={e => setF('pages', e.target.value)} placeholder="318" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Weight (grams)</label>
                <input type="number" value={form.weight} onChange={e => setF('weight', e.target.value)} placeholder="420" className={INP} />
              </div>
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Short Description</label>
                <input value={form.shortDescription} onChange={e => setF('shortDescription', e.target.value)} placeholder="Brief one-liner" className={INP} />
              </div>
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Full Description *</label>
                <textarea value={form.description} onChange={e => setF('description', e.target.value)} rows={3} placeholder="Detailed description..." className={`${INP} resize-none`} />
              </div>

              {/* Images */}
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-2 block">Product Images (URL)</label>
                {form.images.map((img: any, i: number) => (
                  <div key={i} className="flex gap-2 mb-2">
                    <input value={img.url} onChange={e => setImage(i, 'url', e.target.value)} placeholder="https://..." className={`${INP} flex-1`} />
                    <input value={img.alt} onChange={e => setImage(i, 'alt', e.target.value)} placeholder="Alt text" className={`${INP}`} style={{ width: 120 }} />
                  </div>
                ))}
                <button onClick={() => setForm((p: any) => ({ ...p, images: [...p.images, { url:'', alt:'' }] }))} className="text-xs text-blue-300 hover:text-blue-200">+ Add Image</button>
              </div>

              {/* Features */}
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-2 block">Key Features (bullet points)</label>
                {form.features.map((f: string, i: number) => (
                  <input key={i} value={f} onChange={e => setFeature(i, e.target.value)} placeholder={`Feature ${i+1}`} className={`${INP} mb-2`} />
                ))}
                <button onClick={() => setForm((p: any) => ({ ...p, features: [...p.features, ''] }))} className="text-xs text-blue-300 hover:text-blue-200">+ Add Feature</button>
              </div>

              {/* Tags */}
              <div className="sm:col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Tags (comma separated)</label>
                <input value={form.tags} onChange={e => setF('tags', e.target.value)} placeholder="ncert, biology, class 11, neet" className={INP} />
              </div>

              {/* Toggles */}
              <div className="sm:col-span-2">
                <div className="flex gap-4 flex-wrap">
                  {[['isFeatured','⭐ Featured'],['isNew','✨ New'],['isBestSeller','🔥 Best Seller'],['isActive','✓ Active']].map(([k, label]) => (
                    <label key={k} className="flex items-center gap-2 cursor-pointer">
                      <input type="checkbox" checked={!!form[k]} onChange={e => setF(k, e.target.checked)} className="w-4 h-4 accent-blue-500" />
                      <span className="text-sm text-white/70">{label}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button onClick={saveProduct} className={`${BTN} bg-blue-600 hover:bg-blue-500 text-white flex-1`}>
                {editing ? '💾 Save Changes' : '➕ Create Product'}
              </button>
              <button onClick={() => setShowForm(false)} className={`${BTN} bg-white/10 text-white/60 hover:bg-white/20`}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════
// ORDERS MANAGER
// ══════════════════════════════════════════════════
function OrdersManager({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [selected, setSelected] = useState<any>(null);
  const [statusForm, setStatusForm] = useState({ status:'', note:'', trackingNumber:'', trackingUrl:'', courierName:'', estimatedDelivery:'' });

  const loadOrders = useCallback(() => {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), limit:'15', ...(search && { search }), ...(statusFilter && { status: statusFilter }) });
    fetch(`${API}/api/admin/store/orders?${params}`, { headers: hdr() })
      .then(r => r.json()).then(d => { setOrders(d.orders || []); setTotal(d.total || 0); })
      .catch(() => showToast('Failed to load orders', 'error'))
      .finally(() => setLoading(false));
  }, [page, search, statusFilter]);

  useEffect(() => { loadOrders(); }, [loadOrders]);

  const openOrder = async (order: any) => {
    const r = await fetch(`${API}/api/admin/store/orders/${order._id}`, { headers: hdr() });
    const d = await r.json();
    setSelected(d.order || order);
    setStatusForm({ status: order.status, note:'', trackingNumber: order.trackingNumber||'', trackingUrl: order.trackingUrl||'', courierName: order.courierName||'', estimatedDelivery:'' });
  };

  const updateStatus = async () => {
    if (!selected) return;
    const r = await fetch(`${API}/api/admin/store/orders/${selected._id}/status`, { method: 'PUT', headers: hdr(), body: JSON.stringify(statusForm) });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) { setSelected(null); loadOrders(); }
  };

  const statuses = ['pending','confirmed','packed','shipped','out_for_delivery','delivered','cancelled','return_requested','returned','refunded'];

  return (
    <div className="space-y-4">
      <div className={`${GLASS} p-4 flex flex-col sm:flex-row gap-3`}>
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search by Order ID or name..." className={`${INP} flex-1`} />
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className={SEL} style={{ width:'auto' }}>
          <option value="">All Statuses</option>
          {statuses.map(s => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>

      <p className="text-white/40 text-sm">{total} orders found</p>

      {loading ? <div className="flex justify-center py-12"><div className="w-8 h-8 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" /></div> : (
        <div className={`${GLASS} overflow-hidden`}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b border-white/10">
                <tr className="text-white/40 text-xs">
                  <th className="text-left px-4 py-3 font-medium">Order ID</th>
                  <th className="text-left px-4 py-3 font-medium">Student</th>
                  <th className="text-left px-4 py-3 font-medium">Items</th>
                  <th className="text-left px-4 py-3 font-medium">Total</th>
                  <th className="text-left px-4 py-3 font-medium">Payment</th>
                  <th className="text-left px-4 py-3 font-medium">Status</th>
                  <th className="text-left px-4 py-3 font-medium">Date</th>
                  <th className="text-left px-4 py-3 font-medium">Action</th>
                </tr>
              </thead>
              <tbody>
                {orders.length === 0 ? (
                  <tr><td colSpan={8} className="text-center py-12 text-white/30">No orders yet</td></tr>
                ) : orders.map(o => (
                  <tr key={o._id} className="border-b border-white/5 hover:bg-white/3">
                    <td className="px-4 py-3 font-mono text-blue-300 text-xs">{o.orderId}</td>
                    <td className="px-4 py-3">
                      <p className="text-white text-xs font-medium">{o.student?.name || '—'}</p>
                      <p className="text-white/40 text-xs">{o.student?.email}</p>
                    </td>
                    <td className="px-4 py-3 text-white/60 text-xs">{o.items?.length} item{o.items?.length !== 1 ? 's' : ''}</td>
                    <td className="px-4 py-3 text-green-300 font-bold text-xs">{fmtPrice(o.pricing?.total || 0)}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs px-2 py-1 rounded-full ${o.payment?.method === 'COD' ? 'bg-purple-500/20 text-purple-300' : 'bg-green-500/20 text-green-300'}`}>{o.payment?.method}</span>
                    </td>
                    <td className="px-4 py-3"><span className={`px-2 py-1 rounded-full text-xs ${STATUS_COLORS[o.status] || ''}`}>{o.status}</span></td>
                    <td className="px-4 py-3 text-white/40 text-xs">{fmtDate(o.createdAt)}</td>
                    <td className="px-4 py-3"><button onClick={() => openOrder(o)} className={`${BTN} bg-blue-600/30 text-blue-300 text-xs`}>Manage</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {total > 15 && (
        <div className="flex justify-center gap-2">
          <button onClick={() => setPage(p => Math.max(1,p-1))} disabled={page===1} className={`${BTN} bg-white/5 text-white/60 disabled:opacity-30`}>← Prev</button>
          <span className="px-4 py-2 text-white/50 text-sm">{page}/{Math.ceil(total/15)}</span>
          <button onClick={() => setPage(p => p+1)} disabled={page>=Math.ceil(total/15)} className={`${BTN} bg-white/5 text-white/60 disabled:opacity-30`}>Next →</button>
        </div>
      )}

      {/* Order Detail Modal */}
      {selected && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 overflow-y-auto p-4">
          <div className="max-w-2xl mx-auto" style={{ background:'#0a0f1e', border:'1px solid rgba(255,255,255,0.1)', borderRadius:24, padding:24 }}>
            <div className="flex justify-between mb-4">
              <div>
                <h2 className="text-xl font-bold text-white">Order: {selected.orderId}</h2>
                <p className="text-white/40 text-xs">Placed: {fmtDate(selected.createdAt)}</p>
              </div>
              <button onClick={() => setSelected(null)} className="text-white/40 text-2xl hover:text-white">×</button>
            </div>

            {/* Student Info */}
            <div className={`${GLASS} p-4 mb-4`}>
              <p className="text-xs text-white/40 mb-2">CUSTOMER</p>
              <p className="font-semibold text-white">{selected.student?.name}</p>
              <p className="text-white/50 text-sm">{selected.student?.email} • {selected.student?.phone}</p>
            </div>

            {/* Shipping */}
            <div className={`${GLASS} p-4 mb-4`}>
              <p className="text-xs text-white/40 mb-2">SHIPPING ADDRESS</p>
              <p className="text-white text-sm">{selected.shippingAddress?.fullName} • {selected.shippingAddress?.phone}</p>
              <p className="text-white/60 text-sm">{selected.shippingAddress?.addressLine1}, {selected.shippingAddress?.addressLine2}</p>
              <p className="text-white/60 text-sm">{selected.shippingAddress?.city}, {selected.shippingAddress?.state} — {selected.shippingAddress?.pincode}</p>
            </div>

            {/* Items */}
            <div className={`${GLASS} p-4 mb-4`}>
              <p className="text-xs text-white/40 mb-2">ORDER ITEMS</p>
              {selected.items?.map((item: any, i: number) => (
                <div key={i} className="flex justify-between items-center py-2 border-b border-white/5">
                  <div>
                    <p className="text-white text-sm font-medium">{item.name}</p>
                    <p className="text-white/40 text-xs">Qty: {item.quantity} × {fmtPrice(item.price)}</p>
                  </div>
                  <p className="text-green-300 font-semibold">{fmtPrice(item.price * item.quantity)}</p>
                </div>
              ))}
              <div className="mt-3 space-y-1">
                <div className="flex justify-between text-sm text-white/60"><span>Subtotal</span><span>{fmtPrice(selected.pricing?.subtotal||0)}</span></div>
                <div className="flex justify-between text-sm text-white/60"><span>Delivery</span><span>{fmtPrice(selected.pricing?.deliveryCharge||0)}</span></div>
                {(selected.pricing?.couponDiscount > 0) && <div className="flex justify-between text-sm text-green-300"><span>Coupon</span><span>-{fmtPrice(selected.pricing.couponDiscount)}</span></div>}
                <div className="flex justify-between font-bold text-white border-t border-white/10 pt-2"><span>Total</span><span>{fmtPrice(selected.pricing?.total||0)}</span></div>
              </div>
            </div>

            {/* Update Status */}
            <div className={`${GLASS} p-4`}>
              <p className="text-xs text-white/40 mb-3">UPDATE ORDER STATUS</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-3">
                <select value={statusForm.status} onChange={e => setStatusForm(p => ({...p, status:e.target.value}))} className={SEL}>
                  {statuses.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
                <input value={statusForm.courierName} onChange={e => setStatusForm(p => ({...p, courierName:e.target.value}))} placeholder="Courier (e.g. DTDC)" className={INP} />
                <input value={statusForm.trackingNumber} onChange={e => setStatusForm(p => ({...p, trackingNumber:e.target.value}))} placeholder="Tracking Number" className={INP} />
                <input value={statusForm.trackingUrl} onChange={e => setStatusForm(p => ({...p, trackingUrl:e.target.value}))} placeholder="Tracking URL" className={INP} />
                <input type="date" value={statusForm.estimatedDelivery} onChange={e => setStatusForm(p => ({...p, estimatedDelivery:e.target.value}))} className={`${INP} sm:col-span-2`} />
                <textarea value={statusForm.note} onChange={e => setStatusForm(p => ({...p, note:e.target.value}))} placeholder="Status note (optional)..." rows={2} className={`${INP} resize-none sm:col-span-2`} />
              </div>
              <button onClick={updateStatus} className={`${BTN} bg-blue-600 hover:bg-blue-500 text-white w-full`}>💾 Update Status</button>
            </div>

            {/* Status History */}
            {selected.statusHistory?.length > 0 && (
              <div className="mt-4">
                <p className="text-xs text-white/40 mb-2">STATUS HISTORY</p>
                <div className="space-y-2">
                  {[...selected.statusHistory].reverse().map((h: any, i: number) => (
                    <div key={i} className="flex items-start gap-3 text-xs">
                      <span className={`px-2 py-0.5 rounded-full ${STATUS_COLORS[h.status] || 'bg-white/10'} whitespace-nowrap`}>{h.status}</span>
                      <span className="text-white/40">{h.note}</span>
                      <span className="text-white/20 ml-auto whitespace-nowrap">{fmtDate(h.timestamp)}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════
// COUPONS MANAGER
// ══════════════════════════════════════════════════
function CouponsManager({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [coupons, setCoupons] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing]  = useState<any>(null);
  const [form, setForm] = useState({ code:'', description:'', type:'percent', value:'', minOrderValue:'0', maxDiscount:'', usageLimit:'100', validFrom:'', validTill:'', isActive:true });

  const load = () => fetch(`${API}/api/admin/store/coupons`, { headers: hdr() }).then(r => r.json()).then(d => setCoupons(d.coupons || []));
  useEffect(() => { load(); }, []);

  const openCreate = () => { setEditing(null); setForm({ code:'', description:'', type:'percent', value:'', minOrderValue:'0', maxDiscount:'', usageLimit:'100', validFrom:'', validTill:'', isActive:true }); setShowForm(true); };
  const openEdit   = (c: any) => { setEditing(c); setForm({ ...c, value:String(c.value), minOrderValue:String(c.minOrderValue||0), maxDiscount:String(c.maxDiscount||''), usageLimit:String(c.usageLimit||100), validFrom:c.validFrom?c.validFrom.substring(0,10):'', validTill:c.validTill?c.validTill.substring(0,10):'' }); setShowForm(true); };

  const save = async () => {
    const payload = { ...form, value:parseFloat(form.value), minOrderValue:parseFloat(form.minOrderValue)||0, usageLimit:parseInt(form.usageLimit)||100, maxDiscount:form.maxDiscount?parseFloat(form.maxDiscount):undefined };
    const url    = editing ? `${API}/api/admin/store/coupons/${editing._id}` : `${API}/api/admin/store/coupons`;
    const method = editing ? 'PUT' : 'POST';
    const r = await fetch(url, { method, headers: hdr(), body: JSON.stringify(payload) });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) { setShowForm(false); load(); }
  };

  const toggle = async (id: string) => {
    await fetch(`${API}/api/admin/store/coupons/${id}/toggle`, { method:'PATCH', headers:hdr() });
    load();
  };
  const del = async (id: string) => {
    if (!confirm('Delete coupon?')) return;
    const r = await fetch(`${API}/api/admin/store/coupons/${id}`, { method:'DELETE', headers:hdr() });
    showToast((await r.json()).message, r.ok ? 'success' : 'error');
    if (r.ok) load();
  };

  const setF = (k: string, v: any) => setForm(p => ({...p, [k]:v}));

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <p className="text-white/40 text-sm">{coupons.length} coupons</p>
        <button onClick={openCreate} className={`${BTN} bg-blue-600 hover:bg-blue-500 text-white`}>+ Create Coupon</button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {coupons.map(c => (
          <div key={c._id} className={`${GLASS} p-5`}>
            <div className="flex items-center justify-between mb-3">
              <span className="font-mono text-lg font-black text-blue-300">{c.code}</span>
              <span className={`text-xs px-2 py-1 rounded-full ${c.isActive ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'}`}>{c.isActive ? 'Active' : 'Inactive'}</span>
            </div>
            <p className="text-white/60 text-xs mb-3">{c.description}</p>
            <div className="space-y-1 text-xs text-white/50 mb-4">
              <div className="flex justify-between"><span>Discount</span><span className="text-green-300 font-bold">{c.type === 'percent' ? `${c.value}%` : `₹${c.value}`} off</span></div>
              <div className="flex justify-between"><span>Min Order</span><span>₹{c.minOrderValue || 0}</span></div>
              {c.maxDiscount && <div className="flex justify-between"><span>Max Discount</span><span>₹{c.maxDiscount}</span></div>}
              <div className="flex justify-between"><span>Used</span><span>{c.usedCount}/{c.usageLimit}</span></div>
              {c.validTill && <div className="flex justify-between"><span>Valid Till</span><span>{fmtDate(c.validTill)}</span></div>}
            </div>
            <div className="w-full bg-white/10 rounded-full h-1.5 mb-3">
              <div className="bg-blue-500 h-1.5 rounded-full" style={{ width: `${Math.min(100, (c.usedCount/c.usageLimit)*100)}%` }} />
            </div>
            <div className="flex gap-2">
              <button onClick={() => toggle(c._id)} className={`${BTN} ${c.isActive ? 'bg-yellow-500/20 text-yellow-300' : 'bg-green-500/20 text-green-300'} flex-1 text-xs`}>
                {c.isActive ? 'Deactivate' : 'Activate'}
              </button>
              <button onClick={() => openEdit(c)} className={`${BTN} bg-white/10 text-white/60 text-xs`}>Edit</button>
              <button onClick={() => del(c._id)} className={`${BTN} bg-red-500/20 text-red-300 text-xs`}>Del</button>
            </div>
          </div>
        ))}
        {coupons.length === 0 && (
          <div className={`${GLASS} p-12 col-span-full text-center`}><p className="text-white/30">No coupons yet. Create your first coupon!</p></div>
        )}
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="w-full max-w-lg" style={{ background:'#0a0f1e', border:'1px solid rgba(255,255,255,0.1)', borderRadius:24, padding:24 }}>
            <div className="flex justify-between mb-5">
              <h2 className="text-xl font-bold text-white">{editing ? 'Edit Coupon' : 'Create Coupon'}</h2>
              <button onClick={() => setShowForm(false)} className="text-white/40 text-2xl">×</button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Coupon Code *</label>
                <input value={form.code} onChange={e => setF('code', e.target.value.toUpperCase())} placeholder="SAVE20" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Type</label>
                <select value={form.type} onChange={e => setF('type', e.target.value)} className={SEL}>
                  <option value="percent">Percent (%)</option>
                  <option value="flat">Flat (₹)</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Value * {form.type === 'percent' ? '(%)' : '(₹)'}</label>
                <input type="number" value={form.value} onChange={e => setF('value', e.target.value)} placeholder="20" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Min Order (₹)</label>
                <input type="number" value={form.minOrderValue} onChange={e => setF('minOrderValue', e.target.value)} placeholder="0" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Max Discount (₹)</label>
                <input type="number" value={form.maxDiscount} onChange={e => setF('maxDiscount', e.target.value)} placeholder="100" className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Usage Limit</label>
                <input type="number" value={form.usageLimit} onChange={e => setF('usageLimit', e.target.value)} placeholder="100" className={INP} />
              </div>
              <div />
              <div>
                <label className="text-xs text-white/40 mb-1 block">Valid From</label>
                <input type="date" value={form.validFrom} onChange={e => setF('validFrom', e.target.value)} className={INP} />
              </div>
              <div>
                <label className="text-xs text-white/40 mb-1 block">Valid Till</label>
                <input type="date" value={form.validTill} onChange={e => setF('validTill', e.target.value)} className={INP} />
              </div>
              <div className="col-span-2">
                <label className="text-xs text-white/40 mb-1 block">Description</label>
                <input value={form.description} onChange={e => setF('description', e.target.value)} placeholder="Get 20% off on all books" className={INP} />
              </div>
              <div className="col-span-2 flex items-center gap-2">
                <input type="checkbox" checked={form.isActive} onChange={e => setF('isActive', e.target.checked)} className="w-4 h-4 accent-blue-500" />
                <span className="text-sm text-white/70">Active</span>
              </div>
            </div>
            <div className="flex gap-3 mt-5">
              <button onClick={save} className={`${BTN} bg-blue-600 hover:bg-blue-500 text-white flex-1`}>{editing ? 'Save' : 'Create'}</button>
              <button onClick={() => setShowForm(false)} className={`${BTN} bg-white/10 text-white/60`}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════
// INVENTORY VIEW
// ══════════════════════════════════════════════════
function InventoryView({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [data, setData] = useState<any>(null);
  const [editing, setEditing] = useState<any>(null);
  const [stockForm, setStockForm] = useState({ stock:'', lowStockThreshold:'10' });

  useEffect(() => {
    fetch(`${API}/api/admin/store/inventory`, { headers: hdr() })
      .then(r => r.json()).then(setData).catch(() => showToast('Failed to load inventory', 'error'));
  }, []);

  const updateStock = async (id: string) => {
    const r = await fetch(`${API}/api/admin/store/products/${id}/inventory`, { method:'PATCH', headers:hdr(), body:JSON.stringify({ stock:parseInt(stockForm.stock), lowStockThreshold:parseInt(stockForm.lowStockThreshold) }) });
    const d = await r.json();
    showToast(d.message, r.ok ? 'success' : 'error');
    if (r.ok) { setEditing(null); fetch(`${API}/api/admin/store/inventory`, { headers: hdr() }).then(r => r.json()).then(setData); }
  };

  if (!data) return <div className="flex justify-center py-12"><div className="w-8 h-8 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" /></div>;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-4">
        {[
          { label:'Total Products', value:data.totalProducts, color:'blue' },
          { label:'Low Stock',      value:data.lowStock?.length || 0, color:'yellow' },
          { label:'Out of Stock',   value:data.outOfStock?.length || 0, color:'red' },
        ].map((s, i) => (
          <div key={i} className={`${GLASS} p-4 text-center`}>
            <p className="text-2xl font-bold text-white">{s.value}</p>
            <p className="text-xs text-white/40 mt-1">{s.label}</p>
          </div>
        ))}
      </div>

      {data.outOfStock?.length > 0 && (
        <div className={`${GLASS} p-4 border-red-500/30`}>
          <p className="text-red-300 font-bold text-sm mb-3">🚫 Out of Stock ({data.outOfStock.length})</p>
          <div className="space-y-2">
            {data.outOfStock.map((p: any) => (
              <div key={p._id} className="flex items-center justify-between bg-red-500/10 rounded-xl px-4 py-2">
                <div>
                  <p className="text-white text-sm font-medium">{p.name}</p>
                  <p className="text-white/40 text-xs">{p.sku} • {p.category}</p>
                </div>
                <button onClick={() => { setEditing(p._id); setStockForm({ stock:'', lowStockThreshold:String(p.lowStockThreshold||10) }); }} className={`${BTN} bg-blue-600/30 text-blue-300 text-xs`}>Restock</button>
              </div>
            ))}
          </div>
        </div>
      )}

      {data.lowStock?.length > 0 && (
        <div className={`${GLASS} p-4 border-yellow-500/30`}>
          <p className="text-yellow-300 font-bold text-sm mb-3">⚠️ Low Stock ({data.lowStock.length})</p>
          <div className="space-y-2">
            {data.lowStock.map((p: any) => (
              <div key={p._id} className="flex items-center justify-between bg-yellow-500/10 rounded-xl px-4 py-2">
                <div>
                  <p className="text-white text-sm font-medium">{p.name}</p>
                  <p className="text-white/40 text-xs">{p.sku} • {p.stock} left</p>
                </div>
                <button onClick={() => { setEditing(p._id); setStockForm({ stock:String(p.stock), lowStockThreshold:String(p.lowStockThreshold||10) }); }} className={`${BTN} bg-blue-600/30 text-blue-300 text-xs`}>Update</button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className={`${GLASS} overflow-hidden`}>
        <div className="p-4 border-b border-white/10"><h3 className="font-bold text-white">📦 Full Inventory</h3></div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-white/40 text-xs border-b border-white/10">
              <tr>
                <th className="text-left px-4 py-3 font-medium">Product</th>
                <th className="text-left px-4 py-3 font-medium">SKU</th>
                <th className="text-left px-4 py-3 font-medium">Category</th>
                <th className="text-left px-4 py-3 font-medium">Price</th>
                <th className="text-left px-4 py-3 font-medium">Stock</th>
                <th className="text-left px-4 py-3 font-medium">Sold</th>
                <th className="text-left px-4 py-3 font-medium">Action</th>
              </tr>
            </thead>
            <tbody>
              {data.products?.map((p: any) => (
                <tr key={p._id} className="border-b border-white/5 hover:bg-white/3">
                  <td className="px-4 py-3 text-white text-xs font-medium">{p.name}</td>
                  <td className="px-4 py-3 font-mono text-white/40 text-xs">{p.sku}</td>
                  <td className="px-4 py-3 text-white/50 text-xs">{p.category}</td>
                  <td className="px-4 py-3 text-green-300 text-xs font-semibold">{fmtPrice(p.price)}</td>
                  <td className="px-4 py-3">
                    <span className={`text-xs px-2 py-1 rounded-full ${p.stock > p.lowStockThreshold ? 'bg-green-500/20 text-green-300' : p.stock > 0 ? 'bg-yellow-500/20 text-yellow-300' : 'bg-red-500/20 text-red-300'}`}>{p.stock}</span>
                  </td>
                  <td className="px-4 py-3 text-white/50 text-xs">{p.sold}</td>
                  <td className="px-4 py-3">
                    <button onClick={() => { setEditing(p._id); setStockForm({ stock:String(p.stock), lowStockThreshold:String(p.lowStockThreshold||10) }); }} className={`${BTN} bg-white/5 text-white/50 text-xs`}>Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Stock Edit Modal */}
      {editing && (
        <div className="fixed inset-0 bg-black/80 z-50 flex items-center justify-center p-4">
          <div style={{ background:'#0a0f1e', border:'1px solid rgba(255,255,255,0.15)', borderRadius:20, padding:24, width:'100%', maxWidth:400 }}>
            <h3 className="text-lg font-bold text-white mb-4">Update Inventory</h3>
            <label className="text-xs text-white/40 mb-1 block">New Stock Quantity</label>
            <input type="number" value={stockForm.stock} onChange={e => setStockForm(p => ({...p, stock:e.target.value}))} className={`${INP} mb-3`} placeholder="0" />
            <label className="text-xs text-white/40 mb-1 block">Low Stock Threshold</label>
            <input type="number" value={stockForm.lowStockThreshold} onChange={e => setStockForm(p => ({...p, lowStockThreshold:e.target.value}))} className={`${INP} mb-4`} placeholder="10" />
            <div className="flex gap-3">
              <button onClick={() => updateStock(editing)} className={`${BTN} bg-blue-600 text-white flex-1`}>Save</button>
              <button onClick={() => setEditing(null)} className={`${BTN} bg-white/10 text-white/60`}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════
// REVIEWS MANAGER
// ══════════════════════════════════════════════════
function ReviewsManager({ showToast }: { showToast: (m: string, t?: any) => void }) {
  const [reviews, setReviews]  = useState<any[]>([]);
  const [replyForm, setReplyForm] = useState<{ id: string; text: string } | null>(null);

  useEffect(() => {
    fetch(`${API}/api/admin/store/reviews`, { headers: hdr() })
      .then(r => r.json()).then(d => setReviews(d.reviews || []));
  }, []);

  const sendReply = async () => {
    if (!replyForm) return;
    const r = await fetch(`${API}/api/admin/store/reviews/${replyForm.id}/reply`, { method:'PUT', headers:hdr(), body:JSON.stringify({ reply:replyForm.text }) });
    showToast((await r.json()).message, r.ok ? 'success' : 'error');
    if (r.ok) { setReplyForm(null); }
  };

  const delReview = async (id: string) => {
    if (!confirm('Delete review?')) return;
    const r = await fetch(`${API}/api/admin/store/reviews/${id}`, { method:'DELETE', headers:hdr() });
    showToast((await r.json()).message, r.ok ? 'success' : 'error');
    if (r.ok) setReviews(prev => prev.filter(rv => rv._id !== id));
  };

  const stars = (n: number) => '★'.repeat(n) + '☆'.repeat(5-n);

  return (
    <div className="space-y-4">
      <p className="text-white/40 text-sm">{reviews.length} reviews</p>
      {reviews.length === 0 ? (
        <div className={`${GLASS} p-12 text-center`}><p className="text-white/30">No reviews yet</p></div>
      ) : reviews.map(r => (
        <div key={r._id} className={`${GLASS} p-5`}>
          <div className="flex items-start justify-between mb-2">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <span className="text-yellow-400 text-sm">{stars(r.rating)}</span>
                {r.isVerifiedPurchase && <span className="text-green-300 text-xs bg-green-500/20 px-2 py-0.5 rounded-full">✓ Verified Purchase</span>}
              </div>
              <p className="text-white font-semibold text-sm">{r.title}</p>
              <p className="text-white/50 text-xs">{r.student?.name} • {fmtDate(r.createdAt)}</p>
              <p className="text-white/60 text-xs mt-1">Product: {r.product?.name}</p>
            </div>
            <button onClick={() => delReview(r._id)} className={`${BTN} bg-red-500/20 text-red-300 text-xs`}>Delete</button>
          </div>
          <p className="text-white/70 text-sm mb-3">{r.body}</p>
          {r.adminReply && <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-3 mb-3"><p className="text-xs text-blue-300 font-semibold mb-1">Admin Reply</p><p className="text-white/70 text-sm">{r.adminReply}</p></div>}
          {!r.adminReply && (
            replyForm?.id === r._id ? (
              <div className="flex gap-2">
                <textarea value={replyForm.text} onChange={e => setReplyForm(p => p ? {...p, text:e.target.value} : null)} rows={2} placeholder="Write your reply..." className={`${INP} flex-1 resize-none text-xs`} />
                <div className="flex flex-col gap-2">
                  <button onClick={sendReply} className={`${BTN} bg-blue-600 text-white text-xs`}>Send</button>
                  <button onClick={() => setReplyForm(null)} className={`${BTN} bg-white/10 text-white/60 text-xs`}>×</button>
                </div>
              </div>
            ) : (
              <button onClick={() => setReplyForm({ id: r._id, text:'' })} className={`${BTN} bg-blue-600/20 text-blue-300 text-xs`}>Reply to Review</button>
            )
          )}
        </div>
      ))}
    </div>
  );
}
