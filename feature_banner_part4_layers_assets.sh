#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 4: Layers foundation + Brand Kit / Org
# Templates / Asset Library consumption in the Banner tab.
#
# DESIGN CHOICE (safety-first): layers are plain data on the Banner
# document (banner.layers array) and are saved through the SAME
# existing PUT /:id/banner call used by Save Draft / Save & Mark
# Ready — no new per-layer API routes needed. All drag/resize/rotate/
# flip/shadow/border/blend interactions (Part 5) just edit local
# React state; the existing Save button persists everything at once.
# This avoids a proliferation of granular endpoints and keeps the
# already-deployed Part 1 routes untouched except one small whitelist
# addition.
#
# BACKEND CHANGES:
#   • src/models/Banner.js — add `layers` array + `textStyleOverride`
#   • batchManagerUltra.js / testSeriesManagerUltra.js — add 'layers'
#     and 'textStyleOverride' to the existing PUT /:id/banner
#     editable-fields whitelist (one-line addition, both files)
#
# FRONTEND CHANGES (both BatchManagerUltra.tsx / TestSeriesManagerUltra.tsx):
#   • BannerLivePreview now renders banner.layers visually (position,
#     scale, rotation, opacity, flip, shadow, border, blend mode) —
#     foundation Part 5 will make interactive
#   • New sub-tabs inside "Templates & Assets": Built-in (with
#     favorite ⭐ + Recently Used, tracked in localStorage since these
#     are static designs, not DB rows) · My Templates (org-saved,
#     fully DB-backed via Part 3's bannerAssets API — search/filter/
#     favorite/clone/export/delete) · Brand Kit (view + edit shared
#     org brand kit, one-click "Apply to This Banner") · Stickers ·
#     Decorative · Subject Graphics · Icons · Typography (all fetched
#     from the global asset library, click-to-add as a layer)
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

BANNER_MODEL="src/models/Banner.js"
B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$BANNER_MODEL" "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_part4.js << 'NODEEOF'
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
// A) src/models/Banner.js — add layers + textStyleOverride
// ══════════════════════════════════════════
replaceExact('src/models/Banner.js', [
[
'Banner.js — add layers array + textStyleOverride field',
`  fieldLocks: [{ type: String }],
}, { timestamps: true });`,
`  fieldLocks: [{ type: String }],

  // ── FPR4: layered assets (stickers/decorative/subject graphics/
  // icons/illustrations placed on the banner) — plain data, edited
  // client-side, persisted via the normal banner save. ──
  layers: [{
    id: { type: String, required: true },
    type: { type: String, enum: ['sticker', 'decorative', 'subject_graphic', 'icon', 'illustration', 'logo', 'watermark'], required: true },
    content: { type: String, default: '' },
    assetId: { type: mongoose.Schema.Types.ObjectId, ref: 'SavedAsset', default: null },
    x: { type: Number, default: 50 },
    y: { type: Number, default: 50 },
    scale: { type: Number, default: 1 },
    rotation: { type: Number, default: 0 },
    opacity: { type: Number, default: 1 },
    zIndex: { type: Number, default: 1 },
    locked: { type: Boolean, default: false },
    flipH: { type: Boolean, default: false },
    flipV: { type: Boolean, default: false },
    shadow: { type: Boolean, default: false },
    shadowColor: { type: String, default: '#000000' },
    border: { type: Boolean, default: false },
    borderColor: { type: String, default: '#FFFFFF' },
    borderWidth: { type: Number, default: 2 },
    blendMode: { type: String, default: 'normal' }
  }],
  textStyleOverride: { type: mongoose.Schema.Types.Mixed, default: null },
}, { timestamps: true });`
]
]);

// ══════════════════════════════════════════
// B) batchManagerUltra.js — whitelist layers/textStyleOverride
// ══════════════════════════════════════════
replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — add layers to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`
]
]);

// ══════════════════════════════════════════
// C) testSeriesManagerUltra.js — whitelist layers/textStyleOverride
// ══════════════════════════════════════════
replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — add layers to editable whitelist',
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage'];`,
`const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];`
]
]);

