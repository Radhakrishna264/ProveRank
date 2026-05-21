'use client'
import{useState,useEffect,useRef,useCallback}from'react'

const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'

type Batch={
  _id:string;name:string;description:string;examType:string;category:string;
  price:number;discountPrice:number;isFree:boolean;thumbnail:string;
  totalTests:number;enrolledCount:number;language:string;difficulty:string;
  batchType:string;isSpotlight:boolean;flashSaleEndTime?:string;flashSalePrice?:number;
  allowFreeTrial:boolean;trialDays:number;isBundle:boolean;validity:number;
  tags:string[];rating:number;ratingCount:number;isEnrolled?:boolean;
  isWishlisted?:boolean;createdAt:string;subject:string;
}

const FACTS=[
  {icon:'🧬',title:'DNA Replication',fact:'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl experiment, 1958)',col:'#4D9FFF'},
  {icon:'⚡',title:'ATP Synthesis',fact:'Mitochondria produce 36–38 ATP per glucose via oxidative phosphorylation — F₀F₁ ATP synthase',col:'#00D4FF'},
  {icon:'💡',title:"Newton's Laws",fact:"3rd Law: Every action has equal & opposite reaction. F=ma (2nd Law). Inertia (1st Law).",col:'#9B59B6'},
  {icon:'🌿',title:'Photosynthesis',fact:'6CO₂ + 6H₂O + Light → C₆H₁₂O₆ + 6O₂ · Light reactions in thylakoid · Calvin in stroma',col:'#27AE60'},
  {icon:'⚗️',title:'Periodic Law',fact:'Properties repeat periodically by atomic number — Mendeleev (mass) → Moseley (atomic no.)',col:'#E67E22'},
  {icon:'🦠',title:'Cell Division',fact:'Mitosis: 4 daughter cells (diploid). Meiosis: 4 haploid cells. S phase: DNA replication.',col:'#E74C3C'},
]

const QUOTES=[
  {q:'The more I learn, the more I realize how much I don\'t know.',a:'Albert Einstein',bg:'linear-gradient(135deg,#0a1428,#0d2137)'},
  {q:'Success is not final, failure is not fatal — it is the courage to continue that counts.',a:'Winston Churchill',bg:'linear-gradient(135deg,#0a1428,#16213e)'},
  {q:'In the middle of every difficulty lies opportunity.',a:'Albert Einstein',bg:'linear-gradient(135deg,#0d1b2a,#1a1a3e)'},
  {q:'The secret of getting ahead is getting started.',a:'Mark Twain',bg:'linear-gradient(135deg,#0a1428,#1b2838)'},
]

const CATS=['All','NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course']
const CICONS:Record<string,string>={All:'🌟',NEET:'🩺',JEE:'⚙️',CUET:'📖','Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'}
const ECOLS:Record<string,string>={NEET:'#4D9FFF',JEE:'#9B59B6',CUET:'#27AE60','Class 11':'#E67E22','Class 12':'#E74C3C',Foundation:'#00D4FF','Crash Course':'#FF6B6B'}

