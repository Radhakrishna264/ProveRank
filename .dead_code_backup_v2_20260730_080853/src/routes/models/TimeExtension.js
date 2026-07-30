const mongoose = require('mongoose');

// Feature 32 — Per-Student Time Extension Model
const TimeExtensionSchema = new mongoose.Schema({
  // 32.6 — Log: examId, attemptId, studentId, adminId
  examId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Exam',    required: true, index: true },
  attemptId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true, index: true },
  studentId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  adminId:     { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  adminName:   { type: String, default: 'Admin' },
  studentName: { type: String, default: 'Student' },

  // 32.3 — Extra minutes granted
  extraMinutes: { type: Number, required: true, min: 1, max: 120 },

  // 32.9 — Reason dropdown
  reason: {
    type: String,
    enum: ['Disability', 'Technical Issue', 'Internet Problem', 'Other'],
    default: 'Other'
  },

  // 32.8 — Global extension flag
  isGlobal: { type: Boolean, default: false },

  // 32.12 — Undo tracking
  isUndone:  { type: Boolean, default: false },
  undoneAt:  { type: Date },
  undoneBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: true });

// Index for fast log lookup per exam
TimeExtensionSchema.index({ examId: 1, createdAt: -1 });
TimeExtensionSchema.index({ attemptId: 1, isUndone: 1 });

module.exports = mongoose.model('TimeExtension', TimeExtensionSchema);