// ══════════════════════════════════════════
// D) BannerLivePreview — render layers (both tsx files, same patch)
// ══════════════════════════════════════════
const oldPreviewFnHead = `function BannerLivePreview({ b, size, showSafeZone }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  const bg = b.bgImage ? \`url(\${b.bgImage}) center/cover\` : (tpl.bg)
  const badgeObj = BN_BADGES.find(x => x.id === b.badge)
  return (
    <div style={{ width: d.w, height: d.h, maxWidth: '100%', borderRadius: 14, position: 'relative', overflow: 'hidden', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find(f => f.id === b.fontStyle) || BN_FONTS[0]).family, border: \`1px solid \${BOR}\`, padding: 16, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', margin: '0 auto' }}>
      {showSafeZone && <div style={{ position: 'absolute', inset: '8%', border: '1px dashed rgba(255,255,255,0.4)', borderRadius: 8, pointerEvents: 'none' }} />}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>`;

const newPreviewFnHead = `function BannerLivePreview({ b, size, showSafeZone, safeZoneMode, onLayerPointerDown, selectedLayerId, boxRef }: any) {
  const dims: any = { card: { w: 320, h: 200 }, wide: { w: 480, h: 200 }, square: { w: 320, h: 320 }, mobile: { w: 280, h: 420 } }
  const d = dims[size] || dims.card
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  const bg = b.bgImage ? \`url(\${b.bgImage}) center/cover\` : (tpl.bg)
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>`;

// ══════════════════════════════════════════
// E) New state + effects + handlers inserted right after existing
//    state declarations (both files, same code)
// ══════════════════════════════════════════
const oldStateBlock = `  const [templateCat, setTemplateCat] = useState('All')
  const [templateSearch, setTemplateSearch] = useState('')
  const [downloading, setDownloading] = useState(false)`;

