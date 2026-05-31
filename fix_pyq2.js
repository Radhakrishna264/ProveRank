const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/pyq-bank/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');
let n=0;

for(let i=65;i<75;i++){
  if(lines[i]&&lines[i].includes('q.text||q.question')){
    console.log('Found at line '+(i+1)+': '+lines[i].trim());
    if(lines[i].includes('</div>')){
      lines[i]=lines[i].replace(` {q.text||q.question||'-'}</div>`,` <span dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/></div>`);
      n++;console.log('✅ Fixed single-line');
    } else {
      lines[i]=lines[i].replace(` {q.text||q.question||`,` <span dangerouslySetInnerHTML={{__html:renderLatex(q.text||q.question||'')}}/>`);
      if(lines[i+1]&&(lines[i+1].trim()===`'-'}</div>`||lines[i+1].trim()===`'-'}</div>`)){
        lines.splice(i+1,1);
        console.log('✅ Removed next line');
      }
      n++;console.log('✅ Fixed multi-line');
    }
    break;
  }
}

if(n===0)console.log('❌ Not found');
else{fs.writeFileSync(fp,lines.join('\n'));console.log('✅ Saved');}
