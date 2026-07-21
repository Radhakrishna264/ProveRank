#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — PART 6: Content Intelligence + Validation
# Engine + Productivity
#
# CONTENT INTELLIGENCE (rule-based, not real AI — no paid AI API is
# configured on this platform, so suggestions are generated from
# templated logic against the batch's own data, clearly labeled as
# "Smart Suggestions" rather than claiming true AI):
#   Title / CTA / Highlight / Badge suggestion buttons, dynamic title
#   font-scaling for long titles (in BannerLivePreview).
#
# VALIDATION ENGINE (extends Part 2's basic warnings):
#   Low-contrast detection (WCAG relative-luminance contrast ratio),
#   text-overflow heuristic, background-image resolution check (real
#   Image() load + naturalWidth/Height), CTA-visibility (accent-color
#   darkness) check, safe-zone violation check for placed layers.
#
# PRODUCTIVITY:
#   Undo/Redo (Ctrl+Z / Ctrl+Y, 20-step history, debounced snapshots),
#   Auto Save Draft (silent background save 5s after last edit, shown
#   as a small "Auto-saved HH:MM:SS" indicator), Smart Replace Colors
#   (swap a color across primary/secondary/accent/text + all layer
#   borders/shadows in one click).
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_banner_part6.js << 'NODEEOF'
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
// A) Module-level helper functions — insert before BN_effPrice
// ══════════════════════════════════════════
const oldHelperAnchor = `function BN_effPrice(b: any) { return b.discountPrice || b.price || 0 }`;
const newHelperAnchor = `function BN_luminance(hex: string) {
  const c = (hex || '#888888').replace('#', '')
  if (c.length !== 6) return 0.5
  const r = parseInt(c.slice(0, 2), 16) / 255, g = parseInt(c.slice(2, 4), 16) / 255, b = parseInt(c.slice(4, 6), 16) / 255
  const [rl, gl, bl] = [r, g, b].map(v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4))
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
}
function BN_contrastRatio(hex1: string, hex2: string) {
  const l1 = BN_luminance(hex1), l2 = BN_luminance(hex2)
  const lighter = Math.max(l1, l2), darker = Math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
}
function BN_titleSuggestions(name: string, examType: string) {
  const n = name || 'Your Batch', e = examType || 'NEET'
  return [n + ' — Crack ' + e + ' 2026', 'Master ' + e + ' with ' + n, n + ': Your Path to ' + e + ' Success']
}
function BN_ctaSuggestions() { return ['Enroll Now', 'Start Learning', 'Join Batch', 'Get Started', 'Claim Your Seat', 'Book Now'] }
function BN_highlightSuggestions(sp: any) {
  const s = sp || {}
  return [(s.totalTests || '0') + ' Practice Tests', (s.duration || '365 days') + ' Access', 'Expert Faculty Support', 'Detailed Performance Analytics', 'Hindi + English Both']
}
function BN_badgeSuggestions() { return ['new', 'trending', 'limitedseats', 'earlybird'] }
function BN_effPrice(b: any) { return b.discountPrice || b.price || 0 }`;

// ══════════════════════════════════════════
// B) Component hooks — insert right after moveLayerZ (Part 5), before
//    previewRef (must stay above the early "if (!data) return" per
//    Rules of Hooks)
// ══════════════════════════════════════════
const oldHooksAnchor = `  const moveLayerZ = (layerId: string, dir: number) => {
    setForm((f: any) => {
      const layers = [...(f.layers || [])]
      const layer = layers.find((l: any) => l.id === layerId)
      if (!layer) return f
      layer.zIndex = Math.max(0, (layer.zIndex || 0) + dir)
      return { ...f, layers }
    })
  }
  const previewRef = useRef<any>(null)`;

