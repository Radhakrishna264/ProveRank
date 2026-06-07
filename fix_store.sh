#!/bin/bash
set -e
echo "══════════════════════════════════════════"
echo "🔧 STORE FIX SCRIPT"
echo "══════════════════════════════════════════"

ADMIN_PAGE=~/workspace/frontend/app/admin/x7k2p/page.tsx
SHELL_FILE=~/workspace/frontend/src/components/StudentShell.tsx

# ─────────────────────────────────────────
# STEP 1: Find actual tab variable in admin page.tsx
# ─────────────────────────────────────────
echo ""
echo "── Finding tab variable in admin page.tsx ──"
grep -n "useState\|setTab\|setActive\|setCurrent\|setSelected\|tab\b\|Tab\b" $ADMIN_PAGE | grep -i "tab\|active\|current\|selected\|view" | head -20

echo ""
echo "── All useState declarations ──"
grep -n "useState" $ADMIN_PAGE | head -20

echo ""
echo "── Tab render patterns (===) ──"
grep -n "=== '" $ADMIN_PAGE | head -30

# ─────────────────────────────────────────
# STEP 2: Fix admin page.tsx — add Store tab render
# ─────────────────────────────────────────
echo ""
echo "── Fixing Admin page.tsx tab render ──"
node << 'ENDOFFILE'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(file, 'utf-8');

// Already fixed?
if (content.includes("=== 'store'") || content.includes('=== "store"')) {
  console.log('ℹ️  Store tab render already present');
  process.exit(0);
}

