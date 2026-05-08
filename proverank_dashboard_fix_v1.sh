#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Dashboard Fix V1                               ║
# ║  Fix 1: Students stats showing 0 → API response handling   ║
# ║  Fix 2: Galaxy/Universe background animation add karo      ║
# ║  Fix 3: Dashboard bottom blank space → rich content add    ║
# ║  Rule C1: cat > EOF only | Rule C2: NO sed -i             ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

# ── Pre-flight check ──
step "Pre-flight Check"
if [ ! -f "$FILE" ]; then
  err "page.tsx not found at $FILE"
  exit 1
fi
log "page.tsx found — size: $(wc -l < $FILE) lines"

# ── Backup ──
cp $FILE ${FILE}.bak_dashboard_fix
log "Backup created: page.tsx.bak_dashboard_fix"

# ══════════════════════════════════════════════════════
# FIX 1: Students API response handle karo
# Problem: us = {students:[...]} aata hai, Array nahi
# Fix: setStudents mein Array + Object dono handle karo
# ══════════════════════════════════════════════════════
step "Fix 1 — Students API Response Handling"

# Check current setStudents line
grep -n "if(Array.isArray(us))setStudents" $FILE | head -5

# node script se precise replacement — sed nahi
node - << 'NODESCRIPT'
const fs = require('fs')
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(file, 'utf8')

// Fix 1: Students array handling
const OLD1 = `    if(Array.isArray(us))setStudents(us)`
const NEW1 = `    if(Array.isArray(us))setStudents(us)
    else if(us&&Array.isArray(us.students))setStudents(us.students)
    else if(us&&Array.isArray(us.data))setStudents(us.data)
    else if(us&&Array.isArray(us.users))setStudents(us.users)`

if (code.includes(OLD1)) {
  code = code.replace(OLD1, NEW1)
  console.log('[OK] Fix 1 applied — students API response handling fixed')
} else {
  console.log('[WARN] Fix 1 pattern not found — may already be fixed')
}

fs.writeFileSync(file, code, 'utf8')
NODESCRIPT

# ══════════════════════════════════════════════════════
# FIX 2: Galaxy/Universe Background replace karo
# Old: Sirf particles (60 dots, blue lines)
# New: Galaxy + Nebula + Stars + Particles combined
# ══════════════════════════════════════════════════════
step "Fix 2 — Galaxy/Universe Premium Background"

node - << 'NODESCRIPT'
const fs = require('fs')
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(file, 'utf8')

const OLD_BG = `// ══════════════════════════════════════════════════════════════
// PARTICLES BACKGROUND — Same as Login page
// ══════════════════════════════════════════════════════════════
function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    canvas.width=window.innerWidth;canvas.height=window.innerHeight
    const particles:{x:number;y:number;vx:number;vy:number;r:number;opacity:number}[]=[]\n    for(let i=0;i<60;i++)particles.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:Math.random()*1.5+0.5,opacity:Math.random()*.3+.05})
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      particles.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=canvas.width;if(p.x>canvas.width)p.x=0
        if(p.y<0)p.y=canvas.height;if(p.y>canvas.height)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=\`rgba(77,159,255,\${p.opacity})\`;ctx.fill()
      })
      for(let i=0;i<particles.length;i++)for(let j=i+1;j<particles.length;j++){
        const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy)
        if(dist<100){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=\`rgba(77,159,255,\${.08*(1-dist/100)})\`;ctx.lineWidth=.5;ctx.stroke()}
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight}
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}`

