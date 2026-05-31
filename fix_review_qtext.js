const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam-review/[id]/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');
let n=0;

for(let i=74;i<84;i++){
  if(lines[i]&&lines[i].includes('q.text||q.question')&&lines[i].includes('marginBottom:14')){
    if(lines[i].includes('</div>')){
      lines[i]=lines[i].replace(`>{q.text||q.question||'-'}</div>`,` dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>`);
      n++;console.log('✅ q.text single-line fixed at '+(i+1));
    } else {
      lines[i]=lines[i].replace(`q.text||q.question||`,'');
      lines[i]=lines[i].replace('marginBottom:14}}>',' marginBottom:14}} dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||\'\')}}/> ');
      if(lines[i+1]&&lines[i+1].trim()===`'-'}</div>`){
        lines.splice(i+1,1);
        console.log('✅ Removed continuation line');
      }
      n++;console.log('✅ q.text multi-line fixed at '+(i+1));
    }
    break;
  }
}

if(n===0)console.log('❌ Not found');
else{fs.writeFileSync(fp,lines.join('\n'));console.log('✅ Saved');}
