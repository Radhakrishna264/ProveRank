const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/demo/attempt/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');
let c=lines.join('\n');
let n=0;

// Add import
if(!c.includes("from '@/lib/renderLatex'")){
  for(let i=0;i<5;i++){
    if(lines[i]&&lines[i].includes("from 'react'")){
      lines.splice(i+1,0,"import { renderLatex } from '@/lib/renderLatex'");
      n++;console.log('✅ Import added');break;
    }
  }
}

// Fix q.text line
for(let i=250;i<262;i++){
  if(lines[i]&&lines[i].trim()==='{q.text}'){
    lines[i]=lines[i].replace('{q.text}','<span dangerouslySetInnerHTML={{__html:renderLatex(q.text||\'\')}}/> ');
    n++;console.log('✅ q.text fixed at line '+(i+1));break;
  }
}

// Fix {opt} span
for(let i=260;i<275;i++){
  if(lines[i]&&lines[i].includes('<span>{opt}</span>')){
    lines[i]=lines[i].replace('<span>{opt}</span>','<span dangerouslySetInnerHTML={{__html:renderLatex(String(opt||\'\')||\'\'}}></span>');
    n++;console.log('✅ opt fixed at line '+(i+1));break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
console.log(n+' fixes saved');
