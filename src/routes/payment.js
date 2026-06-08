const express  = require('express');
const router   = express.Router();
const Razorpay = require('razorpay');
const crypto   = require('crypto');
const jwt      = require('jsonwebtoken');
const Order    = require('../models/Order');
const Cart     = require('../models/Cart');
const Product  = require('../models/Product');
const Coupon   = require('../models/Coupon');

// ── Auth ───────────────────────────────────────
const protect = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024');
    req.user = decoded;
    next();
  } catch (e) { return res.status(401).json({ message: 'Invalid token' }); }
};

// ── Razorpay instance ──────────────────────────
const getRazorpay = () => new Razorpay({
  key_id:     process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Ensure JSON responses
// ── Utility: calc cart ─────────────────────────
const calcCart = async (studentId) => {
  const cart = await Cart.findOne({ student: studentId }).populate('items.product');
  if (!cart) return { items: [], subtotal: 0, deliveryCharge: 0, couponDiscount: 0, total: 0 };
  let subtotal = 0;
  const enrichedItems = cart.items.map(item => {
    if (!item.product || !item.product.isActive) return null;
    subtotal += item.product.price * item.quantity;
    return { product: item.product, quantity: item.quantity };
  }).filter(Boolean);
  const maxFreeDelivery = Math.max(...enrichedItems.map(i => i.product.freeDeliveryAbove || 499));
  const maxProductDelivery = enrichedItems.length > 0 ? Math.max(...enrichedItems.map(i => i.product.deliveryCharge ?? 49)) : 49;
  const deliveryCharge = subtotal >= maxFreeDelivery ? 0 : maxProductDelivery;
  const couponDiscount = Math.min(cart.couponDiscount || 0, subtotal + deliveryCharge - 1); // min ₹1
  const total = Math.max(1, subtotal + deliveryCharge - couponDiscount); // min ₹1 for Razorpay
  return { items: enrichedItems, subtotal, deliveryCharge, couponDiscount, couponCode: cart.couponCode, total };
};

// ══════════════════════════════════════════════
// POST /api/store/payment/create-order
// Creates a Razorpay order for checkout
// ══════════════════════════════════════════════
router.post('/create-order', protect, async (req, res) => {
  try {
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.status(500).json({ message: 'Razorpay not configured. Add RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET env vars.' });
    }

    const cartData = await calcCart(req.user.id);
    if (!cartData.items || cartData.items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }

    const razorpay = getRazorpay();
    const receipt  = 'rcpt_' + req.user.id.toString().slice(-6) + '_' + Date.now();

    const rzpOrder = await razorpay.orders.create({
      amount:   Math.round(cartData.total * 100), // paise
      currency: 'INR',
      receipt,
    });

    res.json({
      success:   true,
      order_id:  rzpOrder.id,
      amount:    rzpOrder.amount,
      currency:  rzpOrder.currency,
      key:       process.env.RAZORPAY_KEY_ID,
      cart_total: cartData.total,
    });
  } catch (e) {
    console.error('Razorpay create-order error:', e);
    res.status(500).json({ message: e.message || 'Payment initiation failed' });
  }
});

// ══════════════════════════════════════════════
// POST /api/store/payment/verify
// Verifies Razorpay signature + creates order
// ══════════════════════════════════════════════
router.post('/verify', protect, async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      shippingAddress,
      buyerNotes,
    } = req.body;

    // 2. Build order from cart
    const cartData = await calcCart(req.user.id);
    if (!cartData.items || cartData.items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }
    if (!shippingAddress?.fullName || !shippingAddress?.phone || !shippingAddress?.pincode) {
      return res.status(400).json({ message: 'Shipping address required' });
    }

      // 1. FIXED: free order bypass — signature skipped for ₹0
  if (cartData.total > 0) {
    if (!process.env.RAZORPAY_KEY_SECRET) {
      console.error('RAZORPAY_KEY_SECRET missing from environment!');
      return res.status(500).json({
        success: false,
        message: 'Payment config error. Contact support with Payment ID: ' + razorpay_payment_id
      });
    }
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSig = require('crypto')
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body).digest('hex');
    if (expectedSig !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Payment verification failed – invalid signature' });
    }
  }

  // 3. Check stock
    for (const item of cartData.items) {
      if (item.product.stock < item.quantity) {
        return res.status(400).json({ message: `Insufficient stock for ${item.product.name}` });
      }
    }

    const orderItems = cartData.items.map(item => ({
      product:       item.product._id,
      name:          item.product.name,
      image:         item.product.images?.[0]?.url || '',
      sku:           item.product.sku,
      quantity:      item.quantity,
      price:         item.product.price,
      originalPrice: item.product.originalPrice,
      discount:      item.product.originalPrice - item.product.price,
    }));

    // 4. Create order in DB
    const order = new Order({
      student: req.user.id,
      items:   orderItems,
      shippingAddress,
      payment: {
        method:        'UPI',
        status:        'paid',
        transactionId: razorpay_payment_id,
        gatewayRef:    razorpay_order_id,
        paidAt:        new Date(),
      },
      pricing: {
        subtotal:       cartData.subtotal,
        deliveryCharge: cartData.deliveryCharge,
        couponDiscount: cartData.couponDiscount,
        totalDiscount:  cartData.items.reduce((s, i) => s + (i.product.originalPrice - i.product.price) * i.quantity, 0) + cartData.couponDiscount,
        total:          cartData.total,
      },
      couponCode:        cartData.couponCode,
      buyerNotes,
      estimatedDelivery: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      status:            'confirmed', // auto-confirm for online payment
    });
    order.statusHistory.push({ status: 'confirmed', note: 'Payment received via Razorpay', updatedBy: 'System' });
    await order.save();

    // 5. Deduct stock
    for (const item of cartData.items) {
      await Product.findByIdAndUpdate(item.product._id, {
        $inc: { stock: -item.quantity, sold: item.quantity }
      });
    }

    // 6. Mark coupon used
    if (cartData.couponCode) {
      await Coupon.findOneAndUpdate(
        { code: cartData.couponCode },
        { $inc: { usedCount: 1 }, $push: { usedBy: req.user.id } }
      );
    }

    // 7. Clear cart
    await Cart.findOneAndDelete({ student: req.user.id });

    res.json({
      success: true,
      message: 'Payment verified & order placed!',
      orderId: order.orderId,
      order,
    });
  } catch (e) {
    console.error('Razorpay verify error:', e.message, e.stack);
    res.status(500).json({ success: false, message: 'Server error: ' + (e.message || 'Unknown') });
  }
});

// ══════════════════════════════════════════════
// GET /api/store/payment/config
// Returns Razorpay key for frontend
// ══════════════════════════════════════════════
router.get('/config', protect, (req, res) => {
  res.json({
    key: process.env.RAZORPAY_KEY_ID || '',
    configured: !!(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET),
  });
});

module.exports = router;
