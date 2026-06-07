#!/bin/bash
set -e
BASE=~/workspace
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏪  ProveRank Store — BACKEND SETUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─────────────────────────────────────────
# MODEL 1: Product.js
# ─────────────────────────────────────────
cat > $BASE/src/models/Product.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const specSchema = new mongoose.Schema({ key: String, value: String }, { _id: false });
const imageSchema = new mongoose.Schema({ url: String, alt: String, isPrimary: { type: Boolean, default: false } }, { _id: false });

const productSchema = new mongoose.Schema({
  name:             { type: String, required: true, trim: true },
  slug:             { type: String, unique: true, sparse: true },
  description:      { type: String, required: true },
  shortDescription: String,
  category: {
    type: String,
    enum: ['Books', 'Notes', 'Stationery', 'Lab Equipment', 'Combo Pack', 'Digital', 'Other'],
    required: true
  },
  subject: {
    type: String,
    enum: ['Physics', 'Chemistry', 'Biology', 'Mathematics', 'All Subjects', 'Other'],
    default: 'All Subjects'
  },
  classLevel: { type: String, enum: ['Class 11', 'Class 12', 'Both', 'All'], default: 'All' },
  examType:   { type: String, enum: ['NEET', 'JEE', 'Both', 'All'], default: 'All' },
  images:     [imageSchema],
  price:          { type: Number, required: true, min: 0 },
  originalPrice:  { type: Number, required: true, min: 0 },
  discountPercent:{ type: Number, default: 0 },
  stock:              { type: Number, default: 0, min: 0 },
  lowStockThreshold:  { type: Number, default: 10 },
  sold:               { type: Number, default: 0 },
  sku:    { type: String, unique: true, sparse: true },
  isbn:   String,
  author: String,
  publisher: String,
  edition:   String,
  language:  { type: String, default: 'English' },
  pages:   Number,
  weight:  Number,
  dimensions: { length: Number, width: Number, height: Number },
  ratings: { average: { type: Number, default: 0 }, count: { type: Number, default: 0 } },
  tags:           [String],
  features:       [String],
  specifications: [specSchema],
  isActive:     { type: Boolean, default: true },
  isFeatured:   { type: Boolean, default: false },
  isNew:        { type: Boolean, default: true },
  isBestSeller: { type: Boolean, default: false },
  deliveryTime:       { type: String, default: '3-5 business days' },
  returnPolicy:       { type: String, default: '7 days return policy' },
  deliveryCharge:     { type: Number, default: 49 },
  freeDeliveryAbove:  { type: Number, default: 499 },
  relatedProducts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }]
}, { timestamps: true });

productSchema.pre('save', function (next) {
  if (!this.slug) {
    this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') + '-' + Date.now();
  }
  if (!this.sku) {
    this.sku = 'PRK-' + Math.random().toString(36).substring(2, 8).toUpperCase();
  }
  if (this.originalPrice && this.price) {
    this.discountPercent = Math.round(((this.originalPrice - this.price) / this.originalPrice) * 100);
  }
  next();
});

productSchema.index({ name: 'text', description: 'text', tags: 'text', author: 'text', publisher: 'text' });
productSchema.index({ category: 1, subject: 1, isActive: 1 });
productSchema.index({ isFeatured: 1, isBestSeller: 1 });

module.exports = mongoose.model('Product', productSchema);
ENDOFFILE
echo "✅ Product model created"

# ─────────────────────────────────────────
# MODEL 2: Order.js
# ─────────────────────────────────────────
cat > $BASE/src/models/Order.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  product:       { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
  name:          String,
  image:         String,
  sku:           String,
  quantity:      { type: Number, min: 1, default: 1 },
  price:         Number,
  originalPrice: Number,
  discount:      Number
}, { _id: false });

const addressSchema = new mongoose.Schema({
  fullName:    String,
  phone:       String,
  addressLine1: String,
  addressLine2: String,
  city:        String,
  state:       String,
  pincode:     String,
  country:     { type: String, default: 'India' },
  landmark:    String
}, { _id: false });

