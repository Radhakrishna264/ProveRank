const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/demo/attempt/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');

for(let i=260;i<270;i++){
  if(lines[i]&&lines[i].includes("renderLatex(String(opt||'')}}>")){
    lines[i]=lines[i].replace("renderLatex(String(opt||'')}}>",'renderLatex(String(opt||\'\')))}}> ');
    console.log('✅ Fixed at line '+(i+1)+': '+lines[i].trim());
    break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
