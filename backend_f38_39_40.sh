#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — F38+F39+F40 Backend
#  1. User.js  — add new profile fields
#  2. auth.js  — PATCH /api/auth/me handle new fields
# ═══════════════════════════════════════════════════════════════
set -e

USER_F=$(find . -path "*/models/User.js" | grep -v node_modules | head -1)
AUTH_F=$(find . -path "*/routes/auth.js" | grep -v node_modules | head -1)
echo "User.js: $USER_F"
echo "auth.js: $AUTH_F"

cp "$USER_F" "${USER_F}.bak_f38"
cp "$AUTH_F" "${AUTH_F}.bak_f38"
export USER_F AUTH_F

# ════════════════════════════════════════════════════════════════
# 1. PATCH — User.js (add new fields)
# ════════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.USER_F;
let c = fs.readFileSync(f, 'utf8');

const NEW_FIELDS = `
  // ── F38/F39: Extended Profile Fields ──────────────────────────
  state:              { type: String, default: '' },
  gender:             { type: String, default: '' },
  timezone:           { type: String, default: 'Asia/Kolkata' },
  targetYear:         { type: String, default: '' },
  yearOfAppearing:    { type: String, default: '' },
  coachingInstitute:  { type: String, default: '' },

  // Profile history (each save timestamped — Superadmin can view)
  profileHistory: [{
    updatedAt:        { type: Date, default: Date.now },
    updatedFields:    [String],
    snapshot: {
      name: String, phone: String, dob: String, city: String,
      state: String, gender: String, bio: String,
      targetExam: String, targetYear: String, board: String,
      school: String, coachingInstitute: String,
    }
  }],

  // Preferences
  preferences: {
    emailNotif:    { type: Boolean, default: true },
    smsNotif:      { type: Boolean, default: false },
    studyReminder: { type: Boolean, default: true },
  },

`;

// Insert before existing fields or before closing of schema
// Find a safe anchor — before 'welcomeSeen' or before 'onboarded'
const anchors = ['  welcomeSeen:', '  onboarded:', '  badges:'];
let inserted = false;
for (const anchor of anchors) {
  if (c.includes(anchor) && !c.includes('coachingInstitute')) {
    c = c.replace(anchor, NEW_FIELDS + anchor);
    inserted = true;
    break;
  }
}

if (!inserted && !c.includes('coachingInstitute')) {
  // Fallback: add before last }); (schema close)
  const schemaClose = c.lastIndexOf('}, {');
  if (schemaClose !== -1) {
    c = c.slice(0, schemaClose) + NEW_FIELDS + c.slice(schemaClose);
    inserted = true;
  }
}

if (inserted) {
  fs.writeFileSync(f, c);
  console.log('✅ User.js — new profile fields added');
} else {
  console.log('ℹ️  Fields may already exist');
}

const v = fs.readFileSync(f, 'utf8');
console.log('state field:',           v.includes('state:') ? '✅':'❌');
console.log('gender field:',          v.includes('gender:') ? '✅':'❌');
console.log('timezone field:',        v.includes('timezone:') ? '✅':'❌');
console.log('targetYear field:',      v.includes('targetYear:') ? '✅':'❌');
console.log('yearOfAppearing field:', v.includes('yearOfAppearing:') ? '✅':'❌');
console.log('coachingInstitute:',     v.includes('coachingInstitute:') ? '✅':'❌');
console.log('profileHistory:',        v.includes('profileHistory:') ? '✅':'❌');
console.log('preferences:',           v.includes('preferences:') ? '✅':'❌');
JSEOF

# ════════════════════════════════════════════════════════════════
# 2. PATCH — auth.js PATCH /api/auth/me route
# ════════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.AUTH_F;
let c = fs.readFileSync(f, 'utf8');

// Find the existing PATCH /api/auth/me handler
const patchIdx = c.indexOf("router.patch('/me'") !== -1
  ? c.indexOf("router.patch('/me'")
  : c.indexOf('router.patch("/me"');

