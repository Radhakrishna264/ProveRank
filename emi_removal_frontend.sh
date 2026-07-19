#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — EMI FEATURE COMPLETE REMOVAL — FRONTEND
# Removes all EMI-related UI from: Batches & Test Series page,
# admin/x7k2p/batch-controls page, admin/x7k2p/BatchManagerUltra.tsx,
# admin/x7k2p/TestSeriesManagerUltra.tsx
# Run from your project ROOT on Replit:  bash emi_removal_frontend.sh
# Safe to re-run (idempotent).
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank — EMI Feature Removal — FRONTEND install starting..."

TS_DIR=$(find . -type d \( -iname "test-series" -o -iname "batches" \) -not -path "*/node_modules/*" -not -path "*admin*" 2>/dev/null | head -1)
BC_DIR=$(find . -type d -iname "batch-controls" -not -path "*/node_modules/*" 2>/dev/null | head -1)
ADMIN_DIR=$(find . -type d -path "*admin/x7k2p" -not -path "*/node_modules/*" 2>/dev/null | head -1)

if [ -z "$TS_DIR" ]; then TS_DIR="./frontend/app/dashboard/test-series"; echo "⚠️  Test Series dir not auto-detected — defaulting to $TS_DIR"; fi
if [ -z "$BC_DIR" ]; then BC_DIR="./frontend/app/admin/x7k2p/batch-controls"; echo "⚠️  batch-controls dir not auto-detected — defaulting to $BC_DIR"; fi
if [ -z "$ADMIN_DIR" ]; then ADMIN_DIR="./frontend/app/admin/x7k2p"; echo "⚠️  admin panel dir not auto-detected — defaulting to $ADMIN_DIR"; fi

echo "📁 Test Series dir     : $TS_DIR"
echo "📁 batch-controls dir  : $BC_DIR"
echo "📁 Admin panel dir     : $ADMIN_DIR"

# ── 1) Batches & Test Series page.tsx ──
cp "$TS_DIR/page.tsx" "$TS_DIR/page.tsx.bak_emirm" 2>/dev/null || true
cat > "$TS_DIR/page.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Theme system (FPR4: replaces old locked-dark immersive background) ──
type PageTheme = 'light' | 'dark'
function usePageTheme(): PageTheme {
  const [theme, setTheme] = useState<PageTheme>('dark')
  useEffect(() => {
    const read = () => {
      try { setTheme((localStorage.getItem('pr_color_theme') as PageTheme) || 'dark') } catch { setTheme('dark') }
    }
    read()
    const onStorage = (e: StorageEvent) => { if (!e.key || e.key === 'pr_color_theme') read() }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])
  return theme
}
const THEME_VARS: Record<PageTheme, Record<string, string>> = {
  dark: {
    '--pr-bg': 'radial-gradient(ellipse at 20% 0%,#0C1220 0%,#070A12 55%,#040609 100%)',
    '--pr-card-rgb': '4,12,30',
    '--pr-header-rgb': '2,8,22',
    '--pr-sub-rgb': '160,200,240',
    '--pr-text': '#F1F6FC',
  },
  light: {
    '--pr-bg': 'radial-gradient(ellipse at 15% 0%,#FFFFFF 0%,#F3F7FF 55%,#E9F1FF 100%)',
    '--pr-card-rgb': '255,255,255',
    '--pr-header-rgb': '255,255,255',
    '--pr-sub-rgb': '71,85,105',
    '--pr-text': '#0F172A',
  },
}

type Batch = {
  _id: string; name: string; description: string; examType: string;
  price: number; discountPrice: number; isFree: boolean; thumbnail: string;
  totalTests: number; enrolledCount: number; language: string; batchType: string;
  isSpotlight: boolean; flashSaleEndTime?: string; flashSalePrice?: number;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; validity: number;
  rating: number; isEnrolled?: boolean; isWishlisted?: boolean; createdAt: string;
  difficulty?: string; subject?: string;
  effectivePrice?: number; discountPct?: number; fitScore?: number;
  isPriceWatched?: boolean; priceDropped?: boolean; watchedPrice?: number|null;
  teacherAssigned?: string; seatLimit?: number;
}
type AcSuggestion = { _id: string; name: string; examType: string; isFree: boolean }
type Notif = { _id: string; title: string; message: string; isRead: boolean; createdAt: string; link?: string }

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', 'NEET UG': '#4D9FFF', JEE: '#9B59B6', 'JEE MAINS': '#9B59B6', 'JEE ADVANCE': '#7D3C98',
  CUET: '#27AE60', 'CUET UG': '#27AE60', 'CUET PG': '#1E8449', 'SSC CGL': '#E67E22', 'IIT JAM': '#00D4FF',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}
const CATS = ['All','NEET UG','JEE MAINS','JEE ADVANCE','CUET UG','CUET PG','SSC CGL','IIT JAM']
const CICONS: Record<string,string> = {
  All:'🌟','NEET UG':'🩺','JEE MAINS':'⚙️','JEE ADVANCE':'🛠️','CUET UG':'📖','CUET PG':'📚','SSC CGL':'🏛️','IIT JAM':'🔬',
  NEET:'🩺',JEE:'⚙️',CUET:'📖','Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'
}
const QUOTES = [
  { q:"Champions aren't made in gyms. They are made from something deep inside them.", a:"Muhammad Ali" },
  { q:"The secret of getting ahead is getting started. Every expert was once a beginner.", a:"Mark Twain" },
  { q:"In the middle of every difficulty lies opportunity. Stay focused, stay strong.", a:"Albert Einstein" },
  { q:"Success is not final, failure is not fatal — it is the courage to continue that counts.", a:"Winston Churchill" },
]
const FACTS = [
  { icon:'🧬', t:'DNA Replication', f:'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.', c:'#4D9FFF' },
  { icon:'⚡', t:'ATP Synthesis', f:'Mitochondria produce 36-38 ATP per glucose via oxidative phosphorylation. F0F1 ATP synthase rotates at 100 rpm.', c:'#00D4FF' },
]

function loadRazorpay(): Promise<boolean> {
  return new Promise(resolve => {
    if ((window as any).Razorpay) return resolve(true)
    const s = document.createElement('script')
    s.src = 'https://checkout.razorpay.com/v1/checkout.js'
    s.onload = () => resolve(true); s.onerror = () => resolve(false)
    document.body.appendChild(s)
  })
}

function PRLogo({ size = 36 }: { size?: number }) {
  const b = Math.round(size * 0.94), p = Math.round(b * 0.63), f = Math.round(p * 0.52), r = Math.round(p * 0.28)
  return (
    <div style={{ position:'relative', width:b, height:b, flexShrink:0, display:'inline-flex' }}>
      <div style={{ position:'absolute', top:0, left:0, width:p, height:p, borderRadius:r, background:'linear-gradient(135deg,#4D9FFF,#00D4FF)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#030810' }}>P</div>
      <div style={{ position:'absolute', bottom:0, right:0, width:p, height:p, borderRadius:r, background:'rgba(0,212,255,0.15)', border:'1.5px solid rgba(0,212,255,0.45)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:f, fontWeight:900, fontFamily:'Inter,sans-serif', color:'#00D4FF' }}>R</div>
    </div>
  )
}

function FlashTimer({ end }: { end: string }) {
  const [s,setS]=useState({h:0,m:0,s:0})
  useEffect(()=>{
    const tick=()=>{const d=new Date(end).getTime()-Date.now();if(d<=0){setS({h:0,m:0,s:0});return};setS({h:Math.floor(d/3600000),m:Math.floor(d%3600000/60000),s:Math.floor(d%60000/1000)})}
    tick();const iv=setInterval(tick,1000);return()=>clearInterval(iv)
  },[end])
  const p=(n:number)=>n.toString().padStart(2,'0')
  return <span style={{ fontFamily:'monospace',fontSize:13,fontWeight:800,color:'#FF6B6B',letterSpacing:2 }}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

function Stars({ r }: { r: number }) {
  return (
    <span>
      {[1,2,3,4,5].map(i=><span key={i} style={{ color:i<=Math.round(r)?'#FFD700':'rgba(255,215,0,0.15)',fontSize:11 }}>★</span>)}
      <span style={{ fontSize:10,color:'rgba(255,255,255,0.3)',marginLeft:3 }}>{r.toFixed(1)}</span>
    </span>
  )
}

// ── NOTIFICATION BELL ──
function NotificationBell({ tok }: { tok: string | null }) {
  const [open,setOpen]=useState(false)
  const [notifs,setNotifs]=useState<Notif[]>([])
  const [unread,setUnread]=useState(0)
  const router=useRouter()

  const fetchNotifs=useCallback(async()=>{
    if(!tok)return
    try{
      const r=await fetch(`${API}/api/student/notifications`,{headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      setNotifs(d.notifications||[]);setUnread(d.unread||0)
    }catch{}
  },[tok])

  useEffect(()=>{ fetchNotifs(); const iv=setInterval(fetchNotifs,30000); return()=>clearInterval(iv) },[fetchNotifs])

  const markAllRead=async()=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/read-all`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setUnread(0);setNotifs(prev=>prev.map(n=>({...n,isRead:true})))
  }
  const markRead=async(id:string,link?:string)=>{
    if(!tok)return
    await fetch(`${API}/api/student/notifications/${id}/read`,{method:'PUT',headers:{Authorization:`Bearer ${tok}`}})
    setNotifs(prev=>prev.map(n=>n._id===id?{...n,isRead:true}:n))
    setUnread(prev=>Math.max(0,prev-1))
    if(link)router.push(link)
    setOpen(false)
  }

  if(!tok)return null
  return (
    <div style={{ position:'relative' }}>
      <button onClick={()=>{ setOpen(o=>!o); if(!open)fetchNotifs() }}
        style={{ position:'relative',background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',fontSize:18,flexShrink:0,transition:'background 0.2s' }}
        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
        onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>
        🔔
        {unread>0&&<div style={{ position:'absolute',top:-4,right:-4,width:18,height:18,borderRadius:'50%',background:'linear-gradient(135deg,#E74C3C,#FF6B6B)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:9,fontWeight:900,color:'#fff',border:'2px solid #020816' }}>{unread>9?'9+':unread}</div>}
      </button>
      {open&&(
        <div style={{ position:'absolute',top:44,right:0,width:300,maxHeight:380,background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,overflow:'hidden',zIndex:200,boxShadow:'0 20px 60px rgba(0,0,0,0.6)',backdropFilter:'blur(24px)',animation:'slideUp 0.2s ease' }}>
          <div style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.1)',display:'flex',alignItems:'center',justifyContent:'space-between' }}>
            <span style={{ fontWeight:700,fontSize:12,color:'var(--pr-text)' }}>🔔 Notifications</span>
            {unread>0&&<button onClick={markAllRead} style={{ background:'transparent',border:'none',color:'#4D9FFF',fontSize:10,cursor:'pointer',fontWeight:600 }}>Mark all read</button>}
          </div>
          <div style={{ overflowY:'auto',maxHeight:320 }}>
            {notifs.length===0?(
              <div style={{ padding:'28px 16px',textAlign:'center',color:'rgba(var(--pr-sub-rgb),0.4)',fontSize:12 }}>No notifications yet</div>
            ):notifs.map(n=>(
              <div key={n._id} onClick={()=>markRead(n._id,n.link)}
                style={{ padding:'12px 14px',borderBottom:'1px solid rgba(77,159,255,0.06)',cursor:'pointer',background:n.isRead?'transparent':'rgba(77,159,255,0.05)',transition:'background 0.2s' }}
                onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.09)')}
                onMouseLeave={e=>(e.currentTarget.style.background=n.isRead?'transparent':'rgba(77,159,255,0.05)')}>
                <div style={{ display:'flex',gap:8,alignItems:'flex-start' }}>
                  {!n.isRead&&<div style={{ width:7,height:7,borderRadius:'50%',background:'#4D9FFF',flexShrink:0,marginTop:4 }} />}
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:12,fontWeight:n.isRead?400:700,color:'var(--pr-text)',marginBottom:3 }}>{n.title}</div>
                    <div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)',lineHeight:1.5 }}>{n.message}</div>
                    <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.3)',marginTop:4 }}>{new Date(n.createdAt).toLocaleDateString()}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ── PAYMENT CHECKOUT MODAL ──
function PaymentModal({ batch, tok, onClose, onSuccess }: { batch: Batch; tok: string; onClose: () => void; onSuccess: () => void }) {
  const [loading,setLoading]=useState(false)
  const price=batch.discountPrice||batch.price

  const handlePayFull=async()=>{
    if(!tok)return
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-order`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'}})
      const d=await r.json()
      if(!d.success)return alert(d.error||'Error')
      if(d.testMode){alert(`TEST MODE\n\nBatch: ${d.batchName}\nFull Amount: ₹${Math.round(d.amount/100)}\nOrder: ${d.orderId}\n\nAdd Razorpay keys in Render to enable real payments.`);onClose();return}
      const loaded=await loadRazorpay()
      if(!loaded)return alert('Could not load payment gateway')
      const rzp=new (window as any).Razorpay({key:d.key,amount:d.amount,currency:d.currency,order_id:d.orderId,name:'ProveRank',description:batch.name,handler:()=>{onSuccess();onClose()},theme:{color:'#4D9FFF'}})
      rzp.open();onClose()
    }finally{setLoading(false)}
  }

  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)' }}>💳 Payment</div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:6,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batch.name}</div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:20 }}>₹{price}</div>
        <button onClick={handlePayFull} disabled={loading}
          style={{ width:'100%',padding:'13px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.35)' }}>
          {loading?'Processing...':'💰 Pay Full Amount ₹'+price}
        </button>
      </div>
    </div>
  )
}

// ── REVIEW MODAL ──
function ReviewModal({ batchId, batchName, tok, onClose }: { batchId:string; batchName:string; tok:string; onClose:()=>void }) {
  const [rating,setRating]=useState(0)
  const [hov,setHov]=useState(0)
  const [comment,setComment]=useState('')
  const [loading,setLoading]=useState(false)
  const [done,setDone]=useState(false)
  const submit=async()=>{
    if(!rating)return alert('Please select a rating')
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batchId}/review`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({rating,comment})})
      const d=await r.json()
      if(d.success)setDone(true); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)' }}>
        {done?(
          <div style={{ textAlign:'center',padding:'20px 0' }}>
            <div style={{ fontSize:52,marginBottom:14 }}>⭐</div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'var(--pr-text)',marginBottom:8 }}>Review Submitted!</div>
            <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:20 }}>Pending admin approval.</div>
            <button onClick={onClose} style={{ background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'11px 28px',color:'#fff',fontWeight:700,cursor:'pointer' }}>Done</button>
          </div>
        ):(
          <>
            <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
              <div style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'var(--pr-text)' }}>Rate this Batch</div>
              <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:20 }}>×</button>
            </div>
            <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.55)',marginBottom:16,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batchName}</div>
            <div style={{ display:'flex',gap:8,justifyContent:'center',marginBottom:18 }}>
              {[1,2,3,4,5].map(i=>(
                <span key={i} onClick={()=>setRating(i)} onMouseEnter={()=>setHov(i)} onMouseLeave={()=>setHov(0)}
                  style={{ fontSize:36,cursor:'pointer',transition:'transform 0.15s',transform:i<=(hov||rating)?'scale(1.2)':'scale(1)',color:i<=(hov||rating)?'#FFD700':'rgba(255,215,0,0.18)' }}>★</span>
              ))}
            </div>
            <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="Share your experience (optional)..." rows={3}
              style={{ width:'100%',padding:'10px 12px',background:'rgba(255,255,255,0.04)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,color:'var(--pr-text)',fontSize:12,resize:'none',marginBottom:16,fontFamily:'Inter,sans-serif' }} />
            <button onClick={submit} disabled={loading||!rating}
              style={{ width:'100%',padding:'12px',background:rating?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.15)',border:'none',borderRadius:12,color:rating?'#fff':'rgba(var(--pr-sub-rgb),0.4)',fontWeight:700,cursor:rating?'pointer':'not-allowed',fontSize:13 }}>
              {loading?'Submitting...':'⭐ Submit Review'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}

// ── BATCH CARD ──
function BatchCard({ b, tok, onUpdate, compareList, toggleCompare, onBuy, onReview, onPreview, showPriceWatch }: {
  b:Batch; tok:string|null; onUpdate:()=>void;
  compareList?:Batch[]; toggleCompare?:(b:Batch)=>void;
  onBuy?:(b:Batch)=>void; onReview?:(b:Batch)=>void; onPreview?:(b:Batch)=>void; showPriceWatch?:boolean;
}) {
  const [loading,setLoading]=useState(false)
  const [hov,setHov]=useState(false)
  const isFlash=!!(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())
  const isNew=Date.now()-new Date(b.createdAt).getTime()<7*86400000
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=isFlash&&b.flashSalePrice?b.flashSalePrice:(b.discountPrice||b.price)
  const disc=b.price>0&&finalPrice<b.price?Math.round((1-finalPrice/b.price)*100):0
  const enroll=async()=>{
    if(!tok)return alert('Please login')
    setLoading(true)
    try{
      const res=await fetch(`${API}/api/student/batches/${b._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await res.json()
      if(d.success)onUpdate(); else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  const toggleWish=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  const togglePriceWatch=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batch-ultra/${b._id}/price-watch`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  return (
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)' }}>
      <div style={{ position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4 }}>
        {isNew&&<span style={{ background:'linear-gradient(135deg,#27AE60,#1E8449)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>✨ NEW</span>}
        {typeof b.fitScore==='number'&&b.fitScore>=70&&<span style={{ background:'linear-gradient(135deg,#00D4FF,#0090B0)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🎯 {b.fitScore}% Fit</span>}
        {b.enrolledCount>100&&<span style={{ background:'linear-gradient(135deg,#E67E22,#CA6F1E)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>🔥 HOT</span>}
        {b.isBundle&&<span style={{ background:'linear-gradient(135deg,#9B59B6,#7D3C98)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20 }}>📦 BUNDLE</span>}
      </div>
      {toggleCompare&&compareList&&(
        <button onClick={e=>{e.stopPropagation();toggleCompare(b)}}
          style={{ position:'absolute',top:10,right:48,zIndex:5,background:compareList.find(x=>x._id===b._id)?'rgba(155,89,182,0.9)':'rgba(0,0,20,0.6)',border:'1px solid rgba(155,89,182,0.4)',borderRadius:'50%',width:32,height:32,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',color:'#fff',fontWeight:900,transition:'all 0.2s' }}>
          {compareList.find(x=>x._id===b._id)?'✓':'⚖'}
        </button>
      )}
      <button onClick={toggleWish} style={{ position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:15,display:'flex',alignItems:'center',justifyContent:'center' }}>{b.isWishlisted?'❤️':'🤍'}</button>
      {onPreview&&<button onClick={e=>{e.stopPropagation();onPreview(b)}} style={{ position:'absolute',top:52,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:32,height:32,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',color:'#fff' }}>👁️</button>}
      <div style={{ height:140,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden' }}>
        <div style={{ position:'absolute',inset:0,background:'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))',zIndex:1 }} />
        {!b.thumbnail&&<span style={{ fontSize:46,filter:`drop-shadow(0 0 16px ${ec})`,zIndex:2,opacity:0.88 }}>{CICONS[b.examType]||'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{ position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.92)',padding:'4px 0',textAlign:'center',fontSize:10,fontWeight:700,color:'#fff',zIndex:3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled&&<div style={{ position:'absolute',inset:0,background:'rgba(39,174,96,0.16)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2 }}><span style={{ background:'rgba(39,174,96,0.9)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:11,fontWeight:800 }}>✅ Enrolled</span></div>}
      </div>
      <div style={{ padding:'13px 14px 15px' }}>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginBottom:7 }}>
          <span style={{ background:`${ec}16`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20,border:`1px solid ${ec}25` }}>{b.examType}</span>
          <span style={{ background:b.isFree?'rgba(39,174,96,0.13)':'rgba(230,126,34,0.13)',color:b.isFree?'#27AE60':'#E67E22',fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20 }}>{b.isFree?'🆓 FREE':b.allowFreeTrial?`🎯 ${b.trialDays}-Day Trial`:'💎 PAID'}</span>
        </div>
        <div style={{ fontSize:14,fontWeight:700,color:'var(--pr-text)',marginBottom:4,fontFamily:'Playfair Display,serif',lineHeight:1.4,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical' }}>{b.name}</div>
        <div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.55)',lineHeight:1.5,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical',marginBottom:9 }}>{b.description||'Premium test series — NCERT based, expert curated.'}</div>
        <Stars r={b.rating} />
        <div style={{ display:'flex',gap:7,marginTop:7,flexWrap:'wrap' }}>
          {[{i:'📝',v:`${b.totalTests} Tests`},{i:'👥',v:b.enrolledCount.toLocaleString()},{i:'📅',v:`${b.validity}d`}].map((it,idx)=>(
            <span key={idx} style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.45)' }}>{it.i} {it.v}</span>
          ))}
        </div>
        <div style={{ display:'flex',alignItems:'center',gap:7,margin:'9px 0 11px' }}>
          {b.isFree
            ?<span style={{ fontSize:21,fontWeight:900,color:'#27AE60',fontFamily:'Playfair Display,serif' }}>FREE</span>
            :<><span style={{ fontSize:21,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif' }}>₹{finalPrice}</span>{disc>0&&<span style={{ fontSize:11,color:'rgba(255,255,255,0.26)',textDecoration:'line-through' }}>₹{b.price}</span>}{disc>0&&<span style={{ fontSize:9,background:'rgba(39,174,96,0.16)',color:'#27AE60',padding:'2px 7px',borderRadius:20,fontWeight:700 }}>{disc}% OFF</span>}</>}
        </div>
        {b.priceDropped&&<div style={{ fontSize:10,color:'#27AE60',fontWeight:700,marginBottom:8 }}>📉 Price dropped since you watched!</div>}
        {showPriceWatch&&!b.isFree&&(
          <button onClick={togglePriceWatch} style={{ width:'100%',padding:'6px',marginBottom:8,background:b.isPriceWatched?'rgba(0,212,255,0.12)':'rgba(77,159,255,0.05)',border:`1px solid ${b.isPriceWatched?'rgba(0,212,255,0.35)':'rgba(77,159,255,0.12)'}`,borderRadius:10,color:b.isPriceWatched?'#00D4FF':'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:10,fontWeight:700 }}>
            {b.isPriceWatched?'👁️ Watching Price':'🔔 Watch Price'}
          </button>
        )}
        {b.isEnrolled?(
          <div style={{ display:'flex',gap:6 }}>
            <button style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to Batch →</button>
            {onReview&&<button onClick={()=>onReview(b)} style={{ padding:'10px 10px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:11 }}>⭐</button>}
          </div>
        ):b.isFree?(
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
        ):b.allowFreeTrial?(
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Starting...':'🎯 Free Trial'}</button>
        ):(
          <button onClick={()=>onBuy&&onBuy(b)} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>
            🛒 Buy ₹{finalPrice}
          </button>
        )}
      </div>
    </div>
  )
}

// ── QUICK PREVIEW MODAL (FPR4) ──
function QuickPreviewModal({ batchId, tok, onClose, onBuy, onEnrollUpdate }: { batchId:string; tok:string|null; onClose:()=>void; onBuy:(b:Batch)=>void; onEnrollUpdate:()=>void }) {
  const [detail,setDetail]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  useEffect(()=>{
    setLoading(true)
    const h=tok?{Authorization:`Bearer ${tok}`}:{} as Record<string,string>
    fetch(`${API}/api/student/batches/${batchId}`,{headers:h}).then(r=>r.json()).then(d=>setDetail(d.batch)).finally(()=>setLoading(false))
    fetch(`${API}/api/student/batch-ultra/${batchId}/preview-track`,{method:'POST'}).catch(()=>{})
  },[batchId])
  const enroll=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${batchId}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onEnrollUpdate();onClose()
  }
  if(loading||!detail)return(
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center' }}>
      <div style={{ color:'var(--pr-text)',fontSize:13 }}>Loading preview…</div>
    </div>
  )
  const b=detail
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=b.effectivePrice??(b.discountPrice||b.price)
  return (
    <div onClick={onClose} style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.85)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:`1px solid ${ec}30`,borderRadius:22,padding:24,maxWidth:440,width:'100%',maxHeight:'88vh',overflowY:'auto',backdropFilter:'blur(30px)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14 }}>
          <div>
            <span style={{ background:`${ec}16`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20 }}>{b.examType}</span>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)',marginTop:8 }}>{b.name}</div>
          </div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.6)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <Stars r={b.rating||0} />
        <div style={{ display:'flex',gap:10,flexWrap:'wrap',margin:'10px 0' }}>
          <span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)' }}>📝 {b.totalTests} Tests</span>
          <span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)' }}>📅 {b.validity}d validity</span>
          <span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)' }}>👥 {(b.enrolledCount||0).toLocaleString()} enrolled</span>
          {typeof b.fitScore==='number'&&<span style={{ fontSize:11,color:'#00D4FF',fontWeight:700 }}>🎯 {b.fitScore}% Fit for you</span>}
        </div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:12 }}>
          {b.isFree?'FREE':`₹${finalPrice}`}{b.discountPct>0&&<span style={{ fontSize:11,color:'#27AE60',marginLeft:8 }}>{b.discountPct}% OFF</span>}
        </div>
        {b.syllabusCoveragePct!==undefined&&(
          <div style={{ marginBottom:14 }}>
            <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.5)',marginBottom:4,textTransform:'uppercase',fontWeight:700 }}>📚 Syllabus Coverage</div>
            <div style={{ height:6,background:'rgba(77,159,255,0.1)',borderRadius:4,overflow:'hidden' }}><div style={{ height:'100%',width:`${b.syllabusCoveragePct}%`,background:ec }} /></div>
          </div>
        )}
        {b.studyLoadPerWeek>0&&<div style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:10 }}>⏱️ Study Load: ~{b.studyLoadPerWeek} test(s)/week</div>}
        {b.instructorHighlight&&(
          <div style={{ background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:10,marginBottom:12,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.75)' }}>👨‍🏫 {b.instructorHighlight}</div>
        )}
        {b.socialProof&&(
          <div style={{ display:'flex',gap:14,marginBottom:14,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)' }}>
            <span>⭐ {b.socialProof.rating} ({b.socialProof.ratingCount} reviews)</span>
            <span>👥 {b.socialProof.enrolledCount} students</span>
          </div>
        )}
        {b.faqPreview&&b.faqPreview.length>0&&(
          <div style={{ marginBottom:16 }}>
            <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.5)',marginBottom:6,textTransform:'uppercase',fontWeight:700 }}>❓ FAQ</div>
            {b.faqPreview.map((f:any,i:number)=>(
              <div key={i} style={{ marginBottom:8 }}>
                <div style={{ fontSize:11,fontWeight:700,color:'var(--pr-text)' }}>{f.q}</div>
                <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.55)' }}>{f.a}</div>
              </div>
            ))}
          </div>
        )}
        <div style={{ display:'flex',gap:8 }}>
          {b.isEnrolled?(
            <button style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec}30,${ec}15)`,border:`1px solid ${ec}50`,borderRadius:12,color:ec,fontWeight:700,cursor:'pointer',fontSize:12 }}>Go to Batch →</button>
          ):b.isFree?(
            <button onClick={enroll} style={{ flex:1,padding:'11px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>🚀 Enroll Free</button>
          ):(
            <button onClick={()=>{onClose();onBuy(b)}} style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>🛒 Buy ₹{finalPrice}</button>
          )}
        </div>
      </div>
    </div>
  )
}

