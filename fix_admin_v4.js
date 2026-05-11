const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

const archComment = '{/* ===== ARCHIVED ADMINS SECTION (FIXED) ===== */}';
const archIdx = c.indexOf(archComment);
console.log('Archived section found at:', archIdx);

if(archIdx > -1){
  // Step 1: Find and remove the extra { before the comment
  let ci = archIdx - 1;
  while(ci >= 0 && '\n\r\t '.includes(c[ci])) ci--;
  console.log('Char before comment:', JSON.stringify(c[ci]));
  
  if(c[ci] === '{'){
    c = c.substring(0, ci) + c.substring(ci + 1);
    n++; console.log('F1 PASS: Removed extra { at pos ' + ci);
  } else {
    console.log('F1 INFO: No extra { found');
  }

  // Step 2: Find tab==='permissions' that's now missing its {
  const tabIdx = c.indexOf("tab==='permissions'&&(");
  if(tabIdx > -1){
    let ci2 = tabIdx - 1;
    while(ci2 >= 0 && '\n\r\t '.includes(c[ci2])) ci2--;
    console.log('Char before tab===:', JSON.stringify(c[ci2]));
    
    if(c[ci2] !== '{'){
      let iPos = tabIdx;
      while(iPos > 0 && '\n\r\t '.includes(c[iPos-1])) iPos--;
      c = c.substring(0, iPos) + '\n{' + c.substring(iPos);
      n++; console.log('F2 PASS: Added { back before tab===permissions');
    } else {
      console.log('F2 INFO: { already present');
    }
  } else {
    console.log('F2 WARN: tab=== not found');
  }
}

// Step 3: Fix any malformed style ,'center' from line breaks
const badStyle = "alignItems:'center','center'";
if(c.includes(badStyle)){
  c = c.replace(/alignItems:'center','center'/g, "alignItems:'center',justifyContent:'center'");
  n++; console.log('F3 PASS: Fixed malformed style object');
}

fs.writeFileSync(fp, c);
console.log('\nFIX V4 DONE — ' + n + ' changes');