if (patchIdx === -1) {
  console.log('⚠️  PATCH /me route not found — adding new route');

  const NEW_PATCH = `
// ── F38/F39/F40: PATCH /api/auth/me — update profile ──────────
router.patch('/me', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ message: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ message: 'Invalid token' }) }

    const {
      name, phone, dob, city, state, gender, bio, avatar, timezone,
      targetExam, targetYear, yearOfAppearing, board, school, coachingInstitute,
      goals, preferences,
    } = req.body

    const allowed = {}
    const updatedFields = []

    if (name             !== undefined) { allowed.name             = name;             updatedFields.push('name') }
    if (phone            !== undefined) { allowed.phone            = phone;            updatedFields.push('phone') }
    if (dob              !== undefined) { allowed.dob              = dob;              updatedFields.push('dob') }
    if (city             !== undefined) { allowed.city             = city;             updatedFields.push('city') }
    if (state            !== undefined) { allowed.state            = state;            updatedFields.push('state') }
    if (gender           !== undefined) { allowed.gender           = gender;           updatedFields.push('gender') }
    if (bio              !== undefined) { allowed.bio              = bio.slice(0,160); updatedFields.push('bio') }
    if (avatar           !== undefined) { allowed.avatar           = avatar;           updatedFields.push('avatar') }
    if (timezone         !== undefined) { allowed.timezone         = timezone;         updatedFields.push('timezone') }
    if (targetExam       !== undefined) { allowed.targetExam       = targetExam;       updatedFields.push('targetExam') }
    if (targetYear       !== undefined) { allowed.targetYear       = targetYear;       updatedFields.push('targetYear') }
    if (yearOfAppearing  !== undefined) { allowed.yearOfAppearing  = yearOfAppearing;  updatedFields.push('yearOfAppearing') }
    if (board            !== undefined) { allowed.board            = board;            updatedFields.push('board') }
    if (school           !== undefined) { allowed.school           = school;           updatedFields.push('school') }
    if (coachingInstitute!== undefined) { allowed.coachingInstitute= coachingInstitute;updatedFields.push('coachingInstitute') }
    if (goals            !== undefined) { allowed.goals            = goals;            updatedFields.push('goals') }
    if (preferences      !== undefined) { allowed.preferences      = preferences;      updatedFields.push('preferences') }

    // Save profile history snapshot (Superadmin can view)
    const user = await User.findById(decoded.id)
    if (!user) return res.status(404).json({ message: 'User not found' })

    if (updatedFields.length > 0) {
      const snapshot = {
        name: user.name, phone: user.phone, dob: user.dob, city: user.city,
        state: user.state, gender: user.gender, bio: user.bio,
        targetExam: user.targetExam, targetYear: user.targetYear,
        board: user.board, school: user.school, coachingInstitute: user.coachingInstitute,
      }
      if (!allowed.$push) {
        await User.findByIdAndUpdate(decoded.id, {
          $set: allowed,
          $push: { profileHistory: { updatedAt: new Date(), updatedFields, snapshot } }
        })
      }
    }

    const updated = await User.findById(decoded.id).select('-password -otp -otpExpiry')
    res.json({ success: true, user: updated, message: 'Profile updated successfully' })
  } catch (err) {
    res.status(500).json({ message: err.message })
  }
})

`;
  c = c.replace('module.exports = router', NEW_PATCH + 'module.exports = router');
  console.log('✅ PATCH /me route added');

} else {
  console.log('ℹ️  PATCH /me already exists — patching to include new fields...');

  // Find end of existing patch handler
  const routeStr = c.slice(patchIdx)
  const endMatch = routeStr.match(/\}\)\s*\n/)
  if (endMatch) {
    const endIdx = patchIdx + routeStr.indexOf(endMatch[0]) + endMatch[0].length

    // Check if new fields already there
    if (c.includes('coachingInstitute') && c.includes('yearOfAppearing')) {
      console.log('ℹ️  PATCH /me already has new fields');
    } else {
      // Insert new allowed fields before the findByIdAndUpdate call
      const updateCall = 'await User.findByIdAndUpdate'
      const updateIdx = c.indexOf(updateCall, patchIdx)
      if (updateIdx !== -1) {
        const NEW_FIELDS_PATCH = `
    if (state            !== undefined) allowed.state            = state
    if (gender           !== undefined) allowed.gender           = gender
    if (timezone         !== undefined) allowed.timezone         = timezone
    if (targetYear       !== undefined) allowed.targetYear       = targetYear
    if (yearOfAppearing  !== undefined) allowed.yearOfAppearing  = yearOfAppearing
    if (coachingInstitute!== undefined) allowed.coachingInstitute= coachingInstitute
    if (preferences      !== undefined) allowed.preferences      = preferences
    // Profile history snapshot
    `
        c = c.slice(0, updateIdx) + NEW_FIELDS_PATCH + c.slice(updateIdx)
        console.log('✅ New fields patched into existing PATCH /me')
      }
    }
  }
}

