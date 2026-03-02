const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  phone: { type: String, trim: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['superadmin', 'admin', 'student'], default: 'student' },
  group: { type: String, default: '' },
  otp: { type: String },
  otpExpiry: { type: Date },
  verified: { type: Boolean, default: false },
  profilePhoto: { type: String, default: '' },
  loginHistory: [{ ip: String, device: String, city: String, time: Date }],
  twoFactorEnabled: { type: Boolean, default: false },
  twoFactorSecret: { type: String, default: null },
  twoFactorTempSecret: { type: String, default: null },
  customFields: { type: Map, of: String, default: {} },


  banned: { type: Boolean, default: false },
  banReason: { type: String, default: '' },
  banExpiry: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
