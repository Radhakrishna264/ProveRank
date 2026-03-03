const mongoose = require('mongoose');

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

  // 🔹 Granular Permission System (S37)
  permissions: {
    type: Map,
    of: Boolean,
    default: {}
  },

  // 🔹 Admin Freeze Control (S72)
  adminFrozen: {
    type: Boolean,
    default: false
  },

  group: { type: String },

  otp: { type: String },

  otpExpiry: { type: Date },

  verified: { type: Boolean, default: false },

  profilePhoto: { type: String },

  loginHistory: [
    {
      ip: String,
      device: String,
      time: { type: Date, default: Date.now }
    }
  ],

  customFields: { type: Object },

  banned: { type: Boolean, default: false },

  banReason: { type: String },

  banExpiry: { type: Date },

  parentEmail: { type: String }

}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
