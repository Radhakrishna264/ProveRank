// ══════════════════════════════════════════════════════════════════
// FPR4 — STUDENT MARKETPLACE ULTRA UPGRADE APIs
// Mounted at: /api/student/batch-ultra
// Price Watch · Fit Score · Compare Save/Share · Preview Analytics ·
// Batch Activity Feed · Exam Calendar View
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const crypto   = require('crypto');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
let BatchActivity;
try { BatchActivity = require('../models/BatchActivity'); } catch (e) { BatchActivity = null; }

const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

function effectivePrice(b) {
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  return b.discountPrice || b.price || 0;
}
function computeFitScore(b, user) {
  let score = 50;
  if (user && user.targetExam) {
    if ((b.examType || '').toLowerCase() === String(user.targetExam).toLowerCase()) score += 30;
    else score -= 10;
  }
  if (b.rating) score += Math.round((b.rating - 3) * 5);
  if (b.enrolledCount > 100) score += 10; else if (b.enrolledCount > 20) score += 5;
  if (b.isSpotlight) score += 5;
  return Math.max(0, Math.min(100, score));
}

// Lightweight local model for saved compare shortlists (public share link)
const CompareSetSchema = new mongoose.Schema({
  shareId: { type: String, unique: true, index: true },
  batchIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
const CompareSet = mongoose.models.CompareSet || mongoose.model('CompareSet', CompareSetSchema);

// ══════════════════════════════════════════════════════════════════
// PRICE WATCH
// ══════════════════════════════════════════════════════════════════
router.post('/:id/price-watch', auth, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    const existing = (user?.priceWatch || []).find(pw => pw.batchId?.toString() === req.params.id);
    if (existing) {
      await User.collection.updateOne({ _id: userId }, { $pull: { priceWatch: { batchId: new mongoose.Types.ObjectId(req.params.id) } } });
      return res.json({ success: true, watching: false });
    }
    await User.collection.updateOne({ _id: userId }, {
      $addToSet: { wishlistBatches: batch._id },
      $push: { priceWatch: { batchId: batch._id, watchedPrice: effectivePrice(batch), createdAt: new Date() } }
    });
    res.json({ success: true, watching: true, watchedPrice: effectivePrice(batch) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/price-watch/alerts', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const watches = user?.priceWatch || [];
    if (!watches.length) return res.json({ alerts: [] });
    const batches = await Batch.find({ _id: { $in: watches.map(w => w.batchId) } }).lean();
    const alerts = batches.map(b => {
      const w = watches.find(x => x.batchId?.toString() === b._id.toString());
      const eff = effectivePrice(b);
      return { batchId: b._id, name: b.name, watchedPrice: w?.watchedPrice || 0, currentPrice: eff, dropped: eff < (w?.watchedPrice || 0) };
    }).filter(a => a.dropped);
    res.json({ alerts });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// FIT SCORE (standalone)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/fit-score', async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    let user = null;
    const h = req.headers.authorization;
    if (h && h.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(h.split(' ')[1], JWT);
        user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(decoded.id) });
      } catch (e) {}
    }
    res.json({ fitScore: computeFitScore(batch, user) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// COMPARE SAVE / SHARE
// ══════════════════════════════════════════════════════════════════
router.post('/compare/save', auth, async (req, res) => {
  try {
    const { batchIds } = req.body;
    if (!Array.isArray(batchIds) || batchIds.length < 2) return res.status(400).json({ error: 'Select at least 2 items to compare' });
    const shareId = crypto.randomBytes(5).toString('hex');
    const set = await CompareSet.create({ shareId, batchIds, createdBy: req.user.id });
    res.json({ success: true, shareId: set.shareId });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/compare/:shareId', async (req, res) => {
  try {
    const set = await CompareSet.findOne({ shareId: req.params.shareId }).lean();
    if (!set) return res.status(404).json({ error: 'Compare link not found or expired' });
    const batches = await Batch.find({ _id: { $in: set.batchIds } }).lean();
    res.json({ batches: batches.map(b => ({ ...b, effectivePrice: effectivePrice(b) })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// PREVIEW ANALYTICS (best-effort, non-blocking)
// ══════════════════════════════════════════════════════════════════
router.post('/:id/preview-track', async (req, res) => {
  try {
    await Batch.findByIdAndUpdate(req.params.id, { $inc: { previewCount: 1 } });
    res.json({ success: true });
  } catch (e) { res.json({ success: true }); } // never block UX for analytics
});

// ══════════════════════════════════════════════════════════════════
// BATCH ACTIVITY FEED (student-facing, read-only)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/activity', async (req, res) => {
  try {
    if (!BatchActivity) return res.json({ activity: [] });
    const activity = await BatchActivity.find({ batchId: req.params.id, isActive: true }).sort({ createdAt: -1 }).limit(20).lean();
    res.json({ activity });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// EXAM CALENDAR VIEW — upcoming tests across a student's enrolled batches
// ══════════════════════════════════════════════════════════════════
router.get('/calendar/upcoming', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const ids = user?.enrolledBatches || [];
    let Exam;
    try { Exam = mongoose.model('Exam'); } catch (e) { Exam = null; }
    if (!Exam || !ids.length) return res.json({ upcoming: [] });
    const batches = await Batch.find({ _id: { $in: ids } }).select('exams name').lean();
    const examIds = batches.flatMap(b => b.exams || []);
    const exams = await Exam.find({ _id: { $in: examIds }, scheduledDate: { $gte: new Date() } }).sort({ scheduledDate: 1 }).limit(20).lean().catch(() => []);
    res.json({ upcoming: exams || [] });
  } catch (e) { res.json({ upcoming: [] }); }
});

module.exports = router;
