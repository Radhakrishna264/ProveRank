const mongoose = require('mongoose');

const attemptSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  examInstanceId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamInstance' },
  status: { type: String, enum: ['waiting', 'instructions', 'active', 'submitted', 'timeout'], default: 'waiting' },
  ipAddress: { type: String },
  startedAt: { type: Date },
  submittedAt: { type: Date },
  termsAccepted: { type: Boolean, default: false },
  termsAcceptedAt: { type: Date },
  admitCardVerified: { type: Boolean, default: false },
  admitCardVerifiedAt: { type: Date },
  fullscreenWarnings: { type: Number, default: 0 },
  fullscreenDenied: { type: Boolean, default: false },
  answers: [{
    questionId: mongoose.Schema.Types.ObjectId,
    selectedOption: mongoose.Schema.Types.Mixed,
    isMarkedForReview: { type: Boolean, default: false },
    timeTaken: { type: Number, default: 0 },
    savedAt: { type: Date }
  }],
  attemptNumber: { type: Number, default: 1 },
  score: { type: Number },
  rank: { type: Number },
  percentile: { type: Number },
  predictedRank: { type: Number },
  predictedScore: { type: Number },
  predictionConfidence: { type: String, enum: ['low', 'medium', 'high'] },
  deviceSessionId: { type: String, default: null },
  isPaused: { type: Boolean, default: false },
  pausedAt: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model('Attempt', attemptSchema);
