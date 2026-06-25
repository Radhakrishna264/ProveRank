/**
 * ProveRank — Feature 29: Exam Templates — Create, Save & Reuse
 * Formal model. NOTE: examWizardRoutes.js (28.8.4 "Save as Template" +
 * 26 "Quick Templates" picker) already lazily creates a mongoose model
 * named 'ExamTemplate' with a smaller inline schema. Because this file
 * is now require()'d once at server startup (see index.js), this richer
 * schema registers FIRST — examWizardRoutes.js's try/catch will simply
 * reuse this same model. Old fields (name, icon, subject, category,
 * totalQs, subjectQs, duration, totalMarks, correctMarks, negativeMarks,
 * examType, markingScheme, instructions, createdBy) are kept 100%
 * backward-compatible so nothing that already works breaks.
 */
const mongoose = require('mongoose')

const versionSnapshotSchema = new mongoose.Schema({
  name:          String,
  titleFormat:   String,
  category:      String,
  examType:      String,
  subject:       String,
  totalQs:       Number,
  subjectQs:     Object,
  sections:      Array,
  duration:      Number,
  totalMarks:    Number,
  correctMarks:  Number,
  negativeMarks: Number,
  markingScheme: Object,
  instructions:  String,
  savedAt:       { type: Date, default: Date.now }
}, { _id: false })

const examTemplateSchema = new mongoose.Schema({
  name:           { type: String, required: true, trim: true },         // 29.2
  icon:           { type: String, default: '📋' },
  titleFormat:    { type: String, default: '{name}' },                  // 29.2 — tokens: {name} {date} {category} {examType} {n}
  category:       { type: String, default: 'Custom' },                  // 29.3
  categoryColor:  { type: String, default: '#A78BFA' },                 // 29.10
  subject:        { type: String, default: 'Full Mock' },
  examType:       { type: String, default: 'Custom' },
  totalQs:        { type: Number, default: 0 },
  subjectQs:      { type: Object, default: {} },
  sections:       { type: Array,  default: [] },                        // 29.2
  duration:       { type: Number, default: 60 },
  totalMarks:     { type: Number, default: 0 },
  correctMarks:   { type: Number, default: 4 },
  negativeMarks:  { type: Number, default: 1 },
  markingScheme:  { type: Object, default: {} },                        // { correct, wrong, skip }
  instructions:   { type: String, default: '' },
  usageCount:     { type: Number, default: 0 },                         // 29.4
  lastUsedAt:     { type: Date,   default: null },                      // 29.6
  isPinned:       { type: Boolean, default: false },                    // 29.8
  versions:       { type: [versionSnapshotSchema], default: [] },       // 29.9
  createdBy:      { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedBy:      { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true })

module.exports = mongoose.models.ExamTemplate || mongoose.model('ExamTemplate', examTemplateSchema)