const newStateBlock = `  const [templateCat, setTemplateCat] = useState('All')
  const [templateSearch, setTemplateSearch] = useState('')
  const [downloading, setDownloading] = useState(false)
  const [assetTab, setAssetTab] = useState('builtin')
  const [assetSearch, setAssetSearch] = useState('')
  const [brandKit, setBrandKit] = useState<any>(null)
  const [orgTemplates, setOrgTemplates] = useState<any[]>([])
  const [assetsMap, setAssetsMap] = useState<any>({ sticker: [], decorative: [], subject_graphic: [], icon: [], typography: [] })
  const [builtinFav, setBuiltinFav] = useState<string[]>(() => { try { return JSON.parse(localStorage.getItem('pr_banner_builtin_fav') || '[]') } catch { return [] } })
  const [builtinRecent, setBuiltinRecent] = useState<string[]>(() => { try { return JSON.parse(localStorage.getItem('pr_banner_builtin_recent') || '[]') } catch { return [] } })
  const assetsBase = base.replace('/api/admin/batch-manager', '/api/admin/banner-assets').replace('/api/admin/test-series-manager', '/api/admin/banner-assets')

  const loadOrgTemplates = useCallback(() => {
    const p = new URLSearchParams()
    if (assetSearch) p.set('search', assetSearch)
    fetch(assetsBase + '/templates?' + p.toString(), { headers: authHeaders }).then(r => r.json()).then(d => setOrgTemplates(d.templates || [])).catch(() => {})
  }, [assetSearch])
  useEffect(() => { fetch(assetsBase + '/brand-kit', { headers: authHeaders }).then(r => r.json()).then(d => setBrandKit(d.brandKit)).catch(() => {}) }, [])
  useEffect(() => { loadOrgTemplates() }, [loadOrgTemplates])
  useEffect(() => {
    ['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].forEach(t => {
      fetch(assetsBase + '/assets?type=' + t, { headers: authHeaders }).then(r => r.json()).then(d => setAssetsMap((m: any) => ({ ...m, [t]: d.assets || [] }))).catch(() => {})
    })
  }, [])

  const toggleBuiltinFav = (tid: string) => {
    setBuiltinFav(prev => { const next = prev.includes(tid) ? prev.filter(x => x !== tid) : [...prev, tid]; try { localStorage.setItem('pr_banner_builtin_fav', JSON.stringify(next)) } catch { }; return next })
  }
  const applyBuiltinTemplate = (tid: string) => {
    setForm({ ...form, template: tid })
    setBuiltinRecent(prev => { const next = [tid, ...prev.filter(x => x !== tid)].slice(0, 10); try { localStorage.setItem('pr_banner_builtin_recent', JSON.stringify(next)) } catch { }; return next })
  }
  const applyBrandKitToBanner = () => {
    if (!brandKit) return
    setForm({ ...form, primaryColor: brandKit.primaryColor, secondaryColor: brandKit.secondaryColor, accentColor: brandKit.accentColor, fontStyle: brandKit.fontPair })
    showToast('✅ Brand Kit applied to this banner')
  }
  const saveBrandKitField = async (patch: any) => {
    const r = await fetch(assetsBase + '/brand-kit', { method: 'PUT', headers: authHeaders, body: JSON.stringify(patch) })
    const d = await r.json()
    if (d.success) { setBrandKit(d.brandKit); showToast('✅ Brand Kit saved') } else showToast('⚠️ ' + d.error)
  }
  const saveAsOrgTemplate = async () => {
    const name = window.prompt('Template name?')
    if (!name || !name.trim()) return
    const config = { template: form.template, primaryColor: form.primaryColor, secondaryColor: form.secondaryColor, textColor: form.textColor, accentColor: form.accentColor, fontStyle: form.fontStyle, bgImage: form.bgImage, layers: form.layers || [] }
    const r = await fetch(assetsBase + '/templates', { method: 'POST', headers: authHeaders, body: JSON.stringify({ name: name.trim(), category: 'Custom', config }) })
    const d = await r.json()
    if (d.success) { showToast('✅ Saved as template'); loadOrgTemplates() } else showToast('⚠️ ' + d.error)
  }
  const applyOrgTemplate = async (t: any) => {
    setForm({ ...form, ...t.config })
    await fetch(assetsBase + '/templates/' + t._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    loadOrgTemplates()
  }
  const toggleOrgTemplateFav = async (t: any) => { await fetch(assetsBase + '/templates/' + t._id, { method: 'PUT', headers: authHeaders, body: JSON.stringify({ isFavorite: !t.isFavorite }) }); loadOrgTemplates() }
  const cloneOrgTemplate = async (t: any) => { await fetch(assetsBase + '/templates/' + t._id + '/clone', { method: 'POST', headers: authHeaders }); showToast('✅ Cloned'); loadOrgTemplates() }
  const deleteOrgTemplate = async (t: any) => { if (!window.confirm('Delete template "' + t.name + '"?')) return; await fetch(assetsBase + '/templates/' + t._id, { method: 'DELETE', headers: authHeaders }); showToast('✅ Deleted'); loadOrgTemplates() }
  const exportOrgTemplate = async (t: any) => {
    const r = await fetch(assetsBase + '/templates/' + t._id + '/export', { headers: authHeaders })
    const d = await r.json()
    const blob = new Blob([JSON.stringify(d.exportData, null, 2)], { type: 'application/json' })
    const link = document.createElement('a'); link.href = URL.createObjectURL(blob); link.download = t.name + '.json'; link.click()
  }
  const addAssetLayer = (asset: any) => {
    const layer = { id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), type: asset.type, content: asset.content, assetId: asset._id, x: 50, y: 50, scale: 1, rotation: 0, opacity: 1, zIndex: ((form.layers || []).length) + 1, locked: false, flipH: false, flipV: false, shadow: false, shadowColor: '#000000', border: false, borderColor: '#FFFFFF', borderWidth: 2, blendMode: 'normal' }
    setForm({ ...form, layers: [...(form.layers || []), layer] })
    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }`;

