const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Coupon = require('../models/Coupon');
const ProductReview = require('../models/ProductReview');

// ── Inline Auth Middleware ───────────────────────
const jwt = require('jsonwebtoken');
const protectAdmin = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024');
    req.user = decoded;
    if (!['admin', 'superadmin'].includes(decoded.role)) {
      return res.status(403).json({ message: 'Admin access required' });
    }
    next();
  } catch (e) { return res.status(401).json({ message: 'Invalid token' }); }
};

// ══════════════════════════════════════════════════
// ANALYTICS
// ══════════════════════════════════════════════════
router.get('/analytics', protectAdmin, async (req, res) => {
  try {
    const [
      totalProducts, activeProducts, outOfStock, totalOrders,
      pendingOrders, deliveredOrders, cancelledOrders,
      totalRevenuePipeline, recentOrders, topProducts, ordersByStatus
    ] = await Promise.all([
      Product.countDocuments(),
      Product.countDocuments({ isActive: true, stock: { $gt: 0 } }),
      Product.countDocuments({ stock: 0 }),
      Order.countDocuments(),
      Order.countDocuments({ status: 'pending' }),
      Order.countDocuments({ status: 'delivered' }),
      Order.countDocuments({ status: 'cancelled' }),
      Order.aggregate([{ $match: { 'payment.status': 'paid' } }, { $group: { _id: null, total: { $sum: '$pricing.total' } } }]),
      Order.find().sort({ createdAt: -1 }).limit(10).populate('student', 'name email'),
      Order.aggregate([
        { $unwind: '$items' },
        { $group: { _id: '$items.product', totalSold: { $sum: '$items.quantity' }, revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } } } },
        { $sort: { totalSold: -1 } }, { $limit: 5 },
        { $lookup: { from: 'products', localField: '_id', foreignField: '_id', as: 'product' } },
        { $unwind: '$product' },
        { $project: { name: '$product.name', totalSold: 1, revenue: 1, image: { $arrayElemAt: ['$product.images.url', 0] } } }
      ]),
      Order.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ])
    ]);

    const revenue30d = await Order.aggregate([
      { $match: { createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }, 'payment.status': 'paid' } },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, revenue: { $sum: '$pricing.total' }, orders: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    const lowStockProducts = await Product.find({ stock: { $gt: 0, $lte: 10 }, isActive: true })
      .select('name stock lowStockThreshold sku').limit(10);

    res.json({
      overview: {
        totalProducts, activeProducts, outOfStock,
        totalOrders, pendingOrders, deliveredOrders, cancelledOrders,
        totalRevenue: totalRevenuePipeline[0]?.total || 0
      },
      recentOrders, topProducts, ordersByStatus, revenue30d, lowStockProducts
    });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// PRODUCTS CRUD
// ══════════════════════════════════════════════════
router.get('/products', protectAdmin, async (req, res) => {
  try {
    const { category, subject, isActive, search, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (category) filter.category = category;
    if (subject)  filter.subject = subject;
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (search) filter.$text = { $search: search };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [products, total] = await Promise.all([
      Product.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Product.countDocuments(filter)
    ]);
    res.json({ products, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)) });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/products', protectAdmin, async (req, res) => {
  try {
    const product = new Product(req.body);
    await product.save();
    res.status(201).json({ message: 'Product created', product });
  } catch (e) { res.status(400).json({ message: e.message }); }
});

router.get('/products/:id', protectAdmin, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ product });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/products/:id', protectAdmin, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    Object.assign(product, req.body);
    await product.save(); // triggers pre-save hook to recalculate discountPercent
    res.json({ message: 'Product updated', product });
  } catch (e) { res.status(400).json({ message: e.message }); }
});