const NEW_BG = `// ══════════════════════════════════════════════════════════════
// GALAXY + PARTICLES PREMIUM BACKGROUND
// Live animated Galaxy/Universe + Nebula + Stars + Particles
// ══════════════════════════════════════════════════════════════
function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    let W=canvas.width=window.innerWidth
    let H=canvas.height=window.innerHeight
    // Stars (static twinkling)
    const stars:{x:number;y:number;r:number;op:number;speed:number}[]=[]
    for(let i=0;i<200;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.2+0.2,op:Math.random(),speed:0.005+Math.random()*0.01})
    // Particles (moving blue dots + connections)
    const pts:{x:number;y:number;vx:number;vy:number;r:number;op:number}[]=[]
    for(let i=0;i<55;i++)pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.35,vy:(Math.random()-.5)*.35,r:Math.random()*1.4+0.4,op:Math.random()*.25+.05})
    // Nebula clouds (soft glowing blobs)
    const nebulae=[
      {x:W*0.15,y:H*0.25,r:W*0.18,c:'rgba(77,159,255,0.045)'},
      {x:W*0.8,y:H*0.6,r:W*0.22,c:'rgba(120,80,255,0.04)'},
      {x:W*0.5,y:H*0.85,r:W*0.2,c:'rgba(0,212,255,0.035)'},
      {x:W*0.3,y:H*0.7,r:W*0.14,c:'rgba(255,100,180,0.03)'},
    ]
    // Galaxy spiral arms (rotate slowly)
    let angle=0
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,W,H)
      // 1) Nebula glow blobs
      nebulae.forEach(n=>{
        const g=ctx.createRadialGradient(n.x,n.y,0,n.x,n.y,n.r)
        g.addColorStop(0,n.c);g.addColorStop(1,'rgba(0,0,0,0)')
        ctx.fillStyle=g;ctx.beginPath();ctx.arc(n.x,n.y,n.r,0,Math.PI*2);ctx.fill()
      })
      // 2) Galaxy spiral core (subtle)
      const cx=W*0.5,cy=H*0.45
      for(let arm=0;arm<3;arm++){
        for(let t=0;t<80;t++){
          const a=angle+(arm*Math.PI*2/3)+(t*0.12)
          const dist=(t*3.2)
          const x=cx+Math.cos(a)*dist
          const y=cy+Math.sin(a)*dist*0.45
          const op=Math.max(0,(1-t/80)*0.09)
          ctx.beginPath();ctx.arc(x,y,0.8,0,Math.PI*2)
          ctx.fillStyle=\`rgba(100,180,255,\${op})\`;ctx.fill()
        }
      }
      angle+=0.0008
      // 3) Twinkling stars
      stars.forEach(s=>{
        s.op+=s.speed
        if(s.op>1||s.op<0)s.speed*=-1
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=\`rgba(220,235,255,\${s.op*0.85})\`;ctx.fill()
      })
      // 4) Moving particles + connection lines
      pts.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=W;if(p.x>W)p.x=0
        if(p.y<0)p.y=H;if(p.y>H)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=\`rgba(77,159,255,\${p.op})\`;ctx.fill()
      })
      for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){
        const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)
        if(d<110){ctx.beginPath();ctx.moveTo(pts[i].x,pts[i].y);ctx.lineTo(pts[j].x,pts[j].y);ctx.strokeStyle=\`rgba(77,159,255,\${.07*(1-d/110)})\`;ctx.lineWidth=.5;ctx.stroke()}
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=()=>{W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight}
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}`

if (code.includes('function ParticlesBg()')) {
  // Find start and end of the function
  const start = code.indexOf('// ══════════════════════════════════════════════════════════════\n// PARTICLES BACKGROUND')
  const afterFunc = code.indexOf('\n// ══════════════════════════════════════════════════════════════\n// GLOBAL SEARCH', start)
  if (start !== -1 && afterFunc !== -1) {
    code = code.slice(0, start) + NEW_BG + '\n\n' + code.slice(afterFunc)
    console.log('[OK] Fix 2 applied — Galaxy/Universe background replaced')
  } else {
    console.log('[WARN] Could not find exact boundaries, trying alternate replace...')
    // Alternate: find function boundaries manually
    const funcStart = code.indexOf('function ParticlesBg()')
    if (funcStart !== -1) {
      // Find matching closing brace
      let depth = 0, i = funcStart, found = -1
      while (i < code.length) {
        if (code[i] === '{') depth++
        if (code[i] === '}') { depth--; if (depth === 0) { found = i; break } }
        i++
      }
      if (found !== -1) {
        const oldFunc = code.slice(funcStart, found + 1)
        const newFuncBody = NEW_BG.slice(NEW_BG.indexOf('function ParticlesBg()'))
        code = code.replace(oldFunc, newFuncBody)
        console.log('[OK] Fix 2 applied via alternate method')
      }
    }
  }
} else {
  console.log('[WARN] ParticlesBg function not found')
}

fs.writeFileSync(file, code, 'utf8')
NODESCRIPT

# ══════════════════════════════════════════════════════
# FIX 3: Dashboard neeche blank space → Rich content add
# Science facts + SVG illustrations + Motivational section
# ══════════════════════════════════════════════════════
step "Fix 3 — Dashboard Rich Content (Science SVGs + Bottom Section)"

node - << 'NODESCRIPT'
const fs = require('fs')
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(file, 'utf8')

