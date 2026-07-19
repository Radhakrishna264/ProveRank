#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# PRICING TAB SIMPLIFICATION (Batch + TestSeries Detail Pages)
#
# REMOVED (backend + frontend + schema): Bundle Price, Early Bird
# Price, Limited Time Price, Coupon Code, Free Trial toggle, Flash
# Sale (price + end time).
#
# ADDED: Discount Valid Till date — after this date, effectivePrice()
# automatically falls back to Base Price everywhere (admin + pricing
# calc), so discount stops applying without any manual action.
#
# CHANGED: "Save Pricing" CTA -> "Save & Lock Price". On save, price
# fields lock immediately (priceLocked=true). While locked, Base
# Price / Discount Price / Discount Valid Till are all read-only.
# Only a manual "Unlock" button (admin-only) re-enables editing.
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_MODEL="src/models/Batch.js"
S_MODEL="src/models/TestSeries.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"

for f in "$B_ROUTE" "$S_ROUTE" "$B_MODEL" "$S_MODEL" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

cat > /tmp/fix_pricing_tab.js << 'ENDOFFILE'
const fs = require('fs');

function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error(`❌ [${path}] anchor not found: ${label}`);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

// ══════════════════════════════════════════
// 1) src/models/Batch.js
// ══════════════════════════════════════════
replaceExact('src/models/Batch.js', [
[
'Batch — add discountValidTill after discountPrice',
`  discountPrice:{type:Number,default:0},`,
`  discountPrice:{type:Number,default:0},
  discountValidTill:{type:Date},`
],
[
'Batch — remove flashSale/allowFreeTrial/trialDays fields',
`  flashSaleEndTime:{type:Date},
  flashSalePrice:{type:Number},
  allowFreeTrial:{type:Boolean,default:false},
  trialDays:{type:Number,default:3},
`,
``
],
[
'Batch — remove couponCode/earlyBirdPrice/limitedTimePrice fields',
`  couponCode:{type:String,default:''},
  earlyBirdPrice:{type:Number},
  limitedTimePrice:{type:Number},
`,
``
]
]);

// ══════════════════════════════════════════
// 2) src/models/TestSeries.js
// ══════════════════════════════════════════
replaceExact('src/models/TestSeries.js', [
[
'TestSeries — add discountValidTill after discountPrice',
`  discountPrice: { type: Number, default: 0 },`,
`  discountPrice: { type: Number, default: 0 },
  discountValidTill: { type: Date },`
],
[
'TestSeries — remove flashSale/allowFreeTrial/trialDays fields',
`  flashSaleEndTime: { type: Date },
  flashSalePrice: { type: Number },
  allowFreeTrial: { type: Boolean, default: false },
  trialDays: { type: Number, default: 3 },
`,
``
],
[
'TestSeries — remove couponCode/earlyBirdPrice/limitedTimePrice fields',
`  couponCode: { type: String, default: '' },
  earlyBirdPrice: { type: Number },
  limitedTimePrice: { type: Number },
`,
``
]
]);

// ══════════════════════════════════════════
// 3) src/routes/batchManagerUltra.js
// ══════════════════════════════════════════
replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — effectivePrice() simplified',
`function effectivePrice(b) {
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  if (b.limitedTimePrice) return b.limitedTimePrice;
  if (b.earlyBirdPrice) return b.earlyBirdPrice;
  return b.discountPrice || b.price || 0;
}`,
`function effectivePrice(b) {
  if (b.discountPrice && (!b.discountValidTill || new Date(b.discountValidTill) >= new Date())) return b.discountPrice;
  return b.price || 0;
}`
],
[
'batchManagerUltra — GET /:id/pricing response simplified',
`    res.json({
      pricing: {
        basePrice: batch.price || 0,
        discountPrice: batch.discountPrice || null,
        bundlePrice: batch.bundlePrice || null,
        earlyBirdPrice: batch.earlyBirdPrice || null,
        limitedTimePrice: batch.limitedTimePrice || null,
        flashSalePrice: batch.flashSalePrice || null,
        flashSaleEndTime: batch.flashSaleEndTime || null,
        couponCode: batch.couponCode || '',
        allowFreeTrial: !!batch.allowFreeTrial,
        trialDays: batch.trialDays || 0,
        priceLocked: !!batch.priceLocked,
        effectivePrice: effectivePrice(batch)
      },
      history: batch.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(batch) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (batch.isSpotlight || batch.isBundle || batch.allowFreeTrial) ? 'High' : 'Moderate'
      }
    });`,
`    res.json({
      pricing: {
        basePrice: batch.price || 0,
        discountPrice: batch.discountPrice || null,
        discountValidTill: batch.discountValidTill || null,
        priceLocked: !!batch.priceLocked,
        effectivePrice: effectivePrice(batch)
      },
      history: batch.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(batch) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (batch.isSpotlight || batch.isBundle) ? 'High' : 'Moderate'
      }
    });`
],
[
'batchManagerUltra — PUT /:id/pricing simplified',
`    const fields = ['price', 'discountPrice', 'bundlePrice', 'earlyBirdPrice', 'limitedTimePrice', 'couponCode', 'allowFreeTrial', 'trialDays'];
    batch.priceHistory = batch.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(batch[f]) !== String(req.body[f])) {
        batch.priceHistory.push({ oldPrice: batch[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        batch[f] = req.body[f];
      }
    }
    if (req.body.flashSalePrice !== undefined) {
      batch.flashSalePrice = req.body.flashSalePrice;
      batch.flashSaleEndTime = req.body.flashSaleEndTime ? new Date(req.body.flashSaleEndTime) : batch.flashSaleEndTime;
    }`,
`    const fields = ['price', 'discountPrice'];
    batch.priceHistory = batch.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(batch[f]) !== String(req.body[f])) {
        batch.priceHistory.push({ oldPrice: batch[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        batch[f] = req.body[f];
      }
    }
    if (req.body.discountValidTill !== undefined) {
      batch.discountValidTill = req.body.discountValidTill ? new Date(req.body.discountValidTill) : null;
    }`
]
]);

