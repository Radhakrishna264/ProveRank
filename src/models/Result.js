const mongoose = require('mongoose');

const answerSchema = new mongoose.Schema({
  questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question' },
  selectedOption: { type: String },
  isCorrect: { type: Boolean },
  marksAwarded: { type: Number }
}, { _id: false });

const resultSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  answers: [answerSchema],

  score: { type: Number, default: 0 },
  correctCount: { type: Number, default: 0 },
  incorrectCount: { type: Number, default: 0 },
  unattemptedCount: { type: Number, default: 0 },

  attemptNumber: { type: Number, default: 1 },

  rank: { type: Number },
  percentile: { type: Number },

  isLocked: { type: Boolean, default: false },
  reviewed: { type: Boolean, default: false },
  visibility: { type: Boolean, default: false },

  submittedAt: { type: Date, default: Date.now }

}, { timestamps: true });

module.exports = mongoose.model('Result', resultSchema);
