#!/bin/bash
# ProveRank — Admin Dashboard Fix V2
# Fix 1: Galaxy+Nebula+ShootingStar BG (replaces ParticlesBg)
# Fix 2: SVG Illustrations on Dashboard
# Fix 3: Rich content sections (fills empty space)
# Rule C1: cat > EOF only | Rule C2: NO sed -i | NO python

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }
err(){ echo -e "${Y}[ERR]${N} $1"; exit 1; }

FE=~/workspace/frontend
FILE=$FE/app/admin/x7k2p/page.tsx

step "Verifying file exists"
[ ! -f "$FILE" ] && err "page.tsx not found at $FILE — run Part 1 first!"
log "File found"

step "Backup"
cp "$FILE" "$FILE.bak_$(date +%Y%m%d_%H%M%S)"
log "Backup created"

# ─────────────────────────────────────────────────────────
# Write Node.js fix script to ~/workspace (Rule H3)
# ─────────────────────────────────────────────────────────
step "Writing Node fix script to ~/workspace/fix_dashboard.js"

cat > ~/workspace/fix_dashboard.js << 'NODEEOF'
const fs = require('fs');
const path = require('path');

const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx');
let content = fs.readFileSync(FILE, 'utf8');

// ══════════════════════════════════════════════════════
// FIX 1 — Replace ParticlesBg with GalaxyBg
// ══════════════════════════════════════════════════════
const OLD_BG_START = '// ══════════════════════════════════════════════════════════════\n// PARTICLES BACKGROUND — Same as Login page';
const OLD_BG_END = '  return <canvas ref={canvasRef} style={{position:\'fixed\',inset:0,pointerEvents:\'none\',zIndex:0}}/>\n}';

const sidx = content.indexOf(OLD_BG_START);
const eidx = content.indexOf(OLD_BG_END, sidx);
if (sidx === -1 || eidx === -1) {
  console.error('ERROR: ParticlesBg section not found');
  process.exit(1);
}