const statusHistorySchema = new mongoose.Schema({
  status:    String,
  note:      String,
  updatedBy: String,
  timestamp: { type: Date, default: Date.now }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderId:  { type: String, unique: true },
  student:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  items:    [orderItemSchema],
  shippingAddress: addressSchema,
  payment: {
    method:        { type: String, enum: ['COD', 'UPI', 'Card', 'NetBanking', 'Wallet'], default: 'COD' },
    status:        { type: String, enum: ['pending', 'paid', 'failed', 'refunded'], default: 'pending' },
    transactionId: String,
    upiId:         String,
    paidAt:        Date,
    refundedAt:    Date,
    refundAmount:  Number,
    gatewayRef:    String
  },
  pricing: {
    subtotal:       { type: Number, default: 0 },
    deliveryCharge: { type: Number, default: 0 },
    couponDiscount: { type: Number, default: 0 },
    totalDiscount:  { type: Number, default: 0 },
    total:          { type: Number, default: 0 }
  },
  couponCode:    String,
  status: {
    type: String,
    enum: ['pending','confirmed','packed','shipped','out_for_delivery','delivered','cancelled','return_requested','returned','refunded'],
    default: 'pending'
  },
  statusHistory:     [statusHistorySchema],
  trackingNumber:    String,
  trackingUrl:       String,
  courierName:       String,
  estimatedDelivery: Date,
  deliveredAt:       Date,
  cancelledAt:       Date,
  cancellationReason: String,
  returnReason:      String,
  buyerNotes:        String,
  adminNotes:        String,
  invoiceNumber:     String
}, { timestamps: true });

orderSchema.pre('save', async function (next) {
  if (!this.orderId) {
    const count = await mongoose.model('Order').countDocuments();
    const rand = Math.random().toString(36).substring(2, 5).toUpperCase();
    this.orderId = 'PRO-' + String(count + 1001).padStart(6, '0') + rand;
  }
  if (!this.invoiceNumber) {
    const d = new Date();
    this.invoiceNumber = 'INV-' + d.getFullYear() + String(d.getMonth()+1).padStart(2,'0') + '-' + this.orderId;
  }
  next();
});

orderSchema.index({ student: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
ENDOFFILE
echo "✅ Order model created"

# ─────────────────────────────────────────
# MODEL 3: Cart.js
# ─────────────────────────────────────────
cat > $BASE/src/models/Cart.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  items: [{
    product:  { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    quantity: { type: Number, default: 1, min: 1, max: 20 }
  }],
  couponCode:     String,
  couponDiscount: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Cart', cartSchema);
ENDOFFILE
echo "✅ Cart model created"

# ─────────────────────────────────────────
# MODEL 4: Coupon.js
# ─────────────────────────────────────────
cat > $BASE/src/models/Coupon.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code:        { type: String, required: true, unique: true, uppercase: true, trim: true },
  description: String,
  type:        { type: String, enum: ['percent', 'flat'], required: true },
  value:       { type: Number, required: true, min: 0 },
  minOrderValue: { type: Number, default: 0 },
  maxDiscount:   Number,
  validFrom:   Date,
  validTill:   Date,
  usageLimit:  { type: Number, default: 100 },
  usedCount:   { type: Number, default: 0 },
  usedBy:      [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  isActive:    { type: Boolean, default: true },
  applicableCategories: [String],
  applicableSubjects:   [String],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Coupon', couponSchema);
ENDOFFILE
echo "✅ Coupon model created"

# ─────────────────────────────────────────
# MODEL 5: ProductReview.js
# ─────────────────────────────────────────
cat > $BASE/src/models/ProductReview.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  product:  { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
  student:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  order:    { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  rating:   { type: Number, required: true, min: 1, max: 5 },
  title:    String,
  body:     String,
  images:   [String],
  isVerifiedPurchase: { type: Boolean, default: false },
  helpful:  [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  adminReply:   String,
  adminReplyAt: Date,
  isVisible: { type: Boolean, default: true }
}, { timestamps: true });

reviewSchema.index({ product: 1, createdAt: -1 });

module.exports = mongoose.model('ProductReview', reviewSchema);
ENDOFFILE
echo "✅ ProductReview model created"

# ─────────────────────────────────────────
# MODEL 6: Wishlist.js
# ─────────────────────────────────────────
cat > $BASE/src/models/Wishlist.js << 'ENDOFFILE'
const mongoose = require('mongoose');

const wishlistSchema = new mongoose.Schema({
  student:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  products: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }]
}, { timestamps: true });

module.exports = mongoose.model('Wishlist', wishlistSchema);
ENDOFFILE
echo "✅ Wishlist model created"

# ─────────────────────────────────────────
# ROUTE 1: Admin Store Routes
# ─────────────────────────────────────────
cat > $BASE/src/routes/adminStore.js << 'ENDOFFILE'
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
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!product) return res.status(404).json({ message: 'Product not found' });
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
ENDOFFILE
echo "✅ Admin Store routes created"

# ─────────────────────────────────────────
# ROUTE 2: Student Store Routes
# ─────────────────────────────────────────
cat > $BASE/src/routes/studentStore.js << 'ENDOFFILE'
const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Coupon = require('../models/Coupon');
const ProductReview = require('../models/ProductReview');
const Wishlist = require('../models/Wishlist');
const jwt = require('jsonwebtoken');

// ── Auth Middleware ──────────────────────────────
const protect = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024');
    req.user = decoded;
    next();
  } catch (e) { return res.status(401).json({ message: 'Invalid token' }); }
};

