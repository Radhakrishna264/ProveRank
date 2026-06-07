#!/bin/bash
set -e
echo "🔧 Fix: adminStore.js syntax error"

echo "── Lines 125-140 of adminStore.js ──"
sed -n '125,140p' ~/workspace/src/routes/adminStore.js

echo ""
echo "── Fixing PUT route ──"
node << 'EOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/src/routes/adminStore.js';
let c = fs.readFileSync(file, 'utf-8');

// Remove ALL existing PUT /products/:id routes (there might be duplicates or broken ones)
// Find and replace cleanly

// Strategy: find the broken PUT route and rewrite it clean
// Look for any router.put('/products/:id' and rebuild it
const cleanPutRoute = `router.put('/products/:id', protectAdmin, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    const fields = ['name','description','shortDescription','category','subject','classLevel',
      'examType','price','originalPrice','stock','lowStockThreshold','isbn','author',
      'publisher','edition','language','pages','weight','deliveryTime','returnPolicy',
      'deliveryCharge','freeDeliveryAbove','isActive','isFeatured','isNew','isBestSeller',
      'tags','features','specifications','images'];
    fields.forEach(f => {
      if (req.body[f] !== undefined) {
        product[f] = req.body[f];
        product.markModified(f);
      }
    });
    await product.save();
    res.json({ message: 'Product updated', product });
  } catch (e) { res.status(400).json({ message: e.message }); }
});`;

// Remove any existing PUT /products/:id block completely
// Match from router.put('/products/:id' to the closing });
const putRegex = /router\.put\(['"]\/products\/:id['"][\s\S]*?\}\s*\}\s*\}\s*\)\s*;/g;
const matches = c.match(putRegex);
if (matches) {
  console.log(`Found ${matches.length} PUT route(s), replacing...`);
  // Remove all and add one clean version
  c = c.replace(putRegex, '');
  // Insert after GET /products/:id
  const insertAfter = "router.get('/products/:id', protectAdmin, async (req, res) => {";
  const getRouteEnd = c.indexOf(insertAfter);
  if (getRouteEnd !== -1) {
    // Find end of this GET route
    let pos = getRouteEnd;
    let depth = 0;
    let started = false;
    while (pos < c.length) {
      if (c[pos] === '{') { depth++; started = true; }
      else if (c[pos] === '}') { depth--; if (started && depth === 0) { pos++; break; } }
      pos++;
    }
    // Skip ); after }
    while (pos < c.length && (c[pos] === ')' || c[pos] === ';' || c[pos] === '\n')) pos++;
    c = c.slice(0, pos) + '\n\n' + cleanPutRoute + '\n' + c.slice(pos);
    console.log('✅ Clean PUT route inserted after GET /products/:id');
  }
} else {
  console.log('PUT route regex not found, trying simple approach...');
  // Find any syntax issues around line 134
  const lines = c.split('\n');
  console.log('Lines 130-138:');
  lines.slice(129, 138).forEach((l, i) => console.log((i+130) + ': ' + l));
}

// Verify syntax by checking braces balance
const openBraces  = (c.match(/\{/g)||[]).length;
const closeBraces = (c.match(/\}/g)||[]).length;
console.log(`Brace check: { = ${openBraces}, } = ${closeBraces}, diff = ${openBraces - closeBraces}`);

fs.writeFileSync(file, c);
console.log('✅ adminStore.js saved');
EOF

echo ""
echo "── Verify lines 125-145 after fix ──"
sed -n '125,145p' ~/workspace/src/routes/adminStore.js

echo ""
echo "── Git push ──"
cd ~/workspace
git add src/routes/adminStore.js
git commit -m "fix: clean PUT /products/:id route syntax error in adminStore.js"
git push origin main
echo "✅ Pushed — watch Render deploy"
