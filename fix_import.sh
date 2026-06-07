#!/bin/bash
set -e
echo "🔧 Fix: StoreAdminTab import"

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

echo "── Current import status ──"
grep -n "StoreAdminTab\|import.*Store" $FILE | head -10

echo ""
echo "── StoreAdminTab.tsx exists? ──"
ls -la ~/workspace/frontend/app/admin/x7k2p/StoreAdminTab.tsx 2>/dev/null || echo "❌ FILE NOT FOUND"

node << 'EOF'
const fs = require('fs');
const path = require('path');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
const tabFile = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/StoreAdminTab.tsx';

// Check StoreAdminTab.tsx exists
if (!fs.existsSync(tabFile)) {
  console.log('❌ StoreAdminTab.tsx missing! Need to recreate it.');
  process.exit(1);
}
console.log('✅ StoreAdminTab.tsx exists, size:', fs.statSync(tabFile).size, 'bytes');

let c = fs.readFileSync(file, 'utf-8');

// Check if import exists
const hasImport = c.includes("import StoreAdminTab") || c.includes("import { StoreAdminTab");
console.log('Import exists:', hasImport);

if (!hasImport) {
  // Add import at the very top after 'use client'
  if (c.startsWith("'use client'")) {
    c = c.replace("'use client';", "'use client';\nimport StoreAdminTab from './StoreAdminTab';");
    console.log("✅ Import added after 'use client'");
  } else if (c.includes('"use client"')) {
    c = c.replace('"use client";', '"use client";\nimport StoreAdminTab from \'./StoreAdminTab\';');
    console.log('✅ Import added after "use client"');
  } else {
    // Add at very beginning
    c = "import StoreAdminTab from './StoreAdminTab';\n" + c;
    console.log('✅ Import added at top');
  }
  fs.writeFileSync(file, c);
  console.log('✅ File saved');
} else {
  // Import exists but might have wrong syntax - verify and fix
  const importLine = c.split('\n').find(l => l.includes('StoreAdminTab'));
  console.log('Current import line:', importLine);
  
  // Make sure it's the correct import format
  if (!importLine?.includes("from './StoreAdminTab'")) {
    // Fix the import
    c = c.replace(/import.*StoreAdminTab.*\n/, "import StoreAdminTab from './StoreAdminTab';\n");
    fs.writeFileSync(file, c);
    console.log('✅ Import fixed');
  } else {
    console.log('ℹ️  Import looks correct already');
    // Maybe the component file has an issue - check export
    const tabContent = fs.readFileSync(tabFile, 'utf-8');
    const hasDefaultExport = tabContent.includes('export default');
    console.log('StoreAdminTab has default export:', hasDefaultExport);
  }
}

// Final verify
const finalContent = fs.readFileSync(file, 'utf-8');
const importLine = finalContent.split('\n').find(l => l.includes('StoreAdminTab'));
console.log('\nFinal import line:', importLine?.trim());
EOF

echo ""
echo "── Git push ──"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix: add missing StoreAdminTab import in admin page.tsx"
git push origin main
echo "✅ Pushed!"
