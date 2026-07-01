#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — F35 Backend: Session Control + Email Check     ║
# ║              + Terms Acceptance Tracking                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
SRC=/home/runner/workspace/src
echo "🚀 F35 Backend setup..."

# ═══════════════════════════════════════════════════════════════
# 1. User.js — add session/terms tracking fields
# ═══════════════════════════════════════════════════════════════
node << 'EOF'
const fs = require('fs');
const f  = '/home/runner/workspace/src/models/User.js';
let c = fs.readFileSync(f, 'utf8');

if (c.includes('activeSessionToken')) {
  console.log('✅ User.js fields already present');
} else {
  const OLD = `  parentEmail: { type: String }\n}, { timestamps: true });`;
  const NEW = `  parentEmail: { type: String },

  // ── F35: Multi-device session control + Terms tracking ─────────
  activeSessionToken: { type: String, default: null },
  termsAccepted:      { type: Boolean, default: false },
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },
}, { timestamps: true });`;

  if (c.includes(OLD)) {
    c = c.replace(OLD, NEW);
    fs.writeFileSync(f, c);
    console.log('✅ User.js: session + terms fields added');
  } else {
    console.log('❌ User.js anchor not found — manual check needed');
  }
}
EOF

# ═══════════════════════════════════════════════════════════════
# 2. auth.js — multi-device session, email check, accept-terms
# ═══════════════════════════════════════════════════════════════
node << 'EOF'
const fs = require('fs');
const f  = '/home/runner/workspace/src/routes/auth.js';
let c = fs.readFileSync(f, 'utf8');
let changed = 0;

// ── Patch 1: Password login — set activeSessionToken ──────────────
const OLD1 = `    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', name:user.name||'',studentId:user.studentId||null,welcomeSeen:user.welcomeSeen||false,message:'Login successful' })`;

const NEW1 = `    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    // F35.1 — Multi-device session control: new login invalidates old device
    await User.collection.updateOne({ _id: user._id }, { $set: { activeSessionToken: token } })
    res.json({ token, role: user.role || 'student', name:user.name||'',studentId:user.studentId||null,welcomeSeen:user.welcomeSeen||false,message:'Login successful' })`;

if (c.includes(OLD1)) { c = c.replace(OLD1, NEW1); changed++; console.log('✅ Patch 1: password login session token'); }
else console.log('⚠️  Patch 1: anchor not found (may already be patched)');

// ── Patch 2: OTP login — set activeSessionToken ────────────────────
const OLD2 = `    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, role: user.role || 'student', message: 'Login successful' })`;

const NEW2 = `    const token = jwt.sign(
      { id: user._id.toString(), role: user.role || 'student' },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    // F35.1 — Multi-device session control
    await User.collection.updateOne({ _id: user._id }, { $set: { activeSessionToken: token } })
    res.json({ token, role: user.role || 'student', message: 'Login successful' })`;

if (c.includes(OLD2)) { c = c.replace(OLD2, NEW2); changed++; console.log('✅ Patch 2: OTP login session token'); }
else console.log('⚠️  Patch 2: anchor not found (may already be patched)');

// ── Patch 3: /me route — verify session token still active ────────
const OLD3 = `    const user = await User.collection.findOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { projection: { password:0, emailVerifyOTP:0, loginOTP:0, resetOTP:0, emailVerifyToken:0 } }
    )
    if (!user) return res.status(404).json({ message: 'User not found' })
    res.json({ ...user, studentId: user.studentId||null, loginHistory: user.loginHistory || [] })`;

const OLD3_TOKEN_VAR = `    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)\n    const mongoose = require('mongoose')\n` + OLD3;