const GALAXY_BG = `// ══════════════════════════════════════════════════════════════
// GALAXY BACKGROUND — Stars + Nebula + Shooting Stars + Particles
// ══════════════════════════════════════════════════════════════
function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    let W=window.innerWidth,H=window.innerHeight
    canvas.width=W;canvas.height=H
    // Twinkling stars
    const stars:{x:number;y:number;r:number;op:number;ts:number;tp:number}[]=[]
    for(let i=0;i<200;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.5+0.2,op:Math.random()*0.65+0.15,ts:Math.random()*0.025+0.005,tp:Math.random()*Math.PI*2})
    // Galaxy spiral stars
    const gStars:{x:number;y:number;r:number;op:number}[]=[]
    const cx=W*0.74,cy=H*0.25
    for(let i=0;i<160;i++){const arm=Math.floor(Math.random()*3);const t=Math.random()*Math.PI*3;const sp=Math.random()*50+8;const gx=cx+Math.cos(t+arm*2.09)*sp*(1+t*0.18)+(Math.random()-0.5)*20;const gy=cy+Math.sin(t+arm*2.09)*sp*0.55*(1+t*0.12)+(Math.random()-0.5)*18;gStars.push({x:gx,y:gy,r:Math.random()*1.3+0.2,op:Math.random()*0.5+0.15})}
    // Floating particles
    const particles:{x:number;y:number;vx:number;vy:number;r:number;opacity:number}[]=[]
    for(let i=0;i<50;i++)particles.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.25,vy:(Math.random()-.5)*.25,r:Math.random()*1.2+0.3,opacity:Math.random()*.22+.04})
    // Shooting stars
    const shoots:{x:number;y:number;len:number;spd:number;life:number;maxL:number;active:boolean}[]=[]
    for(let i=0;i<4;i++)shoots.push({x:Math.random()*W,y:Math.random()*H*0.45,len:Math.random()*85+55,spd:Math.random()*5+4,life:0,maxL:Math.random()*55+35,active:Math.random()>0.5})
    let frame=0,animId:number
    const ANG=Math.PI/5
    const draw=()=>{
      ctx.clearRect(0,0,W,H)
      // Deep space base
      const bg=ctx.createRadialGradient(W*0.5,H*0.35,0,W*0.5,H*0.5,W*0.8)
      bg.addColorStop(0,'rgba(4,8,32,1)');bg.addColorStop(0.5,'rgba(1,5,18,1)');bg.addColorStop(1,'rgba(0,2,10,1)')
      ctx.fillStyle=bg;ctx.fillRect(0,0,W,H)
      // Nebula — purple
      const n1=ctx.createRadialGradient(W*0.18,H*0.62,0,W*0.18,H*0.62,W*0.35)
      n1.addColorStop(0,'rgba(75,35,155,0.13)');n1.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n1;ctx.fillRect(0,0,W,H)
      // Nebula — blue
      const n2=ctx.createRadialGradient(W*0.78,H*0.18,0,W*0.78,H*0.18,W*0.3)
      n2.addColorStop(0,'rgba(25,75,175,0.14)');n2.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n2;ctx.fillRect(0,0,W,H)
      // Nebula — teal
      const n3=ctx.createRadialGradient(W*0.88,H*0.78,0,W*0.88,H*0.78,W*0.22)
      n3.addColorStop(0,'rgba(0,155,175,0.08)');n3.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n3;ctx.fillRect(0,0,W,H)
      // Galaxy core glow
      const gc=ctx.createRadialGradient(cx,cy,0,cx,cy,120)
      gc.addColorStop(0,'rgba(110,155,255,0.18)');gc.addColorStop(0.45,'rgba(55,95,195,0.08)');gc.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=gc;ctx.fillRect(0,0,W,H)
      // Galaxy stars
      gStars.forEach(s=>{ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=`rgba(155,195,255,${s.op})`;ctx.fill()})
      // Twinkling stars
      frame++
      stars.forEach(s=>{
        const tw=s.op*(0.45+0.55*Math.sin(frame*s.ts+s.tp))
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=`rgba(215,232,255,${tw})`;ctx.fill()
        if(s.r>1.1){ctx.beginPath();ctx.arc(s.x,s.y,s.r*2.5,0,Math.PI*2);ctx.fillStyle=`rgba(175,210,255,${tw*0.07})`;ctx.fill()}
      })
      // Shooting stars
      shoots.forEach(s=>{
        if(!s.active){s.life++;if(s.life>s.maxL*2.5){s.life=0;s.active=true;s.x=Math.random()*W;s.y=Math.random()*H*0.4;s.maxL=Math.random()*55+35}return}
        s.life++;const prog=s.life/s.maxL
        if(prog>=1){s.active=false;s.life=0;return}
        const op=prog<0.2?prog/0.2:prog>0.8?(1-prog)/0.2:1
        const ex=s.x+Math.cos(ANG)*s.len*prog,ey=s.y+Math.sin(ANG)*s.len*prog
        const sg=ctx.createLinearGradient(s.x,s.y,ex,ey)
        sg.addColorStop(0,'rgba(255,255,255,0)');sg.addColorStop(0.5,`rgba(175,215,255,${op*0.55})`);sg.addColorStop(1,`rgba(255,255,255,${op})`)
        ctx.beginPath();ctx.moveTo(s.x,s.y);ctx.lineTo(ex,ey);ctx.strokeStyle=sg;ctx.lineWidth=1.5;ctx.stroke()
      })
      // Particles + connections
      particles.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0)p.x=W;if(p.x>W)p.x=0;if(p.y<0)p.y=H;if(p.y>H)p.y=0;ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);ctx.fillStyle=`rgba(77,159,255,${p.opacity})`;ctx.fill()})
      for(let i=0;i<particles.length;i++)for(let j=i+1;j<particles.length;j++){const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy);if(dist<110){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=`rgba(77,159,255,${.07*(1-dist/110)})`;ctx.lineWidth=.4;ctx.stroke()}}
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=()=>{W=window.innerWidth;H=window.innerHeight;canvas.width=W;canvas.height=H}
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}`;

