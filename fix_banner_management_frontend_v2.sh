#!/bin/bash
# ════════════════════════════════════════════════════════════════════
# ProveRank — Banner Management Tab — FRONTEND FIX SCRIPT — V2 (MERGED)
#
# V2 combines two independent gap-analysis passes into ONE complete,
# non-redundant frontend patch, applied IDENTICALLY to both:
#   • frontend/app/admin/x7k2p/BatchManagerUltra.tsx
#   • frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx
#
# ⚠️ PREREQUISITE: run fix_banner_management_backend_v2.sh FIRST.
#
# WHAT'S NEW IN V2 vs the two separate v1 scripts:
#
#   19 sub-features, fully merged, ZERO duplicate/conflicting systems:
#
#   1.  Illustration Library — search bar
#   2.  Illustration Library — 9 new exam-category illustrations
#       (Medical/NEET, Engineering/JEE, CUET, SSC, UPSC, Banking,
#       Defence, Law, MBA)
#   3.  Crop Asset controls — 4-directional (Top/Right/Bottom/Left)
#       — ⚠️ BUG FIX: v1 shipped these sliders but never wired them
#       into the actual banner preview (cosmetic only, zero visual
#       effect). V2 fixes this — crop now really works, via CSS
#       clip-path in BannerLivePreview.
#   4.  🐛 BUG FIX: layer images (logo/watermark/uploaded assets) now
#       render correctly for plain http(s):// URLs, not just
#       data:image URLs / inline SVG. Previously any layer whose
#       content was a normal image link (e.g. a Brand Kit logo URL)
#       silently fell back to a 🖼️ placeholder emoji instead of
#       showing the actual image.
#   5.  Apply Official Logo / Apply Watermark — added as draggable,
#       scalable, rotatable, croppable LAYERS (reuses the existing
#       layer system in full) rather than a separate fixed-position
#       toggle — one unified mechanism, not two competing ones.
#   6.  View Version Diff (banner instance versions, field-by-field)
#   7.  Duplicate Version (banner instance versions)
#   8.  Media Upload — real file → base64 → backend-persisted asset
#       (background OR layer target), validated, reusable
#   9.  Import Template (JSON file picker)
#  10.  Preview Before Apply (org templates)
#  11.  AI-Recommended Assets tab (heuristic engine, honestly labelled)
#  12.  Keyboard shortcuts — Ctrl+S save draft, Delete/Backspace
#       remove selected layer, Escape deselect / cancel replace-mode
#  13.  Integration Summary panel
#  14.  Section Visibility / Lock (Layout Controls) — AND Lock now has
#       real effect: locked sections' input fields become disabled in
#       Banner Builder (previously — in both prior scripts — "Lock"
#       only stored a flag with no actual enforcement anywhere)
#  15.  Badge Style / Card Style / Gradient Angle / Spacing controls
#  16.  Multi-preset Brand Kit ("Saved Brand Kits" — create, switch,
#       delete presets)
#  17.  Cross-banner Analytics — performance by-template / by-CTA
#  18.  Asset Favorites / Recent / Most-Used filters
#  19.  Template Version History + Restore (wires a backend endpoint
#       that already existed but had zero frontend caller anywhere)
#  20.  TRUE Replace Asset — keeps the layer's position/scale/
#       rotation/opacity/crop/lock and only swaps its content (an
#       earlier draft of this feature only switched tabs and showed a
#       hint, which silently created a brand-new layer instead of
#       actually replacing anything — V2 fixes this properly)
#  21.  Smart Replace Font (cycle through font pairs)
#
# INTENTIONALLY NOT DUPLICATED:
#   Only ONE crop mechanism (4-directional, now working) — not two.
#   Only ONE logo/watermark mechanism (layer-based) — not two.
#   Only ONE media-upload path (backend-persisted) — not the
#   alternative inline-base64-only approach, which has no size limit,
#   no validation, and bloats the Banner document on every save/load.
#
# SAFE TO RE-RUN: every patch checks for its own anchor text before
# writing, and skips (does not error) if already applied. Full
# timestamped backups are taken before any file is touched, and every
# patched file is syntax-checked (real TSX parser) before the script
# exits successfully — on ANY failure, both files are restored
# automatically.
# ════════════════════════════════════════════════════════════════════
set -e
cd ~/workspace || { echo "❌ ~/workspace not found — run this from the Replit shell"; exit 1; }

BATCH_FILE="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
SERIES_FILE="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

TS=$(date +%s)
BACKUP_DIR=~/workspace/.banner_frontend_v2_backups_$TS
mkdir -p "$BACKUP_DIR"

echo "════════════════════════════════════════════════"
echo "📦  Backing up files before patching..."
echo "════════════════════════════════════════════════"
for f in "$BATCH_FILE" "$SERIES_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename $f).bak"
    echo "  ✅ backed up: $f"
  else
    echo "  ❌ MISSING FILE: $f — cannot continue safely"; exit 1
  fi
done
echo "Backups saved to: $BACKUP_DIR"
echo ""

restore_and_exit() {
  echo ""
  echo "❌ $1"
  echo "↩️  Restoring original files from backup — no changes were kept."
  cp "$BACKUP_DIR/$(basename $BATCH_FILE).bak" "$BATCH_FILE"
  cp "$BACKUP_DIR/$(basename $SERIES_FILE).bak" "$SERIES_FILE"
  exit 1
}

