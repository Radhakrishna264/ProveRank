#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# NEW FEATURE: Coupon Management Tab (Batch + TestSeries Detail Page)
#
# Adds a brand-new tab "🎟️ Coupons" right after "💰 Pricing" on both
# the Batch Detail page and the Test Series Detail page.
#
# Scope: coupons are ALWAYS scoped to a single batch or single test
# series (via scopeType + scopeId on the Coupon model). There is NO
# global coupon manager — everything lives inside this tab only.
#
# Backend adds per batch/series:
#   GET    /:id/coupons                       list + KPIs (filter/sort)
#   POST   /:id/coupons                       create
#   PUT    /:id/coupons/:couponId             edit
#   PUT    /:id/coupons/:couponId/status      draft/active/disabled
#   POST   /:id/coupons/:couponId/duplicate   duplicate
#   DELETE /:id/coupons/:couponId             soft delete
#   GET    /:id/coupons/:couponId/usage       usage history + summary
#   GET    /:id/coupons/:couponId/analytics   per-coupon analytics
#   GET    /:id/coupons/analytics             scope-wide analytics
#   POST   /:id/coupons/validate              student: check before checkout
#   POST   /:id/coupons/redeem                student: record redemption
#
# Status is DERIVED at read-time from validFrom/validTill (scheduled/
# active/expired), not persisted via cron — cron is unreliable on
# Render's free-tier spin-down, so this is more robust. Only draft/
# active/disabled are ever stored; scheduled/expired are computed.
#
# Frontend adds a full CouponManagementTab in both admin detail pages:
# KPI strip, filter chips, sort, create/edit form (percent/flat,
# max discount, usage limits, per-student limits, validity window,
# visibility, auto-apply-best), coupon list with edit/duplicate/
# enable-disable/delete/view-usage/view-analytics, and a scope-wide
# analytics summary block (best/worst performing, expiring soon,
# revenue loss).
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"
COUPON_MODEL="src/models/Coupon.js"

for f in "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done
if [ -f "$COUPON_MODEL" ]; then cp "$COUPON_MODEL" "${COUPON_MODEL}.bak_$(date +%s)"; fi

# ══════════════════════════════════════════════════════════════════
# 1) NEW MODEL: src/models/Coupon.js
# ══════════════════════════════════════════════════════════════════
cat > "$COUPON_MODEL" << 'MODELEOF'
// ══════════════════════════════════════════════════════════════════
// Coupon — scoped ONLY to a single Batch or single TestSeries via
// scopeType + scopeId. No global coupon manager. Uniqueness of `code`
// is enforced within (scopeType, scopeId) only, among non-deleted docs.
// ══════════════════════════════════════════════════════════════════
const mongoose = require('mongoose');

const CouponSchema = new mongoose.Schema({
  code: { type: String, required: true, uppercase: true, trim: true },
  scopeType: { type: String, required: true, enum: ['batch', 'series'] },
  scopeId: { type: mongoose.Schema.Types.ObjectId, required: true },

  type: { type: String, required: true, enum: ['percent', 'flat'], default: 'percent' },
  value: { type: Number, required: true, min: 0 },
  maxDiscount: { type: Number, default: null },

  usageLimit: { type: Number, required: true, min: 1, default: 100 },
  perStudentLimitType: { type: String, enum: ['once', 'unlimited', 'custom'], default: 'once' },
  perStudentLimitCustom: { type: Number, default: 1 },

  validFrom: { type: Date, required: true },
  validTill: { type: Date, required: true },

  description: { type: String, default: '' },
  // NOTE: 'scheduled' and 'expired' are DERIVED at read-time from
  // validFrom/validTill (see getEffectiveCouponStatus in the route
  // files) — not persisted, to avoid relying on cron (unreliable on
  // Render free-tier spin-down). Only these 3 states are ever stored:
  status: { type: String, enum: ['draft', 'active', 'disabled'], default: 'draft' },
  visibility: { type: String, enum: ['public', 'hidden'], default: 'public' },
  autoApplyBest: { type: Boolean, default: false },
  applicablePlan: { type: String, enum: ['entire', 'base_price'], default: 'entire' },

  usageCount: { type: Number, default: 0 },
  uniqueStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  revenueGenerated: { type: Number, default: 0 },
  discountGiven: { type: Number, default: 0 },
  firstUsedAt: { type: Date, default: null },
  lastUsedAt: { type: Date, default: null },
  usageHistory: [{
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    studentName: String,
    appliedAmount: Number,
    discountAmount: Number,
    timestamp: { type: Date, default: Date.now },
    orderRef: String,
    status: { type: String, default: 'success' }
  }],

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: String,
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedByName: String,
  statusChangedBy: String,
  statusChangedAt: Date,

  isDeleted: { type: Boolean, default: false },
  deletedBy: String,
  deletedAt: Date,

  history: [{
    field: String,
    oldValue: mongoose.Schema.Types.Mixed,
    newValue: mongoose.Schema.Types.Mixed,
    action: String,
    performedBy: String,
    performedByName: String,
    timestamp: { type: Date, default: Date.now }
  }]
}, { timestamps: true });

CouponSchema.index({ scopeType: 1, scopeId: 1, code: 1 }, { unique: true, partialFilterExpression: { isDeleted: false } });

module.exports = mongoose.models.Coupon || mongoose.model('Coupon', CouponSchema);
MODELEOF
echo "✅ Created $COUPON_MODEL"

# ══════════════════════════════════════════════════════════════════
# 2) Node.js precise-patch for the 4 existing files (backend routes +
#    frontend tabs). Using exact string replacement (H3 pattern), not
#    sed, since these are route files / large tsx files.
# ══════════════════════════════════════════════════════════════════
cat > /tmp/fix_coupon_tab.js << 'NODEEOF'
const fs = require('fs');

