#!/bin/bash
# ProveRank — Payment Cart Empty Fix
# Cart snapshot save in create-order, use in verify
# No Python used

PAYMENT_FILE="$HOME/workspace/src/routes/payment.js"
BACKUP_FILE="$HOME/workspace/src/routes/payment.js.bak_$(date +%Y%m%d_%H%M%S)"

echo "=== ProveRank Payment Fix ==="
echo "Backup: $BACKUP_FILE"
cp "$PAYMENT_FILE" "$BACKUP_FILE"
echo "Backup done ✅"

# ---- Step 1: Add PendingPayment model inline at top of payment.js ----
# Check if already patched
if grep -q "PendingPayment" "$PAYMENT_FILE"; then
  echo "Already patched — skipping model injection"
else
  # Inject PendingPayment schema after the first require block
  node << 'NODEOF'
const fs = require('fs');
const path = process.env.HOME + '/workspace/src/routes/payment.js';
let code = fs.readFileSync(path, 'utf8');

// Find the last require line at the top
const requireBlock = `const mongoose = require('mongoose');

// PendingPayment — cart snapshot before Razorpay payment
const pendingPaymentSchema = new mongoose.Schema({
  razorpayOrderId: { type: String, required: true, unique: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  cartSnapshot: { type: Object, required: true },
  shippingAddress: { type: Object, required: true },
  buyerNotes: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now, expires: 3600 } // auto-delete after 1 hour
});
const PendingPayment = mongoose.model('PendingPayment', pendingPaymentSchema);

`;

// Insert after the first block of requires (before first router.get/post)
const insertPoint = code.indexOf('\nrouter.');
if (insertPoint === -1) {
  console.error('Could not find router. in payment.js');
  process.exit(1);
}

code = code.slice(0, insertPoint) + '\n' + requireBlock + code.slice(insertPoint);
fs.writeFileSync(path, code, 'utf8');
console.log('PendingPayment model injected ✅');
NODEOF
fi

# ---- Step 2: Patch create-order route to save cart snapshot ----
if grep -q "await PendingPayment" "$PAYMENT_FILE"; then
  echo "create-order already patched — skipping"
else
  node << 'NODEOF'
const fs = require('fs');
const path = process.env.HOME + '/workspace/src/routes/payment.js';
let code = fs.readFileSync(path, 'utf8');

// Find the create-order route and add snapshot save after razorpay.orders.create
// Look for the pattern where razorpayOrder is created and returned
const OLD = `  res.json({
    success: true,
    razorpay_order_id: razorpayOrder.id,`;

const NEW = `  // Save cart snapshot so verify works even after page redirect
  try {
    await PendingPayment.findOneAndDelete({ razorpayOrderId: razorpayOrder.id });
    await PendingPayment.create({
      razorpayOrderId: razorpayOrder.id,
      userId: req.user.id,
      cartSnapshot: cartData,
      shippingAddress: shippingAddress || {},
      buyerNotes: buyerNotes || ''
    });
  } catch(snapErr) {
    console.error('Snapshot save error (non-fatal):', snapErr.message);
  }

  res.json({
    success: true,
    razorpay_order_id: razorpayOrder.id,`;

if (code.includes(OLD)) {
  code = code.replace(OLD, NEW);
  fs.writeFileSync(path, code, 'utf8');
  console.log('create-order snapshot save patched ✅');
} else {
  console.log('create-order pattern not found — trying alternative pattern');
  // Try alternate pattern
  const OLD2 = `res.json({ success: true, razorpay_order_id: razorpayOrder.id,`;
  if (code.includes(OLD2)) {
    const NEW2 = `// Save snapshot\n  try { await PendingPayment.findOneAndDelete({ razorpayOrderId: razorpayOrder.id }); await PendingPayment.create({ razorpayOrderId: razorpayOrder.id, userId: req.user.id, cartSnapshot: cartData, shippingAddress: shippingAddress || {}, buyerNotes: buyerNotes || '' }); } catch(e2){ console.error('snap err',e2.message); }\n  ` + OLD2;
    code = code.replace(OLD2, NEW2);
    fs.writeFileSync(path, code, 'utf8');
    console.log('create-order alt pattern patched ✅');
  } else {
    console.log('WARNING: Could not auto-patch create-order. Manual patch needed.');
  }
}
NODEOF
fi

# ---- Step 3: Patch verify route to use snapshot if cart is empty ----
if grep -q "PendingPayment.findOne" "$PAYMENT_FILE"; then
  echo "verify already patched — skipping"
else
  node << 'NODEOF'
const fs = require('fs');
const path = process.env.HOME + '/workspace/src/routes/payment.js';
let code = fs.readFileSync(path, 'utf8');

