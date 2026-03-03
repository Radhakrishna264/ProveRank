const mongoose = require('mongoose');

const sectionTimerSchema = new mongoose.Schema({
  sectionName: { type: String, required: true },
  subject: { type: String, required: true },
  durationMinutes: { type: Number, required: true },
  isLocked: { type: Boolean, default: false },
  lockedAt: { type: Date, default: null }
}, { _id: false });

const examInstanceSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  versionCode: { type: String, unique: true, sparse: true },
  setLabel: { type: String, enum: ['Set-A', 'Set-B', 'Set-C', 'Set-D', 'Default'], default: 'Default' },
  batchId: { type: mongoose.Schema.Types.ObjectId, default: null },
  questionSnapshot: [{
    questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question' },
    subject: String,
    order: Number
  }],
  totalQuestions: { type: Number, default: 0 },
  isPublished: { type: Boolean, default: false },
  publishedAt: { type: Date, default: null },
  isLocked: { type: Boolean, default: false },
  lockedAt: { type: Date, default: null },
  lockReason: { type: String, default: null },
  attemptStarted: { type: Boolean, default: false },
  firstAttemptAt: { type: Date, default: null },
  sectionTimers: [sectionTimerSchema],
  socketRoomId: { type: String, default: null },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
}, { timestamps: true });

module.exports = mongoose.model('ExamInstance', examInstanceSchema);
