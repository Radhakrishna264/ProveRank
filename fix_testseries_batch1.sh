#!/bin/bash
# ProveRank — Test Series Page Fix (Batch 1)
# Run: bash fix_testseries_batch1.sh

echo "=== Fixing Test Series Page (Batch 1) ==="

# Step 1: Get real batch count from DB for stats
node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// ── FIX 1: Remove Nebula + Quote section (red circle) ──
// Remove NebulaAnim component call + quote section entirely
c = c.replace(
  /\/\* ━━ NEBULA VIDEO \+ MOTIVATIONAL QUOTE ━━ \*\/[\s\S]*?<\/div>\s*\n\s*\{\/\* ━━ CATEGORY STRIP/,
  '        {/* ━━ CATEGORY STRIP'
);

// ── FIX 2: Hero — remove "Premium Prep Platform" subtitle ──
c = c.replace(
  "<div style={{fontSize:12,color:'rgba(160,200,240,0.7)',marginTop:3}}>ProveRank · NEET / JEE / CUET · Premium Prep Platform</div>",
  "<div style={{fontSize:12,color:'rgba(160,200,240,0.7)',marginTop:3}}>NEET / JEE / CUET · Free Platform</div>"
);

// ── FIX 3: Hero title — center align ──
c = c.replace(
  "display:'flex',alignItems:'center',gap:14,marginBottom:8,flexWrap:'wrap'",
  "display:'flex',alignItems:'center',gap:14,marginBottom:8,flexWrap:'wrap',justifyContent:'center',textAlign:'center'"
);

// ── FIX 4: Remove "Total Students" and "Top Rankers" stat cards, keep Test Series (dynamic) ──
// Replace the static stats array with just 2 cards (Test Series from API, Free)
c = c.replace(
  `{[{i:'📚',v:'120+',l:'Test Series'},{i:'👥',v:'50K+',l:'Students'},{i:'🏆',v:'5K+',l:'Top Rankers'},{i:'🆓',v:'Free',l:'Available'}].map((s,i)=>(`,
  `{[{i:'📚',v:batches.length>0?batches.length+'+':'--',l:'Test Series'},{i:'🆓',v:'Free',l:'Available'}].map((s,i)=>(`
);

// ── FIX 5: NCERT Facts — max 2, no card/box, transparent SVG style ──
// Replace the full facts grid with 2 transparent facts
const oldFacts = `        {/* ━━ NCERT SCIENCE FACTS ━━ */}
        <div style={{marginTop:50}}>
          <div style={{textAlign:'center',marginBottom:22}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:24,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:6}}>🔬 NCERT Science Facts</div>
            <div style={{fontSize:12,color:'rgba(160,200,240,0.6)'}}>Essential concepts for NEET 2026 — 100% NCERT Based</div>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:14}}>
            {FACTS.map((f,i)=>(
              <div key={i} style={{background:'rgba(4,12,30,0.95)',border:\`1px solid \${f.c}22\`,borderRadius:18,padding:18,backdropFilter:'blur(20px)',transition:'all 0.3s',animation:\`slideUp \${1.0+i*0.08}s ease\`,boxShadow:'0 4px 20px rgba(0,10,40,0.3)'}}
                onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'44'}}
                onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='';(e.currentTarget as HTMLDivElement).style.borderColor=f.c+'22'}}>
                <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>
                  <div style={{fontSize:28,filter:\`drop-shadow(0 0 10px \${f.c})\`,flexShrink:0}}>{f.icon}</div>
                  <div>
                    <div style={{fontWeight:700,color:f.c,fontSize:13,marginBottom:5,fontFamily:'Playfair Display,serif'}}>{f.t}</div>
                    <div style={{fontSize:11,color:'rgba(180,210,240,0.75)',lineHeight:1.65}}>{f.f}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>`;

const newFacts = `        {/* ━━ NCERT SCIENCE FACTS (2 max, transparent) ━━ */}
        <div style={{marginTop:50}}>
          <div style={{textAlign:'center',marginBottom:28}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:5}}>🔬 NCERT Facts</div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.5)'}}>NEET 2026 — 100% NCERT Based</div>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))',gap:24,maxWidth:700,margin:'0 auto'}}>
            {FACTS.slice(0,2).map((f,i)=>(
              <div key={i} style={{display:'flex',gap:14,alignItems:'flex-start',padding:'4px 0',animation:\`slideUp \${1.0+i*0.1}s ease\`}}>
                <div style={{fontSize:34,filter:\`drop-shadow(0 0 14px \${f.c}88)\`,flexShrink:0}}>{f.icon}</div>
                <div>
                  <div style={{fontWeight:700,color:f.c,fontSize:13,marginBottom:5,fontFamily:'Playfair Display,serif'}}>{f.t}</div>
                  <div style={{fontSize:11,color:'rgba(180,210,240,0.65)',lineHeight:1.7}}>{f.f}</div>
                </div>
              </div>
            ))}
          </div>
        </div>`;

if (c.includes('/* ━━ NCERT SCIENCE FACTS ━━ */')) {
  c = c.replace(oldFacts, newFacts);
  console.log('✅ NCERT Facts fixed');
} else {
  // fallback — replace the facts section differently
  c = c.replace(
    /\{\/\* ━━ NCERT SCIENCE FACTS ━━ \*\/\}[\s\S]*?\{\/\* ━━ WHY PROVERANK/,
    newFacts + '\n\n        {/* ━━ WHY PROVERANK'
  );
  console.log('✅ NCERT Facts fixed (fallback)');
}

fs.writeFileSync(fp, c);
console.log('✅ All fixes written to page.tsx');
NODEEOF

echo ""
echo "=== Step 2: Add PRLogo + Back/Hamburger to Test Series page ==="

node << 'NODEEOF2'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// ── FIX 6: Add PRLogo import + useRouter + back button at top of page ──
// Add router import
if (!c.includes("import{useState,useEffect,useRef,useCallback,useContext}")) {
  c = c.replace(
    "import{useState,useEffect,useRef,useCallback}from'react'",
    "import{useState,useEffect,useRef,useCallback}from'react'\nimport{useRouter}from'next/navigation'"
  );
}

// Add useRouter inside component
if (!c.includes("const router=useRouter()")) {
  c = c.replace(
    "const[batches,setBatches]=useState<Batch[]>([])",
    "const router=useRouter()\n  const[batches,setBatches]=useState<Batch[]>([])"
  );
}

// Add PRLogo component if not present
if (!c.includes("function PRLogo")) {
  const prlogo = `
// ━━ PR LOGO ━━
function PRLogo({size=36}:{size?:number}){
  const b=Math.round(size*0.94),p=Math.round(b*0.63),f=Math.round(p*0.52),radius=Math.round(p*0.28)
  return(
    <div style={{position:'relative',width:b,height:b,flexShrink:0,display:'inline-flex'}}>
      <div style={{position:'absolute',top:0,left:0,width:p,height:p,borderRadius:radius,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#030810',boxShadow:'0 4px 16px rgba(77,159,255,0.4)'}}><span>P</span></div>
      <div style={{position:'absolute',bottom:0,right:0,width:p,height:p,borderRadius:radius,background:'rgba(0,212,255,0.15)',border:'1.5px solid rgba(0,212,255,0.45)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:f,fontWeight:900,fontFamily:'Inter,sans-serif',color:'#00D4FF',backdropFilter:'blur(8px)'}}><span>R</span></div>
    </div>
  )
}

`;
  c = prlogo + c;
}

// ── FIX 7: Add sticky top bar with back button + logo + title ──
const heroStart = `      <div style={{position:'relative',zIndex:2,padding:'16px 14px 80px',maxWidth:1200,margin:'0 auto'}}>

        {/* ━━ HERO BANNER ━━ */}`;

const heroWithTopBar = `      <div style={{position:'relative',zIndex:2,padding:'0 0 80px',maxWidth:1200,margin:'0 auto'}}>

        {/* ━━ TOP NAV BAR ━━ */}
        <div style={{position:'sticky',top:0,zIndex:50,background:'rgba(2,8,22,0.92)',backdropFilter:'blur(20px)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'10px 14px',display:'flex',alignItems:'center',gap:12,marginBottom:16}}>
          <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:18,flexShrink:0,transition:'all 0.2s'}}
            onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
            onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>
            ←
          </button>
          <PRLogo size={32}/>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>Test Series & Batches</div>
            <div style={{fontSize:10,color:'rgba(160,200,240,0.5)'}}>ProveRank · NEET / JEE / CUET</div>
          </div>
        </div>

        <div style={{padding:'0 14px'}}>

        {/* ━━ HERO BANNER ━━ */}`;

c = c.replace(heroStart, heroWithTopBar);

// Close the extra div at end of main content
c = c.replace(
  '</div>\n    </div>\n  )\n}',
  '</div>\n        </div>\n    </div>\n  )\n}'
);

fs.writeFileSync(fp, c);
console.log('✅ PRLogo + Back button + TopNav added');
NODEEOF2

echo ""
echo "=== Step 3: Git push ==="
cd ~/workspace && git add -A && git commit -m "fix: Test Series batch1 — back btn, PRLogo, remove red section, 2 transparent facts, remove extra stat cards, center hero" && git push origin main

echo ""
echo "=== ALL DONE — Vercel deploy in ~2 min ==="
