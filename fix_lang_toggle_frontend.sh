#!/bin/bash
set -e
echo "=== Fix: Add Language Toggle to Question Bank Preview (page.tsx) ==="

cat > /tmp/fix_lang_toggle.js << 'JSEOF'
const fs = require('fs');
const path = require('path');

const filePath = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx');
let code = fs.readFileSync(filePath, 'utf8');
let changeCount = 0;

function replace(old, nw, label) {
  if (!code.includes(old)) {
    console.log('⚠️  [' + label + '] Pattern not found — skipping');
    return;
  }
  code = code.replace(old, nw);
  changeCount++;
  console.log('✅ [' + label + '] Applied');
}

// ──────────────────────────────────────────────────────────────
// CHANGE 1: Add qLang state after stdPrv state
// ──────────────────────────────────────────────────────────────
replace(
  `const [stdPrv,setStdPrv]=useState(false)`,
  `const [stdPrv,setStdPrv]=useState(false)
  const [qLang,setQLang]=useState(function(){try{return localStorage.getItem('pr_qb_lang')||'en'}catch(e){return 'en'}})`,
  'Add qLang state'
);

// ──────────────────────────────────────────────────────────────
// CHANGE 2: Add EN/HI toggle button in Preview All header
//           (after the 🎓 Student View button)
// ──────────────────────────────────────────────────────────────
replace(
  `{stdPrv?'🎓 ON':'🎓 View'}</button>`,
  `{stdPrv?'🎓 ON':'🎓 View'}</button><button onClick={function(){var nl=qLang==='en'?'hi':'en';setQLang(nl);try{localStorage.setItem('pr_qb_lang',nl)}catch{}}} style={{padding:'5px 10px',borderRadius:7,fontSize:10,fontWeight:700,cursor:'pointer',transition:'all 0.2s',background:qLang==='hi'?'rgba(251,146,60,0.18)':'rgba(255,255,255,0.05)',color:qLang==='hi'?'#FB923C':'#94A3B8',border:'1px solid '+(qLang==='hi'?'rgba(251,146,60,0.45)':'rgba(255,255,255,0.1)')}} title={qLang==='hi'?'Switch to English':'Switch to Hindi'}>{qLang==='hi'?'🇮🇳 हिंदी ✓':'🌐 EN | हिंदी'}</button>`,
  'Add EN/HI toggle button'
);

// ──────────────────────────────────────────────────────────────
// CHANGE 3: Question card list — show hindi text when qLang=hi
//           Also add 🔄 translation pending indicator
// ──────────────────────────────────────────────────────────────
replace(
  `<div onClick={function(){setSelQId(q._id)}} style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.5,marginBottom:3,display:'-webkit-box',WebkitLineClamp:3,WebkitBoxOrient:'vertical',overflow:'hidden'}}>{(q.text||'').slice(0,90)}{(q.text||'').length>90?'…':''}</div>`,
  `<div onClick={function(){setSelQId(q._id)}} style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.5,marginBottom:3,display:'-webkit-box',WebkitLineClamp:3,WebkitBoxOrient:'vertical',overflow:'hidden'}}>
{(qLang==='hi'&&q.hindiText?q.hindiText:q.text||'').slice(0,90)}{(qLang==='hi'&&q.hindiText?q.hindiText:q.text||'').length>90?'…':''}
</div>
{qLang==='hi'&&!q.hindiText&&<div style={{fontSize:9,color:'#6366f1',marginTop:2,display:'flex',alignItems:'center',gap:3}}><span style={{display:'inline-block',width:6,height:6,borderRadius:'50%',background:'#6366f1',animation:'pulse 1.5s infinite'}}></span>हिंदी अनुवाद प्रतीक्षा में...</div>}`,
  'Question card hindi text'
);

// ──────────────────────────────────────────────────────────────
// CHANGE 4: stdPrv options — show hindiOptions when qLang=hi
// ──────────────────────────────────────────────────────────────
replace(
  `{(opt||'').replace(/^[A-Da-d][\\.\\)\\:]s*/,'').trim().slice(0,28)}{isC&&' ✓'}`,
  `{((qLang==='hi'&&(q.hindiOptions||[])[oi])?q.hindiOptions[oi]:opt||'').replace(/^[A-Da-d][\\.\\)\\:]\s*/,'').trim().slice(0,28)}{isC&&' ✓'}`,
  'stdPrv options hindi'
);

// ──────────────────────────────────────────────────────────────
// CHANGE 5: selQId modal — add language toggle + update text/options/explanation
// ──────────────────────────────────────────────────────────────

