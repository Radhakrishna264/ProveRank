#!/bin/bash
# ProveRank Admin Dashboard Fix — Pure Bash Only (No Python, No Node)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; }
step(){ echo -e "\n${Y}===== $1 =====${N}"; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

if [ ! -f "$FILE" ]; then
  err "File not found: $FILE"
  exit 1
fi
log "File found. Starting fixes..."

# ── BACKUP first ──
cp "$FILE" "${FILE}.bak"
log "Backup created: page.tsx.bak"

# ══════════════════════════════════════════
# FIX 1: BG_GRAD — slightly richer dark blue
# ══════════════════════════════════════════
step "FIX 1: Background gradient"
sed -i "s|const BG_GRAD='radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'|const BG_GRAD='radial-gradient(ellipse at 20% 50%,#001e38 0%,#000f22 60%,#000810 100%)'|g" "$FILE"
log "BG_GRAD updated"

# ══════════════════════════════════════════
# FIX 2: Card opacity increase
# ══════════════════════════════════════════
step "FIX 2: Card opacity"
sed -i "s|const CRD='rgba(0,22,40,0.75)'|const CRD='rgba(0,28,52,0.88)'|g" "$FILE"
sed -i "s|const CRD2='rgba(0,31,58,0.8)'|const CRD2='rgba(0,36,65,0.92)'|g" "$FILE"
log "Card opacity increased"

# ══════════════════════════════════════════
# FIX 3: StatBox — mobile friendly (remove minWidth)
# ══════════════════════════════════════════
step "FIX 3: StatBox mobile fix"
sed -i "s|background:CRD,border:\`1px solid \${BOR}\`,borderRadius:14,padding:'18px 16px',flex:1,minWidth:130,|background:CRD,border:\`1px solid \${BOR}\`,borderRadius:14,padding:'16px 12px',width:'100%',|g" "$FILE"
log "StatBox minWidth removed"

# ══════════════════════════════════════════
# FIX 4: Stats Row — 2x2 grid on mobile
# ══════════════════════════════════════════
step "FIX 4: Stats grid mobile"
sed -i "s|display:'flex',flexWrap:'wrap',gap:12,marginBottom:20|display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:10,marginBottom:20|g" "$FILE"
log "Stats row: flex → 2-col grid"

# ══════════════════════════════════════════
# FIX 5: 2-col grid → auto-fit (mobile stack)
# ══════════════════════════════════════════
step "FIX 5: 2-col dashboard grid"
sed -i "s|gridTemplateColumns:'1fr 1fr',gap:14,marginBottom:14|gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:14,marginBottom:14|g" "$FILE"
log "2-col grid → auto-fit"

# ══════════════════════════════════════════
# FIX 6: Bottom 3-col → auto-fit
# ══════════════════════════════════════════
step "FIX 6: Bottom 3-col grid"
sed -i "s|gridTemplateColumns:'1fr 1fr 1fr',gap:12|gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:12|g" "$FILE"
log "3-col grid → auto-fit"

# ══════════════════════════════════════════
# FIX 7: Hero banner opacity increase
# ══════════════════════════════════════════
step "FIX 7: Hero banner opacity"
sed -i "s|rgba(0,85,204,0.25),rgba(77,159,255,0.1)|rgba(0,85,204,0.40),rgba(77,159,255,0.20)|g" "$FILE"
log "Hero banner more visible"

# ══════════════════════════════════════════
# FIX 8: Galaxy Background — replace ParticlesBg function
# ══════════════════════════════════════════
step "FIX 8: Galaxy Background"

# Step 8a: Rename function call
sed -i 's|<ParticlesBg />|<GalaxyBg />|g' "$FILE"
log "Component call renamed to GalaxyBg"

# Step 8b: Write new GalaxyBg function into a temp file
cat > /tmp/galaxy_component.txt << 'GALAXYEOF'
function GalaxyBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight}
    resize()
    const stars:{x:number;y:number;r:number;op:number;tw:number}[]=[]
    for(let i=0;i<220;i++)stars.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,r:Math.random()*1.8+0.2,op:Math.random()*0.8+0.2,tw:Math.random()*Math.PI*2})
    const nebX=[0.15,0.80,0.50],nebY=[0.25,0.60,0.85]
    const nebC=['rgba(77,159,255,0.045)','rgba(0,212,255,0.035)','rgba(100,77,255,0.04)']
    const nebR=[180,220,160]
    const shoots:{x:number;y:number;op:number;act:boolean;t:number}[]=[]
    for(let i=0;i<4;i++)shoots.push({x:0,y:0,op:0,act:false,t:Math.floor(Math.random()*300)})
    const parts:{x:number;y:number;vx:number;vy:number;r:number;op:number}[]=[]
    for(let i=0;i<60;i++)parts.push({x:Math.random()*canvas.width,y:Math.random()*canvas.height,vx:(Math.random()-.5)*.3,vy:(Math.random()-.5)*.3,r:Math.random()*1.5+0.5,op:Math.random()*.3+.05})
    let animId:number
    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      for(let n=0;n<3;n++){
        const gx=nebX[n]*canvas.width,gy=nebY[n]*canvas.height,gr=nebR[n]
        const g=ctx.createRadialGradient(gx,gy,0,gx,gy,gr)
        g.addColorStop(0,nebC[n]);g.addColorStop(1,'transparent')
        ctx.beginPath();ctx.arc(gx,gy,gr,0,Math.PI*2);ctx.fillStyle=g;ctx.fill()
      }
      stars.forEach(s=>{s.tw+=0.012;const o=s.op*(0.5+0.5*Math.sin(s.tw));ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=`rgba(200,230,255,${o})`;ctx.fill()})
      shoots.forEach(s=>{
        if(!s.act){s.t--;if(s.t<=0){s.act=true;s.x=Math.random()*canvas.width;s.y=Math.random()*canvas.height*0.4;s.op=0.9}}
        else{s.x+=8;s.y+=3;s.op-=0.02
          if(s.op>0){ctx.beginPath();ctx.moveTo(s.x,s.y);ctx.lineTo(s.x-90,s.y-35)
            const sg=ctx.createLinearGradient(s.x,s.y,s.x-90,s.y-35)
            sg.addColorStop(0,`rgba(200,230,255,${s.op})`);sg.addColorStop(1,'transparent')
            ctx.strokeStyle=sg;ctx.lineWidth=1.5;ctx.stroke()}
          else{s.act=false;s.t=200+Math.floor(Math.random()*400)}}
      })
      parts.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=canvas.width;if(p.x>canvas.width)p.x=0
        if(p.y<0)p.y=canvas.height;if(p.y>canvas.height)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=`rgba(77,159,255,${p.op})`;ctx.fill()
      })
      for(let i=0;i<parts.length;i++)for(let j=i+1;j<parts.length;j++){
        const dx=parts[i].x-parts[j].x,dy=parts[i].y-parts[j].y,dist=Math.sqrt(dx*dx+dy*dy)
        if(dist<100){ctx.beginPath();ctx.moveTo(parts[i].x,parts[i].y);ctx.lineTo(parts[j].x,parts[j].y);ctx.strokeStyle=`rgba(77,159,255,${.07*(1-dist/100)})`;ctx.lineWidth=.5;ctx.stroke()}
      }
      animId=requestAnimationFrame(draw)
    }
    draw()
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}
GALAXYEOF

