#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 8: Bug fix + Text Intelligence + Sync
# State Refinement
#
# FIXES:
#   🐛 Typography presets were being added as a visual LAYER (since
#      addAssetLayer() didn't special-case them), producing a broken
#      generic 🖼️ placeholder floating on the banner. Typography is a
#      TEXT STYLE, not an overlay image — clicking a preset now
#      applies it to banner.textStyleOverride directly (title font
#      weight/size/family), no stray layer created.
#
# ADDS:
#   • Auto Text Alignment — Left/Center/Right toggle for the title
#     block (new `textAlign` field)
#   • Dynamic Font Scaling — title font-size now actually shrinks for
#     long titles (was previously just a warning, no real effect)
#   • Smart Text Wrapping — title clamps to 2 lines with ellipsis
#     instead of overflowing the card
#   • Sync State refinement — "Conflict" now genuinely fires when a
#     manually-customized banner's product ALSO changed since (was
#     previously indistinguishable from plain manual_override);
#     "Ready To Edit" label shown for a fresh, never-edited draft
#   • Auto-draft-on-create hook (already existed from earlier FPR3
#     work) upgraded to fill the SAME complete defaults (CTA text,
#     template, colors, font) that the tab's own Auto-Generate button
#     uses, instead of a bare-minimum record
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"
BANNER_MODEL="src/models/Banner.js"

for f in "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX" "$BANNER_MODEL"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_part8.js << 'NODEEOF'
const fs = require('fs');
function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) { console.error(`❌ [${path}] anchor not found: ${label}`); process.exit(1); }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

// ══════════════════════════════════════════
// A) Banner.js — add textAlign field
// ══════════════════════════════════════════
replaceExact('src/models/Banner.js', [
[
'Banner.js — add textAlign field',
`  ctaShape: { type: String, enum: ['pill', 'rounded', 'square', 'outline'], default: 'pill' },`,
`  ctaShape: { type: String, enum: ['pill', 'rounded', 'square', 'outline'], default: 'pill' },
  textAlign: { type: String, enum: ['left', 'center', 'right'], default: 'left' },`
]
]);

// ══════════════════════════════════════════
// B) batchManagerUltra.js / testSeriesManagerUltra.js — whitelist
//    textAlign + refine checkBannerSyncState (conflict detection)
// ══════════════════════════════════════════
const oldSyncFn = `function checkBannerSyncState(banner, batch) {
  if (banner.syncState === 'manual_override') return 'manual_override';
  const live = buildBannerSyncFields(batch);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  return mismatch ? 'pending_sync' : 'synced';
}`;
const newSyncFn = `function checkBannerSyncState(banner, batch) {
  const live = buildBannerSyncFields(batch);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  if (banner.syncState === 'manual_override') return mismatch ? 'conflict' : 'manual_override';
  return mismatch ? 'pending_sync' : 'synced';
}`;

const oldSyncFnSeries = `function checkBannerSyncState(banner, series) {
  if (banner.syncState === 'manual_override') return 'manual_override';
  const live = buildBannerSyncFields(series);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  return mismatch ? 'pending_sync' : 'synced';
}`;
const newSyncFnSeries = `function checkBannerSyncState(banner, series) {
  const live = buildBannerSyncFields(series);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  if (banner.syncState === 'manual_override') return mismatch ? 'conflict' : 'manual_override';
  return mismatch ? 'pending_sync' : 'synced';
}`;

replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — refine checkBannerSyncState',
oldSyncFn, newSyncFn
],
[
'batchManagerUltra — add textAlign to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride', 'textAlign'];`
],
[
'batchManagerUltra — enhance auto-draft-on-create hook with full defaults',
`        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'batch',
          examType: doc.examType, price: doc.price, status: 'draft',
          syncState: 'synced', published: false
        });`,
`        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'batch',
          examType: doc.examType, price: String(doc.price || 0), status: 'draft',
          syncState: 'synced', published: false,
          tagline: '', ctaText: 'Enroll Now', ctaShape: 'pill', template: 'classic',
          primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
          fontStyle: 'modern', textAlign: 'left', badge: doc.isSpotlight ? 'trending' : 'none',
          totalTests: '0', validity: (doc.validity || 365) + ' days', duration: (doc.validity || 365) + ' days',
          highlights: ['0 Practice Tests', (doc.validity || 365) + ' days Validity', doc.language || 'Hindi + English'],
          createdBy: req.user.id
        });`
]
]);

replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — refine checkBannerSyncState',
oldSyncFnSeries, newSyncFnSeries
],
[
'testSeriesManagerUltra — add textAlign to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride', 'textAlign'];`
]
]);

