#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — F36 Onboarding Tour (BACKEND)
#  1. Patch User.js  — add onboarded + badges fields
#  2. Patch auth.js  — redirect to /onboarding after verify-otp
#  3. Add route POST /api/auth/complete-onboarding
# ═══════════════════════════════════════════════════════════════
set -e

USER_F=$(find . -path "*/models/User.js" | grep -v node_modules | head -1)
AUTH_F=$(find . -path "*/routes/auth.js"  | grep -v node_modules | head -1)
echo "User.js : $USER_F"
echo "auth.js : $AUTH_F"

cp "$USER_F" "${USER_F}.bak_f36"
cp "$AUTH_F" "${AUTH_F}.bak_f36"

# ════════════════════════════════════════════════════════════════
# 1. PATCH — User.js (add onboarded + badges fields)
# ════════════════════════════════════════════════════════════════
export USER_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.USER_F;
let c = fs.readFileSync(f, 'utf8');

if (c.includes('onboarded')) {
  console.log('ℹ️  User.js already has onboarded field');
} else {
  c = c.replace(
    "  // ── F35: Multi-device session control + Terms tracking ─────────",
    "  // ── F36: Onboarding Tour ──────────────────────────────────────────\n  onboarded:      { type: Boolean, default: false },\n  onboardedAt:    { type: Date,    default: null },\n  badges:         [{ id: String, name: String, unlockedAt: { type: Date, default: Date.now } }],\n\n  // ── F35: Multi-device session control + Terms tracking ─────────"
  );
  fs.writeFileSync(f, c);
  console.log('✅ User.js — onboarded + badges fields added');
}

const v = fs.readFileSync(f, 'utf8');
console.log('onboarded field:', v.includes('onboarded') ? '✅' : '❌');
console.log('badges field:',    v.includes('badges')    ? '✅' : '❌');
JSEOF

# ════════════════════════════════════════════════════════════════
# 2. PATCH — auth.js
#    a. verify-otp response: add needsOnboarding flag
#    b. Add POST /api/auth/complete-onboarding route
# ════════════════════════════════════════════════════════════════
export AUTH_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.AUTH_F;
let c = fs.readFileSync(f, 'utf8');

// ── a. verify-otp: add needsOnboarding in response ────────────
const OLD_RESP = "res.json({ token, role: user.role || 'student', name: user.name, studentId: user.studentId||null, welcomeSeen: user.welcomeSeen||false,\n               message: 'Email verified! Welcome to ProveRank.' })";
const NEW_RESP = "res.json({ token, role: user.role || 'student', name: user.name, studentId: user.studentId||null, welcomeSeen: user.welcomeSeen||false,\n               needsOnboarding: !user.onboarded, message: 'Email verified! Welcome to ProveRank.' })";

if (!c.includes('needsOnboarding')) {
  if (c.includes(OLD_RESP)) {
    c = c.replace(OLD_RESP, NEW_RESP);
    console.log('✅ verify-otp: needsOnboarding flag added');
  } else {
    // Flexible patch
    c = c.replace(
      "welcomeSeen: user.welcomeSeen||false,\n               message: 'Email verified! Welcome to ProveRank.'",
      "welcomeSeen: user.welcomeSeen||false,\n               needsOnboarding: !user.onboarded, message: 'Email verified! Welcome to ProveRank.'"
    );
    console.log('✅ verify-otp patched (flexible match)');
  }
} else {
  console.log('ℹ️  needsOnboarding already in verify-otp');
}

// ── b. Add complete-onboarding route ─────────────────────────
if (c.includes('complete-onboarding')) {
  console.log('ℹ️  complete-onboarding route already exists');
} else {
  const ROUTE = `
// ── F36: Complete Onboarding — mark user as onboarded + give Explorer badge ──
router.post('/complete-onboarding', async (req, res) => {
  try {
    const token   = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ message: 'Token required' })

    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ message: 'Invalid token' }) }

    const user = await User.findById(decoded.id)
    if (!user) return res.status(404).json({ message: 'User not found' })

    if (!user.onboarded) {
      // Add Explorer badge if not already present
      const hasExplorer = (user.badges || []).some(b => b.id === 'explorer')
      const badges = hasExplorer ? user.badges : [
        ...(user.badges || []),
        { id: 'explorer', name: 'Explorer', unlockedAt: new Date() }
      ]
      await User.findByIdAndUpdate(decoded.id, {
        onboarded: true, onboardedAt: new Date(), badges
      })
      return res.json({ success: true, badge: 'explorer', message: 'Onboarding complete! Explorer badge unlocked.' })
    }
    res.json({ success: true, message: 'Already onboarded' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

`;
  // Insert before module.exports
  c = c.replace('module.exports = router', ROUTE + 'module.exports = router');
  console.log('✅ /complete-onboarding route added');
}

fs.writeFileSync(f, c);

// ── Verify ────────────────────────────────────────────────────
const v = fs.readFileSync(f, 'utf8');
console.log('needsOnboarding in verify-otp:', v.includes('needsOnboarding') ? '✅' : '❌');
console.log('complete-onboarding route:',     v.includes('complete-onboarding') ? '✅' : '❌');
console.log('Explorer badge logic:',           v.includes("'explorer'") ? '✅' : '❌');
JSEOF

# ════════════════════════════════════════════════════════════════
# VERIFY
# ════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════"
echo "  🔍 Backend F36 — Verification"
echo "═══════════════════════════════════════════════"
export USER_F AUTH_F
node << 'JSEOF'
const fs = require('fs');
const u  = fs.readFileSync(process.env.USER_F, 'utf8');
const a  = fs.readFileSync(process.env.AUTH_F, 'utf8');

const checks = [
  ['User.js: onboarded field',           u.includes('onboarded')],
  ['User.js: onboardedAt field',         u.includes('onboardedAt')],
  ['User.js: badges array field',        u.includes('badges')],
  ['auth.js: needsOnboarding in response', a.includes('needsOnboarding')],
  ['auth.js: /complete-onboarding route',  a.includes('complete-onboarding')],
  ['auth.js: Explorer badge unlock',       a.includes("'explorer'")],
];

let pass=0, fail=0;
checks.forEach(([l,v]) => { console.log((v?'✅':'❌')+' '+l); v?pass++:fail++; });
console.log('\n'+pass+'/'+checks.length+' passed');
if (fail===0) console.log('🎉 Backend F36 ready!');
else          console.log('⚠️  '+fail+' issue(s)');
JSEOF

echo ""
echo "git add . && git commit -m 'feat: F36 onboarding — backend (User fields + complete-onboarding route)' && git push"
