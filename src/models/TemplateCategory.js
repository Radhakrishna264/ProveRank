/**
 * ProveRank — Feature 29.10: custom Exam-Template categories with colours
 * e.g. admin creates "RPSC" with its own colour, on top of the 4 defaults
 * (NEET / JEE / CUET / Custom) which are not stored in DB — see
 * DEFAULT_CATEGORIES in routes/examTemplates.js.
 */
const mongoose = require('mongoose')

const templateCategorySchema = new mongoose.Schema({
  name:      { type: String, required: true, trim: true },
  color:     { type: String, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true })

module.exports = mongoose.models.TemplateCategory || mongoose.model('TemplateCategory', templateCategorySchema)
