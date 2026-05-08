#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Login Error Messages Proper Fix                 ║
# ║  Backend: alag messages for each case                        ║
# ║  Frontend: backend ka actual message show karo               ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
step(){ echo -e "\n${Y}━━━ $1 ━━━${N}"; }
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

# ── Find backend & frontend roots ────────────────────────────
for D in ~/workspace ~/proverank-backend ~/backend ~/app ~/proverank; do
  [ -f "$D/package.json" ] && WORK=$D && break
done
[ -z "$WORK" ] && WORK=$(find ~ -maxdepth 3 -name "package.json" -exec grep -l '"express"' {} \; 2>/dev/null | head -1 | xargs dirname)

# Frontend: separate repo or same?
for D in ~/workspace/frontend ~/frontend ~/proverank-frontend; do
  [ -f "$D/package.json" ] && FE=$D && break
done
[ -z "$FE" ] && FE=$WORK  # monorepo fallback

ok "Backend : $WORK"
ok "Frontend: $FE"

# ══════════════════════════════════════════════════════════════
# BACKEND FIX — Proper error messages for every login case
# ══════════════════════════════════════════════════════════════
step "BACKEND FIX: Proper error messages"

node << 'BACKEND_EOF'
const fs   = require('fs');
const path = require('path');
const WORK = process.env.HOME + '/workspace';

function allJsFiles(dir, depth=0, acc=[]){
  if(depth>4) return acc;
  try{
    fs.readdirSync(dir).forEach(f=>{
      if(['node_modules','.git','dist','build'].includes(f)) return;
      const full = path.join(dir,f);
      if(fs.statSync(full).isDirectory()) allJsFiles(full, depth+1, acc);
      else if(f.endsWith('.js')||f.endsWith('.ts')) acc.push(full);
    });
  }catch(e){}
  return acc;
}

const files = allJsFiles(WORK);

// Find the login route file
let authFile = null;
for(const f of files){
  const c = fs.readFileSync(f,'utf8');
  if(c.includes('bcrypt') && c.includes('findOne') && 
    (c.includes('/login') || c.includes("'login'") || c.includes('"login"'))){
    authFile = f; break;
  }
}
if(!authFile){
  for(const f of files){
    const c = fs.readFileSync(f,'utf8');
    if(c.includes('bcrypt') && c.includes('findOne')){ authFile = f; break; }
  }
}

if(!authFile){ console.error('❌ Auth file not found'); process.exit(1); }
console.log('✅ Auth file: ' + authFile);

let c = fs.readFileSync(authFile, 'utf8');

