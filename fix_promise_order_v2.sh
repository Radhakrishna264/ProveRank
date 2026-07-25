#!/bin/bash
set -e
cd ~/workspace

echo "🔎 Step 0 — Verifying target file..."
if [ ! -f frontend/app/admin/x7k2p/page.tsx ]; then echo "❌ Missing page.tsx — abort"; exit 1; fi

echo "🗄️  Step 1 — Backup..."
mkdir -p .fix_backups
cp frontend/app/admin/x7k2p/page.tsx ".fix_backups/page.tsx.bak_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup saved"

echo "🛠️  Step 2 — Patching Promise.all array order (CRITICAL FIX — my earlier patch put"
echo "    the test-series fetch in the WRONG position, shifting au/rs/mn variables and"
echo "    breaking Admin Management / Results / Maintenance Mode data)..."

cat > /tmp/patch_order_fix.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Remove the wrongly-positioned test-series fetch (was inserted right after batches fetch)
must(
`      getFirst(\`\${API}/api/admin/batches\`,\`\${API}/api/admin/manage/batches\`),
      getFirst(\`\${API}/api/admin/test-series-manager?limit=200\`,\`\${API}/api/testseries\`),`,
`      getFirst(\`\${API}/api/admin/batches\`,\`\${API}/api/admin/manage/batches\`),`,
'remove misplaced test-series fetch from position 12'
);

// 2) Re-add it at the correct position — the very END of the array, matching
//    tsr's position (last) in the destructure: [...,mn,tsr]
must(
`      get(\`\${API}/api/admin/maintenance\`),
    ])`,
`      get(\`\${API}/api/admin/maintenance\`),
      getFirst(\`\${API}/api/admin/test-series-manager?limit=200\`,\`\${API}/api/testseries\`),
    ])`,
'add test-series fetch at correct last position (matches tsr in destructure)'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_order_fix.js

echo ""
echo "🔎 Step 3 — Verifying final order (should show batches, then admins/results/maintenance in ORIGINAL order, then test-series LAST)..."
grep -n "getFirst(\`\${API}/api/admin/batches\`\|get(\`\${API}/api/admin/manage/admins\`)\|getFirst(\`\${API}/api/results\`\|get(\`\${API}/api/admin/maintenance\`)\|test-series-manager" frontend/app/admin/x7k2p/page.tsx

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ CRITICAL ORDER BUG FIXED"
echo "═══════════════════════════════════════════════════"
echo "👉 Next steps:"
echo "   1. Verify the order above looks correct (batches → admins → results → maintenance → test-series LAST)"
echo "   2. git add -A && git commit -m 'Fix: Promise.all array position bug that broke admins/results/maintenance data' && git push"
echo "   3. Wait for Vercel redeploy, then hard-refresh browser and test:"
echo "      - Test Series dropdown (should now populate)"
echo "      - Admin Management tab (should show correct admins again)"
echo "      - Results tab (should show correct results again)"
echo "      - Maintenance Mode toggle (should show correct state again)"
