const mongoose = require('mongoose');

const webcamLogSchema = new mongoose.Schema({
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  eventType: {
    type: String,
    enum: ['permission_granted','permission_denied','snapshot','virtual_bg_detected','exam_blocked','face_flag'],
    required: true
  },
  snapshotData: { type: String, default: null },
  snapshotSize: { type: Number, default: 0 },
  cheatingFlag: { type: Boolean, default: false },
  flagReason: { type: String, default: null },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

webcamLogSchema.index({ attemptId: 1 });
webcamLogSchema.index({ studentId: 1 });
webcamLogSchema.index({ eventType: 1 });
webcamLogSchema.index({ cheatingFlag: 1 });

module.exports = mongoose.model('WebcamLog', webcamLogSchema);