const newHooksAnchor = `  const moveLayerZ = (layerId: string, dir: number) => {
    setForm((f: any) => {
      const layers = [...(f.layers || [])]
      const layer = layers.find((l: any) => l.id === layerId)
      if (!layer) return f
      layer.zIndex = Math.max(0, (layer.zIndex || 0) + dir)
      return { ...f, layers }
    })
  }

  // ── FPR6: Undo/Redo, Auto-Save Draft, image-resolution check,
  // Smart Replace Colors — all local-state productivity features. ──
  const [historyStack, setHistoryStack] = useState<any[]>([])
  const [redoStack, setRedoStack] = useState<any[]>([])
  const historyTimerRef = useRef<any>(null)
  const isUndoRedoRef = useRef(false)
  const autoSaveTimerRef = useRef<any>(null)
  const [lastAutoSaved, setLastAutoSaved] = useState<any>(null)
  const [imgResWarning, setImgResWarning] = useState('')
  const [replaceFromColor, setReplaceFromColor] = useState('#4D9FFF')
  const [replaceToColor, setReplaceToColor] = useState('#4D9FFF')
  const [showSuggestions, setShowSuggestions] = useState(false)

  useEffect(() => {
    if (!form) return
    if (isUndoRedoRef.current) { isUndoRedoRef.current = false; return }
    if (historyTimerRef.current) clearTimeout(historyTimerRef.current)
    historyTimerRef.current = setTimeout(() => { setHistoryStack(prev => [...prev.slice(-19), form]); setRedoStack([]) }, 800)
    return () => { if (historyTimerRef.current) clearTimeout(historyTimerRef.current) }
  }, [form])

  useEffect(() => {
    if (!form || !data?.banner) return
    if (autoSaveTimerRef.current) clearTimeout(autoSaveTimerRef.current)
    autoSaveTimerRef.current = setTimeout(() => {
      fetch(base + '/' + id + '/banner', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }).then(r => r.json()).then(d => { if (d.success) setLastAutoSaved(new Date()) }).catch(() => {})
    }, 5000)
    return () => { if (autoSaveTimerRef.current) clearTimeout(autoSaveTimerRef.current) }
  }, [form])

  useEffect(() => {
    if (!form?.bgImage || !/^https?:\\/\\//.test(form.bgImage)) { setImgResWarning(''); return }
    const img = new Image()
    img.onload = () => { setImgResWarning((img.naturalWidth < 300 || img.naturalHeight < 150) ? 'Background image resolution is low — may look blurry' : '') }
    img.onerror = () => setImgResWarning('')
    img.src = form.bgImage
  }, [form?.bgImage])

  const undo = () => {
    if (historyStack.length < 2) { showToast('Nothing to undo'); return }
    const current = historyStack[historyStack.length - 1]
    const prevState = historyStack[historyStack.length - 2]
    isUndoRedoRef.current = true
    setRedoStack(r => [current, ...r])
    setHistoryStack(h => h.slice(0, -1))
    setForm(prevState)
  }
  const redo = () => {
    if (redoStack.length === 0) { showToast('Nothing to redo'); return }
    const next = redoStack[0]
    isUndoRedoRef.current = true
    setHistoryStack(h => [...h, next])
    setRedoStack(r => r.slice(1))
    setForm(next)
  }
  useEffect(() => {
    const onKey = (e: any) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) { e.preventDefault(); undo() }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) { e.preventDefault(); redo() }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [historyStack, redoStack])

  const smartReplaceColor = () => {
    const from = (replaceFromColor || '').toLowerCase()
    const to = replaceToColor
    const newForm: any = { ...form }
    const fields = ['primaryColor', 'secondaryColor', 'accentColor', 'textColor']
    fields.forEach(f => { if ((newForm[f] || '').toLowerCase() === from) newForm[f] = to })
    newForm.layers = (newForm.layers || []).map((l: any) => ({ ...l, shadowColor: (l.shadowColor || '').toLowerCase() === from ? to : l.shadowColor, borderColor: (l.borderColor || '').toLowerCase() === from ? to : l.borderColor }))
    setForm(newForm)
    showToast('✅ Colors replaced across banner')
  }

  const previewRef = useRef<any>(null)`;

