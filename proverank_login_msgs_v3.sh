#!/bin/bash
# ProveRank — Login Error Messages Fix (Clean Version)
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
step(){ echo -e "\n${Y}━━━ $1 ━━━${N}"; }
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

WORK=~/workspace
FE=~/workspace/frontend

# ══════════════════════════════════════════════════════════════
# STEP 1: BACKEND — Proper error messages
# ══════════════════════════════════════════════════════════════
step "STEP 1: Backend — proper error messages per case"

node << 'NODE_EOF'
const fs   = require('fs');
const path = require('path');
const base = process.env.HOME + '/workspace/src/routes/';

// Find auth file
let authFile = null;
const files = fs.readdirSync(base);
for(const f of files){
  const c = fs.readFileSync(base + f, 'utf8');
  if(c.includes('bcrypt') && c.includes('findOne')){
    authFile = base + f; break;
  }
}
if(!authFile){ console.log('ERR: auth file not found'); process.exit(1); }
console.log('Auth file: ' + authFile);

let c = fs.readFileSync(authFile, 'utf8');

// Fix 1: deleted account → specific message
// Already inserted by previous script — just update the message text
c = c.replace(
  /res\.status\(403\)\.json\(\{[^}]*ACCOUNT_DELETED[^}]*\}\)/g,
  "res.status(403).json({ error: 'Your account has been removed by admin. Please contact support.' })"
);

// Fix 2: user not found → "No account found"
// Common pattern: if(!user) return res.status(4xx).json({...})
c = c.replace(
  /if\s*\(\s*!user\s*\)\s*(?:return\s+)?res\.status\(\d+\)\.json\(\{[^}]+\}\)/g,
  function(match){
    return match
      .replace(/'Invalid email or password'/g, "'No account found with this email.'")
      .replace(/"Invalid email or password"/g, '"No account found with this email."')
      .replace(/'Invalid credentials'/g, "'No account found with this email.'")
      .replace(/"Invalid credentials"/g, '"No account found with this email."')
      .replace(/'User not found'/g, "'No account found with this email.'")
      .replace(/"User not found"/g, '"No account found with this email."')
      .replace(/'Incorrect email or password'/g, "'No account found with this email.'")
      .replace(/"Incorrect email or password"/g, '"No account found with this email."');
  }
);

// Fix 3: wrong password → "Incorrect password"
// Common pattern: if(!isMatch) or if(!passwordValid)
c = c.replace(
  /if\s*\(\s*!(?:isMatch|passwordMatch|validPassword|isPasswordValid|passMatch|valid|match)\s*\)\s*(?:return\s+)?res\.status\(\d+\)\.json\(\{[^}]+\}\)/g,
  function(match){
    return match
      .replace(/'Invalid email or password'/g, "'Incorrect password. Please try again.'")
      .replace(/"Invalid email or password"/g, '"Incorrect password. Please try again."')
      .replace(/'Invalid credentials'/g, "'Incorrect password. Please try again.'")
      .replace(/"Invalid credentials"/g, '"Incorrect password. Please try again."')
      .replace(/'Incorrect email or password'/g, "'Incorrect password. Please try again.'")
      .replace(/"Incorrect email or password"/g, '"Incorrect password. Please try again."');
  }
);

fs.writeFileSync(authFile, c);
console.log('Backend saved OK');
NODE_EOF

# ══════════════════════════════════════════════════════════════
# STEP 2: FRONTEND — Show actual backend error (not hardcoded)
# ══════════════════════════════════════════════════════════════
step "STEP 2: Frontend login page — show backend's actual error"

LOGIN_FILE=$(find $FE/app $FE/pages -name "page.tsx" -path "*/login/*" 2>/dev/null | head -1)
[ -z "$LOGIN_FILE" ] && LOGIN_FILE=$(find $FE -name "page.tsx" -path "*/login*" 2>/dev/null | grep -v node_modules | head -1)
[ -z "$LOGIN_FILE" ] && LOGIN_FILE=$(find $FE -name "*.tsx" 2>/dev/null | xargs grep -l "api/auth/login" 2>/dev/null | grep -v node_modules | head -1)

if [ -z "$LOGIN_FILE" ]; then
  err "Login page not found"
  echo "Run: find $FE -name '*.tsx' | xargs grep -l 'auth/login' 2>/dev/null"
else
  ok "Login page: $LOGIN_FILE"

  node << 'LOGIN_FIX_EOF'
const fs = require('fs');

// Get file path from env-like approach
const { execSync } = require('child_process');
const filePath = process.env.LOGIN_FILE || '';

if(!filePath || !fs.existsSync(filePath)){
  console.log('Login file path not set or not found');
  process.exit(0);
}

let c = fs.readFileSync(filePath, 'utf8');
const original = c;

// Find which variable holds the fetch response to /api/auth/login
// Pattern: const r = await fetch(`${API}/api/auth/login`, ...)
// or:      const res = await fetch(...)
const fetchLine = c.match(/(const|let)\s+(\w+)\s*=\s*await\s+fetch\([^)]*auth\/login/);
if(!fetchLine){
  console.log('fetch /api/auth/login not found in login page');
  process.exit(0);
}
const rv = fetchLine[2]; // response variable name e.g. "r" or "res"
console.log('Response var: ' + rv);

// Strategy: Find the !rv.ok error block and patch it to read JSON
// Before: if(!r.ok){ setError('Invalid email or password') }
// After:  if(!r.ok){ const d=await r.json().catch(()=>({}))); setError(d.error||d.message||'Login failed.') }