fs.writeFileSync(f, c);

// Verify
const v = fs.readFileSync(f, 'utf8');
console.log('\n── auth.js Verification:');
console.log("PATCH /me exists:",           v.includes("router.patch('/me'") || v.includes('router.patch("/me"') ? '✅':'❌');
console.log('coachingInstitute handled:',  v.includes('coachingInstitute') ? '✅':'❌');
console.log('yearOfAppearing handled:',    v.includes('yearOfAppearing') ? '✅':'❌');
console.log('profileHistory saved:',       v.includes('profileHistory') ? '✅':'❌');
console.log('preferences handled:',        v.includes('preferences') ? '✅':'❌');
console.log('bio slice(0,160):',           v.includes('bio.slice(0,160)') ? '✅':'❌');
JSEOF

echo ""
echo "══════════════════════════════════════════════"
echo "  🔍 Final Backend Verification"
echo "══════════════════════════════════════════════"
export USER_F AUTH_F
node << 'JSEOF'
const fs = require('fs');
const u  = fs.readFileSync(process.env.USER_F, 'utf8');
const a  = fs.readFileSync(process.env.AUTH_F, 'utf8');

const checks = [
  ['User.js: state field',            u.includes('state:')],
  ['User.js: gender field',           u.includes('gender:')],
  ['User.js: timezone field',         u.includes('timezone:')],
  ['User.js: targetYear field',       u.includes('targetYear:')],
  ['User.js: yearOfAppearing field',  u.includes('yearOfAppearing:')],
  ['User.js: coachingInstitute field',u.includes('coachingInstitute:')],
  ['User.js: profileHistory array',   u.includes('profileHistory:')],
  ['User.js: preferences object',     u.includes('preferences:')],
  ['auth.js: PATCH /me route',        a.includes("router.patch('/me'") || a.includes('router.patch("/me"')],
  ['auth.js: coachingInstitute',      a.includes('coachingInstitute')],
  ['auth.js: yearOfAppearing',        a.includes('yearOfAppearing')],
  ['auth.js: profileHistory saved',   a.includes('profileHistory')],
  ['auth.js: bio max 160 chars',      a.includes('bio.slice(0,160)')],
];

let pass=0,fail=0;
checks.forEach(([l,v])=>{ console.log((v?'✅':'❌')+' '+l); v?pass++:fail++; });
console.log('\n'+pass+'/'+checks.length+' passed');
if(fail===0) console.log('🎉 Backend F38+F39+F40 ready!');
else         console.log('⚠️ '+fail+' issue(s)');
JSEOF

echo ""
echo "git add . && git commit -m 'feat: F38+F39+F40 backend — new profile fields + PATCH /me' && git push"
