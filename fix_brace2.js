const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');

for(let i=2845;i<2855;i++){
  if(lines[i]&&lines[i].includes("renderLatex(q.explanation||'')}")){
    console.log('Line '+(i+1)+': '+lines[i].trim());
    lines[i]=lines[i].replace(
      "renderLatex(q.explanation||'')}}}/>",
      "renderLatex(q.explanation||'')}}/>}"
    );
    console.log('✅ Fixed to: '+lines[i].trim());
    break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
