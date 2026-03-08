const mongoose = require('mongoose');
const qvSchema = new mongoose.Schema({
  questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question', required: true },
  versionData: { type: Object, required: true },
  editedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
module.exports = mongoose.model('QuestionVersion', qvSchema);
