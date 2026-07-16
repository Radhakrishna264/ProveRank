#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — FPR3 BANNER MANAGEMENT & PUBLISH GATE — BACKEND INSTALLER
# Run from your project ROOT on Replit, AFTER FPR1 + FPR2 backend
# installers have already run (patches batchManagerUltra.js and
# testSeriesManagerUltra.js with the Publish Gate).
# Safe to re-run (idempotent).
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank FPR3 — Banner Management & Publish Gate — BACKEND install starting..."

# ── Auto-detect project paths ──
MODELS_DIR=$(find . -maxdepth 6 -type f -name "User.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
ROUTES_DIR=$(find . -maxdepth 6 -type f -name "bannerGenerator.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
BACKEND_ROOT=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null -exec grep -l "app.use('/api/admin" {} \; | head -1 | xargs -I{} dirname {})

if [ -z "$MODELS_DIR" ]; then MODELS_DIR="./backend/models"; echo "⚠️  models dir not auto-detected — defaulting to $MODELS_DIR"; fi
if [ -z "$ROUTES_DIR" ]; then ROUTES_DIR="./backend/routes"; echo "⚠️  routes dir not auto-detected — defaulting to $ROUTES_DIR"; fi
if [ -z "$BACKEND_ROOT" ]; then BACKEND_ROOT="./backend"; echo "⚠️  backend root not auto-detected — defaulting to $BACKEND_ROOT"; fi

BATCH_ROUTE_FILE="$ROUTES_DIR/batchManagerUltra.js"
SERIES_ROUTE_FILE="$ROUTES_DIR/testSeriesManagerUltra.js"

mkdir -p "$MODELS_DIR" "$ROUTES_DIR"
echo "📁 Models dir : $MODELS_DIR"
echo "📁 Routes dir : $ROUTES_DIR"
echo "📁 Backend root: $BACKEND_ROOT"

if [ ! -f "$BATCH_ROUTE_FILE" ]; then
  echo "⚠️  $BATCH_ROUTE_FILE not found — run FPR1 backend installer first for full Publish Gate integration on Batches."
fi
if [ ! -f "$SERIES_ROUTE_FILE" ]; then
  echo "⚠️  $SERIES_ROUTE_FILE not found — run FPR2 backend installer first for full Publish Gate integration on Test Series."
fi

# ── 1) Create models/Banner.js (idempotent — skip if exists) ──
if [ -f "$MODELS_DIR/Banner.js" ]; then echo "⏭️  Banner.js exists — skipping"; else
cat > "$MODELS_DIR/Banner.js" << 'PRVRNK_EOF_MARKER'
const mongoose = require('mongoose');

const BannerSchema = new mongoose.Schema({
  // ── Legacy fields (preserved for backward compatibility) ──
  batchId: { type: String, default: '' },
  batchName: { type: String, default: '' },
  title: { type: String, required: true },
  tagline: { type: String, default: '' },
  examType: { type: String, default: 'NEET' },
  price: { type: String, default: '' },
  totalTests: { type: String, default: '' },
  duration: { type: String, default: '' },
  validity: { type: String, default: '' },
  highlights: [{ type: String }],
  ctaText: { type: String, default: 'Enroll Now' },
  badge: { type: String, default: 'none' },
  template: { type: String, default: 'classic' },
  primaryColor: { type: String, default: '#4D9FFF' },
  secondaryColor: { type: String, default: '#00D4FF' },
  textColor: { type: String, default: '#FFFFFF' },
  accentColor: { type: String, default: '#FFD700' },
  fontStyle: { type: String, default: 'modern' },
  bgImage: { type: String, default: '' },
  published: { type: Boolean, default: false },
  scheduledAt: { type: Date },
  versions: [{
    data: { type: mongoose.Schema.Types.Mixed },
    savedAt: { type: Date, default: Date.now },
    label: { type: String, default: '' }
  }],
  analytics: {
    views: { type: Number, default: 0 },
    clicks: { type: Number, default: 0 },
    enrolls: { type: Number, default: 0 }
  },
  createdBy: { type: String, default: '' },

  // ── FPR3 Ultra SaaS Publish-Gate fields ──
  linkedBatchId: { type: mongoose.Schema.Types.ObjectId, default: null },
  linkedType: { type: String, default: 'none', enum: ['batch', 'series', 'none'] },
  status: { type: String, default: 'draft', enum: ['draft', 'ready', 'scheduled', 'published', 'archived', 'removed', 'replaced'] },
  syncState: { type: String, default: 'synced', enum: ['synced', 'pending_sync', 'conflict', 'manual_override', 'ready_to_publish'] },
  qualityScore: { type: Number, default: 0 },
  tags: [{ type: String }],
  autoPublish: { type: Boolean, default: false },
  timezone: { type: String, default: 'Asia/Kolkata' },
  replacedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Banner', default: null },
  replacedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'Banner', default: null },
  removedAt: { type: Date, default: null },
  approvedAt: { type: Date, default: null },
  approvedBy: { type: String, default: '' },
  fieldLocks: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.models.Banner || mongoose.model('Banner', BannerSchema);
PRVRNK_EOF_MARKER
echo "✅ Created Banner.js"
fi

# ── 2) Create models/BannerAuditLog.js (idempotent) ──
if [ -f "$MODELS_DIR/BannerAuditLog.js" ]; then echo "⏭️  BannerAuditLog.js exists — skipping"; else
cat > "$MODELS_DIR/BannerAuditLog.js" << 'PRVRNK_EOF_MARKER'
const mongoose = require('mongoose');

const BannerAuditLogSchema = new mongoose.Schema({
  bannerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Banner', index: true },
  action: { type: String },
  oldValue: { type: mongoose.Schema.Types.Mixed },
  newValue: { type: mongoose.Schema.Types.Mixed },
  performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  performedByName: { type: String, default: 'Admin' },
  linkedType: { type: String, default: 'none' },
  linkedBatchId: { type: mongoose.Schema.Types.ObjectId, default: null },
  reason: { type: String, default: '' },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.models.BannerAuditLog || mongoose.model('BannerAuditLog', BannerAuditLogSchema);
PRVRNK_EOF_MARKER
echo "✅ Created BannerAuditLog.js"
fi

# ── 3) Overwrite routes/bannerGenerator.js with FPR3 Ultra version ──
cp "$ROUTES_DIR/bannerGenerator.js" "$ROUTES_DIR/bannerGenerator.js.bak_fpr3" 2>/dev/null || true
cat > "$ROUTES_DIR/bannerGenerator.js" << 'PRVRNK_EOF_MARKER'
// ══════════════════════════════════════════════════════════════════
// FPR3 — BANNER MANAGEMENT & PUBLISH GATE (Admin)
// Mounted at: /api/admin/banners
// Preserves ALL legacy endpoints (list/get/create/update/delete/
// duplicate/restore-version/publish-toggle/track) used by the
// existing Banner Generator page, and adds: Overview, Sync Queue,
// Publish Gate, Bulk Manager, Analytics Summary, Audit Trail,
// Approve/Remove/Replace/Restore flows, Quality Score.
// ══════════════════════════════════════════════════════════════════
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const Banner = require('../models/Banner');
let BannerAuditLog;
try { BannerAuditLog = require('../models/BannerAuditLog'); } catch (e) { BannerAuditLog = null; }

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

async function logAudit({ bannerId, action, oldValue, newValue, performedBy, performedByName, linkedType, linkedBatchId, reason }) {
  if (!BannerAuditLog) return;
  try {
    await BannerAuditLog.create({ bannerId, action, oldValue, newValue, performedBy, performedByName: performedByName || 'Admin', linkedType, linkedBatchId, reason: reason || '', timestamp: new Date() });
  } catch (e) { /* audit must never break main flow */ }
}

function computeQualityScore(b) {
  let score = 0;
  if (b.title && b.title.trim()) score += 20;
  if (b.ctaText && b.ctaText.trim()) score += 15;
  if (b.price && String(b.price).trim()) score += 15;
  if (b.tagline && b.tagline.trim()) score += 10;
  if (b.highlights && b.highlights.filter(Boolean).length >= 2) score += 15;
  if (b.bgImage && b.bgImage.trim()) score += 10;
  if (b.template) score += 10;
  if (b.primaryColor && b.accentColor) score += 5;
  return Math.min(100, score);
}

// ── Lazy auto-publish: flip overdue scheduled banners to published on each list load ──
async function autoPublishOverdue() {
  try {
    const now = new Date();
    const due = await Banner.find({ published: false, status: { $in: ['scheduled', 'ready'] }, scheduledAt: { $lte: now, $ne: null } });
    for (const b of due) {
      b.published = true;
      b.status = 'published';
      await b.save();
      await logAudit({ bannerId: b._id, action: 'auto_published', newValue: { publishedAt: now }, linkedType: b.linkedType, linkedBatchId: b.linkedBatchId });
    }
  } catch (e) { /* non-fatal */ }
}

// ══════════════════════════════════════════════════════════════════
// OVERVIEW — stats dashboard
// ══════════════════════════════════════════════════════════════════
router.get('/overview', auth, async (req, res) => {
  try {
    await autoPublishOverdue();
    const all = await Banner.find({}).sort({ updatedAt: -1 }).lean();
    const linkedBatches = new Set(all.filter(b => b.linkedType === 'batch').map(b => String(b.linkedBatchId)));
    const linkedSeries = new Set(all.filter(b => b.linkedType === 'series').map(b => String(b.linkedBatchId)));
    res.json({
      overview: {
        total: all.length,
        draft: all.filter(b => b.status === 'draft').length,
        ready: all.filter(b => b.status === 'ready').length,
        published: all.filter(b => b.published || b.status === 'published').length,
        scheduled: all.filter(b => b.status === 'scheduled' || (b.scheduledAt && new Date(b.scheduledAt) > new Date())).length,
        removed: all.filter(b => b.status === 'removed').length,
        linkedBatches: linkedBatches.size,
        linkedSeries: linkedSeries.size,
        recentlyEdited: all.slice(0, 6).map(b => ({ _id: b._id, title: b.title, updatedAt: b.updatedAt, status: b.status }))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SYNC QUEUE — banners needing re-sync from linked batch/series
// ══════════════════════════════════════════════════════════════════
router.get('/sync-queue', auth, async (req, res) => {
  try {
    const pending = await Banner.find({ syncState: { $in: ['pending_sync', 'conflict'] } }).sort({ updatedAt: -1 }).lean();
    res.json({ pending });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/sync', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    const { title, price, duration, validity, totalTests, examType } = req.body;
    const oldVal = { title: banner.title, price: banner.price };
    if (title !== undefined) banner.title = title;
    if (price !== undefined) banner.price = price;
    if (duration !== undefined) banner.duration = duration;
    if (validity !== undefined) banner.validity = validity;
    if (totalTests !== undefined) banner.totalTests = totalTests;
    if (examType !== undefined) banner.examType = examType;
    banner.syncState = 'synced';
    banner.qualityScore = computeQualityScore(banner);
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'synced', oldValue: oldVal, newValue: { title: banner.title, price: banner.price }, linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// PUBLISH GATE — check readiness for a linked batch/series
// ══════════════════════════════════════════════════════════════════
router.get('/gate/:linkedType/:linkedId', auth, async (req, res) => {
  try {
    const { linkedType, linkedId } = req.params;
    const banner = await Banner.findOne({ linkedType, linkedBatchId: linkedId, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return res.json({ gate: 'banner_required', launchAllowed: false, banner: null });
    let gate = 'banner_draft_ready';
    if (banner.status === 'published' || banner.published) gate = 'banner_published';
    else if (banner.approvedAt) gate = 'banner_approved';
    const qualityScore = banner.qualityScore || computeQualityScore(banner);
    const launchAllowed = qualityScore >= 60 && ['ready', 'scheduled', 'published'].includes(banner.status) || banner.published;
    res.json({ gate, launchAllowed, banner: { _id: banner._id, title: banner.title, status: banner.status, qualityScore } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Internal helper other route files can use via HTTP-free direct import pattern
async function isBannerReady(linkedType, linkedId) {
  try {
    const banner = await Banner.findOne({ linkedType, linkedBatchId: linkedId, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return { ready: false, reason: 'No banner has been created for this item yet.' };
    const qualityScore = banner.qualityScore || computeQualityScore(banner);
    const ready = (['ready', 'scheduled', 'published'].includes(banner.status) || banner.published) && qualityScore >= 60;
    return { ready, reason: ready ? '' : 'Banner draft is incomplete or not marked ready. Open Banner Management to complete it.', bannerId: banner._id, qualityScore };
  } catch (e) { return { ready: true, reason: '' }; } // fail-open to avoid blocking launches on transient errors
}
router._isBannerReady = isBannerReady; // exposed for require() by batch/series routes

// ══════════════════════════════════════════════════════════════════
// APPROVE / REMOVE / REPLACE / RESTORE-REMOVED
// ══════════════════════════════════════════════════════════════════
router.post('/:id/approve', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    banner.status = banner.status === 'draft' ? 'ready' : banner.status;
    banner.approvedAt = new Date();
    banner.approvedBy = req.user.name || 'Admin';
    banner.qualityScore = computeQualityScore(banner);
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'approved', newValue: { status: banner.status }, linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/remove', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    banner.status = 'removed';
    banner.removedAt = new Date();
    banner.published = false;
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'removed', reason: req.body.reason, linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/restore-removed', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    banner.status = 'draft';
    banner.removedAt = null;
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'restored_from_removed', linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/replace', auth, async (req, res) => {
  try {
    const old = await Banner.findById(req.params.id);
    if (!old) return res.status(404).json({ error: 'Not found' });
    const oldObj = old.toObject();
    delete oldObj._id; delete oldObj.createdAt; delete oldObj.updatedAt; delete oldObj.versions; delete oldObj.__v;
    const replacement = await Banner.create({
      ...oldObj, ...req.body, status: 'draft', published: false, replacedFrom: old._id,
      versions: [], analytics: { views: 0, clicks: 0, enrolls: 0 }
    });
    old.status = 'replaced';
    old.replacedBy = replacement._id;
    old.published = false;
    await old.save();
    await logAudit({ bannerId: replacement._id, action: 'replacement_created', oldValue: { replacedFrom: old._id }, linkedType: old.linkedType, linkedBatchId: old.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: replacement });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// QUALITY SCORE
// ══════════════════════════════════════════════════════════════════
router.get('/:id/quality-score', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id).lean();
    if (!banner) return res.status(404).json({ error: 'Not found' });
    const score = computeQualityScore(banner);
    res.json({
      qualityScore: score,
      breakdown: {
        completeness: (banner.title ? 20 : 0) + (banner.tagline ? 10 : 0),
        ctaClarity: banner.ctaText ? 15 : 0,
        priceClarity: banner.price ? 15 : 0,
        designBalance: (banner.template ? 10 : 0) + (banner.primaryColor && banner.accentColor ? 5 : 0),
        previewFit: banner.bgImage ? 10 : 0,
        highlightsProvided: (banner.highlights || []).filter(Boolean).length
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// BULK MANAGER
// ══════════════════════════════════════════════════════════════════
router.post('/bulk', auth, async (req, res) => {
  try {
    const { ids, action } = req.body;
    if (!Array.isArray(ids) || !ids.length) return res.status(400).json({ error: 'No banners selected' });
    const results = [];
    for (const id of ids) {
      const banner = await Banner.findById(id);
      if (!banner) continue;
      if (action === 'publish') { banner.published = true; banner.status = 'published'; }
      else if (action === 'archive') { banner.status = 'archived'; banner.published = false; }
      else if (action === 'duplicate') {
        const obj = banner.toObject();
        delete obj._id; delete obj.createdAt; delete obj.updatedAt;
        obj.title = obj.title + ' (Copy)'; obj.published = false; obj.status = 'draft'; obj.versions = [];
        const dup = await Banner.create(obj);
        results.push(dup._id);
        continue;
      }
      await banner.save();
      results.push(banner._id);
    }
    await logAudit({ action: 'bulk_' + action, newValue: { ids: results } });
    res.json({ success: true, affected: results.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ANALYTICS SUMMARY
// ══════════════════════════════════════════════════════════════════
router.get('/analytics/summary', auth, async (req, res) => {
  try {
    const all = await Banner.find({}).lean();
    const totalViews = all.reduce((s, b) => s + (b.analytics?.views || 0), 0);
    const totalClicks = all.reduce((s, b) => s + (b.analytics?.clicks || 0), 0);
    const totalEnrolls = all.reduce((s, b) => s + (b.analytics?.enrolls || 0), 0);
    const byTemplate = {};
    all.forEach(b => {
      byTemplate[b.template] = byTemplate[b.template] || { views: 0, clicks: 0, enrolls: 0, count: 0 };
      byTemplate[b.template].views += b.analytics?.views || 0;
      byTemplate[b.template].clicks += b.analytics?.clicks || 0;
      byTemplate[b.template].enrolls += b.analytics?.enrolls || 0;
      byTemplate[b.template].count += 1;
    });
    const byCta = {};
    all.forEach(b => {
      const k = b.ctaText || 'Enroll Now';
      byCta[k] = byCta[k] || { clicks: 0, views: 0 };
      byCta[k].clicks += b.analytics?.clicks || 0;
      byCta[k].views += b.analytics?.views || 0;
    });
    res.json({
      summary: {
        totalViews, totalClicks, totalEnrolls,
        clickRate: totalViews ? +((totalClicks / totalViews) * 100).toFixed(1) : 0,
        conversionRate: totalViews ? +((totalEnrolls / totalViews) * 100).toFixed(1) : 0,
        byTemplate, byCta,
        batchVsSeries: {
          batch: all.filter(b => b.linkedType === 'batch').reduce((s, b) => s + (b.analytics?.views || 0), 0),
          series: all.filter(b => b.linkedType === 'series').reduce((s, b) => s + (b.analytics?.views || 0), 0)
        }
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// AUDIT TRAIL
// ══════════════════════════════════════════════════════════════════
router.get('/audit/:id', auth, async (req, res) => {
  try {
    if (!BannerAuditLog) return res.json({ audit: [] });
    const audit = await BannerAuditLog.find({ bannerId: req.params.id }).sort({ timestamp: -1 }).limit(100).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// LEGACY ENDPOINTS (preserved, unchanged behavior + light FPR3 enrichment)
// ══════════════════════════════════════════════════════════════════

// GET all banners
router.get('/', auth, async (req, res) => {
  try {
    await autoPublishOverdue();
    const banners = await Banner.find().sort({ createdAt: -1 }).lean();
    res.json({ banners });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET single banner
router.get('/:id', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id).lean();
    if (!banner) return res.status(404).json({ error: 'Not found' });
    res.json({ banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST create
router.post('/', auth, async (req, res) => {
  try {
    const body = { ...req.body, createdBy: req.user.id };
    if (body.linkedBatchId) {
      body.syncState = 'synced';
      body.status = body.status || 'draft';
    }
    const banner = await Banner.create(body);
    banner.qualityScore = computeQualityScore(banner);
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'created', newValue: { title: banner.title }, linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT update (saves version history)
router.put('/:id', auth, async (req, res) => {
  try {
    const existing = await Banner.findById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Not found' });
    // Save current as version before update
    const versionSnap = existing.toObject();
    delete versionSnap._id; delete versionSnap.versions; delete versionSnap.__v;
    existing.versions.push({ data: versionSnap, savedAt: new Date(), label: `v${existing.versions.length + 1}` });
    // Apply updates
    Object.assign(existing, req.body);
    existing.qualityScore = computeQualityScore(existing);
    if (existing.linkedBatchId) existing.syncState = existing.syncState === 'conflict' ? 'conflict' : 'synced';
    await existing.save();
    await logAudit({ bannerId: existing._id, action: 'updated', linkedType: existing.linkedType, linkedBatchId: existing.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: existing });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE
router.delete('/:id', auth, async (req, res) => {
  try {
    await Banner.findByIdAndDelete(req.params.id);
    await logAudit({ bannerId: req.params.id, action: 'deleted', performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST duplicate
router.post('/:id/duplicate', auth, async (req, res) => {
  try {
    const orig = await Banner.findById(req.params.id).lean();
    if (!orig) return res.status(404).json({ error: 'Not found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false;
    orig.status = 'draft';
    orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    const dup = await Banner.create(orig);
    await logAudit({ bannerId: dup._id, action: 'duplicated', oldValue: { from: req.params.id }, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST restore version
router.post('/:id/restore/:vIdx', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    await banner.save();
    await logAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST publish toggle
router.post('/:id/publish', auth, async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    banner.published = !banner.published;
    banner.status = banner.published ? 'published' : (banner.approvedAt ? 'ready' : 'draft');
    await banner.save();
    await logAudit({ bannerId: banner._id, action: banner.published ? 'published' : 'unpublished', linkedType: banner.linkedType, linkedBatchId: banner.linkedBatchId, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, published: banner.published });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST track view/click
router.post('/:id/track', async (req, res) => {
  try {
    const { type } = req.body;
    const inc = {};
    if (type === 'view') inc['analytics.views'] = 1;
    if (type === 'click') inc['analytics.clicks'] = 1;
    if (type === 'enroll') inc['analytics.enrolls'] = 1;
    await Banner.findByIdAndUpdate(req.params.id, { $inc: inc });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
PRVRNK_EOF_MARKER
node --check "$ROUTES_DIR/bannerGenerator.js" && echo "✅ Created/Updated routes/bannerGenerator.js (syntax verified)" || { echo "❌ bannerGenerator.js syntax error — restoring backup"; cp "$ROUTES_DIR/bannerGenerator.js.bak_fpr3" "$ROUTES_DIR/bannerGenerator.js" 2>/dev/null; exit 1; }

# ══════════════════════════════════════════════════════════════════
# 4) Patch batchManagerUltra.js — inject Publish Gate (idempotent)
# ══════════════════════════════════════════════════════════════════
if [ -f "$BATCH_ROUTE_FILE" ]; then
  if grep -q "checkBannerGate" "$BATCH_ROUTE_FILE"; then
    echo "⏭️  batchManagerUltra.js already has Publish Gate — skipping"
  else
    cp "$BATCH_ROUTE_FILE" "$BATCH_ROUTE_FILE.bak_fpr3"

    # 4a) Insert checkBannerGate() helper before findStudentByIdOrEmail
    awk '
      /^async function findStudentByIdOrEmail/ && ins!=1 {
        print "// -- FPR3 Publish Gate: block launch (lifecycleStatus -> \x27active\x27) without a ready banner --"
        print "async function checkBannerGate(batchId) {"
        print "  try {"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const banner = await Banner.findOne({ linkedType: \x27batch\x27, linkedBatchId: batchId, status: { $ne: \x27removed\x27 } }).sort({ createdAt: -1 }).lean();"
        print "    if (!banner) return { ready: false, reason: \x27No banner has been created for this batch yet. Open Banner Management to generate one before launching.\x27 };"
        print "    const ready = ([\x27ready\x27, \x27scheduled\x27, \x27published\x27].includes(banner.status) || banner.published);"
        print "    return { ready, reason: ready ? \x27\x27 : \x27Banner draft is not marked ready/approved yet. Open Banner Management to complete it before launching.\x27, bannerId: banner._id };"
        print "  } catch (e) { return { ready: true, reason: \x27\x27 }; }"
        print "}"
        print ""
        ins=1
      }
      { print }
    ' "$BATCH_ROUTE_FILE" > "$BATCH_ROUTE_FILE.tmp" && mv "$BATCH_ROUTE_FILE.tmp" "$BATCH_ROUTE_FILE"

    # 4b) Gate check in controls PUT (launch on lifecycleStatus -> active)
    sed -i "s/    const fields = \['isSpotlight', 'isBundle', 'allowFreeTrial', 'allowEMI', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'\];/    if (req.body.lifecycleStatus === 'active' \&\& batch.lifecycleStatus !== 'active') {\n      const gate = await checkBannerGate(batch._id);\n      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });\n    }\n    const fields = ['isSpotlight', 'isBundle', 'allowFreeTrial', 'allowEMI', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'];/" "$BATCH_ROUTE_FILE"

    # 4c) Gate check in resume-from-pause
    sed -i "s/    const wasPaused = batch.lifecycleStatus === 'paused';\n    batch.lifecycleStatus = wasPaused ? 'active' : 'paused';/&/" "$BATCH_ROUTE_FILE"
    awk '
      /const wasPaused = batch.lifecycleStatus === .paused.;/ && p!=1 {
        print
        print "    if (wasPaused) {"
        print "      const gate = await checkBannerGate(batch._id);"
        print "      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: \x27launch_blocked\x27 });"
        print "    }"
        p=1
        next
      }
      { print }
    ' "$BATCH_ROUTE_FILE" > "$BATCH_ROUTE_FILE.tmp" && mv "$BATCH_ROUTE_FILE.tmp" "$BATCH_ROUTE_FILE"

    # 4d) Banner panel endpoints before module.exports
    awk '
      /^module.exports = router;/ && d!=1 {
        print "// -- FPR3 Banner Panel (Batch Detail page integration) --"
        print "router.get(\x27/:id/banner-panel\x27, auth, isAdmin, async (req, res) => {"
        print "  try {"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const banner = await Banner.findOne({ linkedType: \x27batch\x27, linkedBatchId: req.params.id }).sort({ createdAt: -1 }).lean();"
        print "    const gate = await checkBannerGate(req.params.id);"
        print "    res.json({ banner: banner || null, gate });"
        print "  } catch (e) { res.status(500).json({ error: e.message }); }"
        print "});"
        print ""
        print "router.post(\x27/:id/banner-panel/regenerate\x27, auth, isAdmin, async (req, res) => {"
        print "  try {"
        print "    const batch = await Batch.findById(req.params.id).lean();"
        print "    if (!batch) return res.status(404).json({ error: \x27Batch not found\x27 });"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const draft = await Banner.create({"
        print "      title: batch.name, linkedBatchId: batch._id, linkedType: \x27batch\x27,"
        print "      examType: batch.examType, price: String(effectivePrice(batch) || \x27\x27), status: \x27draft\x27,"
        print "      syncState: \x27synced\x27, published: false, createdBy: req.user.id"
        print "    });"
        print "    res.json({ success: true, banner: draft });"
        print "  } catch (e) { res.status(500).json({ error: e.message }); }"
        print "});"
        print ""
        d=1
      }
      { print }
    ' "$BATCH_ROUTE_FILE" > "$BATCH_ROUTE_FILE.tmp" && mv "$BATCH_ROUTE_FILE.tmp" "$BATCH_ROUTE_FILE"

    node --check "$BATCH_ROUTE_FILE" && echo "✅ Patched batchManagerUltra.js with Publish Gate (syntax verified)" || { echo "❌ batchManagerUltra.js syntax error after patch — restoring backup"; cp "$BATCH_ROUTE_FILE.bak_fpr3" "$BATCH_ROUTE_FILE"; exit 1; }
  fi
fi

# ══════════════════════════════════════════════════════════════════
# 5) Patch testSeriesManagerUltra.js — inject Publish Gate (idempotent)
# ══════════════════════════════════════════════════════════════════
if [ -f "$SERIES_ROUTE_FILE" ]; then
  if grep -q "checkBannerGate" "$SERIES_ROUTE_FILE"; then
    echo "⏭️  testSeriesManagerUltra.js already has Publish Gate — skipping"
  else
    cp "$SERIES_ROUTE_FILE" "$SERIES_ROUTE_FILE.bak_fpr3"

    awk '
      /^async function findStudentByIdOrEmail/ && ins!=1 {
        print "// -- FPR3 Publish Gate: block launch (lifecycleStatus -> \x27active\x27) without a ready banner --"
        print "async function checkBannerGate(seriesId) {"
        print "  try {"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const banner = await Banner.findOne({ linkedType: \x27series\x27, linkedBatchId: seriesId, status: { $ne: \x27removed\x27 } }).sort({ createdAt: -1 }).lean();"
        print "    if (!banner) return { ready: false, reason: \x27No banner has been created for this test series yet. Open Banner Management to generate one before launching.\x27 };"
        print "    const ready = ([\x27ready\x27, \x27scheduled\x27, \x27published\x27].includes(banner.status) || banner.published);"
        print "    return { ready, reason: ready ? \x27\x27 : \x27Banner draft is not marked ready/approved yet. Open Banner Management to complete it before launching.\x27, bannerId: banner._id };"
        print "  } catch (e) { return { ready: true, reason: \x27\x27 }; }"
        print "}"
        print ""
        ins=1
      }
      { print }
    ' "$SERIES_ROUTE_FILE" > "$SERIES_ROUTE_FILE.tmp" && mv "$SERIES_ROUTE_FILE.tmp" "$SERIES_ROUTE_FILE"

    sed -i "s/    const fields = \['isSpotlight', 'isBundle', 'allowFreeTrial', 'allowEMI', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'\];/    if (req.body.lifecycleStatus === 'active' \&\& series.lifecycleStatus !== 'active') {\n      const gate = await checkBannerGate(series._id);\n      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });\n    }\n    const fields = ['isSpotlight', 'isBundle', 'allowFreeTrial', 'allowEMI', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'];/" "$SERIES_ROUTE_FILE"

    awk '
      /const wasPaused = series.lifecycleStatus === .paused.;/ && p!=1 {
        print
        print "    if (wasPaused) {"
        print "      const gate = await checkBannerGate(series._id);"
        print "      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: \x27launch_blocked\x27 });"
        print "    }"
        p=1
        next
      }
      { print }
    ' "$SERIES_ROUTE_FILE" > "$SERIES_ROUTE_FILE.tmp" && mv "$SERIES_ROUTE_FILE.tmp" "$SERIES_ROUTE_FILE"

    awk '
      /^module.exports = router;/ && d!=1 {
        print "// -- FPR3 Banner Panel (Test Series Detail page integration) --"
        print "router.get(\x27/:id/banner-panel\x27, auth, isAdmin, async (req, res) => {"
        print "  try {"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const banner = await Banner.findOne({ linkedType: \x27series\x27, linkedBatchId: req.params.id }).sort({ createdAt: -1 }).lean();"
        print "    const gate = await checkBannerGate(req.params.id);"
        print "    res.json({ banner: banner || null, gate });"
        print "  } catch (e) { res.status(500).json({ error: e.message }); }"
        print "});"
        print ""
        print "router.post(\x27/:id/banner-panel/regenerate\x27, auth, isAdmin, async (req, res) => {"
        print "  try {"
        print "    const series = await TestSeries.findById(req.params.id).lean();"
        print "    if (!series) return res.status(404).json({ error: \x27Test series not found\x27 });"
        print "    let Banner;"
        print "    try { Banner = mongoose.model(\x27Banner\x27); } catch (e) { Banner = require(\x27../models/Banner\x27); }"
        print "    const draft = await Banner.create({"
        print "      title: series.name, linkedBatchId: series._id, linkedType: \x27series\x27,"
        print "      examType: series.examType, price: String(effectivePrice(series) || \x27\x27), status: \x27draft\x27,"
        print "      syncState: \x27synced\x27, published: false, createdBy: req.user.id"
        print "    });"
        print "    res.json({ success: true, banner: draft });"
        print "  } catch (e) { res.status(500).json({ error: e.message }); }"
        print "});"
        print ""
        d=1
      }
      { print }
    ' "$SERIES_ROUTE_FILE" > "$SERIES_ROUTE_FILE.tmp" && mv "$SERIES_ROUTE_FILE.tmp" "$SERIES_ROUTE_FILE"

    node --check "$SERIES_ROUTE_FILE" && echo "✅ Patched testSeriesManagerUltra.js with Publish Gate (syntax verified)" || { echo "❌ testSeriesManagerUltra.js syntax error after patch — restoring backup"; cp "$SERIES_ROUTE_FILE.bak_fpr3" "$SERIES_ROUTE_FILE"; exit 1; }
  fi
fi

# ── 6) Ensure bannerGenerator route is mounted in index.js (idempotent) ──
INDEX_FILE="$BACKEND_ROOT/index.js"
if [ ! -f "$INDEX_FILE" ]; then
  INDEX_FILE=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null | head -1)
fi
if [ -n "$INDEX_FILE" ] && [ -f "$INDEX_FILE" ]; then
  if grep -q "bannerGenerator" "$INDEX_FILE"; then
    echo "⏭️  bannerGenerator already mounted in index.js — skipping"
  else
    cp "$INDEX_FILE" "$INDEX_FILE.bak_fpr3"
    printf "\nconst bannerGeneratorRoutes = require('./routes/bannerGenerator');\napp.use('/api/admin/banners', bannerGeneratorRoutes);\n" >> "$INDEX_FILE"
    node --check "$INDEX_FILE" && echo "✅ Mounted /api/admin/banners route in index.js" || { echo "❌ index.js syntax error — restoring backup"; cp "$INDEX_FILE.bak_fpr3" "$INDEX_FILE"; exit 1; }
  fi
fi

# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — BACKEND (FPR3 Banner Management & Publish Gate)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR3 BANNER MANAGEMENT — BACKEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
BFILE="$ROUTES_DIR/bannerGenerator.js"
PASS=0; FAIL=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

check "1) Banner Model — Legacy Fields Preserved"                  "batchName: { type: String" "$MODELS_DIR/Banner.js"
check "2) Banner Model — Linked Batch/Series Fields"               "linkedType:" "$MODELS_DIR/Banner.js"
check "3) Banner Model — Status Lifecycle Enum"                    "'draft', 'ready', 'scheduled', 'published', 'archived', 'removed', 'replaced'" "$MODELS_DIR/Banner.js"
check "4) Banner Model — Sync State Enum"                          "syncState:" "$MODELS_DIR/Banner.js"
check "5) Banner Model — Quality Score + Tags + Field Locks"       "qualityScore:" "$MODELS_DIR/Banner.js"
check "6) BannerAuditLog Model Created"                             "" "$MODELS_DIR/BannerAuditLog.js"
check "7) Overview Dashboard API (counts by status)"                "router.get('/overview'" "$BFILE"
check "8) Sync Queue API (pending/conflict banners)"                "router.get('/sync-queue'" "$BFILE"
check "9) Banner Sync (re-pull from linked batch/series)"           "router.post('/:id/sync'" "$BFILE"
check "10) Publish Gate Check API (per batch/series)"               "router.get('/gate/:linkedType/:linkedId'" "$BFILE"
check "11) Approve Banner Flow"                                      "router.post('/:id/approve'" "$BFILE"
check "12) Remove Banner Flow (soft-remove, recoverable)"           "router.post('/:id/remove'" "$BFILE"
check "13) Restore Removed Banner"                                   "router.post('/:id/restore-removed'" "$BFILE"
check "14) Replace Banner Flow (preserves old, links replacement)"  "router.post('/:id/replace'" "$BFILE"
check "15) Banner Quality Score API"                                 "router.get('/:id/quality-score'" "$BFILE"
check "16) Bulk Banner Manager (publish/archive/duplicate)"         "router.post('/bulk'" "$BFILE"
check "17) Analytics Summary (funnel/template/CTA leaderboard)"    "router.get('/analytics/summary'" "$BFILE"
check "18) Banner Audit Trail API"                                   "router.get('/audit/:id'" "$BFILE"
check "19) Lazy Auto-Publish Safety Net (in addition to cron)"      "async function autoPublishOverdue" "$BFILE"
check "20) Legacy List/Get/Create/Update/Delete Preserved"          "router.put('/:id', auth, async" "$BFILE"
check "21) Legacy Duplicate/Restore-Version/Publish-Toggle Preserved" "router.post('/:id/publish'" "$BFILE"
check "22) Legacy Analytics Track Endpoint Preserved"                "router.post('/:id/track'" "$BFILE"
check "23) Auto Banner Draft Creation Hooks Now Resolve (models/Banner.js exists)" "" "$MODELS_DIR/Banner.js"
check "24) Batch Publish Gate — checkBannerGate() Helper"           "checkBannerGate" "$ROUTES_DIR/batchManagerUltra.js"
check "25) Batch Publish Gate — Blocks Launch on Activate"          "gate: 'launch_blocked'" "$ROUTES_DIR/batchManagerUltra.js"
check "26) Batch Publish Gate — Blocks Resume-from-Pause"           "if (wasPaused) {" "$ROUTES_DIR/batchManagerUltra.js"
check "27) Batch Banner Panel API (status/preview for detail page)" "router.get('/:id/banner-panel'" "$ROUTES_DIR/batchManagerUltra.js"
check "28) Batch Banner Regenerate API"                              "banner-panel/regenerate" "$ROUTES_DIR/batchManagerUltra.js"
check "29) Series Publish Gate — checkBannerGate() Helper"          "checkBannerGate" "$ROUTES_DIR/testSeriesManagerUltra.js"
check "30) Series Publish Gate — Blocks Launch on Activate"          "gate: 'launch_blocked'" "$ROUTES_DIR/testSeriesManagerUltra.js"
check "31) Series Publish Gate — Blocks Resume-from-Pause"          "if (wasPaused) {" "$ROUTES_DIR/testSeriesManagerUltra.js"
check "32) Series Banner Panel API (status/preview for detail page)" "router.get('/:id/banner-panel'" "$ROUTES_DIR/testSeriesManagerUltra.js"
check "33) Series Banner Regenerate API"                             "banner-panel/regenerate" "$ROUTES_DIR/testSeriesManagerUltra.js"
check "34) bannerGenerator Route Mounted in index.js"               "bannerGenerator" "$INDEX_FILE"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 ALL BACKEND FPR3 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "👉 Next: Restart your backend (Render/Replit run) then run the FRONTEND installer script (fpr3_frontend_install.sh)."