content = content.slice(0, sidx) + GALAXY_BG + content.slice(eidx + OLD_BG_END.length);
console.log('Fix 1 DONE: GalaxyBg installed');

// ══════════════════════════════════════════════════════
// FIX 2 & 3 — Dashboard: SVG Illustrations + rich content
// Replace from dashboard section start to closing ))}
// ══════════════════════════════════════════════════════
const DASH_START = "          {/* ══ DASHBOARD ══ */}\n          {tab==='dashboard'&&(";
const DASH_END   = "          {/* ══ GLOBAL SEARCH ══ */}";

const ds = content.indexOf(DASH_START);
const de = content.indexOf(DASH_END);
if (ds === -1 || de === -1) { console.error('ERROR: Dashboard section not found'); process.exit(1); }

const NEW_DASH = `          {/* ══ DASHBOARD ══ */}
          {tab==='dashboard'&&(
            <div>
              <div style={{marginBottom:20}}>
                <div style={pageTitle}>📊 Dashboard Overview</div>
                <div style={pageSub}>Welcome back, {role==='superadmin'?'Super Admin':'Admin'} — Here is your platform at a glance</div>
              </div>

              {/* Stats Row */}
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:20}}>\n                <StatBox ico='👥' lbl='Total Students' val={loading?'…':stats?.totalStudents||(students||[]).length||0} col={ACC}/>
                <StatBox ico='📝' lbl='Total Exams' val={loading?'…':stats?.totalExams||(exams||[]).length||0} col={GOLD}/>
                <StatBox ico='📈' lbl='Exam Attempts' val={loading?'…':stats?.totalAttempts||'—'} col={SUC}/>
                <StatBox ico='🟢' lbl='Active Today' val={loading?'…':stats?.activeStudents||'—'} col='#00E5FF'/>
                <StatBox ico='❓' lbl='Questions' val={loading?'…':stats?.totalQuestions||(questions||[]).length||0} col='#FF6B9D'/>
              </div>

              {/* Hero Banner */}
              <div style={{background:'linear-gradient(135deg,rgba(0,85,204,0.25),rgba(77,159,255,0.1))',border:'1px solid rgba(77,159,255,0.25)',borderRadius:16,padding:'24px 20px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',right:-20,top:-20,fontSize:100,opacity:0.06}}>⬡</div>
                <div style={{position:'absolute',right:30,top:20,fontSize:60,opacity:0.08}}>⬡</div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:TS,marginBottom:6}}>🎯 ProveRank Admin Center</div>
                <div style={{fontSize:12,color:DIM,lineHeight:1.7,maxWidth:500}}>Manage your complete NEET test platform from here. Create exams, monitor students, review analytics, and keep your platform running smoothly.</div>
                <div style={{display:'flex',flexWrap:'wrap',gap:8,marginTop:14}}>
                  {([['➕ Create Exam','create_exam',ACC],['👥 All Students','students',SUC],['🔴 Live Monitor','live',DNG],['📊 Analytics','analytics',GOLD]] as [string,string,string][]).map(([l,t,c])=>(
                    <button key={t} onClick={()=>setTab(t)} style={{padding:'8px 16px',background:c+'22',border:'1px solid '+c+'44',color:c,borderRadius:20,cursor:'pointer',fontSize:12,fontWeight:600}}>{l}</button>
                  ))}
                </div>
              </div>

              {/* SVG Illustration Cards */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginBottom:20}}>
                <div style={{...cs,textAlign:'center',padding:'18px 10px'}}>
                  <svg viewBox="0 0 110 100" width="90" style={{display:'block',margin:'0 auto 10px'}} xmlns="http://www.w3.org/2000/svg">
                    <circle cx="55" cy="30" r="16" fill="rgba(77,159,255,0.15)" stroke="rgba(77,159,255,0.6)" strokeWidth="1.5"/>
                    <circle cx="55" cy="26" r="7" fill="rgba(77,159,255,0.7)"/>
                    <path d="M38 50 Q55 44 72 50 L74 72 Q55 78 36 72 Z" fill="rgba(0,22,40,0.85)" stroke="rgba(77,159,255,0.5)" strokeWidth="1.2"/>
                    <rect x="42" y="55" width="26" height="3" rx="1.5" fill="rgba(77,159,255,0.6)"/>
                    <rect x="42" y="61" width="20" height="2.5" rx="1.2" fill="rgba(77,159,255,0.4)"/>
                    <rect x="42" y="67" width="16" height="2.5" rx="1.2" fill="rgba(77,159,255,0.3)"/>
                    <circle cx="55" cy="30" r="24" fill="none" stroke="rgba(77,159,255,0.1)" strokeWidth="1" strokeDasharray="3,5"/>
                  </svg>
                  <div style={{fontSize:11,fontWeight:700,color:ACC,marginBottom:3}}>Students</div>
                  <div style={{fontSize:22,fontWeight:900,color:TS}}>{(students||[]).length}</div>
                  <div style={{fontSize:10,color:DIM}}>Registered learners</div>
                </div>
                <div style={{...cs,textAlign:'center',padding:'18px 10px'}}>
                  <svg viewBox="0 0 110 100" width="90" style={{display:'block',margin:'0 auto 10px'}} xmlns="http://www.w3.org/2000/svg">
                    <rect x="20" y="15" width="70" height="78" rx="6" fill="rgba(0,22,40,0.85)" stroke="rgba(255,215,0,0.45)" strokeWidth="1.5"/>
                    <rect x="32" y="25" width="46" height="5" rx="2.5" fill="rgba(255,215,0,0.75)"/>
                    <rect x="32" y="34" width="32" height="3" rx="1.5" fill="rgba(77,159,255,0.5)"/>
                    <rect x="32" y="44" width="20" height="3" rx="1.5" fill="rgba(200,220,255,0.35)"/>
                    <circle cx="58" cy="45.5" r="3.5" fill="rgba(0,196,140,0.75)" stroke="rgba(77,159,255,0.3)" strokeWidth="1"/>
                    <rect x="32" y="52" width="20" height="3" rx="1.5" fill="rgba(200,220,255,0.35)"/>
                    <circle cx="58" cy="53.5" r="3.5" fill="rgba(0,196,140,0.75)" stroke="rgba(77,159,255,0.3)" strokeWidth="1"/>
                    <rect x="32" y="60" width="20" height="3" rx="1.5" fill="rgba(200,220,255,0.35)"/>
                    <circle cx="58" cy="61.5" r="3.5" fill="rgba(77,159,255,0.6)" stroke="rgba(77,159,255,0.3)" strokeWidth="1"/>
                    <path d="M78 72 L85 65 L87 67 L80 75 Z" fill="rgba(255,215,0,0.85)"/>
                    <line x1="84" y1="63" x2="91" y2="56" stroke="rgba(255,215,0,0.6)" strokeWidth="2"/>
                  </svg>
                  <div style={{fontSize:11,fontWeight:700,color:GOLD,marginBottom:3}}>Exams</div>
                  <div style={{fontSize:22,fontWeight:900,color:TS}}>{(exams||[]).length}</div>
                  <div style={{fontSize:10,color:DIM}}>Created on platform</div>
                </div>
                <div style={{...cs,textAlign:'center',padding:'18px 10px'}}>
                  <svg viewBox="0 0 110 100" width="90" style={{display:'block',margin:'0 auto 10px'}} xmlns="http://www.w3.org/2000/svg">
                    <rect x="12" y="66" width="86" height="26" rx="4" fill="rgba(0,22,40,0.85)" stroke="rgba(0,196,140,0.4)" strokeWidth="1.2"/>
                    <rect x="28" y="52" width="54" height="15" rx="3" fill="rgba(0,22,40,0.8)" stroke="rgba(0,196,140,0.3)" strokeWidth="1"/>
                    <rect x="44" y="38" width="22" height="15" rx="2" fill="rgba(0,22,40,0.8)" stroke="rgba(0,196,140,0.3)" strokeWidth="1"/>
                    <polygon points="50,18 55,10 60,18" fill="rgba(0,196,140,0.85)"/>
                    <line x1="55" y1="10" x2="55" y2="6" stroke="rgba(0,196,140,0.6)" strokeWidth="1.5"/>
                    <circle cx="55" cy="4" r="3" fill="rgba(0,196,140,0.95)"/>
                    <rect x="20" y="72" width="9" height="13" rx="2" fill="rgba(77,159,255,0.3)"/>
                    <rect x="50" y="72" width="9" height="13" rx="2" fill="rgba(77,159,255,0.3)"/>
                    <rect x="80" y="72" width="9" height="13" rx="2" fill="rgba(77,159,255,0.3)"/>
                  </svg>
                  <div style={{fontSize:11,fontWeight:700,color:SUC,marginBottom:3}}>Features</div>
                  <div style={{fontSize:22,fontWeight:900,color:TS}}>{features.filter((f:any)=>f.enabled).length}/{features.length}</div>
                  <div style={{fontSize:10,color:DIM}}>Enabled on platform</div>
                </div>
              </div>

              {/* 2-col grid */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:14}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <span>📝 Recent Exams</span>
                    <button onClick={()=>setTab('exams')} style={{...bg_,padding:'4px 10px',fontSize:10}}>View All</button>
                  </div>
                  {(exams||[]).length===0
                    ?<div style={{textAlign:'center',padding:'20px 0',color:DIM}}>
                      <div style={{fontSize:30,marginBottom:8}}>📭</div>
                      <div style={{fontSize:12}}>No exams yet</div>
                      <button onClick={()=>setTab('create_exam')} style={{...bp,fontSize:11,padding:'6px 14px',marginTop:8}}>Create First Exam</button>
                    </div>
                    :(exams||[]).slice(0,4).map((e:any)=>(
                      <div key={e._id} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:'1px solid '+BOR,fontSize:12}}>
                        <div>
                          <div style={{fontWeight:600,color:TS}}>{e.title}</div>
                          <div style={{fontSize:10,color:DIM,marginTop:2}}>{e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():''}</div>
                        </div>
                        <Badge label={e.status||'draft'} col={e.status==='active'?SUC:e.status==='published'?ACC:DIM}/>
                      </div>
                    ))
                  }
                </div>
                <div>
                  <div style={{...cs,marginBottom:12}}>
                    <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>🚨 Alerts</div>
                    {(flags||[]).length===0&&(tickets||[]).filter((t:any)=>t.status==='open').length===0
                      ?<div style={{color:SUC,fontSize:12,display:'flex',alignItems:'center',gap:6}}><span style={{fontSize:20}}>✅</span> All clear — no alerts</div>
                      :<div>
                        {(flags||[]).length>0&&<div style={{fontSize:12,color:WRN,marginBottom:6,padding:'6px 10px',background:'rgba(255,184,77,0.08)',borderRadius:8}}>⚠️ {flags.length} cheating flag{flags.length>1?'s':''}</div>}
                        {(tickets||[]).filter((t:any)=>t.status==='open').length>0&&<div style={{fontSize:12,color:ACC,padding:'6px 10px',background:'rgba(77,159,255,0.08)',borderRadius:8}}>🎫 {tickets.filter((t:any)=>t.status==='open').length} open ticket</div>}
                      </div>
                    }
                  </div>
                  <div style={cs}>
                    <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>⚡ Quick Actions</div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6}}>
                      {([['➕ Exam','create_exam'],['❓ Question','questions'],['📢 Announce','announcements'],['💾 Backup','backup']] as [string,string][]).map(([l,t])=>(
                        <button key={t} onClick={()=>setTab(t)} style={{...bg_,textAlign:'center',fontSize:11,padding:'8px 6px'}}>{l}</button>
                      ))}
                    </div>
                    <div style={{marginTop:10,fontSize:11,color:DIM,display:'flex',gap:12}}>
                      <span>📦 {(batches||[]).length} Batches</span>
                      <span>🛡️ {(adminUsers||[]).length} Admins</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Bottom row — Top Students / Flags / Health */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:12,marginBottom:16}}>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🏆 Top Students</div>
                  {(students||[]).filter((s:any)=>!s.banned).slice(0,4).map((s:any,i:number)=>(
                    <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'5px 0',borderBottom:'1px solid '+BOR,fontSize:11}}>
                      <span style={{width:20,height:20,borderRadius:'50%',background:i===0?GOLD:i===1?'#C0C0C0':i===2?'#CD7F32':CRD2,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:10,color:i<3?'#000':DIM,flexShrink:0}}>{i+1}</span>
                      <span style={{flex:1,fontWeight:500,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</span>
                    </div>
                  ))}
                  {(students||[]).length===0&&<div style={{color:DIM,fontSize:11,textAlign:'center',padding:'10px 0'}}>No students yet</div>}
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🚨 Recent Flags</div>
                  {(flags||[]).length===0
                    ?<div style={{color:SUC,fontSize:11,textAlign:'center',padding:'10px 0'}}>✅ No cheating flags</div>
                    :(flags||[]).slice(0,4).map((f:any,i:number)=>(
                      <div key={f._id||i} style={{fontSize:11,padding:'5px 0',borderBottom:'1px solid '+BOR,color:DIM}}>
                        <span style={{color:f.severity==='high'?DNG:WRN,fontWeight:600}}>{f.type}</span> — {f.studentName||'—'}
                      </div>
                    ))
                  }
                </div>
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:8,fontSize:12}}>📊 Platform Health</div>
                  {([['Students',(students||[]).filter((s:any)=>!s.banned).length+'/'+(students||[]).length,SUC],['Exams',(exams||[]).filter((e:any)=>e.status==='active').length+' active',ACC],['Questions',(questions||[]).length+' in bank',GOLD],['Features',features.filter((f:any)=>f.enabled).length+'/'+features.length+' on','#FF6B9D']] as [string,string,string][]).map(([l,v,c])=>(
                    <div key={l} style={{display:'flex',justifyContent:'space-between',fontSize:11,padding:'4px 0',borderBottom:'1px solid '+BOR}}>
                      <span style={{color:DIM}}>{l}</span><span style={{color:c,fontWeight:600}}>{v}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Admin Getting-Started Guide + Platform Overview */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16}}>
                <div style={{...cs,background:'linear-gradient(135deg,rgba(0,85,204,0.18),rgba(0,22,40,0.75))'}}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13,color:ACC}}>🚀 Admin Quick-Start Guide</div>
                  {([['1','Create a Batch','Students → Batches — add a group first','students'],['2','Add Questions','Question Bank → add manually or bulk upload','questions'],['3','Create Exam','All Exams → Create — fill title, duration, questions','create_exam'],['4','Monitor Live','Live Monitor → watch students attempt in real-time','live']] as [string,string,string,string][]).map(([n,title,desc,t])=>(
                    <div key={n} onClick={()=>setTab(t)} style={{display:'flex',gap:10,padding:'8px 0',borderBottom:'1px solid '+BOR,cursor:'pointer'}} className="card-hover">
                      <div style={{width:22,height:22,borderRadius:'50%',background:ACC+'22',border:'1px solid '+ACC+'44',display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:ACC,flexShrink:0}}>{n}</div>
                      <div>
                        <div style={{fontSize:12,fontWeight:600,color:TS}}>{title}</div>
                        <div style={{fontSize:10,color:DIM,marginTop:2}}>{desc}</div>
                      </div>
                    </div>
                  ))}
                </div>
                <div style={{...cs,background:'linear-gradient(135deg,rgba(0,100,80,0.15),rgba(0,22,40,0.75))'}}>
                  <div style={{fontWeight:700,marginBottom:12,fontSize:13,color:SUC}}>📋 Platform Summary</div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                    {([['👥','Students',(students||[]).length+' total',ACC],['📝','Exams',(exams||[]).length+' created',GOLD],['❓','Questions',(questions||[]).length+' in bank','#FF6B9D'],['🛡️','Admins',(adminUsers||[]).length+' active',SUC],['📦','Batches',(batches||[]).length+' groups','#00E5FF'],['🚩','Flags',(flags||[]).length+' total',(flags||[]).length>0?DNG:SUC]] as [string,string,string,string][]).map(([ico,lbl,val,col])=>(
                      <div key={lbl} style={{background:'rgba(0,0,0,0.2)',borderRadius:10,padding:'10px',border:'1px solid '+BOR}}>
                        <div style={{fontSize:18,marginBottom:4}}>{ico}</div>
                        <div style={{fontSize:10,color:DIM}}>{lbl}</div>
                        <div style={{fontSize:12,fontWeight:700,color:col}}>{val}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Student Journey Banner */}
              <div style={{...cs,background:'linear-gradient(135deg,rgba(77,159,255,0.08),rgba(0,22,40,0.75))',marginBottom:4}}>
                <div style={{fontWeight:700,marginBottom:14,fontSize:13,color:TS}}>🎓 Student Journey on ProveRank</div>
                <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:6}}>
                  {(['📝|Register|Signs up & verifies','📚|Practice|PYQ Bank & Mini Tests','🎯|Attempt|Live exam + anti-cheat','📊|Analyse|Results & AIR Rank','🏆|Improve|Certificates & study plan']).map((item,i,arr)=>{const [ico,t,d]=item.split('|');return(
                    <div key={t} style={{display:'flex',alignItems:'center',gap:5}}>
                      <div style={{textAlign:'center',minWidth:56}}>
                        <div style={{fontSize:20,marginBottom:3}}>{ico}</div>
                        <div style={{fontSize:11,fontWeight:700,color:ACC}}>{t}</div>
                        <div style={{fontSize:9,color:DIM,lineHeight:1.4,maxWidth:62}}>{d}</div>
                      </div>
                      {i<arr.length-1&&<div style={{fontSize:14,color:'rgba(77,159,255,0.35)',flexShrink:0,marginBottom:12}}>→</div>}
                    </div>
                  )})}
                </div>
              </div>
            </div>
          )}

          `;

