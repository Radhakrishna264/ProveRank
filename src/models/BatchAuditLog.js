const mongoose = require('mongoose');

const BatchAuditLogSchema = new mongoose.Schema({
  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', index: true },
  field: { type: String },
  action: { type: String },
  oldValue: { type: mongoose.Schema.Types.Mixed },
  newValue: { type: mongoose.Schema.Types.Mixed },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  changedByName: { type: String, default: 'Admin' },
  source: { type: String, default: 'batch-manager-ultra' },
  timestamp: { type: Date, default: Date.now }
,
  reason: { type: String, default: '' },
  snapshotVersion: { type: mongoose.Schema.Types.Mixed, default: null }

}, { timestamps: true });

module.exports = mongoose.models.BatchAuditLog || mongoose.model('BatchAuditLog', BatchAuditLogSchema);