// ══════════════════════════════════════════
// 4) src/routes/testSeriesManagerUltra.js
// ══════════════════════════════════════════
replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — effectivePrice() simplified',
`function effectivePrice(b) {
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  if (b.limitedTimePrice) return b.limitedTimePrice;
  if (b.earlyBirdPrice) return b.earlyBirdPrice;
  return b.discountPrice || b.price || 0;
}`,
`function effectivePrice(b) {
  if (b.discountPrice && (!b.discountValidTill || new Date(b.discountValidTill) >= new Date())) return b.discountPrice;
  return b.price || 0;
}`
],
[
'testSeriesManagerUltra — GET /:id/pricing response simplified',
`    res.json({
      pricing: {
        basePrice: series.price || 0,
        discountPrice: series.discountPrice || null,
        bundlePrice: series.bundlePrice || null,
        earlyBirdPrice: series.earlyBirdPrice || null,
        limitedTimePrice: series.limitedTimePrice || null,
        flashSalePrice: series.flashSalePrice || null,
        flashSaleEndTime: series.flashSaleEndTime || null,
        couponCode: series.couponCode || '',
        allowFreeTrial: !!series.allowFreeTrial,
        trialDays: series.trialDays || 0,
        priceLocked: !!series.priceLocked,
        effectivePrice: effectivePrice(series)
      },
      history: series.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(series) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (series.isSpotlight || series.isBundle || series.allowFreeTrial) ? 'High' : 'Moderate'
      }
    });`,
`    res.json({
      pricing: {
        basePrice: series.price || 0,
        discountPrice: series.discountPrice || null,
        discountValidTill: series.discountValidTill || null,
        priceLocked: !!series.priceLocked,
        effectivePrice: effectivePrice(series)
      },
      history: series.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(series) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (series.isSpotlight || series.isBundle) ? 'High' : 'Moderate'
      }
    });`
],
[
'testSeriesManagerUltra — PUT /:id/pricing simplified',
`    const fields = ['price', 'discountPrice', 'bundlePrice', 'earlyBirdPrice', 'limitedTimePrice', 'couponCode', 'allowFreeTrial', 'trialDays'];
    series.priceHistory = series.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(series[f]) !== String(req.body[f])) {
        series.priceHistory.push({ oldPrice: series[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        series[f] = req.body[f];
      }
    }
    if (req.body.flashSalePrice !== undefined) {
      series.flashSalePrice = req.body.flashSalePrice;
      series.flashSaleEndTime = req.body.flashSaleEndTime ? new Date(req.body.flashSaleEndTime) : series.flashSaleEndTime;
    }`,
`    const fields = ['price', 'discountPrice'];
    series.priceHistory = series.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(series[f]) !== String(req.body[f])) {
        series.priceHistory.push({ oldPrice: series[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        series[f] = req.body[f];
      }
    }
    if (req.body.discountValidTill !== undefined) {
      series.discountValidTill = req.body.discountValidTill ? new Date(req.body.discountValidTill) : null;
    }`
]
]);

