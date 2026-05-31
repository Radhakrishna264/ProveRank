const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/demo/attempt/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');

for(let i=260;i<270;i++){
  if(lines[i]&&lines[i].includes('renderLatex(String(opt')){
    // Replace entire span with correct version
    lines[i]=lines[i].replace(
      /<span dangerouslySetInnerHTML=\{\{__html:renderLatex\(String\(opt\|\|''\)+\}\}>.*<\/span>/,
      `<span dangerouslySetInnerHTML={{__html:renderLatex(String(opt||''))}}></span>`
    );
    console.log('✅ Fixed: '+lines[i].trim());
    break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