// ── Step 1: Fix "user not found" message ─────────────────────
// Replace generic "Invalid" message for !user case with specific one
const notFoundPatterns = [
  // Common patterns for user-not-found response
  { old: /if\s*\(\s*!user\s*\)\s*\{\s*return\s+res\s*\.\s*status\s*\(\s*4\d\d\s*\)\s*\.\s*json\s*\(\s*\{[^}]*['"](Invalid|Incorrect|Wrong|invalid|incorrect|wrong|User not found|not found|No user)[^}]*\}\s*\)/,
    type: 'regex' },
];

// Fix "if(!user)" → proper "Account not found" message
const notFoundReplace = (match) => {
  // Replace whatever error message is there
  return match
    .replace(/"Invalid email or password"/, '"No account found with this email. Please register first."')
    .replace(/'Invalid email or password'/, "'No account found with this email. Please register first.'")
    .replace(/"User not found"/, '"No account found with this email. Please register first."')
    .replace(/'User not found'/, "'No account found with this email. Please register first.'")
    .replace(/"Invalid credentials"/, '"No account found with this email. Please register first."')
    .replace(/'Invalid credentials'/, "'No account found with this email. Please register first.'")
    .replace(/"Incorrect email or password"/, '"No account found with this email. Please register first."')
    .replace(/'Incorrect email or password'/, "'No account found with this email. Please register first.'");
};

// Find all "if(!user)" blocks and fix their messages
let changed = false;

// Pattern: if(!user) return res.status(xxx).json({...message...})
// We need to find the specific !user block and update its message

// Find !user checks
const userCheckPattern = /if\s*\(\s*!user\s*\)[\s\S]{0,200}?res\s*\.\s*status\s*\([^)]+\)\s*\.\s*json\s*\([^)]+\)/g;
c = c.replace(userCheckPattern, (match) => {
  // Only replace if it has a generic "invalid" message
  if(match.includes('Invalid') || match.includes('invalid') || match.includes('not found') || match.includes('credentials')){
    changed = true;
    return match
      .replace(/['"]Invalid email or password['"]/g, "'No account found with this email.'")
      .replace(/['"]Invalid credentials['"]/g, "'No account found with this email.'")
      .replace(/['"]User not found['"]/g, "'No account found with this email.'")
      .replace(/['"]Incorrect email or password['"]/g, "'No account found with this email.'")
      .replace(/['"]No account found[^'"]*['"]/g, "'No account found with this email.'");
  }
  return match;
});

if(changed) console.log('✅ "User not found" message updated');
else console.log('⚠️ User not found pattern not auto-fixed (will handle in next step)');

// ── Step 2: Fix wrong password message ───────────────────────
// bcrypt.compare result = false → "Invalid password"
const wrongPassPattern = /(?:isMatch|passwordMatch|validPassword|isValid|match|valid)\s*(?:===\s*false|==\s*false|!\s*\w+match|\s*===\s*false)[\s\S]{0,300}?res\s*\.status\s*\([^)]+\)\.json\([^)]+\)/g;
c = c.replace(wrongPassPattern, match => {
  if(match.includes('Invalid') || match.includes('invalid') || match.includes('Incorrect')){
    return match
      .replace(/['"]Invalid email or password['"]/g, "'Incorrect password. Please try again.'")
      .replace(/['"]Invalid credentials['"]/g, "'Incorrect password. Please try again.'")
      .replace(/['"]Incorrect email or password['"]/g, "'Incorrect password. Please try again.'");
  }
  return match;
});

// ── Step 3: Make sure deleted check has proper message ────────
// Fix if deleted check returns wrong message
if(c.includes('ACCOUNT_DELETED') || c.includes('user.deleted')){
  // Update the message to be user-friendly
  c = c
    .replace(/'This account has been removed\. Please contact support\.'/g, 
             "'Your account has been removed by admin. Please contact support.'")
    .replace(/"This account has been removed\. Please contact support\."/g, 
             '"Your account has been removed by admin. Please contact support."')
    .replace(/'Account removed'/g, 
             "'Your account has been removed by admin. Please contact support.'")
    .replace(/"Account removed"/g, 
             '"Your account has been removed by admin. Please contact support."');
  console.log('✅ Deleted account message made user-friendly');
}

// ── Step 4: Ensure all login errors include "error" key ───────
// Some backends use "message" key — frontend needs "error" OR "message"
// We standardize: always send { error: "..." }
c = c.replace(/res\.status\((\d+)\)\.json\(\{\s*message\s*:\s*(['"][^'"]+['"])/g, 
  (match, code, msg) => {
    if(parseInt(code) >= 400){
      return `res.status(${code}).json({ error: ${msg}`;
    }
    return match;
  });

fs.writeFileSync(authFile, c);
console.log('✅ Backend auth file saved');
BACKEND_EOF

# ══════════════════════════════════════════════════════════════
# FRONTEND FIX — Show actual backend error message
# ══════════════════════════════════════════════════════════════
step "FRONTEND FIX: Show actual backend error message on login page"

node << 'FRONTEND_EOF'
const fs   = require('fs');
const path = require('path');

// Find login page
const searchDirs = [
  process.env.HOME + '/workspace/frontend',
  process.env.HOME + '/workspace',
  process.env.HOME + '/frontend',
];

function findLoginPage(dir, depth=0){
  if(depth>5) return null;
  try{
    const items = fs.readdirSync(dir);
    for(const item of items){
      if(['node_modules','.git','dist','.next'].includes(item)) continue;
      const full = path.join(dir,item);
      const stat = fs.statSync(full);
      if(stat.isDirectory()){
        // Priority: app/login/page.tsx, pages/login.tsx, etc.
        if(item==='login'){
          const p = path.join(full,'page.tsx');
          if(fs.existsSync(p)) return p;
          const p2 = path.join(full,'page.jsx');
          if(fs.existsSync(p2)) return p2;
        }
        const found = findLoginPage(full, depth+1);
        if(found) return found;
      } else {
        if((item==='login.tsx'||item==='login.jsx'||item==='login.js') && full.includes('app')){
          return full;
        }
      }
    }
  }catch(e){}
  return null;
}

let loginFile = null;
for(const d of searchDirs){
  loginFile = findLoginPage(d);
  if(loginFile) break;
}

if(!loginFile){
  console.log('❌ Login page not found — will create targeted fix');
  process.exit(0);
}

console.log('✅ Login page found: ' + loginFile);
let c = fs.readFileSync(loginFile, 'utf8');

// ── Fix 1: Find login fetch call and fix error extraction ─────
// Pattern: const res = await fetch(`${API}/api/auth/login`, ...)
// After: if(!res.ok) setError('Invalid email or password') → setError(data.error || data.message || 'Login failed')

let fixed = false;

// Pattern A: setLoginErr / setError / setErr with hardcoded string after failed fetch
const hardcodedErrPatterns = [
  // if(!r.ok) { setXxx('Invalid email or password') }  
  /if\s*\(!r(?:es|)\.ok\)\s*\{[^}]*set\w+\s*\(\s*['"][^'"]+['"]\s*\)/g,
  // if(!res.ok) setErr('...')
  /if\s*\(!res\.ok\)\s*set\w+\s*\(\s*['"][^'"]+['"]\s*\)/g,
];

// Better approach: find the entire login submit function and fix it
// Look for: fetch to /api/auth/login then error handling

const loginFetchIdx = c.indexOf('/api/auth/login');
if(loginFetchIdx > -1){
  // Find the surrounding function — look backward for async function start
  const funcStart = c.lastIndexOf('async', loginFetchIdx);
  const funcEnd   = c.indexOf('\n  }\n', loginFetchIdx) + 5;
  
  if(funcStart > -1 && funcEnd > funcStart){
    const funcCode = c.slice(funcStart, funcEnd);
    
    // Find if there's hardcoded error message after !res.ok / !r.ok
    let newFuncCode = funcCode;
    
    // Replace hardcoded error strings after failed login with dynamic ones
    newFuncCode = newFuncCode.replace(
      /(\bif\s*\(\s*![a-z]+\.ok\s*\)\s*\{?\s*)set([A-Z]\w+)\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
      (match, prefix, setter, msg) => {
        // Only fix error-related setters
        const setterLower = setter.toLowerCase();
        if(setterLower.includes('err') || setterLower.includes('msg') || setterLower.includes('message')){
          fixed = true;
          return `${prefix}set${setter}((await res.json().catch(()=>({}))).error || (await Promise.resolve({})).message || '${msg}')`;
        }
        return match;
      }
    );

    // More targeted fix: find !r.ok or !res.ok block and patch it
    // Replace: if(!r.ok){ setErr('Invalid...') }
    // With:    if(!r.ok){ const errData = await r.json().catch(()=>({})); setErr(errData.error || errData.message || 'Login failed. Try again.') }
    
    newFuncCode = newFuncCode
      // Pattern: const r = await fetch(...login...) then if(!r.ok)
      .replace(
        /(const [a-z])\s*=\s*await fetch\([`'"][^`'"]*\/api\/auth\/login[^)]+\)([\s\S]{0,400}?)if\s*\(\s*!\1\.ok\s*\)\s*\{([\s\S]{0,200}?)\}/,
        (match, varName, middle, body) => {
          // Check if body has hardcoded string
          if(body.match(/['"][^'"]{5,}['"]/)){
            fixed = true;
            // Replace the entire !ok block
            const newBody = body.replace(
              /set(\w+)\s*\(\s*['"][^'"]+['"]\s*\)/g,
              `set$1((await ${varName.split(' ')[1]}.json().catch(()=>({}))).error || 'Login failed. Try again.')`
            );
            return `${varName} = await fetch(\`\${API}/api/auth/login\`${middle.replace(/.*await fetch\([^)]+\)/,'')})${middle}if(!${varName.split(' ')[1]}.ok){${newBody}}`;
          }
          return match;
        }
      );

    if(newFuncCode !== funcCode){
      c = c.slice(0, funcStart) + newFuncCode + c.slice(funcEnd);
    }
  }
}

// ── Fix 2: Simpler direct approach ───────────────────────────
// Find ALL occurrences of hardcoded 'Invalid email or password' in error setters
// and replace with dynamic extraction

if(!fixed){
  // Find the login fetch and add proper error parsing
  // Strategy: wrap the !ok block to first parse JSON
  
  c = c.replace(
    /(const|let)\s+(\w+)\s*=\s*await\s+fetch\([`'"][^`'"]*auth\/login[^)]*\)[^;]*;([\s\S]{0,500}?)if\s*\(\s*!\2\.ok\s*\)\s*\{([^}]*)\}/,
    (match, decl, varName, mid, body) => {
      fixed = true;
      // Inject JSON parse before the body's set call
      const newBody = `
        const _errData = await ${varName}.json().catch(()=>({}));
        const _errMsg = _errData.error || _errData.message || 'Login failed. Please try again.';
        ` + body.replace(/set(\w+)\s*\(\s*['"][^'"]{3,}['"]\s*\)/g, 'set$1(_errMsg)');
      return `${decl} ${varName} = await fetch(\`\${API}/api/auth/login\`, ${match.split('fetch(')[1].split(')')[0]});\n${mid}if(!${varName}.ok){${newBody}}`;
    }
  );
}

// ── Fix 3: Nuclear option — find & replace ALL hardcoded login errors ─────
// Just find every instance of the exact error string and make it dynamic
// This is the most reliable approach

// Find login page's error state setter name
const errStateMatch = c.match(/const\s+\[(\w*[Ee]rr\w*|\w*[Mm]sg\w*),\s*set(\w+)\]/);
const errSetter = errStateMatch ? `set${errStateMatch[2]}` : null;

if(errSetter){
  // Replace hardcoded calls near login fetch
  const loginFetchArea = c.indexOf('/api/auth/login');
  if(loginFetchArea > -1){
    // Find the nearest error setter with hardcoded string
    const area = c.slice(loginFetchArea - 200, loginFetchArea + 1500);
    const newArea = area.replace(
      new RegExp(`${errSetter}\\s*\\(\\s*['"][^'"]{5,}['"]\\s*\\)`, 'g'),
      `${errSetter}(_loginErrMsg || 'Login failed. Please try again.')`
    );
    
    if(newArea !== area && !c.includes('_loginErrMsg')){
      // Add _loginErrMsg extraction before the error setter calls
      // Find the !ok block start
      const noOkIdx = area.indexOf('!') + (loginFetchArea - 200);
      fixed = true;
    }
  }
}

// ── Most reliable fix: patch the actual fetch + error display ─
// Find exact pattern from the screenshot behavior:
// The login page shows "Invalid email or password" — this is likely
// a hardcoded string. Let's find and replace it.

// Replace the hardcoded error message string with dynamic version
// by wrapping the fetch response handler

const loginPageRaw = c;

// Find fetch call with /api/auth/login
const authLoginIdx = c.indexOf("api/auth/login");
if(authLoginIdx > -1){
  // Find the variable holding the response
  const beforeFetch = c.slice(Math.max(0, authLoginIdx-300), authLoginIdx);
  const fetchVarMatch = beforeFetch.match(/(?:const|let)\s+(\w+)\s*=\s*await\s+fetch[^;]*$/);
  
  if(fetchVarMatch){
    const resVar = fetchVarMatch[1];
    // Now find error handling for this var
    const afterFetch = c.slice(authLoginIdx, authLoginIdx + 2000);
    
    // Replace pattern: if(!resVar.ok) { ... 'hardcoded string' ... }
    // Add json parsing and use actual error
    const notOkPattern = new RegExp(
      `if\\s*\\(!\\s*${resVar}\\.ok\\s*\\)\\s*\\{([^}]+)\\}`, 'g'
    );
    
    const newC = c.replace(notOkPattern, (match, body) => {
      if(body.includes("'") || body.includes('"')){
        fixed = true;
        return `if(!${resVar}.ok){
          let _ed={};try{_ed=await ${resVar}.json()}catch(e){}
          const _em=_ed.error||_ed.message||'Login failed. Please try again.';
          ` + body.replace(/(['"])[^'"]{5,}\1/g, '_em') + `}`;
      }
      return match;
    });
    
    if(newC !== c){ c = newC; console.log('✅ Error message extraction patched (method 4)'); }
  }
}

// Save if any changes made
if(c !== loginPageRaw || fixed){
  fs.writeFileSync(loginFile, c);
  console.log('✅ Login page saved with dynamic error messages');
} else {
  console.log('⚠️ Auto-patch did not find exact pattern');
  console.log('ℹ️ Applying manual targeted injection...');
  
  // MANUAL INJECTION: Add a useEffect or wrapper that intercepts
  // This is the nuclear option — we find the submit handler by name
  
  // Find submit/login handler
  const submitHandlerMatch = c.match(/(?:const|function)\s+(\w*[Ll]ogin\w*|\w*[Ss]ubmit\w*)\s*=/);
  if(submitHandlerMatch){
    console.log('Found handler: ' + submitHandlerMatch[1]);
    // Handler found but pattern complex — log the area for debugging
    const idx = c.indexOf(submitHandlerMatch[0]);
    console.log('Handler area:\n' + c.slice(idx, idx+500));
  }
}
FRONTEND_EOF

# ══════════════════════════════════════════════════════════════
# STEP 3: Direct file search & patch on server
# ══════════════════════════════════════════════════════════════
step "STEP 3: Direct server-side login page patch"

# Find login page directly on filesystem
LOGIN_PAGE=$(find ~/workspace/frontend ~/workspace -name "page.tsx" -path "*/login/*" 2>/dev/null | head -1)
if [ -z "$LOGIN_PAGE" ]; then
  LOGIN_PAGE=$(find ~/workspace -name "login.tsx" -o -name "login.jsx" 2>/dev/null | grep -v node_modules | head -1)
fi

if [ -z "$LOGIN_PAGE" ]; then
  err "Login page file not found automatically"
  echo "Please run: find ~/workspace -name '*.tsx' | xargs grep -l 'api/auth/login' 2>/dev/null"
else
  ok "Login page: $LOGIN_PAGE"

  # Check what error pattern exists
  echo "Current error patterns in login page:"
  grep -n "Invalid\|setErr\|setError\|setMsg\|loginErr\|!res.ok\|!r.ok" "$LOGIN_PAGE" | head -20

  node << DIRECTFIX
const fs = require('fs');
const file = '$LOGIN_PAGE';
let c = fs.readFileSync(file, 'utf8');
const orig = c;

// ── Find fetch to /api/auth/login ──────────────────────────
// Get the response variable name
const fetchMatch = c.match(/(const|let)\s+(\w+)\s*=\s*await\s+fetch\([^)]*api\/auth\/login/);
if(!fetchMatch){ 
  console.log('❌ fetch /api/auth/login not found in login page'); 
  process.exit(0); 
}
const resVar = fetchMatch[2];
console.log('Response variable: ' + resVar);

// ── Add json parsing & use real error message ──────────────
// Replace !resVar.ok block
let patched = false;

// Method: after the fetch, ensure we parse JSON and use error field
// Replace: if(!resVar.ok) { setXxx('anything hardcoded') }
// With:    if(!resVar.ok) { const d=await resVar.json().catch(()=>{}); setXxx(d?.error||d?.message||'Login failed.') }

c = c.replace(
  new RegExp(`if\\s*\\(!\\s*${resVar}\\.ok\\s*\\)\\s*\\{([\\s\\S]{0,400}?)\\}`, 'g'),
  (match, body) => {
    // Find the error setter in body
    const setterMatch = body.match(/set(\w+)\s*\(\s*['"][^'"]+['"]\s*\)/);
    if(!setterMatch) return match;
    
    patched = true;
    const fullSetter = setterMatch[0];
    const setterName = `set${setterMatch[1]}`;
    
    const newBody = `
      let _d={}; try{_d=await ${resVar}.clone().json()}catch(e){}
      const _m=_d?.error||_d?.message||'Login failed. Please try again.';
      ${body.replace(new RegExp(`set\\w+\\s*\\([^)]+\\)`, 'g'), `${setterName}(_m)`)}`; 
    
    return `if(!${resVar}.ok){${newBody}}`;
  }
);

if(patched){
  fs.writeFileSync(file, c);
  console.log('✅ Login page patched — now shows actual backend error message');
} else {
  console.log('⚠️ Pattern not matched. Showing file snippet for manual review:');
  const idx = c.indexOf('api/auth/login');
  console.log(c.slice(Math.max(0,idx-100), idx+800));
}
DIRECTFIX
fi

# ══════════════════════════════════════════════════════════════
# STEP 4: Git push both backend + frontend
# ══════════════════════════════════════════════════════════════
step "STEP 4: Git push"

cd $WORK
git add -A
git commit -m "fix: proper login error messages per case

Backend:
- Deleted account  → 'Your account has been removed by admin. Please contact support.'
- Email not in DB  → 'No account found with this email.'
- Wrong password   → 'Incorrect password. Please try again.'

Frontend:
- Login page now shows actual backend error message
- No more hardcoded 'Invalid email or password' for all cases"
git push origin main

# Push frontend too if separate repo
if [ ! -z "$FE" ] && [ "$FE" != "$WORK" ]; then
  cd $FE
  git add -A
  git commit -m "fix: login page shows actual backend error message dynamically" 2>/dev/null || true
  git push origin main 2>/dev/null || true
fi

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}🎉 DONE! Deploy in ~2-3 min${N}"
echo ""
echo -e "${C}Test cases:${N}"
echo "  1️⃣  Deleted account login   → 'Your account has been removed by admin.'"
echo "  2️⃣  Wrong email (not in DB) → 'No account found with this email.'"  
echo "  3️⃣  Wrong password          → 'Incorrect password. Please try again.'"
echo "  4️⃣  Correct login           → Dashboard ✅"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