# ────────────────────────────────────────────────────────────────────
# Node.js patcher (no python, per project rule). Applies the SAME 19
# patch operations to BOTH files via a loop — every anchor was tested
# against the real project files before this script was written.
# ────────────────────────────────────────────────────────────────────
cat > /tmp/banner_frontend_v2_patch.js << 'NODEEOF'
const fs = require('fs');
const FILES = process.argv.slice(2);
function patchFile(path, patches) {
  let src = fs.readFileSync(path, 'utf8');
  for (const p of patches) {
    if (src.includes(p.skipIfPresent)) { console.log('  ⏭️  already applied:', p.label, '(' + path + ')'); continue; }
    const count = src.split(p.anchor).length - 1;
    if (count === 0) { console.error('  ❌ ANCHOR NOT FOUND for "' + p.label + '" in ' + path); process.exit(1); }
    if (count > 1) { console.error('  ❌ ANCHOR NOT UNIQUE (' + count + 'x) for "' + p.label + '" in ' + path); process.exit(1); }
    src = src.replace(p.anchor, p.replacement);
    console.log('  ✅ applied:', p.label, '(' + path + ')');
  }
  fs.writeFileSync(path, src, 'utf8');
}
for (const path of FILES) {
  console.log('\n📄', path);
  patchFile(path, [
// ══════════════════════════════════════════════════════════════
    // F1: New state variables (mine + theirs + new replacingLayerId)
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F1. New state variables',
      skipIfPresent: 'const [replacingLayerId, setReplacingLayerId]',
      anchor: `  const [brandKit, setBrandKit] = useState<any>(null)
  const [orgTemplates, setOrgTemplates] = useState<any[]>([])`,
      replacement: `  const [brandKit, setBrandKit] = useState<any>(null)
  const [brandKits, setBrandKits] = useState<any[]>([])
  const [orgTemplates, setOrgTemplates] = useState<any[]>([])
  const [assetFilter, setAssetFilter] = useState('all')
  const [templateVersionsOpenId, setTemplateVersionsOpenId] = useState('')
  const [templateAnalytics, setTemplateAnalytics] = useState<any[]>([])
  const [ctaAnalytics, setCtaAnalytics] = useState<any[]>([])
  const [replacingLayerId, setReplacingLayerId] = useState('')
  const [expandedVersionIdx, setExpandedVersionIdx] = useState(-1)
  const [recommendedAssets, setRecommendedAssets] = useState<any[]>([])
  const [uploadingImage, setUploadingImage] = useState(false)
  const [showIntegrationSummary, setShowIntegrationSummary] = useState(true)
  const [previewTemplate, setPreviewTemplate] = useState<any>(null)
  const [illustrationSearch, setIllustrationSearch] = useState('')`
    },

    // ══════════════════════════════════════════════════════════════
    // F2: Expand BN_ILLUSTRATIONS with exam-category illustrations
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F2. Expand illustration library with exam-category SVGs',
      skipIfPresent: "id: 'stethoscope-il'",
      anchor: `  { id: 'circuit', label: 'Circuit', category: 'Physics', svg: '<svg viewBox="0 0 100 60"><path d="M10 30 H30 V10 H70 V30 H90" stroke="#00D4FF" stroke-width="2" fill="none"/><circle cx="50" cy="30" r="4" fill="#00D4FF"/></svg>' },
]`,
      replacement: `  { id: 'circuit', label: 'Circuit', category: 'Physics', svg: '<svg viewBox="0 0 100 60"><path d="M10 30 H30 V10 H70 V30 H90" stroke="#00D4FF" stroke-width="2" fill="none"/><circle cx="50" cy="30" r="4" fill="#00D4FF"/></svg>' },
  { id: 'stethoscope-il', label: 'Stethoscope', category: 'Medical (NEET)', svg: '<svg viewBox="0 0 100 100"><path d="M25 15 Q25 50 50 55 Q75 50 75 15" stroke="#FF6B6B" stroke-width="4" fill="none"/><circle cx="50" cy="70" r="10" fill="#FF6B6B"/></svg>' },
  { id: 'gear-il', label: 'Engineering Gear', category: 'Engineering (JEE)', svg: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="22" fill="none" stroke="#4D9FFF" stroke-width="6"/><circle cx="50" cy="50" r="8" fill="#4D9FFF"/></svg>' },
  { id: 'graduation-il', label: 'Graduation Cap', category: 'CUET', svg: '<svg viewBox="0 0 100 60"><polygon points="50,10 95,30 50,50 5,30" fill="#A78BFA"/><rect x="45" y="30" width="10" height="25" fill="#A78BFA"/></svg>' },
  { id: 'document-il', label: 'Govt Document', category: 'SSC', svg: '<svg viewBox="0 0 100 100"><rect x="25" y="10" width="50" height="80" rx="4" fill="none" stroke="#37474F" stroke-width="3"/><line x1="35" y1="30" x2="65" y2="30" stroke="#37474F" stroke-width="2"/><line x1="35" y1="45" x2="65" y2="45" stroke="#37474F" stroke-width="2"/></svg>' },
  { id: 'ashoka-il', label: 'Civil Services Pillar', category: 'UPSC', svg: '<svg viewBox="0 0 100 100"><rect x="40" y="20" width="20" height="60" fill="#8D6E63"/><ellipse cx="50" cy="20" rx="25" ry="8" fill="#8D6E63"/></svg>' },
  { id: 'bank-il', label: 'Bank Building', category: 'Banking', svg: '<svg viewBox="0 0 100 100"><polygon points="50,15 90,40 10,40" fill="#00796B"/><rect x="15" y="40" width="70" height="45" fill="none" stroke="#00796B" stroke-width="3"/></svg>' },
  { id: 'shield-il', label: 'Defence Shield', category: 'Defence', svg: '<svg viewBox="0 0 100 100"><path d="M50 10 L85 25 V55 Q85 80 50 95 Q15 80 15 55 V25 Z" fill="#2E7D32"/></svg>' },
  { id: 'scale-il', label: 'Justice Scale', category: 'Law', svg: '<svg viewBox="0 0 100 100"><line x1="50" y1="10" x2="50" y2="80" stroke="#B71C1C" stroke-width="3"/><line x1="20" y1="30" x2="80" y2="30" stroke="#B71C1C" stroke-width="3"/><circle cx="20" cy="45" r="10" fill="none" stroke="#B71C1C" stroke-width="2"/><circle cx="80" cy="45" r="10" fill="none" stroke="#B71C1C" stroke-width="2"/></svg>' },
  { id: 'chart-il', label: 'Business Chart', category: 'MBA', svg: '<svg viewBox="0 0 100 60"><rect x="10" y="30" width="15" height="25" fill="#FF9800"/><rect x="35" y="15" width="15" height="40" fill="#FF9800"/><rect x="60" y="5" width="15" height="50" fill="#FF9800"/></svg>' },
]`
    },

    // ══════════════════════════════════════════════════════════════
    // F3: Illustration Library modal — add search bar
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F3. Illustration Library search bar',
      skipIfPresent: 'placeholder="Search illustrations…"',
      anchor: `function BN_IllustrationModal({ onSelect, onClose }: any) {
  const [cat, setCat] = useState('All')
  const cats = ['All', ...Array.from(new Set(BN_ILLUSTRATIONS.map(i => i.category)))]
  const list = cat === 'All' ? BN_ILLUSTRATIONS : BN_ILLUSTRATIONS.filter(i => i.category === cat)
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={onClose}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', overflowY: 'auto', border: \`1px solid \${BOR2}\` }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontWeight: 700, color: TS }}>🎨 Subject Illustration Library</div>
          <button style={bs} onClick={onClose}>✕</button>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
          {cats.map(c => <button key={c} style={cat === c ? bp : bs} onClick={() => setCat(c)}>{c}</button>)}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(90px,1fr))', gap: 10 }}>
          {list.map(ill => (
            <div key={ill.id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer' }} onClick={() => { onSelect('data:image/svg+xml;utf8,' + encodeURIComponent(ill.svg)); onClose() }}>
              <div style={{ width: 60, height: 60, margin: '0 auto 6px' }} dangerouslySetInnerHTML={{ __html: ill.svg }} />
              <div style={{ fontSize: 10, color: DIM }}>{ill.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}`,
      replacement: `function BN_IllustrationModal({ onSelect, onClose }: any) {
  const [cat, setCat] = useState('All')
  const [search, setSearch] = useState('')
  const cats = ['All', ...Array.from(new Set(BN_ILLUSTRATIONS.map(i => i.category)))]
  const list = BN_ILLUSTRATIONS.filter(i => (cat === 'All' || i.category === cat) && i.label.toLowerCase().includes(search.toLowerCase()))
  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={onClose}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 480, width: '100%', maxHeight: '80vh', overflowY: 'auto', border: \`1px solid \${BOR2}\` }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontWeight: 700, color: TS }}>🎨 Subject Illustration Library</div>
          <button style={bs} onClick={onClose}>✕</button>
        </div>
        <input style={{ width: '100%', padding: '8px 10px', borderRadius: 8, border: \`1px solid \${BOR}\`, background: 'rgba(255,255,255,0.04)', color: TS, fontSize: 12, marginBottom: 10 }} placeholder="Search illustrations…" value={search} onChange={e => setSearch(e.target.value)} />
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
          {cats.map(c => <button key={c} style={cat === c ? bp : bs} onClick={() => setCat(c)}>{c}</button>)}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(90px,1fr))', gap: 10 }}>
          {list.map(ill => (
            <div key={ill.id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer' }} onClick={() => { onSelect('data:image/svg+xml;utf8,' + encodeURIComponent(ill.svg)); onClose() }}>
              <div style={{ width: 60, height: 60, margin: '0 auto 6px' }} dangerouslySetInnerHTML={{ __html: ill.svg }} />
              <div style={{ fontSize: 10, color: DIM }}>{ill.label}</div>
            </div>
          ))}
        </div>
        {list.length === 0 && <div style={{ textAlign: 'center', padding: 20, fontSize: 11, color: DIM }}>No illustrations match your search.</div>}
      </div>
    </div>
  )
}`
    },

    // ══════════════════════════════════════════════════════════════
    // F5 (do before F4 textually since F4 anchors sit right after
    // applyBrandKitToBanner, but BannerLivePreview comes earlier in
    // the file — order in this array doesn't matter, each patch
    // finds its own anchor independently)
    // BannerLivePreview — FULL rewrite: section visibility, badge/
    // card/gradient/spacing style + REAL crop (clip-path, fixed) +
    // FIX: layer images now render for plain http(s) URLs too (this
    // was a silent bug — brandKit logo/watermark URLs are normal
    // https:// links, not data: URLs, so they previously fell
    // through to a placeholder emoji instead of rendering)
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F5. BannerLivePreview rewrite (sections, style, working crop, URL-image fix)',
      skipIfPresent: 'const renderLayerContent = (l: any) => {',
      anchor: `function BannerLivePreview({ b, size, showSafeZone, safeZoneMode, onLayerPointerDown, selectedLayerId, boxRef }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  const bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\\(/.test(b.bgImage) ? b.bgImage : \`url(\${b.bgImage}) center/cover\`) : (tpl.bg)
  const ctaRadius = b.ctaShape === 'square' ? 4 : b.ctaShape === 'rounded' ? 10 : 20
  const ctaIsOutline = b.ctaShape === 'outline'
  const badgeObj = BN_BADGES.find(x => x.id === b.badge)
  const safeInset = safeZoneMode === 'mobile' ? '12%' : safeZoneMode === 'desktop' ? '6%' : '8%'
  return (
    <div ref={boxRef} style={{ width: d.w, height: d.h, maxWidth: '100%', borderRadius: 14, position: 'relative', overflow: 'hidden', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find(f => f.id === b.fontStyle) || BN_FONTS[0]).family, border: \`1px solid \${BOR}\`, padding: 16, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', margin: '0 auto' }}>
      {showSafeZone && <div style={{ position: 'absolute', inset: safeInset, border: '1px dashed rgba(255,255,255,0.4)', borderRadius: 8, pointerEvents: 'none', zIndex: 50 }} />}
      {(b.layers || []).slice().sort((a: any, b2: any) => a.zIndex - b2.zIndex).map((l: any) => (
        <div key={l.id}
          onMouseDown={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          onTouchStart={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          style={{
            position: 'absolute', left: l.x + '%', top: l.y + '%',
            transform: \`translate(-50%,-50%) scale(\${l.scale}) rotate(\${l.rotation}deg) scaleX(\${l.flipH ? -1 : 1}) scaleY(\${l.flipV ? -1 : 1})\`,
            opacity: l.opacity, mixBlendMode: l.blendMode, zIndex: 10 + l.zIndex,
            cursor: l.locked ? 'not-allowed' : 'move',
            filter: l.shadow ? \`drop-shadow(0 4px 6px \${l.shadowColor})\` : 'none',
            border: l.border ? \`\${l.borderWidth}px solid \${l.borderColor}\` : 'none',
            borderRadius: l.border ? 6 : 0,
            outline: selectedLayerId === l.id ? '2px dashed #4D9FFF' : 'none',
            outlineOffset: 2,
            width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
          {l.type === 'icon' ? <span style={{ fontSize: 26 }}>{l.content}</span> :
            l.content && l.content.startsWith('<svg') ? <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: l.content }} /> :
            l.content && l.content.startsWith('data:image') ? <img src={l.content} style={{ width: '100%', height: '100%' }} /> :
            <span style={{ fontSize: 20 }}>🖼️</span>}
        </div>
      ))}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <span style={{ fontSize: 20 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span>
        {badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 9, fontWeight: 700, padding: '3px 8px', borderRadius: 20, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
      </div>
      <div style={{ textAlign: (b.textAlign || 'left') as any }}>
        <div style={{
          fontSize: (b.title || '').length > 30 ? (size === 'square' ? 15 : 13) : (size === 'square' ? 18 : 16),
          fontWeight: 800, lineHeight: 1.2, overflow: 'hidden', display: '-webkit-box',
          WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any, wordBreak: 'break-word',
          ...(b.textStyleOverride || {})
        }}>{b.title || 'Batch Title'}</div>
        {b.tagline && <div style={{ fontSize: 10.5, opacity: 0.85, marginTop: 3 }}>{b.tagline}</div>}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6, justifyContent: b.textAlign === 'center' ? 'center' : b.textAlign === 'right' ? 'flex-end' : 'flex-start' }}>
          {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
            <span key={i} style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
          ))}
        </div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 14, fontWeight: 800, color: b.accentColor || tpl.accent }}>{b.price && Number(b.price) > 0 ? '₹' + b.price : 'FREE'}</span>
        <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: ctaRadius, background: ctaIsOutline ? 'transparent' : (b.accentColor || tpl.accent), color: ctaIsOutline ? (b.accentColor || tpl.accent) : '#1a1a2e', border: ctaIsOutline ? \`1.5px solid \${b.accentColor || tpl.accent}\` : 'none' }}>{b.ctaText || 'Enroll Now'} →</span>
      </div>
    </div>
  )
}`,
      replacement: `function BannerLivePreview({ b, size, showSafeZone, safeZoneMode, onLayerPointerDown, selectedLayerId, boxRef }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  let bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\\(/.test(b.bgImage) ? b.bgImage : \`url(\${b.bgImage}) center/cover\`) : (tpl.bg)
  if (b.gradientAngle && b.gradientAngle !== 135 && typeof bg === 'string' && bg.indexOf('135deg') >= 0) bg = bg.replace('135deg', b.gradientAngle + 'deg')
  const ctaRadius = b.ctaShape === 'square' ? 4 : b.ctaShape === 'rounded' ? 10 : 20
  const ctaIsOutline = b.ctaShape === 'outline'
  const badgeObj = BN_BADGES.find(x => x.id === b.badge)
  const safeInset = safeZoneMode === 'mobile' ? '12%' : safeZoneMode === 'desktop' ? '6%' : '8%'
  const sv = b.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }
  const cardRadius = b.cardStyle === 'sharp' ? 4 : b.cardStyle === 'soft' ? 20 : 14
  const cardShadow = b.cardStyle === 'elevated' ? '0 12px 28px rgba(0,0,0,0.35)' : 'none'
  const pad = b.spacing === 'compact' ? 10 : b.spacing === 'spacious' ? 24 : 16
  const badgeRadius = b.badgeStyle === 'corner' ? 0 : b.badgeStyle === 'ribbon' ? 3 : 20
  const renderLayerContent = (l: any) => {
    if (l.type === 'icon') return <span style={{ fontSize: 26 }}>{l.content}</span>
    if (!l.content) return <span style={{ fontSize: 20 }}>🖼️</span>
    if (l.content.startsWith('<svg')) return <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: l.content }} />
    // FIX: handle both data: URLs AND normal http(s) URLs (e.g. Brand
    // Kit logo/watermark links) — previously only data: URLs rendered,
    // any plain https:// image link silently fell through to the
    // placeholder emoji below.
    if (l.content.startsWith('data:image') || /^https?:\\/\\//.test(l.content)) {
      const hasCrop = (l.cropTop || l.cropRight || l.cropBottom || l.cropLeft)
      return <img src={l.content} style={{ width: '100%', height: '100%', objectFit: 'cover', clipPath: hasCrop ? \`inset(\${l.cropTop || 0}% \${l.cropRight || 0}% \${l.cropBottom || 0}% \${l.cropLeft || 0}%)\` : 'none' }} />
    }
    return <span style={{ fontSize: 20 }}>🖼️</span>
  }
  return (
    <div ref={boxRef} style={{ width: d.w, height: d.h, maxWidth: '100%', borderRadius: cardRadius, boxShadow: cardShadow, position: 'relative', overflow: 'hidden', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find(f => f.id === b.fontStyle) || BN_FONTS[0]).family, border: \`1px solid \${BOR}\`, padding: pad, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', margin: '0 auto' }}>
      {showSafeZone && <div style={{ position: 'absolute', inset: safeInset, border: '1px dashed rgba(255,255,255,0.4)', borderRadius: 8, pointerEvents: 'none', zIndex: 50 }} />}
      {(b.layers || []).slice().sort((a: any, b2: any) => a.zIndex - b2.zIndex).map((l: any) => (
        <div key={l.id}
          onMouseDown={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          onTouchStart={(e: any) => onLayerPointerDown && onLayerPointerDown(e, l.id)}
          style={{
            position: 'absolute', left: l.x + '%', top: l.y + '%',
            transform: \`translate(-50%,-50%) scale(\${l.scale}) rotate(\${l.rotation}deg) scaleX(\${l.flipH ? -1 : 1}) scaleY(\${l.flipV ? -1 : 1})\`,
            opacity: l.opacity, mixBlendMode: l.blendMode, zIndex: 10 + l.zIndex,
            cursor: l.locked ? 'not-allowed' : 'move',
            filter: l.shadow ? \`drop-shadow(0 4px 6px \${l.shadowColor})\` : 'none',
            border: l.border ? \`\${l.borderWidth}px solid \${l.borderColor}\` : 'none',
            borderRadius: l.border ? 6 : 0,
            outline: selectedLayerId === l.id ? '2px dashed #4D9FFF' : 'none',
            outlineOffset: 2,
            width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden'
          }}>
          {renderLayerContent(l)}
        </div>
      ))}
      {(sv.icon !== false || sv.badge !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          {sv.icon !== false ? <span style={{ fontSize: 20 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span> : <span />}
          {sv.badge !== false && badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 9, fontWeight: 700, padding: '3px 8px', borderRadius: badgeRadius, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
        </div>
      )}
      {(sv.title !== false || sv.tagline !== false || sv.highlights !== false) && (
        <div style={{ textAlign: (b.textAlign || 'left') as any }}>
          {sv.title !== false && (
            <div style={{
              fontSize: (b.title || '').length > 30 ? (size === 'square' ? 15 : 13) : (size === 'square' ? 18 : 16),
              fontWeight: 800, lineHeight: 1.2, overflow: 'hidden', display: '-webkit-box',
              WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any, wordBreak: 'break-word',
              ...(b.textStyleOverride || {})
            }}>{b.title || 'Batch Title'}</div>
          )}
          {sv.tagline !== false && b.tagline && <div style={{ fontSize: 10.5, opacity: 0.85, marginTop: 3 }}>{b.tagline}</div>}
          {sv.highlights !== false && (
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6, justifyContent: b.textAlign === 'center' ? 'center' : b.textAlign === 'right' ? 'flex-end' : 'flex-start' }}>
              {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
                <span key={i} style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
              ))}
            </div>
          )}
        </div>
      )}
      {(sv.price !== false || sv.cta !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          {sv.price !== false ? <span style={{ fontSize: 14, fontWeight: 800, color: b.accentColor || tpl.accent }}>{b.price && Number(b.price) > 0 ? '₹' + b.price : 'FREE'}</span> : <span />}
          {sv.cta !== false && <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: ctaRadius, background: ctaIsOutline ? 'transparent' : (b.accentColor || tpl.accent), color: ctaIsOutline ? (b.accentColor || tpl.accent) : '#1a1a2e', border: ctaIsOutline ? \`1.5px solid \${b.accentColor || tpl.accent}\` : 'none' }}>{b.ctaText || 'Enroll Now'} →</span>}
        </div>
      )}
    </div>
  )
}`
    },

