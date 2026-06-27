const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  action: {
    type: String,
    required: true,
    enum: [
      'PERMISSION_UPDATE', 'ADMIN_FROZEN', 'ADMIN_UNFROZEN',
      'STUDENT_IMPERSONATE', 'ADMIN_CREATE', 'STUDENT_BAN',
      'STUDENT_UNBAN', 'EXAM_CREATE', 'EXAM_DELETE', 'LOGIN',
      'QUESTION_ADD', 'QUESTION_DELETE', 'BULK_IMPORT'
    ]
  },
  performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  targetUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  details: { type: String },
  ip: { type: String },
  createdAt: { type: Date, default: Date.now }
}, { timestamps: false });

// Tamper-proof: no update allowed
auditLogSchema.pre('updateOne', function() { throw new Error('AuditLog is tamper-proof'); });
auditLogSchema.pre('findOneAndUpdate', function() { throw new Error('AuditLog is tamper-proof'); });

module.exports = mongoose.model('AuditLog', auditLogSchema);