const NEW3 = `    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const user = await User.collection.findOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { projection: { password:0, emailVerifyOTP:0, loginOTP:0, resetOTP:0, emailVerifyToken:0 } }
    )
    if (!user) return res.status(404).json({ message: 'User not found' })
    // F35.1 — Reject if logged in on another device (session replaced)
    const presentedToken = auth.split(' ')[1]
    if ((user.role==='student'||!user.role) && user.activeSessionToken && user.activeSessionToken !== presentedToken) {
      return res.status(401).json({ message: 'Session expired — you have been logged in on another device.', code: 'SESSION_REPLACED' })
    }
    res.json({ ...user, studentId: user.studentId||null, loginHistory: user.loginHistory || [] })`;

if (c.includes(OLD3_TOKEN_VAR)) { c = c.replace(OLD3_TOKEN_VAR, NEW3); changed++; console.log('✅ Patch 3: /me session validation'); }
else console.log('⚠️  Patch 3: anchor not found (may already be patched)');

// ── Patch 4 + 5: Add /check-email and /accept-terms before module.exports ─
if (!c.includes('/check-email')) {
  const NEW_ROUTES = `
// ── F35.8 — Real-time Email Availability Check ─────────────────────
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ message: 'Email required' })
    const validFormat = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)
    if (!validFormat) return res.json({ valid:false, available:false, message:'Invalid email format' })
    const existing = await User.collection.findOne({ email })
    const taken = !!(existing && (existing.emailVerified || existing.verified) && !existing.archived)
    res.json({ valid:true, available: !taken, message: taken ? 'Email already registered' : 'Email available' })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

// ── F35.15 — Accept Terms (timestamp + version tracking) ───────────
router.post('/accept-terms', async (req, res) => {
  try {
    const auth = req.headers.authorization
    if (!auth) return res.status(401).json({ message: 'No token' })
    const payload = jwt.verify(auth.split(' ')[1], JWT_SECRET)
    const mongoose = require('mongoose')
    const TERMS_VERSION = 'Version 2.1 — Updated March 2026'
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(payload.id) },
      { \$set: { termsAccepted:true, termsAcceptedAt:new Date(), termsVersion: TERMS_VERSION } }
    )
    res.json({ message: 'Terms accepted', version: TERMS_VERSION })
  } catch (err) {
    res.status(500).json({ message: 'Server error' })
  }
})

`;
  c = c.replace('module.exports = router', NEW_ROUTES + 'module.exports = router');
  changed++;
  console.log('✅ Patch 4+5: /check-email and /accept-terms routes added');
} else {
  console.log('✅ Patch 4+5: routes already present');
}

fs.writeFileSync(f, c);
console.log(`\n✅ auth.js updated — ${changed} patches applied`);
EOF

# ─── Verification ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  F35 Backend — Verification"
echo "══════════════════════════════════════════════════════"
U=$SRC/models/User.js
A=$SRC/routes/auth.js
chk(){ grep -q "$2" "$1" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }

chk "$U" "activeSessionToken"  "35.1  User model: activeSessionToken field"
chk "$U" "termsAcceptedAt"     "35.15 User model: termsAcceptedAt field"
chk "$U" "termsVersion"        "35.15 User model: termsVersion field"
chk "$A" "F35.1.*Multi-device session control: new login" "35.1  Password login sets session token"
chk "$A" "F35.1.*Multi-device session control\$"           "35.1  OTP login sets session token"
chk "$A" "SESSION_REPLACED"    "35.1  /me route rejects replaced session"
chk "$A" "/check-email"        "35.8  Email availability check endpoint"
chk "$A" "/accept-terms"       "35.15 Accept-terms endpoint (timestamp+version)"
chk "$A" "Version 2.1"         "35.15 Terms version string"

echo ""
echo "  Flow:"
echo "  Login → activeSessionToken saved → old device's /me call fails"
echo "  → old device auto-logs-out (frontend handles SESSION_REPLACED)"
echo ""
echo "══════════════════════════════════════════════════════"
echo "🎉 git add . && git commit -m 'feat: F35 backend — session control + email check' && git push"
echo "══════════════════════════════════════════════════════"