// ══════════════════════════════════════════════════════════════
    // F4a: loadOrgTemplates / brand-kit useEffect region — add
    // multi-preset brand kit loader + analytics fetch + section
    // visibility/lock toggles + favorite toggle + font cycle
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F4a. Brand-kit presets loader + analytics fetch + section/asset/font helper functions',
      skipIfPresent: 'const loadBrandKits = useCallback(',
      anchor: `  const loadOrgTemplates = useCallback(() => {
    const p = new URLSearchParams()
    if (assetSearch) p.set('search', assetSearch)
    fetch(assetsBase + '/templates?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setOrgTemplates(d.templates || [])).catch(() => {})
  }, [assetSearch])
  useEffect(() => { fetch(assetsBase + '/brand-kit', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKit(d.brandKit)).catch(() => {}) }, [])`,
      replacement: `  const loadOrgTemplates = useCallback(() => {
    const p = new URLSearchParams()
    if (assetSearch) p.set('search', assetSearch)
    fetch(assetsBase + '/templates?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setOrgTemplates(d.templates || [])).catch(() => {})
  }, [assetSearch])
  const loadBrandKits = useCallback(() => fetch(assetsBase + '/brand-kits', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKits(d.brandKits || [])).catch(() => {}), [])
  useEffect(() => { fetch(assetsBase + '/brand-kit', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKit(d.brandKit)).catch(() => {}); loadBrandKits() }, [])
  useEffect(() => {
    fetch(assetsBase + '/analytics/templates', { headers: authHeaders }).then(r => r.json()).then(d => setTemplateAnalytics(d.breakdown || [])).catch(() => {})
    fetch(assetsBase + '/analytics/cta', { headers: authHeaders }).then(r => r.json()).then(d => setCtaAnalytics(d.breakdown || [])).catch(() => {})
  }, [])
  const createBrandKitPreset = async () => {
    const name = window.prompt('New Brand Kit preset name?')
    if (!name || !name.trim()) return
    const r = await fetch(assetsBase + '/brand-kits', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: name.trim(), primaryColor: brandKit?.primaryColor, secondaryColor: brandKit?.secondaryColor, accentColor: brandKit?.accentColor, fontPair: brandKit?.fontPair, logoUrl: brandKit?.logoUrl, watermarkUrl: brandKit?.watermarkUrl }) })
    const d = await r.json()
    if (d.success) { showToast('✅ Preset created'); loadBrandKits() } else showToast('⚠️ ' + d.error)
  }
  const setDefaultBrandKit = async (kitId: string) => {
    await fetch(assetsBase + '/brand-kits/' + kitId + '/set-default', { method: 'POST', headers: authHeaders })
    const r = await fetch(assetsBase + '/brand-kit', { headers: authHeaders }); const d = await r.json()
    setBrandKit(d.brandKit); loadBrandKits(); showToast('✅ Default preset changed')
  }
  const deleteBrandKitPreset = async (kitId: string) => {
    if (!window.confirm('Delete this Brand Kit preset?')) return
    const r = await fetch(assetsBase + '/brand-kits/' + kitId, { method: 'DELETE', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Preset deleted'); loadBrandKits() } else showToast('⚠️ ' + d.error)
  }
  const toggleAssetFavorite = async (asset: any, tab: string) => {
    await fetch(assetsBase + '/assets/' + asset._id, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ isFavorite: !asset.isFavorite }) })
    fetch(assetsBase + '/assets?type=' + tab, { headers: authHeaders }).then(r => r.json()).then(d => setAssetsMap((m: any) => ({ ...m, [tab]: d.assets || [] })))
  }
  const cycleFontStyle = () => {
    const idx = BN_FONTS.findIndex(f => f.id === form.fontStyle)
    const next = BN_FONTS[(idx + 1) % BN_FONTS.length]
    setForm({ ...form, fontStyle: next.id })
    showToast('🔤 Font changed to ' + next.label)
  }
  const toggleSectionVisible = (key: string) => {
    const sv = { ...(form.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }) }
    sv[key] = sv[key] === false ? true : false
    setForm({ ...form, sectionVisibility: sv })
  }
  const toggleSectionLock = (key: string) => {
    const sl = { ...(form.sectionLock || {}) }
    sl[key] = !sl[key]
    setForm({ ...form, sectionLock: sl })
    showToast(sl[key] ? '🔒 ' + key + ' locked — its field is now disabled in Banner Builder' : '🔓 ' + key + ' unlocked')
  }`
    },

    // ══════════════════════════════════════════════════════════════
    // F4b: Apply Logo / Apply Watermark — kept as draggable, croppable
    // LAYERS (reuses the full layer system: drag/scale/rotate/opacity/
    // crop/lock/undo-redo) rather than a separate fixed-corner toggle,
    // so there is only ONE mechanism for placing brand imagery.
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F4b. applyLogoToBanner / applyWatermarkToBanner functions',
      skipIfPresent: 'const applyLogoToBanner',
      anchor: `  const applyBrandKitToBanner = () => {
    if (!brandKit) return
    setForm({ ...form, primaryColor: brandKit.primaryColor, secondaryColor: brandKit.secondaryColor, accentColor: brandKit.accentColor, fontStyle: brandKit.fontPair })
    showToast('✅ Brand Kit applied to this banner')
  }`,
      replacement: `  const applyBrandKitToBanner = () => {
    if (!brandKit) return
    setForm({ ...form, primaryColor: brandKit.primaryColor, secondaryColor: brandKit.secondaryColor, accentColor: brandKit.accentColor, fontStyle: brandKit.fontPair })
    showToast('✅ Brand Kit applied to this banner')
  }
  const applyLogoToBanner = () => {
    if (!brandKit?.logoUrl) return showToast('⚠️ No Logo URL set in this Brand Kit preset yet')
    const layer = { id: 'ly_logo_' + Date.now(), type: 'logo', content: brandKit.logoUrl, x: 12, y: 12, scale: 0.5, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal', cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    showToast('✅ Logo added as a layer — drag/resize/crop it in Preview & Variants')
  }
  const applyWatermarkToBanner = () => {
    if (!brandKit?.watermarkUrl) return showToast('⚠️ No Watermark URL set in this Brand Kit preset yet')
    const layer = { id: 'ly_watermark_' + Date.now(), type: 'watermark', content: brandKit.watermarkUrl, x: 85, y: 88, scale: 0.35, rotation: 0, opacity: 0.55, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal', cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    showToast('✅ Watermark added as a layer — drag/resize/crop it in Preview & Variants')
  }`
    },

    // ══════════════════════════════════════════════════════════════
    // F4c: media-upload / duplicate-version / import-template /
    // template-version-restore / recommended-assets / version-diff /
    // true-replace-asset helper functions
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F4c. uploadBannerImage / duplicateVersion / importTemplateFile / restoreTemplateVersion / versionDiff / startReplaceAsset functions',
      skipIfPresent: 'const uploadBannerImage = ',
      anchor: `  const previewRef = useRef<any>(null)
  const cardRef = useRef<any>(null); const wideRef = useRef<any>(null); const squareRef = useRef<any>(null); const mobileRef = useRef<any>(null)`,
      replacement: `  const uploadBannerImage = async (file: File, target: 'background' | 'layer') => {
    if (!file) return
    if (!/^image\\/(png|jpe?g|webp|svg\\+xml|gif)$/.test(file.type)) return showToast('⚠️ Unsupported file type — use PNG, JPG, WebP, SVG or GIF')
    if (file.size > 900000) return showToast('⚠️ Image too large (max ~900KB) — please compress first')
    setUploadingImage(true)
    try {
      const dataUrl: string = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.onerror = reject
        reader.readAsDataURL(file)
      })
      const r = await fetch(assetsBase + '/assets/upload-image', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: file.name, dataUrl, category: 'Uploaded' }) })
      const d = await r.json()
      if (!d.success) return showToast('⚠️ ' + (d.error || 'Upload failed'))
      if (target === 'background') { setForm({ ...form, bgImage: d.asset.content }); showToast('✅ Image uploaded and set as background') }
      else { addOrReplaceAssetLayer(d.asset); showToast('✅ Image uploaded and added as a layer') }
    } catch (e) { showToast('⚠️ Upload failed — please try again') }
    setUploadingImage(false)
  }
  const duplicateVersion = async (vIdx: number) => {
    const r = await fetch(base + '/' + id + '/banner/duplicate-version/' + vIdx, { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Version duplicated'); load() } else showToast('⚠️ ' + d.error)
  }
  const importTemplateFile = async (file: File) => {
    if (!file) return
    try {
      const text = await file.text()
      const parsed = JSON.parse(text)
      const name = parsed.name || file.name.replace(/\\.json$/i, '')
      const config = parsed.config || parsed
      const r = await fetch(assetsBase + '/templates/import', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name, category: parsed.category || 'Custom', config }) })
      const d = await r.json()
      if (d.success) { showToast('✅ Template imported'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
    } catch (e) { showToast('⚠️ Invalid template file — expected exported JSON') }
  }
  const restoreTemplateVersion = async (t: any, vIdx: number) => {
    const r = await fetch(assetsBase + '/templates/' + t._id + '/restore-version/' + vIdx, { method: 'POST', headers: authHeaders })
    const d = await r.json()
    if (d.success) { showToast('✅ Template version restored'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
  }
  const loadRecommendedAssets = useCallback(() => {
    const p = new URLSearchParams()
    if (data?.syncPreview?.examType) p.set('examType', data.syncPreview.examType)
    fetch(assetsBase + '/assets/recommended?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setRecommendedAssets(d.assets || [])).catch(() => {})
  }, [data?.syncPreview?.examType])
  useEffect(() => { loadRecommendedAssets() }, [loadRecommendedAssets])
  const VERSION_DIFF_FIELDS: [string, string][] = [['title', 'Title'], ['tagline', 'Tagline'], ['price', 'Price'], ['ctaText', 'CTA Text'], ['template', 'Template'], ['primaryColor', 'Primary Color'], ['badge', 'Badge'], ['bgImage', 'Background Image']]
  const versionDiff = (vData: any) => {
    if (!vData || !form) return []
    return VERSION_DIFF_FIELDS.filter(([key]) => (vData[key] || '') !== (form[key] || '')).map(([key, label]) => ({ label, from: vData[key] || '—', to: form[key] || '—' }))
  }
  // TRUE "Replace Asset": unlike a simple add, this keeps the existing
  // layer's position/scale/rotation/opacity/crop/lock and only swaps
  // its content — click "🔁 Replace" on a layer, then pick any asset
  // from the library below to swap it in-place.
  const startReplaceAsset = (layerId: string) => {
    setReplacingLayerId(layerId)
    showToast('🔁 Pick an asset below to replace the selected layer (position kept)')
  }
  const addOrReplaceAssetLayer = (asset: any) => {
    if (replacingLayerId) {
      setForm({ ...form, layers: (form.layers || []).map((l: any) => l.id === replacingLayerId ? { ...l, type: asset.type, content: asset.content, assetId: asset._id } : l) })
      setReplacingLayerId('')
      showToast('✅ Layer replaced: ' + asset.name)
      fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
      return
    }
    addAssetLayer(asset)
  }

  const previewRef = useRef<any>(null)
  const cardRef = useRef<any>(null); const wideRef = useRef<any>(null); const squareRef = useRef<any>(null); const mobileRef = useRef<any>(null)`
    },

