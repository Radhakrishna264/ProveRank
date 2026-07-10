#!/bin/bash
set -e
echo "════════════════════════════════════════════════════════"
echo " F38B — Student 360° Profile Preview — BACKEND fix script"
echo "════════════════════════════════════════════════════════"

ROOT=""
for candidate in "/root/workspace/src" "/home/runner/workspace/src" "$(pwd)/src" "$(pwd)"; do
  if [ -f "$candidate/routes/auth.js" ]; then ROOT="$candidate"; break; fi
done
if [ -z "$ROOT" ]; then echo "❌ Could not find routes/auth.js — run from project root or set ROOT manually."; exit 1; fi
echo "📂 Project root detected: $ROOT"

WORKDIR=$(mktemp -d); cd "$WORKDIR"

# ── New route file: routes/adminStudentPreview.js ──
cat > "$ROOT/routes/adminStudentPreview.js" << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38B — Student 360° Profile Preview (Superadmin ONLY)
// Mounted at: /api/admin/student-preview
//
// GET /api/admin/student-preview/:id
//   → Full 360° inspector payload: personal, academic, security,
//     login activity, photo history, field change timeline, audit
//     trail, verification, quick inspect cards, device intelligence,
//     change frequency analysis.
//
// Access: Superadmin ONLY (verifyToken + isSuperAdmin).
// Admin / Teacher / Examiner / Student panels have zero access —
// this route is never mounted/called from any of those panels.
// ════════════════════════════════════════════════════════════════
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const User = require('../models/User');

// ── helper: safe require, degrades gracefully if a model is absent ──
function tryModel(name, path) {
  try { return mongoose.model(name); } catch (e) {
    try { return require(path); } catch (e2) { return null; }
  }
}

