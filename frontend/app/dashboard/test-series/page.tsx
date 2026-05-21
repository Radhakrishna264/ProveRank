'use client'
import{useState,useEffect,useRef,useCallback}from'react'
const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'
type Batch={_id:string;name:string;description:string;examType:string;category:string;price:number;discountPrice:number;isFree:boolean;thumbnail:string;totalTests:number;enrolledCount:number;language:string;difficulty:string;batchType:string;isSpotlight:boolean;flashSaleEndTime?:string;flashSalePrice?:number;allowFreeTrial:boolean;trialDays:number;isBundle:boolean;validity:number;tags:string[];rating:number;ratingCount:number;isEnrolled?:boolean;isWishlisted?:boolean;createdAt:string;subject:string;}
const ECOLS:Record<string,string>={NEET:'#4D9FFF',JEE:'#9B59B6',CUET:'#27AE60','Class 11':'#E67E22','Class 12':'#E74C3C',Foundation:'#00D4FF','Crash Course':'#FF6B6B',Other:'#7F8C8D'}
const CATS=['All','NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course']
const CICONS:Record<string,string>={All:'🌟',NEET:'🩺',JEE:'⚙️',CUET:'📖','Class 11':'📗','Class 12':'📘',Foundation:'🏛️','Crash Course':'🚀'}
const QUOTES=[
  {q:"Champions aren't made in the gyms. Champions are made from something deep inside them.",a:"Muhammad Ali"},
  {q:"The secret of getting ahead is getting started. Every expert was once a beginner.",a:"Mark Twain"},
  {q:"In the middle of every difficulty lies opportunity. Stay focused.",a:"Albert Einstein"},
  {q:"Success is not final, failure is not fatal — it is the courage to continue that counts.",a:"Winston Churchill"},
]
const FACTS=[
  {icon:'🧬',t:'DNA Replication',f:'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.',c:'#4D9FFF'},
  {icon:'⚡',t:'ATP Synthesis',f:'Mitochondria produce 36-38 ATP/glucose via oxidative phosphorylation. F₀F₁ ATP synthase rotates at 100 rpm.',c:'#00D4FF'},
  {icon:'🌿',t:'Photosynthesis',f:'6CO₂+6H₂O+Light→C₆H₁₂O₆+6O₂. Light reactions in thylakoid. Calvin cycle in stroma. C4 plants more efficient.',c:'#27AE60'},
  {icon:'⚗️',t:'Periodic Table',f:'Elements arranged by atomic number. Mendeleev (mass) → Moseley (atomic no). 118 elements known. Period 7 complete.',c:'#E67E22'},
  {icon:'🔭',t:'Laws of Motion',f:"Newton's 3 Laws: Inertia, F=ma, Action-Reaction. Gravity: F=Gm₁m₂/r². Einstein: mass curves spacetime.",c:'#9B59B6'},
  {icon:'🦠',t:'Cell Division',f:'Mitosis: 2 identical diploid cells. Meiosis: 4 haploid cells (gametes). S phase: DNA replication. G2: cell growth.',c:'#E74C3C'},
]