// ══════════════════════════════════════════════════════════════
    // F6: Layer Controls — Crop sliders (4-directional, now actually
    // wired into BannerLivePreview via clip-path) + TRUE Replace Asset
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F6. Layer Controls: working crop sliders + true Replace Asset button',
      skipIfPresent: '✂️ Crop (Safe Zone Trim)',
      anchor: `                  <div><label style={lbl}>Blend Mode</label>
                    <select style={inp} value={layer.blendMode} onChange={e => updateLayer(layer.id, { blendMode: e.target.value })}>
                      {['normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge', 'difference'].map(m => <option key={m} value={m}>{m}</option>)}
                    </select>
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                    <button style={bs} onClick={() => duplicateLayer(layer.id)}>⧉ Duplicate</button>
                    <button style={bd} onClick={() => removeLayer(layer.id)}>🗑️ Delete</button>
                  </div>`,
      replacement: `                  <div><label style={lbl}>Blend Mode</label>
                    <select style={inp} value={layer.blendMode} onChange={e => updateLayer(layer.id, { blendMode: e.target.value })}>
                      {['normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge', 'difference'].map(m => <option key={m} value={m}>{m}</option>)}
                    </select>
                  </div>
                  {['sticker', 'decorative', 'subject_graphic', 'illustration', 'logo', 'watermark', 'media'].includes(layer.type) && (
                    <div style={{ marginTop: 10, paddingTop: 10, borderTop: \`1px solid \${BOR}\` }}>
                      <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>✂️ Crop (Safe Zone Trim)</div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(110px,1fr))', gap: 8 }}>
                        <div><label style={lbl}>Crop Top ({layer.cropTop || 0}%)</label><input type="range" min="0" max="45" value={layer.cropTop || 0} onChange={e => updateLayer(layer.id, { cropTop: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Right ({layer.cropRight || 0}%)</label><input type="range" min="0" max="45" value={layer.cropRight || 0} onChange={e => updateLayer(layer.id, { cropRight: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Bottom ({layer.cropBottom || 0}%)</label><input type="range" min="0" max="45" value={layer.cropBottom || 0} onChange={e => updateLayer(layer.id, { cropBottom: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                        <div><label style={lbl}>Crop Left ({layer.cropLeft || 0}%)</label><input type="range" min="0" max="45" value={layer.cropLeft || 0} onChange={e => updateLayer(layer.id, { cropLeft: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                      </div>
                      {(layer.cropTop || layer.cropRight || layer.cropBottom || layer.cropLeft) ? <button style={{ ...bs, marginTop: 6 }} onClick={() => updateLayer(layer.id, { cropTop: 0, cropRight: 0, cropBottom: 0, cropLeft: 0 })}>↺ Reset Crop</button> : null}
                    </div>
                  )}
                  <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                    <button style={bs} onClick={() => duplicateLayer(layer.id)}>⧉ Duplicate</button>
                    <button style={replacingLayerId === layer.id ? bp : bs} onClick={() => startReplaceAsset(layer.id)}>🔁 {replacingLayerId === layer.id ? 'Pick asset below…' : 'Replace'}</button>
                    <button style={bd} onClick={() => removeLayer(layer.id)}>🗑️ Delete</button>
                  </div>`
    },

    // ══════════════════════════════════════════════════════════════
    // F7: Content Fields — Lock/Unlock now has real teeth: locked
    // sections' inputs become disabled (previously "Lock" only stored
    // a flag with no actual effect on the form).
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F7. Content field inputs respect Section Lock (disabled when locked)',
      skipIfPresent: "disabled={!!(form.sectionLock || {}).title}",
      anchor: `          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>✏️ Banner Builder</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
              <div><label style={lbl}>Title</label><input style={inp} value={form.title || ''} onChange={e => setForm({ ...form, title: e.target.value })} /></div>
              <div><label style={lbl}>Tagline / Subtitle</label><input style={inp} value={form.tagline || ''} onChange={e => setForm({ ...form, tagline: e.target.value })} /></div>
              <div><label style={lbl}>Base Price ₹</label><input style={inp} value={form.price || ''} onChange={e => setForm({ ...form, price: e.target.value })} /></div>
              <div><label style={lbl}>Total Tests</label><input style={inp} value={form.totalTests || ''} onChange={e => setForm({ ...form, totalTests: e.target.value })} /></div>
              <div><label style={lbl}>Validity (read-only)</label><input style={{ ...inp, opacity: 0.6 }} value={form.validity || ''} disabled /></div>
              <div><label style={lbl}>Duration (auto)</label><input style={{ ...inp, opacity: 0.6 }} value={form.duration || ''} disabled /></div>
              <div><label style={lbl}>CTA Button Text</label><input style={inp} value={form.ctaText || ''} onChange={e => setForm({ ...form, ctaText: e.target.value })} /></div>
              <div><label style={lbl}>Badge / Ribbon</label>
                <select style={inp} value={form.badge || 'none'} onChange={e => setForm({ ...form, badge: e.target.value })}>
                  {BN_BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Text Alignment</label>
                <div style={{ display: 'flex', gap: 4 }}>
                  {['left', 'center', 'right'].map(al => (
                    <button key={al} style={(form.textAlign || 'left') === al ? bp : bs} onClick={() => setForm({ ...form, textAlign: al })}>{al === 'left' ? '⬅️' : al === 'center' ? '⬛' : '➡️'}</button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} placeholder={'Highlight ' + (i + 1)} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>`,
      replacement: `          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>✏️ Banner Builder</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
              <div><label style={lbl}>Title {(form.sectionLock || {}).title && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).title ? 0.5 : 1 }} value={form.title || ''} disabled={!!(form.sectionLock || {}).title} onChange={e => setForm({ ...form, title: e.target.value })} /></div>
              <div><label style={lbl}>Tagline / Subtitle {(form.sectionLock || {}).tagline && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).tagline ? 0.5 : 1 }} value={form.tagline || ''} disabled={!!(form.sectionLock || {}).tagline} onChange={e => setForm({ ...form, tagline: e.target.value })} /></div>
              <div><label style={lbl}>Base Price ₹ {(form.sectionLock || {}).price && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).price ? 0.5 : 1 }} value={form.price || ''} disabled={!!(form.sectionLock || {}).price} onChange={e => setForm({ ...form, price: e.target.value })} /></div>
              <div><label style={lbl}>Total Tests</label><input style={inp} value={form.totalTests || ''} onChange={e => setForm({ ...form, totalTests: e.target.value })} /></div>
              <div><label style={lbl}>Validity (read-only)</label><input style={{ ...inp, opacity: 0.6 }} value={form.validity || ''} disabled /></div>
              <div><label style={lbl}>Duration (auto)</label><input style={{ ...inp, opacity: 0.6 }} value={form.duration || ''} disabled /></div>
              <div><label style={lbl}>CTA Button Text {(form.sectionLock || {}).cta && '🔒'}</label><input style={{ ...inp, opacity: (form.sectionLock || {}).cta ? 0.5 : 1 }} value={form.ctaText || ''} disabled={!!(form.sectionLock || {}).cta} onChange={e => setForm({ ...form, ctaText: e.target.value })} /></div>
              <div><label style={lbl}>Badge / Ribbon {(form.sectionLock || {}).badge && '🔒'}</label>
                <select style={{ ...inp, opacity: (form.sectionLock || {}).badge ? 0.5 : 1 }} value={form.badge || 'none'} disabled={!!(form.sectionLock || {}).badge} onChange={e => setForm({ ...form, badge: e.target.value })}>
                  {BN_BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Text Alignment</label>
                <div style={{ display: 'flex', gap: 4 }}>
                  {['left', 'center', 'right'].map(al => (
                    <button key={al} style={(form.textAlign || 'left') === al ? bp : bs} onClick={() => setForm({ ...form, textAlign: al })}>{al === 'left' ? '⬅️' : al === 'center' ? '⬛' : '➡️'}</button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8, opacity: (form.sectionLock || {}).highlights ? 0.5 : 1 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} disabled={!!(form.sectionLock || {}).highlights} placeholder={'Highlight ' + (i + 1) + ((form.sectionLock || {}).highlights ? ' 🔒' : '')} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>`
    },

    // ══════════════════════════════════════════════════════════════
    // F8: Font/BgImage row — combine: unchanged font+bgImage+library
    // button, MY backend-persisted file-upload (background + layer
    // targets), NEW badge/card/gradient/spacing style controls,
    // Smart Replace Font, and Section Visibility/Lock toggle row.
    // (Show Brand Logo/Watermark toggles intentionally NOT added here
    //  — logo/watermark are placed via the Brand Kit tab as proper
    //  layers instead, see F4b — avoids a second, conflicting
    //  mechanism for the same purpose.)
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F8. Badge/Card/Gradient/Spacing style controls + Section Visibility/Lock row + working media upload',
      skipIfPresent: '👁️ Section Visibility / Lock',
      anchor: `            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 8, marginTop: 8 }}>
              <div><label style={lbl}>Font Style</label>
                <select style={inp} value={form.fontStyle || 'modern'} onChange={e => setForm({ ...form, fontStyle: e.target.value })}>
                  {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Background Image URL</label><input style={inp} value={form.bgImage || ''} onChange={e => setForm({ ...form, bgImage: e.target.value })} placeholder="https:// or pick from library" /></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}><button style={{ ...bs, width: '100%' }} onClick={() => setShowIllustrations(true)}>🎨 Illustration Library</button></div>
            </div>`,
      replacement: `            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 8, marginTop: 8 }}>
              <div><label style={lbl}>Font Style</label>
                <select style={inp} value={form.fontStyle || 'modern'} onChange={e => setForm({ ...form, fontStyle: e.target.value })}>
                  {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Background Image URL</label><input style={inp} value={(form.bgImage || '').startsWith('data:') ? '(uploaded image set)' : (form.bgImage || '')} onChange={e => setForm({ ...form, bgImage: e.target.value })} placeholder="https:// or pick from library" /></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}><button style={{ ...bs, width: '100%' }} onClick={() => setShowIllustrations(true)}>🎨 Illustration Library</button></div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}>
                <label style={{ ...bs, width: '100%', textAlign: 'center', cursor: 'pointer', display: 'block' }}>
                  {uploadingImage ? '⟳ Uploading…' : '📤 Upload (as Background)'}
                  <input type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif" style={{ display: 'none' }} disabled={uploadingImage} onChange={e => { if (e.target.files && e.target.files[0]) uploadBannerImage(e.target.files[0], 'background'); e.target.value = '' }} />
                </label>
              </div>
              <div style={{ display: 'flex', alignItems: 'flex-end' }}>
                <label style={{ ...bs, width: '100%', textAlign: 'center', cursor: 'pointer', display: 'block' }}>
                  {uploadingImage ? '⟳ Uploading…' : '📤 Upload (as Layer)'}
                  <input type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif" style={{ display: 'none' }} disabled={uploadingImage} onChange={e => { if (e.target.files && e.target.files[0]) uploadBannerImage(e.target.files[0], 'layer'); e.target.value = '' }} />
                </label>
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              <div><label style={lbl}>Badge Style</label>
                <select style={inp} value={form.badgeStyle || 'pill'} onChange={e => setForm({ ...form, badgeStyle: e.target.value })}>
                  <option value="pill">Pill</option><option value="ribbon">Ribbon</option><option value="corner">Corner</option>
                </select>
              </div>
              <div><label style={lbl}>Card Style</label>
                <select style={inp} value={form.cardStyle || 'rounded'} onChange={e => setForm({ ...form, cardStyle: e.target.value })}>
                  <option value="sharp">Sharp</option><option value="rounded">Rounded</option><option value="soft">Soft</option><option value="elevated">Elevated</option>
                </select>
              </div>
              <div><label style={lbl}>Gradient Angle ({form.gradientAngle || 135}°)</label><input type="range" min="0" max="360" value={form.gradientAngle || 135} onChange={e => setForm({ ...form, gradientAngle: Number(e.target.value) })} style={{ width: '100%' }} /></div>
              <div><label style={lbl}>Spacing</label>
                <select style={inp} value={form.spacing || 'normal'} onChange={e => setForm({ ...form, spacing: e.target.value })}>
                  <option value="compact">Compact</option><option value="normal">Normal</option><option value="spacious">Spacious</option>
                </select>
              </div>
            </div>
            <button style={{ ...bs, marginTop: 8 }} onClick={cycleFontStyle}>🔤 Smart Replace Font (cycle)</button>
            <div style={{ marginTop: 10, marginBottom: 4 }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>👁️ Section Visibility / Lock (Layout Controls)</div>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                {['icon', 'badge', 'title', 'tagline', 'highlights', 'price', 'cta'].map(key => {
                  const sv = form.sectionVisibility || { icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }
                  const sl = form.sectionLock || {}
                  const visible = sv[key] !== false
                  return (
                    <div key={key} style={{ display: 'flex', alignItems: 'center', gap: 3, padding: '4px 8px', borderRadius: 6, border: \`1px solid \${BOR}\`, opacity: visible ? 1 : 0.5 }}>
                      <span style={{ fontSize: 10.5, color: DIM, textTransform: 'capitalize' }}>{key}</span>
                      <button style={{ ...bs, padding: '1px 5px', fontSize: 10 }} onClick={() => toggleSectionVisible(key)} title={visible ? 'Hide this section' : 'Show this section'}>{visible ? '👁️' : '🚫'}</button>
                      <button style={{ ...bs, padding: '1px 5px', fontSize: 10 }} onClick={() => toggleSectionLock(key)} title={sl[key] ? 'Unlock editing' : 'Lock editing'}>{sl[key] ? '🔒' : '🔓'}</button>
                    </div>
                  )
                })}
              </div>
            </div>`
    },