function EmptyState() {
  return (
    <div style={{ textAlign:'center',padding:'55px 16px' }}>
      <div style={{ fontSize:72,marginBottom:18,display:'inline-block',animation:'floatBob 3s ease infinite' }}>🚀</div>
      <div style={{ fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:10 }}>Batches Launching Soon!</div>
      <div style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.6)',maxWidth:360,margin:'0 auto 24px',lineHeight:1.8 }}>Premium Test Series will appear here once created by the Admin.</div>
    </div>
  )
}

// ══════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════
export default function TestSeriesPage() {
  const router=useRouter()
  const [batches,setBatches]=useState<Batch[]>([])
  const [loading,setLoading]=useState(true)
  const [search,setSearch]=useState('')
  const [cat,setCat]=useState('All')
  const [sort,setSort]=useState('newest')
  const [filterOpen,setFilterOpen]=useState(false)
  const [filters,setFilters]=useState({ isFree:'', batchType:'', difficulty:'', subject:'', language:'', offerType:'', flashSaleActive:'', enrollmentState:'' })
  const [priceRange,setPriceRange]=useState([0,5000])
  const [tab,setTab]=useState<'all'|'enrolled'|'wishlist'>('all')
  const [tok,setTok]=useState<string|null>(null)
  const [qIdx,setQIdx]=useState(0)
  const [compareList,setCompareList]=useState<Batch[]>([])
  const [spotlights,setSpotlights]=useState<Batch[]>([])
  const [acSuggestions,setAcSuggestions]=useState<AcSuggestion[]>([])
  const [showAc,setShowAc]=useState(false)
  const [recommendations,setRecommendations]=useState<Batch[]>([])
  const [isDesktop,setIsDesktop]=useState(false)
  const [desktopFilterOpen,setDesktopFilterOpen]=useState(false)
  const [reviewBatch,setReviewBatch]=useState<Batch|null>(null)
  const [buyBatch,setBuyBatch]=useState<Batch|null>(null)
  const [previewBatchId,setPreviewBatchId]=useState<string|null>(null)

  const toggleCompare=(b:Batch)=>setCompareList(prev=>prev.find(x=>x._id===b._id)?prev.filter(x=>x._id!==b._id):prev.length>=3?prev:[...prev,b])

  useEffect(()=>{
    setTok(localStorage.getItem('pr_token'))
    const iv=setInterval(()=>setQIdx(i=>(i+1)%QUOTES.length),5000)
    return()=>clearInterval(iv)
  },[])

  useEffect(()=>{
    const check=()=>setIsDesktop(window.innerWidth>=900)
    check(); window.addEventListener('resize',check); return()=>window.removeEventListener('resize',check)
  },[])

  useEffect(()=>{
    if(!search||search.length<2){setAcSuggestions([]);setShowAc(false);return}
    const timer=setTimeout(async()=>{
      try{
        const r=await fetch(`${API}/api/student/batch-extras/autocomplete?q=${encodeURIComponent(search)}`)
        const d=await r.json()
        setAcSuggestions(d.suggestions||[]);setShowAc((d.suggestions||[]).length>0)
      }catch{setShowAc(false)}
    },300)
    return()=>clearTimeout(timer)
  },[search])

  useEffect(()=>{
    const examType=cat!=='All'?cat:''
    fetch(`${API}/api/student/batch-extras/recommendations?examType=${examType}`)
      .then(r=>r.json()).then(d=>setRecommendations(d.batches||[])).catch(()=>{})
  },[cat])

  const fetchBatches=useCallback(async()=>{
    setLoading(true)
    try{
      const p=new URLSearchParams({sort})
      if(cat!=='All')p.set('examType',cat)
      if(search)p.set('search',search)
      if(filters.isFree)p.set('isFree',filters.isFree)
      if(filters.batchType)p.set('batchType',filters.batchType)
      if(filters.difficulty)p.set('difficulty',filters.difficulty)
      if(filters.subject)p.set('subject',filters.subject)
      if(filters.language)p.set('language',filters.language)
      if(filters.offerType)p.set('offerType',filters.offerType)
      if(filters.flashSaleActive)p.set('flashSaleActive',filters.flashSaleActive)
      if(filters.enrollmentState)p.set('enrollmentState',filters.enrollmentState)
      p.set('minPrice',priceRange[0].toString())
      p.set('maxPrice',priceRange[1].toString())
      const token=localStorage.getItem('pr_token')
      const h=token?{Authorization:`Bearer ${token}`}:{} as Record<string,string>
      const url=tab==='enrolled'?`${API}/api/student/batches/my`:tab==='wishlist'?`${API}/api/student/batches/wishlist`:`${API}/api/student/batches?${p}`
      const res=await fetch(url,{headers:h})
      const d=await res.json()
      const all=d.batches||[]
      setBatches(all);setSpotlights(all.filter((b:Batch)=>b.isSpotlight).slice(0,3))
    }catch{setBatches([])}finally{setLoading(false)}
  },[cat,sort,search,filters,tab,priceRange])

  useEffect(()=>{fetchBatches()},[fetchBatches])

  const handleBuy=async(b:Batch)=>{
    if(!tok)return alert('Please login to purchase')
    setBuyBatch(b)
  }

  const currentQuote=QUOTES[qIdx]

  const FilterContent=()=>(
    <>
      <div style={{ fontWeight:700,fontSize:11,color:'rgba(var(--pr-sub-rgb),0.5)',textTransform:'uppercase',letterSpacing:1,marginBottom:14 }}>🔧 Filters</div>

      {/* Price Range Slider */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Range</div>
        <div style={{ display:'flex',justifyContent:'space-between',marginBottom:6 }}>
          <span style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.6)' }}>₹{priceRange[0]}</span>
          <span style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.6)' }}>₹{priceRange[1]}</span>
        </div>
        <input type="range" min={0} max={5000} step={100} value={priceRange[1]}
          onChange={e=>setPriceRange([priceRange[0],Number(e.target.value)])}
          style={{ width:'100%',accentColor:'#4D9FFF',cursor:'pointer',marginBottom:4 }} />
        <div style={{ display:'flex',gap:5,flexWrap:'wrap',marginTop:6 }}>
          {[{v:[0,5000],l:'All'},{v:[0,0],l:'🆓 Free'},{v:[1,499],l:'Under ₹500'},{v:[500,999],l:'₹500-999'},{v:[1000,5000],l:'₹1000+'}].map((o,i)=>{
            const active=priceRange[0]===o.v[0]&&priceRange[1]===o.v[1]
            return <button key={i} onClick={()=>setPriceRange(o.v as [number,number])}
              style={{ padding:'4px 9px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Free/Paid */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Price Type</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'true',l:'🆓 Free'},{v:'false',l:'💎 Paid'}].map(o=>{
            const active=filters.isFree===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,isFree:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Format */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Format</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Live',l:'🔴 Live'},{v:'Recorded',l:'📹 Recorded'},{v:'Both',l:'🔄 Both'}].map(o=>{
            const active=filters.batchType===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,batchType:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Difficulty */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Difficulty</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Easy',l:'🟢 Easy'},{v:'Medium',l:'🟡 Medium'},{v:'Hard',l:'🔴 Hard'},{v:'Mixed',l:'🔀 Mixed'}].map(o=>{
            const active=filters.difficulty===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,difficulty:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Subject */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Subject</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'All'},{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'},{v:'Mathematics',l:'📐 Maths'}].map(o=>{
            const active=filters.subject===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,subject:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Language */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Language</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'Hindi',l:'🇮🇳 Hindi'},{v:'English',l:'🇬🇧 English'},{v:'Hindi + English',l:'🔤 Bilingual'}].map(o=>{
            const active=filters.language===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,language:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Quick Toggle: Flash Sale Active (FPR4) */}
      <div style={{ marginBottom:18,display:'flex',gap:8,flexWrap:'wrap' }}>
        <button onClick={()=>setFilters(prev=>({...prev,flashSaleActive:prev.flashSaleActive?'':'true'}))}
          style={{ padding:'6px 11px',borderRadius:20,fontSize:10,cursor:'pointer',background:filters.flashSaleActive?'rgba(231,76,60,0.15)':'rgba(77,159,255,0.05)',border:`1px solid ${filters.flashSaleActive?'rgba(231,76,60,0.4)':'rgba(77,159,255,0.1)'}`,color:filters.flashSaleActive?'#E74C3C':'rgba(var(--pr-sub-rgb),0.42)' }}>⚡ Flash Sale Live</button>
      </div>

      {/* Offer Type (FPR4) */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Offer Type</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'trial',l:'🎯 Free Trial'},{v:'bundle',l:'📦 Bundle'},{v:'spotlight',l:'⭐ Spotlight'},{v:'flashsale',l:'⚡ Flash Sale'}].map(o=>{
            const active=filters.offerType===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,offerType:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Enrollment State (FPR4) */}
      <div style={{ marginBottom:18 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Enrollment State</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'',l:'Any'},{v:'open',l:'🟢 Open'},{v:'full',l:'🔴 Full'}].map(o=>{
            const active=filters.enrollmentState===o.v
            return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,enrollmentState:o.v}))}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Sort */}
      <div style={{ marginBottom:8 }}>
        <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.42)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1 }}>Sort By</div>
        <div style={{ display:'flex',gap:5,flexWrap:'wrap' }}>
          {[{v:'newest',l:'🆕 Newest'},{v:'popular',l:'🔥 Popular'},{v:'enrolled',l:'👥 Most Enrolled'},{v:'rating',l:'⭐ Top Rated'},{v:'price_low',l:'💰 Low Price'},{v:'price_high',l:'💎 High Price'},{v:'discount',l:'🏷️ Highest Discount'}].map(o=>{
            const active=sort===o.v
            return <button key={o.v} onClick={()=>setSort(o.v)}
              style={{ padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.05)',border:`1px solid ${active?'rgba(77,159,255,0.42)':'rgba(77,159,255,0.1)'}`,color:active?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>

      {/* Reset */}
      <button onClick={()=>{setFilters({isFree:'',batchType:'',difficulty:'',subject:'',language:'',offerType:'',flashSaleActive:'',enrollmentState:''});setPriceRange([0,5000]);setSort('newest')}}
        style={{ width:'100%',padding:'8px',background:'rgba(231,76,60,0.07)',border:'1px solid rgba(231,76,60,0.18)',borderRadius:10,color:'#E74C3C',cursor:'pointer',fontSize:10,fontWeight:700,marginTop:4 }}>
        🗑 Reset All Filters
      </button>
    </>
  )

  const pageTheme = usePageTheme()
  const vars = THEME_VARS[pageTheme]

  return (
    <div style={{ minHeight:'100vh',color:'var(--pr-text)',fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:'var(--pr-bg)', ...(vars as any) }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-13px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(26px)}to{opacity:1;transform:translateY(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
        input,select,textarea{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
        input[type=range]{height:4px;border-radius:2px}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{ position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:1300,margin:'0 auto' }}>
        {/* HERO */}
        <div style={{ padding:'22px 18px 20px',marginBottom:16,textAlign:'center',animation:'slideUp 0.5s ease',position:'relative' }}>
          <div style={{ position:'absolute',top:8,right:8 }}><NotificationBell tok={tok} /></div>
          <div style={{ display:'flex',alignItems:'center',gap:12,marginBottom:4,justifyContent:'center' }}>
            <span style={{ fontSize:34,filter:'drop-shadow(0 0 13px rgba(77,159,255,0.5))' }}>🎓</span>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:25,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 45%,#9B59B6 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundSize:'200%',animation:'gradShift 6s ease infinite' }}>Batches & Test Series</div>
          </div>
        </div>

        {/* HERO QUICK STATS STRIP (FPR4) */}
        <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(90px,1fr))',gap:8,marginBottom:16 }}>
          {[
            {l:'Available',v:batches.length,c:'#4D9FFF'},
            {l:'Enrolled',v:batches.filter(b=>b.isEnrolled).length,c:'#27AE60'},
            {l:'Wishlisted',v:batches.filter(b=>b.isWishlisted).length,c:'#E74C3C'},
            {l:'Spotlight',v:spotlights.length,c:'#FFD700'},
            {l:'Live Offers',v:batches.filter(b=>b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date()).length,c:'#FF6B6B'},
            {l:'Comparing',v:compareList.length,c:'#9B59B6'},
          ].map(s=>(
            <div key={s.l} style={{ background:'rgba(var(--pr-card-rgb),0.85)',border:`1px solid ${s.c}20`,borderRadius:12,padding:'8px 6px',textAlign:'center' }}>
              <div style={{ fontSize:16,fontWeight:800,color:s.c }}>{s.v}</div>
              <div style={{ fontSize:8.5,color:'rgba(var(--pr-sub-rgb),0.5)',textTransform:'uppercase',letterSpacing:0.4 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* CATEGORY STRIP */}
        <div style={{ display:'flex',gap:7,overflowX:'auto',paddingBottom:7,marginBottom:14,scrollbarWidth:'none' }}>
          {CATS.map(c=>{
            const active=cat===c
            return <button key={c} onClick={()=>setCat(c)} style={{ flexShrink:0,padding:'8px 15px',borderRadius:22,background:active?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.07)',border:active?'none':'1px solid rgba(77,159,255,0.13)',color:active?'#fff':'rgba(var(--pr-sub-rgb),0.62)',fontWeight:active?700:400,cursor:'pointer',fontSize:11,transition:'all 0.2s',whiteSpace:'nowrap',boxShadow:active?'0 4px 13px rgba(77,159,255,0.26)':'none' }}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* SPOTLIGHT */}
        {spotlights.length>0&&(
          <div style={{ marginBottom:20 }}>
            <div style={{ display:'flex',alignItems:'center',gap:7,marginBottom:11 }}>
              <span style={{ fontSize:17 }}>⭐</span>
              <span style={{ fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'var(--pr-text)' }}>Spotlight Picks</span>
            </div>
            <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:14 }}>
              {spotlights.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} onPreview={x=>setPreviewBatchId(x._id)} />)}
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:7,marginBottom:13 }}>
          {(['all','enrolled','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{ padding:'10px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.8)',border:`1px solid ${tab===t?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.1)'}`,color:tab===t?'#4D9FFF':'rgba(var(--pr-sub-rgb),0.42)',fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)' }}>
              {t==='all'?'🌟 All':t==='enrolled'?'✅ My Batches':'❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* LAYOUT */}
        <div style={{ display:isDesktop?'flex':'block',gap:22,alignItems:'flex-start' }}>

          {/* DESKTOP STICKY SIDEBAR (hidden by default — toggle via Filter button) */}
          {isDesktop&&desktopFilterOpen&&(
            <div style={{ width:220,flexShrink:0,position:'sticky',top:70,background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:18,padding:'18px 16px',backdropFilter:'blur(22px)',boxShadow:'0 10px 40px rgba(0,10,40,0.35)',animation:'slideUp 0.4s ease',maxHeight:'calc(100vh - 90px)',overflowY:'auto' }}>
              <FilterContent />
            </div>
          )}

          <div style={{ flex:1,minWidth:0 }}>
            {/* SEARCH */}
            <div style={{ display:'flex',gap:7,marginBottom:12,flexWrap:'wrap' }}>
              <div style={{ flex:1,minWidth:150,position:'relative' }}>
                <span style={{ position:'absolute',left:10,top:'50%',transform:'translateY(-50%)',fontSize:12,opacity:0.42,zIndex:2 }}>🔍</span>
                <input value={search} onChange={e=>setSearch(e.target.value)} onFocus={()=>acSuggestions.length>0&&setShowAc(true)} onBlur={()=>setTimeout(()=>setShowAc(false),200)}
                  placeholder="Search batches..." style={{ width:'100%',padding:'10px 10px 10px 32px',background:'rgba(var(--pr-card-rgb),0.9)',border:'1px solid rgba(77,159,255,0.13)',borderRadius:12,color:'var(--pr-text)',fontSize:12,backdropFilter:'blur(12px)' }} />
                {showAc&&acSuggestions.length>0&&(
                  <div style={{ position:'absolute',top:'100%',left:0,right:0,marginTop:4,background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:12,overflow:'hidden',zIndex:100,boxShadow:'0 12px 40px rgba(0,0,0,0.5)',backdropFilter:'blur(24px)',animation:'slideUp 0.18s ease' }}>
                    {acSuggestions.map(s=>(
                      <div key={s._id} onClick={()=>{setSearch(s.name);setShowAc(false)}}
                        style={{ padding:'10px 14px',cursor:'pointer',display:'flex',alignItems:'center',gap:10,borderBottom:'1px solid rgba(77,159,255,0.06)',transition:'background 0.15s' }}
                        onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.08)')}
                        onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                        <span style={{ fontSize:16 }}>{CICONS[s.examType]||'📚'}</span>
                        <div>
                          <div style={{ fontSize:12,color:'var(--pr-text)',fontWeight:600 }}>{s.name}</div>
                          <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.45)' }}>{s.examType} · {s.isFree?'Free':'Paid'}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              {!isDesktop&&(
                <button onClick={()=>setFilterOpen(o=>!o)} style={{ padding:'10px 12px',background:filterOpen?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.9)',border:`1px solid ${filterOpen?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.13)'}`,borderRadius:12,color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:600 }}>⚙️ Filter</button>
              )}
              {isDesktop&&(
                <button onClick={()=>setDesktopFilterOpen(o=>!o)} style={{ padding:'10px 14px',background:desktopFilterOpen?'rgba(77,159,255,0.13)':'rgba(var(--pr-card-rgb),0.9)',border:`1px solid ${desktopFilterOpen?'rgba(77,159,255,0.36)':'rgba(77,159,255,0.13)'}`,borderRadius:12,color:'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap' }}>⚙️ {desktopFilterOpen?'Hide Filters':'Filters'}</button>
              )}
            </div>

            {/* MOBILE FILTER */}
            {!isDesktop&&filterOpen&&(
              <div style={{ background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:15,padding:15,marginBottom:12,backdropFilter:'blur(22px)',animation:'slideUp 0.22s ease' }}>
                <FilterContent />
              </div>
            )}

            {/* BATCH GRID */}
            {loading?(
              <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:16 }}>
                {[1,2,3,4].map(i=><div key={i} style={{ height:380,background:'rgba(var(--pr-card-rgb),0.8)',borderRadius:20,border:'1px solid rgba(77,159,255,0.06)',animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.14}s` }} />)}
              </div>
            ):batches.length===0?<EmptyState />:(
              <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(230px,1fr))',gap:16 }}>
                {batches.map((b,i)=>(
                  <div key={b._id} style={{ animation:`slideUp ${0.28+i*0.04}s ease both` }}>
                    <BatchCard b={b} tok={tok} onUpdate={fetchBatches} compareList={compareList} toggleCompare={toggleCompare} onBuy={handleBuy} onReview={setReviewBatch} onPreview={x=>setPreviewBatchId(x._id)} showPriceWatch={tab==='wishlist'} />
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* WHY PROVERANK */}
        <div style={{ marginTop:42,background:'rgba(var(--pr-card-rgb),0.97)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:20,padding:'24px 16px',backdropFilter:'blur(22px)' }}>
          <div style={{ textAlign:'center',marginBottom:20 }}>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:'var(--pr-text)',marginBottom:3 }}>✨ Why Choose ProveRank?</div>
          </div>
          <div style={{ display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:10 }}>
            {[{i:'🤖',t:'AI Analytics',d:'Weak area detection\nSmart revision',c:'#9B59B6'},{i:'🔒',t:'Anti-Cheat',d:'Webcam · Face AI\nIP Lock',c:'#E74C3C'},{i:'📊',t:'Live Ranks',d:'Real-time AIR\nPercentile',c:'#27AE60'},{i:'📄',t:'OMR + PDFs',d:'Bubble sheet\nCertificates',c:'#E67E22'},{i:'🆓',t:'100% Free',d:'Free hosting\nNo charges',c:'#00D4FF'}].map((f,i)=>(
              <div key={i} style={{ background:'rgba(var(--pr-card-rgb),0.72)',border:`1px solid ${f.c}14`,borderRadius:14,padding:'14px 10px',textAlign:'center',transition:'all 0.3s' }} onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'36'}} onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'14'}}>
                <div style={{ fontSize:26,marginBottom:8,filter:`drop-shadow(0 0 6px ${f.c}75)` }}>{f.i}</div>
                <div style={{ fontWeight:700,color:f.c,fontSize:11,marginBottom:4 }}>{f.t}</div>
                <div style={{ fontSize:10,color:'rgba(var(--pr-sub-rgb),0.46)',lineHeight:1.62,whiteSpace:'pre-line' }}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

        {/* QUOTE */}
        <div style={{ padding:'24px 4px 8px',display:'flex',alignItems:'center',gap:13 }}>
          <span style={{ fontSize:26,flexShrink:0 }}>💫</span>
          <div>
            <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.72)',fontStyle:'italic',lineHeight:1.65,fontFamily:'Playfair Display,serif' }}>"{currentQuote.q}"</div>
            <div style={{ fontSize:11,color:'#4D9FFF',fontWeight:700,marginTop:5 }}>— {currentQuote.a}</div>
          </div>
        </div>

        {/* COMPARE TRAY */}
        {compareList.length>=1&&(
          <div style={{ position:'fixed',bottom:0,left:0,right:0,zIndex:200,background:'rgba(var(--pr-card-rgb),0.98)',borderTop:`1px solid ${compareList.length===3?'rgba(155,89,182,0.5)':'rgba(77,159,255,0.2)'}`,backdropFilter:'blur(24px)',padding:'12px 16px' }}>
            <div style={{ maxWidth:1200,margin:'0 auto',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap' }}>
              <span style={{ fontSize:12,color:'rgba(var(--pr-sub-rgb),0.6)',flexShrink:0 }}>⚖️ <strong style={{ color:'#9B59B6' }}>{compareList.length}</strong>/3</span>
              <div style={{ display:'flex',gap:6,flex:1,overflow:'hidden' }}>
                {compareList.map(b=><span key={b._id} style={{ fontSize:11,background:'rgba(155,89,182,0.15)',border:'1px solid rgba(155,89,182,0.3)',borderRadius:20,padding:'4px 10px',color:'#9B59B6',maxWidth:110,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis',flexShrink:0 }}>{b.name}</span>)}
              </div>
              <button onClick={()=>setCompareList([])} style={{ background:'rgba(231,76,60,0.1)',border:'1px solid rgba(231,76,60,0.2)',borderRadius:8,padding:'7px 10px',color:'#E74C3C',cursor:'pointer',fontSize:11,fontWeight:600,flexShrink:0 }}>Clear</button>
              {compareList.length>=2?<button onClick={()=>router.push('/dashboard/batch-compare?ids='+compareList.map(b=>b._id).join(','))} style={{ background:'linear-gradient(135deg,#9B59B6,#7D3C98)',border:'none',borderRadius:10,padding:'9px 16px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,flexShrink:0 }}>Compare Now →</button>:<span style={{ fontSize:11,color:'rgba(var(--pr-sub-rgb),0.4)',flexShrink:0 }}>+{2-compareList.length} more needed</span>}
            </div>
          </div>
        )}
      </div>

      {/* MODALS */}
      {reviewBatch&&tok&&<ReviewModal batchId={reviewBatch._id} batchName={reviewBatch.name} tok={tok} onClose={()=>setReviewBatch(null)} />}
      {buyBatch&&tok&&<PaymentModal batch={buyBatch} tok={tok} onClose={()=>setBuyBatch(null)} onSuccess={fetchBatches} />}
      {previewBatchId&&<QuickPreviewModal batchId={previewBatchId} tok={tok} onClose={()=>setPreviewBatchId(null)} onBuy={setBuyBatch} onEnrollUpdate={fetchBatches} />}
    </div>
  )
}
PRVRNK_EOF_MARKER
echo "✅ Batches & Test Series page.tsx updated (EMI removed)"

# ── 2) admin/x7k2p/batch-controls/page.tsx ──
if [ -f "$BC_DIR/page.tsx" ]; then
  cp "$BC_DIR/page.tsx" "$BC_DIR/page.tsx.bak_emirm"
  cat > "$BC_DIR/page.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; examType: string; price: number; discountPrice: number;
  isFree: boolean; isSpotlight: boolean; flashSalePrice?: number; flashSaleEndTime?: string;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean;
  enrolledCount: number; rating: number; status: string;
}
type Review = {
  _id: string; batchId: string; studentName: string; rating: number; comment: string;
  status: string; createdAt: string;
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60', 'Class 11': '#E67E22',
  'Class 12': '#E74C3C', Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

function ToggleSwitch({ on, onToggle, loading }: { on: boolean; onToggle: () => void; loading?: boolean }) {
  return (
    <div onClick={!loading ? onToggle : undefined}
      style={{ width: 44, height: 24, borderRadius: 12, background: on ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(255,255,255,0.08)', border: `1px solid ${on ? '#4D9FFF' : 'rgba(255,255,255,0.14)'}`, cursor: loading ? 'wait' : 'pointer', position: 'relative', transition: 'all 0.3s', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: 2, left: on ? 22 : 2, width: 18, height: 18, borderRadius: '50%', background: on ? '#fff' : 'rgba(255,255,255,0.3)', transition: 'left 0.3s', boxShadow: on ? '0 2px 8px rgba(77,159,255,0.5)' : 'none' }} />
    </div>
  )
}

export default function BatchControlsPage() {
  const router  = useRouter()
  const [tok, setTok]           = useState('')
  const [batches, setBatches]   = useState<Batch[]>([])
  const [reviews, setReviews]   = useState<Review[]>([])
  const [loading, setLoading]   = useState(true)
  const [activeTab, setActiveTab] = useState<'controls' | 'reviews' | 'flashsale'>('controls')
  const [toggling, setToggling] = useState<string | null>(null)
  const [toast, setToast]       = useState('')
  // Flash sale form
  const [fsId, setFsId]         = useState('')
  const [fsPrice, setFsPrice]   = useState('')
  const [fsEnd, setFsEnd]       = useState('')
  // Notify price drop
  const [notifying, setNotifying] = useState<string | null>(null)

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000) }

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t); fetchAll(t)
  }, [])

  const fetchAll = async (t: string) => {
    setLoading(true)
    try {
      const [bRes, rRes] = await Promise.all([
        fetch(`${API}/api/admin/batch-controls`, { headers: { Authorization: `Bearer ${t}` } }),
        fetch(`${API}/api/admin/batch-controls/reviews?status=pending`, { headers: { Authorization: `Bearer ${t}` } }),
      ])
      const bd = await bRes.json(); const rd = await rRes.json()
      setBatches(bd.batches || [])
      setReviews(rd.reviews || [])
    } catch { } finally { setLoading(false) }
  }

  const toggle = async (id: string, action: string, body?: object) => {
    setToggling(id + action)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/${action}`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined
      })
      const d = await r.json()
      if (d.success) { showToast('Updated ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error ❌')
    } catch { showToast('Network error ❌') } finally { setToggling(null) }
  }

  const setFlashSale = async () => {
    if (!fsId || !fsPrice || !fsEnd) return showToast('Fill all flash sale fields')
    await toggle(fsId, 'flashsale', { flashSalePrice: Number(fsPrice), flashSaleEndTime: fsEnd })
    setFsId(''); setFsPrice(''); setFsEnd('')
  }

  const removeFlashSale = async (id: string) => {
    await toggle(id, 'flashsale', { remove: true })
  }

  const approveReview = async (rid: string) => {
    setToggling(rid)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}/approve`, { method: 'PUT', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review approved ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error')
    } finally { setToggling(null) }
  }

  const rejectReview = async (rid: string) => {
    setToggling(rid + 'r')
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}`, { method: 'DELETE', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review rejected'); fetchAll(tok) }
    } finally { setToggling(null) }
  }

  const notifyPriceDrop = async (id: string) => {
    setNotifying(id)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/price-drop-notify`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) showToast(`📣 ${d.notified} wishlisted users notified!`)
      else showToast(d.error || 'Error')
    } finally { setNotifying(null) }
  }

  const inp = { padding: '9px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(77,159,255,0.18)', borderRadius: 10, color: '#F0F8FF', fontSize: 12, outline: 'none' }
  const btn = (col: string) => ({ padding: '9px 16px', background: `linear-gradient(135deg,${col},${col}BB)`, border: 'none', borderRadius: 10, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 })

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(135deg,#020816 0%,#030c1a 100%)', color: '#F0F8FF', fontFamily: 'Inter,sans-serif', padding: '0 0 60px' }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap'); *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px} input,select{outline:none}`}</style>

      {/* TOAST */}
      {toast && (
        <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 9999, background: 'rgba(4,12,30,0.98)', border: '1px solid rgba(77,159,255,0.3)', borderRadius: 12, padding: '12px 24px', fontSize: 13, fontWeight: 600, boxShadow: '0 8px 40px rgba(0,0,0,0.5)', backdropFilter: 'blur(20px)', whiteSpace: 'nowrap' }}>{toast}</div>
      )}

      {/* HEADER */}
      <div style={{ background: 'rgba(2,8,22,0.96)', backdropFilter: 'blur(22px)', borderBottom: '1px solid rgba(77,159,255,0.1)', padding: '14px 20px', display: 'flex', alignItems: 'center', gap: 12, position: 'sticky', top: 0, zIndex: 50 }}>
        <button onClick={() => router.push('/admin/x7k2p')} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20 }}>←</button>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚙️ Batch Controls</div>
          <div style={{ fontSize: 11, color: 'rgba(160,200,240,0.42)' }}>Spotlight · Flash Sale · Bundle · Trial · Reviews · Price Drop</div>
        </div>
        <div style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(160,200,240,0.45)' }}>{batches.length} batches · {reviews.length} pending reviews</div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 16px' }}>

        {/* TABS */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {(['controls', 'flashsale', 'reviews'] as const).map(t => (
            <button key={t} onClick={() => setActiveTab(t)} style={{ padding: '9px 18px', borderRadius: 12, background: activeTab === t ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.07)', border: 'none', color: activeTab === t ? '#fff' : 'rgba(160,200,240,0.5)', fontWeight: activeTab === t ? 700 : 400, cursor: 'pointer', fontSize: 11 }}>
              {t === 'controls' ? '🔧 Batch Toggles' : t === 'flashsale' ? '⚡ Flash Sale' : `⭐ Reviews (${reviews.length})`}
            </button>
          ))}
        </div>

        {/* ── TAB: BATCH TOGGLES ── */}
        {activeTab === 'controls' && (
          <div>
            {loading ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>Loading batches...</div>
            ) : batches.length === 0 ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>No batches found. Create batches from the main Admin Panel first.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {batches.map(b => {
                  const ec = ECOLS[b.examType] || '#4D9FFF'
                  const isFlashActive = !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date())
                  return (
                    <div key={b._id} style={{ background: 'rgba(4,12,30,0.95)', border: `1px solid ${ec}18`, borderRadius: 18, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14, flexWrap: 'wrap' }}>
                        <div style={{ width: 38, height: 38, borderRadius: 10, background: `${ec}18`, border: `1px solid ${ec}28`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 }}>
                          {b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : '📚'}
                        </div>
                        <div style={{ flex: 1, minWidth: 120 }}>
                          <div style={{ fontWeight: 700, fontSize: 13, color: '#F0F8FF', fontFamily: 'Playfair Display,serif' }}>{b.name}</div>
                          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginTop: 2 }}>
                            <span style={{ color: ec }}>{b.examType}</span> · {b.isFree ? 'Free' : `₹${b.discountPrice || b.price}`} · {b.enrolledCount} enrolled · ⭐ {b.rating}
                          </div>
                        </div>
                        {isFlashActive && <span style={{ fontSize: 9, background: 'rgba(231,76,60,0.18)', color: '#E74C3C', padding: '3px 10px', borderRadius: 20, fontWeight: 700 }}>⚡ FLASH ACTIVE</span>}
                        <button onClick={() => notifyPriceDrop(b._id)} disabled={notifying === b._id}
                          style={{ padding: '6px 12px', background: 'rgba(255,215,0,0.08)', border: '1px solid rgba(255,215,0,0.2)', borderRadius: 8, color: '#FFD700', cursor: 'pointer', fontSize: 10, fontWeight: 600, whiteSpace: 'nowrap' }}>
                          {notifying === b._id ? '...' : '📣 Notify Price Drop'}
                        </button>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
                        {[
                          { label: '⭐ Spotlight', desc: 'Show in featured section', key: 'spotlight', val: b.isSpotlight },
                          { label: '📦 Bundle', desc: 'Mark as bundle product', key: 'bundle', val: b.isBundle },
                          { label: '🎯 Free Trial', desc: `${b.trialDays}-day trial access`, key: 'trial', val: b.allowFreeTrial },
                          { label: '⚡ Remove Flash', desc: 'Clear active flash sale', key: 'flashsale_remove', val: isFlashActive },
                        ].map(ctrl => (
                          <div key={ctrl.key} style={{ background: 'rgba(255,255,255,0.03)', border: `1px solid ${ctrl.val ? ec + '30' : 'rgba(255,255,255,0.06)'}`, borderRadius: 12, padding: '11px 13px', display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'space-between' }}>
                            <div>
                              <div style={{ fontSize: 11, fontWeight: 700, color: ctrl.val ? '#F0F8FF' : 'rgba(160,200,240,0.5)' }}>{ctrl.label}</div>
                              <div style={{ fontSize: 9, color: 'rgba(160,200,240,0.35)', marginTop: 2 }}>{ctrl.desc}</div>
                            </div>
                            {ctrl.key === 'flashsale_remove' ? (
                              <button onClick={() => removeFlashSale(b._id)} disabled={!isFlashActive || toggling === b._id + 'flashsale'}
                                style={{ padding: '5px 10px', background: isFlashActive ? 'rgba(231,76,60,0.15)' : 'rgba(255,255,255,0.04)', border: `1px solid ${isFlashActive ? 'rgba(231,76,60,0.3)' : 'rgba(255,255,255,0.08)'}`, borderRadius: 8, color: isFlashActive ? '#E74C3C' : 'rgba(160,200,240,0.25)', cursor: isFlashActive ? 'pointer' : 'not-allowed', fontSize: 9, fontWeight: 700 }}>
                                Remove
                              </button>
                            ) : (
                              <ToggleSwitch on={ctrl.val as boolean} loading={toggling === b._id + ctrl.key} onToggle={() => toggle(b._id, ctrl.key)} />
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}

        {/* ── TAB: FLASH SALE ── */}
        {activeTab === 'flashsale' && (
          <div>
            <div style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 20, padding: '22px 20px', marginBottom: 22, backdropFilter: 'blur(20px)' }}>
              <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF', marginBottom: 18 }}>⚡ Set Flash Sale</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 12, marginBottom: 14 }}>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Select Batch</div>
                  <select value={fsId} onChange={e => setFsId(e.target.value)} style={{ ...inp, width: '100%' }}>
                    <option value="">Choose batch...</option>
                    {batches.filter(b => !b.isFree).map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Flash Price (₹)</div>
                  <input type="number" value={fsPrice} onChange={e => setFsPrice(e.target.value)} placeholder="e.g. 299" style={{ ...inp, width: '100%' }} />
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>End Date & Time</div>
                  <input type="datetime-local" value={fsEnd} onChange={e => setFsEnd(e.target.value)} style={{ ...inp, width: '100%' }} />
                </div>
              </div>
              <button onClick={setFlashSale} style={btn('#E74C3C')}>⚡ Set Flash Sale</button>
            </div>
            {/* Active flash sales */}
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: '#F0F8FF', marginBottom: 14 }}>Active Flash Sales</div>
            {batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).length === 0
              ? <div style={{ color: 'rgba(160,200,240,0.4)', fontSize: 12, padding: '20px 0' }}>No active flash sales.</div>
              : batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).map(b => (
                <div key={b._id} style={{ background: 'rgba(231,76,60,0.06)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 14, padding: '14px 16px', marginBottom: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{b.name}</div>
                    <div style={{ fontSize: 11, color: '#E74C3C', marginTop: 3 }}>⚡ ₹{b.flashSalePrice} · Ends {new Date(b.flashSaleEndTime!).toLocaleString()}</div>
                  </div>
                  <button onClick={() => removeFlashSale(b._id)} style={{ padding: '7px 14px', background: 'rgba(231,76,60,0.12)', border: '1px solid rgba(231,76,60,0.25)', borderRadius: 8, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>Remove</button>
                </div>
              ))
            }
          </div>
        )}

        {/* ── TAB: REVIEWS ── */}
        {activeTab === 'reviews' && (
          <div>
            {reviews.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 0', color: 'rgba(160,200,240,0.4)', fontSize: 13 }}>✅ No pending reviews</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {reviews.map(rv => (
                  <div key={rv._id} style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(255,215,0,0.12)', borderRadius: 16, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, justifyContent: 'space-between', flexWrap: 'wrap' }}>
                      <div style={{ flex: 1, minWidth: 160 }}>
                        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 6 }}>
                          <span style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{rv.studentName}</span>
                          <span style={{ display: 'inline-flex', gap: 1 }}>{[1,2,3,4,5].map(i => <span key={i} style={{ color: i <= rv.rating ? '#FFD700' : 'rgba(255,215,0,0.15)', fontSize: 12 }}>★</span>)}</span>
                        </div>
                        {rv.comment && <div style={{ fontSize: 12, color: 'rgba(180,210,240,0.65)', lineHeight: 1.6, marginBottom: 6 }}>"{rv.comment}"</div>}
                        <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.35)' }}>{new Date(rv.createdAt).toLocaleDateString()}</div>
                      </div>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button onClick={() => approveReview(rv._id)} disabled={toggling === rv._id}
                          style={{ padding: '8px 14px', background: 'rgba(39,174,96,0.12)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 10, color: '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id ? '...' : '✅ Approve'}
                        </button>
                        <button onClick={() => rejectReview(rv._id)} disabled={toggling === rv._id + 'r'}
                          style={{ padding: '8px 14px', background: 'rgba(231,76,60,0.08)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id + 'r' ? '...' : '❌ Reject'}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  )
}
PRVRNK_EOF_MARKER
  echo "✅ batch-controls/page.tsx updated (EMI removed)"
else echo "⚠️  batch-controls/page.tsx not found at $BC_DIR — skipping"; fi

# ── 3) admin/x7k2p/BatchManagerUltra.tsx (FPR1) ──
if [ -f "$ADMIN_DIR/BatchManagerUltra.tsx" ]; then
  cp "$ADMIN_DIR/BatchManagerUltra.tsx" "$ADMIN_DIR/BatchManagerUltra.tsx.bak_emirm"
  cat > "$ADMIN_DIR/BatchManagerUltra.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
// ══════════════════════════════════════════════════════════════════
// FPR1 — BATCH MANAGEMENT ULTRA SaaS UPGRADE (Admin) — Frontend
// Home (cards + smart search/filter + create) + Detail (10 tabs)
// Add/Transfer Student by ID + Email · Pricing · Controls · Materials
// Analytics · Announcements · Settings · Audit History · Templates
// Desktop + Mobile responsive · Admin theme matched
// ══════════════════════════════════════════════════════════════════
import { useState, useEffect, useCallback, useRef } from 'react'

// ── Theme (matches global admin panel theme) ─────────────────────
const CRD  = 'rgba(0,28,52,0.88)'
const CRD2 = 'rgba(0,36,65,0.92)'
const ACC  = '#4D9FFF'
const BOR  = 'rgba(77,159,255,0.18)'
const BOR2 = 'rgba(77,159,255,0.3)'
const TS   = '#E8F4FF'
const DIM  = '#6B8FAF'
const GOOD = '#34D399'
const WARN = '#FBBF24'
const BAD  = '#F87171'

const cs: any = { background: CRD, border: `1px solid ${BOR}`, borderRadius: 14, padding: 18, marginBottom: 14, backdropFilter: 'blur(12px)' }
const inp: any = { width: '100%', padding: '10px 12px', background: 'rgba(0,22,40,0.85)', border: `1.5px solid ${BOR2}`, borderRadius: 10, color: TS, fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none', boxSizing: 'border-box' }
const bp: any = { background: `linear-gradient(135deg,${ACC},#0055CC)`, color: '#fff', border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer', fontWeight: 700, fontSize: 13, fontFamily: 'Inter,sans-serif', boxShadow: '0 4px 16px rgba(77,159,255,0.35)' }
const bs: any = { background: 'rgba(77,159,255,0.1)', color: ACC, border: `1px solid ${BOR2}`, borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const bd: any = { background: 'rgba(239,68,68,0.1)', color: BAD, border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const lbl: any = { display: 'block', fontSize: 10.5, color: DIM, marginBottom: 5, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }
const pageTitle: any = { fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TS, margin: '0 0 4px', background: `linear-gradient(90deg,${ACC},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }
const pageSub: any = { fontSize: 12, color: DIM, marginBottom: 18 }
const chip = (color: string, bg: string): any => ({ fontSize: 10.5, color, background: bg, padding: '3px 10px', borderRadius: 20, fontWeight: 600, display: 'inline-block' })

function useIsMobile() {
  const [m, setM] = useState(false)
  useEffect(() => {
    const chk = () => setM(window.innerWidth < 768)
    chk(); window.addEventListener('resize', chk)
    return () => window.removeEventListener('resize', chk)
  }, [])
  return m
}

function Toggle({ on, onChange, label }: { on: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <div onClick={() => onChange(!on)} style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
      <div style={{ width: 38, height: 20, borderRadius: 20, background: on ? ACC : 'rgba(107,143,175,0.3)', position: 'relative', transition: 'all .2s' }}>
        <div style={{ width: 16, height: 16, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: on ? 20 : 2, transition: 'all .2s' }} />
      </div>
      {label && <span style={{ fontSize: 12, color: TS }}>{label}</span>}
    </div>
  )
}

function Modal({ children, onClose, width = 560 }: { children: any; onClose: () => void; width?: number }) {
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 14 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: `linear-gradient(135deg,${CRD2},${CRD})`, border: `1.5px solid ${BOR2}`, borderRadius: 18, padding: 22, maxWidth: width, width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
        {children}
      </div>
    </div>
  )
}

function EmptyMsg({ text }: { text: string }) {
  return <div style={{ textAlign: 'center', padding: '30px 10px', color: DIM, fontSize: 12.5 }}>{text}</div>
}

// ══════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════════════════════
export default function BatchManagerUltra({ token, API }: { token: string; API: string }) {
  const isMobile = useIsMobile()
  const [batches, setBatches] = useState<any[]>([])
  const [summary, setSummary] = useState<any>({})
  const [loading, setLoading] = useState(false)
  const [q, setQ] = useState('')
  const [filters, setFilters] = useState<any>({})
  const [showFilters, setShowFilters] = useState(false)
  const [sort, setSort] = useState('newest')
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [detailId, setDetailId] = useState<string | null>(() => {
    try { return typeof window !== 'undefined' ? localStorage.getItem('pr_bm_detailId') : null } catch (e) { return null }
  })
  const [showCreate, setShowCreate] = useState(false)
  const [presets, setPresets] = useState<any[]>([])
  const [toast, setToast] = useState('')

  const authHeaders = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }
  const base = API + '/api/admin/batch-manager'

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500) }

  const loadBatches = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (q) params.set('q', q)
      Object.entries(filters).forEach(([k, v]: any) => { if (v !== undefined && v !== '' && v !== null) params.set(k, String(v)) })
      if (sort) params.set('sort', sort)
      const r = await fetch(base + '?' + params.toString(), { headers: authHeaders })
      const d = await r.json()
      setBatches(d.batches || [])
      setSummary(d.summary || {})
    } catch (e) { showToast('⚠️ Failed to load batches') }
    setLoading(false)
  }, [q, filters, sort])

  useEffect(() => { loadBatches() }, [loadBatches])

  useEffect(() => {
    try {
      if (detailId) localStorage.setItem('pr_bm_detailId', detailId)
      else localStorage.removeItem('pr_bm_detailId')
    } catch (e) { /* localStorage unavailable */ }
  }, [detailId])

  useEffect(() => {
    fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json()).then(d => setPresets(d.presets || [])).catch(() => {})
  }, [])

  const savePreset = async () => {
    const name = window.prompt('Preset name?')
    if (!name) return
    await fetch(base + '/filter-presets', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, filters }) })
    const d = await fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json())
    setPresets(d.presets || [])
    showToast('✅ Filter preset saved')
  }

  const toggleSelect = (id: string) => setSelectedIds(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  const bulkAction = async (action: 'archive' | 'delete') => {
    if (selectedIds.length === 0) return
    if (action === 'delete' && !window.confirm(`Delete ${selectedIds.length} selected batch(es)? This cannot be undone.`)) return
    for (const id of selectedIds) {
      await fetch(base + '/' + id + (action === 'archive' ? '/archive' : ''), { method: action === 'archive' ? 'PUT' : 'DELETE', headers: authHeaders })
    }
    showToast(action === 'archive' ? '✅ Batches archived/unarchived' : '✅ Batches deleted')
    setSelectedIds([])
    loadBatches()
  }

  const duplicateBatch = async (id: string) => {
    const r = await fetch(base + '/' + id + '/duplicate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Batch duplicated'); loadBatches() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  const archiveBatch = async (id: string) => {
    const r = await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Status: ' + d.lifecycleStatus); loadBatches() }
  }
  const deleteBatch = async (id: string, name: string) => {
    if (!window.confirm(`Delete batch "${name}"? Students will be unassigned.`)) return
    const r = await fetch(base + '/' + id, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Batch deleted'); loadBatches() }
  }

  if (detailId) {
    return <BatchDetail id={detailId} base={base} authHeaders={authHeaders} onBack={() => { setDetailId(null); loadBatches() }} isMobile={isMobile} showToast={showToast} allBatches={batches} />
  }

  return (
    <div>
      <div style={pageTitle}>🗂️ Batch Management — Ultra SaaS</div>
      <div style={pageSub}>Complete lifecycle control — create, price, control, enroll, assign exams, analyze & archive batches.</div>

      {toast && <div style={{ position: 'fixed', top: 16, right: 16, zIndex: 10000, background: CRD2, border: `1px solid ${BOR2}`, borderRadius: 10, padding: '10px 16px', color: TS, fontSize: 12.5, boxShadow: '0 8px 24px rgba(0,0,0,0.4)' }}>{toast}</div>}

      {/* ── Status Summary Strip ── */}
      <div style={{ display: 'grid', gridTemplateColumns: isMobile ? 'repeat(3,1fr)' : 'repeat(6,1fr)', gap: 8, marginBottom: 14 }}>
        {[
          ['Active', summary.active, GOOD], ['Paused', summary.paused, WARN], ['Archived', summary.archived, DIM],
          ['Draft', summary.draft, '#A78BFA'], ['Upcoming', summary.upcoming, ACC], ['Students', summary.totalStudents, '#7DD3FC']
        ].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, padding: 10, textAlign: 'center' }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM, textTransform: 'uppercase', letterSpacing: 0.5 }}>{l}</div>
          </div>
        ))}
      </div>

      {/* ── Smart Search + Filter Bar ── */}
      <div style={cs}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <input style={{ ...inp, flex: 1, minWidth: 160 }} placeholder="🔎 Search batch, code, exam, student, faculty, email…" value={q} onChange={e => setQ(e.target.value)} />
          <button style={bs} onClick={() => setShowFilters(s => !s)}>🧰 Filters {showFilters ? '▲' : '▼'}</button>
          <select style={{ ...inp, width: 150 }} value={sort} onChange={e => setSort(e.target.value)}>
            <option value="newest">Newest</option><option value="oldest">Oldest</option>
            <option value="most_students">Most Students</option><option value="price_high">Highest Revenue</option>
            <option value="price_low">Lowest Price</option><option value="most_active">Most Active</option><option value="name">Name A-Z</option>
          </select>
          <button style={bp} onClick={() => setShowCreate(true)}>➕ Create Batch</button>
        </div>
        {showFilters && (
          <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4,1fr)', gap: 10 }}>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={filters.status || ''} onChange={e => setFilters({ ...filters, status: e.target.value })}>
                <option value="">All</option><option value="draft">Draft</option><option value="active">Active</option>
                <option value="upcoming">Upcoming</option><option value="paused">Paused</option><option value="archived">Archived</option>
              </select>
            </div>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={filters.exam || ''} onChange={e => setFilters({ ...filters, exam: e.target.value })}>
                <option value="">All</option><option value="NEET">NEET</option><option value="JEE">JEE</option><option value="CUET">CUET</option>
                <option value="Class 11">Class 11</option><option value="Class 12">Class 12</option><option value="Foundation">Foundation</option><option value="Crash Course">Crash Course</option>
              </select>
            </div>
            <div><label style={lbl}>Price Min</label><input style={inp} type="number" value={filters.priceMin || ''} onChange={e => setFilters({ ...filters, priceMin: e.target.value })} /></div>
            <div><label style={lbl}>Price Max</label><input style={inp} type="number" value={filters.priceMax || ''} onChange={e => setFilters({ ...filters, priceMax: e.target.value })} /></div>
            <div><label style={lbl}>Students Min</label><input style={inp} type="number" value={filters.studentMin || ''} onChange={e => setFilters({ ...filters, studentMin: e.target.value })} /></div>
            <div><label style={lbl}>Students Max</label><input style={inp} type="number" value={filters.studentMax || ''} onChange={e => setFilters({ ...filters, studentMax: e.target.value })} /></div>
            <div><label style={lbl}>Date From</label><input style={inp} type="date" value={filters.dateFrom || ''} onChange={e => setFilters({ ...filters, dateFrom: e.target.value })} /></div>
            <div><label style={lbl}>Date To</label><input style={inp} type="date" value={filters.dateTo || ''} onChange={e => setFilters({ ...filters, dateTo: e.target.value })} /></div>
            {['spotlight', 'trial', 'bundle', 'flashsale'].map(f => (
              <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Toggle on={filters[f] === 'true'} onChange={v => setFilters({ ...filters, [f]: v ? 'true' : '' })} label={f[0].toUpperCase() + f.slice(1)} />
              </div>
            ))}
            <div style={{ display: 'flex', gap: 8, gridColumn: isMobile ? 'span 2' : 'span 2' }}>
              <button style={bs} onClick={savePreset}>💾 Save Preset</button>
              <button style={bd} onClick={() => setFilters({})}>✕ Clear All</button>
            </div>
          </div>
        )}
        {presets.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {presets.map(p => <span key={p._id} onClick={() => setFilters(p.filters || {})} style={{ ...chip(ACC, 'rgba(77,159,255,0.12)'), cursor: 'pointer' }}>⭐ {p.name}</span>)}
          </div>
        )}
      </div>

      {/* ── Bulk Actions ── */}
      {selectedIds.length > 0 && (
        <div style={{ ...cs, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 12.5, color: TS }}>{selectedIds.length} selected</span>
          <button style={bs} onClick={() => bulkAction('archive')}>📦 Archive/Unarchive</button>
          <button style={bd} onClick={() => bulkAction('delete')}>🗑️ Delete Selected</button>
          <button style={bs} onClick={() => setSelectedIds([])}>✕ Clear Selection</button>
        </div>
      )}

      {/* ── Batch Card Grid ── */}
      {loading ? <EmptyMsg text="⟳ Loading batches…" /> : batches.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: DIM }}>
          <div style={{ fontSize: 60, marginBottom: 10 }}>🗂️</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#93C5FD' }}>No Batches Found</div>
          <div style={{ fontSize: 12, marginTop: 6 }}>Create your first batch or adjust filters.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit,minmax(280px,1fr))', gap: 12 }}>
          {batches.map(b => (
            <div key={b._id} style={{ ...cs, marginBottom: 0, position: 'relative', borderLeft: `3px solid ${b.lifecycleStatus === 'archived' ? DIM : ACC}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <input type="checkbox" checked={selectedIds.includes(b._id)} onChange={() => toggleSelect(b._id)} style={{ marginTop: 2 }} />
                <span style={chip(b.lifecycleStatus === 'active' ? GOOD : b.lifecycleStatus === 'paused' ? WARN : b.lifecycleStatus === 'archived' ? DIM : '#A78BFA', 'rgba(255,255,255,0.06)')}>{b.lifecycleStatus || 'active'}</span>
              </div>
              <div onClick={() => setDetailId(b._id)} style={{ cursor: 'pointer', marginTop: 6 }}>
                <div style={{ fontWeight: 700, fontSize: 14.5, color: '#93C5FD' }}>{b.colorIcon || '📦'} {b.name}</div>
                <div style={{ fontSize: 10, color: DIM, fontFamily: 'monospace', marginTop: 2 }}>{b.batchCode || '—'} · {b.examType}</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '8px 0' }}>
                  <span style={chip('#7DD3FC', 'rgba(59,130,246,0.12)')}>👥 {b.studentCount || 0}{b.seatLimit ? '/' + b.seatLimit : ''}</span>
                  <span style={chip('#6EE7B7', 'rgba(16,185,129,0.12)')}>📝 {b.examCount || 0} Exams</span>
                  <span style={chip('#FDE68A', 'rgba(251,191,36,0.12)')}>₹{b.effectivePrice ?? b.price ?? 0}</span>
                  <span style={chip(ACC, 'rgba(77,159,255,0.12)')}>💚 {b.healthScore ?? 0}</span>
                </div>
                <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                  {b.isSpotlight && <span style={chip('#FBBF24', 'rgba(251,191,36,0.1)')}>✨ Spotlight</span>}
                  {b.allowFreeTrial && <span style={chip(GOOD, 'rgba(52,211,153,0.1)')}>🆓 Trial</span>}
                  {b.isBundle && <span style={chip('#A78BFA', 'rgba(167,139,250,0.1)')}>📦 Bundle</span>}
                  {b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date() && <span style={chip(BAD, 'rgba(248,113,113,0.1)')}>⚡ Flash</span>}
                </div>
                <div style={{ fontSize: 9.5, color: 'rgba(148,163,184,0.5)', marginTop: 8 }}>Updated {b.updatedAt ? new Date(b.updatedAt).toLocaleDateString() : '-'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                <button style={bs} onClick={() => setDetailId(b._id)}>Open</button>
                <button style={bs} onClick={() => duplicateBatch(b._id)}>⧉ Duplicate</button>
                <button style={bs} onClick={() => archiveBatch(b._id)}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive'}</button>
                <button style={bd} onClick={() => deleteBatch(b._id, b.name)}>🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showCreate && <CreateBatchWizard base={base} authHeaders={authHeaders} isMobile={isMobile} onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); loadBatches(); showToast('✅ Batch created') }} />}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════
// CREATE BATCH WIZARD (multi-step)
// ══════════════════════════════════════════════════════════════════
function CreateBatchWizard({ base, authHeaders, isMobile, onClose, onCreated }: any) {
  const [step, setStep] = useState(1)
  const [templates, setTemplates] = useState<any[]>([])
  const [form, setForm] = useState<any>({
    name: '', batchCode: '', examType: 'NEET', description: '', colorIcon: '📦',
    lifecycleStatus: 'draft', visibility: 'public', seatLimit: 0, enrollmentRule: 'open',
    price: 0, discountPrice: '', allowFreeTrial: false, trialDays: 3, isBundle: false,
    bundlePrice: '', isSpotlight: false, autoArchiveAfterEnd: false, templateId: ''
  })
  const [dupWarn, setDupWarn] = useState<any>(null)

  useEffect(() => { fetch(base + '/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  const set = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }))

  const submit = async (confirmDuplicate = false) => {
    const r = await fetch(base, { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...form, confirmDuplicate }) })
    const d = await r.json()
    if (d.warning === 'duplicate') { setDupWarn(d); return }
    if (d.success) onCreated()
    else alert(d.error || 'Failed to create batch')
  }

  const steps = ['Basic Info', 'Lifecycle & Enrollment', 'Pricing Wizard', 'Default Controls', 'Preview & Confirm']

  return (
    <Modal onClose={onClose} width={640}>
      <div style={{ fontWeight: 800, fontSize: 17, color: ACC, marginBottom: 4 }}>➕ Create New Batch</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {steps.map((s, i) => <span key={s} style={{ ...chip(i + 1 === step ? '#fff' : DIM, i + 1 === step ? ACC : 'rgba(255,255,255,0.05)'), fontSize: 10 }}>{i + 1}. {s}</span>)}
      </div>

      {step === 1 && (
        <div>
          {templates.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={lbl}>Batch Template Picker (optional)</label>
              <select style={inp} value={form.templateId} onChange={e => set('templateId', e.target.value)}>
                <option value="">Start blank</option>
                {templates.map(t => <option key={t._id} value={t._id}>{t.name}</option>)}
              </select>
            </div>
          )}
          <label style={lbl}>Batch Name *</label><input style={{ ...inp, marginBottom: 10 }} value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. NEET Dropper 2027" />
          <label style={lbl}>Batch Code</label><input style={{ ...inp, marginBottom: 10 }} value={form.batchCode} onChange={e => set('batchCode', e.target.value)} placeholder="Auto-generated if left blank" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={form.examType} onChange={e => set('examType', e.target.value)}>
                {['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'].map(x => <option key={x}>{x}</option>)}
              </select>
            </div>
            <div><label style={lbl}>Cover Icon</label><input style={inp} value={form.colorIcon} onChange={e => set('colorIcon', e.target.value)} /></div>
          </div>
          <label style={{ ...lbl, marginTop: 10 }}>Description</label>
          <textarea style={{ ...inp, minHeight: 60 }} value={form.description} onChange={e => set('description', e.target.value)} />
        </div>
      )}

      {step === 2 && (
        <div>
          <label style={lbl}>Lifecycle Mode</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.lifecycleStatus} onChange={e => set('lifecycleStatus', e.target.value)}>
            {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
          </select>
          <label style={lbl}>Enrollment Rule Builder</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.enrollmentRule} onChange={e => set('enrollmentRule', e.target.value)}>
            <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option>
            <option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval by Criteria</option>
          </select>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Seat Limit (0 = unlimited)</label><input type="number" style={inp} value={form.seatLimit} onChange={e => set('seatLimit', e.target.value)} /></div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => set('visibility', e.target.value)}>
                <option value="public">Public</option><option value="private">Private</option><option value="invite_only">Invite Only</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {step === 3 && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Base Price ₹</label><input type="number" style={inp} value={form.price} onChange={e => set('price', e.target.value)} /></div>
            <div><label style={lbl}>Discount Price ₹</label><input type="number" style={inp} value={form.discountPrice} onChange={e => set('discountPrice', e.target.value)} /></div>
          </div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Toggle on={form.allowFreeTrial} onChange={v => set('allowFreeTrial', v)} label="Enable Free Trial" />
            {form.allowFreeTrial && <input type="number" style={inp} value={form.trialDays} onChange={e => set('trialDays', e.target.value)} placeholder="Trial days" />}
            <Toggle on={form.isBundle} onChange={v => set('isBundle', v)} label="Bundle Pricing" />
            {form.isBundle && <input type="number" style={inp} value={form.bundlePrice} onChange={e => set('bundlePrice', e.target.value)} placeholder="Bundle price" />}
          </div>
        </div>
      )}

      {step === 4 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Toggle on={form.isSpotlight} onChange={v => set('isSpotlight', v)} label="✨ Spotlight (Featured)" />
          <Toggle on={form.autoArchiveAfterEnd} onChange={v => set('autoArchiveAfterEnd', v)} label="🗄️ Auto-Archive After End Date" />
        </div>
      )}

      {step === 5 && (
        <div>
          <div style={{ ...cs, marginBottom: 0 }}>
            <div style={{ fontWeight: 700, color: '#93C5FD', fontSize: 14 }}>{form.colorIcon} {form.name || '(Unnamed Batch)'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.examType} · {form.lifecycleStatus} · Seat Limit: {form.seatLimit || 'Unlimited'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Price: ₹{form.price} {form.discountPrice ? `(₹${form.discountPrice} discounted)` : ''}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.allowFreeTrial ? '🆓 Trial Enabled · ' : ''}{form.isBundle ? '📦 Bundle · ' : ''}{form.isSpotlight ? '✨ Spotlight' : ''}</div>
          </div>
          {dupWarn && (
            <div style={{ marginTop: 10, padding: 10, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)', borderRadius: 8, fontSize: 11.5, color: WARN }}>
              ⚠️ Similar batch exists: "{dupWarn.existing?.name}" ({dupWarn.existing?.batchCode}). Create anyway?
              <div style={{ marginTop: 8 }}><button style={bp} onClick={() => submit(true)}>Yes, Create Anyway</button></div>
            </div>
          )}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 18 }}>
        <button style={bs} onClick={step === 1 ? onClose : () => setStep(step - 1)}>{step === 1 ? 'Cancel' : '← Back'}</button>
        {step < 5 ? <button style={bp} onClick={() => setStep(step + 1)}>Next →</button> : <button style={bp} onClick={() => submit(false)}>✅ Publish Batch</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// ADD / TRANSFER STUDENT MODAL — dual ID/Email selector
// ══════════════════════════════════════════════════════════════════
function StudentAddTransferModal({ base, authHeaders, batchId, mode, batches, onClose, onDone, showToast }: any) {
  const [inputType, setInputType] = useState<'id' | 'email'>('id')
  const [val, setVal] = useState('')
  const [suggestions, setSuggestions] = useState<any[]>([])
  const [matched, setMatched] = useState<any>(null)
  const [toBatch, setToBatch] = useState('')
  const [beforeAfter, setBeforeAfter] = useState<any>(null)

  useEffect(() => {
    if (!val || val.length < 2) { setSuggestions([]); return }
    const t = setTimeout(() => {
      fetch(base + '/student-lookup?query=' + encodeURIComponent(val), { headers: authHeaders }).then(r => r.json()).then(d => setSuggestions(d.matches || [])).catch(() => {})
    }, 300)
    return () => clearTimeout(t)
  }, [val])

  const confirm = async () => {
    const payload: any = inputType === 'id' ? { studentId: matched ? matched.studentId || matched._id : val } : { email: matched ? matched.email : val }
    if (mode === 'add') {
      const r = await fetch(base + '/' + batchId + '/students/add', { method: 'POST', headers: authHeaders, body: JSON.stringify(payload) })
      const d = await r.json()
      if (d.success) { setBeforeAfter(d); showToast('✅ Student added to batch'); }
      else showToast('⚠️ ' + (d.error || 'Failed'))
    } else {
      if (!toBatch) { showToast('⚠️ Select target batch'); return }
      const r = await fetch(base + '/' + batchId + '/students/transfer', { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...payload, toBatchId: toBatch }) })
      const d = await r.json()
      if (d.success) { setBeforeAfter(d); showToast('✅ Student transferred') }
      else showToast('⚠️ ' + (d.error || 'Failed'))
    }
  }

  return (
    <Modal onClose={onClose} width={480}>
      <div style={{ fontWeight: 800, fontSize: 16, color: ACC, marginBottom: 12 }}>{mode === 'add' ? '➕ Add Student to Batch' : '🔄 Transfer Student'}</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
        <button style={inputType === 'id' ? bp : bs} onClick={() => setInputType('id')}>🆔 By Student ID</button>
        <button style={inputType === 'email' ? bp : bs} onClick={() => setInputType('email')}>📧 By Registered Email</button>
      </div>
      <input style={inp} value={val} onChange={e => { setVal(e.target.value); setMatched(null) }} placeholder={inputType === 'id' ? 'Enter Student ID (PRxxABCD)…' : 'Enter registered email…'} />
      {suggestions.length > 0 && !matched && (
        <div style={{ marginTop: 6, border: `1px solid ${BOR}`, borderRadius: 8, overflow: 'hidden' }}>
          {suggestions.map(s => (
            <div key={s._id} onClick={() => { setMatched(s); setVal(inputType === 'id' ? (s.studentId || s._id) : s.email) }} style={{ padding: '8px 10px', cursor: 'pointer', fontSize: 12, borderBottom: `1px solid ${BOR}`, color: TS }}>
              {s.name} — {s.email} {s.studentId ? `(${s.studentId})` : ''}
            </div>
          ))}
        </div>
      )}
      {matched && <div style={{ marginTop: 8, fontSize: 12, color: GOOD }}>✅ Matched: {matched.name} ({matched.email})</div>}

      {mode === 'transfer' && (
        <div style={{ marginTop: 12 }}>
          <label style={lbl}>Move To Batch</label>
          <select style={inp} value={toBatch} onChange={e => setToBatch(e.target.value)}>
            <option value="">Select target batch…</option>
            {(batches || []).filter((b: any) => b._id !== batchId).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
        </div>
      )}

      {beforeAfter && (
        <div style={{ marginTop: 12, padding: 10, background: 'rgba(52,211,153,0.08)', border: '1px solid rgba(52,211,153,0.25)', borderRadius: 8, fontSize: 12, color: GOOD }}>
          {mode === 'add'
            ? <>Before: {beforeAfter.before?.count} students → After: {beforeAfter.after?.count} students</>
            : <>Source: {beforeAfter.before?.fromCount} → {beforeAfter.after?.fromCount} · Target: {beforeAfter.before?.toCount} → {beforeAfter.after?.toCount}</>}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 16 }}>
        <button style={bs} onClick={onClose}>Close</button>
        {!beforeAfter ? <button style={bp} onClick={confirm}>Confirm</button> : <button style={bp} onClick={() => { onDone(); onClose() }}>Done</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// BATCH DETAIL PAGE — 10 Tabs
// ══════════════════════════════════════════════════════════════════
function BatchDetail({ id, base, authHeaders, onBack, isMobile, showToast, allBatches }: any) {
  const [tab, setTab] = useState('overview')
  const [detail, setDetail] = useState<any>(null)
  const [notFound, setNotFound] = useState(false)
  const [modal, setModal] = useState<'' | 'add' | 'transfer'>('')

  const load = useCallback(() => {
    fetch(base + '/' + id, { headers: authHeaders })
      .then(r => { if (!r.ok) throw new Error('not-found'); return r.json() })
      .then(d => { if (d.error) throw new Error(d.error); setDetail(d) })
      .catch(() => setNotFound(true))
  }, [id])
  useEffect(() => { load() }, [load])

  if (notFound) {
    return (
      <div style={{ textAlign: 'center', padding: '50px 20px' }}>
        <div style={{ fontSize: 40, marginBottom: 10 }}>⚠️</div>
        <div style={{ color: '#F87171', fontWeight: 700, marginBottom: 10 }}>This batch could not be found. It may have been deleted.</div>
        <button style={bp} onClick={onBack}>← Back to Batch Management</button>
      </div>
    )
  }

  const tabs = [
    ['overview', '📊 Overview'], ['students', '👥 Students'], ['exams', '📝 Exams'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],
    ['announcements', '📢 Announcements'], ['settings', '🔧 Settings'], ['audit', '🕐 Audit History']
  ]

  if (!detail) return <EmptyMsg text="⟳ Loading batch details…" />
  const b = detail.batch || {}

  return (
    <div>
      <button style={{ ...bs, marginBottom: 10 }} onClick={onBack}>← Back to Batch Management</button>

      <div style={{ ...cs, background: `linear-gradient(135deg,${CRD2},${CRD})` }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div>
            <div style={{ fontWeight: 800, fontSize: 19, color: '#93C5FD' }}>{b.colorIcon || '📦'} {b.name}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{b.batchCode} · {b.examType} · {b.lifecycleStatus}</div>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: ACC }}>{b.healthScore}</div><div style={{ fontSize: 9, color: DIM }}>HEALTH SCORE</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#7DD3FC' }}>{b.studentCount}</div><div style={{ fontSize: 9, color: DIM }}>STUDENTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#6EE7B7' }}>{b.examCount}</div><div style={{ fontSize: 9, color: DIM }}>EXAMS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#FDE68A' }}>₹{b.effectivePrice}</div><div style={{ fontSize: 9, color: DIM }}>PRICE</div></div>
          </div>
        </div>
        {detail.alerts?.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {detail.alerts.map((a: any, i: number) => <span key={i} style={chip(a.type === 'warning' ? WARN : ACC, 'rgba(255,255,255,0.05)')}>⚠️ {a.message}</span>)}
          </div>
        )}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14, overflowX: isMobile ? 'auto' : 'visible' }}>
        {tabs.map(([k, l]) => <button key={k} onClick={() => setTab(k)} style={tab === k ? bp : bs}>{l}</button>)}
      </div>

      {tab === 'overview' && <OverviewTab detail={detail} base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} load={load} />}
      {tab === 'students' && <StudentsTab base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} />}
      {tab === 'exams' && <ExamsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'controls' && <ControlsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'materials' && <MaterialsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'analytics' && <AnalyticsTab base={base} authHeaders={authHeaders} id={id} allBatches={allBatches} />}
      {tab === 'announcements' && <AnnouncementsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'settings' && <SettingsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'audit' && <AuditTab base={base} authHeaders={authHeaders} id={id} />}

      {modal && <StudentAddTransferModal base={base} authHeaders={authHeaders} batchId={id} mode={modal} batches={allBatches} onClose={() => setModal('')} onDone={load} showToast={showToast} />}
    </div>
  )
}

// ── 6) OVERVIEW TAB ──
function OverviewTab({ detail, base, authHeaders, id, setModal, showToast, load }: any) {
  const b = detail.batch
  const exportSnapshot = () => window.open(base + '/' + id + '/export-snapshot')
  const archiveToggle = async () => { await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders }); showToast('✅ Status updated'); load() }
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(200px,1fr))', gap: 12 }}>
        <div style={cs}><div style={lbl}>Seat Utilization</div><div style={{ fontSize: 22, fontWeight: 800, color: ACC }}>{b.seatUtilPct ?? '∞'}{b.seatUtilPct !== null ? '%' : ''}</div></div>
        <div style={cs}><div style={lbl}>Engagement Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: GOOD }}>{b.engagementMeter}%</div></div>
        <div style={cs}><div style={lbl}>Revenue Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: '#FDE68A' }}>{b.revenueMeter}%</div></div>
        <div style={cs}><div style={lbl}>Faculty</div><div style={{ fontSize: 15, fontWeight: 700, color: TS }}>{b.teacherAssigned || '—'}</div></div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}>
        <button style={bp} onClick={() => setModal('add')}>➕ Add Student</button>
        <button style={bp} onClick={() => setModal('transfer')}>🔄 Transfer Student</button>
        <button style={bs} onClick={archiveToggle}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive Batch'}</button>
        <button style={bs} onClick={exportSnapshot}>📤 Export Snapshot</button>
      </div>
      <BannerPanel base={base} authHeaders={authHeaders} id={id} linkedType="batch" showToast={showToast} />
      <div style={cs}>
        <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8, color: TS }}>Recent Activity</div>
        {(detail.recentActivity || []).length === 0 ? <EmptyMsg text="No recent activity yet." /> :
          detail.recentActivity.map((a: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              <b style={{ color: TS }}>{a.action}</b> — {a.field} {a.changedByName ? 'by ' + a.changedByName : ''} · {new Date(a.timestamp).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── FPR3: Banner Panel (Publish Gate integration) ──
function BannerPanel({ base, authHeaders, id, linkedType, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/banner-panel', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const regenerate = async () => {
    const r = await fetch(base + '/' + id + '/banner-panel/regenerate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner draft generated'); load() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  if (!data) return null
  const banner = data.banner
  const gate = data.gate || {}
  const openBannerManagement = () => window.open(`/admin/x7k2p/banner-generator?${linkedType === 'batch' ? 'batchId' : 'seriesId'}=${id}&${linkedType === 'batch' ? 'batchName' : 'seriesName'}=${encodeURIComponent(banner?.title || '')}`, '_blank')
  return (
    <div style={{ ...cs, border: `1px solid ${gate.ready ? 'rgba(52,211,153,0.35)' : 'rgba(248,113,113,0.35)'}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: TS }}>🖼️ Banner Panel</div>
        <span style={{ fontSize: 10.5, fontWeight: 700, color: gate.ready ? GOOD : BAD }}>{gate.ready ? '✅ Launch Allowed' : '⛔ Launch Blocked'}</span>
      </div>
      {banner ? (
        <>
          <div style={{ fontSize: 12, color: DIM, marginBottom: 8 }}>{banner.title} · Status: {banner.status} · Quality: {banner.qualityScore || 0}/100</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <button style={bs} onClick={openBannerManagement}>✏️ Edit Banner</button>
            <button style={bs} onClick={regenerate}>🔄 Regenerate Draft</button>
          </div>
        </>
      ) : (
        <>
          <div style={{ fontSize: 12, color: BAD, marginBottom: 8 }}>{gate.reason || 'No banner created yet for this batch.'}</div>
          <button style={bp} onClick={regenerate}>➕ Auto-Generate Banner Draft</button>
        </>
      )}
    </div>
  )
}

// ── 7) STUDENTS TAB ──
function StudentsTab({ base, authHeaders, id, setModal, showToast }: any) {
  const [students, setStudents] = useState<any[]>([])
  const [q, setQ] = useState(''); const [status, setStatus] = useState(''); const [sort, setSort] = useState('')
  const load = useCallback(() => {
    const params = new URLSearchParams(); if (q) params.set('q', q); if (status) params.set('status', status); if (sort) params.set('sort', sort)
    fetch(base + '/' + id + '/students?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setStudents(d.students || [])).catch(() => {})
  }, [q, status, sort])
  useEffect(() => { load() }, [load])

  const remove = async (sid: string) => { if (!window.confirm('Remove student from batch?')) return; await fetch(base + '/' + id + '/students/' + sid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Removed'); load() }
  const setInactive = async (sid: string, s: string) => { await fetch(base + '/' + id + '/students/' + sid + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status: s }) }); load() }
  const exportCsv = () => window.open(base + '/' + id + '/students/export')

  return (
    <div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
        <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search student…" value={q} onChange={e => setQ(e.target.value)} />
        <select style={{ ...inp, width: 130 }} value={status} onChange={e => setStatus(e.target.value)}><option value="">All Status</option><option value="active">Active</option><option value="inactive">Inactive</option></select>
        <select style={{ ...inp, width: 130 }} value={sort} onChange={e => setSort(e.target.value)}><option value="">Newest</option><option value="oldest">Oldest</option><option value="name">Name</option></select>
        <button style={bp} onClick={() => setModal('add')}>➕ Add</button>
        <button style={bp} onClick={() => setModal('transfer')}>🔄 Transfer</button>
        <button style={bs} onClick={exportCsv}>⬇️ Export CSV</button>
      </div>
      {students.length === 0 ? <EmptyMsg text="No students in this batch yet." /> : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <thead><tr style={{ color: DIM, textAlign: 'left' }}><th style={{ padding: 6 }}>Name</th><th>ID</th><th>Email</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead>
            <tbody>
              {students.map(s => (
                <tr key={s._id} style={{ borderTop: `1px solid ${BOR}` }}>
                  <td style={{ padding: 6, color: TS }}>{s.name}</td><td style={{ color: DIM }}>{s.studentId}</td><td style={{ color: DIM }}>{s.email}</td>
                  <td><span style={chip(s.status === 'active' ? GOOD : DIM, 'rgba(255,255,255,0.05)')}>{s.status}</span></td>
                  <td style={{ color: DIM }}>{s.joinedDate ? new Date(s.joinedDate).toLocaleDateString() : '-'}</td>
                  <td>
                    <button style={{ ...bs, padding: '3px 8px', marginRight: 4 }} onClick={() => setInactive(s._id, s.status === 'active' ? 'inactive' : 'active')}>{s.status === 'active' ? 'Mark Inactive' : 'Mark Active'}</button>
                    <button style={{ ...bd, padding: '3px 8px' }} onClick={() => remove(s._id)}>Remove</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ── 8) EXAMS TAB ──
function ExamsTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>({ assigned: [], available: [] })
  const load = useCallback(() => fetch(base + '/' + id + '/exams', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const assign = async (examId: string) => { await fetch(base + '/' + id + '/exams/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ examId }) }); showToast('✅ Exam assigned'); load() }
  const unassign = async (examId: string) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Exam removed'); load() }
  const updateFlag = async (examId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Exams ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No exams assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Available Exams</div>
        {(!data.available || data.available.length === 0) ? <EmptyMsg text="No more exams available." /> : data.available.map((e: any) => (
          <div key={e._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
            <span style={{ color: DIM, fontSize: 12 }}>{e.title || e.name}</span>
            <button style={{ ...bs, padding: '3px 10px' }} onClick={() => assign(e._id)}>+ Assign</button>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 9) PRICING TAB ──
function PricingTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [form, setForm] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/pricing', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  useEffect(() => { if (data?.pricing) setForm(data.pricing) }, [data])
  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>

      <div style={{ ...cs, marginTop: 16 }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>💡 Revenue Forecast</div>
        <div style={{ fontSize: 12, color: DIM }}>Expected Income: ₹{Math.round(data.forecast?.expectedIncome || 0)} · Conversion Estimate: {data.forecast?.conversionEstimate}% · Offer Performance: {data.forecast?.offerPerformance}</div>
      </div>

      <div style={{ ...cs }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>📜 Price History Timeline</div>
        {(!data.history || data.history.length === 0) ? <EmptyMsg text="No price changes yet." /> :
          data.history.slice().reverse().map((h: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              {h.field}: ₹{h.oldPrice} → ₹{h.newPrice} by {h.updatedByName} · {new Date(h.updatedAt).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/controls', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!data) return <EmptyMsg text="⟳ Loading controls…" />
  const c = data.controls
  const update = async (patch: any) => { await fetch(base + '/' + id + '/controls', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) }); showToast('✅ Control updated'); load(); loadParent && loadParent() }
  const pause = async () => { await fetch(base + '/' + id + '/controls/pause', { method: 'PUT', headers: authHeaders }); showToast('✅ Pause toggled'); load(); loadParent && loadParent() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14 }}>
        <Toggle on={c.isSpotlight} onChange={v => update({ isSpotlight: v })} label="✨ Spotlight" />
        <Toggle on={c.isBundle} onChange={v => update({ isBundle: v })} label="📦 Bundle" />
        <Toggle on={c.allowFreeTrial} onChange={v => update({ allowFreeTrial: v })} label="🆓 Free Trial" />
      </div>
      <div style={cs}>
        <label style={lbl}>Batch Status Manager</label>
        <select style={inp} value={c.lifecycleStatus} onChange={e => update({ lifecycleStatus: e.target.value })}>
          {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Enrollment Lock / Access Policy</label>
        <select style={{ ...inp, marginBottom: 8 }} value={c.enrollmentRule} onChange={e => update({ enrollmentRule: e.target.value })}>
          <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval</option>
        </select>
        <select style={inp} value={c.accessPolicy} onChange={e => update({ accessPolicy: e.target.value })}>
          <option value="open">Open Access</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="code_based">Code-Based Join</option>
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Seat Limit</label>
        <input style={inp} type="number" value={c.seatLimit} onChange={e => update({ seatLimit: e.target.value })} />
      </div>
      <button style={bd} onClick={pause}>{c.lifecycleStatus === 'paused' ? '▶️ Resume Batch (One-Click)' : '⏸️ One-Click Pause'}</button>
      {data.snapshot && <div style={{ fontSize: 11, color: DIM, marginTop: 10 }}>Last applied by {data.snapshot.appliedBy} at {new Date(data.snapshot.appliedAt).toLocaleString()}</div>}
    </div>
  )
}

// ── 11) MATERIALS TAB ──
function MaterialsTab({ base, authHeaders, id, showToast }: any) {
  const [materials, setMaterials] = useState<any[]>([])
  const [form, setForm] = useState<any>({ title: '', type: 'pdf', url: '', category: 'General' })
  const load = useCallback(() => fetch(base + '/' + id + '/materials', { headers: authHeaders }).then(r => r.json()).then(d => setMaterials(d.materials || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const add = async () => { if (!form.title) return showToast('⚠️ Title required'); await fetch(base + '/' + id + '/materials', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) }); showToast('✅ Material added'); setForm({ title: '', type: 'pdf', url: '', category: 'General' }); load() }
  const pin = async (mid: string, pinned: boolean) => { await fetch(base + '/' + id + '/materials/' + mid, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ pinned: !pinned }) }); load() }
  const del = async (mid: string) => { if (!window.confirm('Delete material?')) return; await fetch(base + '/' + id + '/materials/' + mid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8 }}>
        <input style={inp} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>{['pdf', 'video', 'doc', 'link', 'image', 'other'].map(x => <option key={x}>{x}</option>)}</select>
        <input style={inp} placeholder="URL" value={form.url} onChange={e => setForm({ ...form, url: e.target.value })} />
        <input style={inp} placeholder="Category" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} />
        <button style={bp} onClick={add}>⬆️ Upload</button>
      </div>
      {materials.length === 0 ? <EmptyMsg text="No materials uploaded yet." /> : materials.map(m => (
        <div key={m._id} style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{m.pinned ? '📌 ' : ''}{m.title} <span style={{ fontSize: 10, color: DIM }}>v{m.version}</span></div>
            <div style={{ fontSize: 10, color: DIM }}>{m.type} · {m.subject} {m.expiryDate ? '· expires ' + new Date(m.expiryDate).toLocaleDateString() : ''}</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={bs} onClick={() => pin(m._id, m.pinned)}>{m.pinned ? 'Unpin' : 'Pin'}</button>
            <button style={bd} onClick={() => del(m._id)}>Delete</button>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── 12) ANALYTICS TAB ──
function AnalyticsTab({ base, authHeaders, id, allBatches }: any) {
  const [data, setData] = useState<any>(null)
  const [compareWith, setCompareWith] = useState('')
  const [cmp, setCmp] = useState<any>(null)
  useEffect(() => { fetch(base + '/' + id + '/analytics', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}) }, [])
  const runCompare = async () => { if (!compareWith) return; const d = await fetch(base + '/' + id + '/analytics/compare?withId=' + compareWith, { headers: authHeaders }).then(r => r.json()); setCmp(d) }
  if (!data) return <EmptyMsg text="⟳ Loading analytics…" />
  const a = data.analytics
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))', gap: 10 }}>
        {[['Health Score', a.healthScore, ACC], ['Active Users', a.activeUsers, '#7DD3FC'], ['Exam Participation', a.examParticipation, '#6EE7B7'],
        ['Avg Score', a.avgScore ?? '—', '#FDE68A'], ['Revenue', '₹' + a.revenueSummary, GOOD], ['Seat Util %', a.seatUtilization ?? '∞', WARN],
        ['Engagement Trend', a.engagementTrend + '%', ACC], ['Revenue/Seat', '₹' + a.revenuePerSeat, '#A78BFA'], ['Churn Trend', a.churnTrend, BAD]].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v}</div><div style={{ fontSize: 9.5, color: DIM }}>{l}</div></div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🔻 Conversion Funnel</div>
        <div style={{ fontSize: 12, color: DIM }}>Views: {a.conversionFunnel?.views} → Wishlisted: {a.conversionFunnel?.wishlisted} → Enrolled: {a.conversionFunnel?.enrolled}</div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>⚖️ Batch Comparison</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <select style={inp} value={compareWith} onChange={e => setCompareWith(e.target.value)}>
            <option value="">Select batch to compare…</option>
            {(allBatches || []).filter((b: any) => b._id !== id).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
          <button style={bs} onClick={runCompare}>Compare</button>
        </div>
        {cmp && <div style={{ fontSize: 12, color: DIM, marginTop: 8 }}>{cmp.a?.name}: {cmp.a?.studentCount} students, ₹{cmp.a?.revenue} vs {cmp.b?.name}: {cmp.b?.studentCount} students, ₹{cmp.b?.revenue}</div>}
      </div>
    </div>
  )
}

// ── 13) ANNOUNCEMENTS TAB ──
function AnnouncementsTab({ base, authHeaders, id, showToast }: any) {
  const [list, setList] = useState<any[]>([])
  const [form, setForm] = useState({ title: '', message: '', urgent: false, scheduledAt: '' })
  const load = useCallback(() => fetch(base + '/' + id + '/announcements', { headers: authHeaders }).then(r => r.json()).then(d => setList(d.announcements || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const send = async () => {
    if (!form.message) return showToast('⚠️ Message required')
    const r = await fetch(base + '/' + id + '/announcements', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    showToast(`✅ Sent to ${d.notified || 0} students`)
    setForm({ title: '', message: '', urgent: false, scheduledAt: '' }); load()
  }
  return (
    <div>
      <div style={cs}>
        <input style={{ ...inp, marginBottom: 8 }} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <textarea style={{ ...inp, minHeight: 70, marginBottom: 8 }} placeholder="Message" value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} />
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <Toggle on={form.urgent} onChange={v => setForm({ ...form, urgent: v })} label="🚨 Urgent" />
          <input style={{ ...inp, width: 200 }} type="datetime-local" value={form.scheduledAt} onChange={e => setForm({ ...form, scheduledAt: e.target.value })} />
          <button style={bp} onClick={send}>📢 Send / Schedule</button>
        </div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>History</div>
        {list.length === 0 ? <EmptyMsg text="No announcements sent yet." /> : list.map((a: any) => (
          <div key={a._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{a.urgent ? '🚨 ' : ''}{a.title}</div>
            <div style={{ color: DIM, fontSize: 11 }}>{a.message}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const save = async () => { await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) }); showToast('✅ Settings saved'); load(); loadParent && loadParent() }
  const toggleLock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); load() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Batch Name</label><input style={inp} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Color / Icon</label><input style={inp} value={s.colorIcon} onChange={e => setS({ ...s, colorIcon: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
        <div><label style={lbl}>Teacher / Faculty</label><input style={inp} value={s.teacherAssigned} onChange={e => setS({ ...s, teacherAssigned: e.target.value })} /></div>
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={bp} onClick={save}>💾 Save Settings</button>
        <button style={bs} onClick={toggleLock}>{s.isLocked ? '🔓 Unlock Batch' : '🔒 Lock Batch'}</button>
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

// ── 15) AUDIT HISTORY TAB ──
function AuditTab({ base, authHeaders, id }: any) {
  const [audit, setAudit] = useState<any[]>([])
  useEffect(() => { fetch(base + '/' + id + '/audit', { headers: authHeaders }).then(r => r.json()).then(d => setAudit(d.audit || [])).catch(() => {}) }, [])
  return (
    <div style={cs}>
      {audit.length === 0 ? <EmptyMsg text="No audit records yet." /> : audit.map((a, i) => (
        <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}`, fontSize: 11.5 }}>
          <div style={{ color: TS, fontWeight: 600 }}>{a.action} — {a.field}</div>
          <div style={{ color: DIM }}>Old: {JSON.stringify(a.oldValue)} → New: {JSON.stringify(a.newValue)}</div>
          <div style={{ color: DIM, fontSize: 10 }}>{a.changedByName} · {new Date(a.timestamp).toLocaleString()}</div>
        </div>
      ))}
    </div>
  )
}
PRVRNK_EOF_MARKER
  echo "✅ BatchManagerUltra.tsx updated (EMI removed)"
else echo "ℹ️  BatchManagerUltra.tsx not found — skipping (FPR1 may not be installed)"; fi

# ── 4) admin/x7k2p/TestSeriesManagerUltra.tsx (FPR2) ──
if [ -f "$ADMIN_DIR/TestSeriesManagerUltra.tsx" ]; then
  cp "$ADMIN_DIR/TestSeriesManagerUltra.tsx" "$ADMIN_DIR/TestSeriesManagerUltra.tsx.bak_emirm"
  cat > "$ADMIN_DIR/TestSeriesManagerUltra.tsx" << 'PRVRNK_EOF_MARKER'
'use client'
// ══════════════════════════════════════════════════════════════════
// FPR2 — TEST SERIES MANAGEMENT ULTRA SaaS UPGRADE (Admin) — Frontend
// Home (cards + smart search/filter + create) + Detail (10 tabs)
// Add Student by ID + Email · Pricing · Controls · Materials
// Analytics · Announcements · Settings · Audit History · Templates
// Desktop + Mobile responsive · Admin theme matched
// ══════════════════════════════════════════════════════════════════
import { useState, useEffect, useCallback, useRef } from 'react'

// ── Theme (matches global admin panel theme) ─────────────────────
const CRD  = 'rgba(0,28,52,0.88)'
const CRD2 = 'rgba(0,36,65,0.92)'
const ACC  = '#4D9FFF'
const BOR  = 'rgba(77,159,255,0.18)'
const BOR2 = 'rgba(77,159,255,0.3)'
const TS   = '#E8F4FF'
const DIM  = '#6B8FAF'
const GOOD = '#34D399'
const WARN = '#FBBF24'
const BAD  = '#F87171'

const cs: any = { background: CRD, border: `1px solid ${BOR}`, borderRadius: 14, padding: 18, marginBottom: 14, backdropFilter: 'blur(12px)' }
const inp: any = { width: '100%', padding: '10px 12px', background: 'rgba(0,22,40,0.85)', border: `1.5px solid ${BOR2}`, borderRadius: 10, color: TS, fontSize: 13, fontFamily: 'Inter,sans-serif', outline: 'none', boxSizing: 'border-box' }
const bp: any = { background: `linear-gradient(135deg,${ACC},#0055CC)`, color: '#fff', border: 'none', borderRadius: 10, padding: '10px 18px', cursor: 'pointer', fontWeight: 700, fontSize: 13, fontFamily: 'Inter,sans-serif', boxShadow: '0 4px 16px rgba(77,159,255,0.35)' }
const bs: any = { background: 'rgba(77,159,255,0.1)', color: ACC, border: `1px solid ${BOR2}`, borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const bd: any = { background: 'rgba(239,68,68,0.1)', color: BAD, border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '7px 14px', cursor: 'pointer', fontWeight: 600, fontSize: 12 }
const lbl: any = { display: 'block', fontSize: 10.5, color: DIM, marginBottom: 5, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }
const pageTitle: any = { fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, color: TS, margin: '0 0 4px', background: `linear-gradient(90deg,${ACC},#fff)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }
const pageSub: any = { fontSize: 12, color: DIM, marginBottom: 18 }
const chip = (color: string, bg: string): any => ({ fontSize: 10.5, color, background: bg, padding: '3px 10px', borderRadius: 20, fontWeight: 600, display: 'inline-block' })

function useIsMobile() {
  const [m, setM] = useState(false)
  useEffect(() => {
    const chk = () => setM(window.innerWidth < 768)
    chk(); window.addEventListener('resize', chk)
    return () => window.removeEventListener('resize', chk)
  }, [])
  return m
}

function Toggle({ on, onChange, label }: { on: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <div onClick={() => onChange(!on)} style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
      <div style={{ width: 38, height: 20, borderRadius: 20, background: on ? ACC : 'rgba(107,143,175,0.3)', position: 'relative', transition: 'all .2s' }}>
        <div style={{ width: 16, height: 16, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: on ? 20 : 2, transition: 'all .2s' }} />
      </div>
      {label && <span style={{ fontSize: 12, color: TS }}>{label}</span>}
    </div>
  )
}

function Modal({ children, onClose, width = 560 }: { children: any; onClose: () => void; width?: number }) {
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 14 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: `linear-gradient(135deg,${CRD2},${CRD})`, border: `1.5px solid ${BOR2}`, borderRadius: 18, padding: 22, maxWidth: width, width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
        {children}
      </div>
    </div>
  )
}

function EmptyMsg({ text }: { text: string }) {
  return <div style={{ textAlign: 'center', padding: '30px 10px', color: DIM, fontSize: 12.5 }}>{text}</div>
}

// ══════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════════════════════
export default function TestSeriesManagerUltra({ token, API }: { token: string; API: string }) {
  const isMobile = useIsMobile()
  const [series, setSeriesList] = useState<any[]>([])
  const [summary, setSummary] = useState<any>({})
  const [loading, setLoading] = useState(false)
  const [q, setQ] = useState('')
  const [filters, setFilters] = useState<any>({})
  const [showFilters, setShowFilters] = useState(false)
  const [sort, setSort] = useState('newest')
  const [selectedIds, setSelectedIds] = useState<string[]>([])
  const [detailId, setDetailId] = useState<string | null>(() => {
    try { return typeof window !== 'undefined' ? localStorage.getItem('pr_tsm_detailId') : null } catch (e) { return null }
  })
  const [showCreate, setShowCreate] = useState(false)
  const [presets, setPresets] = useState<any[]>([])
  const [toast, setToast] = useState('')

  const authHeaders = { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }
  const base = API + '/api/admin/test-series-manager'

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3500) }

  const loadSeries = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (q) params.set('q', q)
      Object.entries(filters).forEach(([k, v]: any) => { if (v !== undefined && v !== '' && v !== null) params.set(k, String(v)) })
      if (sort) params.set('sort', sort)
      const r = await fetch(base + '?' + params.toString(), { headers: authHeaders })
      const d = await r.json()
      setSeriesList(d.series || [])
      setSummary(d.summary || {})
    } catch (e) { showToast('⚠️ Failed to load series') }
    setLoading(false)
  }, [q, filters, sort])

  useEffect(() => { loadSeries() }, [loadSeries])

  useEffect(() => {
    try {
      if (detailId) localStorage.setItem('pr_tsm_detailId', detailId)
      else localStorage.removeItem('pr_tsm_detailId')
    } catch (e) { /* localStorage unavailable */ }
  }, [detailId])

  useEffect(() => {
    fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json()).then(d => setPresets(d.presets || [])).catch(() => {})
  }, [])

  const savePreset = async () => {
    const name = window.prompt('Preset name?')
    if (!name) return
    await fetch(base + '/filter-presets', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, filters }) })
    const d = await fetch(base + '/filter-presets', { headers: authHeaders }).then(r => r.json())
    setPresets(d.presets || [])
    showToast('✅ Filter preset saved')
  }

  const toggleSelect = (id: string) => setSelectedIds(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  const bulkAction = async (action: 'archive' | 'delete') => {
    if (selectedIds.length === 0) return
    if (action === 'delete' && !window.confirm(`Delete ${selectedIds.length} selected series(es)? This cannot be undone.`)) return
    for (const id of selectedIds) {
      await fetch(base + '/' + id + (action === 'archive' ? '/archive' : ''), { method: action === 'archive' ? 'PUT' : 'DELETE', headers: authHeaders })
    }
    showToast(action === 'archive' ? '✅ Test series archived/unarchived' : '✅ Test series deleted')
    setSelectedIds([])
    loadSeries()
  }

  const duplicateSeries = async (id: string) => {
    const r = await fetch(base + '/' + id + '/duplicate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Series duplicated'); loadSeries() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  const archiveSeries = async (id: string) => {
    const r = await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Status: ' + d.lifecycleStatus); loadSeries() }
  }
  const deleteSeries = async (id: string, name: string) => {
    if (!window.confirm(`Delete series "${name}"? Students will be unassigned.`)) return
    const r = await fetch(base + '/' + id, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Series deleted'); loadSeries() }
  }

  if (detailId) {
    return <TestSeriesDetail id={detailId} base={base} authHeaders={authHeaders} onBack={() => { setDetailId(null); loadSeries() }} isMobile={isMobile} showToast={showToast} allSeries={series} />
  }

  return (
    <div>
      <div style={pageTitle}>📚 Test Series Management — Ultra SaaS</div>
      <div style={pageSub}>Complete lifecycle control — create, price, control, enroll, assign tests, analyze & archive series.</div>

      {toast && <div style={{ position: 'fixed', top: 16, right: 16, zIndex: 10000, background: CRD2, border: `1px solid ${BOR2}`, borderRadius: 10, padding: '10px 16px', color: TS, fontSize: 12.5, boxShadow: '0 8px 24px rgba(0,0,0,0.4)' }}>{toast}</div>}

      {/* ── Status Summary Strip ── */}
      <div style={{ display: 'grid', gridTemplateColumns: isMobile ? 'repeat(3,1fr)' : 'repeat(6,1fr)', gap: 8, marginBottom: 14 }}>
        {[
          ['Active', summary.active, GOOD], ['Paused', summary.paused, WARN], ['Archived', summary.archived, DIM],
          ['Draft', summary.draft, '#A78BFA'], ['Upcoming', summary.upcoming, ACC], ['Students', summary.totalStudents, '#7DD3FC']
        ].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, padding: 10, textAlign: 'center' }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM, textTransform: 'uppercase', letterSpacing: 0.5 }}>{l}</div>
          </div>
        ))}
      </div>

      {/* ── Smart Search + Filter Bar ── */}
      <div style={cs}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <input style={{ ...inp, flex: 1, minWidth: 160 }} placeholder="🔎 Search series, code, exam, student, faculty, email…" value={q} onChange={e => setQ(e.target.value)} />
          <button style={bs} onClick={() => setShowFilters(s => !s)}>🧰 Filters {showFilters ? '▲' : '▼'}</button>
          <select style={{ ...inp, width: 150 }} value={sort} onChange={e => setSort(e.target.value)}>
            <option value="newest">Newest</option><option value="oldest">Oldest</option>
            <option value="most_students">Most Students</option><option value="price_high">Highest Revenue</option>
            <option value="price_low">Lowest Price</option><option value="most_active">Most Active</option><option value="name">Name A-Z</option>
          </select>
          <button style={bp} onClick={() => setShowCreate(true)}>➕ Create Series</button>
        </div>
        {showFilters && (
          <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4,1fr)', gap: 10 }}>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={filters.status || ''} onChange={e => setFilters({ ...filters, status: e.target.value })}>
                <option value="">All</option><option value="draft">Draft</option><option value="active">Active</option>
                <option value="upcoming">Upcoming</option><option value="paused">Paused</option><option value="archived">Archived</option>
              </select>
            </div>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={filters.exam || ''} onChange={e => setFilters({ ...filters, exam: e.target.value })}>
                <option value="">All</option><option value="NEET">NEET</option><option value="JEE">JEE</option><option value="CUET">CUET</option>
                <option value="Class 11">Class 11</option><option value="Class 12">Class 12</option><option value="Foundation">Foundation</option><option value="Crash Course">Crash Course</option>
              </select>
            </div>
            <div><label style={lbl}>Price Min</label><input style={inp} type="number" value={filters.priceMin || ''} onChange={e => setFilters({ ...filters, priceMin: e.target.value })} /></div>
            <div><label style={lbl}>Price Max</label><input style={inp} type="number" value={filters.priceMax || ''} onChange={e => setFilters({ ...filters, priceMax: e.target.value })} /></div>
            <div><label style={lbl}>Students Min</label><input style={inp} type="number" value={filters.studentMin || ''} onChange={e => setFilters({ ...filters, studentMin: e.target.value })} /></div>
            <div><label style={lbl}>Students Max</label><input style={inp} type="number" value={filters.studentMax || ''} onChange={e => setFilters({ ...filters, studentMax: e.target.value })} /></div>
            <div><label style={lbl}>Date From</label><input style={inp} type="date" value={filters.dateFrom || ''} onChange={e => setFilters({ ...filters, dateFrom: e.target.value })} /></div>
            <div><label style={lbl}>Date To</label><input style={inp} type="date" value={filters.dateTo || ''} onChange={e => setFilters({ ...filters, dateTo: e.target.value })} /></div>
            {['spotlight', 'trial', 'bundle', 'flashsale'].map(f => (
              <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Toggle on={filters[f] === 'true'} onChange={v => setFilters({ ...filters, [f]: v ? 'true' : '' })} label={f[0].toUpperCase() + f.slice(1)} />
              </div>
            ))}
            <div style={{ display: 'flex', gap: 8, gridColumn: isMobile ? 'span 2' : 'span 2' }}>
              <button style={bs} onClick={savePreset}>💾 Save Preset</button>
              <button style={bd} onClick={() => setFilters({})}>✕ Clear All</button>
            </div>
          </div>
        )}
        {presets.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {presets.map(p => <span key={p._id} onClick={() => setFilters(p.filters || {})} style={{ ...chip(ACC, 'rgba(77,159,255,0.12)'), cursor: 'pointer' }}>⭐ {p.name}</span>)}
          </div>
        )}
      </div>

      {/* ── Bulk Actions ── */}
      {selectedIds.length > 0 && (
        <div style={{ ...cs, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 12.5, color: TS }}>{selectedIds.length} selected</span>
          <button style={bs} onClick={() => bulkAction('archive')}>📦 Archive/Unarchive</button>
          <button style={bd} onClick={() => bulkAction('delete')}>🗑️ Delete Selected</button>
          <button style={bs} onClick={() => setSelectedIds([])}>✕ Clear Selection</button>
        </div>
      )}

      {/* ── Series Card Grid ── */}
      {loading ? <EmptyMsg text="⟳ Loading series…" /> : series.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '50px 20px', color: DIM }}>
          <div style={{ fontSize: 60, marginBottom: 10 }}>📚</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#93C5FD' }}>No Test Series Found</div>
          <div style={{ fontSize: 12, marginTop: 6 }}>Create your first series or adjust filters.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit,minmax(280px,1fr))', gap: 12 }}>
          {series.map(b => (
            <div key={b._id} style={{ ...cs, marginBottom: 0, position: 'relative', borderLeft: `3px solid ${b.lifecycleStatus === 'archived' ? DIM : ACC}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <input type="checkbox" checked={selectedIds.includes(b._id)} onChange={() => toggleSelect(b._id)} style={{ marginTop: 2 }} />
                <span style={chip(b.lifecycleStatus === 'active' ? GOOD : b.lifecycleStatus === 'paused' ? WARN : b.lifecycleStatus === 'archived' ? DIM : '#A78BFA', 'rgba(255,255,255,0.06)')}>{b.lifecycleStatus || 'active'}</span>
              </div>
              <div onClick={() => setDetailId(b._id)} style={{ cursor: 'pointer', marginTop: 6 }}>
                <div style={{ fontWeight: 700, fontSize: 14.5, color: '#93C5FD' }}>{b.colorIcon || '📚'} {b.name}</div>
                <div style={{ fontSize: 10, color: DIM, fontFamily: 'monospace', marginTop: 2 }}>{b.seriesCode || '—'} · {b.examType}</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', margin: '8px 0' }}>
                  <span style={chip('#7DD3FC', 'rgba(59,130,246,0.12)')}>👥 {b.studentCount || 0}{b.seatLimit ? '/' + b.seatLimit : ''}</span>
                  <span style={chip('#6EE7B7', 'rgba(16,185,129,0.12)')}>📝 {b.testCount || 0} Tests</span>
                  <span style={chip('#FDE68A', 'rgba(251,191,36,0.12)')}>₹{b.effectivePrice ?? b.price ?? 0}</span>
                  <span style={chip(ACC, 'rgba(77,159,255,0.12)')}>💚 {b.healthScore ?? 0}</span>
                </div>
                <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                  {b.isSpotlight && <span style={chip('#FBBF24', 'rgba(251,191,36,0.1)')}>✨ Spotlight</span>}
                  {b.allowFreeTrial && <span style={chip(GOOD, 'rgba(52,211,153,0.1)')}>🆓 Trial</span>}
                  {b.isBundle && <span style={chip('#A78BFA', 'rgba(167,139,250,0.1)')}>📦 Bundle</span>}
                  {b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date() && <span style={chip(BAD, 'rgba(248,113,113,0.1)')}>⚡ Flash</span>}
                </div>
                <div style={{ fontSize: 9.5, color: 'rgba(148,163,184,0.5)', marginTop: 8 }}>Updated {b.updatedAt ? new Date(b.updatedAt).toLocaleDateString() : '-'}</div>
              </div>
              <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                <button style={bs} onClick={() => setDetailId(b._id)}>Open</button>
                <button style={bs} onClick={() => duplicateSeries(b._id)}>⧉ Duplicate</button>
                <button style={bs} onClick={() => archiveSeries(b._id)}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive'}</button>
                <button style={bd} onClick={() => deleteSeries(b._id, b.name)}>🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showCreate && <CreateSeriesWizard base={base} authHeaders={authHeaders} isMobile={isMobile} onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); loadSeries(); showToast('✅ Series created') }} />}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════
