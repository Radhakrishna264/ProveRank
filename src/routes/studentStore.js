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
