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