function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error(`❌ [${path}] anchor not found: ${label}`);
      process.exit(1);
    }
    if (src.split(oldStr).length - 1 > 1 && !label.includes('(non-unique, first-only)')) {
      console.error(`⚠️  [${path}] anchor "${label}" appears more than once — proceeding with first occurrence via .replace (safe since it's an insertion, not a structural rewrite over ambiguous text). Verify output.`);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

// ══════════════════════════════════════════
// A) src/routes/batchManagerUltra.js
// ══════════════════════════════════════════
const batchCouponRoutes = `
// ══════════════════════════════════════════════════════════════════
// COUPON MANAGEMENT TAB — batch-scoped coupons only (no global system)
// ══════════════════════════════════════════════════════════════════
function getEffectiveCouponStatus(c) {
  if (c.isDeleted) return 'deleted';
  if (c.status === 'disabled') return 'disabled';
  if (c.status === 'draft') return 'draft';
  const now = new Date();
  if (c.validFrom && new Date(c.validFrom) > now) return 'scheduled';
  if (c.validTill && new Date(c.validTill) < now) return 'expired';
  return 'active';
}
function computeCouponDiscount(c, baseAmount) {
  let discount = c.type === 'percent' ? (baseAmount * c.value / 100) : c.value;
  if (c.type === 'percent' && c.maxDiscount) discount = Math.min(discount, c.maxDiscount);
  discount = Math.min(discount, baseAmount);
  return Math.round(discount * 100) / 100;
}

router.get('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const { status, sort } = req.query;
    const all = await Coupon.find({ scopeType: 'batch', scopeId, isDeleted: false }).lean();
    const withStatus = all.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    let coupons = withStatus;
    if (status && status !== 'all') coupons = coupons.filter(c => c.effectiveStatus === status);
    if (sort === 'usage') coupons = coupons.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    else if (sort === 'discount') coupons = coupons.slice().sort((a, b) => (b.value || 0) - (a.value || 0));
    else if (sort === 'expiring') coupons = coupons.slice().sort((a, b) => new Date(a.validTill) - new Date(b.validTill));
    else if (sort === 'updated') coupons = coupons.slice().sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    else coupons = coupons.slice().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const kpis = {
      total: withStatus.length,
      active: withStatus.filter(c => c.effectiveStatus === 'active').length,
      scheduled: withStatus.filter(c => c.effectiveStatus === 'scheduled').length,
      expired: withStatus.filter(c => c.effectiveStatus === 'expired').length,
      disabled: withStatus.filter(c => c.effectiveStatus === 'disabled').length,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0),
      revenueViaCoupons: withStatus.reduce((s, c) => s + (c.revenueGenerated || 0), 0),
      conversionRate: withStatus.length ? Math.round((withStatus.filter(c => c.usageCount > 0).length / withStatus.length) * 100) : 0
    };
    res.json({ coupons, kpis });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const batch = await Batch.findById(scopeId).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const b = req.body;
    if (!b.code || !b.code.trim()) return res.status(400).json({ error: 'Coupon code required' });
    const code = b.code.trim().toUpperCase();
    if (!b.validFrom || !b.validTill) return res.status(400).json({ error: 'Valid From and Valid Till required' });
    if (new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (!b.value || Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.type === 'percent' && b.maxDiscount !== undefined && b.maxDiscount !== null && b.maxDiscount !== '' && Number(b.maxDiscount) <= 0) return res.status(400).json({ error: 'Max discount must be greater than 0' });
    if (b.usageLimit !== undefined && b.usageLimit !== '' && Number(b.usageLimit) <= 0) return res.status(400).json({ error: 'Usage limit must be greater than 0' });
    const dup = await Coupon.findOne({ scopeType: 'batch', scopeId, code, isDeleted: false });
    if (dup) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    const doc = await Coupon.create({
      code, scopeType: 'batch', scopeId,
      type: b.type === 'flat' ? 'flat' : 'percent',
      value: Number(b.value),
      maxDiscount: b.type === 'percent' && b.maxDiscount ? Number(b.maxDiscount) : null,
      usageLimit: Number(b.usageLimit) || 100,
      perStudentLimitType: ['once', 'unlimited', 'custom'].includes(b.perStudentLimitType) ? b.perStudentLimitType : 'once',
      perStudentLimitCustom: b.perStudentLimitType === 'custom' ? (Number(b.perStudentLimitCustom) || 1) : 1,
      validFrom: new Date(b.validFrom),
      validTill: new Date(b.validTill),
      description: b.description || '',
      status: (b.status === 'active' || b.status === 'disabled') ? b.status : 'draft',
      visibility: b.visibility === 'hidden' ? 'hidden' : 'public',
      autoApplyBest: !!b.autoApplyBest,
      applicablePlan: b.applicablePlan === 'base_price' ? 'base_price' : 'entire',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'created', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: code }]
    });
    await logAudit({ batchId: scopeId, field: 'coupon', action: 'coupon_created', newValue: { code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const b = req.body;
    if (b.validFrom && b.validTill && new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (b.value !== undefined && Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.code && b.code.trim().toUpperCase() !== c.code) {
      const newCode = b.code.trim().toUpperCase();
      const dup = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: newCode, isDeleted: false, _id: { $ne: c._id } });
      if (dup) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
      c.history.push({ field: 'code', oldValue: c.code, newValue: newCode, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
      c.code = newCode;
    }
    const editable = ['type', 'value', 'maxDiscount', 'usageLimit', 'perStudentLimitType', 'perStudentLimitCustom', 'validFrom', 'validTill', 'description', 'visibility', 'autoApplyBest', 'applicablePlan'];
    for (const f of editable) {
      if (b[f] !== undefined) {
        let newV = b[f];
        if (f === 'validFrom' || f === 'validTill') newV = new Date(newV);
        if (String(c[f]) !== String(newV)) {
          c.history.push({ field: f, oldValue: c[f], newValue: newV, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
          c[f] = newV;
        }
      }
    }
    c.updatedBy = req.user.id; c.updatedByName = req.user.name || 'Admin';
    await c.save();
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_updated', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: c });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId/status', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const { status } = req.body;
    if (!['draft', 'active', 'disabled'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    const old = c.status;
    c.status = status;
    c.statusChangedBy = req.user.name || 'Admin';
    c.statusChangedAt = new Date();
    c.history.push({ field: 'status', oldValue: old, newValue: status, action: 'status_changed', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ batchId: req.params.id, field: 'coupon_status', action: 'coupon_status_changed', newValue: { code: c.code, status }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, status: c.status, effectiveStatus: getEffectiveCouponStatus(c) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/:couponId/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    if (!src) return res.status(404).json({ error: 'Coupon not found' });
    let newCode = src.code + '-COPY';
    let n = 1;
    while (await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: newCode, isDeleted: false })) {
      n++; newCode = src.code + '-COPY' + n;
    }
    const { _id, createdAt, updatedAt, __v, usageCount, uniqueStudents, revenueGenerated, discountGiven, firstUsedAt, lastUsedAt, usageHistory, history, statusChangedBy, statusChangedAt, ...rest } = src;
    const doc = await Coupon.create({
      ...rest, code: newCode, status: 'draft',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'duplicated', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: newCode, oldValue: src.code }]
    });
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_duplicated', newValue: { from: src.code, to: newCode }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    c.isDeleted = true;
    c.deletedBy = req.user.name || 'Admin';
    c.deletedAt = new Date();
    c.history.push({ field: 'coupon', action: 'deleted', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_deleted', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/analytics', auth, isAdmin, async (req, res) => {
  try {
    const coupons = await Coupon.find({ scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    const withStatus = coupons.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    const sorted = withStatus.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    const best = sorted[0] || null;
    const worst = sorted.length ? sorted[sorted.length - 1] : null;
    const expiringSoon = withStatus.filter(c => {
      if (c.effectiveStatus !== 'active') return false;
      const days = Math.ceil((new Date(c.validTill) - new Date()) / 86400000);
      return days <= 7 && days >= 0;
    });
    const totalRevenueLoss = withStatus.reduce((s, c) => s + (c.discountGiven || 0), 0);
    res.json({
      bestPerforming: best ? { code: best.code, usageCount: best.usageCount, revenueGenerated: best.revenueGenerated } : null,
      lowestPerforming: worst ? { code: worst.code, usageCount: worst.usageCount, revenueGenerated: worst.revenueGenerated } : null,
      expiringSoon: expiringSoon.map(c => ({ code: c.code, validTill: c.validTill })),
      totalRevenueLoss,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0)
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/usage', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    res.json({
      usage: (c.usageHistory || []).slice().reverse(),
      summary: {
        totalUses: c.usageCount || 0,
        uniqueStudents: (c.uniqueStudents || []).length,
        firstUsedAt: c.firstUsedAt || null,
        lastUsedAt: c.lastUsedAt || null,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/analytics', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const batch = await Batch.findById(req.params.id).lean();
    const enrolledCount = (batch && batch.enrolledCount) || 0;
    const conversionRate = enrolledCount > 0 ? Math.min(100, Math.round(((c.usageCount || 0) / enrolledCount) * 100)) : 0;
    const now = new Date();
    const daysToExpiry = c.validTill ? Math.ceil((new Date(c.validTill) - now) / 86400000) : null;
    const trend = {};
    (c.usageHistory || []).forEach(u => {
      const day = new Date(u.timestamp).toISOString().slice(0, 10);
      trend[day] = (trend[day] || 0) + 1;
    });
    res.json({
      analytics: {
        uses: c.usageCount || 0,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0,
        conversionRate,
        daysToExpiry,
        isExpiringSoon: daysToExpiry !== null && daysToExpiry <= 7 && daysToExpiry >= 0,
        usageTrend: Object.entries(trend).map(([date, count]) => ({ date, count })).sort((a, b) => a.date.localeCompare(b.date))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/validate', auth, async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'Coupon code required' });
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const c = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: code.trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: \`Coupon is \${eff}\` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'You have already used this coupon the maximum number of times' });
    }
    const base = batch.price || 0;
    const discount = computeCouponDiscount(c, base);
    res.json({ valid: true, code: c.code, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/redeem', auth, async (req, res) => {
  try {
    const { code, appliedAmount, orderRef } = req.body;
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const c = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: (code || '').trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: \`Coupon is \${eff}\` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'Coupon usage limit reached for this student' });
    }
    const base = Number(appliedAmount) || batch.price || 0;
    const discount = computeCouponDiscount(c, base);
    c.usageCount += 1;
    if (!c.uniqueStudents.some(s => String(s) === String(req.user.id))) c.uniqueStudents.push(req.user.id);
    c.revenueGenerated += Math.max(0, base - discount);
    c.discountGiven += discount;
    if (!c.firstUsedAt) c.firstUsedAt = new Date();
    c.lastUsedAt = new Date();
    c.usageHistory.push({ student: req.user.id, studentName: req.user.name || 'Student', appliedAmount: base, discountAmount: discount, orderRef: orderRef || '', status: 'success' });
    await c.save();
    res.json({ success: true, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`;

replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — import Coupon model',
`const User     = require('../models/User');`,
`const User     = require('../models/User');
const Coupon   = require('../models/Coupon');`
],
[
'batchManagerUltra — insert coupon routes before CONTROLS TAB',
`
// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`,
batchCouponRoutes + `// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`
]
]);

