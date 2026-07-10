#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " FIX — Profile Photo thumbnail blank/corrupted at small size"
echo "════════════════════════════════════════════════════════"

WORKDIR=$(mktemp -d); cd "$WORKDIR"

cat > fix_avatar_img_tag.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38 — Fix: Profile Photo thumbnail shows blank/white/corrupted at
// small size while the large (200px) view shows it correctly.
//
// Root cause: avatar was rendered via CSS `background-image: url(data:...)`
// with `background-size:cover` at very small element sizes (72px/56px).
// This is a known mobile-Chrome data-URI decode/downscale rendering quirk —
// large base64 JPEGs sometimes fail to paint correctly when the target
// CSS background box is very small, while the same data renders fine at
// a larger size (200px modal).
//
// Fix: switch all 3 avatar render spots from CSS background-image to a
// real <img> tag with object-fit:cover — the standard, most reliably
// rendered approach across browsers/devices at any thumbnail size.
//
// Run with: node fix_avatar_img_tag.js
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/app/dashboard',
  '/root/workspace/frontend/app',
  '/home/runner/workspace/frontend/app',
  path.join(process.cwd(), 'frontend/app/dashboard'),
  path.join(process.cwd(), 'frontend/app'),
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
  console.error('   APP_DIR=/home/runner/workspace/frontend/app node fix_avatar_img_tag.js');
  process.exit(1);
}
console.log('📄 Target file:', TARGET);

let src = fs.readFileSync(TARGET, 'utf8');
const before = src;
let count = 0;

// ── Spot 1: Hero card avatar (72px, clickable, with hover overlay) ──
{
  const bad = `          <div onClick={()=>setPhotoViewerOpen(true)} style={{position:'absolute',top:6,left:6,width:72,height:72,borderRadius:'50%',background: avatar?\`url(\${avatar})\`:\`linear-gradient(135deg,\${prim},#00D4FF)\`,backgroundSize:'cover',backgroundPosition:'center',display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:800,color:'#fff',cursor:'pointer',overflow:'hidden'}}>
            {!avatar && initials}`;
  const good = `          <div onClick={()=>setPhotoViewerOpen(true)} style={{position:'absolute',top:6,left:6,width:72,height:72,borderRadius:'50%',background: avatar?'transparent':\`linear-gradient(135deg,\${prim},#00D4FF)\`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:800,color:'#fff',cursor:'pointer',overflow:'hidden'}}>
            {avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: Hero avatar (72px) → <img> tag'); }
  else console.log('⚠️  Hero avatar (72px) block not found — may already be patched or text differs');
}

// ── Spot 2: Personal Details tab avatar (56px, no click handler) ──
{
  const bad = `      <div style={{width:56,height:56,borderRadius:'50%',background: avatar?\`url(\${avatar})\`:\`linear-gradient(135deg,\${prim},#00D4FF)\`,backgroundSize:'cover',backgroundPosition:'center',display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:800,color:'#fff',flexShrink:0}}>{!avatar && initials}</div>`;
  const good = `      <div style={{width:56,height:56,borderRadius:'50%',background: avatar?'transparent':\`linear-gradient(135deg,\${prim},#00D4FF)\`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,fontWeight:800,color:'#fff',flexShrink:0,overflow:'hidden'}}>{avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}</div>`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: Personal Details avatar (56px) → <img> tag'); }
  else console.log('⚠️  Personal Details avatar (56px) block not found — may already be patched or text differs');
}

// ── Spot 3: Photo Viewer modal avatar (200px, large view) ──
{
  const bad = `            <div style={{width:200,height:200,borderRadius:'50%',margin:'0 auto 22px',background: avatar?\`url(\${avatar})\`:\`linear-gradient(135deg,\${prim},#00D4FF)\`,backgroundSize:'cover',backgroundPosition:'center',display:'flex',alignItems:'center',justifyContent:'center',fontSize:60,fontWeight:800,color:'#fff',border:'4px solid rgba(255,255,255,0.2)'}}>
              {!avatar && initials}`;
  const good = `            <div style={{width:200,height:200,borderRadius:'50%',margin:'0 auto 22px',background: avatar?'transparent':\`linear-gradient(135deg,\${prim},#00D4FF)\`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:60,fontWeight:800,color:'#fff',border:'4px solid rgba(255,255,255,0.2)',overflow:'hidden'}}>
              {avatar ? <img src={avatar} alt="avatar" style={{width:'100%',height:'100%',objectFit:'cover',display:'block'}}/> : initials}`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: Photo Viewer modal avatar (200px) → <img> tag'); }
  else console.log('⚠️  Photo Viewer modal avatar (200px) block not found — may already be patched or text differs');
}

if (count > 0) {
  fs.writeFileSync(TARGET, src);
  console.log(`\n✅ ${count}/3 avatar spot(s) patched and saved.`);
} else {
  console.log('\n⚠️  No changes were applied — none of the 3 blocks matched. File may have changed further.');
}
PRNODEEOF

echo "🚀 Running fix..."
node fix_avatar_img_tag.js

# ── Verification against the actual file ──
TARGET=""
for candidate in \
  "/root/workspace/frontend/app/dashboard/profile/page.tsx" \
  "/root/workspace/frontend/app/profile/page.tsx" \
  "/home/runner/workspace/frontend/app/profile/page.tsx" \
  "/home/runner/workspace/frontend/app/dashboard/profile/page.tsx"; do
  if [ -f "$candidate" ]; then TARGET="$candidate"; break; fi
done
if [ -n "$TARGET" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo " VERIFICATION"
  echo "════════════════════════════════════════════════════════"
  N=$(grep -c "objectFit:.cover.,display:.block" "$TARGET" || true)
  echo "✅ <img> tag avatar spots found: $N / 3 expected"
  if grep -q "backgroundSize:.cover.,backgroundPosition:.center." "$TARGET" 2>/dev/null && grep -q "url(\${avatar}" "$TARGET" 2>/dev/null; then
    echo "⚠️  Old background-image avatar code may still be present somewhere — please double check."
  else
    echo "✅ Old CSS background-image avatar code fully replaced"
  fi
fi

echo ""
echo "🎉 Done. Restart your frontend (Replit Run button) to load the change."
echo "👉 Existing saved avatar will now render via <img> immediately — no re-upload needed this time."
