#!/bin/bash
# ProveRank — Login Error Fix v4 (Direct Replacement)
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
step(){ echo -e "\n${Y}━━━ $1 ━━━${N}"; }
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

WORK=~/workspace
FE=~/workspace/frontend

# ── Find login page ──────────────────────────────────────────
LOGIN_FILE=$(find $FE -name "*.tsx" -o -name "*.jsx" -o -name "*.js" 2>/dev/null \
  | grep -v node_modules | grep -v ".next" \
  | xargs grep -l "Invalid email or password" 2>/dev/null \
  | head -1)

if [ -z "$LOGIN_FILE" ]; then
  LOGIN_FILE=$(find $FE -name "*.tsx" -o -name "*.jsx" 2>/dev/null \
    | grep -v node_modules | grep -v ".next" \
    | xargs grep -l "api/auth/login" 2>/dev/null \
    | head -1)
fi

if [ -z "$LOGIN_FILE" ]; then
  err "Login page not found at all"
  exit 1
fi

ok "Login file: $LOGIN_FILE"
echo ""
echo "=== Relevant lines in login page ==="
grep -n "Invalid email\|!r\.ok\|!res\.ok\|setError\|setErr\|setMsg\|auth\/login\|r\.ok\|res\.ok" "$LOGIN_FILE" | head -30
echo "==================================="

step "Applying direct fix"

node << 'NODEEOF'
const fs = require('fs');
const filePath = process.env.LOGIN_FILE;
if(!filePath){ console.log('LOGIN_FILE not set'); process.exit(1); }

let c = fs.readFileSync(filePath, 'utf8');
const original = c;

// ── APPROACH: Find the FULL fetch block for /api/auth/login
// and inject proper error parsing ─────────────────────────

// Step 1: Find which variable holds fetch response
// Look for: const/let X = await fetch(...auth/login...)
const fetchMatch = c.match(/(const|let)\s+(\w+)\s*=\s*await\s+fetch\s*\([^)]*auth\/login/);
if(!fetchMatch){
  console.log('fetch call not found — showing file snippet:');
  const idx = c.indexOf('auth/login');
  if(idx > -1) console.log(c.slice(Math.max(0,idx-200), idx+500));
  process.exit(0);
}

const respVar = fetchMatch[2];
console.log('Response variable: ' + respVar);

// Step 2: Find "Invalid email or password" string in file
const errStr1 = "'Invalid email or password'";
const errStr2 = '"Invalid email or password"';

let idx1 = c.indexOf(errStr1);
let idx2 = c.indexOf(errStr2);
let errIdx = idx1 > -1 ? idx1 : idx2;
let errStr = idx1 > -1 ? errStr1 : errStr2;

if(errIdx === -1){
  console.log('Hardcoded error string not found in file');
  // Maybe it uses a variable — check what error state setter is called near !ok
  const notOkIdx = c.indexOf('!' + respVar + '.ok');
  if(notOkIdx > -1){
    console.log('Found !' + respVar + '.ok at index ' + notOkIdx);
    console.log('Surrounding code:');
    console.log(c.slice(notOkIdx - 50, notOkIdx + 300));
  }
  process.exit(0);
}

console.log('Found error string at index: ' + errIdx);
console.log('Context: ' + c.slice(errIdx - 150, errIdx + 100));

