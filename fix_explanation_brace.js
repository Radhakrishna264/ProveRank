const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');

for(let i=2845;i<2855;i++){
  if(lines[i]&&lines[i].includes("renderLatex(q.explanation||'')}}/>")){
    if(!lines[i].trimEnd().endsWith('}}')){
      lines[i]=lines[i].replace("/>","}/>");
      console.log('✅ Fixed closing } at line '+(i+1));
    }else{
      console.log('Already correct at line '+(i+1));
    }
    break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