// ━━ MILKY WAY + DEEP SPACE CANVAS ━━
function MilkyWayCanvas(){
  const r=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const cv=r.current;if(!cv)return
    const ctx=cv.getContext('2d');if(!ctx)return
    let af:number,t=0
    const resize=()=>{cv.width=window.innerWidth;cv.height=window.innerHeight}
    resize();window.addEventListener('resize',resize)
    // Generate stars with spectral classes (O=blue, B=blue-white, A=white, F=yellow-white, G=yellow, K=orange, M=red)
    const stars=Array.from({length:1200},(_,i)=>{
      const cls=Math.random()
      return{
        x:Math.random(),y:Math.random(),
        r:cls<0.005?2.8:cls<0.02?1.8:cls<0.08?1.1:0.5,
        phase:Math.random()*Math.PI*2,
        spd:0.3+Math.random()*3,
        col:cls<0.001?'#9BB0FF':cls<0.005?'#AABFFF':cls<0.02?'#CAD7FF':cls<0.08?'#F8F7FF':cls<0.15?'#FFF4EA':cls<0.25?'#FFD2A1':'#FFCC6F',
        inCore:Math.random()<0.08,
        inArm:Math.random()<0.55,
      }
    })
    const draw=()=>{
      t+=0.003
      const W=cv.width,H=cv.height,cx=W/2,cy=H/2
      ctx.clearRect(0,0,W,H)
      // Deep space base
      ctx.fillStyle='#020816';ctx.fillRect(0,0,W,H)
      // Milky Way diagonal haze band (like actual night sky)
      for(let band=0;band<3;band++){
        const grd=ctx.createLinearGradient(0,H*(0.1+band*0.3),W,H*(0.5+band*0.2))
        grd.addColorStop(0,'transparent')
        grd.addColorStop(0.3,'rgba(100,120,200,0.03)')
        grd.addColorStop(0.5,'rgba(150,165,230,0.06)')
        grd.addColorStop(0.7,'rgba(100,120,200,0.03)')
        grd.addColorStop(1,'transparent')
        ctx.fillStyle=grd;ctx.fillRect(0,0,W,H)
      }
      // Galactic bulge (warm dense core — scientifically yellowish-orange)
      const sz=Math.min(W,H)
      const core=ctx.createRadialGradient(cx,cy*1.1,0,cx,cy*1.1,sz*0.22)
      core.addColorStop(0,'rgba(255,220,130,0.18)')
      core.addColorStop(0.3,'rgba(255,180,80,0.1)')
      core.addColorStop(0.6,'rgba(180,120,60,0.05)')
      core.addColorStop(1,'transparent')
      ctx.fillStyle=core;ctx.fillRect(0,0,W,H)
      // 4 spiral arms (Sagittarius, Perseus, Norma-Cygnus, Scutum-Centaurus)
      const armCols=['rgba(100,160,255,','rgba(180,120,255,','rgba(80,200,255,','rgba(120,200,140,']
      for(let arm=0;arm<4;arm++){
        for(let seg=0;seg<9;seg++){
          const logR=0.25+seg*0.38
          const angle=arm*(Math.PI/2)+logR*1.35+t*0.04
          const dist=(sz*0.07)+(sz*0.07)*seg
          const nx=cx+Math.cos(angle)*dist
          const ny=cy*1.1+Math.sin(angle)*dist*(H/W)
          const bsz=(sz*0.045)+(sz*0.025)*seg
          const neb=ctx.createRadialGradient(nx,ny,0,nx,ny,bsz*(1+0.12*Math.sin(t*0.7+seg+arm)))
          neb.addColorStop(0,armCols[arm]+'0.11)')
          neb.addColorStop(0.5,armCols[arm]+'0.05)')
          neb.addColorStop(1,'transparent')
          ctx.fillStyle=neb;ctx.fillRect(0,0,W,H)
        }
      }
      // Deep space nebulae (colorful clouds)
      const nebCols:Array<[number,number,number]>=[[77,159,255],[155,89,182],[231,76,60],[39,174,96],[0,212,255]]
      nebCols.forEach(([rr,gg,bb],i)=>{
        const nx=W*(0.15+i*0.18)+Math.cos(t*0.12+i)*W*0.04
        const ny=H*(0.12+i*0.17)+Math.sin(t*0.1+i)*H*0.04
        const nr=sz*(0.08+0.04*Math.sin(t*0.2+i))
        const ng=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)
        ng.addColorStop(0,`rgba(${rr},${gg},${bb},0.07)`)
        ng.addColorStop(0.6,`rgba(${rr},${gg},${bb},0.03)`)
        ng.addColorStop(1,'transparent')
        ctx.fillStyle=ng;ctx.fillRect(0,0,W,H)
      })
      // Draw stars with spectral colors + twinkling
      stars.forEach(s=>{
        const x=s.x*W,y=s.y*H
        const tw=0.3+0.7*Math.abs(Math.sin(t*s.spd+s.phase))
        const alpha=s.inCore&&Math.hypot(x-cx,y-cy)<sz*0.1?tw*0.9:s.inArm?tw*0.75:tw*0.55
        // Glow for bright stars
        if(s.r>1.5){
          const gl=ctx.createRadialGradient(x,y,0,x,y,s.r*4)
          gl.addColorStop(0,s.col.replace(')',`,${alpha*0.4})`).replace('rgb','rgba'))
          gl.addColorStop(1,'transparent')
          ctx.fillStyle=gl;ctx.beginPath();ctx.arc(x,y,s.r*4,0,Math.PI*2);ctx.fill()
        }
        ctx.beginPath();ctx.arc(x,y,s.r,0,Math.PI*2)
        ctx.fillStyle=s.col.replace(')',`,${alpha})`).replace('rgb','rgba')
        ctx.fill()
      })
      // Shooting stars occasionally
      if(Math.sin(t*0.7)*Math.sin(t*1.3)>0.95){
        const sx=Math.random()*W,sy=Math.random()*H*0.5
        ctx.beginPath();ctx.moveTo(sx,sy);ctx.lineTo(sx+60,sy+30)
        ctx.strokeStyle=`rgba(255,255,255,${0.4+0.4*Math.random()})`;ctx.lineWidth=1.2;ctx.stroke()
      }
      af=requestAnimationFrame(draw)
    }
    draw()
    return()=>{cancelAnimationFrame(af);window.removeEventListener('resize',resize)}
  },[])
  return<canvas ref={r} style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none'}}/>
}

// ━━ ORBITING SOLAR SYSTEM (accurate colors + Saturn rings) ━━
function SolarSystem(){
  const planets=[
    {sz:7,col:'#9E9E9E',o:120,dur:47,dl:0},
    {sz:13,col:'linear-gradient(135deg,#F5D5A0,#C4A265)',o:180,dur:35,dl:-8},
    {sz:14,col:'linear-gradient(135deg,#5BC8FA,#1565C0,#0D47A1)',o:250,dur:29,dl:-14},
    {sz:9,col:'linear-gradient(135deg,#FF7043,#BF360C)',o:320,dur:24,dl:-20},
  ]
  return(
    <div style={{position:'fixed',top:'42%',left:'50%',transform:'translate(-50%,-50%)',zIndex:1,pointerEvents:'none',width:0,height:0}}>
      <style>{`@keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}`}</style>
      {/* Sun */}
      <div style={{position:'absolute',width:28,height:28,marginLeft:-14,marginTop:-14,borderRadius:'50%',background:'radial-gradient(circle at 40% 40%,#FFF9C4,#FFD600,#FF8F00)',boxShadow:'0 0 40px rgba(255,200,0,0.6),0 0 80px rgba(255,150,0,0.3)'}}/>
      {planets.map((p,i)=>(
        <div key={i} style={{position:'absolute',width:p.o*2,height:p.o*2,marginLeft:-p.o,marginTop:-p.o,borderRadius:'50%',border:'1px solid rgba(77,159,255,0.06)',animation:`orb ${p.dur}s linear infinite`,animationDelay:`${p.dl}s`}}>
          <div style={{position:'absolute',top:-p.sz/2,left:'50%',marginLeft:-p.sz/2,width:p.sz,height:p.sz,borderRadius:'50%',background:p.col,boxShadow:`0 0 ${p.sz*2}px rgba(77,159,255,0.2)`}}/>
        </div>
      ))}
      {/* Saturn with rings */}
      <div style={{position:'absolute',width:860,height:860,marginLeft:-430,marginTop:-430,borderRadius:'50%',border:'1px solid rgba(77,159,255,0.04)',animation:'orb 87s linear infinite',animationDelay:'-30s'}}>
        <div style={{position:'absolute',top:-18,left:'50%',marginLeft:-18}}>
          <div style={{position:'relative',width:36,height:36}}>
            <div style={{width:36,height:36,borderRadius:'50%',background:'radial-gradient(circle at 35% 35%,#FFF9C4,#F0D060,#B8860B)',boxShadow:'0 0 20px rgba(218,165,32,0.3)'}}/>
            <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%) rotateX(70deg)',width:72,height:72,borderRadius:'50%',border:'3px solid rgba(240,210,140,0.45)',pointerEvents:'none'}}/>
            <div style={{position:'absolute',top:'50%',left:'50%',transform:'translate(-50%,-50%) rotateX(70deg)',width:90,height:90,borderRadius:'50%',border:'2px solid rgba(240,210,140,0.22)',pointerEvents:'none'}}/>
          </div>
        </div>
      </div>
    </div>
  )
}

