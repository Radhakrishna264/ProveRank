const mongoose = require('mongoose');
const reEvalSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  attemptId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt' },
  reason: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  adminNote: { type: String },
  resolvedAt: { type: Date }
}, { timestamps: true });
module.exports = mongoose.model('ReEvaluation', reEvalSchema);
