#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 5: Interactive Layer Manipulation
#
# Adds real drag-and-drop positioning (plain React pointer events —
# no external library), a Layers panel (reorder/duplicate/delete/
# select), and a Layer Controls panel (scale, rotation, opacity,
# lock, flip H/V, shadow + color, border + color/width, blend mode)
# to the "Preview & Variants" section. Also adds Mobile/Desktop Safe
# Zone variants and an Auto Safe-Zone Snap toggle that keeps dragged
# layers inside the safe margin automatically.
#
# All of this edits banner.layers in local state only — persists via
# the SAME Save Draft / Save & Mark Ready buttons already built in
# Part 1/2 (layers + textStyleOverride were whitelisted in Part 4).
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_part5.js << 'NODEEOF'
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
// New layer-interaction state + handlers, inserted right after
// addAssetLayer() (end of Part 4's handler block)
// ══════════════════════════════════════════
const oldAnchor1 = `    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }`;

const newAnchor1 = `    fetch(assetsBase + '/assets/' + asset._id + '/use', { method: 'POST', headers: authHeaders }).catch(() => {})
    showToast('✅ Added to banner — drag it into position in Preview & Variants')
  }

  // ── FPR5: interactive layer manipulation (drag/resize/rotate/flip/
  // shadow/border/blend/reorder) — plain React pointer events, no
  // external drag library. Edits form.layers locally; persisted via
  // the existing Save Draft / Save & Mark Ready buttons. ──
  const [selectedLayerId, setSelectedLayerId] = useState('')
  const [draggingLayerId, setDraggingLayerId] = useState('')
  const [safeZoneMode, setSafeZoneMode] = useState('default')
  const [autoSnapSafeZone, setAutoSnapSafeZone] = useState(false)

  const onLayerPointerDown = (e: any, layerId: string) => {
    const layer = (form.layers || []).find((l: any) => l.id === layerId)
    if (!layer || layer.locked) return
    setSelectedLayerId(layerId)
    setDraggingLayerId(layerId)
    e.stopPropagation()
  }
  useEffect(() => {
    if (!draggingLayerId) return
    const onMove = (e: any) => {
      const box = previewRef.current
      if (!box) return
      const rect = box.getBoundingClientRect()
      const clientX = e.touches ? e.touches[0].clientX : e.clientX
      const clientY = e.touches ? e.touches[0].clientY : e.clientY
      let x = ((clientX - rect.left) / rect.width) * 100
      let y = ((clientY - rect.top) / rect.height) * 100
      x = Math.max(0, Math.min(100, x))
      y = Math.max(0, Math.min(100, y))
      if (autoSnapSafeZone) {
        const inset = safeZoneMode === 'mobile' ? 12 : safeZoneMode === 'desktop' ? 6 : 8
        x = Math.max(inset, Math.min(100 - inset, x))
        y = Math.max(inset, Math.min(100 - inset, y))
      }
      setForm((f: any) => ({ ...f, layers: (f.layers || []).map((l: any) => l.id === draggingLayerId ? { ...l, x, y } : l) }))
    }
    const onUp = () => setDraggingLayerId('')
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    window.addEventListener('touchmove', onMove)
    window.addEventListener('touchend', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
      window.removeEventListener('touchmove', onMove)
      window.removeEventListener('touchend', onUp)
    }
  }, [draggingLayerId, autoSnapSafeZone, safeZoneMode])
  const updateLayer = (layerId: string, patch: any) => setForm((f: any) => ({ ...f, layers: (f.layers || []).map((l: any) => l.id === layerId ? { ...l, ...patch } : l) }))
  const removeLayer = (layerId: string) => { setForm((f: any) => ({ ...f, layers: (f.layers || []).filter((l: any) => l.id !== layerId) })); if (selectedLayerId === layerId) setSelectedLayerId('') }
  const duplicateLayer = (layerId: string) => {
    const layer = (form.layers || []).find((l: any) => l.id === layerId)
    if (!layer) return
    const clone = { ...layer, id: 'ly_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8), x: Math.min(95, layer.x + 5), y: Math.min(95, layer.y + 5), zIndex: (form.layers || []).length + 1 }
    setForm((f: any) => ({ ...f, layers: [...(f.layers || []), clone] }))
  }
  const moveLayerZ = (layerId: string, dir: number) => {
    setForm((f: any) => {
      const layers = [...(f.layers || [])]
      const layer = layers.find((l: any) => l.id === layerId)
      if (!layer) return f
      layer.zIndex = Math.max(0, (layer.zIndex || 0) + dir)
      return { ...f, layers }
    })
  }`;