// ━━ LIVE NEBULA ANIMATION (Video Animation Rule) ━━
function NebulaAnim(){
  const r=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const cv=r.current;if(!cv)return
    const ctx=cv.getContext('2d');if(!ctx)return
    cv.width=480;cv.height=280;let af:number,t=0
    const clouds:Array<{x:number;y:number;r:number;col:[number,number,number];spd:number;phase:number}>=Array.from({length:8},(_,i)=>({
      x:240+Math.cos(i*0.8)*100,y:140+Math.sin(i*0.8)*60,
      r:45+i*8,col:([[77,159,255],[155,89,182],[0,212,255],[231,76,60],[39,174,96],[255,183,77],[100,181,246],[240,98,146]][i]as[number,number,number]),
      spd:0.008+i*0.003,phase:i*0.7
    }))
    const draw=()=>{
      t+=0.01;ctx.clearRect(0,0,480,280)
      ctx.fillStyle='rgba(2,8,22,0.15)';ctx.fillRect(0,0,480,280)
      clouds.forEach(cl=>{
        const nx=cl.x+Math.cos(t*cl.spd+cl.phase)*35
        const ny=cl.y+Math.sin(t*cl.spd*1.3+cl.phase)*20
        const nr=cl.r*(1+0.15*Math.sin(t*0.4+cl.phase))
        const g=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)
        const[rr,gg,bb]=cl.col
        g.addColorStop(0,`rgba(${rr},${gg},${bb},0.28)`)
        g.addColorStop(0.5,`rgba(${rr},${gg},${bb},0.12)`)
        g.addColorStop(1,'transparent')
        ctx.fillStyle=g;ctx.fillRect(0,0,480,280)
      })
      // Central star formation region
      const c2=ctx.createRadialGradient(240,140,0,240,140,18+8*Math.sin(t*2.5))
      c2.addColorStop(0,'rgba(255,255,255,0.7)');c2.addColorStop(0.4,'rgba(200,230,255,0.3)');c2.addColorStop(1,'transparent')
      ctx.fillStyle=c2;ctx.fillRect(0,0,480,280)
      // Mini stars
      for(let i=0;i<40;i++){
        const sx=(Math.sin(i*127.1+t*0.1)*0.5+0.5)*480
        const sy=(Math.cos(i*311.7+t*0.07)*0.5+0.5)*280
        const sa=0.3+0.7*Math.abs(Math.sin(t*(0.5+i*0.03)+i))
        ctx.beginPath();ctx.arc(sx,sy,0.8,0,Math.PI*2)
        ctx.fillStyle=`rgba(255,255,255,${sa})`;ctx.fill()
      }
      af=requestAnimationFrame(draw)
    }
    draw();return()=>cancelAnimationFrame(af)
  },[])
  return(
    <div style={{borderRadius:20,overflow:'hidden',border:'1px solid rgba(77,159,255,0.25)',position:'relative',background:'rgba(2,8,22,0.9)',boxShadow:'0 0 40px rgba(77,159,255,0.1)'}}>
      <canvas ref={r} style={{width:'100%',height:'auto',display:'block'}}/>
      <div style={{position:'absolute',inset:0,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:6,pointerEvents:'none'}}>
        <div style={{fontSize:22,filter:'drop-shadow(0 0 12px #4D9FFF)'}}>🌌</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:'rgba(255,255,255,0.9)',textShadow:'0 0 20px #4D9FFF',textAlign:'center',padding:'0 20px'}}>Live Nebula Simulation</div>
        <div style={{fontSize:11,color:'rgba(160,200,255,0.85)',textAlign:'center'}}>Milky Way · 200B Stars · 13.6B Years Old</div>
      </div>
    </div>
  )
}

