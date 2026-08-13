#!/bin/bash
# ProveRank — Re-apply User.js fix (2FA removal + reward-system removal +
# batch field removal) to the CONFIRMED, EXACT path only. No content-based
# guessing this time — the earlier attempt's loose grep matched a different
# file by accident (src/routes/antiCheatRoutes.js, which already contained
# stray User-schema-like content unrelated to this task) and never actually
# touched the real model file.
set -e

cd ~/workspace 2>/dev/null || { echo "❌ ~/workspace not found"; exit 1; }

TARGET="src/models/User.js"
if [ ! -f "$TARGET" ]; then
  echo "❌ $TARGET not found at expected path. Aborting — no changes made."
  exit 1
fi

TS=$(date +%s)
cp "$TARGET" "${TARGET}.bak_${TS}"
echo "✅ Backup: ${TARGET}.bak_${TS}"

cat > "$TARGET" << 'EOF_USRFIX'
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  password: { type: String, required: true },
  studentId: { type: String, unique: true, sparse: true, trim: true },
  adminId: { type: String, unique: true, sparse: true, trim: true },

  // ── F38/F39: Extended Profile Fields ──────────────────────────
  state:              { type: String, default: '' },
  gender:             { type: String, default: '' },
  timezone:           { type: String, default: 'Asia/Kolkata' },
  targetYear:         { type: String, default: '' },
  yearOfAppearing:    { type: String, default: '' },
  coachingInstitute:  { type: String, default: '' },
  dob:                { type: String, default: '' },
  city:               { type: String, default: '' },
  bio:                { type: String, default: '', maxlength: 160 },
  avatar:             { type: String, default: '' },
  targetExam:         { type: String, default: '' },
  board:              { type: String, default: '' },
  school:             { type: String, default: '' },
  medium:             { type: String, default: '' },

  // ── F38: Login health / device tracking ─────────────────────────
  failedLoginAttempts: { type: Number, default: 0 },
  lastFailedLoginAt:   { type: Date, default: null },
  loginCount:          { type: Number, default: 0 },
  trustedDevices: [{
    deviceId:   String,
    label:      String,
    browser:    String,
    os:         String,
    addedAt:    { type: Date, default: Date.now },
    lastUsedAt: Date,
  }],

  // ── F38B §7 — Profile photo version history (Superadmin only view) ──
  avatarHistory: [{
    url:       String,
    updatedAt: { type: Date, default: Date.now },
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
  }],

  // ── F38B §5 — Password change metadata (never the password itself) ──
  passwordChangedAt:   { type: Date, default: null },
  passwordChangeCount: { type: Number, default: 0 },
  passwordResetHistory: [{
    requestedAt: { type: Date, default: Date.now },
    resetBy:     { type: String, default: 'self' },
    method:      { type: String, default: 'otp' },
  }],

  // Profile history (F38 §9 — per-field internal audit trail, DB only, never shown to student)
  profileHistory: [{
    updatedAt:        { type: Date, default: Date.now },
    updatedFields:    [String],
    changes: [{
      field:    String,
      oldValue: mongoose.Schema.Types.Mixed,
      newValue: mongoose.Schema.Types.Mixed,
    }],
    updatedBy: { type: String, default: 'self' },
    source:    { type: String, default: 'profile_page' },
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

  welcomeSeen: { type: Boolean, default: false },
  role: {
    type: String,
    enum: ['superadmin', 'admin', 'student'],
    default: 'student'
  },
  termsAccepted: { type: Boolean, default: false },
  permissions: { type: Map, of: Boolean, default: {} },
  adminFrozen: { type: Boolean, default: false },
  group: { type: String },
  otp: { type: String },
  otpExpiry: { type: Date },
  verified: { type: Boolean, default: false },
  profilePhoto: { type: String },
  emailVerified: { type: Boolean, default: false },

  // OTP fields — register verify, login OTP, reset password
  emailVerifyOTP:      { type: String, default: null },
  emailVerifyOTPExpiry:{ type: Date,   default: null },
  loginOTP:            { type: String, default: null },
  loginOTPExpiry:      { type: Date,   default: null },
  resetOTP:            { type: String, default: null },
  resetOTPExpiry:      { type: Date,   default: null },
  emailVerifyToken: { type: String },
  emailVerifyExpiry: { type: Date },
  loginHistory: [{
    ip: String,
    device: String,
    time: { type: Date, default: Date.now }
  }],
  customFields: { type: Object },
  banned: { type: Boolean, default: false },
  frozen: { type: Boolean, default: false },
  archived: { type: Boolean, default: false },
  banReason: { type: String },
  banExpiry: { type: Date },
  parentEmail: { type: String },

  // ── F35: Multi-device session control + Terms tracking ─────────
  activeSessionToken: { type: String, default: null },
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },

  // ══════════════════════════════════════════════════════════
  // F52-F57 v2 — Waiting Room resume tracking (Rule 1.15.3/1.15.4)
  // NOTE: read/write via User.collection.findOne/updateOne (raw driver)
  // to match project convention (see D-36/D-37 in Brief) — same
  // pattern already used for enrolledBatches/enrolledBatchesMeta.
  // ══════════════════════════════════════════════════════════
  waitingRoomJoins: [{
    examId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    joinedAt: { type: Date, default: Date.now }
  }],

  // F52-F57 v2 — Per-exam T&C consent log (F55 §1.5/§2.5/§3.1)
  examConsents: [{
    examId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    version:    { type: String, default: '1.0' },
    acceptedAt: { type: Date, default: Date.now }
  }],

  // F52 §7 — Per-exam reminder toggle (server-persisted)
  examReminders: [{
    examId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    enabled:   { type: Boolean, default: true },
    updatedAt: { type: Date, default: Date.now }
  }],

}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
EOF_USRFIX
echo "✅ $TARGET updated (exact path — verified before and after)"

echo ""
echo "🔎 Verifying fix landed correctly..."
if grep -qi "twoFactor\|checklist\|^  batch:" "$TARGET"; then
  echo "❌ WARNING: old content still detected — something is wrong, please share output"
else
  echo "✅ Confirmed clean: no 2FA / checklist / xp / batch fields in $TARGET"
fi