// ══════════════════════════════════════════
// B) src/routes/testSeriesManagerUltra.js
// ══════════════════════════════════════════
const seriesCouponRoutes = `
// ══════════════════════════════════════════════════════════════════
// COUPON MANAGEMENT TAB — series-scoped coupons only (no global system)
// ══════════════════════════════════════════════════════════════════
function getEffectiveCouponStatus(c) {
  if (c.isDeleted) return 'deleted';
  if (c.status === 'disabled') return 'disabled';
  if (c.status === 'draft') return 'draft';
  const now = new Date();
  if (c.validFrom && new Date(c.validFrom) > now) return 'scheduled';
  if (c.validTill && new Date(c.validTill) < now) return 'expired';
  return 'active';
}
function computeCouponDiscount(c, baseAmount) {
  let discount = c.type === 'percent' ? (baseAmount * c.value / 100) : c.value;
  if (c.type === 'percent' && c.maxDiscount) discount = Math.min(discount, c.maxDiscount);
  discount = Math.min(discount, baseAmount);
  return Math.round(discount * 100) / 100;
}

router.get('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const { status, sort } = req.query;
    const all = await Coupon.find({ scopeType: 'series', scopeId, isDeleted: false }).lean();
    const withStatus = all.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    let coupons = withStatus;
    if (status && status !== 'all') coupons = coupons.filter(c => c.effectiveStatus === status);
    if (sort === 'usage') coupons = coupons.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    else if (sort === 'discount') coupons = coupons.slice().sort((a, b) => (b.value || 0) - (a.value || 0));
    else if (sort === 'expiring') coupons = coupons.slice().sort((a, b) => new Date(a.validTill) - new Date(b.validTill));
    else if (sort === 'updated') coupons = coupons.slice().sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    else coupons = coupons.slice().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const kpis = {
      total: withStatus.length,
      active: withStatus.filter(c => c.effectiveStatus === 'active').length,
      scheduled: withStatus.filter(c => c.effectiveStatus === 'scheduled').length,
      expired: withStatus.filter(c => c.effectiveStatus === 'expired').length,
      disabled: withStatus.filter(c => c.effectiveStatus === 'disabled').length,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0),
      revenueViaCoupons: withStatus.reduce((s, c) => s + (c.revenueGenerated || 0), 0),
      conversionRate: withStatus.length ? Math.round((withStatus.filter(c => c.usageCount > 0).length / withStatus.length) * 100) : 0
    };
    res.json({ coupons, kpis });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const series = await TestSeries.findById(scopeId).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const b = req.body;
    if (!b.code || !b.code.trim()) return res.status(400).json({ error: 'Coupon code required' });
    const code = b.code.trim().toUpperCase();
    if (!b.validFrom || !b.validTill) return res.status(400).json({ error: 'Valid From and Valid Till required' });
    if (new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (!b.value || Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.type === 'percent' && b.maxDiscount !== undefined && b.maxDiscount !== null && b.maxDiscount !== '' && Number(b.maxDiscount) <= 0) return res.status(400).json({ error: 'Max discount must be greater than 0' });
    if (b.usageLimit !== undefined && b.usageLimit !== '' && Number(b.usageLimit) <= 0) return res.status(400).json({ error: 'Usage limit must be greater than 0' });
    const dup = await Coupon.findOne({ scopeType: 'series', scopeId, code, isDeleted: false });
    if (dup) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    const doc = await Coupon.create({
      code, scopeType: 'series', scopeId,
      type: b.type === 'flat' ? 'flat' : 'percent',
      value: Number(b.value),
      maxDiscount: b.type === 'percent' && b.maxDiscount ? Number(b.maxDiscount) : null,
      usageLimit: Number(b.usageLimit) || 100,
      perStudentLimitType: ['once', 'unlimited', 'custom'].includes(b.perStudentLimitType) ? b.perStudentLimitType : 'once',
      perStudentLimitCustom: b.perStudentLimitType === 'custom' ? (Number(b.perStudentLimitCustom) || 1) : 1,
      validFrom: new Date(b.validFrom),
      validTill: new Date(b.validTill),
      description: b.description || '',
      status: (b.status === 'active' || b.status === 'disabled') ? b.status : 'draft',
      visibility: b.visibility === 'hidden' ? 'hidden' : 'public',
      autoApplyBest: !!b.autoApplyBest,
      applicablePlan: b.applicablePlan === 'base_price' ? 'base_price' : 'entire',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'created', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: code }]
    });
    await logAudit({ seriesId: scopeId, field: 'coupon', action: 'coupon_created', newValue: { code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const b = req.body;
    if (b.validFrom && b.validTill && new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (b.value !== undefined && Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.code && b.code.trim().toUpperCase() !== c.code) {
      const newCode = b.code.trim().toUpperCase();
      const dup = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: newCode, isDeleted: false, _id: { $ne: c._id } });
      if (dup) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
      c.history.push({ field: 'code', oldValue: c.code, newValue: newCode, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
      c.code = newCode;
    }
    const editable = ['type', 'value', 'maxDiscount', 'usageLimit', 'perStudentLimitType', 'perStudentLimitCustom', 'validFrom', 'validTill', 'description', 'visibility', 'autoApplyBest', 'applicablePlan'];
    for (const f of editable) {
      if (b[f] !== undefined) {
        let newV = b[f];
        if (f === 'validFrom' || f === 'validTill') newV = new Date(newV);
        if (String(c[f]) !== String(newV)) {
          c.history.push({ field: f, oldValue: c[f], newValue: newV, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
          c[f] = newV;
        }
      }
    }
    c.updatedBy = req.user.id; c.updatedByName = req.user.name || 'Admin';
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_updated', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: c });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId/status', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const { status } = req.body;
    if (!['draft', 'active', 'disabled'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    const old = c.status;
    c.status = status;
    c.statusChangedBy = req.user.name || 'Admin';
    c.statusChangedAt = new Date();
    c.history.push({ field: 'status', oldValue: old, newValue: status, action: 'status_changed', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon_status', action: 'coupon_status_changed', newValue: { code: c.code, status }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, status: c.status, effectiveStatus: getEffectiveCouponStatus(c) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/:couponId/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!src) return res.status(404).json({ error: 'Coupon not found' });
    let newCode = src.code + '-COPY';
    let n = 1;
    while (await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: newCode, isDeleted: false })) {
      n++; newCode = src.code + '-COPY' + n;
    }
    const { _id, createdAt, updatedAt, __v, usageCount, uniqueStudents, revenueGenerated, discountGiven, firstUsedAt, lastUsedAt, usageHistory, history, statusChangedBy, statusChangedAt, ...rest } = src;
    const doc = await Coupon.create({
      ...rest, code: newCode, status: 'draft',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'duplicated', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: newCode, oldValue: src.code }]
    });
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_duplicated', newValue: { from: src.code, to: newCode }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    c.isDeleted = true;
    c.deletedBy = req.user.name || 'Admin';
    c.deletedAt = new Date();
    c.history.push({ field: 'coupon', action: 'deleted', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_deleted', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/analytics', auth, isAdmin, async (req, res) => {
  try {
    const coupons = await Coupon.find({ scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    const withStatus = coupons.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    const sorted = withStatus.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    const best = sorted[0] || null;
    const worst = sorted.length ? sorted[sorted.length - 1] : null;
    const expiringSoon = withStatus.filter(c => {
      if (c.effectiveStatus !== 'active') return false;
      const days = Math.ceil((new Date(c.validTill) - new Date()) / 86400000);
      return days <= 7 && days >= 0;
    });
    const totalRevenueLoss = withStatus.reduce((s, c) => s + (c.discountGiven || 0), 0);
    res.json({
      bestPerforming: best ? { code: best.code, usageCount: best.usageCount, revenueGenerated: best.revenueGenerated } : null,
      lowestPerforming: worst ? { code: worst.code, usageCount: worst.usageCount, revenueGenerated: worst.revenueGenerated } : null,
      expiringSoon: expiringSoon.map(c => ({ code: c.code, validTill: c.validTill })),
      totalRevenueLoss,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0)
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/usage', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    res.json({
      usage: (c.usageHistory || []).slice().reverse(),
      summary: {
        totalUses: c.usageCount || 0,
        uniqueStudents: (c.uniqueStudents || []).length,
        firstUsedAt: c.firstUsedAt || null,
        lastUsedAt: c.lastUsedAt || null,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/analytics', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const series = await TestSeries.findById(req.params.id).lean();
    const enrolledCount = (series && series.enrolledCount) || 0;
    const conversionRate = enrolledCount > 0 ? Math.min(100, Math.round(((c.usageCount || 0) / enrolledCount) * 100)) : 0;
    const now = new Date();
    const daysToExpiry = c.validTill ? Math.ceil((new Date(c.validTill) - now) / 86400000) : null;
    const trend = {};
    (c.usageHistory || []).forEach(u => {
      const day = new Date(u.timestamp).toISOString().slice(0, 10);
      trend[day] = (trend[day] || 0) + 1;
    });
    res.json({
      analytics: {
        uses: c.usageCount || 0,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0,
        conversionRate,
        daysToExpiry,
        isExpiringSoon: daysToExpiry !== null && daysToExpiry <= 7 && daysToExpiry >= 0,
        usageTrend: Object.entries(trend).map(([date, count]) => ({ date, count })).sort((a, b) => a.date.localeCompare(b.date))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/validate', auth, async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'Coupon code required' });
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const c = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: code.trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: \`Coupon is \${eff}\` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'You have already used this coupon the maximum number of times' });
    }
    const base = series.price || 0;
    const discount = computeCouponDiscount(c, base);
    res.json({ valid: true, code: c.code, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/redeem', auth, async (req, res) => {
  try {
    const { code, appliedAmount, orderRef } = req.body;
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const c = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: (code || '').trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: \`Coupon is \${eff}\` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'Coupon usage limit reached for this student' });
    }
    const base = Number(appliedAmount) || series.price || 0;
    const discount = computeCouponDiscount(c, base);
    c.usageCount += 1;
    if (!c.uniqueStudents.some(s => String(s) === String(req.user.id))) c.uniqueStudents.push(req.user.id);
    c.revenueGenerated += Math.max(0, base - discount);
    c.discountGiven += discount;
    if (!c.firstUsedAt) c.firstUsedAt = new Date();
    c.lastUsedAt = new Date();
    c.usageHistory.push({ student: req.user.id, studentName: req.user.name || 'Student', appliedAmount: base, discountAmount: discount, orderRef: orderRef || '', status: 'success' });
    await c.save();
    res.json({ success: true, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`;

replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — import Coupon model',
`const User     = require('../models/User');`,
`const User     = require('../models/User');
const Coupon   = require('../models/Coupon');`
],
[
'testSeriesManagerUltra — insert coupon routes before CONTROLS TAB',
`
// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`,
seriesCouponRoutes + `// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`
]
]);

// ══════════════════════════════════════════
// C) Frontend: BatchManagerUltra.tsx
// ══════════════════════════════════════════
const batchCouponTab = `// ── COUPON MANAGEMENT TAB ──
function CouponManagementTab({ base, authHeaders, id, showToast }: any) {
  const [data, setData] = useState<any>(null)
  const [analytics, setAnalytics] = useState<any>(null)
  const [filterStatus, setFilterStatus] = useState('all')
  const [sortBy, setSortBy] = useState('newest')
  const [showForm, setShowForm] = useState(false)
  const [editingCoupon, setEditingCoupon] = useState<any>(null)
  const emptyForm = { code: '', type: 'percent', value: '', maxDiscount: '', usageLimit: 100, perStudentLimitType: 'once', perStudentLimitCustom: 1, validFrom: '', validTill: '', description: '', status: 'draft', visibility: 'public', autoApplyBest: false, applicablePlan: 'entire' }
  const [form, setForm] = useState<any>(emptyForm)
  const [expandedUsage, setExpandedUsage] = useState('')
  const [expandedAnalytics, setExpandedAnalytics] = useState('')
  const [usageMap, setUsageMap] = useState<any>({})
  const [analyticsMap, setAnalyticsMap] = useState<any>({})
  const analyticsRef = useRef<any>(null)

  const load = useCallback(() => {
    const params = new URLSearchParams()
    if (filterStatus !== 'all') params.set('status', filterStatus)
    if (sortBy) params.set('sort', sortBy)
    fetch(base + '/' + id + '/coupons?' + params.toString(), { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {})
  }, [filterStatus, sortBy])
  useEffect(() => { load() }, [load])
  useEffect(() => { fetch(base + '/' + id + '/coupons/analytics', { headers: authHeaders }).then(r => r.json()).then(setAnalytics).catch(() => {}) }, [])

  const openCreate = () => { setEditingCoupon(null); setForm(emptyForm); setShowForm(true) }
  const openEdit = (c: any) => {
    setEditingCoupon(c)
    setForm({ ...c, validFrom: c.validFrom ? String(c.validFrom).slice(0, 10) : '', validTill: c.validTill ? String(c.validTill).slice(0, 10) : '' })
    setShowForm(true)
  }
  const submitForm = async () => {
    if (!form.code || !form.code.trim()) return showToast('⚠️ Coupon code required')
    if (!form.value || Number(form.value) <= 0) return showToast('⚠️ Value must be greater than 0')
    if (!form.validFrom || !form.validTill) return showToast('⚠️ Valid From and Valid Till required')
    const url = editingCoupon ? base + '/' + id + '/coupons/' + editingCoupon._id : base + '/' + id + '/coupons'
    const method = editingCoupon ? 'PUT' : 'POST'
    const r = await fetch(url, { method, headers: authHeaders, body: JSON.stringify(form) })
    const d = await r.json()
    if (d.success) { showToast(editingCoupon ? '✅ Coupon updated' : '✅ Coupon created'); setShowForm(false); load() }
    else showToast('⚠️ ' + d.error)
  }
  const duplicate = async (couponId: string) => { const r = await fetch(base + '/' + id + '/coupons/' + couponId + '/duplicate', { method: 'POST', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Coupon duplicated'); load() } else showToast('⚠️ ' + d.error) }
  const toggleStatus = async (c: any, status: string) => { const r = await fetch(base + '/' + id + '/coupons/' + c._id + '/status', { method: 'PUT', headers: authHeaders, body: JSON.stringify({ status }) }); const d = await r.json(); if (d.success) { showToast('✅ Status updated'); load() } else showToast('⚠️ ' + d.error) }
  const del = async (couponId: string) => { if (!window.confirm('Delete this coupon? This cannot be undone.')) return; const r = await fetch(base + '/' + id + '/coupons/' + couponId, { method: 'DELETE', headers: authHeaders }); const d = await r.json(); if (d.success) { showToast('✅ Coupon deleted'); load() } else showToast('⚠️ ' + d.error) }
  const viewUsage = async (couponId: string) => {
    if (expandedUsage === couponId) { setExpandedUsage(''); return }
    setExpandedUsage(couponId)
    if (!usageMap[couponId]) { const d = await fetch(base + '/' + id + '/coupons/' + couponId + '/usage', { headers: authHeaders }).then(r => r.json()); setUsageMap((m: any) => ({ ...m, [couponId]: d })) }
  }
  const viewAnalytics = async (couponId: string) => {
    if (expandedAnalytics === couponId) { setExpandedAnalytics(''); return }
    setExpandedAnalytics(couponId)
    if (!analyticsMap[couponId]) { const d = await fetch(base + '/' + id + '/coupons/' + couponId + '/analytics', { headers: authHeaders }).then(r => r.json()); setAnalyticsMap((m: any) => ({ ...m, [couponId]: d.analytics })) }
  }

  const statusChip = (s: string) => {
    const map: any = { active: [GOOD, 'rgba(52,211,153,0.12)'], scheduled: [ACC, 'rgba(77,159,255,0.12)'], expired: [DIM, 'rgba(107,143,175,0.12)'], disabled: [BAD, 'rgba(248,113,113,0.12)'], draft: [WARN, 'rgba(251,191,36,0.12)'] }
    const [c, bg] = map[s] || map.draft
    return <span style={{ ...chip(c, bg), marginLeft: 6 }}>{s.toUpperCase()}</span>
  }

  const kpis = data?.kpis || {}
  const kpiCards: any[] = [
    ['total', 'Total Coupons', ACC, null],
    ['active', 'Active', GOOD, 'active'],
    ['scheduled', 'Scheduled', ACC, 'scheduled'],
    ['expired', 'Expired', DIM, 'expired'],
    ['disabled', 'Disabled', BAD, 'disabled'],
    ['totalRedemptions', 'Redemptions', '#7DD3FC', 'scroll'],
    ['revenueViaCoupons', 'Revenue ₹', '#FDE68A', 'scroll'],
    ['conversionRate', 'Conversion %', '#A78BFA', null]
  ]

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 10, marginBottom: 14 }}>
        {kpiCards.map(([key, label, color, action]) => (
          <div key={key} style={{ ...cs, marginBottom: 0, textAlign: 'center', cursor: action ? 'pointer' : 'default' }}
            onClick={() => { if (action === 'scroll') analyticsRef.current?.scrollIntoView({ behavior: 'smooth' }); else if (action) setFilterStatus(action) }}>
            <div style={{ fontSize: 18, fontWeight: 800, color }}>{kpis[key] ?? 0}</div>
            <div style={{ fontSize: 9.5, color: DIM }}>{label.toUpperCase()}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10, alignItems: 'center' }}>
        {['all', 'active', 'scheduled', 'expired', 'disabled'].map(s => (
          <button key={s} style={filterStatus === s ? bp : bs} onClick={() => setFilterStatus(s)}>{s === 'all' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}</button>
        ))}
        <select style={{ ...inp, width: 'auto' }} value={sortBy} onChange={e => setSortBy(e.target.value)}>
          <option value="newest">Newest</option>
          <option value="usage">Highest Usage</option>
          <option value="discount">Highest Discount</option>
          <option value="expiring">Expiring Soon</option>
          <option value="updated">Recently Updated</option>
        </select>
        <button style={{ ...bp, marginLeft: 'auto' }} onClick={openCreate}>+ Create Coupon</button>
      </div>

      {showForm && (
        <div style={{ ...cs, border: \`1.5px solid \${BOR2}\` }}>
          <div style={{ fontWeight: 700, marginBottom: 10, color: TS }}>{editingCoupon ? '✏️ Edit Coupon' : '➕ Create Coupon'}</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
            <div><label style={lbl}>Coupon Code</label><input style={inp} value={form.code} onChange={e => setForm({ ...form, code: e.target.value.toUpperCase() })} placeholder="e.g. NEET50" /></div>
            <div><label style={lbl}>Type</label>
              <select style={inp} value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
                <option value="percent">Percent (%)</option>
                <option value="flat">Flat (₹)</option>
              </select>
            </div>
            <div><label style={lbl}>Value {form.type === 'percent' ? '(%)' : '(₹)'}</label><input style={inp} type="number" value={form.value} onChange={e => setForm({ ...form, value: e.target.value })} /></div>
            {form.type === 'percent' && (
              <div><label style={lbl}>Max Discount ₹</label><input style={inp} type="number" value={form.maxDiscount} onChange={e => setForm({ ...form, maxDiscount: e.target.value })} /></div>
            )}
            <div><label style={lbl}>Usage Limit</label><input style={inp} type="number" value={form.usageLimit} onChange={e => setForm({ ...form, usageLimit: e.target.value })} /></div>
            <div><label style={lbl}>Per Student Limit</label>
              <select style={inp} value={form.perStudentLimitType} onChange={e => setForm({ ...form, perStudentLimitType: e.target.value })}>
                <option value="once">Once</option>
                <option value="unlimited">Unlimited</option>
                <option value="custom">Custom</option>
              </select>
            </div>
            {form.perStudentLimitType === 'custom' && (
              <div><label style={lbl}>Custom Usage Count</label><input style={inp} type="number" value={form.perStudentLimitCustom} onChange={e => setForm({ ...form, perStudentLimitCustom: e.target.value })} /></div>
            )}
            <div><label style={lbl}>Valid From</label><input style={inp} type="date" value={form.validFrom} onChange={e => setForm({ ...form, validFrom: e.target.value })} /></div>
            <div><label style={lbl}>Valid Till</label><input style={inp} type="date" value={form.validTill} onChange={e => setForm({ ...form, validTill: e.target.value })} /></div>
            <div><label style={lbl}>Applicable Plan</label>
              <select style={inp} value={form.applicablePlan} onChange={e => setForm({ ...form, applicablePlan: e.target.value })}>
                <option value="entire">Entire Batch</option>
                <option value="base_price">Base Price</option>
              </select>
            </div>
            <div><label style={lbl}>Visibility</label>
              <select style={inp} value={form.visibility} onChange={e => setForm({ ...form, visibility: e.target.value })}>
                <option value="public">Public</option>
                <option value="hidden">Hidden</option>
              </select>
            </div>
            <div><label style={lbl}>Status</label>
              <select style={inp} value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>
                <option value="draft">Draft</option>
                <option value="active">Active</option>
                <option value="disabled">Disabled</option>
              </select>
            </div>
          </div>
          <div style={{ marginTop: 8 }}>
            <label style={lbl}>Description</label>
            <input style={inp} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Short promo note (optional)" />
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', margin: '10px 0' }}>
            <Toggle on={!!form.autoApplyBest} onChange={v => setForm({ ...form, autoApplyBest: v })} label="Auto Apply Best Coupon" />
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={bp} onClick={submitForm}>{editingCoupon ? '💾 Save Changes' : '✅ Create Coupon'}</button>
            <button style={bs} onClick={() => setShowForm(false)}>Cancel</button>
          </div>
        </div>
      )}

      {(!data || !data.coupons) ? <EmptyMsg text="⟳ Loading coupons…" /> : data.coupons.length === 0 ? <EmptyMsg text="No coupons yet. Create your first coupon for this batch." /> : data.coupons.map((c: any) => (
        <div key={c._id} style={cs}>
          <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 }}>
            <div>
              <div style={{ color: TS, fontWeight: 700, fontSize: 14 }}>{c.code}{statusChip(c.effectiveStatus)}</div>
              <div style={{ fontSize: 11, color: DIM, marginTop: 3 }}>{c.type === 'percent' ? \`\${c.value}% off\` : \`₹\${c.value} off\`}{c.maxDiscount ? \` (max ₹\${c.maxDiscount})\` : ''} · {c.usageCount}/{c.usageLimit} used · {c.perStudentLimitType === 'once' ? '1 per student' : c.perStudentLimitType === 'unlimited' ? 'Unlimited per student' : \`\${c.perStudentLimitCustom} per student\`}</div>
              <div style={{ fontSize: 10.5, color: DIM, marginTop: 3 }}>Valid: {new Date(c.validFrom).toLocaleDateString()} → {new Date(c.validTill).toLocaleDateString()} · {c.applicablePlan === 'base_price' ? 'Base Price only' : 'Entire Batch'} · {c.visibility}</div>
              {c.description && <div style={{ fontSize: 11, color: DIM, marginTop: 3, fontStyle: 'italic' }}>{c.description}</div>}
              <div style={{ fontSize: 9.5, color: DIM, marginTop: 4 }}>Updated {new Date(c.updatedAt).toLocaleString()}</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
            <button style={bs} onClick={() => openEdit(c)}>Edit</button>
            <button style={bs} onClick={() => duplicate(c._id)}>Duplicate</button>
            {c.status === 'disabled' ? <button style={bs} onClick={() => toggleStatus(c, 'active')}>Enable</button> : <button style={bs} onClick={() => toggleStatus(c, 'disabled')}>Disable</button>}
            <button style={bs} onClick={() => viewUsage(c._id)}>{expandedUsage === c._id ? 'Hide Usage' : 'View Usage'}</button>
            <button style={bs} onClick={() => viewAnalytics(c._id)}>{expandedAnalytics === c._id ? 'Hide Analytics' : 'View Analytics'}</button>
            <button style={bd} onClick={() => del(c._id)}>Delete</button>
          </div>
          {expandedUsage === c._id && usageMap[c._id] && (
            <div style={{ marginTop: 10, paddingTop: 10, borderTop: \`1px solid \${BOR}\` }}>
              <div style={{ fontSize: 11.5, color: DIM, marginBottom: 6 }}>Total: {usageMap[c._id].summary.totalUses} · Unique Students: {usageMap[c._id].summary.uniqueStudents} · Revenue: ₹{usageMap[c._id].summary.revenueGenerated} · Discount Given: ₹{usageMap[c._id].summary.discountGiven}</div>
              {usageMap[c._id].usage.length === 0 ? <EmptyMsg text="No redemptions yet." /> : usageMap[c._id].usage.map((u: any, i: number) => (
                <div key={i} style={{ fontSize: 11, color: DIM, padding: '5px 0', borderBottom: \`1px solid \${BOR}\` }}>{u.studentName || 'Student'} · Applied ₹{u.appliedAmount} · Discount ₹{u.discountAmount} · {new Date(u.timestamp).toLocaleString()} · {u.status}</div>
              ))}
            </div>
          )}
          {expandedAnalytics === c._id && analyticsMap[c._id] && (
            <div style={{ marginTop: 10, paddingTop: 10, borderTop: \`1px solid \${BOR}\` }}>
              <div style={{ fontSize: 11.5, color: DIM }}>Uses: {analyticsMap[c._id].uses} · Conversion: {analyticsMap[c._id].conversionRate}% · Revenue: ₹{analyticsMap[c._id].revenueGenerated} · Discount Given: ₹{analyticsMap[c._id].discountGiven}{analyticsMap[c._id].isExpiringSoon ? ' · ⚠️ Expiring Soon' : ''}</div>
            </div>
          )}
        </div>
      ))}

      <div ref={analyticsRef} style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>📊 Coupon Analytics</div>
        {!analytics ? <EmptyMsg text="⟳ Loading analytics…" /> : (
          <div style={{ fontSize: 11.5, color: DIM, lineHeight: 1.9 }}>
            Best Performing: {analytics.bestPerforming ? \`\${analytics.bestPerforming.code} (\${analytics.bestPerforming.usageCount} uses)\` : '—'}<br />
            Lowest Performing: {analytics.lowestPerforming ? \`\${analytics.lowestPerforming.code} (\${analytics.lowestPerforming.usageCount} uses)\` : '—'}<br />
            Total Redemptions: {analytics.totalRedemptions}<br />
            Revenue Loss via Discounts: ₹{analytics.totalRevenueLoss}<br />
            Expiring Soon: {analytics.expiringSoon?.length ? analytics.expiringSoon.map((e: any) => e.code).join(', ') : 'None'}
          </div>
        )}
      </div>
    </div>
  )
}

`;

