const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  password: { type: String, required: true },
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
  banReason: { type: String },
  banExpiry: { type: Date },
  parentEmail: { type: String }
}, { timestamps: true });

// password hashing removed — done in auth.js directly;

if (mongoose.models.User) delete mongoose.connection.models['User'];
module.exports = mongoose.model('User', userSchema, 'students');
