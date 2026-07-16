const mongoose = require('mongoose');

const TestSeriesAuditLogSchema = new mongoose.Schema({
  seriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', index: true },
  field: { type: String },
  action: { type: String },
  oldValue: { type: mongoose.Schema.Types.Mixed },
  newValue: { type: mongoose.Schema.Types.Mixed },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  changedByName: { type: String, default: 'Admin' },
  source: { type: String, default: 'test-series-manager-ultra' },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.models.TestSeriesAuditLog || mongoose.model('TestSeriesAuditLog', TestSeriesAuditLogSchema);
