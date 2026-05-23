#!/bin/bash
echo "=== Part-03: My Batches Page ==="

# ── STEP 1: Extend Backend ──
cat > ~/workspace/src/routes/myBatches.js << 'ROUTEOF'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const Batch=require('../models/Batch');
const User=require('../models/User');
const jwt=require('jsonwebtoken');
const JWT=process.env.JWT_SECRET||'proverank_jwt_super_secret_key_2024';

const auth=(req,res,next)=>{
  const h=req.headers.authorization;
  if(!h||!h.startsWith('Bearer '))return res.status(401).json({error:'Unauthorized'});
  try{req.user=jwt.verify(h.split(' ')[1],JWT);next();}
  catch(e){res.status(401).json({error:'Invalid token'});}
};

// Enrollment meta schema (stored in user doc)
// enrolledBatchesMeta: [{batchId, enrolledAt, expiresAt, progress, testsCompleted, lastAccessedAt, streak, streakLastDate, avgScore, bestRank}]

// GET /api/my-batches — all enrolled batches with meta
router.get('/',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=(user?.enrolledBatches||[]);
    const meta=user?.enrolledBatchesMeta||[];
    const batches=await Batch.find({_id:{$in:ids},status:'active'}).lean();
    const now=new Date();
    const result=batches.map(b=>{
      const m=meta.find(x=>x.batchId?.toString()===b._id.toString())||{};
      const enrolledAt=m.enrolledAt?new Date(m.enrolledAt):new Date();
      const validityDays=b.validity||365;
      const expiresAt=m.expiresAt?new Date(m.expiresAt):new Date(enrolledAt.getTime()+validityDays*86400000);
      const daysLeft=Math.max(0,Math.ceil((expiresAt-now)/86400000));
      const testsCompleted=m.testsCompleted||0;
      const totalTests=b.totalTests||0;
      const progress=totalTests>0?Math.round((testsCompleted/totalTests)*100):0;
      const lastAccessedAt=m.lastAccessedAt?new Date(m.lastAccessedAt):enrolledAt;
      const daysSinceAccess=Math.floor((now-lastAccessedAt)/86400000);
      const streak=m.streak||0;
      return{
        ...b, enrolledAt, expiresAt, daysLeft, testsCompleted, totalTests,
        progress, lastAccessedAt, daysSinceAccess, streak,
        avgScore:m.avgScore||0, bestRank:m.bestRank||null,
        isExpiring:daysLeft<=7&&daysLeft>0, isExpired:daysLeft===0,
        isCompleted:progress>=100,
      };
    });
    // Sort: last accessed first
    result.sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime());
    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/my-batches/stats — summary stats
