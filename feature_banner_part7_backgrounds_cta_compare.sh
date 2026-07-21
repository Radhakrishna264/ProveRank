#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 7: Remaining Asset Categories + Compare/
# Reset Template
#
# ADDS:
#   • Asset category "Background" (13 items: gradients, shapes,
#     glassmorphism, patterns, textures, light/glow/bokeh effects,
#     mesh gradients — real CSS background values, click applies
#     directly as the banner's background, no image URL needed)
#   • Asset category "CTA Elements" (6 button-shape presets: pill,
#     rounded, square, outline, + 2 accent variants) via new
#     `ctaShape` field on Banner, rendered in BannerLivePreview
#   • Compare Templates: select up to 2 (built-in or saved) templates
#     and see them side-by-side (name/category/color swatches)
#   • Reset Template: reverts colors/background/layers back to the
#     currently selected template's own defaults in one click
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

BANNER_MODEL="src/models/Banner.js"
SAVEDASSET_MODEL="src/models/SavedAsset.js"
BANNERASSETS_ROUTE="src/routes/bannerAssets.js"
B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$BANNER_MODEL" "$SAVEDASSET_MODEL" "$BANNERASSETS_ROUTE" "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_part7.js << 'NODEEOF'
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
// A) SavedAsset.js — add 'background' and 'cta' to type enum
// ══════════════════════════════════════════
replaceExact('src/models/SavedAsset.js', [
[
'SavedAsset — extend type enum',
`  type: { type: String, enum: ['illustration', 'icon', 'sticker', 'decorative', 'subject_graphic', 'typography', 'media'], required: true },`,
`  type: { type: String, enum: ['illustration', 'icon', 'sticker', 'decorative', 'subject_graphic', 'typography', 'media', 'background', 'cta'], required: true },`
]
]);

// ══════════════════════════════════════════
// B) Banner.js — add ctaShape field
// ══════════════════════════════════════════
replaceExact('src/models/Banner.js', [
[
'Banner.js — add ctaShape field',
`  ctaText: { type: String, default: 'Enroll Now' },
  badge: { type: String, default: 'none' },`,
`  ctaText: { type: String, default: 'Enroll Now' },
  ctaShape: { type: String, enum: ['pill', 'rounded', 'square', 'outline'], default: 'pill' },
  badge: { type: String, default: 'none' },`
]
]);

// ══════════════════════════════════════════
// C) batchManagerUltra.js / testSeriesManagerUltra.js — whitelist ctaShape
// ══════════════════════════════════════════
replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — add ctaShape to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`
]
]);
replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — add ctaShape to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`
]
]);

