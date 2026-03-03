const fs = require('fs');

const newSchema = `
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
    unattempted: { type: Number, default: 0 },
    msqMode: {
      type: String,
      enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'],
      default: 'ALL_OR_NOTHING'
    }
  },

  password: { type: String, default: '' },

  schedule: {
    startTime: Date,
    endTime: Date
  },

  status: {
    type: String,
    enum: ['draft', 'scheduled', 'live', 'ended'],
    default: 'draft'
  },

  batch: { type: String, default: '' },

  category: {
    type: String,
    enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test'],
    default: 'Full Mock'
  },

  whitelist: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],

  watermark: { type: Boolean, default: true },

  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled: { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 }
  },

  template: { type: String, default: '' },

  difficulty: { type: String, default: 'Mixed' },

  type: { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },

  waitingRoomMinutes: { type: Number, default: 10 },

  maxAttempts: { type: Number, default: 1 },

  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
`;

fs.writeFileSync('./src/models/Exam.js', newSchema);
console.log("Exam schema fully rebuilt cleanly.");