router.get('/stats',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=user?.enrolledBatchesMeta||[];
    const ids=user?.enrolledBatches||[];
    const total=ids.length;
    const testsCompleted=meta.reduce((s,m)=>s+(m.testsCompleted||0),0);
    const now=new Date();
    const activeBatches=meta.filter(m=>{
      if(!m.expiresAt)return true;
      return new Date(m.expiresAt)>now;
    }).length;
    const certificates=meta.filter(m=>(m.testsCompleted||0)>=(m.totalTests||1)&&m.totalTests>0).length;
    res.json({total,testsCompleted,activeBatches,certificates});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/:id/access — update last accessed + streak
router.post('/:id/access',auth,async(req,res)=>{
  try{
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const idx=meta.findIndex(m=>m.batchId?.toString()===req.params.id);
    const now=new Date();
    const today=now.toDateString();
    if(idx>=0){
      const last=meta[idx].streakLastDate?new Date(meta[idx].streakLastDate).toDateString():null;
      const yesterday=new Date(now-86400000).toDateString();
      if(last===today){/* same day, no streak change */}
      else if(last===yesterday){meta[idx].streak=(meta[idx].streak||0)+1;}
      else{meta[idx].streak=1;}
      meta[idx].streakLastDate=now;
      meta[idx].lastAccessedAt=now;
    }else{
      meta.push({batchId:req.params.id,enrolledAt:now,streak:1,streakLastDate:now,lastAccessedAt:now,testsCompleted:0,avgScore:0});
    }
    await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    res.json({success:true,streak:idx>=0?meta[idx].streak:1});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/enroll-meta — store enrollment meta when enrolling
router.post('/enroll-meta',auth,async(req,res)=>{
  try{
    const{batchId,validity=365}=req.body;
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const exists=meta.find(m=>m.batchId?.toString()===batchId);
    if(!exists){
      const now=new Date();
      const expiresAt=new Date(now.getTime()+validity*86400000);
      meta.push({batchId,enrolledAt:now,expiresAt,streak:0,testsCompleted:0,avgScore:0,bestRank:null,lastAccessedAt:now});
      await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    }
    res.json({success:true});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/wishlist — wishlist batches (separate from test-series wishlist UI)
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

module.exports=router;
ROUTEOF

echo "✅ Backend route created"

# Mount route
node << 'NODEEOF'
const fs=require('fs');
const fp=process.env.HOME+'/workspace/src/index.js';
let c=fs.readFileSync(fp,'utf8');
if(!c.includes('myBatches')){
  c=c.replace(
    "const bannerGeneratorRoutes",
    "const myBatchesRoutes=require('./routes/myBatches');\nconst bannerGeneratorRoutes"
  );
  c=c.replace(
    "app.use('/api/admin/banners'",
    "app.use('/api/my-batches',myBatchesRoutes);\napp.use('/api/admin/banners'"
  );
  fs.writeFileSync(fp,c);
  console.log('✅ myBatches route mounted');
}else{console.log('✅ Already mounted');}
NODEEOF

# ── STEP 2: Add to StudentShell ──
node << 'NODEEOF2'
const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/src/components/StudentShell.tsx';
let c=fs.readFileSync(fp,'utf8');
if(!c.includes("'my-batches'")){
  c=c.replace(
    "{id:'test-series'",
    "{id:'my-batches',icon:'📚',en:'My Batches',hi:'मेरे बैच',href:'/dashboard/my-batches'},{id:'test-series'"
  );
  fs.writeFileSync(fp,c);
  console.log('✅ My Batches added to StudentShell');
}else{console.log('✅ Already in StudentShell');}
NODEEOF2

# ── STEP 3: Create Page ──
mkdir -p ~/workspace/frontend/app/dashboard/my-batches
cat > ~/workspace/frontend/app/dashboard/my-batches/page.tsx << 'EOF'
'use client'
import{useState,useEffect,useCallback}from'react'
import{useRouter}from'next/navigation'

const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'

type BatchMeta={
  _id:string;name:string;examType:string;thumbnail:string;description:string;
  enrolledAt:string;expiresAt:string;daysLeft:number;
  testsCompleted:number;totalTests:number;progress:number;
  lastAccessedAt:string;daysSinceAccess:number;
  streak:number;avgScore:number;bestRank:number|null;
  isExpiring:boolean;isExpired:boolean;isCompleted:boolean;
  isFree:boolean;batchType:string;language:string;
  rating:number;enrolledCount:number;
}
type Stats={total:number;testsCompleted:number;activeBatches:number;certificates:number}

const ECOLS:Record<string,string>={NEET:'#4D9FFF',JEE:'#9B59B6',CUET:'#27AE60','Class 11':'#E67E22','Class 12':'#E74C3C',Foundation:'#00D4FF','Crash Course':'#FF6B6B',Other:'#7F8C8D'}

// ── Circular Progress Ring ──
function ProgressRing({pct,size=56,stroke=5,color='#4D9FFF'}:{pct:number;size?:number;stroke?:number;color?:string}){
  const r=(size-stroke*2)/2
  const circ=2*Math.PI*r
  const offset=circ-(pct/100)*circ
  return(
    <svg width={size} height={size} style={{transform:'rotate(-90deg)',flexShrink:0}}>
      <circle cx={size/2} cy={size/2} r={r} stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} fill="none"/>
      <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
        strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"
        style={{transition:'stroke-dashoffset 1s ease'}}/>
      <text x="50%" y="50%" dominantBaseline="middle" textAnchor="middle"
        style={{fill:'#F0F8FF',fontSize:size*0.22,fontWeight:700,fontFamily:'Inter,sans-serif',transform:'rotate(90deg)',transformOrigin:'center'}}>
        {pct}%
      </text>
    </svg>
  )
}

// ── Streak Badge ──
function StreakBadge({n}:{n:number}){
  if(n===0)return null
  return(
    <div style={{display:'flex',alignItems:'center',gap:4,background:'rgba(255,107,107,0.12)',border:'1px solid rgba(255,107,107,0.25)',borderRadius:20,padding:'3px 10px'}}>
      <span style={{fontSize:13}}>🔥</span>
      <span style={{fontSize:11,fontWeight:700,color:'#FF6B6B'}}>{n}-day streak</span>
    </div>
  )
}

// ── Empty State ──
function EmptyState({tab,router}:{tab:string;router:ReturnType<typeof useRouter>}){
  return(
    <div style={{textAlign:'center',padding:'55px 20px',animation:'slideUp 0.6s ease'}}>
      <div style={{fontSize:80,marginBottom:18,display:'inline-block',animation:'floatBob 3s ease infinite'}}>
        {tab==='active'?'📚':tab==='completed'?'🏆':'❤️'}
      </div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:10}}>
        {tab==='active'?'No Active Batches Yet':tab==='completed'?'No Completed Batches':'Wishlist is Empty'}
      </div>
      <div style={{fontSize:13,color:'rgba(160,200,240,0.65)',maxWidth:360,margin:'0 auto 28px',lineHeight:1.8}}>
        {tab==='active'?'Your learning journey starts here! Enroll in a batch to begin your preparation.':
         tab==='completed'?'Complete a batch to earn certificates and see them here.':
         'Save batches you like to your wishlist from the Test Series page.'}
      </div>
      {tab==='active'&&(
        <button onClick={()=>router.push('/dashboard/test-series')}
          style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:14,padding:'13px 32px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 24px rgba(77,159,255,0.35)'}}>
          🚀 Explore Batches
        </button>
      )}
    </div>
  )
}

// ── Batch Card ──
function BatchCard({b,onAccess}:{b:BatchMeta;onAccess:(id:string)=>void}){
  const router=useRouter()
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const [hov,setHov]=useState(false)
  const lastStr=b.daysSinceAccess===0?'Today':b.daysSinceAccess===1?'Yesterday':`${b.daysSinceAccess} days ago`

  return(
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)}
      style={{background:'rgba(4,12,30,0.95)',border:`1px solid ${hov?ec+'55':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',transition:'all 0.3s',transform:hov?'translateY(-4px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)',position:'relative'}}>

      {/* Expiry Warning */}
      {b.isExpiring&&!b.isExpired&&(
        <div style={{background:'linear-gradient(135deg,rgba(230,126,34,0.95),rgba(195,88,0,0.95))',padding:'6px 14px',display:'flex',alignItems:'center',gap:8,justifyContent:'space-between'}}>
          <span style={{fontSize:11,fontWeight:700,color:'#fff'}}>⚠️ Expires in {b.daysLeft} day{b.daysLeft!==1?'s':''}</span>
          <button style={{background:'rgba(255,255,255,0.2)',border:'1px solid rgba(255,255,255,0.4)',borderRadius:8,padding:'3px 10px',color:'#fff',fontSize:10,fontWeight:700,cursor:'pointer'}}>Renew?</button>
        </div>
      )}
      {b.isExpired&&(
        <div style={{background:'rgba(231,76,60,0.9)',padding:'6px 14px',textAlign:'center'}}>
          <span style={{fontSize:11,fontWeight:700,color:'#fff'}}>❌ Batch Expired — Renew to continue</span>
        </div>
      )}
      {b.isCompleted&&(
        <div style={{background:'linear-gradient(135deg,rgba(39,174,96,0.95),rgba(27,120,66,0.95))',padding:'6px 14px',display:'flex',alignItems:'center',gap:8,justifyContent:'space-between'}}>
          <span style={{fontSize:11,fontWeight:700,color:'#fff'}}>🏆 Batch Completed!</span>
          <button style={{background:'rgba(255,255,255,0.2)',border:'1px solid rgba(255,255,255,0.4)',borderRadius:8,padding:'3px 10px',color:'#fff',fontSize:10,fontWeight:700,cursor:'pointer'}}
            onClick={()=>router.push('/dashboard/certificate')}>
            📜 Certificate
          </button>
        </div>
      )}

      {/* Thumbnail */}
      <div style={{height:120,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}15,${ec}06,rgba(2,8,22,0.9))`,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden'}}>
        <div style={{position:'absolute',inset:0,background:'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))',zIndex:1}}/>
        {!b.thumbnail&&<span style={{fontSize:42,filter:`drop-shadow(0 0 14px ${ec})`,zIndex:2,opacity:0.85}}>{b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':b.examType==='CUET'?'📖':b.examType==='Crash Course'?'🚀':'📚'}</span>}
        {/* Progress Ring overlay */}
        <div style={{position:'absolute',bottom:10,right:12,zIndex:3}}>
          <ProgressRing pct={b.progress} size={52} stroke={4} color={ec}/>
        </div>
      </div>

      {/* Body */}
      <div style={{padding:'14px 15px 16px'}}>
        {/* Badges row */}
        <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:8,alignItems:'center'}}>
          <span style={{background:`${ec}18`,color:ec,fontSize:9,fontWeight:700,padding:'3px 9px',borderRadius:20,border:`1px solid ${ec}28`}}>{b.examType}</span>
          <span style={{background:'rgba(255,255,255,0.05)',color:'rgba(255,255,255,0.4)',fontSize:9,padding:'3px 8px',borderRadius:20}}>{b.batchType}</span>
          <StreakBadge n={b.streak}/>
        </div>

        {/* Name */}
        <div style={{fontSize:14,fontWeight:700,color:'#F0F8FF',marginBottom:5,fontFamily:'Playfair Display,serif',lineHeight:1.4,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical'}}>{b.name}</div>

        {/* Progress bar */}
        <div style={{marginBottom:10}}>
          <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>
            <span style={{fontSize:10,color:'rgba(180,210,240,0.55)'}}>Tests: {b.testsCompleted}/{b.totalTests}</span>
            <span style={{fontSize:10,color:ec,fontWeight:700}}>{b.progress}% done</span>
          </div>
          <div style={{height:5,background:'rgba(255,255,255,0.07)',borderRadius:3,overflow:'hidden'}}>
            <div style={{height:'100%',width:`${b.progress}%`,background:`linear-gradient(90deg,${ec},${ec}BB)`,borderRadius:3,transition:'width 1s ease'}}/>
          </div>
        </div>

        {/* Stats chips */}
        <div style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:12}}>
          {b.avgScore>0&&<span style={{fontSize:10,color:'rgba(180,210,240,0.5)'}}>📊 Avg: {b.avgScore}%</span>}
          {b.bestRank&&<span style={{fontSize:10,color:'rgba(180,210,240,0.5)'}}>🏆 Rank: #{b.bestRank}</span>}
          <span style={{fontSize:10,color:'rgba(180,210,240,0.5)'}}>🕐 {lastStr}</span>
          {!b.isExpired&&<span style={{fontSize:10,color:b.daysLeft<=7?'#E67E22':'rgba(180,210,240,0.5)'}}>📅 {b.daysLeft}d left</span>}
        </div>

        {/* Enrollment + Expiry */}
        <div style={{display:'flex',gap:8,marginBottom:12,flexWrap:'wrap'}}>
          <span style={{fontSize:10,color:'rgba(160,200,240,0.4)'}}>Enrolled: {new Date(b.enrolledAt).toLocaleDateString()}</span>
          <span style={{fontSize:10,color:'rgba(160,200,240,0.4)'}}>Expires: {new Date(b.expiresAt).toLocaleDateString()}</span>
        </div>

        {/* Mini Leaderboard widget */}
        {b.bestRank&&(
          <div style={{background:`${ec}0A`,border:`1px solid ${ec}20`,borderRadius:10,padding:'8px 12px',marginBottom:12,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
            <span style={{fontSize:11,color:ec,fontWeight:600}}>🏅 Your Rank: #{b.bestRank} of {b.enrolledCount.toLocaleString()}</span>
            <button onClick={()=>router.push('/dashboard/leaderboard')} style={{background:'transparent',border:'none',color:ec,fontSize:10,cursor:'pointer',fontWeight:600}}>View →</button>
          </div>
        )}

        {/* CTA */}
        {b.isCompleted?(
          <button onClick={()=>router.push('/dashboard/certificate')}
            style={{width:'100%',padding:'11px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:'0 4px 16px rgba(39,174,96,0.3)'}}>
            📜 Download Certificate
          </button>
        ):(
          <button onClick={()=>{onAccess(b._id);router.push('/dashboard/exams')}}
            style={{width:'100%',padding:'11px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:`0 4px 16px ${ec}35`,display:'flex',alignItems:'center',justifyContent:'center',gap:8}}>
            <span>Continue Learning</span><span>→</span>
          </button>
        )}
      </div>
    </div>
  )
}

// ── Main Page ──
export default function MyBatchesPage(){
  const router=useRouter()
  const[tab,setTab]=useState<'active'|'completed'|'wishlist'>('active')
  const[batches,setBatches]=useState<BatchMeta[]>([])
  const[wishlist,setWishlist]=useState<BatchMeta[]>([])
  const[stats,setStats]=useState<Stats>({total:0,testsCompleted:0,activeBatches:0,certificates:0})
  const[loading,setLoading]=useState(true)
  const[tok,setTok]=useState('')

  useEffect(()=>{
    const t=localStorage.getItem('pr_token')||''
    setTok(t);fetchAll(t)
  },[])

  const fetchAll=async(t:string)=>{
    setLoading(true)
    try{
      const[bRes,sRes,wRes]=await Promise.all([
        fetch(`${API}/api/my-batches`,{headers:{Authorization:`Bearer ${t}`}}),
        fetch(`${API}/api/my-batches/stats`,{headers:{Authorization:`Bearer ${t}`}}),
        fetch(`${API}/api/my-batches/wishlist`,{headers:{Authorization:`Bearer ${t}`}}),
      ])
      const bd=await bRes.json();const sd=await sRes.json();const wd=await wRes.json()
      setBatches(bd.batches||[]);setStats(sd);setWishlist(wd.batches||[])
    }catch{setBatches([])}finally{setLoading(false)}
  }

  const handleAccess=async(id:string)=>{
    if(!tok)return
    await fetch(`${API}/api/my-batches/${id}/access`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
  }

  const activeBatches=batches.filter(b=>!b.isExpired&&!b.isCompleted)
  const completedBatches=batches.filter(b=>b.isCompleted||b.isExpired)
  const lastAccessed=activeBatches[0]||null
  const displayList=tab==='active'?activeBatches:tab==='completed'?completedBatches:wishlist as unknown as BatchMeta[]

  const C={blue:'#4D9FFF',cyan:'#00D4FF',text:'#F0F8FF',sub:'rgba(160,200,240,0.6)',border:'rgba(77,159,255,0.18)'}

  return(
    <div style={{minHeight:'100vh',color:C.text,fontFamily:'Inter,sans-serif',position:'relative',background:'transparent'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes progressFill{from{width:0}to{width:100%}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{position:'sticky',top:0,zIndex:50,background:'rgba(2,8,22,0.94)',backdropFilter:'blur(22px)',borderBottom:`1px solid ${C.border}`,padding:'10px 14px',display:'flex',alignItems:'center',gap:10}}>
        <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:C.blue,fontSize:20,flexShrink:0}}
          onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
          onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>←</button>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>My Batches</div>
          <div style={{fontSize:10,color:'rgba(160,200,240,0.42)'}}>Your enrolled test series</div>
        </div>
        <div style={{flex:1}}/>
        <button onClick={()=>router.push('/dashboard/test-series')}
          style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,padding:'8px 14px',color:'#fff',fontSize:11,fontWeight:700,cursor:'pointer'}}>
          + Explore
        </button>
      </div>

      <div style={{position:'relative',zIndex:2,padding:'14px 14px 80px',maxWidth:1100,margin:'0 auto'}}>

        {/* STATS BAR */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(110px,1fr))',gap:10,marginBottom:18,animation:'slideUp 0.4s ease'}}>
          {[
            {i:'📚',v:stats.total,l:'Enrolled',c:'#4D9FFF'},
            {i:'✅',v:stats.testsCompleted,l:'Tests Done',c:'#27AE60'},
            {i:'🟢',v:stats.activeBatches,l:'Active',c:'#00D4FF'},
            {i:'🏆',v:stats.certificates,l:'Certificates',c:'#FFD700'},
          ].map((s,i)=>(
            <div key={i} style={{background:'rgba(4,12,30,0.92)',border:`1px solid ${s.c}22`,borderRadius:16,padding:'14px 12px',textAlign:'center',backdropFilter:'blur(16px)',animation:`slideUp ${0.4+i*0.08}s ease`}}>
              <div style={{fontSize:22,marginBottom:4}}>{s.i}</div>
              <div style={{fontSize:22,fontWeight:800,color:s.c,fontFamily:'Playfair Display,serif'}}>{loading?'—':s.v}</div>
              <div style={{fontSize:10,color:C.sub}}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* CONTINUE WHERE YOU LEFT OFF */}
        {lastAccessed&&!loading&&(
          <div style={{background:'linear-gradient(135deg,rgba(4,12,30,0.97),rgba(8,18,45,0.97))',border:'1px solid rgba(77,159,255,0.25)',borderRadius:20,padding:'18px 18px',marginBottom:18,backdropFilter:'blur(22px)',boxShadow:'0 8px 40px rgba(77,159,255,0.08)',position:'relative',overflow:'hidden',animation:'slideUp 0.5s ease'}}>
            <div style={{position:'absolute',top:-20,right:-20,width:120,height:120,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.08),transparent)',pointerEvents:'none'}}/>
            <div style={{fontSize:11,fontWeight:700,color:'rgba(160,200,240,0.5)',textTransform:'uppercase',letterSpacing:1,marginBottom:10}}>▶ Continue Where You Left Off</div>
            <div style={{display:'flex',alignItems:'center',gap:14,flexWrap:'wrap'}}>
              <div style={{width:48,height:48,borderRadius:12,background:lastAccessed.thumbnail?`url(${lastAccessed.thumbnail}) center/cover`:`linear-gradient(135deg,${ECOLS[lastAccessed.examType]||'#4D9FFF'}25,rgba(2,8,22,0.8))`,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,fontSize:24}}>
                {!lastAccessed.thumbnail&&(lastAccessed.examType==='NEET'?'🩺':lastAccessed.examType==='JEE'?'⚙️':'📚')}
              </div>
              <div style={{flex:1,minWidth:120}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:C.text,marginBottom:3,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis'}}>{lastAccessed.name}</div>
                <div style={{display:'flex',gap:8,alignItems:'center',flexWrap:'wrap'}}>
                  <span style={{fontSize:11,color:C.sub}}>{lastAccessed.progress}% complete</span>
                  <span style={{fontSize:11,color:C.sub}}>·</span>
                  <span style={{fontSize:11,color:C.sub}}>Last: {lastAccessed.daysSinceAccess===0?'Today':lastAccessed.daysSinceAccess===1?'Yesterday':`${lastAccessed.daysSinceAccess}d ago`}</span>
                  {lastAccessed.streak>0&&<span style={{fontSize:11,color:'#FF6B6B'}}>🔥 {lastAccessed.streak} streak</span>}
                </div>
                <div style={{height:4,background:'rgba(255,255,255,0.07)',borderRadius:2,marginTop:6,overflow:'hidden'}}>
                  <div style={{height:'100%',width:`${lastAccessed.progress}%`,background:`linear-gradient(90deg,${ECOLS[lastAccessed.examType]||'#4D9FFF'},#00D4FF)`,borderRadius:2}}/>
                </div>
              </div>
              <button onClick={()=>{handleAccess(lastAccessed._id);router.push('/dashboard/exams')}}
                style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'10px 20px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:'0 4px 18px rgba(77,159,255,0.35)',flexShrink:0,whiteSpace:'nowrap'}}>
                Resume →
              </button>
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8,marginBottom:16}}>
          {(['active','completed','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{padding:'10px',borderRadius:13,background:tab===t?'rgba(77,159,255,0.14)':'rgba(4,12,30,0.8)',border:`1px solid ${tab===t?'rgba(77,159,255,0.38)':'rgba(77,159,255,0.1)'}`,color:tab===t?'#4D9FFF':'rgba(160,200,240,0.45)',fontWeight:tab===t?700:400,cursor:'pointer',fontSize:11,backdropFilter:'blur(12px)',transition:'all 0.2s'}}>
              {t==='active'?`🟢 Active (${activeBatches.length})`:t==='completed'?`🏆 Completed (${completedBatches.length})`:`❤️ Wishlist (${wishlist.length})`}
            </button>
          ))}
        </div>

        {/* BATCH GRID */}
        {loading?(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:16}}>
            {[1,2,3].map(i=><div key={i} style={{height:380,background:'rgba(4,12,30,0.8)',borderRadius:20,animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.15}s`}}/>)}
          </div>
        ):displayList.length===0?<EmptyState tab={tab} router={router}/>:(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:16}}>
            {displayList.map((b,i)=>(
              <div key={b._id} style={{animation:`slideUp ${0.3+i*0.05}s ease both`}}>
                <BatchCard b={b} onAccess={handleAccess}/>
              </div>
            ))}
          </div>
        )}

        {/* ACTIVITY FEED (What's New) */}
        {!loading&&activeBatches.length>0&&(
          <div style={{marginTop:44,background:'rgba(4,12,30,0.95)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:20,padding:'22px 18px',backdropFilter:'blur(20px)'}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:C.text,marginBottom:16}}>📡 Batch Activity Feed</div>
            {activeBatches.map(b=>(
              <div key={b._id} style={{display:'flex',gap:12,alignItems:'flex-start',padding:'12px 0',borderBottom:'1px solid rgba(77,159,255,0.07)'}}>
                <div style={{width:36,height:36,borderRadius:10,background:`${ECOLS[b.examType]||'#4D9FFF'}18`,border:`1px solid ${ECOLS[b.examType]||'#4D9FFF'}28`,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,fontSize:18}}>
                  {b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':'📚'}
                </div>
                <div style={{flex:1}}>
                  <div style={{fontSize:13,fontWeight:600,color:C.text,marginBottom:3}}>{b.name}</div>
                  <div style={{fontSize:11,color:C.sub}}>
                    {b.testsCompleted>0?`${b.testsCompleted} tests completed · `:'No tests taken yet · '}
                    {b.streak>0?`🔥 ${b.streak}-day streak · `:''}
                    {b.daysLeft<=7?`⚠️ Expires in ${b.daysLeft} days`:`${b.daysLeft} days remaining`}
                  </div>
                </div>
                <ProgressRing pct={b.progress} size={42} stroke={3} color={ECOLS[b.examType]||'#4D9FFF'}/>
              </div>
            ))}
          </div>
        )}

        {/* STUDY TIPS */}
        <div style={{marginTop:24,background:'transparent',padding:'0 2px'}}>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:14}}>
            {[
              {i:'🧠',t:'Consistent Practice',d:'Attempt at least 1 test daily to maintain your streak and rank.',c:'#4D9FFF'},
              {i:'📊',t:'Review Mistakes',d:'Always check incorrect answers — NEET rewards understanding, not rote.',c:'#9B59B6'},
            ].map((tip,i)=>(
              <div key={i} style={{display:'flex',gap:12,alignItems:'flex-start',animation:`slideUp ${1.2+i*0.1}s ease`}}>
                <span style={{fontSize:28,filter:`drop-shadow(0 0 10px ${tip.c}80)`,flexShrink:0}}>{tip.i}</span>
                <div>
                  <div style={{fontWeight:700,color:tip.c,fontSize:12,marginBottom:4,fontFamily:'Playfair Display,serif'}}>{tip.t}</div>
                  <div style={{fontSize:11,color:'rgba(180,210,240,0.58)',lineHeight:1.65}}>{tip.d}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  )
}
EOF

echo "✅ My Batches page created"
echo "=== Git Push ==="
cd ~/workspace && git add -A && git commit -m "feat: Part-03 My Batches page — progress rings, streaks, continue section, stats, activity feed, renewal warnings, certificates" && git push origin main
echo "=== DONE ==="
