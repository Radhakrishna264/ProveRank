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
const optAuth = (req, res, next) => {
  const h = req.headers.authorization;
  if (h && h.startsWith('Bearer ')) {
    try { req.user = jwt.verify(h.split(' ')[1], JWT); } catch (e) {}
  }
  next();
};

// GET /autocomplete?q= — batch name suggestions (debounced from frontend)
router.get('/autocomplete', async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q || q.length < 2) return res.json({ suggestions: [] });
    const batches = await Batch.find({
      name:   { $regex: q, $options: 'i' },
      status: 'active'
    }).select('name examType isFree').limit(6).lean();
    res.json({ suggestions: batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /recommendations?examType=NEET&excludeId=xxx
router.get('/recommendations', optAuth, async (req, res) => {
  try {
    const { examType, excludeId } = req.query;
    const filter = { status: 'active' };
    if (examType) filter.examType = examType;
    if (excludeId) {
      try { filter._id = { $ne: new mongoose.Types.ObjectId(excludeId) }; } catch (e) {}
    }
    const batches = await Batch.find(filter).sort({ enrolledCount: -1, rating: -1 }).limit(4).lean();
    res.json({ batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/review — student submits review (pending admin approval)
router.post('/:id/review', auth, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: 'Rating 1-5 required' });
    const existing = await Review.findOne({ batchId: req.params.id, studentId: req.user.id });
    if (existing) return res.status(400).json({ error: 'You have already reviewed this batch' });
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    await Review.create({
      batchId:     req.params.id,
      studentId:   req.user.id,
      studentName: user?.name || 'Student',
      rating:      Number(rating),
      comment:     comment || '',
      status:      'pending'
    });
    res.json({ success: true, message: 'Review submitted — pending admin approval' });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/reviews — approved reviews for a batch
router.get('/:id/reviews', async (req, res) => {
  try {
    const reviews = await Review.find({ batchId: req.params.id, status: 'approved' })
      .sort({ createdAt: -1 }).limit(10).lean();
    res.json({ reviews });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/razorpay-order — create payment order (test mode safe)
router.post('/:id/razorpay-order', auth, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const amount = ((batch.discountPrice || batch.price) * 100);
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.json({
        success:  true,
        orderId:  'order_test_' + Date.now(),
        amount,
        currency: 'INR',
        key:      'rzp_test_placeholder',
        testMode: true,
        batchName: batch.name
      });
    }
    const Razorpay = require('razorpay');
    const rzp   = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
    const order = await rzp.orders.create({ amount, currency: 'INR', notes: { batchId: req.params.id } });
    res.json({ success: true, orderId: order.id, amount, currency: 'INR', key: process.env.RAZORPAY_KEY_ID, batchName: batch.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
