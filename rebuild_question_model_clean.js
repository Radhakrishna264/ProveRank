const fs = require('fs');

const cleanSchema = `
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

  explanation: { type: String, default: '' },

  similarityScore: { type: Number, default: 0 },
  similarQuestionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question',
    default: null
  },

  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }

}, { timestamps: true });

const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function () {
  if (this.isModified('text') || this.isNew) {
    await runAIPipeline(this);
  }
});

module.exports = mongoose.model('Question', questionSchema);
`;

fs.writeFileSync('./src/models/Question.js', cleanSchema);

console.log("✔ Question model fully rebuilt cleanly");
