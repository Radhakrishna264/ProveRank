const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/exam/[id]/page.tsx';
let lines=fs.readFileSync(fp,'utf8').split('\n');

for(let i=225;i<230;i++){
  if(lines[i]&&lines[i].includes('renderLatex(q.text||q.question')&&lines[i].includes('/>')){
    console.log('Before: '+lines[i].trim());
    lines[i]=lines[i].replace(/\/>.*$/,'/>');
    console.log('After:  '+lines[i].trim());
    break;
  }
}

fs.writeFileSync(fp,lines.join('\n'));
console.log('✅ Done');