// ━━ FLASH TIMER ━━
function FlashTimer({end}:{end:string}){
  const[s,setS]=useState({h:0,m:0,s:0})
  useEffect(()=>{
    const tick=()=>{const d=new Date(end).getTime()-Date.now();if(d<=0){setS({h:0,m:0,s:0});return};setS({h:Math.floor(d/3600000),m:Math.floor(d%3600000/60000),s:Math.floor(d%60000/1000)})};tick();const iv=setInterval(tick,1000);return()=>clearInterval(iv)
  },[end])
  const p=(n:number)=>n.toString().padStart(2,'0')
  return<span style={{fontFamily:'monospace',fontSize:15,fontWeight:800,color:'#FF6B6B',letterSpacing:2}}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

// ━━ STAR RATING ━━
function Stars({r}:{r:number}){
  return<span>{[1,2,3,4,5].map(i=><span key={i} style={{color:i<=Math.round(r)?'#FFD700':'rgba(255,215,0,0.2)',fontSize:11}}>{i<=Math.round(r)?'★':'★'}</span>)}<span style={{fontSize:10,color:'rgba(255,255,255,0.4)',marginLeft:4}}>{r.toFixed(1)}</span></span>
}

// ━━ BATCH CARD ━━
function BatchCard({b,tok,onUpdate}:{b:Batch;tok:string|null;onUpdate:()=>void}){
  const[loading,setLoading]=useState(false)
  const[hovered,setHovered]=useState(false)
  const isFlash=!!(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())
  const isNew=Date.now()-new Date(b.createdAt).getTime()<7*86400000
  const ec=ECOLS[b.examType]||'#4D9FFF'
  const finalPrice=isFlash&&b.flashSalePrice?b.flashSalePrice:b.discountPrice||b.price
  const discount=b.price>0&&finalPrice<b.price?Math.round((1-finalPrice/b.price)*100):0
  const enroll=async()=>{
    if(!tok)return alert('Please login to enroll')
    setLoading(true)
    try{const r2=await fetch(`${API}/api/student/batches/${b._id}/enroll`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}});const d=await r2.json();if(d.success)onUpdate();else alert(d.error||'Error')}
    finally{setLoading(false)}
  }
  const toggleWish=async()=>{
    if(!tok)return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`,{method:'POST',headers:{Authorization:`Bearer ${tok}`}});onUpdate()
  }
  return(
    <div onMouseEnter={()=>setHovered(true)} onMouseLeave={()=>setHovered(false)}
      style={{background:'rgba(4,12,30,0.95)',border:`1px solid ${hovered?ec+'60':ec+'20'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(24px)',position:'relative',transition:'all 0.3s ease',transform:hovered?'translateY(-6px)':'none',boxShadow:hovered?`0 24px 60px ${ec}20,0 0 0 1px ${ec}20`:'0 4px 20px rgba(0,0,20,0.4)'}}>
      {/* Badges */}
      <div style={{position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4}}>
        {isNew&&<span style={{background:'linear-gradient(135deg,#27AE60,#1E8449)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 10px',borderRadius:20,boxShadow:'0 2px 8px rgba(39,174,96,0.4)'}}>✨ NEW</span>}
        {b.enrolledCount>100&&<span style={{background:'linear-gradient(135deg,#E67E22,#CA6F1E)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 10px',borderRadius:20}}>🔥 HOT</span>}
        {b.isBundle&&<span style={{background:'linear-gradient(135deg,#9B59B6,#7D3C98)',color:'#fff',fontSize:9,fontWeight:800,padding:'3px 10px',borderRadius:20}}>📦 BUNDLE</span>}
      </div>
      {/* Wishlist */}
      <button onClick={toggleWish} style={{position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:16,display:'flex',alignItems:'center',justifyContent:'center',backdropFilter:'blur(8px)',transition:'all 0.2s'}}>{b.isWishlisted?'❤️':'🤍'}</button>
      {/* Thumbnail */}
      <div style={{height:148,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}15,${ec}05,rgba(2,8,22,0.8))`,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden'}}>
        <div style={{position:'absolute',inset:0,background:`linear-gradient(180deg,transparent 40%,rgba(4,12,30,0.95))`,zIndex:1}}/>
        {!b.thumbnail&&<span style={{fontSize:52,filter:`drop-shadow(0 0 20px ${ec})`,zIndex:2,opacity:0.9}}>{b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':b.examType==='CUET'?'📖':b.examType==='Crash Course'?'🚀':'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.9)',padding:'5px 0',textAlign:'center',fontSize:11,fontWeight:700,color:'#fff',zIndex:3,backdropFilter:'blur(4px)'}}>⚡ Flash Sale: <FlashTimer end={b.flashSaleEndTime}/></div>}
        {b.isEnrolled&&<div style={{position:'absolute',inset:0,background:'rgba(39,174,96,0.2)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2}}><span style={{background:'rgba(39,174,96,0.9)',color:'#fff',padding:'6px 16px',borderRadius:20,fontSize:12,fontWeight:800,boxShadow:'0 0 20px rgba(39,174,96,0.4)'}}>✅ Enrolled</span></div>}
      </div>
      {/* Body */}
      <div style={{padding:'14px 16px 16px'}}>
        <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:8}}>
          <span style={{background:`${ec}18`,color:ec,fontSize:10,fontWeight:700,padding:'3px 10px',borderRadius:20,border:`1px solid ${ec}30`}}>{b.examType}</span>
          <span style={{background:b.isFree?'rgba(39,174,96,0.15)':'rgba(230,126,34,0.15)',color:b.isFree?'#27AE60':'#E67E22',fontSize:10,fontWeight:700,padding:'3px 10px',borderRadius:20}}>{b.isFree?'🆓 FREE':b.allowFreeTrial?`🎯 ${b.trialDays}-Day Trial`:'💎 PAID'}</span>
          <span style={{background:'rgba(255,255,255,0.05)',color:'rgba(255,255,255,0.4)',fontSize:9,padding:'3px 8px',borderRadius:20}}>{b.batchType}</span>
        </div>
        <div style={{fontSize:14,fontWeight:700,color:'#F0F8FF',marginBottom:5,fontFamily:'Playfair Display,serif',lineHeight:1.4,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical'}}>{b.name}</div>
        <div style={{fontSize:11,color:'rgba(180,210,240,0.65)',lineHeight:1.55,overflow:'hidden',display:'-webkit-box',WebkitLineClamp:2,WebkitBoxOrient:'vertical',marginBottom:10}}>{b.description||'Premium test series for competitive exam preparation — NCERT based, expert curated content.'}</div>
        <Stars r={b.rating}/>
        <div style={{display:'flex',gap:8,marginTop:8,flexWrap:'wrap'}}>
  {[{i:'📝',v:`${b.totalTests} Tests`},{i:'👥',v:b.enrolledCount.toLocaleString()},{i:'📅',v:`${b.validity}d`},{i:'🌐',v:b.language.split('+')[0].trim()}].map((it,idx)=>(
            <span key={idx} style={{fontSize:10,color:'rgba(180,210,240,0.55)',display:'flex',alignItems:'center',gap:3}}>{it.i} {it.v}</span>
          ))}
</div>
        {!b.isFree&&b.price>300&&<div style={{fontSize:10,color:'rgba(255,255,255,0.3)',marginTop:7}}>💳 EMI from ₹{Math.round(finalPrice/3)}/mo</div>}
        <div style={{display:'flex',alignItems:'center',gap:8,margin:'10px 0 12px'}}>
          {b.isFree?<span style={{fontSize:22,fontWeight:900,color:'#27AE60',fontFamily:'Playfair Display,serif'}}>FREE</span>
            :<><span style={{fontSize:22,fontWeight:900,color:'#F0F8FF',fontFamily:'Playfair Display,serif'}}>₹{finalPrice}</span>
            {discount>0&&<span style={{fontSize:12,color:'rgba(255,255,255,0.3)',textDecoration:'line-through'}}>₹{b.price}</span>}
            {discount>0&&<span style={{fontSize:10,background:'rgba(39,174,96,0.2)',color:'#27AE60',padding:'2px 8px',borderRadius:20,fontWeight:700}}>{discount}% OFF</span>}</>}
        </div>
        {b.isEnrolled
          ?<button style={{width:'100%',padding:'11px',background:`linear-gradient(135deg,${ec}25,${ec}15)`,border:`1px solid ${ec}50`,borderRadius:12,color:ec,fontWeight:700,cursor:'pointer',fontSize:12,letterSpacing:0.5,transition:'all 0.2s'}}>Continue Learning →</button>
          :b.isFree?<button onClick={enroll} disabled={loading} style={{width:'100%',padding:'11px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:'0 4px 20px rgba(39,174,96,0.35)',transition:'all 0.2s'}}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
          :b.allowFreeTrial?<button onClick={enroll} disabled={loading} style={{width:'100%',padding:'11px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:`0 4px 20px ${ec}35`}}>{loading?'Starting...':'🎯 Start Free Trial'}</button>
          :<button style={{width:'100%',padding:'11px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,boxShadow:`0 4px 20px ${ec}35`}}>🛒 Buy ₹{finalPrice}</button>}
      </div>
    </div>
  )
}

// ━━ EMPTY STATE ━━
function EmptyState(){
  return(
    <div style={{textAlign:'center',padding:'60px 20px'}}>
      <div style={{fontSize:80,marginBottom:20,display:'inline-block',animation:'floatBob 3s ease infinite'}}>🚀</div>
      <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:12}}>Batches Launching Soon!</div>
      <div style={{fontSize:13,color:'rgba(160,200,240,0.7)',maxWidth:420,margin:'0 auto 28px',lineHeight:1.8}}>Premium Test Series & Batches will appear here once created by the Admin. World-class NEET/JEE preparation is on the way!</div>
      <div style={{display:'flex',gap:8,justifyContent:'center',flexWrap:'wrap',marginBottom:32}}>
        {['🩺 NEET 2026','⚙️ JEE Advanced','📖 CUET','🚀 Crash Course','🏛️ Foundation'].map((t,i)=>(
          <div key={i} style={{background:'rgba(77,159,255,0.08)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:'8px 16px',fontSize:11,color:'#4D9FFF',fontWeight:600}}>{t}</div>
        ))}
      </div>
      <div style={{background:'rgba(4,12,30,0.9)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:18,padding:22,maxWidth:440,margin:'0 auto',textAlign:'left',backdropFilter:'blur(16px)'}}>
        <div style={{fontWeight:700,color:'#4D9FFF',fontSize:12,marginBottom:12,textTransform:'uppercase',letterSpacing:1}}>📋 What's Coming</div>
        {['Full Syllabus Test Series (180 Qs · NEET Pattern · +4/-1)','Chapter-wise Mini Tests (15-20 min each)','Crash Courses with PDF Notes & Explanations','PYQ Bank: NEET 2015-2024 (10 years)','Free & Paid — both available for all students'].map((t,i)=>(
          <div key={i} style={{fontSize:11,color:'rgba(160,200,240,0.7)',marginBottom:7,display:'flex',gap:8,alignItems:'flex-start'}}><span style={{color:'#27AE60',flexShrink:0}}>✓</span>{t}</div>
        ))}
      </div>
    </div>
  )
}

// ━━ MAIN PAGE ━━
export default function TestSeriesPage(){
  const[batches,setBatches]=useState<Batch[]>([])
  const[loading,setLoading]=useState(true)
  const[search,setSearch]=useState('')
  const[cat,setCat]=useState('All')
  const[sort,setSort]=useState('newest')
  const[filterOpen,setFilterOpen]=useState(false)
  const[filters,setFilters]=useState({isFree:'',difficulty:'',batchType:''})
  const[tab,setTab]=useState<'all'|'enrolled'|'wishlist'>('all')
  const[tok,setTok]=useState<string|null>(null)
  const[qIdx,setQIdx]=useState(0)
  const[spotlights,setSpotlights]=useState<Batch[]>([])
  useEffect(()=>{setTok(localStorage.getItem('pr_token'));const iv=setInterval(()=>setQIdx(i=>(i+1)%QUOTES.length),5000);return()=>clearInterval(iv)},[])
  const fetchBatches=useCallback(async()=>{
    setLoading(true)
    try{
      const p=new URLSearchParams({sort})
      if(cat!=='All')p.set('examType',cat)
      if(search)p.set('search',search)
      if(filters.isFree)p.set('isFree',filters.isFree)
      if(filters.batchType)p.set('batchType',filters.batchType)
      const token=localStorage.getItem('pr_token')
      const h=token?{Authorization:`Bearer ${token}`}:{} as Record<string,string>
      const url=tab==='enrolled'?`${API}/api/student/batches/my`:tab==='wishlist'?`${API}/api/student/batches/wishlist`:`${API}/api/student/batches?${p}`
      const res=await fetch(url,{headers:h});const d=await res.json()
      const all=d.batches||[]
      setBatches(all);setSpotlights(all.filter((b:Batch)=>b.isSpotlight).slice(0,3))
    }catch{setBatches([])}finally{setLoading(false)}
  },[cat,sort,search,filters,tab])
  useEffect(()=>{fetchBatches()},[fetchBatches])

  return(
    <div style={{minHeight:'100vh',color:'#F0F8FF',fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:'transparent'}}>
      <MilkyWayCanvas/>
      <SolarSystem/>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-16px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes fadeSlide{from{opacity:0;transform:translateX(20px)}to{opacity:1;transform:translateX(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%{opacity:0.4}50%{opacity:1}100%{opacity:0.4}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        input,select{outline:none;}
        input::placeholder{color:rgba(100,150,200,0.5)}
      `}</style>

      <div style={{position:'relative',zIndex:2,padding:'16px 14px 80px',maxWidth:1200,margin:'0 auto'}}>

        {/* ━━ HERO BANNER ━━ */}
        <div style={{background:'linear-gradient(135deg,rgba(4,12,30,0.97),rgba(2,8,22,0.97))',border:'1px solid rgba(77,159,255,0.2)',borderRadius:24,padding:'26px 20px 22px',marginBottom:20,backdropFilter:'blur(30px)',boxShadow:'0 20px 80px rgba(0,10,40,0.5)',position:'relative',overflow:'hidden',animation:'slideUp 0.5s ease'}}>
          {/* Animated gradient overlay */}
          <div style={{position:'absolute',inset:0,background:'linear-gradient(270deg,rgba(77,159,255,0.06),rgba(0,212,255,0.04),rgba(155,89,182,0.05),rgba(77,159,255,0.06))',backgroundSize:'300%',animation:'gradShift 12s ease infinite',borderRadius:24,pointerEvents:'none'}}/>
          {/* Grid pattern overlay */}
          <div style={{position:'absolute',inset:0,backgroundImage:'linear-gradient(rgba(77,159,255,0.03) 1px,transparent 1px),linear-gradient(90deg,rgba(77,159,255,0.03) 1px,transparent 1px)',backgroundSize:'30px 30px',borderRadius:24,pointerEvents:'none'}}/>
          <div style={{position:'relative',zIndex:1}}>
            <div style={{display:'flex',alignItems:'center',gap:14,marginBottom:8,flexWrap:'wrap'}}>
              <span style={{fontSize:38,filter:'drop-shadow(0 0 16px rgba(77,159,255,0.6))'}}>🎓</span>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 40%,#9B59B6 100%)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',backgroundSize:'200%',animation:'gradShift 6s ease infinite',lineHeight:1.2}}>Test Series & Batches</div>
                <div style={{fontSize:12,color:'rgba(160,200,240,0.7)',marginTop:3}}>ProveRank · NEET / JEE / CUET · Premium Prep Platform</div>
              </div>
            </div>
            <div style={{display:'flex',gap:10,flexWrap:'wrap',marginTop:14}}>
              {[{i:'📚',v:'120+',l:'Test Series'},{i:'👥',v:'50K+',l:'Students'},{i:'🏆',v:'5K+',l:'Top Rankers'},{i:'🆓',v:'Free',l:'Available'}].map((s,i)=>(
                <div key={i} style={{background:'rgba(77,159,255,0.08)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,padding:'10px 14px',textAlign:'center',minWidth:70,animation:`slideUp ${0.6+i*0.1}s ease`,backdropFilter:'blur(8px)'}}>
                  <div style={{fontSize:20,marginBottom:2}}>{s.i}</div>
                  <div style={{fontSize:16,fontWeight:800,color:'#4D9FFF'}}>{s.v}</div>
                  <div style={{fontSize:10,color:'rgba(160,200,240,0.6)'}}>{s.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ━━ NEBULA VIDEO + MOTIVATIONAL QUOTE ━━ */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(250px,1fr))',gap:16,marginBottom:20}}>
          <NebulaAnim/>
          <div key={qIdx} style={{background:'linear-gradient(135deg,rgba(4,12,30,0.97),rgba(8,18,45,0.97))',border:'1px solid rgba(77,159,255,0.18)',borderRadius:20,padding:'22px 20px',backdropFilter:'blur(20px)',display:'flex',flexDirection:'column',justifyContent:'center',animation:'fadeSlide 0.5s ease',boxShadow:'0 8px 40px rgba(0,10,40,0.4)'}}>
            <div style={{fontSize:36,marginBottom:14,filter:'drop-shadow(0 0 12px rgba(255,200,50,0.5))'}}>💫</div>
            <div style={{fontSize:14,color:'rgba(200,220,240,0.9)',fontStyle:'italic',lineHeight:1.75,marginBottom:16,fontFamily:'Playfair Display,serif'}}>"{QUOTES[qIdx].q}"</div>
            <div style={{fontSize:12,color:'#4D9FFF',fontWeight:700}}>— {QUOTES[qIdx].a}</div>
            <div style={{display:'flex',gap:6,marginTop:18,justifyContent:'center'}}>
              {QUOTES.map((_,i)=><div key={i} style={{width:i===qIdx?22:6,height:6,borderRadius:4,background:i===qIdx?'linear-gradient(90deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.25)',transition:'all 0.4s'}}/>)}
            </div>
          </div>
        </div>

        {/* ━━ CATEGORY STRIP ━━ */}
        <div style={{display:'flex',gap:8,overflowX:'auto',paddingBottom:8,marginBottom:16,scrollbarWidth:'none'}}>
          {CATS.map(c=>{
            const active=cat===c
            return<button key={c} onClick={()=>setCat(c)} style={{flexShrink:0,padding:'9px 18px',borderRadius:24,background:active?'linear-gradient(135deg,#4D9FFF,#00D4FF)':'rgba(77,159,255,0.07)',border:active?'none':'1px solid rgba(77,159,255,0.15)',color:active?'#fff':'rgba(160,200,240,0.7)',fontWeight:active?700:400,cursor:'pointer',fontSize:12,transition:'all 0.2s',whiteSpace:'nowrap',boxShadow:active?'0 4px 16px rgba(77,159,255,0.3)':'none'}}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* ━━ SPOTLIGHT SECTION ━━ */}
        {spotlights.length>0&&(
          <div style={{marginBottom:24,animation:'slideUp 0.7s ease'}}>
            <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:14}}>
              <span style={{fontSize:20,animation:'shimmer 2s ease infinite'}}>⭐</span>
              <span style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#F0F8FF'}}>Spotlight Picks</span>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(250px,1fr))',gap:16}}>
              {spotlights.map(b=><BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches}/>)}
            </div>
          </div>
        )}

        {/* ━━ TABS ━━ */}
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8,marginBottom:16}}>
          {(['all','enrolled','wishlist'] as const).map(t=>(
            <button key={t} onClick={()=>setTab(t)} style={{padding:'10px',borderRadius:14,background:tab===t?'rgba(77,159,255,0.15)':'rgba(4,12,30,0.8)',border:`1px solid ${tab===t?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.1)'}`,color:tab===t?'#4D9FFF':'rgba(160,200,240,0.5)',fontWeight:tab===t?700:400,cursor:'pointer',fontSize:12,transition:'all 0.2s',backdropFilter:'blur(12px)'}}>
              {t==='all'?'🌟 All':t==='enrolled'?'✅ My Batches':'❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* ━━ SEARCH + SORT + FILTER ━━ */}
        <div style={{display:'flex',gap:8,marginBottom:14,flexWrap:'wrap'}}>
          <div style={{flex:1,minWidth:180,position:'relative'}}>
            <span style={{position:'absolute',left:12,top:'50%',transform:'translateY(-50%)',fontSize:14,opacity:0.5}}>🔍</span>
            <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search batches, subjects..." style={{width:'100%',padding:'11px 12px 11px 36px',background:'rgba(4,12,30,0.9)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,color:'#F0F8FF',fontSize:12,backdropFilter:'blur(12px)',transition:'border 0.2s'}} onFocus={e=>e.target.style.borderColor='rgba(77,159,255,0.4)'} onBlur={e=>e.target.style.borderColor='rgba(77,159,255,0.15)'}/>
          </div>
          <select value={sort} onChange={e=>setSort(e.target.value)} style={{padding:'11px 10px',background:'rgba(4,12,30,0.9)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,color:'#F0F8FF',fontSize:11,cursor:'pointer',backdropFilter:'blur(12px)'}}>
            <option value="newest">🆕 Newest</option>
            <option value="popular">🔥 Popular</option>
            <option value="rating">⭐ Top Rated</option>
            <option value="price_low">💰 Low Price</option>
            <option value="price_high">💎 High Price</option>
          </select>
          <button onClick={()=>setFilterOpen(o=>!o)} style={{padding:'11px 14px',background:filterOpen?'rgba(77,159,255,0.15)':'rgba(4,12,30,0.9)',border:`1px solid ${filterOpen?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.15)'}`,borderRadius:14,color:'#4D9FFF',cursor:'pointer',fontSize:12,fontWeight:600,backdropFilter:'blur(12px)',transition:'all 0.2s'}}>⚙️ Filters</button>
        </div>

        {/* ━━ FILTER PANEL ━━ */}
        {filterOpen&&(
          <div style={{background:'rgba(4,12,30,0.97)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:18,padding:18,marginBottom:16,backdropFilter:'blur(24px)',display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(150px,1fr))',gap:14,animation:'slideUp 0.25s ease',boxShadow:'0 8px 40px rgba(0,10,40,0.5)'}}>
            {[{label:'Price',key:'isFree',opts:[{v:'',l:'All'},{v:'true',l:'Free Only'},{v:'false',l:'Paid Only'}]},{label:'Difficulty',key:'difficulty',opts:[{v:'',l:'Any'},{v:'Easy',l:'Easy'},{v:'Medium',l:'Medium'},{v:'Hard',l:'Hard'},{v:'Mixed',l:'Mixed'}]},{label:'Format',key:'batchType',opts:[{v:'',l:'Any'},{v:'Live',l:'🔴 Live'},{v:'Recorded',l:'📹 Recorded'},{v:'Both',l:'🔄 Both'}]}].map(f=>(
              <div key={f.key}>
                <div style={{fontSize:10,color:'rgba(160,200,240,0.5)',marginBottom:8,fontWeight:700,textTransform:'uppercase',letterSpacing:1}}>{f.label}</div>
                <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                  {f.opts.map(o=>{const active=(filters as Record<string,string>)[f.key]===o.v;return<button key={o.v} onClick={()=>setFilters(prev=>({...prev,[f.key]:o.v}))} style={{padding:'5px 10px',borderRadius:20,fontSize:10,cursor:'pointer',background:active?'rgba(77,159,255,0.22)':'rgba(77,159,255,0.06)',border:`1px solid ${active?'rgba(77,159,255,0.5)':'rgba(77,159,255,0.12)'}`,color:active?'#4D9FFF':'rgba(160,200,240,0.5)',transition:'all 0.2s'}}>{o.l}</button>})}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ━━ BATCH GRID ━━ */}
        {loading?(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(250px,1fr))',gap:18}}>
            {[1,2,3,4,5,6].map(i=><div key={i} style={{height:400,background:'rgba(4,12,30,0.8)',borderRadius:20,border:'1px solid rgba(77,159,255,0.08)',animation:'shimmer 1.5s ease infinite',animationDelay:`${i*0.15}s`}}/>)}
          </div>
        ):batches.length===0?<EmptyState/>:(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(250px,1fr))',gap:18}}>
            {batches.map((b,i)=>(
              <div key={b._id} style={{animation:`slideUp ${0.3+i*0.04}s ease both`}}>
                <BatchCard b={b} tok={tok} onUpdate={fetchBatches}/>
              </div>
            ))}
          </div>
        )}

        {/* ━━ NCERT SCIENCE FACTS ━━ */}
        <div style={{marginTop:50}}>
          <div style={{textAlign:'center',marginBottom:22}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:6}}>🔬 NCERT Science Facts</div>
            <div style={{fontSize:12,color:'rgba(160,200,240,0.6)'}}>Essential concepts for NEET 2026 — 100% NCERT Based</div>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:14}}>
            {FACTS.map((f,i)=>(
              <div key={i} style={{background:'rgba(4,12,30,0.95)',border:`1px solid ${f.c}22`,borderRadius:18,padding:18,backdropFilter:'blur(20px)',transition:'all 0.3s',animation:`slideUp ${1.0+i*0.08}s ease`,boxShadow:'0 4px 20px rgba(0,10,40,0.3)'}}
                onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'44'}}
                onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'22'}}>
                <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>
                  <div style={{fontSize:28,filter:`drop-shadow(0 0 10px ${f.c})`,flexShrink:0}}>{f.icon}</div>
                  <div>
                    <div style={{fontWeight:700,color:f.c,fontSize:13,marginBottom:5,fontFamily:'Playfair Display,serif'}}>{f.t}</div>
                    <div style={{fontSize:11,color:'rgba(180,210,240,0.75)',lineHeight:1.65}}>{f.f}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

{/* ━━ WHY PROVERANK ━━ */}
        <div style={{marginTop:40,background:'rgba(4,12,30,0.97)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:24,padding:'28px 20px',backdropFilter:'blur(24px)',boxShadow:'0 12px 50px rgba(0,10,40,0.5)'}}>
          <div style={{textAlign:'center',marginBottom:24}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:'#F0F8FF',marginBottom:6}}>✨ Why Choose ProveRank?</div>
            <div style={{fontSize:12,color:'rgba(160,200,240,0.55)'}}>India's most advanced NEET/JEE test platform</div>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(155px,1fr))',gap:14}}>
            {[{i:'🎯',t:'NEET Pattern',d:'180 Qs · 720 Marks\n+4/−1 · 200 min',c:'#4D9FFF'},{i:'🤖',t:'AI Analytics',d:'Weak areas detection\nSmart revision plan',c:'#9B59B6'},{i:'🔒',t:'Anti-Cheat AI',d:'Webcam · Face AI\nIP Lock · Proctoring',c:'#E74C3C'},{i:'📊',t:'Live Rankings',d:'Real-time AIR\nPercentile calc',c:'#27AE60'},{i:'📄',t:'OMR + PDFs',d:'Bubble view · Certs\nDetailed reports',c:'#E67E22'},{i:'🆓',t:'100% Free',d:'Free hosting\nNo hidden charges',c:'#00D4FF'}].map((f,i)=>(
              <div key={i} style={{background:`rgba(4,12,30,0.8)`,border:`1px solid ${f.c}18`,borderRadius:16,padding:'16px 12px',textAlign:'center',transition:'all 0.3s',cursor:'default'}}
                onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'40'}}
                onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'18'}}>
                <div style={{fontSize:30,marginBottom:10,filter:`drop-shadow(0 0 8px ${f.c}88)`}}>{f.i}</div>
                <div style={{fontWeight:700,color:f.c,fontSize:12,marginBottom:6}}>{f.t}</div>
                <div style={{fontSize:10,color:'rgba(160,200,240,0.55)',lineHeight:1.65,whiteSpace:'pre-line'}}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  )
}
