#!/bin/bash
set -e
echo "🔧 Fix: Wishlist + Razorpay Backend"

# ─────────────────────────────────────────
# FIX 1: Wishlist — targeted line patch
# ─────────────────────────────────────────
echo "── Fix 1: Wishlist state + view ──"
node << 'WISHEOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/dashboard/store/page.tsx';
let c = fs.readFileSync(file, 'utf-8');

// Ensure wishlist state exists
if (!c.includes('const [wishlist, setWishlist]')) {
  // Add after const [wishlistIds line
  c = c.replace(
    /const \[wishlistIds, setWishlistIds\][^\n]+/,
    match => `const [wishlist, setWishlist] = useState<any[]>([]);\n  ${match}`
  );
  console.log('✅ wishlist state added');
}

// Ensure loadWish sets wishlist
if (!c.includes('setWishlist(prods)')) {
  c = c.replace(
    /const loadWish = \(\) =>.*?\.catch[^;]+;/s,
    `const loadWish = () => {
    if (!tok()) return;
    fetch(\`\${API}/api/store/wishlist\`, { headers: hdr() })
      .then(r => r.json())
      .then(d => {
        const prods = d.products || [];
        setWishIds(prods.map((p: any) => p._id));
        setWishlist(prods);
      })
      .catch(() => {});
  };`
  );
  console.log('✅ loadWish updated');
}

// Replace wishlist view — find and replace safely
const wishMarker = `{view === 'wishlist' && (`;
const wishIdx = c.indexOf(wishMarker);
if (wishIdx === -1) { console.log('❌ wishlist view not found'); process.exit(1); }

// Find the closing of this block
let pos = wishIdx + wishMarker.length;
let depth = 1; // we're inside the (
while (pos < c.length && depth > 0) {
  if (c[pos] === '(') depth++;
  else if (c[pos] === ')') depth--;
  pos++;
}
// pos is now after the closing )
// check for }
while (pos < c.length && (c[pos] === '}' || c[pos] === '\n' || c[pos] === ' ')) {
  if (c[pos] === '}') { pos++; break; }
  pos++;
}

const newWishlistView = `{view === 'wishlist' && (
          <div>
            <h2 style={{ fontSize:22, fontWeight:900, color:'#fff', marginBottom:20 }}>❤️ Wishlist</h2>
            {!wishlist || wishlist.length === 0
              ? <div style={{ ...S.card, padding:60, textAlign:'center' }}>
                  <p style={{ fontSize:48, marginBottom:12 }}>🤍</p>
                  <p style={{ color:'rgba(255,255,255,0.4)', fontSize:16, fontWeight:600, marginBottom:16 }}>Wishlist empty</p>
                  <p style={{ color:'rgba(255,255,255,0.25)', fontSize:13, marginBottom:20 }}>
                    Go to Store and tap ❤️ on any product
                  </p>
                  <button onClick={()=>setView('store')} style={S.btnP}>Browse Store</button>
                </div>
              : <div style={{ display:'grid', gridTemplateColumns:'repeat(2,1fr)', gap:12 }}>
                  {wishlist.map((p: any) => (
                    <PCard
                      key={p._id}
                      p={p}
                      onView={viewProduct}
                      onCart={addToCart}
                      onWish={toggleWish}
                      wished={wishIds.includes(p._id)}
                    />
                  ))}
                </div>
            }
          </div>
        )}`;

c = c.slice(0, wishIdx) + newWishlistView + c.slice(pos);
console.log('✅ Wishlist view replaced cleanly');

fs.writeFileSync(file, c);
console.log('✅ store/page.tsx saved');
WISHEOF

# ─────────────────────────────────────────
# FIX 2: Install Razorpay
# ─────────────────────────────────────────
echo ""
echo "── Fix 2: Install Razorpay ──"
cd ~/workspace
npm install razorpay --save
echo "✅ razorpay installed"

# ─────────────────────────────────────────
# FIX 3: Create payment.js route
# ─────────────────────────────────────────
echo ""
echo "── Fix 3: payment.js route ──"
cat > ~/workspace/src/routes/payment.js << 'PAYEOF'
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
  const deliveryCharge = subtotal >= maxFreeDelivery ? 0 : 49;
  const couponDiscount = cart.couponDiscount || 0;
  const total = Math.max(0, subtotal + deliveryCharge - couponDiscount);
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

    // 1. Verify signature
    const body             = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSig      = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    if (expectedSig !== razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Payment verification failed — invalid signature' });
    }

    // 2. Build order from cart
    const cartData = await calcCart(req.user.id);
    if (!cartData.items || cartData.items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }
    if (!shippingAddress?.fullName || !shippingAddress?.phone || !shippingAddress?.pincode) {
      return res.status(400).json({ message: 'Shipping address required' });
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
    console.error('Razorpay verify error:', e);
    res.status(500).json({ success: false, message: e.message });
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
PAYEOF
echo "✅ payment.js route created"

# ─────────────────────────────────────────
# FIX 4: Mount payment route in index.js
# ─────────────────────────────────────────
echo ""
echo "── Fix 4: Mount payment route ──"
node << 'IDXEOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/src/index.js';
let c = fs.readFileSync(file, 'utf-8');

if (c.includes('/api/store/payment')) {
  console.log('ℹ️  Payment route already mounted');
} else {
  // Add require near studentStore
  if (c.includes("require('./routes/studentStore')")) {
    c = c.replace(
      "require('./routes/studentStore');",
      "require('./routes/studentStore');\nconst paymentRoutes = require('./routes/payment');"
    );
  }
  // Add app.use near /api/store
  if (c.includes("app.use('/api/store'")) {
    c = c.replace(
      "app.use('/api/store'",
      "app.use('/api/store/payment', paymentRoutes);\napp.use('/api/store'"
    );
  }
  fs.writeFileSync(file, c);
  console.log('✅ Payment route mounted at /api/store/payment');
}
IDXEOF

# ─────────────────────────────────────────
# Git push
# ─────────────────────────────────────────
echo ""
cd ~/workspace
git add -A
git commit -m "feat: Razorpay payment gateway + fix wishlist display"
git push origin main
echo ""
echo "✅ PUSHED!"
echo ""
echo "══════════════════════════════════════════"
echo "📋 NEXT STEPS — Add ENV vars:"
echo ""
echo "1. RENDER (Backend) → Environment Variables:"
echo "   RAZORPAY_KEY_ID = rzp_live_XXXXXXXXX"
echo "   RAZORPAY_KEY_SECRET = XXXXXXXXXXXXXXXX"
echo ""
echo "2. VERCEL (Frontend) → Environment Variables:"
echo "   NEXT_PUBLIC_RAZORPAY_KEY_ID = rzp_live_XXXXXXXXX"
echo ""
echo "Razorpay Dashboard → Settings → API Keys"
echo "══════════════════════════════════════════"
