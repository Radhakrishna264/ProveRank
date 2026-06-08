'use client';
// Razorpay global type
declare global { interface Window { Razorpay: any; } }
import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com';
const tok = () => typeof window !== 'undefined' ? localStorage.getItem('pr_token') || '' : '';
const hdr = () => ({ 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}` });
const fmtP = (n: number) => '₹' + n.toLocaleString('en-IN');
const pct  = (o: number, s: number) => Math.round(((o - s) / o) * 100);
const fmtD = (d: string) => new Date(d).toLocaleDateString('en-IN', { day:'numeric', month:'short', year:'numeric' });

// ─── Shared styles ───────────────────────────────────────────────
const S = {
  page:   { minHeight:'100vh', background:'#030a1a', color:'#fff', fontFamily:"'Inter',sans-serif", paddingBottom:80 } as React.CSSProperties,
  card:   { background:'rgba(255,255,255,0.04)', border:'1px solid rgba(255,255,255,0.08)', borderRadius:16 } as React.CSSProperties,
  card2:  { background:'rgba(255,255,255,0.02)', border:'1px solid rgba(255,255,255,0.06)', borderRadius:12 } as React.CSSProperties,
  btnP:   { background:'linear-gradient(135deg,#2563eb,#0ea5e9)', color:'#fff', border:'none', borderRadius:12, padding:'12px 20px', fontWeight:700, fontSize:14, cursor:'pointer', transition:'opacity 0.2s' } as React.CSSProperties,
  btnS:   { background:'rgba(255,255,255,0.06)', color:'rgba(255,255,255,0.7)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:12, padding:'10px 16px', fontWeight:600, fontSize:13, cursor:'pointer' } as React.CSSProperties,
  inp:    { width:'100%', background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.1)', borderRadius:12, padding:'12px 16px', color:'#fff', fontSize:14, outline:'none', boxSizing:'border-box' } as React.CSSProperties,
  sel:    { width:'100%', background:'#060d1f', border:'1px solid rgba(255,255,255,0.1)', borderRadius:12, padding:'11px 16px', color:'#fff', fontSize:13, outline:'none' } as React.CSSProperties,
  tag:    (active: boolean, color = '#2563eb') => ({ padding:'6px 12px', borderRadius:20, fontSize:12, fontWeight:600, cursor:'pointer', border:`1px solid ${active ? color : 'rgba(255,255,255,0.1)'}`, background: active ? color + '33' : 'rgba(255,255,255,0.04)', color: active ? color : 'rgba(255,255,255,0.5)' } as React.CSSProperties),
  topbar: { position:'sticky' as const, top:0, zIndex:40, background:'rgba(3,10,26,0.92)', backdropFilter:'blur(20px)', borderBottom:'1px solid rgba(255,255,255,0.06)', padding:'12px 16px' },
};

// Toast
function Toast({ msg, type, onClose }: { msg: string; type: string; onClose: () => void }) {
  useEffect(() => { const t = setTimeout(onClose, 3000); return () => clearTimeout(t); }, [onClose]);
  const bg = type === 'success' ? '#16a34a' : type === 'error' ? '#dc2626' : '#2563eb';
  return (
    <div style={{ position:'fixed', top:20, left:'50%', transform:'translateX(-50%)', zIndex:9999, background:bg, color:'#fff', padding:'12px 20px', borderRadius:16, fontWeight:600, fontSize:13, boxShadow:'0 8px 32px rgba(0,0,0,0.5)', whiteSpace:'nowrap' }}>
      {type === 'success' ? '✓ ' : type === 'error' ? '✕ ' : 'ℹ '}{msg}
    </div>
  );
}

// Stars
function Stars({ n }: { n: number }) {
  return <span style={{ color:'#fbbf24', fontSize:12 }}>{'★'.repeat(Math.round(n))}{'☆'.repeat(5 - Math.round(n))}</span>;
}

// Product Card
function PCard({ p, onView, onCart, onWish, wished }: any) {
  const [adding, setAdding] = useState(false);
  const discount = pct(p.originalPrice, p.price);
  return (
    <div onClick={() => onView(p)} style={{ ...S.card, cursor:'pointer', overflow:'hidden', transition:'transform 0.2s,box-shadow 0.2s' }}
      onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-4px)'; (e.currentTarget as HTMLDivElement).style.boxShadow = '0 12px 40px rgba(37,99,235,0.15)'; }}
      onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.transform = ''; (e.currentTarget as HTMLDivElement).style.boxShadow = ''; }}>
      {/* Image */}
      <div style={{ position:'relative', height:160, background:'linear-gradient(135deg,rgba(37,99,235,0.15),rgba(14,165,233,0.08))', display:'flex', alignItems:'center', justifyContent:'center' }}>
        {p.images?.[0]?.url
          ? <img src={p.images[0].url} alt={p.name} style={{ width:'100%', height:'100%', objectFit:'cover' }} />
          : <span style={{ fontSize:48 }}>📚</span>}
        {discount > 0 && <span style={{ position:'absolute', top:8, right:8, background:'#ef4444', color:'#fff', fontSize:11, fontWeight:700, padding:'2px 7px', borderRadius:20 }}>{discount}% OFF</span>}
        {p.isBestSeller && <span style={{ position:'absolute', top:8, left:8, background:'linear-gradient(90deg,#f59e0b,#ef4444)', color:'#000', fontSize:10, fontWeight:800, padding:'2px 7px', borderRadius:20 }}>🔥 BESTSELLER</span>}
        {p.stock === 0 && (
          <div style={{ position:'absolute', inset:0, background:'rgba(0,0,0,0.6)', display:'flex', alignItems:'center', justifyContent:'center' }}>
            <span style={{ background:'rgba(239,68,68,0.8)', color:'#fff', padding:'6px 14px', borderRadius:20, fontSize:12, fontWeight:700 }}>Out of Stock</span>
          </div>
        )}
        <button onClick={e => { e.stopPropagation(); onWish(p._id); }} style={{ position:'absolute', bottom:8, right:8, width:30, height:30, borderRadius:'50%', background:'rgba(0,0,0,0.5)', border:'1px solid rgba(255,255,255,0.2)', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', fontSize:14 }}>
          {wished ? '❤️' : '🤍'}
        </button>
      </div>
      {/* Info */}
      <div style={{ padding:'12px 14px' }}>
        <p style={{ fontSize:11, color:'#60a5fa', marginBottom:4, fontWeight:600 }}>{p.category} · {p.subject}</p>
        <p style={{ fontSize:13, fontWeight:700, color:'#fff', marginBottom:4, lineHeight:1.4, display:'-webkit-box', WebkitLineClamp:2, WebkitBoxOrient:'vertical', overflow:'hidden' }}>{p.name}</p>
        {p.author && <p style={{ fontSize:11, color:'rgba(255,255,255,0.35)', marginBottom:6 }}>by {p.author}</p>}
        <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:8 }}>
          <Stars n={p.ratings?.average || 0} />
          <span style={{ fontSize:11, color:'rgba(255,255,255,0.3)' }}>({p.ratings?.count || 0})</span>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
          <span style={{ fontSize:18, fontWeight:900, color:'#fff' }}>{fmtP(p.price)}</span>
          {p.originalPrice > p.price && <span style={{ fontSize:12, color:'rgba(255,255,255,0.3)', textDecoration:'line-through' }}>{fmtP(p.originalPrice)}</span>}
        </div>
        <p style={{ fontSize:11, color: p.deliveryCharge === 0 ? '#4ade80' : 'rgba(255,255,255,0.4)', marginBottom:10 }}>
          🚚 {p.deliveryCharge === 0 ? 'Free Delivery' : `+₹${p.deliveryCharge} delivery`}
        </p>
        <button onClick={async e => { e.stopPropagation(); setAdding(true); await onCart(p._id); setAdding(false); }}
          disabled={adding || p.stock === 0} style={{ ...S.btnP, width:'100%', padding:'10px', opacity: (adding || p.stock === 0) ? 0.5 : 1 }}>
          {adding ? '⏳ Adding...' : p.stock > 0 ? '🛒 Add to Cart' : 'Out of Stock'}
        </button>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════
// MAIN
// ════════════════════════════════════════════════════

// Load Razorpay checkout script
const loadRazorpayScript = (): Promise<boolean> => {
  return new Promise(resolve => {
    if (typeof window === 'undefined') return resolve(false);
    if (window.Razorpay) return resolve(true);
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};


// ── Payment Failure Modal ───────────────────────────────────
function PaymentFailureModal({
  paymentId, amount, onRetry, onClose, retrying
}: {
  paymentId: string; amount: number; onRetry: () => void;
  onClose: () => void; retrying: boolean;
}) {
  return (
    <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.9)', zIndex:9999, display:'flex', alignItems:'center', justifyContent:'center', padding:16 }}>
      <div style={{ width:'100%', maxWidth:420, background:'#0a0f1e', border:'1px solid rgba(239,68,68,0.4)', borderRadius:20, padding:24 }}>
        <div style={{ textAlign:'center', marginBottom:20 }}>
          <div style={{ fontSize:48, marginBottom:8 }}>⚠️</div>
          <h2 style={{ fontSize:18, fontWeight:900, color:'#fca5a5', margin:'0 0 6px' }}>
            Payment Done — Order Failed
          </h2>
          <p style={{ fontSize:13, color:'rgba(255,255,255,0.5)', margin:0 }}>
            ₹{amount} was deducted but order was not created due to a connection error.
          </p>
        </div>

        <div style={{ background:'rgba(239,68,68,0.1)', border:'1px solid rgba(239,68,68,0.3)', borderRadius:12, padding:14, marginBottom:16 }}>
          <p style={{ fontSize:11, color:'rgba(255,255,255,0.4)', margin:'0 0 4px', fontWeight:700 }}>PAYMENT ID (Screenshot karo!)</p>
          <p style={{ fontSize:14, fontFamily:'monospace', color:'#60a5fa', fontWeight:700, margin:0, wordBreak:'break-all' }}>{paymentId}</p>
        </div>

        <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginBottom:16, lineHeight:1.7 }}>
          <p style={{ margin:'0 0 6px' }}>✅ Payment ID saved in your browser</p>
          <p style={{ margin:'0 0 6px' }}>📞 Share this ID with support to get your order created</p>
          <p style={{ margin:0 }}>💰 Your money is safe — it reached merchant account</p>
        </div>

        <div style={{ display:'flex', gap:10 }}>
          <button
            onClick={onRetry}
            disabled={retrying}
            style={{ flex:1, padding:12, background:'linear-gradient(135deg,#2563eb,#0ea5e9)', color:'#fff', border:'none', borderRadius:12, fontWeight:700, fontSize:14, cursor:'pointer', opacity:retrying?0.6:1 }}
          >
            {retrying ? '⏳ Retrying...' : '🔄 Retry Order'}
          </button>
          <button
            onClick={onClose}
            style={{ padding:'12px 16px', background:'rgba(255,255,255,0.07)', color:'rgba(255,255,255,0.6)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:12, fontWeight:600, fontSize:13, cursor:'pointer' }}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

export default function StorePage() {
  const router = useRouter();
  const [failedPayment, setFailedPayment] = useState<any>(null);
  const [retryingVerify, setRetryingVerify] = useState(false);
  const [view, setView]   = useState<'store'|'product'|'cart'|'checkout'|'orders'|'wishlist'>('store');
  const [toast, setToast] = useState<{ msg: string; type: string } | null>(null);
  const T = (msg: string, type = 'success') => setToast({ msg, type });

  // Products
  const [products, setProducts] = useState<any[]>([]);
  const [featured, setFeatured] = useState<any[]>([]);
  const [total, setTotal]       = useState(0);
  const [loading, setLoading]   = useState(true);
  const [page, setPage]         = useState(1);
  const [search, setSearch]     = useState('');
  const [catF, setCatF]         = useState('');
  const [subF, setSubF]         = useState('');
  const [sortBy, setSortBy]     = useState('newest');

  // Cart
  const [cart, setCart]         = useState<any>({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
  const [couponInput, setCouponInput] = useState('');

  // Product detail
  const [selProd, setSelProd]   = useState<any>(null);
  const [reviews, setReviews]   = useState<any[]>([]);
  const [myRating, setMyRating] = useState(0);
  const [myReview, setMyReview] = useState({ title:'', body:'' });

  // Orders
  const [orders, setOrders]     = useState<any[]>([]);
  const [selOrder, setSelOrder] = useState<any>(null);

  // Wishlist
  const [wishIds, setWishIds]   = useState<string[]>([]);

  // Checkout
  const [step, setStep]         = useState(0);
  const [addr, setAddr]         = useState({ fullName:'', phone:'', addressLine1:'', addressLine2:'', city:'', state:'', pincode:'' });
  const [payM, setPayM]         = useState('COD');
  const [placing, setPlacing]   = useState(false);

  const loadProducts = useCallback(() => {
    setLoading(true);
    const p = new URLSearchParams({ page: String(page), limit:'12', sort: sortBy });
    if (search) p.set('search', search);
    if (catF)   p.set('category', catF);
    if (subF)   p.set('subject', subF);
    fetch(`${API}/api/store/products?${p}`)
      .then(r => r.json()).then(d => { setProducts(d.products||[]); setTotal(d.total||0); })
      .finally(() => setLoading(false));
  }, [page, search, catF, subF, sortBy]);

  useEffect(() => { loadProducts(); }, [loadProducts]);
  useEffect(() => {
    fetch(`${API}/api/store/products/featured`).then(r=>r.json()).then(d=>setFeatured(d.products||[]));
    if (tok()) { loadCart(); loadWish(); }
  }, []);

  const loadCart = () => fetch(`${API}/api/store/cart`,{headers:hdr()}).then(r=>r.json()).then(setCart).catch(()=>{});
  const loadWish = () => fetch(`${API}/api/store/wishlist`,{headers:hdr()}).then(r=>r.json()).then(d=>{ const prods=d.products||[]; setWishIds(prods.map((p:any)=>p._id)); setWishlist(prods); }).catch(()=>{});
  const loadOrders = () => fetch(`${API}/api/store/orders`,{headers:hdr()}).then(r=>r.json()).then(d=>setOrders(d.orders||[]));

  const addToCart = async (productId: string) => {
    if (!tok()) { T('Please login to add items','error'); return; }
    const r = await fetch(`${API}/api/store/cart/add`,{method:'POST',headers:hdr(),body:JSON.stringify({productId,quantity:1})});
    const d = await r.json();
    if (r.ok) { loadCart(); T('Added to cart! 🛒'); } else T(d.message,'error');
  };

  const updateQty = async (productId: string, qty: number) => {
    const r = await fetch(`${API}/api/store/cart/update`,{method:'PUT',headers:hdr(),body:JSON.stringify({productId,quantity:qty})});
    const d = await r.json(); if (r.ok) setCart(d.cart);
  };
  const removeItem = async (productId: string) => {
    const r = await fetch(`${API}/api/store/cart/remove/${productId}`,{method:'DELETE',headers:hdr()});
    const d = await r.json(); if (r.ok) setCart(d.cart);
  };
  const applyCoupon = async () => {
    if (!couponInput.trim()) return;
    const r = await fetch(`${API}/api/store/coupon/apply`,{method:'POST',headers:hdr(),body:JSON.stringify({couponCode:couponInput})});
    const d = await r.json(); T(d.message, r.ok?'success':'error'); if (r.ok) loadCart();
  };
  const toggleWish = async (productId: string) => {
    if (!tok()) { T('Please login','error'); return; }
    const r = await fetch(`${API}/api/store/wishlist/toggle/${productId}`,{method:'POST',headers:hdr()});
    const d = await r.json(); if (r.ok) { T(d.message); loadWish(); }
  };
  const toggleWishAndRefresh = async (productId: string) => {
    await toggleWish(productId);
  };
  const viewProduct = async (p: any) => {
    setSelProd(p); setView('product');
    const r = await fetch(`${API}/api/store/products/${p._id}`);
    const d = await r.json(); setSelProd(d.product); setReviews(d.reviews||[]);
  };
  const submitReview = async () => {
    if (!myRating) { T('Select a rating','error'); return; }
    const r = await fetch(`${API}/api/store/products/${selProd._id}/review`,{method:'POST',headers:hdr(),body:JSON.stringify({rating:myRating,...myReview})});
    const d = await r.json(); T(d.message, r.ok?'success':'error'); if (r.ok) { setMyRating(0); setMyReview({title:'',body:''}); viewProduct(selProd); }
  };
  
  const retryPaymentVerify = async () => {
    if (!failedPayment) return;
    setRetryingVerify(true);
    try {
      const verifyRes = await fetch(`${API}/api/store/payment/verify`, {
        method: 'POST', headers: hdr(),
        body: JSON.stringify({
          razorpay_order_id:   failedPayment.rzpOrderId,
          razorpay_payment_id: failedPayment.paymentId,
          razorpay_signature:  failedPayment.rzpSignature,
          shippingAddress:     addr,
        }),
      });
      let vd: any = {};
      try { vd = await verifyRes.json(); } catch { vd = { success: false, message: 'Parse error' }; }
      if (verifyRes.ok && vd.success) {
        localStorage.removeItem('pr_pending_payment');
        setFailedPayment(null);
        T(`✅ Order created! ${vd.orderId} 🎉`);
        setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
        loadOrders(); setView('orders');
      } else {
        T(vd.message || 'Retry failed — contact support', 'error');
      }
    } catch {
      T('Connection error — try again in a moment', 'error');
    }
    setRetryingVerify(false);
  };

  const placeOrder = async () => {
    setPlacing(true);
    try {
      if (payM === 'COD') {
        // ── COD flow ──
        const r = await fetch(`${API}/api/store/orders/create`, {
          method: 'POST', headers: hdr(),
          body: JSON.stringify({ shippingAddress: addr, paymentMethod: 'COD', buyerNotes }),
        });
        const d = await r.json();
        if (r.ok) {
          T(`Order placed! ${d.orderId} 🎉`);
          setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
          setStep(0); loadOrders(); setView('orders');
        } else { T(d.message, 'error'); }
      } else {
        // ── Razorpay (UPI / Card / NetBanking) flow ──
        const loaded = await loadRazorpayScript();
        if (!loaded) { T('Razorpay failed to load. Check internet.', 'error'); setPlacing(false); return; }

        // Step 1: Create Razorpay order on backend
        const r = await fetch(`${API}/api/store/payment/create-order`, {
          method: 'POST', headers: hdr(), body: JSON.stringify({}),
        });
        const payData = await r.json();
        if (!r.ok) { T(payData.message || 'Payment initiation failed', 'error'); setPlacing(false); return; }

        // Step 2: Open Razorpay checkout
        const options = {
          key:       payData.key || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID,
          amount:    payData.amount,
          currency:  payData.currency || 'INR',
          order_id:  payData.order_id,
          name:      'ProveRank Store',
          description: 'Study Material Purchase',
          image:     'https://prove-rank.vercel.app/favicon.ico',
          prefill: {
            name:    addr.fullName,
            contact: addr.phone,
          },
          theme: { color: '#2563eb' },
          modal: {
            ondismiss: () => {
              T('Payment cancelled', 'info');
              setPlacing(false);
            },
          },
          handler: async (response: any) => {
            // Save to localStorage immediately as backup
            const paymentBackup = {
              paymentId: response.razorpay_payment_id,
              orderId:   response.razorpay_order_id,
              signature: response.razorpay_signature,
              amount:    cart.total,
              address:   addr,
              timestamp: new Date().toISOString(),
            };
            if (typeof window !== 'undefined') {
              localStorage.setItem('pr_pending_payment', JSON.stringify(paymentBackup));
            }

            // Verify with backend (up to 2 retries)
            let verified = false;
            let lastError = '';
            for (let attempt = 0; attempt < 2; attempt++) {
              try {
                if (attempt > 0) await new Promise(r => setTimeout(r, 2000)); // wait 2s before retry
                const verifyRes = await fetch(`${API}/api/store/payment/verify`, {
                  method: 'POST',
                  headers: hdr(),
                  body: JSON.stringify({
                    razorpay_order_id:   response.razorpay_order_id,
                    razorpay_payment_id: response.razorpay_payment_id,
                    razorpay_signature:  response.razorpay_signature,
                    shippingAddress:     addr,
                    buyerNotes,
                  }),
                });
                let vd: any = {};
                try { vd = await verifyRes.json(); } catch { vd = { success: false, message: 'Parse error' }; }

                if (verifyRes.ok && vd.success) {
                  // Success!
                  localStorage.removeItem('pr_pending_payment');
                  T(`✅ Payment verified! Order: ${vd.orderId} 🎉`);
                  setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
                  setStep(0); loadOrders(); setView('orders');
                  verified = true;
                  break;
                } else {
                  lastError = vd.message || 'Verification failed';
                }
              } catch (err: any) {
                lastError = 'Connection error';
              }
            }

            if (!verified) {
              // Show persistent modal instead of toast
              setFailedPayment({
                paymentId: response.razorpay_payment_id,
                amount:    cart.total,
                rzpOrderId: response.razorpay_order_id,
                rzpSignature: response.razorpay_signature,
              });
            }
            setPlacing(false);
          },
        };

        const rzp = new window.Razorpay(options);
        rzp.on('payment.failed', (resp: any) => {
          T(`Payment failed: ${resp.error?.description || 'Unknown error'}`, 'error');
          setPlacing(false);
        });
        rzp.open();
        return; // placing will be set false in handler
      }
    } catch (e) {
      T('Something went wrong. Try again.', 'error');
    }
    setPlacing(false);
  };
  const setA = (k: string, v: string) => setAddr(p => ({...p, [k]:v}));
  const goBack = () => {
    if (view !== 'store') { setView('store'); setSelProd(null); setSelOrder(null); setStep(0); }
    else router.push('/dashboard');
  };

  // ── Topbar ──────────────────────────────────────────
  const Topbar = () => (
    <div style={S.topbar}>
      <div style={{ maxWidth:800, margin:'0 auto', display:'flex', alignItems:'center', justifyContent:'space-between', gap:12 }}>
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <button onClick={goBack} style={{ width:36, height:36, borderRadius:10, background:'rgba(255,255,255,0.06)', border:'1px solid rgba(255,255,255,0.1)', color:'#fff', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', fontSize:18 }}>←</button>
          <div>
            <div style={{ fontSize:18, fontWeight:900, letterSpacing:-0.5 }}>
              <span style={{ background:'linear-gradient(90deg,#60a5fa,#22d3ee)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>Prove</span>
              <span style={{ color:'#fff' }}>Store</span>
            </div>
            <div style={{ fontSize:10, color:'rgba(255,255,255,0.3)', marginTop:-2 }}>Study Materials</div>
          </div>
        </div>
        <div style={{ display:'flex', gap:6 }}>
          {[
            { icon:'🏪', id:'store', onClick:()=>setView('store') },
            { icon:'❤️', id:'wishlist', onClick:()=>{ loadWish(); setView('wishlist'); } },
            { icon:'📦', id:'orders', onClick:()=>{ loadOrders(); setView('orders'); } },
          ].map(b => (
            <button key={b.id} onClick={b.onClick} style={{ ...S.btnS, padding:'8px 10px', background: view===b.id ? 'rgba(37,99,235,0.3)' : 'rgba(255,255,255,0.05)', border: view===b.id ? '1px solid rgba(37,99,235,0.5)' : '1px solid rgba(255,255,255,0.08)' }}>{b.icon}</button>
          ))}
          <button onClick={()=>setView('cart')} style={{ display:'flex', alignItems:'center', gap:6, padding:'8px 12px', background:'rgba(37,99,235,0.2)', border:'1px solid rgba(37,99,235,0.4)', borderRadius:12, cursor:'pointer', color:'#fff', fontWeight:700, fontSize:13, position:'relative' }}>
            🛒 <span style={{ display:'none' }}>{fmtP(cart.total||0)}</span>
            {cart.itemCount > 0 && <span style={{ background:'#3b82f6', color:'#fff', borderRadius:'50%', width:18, height:18, fontSize:10, fontWeight:900, display:'flex', alignItems:'center', justifyContent:'center' }}>{cart.itemCount}</span>}
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div style={S.page}>
      {(failedPayment !== null && failedPayment !== undefined) && (
        <PaymentFailureModal
          paymentId={failedPayment.paymentId}
          amount={failedPayment.amount}
          onRetry={retryPaymentVerify}
          onClose={() => setFailedPayment(null)}
          retrying={retryingVerify}
        />
      )}
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={()=>setToast(null)} />}
      <Topbar />
      <div style={{ maxWidth:800, margin:'0 auto', padding:'20px 16px' }}>

        {/* ═══ STORE HOME ═══ */}
        {view === 'store' && (
          <div>
            {/* Hero */}
            <div style={{ borderRadius:20, padding:'28px 24px', marginBottom:24, background:'linear-gradient(135deg,rgba(37,99,235,0.2),rgba(14,165,233,0.1))', border:'1px solid rgba(96,165,250,0.2)', position:'relative', overflow:'hidden' }}>
              <div style={{ position:'absolute', top:-20, right:-20, width:120, height:120, borderRadius:'50%', background:'radial-gradient(circle,rgba(96,165,250,0.15),transparent)' }} />
              <span style={{ display:'inline-block', background:'rgba(96,165,250,0.15)', border:'1px solid rgba(96,165,250,0.3)', color:'#93c5fd', borderRadius:20, padding:'4px 12px', fontSize:11, fontWeight:600, marginBottom:12 }}>✨ Official NCERT Books & Study Material</span>
              <h2 style={{ fontSize:26, fontWeight:900, color:'#fff', margin:'0 0 8px', lineHeight:1.2 }}>Everything You Need<br /><span style={{ background:'linear-gradient(90deg,#60a5fa,#22d3ee)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>to Crack NEET</span></h2>
              <p style={{ color:'rgba(255,255,255,0.5)', fontSize:13, margin:'0 0 16px' }}>Books, Notes, Stationery — delivered to your door.</p>
              <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
                {['🚚 Free delivery above ₹499','↩️ 7-day easy returns','🔒 Secure COD & UPI payment'].map(f=>(
                  <span key={f} style={{ fontSize:12, color:'rgba(255,255,255,0.5)' }}>{f}</span>
                ))}
              </div>
            </div>

            {/* Featured */}
            {featured.length > 0 && (
              <div style={{ marginBottom:20 }}>
                <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:10 }}>⭐ Featured</p>
                <div style={{ display:'flex', gap:12, overflowX:'auto', paddingBottom:8 }}>
                  {featured.map((p:any) => (
                    <div key={p._id} onClick={()=>viewProduct(p)} style={{ flexShrink:0, width:140, cursor:'pointer', ...S.card, padding:10 }}>
                      {p.images?.[0]?.url
                        ? <img src={p.images[0].url} alt={p.name} style={{ width:'100%', height:100, objectFit:'cover', borderRadius:8, marginBottom:8 }} />
                        : <div style={{ width:'100%', height:100, background:'rgba(37,99,235,0.1)', borderRadius:8, display:'flex', alignItems:'center', justifyContent:'center', fontSize:32, marginBottom:8 }}>📚</div>}
                      <p style={{ fontSize:11, fontWeight:700, color:'#fff', marginBottom:4, display:'-webkit-box', WebkitLineClamp:2, WebkitBoxOrient:'vertical', overflow:'hidden' }}>{p.name}</p>
                      <p style={{ fontSize:13, fontWeight:900, color:'#60a5fa' }}>{fmtP(p.price)}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Filters */}
            <div style={{ ...S.card, padding:16, marginBottom:20 }}>
              <div style={{ position:'relative', marginBottom:12 }}>
                <span style={{ position:'absolute', left:12, top:'50%', transform:'translateY(-50%)', fontSize:16, color:'rgba(255,255,255,0.3)' }}>🔍</span>
                <input value={search} onChange={e=>{setSearch(e.target.value);setPage(1);}} placeholder="Search books, notes, stationery..." style={{ ...S.inp, paddingLeft:40 }} />
              </div>
              <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:10 }}>
                {['','Books','Notes','Stationery','Combo Pack','Other'].map(c=>(
                  <button key={c} onClick={()=>{setCatF(c);setPage(1);}} style={S.tag(catF===c,'#2563eb')}>{c||'All'}</button>
                ))}
              </div>
              <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:10 }}>
                {['','Physics','Chemistry','Biology','Mathematics'].map(s=>(
                  <button key={s} onClick={()=>{setSubF(s);setPage(1);}} style={S.tag(subF===s,'#0ea5e9')}>{s||'All Subjects'}</button>
                ))}
              </div>
              <select value={sortBy} onChange={e=>setSortBy(e.target.value)} style={S.sel}>
                <option value="newest">Newest First</option>
                <option value="price_asc">Price: Low → High</option>
                <option value="price_desc">Price: High → Low</option>
                <option value="rating">Top Rated</option>
                <option value="popular">Most Popular</option>
              </select>
            </div>

            <p style={{ fontSize:12, color:'rgba(255,255,255,0.3)', marginBottom:14 }}>{total} products found</p>

            {loading ? (
              <div style={{ display:'flex', justifyContent:'center', padding:60 }}>
                <div style={{ width:40, height:40, border:'3px solid rgba(37,99,235,0.3)', borderTop:'3px solid #3b82f6', borderRadius:'50%', animation:'spin 1s linear infinite' }} />
                <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
              </div>
            ) : products.length === 0 ? (
              <div style={{ ...S.card, padding:60, textAlign:'center' }}>
                <p style={{ fontSize:48, marginBottom:12 }}>📭</p>
                <p style={{ color:'rgba(255,255,255,0.4)', fontSize:16, fontWeight:600 }}>No products found</p>
                <p style={{ color:'rgba(255,255,255,0.25)', fontSize:13, margin:'8px 0 20px' }}>Products will appear after admin seeds them, or try clearing filters</p>
                <button onClick={()=>{setSearch('');setCatF('');setSubF('');setPage(1);}} style={S.btnS}>Clear Filters</button>
              </div>
            ) : (
              <div style={{ display:'grid', gridTemplateColumns:'repeat(2,1fr)', gap:12 }}>
                {products.map(p=>(
                  <PCard key={p._id} p={p} onView={viewProduct} onCart={addToCart} onWish={toggleWish} wished={wishIds.includes(p._id)} />
                ))}
              </div>
            )}

            {total > 12 && (
              <div style={{ display:'flex', justifyContent:'center', gap:10, marginTop:24 }}>
                <button onClick={()=>setPage(p=>Math.max(1,p-1))} disabled={page===1} style={{ ...S.btnS, opacity:page===1?0.3:1 }}>← Prev</button>
                <span style={{ color:'rgba(255,255,255,0.4)', fontSize:13, padding:'10px 0' }}>Page {page} / {Math.ceil(total/12)}</span>
                <button onClick={()=>setPage(p=>p+1)} disabled={page>=Math.ceil(total/12)} style={{ ...S.btnS, opacity:page>=Math.ceil(total/12)?0.3:1 }}>Next →</button>
              </div>
            )}

            <div style={{ marginTop:32, ...S.card2, padding:16, textAlign:'center' }}>
              <p style={{ fontSize:11, color:'#60a5fa', fontWeight:600, marginBottom:4 }}>📖 Did you know?</p>
              <p style={{ fontSize:12, color:'rgba(255,255,255,0.5)', lineHeight:1.6 }}>NCERT Biology Class 11 has 22 chapters. NEET 2024 had <strong style={{ color:'#fff' }}>90 biology questions</strong> — all directly from NCERT text.</p>
            </div>
          </div>
        )}

        {/* ═══ PRODUCT DETAIL ═══ */}
        {view === 'product' && selProd && (
          <div>
            {selProd.images?.[0]?.url
              ? <img src={selProd.images[0].url} alt={selProd.name} style={{ width:'100%', height:260, objectFit:'cover', borderRadius:16, marginBottom:16 }} />
              : <div style={{ width:'100%', height:200, background:'rgba(37,99,235,0.1)', borderRadius:16, display:'flex', alignItems:'center', justifyContent:'center', fontSize:60, marginBottom:16 }}>📚</div>}
            <div style={{ display:'flex', gap:8, marginBottom:10, flexWrap:'wrap' }}>
              {[selProd.category, selProd.subject, selProd.classLevel].map(t=>(
                <span key={t} style={{ background:'rgba(37,99,235,0.2)', border:'1px solid rgba(37,99,235,0.4)', color:'#93c5fd', borderRadius:8, padding:'3px 8px', fontSize:11, fontWeight:600 }}>{t}</span>
              ))}
            </div>
            <h1 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:6, lineHeight:1.3 }}>{selProd.name}</h1>
            {selProd.author && <p style={{ fontSize:13, color:'rgba(255,255,255,0.4)', marginBottom:10 }}>by {selProd.author} · {selProd.publisher}</p>}
            <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:6 }}>
              <Stars n={selProd.ratings?.average||0} />
              <span style={{ fontSize:13, color:'rgba(255,255,255,0.4)' }}>{selProd.ratings?.average?.toFixed(1)||'0.0'} ({selProd.ratings?.count||0} reviews)</span>
            </div>
            <div style={{ display:'flex', alignItems:'center', gap:12, marginBottom:8 }}>
              <span style={{ fontSize:32, fontWeight:900, color:'#fff' }}>{fmtP(selProd.price)}</span>
              {selProd.originalPrice > selProd.price && (
                <>
                  <span style={{ fontSize:16, color:'rgba(255,255,255,0.3)', textDecoration:'line-through' }}>{fmtP(selProd.originalPrice)}</span>
                  <span style={{ background:'rgba(16,185,129,0.2)', border:'1px solid rgba(16,185,129,0.4)', color:'#4ade80', padding:'3px 8px', borderRadius:8, fontSize:12, fontWeight:700 }}>{pct(selProd.originalPrice,selProd.price)}% off</span>
                </>
              )}
            </div>
            <p style={{ fontSize:13, color: selProd.deliveryCharge===0?'#4ade80':'rgba(255,255,255,0.4)', marginBottom:12 }}>
              🚚 {selProd.deliveryCharge===0?'Free Delivery':`Delivery: ₹${selProd.deliveryCharge}`}
            </p>
            <p style={{ fontSize:13, fontWeight:600, marginBottom:16, color: selProd.stock>10?'#4ade80':selProd.stock>0?'#fbbf24':'#f87171' }}>
              {selProd.stock>10?`✓ In Stock (${selProd.stock})`:`${selProd.stock>0?`⚠ Only ${selProd.stock} left!`:'✕ Out of Stock'}`}
            </p>
            <div style={{ display:'flex', gap:10, marginBottom:20 }}>
              <button onClick={()=>addToCart(selProd._id)} disabled={selProd.stock===0} style={{ ...S.btnP, flex:1, opacity:selProd.stock===0?0.5:1 }}>🛒 Add to Cart</button>
              <button onClick={()=>toggleWish(selProd._id)} style={{ ...S.btnS, padding:'12px 16px' }}>{wishIds.includes(selProd._id)?'❤️':'🤍'}</button>
            </div>

            {selProd.description && (
              <div style={{ ...S.card, padding:16, marginBottom:16 }}>
                <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:8 }}>About this Product</p>
                <p style={{ fontSize:13, color:'rgba(255,255,255,0.6)', lineHeight:1.7 }}>{selProd.description}</p>
                {selProd.features?.length>0 && (
                  <ul style={{ marginTop:12, paddingLeft:0, listStyle:'none' }}>
                    {selProd.features.map((f:string,i:number)=>(
                      <li key={i} style={{ fontSize:13, color:'rgba(255,255,255,0.6)', marginBottom:6 }}><span style={{ color:'#60a5fa' }}>✓</span> {f}</li>
                    ))}
                  </ul>
                )}
              </div>
            )}

            {/* Reviews */}
            <div style={{ ...S.card, padding:16 }}>
              <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:12 }}>Reviews ({reviews.length})</p>
              {reviews.map((r:any,i:number)=>(
                <div key={i} style={{ ...S.card2, padding:12, marginBottom:10 }}>
                  <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:6 }}>
                    <Stars n={r.rating} />
                    {r.isVerifiedPurchase && <span style={{ background:'rgba(16,185,129,0.15)', color:'#4ade80', fontSize:10, padding:'2px 6px', borderRadius:6, fontWeight:700 }}>✓ Verified</span>}
                  </div>
                  {r.title && <p style={{ fontSize:13, fontWeight:700, color:'#fff', marginBottom:4 }}>{r.title}</p>}
                  <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginBottom:6 }}>{r.student?.name} · {fmtD(r.createdAt)}</p>
                  <p style={{ fontSize:13, color:'rgba(255,255,255,0.6)' }}>{r.body}</p>
                </div>
              ))}
              {tok() && (
                <div style={{ ...S.card2, padding:12, marginTop:12 }}>
                  <p style={{ fontSize:13, fontWeight:700, color:'#fff', marginBottom:10 }}>Write a Review</p>
                  <div style={{ display:'flex', gap:8, marginBottom:10 }}>
                    {[1,2,3,4,5].map(n=>(
                      <button key={n} onClick={()=>setMyRating(n)} style={{ fontSize:24, background:'none', border:'none', cursor:'pointer', color: n<=myRating?'#fbbf24':'#374151' }}>★</button>
                    ))}
                  </div>
                  <input value={myReview.title} onChange={e=>setMyReview(p=>({...p,title:e.target.value}))} placeholder="Review title" style={{ ...S.inp, marginBottom:8 }} />
                  <textarea value={myReview.body} onChange={e=>setMyReview(p=>({...p,body:e.target.value}))} rows={3} placeholder="Your experience..." style={{ ...S.inp, resize:'none', marginBottom:10 }} />
                  <button onClick={submitReview} style={S.btnP}>Submit Review</button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ═══ CART ═══ */}
        {view === 'cart' && (
          <div>
            <h2 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:20 }}>🛒 Cart</h2>
            {cart.items?.length===0 ? (
              <div style={{ ...S.card, padding:60, textAlign:'center' }}>
                <p style={{ fontSize:48, marginBottom:12 }}>🛒</p>
                <p style={{ color:'rgba(255,255,255,0.4)', fontSize:16, fontWeight:600, marginBottom:16 }}>Cart is empty</p>
                <button onClick={()=>setView('store')} style={S.btnP}>Browse Store</button>
              </div>
            ) : (
              <>
                {cart.items?.map((item:any)=>(
                  <div key={item.product._id} style={{ ...S.card, padding:14, marginBottom:12, display:'flex', gap:12 }}>
                    {item.product.images?.[0]?.url
                      ? <img src={item.product.images[0].url} alt="" style={{ width:60, height:72, objectFit:'cover', borderRadius:10, flexShrink:0 }} />
                      : <div style={{ width:60, height:72, background:'rgba(37,99,235,0.1)', borderRadius:10, display:'flex', alignItems:'center', justifyContent:'center', fontSize:24 }}>📚</div>}
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:13, fontWeight:700, color:'#fff', marginBottom:4 }}>{item.product.name}</p>
                      <p style={{ fontSize:13, fontWeight:900, color:'#60a5fa', marginBottom:8 }}>{fmtP(item.product.price)}</p>
                      <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                        <button onClick={()=>updateQty(item.product._id,item.quantity-1)} style={{ width:28, height:28, borderRadius:8, background:'rgba(255,255,255,0.1)', border:'none', color:'#fff', fontSize:16, cursor:'pointer' }}>−</button>
                        <span style={{ color:'#fff', fontWeight:700, width:24, textAlign:'center' }}>{item.quantity}</span>
                        <button onClick={()=>updateQty(item.product._id,item.quantity+1)} style={{ width:28, height:28, borderRadius:8, background:'rgba(255,255,255,0.1)', border:'none', color:'#fff', fontSize:16, cursor:'pointer' }}>+</button>
                        <span style={{ color:'#4ade80', fontWeight:700, marginLeft:8 }}>{fmtP(item.product.price*item.quantity)}</span>
                        <button onClick={()=>removeItem(item.product._id)} style={{ marginLeft:'auto', background:'none', border:'none', color:'rgba(239,68,68,0.6)', cursor:'pointer', fontSize:18 }}>🗑</button>
                      </div>
                    </div>
                  </div>
                ))}
                {/* Coupon */}
                <div style={{ ...S.card, padding:14, marginBottom:12 }}>
                  <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:8 }}>COUPON CODE</p>
                  {cart.couponCode
                    ? <div style={{ display:'flex', justifyContent:'space-between', background:'rgba(16,185,129,0.1)', border:'1px solid rgba(16,185,129,0.3)', borderRadius:10, padding:'10px 14px' }}>
                        <span style={{ color:'#4ade80', fontWeight:700 }}>{cart.couponCode} — −{fmtP(cart.couponDiscount)}</span>
                        <button onClick={async()=>{ await fetch(`${API}/api/store/coupon/remove`,{method:'POST',headers:hdr()}); setCouponInput(''); loadCart(); }} style={{ background:'none', border:'none', color:'#f87171', cursor:'pointer', fontSize:12 }}>Remove</button>
                      </div>
                    : <div style={{ display:'flex', gap:8 }}>
                        <input value={couponInput} onChange={e=>setCouponInput(e.target.value.toUpperCase())} placeholder="Enter coupon code" style={{ ...S.inp, flex:1 }} />
                        <button onClick={applyCoupon} style={S.btnP}>Apply</button>
                      </div>}
                </div>
                {/* Bill */}
                <div style={{ ...S.card, padding:14, marginBottom:16 }}>
                  <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:12 }}>Bill Summary</p>
                  {[['Subtotal', fmtP(cart.subtotal)],['Delivery', cart.deliveryCharge>0?fmtP(cart.deliveryCharge):'Free']].map(([k,v])=>(
                    <div key={k} style={{ display:'flex', justifyContent:'space-between', fontSize:13, color:'rgba(255,255,255,0.5)', marginBottom:8 }}><span>{k}</span><span>{v}</span></div>
                  ))}
                  {cart.couponDiscount>0 && <div style={{ display:'flex', justifyContent:'space-between', fontSize:13, color:'#4ade80', marginBottom:8 }}><span>Coupon</span><span>−{fmtP(cart.couponDiscount)}</span></div>}
                  <div style={{ display:'flex', justifyContent:'space-between', fontSize:18, fontWeight:900, color:'#fff', borderTop:'1px solid rgba(255,255,255,0.1)', paddingTop:10, marginTop:4 }}><span>Total</span><span>{fmtP(cart.total)}</span></div>
                </div>
                <button onClick={()=>setView('checkout')} style={{ ...S.btnP, width:'100%', padding:16, fontSize:16 }}>Proceed to Checkout →</button>
              </>
            )}
          </div>
        )}

        {/* ═══ CHECKOUT ═══ */}
        {view === 'checkout' && (
          <div>
            <h2 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:20 }}>Checkout</h2>
            <div style={{ display:'flex', gap:8, marginBottom:24 }}>
              {['Address','Payment','Confirm'].map((s,i)=>(
                <div key={s} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:4 }}>
                  <div style={{ width:28, height:28, borderRadius:'50%', display:'flex', alignItems:'center', justifyContent:'center', fontSize:12, fontWeight:900, background: i<step?'#2563eb':i===step?'transparent':'transparent', border: i===step?'2px solid #60a5fa':i<step?'none':'2px solid rgba(255,255,255,0.15)', color: i<=step?'#60a5fa':'rgba(255,255,255,0.3)' }}>{i<step?'✓':i+1}</div>
                  <span style={{ fontSize:10, color:i<=step?'rgba(255,255,255,0.7)':'rgba(255,255,255,0.3)', fontWeight:600 }}>{s}</span>
                </div>
              ))}
            </div>

            {step === 0 && (
              <div style={{ ...S.card, padding:16 }}>
                <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:14 }}>Delivery Address</p>
                <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
                  {[['fullName','Full Name *'],['phone','Phone *'],['addressLine1','Address Line 1 *'],['addressLine2','Address Line 2'],['city','City *'],['pincode','Pincode *']].map(([k,pl])=>(
                    <div key={k} style={{ gridColumn: ['addressLine1','addressLine2'].includes(k)?'1/-1':'auto' }}>
                      <label style={{ fontSize:11, color:'rgba(255,255,255,0.4)', marginBottom:4, display:'block' }}>{pl}</label>
                      <input value={(addr as any)[k]} onChange={e=>setA(k,e.target.value)} placeholder={pl.replace(' *','')} style={S.inp} />
                    </div>
                  ))}
                  <div>
                    <label style={{ fontSize:11, color:'rgba(255,255,255,0.4)', marginBottom:4, display:'block' }}>State *</label>
                    <select value={addr.state} onChange={e=>setA('state',e.target.value)} style={S.sel}>
                      <option value="">Select State</option>
                      {['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Delhi','Goa','Gujarat','Haryana','Himachal Pradesh','Jammu & Kashmir','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal'].map(s=><option key={s}>{s}</option>)}
                    </select>
                  </div>
                </div>
                <button onClick={()=>{
                  if (!addr.fullName||!addr.phone||!addr.addressLine1||!addr.city||!addr.state||!addr.pincode){T('Fill all required fields','error');return;}
                  if (!addr.phone.match(/^[6-9]\d{9}$/)){T('Invalid phone number','error');return;}
                  setStep(1);
                }} style={{ ...S.btnP, width:'100%', padding:14, marginTop:16 }}>Continue to Payment →</button>
              </div>
            )}
            {step === 1 && (
              <div style={{ ...S.card, padding:16 }}>
                <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:14 }}>Payment Method</p>
                {[{id:'COD',label:'Cash on Delivery',desc:'Pay when delivered',icon:'💵'},{id:'UPI',label:'UPI / Card / NetBanking',desc:'GPay, PhonePe, Paytm, Visa, Mastercard',icon:'💳'}].map(pm=>(
                  <div key={pm.id} onClick={()=>setPayM(pm.id)} style={{ display:'flex', alignItems:'center', gap:14, padding:14, borderRadius:12, marginBottom:10, cursor:'pointer', border:`1px solid ${payM===pm.id?'rgba(37,99,235,0.6)':'rgba(255,255,255,0.08)'}`, background: payM===pm.id?'rgba(37,99,235,0.1)':'rgba(255,255,255,0.02)' }}>
                    <span style={{ fontSize:28 }}>{pm.icon}</span>
                    <div style={{ flex:1 }}>
                      <p style={{ fontSize:13, fontWeight:700, color:'#fff', marginBottom:2 }}>{pm.label}</p>
                      <p style={{ fontSize:11, color:'rgba(255,255,255,0.4)' }}>{pm.desc}</p>
                    </div>
                    <div style={{ width:20, height:20, borderRadius:'50%', border:`2px solid ${payM===pm.id?'#60a5fa':'rgba(255,255,255,0.2)'}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
                      {payM===pm.id && <div style={{ width:10, height:10, borderRadius:'50%', background:'#60a5fa' }} />}
                    </div>
                  </div>
                ))}
                <div style={{ display:'flex', gap:10, marginTop:16 }}>
                  <button onClick={()=>setStep(0)} style={{ ...S.btnS, flex:1 }}>← Back</button>
                  <button onClick={()=>setStep(2)} style={{ ...S.btnP, flex:1 }}>Review Order →</button>
                </div>
              </div>
            )}
            {step === 2 && (
              <div>
                <div style={{ ...S.card, padding:14, marginBottom:12 }}>
                  <p style={{ fontSize:13, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:8 }}>ORDER ITEMS</p>
                  {cart.items?.map((item:any,i:number)=>(
                    <div key={i} style={{ display:'flex', justifyContent:'space-between', fontSize:13, padding:'6px 0', borderBottom:'1px solid rgba(255,255,255,0.05)' }}>
                      <span style={{ color:'rgba(255,255,255,0.7)' }}>{item.product.name} × {item.quantity}</span>
                      <span style={{ color:'#fff', fontWeight:700 }}>{fmtP(item.product.price*item.quantity)}</span>
                    </div>
                  ))}
                  <div style={{ display:'flex', justifyContent:'space-between', fontSize:18, fontWeight:900, color:'#fff', paddingTop:10, marginTop:4 }}><span>Total</span><span>{fmtP(cart.total)}</span></div>
                </div>
                <div style={{ ...S.card, padding:14, marginBottom:12 }}>
                  <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:6 }}>SHIPPING TO</p>
                  <p style={{ fontSize:13, color:'#fff', fontWeight:700 }}>{addr.fullName} · {addr.phone}</p>
                  <p style={{ fontSize:12, color:'rgba(255,255,255,0.5)' }}>{addr.addressLine1}, {addr.city}, {addr.state} — {addr.pincode}</p>
                </div>
                <div style={{ ...S.card, padding:14, marginBottom:16 }}>
                  <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:4 }}>PAYMENT</p>
                  <p style={{ fontSize:13, color:'#fff', fontWeight:700 }}>{payM==='COD'?'💵 Cash on Delivery':'📱 UPI Payment'}</p>
                </div>
                <div style={{ display:'flex', gap:10 }}>
                  <button onClick={()=>setStep(1)} style={{ ...S.btnS, flex:1 }}>← Back</button>
                  <button onClick={placeOrder} disabled={placing} style={{ ...S.btnP, flex:2, padding:16, opacity:placing?0.6:1 }}>{placing ? '⏳ Placing...' : '🎉 Place Order — ' + fmtP(cart.total)}</button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ═══ ORDERS ═══ */}
        {view === 'orders' && !selOrder && (
          <div>
            <h2 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:20 }}>📦 My Orders</h2>
            {orders.length===0
              ? <div style={{ ...S.card, padding:60, textAlign:'center' }}>
                  <p style={{ fontSize:48, marginBottom:12 }}>📦</p>
                  <p style={{ color:'rgba(255,255,255,0.4)', fontSize:16, fontWeight:600, marginBottom:16 }}>No orders yet</p>
                  <button onClick={()=>setView('store')} style={S.btnP}>Start Shopping</button>
                </div>
              : orders.map((o:any)=>(
                  <div key={o._id} onClick={()=>setSelOrder(o)} style={{ ...S.card, padding:14, marginBottom:12, cursor:'pointer' }}>
                    <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8 }}>
                      <div>
                        <p style={{ fontFamily:'monospace', color:'#60a5fa', fontSize:13, fontWeight:700 }}>{o.orderId}</p>
                        <p style={{ fontSize:11, color:'rgba(255,255,255,0.4)' }}>{fmtD(o.createdAt)} · {o.items?.length} item(s)</p>
                      </div>
                      <div style={{ textAlign:'right' }}>
                        <p style={{ fontSize:16, fontWeight:900, color:'#fff' }}>{fmtP(o.pricing?.total||0)}</p>
                        <span style={{ fontSize:11, fontWeight:600, padding:'2px 8px', borderRadius:10, background:'rgba(37,99,235,0.2)', color:'#93c5fd' }}>{o.status}</span>
                      </div>
                    </div>
                    <p style={{ fontSize:11, color:'rgba(255,255,255,0.35)', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{o.items?.map((i:any)=>i.name).join(', ')}</p>
                  </div>
                ))}
          </div>
        )}

        {/* Order Detail */}
        {view==='orders' && selOrder && (
          <div>
            <button onClick={()=>setSelOrder(null)} style={{ ...S.btnS, marginBottom:16 }}>← Back to Orders</button>
            <h2 style={{ fontSize:18, fontWeight:900, color:'#fff', marginBottom:4 }}>Order {selOrder.orderId}</h2>
            <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginBottom:16 }}>{fmtD(selOrder.createdAt)}</p>
            <div style={{ ...S.card, padding:14, marginBottom:12 }}>
              <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:8 }}>ITEMS</p>
              {selOrder.items?.map((item:any,i:number)=>(
                <div key={i} style={{ display:'flex', justifyContent:'space-between', fontSize:13, padding:'6px 0', borderBottom:'1px solid rgba(255,255,255,0.05)' }}>
                  <span style={{ color:'rgba(255,255,255,0.7)' }}>{item.name} × {item.quantity}</span>
                  <span style={{ color:'#fff', fontWeight:700 }}>{fmtP(item.price*item.quantity)}</span>
                </div>
              ))}
              <div style={{ display:'flex', justifyContent:'space-between', fontSize:16, fontWeight:900, color:'#fff', paddingTop:10 }}><span>Total</span><span>{fmtP(selOrder.pricing?.total||0)}</span></div>
            </div>
            <div style={{ ...S.card, padding:14, marginBottom:12 }}>
              <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:6 }}>DELIVERY TO</p>
              <p style={{ fontSize:13, color:'#fff', fontWeight:700 }}>{selOrder.shippingAddress?.fullName} · {selOrder.shippingAddress?.phone}</p>
              <p style={{ fontSize:12, color:'rgba(255,255,255,0.5)' }}>{selOrder.shippingAddress?.addressLine1}, {selOrder.shippingAddress?.city} — {selOrder.shippingAddress?.pincode}</p>
            </div>
            <div style={{ ...S.card, padding:14, marginBottom:12 }}>
              <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:600, marginBottom:6 }}>STATUS</p>
              <span style={{ background:'rgba(37,99,235,0.2)', border:'1px solid rgba(37,99,235,0.4)', color:'#93c5fd', padding:'4px 12px', borderRadius:8, fontWeight:700, fontSize:13 }}>{selOrder.status}</span>
              {selOrder.trackingNumber && <p style={{ fontSize:12, color:'#60a5fa', marginTop:8 }}>📦 Tracking: {selOrder.trackingNumber}</p>}
            </div>
            {['pending','confirmed'].includes(selOrder.status) && (
              <button onClick={async()=>{ if(!confirm('Cancel this order?'))return; const r=await fetch(`${API}/api/store/orders/${selOrder._id}/cancel`,{method:'POST',headers:hdr(),body:JSON.stringify({reason:'Cancelled by student'})}); const d=await r.json(); T(d.message,r.ok?'success':'error'); if(r.ok){loadOrders();setSelOrder(null);}}} style={{ width:'100%', padding:14, borderRadius:12, border:'1px solid rgba(239,68,68,0.4)', background:'rgba(239,68,68,0.1)', color:'#f87171', fontWeight:700, cursor:'pointer', fontSize:13 }}>Cancel Order</button>
            )}
          </div>
        )}

        {/* ═══ WISHLIST ═══ */}
        {view === 'wishlist' && (
          <div>
            <h2 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:20 }}>❤️ Wishlist</h2>
            {!wishlist || wishlist.length === 0
              ? <div style={{ ...S.card, padding:60, textAlign:'center' }}>
                  <p style={{ fontSize:48, marginBottom:12 }}>🤍</p>
                  <p style={{ color:'rgba(255,255,255,0.4)', fontSize:16, fontWeight:600, marginBottom:16 }}>Wishlist empty</p>
                  <p style={{ color:'rgba(255,255,255,0.25)', fontSize:13, marginBottom:20 }}>
                    Go to Store and tap ❤️ on any product
                  </p>
                  <button onClick={()=>setView('store')} style={S.btnP}>Browse Store</button>
                </div>
              : <div style={{ display:'grid', gridTemplateColumns:'repeat(2,1fr)', gap:12 }}>
                  {wishlist.map((p: any) => (
                    <PCard
                      key={p._id}
                      p={p}
                      onView={viewProduct}
                      onCart={addToCart}
                      onWish={toggleWish}
                      wished={wishIds.includes(p._id)}
                    />
                  ))}
                </div>
            }
          </div>
        )}

      </div>
    </div>
  );
}
