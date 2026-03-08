const mongoose = require('mongoose');

const sessionLogSchema = new mongoose.Schema({
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  eventType: {
    type: String,
    enum: [
      'screen_permission_granted',
      'screen_permission_denied',
      'session_start',
      'session_end',
      'suspicious_activity',
      'ip_lock_violation',
      'metadata_recorded'
    ],
    required: true
  },
  ipAddress: { type: String, default: null },
  sessionMetadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  suspicious: { type: Boolean, default: false },
  flagReason: { type: String, default: null },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

sessionLogSchema.index({ attemptId: 1 });
sessionLogSchema.index({ studentId: 1 });
sessionLogSchema.index({ ipAddress: 1 });
sessionLogSchema.index({ suspicious: 1 });

module.exports = mongoose.model('SessionLog', sessionLogSchema);
