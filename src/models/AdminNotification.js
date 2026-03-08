const mongoose = require('mongoose');

const adminNotificationSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['cheating_alert', 'server_load', 'doubt_submitted', 'exam_error', 'login_suspicious', 'general'],
    required: true
  },
  title: { type: String, required: true },
  message: { type: String, required: true },
  relatedExamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
  relatedStudentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  isRead: { type: Boolean, default: false },
  readAt: { type: Date },
  severity: { type: String, enum: ['info', 'warning', 'critical'], default: 'info' }
}, { timestamps: true });

module.exports = mongoose.model('AdminNotification', adminNotificationSchema);