// ══════════════════════════════════════════════════════════════
    // F9: Version History (banner instance) — diff view + duplicate
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F9. Banner Version diff view + Duplicate Version button',
      skipIfPresent: 'onClick={() => duplicateVersion(realIdx)}',
      anchor: `          {showVersions && (
            <div style={cs}>
              <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🕐 Version History</div>
              {(!form.versions || form.versions.length === 0) ? <EmptyMsg text="No previous versions yet." /> : form.versions.slice().reverse().map((v: any, i: number) => {
                const realIdx = form.versions.length - 1 - i
                return (
                  <div key={realIdx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11.5, color: DIM, padding: '6px 0', borderBottom: \`1px solid \${BOR}\` }}>
                    <span>{v.label} · {new Date(v.savedAt).toLocaleString()}</span>
                    <button style={bs} onClick={() => restoreVersion(realIdx)}>Restore</button>
                  </div>
                )
              })}
            </div>
          )}`,
      replacement: `          {showVersions && (
            <div style={cs}>
              <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>🕐 Version History</div>
              {(!form.versions || form.versions.length === 0) ? <EmptyMsg text="No previous versions yet." /> : form.versions.slice().reverse().map((v: any, i: number) => {
                const realIdx = form.versions.length - 1 - i
                const isExpanded = expandedVersionIdx === realIdx
                const diff = isExpanded ? versionDiff(v.data) : []
                return (
                  <div key={realIdx} style={{ padding: '6px 0', borderBottom: \`1px solid \${BOR}\` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11.5, color: DIM, flexWrap: 'wrap', gap: 6 }}>
                      <span style={{ cursor: 'pointer' }} onClick={() => setExpandedVersionIdx(isExpanded ? -1 : realIdx)}>{isExpanded ? '▾' : '▸'} {v.label} · {new Date(v.savedAt).toLocaleString()}</span>
                      <span style={{ display: 'flex', gap: 4 }}>
                        <button style={bs} onClick={() => setExpandedVersionIdx(isExpanded ? -1 : realIdx)}>{isExpanded ? 'Hide Diff' : 'View Diff'}</button>
                        <button style={bs} onClick={() => duplicateVersion(realIdx)}>⧉ Duplicate</button>
                        <button style={bp} onClick={() => restoreVersion(realIdx)}>Restore</button>
                      </span>
                    </div>
                    {isExpanded && (
                      <div style={{ marginTop: 6, padding: 8, borderRadius: 8, background: 'rgba(77,159,255,0.05)', border: \`1px solid \${BOR}\` }}>
                        {diff.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>No differences from the current live banner.</div> : diff.map((d, di) => (
                          <div key={di} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}><b style={{ color: TS }}>{d.label}:</b> <span style={{ color: '#E74C3C' }}>{String(d.from).slice(0, 40)}</span> → <span style={{ color: '#27AE60' }}>{String(d.to).slice(0, 40)}</span></div>
                        ))}
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}`
    },

    // ══════════════════════════════════════════════════════════════
    // F10: My Templates — Import + Preview-Before-Apply + Version
    // History viewer with Restore (wires the previously-unused
    // backend endpoint /templates/:id/restore-version/:vIdx)
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F10. My Templates: Import + Preview Before Apply + Template Version History/Restore',
      skipIfPresent: "importTemplateFile(e.target.files[0])",
      anchor: `                <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
                  <input style={inp} placeholder="Search my templates…" value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                  <button style={bp} onClick={saveAsOrgTemplate}>💾 Save Current As Template</button>
                </div>
                {orgTemplates.length === 0 ? <EmptyMsg text="No saved templates yet." /> : orgTemplates.map((t: any) => (
                  <div key={t._id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: \`1px solid \${BOR}\`, flexWrap: 'wrap', gap: 6 }}>
                    <span style={{ fontSize: 12, color: TS }}>{t.isFavorite ? '⭐ ' : ''}{t.name} <span style={{ color: DIM, fontSize: 10 }}>({t.category} · used {t.usageCount || 0}×)</span></span>
                    <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                      <button style={bs} onClick={() => applyOrgTemplate(t)}>Apply</button>
                      <button style={bs} onClick={() => toggleOrgTemplateFav(t)}>{t.isFavorite ? 'Unfavorite' : 'Favorite'}</button>
                      <button style={bs} onClick={() => cloneOrgTemplate(t)}>Clone</button>
                      <button style={bs} onClick={() => exportOrgTemplate(t)}>Export</button>
                      <button style={bd} onClick={() => deleteOrgTemplate(t)}>Delete</button>
                    </div>
                  </div>
                ))}`,
      replacement: `                <div style={{ display: 'flex', gap: 8, marginBottom: 10, flexWrap: 'wrap' }}>
                  <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder="Search my templates…" value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                  <button style={bp} onClick={saveAsOrgTemplate}>💾 Save Current As Template</button>
                  <label style={{ ...bs, cursor: 'pointer' }}>
                    📥 Import Template
                    <input type="file" accept="application/json" style={{ display: 'none' }} onChange={e => { if (e.target.files && e.target.files[0]) importTemplateFile(e.target.files[0]); e.target.value = '' }} />
                  </label>
                </div>
                {orgTemplates.length === 0 ? <EmptyMsg text="No saved templates yet." /> : orgTemplates.map((t: any) => (
                  <div key={t._id} style={{ padding: '8px 0', borderBottom: \`1px solid \${BOR}\` }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 6 }}>
                      <span style={{ fontSize: 12, color: TS }}>{t.isFavorite ? '⭐ ' : ''}{t.name} <span style={{ color: DIM, fontSize: 10 }}>({t.category} · used {t.usageCount || 0}× · v{(t.versions || []).length + 1})</span></span>
                      <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                        <button style={bs} onClick={() => setPreviewTemplate(t)}>👁 Preview</button>
                        <button style={bs} onClick={() => applyOrgTemplate(t)}>Apply</button>
                        <button style={bs} onClick={() => toggleOrgTemplateFav(t)}>{t.isFavorite ? 'Unfavorite' : 'Favorite'}</button>
                        <button style={bs} onClick={() => cloneOrgTemplate(t)}>Clone</button>
                        <button style={bs} onClick={() => exportOrgTemplate(t)}>Export</button>
                        <button style={bs} onClick={() => setTemplateVersionsOpenId(templateVersionsOpenId === t._id ? '' : t._id)}>Versions</button>
                        <button style={bd} onClick={() => deleteOrgTemplate(t)}>Delete</button>
                      </div>
                    </div>
                    {templateVersionsOpenId === t._id && (
                      <div style={{ marginTop: 6, paddingLeft: 10, borderLeft: \`2px solid \${BOR}\` }}>
                        {(!t.versions || t.versions.length === 0) ? <div style={{ fontSize: 10.5, color: DIM }}>No previous versions.</div> : t.versions.slice().reverse().map((v: any, i: number) => {
                          const realIdx = t.versions.length - 1 - i
                          return (
                            <div key={realIdx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 10.5, color: DIM, padding: '4px 0' }}>
                              <span>{v.label || ('v' + (realIdx + 1))} · {new Date(v.savedAt).toLocaleString()}</span>
                              <button style={bs} onClick={() => restoreTemplateVersion(t, realIdx)}>Restore</button>
                            </div>
                          )
                        })}
                      </div>
                    )}
                  </div>
                ))}`
    },

    // ══════════════════════════════════════════════════════════════
    // F11: Brand Kit tab — multi-preset selector (Saved Brand Kits) +
    // unchanged color/font/logo/watermark fields + Apply Brand Kit /
    // Apply Logo / Apply Watermark buttons
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F11. Brand Kit: multi-preset selector + Apply Logo/Watermark buttons',
      skipIfPresent: 'onClick={applyLogoToBanner}',
      anchor: `            {assetTab === 'brandkit' && brandKit && (
              <div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginBottom: 10 }}>
                  <div><label style={lbl}>Primary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.primaryColor} onChange={e => saveBrandKitField({ primaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Secondary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.secondaryColor} onChange={e => saveBrandKitField({ secondaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Accent</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.accentColor} onChange={e => saveBrandKitField({ accentColor: e.target.value })} /></div>
                  <div><label style={lbl}>Font Pair</label>
                    <select style={inp} value={brandKit.fontPair} onChange={e => saveBrandKitField({ fontPair: e.target.value })}>
                      {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                    </select>
                  </div>
                  <div><label style={lbl}>Logo URL</label><input style={inp} value={brandKit.logoUrl || ''} onChange={e => setBrandKit({ ...brandKit, logoUrl: e.target.value })} onBlur={e => saveBrandKitField({ logoUrl: e.target.value })} /></div>
                  <div><label style={lbl}>Watermark URL</label><input style={inp} value={brandKit.watermarkUrl || ''} onChange={e => setBrandKit({ ...brandKit, watermarkUrl: e.target.value })} onBlur={e => saveBrandKitField({ watermarkUrl: e.target.value })} /></div>
                </div>
                <button style={bp} onClick={applyBrandKitToBanner}>✅ Apply Brand Kit to This Banner</button>
              </div>
            )}`,
      replacement: `            {assetTab === 'brandkit' && brandKit && (
              <div>
                <div style={{ marginBottom: 12 }}>
                  <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>💾 Saved Brand Kits</div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', alignItems: 'center' }}>
                    {brandKits.map((k: any) => (
                      <button key={k._id} style={k.isDefault ? bp : bs} onClick={() => !k.isDefault && setDefaultBrandKit(k._id)} title={k.isDefault ? 'Currently active preset' : 'Click to make this the active preset'}>
                        {k.isDefault ? '★ ' : ''}{k.name}
                        {!k.isDefault && <span onClick={(e) => { e.stopPropagation(); deleteBrandKitPreset(k._id) }} style={{ marginLeft: 6, opacity: 0.7 }}>✕</span>}
                      </button>
                    ))}
                    <button style={bs} onClick={createBrandKitPreset}>➕ New Preset</button>
                  </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginBottom: 10 }}>
                  <div><label style={lbl}>Primary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.primaryColor} onChange={e => saveBrandKitField({ primaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Secondary</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.secondaryColor} onChange={e => saveBrandKitField({ secondaryColor: e.target.value })} /></div>
                  <div><label style={lbl}>Accent</label><input style={{ ...inp, height: 34, padding: 2 }} type="color" value={brandKit.accentColor} onChange={e => saveBrandKitField({ accentColor: e.target.value })} /></div>
                  <div><label style={lbl}>Font Pair</label>
                    <select style={inp} value={brandKit.fontPair} onChange={e => saveBrandKitField({ fontPair: e.target.value })}>
                      {BN_FONTS.map(f => <option key={f.id} value={f.id}>{f.label}</option>)}
                    </select>
                  </div>
                  <div><label style={lbl}>Logo URL</label><input style={inp} value={brandKit.logoUrl || ''} onChange={e => setBrandKit({ ...brandKit, logoUrl: e.target.value })} onBlur={e => saveBrandKitField({ logoUrl: e.target.value })} /></div>
                  <div><label style={lbl}>Watermark URL</label><input style={inp} value={brandKit.watermarkUrl || ''} onChange={e => setBrandKit({ ...brandKit, watermarkUrl: e.target.value })} onBlur={e => saveBrandKitField({ watermarkUrl: e.target.value })} /></div>
                </div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <button style={bp} onClick={applyBrandKitToBanner}>✅ Apply Brand Kit to This Banner</button>
                  <button style={bs} onClick={applyLogoToBanner}>🏷️ Apply Official Logo</button>
                  <button style={bs} onClick={applyWatermarkToBanner}>💧 Apply Watermark</button>
                </div>
              </div>
            )}`
    },

    // ══════════════════════════════════════════════════════════════
    // F12: Asset tabs list — add "🤖 AI Recommended" tab
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F12. AI Recommended Assets tab registered',
      skipIfPresent: "['recommended', '🤖 AI Recommended']",
      anchor: `              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography'], ['background', '🌌 Backgrounds'], ['cta', '🔘 CTA Elements']].map(([k, l]) => (`,
      replacement: `              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['recommended', '🤖 AI Recommended'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography'], ['background', '🌌 Backgrounds'], ['cta', '🔘 CTA Elements']].map(([k, l]) => (`
    },
    // AI Recommended Assets rendering block (inserted before Background tab block)
    {
      label: 'F13. AI Recommended Assets rendering block',
      skipIfPresent: "assetTab === 'recommended' && (",
      anchor: `            {assetTab === 'background' && (`,
      replacement: `            {assetTab === 'recommended' && (
              <div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 10, lineHeight: 1.6 }}>🤖 Recommended from the asset library based on this batch's exam type — a keyword-matching engine, not generative AI (no image-gen API is configured).</div>
                {recommendedAssets.length === 0 ? <EmptyMsg text="No recommendations yet — try adding more assets to the library." /> : (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(80px,1fr))', gap: 8 }}>
                    {recommendedAssets.map((a: any) => (
                      <div key={a._id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 8, position: 'relative' }} onClick={() => addOrReplaceAssetLayer(a)} title={a.name}>
                        <span style={{ position: 'absolute', top: 2, right: 4, fontSize: 9 }}>🤖</span>
                        <div style={{ width: 40, height: 40, margin: '0 auto 4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          {a.type === 'icon' ? <span style={{ fontSize: 24 }}>{a.content}</span> : a.type === 'typography' ? <span style={{ fontSize: 10, color: TS }}>Aa</span> : a.type === 'media' ? <img src={a.content} style={{ maxWidth: '100%', maxHeight: '100%' }} /> : <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: a.content }} />}
                        </div>
                        <div style={{ fontSize: 8.5, color: DIM }}>{a.name}</div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {assetTab === 'background' && (`
    },

    // ══════════════════════════════════════════════════════════════
    // F14: Sticker/Decorative/SubjectGraphic/Icon/Typography grid —
    // Favorites/Recent/Most-Used filter + favorite star toggle +
    // asset click now respects "replace" mode via addOrReplaceAssetLayer
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F14. Asset grid: Favorites/Recent/Most-Used filter + true-replace click wiring',
      skipIfPresent: "assetFilter === f ? bp : bs",
      anchor: `            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
              <div>
                <input style={{ ...inp, marginBottom: 10 }} placeholder={'Search ' + assetTab + '…'} value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(80px,1fr))', gap: 8 }}>
                  {(assetsMap[assetTab] || []).filter((a: any) => a.name.toLowerCase().includes(assetSearch.toLowerCase())).map((a: any) => (
                    <div key={a._id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 8 }} onClick={() => addAssetLayer(a)} title={a.name}>
                      <div style={{ width: 40, height: 40, margin: '0 auto 4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {a.type === 'icon' ? <span style={{ fontSize: 24 }}>{a.content}</span> : a.type === 'typography' ? <span style={{ fontSize: 10, color: TS }}>Aa</span> : <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: a.content }} />}
                      </div>
                      <div style={{ fontSize: 8.5, color: DIM }}>{a.name}</div>
                    </div>
                  ))}
                </div>
                {(assetsMap[assetTab] || []).length === 0 && <EmptyMsg text="No assets yet — run the one-time seed from the admin setup, or contact support." />}
              </div>
            )}`,
      replacement: `            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
              <div>
                {replacingLayerId && <div style={{ fontSize: 10.5, color: '#FFD700', marginBottom: 8, padding: '6px 8px', borderRadius: 6, background: 'rgba(255,215,0,0.08)' }}>🔁 Replace mode — pick any asset to swap it into the selected layer. <span style={{ cursor: 'pointer', textDecoration: 'underline' }} onClick={() => setReplacingLayerId('')}>Cancel</span></div>}
                <div style={{ display: 'flex', gap: 6, marginBottom: 8, flexWrap: 'wrap' }}>
                  <input style={{ ...inp, flex: 1, minWidth: 140 }} placeholder={'Search ' + assetTab + '…'} value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                  {['all', 'favorites', 'recent', 'most_used'].map(f => <button key={f} style={assetFilter === f ? bp : bs} onClick={() => setAssetFilter(f)}>{f === 'all' ? 'All' : f === 'favorites' ? '⭐ Favorites' : f === 'recent' ? 'Recent' : 'Most Used'}</button>)}
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(80px,1fr))', gap: 8 }}>
                  {(assetsMap[assetTab] || [])
                    .filter((a: any) => a.name.toLowerCase().includes(assetSearch.toLowerCase()))
                    .filter((a: any) => assetFilter !== 'favorites' || a.isFavorite)
                    .slice().sort((a: any, b: any) => assetFilter === 'recent' ? (new Date(b.lastUsedAt || 0).getTime() - new Date(a.lastUsedAt || 0).getTime()) : assetFilter === 'most_used' ? ((b.usageCount || 0) - (a.usageCount || 0)) : 0)
                    .map((a: any) => (
                    <div key={a._id} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 8, position: 'relative' }} title={a.name}>
                      <span onClick={(e) => { e.stopPropagation(); toggleAssetFavorite(a, assetTab) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 11 }}>{a.isFavorite ? '⭐' : '☆'}</span>
                      <div onClick={() => addOrReplaceAssetLayer(a)} style={{ width: 40, height: 40, margin: '0 auto 4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {a.type === 'icon' ? <span style={{ fontSize: 24 }}>{a.content}</span> : a.type === 'typography' ? <span style={{ fontSize: 10, color: TS }}>Aa</span> : <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: a.content }} />}
                      </div>
                      <div onClick={() => addOrReplaceAssetLayer(a)} style={{ fontSize: 8.5, color: DIM }}>{a.name}</div>
                    </div>
                  ))}
                </div>
                {(assetsMap[assetTab] || []).length === 0 && <EmptyMsg text="No assets yet — run the one-time seed from the admin setup, or contact support." />}
              </div>
            )}`
    },

    // ══════════════════════════════════════════════════════════════
    // F15: Analytics — add cross-banner by-template / by-CTA breakdown
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F15. Analytics: performance by-template and by-CTA breakdown',
      skipIfPresent: 'Performance by Template (platform-wide)',
      anchor: `          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>
            {!analytics ? <EmptyMsg text="No analytics yet." /> : (
              <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
                Views: {analytics.views} · Clicks: {analytics.clicks} · Enrolls: {analytics.enrolls}<br />
                Click Rate: {analytics.clickRate}% · Conversion Rate: {analytics.conversionRate}%
              </div>
            )}
          </div>`,
      replacement: `          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>
            {!analytics ? <EmptyMsg text="No analytics yet." /> : (
              <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
                Views: {analytics.views} · Clicks: {analytics.clicks} · Enrolls: {analytics.enrolls}<br />
                Click Rate: {analytics.clickRate}% · Conversion Rate: {analytics.conversionRate}%
              </div>
            )}
            <div style={{ marginTop: 12, paddingTop: 12, borderTop: \`1px solid \${BOR}\` }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>📈 Performance by Template (platform-wide)</div>
              {templateAnalytics.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>Not enough data yet.</div> : templateAnalytics.slice(0, 5).map((t: any, i: number) => (
                <div key={i} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}>{t.template}{form.template === t.template ? ' (current)' : ''} — {t.count} banner(s) · {t.conversionRate}% conversion</div>
              ))}
              <div style={{ fontSize: 11, color: DIM, margin: '10px 0 6px' }}>🔘 Performance by CTA (platform-wide)</div>
              {ctaAnalytics.length === 0 ? <div style={{ fontSize: 10.5, color: DIM }}>Not enough data yet.</div> : ctaAnalytics.slice(0, 5).map((c: any, i: number) => (
                <div key={i} style={{ fontSize: 10.5, color: DIM, padding: '3px 0' }}>{c.cta} — {c.count} banner(s) · {c.conversionRate}% conversion</div>
              ))}
            </div>
          </div>`
    },

    // ══════════════════════════════════════════════════════════════
    // F16: Keyboard shortcuts — Ctrl+S, Delete, Escape
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F16. Additional keyboard shortcuts (Ctrl+S / Delete / Escape)',
      skipIfPresent: "e.key === 'Delete' || e.key === 'Backspace'",
      anchor: `    const onKey = (e: any) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) { e.preventDefault(); undo() }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) { e.preventDefault(); redo() }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [historyStack, redoStack])`,
      replacement: `    const onKey = (e: any) => {
      const tag = ((e.target && e.target.tagName) || '').toLowerCase()
      const inField = tag === 'input' || tag === 'textarea' || tag === 'select'
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) { e.preventDefault(); undo() }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) { e.preventDefault(); redo() }
      else if ((e.ctrlKey || e.metaKey) && e.key === 's') { e.preventDefault(); if (form?.title?.trim()) saveBanner({ saveAsDraft: true }) }
      else if ((e.key === 'Delete' || e.key === 'Backspace') && !inField && selectedLayerId) { e.preventDefault(); removeLayer(selectedLayerId) }
      else if (e.key === 'Escape') { if (replacingLayerId) setReplacingLayerId(''); else if (selectedLayerId) setSelectedLayerId('') }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [historyStack, redoStack, selectedLayerId, form, replacingLayerId])`
    },

    // ══════════════════════════════════════════════════════════════
    // F17: Integration Summary panel + Preview-Template modal
    // ══════════════════════════════════════════════════════════════
    {
      label: 'F17. Integration Summary panel + Preview Template modal',
      skipIfPresent: '📎 Integration Summary',
      anchor: `          <div style={{ ...cs, fontSize: 11, color: DIM }}>
            🔗 This banner is linked to <b style={{ color: TS }}>{data.batchName}</b>. Publish / Launch happens in the separate Publish Center (coming soon) — not from this tab.
          </div>
        </>
      )}

      {showIllustrations && <BN_IllustrationModal onSelect={(url: string) => setForm({ ...form, bgImage: url })} onClose={() => setShowIllustrations(false)} />}
    </div>
  )
}`,
      replacement: `          <div style={cs}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: showIntegrationSummary ? 10 : 0, cursor: 'pointer' }} onClick={() => setShowIntegrationSummary(v => !v)}>
              <div style={{ fontWeight: 700, color: TS }}>📎 Integration Summary</div>
              <span style={{ fontSize: 11, color: DIM }}>{showIntegrationSummary ? '▾ Hide' : '▸ Show'}</span>
            </div>
            {showIntegrationSummary && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 10, fontSize: 11, color: DIM, lineHeight: 1.9 }}>
                <div>🔗 Linked Product: <b style={{ color: TS }}>{data.batchName}</b></div>
                <div>📌 Banner Status: <b style={{ color: TS }}>{form.status}</b></div>
                <div>🔄 Sync State: <b style={{ color: TS }}>{(form.syncState || '—').replace('_', ' ')}</b></div>
                <div>⭐ Quality Score: <b style={{ color: (data.overview?.qualityScore || 0) >= 60 ? GOOD : WARN }}>{data.overview?.qualityScore || 0}/100</b></div>
                <div>🕐 Versions Saved: <b style={{ color: TS }}>{(form.versions || []).length}</b></div>
                <div>🗂️ Layers Placed: <b style={{ color: TS }}>{(form.layers || []).length}</b></div>
                <div>👁️ Views: <b style={{ color: TS }}>{analytics?.views ?? 0}</b> · Clicks: <b style={{ color: TS }}>{analytics?.clicks ?? 0}</b> · Enrolls: <b style={{ color: TS }}>{analytics?.enrolls ?? 0}</b></div>
                <div>📋 Last Audit Action: <b style={{ color: TS }}>{audit && audit.length > 0 ? audit[0].action : '—'}</b></div>
                <div>🕒 Last Updated: <b style={{ color: TS }}>{form.updatedAt ? new Date(form.updatedAt).toLocaleString() : '—'}</b></div>
              </div>
            )}
          </div>

          <div style={{ ...cs, fontSize: 11, color: DIM }}>
            🔗 This banner is linked to <b style={{ color: TS }}>{data.batchName}</b>. Publish / Launch happens in the separate Publish Center (coming soon) — not from this tab.
          </div>
        </>
      )}

      {showIllustrations && <BN_IllustrationModal onSelect={(url: string) => setForm({ ...form, bgImage: url })} onClose={() => setShowIllustrations(false)} />}
      {previewTemplate && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={() => setPreviewTemplate(null)}>
          <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 420, width: '100%', border: \`1px solid \${BOR2}\` }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
              <div style={{ fontWeight: 700, color: TS }}>👁 Preview — {previewTemplate.name}</div>
              <button style={bs} onClick={() => setPreviewTemplate(null)}>✕</button>
            </div>
            <BannerLivePreview b={{ ...form, ...previewTemplate.config }} size="card" showSafeZone={false} />
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              <button style={{ ...bs, flex: 1 }} onClick={() => setPreviewTemplate(null)}>Cancel</button>
              <button style={{ ...bp, flex: 1 }} onClick={() => { applyOrgTemplate(previewTemplate); setPreviewTemplate(null) }}>✅ Apply This Template</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}`
    }  ]);
}
console.log('\n✅ All V2 frontend patches applied successfully to', FILES.length, 'file(s).');
NODEEOF

