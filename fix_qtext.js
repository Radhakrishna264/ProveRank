const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/[id]/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');
let n=0;

for(let i=220;i<235;i++){
  if(lines[i]&&lines[i].includes("q.hindiText?7:0}}>{q.text||q.question||'")){
    lines[i]=lines[i].replace(
      "q.hindiText?7:0}}>{q.text||q.question||'",
      "q.hindiText?7:0}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>"
    );
    if(lines[i+1]&&lines[i+1].trim()==="-'}</div>"){
      lines.splice(i+1,1);
      console.log('✅ Removed continuation line');
    }
    n++;console.log('✅ q.text fixed at line '+(i+1));
    break;
  }
}

if(n===0)console.log('❌ Not found');
else{fs.writeFileSync(fp,lines.join('\n'));console.log('✅ Saved!');}