router.delete('/products/:id', protectAdmin, async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Product deleted' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// Toggle active/featured/bestseller
router.patch('/products/:id/toggle', protectAdmin, async (req, res) => {
  try {
    const { field } = req.body;
    if (!['isActive','isFeatured','isNew','isBestSeller'].includes(field)) return res.status(400).json({ message: 'Invalid field' });
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    product[field] = !product[field];
    await product.save();
    res.json({ message: `${field} toggled`, product });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// Inventory update
router.patch('/products/:id/inventory', protectAdmin, async (req, res) => {
  try {
    const { stock, lowStockThreshold } = req.body;
    const product = await Product.findByIdAndUpdate(req.params.id, { stock, lowStockThreshold }, { new: true });
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Inventory updated', product });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// ORDERS MANAGEMENT
// ══════════════════════════════════════════════════
router.get('/orders', protectAdmin, async (req, res) => {
  try {
    const { status, paymentMethod, paymentStatus, search, page = 1, limit = 20, fromDate, toDate } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (paymentMethod) filter['payment.method'] = paymentMethod;
    if (paymentStatus) filter['payment.status'] = paymentStatus;
    if (fromDate || toDate) {
      filter.createdAt = {};
      if (fromDate) filter.createdAt.$gte = new Date(fromDate);
      if (toDate)   filter.createdAt.$lte = new Date(toDate);
    }
    if (search) filter.$or = [{ orderId: { $regex: search, $options: 'i' } }, { 'shippingAddress.fullName': { $regex: search, $options: 'i' } }, { 'shippingAddress.phone': { $regex: search, $options: 'i' } }];
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [orders, total] = await Promise.all([
      Order.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)).populate('student', 'name email phone'),
      Order.countDocuments(filter)
    ]);
    res.json({ orders, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)) });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/orders/:id', protectAdmin, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate('student', 'name email phone').populate('items.product', 'name images sku');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    res.json({ order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/orders/:id/status', protectAdmin, async (req, res) => {
  try {
    const { status, note, trackingNumber, trackingUrl, courierName, estimatedDelivery } = req.body;
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    order.status = status;
    order.statusHistory.push({ status, note: note || '', updatedBy: 'Admin' });
    if (trackingNumber) order.trackingNumber = trackingNumber;
    if (trackingUrl)    order.trackingUrl = trackingUrl;
    if (courierName)    order.courierName = courierName;
    if (estimatedDelivery) order.estimatedDelivery = new Date(estimatedDelivery);
    if (status === 'delivered') { order.deliveredAt = new Date(); order.payment.status = 'paid'; }
    if (status === 'cancelled') { order.cancelledAt = new Date(); }
    await order.save();
    res.json({ message: 'Order status updated', order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/orders/:id/payment', protectAdmin, async (req, res) => {
  try {
    const { paymentStatus, transactionId, refundAmount } = req.body;
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Order not found' });
    order.payment.status = paymentStatus;
    if (transactionId) order.payment.transactionId = transactionId;
    if (paymentStatus === 'paid')    order.payment.paidAt = new Date();
    if (paymentStatus === 'refunded') { order.payment.refundedAt = new Date(); order.payment.refundAmount = refundAmount; }
    await order.save();
    res.json({ message: 'Payment updated', order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/orders/:id/admin-notes', protectAdmin, async (req, res) => {
  try {
    const order = await Order.findByIdAndUpdate(req.params.id, { adminNotes: req.body.adminNotes }, { new: true });
    res.json({ message: 'Notes saved', order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// COUPONS MANAGEMENT
// ══════════════════════════════════════════════════
router.get('/coupons', protectAdmin, async (req, res) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.json({ coupons });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/coupons', protectAdmin, async (req, res) => {
  try {
    const coupon = new Coupon({ ...req.body, createdBy: req.user.id });
    await coupon.save();
    res.status(201).json({ message: 'Coupon created', coupon });
  } catch (e) { res.status(400).json({ message: e.message }); }
});

router.put('/coupons/:id', protectAdmin, async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!coupon) return res.status(404).json({ message: 'Coupon not found' });
    res.json({ message: 'Coupon updated', coupon });
  } catch (e) { res.status(400).json({ message: e.message }); }
});

router.delete('/coupons/:id', protectAdmin, async (req, res) => {
  try {
    await Coupon.findByIdAndDelete(req.params.id);
    res.json({ message: 'Coupon deleted' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.patch('/coupons/:id/toggle', protectAdmin, async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) return res.status(404).json({ message: 'Coupon not found' });
    coupon.isActive = !coupon.isActive;
    await coupon.save();
    res.json({ message: 'Coupon toggled', coupon });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// REVIEWS MANAGEMENT
// ══════════════════════════════════════════════════
router.get('/reviews', protectAdmin, async (req, res) => {
  try {
    const { productId, rating, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (productId) filter.product = productId;
    if (rating) filter.rating = parseInt(rating);
    const reviews = await ProductReview.find(filter).sort({ createdAt: -1 })
      .skip((parseInt(page)-1)*parseInt(limit)).limit(parseInt(limit))
      .populate('student', 'name email').populate('product', 'name');
    res.json({ reviews });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/reviews/:id/reply', protectAdmin, async (req, res) => {
  try {
    const review = await ProductReview.findByIdAndUpdate(req.params.id, { adminReply: req.body.reply, adminReplyAt: new Date() }, { new: true });
    res.json({ message: 'Reply added', review });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.delete('/reviews/:id', protectAdmin, async (req, res) => {
  try {
    await ProductReview.findByIdAndDelete(req.params.id);
    res.json({ message: 'Review deleted' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// INVENTORY VIEW
// ══════════════════════════════════════════════════
router.get('/inventory', protectAdmin, async (req, res) => {
  try {
    const products = await Product.find({}, 'name sku category subject stock sold lowStockThreshold isActive price').sort({ stock: 1 });
    const lowStock   = products.filter(p => p.stock <= p.lowStockThreshold && p.stock > 0);
    const outOfStock = products.filter(p => p.stock === 0);
    res.json({ products, lowStock, outOfStock, totalProducts: products.length });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// SEED INITIAL PRODUCTS (call once)
// ══════════════════════════════════════════════════
router.post('/seed', protectAdmin, async (req, res) => {
  try {
    const existing = await Product.countDocuments();
    if (existing > 0 && !req.body.force) {
      return res.json({ message: `${existing} products already exist. Send force:true to reseed.` });
    }
    const seedProducts = [
      {
        name: 'NCERT Biology Class 11',
        description: 'The official NCERT Biology textbook for Class 11 — covering Cell Biology, Plant Kingdom, Animal Kingdom, Structural Organisation in Plants & Animals, Cell Division, Biomolecules, and Photosynthesis. This is the primary reference book for NEET Biology preparation. All NEET questions are based directly on NCERT content.',
        shortDescription: 'Official NCERT Class 11 Biology — Primary NEET reference. Chapters: Cell Biology, Plant/Animal Kingdom, Photosynthesis, Biomolecules.',
        category: 'Books',
        subject: 'Biology',
        classLevel: 'Class 11',
        examType: 'NEET',
        images: [
          { url: 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400&h=500&fit=crop', alt: 'NCERT Biology Class 11', isPrimary: true },
          { url: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=500&fit=crop', alt: 'Biology Book Interior' }
        ],
        price: 199,
        originalPrice: 350,
        stock: 150,
        author: 'NCERT',
        publisher: 'National Council of Educational Research and Training',
        edition: '2024 Edition',
        language: 'English + Hindi',
        pages: 318,
        weight: 420,
        isbn: '978-81-7450-721-0',
        isFeatured: true,
        isBestSeller: true,
        deliveryCharge: 0,
        freeDeliveryAbove: 0,
        features: [
          'Official NCERT Textbook — Exact source for NEET questions',
          'Full colour diagrams with labels',
          'Chapter-end exercises with NCERT solutions',
          'Both English and Hindi versions available',
          'Covers complete Class 11 Biology syllabus',
          'Lightweight — 420g, easy to carry'
        ],
        specifications: [
          { key: 'Board', value: 'CBSE / State Boards (NCERT Pattern)' },
          { key: 'Class', value: 'Class 11' },
          { key: 'Subject', value: 'Biology' },
          { key: 'Pages', value: '318' },
          { key: 'Binding', value: 'Paperback' },
          { key: 'Publisher', value: 'NCERT' },
          { key: 'Language', value: 'English & Hindi' }
        ],
        tags: ['ncert', 'biology', 'class 11', 'neet', 'botany', 'zoology', 'cell biology', 'official textbook'],
        deliveryTime: '2-4 business days',
        returnPolicy: '7 days return — unused condition'
      },
      {
        name: 'NCERT Physics Class 11',
        description: 'The official NCERT Physics textbook for Class 11 — Part 1 & Part 2 combined. Covers Physical World, Units & Measurements, Laws of Motion, Work Energy & Power, Gravitation, Thermodynamics, Waves, and Oscillations. Essential for NEET Physics preparation — all concepts directly from NCERT form the basis of NEET questions.',
        shortDescription: 'Official NCERT Class 11 Physics (Part 1 & 2) — NEET Physics foundation. Mechanics, Thermodynamics, Waves & Oscillations.',
        category: 'Books',
        subject: 'Physics',
        classLevel: 'Class 11',
        examType: 'NEET',
        images: [
          { url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=500&fit=crop', alt: 'NCERT Physics Class 11', isPrimary: true },
          { url: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=500&fit=crop', alt: 'Physics Book Interior' }
        ],
        price: 185,
        originalPrice: 325,
        stock: 120,
        author: 'NCERT',
        publisher: 'National Council of Educational Research and Training',
        edition: '2024 Edition',
        language: 'English + Hindi',
        pages: 296,
        weight: 380,
        isbn: '978-81-7450-690-9',
        isFeatured: true,
        isBestSeller: false,
        isNew: true,
        deliveryCharge: 0,
        freeDeliveryAbove: 0,
        features: [
          'Official NCERT Textbook — Exact source for NEET Physics',
          'Includes Part 1 & Part 2 combined',
          'Detailed derivations with step-by-step proofs',
          'Chapter-wise solved examples + exercises',
          'SI units throughout — NEET standard',
          'Covers complete Class 11 Physics syllabus'
        ],
        specifications: [
          { key: 'Board', value: 'CBSE / State Boards (NCERT Pattern)' },
          { key: 'Class', value: 'Class 11' },
          { key: 'Subject', value: 'Physics' },
          { key: 'Includes', value: 'Part 1 + Part 2' },
          { key: 'Pages', value: '296' },
          { key: 'Binding', value: 'Paperback' },
          { key: 'Publisher', value: 'NCERT' }
        ],
        tags: ['ncert', 'physics', 'class 11', 'neet', 'mechanics', 'thermodynamics', 'waves', 'official textbook'],
        deliveryTime: '2-4 business days',
        returnPolicy: '7 days return — unused condition'
      }
    ];

    if (req.body.force) await Product.deleteMany({});
    const created = await Product.insertMany(seedProducts);
    res.status(201).json({ message: `${created.length} seed products created`, products: created });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

module.exports = router;