replaceExact('frontend/app/admin/x7k2p/BatchManagerUltra.tsx', [
[
'BatchManagerUltra — add coupons tab entry',
`    ['overview', '📊 Overview'], ['students', '👥 Students'], ['exams', '📝 Exams'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],`,
`    ['overview', '📊 Overview'], ['students', '👥 Students'], ['exams', '📝 Exams'], ['pricing', '💰 Pricing'],
    ['coupons', '🎟️ Coupons'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],`
],
[
'BatchManagerUltra — render CouponManagementTab',
`      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`,
`      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`
],
[
'BatchManagerUltra — insert CouponManagementTab component before ControlsTab',
`// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`,
batchCouponTab + `// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`
]
]);

// ══════════════════════════════════════════
// D) Frontend: TestSeriesManagerUltra.tsx
// ══════════════════════════════════════════
const seriesCouponTab = batchCouponTab
  .replace(/for this batch\./g, 'for this test series.')
  .replace(/Entire Batch/g, 'Entire Test Series');

replaceExact('frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx', [
[
'TestSeriesManagerUltra — add coupons tab entry',
`    ['overview', '📊 Overview'], ['students', '👥 Students'], ['tests', '📝 Tests'], ['pricing', '💰 Pricing'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],`,
`    ['overview', '📊 Overview'], ['students', '👥 Students'], ['tests', '📝 Tests'], ['pricing', '💰 Pricing'],
    ['coupons', '🎟️ Coupons'],
    ['controls', '⚙️ Controls'], ['materials', '📁 Materials'], ['analytics', '📈 Analytics'],`
],
[
'TestSeriesManagerUltra — render CouponManagementTab',
`      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`,
`      {tab === 'pricing' && <PricingTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}
      {tab === 'coupons' && <CouponManagementTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} />}`
],
[
'TestSeriesManagerUltra — insert CouponManagementTab component before ControlsTab',
`// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`,
seriesCouponTab + `// ── 10) CONTROLS TAB ──
function ControlsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {`
]
]);

console.log('\\n✅ ALL FILES PATCHED SUCCESSFULLY');
NODEEOF

node /tmp/fix_coupon_tab.js

echo ""
echo "=== Verifying ==="
grep -n "CouponManagementTab" "$B_TSX" "$S_TSX" | head -6
grep -n "router.get('/:id/coupons'" "$B_ROUTE" "$S_ROUTE"
grep -n "require('../models/Coupon')" "$B_ROUTE" "$S_ROUTE"

echo ""
echo "✅ DONE. Git push karke Render + Vercel pe deploy karo, phir Batch/Test Series Detail page pe naya 🎟️ Coupons tab (Pricing ke baad) check karo."
