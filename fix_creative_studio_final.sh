#!/bin/bash
echo "=== Creative Studio Final Fix ==="

node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// Step 1: Add to NAV array — after parent_portal entry, new group 'Creative'
c = c.replace(
  `{id:'parent_portal',ico:'👨‍👩‍👧',lbl:'Parent Portal',grp:'Tools'},`,
  `{id:'parent_portal',ico:'👨‍👩‍👧',lbl:'Parent Portal',grp:'Tools'},\n    {id:'creative_studio',ico:'🎨',lbl:'Creative Studio',grp:'Creative',alwaysShow:true},`
);

// Step 2: Handle creative_studio tab click — redirect to banner-generator page
// Find _setTab function definition or the setTab wrapper
// The sidebar button calls _setTab(n.id) — intercept creative_studio there
// Find the _setTab definition
if (c.includes('const _setTab=')) {
  c = c.replace(
    'const _setTab=',
    'const _setTab_orig='
  );
  // Add wrapper after
  c = c.replace(
    'const _setTab_orig=',
    `const _setTab=(id:string)=>{if(id==='creative_studio'){window.location.href='/admin/x7k2p/banner-generator';return;}_setTab_orig(id);}\n  const _setTab_orig=`
  );
  console.log('✅ _setTab wrapper added');
} else {
  // Fallback: find setTab call in sidebar and add condition
  c = c.replace(
    `onClick={()=>{_setTab(n.id);setSideOpen(false)}}`,
    `onClick={()=>{if(n.id==='creative_studio'){window.location.href='/admin/x7k2p/banner-generator';return;}_setTab(n.id);setSideOpen(false)}}`
  );
  console.log('✅ onClick intercept added');
}

fs.writeFileSync(fp, c);
console.log('✅ Done');
NODEEOF

cd ~/workspace && git add -A && git commit -m "feat: Creative Studio in sidebar — correct NAV entry + window.location redirect" && git push origin main
echo "=== DONE ==="