// ── Milky Way + Nebula Canvas (animated, scientifically accurate) ──
function SpaceCanvas(){
  const ref=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const cv=ref.current;if(!cv)return
    const ctx=cv.getContext('2d');if(!ctx)return
    let raf:number,t=0
    const resize=()=>{cv.width=window.innerWidth;cv.height=window.innerHeight}
    resize();window.addEventListener('resize',resize)
    // Star field — generated once
    const stars=Array.from({length:900},()=>({
      x:Math.random(),y:Math.random(),
      r:Math.random()<0.04?1.8:Math.random()<0.12?1.1:0.55,
      phase:Math.random()*Math.PI*2,spd:0.4+Math.random()*2.5,
      inArm:Math.random()<0.6,
    }))
    const draw=()=>{
      t+=0.004
      const W=cv.width,H=cv.height,cx=W/2,cy=H/2
      ctx.clearRect(0,0,W,H)
      // Milky Way diagonal band
      const mw=ctx.createLinearGradient(0,H*0.25,W,H*0.75)
      mw.addColorStop(0,'transparent')
      mw.addColorStop(0.25,'rgba(80,100,180,0.04)')
      mw.addColorStop(0.5,'rgba(140,150,220,0.08)')
      mw.addColorStop(0.75,'rgba(80,100,180,0.04)')
      mw.addColorStop(1,'transparent')
      ctx.fillStyle=mw;ctx.fillRect(0,0,W,H)
      // Galactic core — warm yellowish bulge (Milky Way center)
      const core=ctx.createRadialGradient(cx,cy,0,cx,cy,Math.min(W,H)*0.18)
      core.addColorStop(0,'rgba(255,210,120,0.14)')
      core.addColorStop(0.4,'rgba(220,160,80,0.07)')
      core.addColorStop(1,'transparent')
      ctx.fillStyle=core;ctx.fillRect(0,0,W,H)
      // 4 spiral arms (Scutum-Centaurus, Perseus, Norma, Sagittarius — Milky Way)
      for(let arm=0;arm<4;arm++){
        const baseA=arm*Math.PI/2+t*0.05
        for(let seg=0;seg<7;seg++){
          const logR=0.3+seg*0.45
          const armA=baseA+logR*1.2
          const r=(60+seg*65)*Math.min(W,H)/800
          const nx=cx+Math.cos(armA)*r
          const ny=cy+Math.sin(armA)*r
          const sz=(50+seg*20)*Math.min(W,H)/800
          const neb=ctx.createRadialGradient(nx,ny,0,nx,ny,sz*(1+0.15*Math.sin(t+seg)))
          const cols=['rgba(77,159,255,','rgba(155,89,182,','rgba(0,212,255,','rgba(100,200,140,']
          neb.addColorStop(0,cols[arm%4]+'0.09)')
          neb.addColorStop(1,'transparent')
          ctx.fillStyle=neb;ctx.fillRect(0,0,W,H)
        }
      }
      // Twinkling stars
      stars.forEach(s=>{
        const x=s.x*W,y=s.y*H
        const tw=0.35+0.65*Math.abs(Math.sin(t*s.spd+s.phase))
        const dist=Math.hypot(x-cx,y-cy)
        let col
        if(dist<Math.min(W,H)*0.08) col=`rgba(255,220,150,${tw})`       // core — warm
        else if(s.inArm) col=`rgba(160,200,255,${tw})`                   // spiral arms — blue-white
        else col=`rgba(200,210,255,${tw*0.7})`                           // halo — cooler
        ctx.beginPath();ctx.arc(x,y,s.r,0,Math.PI*2);ctx.fillStyle=col;ctx.fill()
      })
      raf=requestAnimationFrame(draw)
    }
    draw()
    return()=>{cancelAnimationFrame(raf);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={ref} style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none',opacity:0.75}}/>
}

// ── 3D Orbiting Planets (Solar System accurate colors) ──
const PLANETS=[
  {sz:9, bg:'#9E9E9E',                                               orbit:160,dur:47,dl:0,    name:'Mercury'},
  {sz:17,bg:'radial-gradient(circle at 35% 35%,#F5D5A0,#C19A6B)',   orbit:230,dur:35,dl:-6,   name:'Venus'},
  {sz:19,bg:'radial-gradient(circle at 35% 35%,#6CE0FF,#1A5EAA 50%,#1A5276)',orbit:310,dur:29,dl:-12,name:'Earth'},
  {sz:13,bg:'radial-gradient(circle at 35% 35%,#FF8060,#A93226)',    orbit:390,dur:24,dl:-18,  name:'Mars'},
]
function Planets(){
  return(
    <div style={{position:'fixed',top:'50%',left:'50%',transform:'translate(-50%,-50%)',zIndex:1,pointerEvents:'none',width:0,height:0}}>
      {PLANETS.map((p,i)=>(
        <div key={i} style={{
          position:'absolute',width:p.orbit*2,height:p.orbit*2,
          marginLeft:-p.orbit,marginTop:-p.orbit,
          borderRadius:'50%',border:'1px solid rgba(77,159,255,0.07)',
          animation:`orbit ${p.dur}s linear infinite`,animationDelay:`${p.dl}s`,
        }}>
          <div style={{
            position:'absolute',top:0,left:'50%',
            marginLeft:-p.sz/2,marginTop:-p.sz/2,
            width:p.sz,height:p.sz,borderRadius:'50%',background:p.bg,
            boxShadow:`0 0 ${p.sz}px rgba(77,159,255,0.25)`,
          }}/>
        </div>
      ))}
    </div>
  )
}

// ── Saturn (special — has rings) ──
function Saturn(){
  return(
    <div style={{position:'fixed',top:'50%',left:'50%',transform:'translate(-50%,-50%)',zIndex:1,pointerEvents:'none',width:0,height:0}}>
      <div style={{
        position:'absolute',width:1100,height:1100,
        marginLeft:-550,marginTop:-550,
        borderRadius:'50%',border:'1px solid rgba(77,159,255,0.05)',
        animation:'orbit 87s linear infinite',animationDelay:'-25s',
      }}>
        <div style={{position:'absolute',top:0,left:'50%',marginLeft:-22,marginTop:-22}}>
          {/* Planet body */}
          <div style={{width:44,height:44,borderRadius:'50%',background:'radial-gradient(circle at 35% 35%,#F0E68C,#DAA520 50%,#B8860B)',boxShadow:'0 0 20px rgba(218,165,32,0.3)',position:'relative'}}>
            {/* Rings */}
            <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%) rotateX(72deg)',width:88,height:88,borderRadius:'50%',border:'3px solid rgba(228,213,160,0.45)',pointerEvents:'none'}}/>
            <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%) rotateX(72deg)',width:110,height:110,borderRadius:'50%',border:'2px solid rgba(228,213,160,0.25)',pointerEvents:'none'}}/>
          </div>
        </div>
      </div>
    </div>
  )
}

