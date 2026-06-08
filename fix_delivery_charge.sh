#!/bin/bash
set -e
echo "🔧 Fix: DeliveryCharge 0 save + Cart delivery from product"

# ── Fix 1: StoreAdminTab.tsx — fix || fallback for 0 values ──
node << 'EOF1'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/StoreAdminTab.tsx';
let c = fs.readFileSync(file, 'utf-8');

// The bug: parseFloat(form.deliveryCharge)||49 — 0 is falsy so becomes 49
// Fix: use explicit undefined/empty check
const fixes = [
  ['parseFloat(form.deliveryCharge)||49',   'form.deliveryCharge===\'\'||form.deliveryCharge===undefined ? 49 : parseFloat(form.deliveryCharge)'],
  ['parseFloat(form.freeDeliveryAbove)||499','form.freeDeliveryAbove===\'\'||form.freeDeliveryAbove===undefined ? 499 : parseFloat(form.freeDeliveryAbove)'],
  ['parseInt(form.stock)',                   'form.stock===\'\'? 0 : parseInt(form.stock)'],
  ['parseInt(form.pages)||undefined',        'form.pages===\'\'? undefined : parseInt(form.pages)'],
  ['parseInt(form.weight)||undefined',       'form.weight===\'\'? undefined : parseInt(form.weight)'],
];

let changed = 0;
for (const [from, to] of fixes) {
  if (c.includes(from)) {
    c = c.replace(new RegExp(from.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'g'), to);
    changed++;
    console.log('✅ Fixed:', from.substring(0,40));
  }
}
console.log(`Total fixes applied: ${changed}`);

fs.writeFileSync(file, c);
console.log('✅ StoreAdminTab.tsx saved');
EOF1

# ── Fix 2: studentStore.js — calcCart use product.deliveryCharge ──
node << 'EOF2'
const fs = require('fs');
const file = process.env.HOME + '/workspace/src/routes/studentStore.js';
let c = fs.readFileSync(file, 'utf-8');

// OLD: hardcoded 49 — wrong
// const maxFreeDelivery = Math.max(...(enrichedItems.map(i => i.product.freeDeliveryAbove || 499)));
// deliveryCharge = subtotal >= maxFreeDelivery ? 0 : 49;

// NEW: use product's actual deliveryCharge
const oldCalc = `  const maxFreeDelivery = Math.max(...(enrichedItems.map(i => i.product.freeDeliveryAbove || 499)));
  deliveryCharge = subtotal >= maxFreeDelivery ? 0 : 49;`;

const newCalc = `  // Use product's actual freeDeliveryAbove and deliveryCharge
  const minFreeDeliveryThreshold = enrichedItems.length > 0
    ? Math.min(...enrichedItems.map(i => i.product.freeDeliveryAbove ?? 499))
    : 499;
  // Use max delivery charge across products in cart
  const maxProductDelivery = enrichedItems.length > 0
    ? Math.max(...enrichedItems.map(i => i.product.deliveryCharge ?? 49))
    : 49;
  deliveryCharge = subtotal >= minFreeDeliveryThreshold ? 0 : maxProductDelivery;`;

if (c.includes(oldCalc)) {
  c = c.replace(oldCalc, newCalc);
  console.log('✅ calcCart delivery calculation fixed — uses product.deliveryCharge now');
} else {
  // Try pattern with let
  const altPattern = /const maxFreeDelivery.*\n.*deliveryCharge = subtotal >= maxFreeDelivery.*49;/;
  if (altPattern.test(c)) {
    c = c.replace(altPattern, newCalc);
    console.log('✅ calcCart fixed (alt pattern)');
  } else {
    // Manual find and replace
    const lines = c.split('\n');
    let found = false;
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('maxFreeDelivery') && lines[i].includes('freeDeliveryAbove')) {
        // Replace this line and the next one (deliveryCharge = ...)
        if (lines[i+1] && lines[i+1].includes('deliveryCharge') && lines[i+1].includes('49')) {
          lines[i]   = `  const minFreeDeliveryThreshold = enrichedItems.length > 0 ? Math.min(...enrichedItems.map(i => i.product.freeDeliveryAbove ?? 499)) : 499;`;
          lines[i+1] = `  const maxProductDelivery = enrichedItems.length > 0 ? Math.max(...enrichedItems.map(i => i.product.deliveryCharge ?? 49)) : 49;\n  deliveryCharge = subtotal >= minFreeDeliveryThreshold ? 0 : maxProductDelivery;`;
          found = true;
          console.log('✅ calcCart fixed (line-by-line)');
          break;
        }
      }
    }
    if (found) c = lines.join('\n');
    else console.log('⚠️  calcCart pattern not found — check manually');
  }
}

