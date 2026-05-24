const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin','superadmin'].includes(req.user?.role)) return res.status(403).json({ error: 'Admin only' });
  next();
};

// GET / — all batches list for admin controls page
router.get('/', auth, isAdmin, async (req, res) => {
  try {
    const batches = await Batch.find({}).sort({ createdAt: -1 }).lean();
    res.json({ batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/spotlight — toggle spotlight
router.put('/:id/spotlight', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.isSpotlight = !batch.isSpotlight;
    await batch.save();
    res.json({ success: true, isSpotlight: batch.isSpotlight });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/flashsale — set or remove flash sale
router.put('/:id/flashsale', auth, isAdmin, async (req, res) => {
  try {
    const { flashSalePrice, flashSaleEndTime, remove } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    if (remove) {
      await Batch.findByIdAndUpdate(req.params.id, { $unset: { flashSalePrice: 1, flashSaleEndTime: 1 } });
    } else {
      batch.flashSalePrice   = flashSalePrice;
      batch.flashSaleEndTime = new Date(flashSaleEndTime);
      await batch.save();
    }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/bundle — toggle bundle
router.put('/:id/bundle', auth, isAdmin, async (req, res) => {
  try {
    const { bundleItems, bundlePrice } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.isBundle = !batch.isBundle;
    if (bundleItems) batch.bundleItems = bundleItems;
    if (bundlePrice) batch.price       = bundlePrice;
    await batch.save();
    res.json({ success: true, isBundle: batch.isBundle });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/trial — toggle free trial
router.put('/:id/trial', auth, isAdmin, async (req, res) => {
  try {
    const { trialDays } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.allowFreeTrial = !batch.allowFreeTrial;
    if (trialDays) batch.trialDays = Number(trialDays);
    await batch.save();
    res.json({ success: true, allowFreeTrial: batch.allowFreeTrial, trialDays: batch.trialDays });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/emi — toggle EMI
router.put('/:id/emi', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.allowEMI = !batch.allowEMI;
    await batch.save();
    res.json({ success: true, allowEMI: batch.allowEMI });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /reviews — all reviews (filter by status)
router.get('/reviews', auth, isAdmin, async (req, res) => {
  try {
    const status  = req.query.status || 'pending';
    const reviews = await Review.find({ status }).sort({ createdAt: -1 }).lean();
    res.json({ reviews });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /reviews/:id/approve — approve review + recalculate rating
router.put('/reviews/:id/approve', auth, isAdmin, async (req, res) => {
  try {
    const review = await Review.findById(req.params.id);
    if (!review) return res.status(404).json({ error: 'Review not found' });
    review.status     = 'approved';
    review.approvedBy = req.user.id;
    review.approvedAt = new Date();
    await review.save();
    const approved = await Review.find({ batchId: review.batchId, status: 'approved' });
    if (approved.length > 0) {
      const avg = approved.reduce((s, r) => s + r.rating, 0) / approved.length;
      await Batch.findByIdAndUpdate(review.batchId, {
        rating:      Math.round(avg * 10) / 10,
        ratingCount: approved.length
      });
    }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /reviews/:id — reject review
router.delete('/reviews/:id', auth, isAdmin, async (req, res) => {
  try {
    await Review.findByIdAndUpdate(req.params.id, { status: 'rejected' });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/price-drop-notify — count wishlisted users (in-app alert ready)
router.post('/:id/price-drop-notify', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const bObjId = new mongoose.Types.ObjectId(req.params.id);
    const users  = await User.collection.find({ wishlistBatches: { $in: [bObjId] } }).toArray();
    res.json({ success: true, notified: users.length, batchName: batch.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
