#!/bin/bash
# ProveRank — Galaxy Fix V2
# Fix: Template literals heredoc ke andar nahi chalte
# Solution: Poori function ek JS file mein write karo, phir execute karo

G='\033[0;32m'; B='\033[0;34m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; exit 1; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
FIXER=/tmp/galaxy_fixer.js

[ ! -f "$FILE" ] && err "page.tsx not found!"

step "Pre-flight"
log "Lines: $(wc -l < $FILE)"
cp $FILE ${FILE}.bak_galaxy2
log "Backup: page.tsx.bak_galaxy2"

step "Writing fixer JS file"

# Write the JS fixer as a file (no heredoc — direct cat > with escaped content)
cat > $FIXER << 'JSEOF'
const fs = require('fs')
const path = require(process.env.HOME + '/workspace').homedir
  ? require(process.env.HOME + '/workspace')
  : { path: process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx' }

const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(FILE, 'utf8')

// Find ParticlesBg function
const startIdx = code.indexOf('function ParticlesBg()')
if (startIdx === -1) { console.log('[ERR] ParticlesBg not found'); process.exit(1) }

// Find matching closing brace
let depth = 0, i = startIdx, funcEnd = -1, started = false
while (i < code.length) {
  if (code[i] === '{') { depth++; started = true }
  if (code[i] === '}') { depth--; if (started && depth === 0) { funcEnd = i; break } }
  i++
}
if (funcEnd === -1) { console.log('[ERR] Function end not found'); process.exit(1) }
console.log('[OK] Found function: index', startIdx, '->', funcEnd)

// Build new function using string concat (NO backtick template literals)
const nl = '\n'
const bt = '`'
const lines = [
'function ParticlesBg() {',
'  const canvasRef=useRef(null)',
'  useEffect(()=>{',
'    const canvas=canvasRef.current;if(!canvas)return',
'    const ctx=canvas.getContext(' + "'2d'" + ');if(!ctx)return',
'    let W=window.innerWidth,H=window.innerHeight',
'    canvas.width=W;canvas.height=H',
'    const stars=[]',
'    for(let i=0;i<200;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.1+0.2,op:Math.random(),spd:0.004+Math.random()*0.008})',
'    const pts=[]',
'    for(let i=0;i<55;i++)pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.35,vy:(Math.random()-.5)*.35,r:Math.random()*1.3+0.4,op:Math.random()*.22+.05})',
'    const nebDefs=[',
'      {fx:0.12,fy:0.22,fr:0.20,c:' + "'rgba(77,159,255,0.05)'" + '},',
'      {fx:0.82,fy:0.55,fr:0.24,c:' + "'rgba(110,70,255,0.042)'" + '},',
'      {fx:0.48,fy:0.88,fr:0.22,c:' + "'rgba(0,212,255,0.038)'" + '},',
'      {fx:0.28,fy:0.68,fr:0.16,c:' + "'rgba(255,90,180,0.032)'" + '},',
'      {fx:0.65,fy:0.15,fr:0.18,c:' + "'rgba(0,230,160,0.03)'" + '},',
'    ]',
'    let angle=0',
'    let animId',
'    const draw=()=>{',
'      ctx.clearRect(0,0,W,H)',
'      nebDefs.forEach(function(n){',
'        const nx=n.fx*W,ny=n.fy*H,nr=n.fr*W',
'        const g=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)',
'        g.addColorStop(0,n.c);g.addColorStop(1,' + "'rgba(0,0,0,0)'" + ')',
'        ctx.fillStyle=g;ctx.beginPath();ctx.arc(nx,ny,nr,0,Math.PI*2);ctx.fill()',
'      })',
'      const cx=W*0.5,cy=H*0.42',
'      for(let arm=0;arm<3;arm++){',
'        for(let t=0;t<90;t++){',
'          const a=angle+(arm*Math.PI*2/3)+(t*0.11)',
'          const dist=t*2.8',
'          const sx=cx+Math.cos(a)*dist',
'          const sy=cy+Math.sin(a)*dist*0.42',
'          if(sx<0||sx>W||sy<0||sy>H)continue',
'          const op=Math.max(0,(1-t/90)*0.10)',
'          ctx.beginPath();ctx.arc(sx,sy,0.9,0,Math.PI*2)',
'          ctx.fillStyle=' + "'rgba(120,190,255,'" + '+op+' + "')'" + '',
'          ctx.fill()',
'        }',
'      }',
'      const cg=ctx.createRadialGradient(cx,cy,0,cx,cy,18)',
'      cg.addColorStop(0,' + "'rgba(180,220,255,0.18)'" + ')',
'      cg.addColorStop(1,' + "'rgba(0,0,0,0)'" + ')',
'      ctx.fillStyle=cg;ctx.beginPath();ctx.arc(cx,cy,18,0,Math.PI*2);ctx.fill()',
'      angle+=0.0007',
'      stars.forEach(function(s){',
'        s.op+=s.spd',
'        if(s.op>=1||s.op<=0.02)s.spd*=-1',
'        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)',
'        ctx.fillStyle=' + "'rgba(215,235,255,'" + '+s.op*0.9+' + "')'" + '',
'        ctx.fill()',
'      })',
'      pts.forEach(function(p){',
'        p.x+=p.vx;p.y+=p.vy',
'        if(p.x<0)p.x=W;if(p.x>W)p.x=0',
'        if(p.y<0)p.y=H;if(p.y>H)p.y=0',
'        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)',
'        ctx.fillStyle=' + "'rgba(77,159,255,'" + '+p.op+' + "')'" + '',
'        ctx.fill()',
'      })',
'      for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){',
'        const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)',
'        if(d<115){',
'          ctx.beginPath();ctx.moveTo(pts[i].x,pts[i].y);ctx.lineTo(pts[j].x,pts[j].y)',
'          ctx.strokeStyle=' + "'rgba(77,159,255,'" + '+0.065*(1-d/115)+' + "')'" + '',
'          ctx.lineWidth=.5;ctx.stroke()',
'        }',
'      }',
'      animId=requestAnimationFrame(draw)',
'    }',
'    draw()',
'    const resize=function(){W=canvas.width=window.innerWidth;H=canvas.height=window.innerHeight}',
'    window.addEventListener(' + "'resize'" + ',resize)',
'    return function(){cancelAnimationFrame(animId);window.removeEventListener(' + "'resize'" + ',resize)}',
'  },[])',
'  return React.createElement(' + "'canvas'" + ',{ref:canvasRef,style:{position:' + "'fixed'" + ',inset:0,pointerEvents:' + "'none'" + ',zIndex:0}})',
'}'
]

const newFunc = lines.join('\n')

// Replace
const before = code.slice(0, startIdx)
const after = code.slice(funcEnd + 1)
const newCode = before + newFunc + after

fs.writeFileSync(FILE, newCode, 'utf8')
console.log('[OK] Galaxy function written! Lines: ' + newCode.split('\n').length)
JSEOF

log "Fixer JS written to $FIXER"

step "Running fixer"
node $FIXER

step "Verify"
echo "--- Function check ---"
grep -n "function ParticlesBg\|nebDefs\|twinkling\|stars.push\|angle+=0" $FILE | head -8

echo "--- Return statement ---"
grep -n "createElement.*canvas\|return.*canvas" $FILE | grep -A1 -B1 "ParticlesBg" | head -5

step "TypeScript Check"
cd ~/workspace/frontend && npx tsc --noEmit --skipLibCheck 2>&1 | tail -5

step "DONE"
log "Galaxy fix V2 complete!"
echo ""
echo -e "${B}Ab ye run karo:${N}"
echo "git add -A && git commit -m 'Fix: Galaxy background V2 - no template literals' && git push origin main"