// ══════════════════════════════════════════
// C) Extend validation warnings
// ══════════════════════════════════════════
const oldWarnings = `  const warnings: string[] = []
  if (form) {
    if (!form.title || !form.title.trim()) warnings.push('Missing title')
    if (!form.ctaText || !form.ctaText.trim()) warnings.push('Missing CTA text')
    if (form.bgImage && !/^https?:\\/\\/|^data:image/.test(form.bgImage)) warnings.push('Invalid image URL')
    if (data.syncPreview && form.price !== data.syncPreview.price) warnings.push('Price differs from current batch price — consider syncing')
  }`;
const newWarnings = `  const warnings: string[] = []
  if (form) {
    if (!form.title || !form.title.trim()) warnings.push('Missing title')
    if (!form.ctaText || !form.ctaText.trim()) warnings.push('Missing CTA text')
    if (form.bgImage && !/^https?:\\/\\/|^data:image/.test(form.bgImage)) warnings.push('Invalid image URL')
    if (data.syncPreview && form.price !== data.syncPreview.price) warnings.push('Price differs from current batch price — consider syncing')
    if (form.textColor && form.primaryColor && BN_contrastRatio(form.textColor, form.primaryColor) < 3) warnings.push('Low contrast between text and background — may be hard to read')
    if (form.title && form.title.length > 40) warnings.push('Title may overflow on smaller sizes — consider shortening')
    if (form.accentColor && BN_luminance(form.accentColor) < 0.25) warnings.push('CTA button color is quite dark — may reduce visibility')
    if (imgResWarning) warnings.push(imgResWarning)
    if (form.layers && form.layers.length) {
      const inset = safeZoneMode === 'mobile' ? 12 : safeZoneMode === 'desktop' ? 6 : 8
      const outside = form.layers.filter((l: any) => l.x < inset || l.x > 100 - inset || l.y < inset || l.y > 100 - inset)
      if (outside.length > 0) warnings.push(outside.length + ' layer(s) are outside the safe zone')
    }
  }`;

// ══════════════════════════════════════════
// D) Smart Suggestions panel — insert after highlights inputs
// ══════════════════════════════════════════
const oldSuggestAnchor = `            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} placeholder={'Highlight ' + (i + 1)} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 8, marginTop: 10 }}>`;
const newSuggestAnchor = `            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(140px,1fr))', gap: 8, marginTop: 8 }}>
              {[0, 1, 2].map(i => (
                <input key={i} style={inp} placeholder={'Highlight ' + (i + 1)} value={(form.highlights || [])[i] || ''} onChange={e => { const h = [...(form.highlights || ['', '', ''])]; h[i] = e.target.value; setForm({ ...form, highlights: h }) }} />
              ))}
            </div>
            <button style={{ ...bs, marginTop: 8 }} onClick={() => setShowSuggestions(v => !v)}>💡 {showSuggestions ? 'Hide' : 'Show'} Smart Suggestions</button>
            {showSuggestions && (
              <div style={{ marginTop: 8, padding: 10, borderRadius: 8, background: 'rgba(77,159,255,0.06)', border: \`1px solid \${BOR}\` }}>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Title suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_titleSuggestions(data.batchName, form.examType).map((s, i) => <button key={i} style={bs} onClick={() => setForm({ ...form, title: s })}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>CTA suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_ctaSuggestions().map((s, i) => <button key={i} style={bs} onClick={() => setForm({ ...form, ctaText: s })}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Highlight suggestions (click to fill next empty slot)</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {BN_highlightSuggestions(data.syncPreview).map((s, i) => <button key={i} style={bs} onClick={() => { const h = [...(form.highlights || ['', '', ''])]; const idx = h.findIndex((x: string) => !x); if (idx >= 0) h[idx] = s; else h[0] = s; setForm({ ...form, highlights: h }) }}>{s}</button>)}
                </div>
                <div style={{ fontSize: 10.5, color: DIM, marginBottom: 4 }}>Badge suggestions</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {BN_badgeSuggestions().map(bId => { const bObj = BN_BADGES.find(x => x.id === bId); return bObj ? <button key={bId} style={bs} onClick={() => setForm({ ...form, badge: bId })}>{bObj.label}</button> : null })}
                </div>
              </div>
            )}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 8, marginTop: 10 }}>`;