// ── Utility: Recalculate Cart ────────────────────
const calcCart = async (studentId) => {
  const cart = await Cart.findOne({ student: studentId }).populate('items.product');
  if (!cart) return { items: [], subtotal: 0, deliveryCharge: 0, couponDiscount: 0, total: 0, itemCount: 0 };
  let subtotal = 0, deliveryCharge = 0, itemCount = 0;
  const enrichedItems = cart.items.map(item => {
    if (!item.product || !item.product.isActive) return null;
    const lineTotal = item.product.price * item.quantity;
    subtotal += lineTotal;
    itemCount += item.quantity;
    return { product: item.product, quantity: item.quantity, lineTotal };
  }).filter(Boolean);
  const maxFreeDelivery = Math.max(...(enrichedItems.map(i => i.product.freeDeliveryAbove || 499)));
  deliveryCharge = subtotal >= maxFreeDelivery ? 0 : 49;
  const couponDiscount = cart.couponDiscount || 0;
  const total = Math.max(0, subtotal + deliveryCharge - couponDiscount);
  return { items: enrichedItems, subtotal, deliveryCharge, couponDiscount, couponCode: cart.couponCode, total, itemCount };
};

// ══════════════════════════════════════════════════
// PRODUCTS (PUBLIC — no auth needed)
// ══════════════════════════════════════════════════
router.get('/products', async (req, res) => {
  try {
    const { category, subject, classLevel, examType, minPrice, maxPrice, search, sort = 'createdAt', page = 1, limit = 12, featured, bestseller } = req.query;
    const filter = { isActive: true, stock: { $gte: 0 } };
    if (category)   filter.category = category;
    if (subject)    filter.subject = subject;
    if (classLevel) filter.classLevel = classLevel;
    if (examType)   filter.examType = examType;
    if (featured === 'true')    filter.isFeatured = true;
    if (bestseller === 'true')  filter.isBestSeller = true;
    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = parseFloat(minPrice);
      if (maxPrice) filter.price.$lte = parseFloat(maxPrice);
    }
    if (search) filter.$text = { $search: search };
    const sortMap = { price_asc: { price: 1 }, price_desc: { price: -1 }, rating: { 'ratings.average': -1 }, newest: { createdAt: -1 }, popular: { sold: -1 } };
    const sortObj = sortMap[sort] || { createdAt: -1 };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [products, total] = await Promise.all([
      Product.find(filter).sort(sortObj).skip(skip).limit(parseInt(limit)).select('-relatedProducts'),
      Product.countDocuments(filter)
    ]);
    res.json({ products, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)) });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/products/featured', async (req, res) => {
  try {
    const products = await Product.find({ isActive: true, isFeatured: true }).limit(6);
    res.json({ products });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/products/bestsellers', async (req, res) => {
  try {
    const products = await Product.find({ isActive: true, isBestSeller: true }).limit(6);
    res.json({ products });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/products/:id', async (req, res) => {
  try {
    const product = await Product.findOne({ _id: req.params.id, isActive: true }).populate('relatedProducts', 'name price originalPrice images ratings');
    if (!product) return res.status(404).json({ message: 'Product not found' });
    const reviews = await ProductReview.find({ product: product._id, isVisible: true }).sort({ createdAt: -1 }).limit(10).populate('student', 'name');
    res.json({ product, reviews });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// CART (auth required)
// ══════════════════════════════════════════════════
router.get('/cart', protect, async (req, res) => {
  try {
    const cartData = await calcCart(req.user.id);
    res.json(cartData);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/cart/add', protect, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;
    const product = await Product.findById(productId);
    if (!product || !product.isActive) return res.status(404).json({ message: 'Product not available' });
    if (product.stock < 1) return res.status(400).json({ message: 'Out of stock' });
    let cart = await Cart.findOne({ student: req.user.id });
    if (!cart) cart = new Cart({ student: req.user.id, items: [] });
    const existingIdx = cart.items.findIndex(i => i.product.toString() === productId);
    if (existingIdx > -1) {
      const newQty = cart.items[existingIdx].quantity + parseInt(quantity);
      if (newQty > product.stock) return res.status(400).json({ message: `Only ${product.stock} units available` });
      cart.items[existingIdx].quantity = Math.min(newQty, 20);
    } else {
      if (quantity > product.stock) return res.status(400).json({ message: `Only ${product.stock} units available` });
      cart.items.push({ product: productId, quantity: parseInt(quantity) });
    }
    await cart.save();
    const cartData = await calcCart(req.user.id);
    res.json({ message: 'Added to cart', cart: cartData });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.put('/cart/update', protect, async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const cart = await Cart.findOne({ student: req.user.id });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });
    const item = cart.items.find(i => i.product.toString() === productId);
    if (!item) return res.status(404).json({ message: 'Item not in cart' });
    if (quantity <= 0) {
      cart.items = cart.items.filter(i => i.product.toString() !== productId);
    } else {
      item.quantity = Math.min(parseInt(quantity), 20);
    }
    await cart.save();
    const cartData = await calcCart(req.user.id);
    res.json({ message: 'Cart updated', cart: cartData });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.delete('/cart/remove/:productId', protect, async (req, res) => {
  try {
    const cart = await Cart.findOne({ student: req.user.id });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });
    cart.items = cart.items.filter(i => i.product.toString() !== req.params.productId);
    await cart.save();
    const cartData = await calcCart(req.user.id);
    res.json({ message: 'Item removed', cart: cartData });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.delete('/cart/clear', protect, async (req, res) => {
  try {
    await Cart.findOneAndDelete({ student: req.user.id });
    res.json({ message: 'Cart cleared' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// COUPON
// ══════════════════════════════════════════════════
router.post('/coupon/apply', protect, async (req, res) => {
  try {
    const { couponCode } = req.body;
    const coupon = await Coupon.findOne({ code: couponCode.toUpperCase(), isActive: true });
    if (!coupon) return res.status(404).json({ message: 'Invalid coupon code' });
    const now = new Date();
    if (coupon.validFrom && now < coupon.validFrom) return res.status(400).json({ message: 'Coupon not yet active' });
    if (coupon.validTill && now > coupon.validTill) return res.status(400).json({ message: 'Coupon has expired' });
    if (coupon.usedCount >= coupon.usageLimit) return res.status(400).json({ message: 'Coupon usage limit reached' });
    if (coupon.usedBy.includes(req.user.id)) return res.status(400).json({ message: 'You have already used this coupon' });
    const cartData = await calcCart(req.user.id);
    if (cartData.subtotal < coupon.minOrderValue) return res.status(400).json({ message: `Minimum order ₹${coupon.minOrderValue} required` });
    let discount = coupon.type === 'percent' ? (cartData.subtotal * coupon.value / 100) : coupon.value;
    if (coupon.maxDiscount) discount = Math.min(discount, coupon.maxDiscount);
    const cart = await Cart.findOne({ student: req.user.id });
    if (cart) { cart.couponCode = coupon.code; cart.couponDiscount = discount; await cart.save(); }
    res.json({ message: `Coupon applied! ₹${discount} saved`, discount, couponCode: coupon.code });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/coupon/remove', protect, async (req, res) => {
  try {
    const cart = await Cart.findOne({ student: req.user.id });
    if (cart) { cart.couponCode = undefined; cart.couponDiscount = 0; await cart.save(); }
    res.json({ message: 'Coupon removed' });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// WISHLIST
// ══════════════════════════════════════════════════
router.get('/wishlist', protect, async (req, res) => {
  try {
    const wishlist = await Wishlist.findOne({ student: req.user.id }).populate('products', 'name price originalPrice images ratings stock isActive');
    res.json({ products: wishlist?.products || [] });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/wishlist/toggle/:productId', protect, async (req, res) => {
  try {
    let wishlist = await Wishlist.findOne({ student: req.user.id });
    if (!wishlist) wishlist = new Wishlist({ student: req.user.id, products: [] });
    const idx = wishlist.products.findIndex(p => p.toString() === req.params.productId);
    let added = false;
    if (idx > -1) { wishlist.products.splice(idx, 1); }
    else { wishlist.products.push(req.params.productId); added = true; }
    await wishlist.save();
    res.json({ message: added ? 'Added to wishlist' : 'Removed from wishlist', added });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// ORDERS
// ══════════════════════════════════════════════════
router.post('/orders/create', protect, async (req, res) => {
  try {
    const { shippingAddress, paymentMethod, buyerNotes } = req.body;
    const cartData = await calcCart(req.user.id);
    if (!cartData.items || cartData.items.length === 0) return res.status(400).json({ message: 'Cart is empty' });
    if (!shippingAddress?.fullName || !shippingAddress?.phone || !shippingAddress?.addressLine1 || !shippingAddress?.pincode) {
      return res.status(400).json({ message: 'Complete shipping address required' });
    }
    if (!shippingAddress.phone.match(/^[6-9]\d{9}$/)) return res.status(400).json({ message: 'Invalid phone number' });

    // Validate stock for all items
    for (const item of cartData.items) {
      if (item.product.stock < item.quantity) {
        return res.status(400).json({ message: `Insufficient stock for ${item.product.name}` });
      }
    }

    const orderItems = cartData.items.map(item => ({
      product: item.product._id,
      name: item.product.name,
      image: item.product.images?.[0]?.url || '',
      sku: item.product.sku,
      quantity: item.quantity,
      price: item.product.price,
      originalPrice: item.product.originalPrice,
      discount: item.product.originalPrice - item.product.price
    }));

    const order = new Order({
      student: req.user.id,
      items: orderItems,
      shippingAddress,
      payment: { method: paymentMethod || 'COD', status: 'pending' },
      pricing: {
        subtotal: cartData.subtotal,
        deliveryCharge: cartData.deliveryCharge,
        couponDiscount: cartData.couponDiscount,
        totalDiscount: cartData.items.reduce((s, i) => s + (i.product.originalPrice - i.product.price) * i.quantity, 0) + cartData.couponDiscount,
        total: cartData.total
      },
      couponCode: cartData.couponCode,
      buyerNotes,
      estimatedDelivery: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
    });
    order.statusHistory.push({ status: 'pending', note: 'Order placed', updatedBy: 'System' });
    await order.save();

    // Deduct stock
    for (const item of cartData.items) {
      await Product.findByIdAndUpdate(item.product._id, { $inc: { stock: -item.quantity, sold: item.quantity } });
    }

    // Mark coupon used
    if (cartData.couponCode) {
      await Coupon.findOneAndUpdate({ code: cartData.couponCode }, { $inc: { usedCount: 1 }, $push: { usedBy: req.user.id } });
    }

    // Clear cart
    await Cart.findOneAndDelete({ student: req.user.id });

    res.status(201).json({ message: 'Order placed successfully!', order, orderId: order.orderId });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/orders', protect, async (req, res) => {
  try {
    const orders = await Order.find({ student: req.user.id }).sort({ createdAt: -1 });
    res.json({ orders });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/orders/:id', protect, async (req, res) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, student: req.user.id });
    if (!order) return res.status(404).json({ message: 'Order not found' });
    res.json({ order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.post('/orders/:id/cancel', protect, async (req, res) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, student: req.user.id });
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (!['pending','confirmed'].includes(order.status)) return res.status(400).json({ message: 'Order cannot be cancelled at this stage' });
    order.status = 'cancelled';
    order.cancelledAt = new Date();
    order.cancellationReason = req.body.reason || 'Cancelled by student';
    order.statusHistory.push({ status: 'cancelled', note: order.cancellationReason, updatedBy: 'Student' });
    await order.save();
    // Restore stock
    for (const item of order.items) {
      await Product.findByIdAndUpdate(item.product, { $inc: { stock: item.quantity, sold: -item.quantity } });
    }
    res.json({ message: 'Order cancelled', order });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ══════════════════════════════════════════════════
// REVIEWS
// ══════════════════════════════════════════════════
router.post('/products/:id/review', protect, async (req, res) => {
  try {
    const { rating, title, body } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ message: 'Rating must be 1-5' });
    const existingReview = await ProductReview.findOne({ product: req.params.id, student: req.user.id });
    if (existingReview) return res.status(400).json({ message: 'You have already reviewed this product' });
    const verifiedOrder = await Order.findOne({ student: req.user.id, 'items.product': req.params.id, status: 'delivered' });
    const review = new ProductReview({
      product: req.params.id, student: req.user.id,
      rating: parseInt(rating), title, body,
      isVerifiedPurchase: !!verifiedOrder
    });
    await review.save();
    // Update product ratings
    const stats = await ProductReview.aggregate([
      { $match: { product: review.product, isVisible: true } },
      { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } }
    ]);
    if (stats.length) {
      await Product.findByIdAndUpdate(req.params.id, { 'ratings.average': Math.round(stats[0].avg * 10) / 10, 'ratings.count': stats[0].count });
    }
    res.status(201).json({ message: 'Review submitted', review });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

router.get('/products/:id/reviews', async (req, res) => {
  try {
    const reviews = await ProductReview.find({ product: req.params.id, isVisible: true }).sort({ createdAt: -1 }).populate('student', 'name');
    const stats = await ProductReview.aggregate([
      { $match: { product: require('mongoose').Types.ObjectId(req.params.id), isVisible: true } },
      { $group: { _id: '$rating', count: { $sum: 1 } } }
    ]);
    res.json({ reviews, stats });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

module.exports = router;
ENDOFFILE
echo "✅ Student Store routes created"

# ─────────────────────────────────────────
# PATCH index.js — mount store routes
# ─────────────────────────────────────────
node << 'ENDOFFILE'
const fs   = require('fs');
const path = require('path');
const file = path.join(process.env.HOME, 'workspace/src/index.js');
let content = fs.readFileSync(file, 'utf-8');

const adminStoreImport  = "const adminStoreRoutes   = require('./routes/adminStore');";
const studentStoreImport= "const studentStoreRoutes = require('./routes/studentStore');";
const adminStoreMount   = "app.use('/api/admin/store',  adminStoreRoutes);";
const studentStoreMount = "app.use('/api/store',         studentStoreRoutes);";

let changed = false;

if (!content.includes('adminStore')) {
  // Add imports after last require
  const lastRequire = content.lastIndexOf("require('./routes/");
  const endOfLine   = content.indexOf('\n', lastRequire);
  content = content.slice(0, endOfLine+1) + adminStoreImport + '\n' + studentStoreImport + '\n' + content.slice(endOfLine+1);
  changed = true;
}

if (!content.includes('/api/admin/store')) {
  // Add mounts before module.exports or after last app.use
  const lastUse  = content.lastIndexOf("app.use('/api/");
  const endOfLine= content.indexOf('\n', lastUse);
  content = content.slice(0, endOfLine+1) + adminStoreMount + '\n' + studentStoreMount + '\n' + content.slice(endOfLine+1);
  changed = true;
}

if (changed) {
  fs.writeFileSync(file, content);
  console.log('✅ index.js patched — store routes mounted');
} else {
  console.log('ℹ️  index.js already has store routes');
}
ENDOFFILE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅  BACKEND SETUP COMPLETE!"
echo ""
echo "📦 Models Created: Product, Order, Cart, Coupon,"
echo "                   ProductReview, Wishlist"
echo "🔌 Routes Mounted:"
echo "   Admin : /api/admin/store/*"
echo "   Student: /api/store/*"
echo ""
echo "🌱 To seed 2 NCERT books, call this API after login:"
echo "   POST /api/admin/store/seed"
echo "   (with SuperAdmin token in Authorization header)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