// Try to enhance the series auto-draft hook too, if the same pattern exists there (non-fatal if absent)
try {
  const seriesSrc = fs.readFileSync('src/routes/testSeriesManagerUltra.js', 'utf8');
  const oldSeriesHook = `        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'series',
          examType: doc.examType, price: doc.price, status: 'draft',
          syncState: 'synced', published: false
        });`;
  if (seriesSrc.includes(oldSeriesHook)) {
    replaceExact('src/routes/testSeriesManagerUltra.js', [
    [
    'testSeriesManagerUltra — enhance auto-draft-on-create hook',
    oldSeriesHook,
    `        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'series',
          examType: doc.examType, price: String(doc.price || 0), status: 'draft',
          syncState: 'synced', published: false,
          tagline: '', ctaText: 'Enroll Now', ctaShape: 'pill', template: 'classic',
          primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
          fontStyle: 'modern', textAlign: 'left', badge: doc.isSpotlight ? 'trending' : 'none',
          totalTests: '0', validity: (doc.validity || 365) + ' days', duration: (doc.validity || 365) + ' days',
          highlights: ['0 Practice Tests', (doc.validity || 365) + ' days Validity', doc.language || 'Hindi + English'],
          createdBy: req.user.id
        });`
    ]
    ]);
  } else {
    console.log('⚠️  testSeriesManagerUltra.js — auto-draft hook pattern not found (may already differ) — skipped, not critical');
  }
} catch (e) { console.log('⚠️  Could not enhance series auto-draft hook:', e.message); }

// ══════════════════════════════════════════
// C) Frontend — fix typography bug in addAssetLayer + title
//    rendering (font-scale/wrap/align), both tsx files (same patch)
// ══════════════════════════════════════════
const oldAddAssetLayer = `  const addAssetLayer = (asset: any) => {
    const layer = { id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), type: asset.type, content: asset.content, assetId: asset._id, x: 50, y: 50, scale: 1, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal' }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }`;
const newAddAssetLayer = `  const addAssetLayer = (asset: any) => {
    if (asset.type === 'typography') {
      // Typography presets are a TEXT STYLE, not a visual layer —
      // apply directly to the title's style instead of adding an
      // overlay (fixes: previously created a broken placeholder layer).
      try {
        const style = JSON.parse(asset.content)
        setForm({ ...form, textStyleOverride: style })
        fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
        showToast('✅ Title style applied: ' + asset.name)
      } catch (e) { showToast('⚠️ Could not apply this typography style') }
      return
    }
    const layer = { id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), type: asset.type, content: asset.content, assetId: asset._id, x: 50, y: 50, scale: 1, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal' }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }`;

const oldTitleBlock = `      <div>
        <div style={{ fontSize: size === 'square' ? 18 : 16, fontWeight: 800, lineHeight: 1.2 }}>{b.title || 'Batch Title'}</div>
        {b.tagline && <div style={{ fontSize: 10.5, opacity: 0.85, marginTop: 3 }}>{b.tagline}</div>}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 6 }}>
          {(b.highlights || []).filter(Boolean).slice(0, 3).map((h: string, i: number) => (
            <span key={i} style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 6, background: 'rgba(255,255,255,0.15)' }}>{h}</span>
          ))}
        </div>
      </div>`;
const newTitleBlock = `      <div style={{ textAlign: (b.textAlign || 'left') as any }}>
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
      </div>`;

const oldSyncDisplay = `                <div style={{ fontSize: 11, color: DIM, marginTop: 2 }}>Sync: {form.syncState?.replace('_', ' ')}</div>`;
const newSyncDisplay = `                <div style={{ fontSize: 11, color: DIM, marginTop: 2 }}>Sync: {form.status === 'draft' && form.syncState === 'synced' ? 'Ready To Edit' : form.syncState?.replace('_', ' ')}</div>`;

// Text alignment toggle — insert into Banner Builder, right after the
// Badge dropdown grid (reuse the same "CTA/Badge" grid closing anchor)
const oldBuilderGridEnd = `              <div><label style={lbl}>Badge / Ribbon</label>
                <select style={inp} value={form.badge || 'none'} onChange={e => setForm({ ...form, badge: e.target.value })}>
                  {BN_BADGES.map(b => <option key={b.id} value={b.id}>{b.label}</option>)}
                </select>
              </div>
            </div>`;
const newBuilderGridEnd = `              <div><label style={lbl}>Badge / Ribbon</label>
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
            </div>`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — fix typography bug', oldAddAssetLayer, newAddAssetLayer],
  ['BatchManagerUltra — title font-scale/wrap/align', oldTitleBlock, newTitleBlock],
  ['BatchManagerUltra — Ready To Edit label', oldSyncDisplay, newSyncDisplay],
  ['BatchManagerUltra — text alignment toggle', oldBuilderGridEnd, newBuilderGridEnd]
]);

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — fix typography bug', oldAddAssetLayer, newAddAssetLayer],
  ['TestSeriesManagerUltra — title font-scale/wrap/align', oldTitleBlock, newTitleBlock],
  ['TestSeriesManagerUltra — Ready To Edit label', oldSyncDisplay, newSyncDisplay],
  ['TestSeriesManagerUltra — text alignment toggle', oldBuilderGridEnd, newBuilderGridEnd]
]);

console.log('✅ PART 8 PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_part8.js

echo ""
echo "=== Syntax validation ==="
node --check src/models/Banner.js && echo "✅ Banner.js valid"
node --check src/routes/batchManagerUltra.js && echo "✅ batchManagerUltra.js valid"
node --check src/routes/testSeriesManagerUltra.js && echo "✅ testSeriesManagerUltra.js valid"

echo ""
echo "✅ Part 8 DONE."
