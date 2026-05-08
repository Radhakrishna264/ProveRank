#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Galaxy Background Fix                         ║
# ║  Strategy: Line number se directly function replace karo   ║
# ║  NO sed -i | NO pattern matching | Pure node rewrite       ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; exit 1; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

step "Pre-flight"
[ ! -f "$FILE" ] && err "page.tsx not found!"
log "File found: $(wc -l < $FILE) lines"

# Backup
cp $FILE ${FILE}.bak_galaxy
log "Backup: page.tsx.bak_galaxy"

# ── Node script: ParticlesBg function dhundo aur replace karo ──
step "Replacing ParticlesBg with GalaxyBg"

node << 'NODESCRIPT'
const fs = require('fs')
const path = require('os').homedir() + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(path, 'utf8')

// Step 1: Find function start
const FUNC_START_MARKER = 'function ParticlesBg()'
const startIdx = code.indexOf(FUNC_START_MARKER)
if (startIdx === -1) {
  console.log('[WARN] ParticlesBg not found — checking current function name...')
  // Maybe it was renamed in previous run
  const alt = code.indexOf('function GalaxyBg()')
  if (alt !== -1) {
    console.log('[INFO] GalaxyBg already exists — may need content update only')
  } else {
    console.log('[ERR] Neither ParticlesBg nor GalaxyBg found!')
    process.exit(1)
  }
}

// Step 2: Find function end (matching brace counting)
let depth = 0
let i = startIdx
let funcEnd = -1
let inFunc = false

while (i < code.length) {
  if (code[i] === '{') { depth++; inFunc = true }
  if (code[i] === '}') {
    depth--
    if (inFunc && depth === 0) { funcEnd = i; break }
  }
  i++
}

if (funcEnd === -1) {
  console.log('[ERR] Could not find end of ParticlesBg function')
  process.exit(1)
}

console.log('[OK] Function found: chars', startIdx, 'to', funcEnd)

// Step 3: New Galaxy function
const NEW_FUNC = `function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    let W=window.innerWidth,H=window.innerHeight
    canvas.width=W;canvas.height=H

    // Layer 1 — Stars (200 twinkling)
    type Star={x:number;y:number;r:number;op:number;spd:number}
    const stars:Star[]=[]
    for(let i=0;i<200;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.1+0.2,op:Math.random(),spd:0.004+Math.random()*0.008})

    // Layer 2 — Moving particles (55 dots + connections)
    type Pt={x:number;y:number;vx:number;vy:number;r:number;op:number}
    const pts:Pt[]=[]
    for(let i=0;i<55;i++)pts.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.35,vy:(Math.random()-.5)*.35,r:Math.random()*1.3+0.4,op:Math.random()*.22+.05})

    // Layer 3 — Nebula positions (relative, recalc on resize)
    type Neb={fx:number;fy:number;fr:number;c:string}
    const nebDefs:Neb[]=[
      {fx:0.12,fy:0.22,fr:0.20,c:'rgba(77,159,255,0.05)'},
      {fx:0.82,fy:0.55,fr:0.24,c:'rgba(110,70,255,0.042)'},
      {fx:0.48,fy:0.88,fr:0.22,c:'rgba(0,212,255,0.038)'},
      {fx:0.28,fy:0.68,fr:0.16,c:'rgba(255,90,180,0.032)'},
      {fx:0.65,fy:0.15,fr:0.18,c:'rgba(0,230,160,0.03)'},
    ]

    let angle=0
    let animId:number

    const draw=()=>{
      ctx.clearRect(0,0,W,H)

      // Nebula blobs
      nebDefs.forEach(n=>{
        const nx=n.fx*W,ny=n.fy*H,nr=n.fr*W
        const g=ctx.createRadialGradient(nx,ny,0,nx,ny,nr)
        g.addColorStop(0,n.c);g.addColorStop(1,'rgba(0,0,0,0)')
        ctx.fillStyle=g;ctx.beginPath();ctx.arc(nx,ny,nr,0,Math.PI*2);ctx.fill()
      })

      // Galaxy spiral (3 arms, slow rotation)
      const cx=W*0.5,cy=H*0.42
      for(let arm=0;arm<3;arm++){
        for(let t=0;t<90;t++){
          const a=angle+(arm*Math.PI*2/3)+(t*0.11)
          const dist=t*2.8
          const sx=cx+Math.cos(a)*dist
          const sy=cy+Math.sin(a)*dist*0.42
          if(sx<0||sx>W||sy<0||sy>H)continue
          const op=Math.max(0,(1-t/90)*0.10)
          ctx.beginPath();ctx.arc(sx,sy,0.9,0,Math.PI*2)
          ctx.fillStyle=`rgba(120,190,255,${op})`;ctx.fill()
        }
      }
      // Galaxy core glow
      const cg=ctx.createRadialGradient(cx,cy,0,cx,cy,18)
      cg.addColorStop(0,'rgba(180,220,255,0.18)')
      cg.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=cg;ctx.beginPath();ctx.arc(cx,cy,18,0,Math.PI*2);ctx.fill()
      angle+=0.0007

      // Twinkling stars
      stars.forEach(s=>{
        s.op+=s.spd
        if(s.op>=1||s.op<=0.02)s.spd*=-1
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(215,235,255,${s.op*0.9})`;ctx.fill()
      })

      // Particles
      pts.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=W;if(p.x>W)p.x=0
        if(p.y<0)p.y=H;if(p.y>H)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(77,159,255,${p.op})`;ctx.fill()
      })

      // Connection lines
      for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){
        const dx=pts[i].x-pts[j].x,dy=pts[i].y-pts[j].y,d=Math.sqrt(dx*dx+dy*dy)
        if(d<115){
          ctx.beginPath();ctx.moveTo(pts[i].x,pts[i].y);ctx.lineTo(pts[j].x,pts[j].y)
          ctx.strokeStyle=`rgba(77,159,255,${.065*(1-d/115)})`;ctx.lineWidth=.5;ctx.stroke()
        }
      }

      animId=requestAnimationFrame(draw)
    }
    draw()

    const resize=()=>{
      W=canvas.width=window.innerWidth
      H=canvas.height=window.innerHeight
    }
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}`

// Step 4: Replace
const before = code.slice(0, startIdx)
const after = code.slice(funcEnd + 1)
code = before + NEW_FUNC + after

fs.writeFileSync(path, code, 'utf8')
console.log('[OK] Galaxy background successfully written!')
console.log('[OK] New file size:', code.length, 'chars')
NODESCRIPT

# ── Verify ──
step "Verification"

echo "--- Galaxy keywords in file ---"
grep -n "nebDefs\|twinkling\|spiral\|Galaxy spiral\|Nebula blobs" $FILE | head -8

echo ""
echo "--- ParticlesBg still present ---"
grep -n "function ParticlesBg" $FILE | head -3

step "TypeScript Check"
cd ~/workspace/frontend && npx tsc --noEmit --skipLibCheck 2>&1 | grep -E "error TS|PASSED|warning" | tail -10
echo "Exit code: $?"

step "DONE"
log "Galaxy fix complete!"
echo ""
echo -e "${B}Ab ye karo:${N}"
echo "git add -A && git commit -m 'Fix: Galaxy Universe background animation' && git push origin main"