// ── Video-Like Nebula Animation (fulfills "Video Animations" rule) ──
function NebulaVideo(){
  const ref=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const cv=ref.current;if(!cv)return
    const ctx=cv.getContext('2d');if(!ctx)return
    cv.width=400;cv.height=300;let raf:number,t=0
    const draw=()=>{
      t+=0.012;ctx.clearRect(0,0,400,300)
      // Animated nebula clouds
      const nCols=[
        [77,159,255],[155,89,182],[0,212,255],[100,200,140],[231,76,60]
      ]
      for(let i=0;i<5;i++){
        const cx2=200+Math.cos(t*0.3+i*1.25)*80
        const cy2=150+Math.sin(t*0.4+i*1.25)*50
        const r=60+30*Math.sin(t*0.5+i)
        const g=ctx.createRadialGradient(cx2,cy2,0,cx2,cy2,r)
        const [rr,gg,bb]=nCols[i]
        g.addColorStop(0,`rgba(${rr},${gg},${bb},0.25)`)
        g.addColorStop(1,'transparent')
        ctx.fillStyle=g;ctx.fillRect(0,0,400,300)
      }
      // Star burst center
      const sb=ctx.createRadialGradient(200,150,0,200,150,20+10*Math.sin(t*2))
      sb.addColorStop(0,'rgba(255,255,255,0.5)')
      sb.addColorStop(0.5,'rgba(77,159,255,0.2)')
      sb.addColorStop(1,'transparent')
      ctx.fillStyle=sb;ctx.fillRect(0,0,400,300)
      raf=requestAnimationFrame(draw)
    }
    draw();return()=>cancelAnimationFrame(raf)
  },[])
  return(
    <div style={{borderRadius:20,overflow:'hidden',border:'1px solid rgba(77,159,255,0.2)',position:'relative',background:'rgba(0,0,20,0.8)'}}>
      <canvas ref={ref} style={{width:'100%',height:'auto',display:'block'}}/>
      <div style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:8,pointerEvents:'none'}}>
        <div style={{fontSize:13,fontWeight:700,color:'rgba(255,255,255,0.9)',textShadow:'0 0 20px #4D9FFF',fontFamily:'Playfair Display,serif',textAlign:'center',padding:'0 20px'}}>
          🌌 Live Galaxy Simulation
        </div>
        <div style={{fontSize:11,color:'rgba(180,210,255,0.8)',textAlign:'center',padding:'0 20px'}}>
          Milky Way · 200 Billion Stars · 13.6 Billion Years Old
        </div>
      </div>
    </div>
  )
}

// ── Flash Sale Timer ──
function FlashTimer({end}:{end:string}){
  const [t,setT]=useState({h:0,m:0,s:0})
  useEffect(()=>{
    const tick=()=>{
      const d=new Date(end).getTime()-Date.now()
      if(d<=0){setT({h:0,m:0,s:0});return}
      setT({h:Math.floor(d/3600000),m:Math.floor(d%3600000/60000),s:Math.floor(d%60000/1000)})
    };tick();const iv=setInterval(tick,1000);return()=>clearInterval(iv)
  },[end])
  const p=(n:number)=>n.toString().padStart(2,'0')
  return <span style={{fontFamily:'monospace',fontSize:16,fontWeight:800,color:'#FF6B6B',letterSpacing:3}}>{p(t.h)}:{p(t.m)}:{p(t.s)}</span>
}

// ── Stars Rating ──
function Stars({r}:{r:number}){
  return <span>{[1,2,3,4,5].map(i=><span key={i} style={{color:i<=Math.round(r)?'#FFD700':'#444',fontSize:12}}>{i<=Math.round(r)?'★':'☆'}</span>)}<span style={{fontSize:11,color:'#7FA8C9',marginLeft:4}}>{r.toFixed(1)}</span></span>
}