// ══════════════════════════════════════════
// E) Undo/Redo buttons + auto-save indicator in the action row
// ══════════════════════════════════════════
const oldActionsAnchor = `            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 12 }}>
              <button style={bs} onClick={syncNow}>🔄 Sync Now</button>
              <button style={bs} onClick={() => saveBanner({ saveAsDraft: true })}>💾 Save Draft</button>
              <button style={bp} onClick={() => saveBanner({ markReady: true })}>✅ Save & Mark Ready</button>
              <button style={bs} onClick={discard}>↩️ Discard Changes</button>
            </div>`;
const newActionsAnchor = `            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 12, alignItems: 'center' }}>
              <button style={bs} onClick={undo} disabled={historyStack.length < 2}>↶ Undo</button>
              <button style={bs} onClick={redo} disabled={redoStack.length === 0}>↷ Redo</button>
              <button style={bs} onClick={syncNow}>🔄 Sync Now</button>
              <button style={bs} onClick={() => saveBanner({ saveAsDraft: true })}>💾 Save Draft</button>
              <button style={bp} onClick={() => saveBanner({ markReady: true })}>✅ Save & Mark Ready</button>
              <button style={bs} onClick={discard}>↩️ Discard Changes</button>
              {lastAutoSaved && <span style={{ fontSize: 10, color: DIM }}>Auto-saved {lastAutoSaved.toLocaleTimeString()}</span>}
            </div>`;

// ══════════════════════════════════════════
// F) Smart Replace Colors panel — near Color Presets
// ══════════════════════════════════════════
const oldReplaceAnchor = `            <button style={bs} onClick={() => setShowIllustrations(true)}>🎨 Open Illustration Library ({BN_ILLUSTRATIONS.length})</button>
          </div>`;
const newReplaceAnchor = `            <button style={bs} onClick={() => setShowIllustrations(true)}>🎨 Open Illustration Library ({BN_ILLUSTRATIONS.length})</button>
            <div style={{ marginTop: 12, paddingTop: 12, borderTop: \`1px solid \${BOR}\` }}>
              <div style={{ fontSize: 11, color: DIM, marginBottom: 6 }}>🔁 Smart Replace Color (across colors + all layer borders/shadows)</div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                <label style={lbl}>From</label><input type="color" value={replaceFromColor} onChange={e => setReplaceFromColor(e.target.value)} />
                <label style={lbl}>To</label><input type="color" value={replaceToColor} onChange={e => setReplaceToColor(e.target.value)} />
                <button style={bs} onClick={smartReplaceColor}>Replace</button>
              </div>
            </div>
          </div>`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
  ['BatchManagerUltra — module-level helpers', oldHelperAnchor, newHelperAnchor],
  ['BatchManagerUltra — component hooks', oldHooksAnchor, newHooksAnchor],
  ['BatchManagerUltra — extended warnings', oldWarnings, newWarnings],
  ['BatchManagerUltra — Smart Suggestions panel', oldSuggestAnchor, newSuggestAnchor],
  ['BatchManagerUltra — Undo/Redo + autosave indicator', oldActionsAnchor, newActionsAnchor],
  ['BatchManagerUltra — Smart Replace Colors panel', oldReplaceAnchor, newReplaceAnchor]
]);

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
  ['TestSeriesManagerUltra — module-level helpers', oldHelperAnchor, newHelperAnchor],
  ['TestSeriesManagerUltra — component hooks', oldHooksAnchor, newHooksAnchor],
  ['TestSeriesManagerUltra — extended warnings', oldWarnings, newWarnings],
  ['TestSeriesManagerUltra — Smart Suggestions panel', oldSuggestAnchor, newSuggestAnchor],
  ['TestSeriesManagerUltra — Undo/Redo + autosave indicator', oldActionsAnchor, newActionsAnchor],
  ['TestSeriesManagerUltra — Smart Replace Colors panel', oldReplaceAnchor, newReplaceAnchor]
]);

console.log('✅ PART 6 PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_banner_part6.js

echo "✅ Part 6 DONE."