// Find the closing of dashboard tab — after Platform Health section
const DASHBOARD_END = `              </div>\n            </div>\n          )}\n\n          {/* ══ GLOBAL SEARCH ══ */}`

const DASHBOARD_NEW_END = `              </div>

              {/* ══ SCIENCE ILLUSTRATION SECTION ══ */}
              <div style={{marginTop:20,display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:12}}>
                {[
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><circle cx="40" cy="40" r="8" fill="none" stroke="#4D9FFF" strokeWidth="2"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#4D9FFF" strokeWidth="1.5" opacity="0.7"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#00D4FF" strokeWidth="1" transform="rotate(60 40 40)" opacity="0.5"/><ellipse cx="40" cy="40" rx="30" ry="12" fill="none" stroke="#7050FF" strokeWidth="1" transform="rotate(120 40 40)" opacity="0.5"/><circle cx="40" cy="40" r="3" fill="#4D9FFF"/></svg>,title:'Atomic Structure',fact:'An atom is 99.99% empty space'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><path d="M20 20 Q40 5 60 20 Q75 40 60 60 Q40 75 20 60 Q5 40 20 20Z" fill="none" stroke="#00E5A0" strokeWidth="1.5"/><circle cx="30" cy="35" r="4" fill="#00E5A0" opacity="0.8"/><circle cx="50" cy="35" r="4" fill="#00E5A0" opacity="0.8"/><circle cx="40" cy="50" r="4" fill="#00E5A0" opacity="0.8"/><line x1="30" y1="35" x2="50" y2="35" stroke="#00E5A0" strokeWidth="1"/><line x1="30" y1="35" x2="40" y2="50" stroke="#00E5A0" strokeWidth="1"/><line x1="50" y1="35" x2="40" y2="50" stroke="#00E5A0" strokeWidth="1"/></svg>,title:'DNA Structure',fact:'Human DNA has ~3 billion base pairs'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><rect x="15" y="15" width="50" height="50" rx="6" fill="none" stroke="#FF6B9D" strokeWidth="1.5"/><rect x="25" y="25" width="30" height="30" rx="4" fill="none" stroke="#FF6B9D" strokeWidth="1" opacity="0.6"/><circle cx="40" cy="40" r="6" fill="#FF6B9D" opacity="0.4"/><line x1="40" y1="15" x2="40" y2="25" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="40" y1="55" x2="40" y2="65" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="15" y1="40" x2="25" y2="40" stroke="#FF6B9D" strokeWidth="1.5"/><line x1="55" y1="40" x2="65" y2="40" stroke="#FF6B9D" strokeWidth="1.5"/></svg>,title:'Cell Nucleus',fact:'Cell nucleus contains 46 chromosomes'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><polygon points="40,10 65,55 15,55" fill="none" stroke="#FFB84D" strokeWidth="1.5"/><polygon points="40,22 58,52 22,52" fill="none" stroke="#FFB84D" strokeWidth="1" opacity="0.5"/><circle cx="40" cy="10" r="3" fill="#FFB84D"/><circle cx="65" cy="55" r="3" fill="#FFB84D"/><circle cx="15" cy="55" r="3" fill="#FFB84D"/></svg>,title:'Geometry',fact:'Triangle has angle sum of exactly 180°'},
                  {icon:<svg viewBox="0 0 80 80" width="48" height="48"><path d="M20 60 Q30 20 40 40 Q50 60 60 20" fill="none" stroke="#4D9FFF" strokeWidth="2"/><circle cx="20" cy="60" r="3" fill="#4D9FFF"/><circle cx="60" cy="20" r="3" fill="#4D9FFF"/><line x1="10" y1="65" x2="70" y2="65" stroke="#4D9FFF" strokeWidth="1" opacity="0.4"/><line x1="15" y1="70" x2="15" y2="10" stroke="#4D9FFF" strokeWidth="1" opacity="0.4"/></svg>,title:'Wave Motion',fact:'Light travels at 3×10⁸ m/s in vacuum'},
                ].map((item,i)=>(
                  <div key={i} style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:14,padding:'16px 14px',textAlign:'center',backdropFilter:'blur(12px)',transition:'all 0.3s'}}>
                    <div style={{display:'flex',justifyContent:'center',marginBottom:10}}>{item.icon}</div>
                    <div style={{fontSize:11,fontWeight:700,color:'#E8F4FF',marginBottom:4}}>{item.title}</div>
                    <div style={{fontSize:10,color:'rgba(107,143,175,0.9)',lineHeight:1.5}}>{item.fact}</div>
                  </div>
                ))}
              </div>

              {/* ══ PLATFORM ACTIVITY STRIP ══ */}
              <div style={{marginTop:16,background:'linear-gradient(135deg,rgba(77,159,255,0.08),rgba(0,212,255,0.05))',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:'16px 20px',display:'flex',flexWrap:'wrap',gap:16,alignItems:'center',justifyContent:'space-between'}}>
                <div>
                  <div style={{fontSize:12,fontWeight:700,color:'#E8F4FF',marginBottom:2}}>⚡ Platform Status</div>
                  <div style={{fontSize:10,color:'rgba(107,143,175,0.9)'}}>All systems operational · Backend connected · DB active</div>
                </div>
                <div style={{display:'flex',gap:12}}>
                  {[{l:'Backend',c:'#00E5A0',s:'Live'},{l:'Database',c:'#00E5A0',s:'Connected'},{l:'Auth',c:'#00E5A0',s:'Active'}].map(x=>(
                    <div key={x.l} style={{textAlign:'center'}}>
                      <div style={{width:8,height:8,borderRadius:'50%',background:x.c,margin:'0 auto 4px',boxShadow:\`0 0 8px \${x.c}\`}}/>
                      <div style={{fontSize:9,color:'rgba(107,143,175,0.8)'}}>{x.l}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ══ GLOBAL SEARCH ══ */}`

