const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam-review/[id]/page.tsx';
let c=fs.readFileSync(fp,'utf8');
let n=0;

if(!c.includes("from '@/lib/renderLatex'")){
  c=c.replace(
    "const API = process.env.NEXT_PUBLIC_API_URL",
    "import { renderLatex } from '@/lib/renderLatex'\nconst API = process.env.NEXT_PUBLIC_API_URL"
  );
  n++;console.log('✅ Import added');
}

if(c.includes(`marginBottom:14}}>{q.text||q.question||'-'}</div>`)){
  c=c.replace(
    `marginBottom:14}}>{q.text||q.question||'-'}</div>`,
    `marginBottom:14}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>`
  );
  n++;console.log('✅ q.text fixed');
}else console.log('❌ q.text not found');

if(c.includes(`flex:1}}>{opt}</span>`)){
  c=c.replace(
    `flex:1}}>{opt}</span>`,
    `flex:1}} dangerouslySetInnerHTML={{__html:renderLatex(String(opt||''))}}></span>`
  );
  n++;console.log('✅ opt fixed');
}else console.log('❌ opt not found');

fs.writeFileSync(fp,c);
console.log(n+' fixes saved');
