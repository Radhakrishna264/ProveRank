const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  subject: { type: String, default: 'NEET' },
  duration: { type: Number, required: true },
  totalMarks: { type: Number, default: 720 },
  sections: [{
    name: String,
    subject: String,
    questionCount: Number,
    timeLimit: Number,
    marks: Number
  }],
  markingScheme: {
    correct: { type: Number, default: 4 },
    incorrect: { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 }
  },
  password: { type: String, default: '' },
  schedule: {
    startTime: Date,
    endTime: Date
  },
  status: { type: String, enum: ['draft','scheduled','live','ended'], default: 'draft' },
  batch: { type: String, default: '' },
  category: { type: String, enum: ['Full Mock','Chapter Test','Part Test','Grand Test'], default: 'Full Mock' },
  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  watermark: { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },
  maxAttempts: { type: Number, default: 1 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