// Find what variable is used for tab switching
// Look for patterns like: tab === 'something', currentTab === 'something', etc.
const tabVarMatch = content.match(/(\w+)\s*===\s*['"][a-z]+['"]/g);
if (tabVarMatch && tabVarMatch.length > 0) {
  const firstMatch = tabVarMatch[0];
  const varName = firstMatch.split(/\s*===\s*/)[0].trim();
  console.log('✅ Tab variable found:', varName);

  // Find the last occurrence of this pattern to insert after it
  const pattern = new RegExp(`{\\s*${varName}\\s*===\\s*['"][^'"]+['"]\\s*&&[^}]*}`, 'g');
  const allMatches = [...content.matchAll(new RegExp(`${varName}\\s*===\\s*['"][^'"]+['"]`, 'g'))];

  if (allMatches.length > 0) {
    const lastMatch = allMatches[allMatches.length - 1];
    // Find the end of the JSX block containing this match
    let pos = lastMatch.index;
    // Find the closing of this conditional render block
    // Look forward for '}' that closes the {varName === 'x' && <Component />}
    let depth = 0;
    let searchPos = pos;
    while (searchPos < content.length) {
      if (content[searchPos] === '{') depth++;
      else if (content[searchPos] === '}') {
        depth--;
        if (depth === 0) break;
      }
      searchPos++;
    }
    const insertAfter = searchPos + 1;
    const storeRender = `\n        {${varName} === 'store' && <StoreAdminTab />}`;
    content = content.slice(0, insertAfter) + storeRender + content.slice(insertAfter);
    fs.writeFileSync(file, content);
    console.log('✅ Store tab render added after position:', insertAfter);
    console.log('   Render added:', storeRender.trim());
  } else {
    console.log('⚠️  Could not find closing brace. Using </main> fallback.');
    const mainClose = content.lastIndexOf('</main>');
    if (mainClose !== -1) {
      content = content.slice(0, mainClose) + `\n        {${varName} === 'store' && <StoreAdminTab />}\n      ` + content.slice(mainClose);
      fs.writeFileSync(file, content);
      console.log('✅ Store tab render added before </main>');
    } else {
      console.log('❌ Could not add automatically - check MANUAL FIX below');
    }
  }
} else {
  console.log('⚠️  No tab variable found via === pattern. Trying alternate...');
  // Try looking for JSX conditional like: tab == or similar
  const altMatch = content.match(/\b(\w+)\s*==\s*['"][a-z]+['"]/g);
  console.log('Alternate matches:', altMatch ? altMatch.slice(0,5).join(', ') : 'none');
  console.log('→ Run diagnose to see exact variable name, then fix manually');
}
ENDOFFILE

# ─────────────────────────────────────────
# STEP 3: Fix StudentShell — add Store nav link
# ─────────────────────────────────────────
echo ""
echo "── Fixing StudentShell.tsx ──"

if [ ! -f "$SHELL_FILE" ]; then
  echo "⚠️  StudentShell not at expected path, searching..."
  SHELL_FILE=$(find ~/workspace/frontend/src -name "StudentShell.tsx" ! -name "*.bak*" 2>/dev/null | head -1)
  echo "Found at: $SHELL_FILE"
fi

if [ -f "$SHELL_FILE" ]; then
  echo "✅ StudentShell found: $SHELL_FILE"
  echo "── Current nav links in StudentShell ──"
  grep -n "href\|dashboard\|Store\|store" "$SHELL_FILE" | head -20
else
  echo "❌ StudentShell.tsx not found"
fi

node << 'ENDOFFILE2'
const fs   = require('fs');
const path = require('path');

// Find StudentShell - only actual .tsx files, not .bak
const { execSync } = require('child_process');
let shellPath = null;

const candidates = [
  process.env.HOME + '/workspace/frontend/src/components/StudentShell.tsx',
  process.env.HOME + '/workspace/frontend/components/StudentShell.tsx',
];
for (const c of candidates) {
  if (fs.existsSync(c) && fs.statSync(c).isFile()) {
    shellPath = c;
    break;
  }
}

if (!shellPath) {
  try {
    const result = execSync(
      `find ${process.env.HOME}/workspace/frontend/src -name "StudentShell.tsx" -not -name "*.bak*" -type f 2>/dev/null | head -3`
    ).toString().trim();
    if (result) shellPath = result.split('\n')[0];
  } catch(e) {}
}

if (!shellPath || !fs.statSync(shellPath).isFile()) {
  console.log('❌ StudentShell.tsx file not found as a file. Check manually.');
  process.exit(0);
}

console.log('✅ Working with:', shellPath);
let content = fs.readFileSync(shellPath, 'utf-8');

if (content.includes('/dashboard/store')) {
  console.log('ℹ️  Store nav already in StudentShell');
  process.exit(0);
}

// Show what nav patterns exist
const navMatches = content.match(/href[:\s]*['"](\/dashboard\/[^'"]+)['"]/g) || [];
console.log('Existing nav hrefs:', navMatches.slice(0,8).join(' | '));

// Try inserting Store before profile or last nav item
const insertBefore = [
  "/dashboard/profile",
  "/dashboard/settings",
  "/dashboard/analytics",
  "/dashboard/certificate",
  "/dashboard/admit-card",
];

let inserted = false;
for (const target of insertBefore) {
  // Find this target in content and insert store before it
  const idx = content.indexOf(target);
  if (idx === -1) continue;
  // Go back to find the opening of this nav item (find { or <)
  let start = idx;
  while (start > 0 && content[start] !== '{' && content[start] !== '<' && content[start] !== '\n') start--;
  const lineStart = content.lastIndexOf('\n', idx);

  // Get the line and replicate its indentation
  const line = content.slice(lineStart, content.indexOf('\n', idx));
  const indent = line.match(/^(\s*)/)?.[1] || '          ';

  // Determine what pattern is used: object array or JSX Link
  if (content.includes(`href: '${target}'`) || content.includes(`href: "${target}"`)) {
    // Object array pattern
    const quote = content.includes(`href: '${target}'`) ? "'" : '"';
    const pattern = `href: ${quote}${target}${quote}`;
    const insertion = `href: ${quote}/dashboard/store${quote}, label: ${quote}Store${quote}, icon: ${quote}🛒${quote} },\n${indent}{ `;
    content = content.replace(pattern, insertion + pattern.slice(pattern.indexOf('href')));
    inserted = true;
    console.log('✅ Store nav inserted (object pattern) before:', target);
    break;
  } else if (content.includes(`href="${target}"`) || content.includes(`href='${target}'`)) {
    // JSX Link pattern
    const q = content.includes(`href="${target}"`) ? '"' : "'";
    // Find the full Link component block containing this href and insert before it
    const hrefStr = `href=${q}${target}${q}`;
    const hrefIdx = content.indexOf(hrefStr);
    // Go back to find the <Link or <a or li start
    let blockStart = hrefIdx;
    while (blockStart > 0 && !(content[blockStart] === '<' && (content.slice(blockStart,blockStart+5) === '<Link' || content.slice(blockStart,blockStart+2) === '<a' || content.slice(blockStart,blockStart+3) === '<li'))) {
      blockStart--;
    }
    const lineOfBlock = content.lastIndexOf('\n', blockStart);
    const indentOfBlock = content.slice(lineOfBlock+1, blockStart).match(/^(\s*)/)?.[1] || '            ';
    const storeLink = `<Link href="/dashboard/store" className={navLinkClass('/dashboard/store')}>\n${indentOfBlock}  🛒 Store\n${indentOfBlock}</Link>\n${indentOfBlock}`;
    content = content.slice(0, blockStart) + storeLink + content.slice(blockStart);
    inserted = true;
    console.log('✅ Store nav inserted (JSX Link pattern) before:', target);
    break;
  }
}

if (!inserted) {
  console.log('⚠️  Could not auto-insert nav. See MANUAL FIX instructions below.');
}

if (inserted) {
  fs.writeFileSync(shellPath, content);
  console.log('✅ StudentShell.tsx saved successfully');
}
ENDOFFILE2

# ─────────────────────────────────────────
# STEP 4: Manual fix instructions (fallback)
# ─────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "📋 MANUAL FIX (if auto-patch shows ⚠️)"
echo "══════════════════════════════════════════"
echo ""
echo "A) Admin page.tsx — Find the tab variable name from"
echo "   output above, then find last tab render and add:"
echo "   {TAB_VAR === 'store' && <StoreAdminTab />}"
echo ""
echo "B) StudentShell.tsx nav — add this item to nav array:"
echo "   { href: '/dashboard/store', label: 'Store', icon: '🛒' }"
echo "   OR for JSX: <Link href='/dashboard/store'>🛒 Store</Link>"
echo ""
echo "── Verify store page ──"
ls -la ~/workspace/frontend/app/dashboard/store/page.tsx
echo ""
echo "── Verify StoreAdminTab ──"
ls -la ~/workspace/frontend/app/admin/x7k2p/StoreAdminTab.tsx
echo ""
echo "── Check if store render now in admin page ──"
grep -n "store" ~/workspace/frontend/app/admin/x7k2p/page.tsx | head -10
echo ""
echo "── Check if store in StudentShell ──"
grep -n "store\|Store" ~/workspace/frontend/src/components/StudentShell.tsx 2>/dev/null | head -5 || echo "StudentShell check failed - check path"
echo "══════════════════════════════════════════"
echo "✅ Fix script complete"
echo "══════════════════════════════════════════"
