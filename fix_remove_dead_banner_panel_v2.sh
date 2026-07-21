#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX: Remove dead legacy "Banner Panel" widget from Batch/Series
# Overview tab. Its "Edit Banner" button links to the now-deleted
# /admin/x7k2p/banner-generator page -> 404 Page Not Found. The new
# 🖼️ Banner tab (built in Parts 1-7) fully replaces this.
#
# Uses REGEX matching (robust to minor formatting differences)
# instead of exact-string matching, with clear per-file reporting —
# if a section isn't found in a given file (e.g. already removed),
# it's skipped with a warning rather than crashing the whole script.
#
# REMOVED: BannerPanel call site + component (frontend, both files),
#          GET /:id/banner-panel + POST /:id/banner-panel/regenerate
#          (backend, both files).
# KEPT:    checkBannerGate() — still used by PUT /:id/controls to
#          actually enforce "no launch without a ready banner".
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_remove_banner_panel_v2.js << 'NODEEOF'
const fs = require('fs');

function removeByRegex(path, patterns) {
  let src = fs.readFileSync(path, 'utf8');
  let changed = false;
  for (const [label, re, replacement] of patterns) {
    if (re.test(src)) {
      src = src.replace(re, replacement);
      console.log(`✅ [${path}] removed: ${label}`);
      changed = true;
    } else {
      console.log(`⚠️  [${path}] not found (may already be removed): ${label}`);
    }
  }
  if (changed) fs.writeFileSync(path, src);
  return changed;
}

// ══════════════════════════════════════════
// Backend: remove GET+POST /:id/banner-panel* routes, keep checkBannerGate
// ══════════════════════════════════════════
const backendPattern = [
  'GET+POST /:id/banner-panel routes',
  /\n\/\/ [═=]+\n\/\/ FPR3 — BANNER PANEL[^\n]*\n\/\/ [═=]+\nrouter\.get\('\/:id\/banner-panel'[\s\S]*?\n\}\);\n\nrouter\.post\('\/:id\/banner-panel\/regenerate'[\s\S]*?\n\}\);\n/,
  '\n'
];

removeByRegex('src/routes/batchManagerUltra.js', [backendPattern]);
removeByRegex('src/routes/testSeriesManagerUltra.js', [backendPattern]);

// ══════════════════════════════════════════
// Frontend: remove <BannerPanel .../> call site + component definition
// ══════════════════════════════════════════
const callSitePattern = [
  '<BannerPanel .../> call site',
  /[ \t]*<BannerPanel[^/]*\/>\n/,
  ''
];
const componentPattern = [
  'BannerPanel component definition',
  /\n\/\/ ── FPR3: Banner Panel[^\n]*──\nfunction BannerPanel\([\s\S]*?\n\}\n/,
  '\n'
];

removeByRegex('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [callSitePattern, componentPattern]);
removeByRegex('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [callSitePattern, componentPattern]);

console.log('\n✅ Script finished (see per-file lines above for what was actually removed).');
NODEEOF

node /tmp/fix_remove_banner_panel_v2.js

echo ""
echo "=== Syntax validation ==="
node --check src/routes/batchManagerUltra.js && echo "✅ batchManagerUltra.js valid"
node --check src/routes/testSeriesManagerUltra.js && echo "✅ testSeriesManagerUltra.js valid"

echo ""
echo "=== Verify checkBannerGate still intact (function definition should still be present) ==="
grep -c "async function checkBannerGate" src/routes/batchManagerUltra.js src/routes/testSeriesManagerUltra.js

echo ""
echo "=== Final check: any remaining dead references? ==="
grep -n "banner-panel\|BannerPanel" src/routes/batchManagerUltra.js src/routes/testSeriesManagerUltra.js frontend/app/admin/x7k2p/BatchManagerUltra.tsx frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx && echo "⚠️ Some references remain — see above" || echo "✅ Clean — no references left"

echo ""
echo "✅ DONE. Git push karke deploy karo."
