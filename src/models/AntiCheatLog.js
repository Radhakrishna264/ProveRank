const mongoose = require('mongoose');

const antiCheatLogSchema = new mongoose.Schema({
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  eventType: {
    type: String,
    enum: ['tab_switch','window_blur','fullscreen_exit','fast_answer','identical_pattern','ip_flag','face_away','multi_device'],
    required: true
  },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  warningNumber: { type: Number, default: 0 },
  autoSubmitTriggered: { type: Boolean, default: false },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

antiCheatLogSchema.index({ attemptId: 1 });
antiCheatLogSchema.index({ studentId: 1 });
antiCheatLogSchema.index({ eventType: 1 });

module.exports = mongoose.model('AntiCheatLog', antiCheatLogSchema);