// Replace the calcCart block in verify with snapshot-first approach
const OLD = `  // 2. Build order from cart
  const cartData = await calcCart(req.user.id);
  if (!cartData.items || cartData.items.length === 0) {
    return res.status(400).json({ message: 'Cart is empty' });
  }`;

const NEW = `  // 2. Build order — use cart snapshot (works after Razorpay redirect on mobile)
  let cartData = null;
  const pendingSnap = await PendingPayment.findOne({ razorpayOrderId: razorpay_order_id, userId: req.user.id });
  if (pendingSnap && pendingSnap.cartSnapshot && pendingSnap.cartSnapshot.items && pendingSnap.cartSnapshot.items.length > 0) {
    cartData = pendingSnap.cartSnapshot;
    // Use shipping from snapshot if not in request
    if (!shippingAddress || !shippingAddress.fullName) {
      shippingAddress = pendingSnap.shippingAddress;
    }
    if (!buyerNotes) buyerNotes = pendingSnap.buyerNotes;
    console.log('Using cart snapshot for order:', razorpay_order_id);
  } else {
    // Fallback: try live cart
    cartData = await calcCart(req.user.id);
  }
  if (!cartData || !cartData.items || cartData.items.length === 0) {
    return res.status(400).json({ message: 'Cart is empty — payment received but order could not be created. Please contact support with Payment ID: ' + razorpay_payment_id });
  }`;

if (code.includes(OLD)) {
  code = code.replace(OLD, NEW);
  fs.writeFileSync(path, code, 'utf8');
  console.log('verify route patched with snapshot fallback ✅');
} else {
  console.log('WARNING: verify cart pattern not found exactly. Checking for partial match...');
  // Try finding just the "Cart is empty" return line
  const OLD2 = `return res.status(400).json({ message: 'Cart is empty' });`;
  if (code.includes(OLD2)) {
    const NEW2 = `// Snapshot fallback
    const pendingSnap2 = await PendingPayment.findOne({ razorpayOrderId: razorpay_order_id });
    if (pendingSnap2 && pendingSnap2.cartSnapshot && pendingSnap2.cartSnapshot.items && pendingSnap2.cartSnapshot.items.length > 0) {
      cartData.items = pendingSnap2.cartSnapshot.items;
      cartData.total = pendingSnap2.cartSnapshot.total;
      cartData.subtotal = pendingSnap2.cartSnapshot.subtotal;
      cartData.deliveryCharge = pendingSnap2.cartSnapshot.deliveryCharge;
      cartData.couponCode = pendingSnap2.cartSnapshot.couponCode;
      cartData.couponDiscount = pendingSnap2.cartSnapshot.couponDiscount;
      console.log('Snapshot fallback used for empty cart');
    } else {
      return res.status(400).json({ message: 'Cart is empty — Payment ID: ' + razorpay_payment_id + ' received. Contact support.' });
    }`;
    code = code.replace(OLD2, NEW2);
    fs.writeFileSync(path, code, 'utf8');
    console.log('verify Cart is empty fallback patched ✅');
  } else {
    console.log('WARNING: Could not find Cart is empty line. Manual patch needed.');
  }
}
NODEOF
fi

# ---- Step 4: Cleanup PendingPayment after successful order ----
if grep -q "PendingPayment.findOneAndDelete({ razorpayOrderId: razorpay_order_id })" "$PAYMENT_FILE" 2>/dev/null; then
  echo "Cleanup already patched"
else
  node << 'NODEOF'
const fs = require('fs');
const path = process.env.HOME + '/workspace/src/routes/payment.js';
let code = fs.readFileSync(path, 'utf8');

// After "// 7. Clear cart" cleanup pending payment too
const OLD = `  // 7. Clear cart
  await Cart.findOneAndDelete({ student: req.user.id });`;

const NEW = `  // 7. Clear cart + pending payment snapshot
  await Cart.findOneAndDelete({ student: req.user.id });
  await PendingPayment.findOneAndDelete({ razorpayOrderId: razorpay_order_id }).catch(() => {});`;

if (code.includes(OLD)) {
  code = code.replace(OLD, NEW);
  fs.writeFileSync(path, code, 'utf8');
  console.log('PendingPayment cleanup after order patched ✅');
} else {
  console.log('Cleanup pattern not found (non-critical)');
}
NODEOF
fi

# ---- Step 5: Verify syntax ----
echo ""
echo "=== Syntax Check ==="
node --check "$PAYMENT_FILE" && echo "Syntax OK ✅" || echo "Syntax ERROR ❌ — restoring backup"

if ! node --check "$PAYMENT_FILE" 2>/dev/null; then
  cp "$BACKUP_FILE" "$PAYMENT_FILE"
  echo "Backup restored ⚠️"
  exit 1
fi

echo ""
echo "=== Fix Complete ==="
echo "Backup saved at: $BACKUP_FILE"
echo "Now run: cd ~/workspace && npm run dev (or git push to redeploy)"