// ══════════════════════════════════════════
// Preview & Variants JSX — add safe-zone mode selector, wire up
// interactivity on the main preview, and add Layers + Layer Controls
// panels right after the PNG download button.
// ══════════════════════════════════════════
const oldAnchor2 = `              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM, marginLeft: 8 }}>
                <input type="checkbox" checked={showSafeZone} onChange={e => setShowSafeZone(e.target.checked)} /> Safe Zone Guide
              </label>
              <button style={{ ...bs, marginLeft: 'auto' }} onClick={() => setShowAllVariants(v => !v)}>{showAllVariants ? 'Hide All Variants' : 'Generate All Variants'}</button>
            </div>
            <div ref={previewRef}><BannerLivePreview b={form} size={previewSize} showSafeZone={showSafeZone} /></div>
            <div style={{ marginTop: 10 }}><button style={bs} disabled={downloading} onClick={() => downloadPNG(previewRef, previewSize)}>{downloading ? '⟳ Exporting…' : '⬇️ Download PNG (' + previewSize + ')'}</button></div>

            {showAllVariants && (`;

const newAnchor2 = `              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM, marginLeft: 8 }}>
                <input type="checkbox" checked={showSafeZone} onChange={e => setShowSafeZone(e.target.checked)} /> Safe Zone Guide
              </label>
              <select style={{ ...inp, width: 'auto' }} value={safeZoneMode} onChange={e => setSafeZoneMode(e.target.value)}>
                <option value="default">Default Safe Zone</option>
                <option value="mobile">Mobile Safe Zone</option>
                <option value="desktop">Desktop Safe Zone</option>
              </select>
              <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: DIM }}>
                <input type="checkbox" checked={autoSnapSafeZone} onChange={e => setAutoSnapSafeZone(e.target.checked)} /> Auto Safe-Zone Snap
              </label>
              <button style={{ ...bs, marginLeft: 'auto' }} onClick={() => setShowAllVariants(v => !v)}>{showAllVariants ? 'Hide All Variants' : 'Generate All Variants'}</button>
            </div>
            <BannerLivePreview b={form} size={previewSize} showSafeZone={showSafeZone} safeZoneMode={safeZoneMode} boxRef={previewRef} onLayerPointerDown={onLayerPointerDown} selectedLayerId={selectedLayerId} />
            <div style={{ marginTop: 10 }}><button style={bs} disabled={downloading} onClick={() => downloadPNG(previewRef, previewSize)}>{downloading ? '⟳ Exporting…' : '⬇️ Download PNG (' + previewSize + ')'}</button></div>

            {form.layers && form.layers.length > 0 && (
              <div style={{ marginTop: 14, paddingTop: 14, borderTop: \`1px solid \${BOR}\` }}>
                <div style={{ fontWeight: 700, marginBottom: 8, color: TS, fontSize: 12 }}>🗂️ Layers ({form.layers.length})</div>
                {form.layers.slice().sort((a: any, b: any) => b.zIndex - a.zIndex).map((l: any) => (
                  <div key={l.id} onClick={() => setSelectedLayerId(l.id)} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 8px', borderRadius: 6, cursor: 'pointer', background: selectedLayerId === l.id ? 'rgba(77,159,255,0.12)' : 'transparent', fontSize: 11, color: DIM }}>
                    <span>{l.locked ? '🔒 ' : ''}{l.type}</span>
                    <span style={{ display: 'flex', gap: 4 }}>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); moveLayerZ(l.id, 1) }}>⬆️</button>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); moveLayerZ(l.id, -1) }}>⬇️</button>
                      <button style={{ ...bs, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); duplicateLayer(l.id) }}>⧉</button>
                      <button style={{ ...bd, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); removeLayer(l.id) }}>🗑️</button>
                    </span>
                  </div>
                ))}
              </div>
            )}

            {selectedLayerId && (form.layers || []).find((l: any) => l.id === selectedLayerId) && (() => {
              const layer = (form.layers || []).find((l: any) => l.id === selectedLayerId)
              return (
                <div style={{ marginTop: 14, paddingTop: 14, borderTop: \`1px solid \${BOR}\` }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ fontWeight: 700, color: TS, fontSize: 12 }}>🔧 Layer Controls — {layer.type}</div>
                    <button style={bs} onClick={() => setSelectedLayerId('')}>✕ Close</button>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 10 }}>
                    <div><label style={lbl}>Scale ({layer.scale.toFixed(2)}x)</label><input type="range" min="0.3" max="3" step="0.05" value={layer.scale} onChange={e => updateLayer(layer.id, { scale: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                    <div><label style={lbl}>Rotation ({layer.rotation}°)</label><input type="range" min="-180" max="180" value={layer.rotation} onChange={e => updateLayer(layer.id, { rotation: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                    <div><label style={lbl}>Opacity ({Math.round(layer.opacity * 100)}%)</label><input type="range" min="0" max="1" step="0.05" value={layer.opacity} onChange={e => updateLayer(layer.id, { opacity: Number(e.target.value) })} style={{ width: '100%' }} /></div>
                  </div>
                  <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '10px 0' }}>
                    <Toggle on={!!layer.locked} onChange={(v: boolean) => updateLayer(layer.id, { locked: v })} label="Lock" />
                    <Toggle on={!!layer.flipH} onChange={(v: boolean) => updateLayer(layer.id, { flipH: v })} label="Flip H" />
                    <Toggle on={!!layer.flipV} onChange={(v: boolean) => updateLayer(layer.id, { flipV: v })} label="Flip V" />
                    <Toggle on={!!layer.shadow} onChange={(v: boolean) => updateLayer(layer.id, { shadow: v })} label="Shadow" />
                    <Toggle on={!!layer.border} onChange={(v: boolean) => updateLayer(layer.id, { border: v })} label="Border" />
                  </div>
                  {layer.shadow && (
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 8 }}>
                      <label style={lbl}>Shadow Color</label><input type="color" value={layer.shadowColor} onChange={e => updateLayer(layer.id, { shadowColor: e.target.value })} />
                    </div>
                  )}
                  {layer.border && (
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 8 }}>
                      <label style={lbl}>Border Color</label><input type="color" value={layer.borderColor} onChange={e => updateLayer(layer.id, { borderColor: e.target.value })} />
                      <label style={lbl}>Width</label><input type="number" style={{ ...inp, width: 60 }} value={layer.borderWidth} onChange={e => updateLayer(layer.id, { borderWidth: Number(e.target.value) })} />
                    </div>
                  )}
                  <div><label style={lbl}>Blend Mode</label>
                    <select style={inp} value={layer.blendMode} onChange={e => updateLayer(layer.id, { blendMode: e.target.value })}>
                      {['normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge', 'difference'].map(m => <option key={m} value={m}>{m}</option>)}
                    </select>
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                    <button style={bs} onClick={() => duplicateLayer(layer.id)}>⧉ Duplicate</button>
                    <button style={bd} onClick={() => removeLayer(layer.id)}>🗑️ Delete</button>
                  </div>
                </div>
              )
            })()}

            {showAllVariants && (`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — layer interaction state/handlers', oldAnchor1, newAnchor1],
  ['BatchManagerUltra — Layers + Layer Controls panels', oldAnchor2, newAnchor2]
]);

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — layer interaction state/handlers', oldAnchor1, newAnchor1],
  ['TestSeriesManagerUltra — Layers + Layer Controls panels', oldAnchor2, newAnchor2]
]);

console.log('✅ PART 5 PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_part5.js

echo "✅ Part 5 DONE."
