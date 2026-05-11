const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

// FIX 1: &&{ → &&(
if(c.includes("tab==='permissions'&&{")){
  c = c.replace("tab==='permissions'&&{","tab==='permissions'&&(");
  n++; console.log('FIX1 PASS: &&{ fixed to &&(');
} else console.log('FIX1 SKIP: pattern not found');

// FIX 2: Restore <PageHero icon tag (was broken — only title="" remained)
const pgRe = /(\n[ \t]+)title="Granular Permission Control"/;
if(!c.includes('<PageHero') && pgRe.test(c)){
  c = c.replace(pgRe,'$1<PageHero icon="\uD83D\uDD10" title="Granular Permission Control"');
  n++; console.log('FIX2 PASS: PageHero icon+tag restored');
} else if(c.includes('<PageHero')){
  console.log('FIX2 SKIP: PageHero already present in file');
} else {
  console.log('FIX2 SKIP: broken title pattern not matched');
}

// FIX 3: closing }} → )} before RESULTS section
if(c.includes("}}\n{/* == RESULTS")){
  c = c.replace("}}\n{/* == RESULTS",")\n{/* == RESULTS");
  n++; console.log('FIX3 PASS: }} → )} at permissions end');
} else if(c.includes("}}\n  {/* == RESULTS")){
  c = c.replace("}}\n  {/* == RESULTS",")\n  {/* == RESULTS");
  n++; console.log('FIX3b PASS');
} else console.log('FIX3 SKIP: closing }} not found before RESULTS');

// FIX 4 (safety): marginTop:Top:16 typo
if(c.includes('marginTop:Top:16')){
  c = c.replace(/marginTop:Top:16/g,'marginTop:16');
  n++; console.log('FIX4 PASS: marginTop:Top:16 fixed');
} else console.log('FIX4 SKIP: marginTop ok');

fs.writeFileSync(fp,c);
console.log('\n✅ DONE — '+n+' fixes applied');