echo "════════════════════════════════════════════════"
echo "🔧  Running patcher on both files..."
echo "════════════════════════════════════════════════"
node /tmp/banner_frontend_v2_patch.js "$BATCH_FILE" "$SERIES_FILE"
PATCH_EXIT=$?
rm -f /tmp/banner_frontend_v2_patch.js

if [ $PATCH_EXIT -ne 0 ]; then
  restore_and_exit "Patch failed"
fi

# ────────────────────────────────────────────────────────────────────
# Syntax-check both patched TSX files using @babel/parser (installed
# temporarily, dev-only, does not touch your project's package.json)
# ────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo "🧪  Syntax-checking patched TSX files..."
echo "════════════════════════════════════════════════"

TMPCHECK=/tmp/banner_tsx_v2_check_$TS
mkdir -p "$TMPCHECK"
cd "$TMPCHECK"
npm init -y >/dev/null 2>&1
npm install --no-save @babel/parser >/dev/null 2>&1
cd ~/workspace

cat > "$TMPCHECK/check.js" << 'CHECKEOF'
const parser = require('@babel/parser');
const fs = require('fs');
const file = process.argv[2];
const code = fs.readFileSync(file, 'utf8');
try {
  parser.parse(code, { sourceType: 'module', plugins: ['jsx', 'typescript'] });
  console.log('✅ PARSE OK:', file);
  process.exit(0);
} catch (e) {
  console.error('❌ PARSE ERROR:', file);
  console.error('Line', e.loc ? e.loc.line : '?', 'Col', e.loc ? e.loc.column : '?', '-', e.message);
  process.exit(1);
}
CHECKEOF