// ══════════════════════════════════════════
// 5) frontend BatchManagerUltra.tsx — PricingTab
// ══════════════════════════════════════════
replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
[
'BatchManagerUltra — PricingTab full replace',
`  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>`,
`  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const saveAndLock = async () => {
    const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ price: form.basePrice, discountPrice: form.discountPrice, discountValidTill: form.discountValidTill }) })
    const d = await r.json()
    if (d.success) {
      if (!p.priceLocked) await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders })
      showToast('✅ Price saved & locked')
      load()
    } else showToast('⚠️ ' + d.error)
  }
  const unlock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); showToast('🔓 Price unlocked'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        {p.priceLocked && <button style={bs} onClick={unlock}>Unlock</button>}
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Valid Till</label><input style={inp} type="date" disabled={p.priceLocked} value={form.discountValidTill ? String(form.discountValidTill).slice(0, 10) : ''} onChange={e => setForm({ ...form, discountValidTill: e.target.value })} /></div>
      </div>
      <button style={bp} onClick={saveAndLock} disabled={p.priceLocked}>🔒 Save & Lock Price</button>`
]
]);

// ══════════════════════════════════════════
// 6) frontend TestSeriesManagerUltra.tsx — PricingTab
// ══════════════════════════════════════════
replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
[
'TestSeriesManagerUltra — PricingTab full replace',
`  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const save = async () => { const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify(form) }); const d = await r.json(); if (d.success) { showToast('✅ Pricing updated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleLock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        <button style={bs} onClick={toggleLock}>{p.priceLocked ? 'Unlock' : 'Lock'} Price</button>
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Bundle Price ₹</label><input style={inp} type="number" value={form.bundlePrice || ''} onChange={e => setForm({ ...form, bundlePrice: e.target.value })} /></div>
        <div><label style={lbl}>Early Bird Price ₹</label><input style={inp} type="number" value={form.earlyBirdPrice || ''} onChange={e => setForm({ ...form, earlyBirdPrice: e.target.value })} /></div>
        <div><label style={lbl}>Limited Time Price ₹</label><input style={inp} type="number" value={form.limitedTimePrice || ''} onChange={e => setForm({ ...form, limitedTimePrice: e.target.value })} /></div>
        <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.couponCode || ''} onChange={e => setForm({ ...form, couponCode: e.target.value })} /></div>
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '4px 0 14px' }}>
        <Toggle on={!!form.allowFreeTrial} onChange={v => setForm({ ...form, allowFreeTrial: v })} label="Free Trial" />
      </div>
      <button style={bp} onClick={save}>💾 Save Pricing</button>`,
`  if (!data || !form) return <EmptyMsg text="⟳ Loading pricing…" />
  const p = data.pricing
  const saveAndLock = async () => {
    const r = await fetch(base + '/' + id + '/pricing', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ price: form.basePrice, discountPrice: form.discountPrice, discountValidTill: form.discountValidTill }) })
    const d = await r.json()
    if (d.success) {
      if (!p.priceLocked) await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders })
      showToast('✅ Price saved & locked')
      load()
    } else showToast('⚠️ ' + d.error)
  }
  const unlock = async () => { await fetch(base + '/' + id + '/pricing/lock', { method: 'PUT', headers: authHeaders }); showToast('🔓 Price unlocked'); load() }

  return (
    <div>
      <div style={{ ...cs, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, color: TS }}>{p.priceLocked ? '🔒 Price Locked' : '🔓 Price Unlocked'}</span>
        {p.priceLocked && <button style={bs} onClick={unlock}>Unlock</button>}
      </div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Base Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.basePrice} onChange={e => setForm({ ...form, price: e.target.value, basePrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Price ₹</label><input style={inp} type="number" disabled={p.priceLocked} value={form.discountPrice || ''} onChange={e => setForm({ ...form, discountPrice: e.target.value })} /></div>
        <div><label style={lbl}>Discount Valid Till</label><input style={inp} type="date" disabled={p.priceLocked} value={form.discountValidTill ? String(form.discountValidTill).slice(0, 10) : ''} onChange={e => setForm({ ...form, discountValidTill: e.target.value })} /></div>
      </div>
      <button style={bp} onClick={saveAndLock} disabled={p.priceLocked}>🔒 Save & Lock Price</button>`
]
]);

console.log('\n✅ ALL 6 FILES PATCHED SUCCESSFULLY');
ENDOFFILE

node /tmp/fix_pricing_tab.js

echo ""
echo "=== Verifying removal ==="
grep -n "bundlePrice\|earlyBirdPrice\|limitedTimePrice\|couponCode\|allowFreeTrial\|trialDays\|flashSalePrice\|flashSaleEndTime" "$B_ROUTE" "$S_ROUTE" "$B_MODEL" "$S_MODEL" "$B_TSX" "$S_TSX" && echo "⚠️ Some references still remain — check above" || echo "✅ Clean — no references left"

echo ""
echo "=== Verifying discountValidTill added ==="
grep -n "discountValidTill" "$B_ROUTE" "$S_ROUTE" "$B_MODEL" "$S_MODEL" "$B_TSX" "$S_TSX"

echo ""
echo "✅ DONE. Git push karke Render + Vercel pe deploy karo."
