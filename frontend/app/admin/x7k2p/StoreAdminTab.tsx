'use client';
import { useState, useEffect, useCallback } from 'react';

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com';
const tok = () => typeof window !== 'undefined' ? localStorage.getItem('pr_token') || '' : '';
const hdr = () => ({ 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}` });
const fmtP = (n: number) => '₹' + (n||0).toLocaleString('en-IN');
const fmtD = (d: string) => new Date(d).toLocaleDateString('en-IN', { day:'numeric', month:'short', year:'numeric' });

const S = {
  page:  { minHeight:'100vh', color:'#fff', fontFamily:"'Inter',sans-serif", padding:'0 0 40px' } as React.CSSProperties,
  card:  { background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.1)', borderRadius:16, padding:20 } as React.CSSProperties,
  card2: { background:'rgba(255,255,255,0.03)', border:'1px solid rgba(255,255,255,0.07)', borderRadius:12, padding:14 } as React.CSSProperties,
  btnP:  { background:'linear-gradient(135deg,#2563eb,#0ea5e9)', color:'#fff', border:'none', borderRadius:10, padding:'10px 18px', fontWeight:700, fontSize:13, cursor:'pointer' } as React.CSSProperties,
  btnS:  { background:'rgba(255,255,255,0.07)', color:'rgba(255,255,255,0.7)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:10, padding:'9px 14px', fontWeight:600, fontSize:12, cursor:'pointer' } as React.CSSProperties,
  btnD:  { background:'rgba(239,68,68,0.15)', color:'#f87171', border:'1px solid rgba(239,68,68,0.3)', borderRadius:10, padding:'9px 14px', fontWeight:600, fontSize:12, cursor:'pointer' } as React.CSSProperties,
  inp:   { width:'100%', background:'rgba(255,255,255,0.06)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:10, padding:'10px 14px', color:'#fff', fontSize:13, outline:'none', boxSizing:'border-box' } as React.CSSProperties,
  sel:   { width:'100%', background:'#060d1f', border:'1px solid rgba(255,255,255,0.12)', borderRadius:10, padding:'10px 14px', color:'#fff', fontSize:13, outline:'none' } as React.CSSProperties,
  label: { fontSize:11, color:'rgba(255,255,255,0.4)', marginBottom:4, display:'block', fontWeight:600 } as React.CSSProperties,
  th:    { textAlign:'left' as const, padding:'10px 14px', fontSize:11, color:'rgba(255,255,255,0.35)', fontWeight:600, borderBottom:'1px solid rgba(255,255,255,0.08)' },
  td:    { padding:'12px 14px', fontSize:13, borderBottom:'1px solid rgba(255,255,255,0.05)' },
};

const STATUS_COLOR: Record<string,string> = {
  pending:'rgba(234,179,8,0.2)', confirmed:'rgba(59,130,246,0.2)', packed:'rgba(139,92,246,0.2)',
  shipped:'rgba(14,165,233,0.2)', out_for_delivery:'rgba(249,115,22,0.2)', delivered:'rgba(34,197,94,0.2)',
  cancelled:'rgba(239,68,68,0.2)', returned:'rgba(107,114,128,0.2)', refunded:'rgba(20,184,166,0.2)',
};
const STATUS_TEXT: Record<string,string> = {
  pending:'#fde047', confirmed:'#93c5fd', packed:'#c4b5fd', shipped:'#67e8f9',
  out_for_delivery:'#fdba74', delivered:'#86efac', cancelled:'#fca5a5', returned:'#d1d5db', refunded:'#5eead4',
};

function Toast({ msg, type, onClose }: { msg:string; type:string; onClose:()=>void }) {
  useEffect(() => { const t = setTimeout(onClose, 3500); return () => clearTimeout(t); }, [onClose]);
  const bg = type==='success'?'#16a34a':type==='error'?'#dc2626':'#2563eb';
  return <div style={{ position:'fixed', top:20, right:20, zIndex:9999, background:bg, color:'#fff', padding:'12px 20px', borderRadius:12, fontWeight:600, fontSize:13, boxShadow:'0 8px 32px rgba(0,0,0,0.5)' }}>{type==='success'?'✓ ':type==='error'?'✕ ':'ℹ '}{msg}</div>;
}

export default function StoreAdminTab() {
  const [view, setView] = useState<'dashboard'|'products'|'orders'|'coupons'|'inventory'|'reviews'>('dashboard');
  const [toast, setToast] = useState<{msg:string;type:string}|null>(null);
  const T = (msg:string, type='success') => setToast({msg,type});

  const tabs = [
    {id:'dashboard',label:'📊 Dashboard'},{id:'products',label:'📦 Products'},
    {id:'orders',label:'🚚 Orders'},{id:'coupons',label:'🎟 Coupons'},
    {id:'inventory',label:'🗄 Inventory'},{id:'reviews',label:'⭐ Reviews'},
  ];

  return (
    <div style={S.page}>
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={()=>setToast(null)} />}
      {/* Header */}
      <div style={{ background:'linear-gradient(135deg,rgba(37,99,235,0.2),rgba(14,165,233,0.1))', borderBottom:'1px solid rgba(255,255,255,0.08)', padding:'20px 24px', marginBottom:20 }}>
        <div style={{ display:'flex', alignItems:'center', gap:14 }}>
          <div style={{ width:48, height:48, borderRadius:14, background:'linear-gradient(135deg,#1d4ed8,#0ea5e9)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:22 }}>🛒</div>
          <div>
            <h1 style={{ fontSize:20, fontWeight:900, color:'#fff', margin:0 }}>ProveRank Store</h1>
            <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', margin:0 }}>Physical Study Material Management</p>
          </div>
        </div>
        {/* Tab nav */}
        <div style={{ display:'flex', gap:6, marginTop:16, flexWrap:'wrap' }}>
          {tabs.map(t => (
            <button key={t.id} onClick={()=>setView(t.id as any)} style={{ padding:'8px 14px', borderRadius:10, fontSize:12, fontWeight:700, cursor:'pointer', border:'none', background:view===t.id?'rgba(37,99,235,0.5)':'rgba(255,255,255,0.06)', color:view===t.id?'#93c5fd':'rgba(255,255,255,0.5)', transition:'all 0.2s' }}>{t.label}</button>
          ))}
        </div>
      </div>

      <div style={{ padding:'0 20px' }}>
        {view==='dashboard'  && <Dashboard T={T} />}
        {view==='products'   && <Products T={T} />}
        {view==='orders'     && <Orders T={T} />}
        {view==='coupons'    && <Coupons T={T} />}
        {view==='inventory'  && <Inventory T={T} />}
        {view==='reviews'    && <Reviews T={T} />}
      </div>
    </div>
  );
}

// ── DASHBOARD ─────────────────────────────────────────
function Dashboard({ T }: { T:(m:string,t?:string)=>void }) {
  const [data, setData] = useState<any>(null);
  const [seeding, setSeeding] = useState(false);
  useEffect(() => { fetch(`${API}/api/admin/store/analytics`,{headers:hdr()}).then(r=>r.json()).then(setData).catch(()=>T('Failed to load','error')); }, []);
  const seed = async () => { setSeeding(true); const r=await fetch(`${API}/api/admin/store/seed`,{method:'POST',headers:hdr(),body:JSON.stringify({})}); const d=await r.json(); T(d.message,r.ok?'success':'error'); setSeeding(false); };
  const ov = data?.overview||{};
  const stats = [
    {label:'Total Products',val:ov.totalProducts||0,sub:`${ov.activeProducts||0} active`,icon:'📦',c:'#3b82f6'},
    {label:'Total Orders',val:ov.totalOrders||0,sub:`${ov.pendingOrders||0} pending`,icon:'🚚',c:'#8b5cf6'},
    {label:'Revenue (Paid)',val:fmtP(ov.totalRevenue||0),sub:`${ov.deliveredOrders||0} delivered`,icon:'💰',c:'#10b981'},
    {label:'Out of Stock',val:ov.outOfStock||0,sub:'products',icon:'⚠️',c:'#f59e0b'},
  ];
  return (
    <div>
      <div style={{ display:'grid', gridTemplateColumns:'repeat(2,1fr)', gap:12, marginBottom:20 }}>
        {stats.map((s,i) => (
          <div key={i} style={{ ...S.card }}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10 }}>
              <span style={{ fontSize:20 }}>{s.icon}</span>
              <span style={{ fontSize:10, color:'rgba(255,255,255,0.3)', fontWeight:700, textTransform:'uppercase', letterSpacing:1 }}>{s.label}</span>
            </div>
            <p style={{ fontSize:22, fontWeight:900, color:'#fff', margin:'0 0 2px' }}>{s.val}</p>
            <p style={{ fontSize:11, color:'rgba(255,255,255,0.4)', margin:0 }}>{s.sub}</p>
          </div>
        ))}
      </div>

      {/* Recent Orders */}
      <div style={{ ...S.card, marginBottom:16 }}>
        <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:14 }}>🕐 Recent Orders</p>
        <div style={{ overflowX:'auto' }}>
          <table style={{ width:'100%', borderCollapse:'collapse' }}>
            <thead><tr><th style={S.th}>Order ID</th><th style={S.th}>Student</th><th style={S.th}>Amount</th><th style={S.th}>Status</th><th style={S.th}>Date</th></tr></thead>
            <tbody>
              {data?.recentOrders?.length ? data.recentOrders.map((o:any,i:number)=>(
                <tr key={i} style={{ background:'rgba(255,255,255,0.01)' }}>
                  <td style={{ ...S.td, color:'#60a5fa', fontFamily:'monospace', fontSize:11 }}>{o.orderId}</td>
                  <td style={{ ...S.td, color:'rgba(255,255,255,0.7)' }}>{o.student?.name||'—'}</td>
                  <td style={{ ...S.td, color:'#4ade80', fontWeight:700 }}>{fmtP(o.pricing?.total||0)}</td>
                  <td style={S.td}><span style={{ background:STATUS_COLOR[o.status]||'rgba(255,255,255,0.1)', color:STATUS_TEXT[o.status]||'#fff', borderRadius:8, padding:'3px 8px', fontSize:11, fontWeight:700 }}>{o.status}</span></td>
                  <td style={{ ...S.td, color:'rgba(255,255,255,0.35)', fontSize:11 }}>{fmtD(o.createdAt)}</td>
                </tr>
              )) : <tr><td colSpan={5} style={{ padding:24, textAlign:'center', color:'rgba(255,255,255,0.3)', fontSize:13 }}>No orders yet</td></tr>}
            </tbody>
          </table>
        </div>
      </div>

      {/* Top Products */}
      {data?.topProducts?.length > 0 && (
        <div style={{ ...S.card, marginBottom:16 }}>
          <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:12 }}>🏆 Top Selling</p>
          {data.topProducts.map((p:any,i:number)=>(
            <div key={i} style={{ display:'flex', alignItems:'center', gap:10, padding:'8px 0', borderBottom:'1px solid rgba(255,255,255,0.05)' }}>
              <span style={{ fontSize:18, fontWeight:900, color:'rgba(255,255,255,0.2)', width:20 }}>{i+1}</span>
              <div style={{ flex:1 }}>
                <p style={{ fontSize:13, fontWeight:600, color:'#fff', margin:0 }}>{p.name}</p>
                <p style={{ fontSize:11, color:'rgba(255,255,255,0.35)', margin:0 }}>{p.totalSold} sold · {fmtP(p.revenue)}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Seed */}
      <div style={{ ...S.card }}>
        <p style={{ fontSize:14, fontWeight:700, color:'#fff', marginBottom:6 }}>🌱 Quick Start — Add Sample Products</p>
        <p style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginBottom:14 }}>Add 2 sample NCERT books to get started. You can add any book/product from the Products tab.</p>
        <button onClick={seed} disabled={seeding} style={{ ...S.btnP, opacity:seeding?0.6:1 }}>{seeding?'Seeding...':'🌱 Add Sample Books'}</button>
        <span style={{ fontSize:11, color:'rgba(255,255,255,0.3)', marginLeft:12 }}>Or use Products → Add Product to add any book</span>
      </div>
    </div>
  );
}

// ── PRODUCTS ─────────────────────────────────────────
function Products({ T }: { T:(m:string,t?:string)=>void }) {
  const [products, setProducts] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [catF, setCatF] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState<any>({
    name:'', description:'', shortDescription:'', category:'Books', subject:'All Subjects',
    classLevel:'All', examType:'All', price:'', originalPrice:'', stock:'100',
    author:'', publisher:'', edition:'', language:'English', pages:'', weight:'',
    isbn:'', deliveryTime:'3-5 business days', returnPolicy:'7 days return',
    deliveryCharge:'49', freeDeliveryAbove:'499',
    isFeatured:false, isNew:true, isBestSeller:false, isActive:true,
    images:[{url:'',alt:''}], features:[''], tags:''
  });

  const load = useCallback(() => {
    const p = new URLSearchParams({ page:String(page), limit:'12', ...(search&&{search}), ...(catF&&{category:catF}) });
    fetch(`${API}/api/admin/store/products?${p}`,{headers:hdr()}).then(r=>r.json()).then(d=>{setProducts(d.products||[]);setTotal(d.total||0);});
  }, [page, search, catF]);
  useEffect(()=>{ load(); }, [load]);

  const openCreate = () => { setEditing(null); setForm({ name:'', description:'', shortDescription:'', category:'Books', subject:'All Subjects', classLevel:'All', examType:'All', price:'', originalPrice:'', stock:'100', author:'', publisher:'', edition:'', language:'English', pages:'', weight:'', isbn:'', deliveryTime:'3-5 business days', returnPolicy:'7 days return', deliveryCharge:'49', freeDeliveryAbove:'499', isFeatured:false, isNew:true, isBestSeller:false, isActive:true, images:[{url:'',alt:''}], features:[''], tags:'' }); setShowForm(true); };
  const openEdit = (p:any) => { setEditing(p); setForm({...p, tags:p.tags?.join(', ')||'', features:p.features?.length?p.features:[''], images:p.images?.length?p.images:[{url:'',alt:''}]}); setShowForm(true); };
  const save = async () => {
    const payload = { ...form, price:parseFloat(form.price), originalPrice:parseFloat(form.originalPrice), stock:parseInt(form.stock), pages:parseInt(form.pages)||undefined, weight:parseInt(form.weight)||undefined, deliveryCharge:parseFloat(form.deliveryCharge)||49, freeDeliveryAbove:parseFloat(form.freeDeliveryAbove)||499, tags:form.tags.split(',').map((t:string)=>t.trim()).filter(Boolean), features:form.features.filter((f:string)=>f.trim()), images:form.images.filter((img:any)=>img.url) };
    const url = editing?`${API}/api/admin/store/products/${editing._id}`:`${API}/api/admin/store/products`;
    const r = await fetch(url,{method:editing?'PUT':'POST',headers:hdr(),body:JSON.stringify(payload)});
    const d = await r.json(); T(d.message,r.ok?'success':'error'); if(r.ok){setShowForm(false);load();}
  };
  const del = async (id:string) => { if(!confirm('Delete?'))return; const r=await fetch(`${API}/api/admin/store/products/${id}`,{method:'DELETE',headers:hdr()}); T((await r.json()).message,r.ok?'success':'error'); if(r.ok)load(); };
  const toggle = async (id:string,field:string) => { await fetch(`${API}/api/admin/store/products/${id}/toggle`,{method:'PATCH',headers:hdr(),body:JSON.stringify({field})}); load(); };
  const setF = (k:string,v:any) => setForm((p:any)=>({...p,[k]:v}));
  const disc = form.originalPrice&&form.price?Math.round(((parseFloat(form.originalPrice)-parseFloat(form.price))/parseFloat(form.originalPrice))*100):0;

  const cats = ['Books','Notes','Stationery','Lab Equipment','Combo Pack','Digital','Other'];
  const subs = ['Physics','Chemistry','Biology','Mathematics','All Subjects','Other'];

  return (
    <div>
      <div style={{ display:'flex', gap:10, marginBottom:16, flexWrap:'wrap' }}>
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search products..." style={{ ...S.inp, flex:1, minWidth:160 }} />
        <select value={catF} onChange={e=>setCatF(e.target.value)} style={{ ...S.sel, width:'auto' }}>
          <option value="">All Categories</option>
          {cats.map(c=><option key={c}>{c}</option>)}
        </select>
        <button onClick={openCreate} style={S.btnP}>+ Add Product</button>
      </div>
      <p style={{ fontSize:12, color:'rgba(255,255,255,0.35)', marginBottom:12 }}>{total} products</p>

      {products.length===0 ? (
        <div style={{ ...S.card, textAlign:'center', padding:40 }}>
          <p style={{ fontSize:36, marginBottom:8 }}>📦</p>
          <p style={{ color:'rgba(255,255,255,0.4)', marginBottom:16 }}>No products yet. Add your first product!</p>
          <button onClick={openCreate} style={S.btnP}>+ Add Product</button>
        </div>
      ) : (
        <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(220px,1fr))', gap:12, marginBottom:16 }}>
          {products.map(p=>(
            <div key={p._id} style={{ ...S.card, padding:0, overflow:'hidden' }}>
              <div style={{ position:'relative', height:130, background:'linear-gradient(135deg,rgba(37,99,235,0.15),rgba(14,165,233,0.08))', display:'flex',alignItems:'center',justifyContent:'center' }}>
                {p.images?.[0]?.url?<img src={p.images[0].url} alt={p.name} style={{ width:'100%',height:'100%',objectFit:'cover' }} />:<span style={{ fontSize:40 }}>📚</span>}
                {p.discountPercent>0&&<span style={{ position:'absolute',top:6,right:6,background:'#ef4444',color:'#fff',fontSize:10,fontWeight:800,padding:'2px 6px',borderRadius:8 }}>{p.discountPercent}% OFF</span>}
                <div style={{ position:'absolute',top:6,left:6,display:'flex',gap:4,flexWrap:'wrap' }}>
                  {p.isFeatured&&<span style={{ background:'#f59e0b',color:'#000',fontSize:9,fontWeight:800,padding:'1px 5px',borderRadius:6 }}>⭐</span>}
                  {p.isBestSeller&&<span style={{ background:'#ef4444',color:'#fff',fontSize:9,fontWeight:800,padding:'1px 5px',borderRadius:6 }}>🔥</span>}
                  {!p.isActive&&<span style={{ background:'rgba(0,0,0,0.6)',color:'#f87171',fontSize:9,fontWeight:800,padding:'1px 5px',borderRadius:6 }}>OFF</span>}
                </div>
              </div>
              <div style={{ padding:12 }}>
                <p style={{ fontSize:12,fontWeight:700,color:'#fff',margin:'0 0 3px',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{p.name}</p>
                <p style={{ fontSize:10,color:'rgba(255,255,255,0.35)',margin:'0 0 6px' }}>{p.category} · {p.subject}</p>
                <div style={{ display:'flex',alignItems:'center',gap:8,marginBottom:8 }}>
                  <span style={{ fontWeight:900,color:'#fff',fontSize:14 }}>{fmtP(p.price)}</span>
                  {p.originalPrice>p.price&&<span style={{ fontSize:11,color:'rgba(255,255,255,0.3)',textDecoration:'line-through' }}>{fmtP(p.originalPrice)}</span>}
                </div>
                <span style={{ fontSize:10,padding:'2px 6px',borderRadius:6,fontWeight:700,background:p.stock>10?'rgba(34,197,94,0.15)':p.stock>0?'rgba(234,179,8,0.15)':'rgba(239,68,68,0.15)',color:p.stock>10?'#86efac':p.stock>0?'#fde047':'#fca5a5' }}>{p.stock>0?`${p.stock} in stock`:'Out of stock'}</span>
                <div style={{ display:'flex',gap:4,marginTop:10,flexWrap:'wrap' }}>
                  {['isFeatured','isNew','isBestSeller','isActive'].map(f=>(
                    <button key={f} onClick={()=>toggle(p._id,f)} style={{ fontSize:9,padding:'3px 6px',borderRadius:6,cursor:'pointer',border:`1px solid rgba(255,255,255,${(p as any)[f]?0.3:0.08})`,background:(p as any)[f]?'rgba(37,99,235,0.3)':'rgba(255,255,255,0.04)',color:(p as any)[f]?'#93c5fd':'rgba(255,255,255,0.3)' }} title={f}>
                      {f==='isFeatured'?'⭐':f==='isNew'?'✨':f==='isBestSeller'?'🔥':'✓'}
                    </button>
                  ))}
                  <button onClick={()=>openEdit(p)} style={{ ...S.btnS,fontSize:10,padding:'3px 8px' }}>Edit</button>
                  <button onClick={()=>del(p._id)} style={{ ...S.btnD,fontSize:10,padding:'3px 8px' }}>Del</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {total>12&&<div style={{ display:'flex',justifyContent:'center',gap:10 }}>
        <button onClick={()=>setPage(p=>Math.max(1,p-1))} disabled={page===1} style={{ ...S.btnS,opacity:page===1?0.4:1 }}>← Prev</button>
        <span style={{ color:'rgba(255,255,255,0.4)',fontSize:13,padding:'8px 0' }}>{page}/{Math.ceil(total/12)}</span>
        <button onClick={()=>setPage(p=>p+1)} disabled={page>=Math.ceil(total/12)} style={{ ...S.btnS,opacity:page>=Math.ceil(total/12)?0.4:1 }}>Next →</button>
      </div>}

      {/* Product Form Modal */}
      {showForm&&(
        <div style={{ position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:50,overflowY:'auto',padding:16 }}>
          <div style={{ maxWidth:680,margin:'0 auto',background:'#0a0f1e',border:'1px solid rgba(255,255,255,0.1)',borderRadius:20,padding:24 }}>
            <div style={{ display:'flex',justifyContent:'space-between',marginBottom:20 }}>
              <h2 style={{ fontSize:18,fontWeight:900,color:'#fff',margin:0 }}>{editing?'Edit Product':'Add New Product'}</h2>
              <button onClick={()=>setShowForm(false)} style={{ background:'none',border:'none',color:'rgba(255,255,255,0.4)',fontSize:24,cursor:'pointer' }}>×</button>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:12 }}>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Product Name *</label><input value={form.name} onChange={e=>setF('name',e.target.value)} placeholder="e.g. NCERT Biology Class 11" style={S.inp} /></div>
              <div><label style={S.label}>Category *</label><select value={form.category} onChange={e=>setF('category',e.target.value)} style={S.sel}>{cats.map(c=><option key={c}>{c}</option>)}</select></div>
              <div><label style={S.label}>Subject</label><select value={form.subject} onChange={e=>setF('subject',e.target.value)} style={S.sel}>{subs.map(s=><option key={s}>{s}</option>)}</select></div>
              <div><label style={S.label}>Class Level</label><select value={form.classLevel} onChange={e=>setF('classLevel',e.target.value)} style={S.sel}>{['Class 11','Class 12','Both','All'].map(c=><option key={c}>{c}</option>)}</select></div>
              <div><label style={S.label}>Exam Type</label><select value={form.examType} onChange={e=>setF('examType',e.target.value)} style={S.sel}>{['NEET','JEE','Both','All'].map(e=><option key={e}>{e}</option>)}</select></div>
              <div><label style={S.label}>Sale Price (₹) *</label><input type="number" value={form.price} onChange={e=>setF('price',e.target.value)} placeholder="199" style={S.inp} /></div>
              <div><label style={S.label}>Original Price (₹) *</label><input type="number" value={form.originalPrice} onChange={e=>setF('originalPrice',e.target.value)} placeholder="350" style={S.inp} /></div>
              {disc>0&&<div style={{ gridColumn:'1/-1' }}><span style={{ color:'#4ade80',fontSize:12,fontWeight:700 }}>✓ {disc}% discount calculated</span></div>}
              <div><label style={S.label}>Stock Quantity *</label><input type="number" value={form.stock} onChange={e=>setF('stock',e.target.value)} placeholder="100" style={S.inp} /></div>
              <div><label style={S.label}>Delivery Charge (₹)</label><input type="number" value={form.deliveryCharge} onChange={e=>setF('deliveryCharge',e.target.value)} placeholder="49" style={S.inp} /></div>
              <div><label style={S.label}>Free Delivery Above (₹)</label><input type="number" value={form.freeDeliveryAbove} onChange={e=>setF('freeDeliveryAbove',e.target.value)} placeholder="499" style={S.inp} /></div>
              <div><label style={S.label}>Author</label><input value={form.author} onChange={e=>setF('author',e.target.value)} placeholder="Author name" style={S.inp} /></div>
              <div><label style={S.label}>Publisher</label><input value={form.publisher} onChange={e=>setF('publisher',e.target.value)} placeholder="Publisher" style={S.inp} /></div>
              <div><label style={S.label}>Edition</label><input value={form.edition} onChange={e=>setF('edition',e.target.value)} placeholder="2024 Edition" style={S.inp} /></div>
              <div><label style={S.label}>ISBN</label><input value={form.isbn} onChange={e=>setF('isbn',e.target.value)} placeholder="978-..." style={S.inp} /></div>
              <div><label style={S.label}>Pages</label><input type="number" value={form.pages} onChange={e=>setF('pages',e.target.value)} placeholder="300" style={S.inp} /></div>
              <div><label style={S.label}>Weight (grams)</label><input type="number" value={form.weight} onChange={e=>setF('weight',e.target.value)} placeholder="400" style={S.inp} /></div>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Short Description</label><input value={form.shortDescription} onChange={e=>setF('shortDescription',e.target.value)} placeholder="One-line description" style={S.inp} /></div>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Full Description *</label><textarea value={form.description} onChange={e=>setF('description',e.target.value)} rows={3} placeholder="Detailed description..." style={{ ...S.inp,resize:'none' }} /></div>
              <div style={{ gridColumn:'1/-1' }}>
                <label style={S.label}>Product Image URLs</label>
                {form.images.map((img:any,i:number)=>(
                  <div key={i} style={{ display:'flex',gap:8,marginBottom:6 }}>
                    <input value={img.url} onChange={e=>{ const imgs=[...form.images]; imgs[i]={...imgs[i],url:e.target.value}; setF('images',imgs); }} placeholder="https://..." style={{ ...S.inp,flex:1 }} />
                    <input value={img.alt} onChange={e=>{ const imgs=[...form.images]; imgs[i]={...imgs[i],alt:e.target.value}; setF('images',imgs); }} placeholder="Alt text" style={{ ...S.inp,width:120 }} />
                  </div>
                ))}
                <button onClick={()=>setF('images',[...form.images,{url:'',alt:''}])} style={{ fontSize:11,color:'#60a5fa',background:'none',border:'none',cursor:'pointer' }}>+ Add Image</button>
              </div>
              <div style={{ gridColumn:'1/-1' }}>
                <label style={S.label}>Key Features (bullet points)</label>
                {form.features.map((f:string,i:number)=>(
                  <input key={i} value={f} onChange={e=>{ const fs=[...form.features]; fs[i]=e.target.value; setF('features',fs); }} placeholder={`Feature ${i+1}`} style={{ ...S.inp,marginBottom:6 }} />
                ))}
                <button onClick={()=>setF('features',[...form.features,''])} style={{ fontSize:11,color:'#60a5fa',background:'none',border:'none',cursor:'pointer' }}>+ Add Feature</button>
              </div>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Tags (comma separated)</label><input value={form.tags} onChange={e=>setF('tags',e.target.value)} placeholder="ncert, biology, class 11" style={S.inp} /></div>
              <div style={{ gridColumn:'1/-1',display:'flex',gap:16,flexWrap:'wrap' }}>
                {[['isFeatured','⭐ Featured'],['isNew','✨ New'],['isBestSeller','🔥 Best Seller'],['isActive','✓ Active']].map(([k,lbl])=>(
                  <label key={k} style={{ display:'flex',alignItems:'center',gap:6,cursor:'pointer',fontSize:13,color:'rgba(255,255,255,0.7)' }}>
                    <input type="checkbox" checked={!!form[k]} onChange={e=>setF(k,e.target.checked)} style={{ accentColor:'#2563eb',width:15,height:15 }} />{lbl}
                  </label>
                ))}
              </div>
            </div>
            <div style={{ display:'flex',gap:10,marginTop:20 }}>
              <button onClick={save} style={{ ...S.btnP,flex:1,padding:14 }}>{editing?'💾 Save Changes':'➕ Create Product'}</button>
              <button onClick={()=>setShowForm(false)} style={S.btnS}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── ORDERS ─────────────────────────────────────────
function Orders({ T }: { T:(m:string,t?:string)=>void }) {
  const [orders, setOrders] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusF, setStatusF] = useState('');
  const [sel, setSel] = useState<any>(null);
  const [sf, setSf] = useState({ status:'', note:'', trackingNumber:'', trackingUrl:'', courierName:'' });

  const load = useCallback(() => {
    const p = new URLSearchParams({ page:String(page), limit:'15', ...(search&&{search}), ...(statusF&&{status:statusF}) });
    fetch(`${API}/api/admin/store/orders?${p}`,{headers:hdr()}).then(r=>r.json()).then(d=>{setOrders(d.orders||[]);setTotal(d.total||0);});
  }, [page, search, statusF]);
  useEffect(()=>{load();},[load]);

  const openOrder = async (o:any) => {
    const r = await fetch(`${API}/api/admin/store/orders/${o._id}`,{headers:hdr()});
    const d = await r.json(); setSel(d.order||o); setSf({status:o.status,note:'',trackingNumber:o.trackingNumber||'',trackingUrl:o.trackingUrl||'',courierName:o.courierName||''});
  };
  const updateStatus = async () => {
    if(!sel)return;
    const r = await fetch(`${API}/api/admin/store/orders/${sel._id}/status`,{method:'PUT',headers:hdr(),body:JSON.stringify(sf)});
    T((await r.json()).message,r.ok?'success':'error'); if(r.ok){setSel(null);load();}
  };
  const statuses = ['pending','confirmed','packed','shipped','out_for_delivery','delivered','cancelled','return_requested','returned','refunded'];

  return (
    <div>
      <div style={{ display:'flex',gap:10,marginBottom:16,flexWrap:'wrap' }}>
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search by Order ID or name..." style={{ ...S.inp,flex:1 }} />
        <select value={statusF} onChange={e=>setStatusF(e.target.value)} style={{ ...S.sel,width:'auto' }}>
          <option value="">All Statuses</option>
          {statuses.map(s=><option key={s}>{s}</option>)}
        </select>
      </div>
      <p style={{ fontSize:12,color:'rgba(255,255,255,0.35)',marginBottom:12 }}>{total} orders</p>
      <div style={{ ...S.card,padding:0,overflow:'hidden' }}>
        <div style={{ overflowX:'auto' }}>
          <table style={{ width:'100%',borderCollapse:'collapse' }}>
            <thead><tr><th style={S.th}>Order ID</th><th style={S.th}>Student</th><th style={S.th}>Items</th><th style={S.th}>Total</th><th style={S.th}>Payment</th><th style={S.th}>Status</th><th style={S.th}>Date</th><th style={S.th}>Action</th></tr></thead>
            <tbody>
              {orders.length===0?<tr><td colSpan={8} style={{ padding:30,textAlign:'center',color:'rgba(255,255,255,0.3)' }}>No orders yet</td></tr>:orders.map(o=>(
                <tr key={o._id} style={{ background:'rgba(255,255,255,0.01)' }}>
                  <td style={{ ...S.td,color:'#60a5fa',fontFamily:'monospace',fontSize:11 }}>{o.orderId}</td>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.7)' }}><p style={{ margin:0,fontSize:12,fontWeight:600 }}>{o.student?.name||'—'}</p><p style={{ margin:0,fontSize:10,color:'rgba(255,255,255,0.35)' }}>{o.student?.email}</p></td>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.5)',fontSize:12 }}>{o.items?.length}</td>
                  <td style={{ ...S.td,color:'#4ade80',fontWeight:700 }}>{fmtP(o.pricing?.total||0)}</td>
                  <td style={S.td}><span style={{ background:'rgba(139,92,246,0.2)',color:'#c4b5fd',borderRadius:8,padding:'2px 6px',fontSize:11,fontWeight:700 }}>{o.payment?.method}</span></td>
                  <td style={S.td}><span style={{ background:STATUS_COLOR[o.status]||'rgba(255,255,255,0.1)',color:STATUS_TEXT[o.status]||'#fff',borderRadius:8,padding:'2px 6px',fontSize:11,fontWeight:700 }}>{o.status}</span></td>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.35)',fontSize:11 }}>{fmtD(o.createdAt)}</td>
                  <td style={S.td}><button onClick={()=>openOrder(o)} style={{ ...S.btnS,fontSize:11,padding:'4px 10px' }}>Manage</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      {total>15&&<div style={{ display:'flex',justifyContent:'center',gap:10,marginTop:12 }}>
        <button onClick={()=>setPage(p=>Math.max(1,p-1))} disabled={page===1} style={{ ...S.btnS,opacity:page===1?0.4:1 }}>← Prev</button>
        <span style={{ color:'rgba(255,255,255,0.4)',fontSize:13,padding:'8px 0' }}>{page}/{Math.ceil(total/15)}</span>
        <button onClick={()=>setPage(p=>p+1)} disabled={page>=Math.ceil(total/15)} style={{ ...S.btnS,opacity:page>=Math.ceil(total/15)?0.4:1 }}>Next →</button>
      </div>}

      {sel&&(
        <div style={{ position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:50,overflowY:'auto',padding:16 }}>
          <div style={{ maxWidth:580,margin:'0 auto',background:'#0a0f1e',border:'1px solid rgba(255,255,255,0.1)',borderRadius:20,padding:24 }}>
            <div style={{ display:'flex',justifyContent:'space-between',marginBottom:16 }}>
              <div><h2 style={{ fontSize:18,fontWeight:900,color:'#fff',margin:0 }}>Order: {sel.orderId}</h2><p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:0 }}>{fmtD(sel.createdAt)}</p></div>
              <button onClick={()=>setSel(null)} style={{ background:'none',border:'none',color:'rgba(255,255,255,0.4)',fontSize:24,cursor:'pointer' }}>×</button>
            </div>
            <div style={{ ...S.card2,marginBottom:12 }}><p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:'0 0 6px',fontWeight:700 }}>CUSTOMER</p><p style={{ fontSize:14,fontWeight:700,color:'#fff',margin:0 }}>{sel.student?.name}</p><p style={{ fontSize:12,color:'rgba(255,255,255,0.4)',margin:0 }}>{sel.student?.email}</p></div>
            <div style={{ ...S.card2,marginBottom:12 }}><p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:'0 0 6px',fontWeight:700 }}>SHIPPING</p><p style={{ fontSize:13,color:'#fff',margin:0 }}>{sel.shippingAddress?.fullName} · {sel.shippingAddress?.phone}</p><p style={{ fontSize:12,color:'rgba(255,255,255,0.4)',margin:0 }}>{sel.shippingAddress?.addressLine1}, {sel.shippingAddress?.city}, {sel.shippingAddress?.state} — {sel.shippingAddress?.pincode}</p></div>
            <div style={{ ...S.card2,marginBottom:12 }}>
              <p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:'0 0 8px',fontWeight:700 }}>ITEMS</p>
              {sel.items?.map((item:any,i:number)=>(
                <div key={i} style={{ display:'flex',justifyContent:'space-between',padding:'6px 0',borderBottom:'1px solid rgba(255,255,255,0.05)',fontSize:13 }}>
                  <span style={{ color:'rgba(255,255,255,0.7)' }}>{item.name} × {item.quantity}</span>
                  <span style={{ color:'#4ade80',fontWeight:700 }}>{fmtP(item.price*item.quantity)}</span>
                </div>
              ))}
              <div style={{ display:'flex',justifyContent:'space-between',paddingTop:8,fontSize:16,fontWeight:900,color:'#fff' }}><span>Total</span><span>{fmtP(sel.pricing?.total||0)}</span></div>
            </div>
            <div style={{ ...S.card2,marginBottom:12 }}>
              <p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:'0 0 10px',fontWeight:700 }}>UPDATE STATUS</p>
              <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:8 }}>
                <select value={sf.status} onChange={e=>setSf(p=>({...p,status:e.target.value}))} style={S.sel}>{statuses.map(s=><option key={s}>{s}</option>)}</select>
                <input value={sf.courierName} onChange={e=>setSf(p=>({...p,courierName:e.target.value}))} placeholder="Courier name" style={S.inp} />
                <input value={sf.trackingNumber} onChange={e=>setSf(p=>({...p,trackingNumber:e.target.value}))} placeholder="Tracking number" style={S.inp} />
                <input value={sf.trackingUrl} onChange={e=>setSf(p=>({...p,trackingUrl:e.target.value}))} placeholder="Tracking URL" style={S.inp} />
                <textarea value={sf.note} onChange={e=>setSf(p=>({...p,note:e.target.value}))} rows={2} placeholder="Status note..." style={{ ...S.inp,resize:'none',gridColumn:'1/-1' }} />
              </div>
              <button onClick={updateStatus} style={{ ...S.btnP,width:'100%' }}>💾 Update Status</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── COUPONS ─────────────────────────────────────────
function Coupons({ T }: { T:(m:string,t?:string)=>void }) {
  const [coupons, setCoupons] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ code:'', description:'', type:'percent', value:'', minOrderValue:'0', maxDiscount:'', usageLimit:'100', validFrom:'', validTill:'', isActive:true });
  const load = () => fetch(`${API}/api/admin/store/coupons`,{headers:hdr()}).then(r=>r.json()).then(d=>setCoupons(d.coupons||[]));
  useEffect(()=>{load();},[]);
  const openCreate = () => { setEditing(null); setForm({code:'',description:'',type:'percent',value:'',minOrderValue:'0',maxDiscount:'',usageLimit:'100',validFrom:'',validTill:'',isActive:true}); setShowForm(true); };
  const openEdit = (c:any) => { setEditing(c); setForm({...c,value:String(c.value),minOrderValue:String(c.minOrderValue||0),maxDiscount:String(c.maxDiscount||''),usageLimit:String(c.usageLimit||100),validFrom:c.validFrom?c.validFrom.substring(0,10):'',validTill:c.validTill?c.validTill.substring(0,10):''}); setShowForm(true); };
  const save = async () => {
    const payload = {...form,value:parseFloat(form.value),minOrderValue:parseFloat(form.minOrderValue)||0,usageLimit:parseInt(form.usageLimit)||100,maxDiscount:form.maxDiscount?parseFloat(form.maxDiscount):undefined};
    const r = await fetch(editing?`${API}/api/admin/store/coupons/${editing._id}`:`${API}/api/admin/store/coupons`,{method:editing?'PUT':'POST',headers:hdr(),body:JSON.stringify(payload)});
    T((await r.json()).message,r.ok?'success':'error'); if(r.ok){setShowForm(false);load();}
  };
  const toggle = async (id:string) => { await fetch(`${API}/api/admin/store/coupons/${id}/toggle`,{method:'PATCH',headers:hdr()}); load(); };
  const del = async (id:string) => { if(!confirm('Delete coupon?'))return; const r=await fetch(`${API}/api/admin/store/coupons/${id}`,{method:'DELETE',headers:hdr()}); T((await r.json()).message,r.ok?'success':'error'); if(r.ok)load(); };
  const setF = (k:string,v:any) => setForm((p:any)=>({...p,[k]:v}));
  return (
    <div>
      <div style={{ display:'flex',justifyContent:'space-between',marginBottom:16 }}><p style={{ fontSize:12,color:'rgba(255,255,255,0.35)',margin:0 }}>{coupons.length} coupons</p><button onClick={openCreate} style={S.btnP}>+ Create Coupon</button></div>
      <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(250px,1fr))',gap:12 }}>
        {coupons.map(c=>(
          <div key={c._id} style={S.card}>
            <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8 }}>
              <span style={{ fontFamily:'monospace',fontSize:16,fontWeight:900,color:'#60a5fa' }}>{c.code}</span>
              <span style={{ fontSize:10,fontWeight:700,padding:'2px 8px',borderRadius:8,background:c.isActive?'rgba(34,197,94,0.15)':'rgba(239,68,68,0.15)',color:c.isActive?'#86efac':'#fca5a5' }}>{c.isActive?'Active':'Inactive'}</span>
            </div>
            {c.description&&<p style={{ fontSize:12,color:'rgba(255,255,255,0.4)',margin:'0 0 10px' }}>{c.description}</p>}
            <div style={{ fontSize:12,color:'rgba(255,255,255,0.5)',marginBottom:10,lineHeight:1.8 }}>
              <div>Discount: <strong style={{ color:'#4ade80' }}>{c.type==='percent'?`${c.value}%`:`₹${c.value}`} off</strong></div>
              <div>Min Order: ₹{c.minOrderValue||0}</div>
              <div>Used: {c.usedCount}/{c.usageLimit}</div>
              {c.validTill&&<div>Valid till: {fmtD(c.validTill)}</div>}
            </div>
            <div style={{ background:'rgba(255,255,255,0.08)',borderRadius:6,height:4,marginBottom:10 }}>
              <div style={{ background:'#3b82f6',height:4,borderRadius:6,width:`${Math.min(100,(c.usedCount/c.usageLimit)*100)}%` }} />
            </div>
            <div style={{ display:'flex',gap:6 }}>
              <button onClick={()=>toggle(c._id)} style={{ ...S.btnS,flex:1,fontSize:11 }}>{c.isActive?'Deactivate':'Activate'}</button>
              <button onClick={()=>openEdit(c)} style={{ ...S.btnS,fontSize:11 }}>Edit</button>
              <button onClick={()=>del(c._id)} style={{ ...S.btnD,fontSize:11 }}>Del</button>
            </div>
          </div>
        ))}
        {coupons.length===0&&<div style={{ ...S.card,textAlign:'center',padding:40,gridColumn:'1/-1' }}><p style={{ fontSize:36,marginBottom:8 }}>🎟</p><p style={{ color:'rgba(255,255,255,0.4)' }}>No coupons. Create your first!</p></div>}
      </div>
      {showForm&&(
        <div style={{ position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:50,display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
          <div style={{ width:'100%',maxWidth:480,background:'#0a0f1e',border:'1px solid rgba(255,255,255,0.1)',borderRadius:20,padding:24 }}>
            <div style={{ display:'flex',justifyContent:'space-between',marginBottom:18 }}><h2 style={{ fontSize:18,fontWeight:900,color:'#fff',margin:0 }}>{editing?'Edit Coupon':'Create Coupon'}</h2><button onClick={()=>setShowForm(false)} style={{ background:'none',border:'none',color:'rgba(255,255,255,0.4)',fontSize:24,cursor:'pointer' }}>×</button></div>
            <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:10 }}>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Coupon Code *</label><input value={form.code} onChange={e=>setF('code',e.target.value.toUpperCase())} placeholder="SAVE20" style={S.inp} /></div>
              <div><label style={S.label}>Type</label><select value={form.type} onChange={e=>setF('type',e.target.value)} style={S.sel}><option value="percent">Percent (%)</option><option value="flat">Flat (₹)</option></select></div>
              <div><label style={S.label}>Value *</label><input type="number" value={form.value} onChange={e=>setF('value',e.target.value)} placeholder="20" style={S.inp} /></div>
              <div><label style={S.label}>Min Order (₹)</label><input type="number" value={form.minOrderValue} onChange={e=>setF('minOrderValue',e.target.value)} placeholder="0" style={S.inp} /></div>
              <div><label style={S.label}>Max Discount (₹)</label><input type="number" value={form.maxDiscount} onChange={e=>setF('maxDiscount',e.target.value)} placeholder="100" style={S.inp} /></div>
              <div><label style={S.label}>Usage Limit</label><input type="number" value={form.usageLimit} onChange={e=>setF('usageLimit',e.target.value)} placeholder="100" style={S.inp} /></div>
              <div />
              <div><label style={S.label}>Valid From</label><input type="date" value={form.validFrom} onChange={e=>setF('validFrom',e.target.value)} style={S.inp} /></div>
              <div><label style={S.label}>Valid Till</label><input type="date" value={form.validTill} onChange={e=>setF('validTill',e.target.value)} style={S.inp} /></div>
              <div style={{ gridColumn:'1/-1' }}><label style={S.label}>Description</label><input value={form.description} onChange={e=>setF('description',e.target.value)} placeholder="e.g. Get 20% off on all books" style={S.inp} /></div>
              <label style={{ display:'flex',alignItems:'center',gap:6,cursor:'pointer',fontSize:13,color:'rgba(255,255,255,0.7)' }}><input type="checkbox" checked={form.isActive} onChange={e=>setF('isActive',e.target.checked)} style={{ accentColor:'#2563eb' }} /> Active</label>
            </div>
            <div style={{ display:'flex',gap:10,marginTop:18 }}><button onClick={save} style={{ ...S.btnP,flex:1 }}>{editing?'Save':'Create'}</button><button onClick={()=>setShowForm(false)} style={S.btnS}>Cancel</button></div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── INVENTORY ─────────────────────────────────────────
function Inventory({ T }: { T:(m:string,t?:string)=>void }) {
  const [data, setData] = useState<any>(null);
  const [editing, setEditing] = useState<any>(null);
  const [sf, setSf] = useState({stock:'',lowStockThreshold:'10'});
  useEffect(()=>{ fetch(`${API}/api/admin/store/inventory`,{headers:hdr()}).then(r=>r.json()).then(setData); },[]);
  const updateStock = async (id:string) => { const r=await fetch(`${API}/api/admin/store/products/${id}/inventory`,{method:'PATCH',headers:hdr(),body:JSON.stringify({stock:parseInt(sf.stock),lowStockThreshold:parseInt(sf.lowStockThreshold)})}); T((await r.json()).message,r.ok?'success':'error'); if(r.ok){setEditing(null);fetch(`${API}/api/admin/store/inventory`,{headers:hdr()}).then(r=>r.json()).then(setData);} };
  if(!data) return <div style={{ textAlign:'center',padding:40,color:'rgba(255,255,255,0.4)' }}>Loading...</div>;
  return (
    <div>
      <div style={{ display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginBottom:16 }}>
        {[{l:'Total Products',v:data.totalProducts,c:'#3b82f6'},{l:'Low Stock',v:data.lowStock?.length||0,c:'#f59e0b'},{l:'Out of Stock',v:data.outOfStock?.length||0,c:'#ef4444'}].map((s,i)=>(
          <div key={i} style={S.card}><p style={{ fontSize:22,fontWeight:900,color:'#fff',margin:'0 0 4px' }}>{s.v}</p><p style={{ fontSize:11,color:'rgba(255,255,255,0.4)',margin:0 }}>{s.l}</p></div>
        ))}
      </div>
      {data.outOfStock?.length>0&&<div style={{ ...S.card,borderColor:'rgba(239,68,68,0.3)',marginBottom:12 }}><p style={{ fontSize:13,fontWeight:700,color:'#fca5a5',margin:'0 0 10px' }}>🚫 Out of Stock ({data.outOfStock.length})</p>{data.outOfStock.map((p:any)=><div key={p._id} style={{ display:'flex',justifyContent:'space-between',alignItems:'center',padding:'6px 0',borderBottom:'1px solid rgba(255,255,255,0.05)' }}><div><p style={{ fontSize:13,color:'#fff',margin:0 }}>{p.name}</p><p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:0 }}>{p.sku}</p></div><button onClick={()=>{setEditing(p._id);setSf({stock:'',lowStockThreshold:String(p.lowStockThreshold||10)});}} style={{ ...S.btnS,fontSize:11 }}>Restock</button></div>)}</div>}
      <div style={{ ...S.card,padding:0,overflow:'hidden' }}>
        <div style={{ overflowX:'auto' }}>
          <table style={{ width:'100%',borderCollapse:'collapse' }}>
            <thead><tr><th style={S.th}>Product</th><th style={S.th}>SKU</th><th style={S.th}>Category</th><th style={S.th}>Price</th><th style={S.th}>Stock</th><th style={S.th}>Sold</th><th style={S.th}>Action</th></tr></thead>
            <tbody>
              {data.products?.map((p:any)=>(
                <tr key={p._id}>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.8)',fontSize:12,fontWeight:600 }}>{p.name}</td>
                  <td style={{ ...S.td,fontFamily:'monospace',color:'rgba(255,255,255,0.35)',fontSize:11 }}>{p.sku}</td>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.4)',fontSize:12 }}>{p.category}</td>
                  <td style={{ ...S.td,color:'#4ade80',fontWeight:700 }}>{fmtP(p.price)}</td>
                  <td style={S.td}><span style={{ fontSize:11,fontWeight:700,padding:'2px 6px',borderRadius:6,background:p.stock>p.lowStockThreshold?'rgba(34,197,94,0.15)':p.stock>0?'rgba(234,179,8,0.15)':'rgba(239,68,68,0.15)',color:p.stock>p.lowStockThreshold?'#86efac':p.stock>0?'#fde047':'#fca5a5' }}>{p.stock}</span></td>
                  <td style={{ ...S.td,color:'rgba(255,255,255,0.4)',fontSize:12 }}>{p.sold}</td>
                  <td style={S.td}><button onClick={()=>{setEditing(p._id);setSf({stock:String(p.stock),lowStockThreshold:String(p.lowStockThreshold||10)});}} style={{ ...S.btnS,fontSize:11,padding:'4px 10px' }}>Edit</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      {editing&&<div style={{ position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:50,display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
        <div style={{ width:'100%',maxWidth:380,background:'#0a0f1e',border:'1px solid rgba(255,255,255,0.1)',borderRadius:16,padding:24 }}>
          <h3 style={{ fontSize:16,fontWeight:900,color:'#fff',margin:'0 0 16px' }}>Update Inventory</h3>
          <label style={S.label}>New Stock Quantity</label><input type="number" value={sf.stock} onChange={e=>setSf(p=>({...p,stock:e.target.value}))} style={{ ...S.inp,marginBottom:10 }} />
          <label style={S.label}>Low Stock Threshold</label><input type="number" value={sf.lowStockThreshold} onChange={e=>setSf(p=>({...p,lowStockThreshold:e.target.value}))} style={{ ...S.inp,marginBottom:16 }} />
          <div style={{ display:'flex',gap:10 }}><button onClick={()=>updateStock(editing)} style={{ ...S.btnP,flex:1 }}>Save</button><button onClick={()=>setEditing(null)} style={S.btnS}>Cancel</button></div>
        </div>
      </div>}
    </div>
  );
}

// ── REVIEWS ─────────────────────────────────────────
function Reviews({ T }: { T:(m:string,t?:string)=>void }) {
  const [reviews, setReviews] = useState<any[]>([]);
  const [replyForm, setReplyForm] = useState<{id:string;text:string}|null>(null);
  useEffect(()=>{ fetch(`${API}/api/admin/store/reviews`,{headers:hdr()}).then(r=>r.json()).then(d=>setReviews(d.reviews||[])); },[]);
  const sendReply = async () => { if(!replyForm)return; const r=await fetch(`${API}/api/admin/store/reviews/${replyForm.id}/reply`,{method:'PUT',headers:hdr(),body:JSON.stringify({reply:replyForm.text})}); T((await r.json()).message,r.ok?'success':'error'); if(r.ok)setReplyForm(null); };
  const del = async (id:string) => { if(!confirm('Delete?'))return; const r=await fetch(`${API}/api/admin/store/reviews/${id}`,{method:'DELETE',headers:hdr()}); T((await r.json()).message,r.ok?'success':'error'); if(r.ok)setReviews(p=>p.filter(r=>r._id!==id)); };
  const stars = (n:number) => '★'.repeat(n)+'☆'.repeat(5-n);
  return (
    <div>
      <p style={{ fontSize:12,color:'rgba(255,255,255,0.35)',marginBottom:12 }}>{reviews.length} reviews</p>
      {reviews.length===0?<div style={{ ...S.card,textAlign:'center',padding:40 }}><p style={{ fontSize:36,marginBottom:8 }}>⭐</p><p style={{ color:'rgba(255,255,255,0.4)' }}>No reviews yet</p></div>:reviews.map(r=>(
        <div key={r._id} style={{ ...S.card,marginBottom:12 }}>
          <div style={{ display:'flex',justifyContent:'space-between',marginBottom:8 }}>
            <div><span style={{ color:'#fbbf24',fontSize:14 }}>{stars(r.rating)}</span>{r.isVerifiedPurchase&&<span style={{ marginLeft:8,fontSize:10,background:'rgba(34,197,94,0.15)',color:'#86efac',padding:'1px 6px',borderRadius:6,fontWeight:700 }}>✓ Verified</span>}</div>
            <button onClick={()=>del(r._id)} style={{ ...S.btnD,fontSize:11,padding:'3px 8px' }}>Delete</button>
          </div>
          {r.title&&<p style={{ fontSize:13,fontWeight:700,color:'#fff',margin:'0 0 3px' }}>{r.title}</p>}
          <p style={{ fontSize:11,color:'rgba(255,255,255,0.35)',margin:'0 0 6px' }}>{r.student?.name} · {r.product?.name} · {fmtD(r.createdAt)}</p>
          <p style={{ fontSize:13,color:'rgba(255,255,255,0.6)',margin:'0 0 10px' }}>{r.body}</p>
          {r.adminReply&&<div style={{ ...S.card2,marginBottom:8 }}><p style={{ fontSize:11,color:'#60a5fa',fontWeight:700,margin:'0 0 4px' }}>Admin Reply</p><p style={{ fontSize:12,color:'rgba(255,255,255,0.6)',margin:0 }}>{r.adminReply}</p></div>}
          {!r.adminReply&&(replyForm?.id===r._id
            ?<div style={{ display:'flex',gap:8 }}><textarea value={replyForm.text} onChange={e=>setReplyForm(p=>p?{...p,text:e.target.value}:null)} rows={2} placeholder="Write reply..." style={{ ...S.inp,flex:1,resize:'none',fontSize:12 }} /><div style={{ display:'flex',flexDirection:'column',gap:6 }}><button onClick={sendReply} style={{ ...S.btnP,fontSize:11 }}>Send</button><button onClick={()=>setReplyForm(null)} style={{ ...S.btnS,fontSize:11 }}>×</button></div></div>
            :<button onClick={()=>setReplyForm({id:r._id,text:''})} style={{ ...S.btnS,fontSize:11 }}>Reply to Review</button>
          )}
        </div>
      ))}
    </div>
  );
}
