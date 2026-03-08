const mongoose = require('mongoose');
const doubtSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question' },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
  subject: { type: String },
  doubtText: { type: String, required: true },
  adminReply: { type: String },
  status: { type: String, enum: ['open', 'resolved'], default: 'open' },
  repliedAt: { type: Date },
  repliedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
module.exports = mongoose.model('Doubt', doubtSchema);
