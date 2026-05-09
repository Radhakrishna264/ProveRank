#!/bin/bash
# ProveRank — Backend Auth Messages Fix
G='\033[0;32m'; R='\033[0;31m'; N='\033[0m'
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

export AUTH_FILE=$(find ~/workspace/src -name "*.js" 2>/dev/null \
  | grep -v node_modules \
  | xargs grep -l "bcrypt" 2>/dev/null \
  | xargs grep -l "findOne" 2>/dev/null \
  | head -1)

if [ -z "$AUTH_FILE" ]; then err "Auth file not found"; exit 1; fi
ok "Auth file: $AUTH_FILE"

echo ""
echo "=== Current login error lines ==="
grep -n "Invalid\|Incorrect\|isMatch\|!user\|deleted\|bcrypt" "$AUTH_FILE" | head -20
echo "================================="

node << 'EOF'
const fs = require('fs');
const file = process.env.AUTH_FILE;
if(!file){ console.log('AUTH_FILE not set'); process.exit(1); }

let c = fs.readFileSync(file, 'utf8');
const orig = c;

// FIX 1: !user → No account found
c = c.replace(
  /if\s*\(\s*!user\s*\)\s*(?:return\s+)?res\.status\(\d+\)\.json\(\s*\{\s*(?:error|message)\s*:\s*['"][^'"]*['"]\s*\}\s*\)/g,
  "if(!user) return res.status(404).json({ error: 'No account found with this email.' })"
);
c = c.replace(
  /if\s*\(\s*!user\s*\)\s*\{\s*(?:return\s+)?res\.status\(\d+\)\.json\(\s*\{\s*(?:error|message)\s*:\s*['"][^'"]*['"]\s*\}\s*\)\s*;?\s*\}/g,
  "if(!user){ return res.status(404).json({ error: 'No account found with this email.' }); }"
);

// FIX 2: wrong password → Incorrect password
const pats = ['isMatch','passwordMatch','validPassword','isPasswordValid','passMatch','isValid','match'];
for(const p of pats){
  const r1 = new RegExp(`if\\s*\\(\\s*!\\s*${p}\\s*\\)\\s*(?:return\\s+)?res\\.status\\(\\d+\\)\\.json\\(\\s*\\{\\s*(?:error|message)\\s*:\\s*['"][^'"]*['"]\\s*\\}\\s*\\)`,'g');
  const r2 = new RegExp(`if\\s*\\(\\s*!\\s*${p}\\s*\\)\\s*\\{\\s*(?:return\\s+)?res\\.status\\(\\d+\\)\\.json\\(\\s*\\{\\s*(?:error|message)\\s*:\\s*['"][^'"]*['"]\\s*\\}\\s*\\)\\s*;?\\s*\\}`,'g');
  c = c.replace(r1, `if(!${p}) return res.status(401).json({ error: 'Incorrect password. Please try again.' })`);
  c = c.replace(r2, `if(!${p}){ return res.status(401).json({ error: 'Incorrect password. Please try again.' }); }`);
}

if(c === orig){
  console.log('NO_MATCH — showing relevant lines:');
  c.split('\n').forEach((l,i)=>{
    if(l.includes('!user')||l.includes('isMatch')||l.includes('Invalid')||l.includes('bcrypt.compare'))
      console.log((i+1)+': '+l.trim());
  });
  process.exit(1);
}

fs.writeFileSync(file, c);
console.log('✅ Saved! Verifying:');
c.split('\n').forEach((l,i)=>{
  if(l.includes('No account')||l.includes('Incorrect password')||l.includes('been removed'))
    console.log((i+1)+': '+l.trim());
});
EOF

if [ $? -ne 0 ]; then
  err "Fix failed — terminal ka screenshot bhejo"
  exit 1
fi

cd ~/workspace
git add -A
git commit -m "fix: proper login errors — notfound/wrongpass/deleted alag messages"
git push origin main

echo ""
ok "Done! Render deploy ~3 min"
echo "Test: Wrong email → 'No account found' | Wrong pass → 'Incorrect password'"