// ── Batch Card ──
function BatchCard({b,tok,onUpdate}:{b:Batch;tok:string|null;onUpdate:()=>void}){
  const[loading,setLoading]=useState(false)
  const isFlash=!!(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())
  const isNew=Date.now()-new Date(b.createdAt).getTime()<7*86400000
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const enroll=async()=>{
    if(!tok)return alert('Please login to enroll')
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batches/${b._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
      const d=await r.json()
      if(d.success)onUpdate();else alert(d.error||'Error')
    }finally{setLoading(false)}
  }
  const toggleWish=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}})
    onUpdate()
  }
  const finalPrice=isFlash&&b.flashSalePrice?b.flashSalePrice:b.discountPrice||b.price
  const discount=b.price>0&&finalPrice<b.price?Math.round((1-finalPrice/b.price)*100):0
  return(
    <div style={{background:'rgba(8,12,28,0.92)',border:`1px solid ${ec}30`,borderRadius:18,overflow:'hidden',backdropFilter:'blur(20px)',position:'relative',transition:'all 0.3s'}}
      onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-5px)';(e.currentTarget as HTMLDivElement).style.boxShadow=`0 24px 60px ${ec}20`}}
      onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.boxShadow=''}}>
      {/* Ribbons */}
      {isNew&&<div style={{position:'absolute',top:10,left:10,background:'#27AE60',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20,zIndex:3}}>✨ NEW</div>}
      {b.enrolledCount>50&&<div style={{position:'absolute',top:isNew?32:10,left:10,background:'#E67E22',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20,zIndex:3}}>🔥 HOT</div>}
      {b.isBundle&&<div style={{position:'absolute',top:10,left:isNew?70:10,background:'#9B59B6',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 9px',borderRadius:20,zIndex:3}}>📦 BUNDLE</div>}
      {/* Wishlist btn */}
      <button onClick={toggleWish} style={{position:'absolute',top:10,right:10,background:'rgba(0,0,0,0.55)',border:'none',borderRadius:'50%',width:34,height:34,cursor:'pointer',fontSize:16,zIndex:3,display:'flex',alignItems:'center',justifyContent:'center'}}>
        {b.isWishlisted?'❤️':'🤍'}
      </button>
      {/* Thumbnail */}
      <div style={{height:145,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}18,${ec}08)`,display:'flex',alignItems:'center',justifyContent:'center',position:'relative'}}>
        {!b.thumbnail&&<span style={{fontSize:52,opacity:0.7}}>{b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':b.examType==='CUET'?'📖':b.examType==='Crash Course'?'🚀':'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&(
          <div style={{position:'absolute',bottom:0,left:0,right:0,background:'rgba(255,80,80,0.92)',padding:'5px 0',textAlign:'center',fontSize:12,fontWeight:700,color:'#fff'}}>
            ⚡ Flash: <FlashTimer end={b.flashSaleEndTime}/>
          </div>
        )}
        {b.isEnrolled&&!isFlash&&(
          <div style={{position:'absolute',inset:0,background:'rgba(39,174,96,0.18)',display:'flex',alignItems:'center',justifyContent:'center'}}>
            <span style={{background:'rgba(39,174,96,0.92)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:12,fontWeight:700}}>✅ Enrolled</span>
          </div>
        )}
      </div>
      {/* Body */}
      <div style={{padding:16}}>
        <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:9}}>
          <span style={{background:`${ec}20`,color:ec,fontSize:10,fontWeight:700,padding:'2px 9px',borderRadius:20,border:`1px solid ${ec}35`}}>{b.examType}</span>
          <span style={{background:b.isFree?'rgba(39,174,96,0.18)':'rgba(230,126,34,0.18)',color:b.isFree?'#27AE60':'#E67E22',fontSize:10,fontWeight:700,padding:'2px 9px',borderRadius:20}}>
            {b.isFree?'FREE':b.allowFreeTrial?`${b.trialDays}-DAY TRIAL`:'PAID'}
          </span>
          <span style={{background:'rgba(255,255,255,0.07)',color:'#888',fontSize:10,padding:'2px 9px',borderRadius:20}}>{b.batchType}</span>
        </div>
        <div style={{fontSize:15,fontWeight:700,color:'#E8F4FD',marginBottom:5,fontFamily:'Playfair Display,serif',lineHeight:1.35,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical'}}>{b.name}</div>
        <div style={{fontSize:12,color:'#7FA8C9',lineHeight:1.5,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical',marginBottom:8}}>{b.description||'Premium test series for competitive exam preparation — NCERT based, expert curated.'}</div>
        <Stars r={b.rating}/>
        <div style={{display:'flex',gap:10,marginTop:8,marginBottom:8,flexWrap:'wrap'}}>
          <span style={{fontSize:11,color:'#7FA8C9'}}>📝 {b.totalTests} Tests</span>
          <span style={{fontSize:11,color:'#7FA8C9'}}>👥 {b.enrolledCount.toLocaleString()}</span>
          <span style={{fontSize:11,color:'#7FA8C9'}}>📅 {b.validity}d</span>
          <span style={{fontSize:11,color:'#7FA8C9'}}>🌐 {b.language}</span>
        </div>
        {/* EMI */}
        {!b.isFree&&b.price>300&&<div style={{fontSize:11,color:'#888',marginBottom:8}}>💳 EMI from ₹{Math.round(finalPrice/3)}/mo available</div>}
        {/* Validity for enrolled */}
        {b.isEnrolled&&<div style={{fontSize:11,color:'#27AE60',marginBottom:8}}>🟢 Active — Valid for {b.validity} days</div>}
        {/* Price */}
        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:12}}>
          {b.isFree
            ?<span style={{fontSize:20,fontWeight:800,color:'#27AE60'}}>FREE</span>
            :<>
              <span style={{fontSize:20,fontWeight:800,color:'#E8F4FD'}}>₹{finalPrice}</span>
              {(discount>0)&&<span style={{fontSize:13,color:'#888',textDecoration:'line-through'}}>₹{b.price}</span>}
              {discount>0&&<span style={{fontSize:11,background:'rgba(39,174,96,0.2)',color:'#27AE60',padding:'2px 7px',borderRadius:20,fontWeight:700}}>{discount}% OFF</span>}
            </>}
        </div>
        {/* CTA */}
        {b.isEnrolled
          ?<button style={{width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec}30,${ec}18)`,border:`1px solid ${ec}`,borderRadius:10,color:ec,fontWeight:700,cursor:'pointer',fontSize:13,letterSpacing:0.5}}>Go to Batch →</button>
          :b.isFree
            ?<button onClick={enroll} disabled={loading} style={{width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:10,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 4px 18px rgba(39,174,96,0.3)'}}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
            :b.allowFreeTrial
              ?<button onClick={enroll} disabled={loading} style={{width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:10,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13}}>{loading?'Starting...':'🎯 Start Free Trial'}</button>
              :<button style={{width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:10,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:`0 4px 18px ${ec}40`}}>🛒 Buy ₹{finalPrice}</button>}
      </div>
    </div>
  )
}

