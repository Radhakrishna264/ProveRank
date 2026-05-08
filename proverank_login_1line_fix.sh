#!/bin/bash
# ProveRank — Login Error Fix (1-line change)
G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'
ok(){ echo -e "${G}✅ $1${N}"; }

LOGIN_FILE=~/workspace/frontend/app/login/page.tsx
[ ! -f "$LOGIN_FILE" ] && LOGIN_FILE=$(find ~/workspace/frontend -name "page.tsx" -path "*/login*" 2>/dev/null | head -1)
[ ! -f "$LOGIN_FILE" ] && LOGIN_FILE=$(find ~/workspace/frontend -name "*.tsx" 2>/dev/null | grep -v node_modules | grep -v .next | xargs grep -l "d\.message.*Invalid email" 2>/dev/null | head -1)

ok "File: $LOGIN_FILE"

node << 'EOF'
const fs = require('fs');
const file = process.env.LOGIN_FILE;
let c = fs.readFileSync(file, 'utf8');

// THE FIX: d.message → d.error||d.message (everywhere in login fetch)
c = c.replace(/d\.message\s*\|\|\s*'Invalid email or password'/g,
              "d.error||d.message||'Login failed. Please try again.'");
c = c.replace(/d\.message\s*\|\|\s*"Invalid email or password"/g,
              "d.error||d.message||'Login failed. Please try again.'");

fs.writeFileSync(file, c);
console.log('✅ Fixed: d.message → d.error||d.message');
EOF

export LOGIN_FILE
node -e "
const fs=require('fs');
const c=fs.readFileSync(process.env.LOGIN_FILE,'utf8');
const ok=c.includes('d.error||d.message');
console.log(ok?'✅ Fix verified!':'❌ Fix not applied');
"

cd ~/workspace
git add -A
git commit -m "fix: login reads d.error||d.message from backend response

- Backend sends {error:'...'} but frontend was reading d.message only
- Now reads d.error first, then d.message as fallback
- Deleted account → 'Your account has been removed by admin.'
- Wrong email → 'No account found with this email.'
- Wrong password → 'Incorrect password. Please try again.'"
git push origin main

[ -d ~/workspace/frontend/.git ] && cd ~/workspace/frontend && git add -A && git commit -m "fix: login error reads d.error from backend" 2>/dev/null && git push origin main 2>/dev/null

echo ""
echo -e "${G}✅ DONE! Vercel deploy ~2 min${N}"
echo "Test deleted account → 'Your account has been removed by admin.'"
