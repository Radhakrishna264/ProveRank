#!/bin/bash
PROF_F=$(find . -path "*/dashboard/profile/page.tsx" | grep -v node_modules | head -1)
echo "Profile: $PROF_F"
export PROF_F

node << 'JSEOF'
const fs = require('fs');
const f  = process.env.PROF_F;
let c = fs.readFileSync(f,'utf8');
const lines = c.split('\n');

// ── Show lines 60-80 for diagnosis ──────────────────────
console.log('\n── Lines 60-80 (current state):');
for(let i=59;i<Math.min(80,lines.length);i++){
  console.log((i+1)+'| '+lines[i]);
}

// ── Show where return( or return ( is ───────────────────
for(let i=0;i<lines.length;i++){
  if(lines[i].trim().startsWith('return')){
    console.log('\nReturn statement at line '+(i+1)+': '+lines[i].trim().slice(0,50));
    break;
  }
}

// ── Show prefs section ───────────────────────────────────
for(let i=0;i<lines.length;i++){
  if(lines[i].includes('Preferences') && lines[i].includes('/*')){
    console.log('Prefs comment at line '+(i+1)+': '+lines[i].trim());
  }
  if(lines[i].includes("tab==='prefs'") || lines[i].includes('tab===\'prefs\'')){
    console.log('Tab check at line '+(i+1)+': '+lines[i].trim().slice(0,60));
  }
}
console.log('\n');