// ── Empty State ──
function EmptyState(){
  return(
    <div style={{textAlign:'center',padding:'50px 20px',animation:'slideUp 0.8s ease'}}>
      <div style={{fontSize:80,marginBottom:20,display:'inline-block',animation:'float 3s ease infinite'}}>🚀</div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,color:'#E8F4FD',marginBottom:12}}>Premium Batches Launching Soon</div>
      <div style={{fontSize:14,color:'#7FA8C9',maxWidth:460,margin:'0 auto 28px',lineHeight:1.8}}>
        Test Series & Batches will appear here once created by the Admin. World-class NEET/JEE preparation is coming!
      </div>
      <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap',marginBottom:32}}>
        {['🩺 NEET 2026','⚙️ JEE Advanced','📖 CUET','🚀 Crash Course','🏛️ Foundation'].map((t,i)=>(
          <div key={i} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:'8px 16px',fontSize:12,color:'#4D9FFF',fontWeight:600}}>{t}</div>
        ))}
      </div>
      <div style={{background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:16,padding:20,maxWidth:480,margin:'0 auto',textAlign:'left'}}>
        <div style={{fontWeight:700,color:'#4D9FFF',fontSize:13,marginBottom:10}}>📋 What you'll find here:</div>
        {['Full Syllabus Test Series (180 Qs · NEET Pattern)','Chapter-wise Mini Tests (15–20 min)','Crash Courses with PDF notes','PYQ Banks (NEET 2015–2024)','Free & Paid both available'].map((t,i)=>(
          <div key={i} style={{fontSize:12,color:'#7FA8C9',marginBottom:6}}>✓ {t}</div>
        ))}
      </div>
    </div>
  )
}