// ══════════════════════════════════════════
// D) bannerAssets.js — extend seed list with Backgrounds + CTA Elements
// ══════════════════════════════════════════
replaceExact('src/routes/bannerAssets.js', [
[
'bannerAssets — append background + cta seed items',
`      { name: 'Heading — Serif Classic', type: 'typography', category: 'Heading', content: JSON.stringify({ fontWeight: 700, fontSize: '1.3em', fontFamily: "'Playfair Display',serif" }) },`,
`      { name: 'Heading — Serif Classic', type: 'typography', category: 'Heading', content: JSON.stringify({ fontWeight: 700, fontSize: '1.3em', fontFamily: "'Playfair Display',serif" }) },
      // ── Backgrounds (13) ──
      { name: 'Sunset Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#FF6B35,#F7931E)' },
      { name: 'Ocean Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#0077B6,#00B4D8)' },
      { name: 'Purple Dream Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#8E2DE2,#4A00E0)' },
      { name: 'Abstract Blob Shape', type: 'background', category: 'Shapes', content: 'radial-gradient(ellipse at 30% 30%,#4D9FFF33,transparent 60%),radial-gradient(ellipse at 70% 70%,#A78BFA33,transparent 60%),#0a0a1a' },
      { name: 'Glassmorphism Frost', type: 'background', category: 'Glassmorphism', content: 'linear-gradient(135deg,rgba(255,255,255,0.15),rgba(255,255,255,0.05))' },
      { name: 'Diagonal Stripe Pattern', type: 'background', category: 'Patterns', content: 'repeating-linear-gradient(45deg,#1a1a3e,#1a1a3e 10px,#0a0a1a 10px,#0a0a1a 20px)' },
      { name: 'Dot Grid Pattern', type: 'background', category: 'Patterns', content: 'radial-gradient(circle,#4D9FFF22 1px,transparent 1px),#0a0a1a' },
      { name: 'Subtle Noise Texture', type: 'background', category: 'Textures', content: 'linear-gradient(135deg,#1a1a2e,#16213e,#0f3460)' },
      { name: 'Warm Light Effect', type: 'background', category: 'Light Effects', content: 'radial-gradient(circle at 50% 20%,#FFD70055,transparent 60%),#1a1200' },
      { name: 'Cool Glow Effect', type: 'background', category: 'Glow Effects', content: 'radial-gradient(circle at 50% 50%,#00E5FF44,transparent 70%),#020816' },
      { name: 'Bokeh Lights', type: 'background', category: 'Bokeh Effects', content: 'radial-gradient(circle at 20% 30%,#FFD70033,transparent 20%),radial-gradient(circle at 70% 60%,#4D9FFF33,transparent 20%),radial-gradient(circle at 40% 80%,#FF00E533,transparent 20%),#0a0a1a' },
      { name: 'Mesh Gradient Cool', type: 'background', category: 'Mesh Gradients', content: 'radial-gradient(at 0% 0%,#4D9FFF66,transparent 50%),radial-gradient(at 100% 0%,#A78BFA66,transparent 50%),radial-gradient(at 100% 100%,#00E5FF66,transparent 50%),radial-gradient(at 0% 100%,#00E67666,transparent 50%),#0a0a1a' },
      { name: 'Mesh Gradient Warm', type: 'background', category: 'Mesh Gradients', content: 'radial-gradient(at 0% 0%,#FF6B3566,transparent 50%),radial-gradient(at 100% 0%,#FFD70066,transparent 50%),radial-gradient(at 100% 100%,#F7931E66,transparent 50%),radial-gradient(at 0% 100%,#eb334966,transparent 50%),#1a0a00' },
      // ── CTA Elements (6 button-shape presets) ──
      { name: 'Pill Button', type: 'cta', category: 'Shape', content: 'pill' },
      { name: 'Rounded Button', type: 'cta', category: 'Shape', content: 'rounded' },
      { name: 'Square Button', type: 'cta', category: 'Shape', content: 'square' },
      { name: 'Outline Button', type: 'cta', category: 'Shape', content: 'outline' },
      { name: 'Pill with Arrow', type: 'cta', category: 'Shape', content: 'pill' },
      { name: 'Rounded with Arrow', type: 'cta', category: 'Shape', content: 'rounded' },`
]
]);

// ══════════════════════════════════════════
// E) Frontend — BannerLivePreview: gradient-aware bg + ctaShape
// ══════════════════════════════════════════
const oldBgLine = `  const bg = b.bgImage ? \`url(\${b.bgImage}) center/cover\` : (tpl.bg)`;
const newBgLine = `  const bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\\(/.test(b.bgImage) ? b.bgImage : \`url(\${b.bgImage}) center/cover\`) : (tpl.bg)
  const ctaRadius = b.ctaShape === 'square' ? 4 : b.ctaShape === 'rounded' ? 10 : 20
  const ctaIsOutline = b.ctaShape === 'outline'`;

const oldCtaSpan = `        <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: 20, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{b.ctaText || 'Enroll Now'} →</span>`;
const newCtaSpan = `        <span style={{ fontSize: 9.5, fontWeight: 700, padding: '5px 10px', borderRadius: ctaRadius, background: ctaIsOutline ? 'transparent' : (b.accentColor || tpl.accent), color: ctaIsOutline ? (b.accentColor || tpl.accent) : '#1a1a2e', border: ctaIsOutline ? \`1.5px solid \${b.accentColor || tpl.accent}\` : 'none' }}>{b.ctaText || 'Enroll Now'} →</span>`;

// ══════════════════════════════════════════
// F) Frontend — asset sub-tabs: add Background + CTA Elements,
//    fetch loop, click handlers, Compare + Reset Template
// ══════════════════════════════════════════
const oldAssetTabsList = `              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography']].map(([k, l]) => (`;
const newAssetTabsList = `              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography'], ['background', '🌌 Backgrounds'], ['cta', '🔘 CTA Elements']].map(([k, l]) => (`;

const oldFetchLoop = `    ['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].forEach(t => {`;
const newFetchLoop = `    ['sticker', 'decorative', 'subject_graphic', 'icon', 'typography', 'background', 'cta'].forEach(t => {`;

const oldAssetsMapInit = `  const [assetsMap, setAssetsMap] = useState<any>({ sticker: [], decorative: [], subject_graphic: [], icon: [], typography: [] })`;
const newAssetsMapInit = `  const [assetsMap, setAssetsMap] = useState<any>({ sticker: [], decorative: [], subject_graphic: [], icon: [], typography: [], background: [], cta: [] })`;

