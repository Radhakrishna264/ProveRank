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
  batch:              { type: String, default: '' },

  // ── F38: 2FA (TOTP) ────────────────────────────────────────────
  twoFactorEnabled:     { type: Boolean, default: false },
  twoFactorSecret:      { type: String, default: null },
  twoFactorTempSecret:  { type: String, default: null },

  // ── F38: Login health / device tracking ─────────────────────────
  failedLoginAttempts: { type: Number, default: 0 },
  lastFailedLoginAt:   { type: Date, default: null },
  trustedDevices: [{
    deviceId:   String,
    label:      String,
    browser:    String,
    os:         String,
    addedAt:    { type: Date, default: Date.now },
    lastUsedAt: Date,
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
  termsAccepted:      { type: Boolean, default: false },
  termsAcceptedAt:    { type: Date,    default: null },
  termsVersion:        { type: String, default: null },

  // F37 — Checklist + XP
  checklist: {
    pyqExplored:      { type: Boolean, default: false },
    analyticsVisited: { type: Boolean, default: false },
  },
  xp: { type: Number, default: 0 },

}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
