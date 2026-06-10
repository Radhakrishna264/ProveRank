#!/bin/bash
# ProveRank — create-order final fix

FILE="$HOME/workspace/src/routes/payment.js"
BACKUP="$FILE.bak3_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP" && echo "Backup OK"

# Write the JS fixer to a temp file (avoids all shell escaping issues)
cat > /tmp/prfix.js << 'ENDOFJS'
const fs = require('fs');
const f = process.env.HOME + '/workspace/src/routes/payment.js';
let c = fs.readFileSync(f, 'utf8');

// Fix 1: Remove the wrong snapshot-read block from create-order
// This block uses undefined variables (razorpay_order_id, razorpay_payment_id)
const marker1 = '// Snapshot fallback\n      const pendingSnap2 = await PendingPayment.findOne({ razorpayOrderId: razorpay_order_id });';

if (c.includes(marker1)) {
  // Find the full if-block to replace
  const startIdx = c.indexOf('    if (!cartData.items || cartData.items.length === 0) {\n      // Snapshot fallback');
  if (startIdx !== -1) {
    // Find the matching closing brace of this if block
    let depth = 0;
    let i = startIdx;
    let foundStart = false;
    while (i < c.length) {
      if (c[i] === '{') { depth++; foundStart = true; }
      if (c[i] === '}') { depth--; }
      if (foundStart && depth === 0) { i++; break; }
      i++;
    }
    const badBlock = c.slice(startIdx, i);
    const goodBlock = '    if (!cartData.items || cartData.items.length === 0) {\n      return res.status(400).json({ message: \'Cart is empty\' });\n    }';
    c = c.replace(badBlock, goodBlock);
    console.log('Fix 1 done: Wrong snapshot block removed');
  }
} else {
  console.log('Fix 1 skip: Already clean');
}

// Fix 2: Add snapshot SAVE after rzpOrder creation, before res.json
const saveMarker = 'Snapshot saved:';
if (!c.includes(saveMarker)) {
  const rzpEnd = '    });\n\n    res.json({\n      success:  true,\n      order_id: rzpOrder.id,';
  const rzpEnd2 = '    });\n    res.json({\n      success:  true,\n      order_id: rzpOrder.id,';
  
  const snapSave = '    });\n\n    // Save snapshot for verify after mobile redirect\n    try {\n      await PendingPayment.findOneAndDelete({ razorpayOrderId: rzpOrder.id });\n      await PendingPayment.create({\n        razorpayOrderId: rzpOrder.id,\n        userId: req.user.id,\n        cartSnapshot: cartData,\n        shippingAddress: req.body.shippingAddress || {},\n        buyerNotes: req.body.buyerNotes || \'\'\n      });\n      console.log(\'Snapshot saved:\', rzpOrder.id);\n    } catch(se) { console.error(\'Snapshot err:\', se.message); }\n\n    res.json({\n      success:  true,\n      order_id: rzpOrder.id,';

  if (c.includes(rzpEnd)) {
    c = c.replace(rzpEnd, snapSave);
    console.log('Fix 2 done: Snapshot SAVE added');
  } else if (c.includes(rzpEnd2)) {
    c = c.replace(rzpEnd2, snapSave.replace('\n\n    res.json', '\n    res.json'));
    console.log('Fix 2 alt done: Snapshot SAVE added');
  } else {
    // Fallback: find rzpOrder.create ending and inject
    const idx = c.indexOf('    res.json({\n      success:  true,\n      order_id: rzpOrder.id,');
    if (idx !== -1) {
      const ins = '\n    // Save snapshot for verify\n    try {\n      await PendingPayment.findOneAndDelete({ razorpayOrderId: rzpOrder.id });\n      await PendingPayment.create({ razorpayOrderId: rzpOrder.id, userId: req.user.id, cartSnapshot: cartData, shippingAddress: req.body.shippingAddress||{}, buyerNotes: req.body.buyerNotes||\'\' });\n      console.log(\'Snapshot saved:\', rzpOrder.id);\n    } catch(se){ console.error(\'Snap err:\',se.message); }\n\n';
      c = c.slice(0, idx) + ins + c.slice(idx);
      console.log('Fix 2 fallback done');
    } else {
      console.log('Fix 2 FAILED: Could not find res.json insertion point');
    }
  }
} else {
  console.log('Fix 2 skip: Snapshot save already present');
}

fs.writeFileSync(f, c, 'utf8');
console.log('File saved');
ENDOFJS

node /tmp/prfix.js

echo ""
echo "=== Syntax Check ==="
node --check "$FILE" && echo "Syntax OK ✅" || {
  echo "Syntax ERROR — restoring backup ❌"
  cp "$BACKUP" "$FILE"
}

echo ""
echo "=== Verify ==="
grep -n "Snapshot saved\|Cart is empty\|pendingSnap2\|razorpay_payment_id" "$FILE"
