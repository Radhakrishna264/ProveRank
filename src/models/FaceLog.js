const mongoose = require('mongoose');

const faceLogSchema = new mongoose.Schema({
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  eventType: {
    type: String,
    enum: [
      'single_face_ok',
      'multiple_faces',
      'no_face',
      'eye_tracking_flag',
      'head_pose_flag',
      'face_warning'
    ],
    required: true
  },
  faceCount: { type: Number, default: 0 },
  warningIssued: { type: Boolean, default: false },
  flagReason: { type: String, default: null },
  eyeTrackingData: { type: mongoose.Schema.Types.Mixed, default: null },
  headPoseData: { type: mongoose.Schema.Types.Mixed, default: null },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

faceLogSchema.index({ attemptId: 1 });
faceLogSchema.index({ studentId: 1 });
faceLogSchema.index({ eventType: 1 });
faceLogSchema.index({ warningIssued: 1 });

module.exports = mongoose.model('FaceLog', faceLogSchema);
