#!/bin/bash
# ProveRank — Galaxy Fix V3
# Function naam hai GalaxyBg (ParticlesBg nahi)
# Direct content replace via JS file

G='\033[0;32m'; B='\033[0;34m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; exit 1; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
FIXER=/tmp/galaxy_fixer_v3.js

[ ! -f "$FILE" ] && err "page.tsx not found!"
cp $FILE ${FILE}.bak_galaxy3
log "Backup done"

cat > $FIXER << 'JSEOF'
const fs = require('fs')
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(FILE, 'utf8')

// Find GalaxyBg function
const FNAME = 'function GalaxyBg()'
const startIdx = code.indexOf(FNAME)
if (startIdx === -1) {
  // Also try ParticlesBg
  const alt = code.indexOf('function ParticlesBg()')
  if (alt === -1) { console.log('[ERR] No background function found!'); process.exit(1) }
  console.log('[INFO] Found ParticlesBg instead')
}
const actualStart = code.indexOf(FNAME) !== -1 ? code.indexOf(FNAME) : code.indexOf('function ParticlesBg()')
console.log('[OK] Function found at index:', actualStart)

// Find end via brace counting
let depth = 0, i = actualStart, funcEnd = -1, started = false
while (i < code.length) {
  if (code[i] === '{') { depth++; started = true }
  if (code[i] === '}') { depth--; if (started && depth === 0) { funcEnd = i; break } }
  i++
}
console.log('[OK] Function ends at index:', funcEnd)

