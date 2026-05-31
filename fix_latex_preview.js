const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let c=fs.readFileSync(fp,'utf8');
let n=0;
function rep(f,t){if(c.includes(f)){c=c.replace(f,t);n++;console.log('✅ Fixed #'+n);}else{console.log('❌ Not found: '+f.substring(0,50));}}

rep(
  `'rgba(255,255,255,0.06)'}}>{q.text}</div>`,
  `'rgba(255,255,255,0.06)'}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||'')}}/>`
);
rep(
  `borderRadius:8}}>{q.hindiText}</div>`,
  `borderRadius:8}} dangerouslySetInnerHTML={{__html:renderLatex(q.hindiText||'')}}/>`
);
rep(
  `color:lsC?'#E2E8F0':'#94A3B8'}}>{opt}</span>`,
  `color:lsC?'#E2E8F0':'#94A3B8'}} dangerouslySetInnerHTML={{__html:renderLatex(String(opt||''))}}></span>`
);
rep(
  `marginTop:4}}>💡 {q.explanation}</div>}`,
  `marginTop:4}} dangerouslySetInnerHTML={{__html:'💡 '+renderLatex(q.explanation||'')}}/>`
);

if(n>0){fs.writeFileSync(fp,c);console.log('\n✅ '+n+' fixes saved!');}
else{console.log('\n❌ 0 changes — strings not matched exactly');}