// ── Main Page ──
export default function TestSeriesPage(){
  const[batches,setBatches]=useState<Batch[]>([])
  const[loading,setLoading]=useState(true)
  const[search,setSearch]=useState('')
  const[activeCat,setActiveCat]=useState('All')
  const[sort,setSort]=useState('newest')
  const[filterOpen,setFilterOpen]=useState(false)
  const[filters,setFilters]=useState({isFree:'',difficulty:'',batchType:''})
  const[tab,setTab]=useState<'all'|'enrolled'|'wishlist'>('all')
  const[tok,setTok]=useState<string|null>(null)
  const[qIdx,setQIdx]=useState(0)
  const[spotlights,setSpotlights]=useState<Batch[]>([])

  useEffect(()=>{
    setTok(localStorage.getItem('pr_token'))
    const iv=setInterval(()=>setQIdx(i=>(i+1)%QUOTES.length),5000)
    return()=>clearInterval(iv)
  },[])

  const fetch_=useCallback(async()=>{
    setLoading(true)
    try{
      const p=new URLSearchParams({sort})
      if(activeCat!=='All')p.set('examType',activeCat)
      if(search)p.set('search',search)
      if(filters.isFree)p.set('isFree',filters.isFree)
      if(filters.difficulty)p.set('difficulty',filters.difficulty)
      if(filters.batchType)p.set('batchType',filters.batchType)
      const token=localStorage.getItem('pr_token')
      const h=token?{Authorization:`Bearer ${token}`}:{} as Record<string,string>
      const url=tab==='enrolled'?`${API}/api/student/batches/my`:tab==='wishlist'?`${API}/api/student/batches/wishlist`:`${API}/api/student/batches?${p}`
      const res=await fetch(url,{headers:h})
      const d=await res.json()
      const all=d.batches||[]
      setBatches(all)
      setSpotlights(all.filter((b:Batch)=>b.isSpotlight).slice(0,3))
    }catch(e){setBatches([])}finally{setLoading(false)}
  },[activeCat,sort,search,filters,tab])

  useEffect(()=>{fetch_()},[fetch_])

  const C={blue:'#4D9FFF',cyan:'#00D4FF',text:'#E8F4FD',sub:'#7FA8C9',border:'rgba(77,159,255,0.2)'}

  return(
    <div style={{minHeight:'100vh',color:C.text,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden'}}>
      <SpaceCanvas/>
      <Planets/>
      <Saturn/>
      <style>{`
        @keyframes orbit{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(28px)}to{opacity:1;transform:translateY(0)}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-14px)}}
        @keyframes fadeSlide{0%{opacity:0;transform:translateX(24px)}100%{opacity:1;transform:translateX(0)}}
        @keyframes gradShift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
        @keyframes pulse{0%,100%{opacity:1}50%{opacity:0.5}}
        @keyframes nebulaPulse{0%,100%{opacity:0.7;transform:scale(1)}50%{opacity:1;transform:scale(1.03)}}
        input,select{outline:none;}
        input::placeholder{color:#4D6E8A}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:#4D9FFF44;border-radius:4px}
      `}</style>

      <div style={{position:'relative',zIndex:2,padding:'0 14px 80px',maxWidth:1200,margin:'0 auto'}}>

        {/* ── HERO ── */}
        <div style={{background:'linear-gradient(135deg,rgba(8,14,36,0.97),rgba(5,12,32,0.97))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:24,padding:'28px 20px',marginBottom:22,backdropFilter:'blur(24px)',boxShadow:'0 20px 80px rgba(0,20,80,0.3)',position:'relative',overflow:'hidden',animation:'slideUp 0.6s ease'}}>
          <div style={{position:'absolute',inset:0,background:'linear-gradient(270deg,rgba(77,159,255,0.05),rgba(0,212,255,0.04),rgba(155,89,182,0.04))',backgroundSize:'300%',animation:'gradShift 10s ease infinite',borderRadius:24,pointerEvents:'none'}}/>
          <div style={{position:'relative',zIndex:1}}>
            <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:14,flexWrap:'wrap'}}>
              <span style={{fontSize:36}}>🎓</span>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF,#9B59B6)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundSize:'200%',animation:'gradShift 5s ease infinite'}}>Test Series & Batches</div>
                <div style={{fontSize:12,color:C.sub,marginTop:2}}>ProveRank · NEET / JEE / CUET · Premium Preparation Platform</div>
              </div>
            </div>
            <div style={{display:'flex',gap:12,flexWrap:'wrap'}}>
              {[{i:'📚',v:'120+',l:'Series'},{i:'👥',v:'50K+',l:'Students'},{i:'🏆',v:'5K+',l:'Rankers'},{i:'🆓',v:'Free',l:'Available'}].map((s,i)=>(
                <div key={i} style={{background:'rgba(77,159,255,0.08)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:12,padding:'10px 14px',minWidth:72,textAlign:'center',animation:`slideUp ${0.7+i*0.1}s ease`}}>
                  <div style={{fontSize:20}}>{s.i}</div>
                  <div style={{fontSize:15,fontWeight:800,color:C.blue}}>{s.v}</div>
                  <div style={{fontSize:10,color:C.sub}}>{s.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ── NEBULA VIDEO ANIMATION + QUOTE (side by side on desktop) ── */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:16,marginBottom:22}}>
          <NebulaVideo/>
          <div key={qIdx} style={{background:QUOTES[qIdx].bg,border:'1px solid rgba(77,159,255,0.18)',borderRadius:16,padding:'20px 18px',backdropFilter:'blur(16px)',display:'flex',flexDirection:'column',justifyContent:'center',animation:'fadeSlide 0.5s ease'}}>
            <div style={{fontSize:32,marginBottom:12}}>💫</div>
            <div style={{fontSize:14,color:'#C8DCF0',fontStyle:'italic',lineHeight:1.7,marginBottom:12}}>"{QUOTES[qIdx].q}"</div>
            <div style={{fontSize:12,color:C.blue,fontWeight:700}}>— {QUOTES[qIdx].a}</div>
            <div style={{display:'flex',gap:6,marginTop:16,justifyContent:'center'}}>
              {QUOTES.map((_,i)=><div key={i} style={{width:i===qIdx?20:6,height:6,borderRadius:4,background:i===qIdx?C.blue:'rgba(77,159,255,0.3)',transition:'all 0.3s'}}/>)}
            </div>
          </div>
        </div>

        {/* ── CATEGORY STRIP ── */}
        <div style={{display:'flex',gap:8,overflowX:'auto',paddingBottom:6,marginBottom:18,scrollbarWidth:'none'}}>
          {CATS.map(cat=>(
            <button key={cat} onClick={()=>setActiveCat(cat)} style={{flexShrink:0,padding:'8px 16px',borderRadius:20,background:activeCat===cat?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.08)',border:activeCat===cat?'none':'1px solid rgba(77,159,255,0.18)',color:activeCat===cat?'#fff':C.sub,fontWeight:activeCat===cat?700:400,cursor:'pointer',fontSize:12,transition:'all 0.2s',whiteSpace:'nowrap'}}>
              {CICONS[cat]} {cat}
            </button>
          ))}
        </div>

        {/* ── SPOTLIGHT SECTION (only if spotlights exist) ── */}
        {spotlights.length>0&&(
          <div style={{marginBottom:24}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:C.text,marginBottom:14,display:'flex',alignItems:'center',gap:8}}>
              <span style={{fontSize:22,animation:'nebulaPulse 2s ease infinite'}}>⭐</span> Superadmin's Spotlight
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:16}}>
              {spotlights.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetch_}/>)}
            </div>
          </div>
        )}

        {/* ── TABS ── */}
        <div style={{display:'flex',gap:8,marginBottom:18}}>
          {(['all','enrolled','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{padding:'8px 14px',borderRadius:12,background:tab===t?'rgba(77,159,255,0.18)':'transparent',border:`1px solid ${tab===t?'rgba(77,159,255,0.45)':'rgba(77,159,255,0.14)'}`,color:tab===t?C.blue:C.sub,fontWeight:tab===t?700:400,cursor:'pointer',fontSize:12,flex:1,transition:'all 0.2s'}}>
              {t==='all'?'🌟 All':t==='enrolled'?'✅ My Batches':'❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* ── SEARCH + SORT + FILTER ── */}
        <div style={{display:'flex',gap:8,marginBottom:16,flexWrap:'wrap'}}>
          <div style={{flex:1,minWidth:180,position:'relative'}}>
            <span style={{position:'absolute',left:11,top:'50%',transform:'translateY(-50%)'}}>🔍</span>
            <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search batches, subjects..." style={{width:'100%',padding:'10px 10px 10px 33px',background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:12,color:C.text,fontSize:13}}/>
          </div>
          <select value={sort} onChange={e=>setSort(e.target.value)} style={{padding:'10px 10px',background:'rgba(77,159,255,0.07)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:12,color:C.text,fontSize:12,cursor:'pointer'}}>
            <option value="newest">🆕 Newest</option>
            <option value="popular">🔥 Popular</option>
            <option value="rating">⭐ Top Rated</option>
            <option value="price_low">💰 Low Price</option>
            <option value="price_high">💎 High Price</option>
          </select>
          <button onClick={()=>setFilterOpen(o=>!o)} style={{padding:'10px 14px',background:filterOpen?'rgba(77,159,255,0.18)':'rgba(77,159,255,0.07)',border:`1px solid ${filterOpen?'rgba(77,159,255,0.45)':'rgba(77,159,255,0.18)'}`,borderRadius:12,color:C.blue,cursor:'pointer',fontSize:12,fontWeight:600,transition:'all 0.2s'}}>⚙️ Filters</button>
        </div>

        {/* ── FILTER PANEL ── */}
        {filterOpen&&(
          <div style={{background:'rgba(8,12,28,0.96)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,padding:18,marginBottom:18,backdropFilter:'blur(20px)',display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:14,animation:'slideUp 0.3s ease'}}>
            {[
              {label:'Price',key:'isFree',opts:[{v:'',l:'All'},{v:'true',l:'Free'},{v:'false',l:'Paid'}]},
              {label:'Difficulty',key:'difficulty',opts:[{v:'',l:'Any'},{v:'Easy',l:'Easy'},{v:'Medium',l:'Medium'},{v:'Hard',l:'Hard'}]},
              {label:'Type',key:'batchType',opts:[{v:'',l:'Any'},{v:'Live',l:'Live'},{v:'Recorded',l:'Recorded'},{v:'Both',l:'Both'}]},
            ].map(f=>(
              <div key={f.key}>
                <div style={{fontSize:11,color:C.sub,marginBottom:7,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>{f.label}</div>
                <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                  {f.opts.map(o=>{
                    const active=(filters as Record<string,string>)[f.key]===o.v
                    return <button key={o.v} onClick={()=>setFilters(prev=>({...prev,[f.key]:o.v}))} style={{padding:'4px 10px',borderRadius:20,fontSize:11,cursor:'pointer',background:active?'rgba(77,159,255,0.28)':'rgba(77,159,255,0.07)',border:`1px solid ${active?C.blue:'rgba(77,159,255,0.18)'}`,color:active?C.blue:C.sub,transition:'all 0.2s'}}>{o.l}</button>
                  })}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ── BATCH GRID ── */}
        {loading?(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:18}}>
            {[1,2,3,4,5,6].map(i=><div key={i} style={{height:420,background:'rgba(77,159,255,0.04)',borderRadius:18,animation:'pulse 1.5s ease infinite',animationDelay:`${i*0.1}s`}}/>)}
          </div>
        ):batches.length===0?<EmptyState/>:(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:18}}>
            {batches.map((b,i)=>(
              <div key={b._id} style={{animation:`slideUp ${0.4+i*0.05}s ease both`}}>
                <BatchCard b={b} tok={tok} onUpdate={fetch_}/>
              </div>
            ))}
          </div>
        )}

        {/* ── NCERT SCIENCE FACTS ── */}
        <div style={{marginTop:44}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:C.text,marginBottom:6,textAlign:'center'}}>🔬 NCERT Science Facts</div>
          <div style={{fontSize:13,color:C.sub,textAlign:'center',marginBottom:22}}>Essential facts for NEET 2026 — Directly from NCERT</div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(270px,1fr))',gap:14}}>
            {FACTS.map((f,i)=>(
              <div key={i} style={{background:'rgba(8,12,28,0.9)',border:`1px solid ${f.col}28`,borderRadius:16,padding:18,backdropFilter:'blur(14px)',transition:'transform 0.3s',animation:`slideUp ${1.2+i*0.08}s ease`}}
                onMouseEnter={e=>(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)'}
                onMouseLeave={e=>(e.currentTarget as HTMLDivElement).style.transform=''}>
                <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>
                  <span style={{fontSize:30,filter:`drop-shadow(0 0 10px ${f.col})`}}>{f.icon}</span>
                  <div>
                    <div style={{fontWeight:700,color:f.col,fontSize:13,marginBottom:5}}>{f.title}</div>
                    <div style={{fontSize:12,color:'#B0CCE0',lineHeight:1.6}}>{f.fact}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── WHY PROVERANK SVG CARDS ── */}
        <div style={{marginTop:40,background:'rgba(8,12,28,0.9)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:22,padding:'28px 20px',backdropFilter:'blur(18px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:21,fontWeight:700,color:C.text,marginBottom:22,textAlign:'center'}}>✨ Why Choose ProveRank?</div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(170px,1fr))',gap:16}}>
            {[
              {i:'🎯',t:'NEET Pattern',d:'180 Qs · 720 Marks\n+4/−1 · 200 min',c:'#4D9FFF'},
              {i:'🤖',t:'AI Analytics',d:'Weak areas · Smart\nrevision · Forecasting',c:'#9B59B6'},
              {i:'🔒',t:'Anti-Cheat',d:'Webcam · Face AI\nIP lock · Proctoring',c:'#E74C3C'},
              {i:'📊',t:'Live Rankings',d:'Real-time AIR\nPercentile · Leaderboard',c:'#27AE60'},
              {i:'📄',t:'OMR Sheets',d:'Bubble view · PDF\nCertificates · Reports',c:'#E67E22'},
              {i:'🆓',t:'100% Free',d:'Free hosting\nNo hidden charges',c:'#00D4FF'},
            ].map((f,i)=>(
              <div key={i} style={{background:`rgba(77,159,255,0.04)`,border:`1px solid ${f.c}28`,borderRadius:14,padding:16,textAlign:'center',transition:'transform 0.3s'}}
                onMouseEnter={e=>(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)'}
                onMouseLeave={e=>(e.currentTarget as HTMLDivElement).style.transform=''}>
                <div style={{fontSize:34,marginBottom:10}}>{f.i}</div>
                <div style={{fontWeight:700,color:f.c,fontSize:13,marginBottom:6}}>{f.t}</div>
                <div style={{fontSize:11,color:C.sub,lineHeight:1.6,whiteSpace:'pre-line'}}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  )
}
