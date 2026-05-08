#!/bin/bash
# ProveRank — Login Fix FINAL
G='\033[0;32m'; R='\033[0;31m'; N='\033[0m'
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

# ── Find login page ──────────────────────────────────────────
F=$(find ~/workspace/frontend -name "*.tsx" 2>/dev/null \
  | grep -v node_modules | grep -v ".next" \
  | xargs grep -l "d\.message.*Invalid email" 2>/dev/null \
  | head -1)

[ -z "$F" ] && F=$(find ~/workspace/frontend -name "page.tsx" -path "*/login*" 2>/dev/null | head -1)

if [ -z "$F" ]; then err "Login page not found"; exit 1; fi
ok "File: $F"

# ── Export FIRST, then run node ──────────────────────────────
export LOGIN_FILE="$F"

node << 'EOF'
const fs   = require('fs');
const file = process.env.LOGIN_FILE;

if(!file){ console.log('❌ LOGIN_FILE not set'); process.exit(1); }

let c = fs.readFileSync(file, 'utf8');
const orig = c;

// Fix: d.message → d.error || d.message
c = c.replace(
  /d\.message\s*\|\|\s*'Invalid email or password'/g,
  "d.error||d.message||'Login failed. Please try again.'"
);
c = c.replace(
  /d\.message\s*\|\|\s*"Invalid email or password"/g,
  'd.error||d.message||"Login failed. Please try again."'
);

if(c === orig){
  console.log('Pattern not found — searching file for clues:');
  c.split('\n').forEach((l,i)=>{
    if(l.includes('Invalid')||l.includes('d.message')||l.includes('setError'))
      console.log((i+1)+': '+l.trim());
  });
  process.exit(1);
}

fs.writeFileSync(file, c);
console.log('✅ Fixed! d.error||d.message now used');
EOF

if [ $? -ne 0 ]; then
  err "Fix failed — check output above"
  exit 1
fi

ok "Pushing to GitHub"
cd ~/workspace
git add -A
git commit -m "fix: login shows backend error - d.error||d.message"
git push origin main

[ -d ~/workspace/frontend/.git ] && [ "~/workspace/frontend" != "~/workspace" ] && \
  cd ~/workspace/frontend && git add -A && \
  git commit -m "fix: login error from backend" 2>/dev/null && \
  git push origin main 2>/dev/null

echo ""
ok "Done! Vercel deploy ~2 min"
echo "Test: deleted account → 'Your account has been removed by admin.'"