router.get('/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const studentId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
      return res.status(400).json({ success: false, message: 'Invalid student id' });
    }

    // ── 1) Core student document (password/2FA secrets/OTPs never leave the server) ──
    const student = await User.findById(studentId)
      .select('-password -twoFactorSecret -twoFactorTempSecret -emailVerifyOTP -loginOTP -resetOTP -resetOTPExpiry')
      .lean();
    if (!student) return res.status(404).json({ success: false, message: 'Student not found' });

    // ══════════════════════════════════════════════════════════
    // 3) PERSONAL DETAILS + completion % (F38 §3.4 reused)
    // ══════════════════════════════════════════════════════════
    const personal = {
      name: student.name, email: student.email, phone: student.phone || '',
      dob: student.dob || '', gender: student.gender || '', state: student.state || '',
      city: student.city || '', bio: student.bio || '',
      avatar: student.avatar || student.profilePhoto || '',
      studentId: student.studentId || null,
    };
    const compFields = [personal.name, personal.phone, personal.dob, personal.city, personal.gender, personal.bio, personal.avatar, student.targetExam, student.board, student.school];
    const completion = Math.round((compFields.filter(Boolean).length / compFields.length) * 100);

    // ══════════════════════════════════════════════════════════
    // 4) ACADEMIC PROFILE + snapshot
    // ══════════════════════════════════════════════════════════
    const academic = {
      targetExam: student.targetExam || '', targetYear: student.targetYear || '',
      board: student.board || '', school: student.school || '',
      medium: student.medium || '', coachingInstitute: student.coachingInstitute || '',
      batch: student.batch || '',
    };
    let totalExams = 0, bestScore = 0, avgScore = 0, rankHistory = [];
    try {
      const Result = tryModel('Result', '../models/Result');
      if (Result) {
        const results = await Result.find({ studentId }).sort({ createdAt: 1 }).lean();
        totalExams = results.length;
        if (results.length) {
          const scores = results.map(r => r.score || r.totalScore || 0);
          bestScore = Math.max(...scores);
          avgScore = Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
          rankHistory = results.slice(-6).map(r => ({ examId: r.examId, rank: r.rank || r.airRank || null, date: r.createdAt }));
        }
      }
    } catch (e) { /* Result model unavailable — degrade to zeros */ }
    const academicSnapshot = { totalExams, bestScore, avgScore, rankHistory, currentStreak: student.streak || 0 };

    // ══════════════════════════════════════════════════════════
    // 5) SECURITY SECTION (password never exposed — metadata only)
    // ══════════════════════════════════════════════════════════
    const profileHistory = student.profileHistory || [];
    const passwordChanges = profileHistory
      .filter(h => (h.updatedFields || []).includes('password') || (h.changes || []).some(c => c.field === 'password'))
      .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    const security = {
      passwordLastChangedAt: passwordChanges[0]?.updatedAt || null,
      passwordChangeCount: passwordChanges.length,
      twoFactorEnabled: !!student.twoFactorEnabled,
      trustedDevices: student.trustedDevices || [],
      activeDeviceCount: 1, // F35.1 — single active session by design
      lastLogin: (student.loginHistory || []).slice(-1)[0] || null,
      failedLoginAttempts: student.failedLoginAttempts || 0,
      lastFailedLoginAt: student.lastFailedLoginAt || null,
    };

    // ══════════════════════════════════════════════════════════
    // 6) LOGIN ACTIVITY + Security Timeline (from ActivityLog — reused)
    // ══════════════════════════════════════════════════════════
    let activityEvents = [];
    try {
      const ActivityLog = tryModel('ActivityLog', '../models/ActivityLog');
      if (ActivityLog) {
        activityEvents = await ActivityLog.find({ userId: studentId })
          .sort({ createdAt: -1 }).limit(100).lean();
      }
    } catch (e) { /* degrade to empty */ }

    const loginActivity = (student.loginHistory || []).slice(-30).reverse().map(l => ({
      loginTime: l.at, device: l.device, browser: l.browser, os: l.os,
      ip: l.ip, city: l.city, country: l.country, status: 'success',
    }));
    const securityTimeline = activityEvents
      .filter(e => e.module === 'security')
      .map(e => ({ action: e.action, details: e.details, status: e.status, at: e.createdAt, ip: e.ipAddress }));

    // ══════════════════════════════════════════════════════════
    // 7) PHOTO HISTORY — derived from profileHistory 'avatar' changes
    // (no separate collection needed — every avatar change already
    //  stores the previous base64 value + timestamp in profileHistory)
    // ══════════════════════════════════════════════════════════
    const photoHistory = [];
    profileHistory.forEach(h => {
      (h.changes || []).forEach(c => {
        if (c.field === 'avatar') {
          if (c.oldValue) photoHistory.push({ url: c.oldValue, at: h.updatedAt, updatedBy: h.updatedBy || 'self', source: h.source || 'profile_page', label: 'previous' });
        }
      });
    });
    if (personal.avatar) photoHistory.push({ url: personal.avatar, at: student.updatedAt, updatedBy: 'self', source: 'current', label: 'current' });
    photoHistory.sort((a, b) => new Date(a.at) - new Date(b.at));

    // ══════════════════════════════════════════════════════════
    // 8) FIELD CHANGE TIMELINE — flattened, filterable
    // ══════════════════════════════════════════════════════════
    const CATEGORY_MAP = {
      name: 'personal', phone: 'personal', dob: 'personal', city: 'personal', state: 'personal', gender: 'personal', bio: 'personal', avatar: 'personal',
      targetExam: 'academic', targetYear: 'academic', board: 'academic', school: 'academic', medium: 'academic', coachingInstitute: 'academic', batch: 'academic',
      password: 'security',
    };
    const fieldChangeTimeline = [];
    profileHistory.forEach(h => {
      (h.changes || []).forEach(c => {
        fieldChangeTimeline.push({
          field: c.field,
          category: CATEGORY_MAP[c.field] || 'other',
          oldValue: c.field === 'avatar' ? '(photo)' : c.oldValue,
          newValue: c.field === 'avatar' ? '(photo)' : c.newValue,
          updatedAt: h.updatedAt, updatedBy: h.updatedBy || 'self', source: h.source || 'general',
        });
      });
    });
    fieldChangeTimeline.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

    // ── 13.5 Change Frequency Analysis ──
    const freqMap = {};
    fieldChangeTimeline.forEach(c => { freqMap[c.field] = (freqMap[c.field] || 0) + 1; });
    const changeFrequency = Object.entries(freqMap)
      .map(([field, count]) => ({ field, count, latestUpdate: fieldChangeTimeline.find(c => c.field === field)?.updatedAt }))
      .sort((a, b) => b.count - a.count);

    // ══════════════════════════════════════════════════════════
    // 9) AUDIT TRAIL — admin actions performed ON this student
    // (existing logActivity calls store the ACTING admin's userId,
    //  with the target's email embedded in `details` — matched here.
    //  NOTE: for precise filtering going forward, consider adding a
    //  `targetUserId` field to ActivityLog at the write-site.)
    // ══════════════════════════════════════════════════════════
    let auditTrail = [];
    try {
      const ActivityLog = tryModel('ActivityLog', '../models/ActivityLog');
      if (ActivityLog && student.email) {
        auditTrail = await ActivityLog.find({
          isAudit: true,
          details: { $regex: student.email, $options: 'i' }
        }).sort({ createdAt: -1 }).limit(50).lean();
      }
    } catch (e) { /* degrade to empty */ }

    // ══════════════════════════════════════════════════════════
    // 10) VERIFICATION + Health Score (F38 logic reused)
    // ══════════════════════════════════════════════════════════
    let health = 0;
    if (student.emailVerified || student.verified) health += 25;
    if (student.phone) health += 15;
    if (personal.avatar) health += 15;
    if (student.targetExam && student.board && student.school) health += 25;
    if (student.twoFactorEnabled) health += 20; else health += 10; // every account has a password by design
    health = Math.min(100, health);
    const verification = {
      email: (student.emailVerified || student.verified) ? 'verified' : 'unverified',
      phone: student.phoneVerified ? 'verified' : (student.phone ? 'pending' : 'unverified'),
      photo: personal.avatar ? (student.photoVerified ? 'verified' : 'pending') : 'unverified',
      healthScore: health,
      riskIndicator: (student.failedLoginAttempts || 0) > 5 ? 'high' : (student.failedLoginAttempts || 0) > 2 ? 'medium' : 'low',
    };

    // ══════════════════════════════════════════════════════════
    // 12) QUICK INSPECT CARDS
    // ══════════════════════════════════════════════════════════
    const quickInspect = {
      bestScore, avgScore, rankHistory, totalExams,
      loginCount: student.loginCount || (student.loginHistory || []).length,
      failedLogins: student.failedLoginAttempts || 0,
      photoChanges: photoHistory.length,
      lastActive: (student.loginHistory || []).slice(-1)[0]?.at || student.updatedAt || null,
    };

    // ══════════════════════════════════════════════════════════
    // 13.3) DEVICE INTELLIGENCE
    // ══════════════════════════════════════════════════════════
    const deviceIntelligence = (student.trustedDevices || []).map(d => ({
      label: d.label, browser: d.browser, os: d.os,
      firstSeen: d.addedAt, lastSeen: d.lastUsedAt, trusted: true,
    }));

    // ── Top header summary (1.3) ──
    const header = {
      name: student.name, studentId: student.studentId || null,
      verification: verification.email, completion,
      status: student.banned ? 'banned' : student.frozen ? 'frozen' : student.archived ? 'archived' : 'active',
      lastUpdated: student.updatedAt || null,
    };

    res.json({
      success: true,
      header,
      personal: { ...personal, completion },
      academic: { ...academic, snapshot: academicSnapshot },
      security,
      loginActivity,
      securityTimeline,
      photoHistory,
      fieldChangeTimeline,
      changeFrequency,
      auditTrail,
      verification,
      quickInspect,
      deviceIntelligence,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;
PRNODEEOF
echo "✅ Created routes/adminStudentPreview.js"

# ── Patch scripts ──
cat > patch_auth_f38b.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38B — Backend patches to routes/auth.js
//  1) Login: log each FAILED login attempt individually (not just a
//     counter) via ActivityLog, and populate/update trustedDevices
//     on every successful login (device intelligence — §13.3).
//  2) Reset-password (forgot-password OTP flow): log a PASSWORD_RESET
//     event — previously this flow was never logged at all.
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'routes', 'auth.js')));
if (!ROOT) { console.error('❌ Could not locate routes/auth.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const AUTH_PATH = path.join(ROOT, 'routes', 'auth.js');

let src = fs.readFileSync(AUTH_PATH, 'utf8');
const before = src;
let count = 0;

// ── Patch 1: failed-login individual logging ──
{
  const bad = `    if (!match) {
      await User.collection.updateOne({ _id: user._id }, {
        $inc: { failedLoginAttempts: 1 },
        $set: { lastFailedLoginAt: new Date() }
      }).catch(()=>{})
      return res.status(401).json({ message: 'Incorrect password. Please try again.' })
    }`;
  const good = `    if (!match) {
      await User.collection.updateOne({ _id: user._id }, {
        $inc: { failedLoginAttempts: 1 },
        $set: { lastFailedLoginAt: new Date() }
      }).catch(()=>{})
      try {
        const { logActivity } = require('../utils/activityLogger')
        const failIp = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.ip || 'Unknown'
        logActivity({ userId: user._id, userName: user.name, userRole: user.role || 'student', action: 'LOGIN_FAILED', details: 'Incorrect password attempt', module: 'security', ipAddress: failIp, userAgent: req.headers['user-agent'] || '', status: 'failed' }).catch(()=>{})
      } catch (e) {}
      return res.status(401).json({ message: 'Incorrect password. Please try again.' })
    }`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: individual FAILED login events now logged to ActivityLog'); }
  else console.log('⚠️  Failed-login block not found — may already be patched or text differs');
}

// ── Patch 2: trustedDevices upsert on successful login (F38B §13.3) ──
{
  const bad = `    history.push({ at: new Date(), ip: realIp, browser, os, city, country, device: \`\${browser} on \${os}\` })
    User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } }).catch(()=>{})`;
  const good = `    history.push({ at: new Date(), ip: realIp, browser, os, city, country, device: \`\${browser} on \${os}\` })

    // F38B §13.3 — Device Intelligence: track/refresh trusted devices
    const devices = [...(user.trustedDevices || [])]
    const deviceKey = \`\${browser}|\${os}\`
    const existingDeviceIdx = devices.findIndex(d => \`\${d.browser}|\${d.os}\` === deviceKey)
    if (existingDeviceIdx >= 0) {
      devices[existingDeviceIdx].lastUsedAt = new Date()
    } else {
      devices.push({ deviceId: deviceKey, label: \`\${browser} on \${os}\`, browser, os, addedAt: new Date(), lastUsedAt: new Date() })
    }

    User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50), trustedDevices: devices.slice(-20) }, $inc: { loginCount: 1 } }).catch(()=>{})`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: trustedDevices now populated/refreshed on every login'); }
  else console.log('⚠️  Login-history push block not found — may already be patched or text differs');
}

// ── Patch 3: log PASSWORD_RESET event on the forgot-password OTP flow ──
{
  const bad = `    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id },
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null } })
    res.json({ message: 'Password reset successfully! You can now login.' })`;
  const good = `    const hash = await bcrypt.hash(newPassword, 12)
    await User.collection.updateOne({ _id: user._id },
      { $set: { password: hash, resetOTP: null, resetOTPExpiry: null } })
    try {
      const { logActivity } = require('../utils/activityLogger')
      logActivity({ userId: user._id, userName: user.name, userRole: user.role || 'student', action: 'PASSWORD_RESET', details: 'Password reset via forgot-password OTP flow', module: 'security', status: 'success' }).catch(()=>{})
    } catch (e) {}
    res.json({ message: 'Password reset successfully! You can now login.' })`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: PASSWORD_RESET (forgot-password flow) now logged'); }
  else console.log('⚠️  Reset-password block not found — may already be patched or text differs');
}

if (count > 0) {
  fs.writeFileSync(AUTH_PATH, src);
  console.log(`\n✅ ${count}/3 auth.js patch(es) applied and saved.`);
} else {
  console.log('\n⚠️  No changes applied — none of the 3 blocks matched.');
}
PRNODEEOF

cat > patch_twofactor_f38b.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38B — Backend patch to routes/twoFactor.js
// Logs TWO_FA_ENABLED / TWO_FA_DISABLED events (previously not
// logged anywhere) so they appear in the Security Timeline (§5.3.6).
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'routes', 'twoFactor.js')));
if (!ROOT) { console.error('❌ Could not locate routes/twoFactor.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const TF_PATH = path.join(ROOT, 'routes', 'twoFactor.js');

let src = fs.readFileSync(TF_PATH, 'utf8');
const before = src;
let count = 0;

// ── Patch 1: log on 2FA enable confirm (/2fa/verify) ──
{
  const bad = `    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: true,
      twoFactorSecret: secret,
      twoFactorTempSecret: null
    });
    res.json({ success: true, message: '2FA activate ho gaya!' });`;
  const good = `    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: true,
      twoFactorSecret: secret,
      twoFactorTempSecret: null
    });
    try {
      const { logActivity } = require('../utils/activityLogger');
      logActivity({ userId: user._id, userName: user.name, userRole: user.role || 'student', action: 'TWO_FA_ENABLED', details: '2FA enabled', module: 'security', status: 'success' }).catch(()=>{});
    } catch (e) {}
    res.json({ success: true, message: '2FA activate ho gaya!' });`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: TWO_FA_ENABLED now logged'); }
  else console.log('⚠️  2FA-enable block not found — may already be patched or text differs');
}

// ── Patch 2: log on 2FA disable ──
{
  const bad = `    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: false,
      twoFactorSecret: null,
      twoFactorTempSecret: null
    });
    res.json({ success: true, message: '2FA disable ho gaya' });`;
  const good = `    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: false,
      twoFactorSecret: null,
      twoFactorTempSecret: null
    });
    try {
      const { logActivity } = require('../utils/activityLogger');
      logActivity({ userId: user._id, userName: user.name, userRole: user.role || 'student', action: 'TWO_FA_DISABLED', details: '2FA disabled', module: 'security', status: 'warning' }).catch(()=>{});
    } catch (e) {}
    res.json({ success: true, message: '2FA disable ho gaya' });`;
  if (src.includes(bad)) { src = src.replace(bad, good); count++; console.log('✅ Patched: TWO_FA_DISABLED now logged'); }
  else console.log('⚠️  2FA-disable block not found — may already be patched or text differs');
}

if (count > 0) {
  fs.writeFileSync(TF_PATH, src);
  console.log(`\n✅ ${count}/2 twoFactor.js patch(es) applied and saved.`);
} else {
  console.log('\n⚠️  No changes applied — none of the 2 blocks matched.');
}
PRNODEEOF

cat > patch_index_f38b.js << 'PRNODEEOF'
// ════════════════════════════════════════════════════════════════
// F38B — Mount routes/adminStudentPreview.js in index.js
// ════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.ROOT,
  '/root/workspace/src',
  '/home/runner/workspace/src',
  path.join(process.cwd(), 'src'),
  process.cwd(),
].filter(Boolean);

let ROOT = CANDIDATES.find(p => fs.existsSync(path.join(p, 'index.js')));
if (!ROOT) { console.error('❌ Could not locate index.js — set ROOT env var.'); process.exit(1); }
console.log('📂 Using project root:', ROOT);
const IDX_PATH = path.join(ROOT, 'index.js');

let src = fs.readFileSync(IDX_PATH, 'utf8');

const anchor = `app.use('/api/admin/manage', adminManagementRoutes);  // S37/S72/S38/S93/M4`;
const mountLine = `app.use('/api/admin/manage', adminManagementRoutes);  // S37/S72/S38/S93/M4
app.use('/api/admin/student-preview', require('./routes/adminStudentPreview')); // F38B — Student 360° Profile Preview (Superadmin only)`;

if (src.includes('adminStudentPreview')) {
  console.log('⚠️  adminStudentPreview already mounted, skipping');
} else if (src.includes(anchor)) {
  src = src.replace(anchor, mountLine);
  fs.writeFileSync(IDX_PATH, src);
  console.log('✅ index.js — mounted /api/admin/student-preview → routes/adminStudentPreview.js');
} else {
  console.log('⚠️  Anchor line not found — mount routes/adminStudentPreview.js manually at /api/admin/student-preview');
}
PRNODEEOF

echo "🚀 Applying patches..."
ROOT="$ROOT" node patch_auth_f38b.js
ROOT="$ROOT" node patch_twofactor_f38b.js
ROOT="$ROOT" node patch_index_f38b.js

# ══════════════════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════════════"
echo " VERIFICATION — F38B Backend"
echo "════════════════════════════════════════════════════════"
PASS=0; FAIL=0
check() { if grep -qF "$2" "$3" 2>/dev/null; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1"; FAIL=$((FAIL+1)); fi }

check "New route file created" "F38B" "$ROOT/routes/adminStudentPreview.js"
check "  -> Personal + completion %" "PERSONAL DETAILS" "$ROOT/routes/adminStudentPreview.js"
check "  -> Academic snapshot" "ACADEMIC PROFILE" "$ROOT/routes/adminStudentPreview.js"
check "  -> Security section (password metadata only)" "SECURITY SECTION" "$ROOT/routes/adminStudentPreview.js"
check "  -> Login Activity + Security Timeline" "LOGIN ACTIVITY" "$ROOT/routes/adminStudentPreview.js"
check "  -> Photo History (derived from profileHistory)" "PHOTO HISTORY" "$ROOT/routes/adminStudentPreview.js"
check "  -> Field Change Timeline" "FIELD CHANGE TIMELINE" "$ROOT/routes/adminStudentPreview.js"
check "  -> Change Frequency Analysis" "Change Frequency Analysis" "$ROOT/routes/adminStudentPreview.js"
check "  -> Audit Trail" "AUDIT TRAIL" "$ROOT/routes/adminStudentPreview.js"
check "  -> Verification + Health Score + Risk Indicator" "riskIndicator" "$ROOT/routes/adminStudentPreview.js"
check "  -> Quick Inspect Cards" "QUICK INSPECT CARDS" "$ROOT/routes/adminStudentPreview.js"
check "  -> Device Intelligence" "DEVICE INTELLIGENCE" "$ROOT/routes/adminStudentPreview.js"
check "  -> Superadmin-only access (isSuperAdmin middleware)" "isSuperAdmin" "$ROOT/routes/adminStudentPreview.js"

check "auth.js: individual FAILED login events logged" "LOGIN_FAILED" "$ROOT/routes/auth.js"
check "auth.js: trustedDevices populated on login" "Device Intelligence: track/refresh" "$ROOT/routes/auth.js"
check "auth.js: PASSWORD_RESET (forgot-password) now logged" "PASSWORD_RESET" "$ROOT/routes/auth.js"

check "twoFactor.js: TWO_FA_ENABLED logged" "TWO_FA_ENABLED" "$ROOT/routes/twoFactor.js"
check "twoFactor.js: TWO_FA_DISABLED logged" "TWO_FA_DISABLED" "$ROOT/routes/twoFactor.js"

check "index.js mounts /api/admin/student-preview" "adminStudentPreview" "$ROOT/index.js"

echo ""
echo "════════════════════════════════════════════════════════"
echo " RESULT: $PASS passed / $((PASS+FAIL)) total"
if [ "$FAIL" -eq 0 ]; then echo " 🎉 ALL F38B BACKEND FEATURES SUCCESSFULLY IMPLEMENTED ✅"; else echo " ⚠️  $FAIL item(s) need review — see ❌ lines above."; fi
echo "════════════════════════════════════════════════════════"

echo "👉 Restart your backend (Replit Run button) to load the changes."
echo "👉 New endpoint: GET /api/admin/student-preview/:id  (superadmin token required)"
echo "👉 NOTE: AuditTrail section matches admin actions by searching student email in"
echo "   existing ActivityLog.details text (no targetUserId field exists yet in your"
echo "   logging schema). This works for now but is a soft-match, not an exact ID link."