SYNTAX_OK=1
node "$TMPCHECK/check.js" "$BATCH_FILE" || SYNTAX_OK=0
node "$TMPCHECK/check.js" "$SERIES_FILE" || SYNTAX_OK=0
rm -rf "$TMPCHECK"

if [ $SYNTAX_OK -eq 0 ]; then
  restore_and_exit "Syntax errors found in patched file(s)"
fi

# ════════════════════════════════════════════════════════════════════
# VERIFICATION CHECKLIST — every sub-feature of the Banner Management
# Tab spec (original + both gap-analysis passes, fully merged),
# checked against BOTH files AND the backend route files.
# ✅ = present, ⚠️ = present in only one file (inconsistent),
# ❌ = missing.
# ════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "✅ VERIFICATION — Banner Management Tab V2 — ALL sub-features"
echo "════════════════════════════════════════════════"

check() {
  local b=0; local s=0
  grep -qF "$2" "$BATCH_FILE" 2>/dev/null && b=1
  grep -qF "$2" "$SERIES_FILE" 2>/dev/null && s=1
  if [ $b -eq 1 ] && [ $s -eq 1 ]; then echo "✅ $1"
  elif [ $b -eq 1 ] || [ $s -eq 1 ]; then echo "⚠️  $1  (present in only ONE of Batch/Series)"
  else echo "❌ $1  (MISSING in both files)"; fi
}
checkBackend() {
  if grep -qF "$2" "src/routes/batchManagerUltra.js" 2>/dev/null && grep -qF "$2" "src/routes/testSeriesManagerUltra.js" 2>/dev/null; then echo "✅ $1"
  else echo "❌ $1  (check src/routes/*ManagerUltra.js — did you run the backend V2 script first?)"; fi
}

