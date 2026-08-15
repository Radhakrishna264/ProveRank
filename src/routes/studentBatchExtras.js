const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const TestSeries=require('../models/TestSeries');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';
const crypto   = require('crypto');
const BatchPayment = require('../models/BatchPayment');

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

// GET /autocomplete?q= — series name suggestions (debounced from frontend)
router.get('/autocomplete', async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q || q.length < 2) return res.json({ suggestions: [] });
    const series = await TestSeries.find({
      name:   { $regex: q, $options: 'i' },
      lifecycleStatus: 'active'
    }).select('name examType isFree').limit(6).lean();
    res.json({ suggestions: series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /recommendations?examType=NEET&excludeId=xxx
router.get('/recommendations', optAuth, async (req, res) => {
  try {
    const { examType, excludeId } = req.query;
    const filter = { lifecycleStatus: 'active', visibility: { $ne: 'private' } };
    if (examType) filter.examType = examType;
    if (excludeId) {
      try { filter._id = { $ne: new mongoose.Types.ObjectId(excludeId) }; } catch (e) {}
    }
    const series = await TestSeries.find(filter).sort({ enrolledCount: -1, rating: -1 }).limit(4).lean();
    res.json({ batches: series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/review — student submits review (pending admin approval)
router.post('/:id/review', auth, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: 'Rating 1-5 required' });
    const existing = await Review.findOne({ batchId: req.params.id, studentId: req.user.id });
    if (existing) return res.status(400).json({ error: 'You have already reviewed this series' });
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

// GET /:id/reviews — approved reviews for a series
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
    const item = await TestSeries.findById(req.params.id);
    if (!item) return res.status(404).json({ error: 'Series not found' });
    const amount = ((item.discountPrice || item.price) * 100);
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.json({
        success:  true,
        orderId:  'order_test_' + Date.now(),
        amount,
        currency: 'INR',
        key:      'rzp_test_placeholder',
        testMode: true,
        batchName: item.name
      });
    }
    const Razorpay = require('razorpay');
    const rzp   = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
    const order = await rzp.orders.create({ amount, currency: 'INR', notes: { seriesId: req.params.id } });
    res.json({ success: true, orderId: order.id, amount, currency: 'INR', key: process.env.RAZORPAY_KEY_ID, batchName: item.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/razorpay-verify — verify payment signature, enroll student, create receipt
router.post('/:id/razorpay-verify', auth, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!razorpay_order_id || !razorpay_payment_id) return res.status(400).json({ error: 'Missing payment details' });

    const isTestOrder = String(razorpay_order_id).startsWith('order_test_');
    if (!isTestOrder) {
      if (!process.env.RAZORPAY_KEY_SECRET) return res.status(500).json({ error: 'Razorpay secret missing on server' });
      const sigBody = razorpay_order_id + '|' + razorpay_payment_id;
      const expectedSig = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(sigBody).digest('hex');
      if (expectedSig !== razorpay_signature) return res.status(400).json({ error: 'Signature mismatch — payment verification failed' });
    }

    const item = await TestSeries.findById(req.params.id);
    if (!item) return res.status(404).json({ error: 'Series not found' });
    const itemType = 'series';

    const amount = item.discountPrice || item.price;
    const userObjId = new mongoose.Types.ObjectId(req.user.id);

    await User.collection.updateOne({ _id: userObjId }, { $addToSet: { enrolledBatches: item._id } });
    await TestSeries.findByIdAndUpdate(item._id, { $inc: { enrolledCount: 1 }, $addToSet: { students: userObjId } });

    const user = await User.collection.findOne({ _id: userObjId });
    const receiptNo = 'PR-' + Date.now().toString(36).toUpperCase();

    const payment = await BatchPayment.create({
      student: req.user.id,
      studentName: user?.name || 'Student',
      studentEmail: user?.email || '',
      itemId: item._id,
      itemType,
      itemName: item.name,
      examType: item.examType || '',
      amount,
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      testMode: isTestOrder,
      receiptNo
    });

    res.json({
      success: true,
      receipt: {
        receiptNo: payment.receiptNo,
        paymentId: payment._id,
        studentName: payment.studentName,
        studentEmail: payment.studentEmail,
        itemName: payment.itemName,
        examType: payment.examType,
        amount: payment.amount,
        razorpayPaymentId: payment.razorpayPaymentId,
        createdAt: payment.createdAt,
        testMode: payment.testMode
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/receipt/:paymentId/pdf — download official payment receipt PDF
router.get('/:id/receipt/:paymentId/pdf', auth, async (req, res) => {
  try {
    const payment = await BatchPayment.findById(req.params.paymentId).lean();
    if (!payment) return res.status(404).json({ error: 'Receipt not found' });
    if (String(payment.student) !== String(req.user.id)) return res.status(403).json({ error: 'Not authorized' });

    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=receipt_${payment.receiptNo}.pdf`);
    doc.pipe(res);

    const logoSize = 46;
    const pSize = Math.round(logoSize * 0.63);
    const rd = Math.round(pSize * 0.28);
    const cx = doc.page.width / 2;
    const startX = cx - logoSize / 2;
    const startY = 45;

    doc.roundedRect(startX, startY, pSize, pSize, rd).fill('#4D9FFF');
    doc.fillColor('#030810').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('P', startX, startY + pSize * 0.22, { width: pSize, align: 'center' });

    doc.roundedRect(startX + logoSize - pSize, startY + logoSize - pSize, pSize, pSize, rd).fillOpacity(0.85).fill('#00D4FF');
    doc.fillOpacity(1).fillColor('#00647A').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('R', startX + logoSize - pSize, startY + logoSize - pSize + pSize * 0.22, { width: pSize, align: 'center' });

    doc.y = startY + logoSize + 14;
    doc.fontSize(20).fillColor('#111').font('Helvetica-Bold').text('ProveRank', { align: 'center' });
    doc.fontSize(10).fillColor('#666').font('Helvetica').text('Online Test Platform', { align: 'center' });
    doc.moveDown(1.2);

    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(16).fillColor('#111').font('Helvetica-Bold').text('Payment Receipt', { align: 'center' });
    if (payment.testMode) { doc.moveDown(0.3); doc.fontSize(9).fillColor('#E67E22').font('Helvetica').text('(Test Mode — no real payment was charged)', { align: 'center' }); }
    doc.moveDown(1.5);

    let y = doc.y;
    const rowH = 22;
    const row = (label, value) => {
      doc.fontSize(11).fillColor('#666').font('Helvetica').text(label, 50, y);
      doc.fontSize(11).fillColor('#111').font('Helvetica-Bold').text(String(value), 300, y, { width: doc.page.width - 350, align: 'right' });
      y += rowH;
    };

    row('Receipt No.', payment.receiptNo);
    row('Date', new Date(payment.createdAt).toLocaleString('en-IN'));
    row('Student Name', payment.studentName);
    if (payment.studentEmail) row('Email', payment.studentEmail);
    row('Item Purchased', payment.itemName);
    if (payment.examType) row('Exam Type', payment.examType);
    row('Payment ID', payment.razorpayPaymentId);
    row('Order ID', payment.razorpayOrderId);

    doc.y = y + 10;
    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(14).fillColor('#111').font('Helvetica-Bold').text('Amount Paid', 50, doc.y);
    doc.fontSize(18).fillColor('#27AE60').font('Helvetica-Bold').text('₹' + payment.amount, 300, doc.y - 18, { width: doc.page.width - 350, align: 'right' });

    doc.moveDown(3);
    doc.fontSize(9).fillColor('#999').font('Helvetica').text('This is a system-generated receipt. For queries, contact ProveRank.support@gmail.com', { align: 'center' });
    doc.moveDown(0.4);
    doc.fontSize(9).fillColor('#999').text('ProveRank — Prove Yourself · Rise to the Top', { align: 'center' });

    doc.end();
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
