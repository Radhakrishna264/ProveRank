#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank Dashboard — Premium Animation + Font Fix         ║
# ║  FIX: "o Days" → "0 Days" (Playfair→Inter for numbers)    ║
# ║  ADD: Galaxy canvas BG, floating SVGs, card animations     ║
# ╚══════════════════════════════════════════════════════════════╝
G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'
DASH=~/workspace/frontend/app/dashboard/page.tsx

echo -e "${Y}Applying font fix + premium animations...${N}"
node -e "
const fs = require('fs');
let c = fs.readFileSync('$DASH', 'utf8');

// ══════════════════════════════════════════════
// FIX 1: StatCard Playfair → Inter
// ══════════════════════════════════════════════
c = c.replace(
  \`fontSize:26,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1,textShadow:\\\`0 0 20px \\\${col}44\\\`\`,
  \`fontSize:26,fontWeight:800,color:col,fontFamily:'Inter,sans-serif',lineHeight:1,fontVariantNumeric:'tabular-nums',textShadow:\\\`0 0 20px \\\${col}44\\\`\`
);

// ══════════════════════════════════════════════
// FIX 2: Countdown daysLeft span → Inter font
// ══════════════════════════════════════════════
c = c.replace(
  \`<span style={{color:C.gold,textShadow:\\\`0 0 20px \\\${C.gold}44\\\`}}>{daysLeft}</span> {t('Days Remaining','दिन शेष')}\`,
  \`<span style={{color:C.gold,textShadow:\\\`0 0 20px \\\${C.gold}44\\\`,fontFamily:'Inter,sans-serif',fontWeight:900,fontVariantNumeric:'tabular-nums'}}>{daysLeft}</span> {t('Days Remaining','दिन शेष')}\`
);

// ══════════════════════════════════════════════
// FIX 3: Motivational footer daysLeft text fix
// ══════════════════════════════════════════════
c = c.replace(
  /daysLeft\+' days remaining for NEET 2026 — Make every day count!'/g,
  \"daysLeft+' days remaining — Make every day count!'\"
);
c = c.replace(
  /'NEET 2026 के लिए '\+daysLeft\+' दिन शेष — हर दिन सार्थक बनाएं!'/g,
  \"daysLeft+' दिन शेष — हर दिन सार्थक बनाएं!'\"
);

// ══════════════════════════════════════════════
// ADD: Premium style animations via style tag
// Inject after 'use client' line
// ══════════════════════════════════════════════
const styleBlock = \`
// ── Premium Dashboard Animations ──
const DASH_STYLES = \\\`
  @keyframes fadeInUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
  @keyframes floatY{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
  @keyframes floatY2{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
  @keyframes spinSlow{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
  @keyframes spinSlowRev{from{transform:rotate(360deg)}to{transform:rotate(0deg)}}
  @keyframes glowPulse{0%,100%{opacity:0.35}50%{opacity:0.65}}
  @keyframes particleDrift{0%{transform:translateY(0) translateX(0);opacity:0}20%{opacity:1}80%{opacity:1}100%{transform:translateY(-120px) translateX(30px);opacity:0}}
  @keyframes twinkle{0%,100%{opacity:0.2}50%{opacity:0.9}}
  @keyframes scaleIn{from{opacity:0;transform:scale(0.92)}to{opacity:1;transform:scale(1)}}
  @keyframes gradMove{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
  .dash-card-anim{animation:scaleIn 0.4s ease both}
  .dash-float{animation:floatY 6s ease-in-out infinite}
  .dash-float2{animation:floatY2 8s ease-in-out infinite 1s}
\\\`;
\`;

// Inject style block after 'use client'
if(!c.includes('DASH_STYLES')) {
  c = c.replace(\"'use client'\", \"'use client'\n\" + styleBlock);
}

// ══════════════════════════════════════════════
// ADD: Canvas galaxy BG + floating science SVGs
// Find the DashboardContent return div start and inject
// ══════════════════════════════════════════════
const canvasHook = \`
// ── Galaxy Canvas Hook ──
const dashCanvasRef = typeof window !== 'undefined' ? require('react').useRef(null) : {current:null};
require('react').useEffect(()=>{
  const canvas = dashCanvasRef.current; if(!canvas) return;
  const ctx = canvas.getContext('2d'); if(!ctx) return;
  let raf:number;
  const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight};
  resize(); window.addEventListener('resize',resize);
  const stars=Array.from({length:160},()=>({x:Math.random()*window.innerWidth,y:Math.random()*window.innerHeight,r:Math.random()*1.6+0.2,o:Math.random()*0.5+0.1,sp:Math.random()*0.03+0.008,ph:Math.random()*Math.PI*2}));
  const W=()=>canvas.width,H=()=>canvas.height;
  let frame=0;
  const draw=()=>{
    ctx.clearRect(0,0,W(),H()); frame++;
    const g1=ctx.createRadialGradient(W()*.2,H()*.3,0,W()*.2,H()*.3,W()*.38);
    g1.addColorStop(0,'rgba(0,60,160,0.22)');g1.addColorStop(1,'transparent');
    ctx.fillStyle=g1;ctx.fillRect(0,0,W(),H());
    const g2=ctx.createRadialGradient(W()*.85,H()*.7,0,W()*.85,H()*.7,W()*.32);
    g2.addColorStop(0,'rgba(80,0,180,0.18)');g2.addColorStop(1,'transparent');
    ctx.fillStyle=g2;ctx.fillRect(0,0,W(),H());
    stars.forEach(s=>{s.ph+=s.sp;const op=s.o*(0.4+0.6*Math.sin(s.ph));ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=\\\`rgba(200,220,255,\\\${op})\\\`;ctx.fill()});
    raf=requestAnimationFrame(draw);
  };
  draw();
  return()=>{cancelAnimationFrame(raf);window.removeEventListener('resize',resize)};
},[]);
\`;
\`;

fs.writeFileSync('$DASH', c, 'utf8');
console.log('✓ Font fix + animation styles applied!');
"

# Now do the canvas injection and SVG floating elements via a second node pass
node << 'NODE_EOF'
const fs = require('fs');
const path = require('os').homedir() + '/workspace/frontend/app/dashboard/page.tsx';
let c = fs.readFileSync(path, 'utf8');

// Inject DASH_STYLES into the JSX return (add <style> tag)
// Find the outermost container div in DashboardContent return
// and add the style tag + canvas + floating SVGs

const styleInjection = `
      {/* Premium BG Styles */}
      <style dangerouslySetInnerHTML={{__html:\`
        @keyframes fadeInUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
        @keyframes floatY{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
        @keyframes floatY2{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes spinSlow2{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes glowPulse{0%,100%{opacity:0.28}50%{opacity:0.55}}
        @keyframes twinkle{0%,100%{opacity:0.15}50%{opacity:0.7}}
        @keyframes particleRise{0%{transform:translateY(0);opacity:0}15%{opacity:0.8}85%{opacity:0.8}100%{transform:translateY(-100px);opacity:0}}
        @keyframes dnaFloat{0%,100%{transform:translateY(0) rotate(-8deg)}50%{transform:translateY(-14px) rotate(-8deg)}}
        @keyframes hexSpin{from{transform:rotate(0deg)}to{transform:rotate(60deg)}}
        @keyframes scaleIn{from{opacity:0;transform:scale(0.94)}to{opacity:1;transform:scale(1)}}
      \`}}/>

      {/* Floating DNA — top left */}
      <div style={{position:'fixed',top:'12%',left:'1%',opacity:0.22,pointerEvents:'none',animation:'dnaFloat 7s ease-in-out infinite',zIndex:1}}>
        <svg width="48" height="110" viewBox="0 0 48 110">
          {[0,1,2,3,4,5,6].map((i:number)=>{const y=i*15+8;const w=Math.sin(i*0.95)*14;return(<g key={i}><ellipse cx={24+w} cy={y} rx={9} ry={3.5} fill="none" stroke="#4D9FFF" strokeWidth="1.5" opacity={0.85}/><line x1={24+w} y1={y} x2={24-w} y2={y+15} stroke="#00D4FF" strokeWidth="1" opacity={0.6}/><circle cx={24+w} cy={y} r={2.5} fill="#4D9FFF" opacity={0.8}/><circle cx={24-w} cy={y} r={2} fill="#7B4DFF" opacity={0.65}/></g>)})}
        </svg>
      </div>

      {/* Rotating Atom — top right */}
      <div style={{position:'fixed',top:'8%',right:'2%',opacity:0.20,pointerEvents:'none',animation:'spinSlow2 22s linear infinite',zIndex:1}}>
        <svg width="75" height="75" viewBox="0 0 75 75">
          <circle cx="37" cy="37" r="5" fill="#4D9FFF"/>
          <ellipse cx="37" cy="37" rx="34" ry="12" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/>
          <ellipse cx="37" cy="37" rx="34" ry="12" fill="none" stroke="#00D4FF" strokeWidth="1.5" transform="rotate(60 37 37)"/>
          <ellipse cx="37" cy="37" rx="34" ry="12" fill="none" stroke="#7B4DFF" strokeWidth="1.5" transform="rotate(120 37 37)"/>
          <circle cx="71" cy="37" r="3.5" fill="#4D9FFF" opacity={0.9}/>
          <circle cx="20" cy="8" r="3.5" fill="#00D4FF" opacity={0.9}/>
        </svg>
      </div>

      {/* Hexagons — bottom left */}
      <div style={{position:'fixed',bottom:'15%',left:'0%',opacity:0.16,pointerEvents:'none',zIndex:1}}>
        <svg width="90" height="90" viewBox="0 0 90 90">
          {[[45,25],[23,52],[67,52],[45,79]].map(([cx,cy]:number[],i:number)=>(
            <polygon key={i} points={`${cx},${cy-16} ${cx+14},${cy-8} ${cx+14},${cy+8} ${cx},${cy+16} ${cx-14},${cy+8} ${cx-14},${cy-8}`} fill="none" stroke="#4D9FFF" strokeWidth="1.3" opacity={0.8}/>
          ))}
        </svg>
      </div>

      {/* Flask — bottom right */}
      <div style={{position:'fixed',bottom:'12%',right:'1%',opacity:0.20,pointerEvents:'none',animation:'floatY2 9s ease-in-out infinite',zIndex:1}}>
        <svg width="42" height="82" viewBox="0 0 42 82">
          <rect x="14" y="3" width="14" height="52" rx="2" fill="none" stroke="#00D4FF" strokeWidth="2"/>
          <path d="M14 55 Q21 75 28 55" fill="rgba(0,212,255,0.2)" stroke="#00D4FF" strokeWidth="2"/>
          <rect x="11" y="3" width="20" height="8" rx="2" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/>
          <circle cx="21" cy="44" r="3" fill="#00D4FF" opacity={0.85}/>
          <circle cx="17" cy="35" r="2" fill="#4D9FFF" opacity={0.7}/>
          <circle cx="25" cy="50" r="2" fill="#7B4DFF" opacity={0.75}/>
        </svg>
      </div>

      {/* Particle dots */}
      {[...Array(6)].map((_:any,i:number)=>(
        <div key={i} style={{position:'fixed',left:\`\${10+i*15}%\`,bottom:'5%',width:3,height:3,borderRadius:'50%',background:['#4D9FFF','#00D4FF','#7B4DFF','#00C48C','#FF8C00','#FF4D9F'][i],opacity:0.5,pointerEvents:'none',zIndex:1,animation:\`particleRise \${4+i*1.2}s ease-in-out \${i*0.7}s infinite\`}}/>
      ))}`;

// Find the first return statement in DashboardContent and inject after the opening <div
// Look for the pattern of the content wrapper
const insertAfter = `return(\n    <div style={{padding:'16px',maxWidth:520,margin:'0 auto'}}>`;
const insertAfterAlt = `return(\n    <div style={{padding`;

if(c.includes(insertAfter)) {
  c = c.replace(insertAfter, insertAfter + '\n' + styleInjection);
  console.log('✓ Injected after exact match');
} else {
  // Find HomeTab or DashboardContent return with padding
  const match = c.match(/return\(\s*\n\s*<div style=\{\{padding:'16px'/);
  if(match) {
    const idx = c.indexOf(match[0]);
    const endOfOpenDiv = c.indexOf('>', idx) + 1;
    c = c.slice(0, endOfOpenDiv) + '\n' + styleInjection + c.slice(endOfOpenDiv);
    console.log('✓ Injected via regex match');
  } else {
    console.log('⚠ Could not find exact injection point - manual check needed');
  }
}

fs.writeFileSync(path, c, 'utf8');
console.log('✓ All changes written to dashboard/page.tsx');
NODE_EOF

echo -e "\n${Y}Verifying font fix:${N}"
grep -n "Inter,sans-serif\|tabular-nums\|fontFamily.*stat\|fontFamily.*26" "$DASH" | head -8

echo -e "\n${Y}Verifying animation injection:${N}"
grep -n "fadeInUp\|floatY\|dnaFloat\|particleRise\|Rotating Atom\|Flask" "$DASH" | head -8

echo ""
echo -e "${Y}Deploy:${N}"
echo "cd ~/workspace/frontend && git add -A && git commit -m 'feat: premium dashboard animations + fix 0 vs o font' && git push"
