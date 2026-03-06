const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  text: { type: String, required: true, trim: true },
  hindiText: { type: String, default: '' },

  options: {
    type: [String],
    required: true,
    validate: {
      validator: function(v) { return v.length >= 2; },
      message: 'At least 2 options required'
    }
  },

  correct: { type: [Number], required: true },

  subject: { type: String, default: 'General' },
  difficulty: { type: String, default: 'Untagged' },

  type: {
    type: String,
    enum: ['SCQ', 'MSQ', 'Integer'],
    default: 'SCQ'
  },

  chapter: { type: String, default: '' },
  topic: { type: String, default: '' },
  explanation: { type: String, default: '' },
  videoLink: { type: String, default: '' },
  tags: [{ type: String }],
  image: { type: String, default: '' },

  usageCount: { type: Number, default: 0 },
  sourceExam: { type: String, default: '' },

  similarityScore: { type: Number, default: 0 },
  similarQuestionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question',
    default: null
  },

  isPYQ: { type: Boolean, default: false },
  pyqYear: { type: Number, default: null },

  approvalStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'approved'
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  approvedAt: { type: Date, default: null },
  rejectionReason: { type: String, default: null },

  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  versionHistory: [
    {
      version: { type: Number },
      text: { type: String },
      editedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      editedAt: { type: Date, default: Date.now },
      changes: { type: String }
    }
  ],

  reports: [
    {
      reason: { type: String },
      reportedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      reportedAt: { type: Date, default: Date.now },
      status: { type: String, enum: ['pending', 'resolved'], default: 'pending' }
    }
  ]

}, { timestamps: true });

const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function () {
  if (this.isModified('text') && !this.isNew) {
    if (!this.versionHistory) this.versionHistory = [];
    this.versionHistory.push({
      version: this.versionHistory.length + 1,
      text: this.text,
      editedAt: new Date(),
      changes: 'text updated'
    });
  }
  if (this.isModified('text') || this.isNew) {
    await runAIPipeline(this);
  }
});

module.exports = mongoose.model('Question', questionSchema);
