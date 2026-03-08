const mongoose = require('mongoose');
const qeSchema = new mongoose.Schema({
  questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question', required: true },
  reportedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
  errorType: { type: String, enum: ['wrong_answer', 'typo', 'image_missing', 'unclear', 'other'], default: 'other' },
  description: { type: String, required: true },
  status: { type: String, enum: ['pending', 'reviewing', 'resolved', 'rejected'], default: 'pending' },
  adminNote: { type: String },
  resolvedAt: { type: Date },
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
module.exports = mongoose.model('QuestionError', qeSchema);