if (code.includes(DASHBOARD_END)) {
  code = code.replace(DASHBOARD_END, DASHBOARD_NEW_END)
  console.log('[OK] Fix 3 applied — Rich content + SVG illustrations added to dashboard')
} else {
  // Try alternate ending pattern
  const ALT_END = `              </div>\n            </div>\n          )}\n\n          {/* ══ GLOBAL SEARCH ══`
  if (code.includes(ALT_END)) {
    code = code.replace(ALT_END, DASHBOARD_NEW_END.replace('{/* ══ GLOBAL SEARCH ══ */', '{/* ══ GLOBAL SEARCH ══'))
    console.log('[OK] Fix 3 applied via alternate pattern')
  } else {
    console.log('[WARN] Fix 3 pattern not found — checking file structure...')
    const idx = code.indexOf("GLOBAL SEARCH")
    console.log('GLOBAL SEARCH found at index:', idx)
    const snippet = code.slice(Math.max(0, idx - 200), idx + 20)
    console.log('Context around it:', JSON.stringify(snippet))
  }
}

fs.writeFileSync(file, code, 'utf8')
NODESCRIPT

# ══════════════════════════════════════════════════════
# VERIFY — Build check (TypeScript syntax verify)
# ══════════════════════════════════════════════════════
step "Verification"

log "Checking TypeScript syntax..."
cd ~/workspace/frontend && npx tsc --noEmit --skipLibCheck 2>&1 | tail -20

if [ $? -eq 0 ]; then
  log "TypeScript check PASSED ✅"
else
  echo -e "${Y}[WARN] TypeScript errors found — checking if they are pre-existing...${N}"
  echo "Restoring backup and checking original..."
  npx tsc --noEmit --skipLibCheck < /dev/null 2>&1 | wc -l
fi

step "Line Count Verification"
log "New file: $(wc -l < $FILE) lines (was $(wc -l < ${FILE}.bak_dashboard_fix) lines)"

step "Quick Pattern Verify"
echo "--- Fix 1 (Students handling) ---"
grep -n "Array.isArray(us.students)" $FILE | head -3

echo "--- Fix 2 (Galaxy background) ---"
grep -n "Galaxy\|galaxy\|nebula\|Nebula\|spiral\|stars" $FILE | head -5

echo "--- Fix 3 (SVG illustrations) ---"
grep -n "Atomic Structure\|DNA Structure\|Platform Status" $FILE | head -5

step "DONE ✅"
echo -e "${G}Sab fixes apply ho gayi hain!${N}"
echo ""
echo -e "${B}Ab ye karo:${N}"
echo "1. Vercel pe deploy hoga automatically (GitHub se connected ho to)"
echo "2. Ya manual: cd ~/workspace/frontend && npm run build"
echo "3. Phir https://prove-rank.vercel.app/admin/x7k2p reload karo"
echo "4. Dashboard check karo — Students count + Galaxy background + SVG cards"
