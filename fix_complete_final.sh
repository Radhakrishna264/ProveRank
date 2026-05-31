#!/bin/bash
set -e
cd ~/workspace/frontend

echo "=== Applying fixes ==="
node << 'JSEOF'
const fs = require('fs');
let c = fs.readFileSync('app/admin/x7k2p/page.tsx', 'utf8');

function rep(old, nw, label) {
  if (!c.includes(old)) { console.error('FAIL: ' + label); process.exit(1); }
  const cnt = c.split(old).length - 1;
  if (cnt > 1) { console.error('MULTI(' + cnt + '): ' + label); process.exit(1); }
  c = c.replace(old, () => nw);
  console.log('  v ' + label);
}

rep(
  `useEffect(()=>{const t=setInterval(()=>{setQTxtVal(qTxtR.current||'')},800);return ()=>clearInterval(t);},[]);`,
  `useEffect(()=>{const t=setInterval(()=>{setQTxtVal(qTxtR.current||'');setOptVals({a:qA.current||'',b:qB.current||'',c:qC.current||'',d:qD.current||''})},800);return ()=>clearInterval(t);},[]);`,
  'Interval: optVals sync added'
);

rep(
  `useEffect(()=>{const timer=setTimeout(()=>{const d={text:qTxtVal,subj:qSubj,diff:qDiff,type:qType,ans:qAns};if(d.text||d.subj){try{localStorage.setItem('pr_q_draft',JSON.stringify(d));setDraftSaved(true);setTimeout(()=>setDraftSaved(false),2000)}catch(ex){}}},2000);return ()=>clearTimeout(timer);},[qTxtVal,qSubj,qDiff,qType,qAns]);`,
  `useEffect(()=>{const timer=setTimeout(()=>{const d={text:qTxtVal,subj:qSubj,diff:qDiff,type:qType,ans:qAns,hindi:qHindi,chap:qChap,topic:qTopic,exp:qExp,img:qImg,optA:qA.current,optB:qB.current,optC:qC.current,optD:qD.current};if(d.text||d.subj||d.hindi||d.optA){try{localStorage.setItem('pr_q_draft',JSON.stringify(d));setDraftSaved(true);setTimeout(()=>setDraftSaved(false),2000)}catch(ex){}}},2000);return ()=>clearTimeout(timer);},[qTxtVal,qSubj,qDiff,qType,qAns,qHindi,qChap,qTopic,qExp,qImg]);`,
  'Autosave: all fields saved'
);

rep(
  `if(d.text||d.subj){if(d.text){qTxtR.current=d.text;setQTxtVal(d.text);setQTxtInit(d.text);setFormKey(function(k){return k+1})}if(d.subj)setQSubj(d.subj);if(d.diff)setQDiff(d.diff);if(d.type)setQType(d.type);if(d.ans)setQAns(d.ans);setDraftRestored(true);setTimeout(()=>setDraftRestored(false),3000)}}catch(e){}},[]);`,
  `if(d.text||d.subj||d.hindi||d.optA){if(d.text){qTxtR.current=d.text;setQTxtVal(d.text);setQTxtInit(d.text)}if(d.subj)setQSubj(d.subj);if(d.diff)setQDiff(d.diff);if(d.type)setQType(d.type);if(d.ans)setQAns(d.ans);if(d.hindi){qHindiR.current=d.hindi;setQHindi(d.hindi)}if(d.chap){qChapR.current=d.chap;setQChap(d.chap)}if(d.topic){qTopicR.current=d.topic;setQTopic(d.topic)}if(d.exp){qExpR.current=d.exp;setQExp(d.exp)}if(d.img)setQImg(d.img);if(d.optA||d.optB||d.optC||d.optD){qA.current=d.optA||'';qB.current=d.optB||'';qC.current=d.optC||'';qD.current=d.optD||'';setOptInit({a:d.optA||'',b:d.optB||'',c:d.optC||'',d:d.optD||''})}setFormKey(function(k){return k+1});setDraftRestored(true);setTimeout(()=>setDraftRestored(false),3000)}}catch(e){}},[]);`,
  'Restore: all fields restored'
);

['a','b','c','d'].forEach(function(x,i){
  const L=String.fromCharCode(65+i), ref='q'+L;
  const o=`init='' onSet={function(v){${ref}.current=v}}`;
  const n=`init={optInit.${x}} onSet={function(v){${ref}.current=v}}`;
  if(c.includes(o)){c=c.replace(o,()=>n);console.log('  v Option '+L+' init fixed');}
  else{console.log('  (Option '+L+' already ok)');}
});

fs.writeFileSync('app/admin/x7k2p/page.tsx', c);
console.log('\nAll fixes done!');
JSEOF

echo ""
echo "=== Verify ==="
grep -n "setOptVals\|optA.*current\|setQHindi(d\|optInit.a" app/admin/x7k2p/page.tsx | head -10

echo ""
echo "=== Git push ==="
git add -A
git commit -m "fix: autosave+restore all fields, optVals interval, options init"
GIT_ASKPASS='' git push origin HEAD:main
echo ""
echo "DONE! ~3 min deploy"