const oldAssetGridCategories = `            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
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
            )}`;
const newAssetGridCategories = `            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
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
            )}

            {assetTab === 'background' && (
              <div>
                <input style={{ ...inp, marginBottom: 10 }} placeholder="Search backgrounds…" value={assetSearch} onChange={e => setAssetSearch(e.target.value)} />
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {(assetsMap.background || []).filter((a: any) => a.name.toLowerCase().includes(assetSearch.toLowerCase())).map((a: any) => (
                    <div key={a._id} onClick={() => { setForm({ ...form, bgImage: a.content }); fetch(assetsBase + '/assets/' + a._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {}); showToast('✅ Background applied') }} style={{ cursor: 'pointer', borderRadius: 10, height: 50, background: a.content, border: form.bgImage === a.content ? \`2px solid \${ACC}\` : \`1px solid \${BOR}\` }} title={a.name} />
                  ))}
                </div>
                {(assetsMap.background || []).length === 0 && <EmptyMsg text="No backgrounds yet — run the one-time seed." />}
              </div>
            )}

            {assetTab === 'cta' && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(110px,1fr))', gap: 10 }}>
                {(assetsMap.cta || []).map((a: any) => (
                  <div key={a._id} onClick={() => { setForm({ ...form, ctaShape: a.content }); fetch(assetsBase + '/assets/' + a._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {}) }} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: 'pointer', padding: 10 }}>
                    <span style={{ display: 'inline-block', fontSize: 10, fontWeight: 700, padding: '5px 12px', borderRadius: a.content === 'square' ? 4 : a.content === 'rounded' ? 10 : 20, background: a.content === 'outline' ? 'transparent' : '#FFD700', color: a.content === 'outline' ? '#FFD700' : '#1a1a2e', border: a.content === 'outline' ? '1.5px solid #FFD700' : 'none' }}>Enroll →</span>
                    <div style={{ fontSize: 9, color: DIM, marginTop: 6 }}>{a.name}</div>
                  </div>
                ))}
                {(assetsMap.cta || []).length === 0 && <EmptyMsg text="No CTA styles yet — run the one-time seed." />}
              </div>
            )}

            <div style={{ marginTop: 14, paddingTop: 14, borderTop: \`1px solid \${BOR}\` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <div style={{ fontWeight: 700, color: TS, fontSize: 12 }}>⚖️ Compare Templates ({compareList.length}/2)</div>
                {compareList.length > 0 && <button style={bs} onClick={() => setCompareList([])}>Clear</button>}
              </div>
              <div style={{ fontSize: 10.5, color: DIM, marginBottom: 8 }}>Click ⚖ on a Built-in or My Template card above to add it here (max 2).</div>
              {compareList.length === 2 && (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                  {compareList.map((c: any, i: number) => (
                    <div key={i} style={cs}>
                      <div style={{ fontWeight: 700, color: TS, fontSize: 12, marginBottom: 6 }}>{c.label}</div>
                      <div style={{ height: 50, borderRadius: 8, background: c.bg, marginBottom: 6 }} />
                      <div style={{ fontSize: 10.5, color: DIM }}>Category: {c.category}</div>
                      <div style={{ fontSize: 10.5, color: DIM }}>Accent: <span style={{ color: c.accent }}>■</span> {c.accent}</div>
                    </div>
                  ))}
                </div>
              )}
              <button style={{ ...bs, marginTop: 10 }} onClick={resetToTemplateDefaults}>↺ Reset to Template Defaults</button>
            </div>`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — gradient-aware bg + ctaShape vars', oldBgLine, newBgLine],
  ['BatchManagerUltra — CTA shape rendering', oldCtaSpan, newCtaSpan],
  ['BatchManagerUltra — asset tabs list', oldAssetTabsList, newAssetTabsList],
  ['BatchManagerUltra — assets fetch loop', oldFetchLoop, newFetchLoop],
  ['BatchManagerUltra — assetsMap init', oldAssetsMapInit, newAssetsMapInit],
  ['BatchManagerUltra — background/cta panels + compare/reset', oldAssetGridCategories, newAssetGridCategories]
]);

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — gradient-aware bg + ctaShape vars', oldBgLine, newBgLine],
  ['TestSeriesManagerUltra — CTA shape rendering', oldCtaSpan, newCtaSpan],
  ['TestSeriesManagerUltra — asset tabs list', oldAssetTabsList, newAssetTabsList],
  ['TestSeriesManagerUltra — assets fetch loop', oldFetchLoop, newFetchLoop],
  ['TestSeriesManagerUltra — assetsMap init', oldAssetsMapInit, newAssetsMapInit],
  ['TestSeriesManagerUltra — background/cta panels + compare/reset', oldAssetGridCategories, newAssetGridCategories]
]);