// CREATE TEST SERIES WIZARD (multi-step)
// ══════════════════════════════════════════════════════════════════
function CreateSeriesWizard({ base, authHeaders, isMobile, onClose, onCreated }: any) {
  const [step, setStep] = useState(1)
  const [templates, setTemplates] = useState<any[]>([])
  const [form, setForm] = useState<any>({
    name: '', seriesCode: '', examType: 'NEET', description: '', colorIcon: '📚',
    lifecycleStatus: 'draft', visibility: 'public', seatLimit: 0, enrollmentRule: 'open',
    price: 0, discountPrice: '', allowFreeTrial: false, trialDays: 3, isBundle: false,
    bundlePrice: '', isSpotlight: false, autoArchiveAfterEnd: false, templateId: ''
  })
  const [dupWarn, setDupWarn] = useState<any>(null)

  useEffect(() => { fetch(base + '/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  const set = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }))

  const submit = async (confirmDuplicate = false) => {
    const r = await fetch(base, { method: 'POST', headers: authHeaders, body: JSON.stringify({ ...form, confirmDuplicate }) })
    const d = await r.json()
    if (d.warning === 'duplicate') { setDupWarn(d); return }
    if (d.success) onCreated()
    else alert(d.error || 'Failed to create series')
  }

  const steps = ['Basic Info', 'Lifecycle & Enrollment', 'Pricing Wizard', 'Default Controls', 'Preview & Confirm']

  return (
    <Modal onClose={onClose} width={640}>
      <div style={{ fontWeight: 800, fontSize: 17, color: ACC, marginBottom: 4 }}>➕ Create New Test Series</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {steps.map((s, i) => <span key={s} style={{ ...chip(i + 1 === step ? '#fff' : DIM, i + 1 === step ? ACC : 'rgba(255,255,255,0.05)'), fontSize: 10 }}>{i + 1}. {s}</span>)}
      </div>

      {step === 1 && (
        <div>
          {templates.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={lbl}>Series Template Picker (optional)</label>
              <select style={inp} value={form.templateId} onChange={e => set('templateId', e.target.value)}>
                <option value="">Start blank</option>
                {templates.map(t => <option key={t._id} value={t._id}>{t.name}</option>)}
              </select>
            </div>
          )}
          <label style={lbl}>Series Name *</label><input style={{ ...inp, marginBottom: 10 }} value={form.name} onChange={e => set('name', e.target.value)} placeholder="e.g. NEET Full Syllabus Test Series 2027" />
          <label style={lbl}>Series Code</label><input style={{ ...inp, marginBottom: 10 }} value={form.seriesCode} onChange={e => set('seriesCode', e.target.value)} placeholder="Auto-generated if left blank" />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Exam / Course</label>
              <select style={inp} value={form.examType} onChange={e => set('examType', e.target.value)}>
                {['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'].map(x => <option key={x}>{x}</option>)}
              </select>
            </div>
            <div><label style={lbl}>Cover Icon</label><input style={inp} value={form.colorIcon} onChange={e => set('colorIcon', e.target.value)} /></div>
          </div>
          <label style={{ ...lbl, marginTop: 10 }}>Description</label>
          <textarea style={{ ...inp, minHeight: 60 }} value={form.description} onChange={e => set('description', e.target.value)} />
        </div>
      )}

      {step === 2 && (
        <div>
          <label style={lbl}>Lifecycle Mode</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.lifecycleStatus} onChange={e => set('lifecycleStatus', e.target.value)}>
            {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
          </select>
          <label style={lbl}>Enrollment Rule Builder</label>
          <select style={{ ...inp, marginBottom: 10 }} value={form.enrollmentRule} onChange={e => set('enrollmentRule', e.target.value)}>
            <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option>
            <option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval by Criteria</option>
          </select>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Seat Limit (0 = unlimited)</label><input type="number" style={inp} value={form.seatLimit} onChange={e => set('seatLimit', e.target.value)} /></div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => set('visibility', e.target.value)}>
                <option value="public">Public</option><option value="private">Private</option><option value="invite_only">Invite Only</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {step === 3 && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div><label style={lbl}>Base Price ₹</label><input type="number" style={inp} value={form.price} onChange={e => set('price', e.target.value)} /></div>
            <div><label style={lbl}>Discount Price ₹</label><input type="number" style={inp} value={form.discountPrice} onChange={e => set('discountPrice', e.target.value)} /></div>
          </div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Toggle on={form.allowFreeTrial} onChange={v => set('allowFreeTrial', v)} label="Enable Free Trial" />
            {form.allowFreeTrial && <input type="number" style={inp} value={form.trialDays} onChange={e => set('trialDays', e.target.value)} placeholder="Trial days" />}
            <Toggle on={form.isBundle} onChange={v => set('isBundle', v)} label="Bundle Pricing" />
            {form.isBundle && <input type="number" style={inp} value={form.bundlePrice} onChange={e => set('bundlePrice', e.target.value)} placeholder="Bundle price" />}
          </div>
        </div>
      )}

      {step === 4 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Toggle on={form.isSpotlight} onChange={v => set('isSpotlight', v)} label="✨ Spotlight (Featured)" />
          <Toggle on={form.autoArchiveAfterEnd} onChange={v => set('autoArchiveAfterEnd', v)} label="🗄️ Auto-Archive After End Date" />
        </div>
      )}

      {step === 5 && (
        <div>
          <div style={{ ...cs, marginBottom: 0 }}>
            <div style={{ fontWeight: 700, color: '#93C5FD', fontSize: 14 }}>{form.colorIcon} {form.name || '(Unnamed Series)'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.examType} · {form.lifecycleStatus} · Seat Limit: {form.seatLimit || 'Unlimited'}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>Price: ₹{form.price} {form.discountPrice ? `(₹${form.discountPrice} discounted)` : ''}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{form.allowFreeTrial ? '🆓 Trial Enabled · ' : ''}{form.isBundle ? '📦 Bundle · ' : ''}{form.isSpotlight ? '✨ Spotlight' : ''}</div>
          </div>
          {dupWarn && (
            <div style={{ marginTop: 10, padding: 10, background: 'rgba(251,191,36,0.1)', border: '1px solid rgba(251,191,36,0.3)', borderRadius: 8, fontSize: 11.5, color: WARN }}>
              ⚠️ Similar series exists: "{dupWarn.existing?.name}" ({dupWarn.existing?.seriesCode}). Create anyway?
              <div style={{ marginTop: 8 }}><button style={bp} onClick={() => submit(true)}>Yes, Create Anyway</button></div>
            </div>
          )}
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 18 }}>
        <button style={bs} onClick={step === 1 ? onClose : () => setStep(step - 1)}>{step === 1 ? 'Cancel' : '← Back'}</button>
        {step < 5 ? <button style={bp} onClick={() => setStep(step + 1)}>Next →</button> : <button style={bp} onClick={() => submit(false)}>✅ Publish Series</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// ADD / TRANSFER STUDENT MODAL — dual ID/Email selector
// ══════════════════════════════════════════════════════════════════
function StudentAddModal({ base, authHeaders, seriesId, onClose, onDone, showToast }: any) {
  const [inputType, setInputType] = useState<'id' | 'email'>('id')
  const [val, setVal] = useState('')
  const [suggestions, setSuggestions] = useState<any[]>([])
  const [matched, setMatched] = useState<any>(null)
  const [beforeAfter, setBeforeAfter] = useState<any>(null)

  useEffect(() => {
    if (!val || val.length < 2) { setSuggestions([]); return }
    const t = setTimeout(() => {
      fetch(base + '/student-lookup?query=' + encodeURIComponent(val), { headers: authHeaders }).then(r => r.json()).then(d => setSuggestions(d.matches || [])).catch(() => {})
    }, 300)
    return () => clearTimeout(t)
  }, [val])

  const confirm = async () => {
    const payload: any = inputType === 'id' ? { studentId: matched ? matched.studentId || matched._id : val } : { email: matched ? matched.email : val }
    const r = await fetch(base + '/' + seriesId + '/students/add', { method: 'POST', headers: authHeaders, body: JSON.stringify(payload) })
    const d = await r.json()
    if (d.success) { setBeforeAfter(d); showToast('✅ Student added to test series') }
    else showToast('⚠️ ' + (d.error || 'Failed'))
  }

  return (
    <Modal onClose={onClose} width={480}>
      <div style={{ fontWeight: 800, fontSize: 16, color: ACC, marginBottom: 12 }}>➕ Add Student to Test Series</div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
        <button style={inputType === 'id' ? bp : bs} onClick={() => setInputType('id')}>🆔 By Student ID</button>
        <button style={inputType === 'email' ? bp : bs} onClick={() => setInputType('email')}>📧 By Registered Email</button>
      </div>
      <input style={inp} value={val} onChange={e => { setVal(e.target.value); setMatched(null) }} placeholder={inputType === 'id' ? 'Enter Student ID (PRxxABCD)…' : 'Enter registered email…'} />
      {suggestions.length > 0 && !matched && (
        <div style={{ marginTop: 6, border: `1px solid ${BOR}`, borderRadius: 8, overflow: 'hidden' }}>
          {suggestions.map(s => (
            <div key={s._id} onClick={() => { setMatched(s); setVal(inputType === 'id' ? (s.studentId || s._id) : s.email) }} style={{ padding: '8px 10px', cursor: 'pointer', fontSize: 12, borderBottom: `1px solid ${BOR}`, color: TS }}>
              {s.name} — {s.email} {s.studentId ? `(${s.studentId})` : ''}
            </div>
          ))}
        </div>
      )}
      {matched && <div style={{ marginTop: 8, fontSize: 12, color: GOOD }}>✅ Matched: {matched.name} ({matched.email})</div>}

      {beforeAfter && (
        <div style={{ marginTop: 12, padding: 10, background: 'rgba(52,211,153,0.08)', border: '1px solid rgba(52,211,153,0.25)', borderRadius: 8, fontSize: 12, color: GOOD }}>
          Before: {beforeAfter.before?.count} students → After: {beforeAfter.after?.count} students
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 16 }}>
        <button style={bs} onClick={onClose}>Close</button>
        {!beforeAfter ? <button style={bp} onClick={confirm}>Confirm</button> : <button style={bp} onClick={() => { onDone(); onClose() }}>Done</button>}
      </div>
    </Modal>
  )
}

// ══════════════════════════════════════════════════════════════════
// TEST SERIES DETAIL PAGE — 10 Tabs
// ══════════════════════════════════════════════════════════════════
function TestSeriesDetail({ id, base, authHeaders, onBack, isMobile, showToast, allSeries }: any) {
  const [tab, setTab] = useState('overview')
  const [detail, setDetail] = useState<any>(null)
  const [notFound, setNotFound] = useState(false)
  const [modal, setModal] = useState<'' | 'add'>('')

  const load = useCallback(() => {
    fetch(base + '/' + id, { headers: authHeaders })
      .then(r => { if (!r.ok) throw new Error('not-found'); return r.json() })
      .then(d => { if (d.error) throw new Error(d.error); setDetail(d) })
      .catch(() => setNotFound(true))
  }, [id])
  useEffect(() => { load() }, [load])

  if (notFound) {
    return (
      <div style={{ textAlign: 'center', padding: '50px 20px' }}>
        <div style={{ fontSize: 40, marginBottom: 10 }}>⚠️</div>
        <div style={{ color: '#F87171', fontWeight: 700, marginBottom: 10 }}>This series could not be found. It may have been deleted.</div>
        <button style={bp} onClick={onBack}>← Back to Test Series Management</button>
      </div>
    )
  }

  const tabs = [
    ['overview', '📊 Overview'], ['students', '👥 Students'], ['tests', '📝 Tests'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],
    ['announcements', '📢 Announcements'], ['settings', '🔧 Settings'], ['audit', '🕐 Audit History']
  ]

  if (!detail) return <EmptyMsg text="⟳ Loading series details…" />
  const b = detail.series || {}

  return (
    <div>
      <button style={{ ...bs, marginBottom: 10 }} onClick={onBack}>← Back to Test Series Management</button>

      <div style={{ ...cs, background: `linear-gradient(135deg,${CRD2},${CRD})` }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div>
            <div style={{ fontWeight: 800, fontSize: 19, color: '#93C5FD' }}>{b.colorIcon || '📚'} {b.name}</div>
            <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>{b.seriesCode} · {b.examType} · {b.lifecycleStatus}</div>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: ACC }}>{b.healthScore}</div><div style={{ fontSize: 9, color: DIM }}>HEALTH SCORE</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#7DD3FC' }}>{b.studentCount}</div><div style={{ fontSize: 9, color: DIM }}>STUDENTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#6EE7B7' }}>{b.testCount}</div><div style={{ fontSize: 9, color: DIM }}>TESTS</div></div>
            <div style={{ textAlign: 'center' }}><div style={{ fontSize: 20, fontWeight: 800, color: '#FDE68A' }}>₹{b.effectivePrice}</div><div style={{ fontSize: 9, color: DIM }}>PRICE</div></div>
          </div>
        </div>
        {detail.alerts?.length > 0 && (
          <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {detail.alerts.map((a: any, i: number) => <span key={i} style={chip(a.type === 'warning' ? WARN : ACC, 'rgba(255,255,255,0.05)')}>⚠️ {a.message}</span>)}
          </div>
        )}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14, overflowX: isMobile ? 'auto' : 'visible' }}>
        {tabs.map(([k, l]) => <button key={k} onClick={() => setTab(k)} style={tab === k ? bp : bs}>{l}</button>)}
      </div>

      {tab === 'overview' && <OverviewTab detail={detail} base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} load={load} />}
      {tab === 'students' && <StudentsTab base={base} authHeaders={authHeaders} id={id} setModal={setModal} showToast={showToast} />}
      {tab === 'tests' && <TestsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'controls' && <ControlsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'materials' && <MaterialsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'analytics' && <AnalyticsTab base={base} authHeaders={authHeaders} id={id} allSeries={allSeries} />}
      {tab === 'announcements' && <AnnouncementsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'settings' && <SettingsTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}
      {tab === 'audit' && <AuditTab base={base} authHeaders={authHeaders} id={id} />}

      {modal === 'add' && <StudentAddModal base={base} authHeaders={authHeaders} seriesId={id} onClose={() => setModal('')} onDone={load} showToast={showToast} />}
    </div>
  )
}

