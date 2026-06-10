#!/bin/bash
# ProveRank — create-order snapshot fix (targeted)
# Fixes wrong patch + adds correct snapshot save

FILE="$HOME/workspace/src/routes/payment.js"
BACKUP="$HOME/workspace/src/routes/payment.js.bak2_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"
echo "Backup: $BACKUP ✅"

node << 'NODEOF'
const fs = require('fs');
const path = process.env.HOME + '/workspace/src/routes/payment.js';
let code = fs.readFileSync(path, 'utf8');

// ---- FIX 1: Remove wrong snapshot-read block from create-order ----
// This block uses undefined razorpay_order_id in create-order context — BUG
const WRONG_BLOCK = `    if (!cartData.items || cartData.items.length === 0) {
      // Snapshot fallback
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
        return res.status(400).json({ message: 'Cart is empty \u2014 Payment ID: ' + razorpay_payment_id + ' received. Contact support.' });
      }
    }`;

const CORRECT_EMPTY = `    if (!cartData.items || cartData.items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }`;

if (code.includes(WRONG_BLOCK)) {
  code = code.replace(WRONG_BLOCK, CORRECT_EMPTY);
  console.log('Fix 1: Wrong snapshot block removed ✅');
} else {
  console.log('Fix 1: Wrong block not found — checking alternate...');
  // Try just fixing the else branch with razorpay_payment_id undefined reference
  const ALT = `        return res.status(400).json({ message: 'Cart is empty \u2014 Payment ID: ' + razorpay_payment_id + ' received. Contact support.' });`;
  if (code.includes(ALT)) {
    code = code.replace(ALT, `        return res.status(400).json({ message: 'Cart is empty' });`);
    console.log('Fix 1 alt: Undefined razorpay_payment_id reference removed ✅');
  } else {
    console.log('Fix 1: Pattern not found — skipping (may already be clean)');
  }
}

// ---- FIX 2: Add snapshot SAVE after rzpOrder.create in create-order ----
// Target: after rzpOrder is created, before res.json
const AFTER_RZP = `    const rzpOrder = await razorpay.orders.create({
      amount: Math.round(cartData.total * 100), // paise
      currency: 'INR',
      receipt,
    });`;

const AFTER_RZP_WITH_SNAP = `    const rzpOrder = await razorpay.orders.create({
      amount: Math.round(cartData.total * 100), // paise
      currency: 'INR',
      receipt,
    });

    // Save cart snapshot so verify works after mobile Razorpay redirect
    try {
      await PendingPayment.findOneAndDelete({ razorpayOrderId: rzpOrder.id });
      await PendingPayment.create({
        razorpayOrderId: rzpOrder.id,
        userId: req.user.id,
        cartSnapshot: cartData,
        shippingAddress: req.body.shippingAddress || {},
        buyerNotes: req.body.buyerNotes || ''
      });
      console.log('Cart snapshot saved for:', rzpOrder.id);
    } catch(snapErr) {
      console.error('Snapshot save error (non-fatal):', snapErr.message);
    }`;

if (code.includes(AFTER_RZP) && !code.includes('Cart snapshot saved for:')) {
  code = code.replace(AFTER_RZP, AFTER_RZP_WITH_SNAP);
  console.log('Fix 2: Snapshot SAVE added after rzpOrder.create ✅');
} else if (code.includes('Cart snapshot saved for:')) {
  console.log('Fix 2: Snapshot save already present ✅');
} else {
  // Try alternate - find res.json({success:true, order_id in create-order
  console.log('Fix 2: Trying alternate — inserting before res.json in create-order...');
  const RES_JSON = `    res.json({
      success: true,
      order_id: rzpOrder.id,`;
  if (code.includes(RES_JSON)) {
    const SNAP_BEFORE = `    // Save cart snapshot so verify works after mobile Razorpay redirect
    try {
      await PendingPayment.findOneAndDelete({ razorpayOrderId: rzpOrder.id });
      await PendingPayment.create({
        razorpayOrderId: rzpOrder.id,
        userId: req.user.id,
        cartSnapshot: cartData,
        shippingAddress: req.body.shippingAddress || {},
        buyerNotes: req.body.buyerNotes || ''
      });
      console.log('Cart snapshot saved for:', rzpOrder.id);
    } catch(snapErr) {
      console.error('Snapshot save (non-fatal):', snapErr.message);
    }

    res.json({
      success: true,
      order_id: rzpOrder.id,`;
    code = code.replace(RES_JSON, SNAP_BEFORE);
    console.log('Fix 2 alt: Snapshot save injected before res.json ✅');
  } else {
    console.log('Fix 2: Could not find insertion point ❌');
  }
}

fs.writeFileSync(path, code, 'utf8');
console.log('File written ✅');
NODEOF

echo ""
echo "=== Syntax Check ==="
node --check "$FILE" && echo "Syntax OK ✅" || {
  echo "Syntax ERROR ❌ — restoring backup"
  cp "$BACKUP" "$FILE"
  exit 1
}

echo ""
echo "=== Verify snippet (lines around snapshot) ==="
grep -n "snapshot\|PendingPayment\|Cart is empty" "$FILE"

echo ""
echo "=== Done — git push to redeploy on Render ==="
