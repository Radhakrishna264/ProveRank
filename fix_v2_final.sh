#!/bin/bash
set -e
cd ~/workspace/frontend

echo "=== Patching page.tsx ==="
node << 'JSEOF'
const fs = require('fs');
let c = fs.readFileSync('app/admin/x7k2p/page.tsx', 'utf8');

function rep(old, nw, label) {
  if (!c.includes(old)) { console.error('FAIL: ' + label + '\n  First 90: ' + old.substring(0,90)); process.exit(1); }
  const cnt = c.split(old).length - 1;
  if (cnt > 1) { console.error('MULTI(' + cnt + '): ' + label); process.exit(1); }
  c = c.replace(old, () => nw);
  console.log('  ✓ ' + label);
}

rep(
  `const [draftRestored,setDraftRestored]=useState(false)`,
  `const [draftRestored,setDraftRestored]=useState(false)
  const [optInit,setOptInit]=useState({a:'',b:'',c:'',d:''})
  const [optVals,setOptVals]=useState({a:'',b:'',c:'',d:''})`,
  'Add optInit + optVals states'
);

rep(
  `useEffect(()=>{const t=setInterval(()=>{setQTxtVal(qTxtR.current||'')},800);return ()=>clearInterval(t);},[]);`,
  `useEffect(()=>{const t=setInterval(()=>{setQTxtVal(qTxtR.current||'');setOptVals({a:qA.current||'',b:qB.current||'',c:qC.current||'',d:qD.current||''})},800);return ()=>clearInterval(t);},[]);`,
  'Interval: add optVals sync'
);

rep(
  `useEffect(()=>{const timer=setTimeout(()=>{const d={text:qTxtVal,subj:qSubj,diff:qDiff,type:qType,ans:qAns};if(d.text||d.subj){try{localStorage.setItem('pr_q_draft',JSON.stringify(d));setDraftSaved(true);setTimeout(()=>setDraftSaved(false),2000)}catch(ex){}}},2000);return ()=>clearTimeout(timer);},[qTxtVal,qSubj,qDiff,qType,qAns]);`,
  `useEffect(()=>{const timer=setTimeout(()=>{const d={text:qTxtVal,subj:qSubj,diff:qDiff,type:qType,ans:qAns,hindi:qHindiR.current,chap:qChapR.current,topic:qTopicR.current,exp:qExpR.current,img:qImg,optA:qA.current,optB:qB.current,optC:qC.current,optD:qD.current};if(d.text||d.subj||d.hindi||d.chap||d.optA){try{localStorage.setItem('pr_q_draft',JSON.stringify(d));setDraftSaved(true);setTimeout(()=>setDraftSaved(false),2000)}catch(ex){}}},2000);return ()=>clearTimeout(timer);},[qTxtVal,qSubj,qDiff,qType,qAns,qHindi,qChap,qTopic,qExp,qImg]);`,
  'Autosave: all fields'
);

rep(
  `useEffect(()=>{try{const d=JSON.parse(localStorage.getItem('pr_q_draft')||'{}');if(d.text||d.subj){if(d.text){qTxtR.current=d.text;setQTxtVal(d.text);setQTxtInit(d.text);setFormKey(function(k){return k+1})}if(d.subj)setQSubj(d.subj);if(d.diff)setQDiff(d.diff);if(d.type)setQType(d.type);if(d.ans)setQAns(d.ans);setDraftRestored(true);setTimeout(()=>setDraftRestored(false),3000)}}catch(e){}},[]);`,
  `useEffect(()=>{try{const d=JSON.parse(localStorage.getItem('pr_q_draft')||'{}');if(d.text||d.subj||d.hindi||d.chap||d.optA){if(d.text){qTxtR.current=d.text;setQTxtVal(d.text);setQTxtInit(d.text)}if(d.subj)setQSubj(d.subj);if(d.diff)setQDiff(d.diff);if(d.type)setQType(d.type);if(d.ans)setQAns(d.ans);if(d.hindi){qHindiR.current=d.hindi;setQHindi(d.hindi)}if(d.chap){qChapR.current=d.chap;setQChap(d.chap)}if(d.topic){qTopicR.current=d.topic;setQTopic(d.topic)}if(d.exp){qExpR.current=d.exp;setQExp(d.exp)}if(d.img){qImageR.current=d.img;setQImg(d.img)}if(d.optA||d.optB||d.optC||d.optD){qA.current=d.optA||'';qB.current=d.optB||'';qC.current=d.optC||'';qD.current=d.optD||'';setOptInit({a:d.optA||'',b:d.optB||'',c:d.optC||'',d:d.optD||''})}setFormKey(function(k){return k+1});setDraftRestored(true);setTimeout(()=>setDraftRestored(false),3000)}}catch(e){}},[]);`,
  'Restore: all fields'
);