// ── 6) OVERVIEW TAB ──
function OverviewTab({ detail, base, authHeaders, id, setModal, showToast, load }: any) {
  const b = detail.series
  const exportSnapshot = () => window.open(base + '/' + id + '/export-snapshot')
  const archiveToggle = async () => { await fetch(base + '/' + id + '/archive', { method: 'PUT', headers: authHeaders }); showToast('✅ Status updated'); load() }
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(200px,1fr))', gap: 12 }}>
        <div style={cs}><div style={lbl}>Seat Utilization</div><div style={{ fontSize: 22, fontWeight: 800, color: ACC }}>{b.seatUtilPct ?? '∞'}{b.seatUtilPct !== null ? '%' : ''}</div></div>
        <div style={cs}><div style={lbl}>Engagement Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: GOOD }}>{b.engagementMeter}%</div></div>
        <div style={cs}><div style={lbl}>Revenue Meter</div><div style={{ fontSize: 22, fontWeight: 800, color: '#FDE68A' }}>{b.revenueMeter}%</div></div>
        <div style={cs}><div style={lbl}>Faculty</div><div style={{ fontSize: 15, fontWeight: 700, color: TS }}>{b.teacherAssigned || '—'}</div></div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}>
        <button style={bp} onClick={() => setModal('add')}>➕ Add Student</button>
        <button style={bs} onClick={archiveToggle}>{b.lifecycleStatus === 'archived' ? '♻️ Unarchive' : '📦 Archive Series'}</button>
        <button style={bs} onClick={exportSnapshot}>📤 Export Snapshot</button>
      </div>
      <BannerPanel base={base} authHeaders={authHeaders} id={id} linkedType="series" showToast={showToast} />
      <div style={cs}>
        <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 8, color: TS }}>Recent Activity</div>
        {(detail.recentActivity || []).length === 0 ? <EmptyMsg text="No recent activity yet." /> :
          detail.recentActivity.map((a: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              <b style={{ color: TS }}>{a.action}</b> — {a.field} {a.changedByName ? 'by ' + a.changedByName : ''} · {new Date(a.timestamp).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── FPR3: Banner Panel (Publish Gate integration) ──
function BannerPanel({ base, authHeaders, id, linkedType, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/banner-panel', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const regenerate = async () => {
    const r = await fetch(base + '/' + id + '/banner-panel/regenerate', { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Banner draft generated'); load() } else showToast('⚠️ ' + (d.error || 'Failed'))
  }
  if (!data) return null
  const banner = data.banner
  const gate = data.gate || {}
  const openBannerManagement = () => window.open(`/admin/x7k2p/banner-generator?${linkedType === 'batch' ? 'batchId' : 'seriesId'}=${id}&${linkedType === 'batch' ? 'batchName' : 'seriesName'}=${encodeURIComponent(banner?.title || '')}`, '_blank')
  return (
    <div style={{ ...cs, border: `1px solid ${gate.ready ? 'rgba(52,211,153,0.35)' : 'rgba(248,113,113,0.35)'}` }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: TS }}>🖼️ Banner Panel</div>
        <span style={{ fontSize: 10.5, fontWeight: 700, color: gate.ready ? GOOD : BAD }}>{gate.ready ? '✅ Launch Allowed' : '⛔ Launch Blocked'}</span>
      </div>
      {banner ? (
        <>
          <div style={{ fontSize: 12, color: DIM, marginBottom: 8 }}>{banner.title} · Status: {banner.status} · Quality: {banner.qualityScore || 0}/100</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <button style={bs} onClick={openBannerManagement}>✏️ Edit Banner</button>
            <button style={bs} onClick={regenerate}>🔄 Regenerate Draft</button>
          </div>
        </>
      ) : (
        <>
          <div style={{ fontSize: 12, color: BAD, marginBottom: 8 }}>{gate.reason || 'No banner created yet for this test series.'}</div>
          <button style={bp} onClick={regenerate}>➕ Auto-Generate Banner Draft</button>
        </>
      )}
    </div>
  )
}

// ── 7) STUDENTS TAB ──
function StudentsTab({ base, authHeaders, id, setModal, showToast }: any) {
  const [students, setStudents] = useState<any[]>([])
  const [q, setQ] = useState(''); const [status, setStatus] = useState(''); const [sort, setSort] = useState('')
  const load = useCallback(() => {
    const params = new URLSearchParams(); if (q) params.set('q', q); if (status) params.set('status', status); if (sort) params.set('sort', sort)
    fetch(base + '/' + id + '/students?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setStudents(d.students || [])).catch(() => {})
  }, [q, status, sort])
  useEffect(() => { load() }, [load])

  const remove = async (sid: string) => { if (!window.confirm('Remove student from series?')) return; await fetch(base + '/' + id + '/students/' + sid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Removed'); load() }
  const setInactive = async (sid: string, s: string) => { await fetch(base + '/' + id + '/students/' + sid + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status: s }) }); load() }
  const exportCsv = () => window.open(base + '/' + id + '/students/export')

  return (
    <div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
        <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search student…" value={q} onChange={e => setQ(e.target.value)} />
        <select style={{ ...inp, width: 130 }} value={status} onChange={e => setStatus(e.target.value)}><option value="">All Status</option><option value="active">Active</option><option value="inactive">Inactive</option></select>
        <select style={{ ...inp, width: 130 }} value={sort} onChange={e => setSort(e.target.value)}><option value="">Newest</option><option value="oldest">Oldest</option><option value="name">Name</option></select>
        <button style={bp} onClick={() => setModal('add')}>➕ Add</button>
        <button style={bs} onClick={exportCsv}>⬇️ Export CSV</button>
      </div>
      {students.length === 0 ? <EmptyMsg text="No students in this series yet." /> : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <thead><tr style={{ color: DIM, textAlign: 'left' }}><th style={{ padding: 6 }}>Name</th><th>ID</th><th>Email</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead>
            <tbody>
              {students.map(s => (
                <tr key={s._id} style={{ borderTop: `1px solid ${BOR}` }}>
                  <td style={{ padding: 6, color: TS }}>{s.name}</td><td style={{ color: DIM }}>{s.studentId}</td><td style={{ color: DIM }}>{s.email}</td>
                  <td><span style={chip(s.status === 'active' ? GOOD : DIM, 'rgba(255,255,255,0.05)')}>{s.status}</span></td>
                  <td style={{ color: DIM }}>{s.joinedDate ? new Date(s.joinedDate).toLocaleDateString() : '-'}</td>
                  <td>
                    <button style={{ ...bs, padding: '3px 8px', marginRight: 4 }} onClick={() => setInactive(s._id, s.status === 'active' ? 'inactive' : 'active')}>{s.status === 'active' ? 'Mark Inactive' : 'Mark Active'}</button>
                    <button style={{ ...bd, padding: '3px 8px' }} onClick={() => remove(s._id)}>Remove</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ── 8) TESTS TAB ──
function TestsTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>({ assigned: [], available: [] })
  const load = useCallback(() => fetch(base + '/' + id + '/tests', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const assign = async (testId: string) => { await fetch(base + '/' + id + '/tests/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ testId }) }); showToast('✅ Test assigned'); load() }
  const unassign = async (testId: string) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Test removed'); load() }
  const updateFlag = async (testId: string, field: string, val: boolean) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ [field]: val }) }); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Tests ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No tests assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 6, flexWrap: 'wrap' }}>
              {['required', 'locked', 'featured', 'hidden'].map(f => (
                <Toggle key={f} on={!!e.control?.[f]} onChange={v => updateFlag(e._id, f, v)} label={f} />
              ))}
            </div>
          </div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Available Tests</div>
        {(!data.available || data.available.length === 0) ? <EmptyMsg text="No more tests available." /> : data.available.map((e: any) => (
          <div key={e._id} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
            <span style={{ color: DIM, fontSize: 12 }}>{e.title || e.name}</span>
            <button style={{ ...bs, padding: '3px 10px' }} onClick={() => assign(e._id)}>+ Assign</button>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 9) PRICING TAB ──
function PricingTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [form, setForm] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/pricing', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  useEffect(() => { if (data?.pricing) setForm(data.pricing) }, [data])
  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>

      <div style={{ ...cs, marginTop: 16 }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>💡 Revenue Forecast</div>
        <div style={{ fontSize: 12, color: DIM }}>Expected Income: ₹{Math.round(data.forecast?.expectedIncome || 0)} · Conversion Estimate: {data.forecast?.conversionEstimate}% · Offer Performance: {data.forecast?.offerPerformance}</div>
      </div>

      <div style={{ ...cs }}>
        <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>📜 Price History Timeline</div>
        {(!data.history || data.history.length === 0) ? <EmptyMsg text="No price changes yet." /> :
          data.history.slice().reverse().map((h: any, i: number) => (
            <div key={i} style={{ fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
              {h.field}: ₹{h.oldPrice} → ₹{h.newPrice} by {h.updatedByName} · {new Date(h.updatedAt).toLocaleString()}
            </div>
          ))}
      </div>
    </div>
  )
}

// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [data, setData] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/controls', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!data) return <EmptyMsg text="⟳ Loading controls…" />
  const c = data.controls
  const update = async (patch: any) => { await fetch(base + '/' + id + '/controls', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) }); showToast('✅ Control updated'); load(); loadParent && loadParent() }
  const pause = async () => { await fetch(base + '/' + id + '/controls/pause', { method: 'PUT', headers: authHeaders }); showToast('✅ Pause toggled'); load(); loadParent && loadParent() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14 }}>
        <Toggle on={c.isSpotlight} onChange={v => update({ isSpotlight: v })} label="✨ Spotlight" />
        <Toggle on={c.isBundle} onChange={v => update({ isBundle: v })} label="📦 Bundle" />
        <Toggle on={c.allowFreeTrial} onChange={v => update({ allowFreeTrial: v })} label="🆓 Free Trial" />
      </div>
      <div style={cs}>
        <label style={lbl}>Series Status Manager</label>
        <select style={inp} value={c.lifecycleStatus} onChange={e => update({ lifecycleStatus: e.target.value })}>
          {['draft', 'active', 'upcoming', 'paused', 'archived'].map(x => <option key={x}>{x}</option>)}
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Enrollment Lock / Access Policy</label>
        <select style={{ ...inp, marginBottom: 8 }} value={c.enrollmentRule} onChange={e => update({ enrollmentRule: e.target.value })}>
          <option value="open">Open Enrollment</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="auto_approval">Auto-Approval</option>
        </select>
        <select style={inp} value={c.accessPolicy} onChange={e => update({ accessPolicy: e.target.value })}>
          <option value="open">Open Access</option><option value="invite_only">Invite Only</option><option value="manual_approval">Manual Approval</option><option value="code_based">Code-Based Join</option>
        </select>
      </div>
      <div style={cs}>
        <label style={lbl}>Seat Limit</label>
        <input style={inp} type="number" value={c.seatLimit} onChange={e => update({ seatLimit: e.target.value })} />
      </div>
      <button style={bd} onClick={pause}>{c.lifecycleStatus === 'paused' ? '▶️ Resume Series (One-Click)' : '⏸️ One-Click Pause'}</button>
      {data.snapshot && <div style={{ fontSize: 11, color: DIM, marginTop: 10 }}>Last applied by {data.snapshot.appliedBy} at {new Date(data.snapshot.appliedAt).toLocaleString()}</div>}
    </div>
  )
}

// ── 11) MATERIALS TAB ──
function MaterialsTab({ base, authHeaders, id, showToast }: any) {
  const [materials, setMaterials] = useState<any[]>([])
  const [form, setForm] = useState<any>({ title: '', type: 'pdf', url: '', category: 'General' })
  const load = useCallback(() => fetch(base + '/' + id + '/materials', { headers: authHeaders }).then(r => r.json()).then(d => setMaterials(d.materials || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const add = async () => { if (!form.title) return showToast('⚠️ Title required'); await fetch(base + '/' + id + '/materials', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) }); showToast('✅ Material added'); setForm({ title: '', type: 'pdf', url: '', category: 'General' }); load() }
  const pin = async (mid: string, pinned: boolean) => { await fetch(base + '/' + id + '/materials/' + mid, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ pinned: !pinned }) }); load() }
  const del = async (mid: string) => { if (!window.confirm('Delete material?')) return; await fetch(base + '/' + id + '/materials/' + mid, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8 }}>
        <input style={inp} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>{['pdf', 'video', 'doc', 'link', 'image', 'other'].map(x => <option key={x}>{x}</option>)}</select>
        <input style={inp} placeholder="URL" value={form.url} onChange={e => setForm({ ...form, url: e.target.value })} />
        <input style={inp} placeholder="Category" value={form.category} onChange={e => setForm({ ...form, category: e.target.value })} />
        <button style={bp} onClick={add}>⬆️ Upload</button>
      </div>
      {materials.length === 0 ? <EmptyMsg text="No materials uploaded yet." /> : materials.map(m => (
        <div key={m._id} style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{m.pinned ? '📌 ' : ''}{m.title} <span style={{ fontSize: 10, color: DIM }}>v{m.version}</span></div>
            <div style={{ fontSize: 10, color: DIM }}>{m.type} · {m.subject} {m.expiryDate ? '· expires ' + new Date(m.expiryDate).toLocaleDateString() : ''}</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={bs} onClick={() => pin(m._id, m.pinned)}>{m.pinned ? 'Unpin' : 'Pin'}</button>
            <button style={bd} onClick={() => del(m._id)}>Delete</button>
          </div>
        </div>
      ))}
    </div>
  )
}

// ── 12) ANALYTICS TAB ──
function AnalyticsTab({ base, authHeaders, id, allSeries }: any) {
  const [data, setData] = useState<any>(null)
  const [compareWith, setCompareWith] = useState('')
  const [cmp, setCmp] = useState<any>(null)
  useEffect(() => { fetch(base + '/' + id + '/analytics', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}) }, [])
  const runCompare = async () => { if (!compareWith) return; const d = await fetch(base + '/' + id + '/analytics/compare?withId=' + compareWith, { headers: authHeaders }).then(r => r.json()); setCmp(d) }
  if (!data) return <EmptyMsg text="⟳ Loading analytics…" />
  const a = data.analytics
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))', gap: 10 }}>
        {[['Health Score', a.healthScore, ACC], ['Active Users', a.activeUsers, '#7DD3FC'], ['Test Participation', a.testParticipation, '#6EE7B7'],
        ['Avg Score', a.avgScore ?? '—', '#FDE68A'], ['Revenue', '₹' + a.revenueSummary, GOOD], ['Seat Util %', a.seatUtilization ?? '∞', WARN],
        ['Engagement Trend', a.engagementTrend + '%', ACC], ['Revenue/Seat', '₹' + a.revenuePerSeat, '#A78BFA'], ['Churn Trend', a.churnTrend, BAD]].map(([l, v, c]: any) => (
          <div key={l} style={{ ...cs, marginBottom: 0, textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 800, color: c }}>{v}</div><div style={{ fontSize: 9.5, color: DIM }}>{l}</div></div>
        ))}
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🔻 Conversion Funnel</div>
        <div style={{ fontSize: 12, color: DIM }}>Views: {a.conversionFunnel?.views} → Wishlisted: {a.conversionFunnel?.wishlisted} → Enrolled: {a.conversionFunnel?.enrolled}</div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>⚖️ Series Comparison</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <select style={inp} value={compareWith} onChange={e => setCompareWith(e.target.value)}>
            <option value="">Select series to compare…</option>
            {(allSeries || []).filter((b: any) => b._id !== id).map((b: any) => <option key={b._id} value={b._id}>{b.name}</option>)}
          </select>
          <button style={bs} onClick={runCompare}>Compare</button>
        </div>
        {cmp && <div style={{ fontSize: 12, color: DIM, marginTop: 8 }}>{cmp.a?.name}: {cmp.a?.studentCount} students, ₹{cmp.a?.revenue} vs {cmp.b?.name}: {cmp.b?.studentCount} students, ₹{cmp.b?.revenue}</div>}
      </div>
    </div>
  )
}

