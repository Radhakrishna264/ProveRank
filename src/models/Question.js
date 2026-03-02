const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  text: { type: String, required: true, trim: true },
  hindiText: { type: String, trim: true, default: '' },
  options: {
    type: [String], required: true,
    validate: { validator: function(v) { return v.length >= 2; }, message: 'At least 2 options required' }
  },
  correct: { type: [Number], required: true },
  subject: { type: String, required: true, enum: ['Physics', 'Chemistry', 'Biology', 'Mathematics', 'Other'], default: 'Other' },
  chapter: { type: String, trim: true, default: '' },
  topic: { type: String, trim: true, default: '' },
  difficulty: { type: String, enum: ['Easy', 'Medium', 'Hard', 'Untagged'], default: 'Untagged' },
  aiDifficulty: { type: String, enum: ['Easy', 'Medium', 'Hard', 'Untagged'], default: 'Untagged' },
  type: { type: String, enum: ['SCQ', 'MSQ', 'Integer', 'Assertion', 'Other'], default: 'SCQ' },
  image: { type: String, default: '' },
  explanation: { type: String, default: '' },
  aiExplanation: { type: String, default: '' },
  videoLink: { type: String, default: '' },
  tags: { type: [String], default: [] },
  usageCount: { type: Number, default: 0 },
  usedInExams: [{
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' },
    examTitle: String,
    usedAt: { type: Date, default: Date.now }
  }],
  correctAttempts: { type: Number, default: 0 },
  totalAttempts: { type: Number, default: 0 },
  sourceExam: { type: String, default: '' },
  isPYQ: { type: Boolean, default: false },
  pyqYear: { type: Number, default: null },
  pyqExam: { type: String, default: '' },
  version: { type: Number, default: 1 },
  versionHistory: [{
    version: Number,
    text: String,
    hindiText: String,
    options: [String],
    correct: [Number],
    explanation: String,
    editedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    editedAt: { type: Date, default: Date.now },
    editReason: String
  }],
  approvalStatus: { type: String, enum: ['Pending', 'Approved', 'Rejected'], default: 'Approved' },
  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  approvedAt: { type: Date, default: null },
  rejectionReason: { type: String, default: '' },
  translatedBy: { type: String, enum: ['Manual', 'AI', 'None'], default: 'None' },
  errorReports: [{
    reportedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    reportedAt: { type: Date, default: Date.now },
    issue: String,
    status: { type: String, enum: ['Open', 'Reviewed', 'Resolved'], default: 'Open' }
  }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

questionSchema.index({ subject: 1, chapter: 1, topic: 1 });
questionSchema.index({ difficulty: 1 });
questionSchema.index({ type: 1 });
questionSchema.index({ tags: 1 });
questionSchema.index({ isPYQ: 1, pyqYear: 1 });
questionSchema.index({ approvalStatus: 1 });
questionSchema.index({ text: 'text', hindiText: 'text' });

module.exports = mongoose.model('Question', questionSchema);