// ══════════════════════════════════════════
// F) New JSX panels inserted between Templates&Assets and Analytics
// ══════════════════════════════════════════
const oldAnalyticsAnchor = `          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>`;

const newAssetPanelsBlock = `          <div style={cs}>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
              {[['builtin', '🖼️ Built-in'], ['mytemplates', '📁 My Templates'], ['brandkit', '🎨 Brand Kit'], ['sticker', '🏷️ Stickers'], ['decorative', '✨ Decorative'], ['subject_graphic', '🧬 Subject Graphics'], ['icon', '🔣 Icons'], ['typography', '🔤 Typography']].map(([k, l]) => (
                <button key={k} style={assetTab === k ? bp : bs} onClick={() => setAssetTab(k)}>{l}</button>
              ))}
            </div>

            {assetTab === 'builtin' && (
              <div>
                {builtinRecent.length > 0 && (
                  <div style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 11, color: DIM, marginBottom: 4 }}>Recently Used</div>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      {builtinRecent.map(tid => { const t = BN_TEMPLATES.find(x => x.id === tid); return t ? <button key={tid} style={bs} onClick={() => applyBuiltinTemplate(tid)}>{t.label}</button> : null })}
                    </div>
                  </div>
                )}
                <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>All Templates</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(90px,1fr))', gap: 8 }}>
                  {BN_TEMPLATES.map(t => (
                    <div key={t.id} style={{ position: 'relative', cursor: 'pointer', borderRadius: 10, height: 54, background: t.bg, border: form.template === t.id ? \`2px solid \${ACC}\` : \`1px solid \${BOR}\`, display: 'flex', alignItems: 'flex-end', padding: 4 }} onClick={() => applyBuiltinTemplate(t.id)}>
                      <span style={{ fontSize: 8.5, color: '#fff', fontWeight: 700, textShadow: '0 1px 2px rgba(0,0,0,0.6)' }}>{t.label}</span>
                      <span onClick={(e) => { e.stopPropagation(); toggleBuiltinFav(t.id) }} style={{ position: 'absolute', top: 2, right: 4, fontSize: 12 }}>{builtinFav.includes(t.id) ? '⭐' : '☆'}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {assetTab === 'mytemplates' && (
              <div>
                <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
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
                ))}
              </div>
            )}

            {assetTab === 'brandkit' && brandKit && (
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
            )}

            {['sticker', 'decorative', 'subject_graphic', 'icon', 'typography'].includes(assetTab) && (
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
          </div>

          <div style={cs}>
            <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Analytics</div>`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — BannerLivePreview layers rendering', oldPreviewFnHead, newPreviewFnHead],
  ['BatchManagerUltra — new state/effects/handlers', oldStateBlock, newStateBlock],
  ['BatchManagerUltra — new Brand Kit/Templates/Assets panels', oldAnalyticsAnchor, newAssetPanelsBlock]
]);

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — BannerLivePreview layers rendering', oldPreviewFnHead, newPreviewFnHead],
  ['TestSeriesManagerUltra — new state/effects/handlers', oldStateBlock, newStateBlock],
  ['TestSeriesManagerUltra — new Brand Kit/Templates/Assets panels', oldAnalyticsAnchor, newAssetPanelsBlock]
]);

console.log('✅ PART 4 PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_part4.js

echo ""
echo "=== Syntax validation ==="
node --check src/models/Banner.js && echo "✅ Banner.js valid"
node --check src/routes/batchManagerUltra.js && echo "✅ batchManagerUltra.js valid"
node --check src/routes/testSeriesManagerUltra.js && echo "✅ testSeriesManagerUltra.js valid"

echo ""
echo "✅ Part 4 DONE."
