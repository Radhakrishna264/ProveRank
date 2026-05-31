const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');
let n=0;

// Fix q.text - search around line 2834
for(let i=2828;i<2842;i++){
  if(lines[i]&&lines[i].includes('{q.text}</div>')){
    lines[i]=lines[i].replace('>{q.text}</div>',' dangerouslySetInnerHTML={{__html:renderLatex(q.text||\'\')}}/>');
    n++;console.log('✅ q.text fixed at line '+(i+1));break;
  }
}

// Fix {opt} - search around line 2845
for(let i=2838;i<2858;i++){
  if(lines[i]&&lines[i].includes('>{opt}</span>')){
    lines[i]=lines[i].replace('>{opt}</span>',' dangerouslySetInnerHTML={{__html:renderLatex(String(opt||\'\'))}}></span>');
    n++;console.log('✅ opt fixed at line '+(i+1));break;
  }
}

if(n===0)console.log('❌ Neither found - check line ranges');
else{fs.writeFileSync(fp,lines.join('\n'));console.log('✅ '+n+' fixes saved!');}