// Step 3: Find which function/setter is being called with this string
// Look backward from errIdx for the setter call: setXxx('Invalid...')
const beforeErr = c.slice(0, errIdx);
const setterMatch = beforeErr.match(/set(\w+)\s*\(\s*$/);
// or: look at the full statement
const fullStmt = c.slice(Math.max(0, errIdx - 60), errIdx + errStr.length + 5);
const stmtSetterMatch = fullStmt.match(/set(\w+)\s*\(/);

let setterName = null;
if(stmtSetterMatch){ setterName = 'set' + stmtSetterMatch[1]; }
console.log('Error setter: ' + setterName);

// Step 4: Find the !ok block that contains this error
// Go backward from errIdx to find if(!respVar.ok) or else {
let blockStart = -1;
let blockType = '';

// Search backward for the !ok pattern within 500 chars
const searchBack = c.slice(Math.max(0, errIdx - 500), errIdx);
const notOkMatch = searchBack.match(new RegExp('if\\s*\\(!\\s*' + respVar + '\\.ok\\s*\\)'));
if(notOkMatch){
  blockStart = errIdx - 500 + searchBack.lastIndexOf(notOkMatch[0]);
  blockType = 'notOk';
  console.log('Found !ok block at: ' + blockStart);
}

if(blockStart === -1){
  // Maybe it's in an else block
  const elseIdx = searchBack.lastIndexOf('else');
  if(elseIdx > -1){ blockStart = errIdx - 500 + elseIdx; blockType = 'else'; }
}

// Step 5: THE FIX
// Replace the hardcoded error string with code that reads from backend
// 
// We need to:
// a) Make sure the response JSON is parsed before showing error  
// b) Use actual error from backend
//
// Simplest reliable fix: 
// Find the entire !ok / else block and rewrite it with JSON parsing

if(blockStart > -1){
  // Find the block content (from { to matching })
  const blockSearchStr = blockType === 'notOk' 
    ? c.slice(blockStart, blockStart + 600)
    : c.slice(blockStart, blockStart + 400);
  
  const braceStart = blockSearchStr.indexOf('{');
  if(braceStart > -1){
    let depth = 0, braceEnd = -1;
    for(let i = braceStart; i < blockSearchStr.length; i++){
      if(blockSearchStr[i] === '{') depth++;
      else if(blockSearchStr[i] === '}'){
        depth--;
        if(depth === 0){ braceEnd = i; break; }
      }
    }
    
    if(braceEnd > -1){
      const absBlockStart = blockStart + braceStart;
      const absBlockEnd   = blockStart + braceEnd + 1;
      const blockBody = c.slice(absBlockStart + 1, absBlockEnd - 1);
      
      console.log('Block body: ' + blockBody.trim());
      
      // Build new block with JSON parsing
      // Replace the hardcoded string calls with dynamic ones
      const newBlockBody = blockBody
        .replace(new RegExp("set(\\w+)\\s*\\(\\s*'Invalid email or password'\\s*\\)", 'g'),
          "set$1((_loginErrMsg_))")
        .replace(new RegExp('set(\\w+)\\s*\\(\\s*"Invalid email or password"\\s*\\)', 'g'),
          "set$1((_loginErrMsg_))");
      
      const newBlock = `{
    let _errD={};
    try{ _errD = await ${respVar}.clone().json(); }catch(e){}
    const _loginErrMsg_ = _errD.error || _errD.message || 'Login failed. Please try again.';
    ${newBlockBody.trim()}
  }`;
      
      c = c.slice(0, absBlockStart) + newBlock + c.slice(absBlockEnd);
      console.log('Block replaced with JSON-parsing version');
    }
  }
}

// Fallback: if block replacement failed, just do direct string replacement
// by wrapping the setter with async JSON reading
if(c.includes(errStr)){
  console.log('Doing fallback direct replacement...');
  
  // We need to parse JSON from the response
  // Insert a variable before the fetch call that will hold error
  // Then replace the hardcoded string
  
  // Find the fetch call line
  const fetchLine = c.match(/(const|let)\s+(\w+)\s*=\s*await\s+fetch\s*\([^)]*auth\/login[^\n]*\n/);
  if(fetchLine){
    const fetchLineEnd = c.indexOf('\n', c.indexOf(fetchLine[0])) + 1;
    
    // Insert: let _loginErr = 'Login failed.';
    const insertCode = `    let _loginErrMsg_ = 'Login failed. Please try again.';\n`;
    c = c.slice(0, fetchLineEnd) + insertCode + c.slice(fetchLineEnd);
    
    // Also add JSON parsing: if(!r.ok){ let d=await r.json()... }
    // and replace hardcoded string
    c = c
      .replace(errStr1, '_loginErrMsg_')
      .replace(errStr2, '_loginErrMsg_');
    
    // Now find where to inject the JSON parse  
    // After the fetch call, add: try{const _d=await r.clone().json(); _loginErrMsg_=_d.error||_d.message||_loginErrMsg_;}catch(e){}
    const newFetchEnd = c.indexOf('\n', c.indexOf(fetchLine[0])) + 1;
    const jsonParseCode = `    try{ const _de=await ${respVar}.clone().json(); _loginErrMsg_=_de.error||_de.message||_loginErrMsg_; }catch(e){}\n`;
    
    // Insert after fetch + 1 more line (skip the 'let _loginErrMsg_' line we added)
    const skipLine = c.indexOf('\n', newFetchEnd) + 1;
    c = c.slice(0, skipLine) + jsonParseCode + c.slice(skipLine);
    
    console.log('Fallback replacement done');
  }
}

if(c !== original){
  fs.writeFileSync(filePath, c);
  console.log('✅ File saved!');
} else {
  console.log('❌ No changes applied');
  console.log('Full file content around auth/login:');
  const ai = c.indexOf('auth/login');
  if(ai > -1) console.log(c.slice(Math.max(0,ai-300), ai+600));
}
NODEEOF

export LOGIN_FILE
node -e "
const fs=require('fs');
const f=process.env.LOGIN_FILE;
if(!f||!fs.existsSync(f)){process.exit(0);}
let c=fs.readFileSync(f,'utf8');
// Verify fix was applied
if(c.includes('_loginErrMsg_')||c.includes('_errD')||c.includes('_loginErr')){
  console.log('✅ Fix verified in file');
}else{
  console.log('⚠️ Fix may not have applied — check manually');
  // Show lines with Invalid
  c.split('\n').forEach((l,i)=>{
    if(l.includes('Invalid')||l.includes('auth/login')||l.includes('setErr')){
      console.log((i+1)+': '+l.trim());
    }
  });
}
"

step "Git Push"
cd $WORK
git add -A
git commit -m "fix: login page reads actual error message from backend response"
git push origin main

[ -d "$FE/.git" ] && [ "$FE" != "$WORK" ] && cd $FE && git add -A && git commit -m "fix: login shows backend error" 2>/dev/null && git push origin main 2>/dev/null

echo ""
ok "Done! Deploy ~2-3 min"
echo "Test: claudeaip03@gmail.com → should show 'Your account has been removed by admin.'"
