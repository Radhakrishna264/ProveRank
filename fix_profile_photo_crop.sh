#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " FIX — Profile Photo zoomed-in/cropped-wrong bug"
echo "════════════════════════════════════════════════════════"

WORKDIR=$(mktemp -d); cd "$WORKDIR"

cat > fix_avatar_crop.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38 — Fix: Profile Photo shows zoomed-in/cropped weirdly
// Root cause: avatar resize used "letterbox/contain" (Math.min scale +
// solid-color padding) instead of "cover-crop" — non-square photos ended
// up mostly solid-color padding, which looked zoomed-in/wrong inside the
// circular avatar. This patch switches to a proper cover-crop resize.
// Run with: node fix_avatar_crop.js
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/app/dashboard',
  '/root/workspace/frontend/app',
  path.join(process.cwd(), 'frontend/app/dashboard'),
  path.join(process.cwd(), 'app/dashboard'),
].filter(Boolean);

let TARGET = null;
for (const dir of CANDIDATES) {
  const p = path.join(dir, 'profile', 'page.tsx');
  if (fs.existsSync(p)) { TARGET = p; break; }
}
if (!TARGET) {
  console.error('❌ Could not find profile/page.tsx automatically.');
  console.error('   Set APP_DIR env var to your app folder and re-run, e.g.:');
  console.error('   APP_DIR=/root/workspace/frontend/app/dashboard node fix_avatar_crop.js');
  process.exit(1);
}
console.log('📄 Target file:', TARGET);

let src = fs.readFileSync(TARGET, 'utf8');
const before = src;
let changed = false;

// ── Replacement 1: the core scale bug (contain → cover) ──
if (src.includes('Math.min(size/img.width, size/img.height)')) {
  src = src.replace(
    'Math.min(size/img.width, size/img.height)',
    'Math.max(size/img.width, size/img.height)'
  );
  changed = true;
  console.log('✅ Patched: resize scale changed from Math.min (contain) → Math.max (cover-crop)');
} else if (src.includes('Math.max(size/img.width, size/img.height)')) {
  console.log('⚠️  Scale already uses Math.max — already patched.');
} else {
  console.log('❌ Could not find the "Math.min(size/img.width, size/img.height)" scale line.');
}

// ── Replacement 2: remove the solid-color letterbox fill (no longer needed with cover-crop) ──
const fillBlockRegex = /\n[ \t]*ctx\.fillStyle\s*=\s*dm\s*\?[^\n]*\n[ \t]*ctx\.fillRect\(0,\s*0,\s*size,\s*size\)\s*\n/;
if (fillBlockRegex.test(src)) {
  src = src.replace(fillBlockRegex, '\n');
  changed = true;
  console.log('✅ Patched: removed solid-color letterbox fill (fillStyle/fillRect)');
} else if (!/ctx\.fillRect\(0,\s*0,\s*size,\s*size\)/.test(src)) {
  console.log('⚠️  Letterbox fill lines not found — likely already removed.');
} else {
  console.log('⚠️  Could not auto-remove the fillStyle/fillRect lines (pattern differs) — leaving them; they are now harmless since Math.max means the canvas gets fully covered by the photo anyway.');
}

if (changed) {
  fs.writeFileSync(TARGET, src);
  console.log('\n✅ File saved.');
} else if (src === before) {
  console.log('\n⚠️  No changes were needed/applied — see notes above.');
}
PRNODEEOF

echo "🚀 Running fix..."
node fix_avatar_crop.js

# ── Verification against the actual file ──
TARGET=""
for candidate in \
  "/root/workspace/frontend/app/dashboard/profile/page.tsx" \
  "/root/workspace/frontend/app/profile/page.tsx"; do
  if [ -f "$candidate" ]; then TARGET="$candidate"; break; fi
done
if [ -n "$TARGET" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo " VERIFICATION"
  echo "════════════════════════════════════════════════════════"
  if grep -qF "Math.max(size/img.width, size/img.height)" "$TARGET"; then
    echo "✅ Cover-crop fix confirmed in $TARGET"
  else
    echo "❌ Fix not found in $TARGET — please check manually"
  fi
  if grep -qF "fillRect(0, 0, size, size)" "$TARGET"; then
    echo "❌ Old letterbox padding code still present"
  else
    echo "✅ Old letterbox padding code removed"
  fi
fi

echo ""
echo "🎉 Done. Existing photos that were saved with the OLD buggy resize"
echo "   (already-uploaded avatars) will still look wrong until re-uploaded —"
echo "   this only fixes NEW uploads going forward."
echo "👉 Ask the student to open Profile → tap avatar → Upload New Photo again"
echo "   once, to re-save it with the corrected crop."
echo "👉 Restart your frontend (Replit Run button) to load the change."
