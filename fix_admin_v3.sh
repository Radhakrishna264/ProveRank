#!/bin/bash
# ProveRank — Admin V3 Syntax Fix
# Rule H3: fix script with node
# Rule C1: cat > EOF style
# Rule C2: NO sed -i

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
log()  { echo -e "${G}[OK]${N} $1"; }
step() { echo -e "\n${B}===== $1 =====${N}"; }

FE=~/workspace/frontend
PAGE=$FE/app/admin/x7k2p/page.tsx

step "Checking file exists"
if [ ! -f "$PAGE" ]; then
  echo "File not found: $PAGE — Run proverank_admin_v3.sh first"
  exit 1
fi

BEFORE=$(wc -l < $PAGE)
log "File found: $BEFORE lines"

step "Applying 2 syntax fixes via Node.js (Rule H3)"

cat > /tmp/fix_admin.js << 'NODEEOF'
const fs = require('fs')
const path = '/root/workspace/frontend/app/admin/x7k2p/page.tsx'

let code = fs.readFileSync(path, 'utf8')
let fixes = 0

// FIX 1: n.read?.0.6:1 → n.read?0.6:1
// Bug: ?. is optional chaining — wrong syntax
const before1 = code
code = code.replace(/n\.read\?\.0\.6:1/g, 'n.read?0.6:1')
if (code !== before1) { fixes++; console.log('[FIX 1] n.read?.0.6 → n.read?0.6 DONE') }
else { console.log('[FIX 1] Pattern not found — checking alternate...') 
  // try alternate spacing
  const alt = code.replace(/\.read\?\.0\.6/g, '.read?0.6')
  if (alt !== code) { code = alt; fixes++; console.log('[FIX 1 ALT] Done') }
}

// FIX 2: if(res.ok)T(...)else T(...) → if(res.ok){T(...)}else{T(...)}
// Bug: if/else without braces causes parse error in Turbopack
const before2 = code
code = code.replace(
  /if\(res\.ok\)T\(`\$\{extMins\} min extra time diya `\)else T\('Extension failed','e'\)/g,
  "if(res.ok){T(`${extMins} min extra time diya`)}else{T('Extension failed','e')}"
)
if (code !== before2) { fixes++; console.log('[FIX 2] if/else braces DONE') }
else { 
  console.log('[FIX 2] Exact pattern not found — trying broader fix...')
  // Fix ANY bare if(res.ok)T(...)else pattern in extendTime
  const before2b = code
  code = code.replace(
    /if\(res\.ok\)\{?T\(`\$\{extMins\}[^`]*`\)\}?else\{?T\('Extension failed','e'\)\}?/g,
    "if(res.ok){T(`${extMins} min extra time diya`)}else{T('Extension failed','e')}"
  )
  if (code !== before2b) { fixes++; console.log('[FIX 2B] Done') }
}

// FIX 3: Any other ?. before a number (defensive)
const before3 = code
code = code.replace(/(\w)\?\.(\d)/g, '$1?$2')
if (code !== before3) { fixes++; console.log('[FIX 3] Additional ?. number fixes done') }

fs.writeFileSync(path, code, 'utf8')
console.log(`\nTotal fixes applied: ${fixes}`)
console.log('File saved successfully.')
NODEEOF

node /tmp/fix_admin.js

AFTER=$(wc -l < $PAGE)
log "File after fix: $AFTER lines"

step "Done!"
echo ""
echo -e "${G}Fix applied! Ab git push karo:${N}"
echo ""
echo "  cd ~/workspace"
echo "  git add frontend/app/admin/x7k2p/page.tsx"
echo "  git commit -m \"Fix: Admin V3 syntax errors — optional chaining + if/else braces\""
echo "  git push origin main"
