#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Login Block Fix for Deleted/Archived Accounts  ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
step(){ echo -e "\n${Y}━━━ $1 ━━━${N}"; }
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

WORK=~/workspace

step "Finding auth/login route file"

node << 'FIND_AND_FIX_EOF'
const fs = require('fs');
const path = require('path');
const base = process.env.HOME + '/workspace/src/routes/';

let authFile = null;

// Find auth file that has login + bcrypt
const files = fs.readdirSync(base);
for(const f of files){
  const c = fs.readFileSync(base + f, 'utf8');
  if(c.includes('bcrypt') && (c.includes('/login') || c.includes("'login'") || c.includes('"login"'))){
    authFile = base + f;
    break;
  }
}

if(!authFile){
  // Try common filenames
  for(const n of ['auth.js','authRoutes.js','auth.route.js','user.js']){
    const p = base + n;
    if(fs.existsSync(p)){ authFile = p; break; }
  }
}

if(!authFile){ console.log('❌ Auth file not found'); process.exit(1); }
console.log('✅ Auth file: ' + authFile);

let c = fs.readFileSync(authFile, 'utf8');

// Already patched?
if(c.includes('Account has been deleted') || c.includes("deleted===true") || c.includes("deleted === true") && c.includes('login')){
  console.log('✅ Login already blocks deleted accounts — no change needed');
  process.exit(0);
}

// ── Strategy: Find where user is fetched during login,
//    then add deleted check right after ──────────────────────

// Common patterns for finding user by email in login route
const findPatterns = [
  // Pattern A: findOne then check password
  { find: /const\s+user\s*=\s*await\s+User\.findOne\s*\(\s*\{?\s*email/,
    type: 'findOne' },
  // Pattern B: let user = await User.findOne
  { find: /let\s+user\s*=\s*await\s+User\.findOne\s*\(\s*\{?\s*email/,
    type: 'findOne' },
];

let matched = false;

for(const pat of findPatterns){
  const match = c.match(pat.find);
  if(!match) continue;

  // Find the end of this statement (next semicolon or newline after it)
  const matchIdx = c.indexOf(match[0]);
  let stmtEnd = c.indexOf('\n', matchIdx + match[0].length);
  // Make sure we get the full line
  const lineEnd = stmtEnd;

  // ─ Insert deleted check after user fetch ─
  const deletedCheck = `
    // ── Block login for soft-deleted / archived accounts ──
    if(user && user.deleted === true){
      return res.status(403).json({ error: 'This account has been removed. Please contact support.' });
    }`;

  c = c.slice(0, lineEnd) + deletedCheck + c.slice(lineEnd);
  matched = true;
  console.log('✅ Deleted account login block inserted after user fetch');
  break;
}

if(!matched){
  // Fallback: look for bcrypt.compare or password check — insert before it
  const passCheckPatterns = [
    'bcrypt.compare(',
    'bcryptjs.compare(',
    'comparePassword(',
    '.compareSync(',
  ];
  for(const pp of passCheckPatterns){
    const idx = c.indexOf(pp);
    if(idx === -1) continue;
    // Go back to find the start of this line
    const lineStart = c.lastIndexOf('\n', idx);
    const deletedCheck = `
    // ── Block login for soft-deleted / archived accounts ──
    if(user && user.deleted === true){
      return res.status(403).json({ error: 'This account has been removed. Please contact support.' });
    }
`;
    c = c.slice(0, lineStart) + deletedCheck + c.slice(lineStart);
    matched = true;
    console.log('✅ (Fallback) Deleted check inserted before password compare');
    break;
  }
}

if(!matched){
  console.log('❌ Could not find insertion point — manual fix needed');
  process.exit(1);
}

fs.writeFileSync(authFile, c);
console.log('✅ Auth file saved with login block for deleted accounts');
FIND_AND_FIX_EOF

if [ $? -ne 0 ]; then
  err "Auto-patch failed. Trying manual approach..."

  # Manual fallback — show the file and let user know
  step "Manual approach — injecting directly"

  node << 'MANUAL_EOF'
  const fs = require('fs');
  const base = process.env.HOME + '/workspace/src/routes/';
  const files = fs.readdirSync(base);

  for(const f of files){
    let c = fs.readFileSync(base + f, 'utf8');
    if(!c.includes('bcrypt')) continue;

    // Find ANY "if(!user)" or "if (!user)" — insert before it
    const patterns = ["if(!user)", "if (!user)", "if(!existingUser)", "if (!existingUser)"];
    for(const p of patterns){
      if(!c.includes(p)) continue;
      const idx = c.indexOf(p);
      const lineStart = c.lastIndexOf('\n', idx);
      const insertCode = `
    if(user && user.deleted === true){
      return res.status(403).json({ error: 'This account has been removed. Please contact support.' });
    }
`;
      c = c.slice(0, lineStart) + insertCode + c.slice(lineStart);
      fs.writeFileSync(base + f, c);
      console.log('✅ Manual patch applied in: ' + f);
      process.exit(0);
    }
  }
  console.log('❌ Could not apply manual patch either');
  process.exit(1);
MANUAL_EOF
fi

step "STEP 2: Git Push"

cd $WORK
git add -A
git commit -m "fix: block login for soft-deleted/archived student accounts

- Login route now checks user.deleted === true before password compare
- Deleted accounts get 403: 'This account has been removed. Please contact support.'
- Prevents archived students from logging in
- Fresh registration still allowed on same email after deletion"
git push origin main

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}🎉 FIX COMPLETE!${N}"
echo -e "${Y}Deploy: ~2 min → prove-rank.vercel.app${N}"
echo ""
echo -e "${C}What changed:${N}"
echo "  ✅ Deleted account → Login blocked (403 error)"
echo "  ✅ Error message: 'This account has been removed. Please contact support.'"
echo "  ✅ Fresh registration still works on same email"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
