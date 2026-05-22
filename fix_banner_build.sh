#!/bin/bash
echo "=== Fix Banner Build Error ==="

# Fix 1: Wrap useSearchParams in Suspense boundary
node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/banner-generator/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// Add Suspense import
c = c.replace(
  "import { useState, useEffect, useRef, useCallback } from 'react'",
  "import { useState, useEffect, useRef, useCallback, Suspense } from 'react'"
);

// Rename main component to inner, wrap with Suspense in default export
c = c.replace(
  "export default function BannerGeneratorPage() {",
  "function BannerGeneratorInner() {"
);

// Add wrapper at end of file
c = c.replace(
  /^}\s*$/m,
  `}

export default function BannerGeneratorPage() {
  return (
    <Suspense fallback={<div style={{minHeight:'100vh',background:'#0a0e1a',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontSize:14}}>Loading...</div>}>
      <BannerGeneratorInner />
    </Suspense>
  )
}`
);

fs.writeFileSync(fp, c);
console.log('✅ Suspense wrapper added');
NODEEOF

# Fix 2: Rename nav tab label
node << 'NODEEOF2'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
c = c.replace(
  "label:'🎨 Banner Generator'",
  "label:'🎨 Creative Studio'"
);
fs.writeFileSync(fp, c);
console.log('✅ Nav label updated to Creative Studio');
NODEEOF2

cd ~/workspace && git add -A && git commit -m "fix: banner-generator Suspense boundary + rename to Creative Studio" && git push origin main
echo "=== DONE ==="