echo ""
echo "── Tab scope, placement & base structure (pre-existing, preserved) ──"
check "Banner tab registered next to Coupons tab"          "{tab === 'banner' && <BannerManagementTab"
checkBackend "Tab scoped to current product only (linkedBatchId query)" "linkedBatchId: req.params.id"
check "Overview: quality score / sync state display"        "qualityScore"
check "Actions: Edit/Replace/Duplicate/Remove/Restore/Sync"  "replaceBanner"
check "Save Draft / Save & Mark Ready / Discard"               "markReady: true"
check "Content fields (title/tagline/price/CTA/badge/highlights)" "'Highlight ' + (i + 1)"
check "Smart Copy Suggestions"                                  "showSuggestions"
check "Live Validation (missing title/CTA/invalid image etc.)"   "warnings.push("
check "Safe Zone Guide"                                            "safeZoneMode"
check "Card/Wide/Square/Mobile preview + PNG download"               "html2canvas"
check "Built-in templates"                                             "BN_TEMPLATES"
check "Org templates: save/apply/favorite/clone/export/delete"          "toggleOrgTemplateFav"
check "Compare Templates"                                                 "Compare Templates ({compareList"
check "Layer system: drag/scale/rotate/opacity/lock/flip/shadow/border/blend" "updateLayer"
check "Undo / Redo / Auto-Save Draft"                                       "autoSave"
check "Audit Trail log"                                                       "audit.map"
check "No Publish button (Publish Center is separate — correct scope)"         "separate Publish Center"

echo ""
echo "── 🆕 V2 sub-features (this script) ──"
check "1. Illustration Library search bar"                     'placeholder="Search illustrations…"'
check "2. Expanded illustrations — Medical/Engineering/CUET/SSC/UPSC/Banking/Defence/Law/MBA" "id: 'stethoscope-il'"
check "3. Crop controls UI (Top/Right/Bottom/Left sliders)"       "Crop (Safe Zone Trim)"
check "3. Crop FIX — actually wired into preview rendering (clip-path)" "const renderLayerContent = (l: any) => {"
check "4. BUG FIX — layer images render for http(s) URLs too"        "test(l.content)"
check "5. Apply Official Logo (as layer)"                               "applyLogoToBanner"
check "5. Apply Watermark (as layer)"                                    "applyWatermarkToBanner"
check "6. View Version Diff (banner instance)"                            "versionDiff"
check "7. Duplicate Version (banner instance)"                             "duplicateVersion(realIdx)"
check "8. Media Upload — real upload, background target"                    "uploadBannerImage(e.target.files[0], 'background')"
check "8. Media Upload — real upload, layer target"                          "uploadBannerImage(e.target.files[0], 'layer')"
check "9. Import Template"                                                     "importTemplateFile"
check "10. Preview Before Apply (org templates)"                                "setPreviewTemplate(t)"
check "11. AI-Recommended Assets tab"                                             "🤖 AI Recommended"
check "12. Keyboard shortcut: Ctrl+S save draft"                                   "e.key === 's'"
check "12. Keyboard shortcut: Delete/Backspace remove layer"                        "e.key === 'Delete' || e.key === 'Backspace'"
check "12. Keyboard shortcut: Escape (deselect / cancel replace)"                     "if (replacingLayerId) setReplacingLayerId('')"
check "13. Integration Summary panel"                                                   "📎 Integration Summary"
check "14. Section Visibility toggle (Layout Controls)"                                  "toggleSectionVisible"
check "14. Section Lock toggle — WITH real enforcement (disabled fields)"                  "disabled={!!(form.sectionLock || {}).title}"
check "15. Badge Style / Card Style / Gradient Angle / Spacing controls"                     "Gradient Angle ("
check "16. Multi-preset Brand Kit (Saved Brand Kits)"                                          "createBrandKitPreset"
check "17. Cross-banner Analytics — by Template"                                                 "Performance by Template (platform-wide)"
check "17. Cross-banner Analytics — by CTA"                                                        "Performance by CTA (platform-wide)"
check "18. Asset Favorites / Recent / Most-Used filters"                                             "most_used"
check "19. Template Version History + Restore (previously dead endpoint, now wired)"                   "restoreTemplateVersion"
check "20. TRUE Replace Asset (position-preserving, not just add-new)"                                    "startReplaceAsset"
check "21. Smart Replace Font (cycle)"                                                                       "cycleFontStyle"

echo ""
echo "── Backend routes this frontend depends on ──"
if grep -qF "router.post('/assets/upload-image'" src/routes/bannerAssets.js 2>/dev/null; then echo "✅ Backend: media upload endpoint present"; else echo "❌ Backend: media upload endpoint MISSING — run fix_banner_management_backend_v2.sh"; fi
if grep -qF "router.get('/assets/recommended'" src/routes/bannerAssets.js 2>/dev/null; then echo "✅ Backend: AI-recommended endpoint present"; else echo "❌ Backend: AI-recommended endpoint MISSING — run fix_banner_management_backend_v2.sh"; fi
if grep -qF "router.get('/brand-kits'" src/routes/bannerAssets.js 2>/dev/null; then echo "✅ Backend: multi-preset brand kit endpoints present"; else echo "❌ Backend: multi-preset brand kit endpoints MISSING — run fix_banner_management_backend_v2.sh"; fi
if grep -qF "router.get('/analytics/templates'" src/routes/bannerAssets.js 2>/dev/null; then echo "✅ Backend: cross-banner analytics endpoints present"; else echo "❌ Backend: cross-banner analytics endpoints MISSING — run fix_banner_management_backend_v2.sh"; fi
checkBackend "Backend: Duplicate Version endpoint" "router.post('/:id/banner/duplicate-version"
checkBackend "Backend: whitelist includes all new Banner fields" "'sectionVisibility', 'sectionLock', 'badgeStyle'"
if grep -qF "cropTop: { type: Number, default: 0 }" src/models/Banner.js 2>/dev/null; then echo "✅ Backend: Banner.layers crop fields present"; else echo "❌ Backend: Banner.layers crop fields MISSING — run fix_banner_management_backend_v2.sh"; fi

echo ""
echo "════════════════════════════════════════════════"
echo "🎉 Frontend V2 patching complete."
echo "   Backups kept at: $BACKUP_DIR"
echo "   If any ⚠️/❌ appear above, do NOT ignore them —"
echo "   share this output so the patch can be corrected."
echo "   Restart your Next.js dev server / rebuild to see changes:"
echo "     cd ~/workspace/frontend && npm run dev"
echo "════════════════════════════════════════════════"
