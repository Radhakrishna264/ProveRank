const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

// DIAGNOSE
const gcTarget = 'title="Granular Permission Control"';
const gcIdx = c.indexOf(gcTarget);
console.log('GC found at:', gcIdx);
if(gcIdx > -1){
  const before = c.substring(Math.max(0,gcIdx-30), gcIdx);
  console.log('Before GC:', JSON.stringify(before));
}

// FIX: Restore <PageHero prefix if missing
if(gcIdx > -1){
  const before25 = c.substring(Math.max(0,gcIdx-25), gcIdx);
  if(!before25.includes('PageHero')){
    c = c.substring(0, gcIdx) + '<PageHero icon="\uD83D\uDD10" ' + c.substring(gcIdx);
    n++; console.log('F1 PASS: PageHero prefix restored!');
  } else {
    console.log('F1 INFO: PageHero already present:', before25.trim().slice(-20));
  }
}

fs.writeFileSync(fp, c);
console.log('\nFIX V5 DONE — '+n+' changes');