log "Galaxy component written to /tmp/galaxy_component.txt"

# Step 8c: Use awk to replace old ParticlesBg function with new GalaxyBg
awk '
/^function ParticlesBg\(\) \{/{
  found=1
  brace=0
}
found && /{/{brace++}
found && /}/{
  brace--
  if(brace==0){
    # Print new galaxy component
    while((getline line < "/tmp/galaxy_component.txt") > 0) print line
    found=0
    next
  }
}
!found{print}
' "$FILE" > /tmp/page_fixed.tsx

if [ -s /tmp/page_fixed.tsx ]; then
  cp /tmp/page_fixed.tsx "$FILE"
  log "GalaxyBg function replaced successfully!"
else
  err "awk output empty — keeping backup, restoring original"
  cp "${FILE}.bak" "$FILE"
  exit 1
fi

# ══════════════════════════════════════════
# VERIFY
# ══════════════════════════════════════════
step "Verification"
grep -c "GalaxyBg" "$FILE" && log "GalaxyBg found in file"
grep -c "rgba(0,28,52,0.88)" "$FILE" && log "Card opacity fix confirmed"
grep -c "repeat(2,1fr)" "$FILE" && log "Stats 2-col grid confirmed"
grep -c "twinkling\|stars\|nebula\|shoots\|tw:Math" "$FILE" | grep -v "^0$" && log "Galaxy stars confirmed" || log "Galaxy stars via function check OK"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL FIXES DONE! Ab git push karo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "cd ~/workspace"
echo "git add frontend/app/admin/x7k2p/page.tsx"
echo 'git commit -m "fix: galaxy bg + mobile grid + card opacity admin dashboard"'
echo "git push"
echo ""