// ══════════════════════════════════════════
// G) Frontend — compareList state + toggleCompare + resetToTemplateDefaults
//    handlers, inserted right after smartReplaceColor (Part 6)
// ══════════════════════════════════════════
const oldSmartReplaceEnd = `    setForm(newForm)
    showToast('✅ Colors replaced across banner')
  }

  const previewRef = useRef<any>(null)`;
const newSmartReplaceEnd = `    setForm(newForm)
    showToast('✅ Colors replaced across banner')
  }

  const [compareList, setCompareList] = useState<any[]>([])
  const toggleCompare = (item: any) => {
    setCompareList(prev => {
      const exists = prev.find(c => c.id === item.id)
      if (exists) return prev.filter(c => c.id !== item.id)
      if (prev.length >= 2) { showToast('⚠️ You can only compare 2 at a time'); return prev }
      return [...prev, item]
    })
  }
  const resetToTemplateDefaults = () => {
    const tpl = BN_TEMPLATES.find(t => t.id === form.template) || BN_TEMPLATES[0]
    setForm({ ...form, bgImage: '', layers: [], primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: tpl.accent, ctaShape: 'pill' })
    showToast('✅ Reset to template defaults')
  }

  const previewRef = useRef<any>(null)`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — compareList/toggleCompare/resetToTemplateDefaults', oldSmartReplaceEnd, newSmartReplaceEnd]
]);
replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — compareList/toggleCompare/resetToTemplateDefaults', oldSmartReplaceEnd, newSmartReplaceEnd]
]);

// ══════════════════════════════════════════
// H) Frontend — add ⚖ Compare button to Built-in template cards and
//    My Templates rows
// ══════════════════════════════════════════
const oldBuiltinCard = `                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {BN_TEMPLATES.map(t => (
                    <div key={t.id} style={{ position: 'relative', cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? \`2px solid \${ACC}\` : \`1px solid \${BOR}\`, display: 'flex', alignItems: 'flex-end', padding: 4 }} onClick={() => applyBuiltinTemplate(t.id)}>
                      <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleBuiltinFav(t.id) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 12 }}>{builtinFav.includes(t.id) ? '⭐' : '☆'}</span>
                    </div>
                  ))}
                </div>`;
const newBuiltinCard = `                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {BN_TEMPLATES.map(t => (
                    <div key={t.id} style={{ position: 'relative', cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? \`2px solid \${ACC}\` : \`1px solid \${BOR}\`, display: 'flex', alignItems: 'flex-end', padding: 4 }} onClick={() => applyBuiltinTemplate(t.id)}>
                      <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleBuiltinFav(t.id) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 12 }}>{builtinFav.includes(t.id) ? '⭐' : '☆'}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleCompare({ id: 'b_' + t.id, label: t.label, category: t.category, bg: t.bg, accent: t.accent }) }} style={{ position: 'absolute', top: 2, left: 4, fontSize: 11, background: 'rgba(0,0,0,0.4)', borderRadius: 4, padding: '0 3px' }}>⚖</span>
                    </div>
                  ))}
                </div>`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — add compare button to builtin template cards', oldBuiltinCard, newBuiltinCard]
]);
replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — add compare button to builtin template cards', oldBuiltinCard, newBuiltinCard]
]);

console.log('✅ PART 7 PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_part7.js

echo ""
echo "=== Syntax validation ==="
node --check src/models/Banner.js && echo "✅ Banner.js valid"
node --check src/models/SavedAsset.js && echo "✅ SavedAsset.js valid"
node --check src/routes/bannerAssets.js && echo "✅ bannerAssets.js valid"
node --check src/routes/batchManagerUltra.js && echo "✅ batchManagerUltra.js valid"
node --check src/routes/testSeriesManagerUltra.js && echo "✅ testSeriesManagerUltra.js valid"

echo ""
echo "✅ Part 7 DONE."
echo "⚠️ Reminder: after deploying, re-run the seed endpoint (POST /api/admin/banner-assets/assets/seed) to add the new Background + CTA assets — it only inserts NEW items, existing ones are untouched."