// ── 13) ANNOUNCEMENTS TAB ──
function AnnouncementsTab({ base, authHeaders, id, showToast }: any) {
  const [list, setList] = useState<any[]>([])
  const [form, setForm] = useState({ title: '', message: '', urgent: false, scheduledAt: '' })
  const load = useCallback(() => fetch(base + '/' + id + '/announcements', { headers: authHeaders }).then(r => r.json()).then(d => setList(d.announcements || [])).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  const send = async () => {
    if (!form.message) return showToast('⚠️ Message required')
    const r = await fetch(base + '/' + id + '/announcements', { method: 'POST', headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    showToast(`✅ Sent to ${d.notified || 0} students`)
    setForm({ title: '', message: '', urgent: false, scheduledAt: '' }); load()
  }
  return (
    <div>
      <div style={cs}>
        <input style={{ ...inp, marginBottom: 8 }} placeholder="Title" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
        <textarea style={{ ...inp, minHeight: 70, marginBottom: 8 }} placeholder="Message" value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} />
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <Toggle on={form.urgent} onChange={v => setForm({ ...form, urgent: v })} label="🚨 Urgent" />
          <input style={{ ...inp, width: 200 }} type="datetime-local" value={form.scheduledAt} onChange={e => setForm({ ...form, scheduledAt: e.target.value })} />
          <button style={bp} onClick={send}>📢 Send / Schedule</button>
        </div>
      </div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>History</div>
        {list.length === 0 ? <EmptyMsg text="No announcements sent yet." /> : list.map((a: any) => (
          <div key={a._id} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{a.urgent ? '🚨 ' : ''}{a.title}</div>
            <div style={{ color: DIM, fontSize: 11 }}>{a.message}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const save = async () => { await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) }); showToast('✅ Settings saved'); load(); loadParent && loadParent() }
  const toggleLock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); load() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Series Name</label><input style={inp} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Color / Icon</label><input style={inp} value={s.colorIcon} onChange={e => setS({ ...s, colorIcon: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
        <div><label style={lbl}>Teacher / Faculty</label><input style={inp} value={s.teacherAssigned} onChange={e => setS({ ...s, teacherAssigned: e.target.value })} /></div>
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        <button style={bp} onClick={save}>💾 Save Settings</button>
        <button style={bs} onClick={toggleLock}>{s.isLocked ? '🔓 Unlock Series' : '🔒 Lock Series'}</button>
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

// ── 15) AUDIT HISTORY TAB ──
function AuditTab({ base, authHeaders, id }: any) {
  const [audit, setAudit] = useState<any[]>([])
  useEffect(() => { fetch(base + '/' + id + '/audit', { headers: authHeaders }).then(r => r.json()).then(d => setAudit(d.audit || [])).catch(() => {}) }, [])
  return (
    <div style={cs}>
      {audit.length === 0 ? <EmptyMsg text="No audit records yet." /> : audit.map((a, i) => (
        <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}`, fontSize: 11.5 }}>
          <div style={{ color: TS, fontWeight: 600 }}>{a.action} — {a.field}</div>
          <div style={{ color: DIM }}>Old: {JSON.stringify(a.oldValue)} → New: {JSON.stringify(a.newValue)}</div>
          <div style={{ color: DIM, fontSize: 10 }}>{a.changedByName} · {new Date(a.timestamp).toLocaleString()}</div>
        </div>
      ))}
    </div>
  )
}
PRVRNK_EOF_MARKER
  echo "✅ TestSeriesManagerUltra.tsx updated (EMI removed)"
else echo "ℹ️  TestSeriesManagerUltra.tsx not found — skipping (FPR2 may not be installed)"; fi

# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — EMI REMOVAL (FRONTEND)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ EMI REMOVAL — FRONTEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
PASS=0; FAIL=0
checkAbsent() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if [ ! -f "$FILE" ]; then echo "⏭️  $DESC (file not present — skipped)"; return; fi
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  else
    echo "✅ $DESC"; PASS=$((PASS+1))
  fi
}
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if [ ! -f "$FILE" ]; then echo "⏭️  $DESC (file not present — skipped)"; return; fi
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

checkAbsent "1) Batches & Test Series page — all EMI references removed" "EMI" "$TS_DIR/page.tsx"
check       "2) Payment checkout modal preserved (renamed EMIModal → PaymentModal)" "function PaymentModal" "$TS_DIR/page.tsx"
check       "3) Full-amount payment (Razorpay) flow still intact"          "handlePayFull" "$TS_DIR/page.tsx"
checkAbsent "4) batch-controls/page.tsx — all EMI references removed"      "EMI" "$BC_DIR/page.tsx"
checkAbsent "5) BatchManagerUltra.tsx — all EMI references removed"        "EMI" "$ADMIN_DIR/BatchManagerUltra.tsx"
checkAbsent "6) TestSeriesManagerUltra.tsx — all EMI references removed"   "EMI" "$ADMIN_DIR/TestSeriesManagerUltra.tsx"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 EMI FEATURE FULLY REMOVED FROM FRONTEND ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🧹 Backups saved as *.bak_emirm next to originals."
echo "👉 Next: Restart Next.js dev server / redeploy and verify EMI is gone everywhere (student marketplace, admin batch/series managers, batch-controls page)."