fs.writeFileSync(file, c);
console.log('✅ studentStore.js saved');
EOF2

# ── Fix 3: payment.js calcCart — same fix ──
node << 'EOF3'
const fs = require('fs');
const file = process.env.HOME + '/workspace/src/routes/payment.js';
let c = fs.readFileSync(file, 'utf-8');

const oldCalc = `  const deliveryCharge = subtotal >= maxFreeDelivery ? 0 : 49;`;
const newCalc = `  const maxProductDelivery = enrichedItems.length > 0 ? Math.max(...enrichedItems.map(i => i.product.deliveryCharge ?? 49)) : 49;
  const deliveryCharge = subtotal >= maxFreeDelivery ? 0 : maxProductDelivery;`;

if (c.includes(oldCalc)) {
  c = c.replace(oldCalc, newCalc);
  console.log('✅ payment.js calcCart delivery fixed');
} else if (c.includes('maxFreeDelivery ? 0 : 49')) {
  c = c.replace('maxFreeDelivery ? 0 : 49', 'maxFreeDelivery ? 0 : (enrichedItems.length > 0 ? Math.max(...enrichedItems.map(i => i.product.deliveryCharge ?? 49)) : 49)');
  console.log('✅ payment.js calcCart delivery fixed (inline)');
}

fs.writeFileSync(file, c);
EOF3

# ── Fix 4: Also fix adminStore.js PUT route — ensure 0 saved ──
node << 'EOF4'
const fs = require('fs');
const file = process.env.HOME + '/workspace/src/routes/adminStore.js';
let c = fs.readFileSync(file, 'utf-8');

// The markModified fix should already handle this
// But let's double check the field is in the list
if (c.includes("'deliveryCharge'") && c.includes('markModified')) {
  console.log('✅ adminStore.js already has deliveryCharge with markModified');
} else if (c.includes('Object.assign(product, req.body)')) {
  // Old style — replace with explicit set
  c = c.replace(
    'Object.assign(product, req.body);',
    `// Explicitly set each field — handles 0/false values correctly
    const updFields = ['name','description','shortDescription','category','subject','classLevel','examType',
      'price','originalPrice','stock','deliveryCharge','freeDeliveryAbove','deliveryTime','returnPolicy',
      'author','publisher','edition','isbn','language','pages','weight','isActive','isFeatured',
      'isNew','isBestSeller','tags','features','images','lowStockThreshold'];
    updFields.forEach(f => {
      if (req.body[f] !== undefined) {
        product.set(f, req.body[f]);
      }
    });`
  );
  console.log('✅ adminStore.js PUT route updated with explicit field setting');
}

fs.writeFileSync(file, c);
EOF4

echo ""
echo "── Git push ──"
cd ~/workspace
git add -A
git commit -m "fix: deliveryCharge 0 save bug + cart uses product.deliveryCharge"
git push origin main

echo ""
echo "✅ PUSHED!"
echo ""
echo "After deploy:"
echo "1. Edit product → delivery charge = 0 → Save → Cart mein 0 dikhega"
echo "2. Edit product → delivery charge = 49 → Save → Cart mein 49 dikhega"
echo "3. deliveryCharge aur freeDeliveryAbove dono 0 save ho jayenge"
