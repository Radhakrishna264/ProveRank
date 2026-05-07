// ProveRank Dashboard — Premium Animation Injector
// Run: node inject_dash_anim.js
const fs = require('fs');
const os = require('os');
const path = os.homedir() + '/workspace/frontend/app/dashboard/page.tsx';

let c = fs.readFileSync(path, 'utf8');

// ── Style tag + floating SVGs to inject ──────────────────────
const INJECT = `
      {/* ── Premium Dashboard Animations ── */}
      <style dangerouslySetInnerHTML={{__html:\`
        @keyframes dashFadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
        @keyframes dashFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
        @keyframes dashFloat2{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        @keyframes dashSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes dashGlow{0%,100%{opacity:0.22}50%{opacity:0.48}}
        @keyframes dashParticle{0%{transform:translateY(0);opacity:0}15%{opacity:0.7}85%{opacity:0.7}100%{transform:translateY(-90px);opacity:0}}
        @keyframes dashDNA{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        @keyframes dashTwinkle{0%,100%{opacity:0.1}50%{opacity:0.8}}
      \`}}/>

      {/* Floating DNA — fixed top-left */}
      <div style={{position:'fixed',top:'14%',left:'1%',opacity:0.25,pointerEvents:'none',animation:'dashDNA 7s ease-in-out infinite',zIndex:1}}>
        <svg width="44" height="100" viewBox="0 0 44 100">
          {[0,1,2,3,4,5,6].map((i:number)=>{
            const y=i*13+7;const w=Math.sin(i*0.95)*13;
            return(<g key={i}>
              <ellipse cx={22+w} cy={y} rx={8} ry={3.5} fill="none" stroke="#4D9FFF" strokeWidth="1.4" opacity={0.9}/>
              <line x1={22+w} y1={y} x2={22-w} y2={y+13} stroke="#00D4FF" strokeWidth="1" opacity={0.6}/>
              <circle cx={22+w} cy={y} r={2.2} fill="#4D9FFF" opacity={0.85}/>
              <circle cx={22-w} cy={y} r={1.8} fill="#7B4DFF" opacity={0.7}/>
            </g>);
          })}
        </svg>
      </div>

      {/* Rotating Atom — fixed top-right */}
      <div style={{position:'fixed',top:'10%',right:'2%',opacity:0.22,pointerEvents:'none',animation:'dashSpin 20s linear infinite',zIndex:1}}>
        <svg width="72" height="72" viewBox="0 0 72 72">
          <circle cx="36" cy="36" r="5" fill="#4D9FFF"/>
          <ellipse cx="36" cy="36" rx="32" ry="11" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/>
          <ellipse cx="36" cy="36" rx="32" ry="11" fill="none" stroke="#00D4FF" strokeWidth="1.5" transform="rotate(60 36 36)"/>
          <ellipse cx="36" cy="36" rx="32" ry="11" fill="none" stroke="#7B4DFF" strokeWidth="1.5" transform="rotate(120 36 36)"/>
          <circle cx="68" cy="36" r="3" fill="#4D9FFF" opacity={0.9}/>
          <circle cx="19" cy="7" r="3" fill="#00D4FF" opacity={0.9}/>
          <circle cx="19" cy="65" r="3" fill="#7B4DFF" opacity={0.9}/>
        </svg>
      </div>

      {/* Hexagons — fixed bottom-left */}
      <div style={{position:'fixed',bottom:'18%',left:'0%',opacity:0.18,pointerEvents:'none',zIndex:1}}>
        <svg width="80" height="80" viewBox="0 0 80 80">
          <polygon points="40,8 55,16 55,32 40,40 25,32 25,16" fill="none" stroke="#4D9FFF" strokeWidth="1.3"/>
          <polygon points="20,44 35,52 35,68 20,76 5,68 5,52" fill="none" stroke="#7B4DFF" strokeWidth="1.3"/>
          <polygon points="60,44 75,52 75,68 60,76 45,68 45,52" fill="none" stroke="#00D4FF" strokeWidth="1.3"/>
        </svg>
      </div>

      {/* Flask — fixed bottom-right */}
      <div style={{position:'fixed',bottom:'14%',right:'1%',opacity:0.22,pointerEvents:'none',animation:'dashFloat2 9s ease-in-out infinite',zIndex:1}}>
        <svg width="40" height="78" viewBox="0 0 40 78">
          <rect x="13" y="3" width="14" height="48" rx="2" fill="none" stroke="#00D4FF" strokeWidth="2"/>
          <path d="M13 51 Q20 72 27 51" fill="rgba(0,212,255,0.18)" stroke="#00D4FF" strokeWidth="2"/>
          <rect x="10" y="3" width="20" height="8" rx="2" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/>
          <circle cx="20" cy="40" r="2.8" fill="#00D4FF" opacity={0.9}/>
          <circle cx="16" cy="32" r="2" fill="#4D9FFF" opacity={0.75}/>
          <circle cx="24" cy="46" r="2" fill="#7B4DFF" opacity={0.75}/>
        </svg>
      </div>

      {/* Rising Particles */}
      {([0,1,2,3,4,5] as number[]).map((i:number)=>(
        <div key={i} style={{
          position:'fixed',
          left:(10+i*14)+'%',
          bottom:'8%',
          width:3,height:3,
          borderRadius:'50%',
          background:['#4D9FFF','#00D4FF','#7B4DFF','#00C48C','#FF8C00','#FF4D9F'][i],
          opacity:0.6,
          pointerEvents:'none',
          zIndex:1,
          animation:'dashParticle '+(4+i*1.1)+'s ease-in-out '+(i*0.8)+'s infinite'
        }}/>
      ))}`;

// Find injection point — after the opening div of the dashboard content
// Look for the first <div with padding:'16px' in the dashboard return
const marker = `padding:'16px',maxWidth:520,margin:'0 auto'}}>`; 
const markerAlt = `padding:'16px',maxWidth:`;

let injected = false;

if (c.includes(marker)) {
  c = c.replace(marker, marker + INJECT);
  injected = true;
  console.log('✓ Injected via exact marker');
} else {
  // Try to find a suitable div in the return
  const idx = c.indexOf(markerAlt);
  if (idx !== -1) {
    const endBrace = c.indexOf('}>', idx);
    if (endBrace !== -1) {
      c = c.slice(0, endBrace + 2) + INJECT + c.slice(endBrace + 2);
      injected = true;
      console.log('✓ Injected via alt marker');
    }
  }
}

if (!injected) {
  // Last resort: inject after first <div in the return of DashboardContent
  const retIdx = c.lastIndexOf('return(');
  if (retIdx !== -1) {
    const divIdx = c.indexOf('<div ', retIdx);
    const divEnd = c.indexOf('>', divIdx);
    c = c.slice(0, divEnd + 1) + INJECT + c.slice(divEnd + 1);
    injected = true;
    console.log('✓ Injected via last-resort return');
  }
}

if (!injected) {
  console.log('✗ ERROR: Could not find injection point!');
  process.exit(1);
}

fs.writeFileSync(path, c, 'utf8');
console.log('✓ Dashboard animation injection complete!');
console.log('Verifying...');
const verify = fs.readFileSync(path, 'utf8');
console.log('dashDNA found:', verify.includes('dashDNA'));
console.log('dashSpin found:', verify.includes('dashSpin'));
console.log('Flask found:', verify.includes('dashFloat2'));
console.log('Particles found:', verify.includes('dashParticle'));