rep(`init='' onSet={function(v){qA.current=v}}`, `init={optInit.a} onSet={function(v){qA.current=v}}`, 'Option A init');
rep(`init='' onSet={function(v){qB.current=v}}`, `init={optInit.b} onSet={function(v){qB.current=v}}`, 'Option B init');
rep(`init='' onSet={function(v){qC.current=v}}`, `init={optInit.c} onSet={function(v){qC.current=v}}`, 'Option C init');
rep(`init='' onSet={function(v){qD.current=v}}`, `init={optInit.d} onSet={function(v){qD.current=v}}`, 'Option D init');

rep(
  `try{localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false)`,
  `try{localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false);setOptInit({a:'',b:'',c:'',d:''});setOptVals({a:'',b:'',c:'',d:''})`,
  'Submit reset: clear opts'
);

rep(
  `localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false);T('Form cleared')`,
  `localStorage.removeItem('pr_q_draft')}catch(e){};setQTxtVal('');setQTxtInit('');setLatexPrev(false);setOptInit({a:'',b:'',c:'',d:''});setOptVals({a:'',b:'',c:'',d:''});T('Form cleared')`,
  'Clear btn: clear opts'
);

rep(
  `{latexPrev&&<div style={{marginTop:6,padding:'8px 12px',background:'rgba(255,255,255,0.04)',borderRadius:6,border:'1px solid rgba(255,255,255,0.08)',color:'#E2E8F0',fontSize:13,lineHeight:1.6,minHeight:40}} dangerouslySetInnerHTML={{__html:renderLatex(qTxtVal)||'<span style="color:#475569;font-style:italic">Type $x^2$ above to preview math...</span>'}}/>}`,
  `{latexPrev&&<div style={{marginTop:6,padding:'10px 14px',background:'rgba(255,255,255,0.04)',borderRadius:6,border:'1px solid rgba(255,255,255,0.08)',color:'#E2E8F0',fontSize:13,lineHeight:1.8}}>
                    {qTxtVal&&<div style={{marginBottom:6}}><span style={{color:'#A78BFA',fontSize:10,fontWeight:700,marginRight:6}}>ENG</span><span dangerouslySetInnerHTML={{__html:renderLatex(qTxtVal)}}/></div>}
                    {qHindi&&<div style={{marginBottom:6}}><span style={{color:'#60A5FA',fontSize:10,fontWeight:700,marginRight:6}}>HIN</span><span dangerouslySetInnerHTML={{__html:renderLatex(qHindi)}}/></div>}
                    {optVals.a&&<div style={{marginBottom:4}}><span style={{color:'#34D399',fontSize:10,fontWeight:700,marginRight:6}}>A</span><span dangerouslySetInnerHTML={{__html:renderLatex(optVals.a)}}/></div>}
                    {optVals.b&&<div style={{marginBottom:4}}><span style={{color:'#34D399',fontSize:10,fontWeight:700,marginRight:6}}>B</span><span dangerouslySetInnerHTML={{__html:renderLatex(optVals.b)}}/></div>}
                    {optVals.c&&<div style={{marginBottom:4}}><span style={{color:'#34D399',fontSize:10,fontWeight:700,marginRight:6}}>C</span><span dangerouslySetInnerHTML={{__html:renderLatex(optVals.c)}}/></div>}
                    {optVals.d&&<div style={{marginBottom:4}}><span style={{color:'#34D399',fontSize:10,fontWeight:700,marginRight:6}}>D</span><span dangerouslySetInnerHTML={{__html:renderLatex(optVals.d)}}/></div>}
                    {qExp&&<div style={{marginTop:4}}><span style={{color:'#FCD34D',fontSize:10,fontWeight:700,marginRight:6}}>EXP</span><span dangerouslySetInnerHTML={{__html:renderLatex(qExp)}}/></div>}
                    {!qTxtVal&&!qHindi&&!optVals.a&&<span style={{color:'#475569',fontStyle:'italic',fontSize:12}}>Type \$x^2\$ in any field to preview math...</span>}
                  </div>}`,
  'LaTeX preview: all fields'
);

fs.writeFileSync('app/admin/x7k2p/page.tsx', c);
console.log('\nAll 11 fixes applied!');
JSEOF

echo ""
echo "=== Verify ==="
grep -n "optInit\|optVals\|qHindiR.current\|optA\|optInit.a\|optInit.b" app/admin/x7k2p/page.tsx | head -15

echo ""
echo "=== Git push ==="
git add -A
git commit -m "feat: autosave all fields + LaTeX preview all text fields"
GIT_ASKPASS='' git push origin HEAD:main
echo ""
echo "DONE! ~3 min deploy"
