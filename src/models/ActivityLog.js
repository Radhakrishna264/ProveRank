const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
  userId:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userName:    { type: String },
  userRole:    { type: String },
  action:      { type: String, required: true },
  details:     { type: String },
  module:      { type: String, default: 'general' },
  ipAddress:   { type: String },
  userAgent:   { type: String },
  status:      { type: String, enum: ['success', 'failed', 'warning'], default: 'success' },
  // S93 — tamper proof fields
  checksum:    { type: String },
  isAudit:     { type: Boolean, default: false },
}, { timestamps: true });

// Index for fast queries
activityLogSchema.index({ userId: 1, createdAt: -1 });
activityLogSchema.index({ action: 1 });
activityLogSchema.index({ isAudit: 1 });

module.exports = mongoose.model('ActivityLog', activityLogSchema);