content = content.slice(0, ds) + NEW_DASH + content.slice(de);
console.log('Fix 2+3 DONE: Dashboard SVG illustrations + rich content added');

fs.writeFileSync(FILE, content, 'utf8');
console.log('File saved successfully.');
NODEEOF

log "Node fix script written"

# ─────────────────────────────────────────────────────────
# Run the Node script
# ─────────────────────────────────────────────────────────
step "Running fix_dashboard.js"
cd ~/workspace
node fix_dashboard.js
[ $? -ne 0 ] && err "Node script failed — check errors above"
log "Node script completed"

# ─────────────────────────────────────────────────────────
# TypeScript check
# ─────────────────────────────────────────────────────────
step "TypeScript syntax check"
cd ~/workspace/frontend
npx tsc --noEmit --skipLibCheck 2>&1 | tail -15
log "TS check done (warnings ok, only errors matter)"

# ─────────────────────────────────────────────────────────
# Git push
# ─────────────────────────────────────────────────────────
step "Git push"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix: Admin Dashboard — Galaxy BG + SVG Illustrations + Rich Content V2"
git push origin main
[ $? -ne 0 ] && err "Git push failed"

echo ""
echo -e "${G}════════════════════════════════════════${N}"
echo -e "${G}  ALL 3 FIXES DONE!${N}"
echo -e "${G}  Wait 2-3 min → Vercel deploy${N}"
echo -e "${G}  Then check: https://prove-rank.vercel.app/admin/x7k2p${N}"
echo -e "${G}════════════════════════════════════════${N}"