// ── STEP 1: Clean ALL bad injections at wrong positions ──
// Remove any JSX block that's in const declarations area (before return)
let returnLineIdx = -1;
for(let i=0;i<lines.length;i++){
  if(lines[i].trim().match(/^return\s*\(/) || lines[i].trim() === 'return ('){
    returnLineIdx = i; break;
  }
}
console.log('return statement at line:', returnLineIdx+1);

// Remove any {tab=== block that appears before return
if(returnLineIdx > 0){
  const beforeReturn = lines.slice(0, returnLineIdx);
  let cleanLines = [];
  let skip = false;
  for(let i=0;i<beforeReturn.length;i++){
    const l = beforeReturn[i];
    if(!skip && (l.includes("{tab===") && !l.includes('useState') && !l.includes('//'))){
      skip = true;
      console.log('Found bad block at line', i+1, '— removing...');
    }
    if(skip){
      if(l.trim() === ')}' || l.trim() === ')}{' || (l.includes(')}') && !l.includes('{'))){
        skip = false; // end of bad block
        console.log('Bad block ends at line', i+1);
        continue;
      }
      continue; // skip this line
    }
    cleanLines.push(l);
  }
  // Reassemble
  c = [...cleanLines, ...lines.slice(returnLineIdx)].join('\n');
  console.log('✅ Pre-return cleanup done. Lines removed:', (returnLineIdx - cleanLines.length));
}

// ── STEP 2: Find injection point in JSX ─────────────────
const newLines = c.split('\n');
let newReturnIdx = -1;
for(let i=0;i<newLines.length;i++){
  if(newLines[i].trim().match(/^return\s*[\(]/)){
    newReturnIdx = i; break;
  }
}

// Find prefs tab closing - look for the last </div> inside prefs section
// Try multiple prefs identifiers
let prefsStartLine = -1;
for(let i=newReturnIdx;i<newLines.length;i++){
  const l = newLines[i];
  if(l.includes('Preferences Tab') ||
     l.includes("tab==='prefs'") ||
     l.includes('Notification Preferences') ||
     l.includes("'prefs'")&&l.includes('&&(')){
    prefsStartLine = i;
    console.log('Prefs section found at line', i+1, ':', l.trim().slice(0,50));
    break;
  }
}

let injected = false;

if(prefsStartLine !== -1){
  // Find next tab section after prefs
  let nextTabLine = newLines.length;
  for(let i=prefsStartLine+1;i<newLines.length;i++){
    const l=newLines[i];
    if((l.includes('tab===') && l.includes('&&(') && i > prefsStartLine+5) ||
       (l.includes('{/* ──') && l.includes('Tab') && i > prefsStartLine+5)){
      nextTabLine = i; break;
    }
  }
  console.log('Next tab at line:', nextTabLine+1);

  // Find last </div> inside prefs block (before nextTabLine)
  let insertLine = -1;
  for(let i=nextTabLine-1;i>prefsStartLine;i--){
    if(newLines[i].includes('</div>') && !newLines[i].includes('{/*')){
      insertLine = i;
      break;
    }
  }
  console.log('Inject before line:', insertLine+1, ':', (newLines[insertLine]||'').trim().slice(0,30));

  if(insertLine !== -1){
    const PICKER_LINES = [
      "          {/* 🎨 Color Theme Picker */}",
      "          <div style={{borderTop:'1px solid '+C.border,paddingTop:18,marginTop:6}}>",
      "            <div style={{fontSize:13,fontWeight:700,color:C.primary,marginBottom:14}}>🎨 {t('App Color Theme','ऐप कलर थीम')}</div>",
      "            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10}}>",
      "              {[",
      "                {id:'white',lbl:'Pure White',bg:'#FFFFFF',acc:'#2563EB',ico:'☀️'},",
      "                {id:'dark', lbl:'Pure Dark', bg:'#0A0A0A',acc:'#4D9FFF',ico:'🌑'},",
      "                {id:'teal', lbl:'Neon Teal',  bg:'linear-gradient(135deg,#001A1A,#002E2E)',acc:'#2DD4BF',ico:'🌊'},",
      "              ].map((th)=>",
      "                <button key={th.id} onClick={()=>applyTheme(th.id as any)}",
      "                  style={{background:th.bg,border:'2px solid '+(activeTheme===th.id?th.acc:'rgba(255,255,255,0.08)'),borderRadius:14,padding:'12px 6px',cursor:'pointer',textAlign:'center',transition:'all .2s',position:'relative',minHeight:82,boxShadow:activeTheme===th.id?('0 0 18px '+th.acc+'55'):'none'}}>",
      "                  {activeTheme===th.id&&<span style={{position:'absolute',top:5,right:7,fontSize:10,color:th.acc,fontWeight:800}}>✓</span>}",
      "                  <div style={{fontSize:20,marginBottom:4}}>{th.ico}</div>",
      "                  <div style={{fontSize:11,fontWeight:700,color:th.acc}}>{th.lbl}</div>",
      "                </button>",
      "              )}",
      "            </div>",
      "            <div style={{fontSize:10,color:C.sub,textAlign:'center',marginTop:8}}>{t('Theme applies to all student pages','थीम सभी पेजों पर लागू')}</div>",
      "          </div>",
    ];
    newLines.splice(insertLine, 0, ...PICKER_LINES);
    c = newLines.join('\n');
    injected = true;
    console.log('✅ Theme picker injected at line', insertLine+1);
  }
}

if(!injected){
  console.log('⚠️  Could not find prefs section. Content around return:');
  const rl = newLines.findIndex(l=>l.trim().match(/^return\s*[\(]/));
  for(let i=rl;i<Math.min(rl+20,newLines.length);i++){
    console.log((i+1)+'|'+newLines[i]);
  }
}

fs.writeFileSync(f, c);

// ── Verify ───────────────────────────────────────────────
const v = fs.readFileSync(f,'utf8');
const vLines = v.split('\n');
const retL = vLines.findIndex(l=>l.trim().match(/^return\s*[\(]/));
const pkL  = vLines.findIndex(l=>l.includes('Color Theme Picker'));
console.log('\nreturn at line:', retL+1, '| picker at line:', pkL+1);
console.log('picker AFTER return:', pkL > retL && pkL !== -1 ? '✅':'❌');
console.log('pr_color_theme:', v.includes('pr_color_theme') ? '✅':'❌');
console.log('3 theme buttons:', v.includes('Pure White') && v.includes('Neon Teal') ? '✅':'❌');
JSEOF

echo ""
echo "If picker AFTER return ✅, run:"
echo "git add . && git commit -m 'fix: Profile theme picker' && git push"