// New Galaxy function — string concat, NO backtick template literals
const Q = "'"
const newFunc = [
'function GalaxyBg() {',
'  const canvasRef=useRef(null)',
'  useEffect(()=>{',
'    const canvas=canvasRef.current;if(!canvas)return',
'    const ctx=canvas.getContext('+Q+'2d'+Q+');if(!ctx)return',
'    let W=window.innerWidth,H=window.innerHeight',
'    canvas.width=W;canvas.height=H',
'    // Stars',
'    const stars=[]',
'    for(let i=0;i<220;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.2+0.2,op:Math.random(),spd:0.003+Math.random()*0.007})',
'    // Particles',
'    const pts=[]',
'    for(let i=0;i<55;i++)pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.4,vy:(Math.random()-.5)*.4,r:Math.random()*1.4+0.4,op:Math.random()*.2+.06})',
'    // Nebula defs',
'    const nebs=[',
'      {fx:0.12,fy:0.22,fr:0.22,c:'+Q+'rgba(77,159,255,0.055)'+Q+'},',
'      {fx:0.82,fy:0.55,fr:0.26,c:'+Q+'rgba(110,70,255,0.045)'+Q+'},',
'      {fx:0.48,fy:0.88,fr:0.20,c:'+Q+'rgba(0,212,255,0.040)'+Q+'},',
'      {fx:0.28,fy:0.68,fr:0.17,c:'+Q+'rgba(255,90,180,0.035)'+Q+'},',
'      {fx:0.65,fy:0.15,fr:0.19,c:'+Q+'rgba(0,230,160,0.032)'+Q+'},',
'    ]',
'    let angle=0',
'    let animId',
'    const draw=()=>{',
'      ctx.clearRect(0,0,W,H)',
'      // Nebula blobs',
'      nebs.forEach(function(n){',
'        const nx=n.fx*W,ny=n.fy*H,nr=n.fr*W',
'        const g=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)',
'        g.addColorStop(0,n.c)',
'        g.addColorStop(1,'+Q+'rgba(0,0,0,0)'+Q+')',
'        ctx.fillStyle=g;ctx.beginPath();ctx.arc(nx,ny,nr,0,Math.PI*2);ctx.fill()',
'      })',
'      // Galaxy spiral arms',
'      const cx=W*0.5,cy=H*0.42',
'      for(let arm=0;arm<3;arm++){',
'        for(let t=0;t<90;t++){',
'          const a=angle+(arm*Math.PI*2/3)+(t*0.11)',
'          const dist=t*2.8',
'          const sx=cx+Math.cos(a)*dist,sy=cy+Math.sin(a)*dist*0.42',
'          if(sx<0||sx>W||sy<0||sy>H)continue',
'          const op=Math.max(0,(1-t/90)*0.11)',
'          ctx.beginPath();ctx.arc(sx,sy,0.9,0,Math.PI*2)',
'          ctx.fillStyle='+Q+'rgba(120,190,255,'+Q+'+op+'+Q+')'+Q,
'          ctx.fill()',
'        }',
'      }',
'      // Galaxy core',
'      const cg=ctx.createRadialGradient(cx,cy,0,cx,cy,20)',
'      cg.addColorStop(0,'+Q+'rgba(180,220,255,0.20)'+Q+')',
'      cg.addColorStop(1,'+Q+'rgba(0,0,0,0)'+Q+')',
'      ctx.fillStyle=cg;ctx.beginPath();ctx.arc(cx,cy,20,0,Math.PI*2);ctx.fill()',
'      angle+=0.0007',
'      // Twinkling stars',
'      stars.forEach(function(s){',
'        s.op+=s.spd;if(s.op>=1||s.op<=0.02)s.spd*=-1',
'        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)',
'        ctx.fillStyle='+Q+'rgba(215,235,255,'+Q+'+s.op*0.9+'+Q+')'+Q,
'        ctx.fill()',
'      })',
'      // Particles',
'      pts.forEach(function(p){',
'        p.x+=p.vx;p.y+=p.vy',
'        if(p.x<0)p.x=W;if(p.x>W)p.x=0',
'        if(p.y<0)p.y=H;if(p.y>H)p.y=0',
'        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)',
'        ctx.fillStyle='+Q+'rgba(77,159,255,'+Q+'+p.op+'+Q+')'+Q,
'        ctx.fill()',
'      })',
'      // Connection lines',
'      for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){',
'        const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)',
'        if(d<115){',
'          ctx.beginPath();ctx.moveTo(pts[i].x,pts[i].y);ctx.lineTo(pts[j].x,pts[j].y)',
'          ctx.strokeStyle='+Q+'rgba(77,159,255,'+Q+'+0.065*(1-d/115)+'+Q+')'+Q,
'          ctx.lineWidth=.5;ctx.stroke()',
'        }',
'      }',
'      animId=requestAnimationFrame(draw)',
'    }',
'    draw()',
'    const resize=function(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight}',
'    window.addEventListener('+Q+'resize'+Q+',resize)',
'    return function(){cancelAnimationFrame(animId);window.removeEventListener('+Q+'resize'+Q+',resize)}',
'  },[])',
'  return <canvas ref={canvasRef} style={{position:'+Q+'fixed'+Q+',inset:0,pointerEvents:'+Q+'none'+Q+',zIndex:0}}/>',
'}'
].join('\n')

const before = code.slice(0, actualStart)
const after = code.slice(funcEnd + 1)
const newCode = before + newFunc + after
fs.writeFileSync(FILE, newCode, 'utf8')
console.log('[OK] GalaxyBg written! Total lines:', newCode.split('\n').length)
JSEOF

step "Running fixer"
node $FIXER

step "Verify"
grep -n "function GalaxyBg\|nebs\[0\]\|nebs=\[" $FILE | head -5
echo "--- Stars check ---"
grep -n "stars.push\|twinkling\|s.op+=s.spd" $FILE | head -3
echo "--- Spiral check ---"
grep -n "Galaxy spiral\|angle+=0.0007\|arm<3" $FILE | head -3

step "TypeScript"
cd ~/workspace/frontend && npx tsc --noEmit --skipLibCheck 2>&1 | tail -4

step "DONE"
log "V3 complete!"
echo ""
echo "git add -A && git commit -m 'Fix: Galaxy bg V3' && git push origin main"