// Simple string replacements for common patterns
const patterns = [
  // Pattern: setError('Invalid email or password')
  [/setError\s*\(\s*'Invalid email or password'\s*\)/g,
   "setError((()=>{try{return window.__loginErrCache||(window.__loginErrCache='Login failed')}catch(e){return 'Login failed'}})())"],
  // Pattern: setError("Invalid email or password")  
  [/setError\s*\(\s*"Invalid email or password"\s*\)/g,
   "setError((()=>{try{return window.__loginErrCache||(window.__loginErrCache='Login failed')}catch(e){return 'Login failed'}})())"],
  // setMsg / setLoginError / setLoginErr similar patterns
  [/setMsg\s*\(\s*'Invalid email or password'\s*\)/g,
   "setMsg((()=>{try{return window.__loginErrCache||'Login failed'}catch(e){return 'Login failed'}})())"],
  [/setLoginErr\s*\(\s*'Invalid email or password'\s*\)/g,
   "setLoginErr((()=>{try{return window.__loginErrCache||'Login failed'}catch(e){return 'Login failed'}})())"],
];

// Better approach: find the !ok block and add json parsing inline
// Replace: if(!r.ok){<body>}
// With: if(!r.ok){let _d={};try{_d=await r.json()}catch(e){} <body with _d.error>}

const notOkStr = `if(!${rv}.ok)`;
const notOkIdx = c.indexOf(notOkStr);

if(notOkIdx > -1){
  // Find the opening brace
  const braceStart = c.indexOf('{', notOkIdx);
  if(braceStart > -1){
    // Find matching closing brace
    let depth = 0, braceEnd = -1;
    for(let i = braceStart; i < c.length; i++){
      if(c[i] === '{') depth++;
      else if(c[i] === '}'){
        depth--;
        if(depth === 0){ braceEnd = i; break; }
      }
    }
    
    if(braceEnd > -1){
      const blockContent = c.slice(braceStart+1, braceEnd);
      
      // Check if block already has json parsing
      if(!blockContent.includes('.json()') && !blockContent.includes('_d.error') && !blockContent.includes('errData')){
        // Find the error setter in blockContent
        const setterMatch = blockContent.match(/set(\w+)\s*\([^)]+\)/);
        if(setterMatch){
          const setterFull = setterMatch[0];
          const setterName = 'set' + setterMatch[1];
          
          // Build new block: parse JSON first, then use actual error
          const newBlock = `{
    let _errData={};
    try{ _errData=await ${rv}.clone().json(); }catch(e){}
    const _errMsg=_errData.error||_errData.message||'Login failed. Please try again.';
    ${blockContent.replace(
      new RegExp('set' + setterMatch[1] + '\\s*\\([^)]+\\)', 'g'),
      setterName + '(_errMsg)'
    )}
  }`;
          
          c = c.slice(0, braceStart) + newBlock + c.slice(braceEnd+1);
          console.log('Patched !ok block with JSON error parsing');
        }
      } else {
        console.log('Block already has JSON parsing — skip');
      }
    }
  }
} else {
  console.log('!'+rv+'.ok block not found directly');
  // Try with else pattern: if(r.ok){...} else { setError(...) }
  const elseIdx = c.lastIndexOf('else', c.indexOf('api/auth/login') + 2000);
  if(elseIdx > -1){
    console.log('Found else at index: ' + elseIdx);
  }
}

if(c !== original){
  fs.writeFileSync(filePath, c);
  console.log('Login page saved with dynamic error messages');
} else {
  console.log('No changes made — showing relevant code for manual review:');
  const loginIdx = c.indexOf('api/auth/login');
  if(loginIdx > -1) console.log(c.slice(loginIdx, loginIdx+600));
}
LOGIN_FIX_EOF

fi

export LOGIN_FILE
node -e "
const fs=require('fs');
const f=process.env.LOGIN_FILE;
if(!f||!fs.existsSync(f)){process.exit(0);}
let c=fs.readFileSync(f,'utf8');
const orig=c;
const rv=(c.match(/(const|let)\s+(\w+)\s*=\s*await\s+fetch\([^)]*auth\/login/)||[])[2];
if(!rv){console.log('rv not found');process.exit(0);}
const pat=new RegExp('if\\\\(!'+rv+'\\\\.ok\\\\)\\\\s*\\\\{([\\\\s\\\\S]{0,600}?)\\\\}');
c=c.replace(pat,function(m,body){
  if(body.includes('.json()')||body.includes('_errMsg')){return m;}
  const sm=body.match(/set(\w+)\s*\([^)]*\)/);
  if(!sm){return m;}
  const sn='set'+sm[1];
  const nb='{let _errData={};try{_errData='+rv+'.json?await '+rv+'.clone().json():{};}catch(e){}const _errMsg=_errData.error||_errData.message||\"Login failed. Please try again.\";'+body.replace(new RegExp('set'+sm[1]+'\\\\s*\\\\([^)]*\\\\)','g'),sn+'(_errMsg)')+'}';
  return 'if(!'+rv+'.ok)'+nb;
});
if(c!==orig){fs.writeFileSync(f,c);console.log('Saved');}else{console.log('No match');}
"

# ══════════════════════════════════════════════════════════════
# STEP 3: Git push
# ══════════════════════════════════════════════════════════════
step "STEP 3: Git Push"

cd $WORK
git add -A
git commit -m "fix: login error messages — deleted/notfound/wrongpass show correct msgs

- Deleted account  → 'Your account has been removed by admin.'
- Email not in DB  → 'No account found with this email.'  
- Wrong password   → 'Incorrect password. Please try again.'
- Frontend reads actual error from backend response JSON"
git push origin main

[ -d "$FE/.git" ] && cd $FE && git add -A && git commit -m "fix: login page shows actual backend error message" 2>/dev/null && git push origin main 2>/dev/null

echo ""
echo -e "${G}✅ DONE! Render+Vercel deploy ~2-3 min${N}"
echo "Test: deleted account → 'Your account has been removed by admin.'"
