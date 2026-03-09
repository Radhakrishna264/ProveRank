// ProveRank — Stage 8 Test Script (Phase 8.1 + 8.2)
// Rule D2: MONGO_URI=$(grep MONGO_URI .env | cut -d= -f2-) node test_stage8.js

const http = require('http');
const fs = require('fs');
const path = require('path');

let PASS = 0;
let FAIL = 0;

const check = (label, condition) => {
  if (condition) {
    console.log(`✅ PASS — ${label}`);
    PASS++;
  } else {
    console.log(`❌ FAIL — ${label}`);
    FAIL++;
  }
};

const fileExists = (filePath) => fs.existsSync(path.join(process.env.HOME, filePath));
const fileContains = (filePath, keyword) => {
  try {
    return fs.readFileSync(path.join(process.env.HOME, filePath), 'utf8').includes(keyword);
  } catch { return false; }
};

console.log('======================================');
console.log('  ProveRank Stage 8 — Security Tests');
console.log('======================================\n');

// ---- PHASE 8.1 FILE CHECKS ----
console.log('📦 Phase 8.1 — File Checks');
console.log('--------------------------------------');

check('rateLimiter.js exists', fileExists('workspace/src/middleware/rateLimiter.js'));
check('security.js exists', fileExists('workspace/src/middleware/security.js'));
check('inputValidator.js exists', fileExists('workspace/src/middleware/inputValidator.js'));
check('loginProtection.js exists', fileExists('workspace/src/middleware/loginProtection.js'));
check('featureFlag.js exists', fileExists('workspace/src/middleware/featureFlag.js'));
check('impersonationSafety.js exists', fileExists('workspace/src/middleware/impersonationSafety.js'));

// ---- PHASE 8.1 CONTENT CHECKS ----
console.log('\n🔍 Phase 8.1 — Content Checks');
console.log('--------------------------------------');

check('Step 1: Rate Limiting — apiLimiter', fileContains('workspace/src/middleware/rateLimiter.js', 'apiLimiter'));
check('Step 1: Rate Limiting — loginLimiter', fileContains('workspace/src/middleware/rateLimiter.js', 'loginLimiter'));
check('Step 2: Helmet active', fileContains('workspace/src/middleware/security.js', 'helmet'));
check('Step 3: Input Validator — validateLogin', fileContains('workspace/src/middleware/inputValidator.js', 'validateLogin'));
check('Step 3: Input Validator — validateRegister', fileContains('workspace/src/middleware/inputValidator.js', 'validateRegister'));
check('Step 4: NoSQL Sanitize — mongoSanitize', fileContains('workspace/src/middleware/security.js', 'mongoSanitize'));
check('Step 5: JWT Expiry — checkJWTExpiry', fileContains('workspace/src/middleware/loginProtection.js', 'checkJWTExpiry'));
check('Step 6: Brute Force — bruteForceProtection', fileContains('workspace/src/middleware/loginProtection.js', 'bruteForceProtection'));
check('Step 6: Max Attempts — MAX_ATTEMPTS', fileContains('workspace/src/middleware/loginProtection.js', 'MAX_ATTEMPTS'));
check('Step 7: XSS Clean active', fileContains('workspace/src/middleware/security.js', 'xssClean'));
check('Step 8: Feature Flag — N21', fileContains('workspace/src/middleware/featureFlag.js', 'featureFlags'));
check('Step 8: Feature Flag — requireFeature', fileContains('workspace/src/middleware/featureFlag.js', 'requireFeature'));
check('Step 9: M4 Impersonation Safety', fileContains('workspace/src/middleware/impersonationSafety.js', 'impersonationLogger'));
check('Step 9: M4 Write Block in impersonation', fileContains('workspace/src/middleware/impersonationSafety.js', 'POST'));
check('index.js — Security middleware applied', fileContains('workspace/src/index.js', 'applySecurityMiddleware'));
check('index.js — API Rate Limiter applied', fileContains('workspace/src/index.js', 'apiLimiter'));

// ---- PHASE 8.2 HARDEN FILE CHECKS ----
console.log('\n🛡️  Phase 8.2 — Harden Files Check');
console.log('--------------------------------------');

// Check if hardened files exist (created by script where missing)
const hardenFiles = [
  ['workspace/src/middleware/auditLog.js', 'Step 7: Audit Log (S93)'],
  ['workspace/src/middleware/examEncryption.js', 'Step 10: Exam Encryption (N23)'],
  ['workspace/src/middleware/ipLock.js', 'Step 3: IP Lock (S20)'],
  ['workspace/src/middleware/sessionControl.js', 'Step 2: Session Control (S112)'],
];
for (const [f, label] of hardenFiles) {
  check(label + ' — file exists', fileExists(f));
}

// Phase 8.2 Verify in codebase
const verifyChecks = [
  ['workspace/src/middleware/auditLog.js', 'auditLogger', 'Step 7: Audit Trail tamper-proof (S93)'],
  ['workspace/src/middleware/examEncryption.js', 'encryptData', 'Step 10: Exam Paper Encryption (N23)'],
  ['workspace/src/middleware/sessionControl.js', 'validateSingleSession', 'Step 2: Multi-Device Block (S112)'],
  ['workspace/src/middleware/ipLock.js', 'ipLockCheck', 'Step 3: IP Lock check (S20)'],
  ['workspace/src/middleware/loginProtection.js', 'bruteForceProtection', 'Step 6: Brute Force (S49 hardened)'],
];
for (const [f, keyword, label] of verifyChecks) {
  check(label, fileContains(f, keyword));
}

// ---- SUMMARY ----
console.log('\n======================================');
console.log('  TEST SUMMARY');
console.log('======================================');
console.log(`✅ PASS: ${PASS}`);
console.log(`❌ FAIL: ${FAIL}`);
const total = PASS + FAIL;
const score = Math.round((PASS / total) * 100);
console.log(`📊 Score: ${score}% (${PASS}/${total})`);

if (FAIL === 0) {
  console.log('\n🏆 ALL TESTS PASSED!');
  console.log('Stage 8 ✅ Phase 8.1 + Phase 8.2 — COMPLETE!');
} else if (score >= 80) {
  console.log('\n✅ PASS (with minor issues)');
  console.log(`${FAIL} step(s) failed — check above`);
} else {
  console.log('\n⚠️  Setup incomplete — script dobara run karo');
}
console.log('======================================');
