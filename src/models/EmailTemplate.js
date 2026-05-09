const mongoose = require('mongoose')
const emailTemplateSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['welcome','result','reminder','broadcast','announcement'],
    unique: true,
    required: true
  },
  subject: { type: String, required: true },
  htmlBody: { type: String, required: true },
  active: { type: Boolean, default: true },
  updatedBy: { type: String },
  updatedAt: { type: Date, default: Date.now }
})
module.exports = mongoose.model('EmailTemplate', emailTemplateSchema)
