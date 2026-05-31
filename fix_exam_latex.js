const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/[id]/page.tsx';
let c=fs.readFileSync(fp,'utf8');
let n=0;

if(!c.includes("from '@/lib/renderLatex'")){
  c=c.replace(
    "const API = process.env.NEXT_PUBLIC_API_URL",
    "import { renderLatex } from '@/lib/renderLatex'\nconst API = process.env.NEXT_PUBLIC_API_URL"
  );
  n++;console.log('✅ Import added');
}

const qt_ml=`marginBottom:q.hindiText??0}}>{q.text||q.question||\n'-'}</div>`;
const qt_sl=`marginBottom:q.hindiText??0}}>{q.text||q.question||'-'}</div>`;
const qt_r=`marginBottom:q.hindiText??0}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>`;
if(c.includes(qt_ml)){c=c.replace(qt_ml,qt_r);n++;console.log('✅ q.text fixed');}
else if(c.includes(qt_sl)){c=c.replace(qt_sl,qt_r);n++;console.log('✅ q.text fixed');}
else console.log('❌ q.text not found');

if(c.includes(`fontStyle:'italic'}}>{q.hindiText}</div>}`)){
  c=c.replace(`fontStyle:'italic'}}>{q.hindiText}</div>}`,`fontStyle:'italic'}} dangerouslySetInnerHTML={{__html:renderLatex(q.hindiText||'')}}/>}`);
  n++;console.log('✅ hindiText fixed');
}else if(c.includes(`fontStyle:'italic'}}>{q.hindiText}</div>`)){
  c=c.replace(`fontStyle:'italic'}}>{q.hindiText}</div>`,`fontStyle:'italic'}} dangerouslySetInnerHTML={{__html:renderLatex(q.hindiText||'')}}/>`);
  n++;console.log('✅ hindiText fixed');
}else console.log('❌ hindiText not found');

if(c.includes(`fontSize:14,lineHeight:1.5}}>{opt}</span>`)){
  c=c.replace(`fontSize:14,lineHeight:1.5}}>{opt}</span>`,`fontSize:14,lineHeight:1.5}} dangerouslySetInnerHTML={{__html:renderLatex(String(opt||''))}}></span>`);
  n++;console.log('✅ opt fixed');
}else console.log('❌ opt not found');

fs.writeFileSync(fp,c);
console.log(n+' total fixes');