// 5a: Add language toggle row after the close button line in modal header
replace(
  `<button onClick={function(){setSelQId(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:10,padding:'11px 13px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}} dangerouslySetInnerHTML={{__html:renderLatex(formatQText(q.text||''))}}/>
                      {q.hindiText&&<div style={{fontSize:11,color:'#94A3B8',marginBottom:10,fontStyle:'italic',padding:'6px 11px',background:'rgba(255,255,255,0.02)',borderRadius:8}} dangerouslySetInnerHTML={{__html:renderLatex(q.hindiText||'')}}/>}`,
  `<button onClick={function(){setSelQId(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      {/* Language Toggle */}
                      <div style={{display:'flex',gap:6,marginBottom:10}}>
                        <button onClick={function(){setQLang('en');try{localStorage.setItem('pr_qb_lang','en')}catch{}}} style={{padding:'4px 12px',borderRadius:6,fontSize:10,fontWeight:700,cursor:'pointer',background:qLang==='en'?'rgba(77,159,255,0.22)':'rgba(255,255,255,0.04)',color:qLang==='en'?'#4D9FFF':'#64748B',border:'1px solid '+(qLang==='en'?'rgba(77,159,255,0.5)':'rgba(255,255,255,0.1)')}}>🇺🇸 English</button>
                        {q.hindiText
                          ?<button onClick={function(){setQLang('hi');try{localStorage.setItem('pr_qb_lang','hi')}catch{}}} style={{padding:'4px 12px',borderRadius:6,fontSize:10,fontWeight:700,cursor:'pointer',background:qLang==='hi'?'rgba(251,146,60,0.22)':'rgba(255,255,255,0.04)',color:qLang==='hi'?'#FB923C':'#64748B',border:'1px solid '+(qLang==='hi'?'rgba(251,146,60,0.5)':'rgba(255,255,255,0.1)')}}>🇮🇳 हिंदी</button>
                          :<span style={{fontSize:9,color:'#6366f1',display:'flex',alignItems:'center',gap:4,padding:'4px 10px',borderRadius:6,border:'1px solid rgba(99,102,241,0.25)',background:'rgba(99,102,241,0.06)'}}><span style={{width:6,height:6,borderRadius:'50%',background:'#6366f1',display:'inline-block'}}></span>हिंदी अनुवाद हो रहा है...</span>
                        }
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:10,padding:'11px 13px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}} dangerouslySetInnerHTML={{__html:renderLatex(formatQText(qLang==='hi'&&q.hindiText?q.hindiText:q.text||''))}}/>`,
  'Modal lang toggle + text'
);

// 5b: Update options display in modal to use hindiOptions when qLang=hi
replace(
  `<span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}} dangerouslySetInnerHTML={{__html:renderLatex((opt||'').replace(/^[A-Da-d][\\.\\)\\:]s*/,'').trim())}}></span>`,
  `<span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}} dangerouslySetInnerHTML={{__html:renderLatex(((qLang==='hi'&&(q.hindiOptions||[])[oi]?q.hindiOptions[oi]:opt)||'').replace(/^[A-Da-d][\\.\\)\\:]\s*/,'').trim())}}></span>`,
  'Modal options hindi'
);

// 5c: Update explanation in modal to use hindiExplanation when qLang=hi
replace(
  `{q.explanation&&<div style={{color:'#94A3B8',marginTop:4}} dangerouslySetInnerHTML={{__html:'💡 '+renderLatex(formatQText(q.explanation||''))}}/>}`,
  `{(q.explanation||q.hindiExplanation)&&<div style={{color:'#94A3B8',marginTop:4}} dangerouslySetInnerHTML={{__html:'💡 '+renderLatex(formatQText(qLang==='hi'&&q.hindiExplanation?q.hindiExplanation:q.explanation||''))}}/>}`,
  'Modal explanation hindi'
);

// ──────────────────────────────────────────────────────────────
// CHANGE 6: Add pulse animation CSS (if not already present)
// ──────────────────────────────────────────────────────────────
if (!code.includes('@keyframes pulse')) {
  // Add after the ncertpulse keyframes
  code = code.replace(
    `@keyframes ncertpulse{`,
    `@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.4}}@keyframes ncertpulse{`
  );
  changeCount++;
  console.log('✅ [Pulse animation] Added');
}

fs.writeFileSync(filePath, code, 'utf8');
console.log('');
console.log('=== Summary: ' + changeCount + ' changes applied ===');
console.log('✅ page.tsx updated with Hindi/English language toggle');
JSEOF

node /tmp/fix_lang_toggle.js
echo ""
echo "=== Frontend fix done! ==="
echo "Now do: cd ~/workspace/frontend && npm run build"
