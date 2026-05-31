const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/pyq-bank/page.tsx';
let c=fs.readFileSync(fp,'utf8');
let n=0;

if(!c.includes("from '@/lib/renderLatex'")){
  c=c.replace(
    "const API = process.env.NEXT_PUBLIC_API_URL",
    "import { renderLatex } from '@/lib/renderLatex'\nconst API = process.env.NEXT_PUBLIC_API_URL"
  );
  n++;console.log('✅ Import added');
}

if(c.includes(` {q.text||q.question||'-'}</div>`)){
  c=c.replace(
    ` {q.text||q.question||'-'}</div>`,
    ` <span dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/></div>`
  );
  n++;console.log('✅ q.text fixed');
}else console.log('❌ q.text not found');

fs.writeFileSync(fp,c);
console.log(n+' fixes saved');
