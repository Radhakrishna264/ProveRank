#!/bin/bash
set -e
echo "══════════════════════════════════════════"
echo "🔧 FINAL FIX — Tab Variable + StudentShell Nav"
echo "══════════════════════════════════════════"

ADMIN_PAGE=~/workspace/frontend/app/admin/x7k2p/page.tsx
SHELL_FILE=~/workspace/frontend/src/components/StudentShell.tsx

# ─────────────────────────────────────────
# FIX 1: Admin page.tsx — wrong variable
# activeSection → tab
# ─────────────────────────────────────────
echo ""
echo "── Fix 1: Admin page.tsx tab variable ──"
node << 'EOF1'
const fs   = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(file, 'utf-8');

// Check what's currently there
if (content.includes("{activeSection === 'store' && <StoreAdminTab />}")) {
  // Replace wrong variable with correct one
  content = content.replace(
    "{activeSection === 'store' && <StoreAdminTab />}",
    "{tab === 'store' && <StoreAdminTab />}"
  );
  fs.writeFileSync(file, content);
  console.log("✅ Fixed: activeSection → tab");
} else if (content.includes("{tab === 'store' && <StoreAdminTab />}")) {
  console.log("ℹ️  Already using 'tab' variable — correct");
} else {
  // Search for the actual tab variable name by looking at useState('overview') or similar
  const tabMatch = content.match(/const\s*\[(\w+),\s*set\w+\]\s*=\s*useState\(['"](?:overview|dashboard|home|main)['"]\)/);
  const tabVar = tabMatch ? tabMatch[1] : 'tab';
  console.log('Tab variable detected:', tabVar);

  // Remove any wrong render that was added
  content = content.replace(/\{activeSection\s*===\s*['"]store['"]\s*&&\s*<StoreAdminTab\s*\/>\}/g, '');

  // Find best insertion point — before </main> or after last tab render
  const allTabRenders = [...content.matchAll(new RegExp(`\\{${tabVar}\\s*===\\s*['"][^'"]+['"]\\s*&&`, 'g'))];
  if (allTabRenders.length) {
    const lastRender = allTabRenders[allTabRenders.length - 1];
    // Find the end of this block
    let pos = lastRender.index;
    let depth = 0;
    while (pos < content.length) {
      if (content[pos] === '{') depth++;
      else if (content[pos] === '}') { depth--; if (depth === 0) { pos++; break; } }
      pos++;
    }
    content = content.slice(0, pos) + `\n        {${tabVar} === 'store' && <StoreAdminTab />}` + content.slice(pos);
    fs.writeFileSync(file, content);
    console.log(`✅ Store tab render added using variable: ${tabVar}`);
  } else {
    const mainClose = content.lastIndexOf('</main>');
    if (mainClose !== -1) {
      content = content.slice(0, mainClose) + `\n        {${tabVar} === 'store' && <StoreAdminTab />}\n      ` + content.slice(mainClose);
      fs.writeFileSync(file, content);
      console.log('✅ Store tab render added before </main>');
    } else {
      console.log('❌ Could not add render — check manual fix below');
    }
  }
}

// Verify
const verify = content.includes('StoreAdminTab') && (content.includes("=== 'store'") || content.includes('=== "store"'));
console.log('Verification — StoreAdminTab render exists:', verify);
EOF1

# ─────────────────────────────────────────
# FIX 2: StudentShell — add Store nav item
# Format: {id:'store',icon:'🛒',en:'Store',hi:'स्टोर',href:'/dashboard/store'}
# ─────────────────────────────────────────
echo ""
echo "── Fix 2: StudentShell nav ──"
node << 'EOF2'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/src/components/StudentShell.tsx';

if (!fs.existsSync(file)) {
  console.log('❌ File not found:', file);
  process.exit(0);
}

let content = fs.readFileSync(file, 'utf-8');

if (content.includes('/dashboard/store')) {
  console.log('ℹ️  Store already in StudentShell nav');
  process.exit(0);
}

// Detect nav item format from existing items
const hasHindi = content.includes("hi:'") || content.includes('hi:"');
const hasEn    = content.includes("en:'") || content.includes('en:"');

console.log('Nav format — has Hindi labels:', hasHindi, '| has English labels:', hasEn);

// Build store nav item based on detected format
let storeItem;
if (hasHindi && hasEn) {
  storeItem = `{id:'store',icon:'🛒',en:'Store',hi:'स्टोर',href:'/dashboard/store'}`;
} else if (hasHindi) {
  storeItem = `{id:'store',icon:'🛒',hi:'स्टोर',href:'/dashboard/store'}`;
} else {
  storeItem = `{id:'store',icon:'🛒',label:'Store',href:'/dashboard/store'}`;
}

console.log('Store item to insert:', storeItem);

// Insertion targets — try each known route before which we insert Store
const insertBeforeTargets = [
  '/dashboard/profile',
  '/dashboard/goals',
  '/dashboard/support',
  '/dashboard/doubt',
  '/dashboard/test-series',
  '/dashboard/my-batches',
  '/dashboard/compare',
];

let inserted = false;
for (const target of insertBeforeTargets) {
  if (!content.includes(target)) continue;

  // Find the object that contains this href
  const idx = content.indexOf(`href:'${target}'`);
  const idx2 = content.indexOf(`href:"${target}"`);
  const hrefIdx = idx !== -1 ? idx : idx2;
  if (hrefIdx === -1) continue;

  // Go back to find the start of this nav object {
  let start = hrefIdx;
  while (start > 0 && content[start] !== '{') start--;

  // Insert store item before this object
  const comma = content[start-1] === ',' ? '' : ',';
  content = content.slice(0, start) + storeItem + ',' + content.slice(start);
  inserted = true;
  console.log(`✅ Store nav item inserted before: ${target}`);
  break;
}

// If still not inserted, try to find the array definition and append
if (!inserted) {
  console.log('Trying array append approach...');
  // Find the nav array — look for common patterns
  const navArrayPatterns = [
    /const\s+(?:NAV|navItems|navLinks|navList|menuItems)\s*=\s*\[/,
    /const\s+\w+\s*=\s*\[\s*\{[^}]*href:\s*['"]\/dashboard/,
  ];
  for (const pattern of navArrayPatterns) {
    const match = content.match(pattern);
    if (!match) continue;
    // Find the closing ] of this array
    let pos = match.index + match[0].length;
    let depth = 1;
    while (pos < content.length && depth > 0) {
      if (content[pos] === '[') depth++;
      else if (content[pos] === ']') depth--;
      if (depth > 0) pos++;
    }
    // Insert before closing ]
    content = content.slice(0, pos) + ',' + storeItem + content.slice(pos);
    inserted = true;
    console.log('✅ Store nav item appended to nav array');
    break;
  }
}

if (inserted) {
  fs.writeFileSync(file, content);
  console.log('✅ StudentShell.tsx saved');
} else {
  console.log('⚠️  Auto-insert failed — MANUAL FIX needed (see below)');
}
EOF2

# ─────────────────────────────────────────
# VERIFY ALL
# ─────────────────────────────────────────
echo ""
echo "──────────── VERIFICATION ────────────"
echo "1. Admin page.tsx — store render:"
grep -n "store.*StoreAdminTab\|StoreAdminTab.*store" $ADMIN_PAGE | head -5

echo ""
echo "2. Admin page.tsx — tab variable used:"
grep -n "'store'" $ADMIN_PAGE | head -5

echo ""
echo "3. StudentShell — store nav:"
grep -n "store\|Store" $SHELL_FILE 2>/dev/null | head -8

echo ""
echo "4. Files check:"
ls -lh ~/workspace/frontend/app/dashboard/store/page.tsx
ls -lh ~/workspace/frontend/app/admin/x7k2p/StoreAdminTab.tsx

echo ""
echo "══════════════════════════════════════════"
echo "📋 IF StudentShell still shows ⚠️ :"
echo "   Open: frontend/src/components/StudentShell.tsx"
echo "   Find the NAV array (has all dashboard links)"
echo "   Add this object anywhere in that array:"
echo "   {id:'store',icon:'🛒',en:'Store',hi:'स्टोर',href:'/dashboard/store'}"
echo "══════════════════════════════════════════"
echo "✅ Final fix complete — screenshot lo"
