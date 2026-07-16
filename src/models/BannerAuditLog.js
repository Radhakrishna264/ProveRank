const mongoose = require('mongoose');

const BannerAuditLogSchema = new mongoose.Schema({
  bannerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Banner', index: true },
  action: { type: String },
  oldValue: { type: mongoose.Schema.Types.Mixed },
  newValue: { type: mongoose.Schema.Types.Mixed },
  performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  performedByName: { type: String, default: 'Admin' },
  linkedType: { type: String, default: 'none' },
  linkedBatchId: { type: mongoose.Schema.Types.ObjectId, default: null },
  reason: { type: String, default: '' },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.models.BannerAuditLog || mongoose.model('BannerAuditLog', BannerAuditLogSchema);
