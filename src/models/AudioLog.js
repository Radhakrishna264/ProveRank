const mongoose = require('mongoose');

const audioLogSchema = new mongoose.Schema({
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  eventType: {
    type: String,
    enum: ['permission_granted','permission_denied','noise_detected','whisper_detected','audio_flag','monitoring_started','monitoring_stopped'],
    required: true
  },
  audioFlag: { type: Boolean, default: false },
  flagReason: { type: String, default: null },
  noiseLevel: { type: Number, default: 0 },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

audioLogSchema.index({ attemptId: 1 });
audioLogSchema.index({ studentId: 1 });
audioLogSchema.index({ audioFlag: 1 });

module.exports = mongoose.model('AudioLog', audioLogSchema);
