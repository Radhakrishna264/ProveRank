/**
 * ProveRank — Feature 29: Exam Templates — Create, Save & Reuse
 *
 * IMPORTANT FIELD-NAMING NOTE (bugfix round):
 * The Create-Exam Wizard already has TWO separate, pre-existing concepts
 * that both sound like "category" in plain English:
 *   - `examType`  → NEET / JEE / CUET / RBSE / CBSE / Custom   (exam board)
 *   - `category`  → Full Mock / Chapter Test / Part Test / Grand Test /
 *                    Mini Test / PYQ / Custom                  (exam format)
 * Feature 29.3 asked for "Template categories — NEET/JEE/CUET/Custom",
 * which by VALUE matches the wizard's existing `examType`, not its
 * `category`. So here we deliberately reuse `examType` for that concept
 * (zero collision) and ALSO store the wizard's real `category` (exam
 * format) so a template can specify the full pattern. Using the exact
 * same field names/meanings as the wizard means applyTemplate() in
 * CreateExamWizard.tsx needs NO changes — it already reads t.category
 * and t.examType correctly.
 *
 * NOTE: examWizardRoutes.js (28.8.4 "Save as Template" + 26 "Quick
 * Templates" picker) already lazily creates a mongoose model named
 * 'ExamTemplate'. Because this file is require()'d once at server
 * startup (see index.js), this richer schema registers FIRST —
 * examWizardRoutes.js's try/catch simply reuses this same model, and
 * its existing fields (name, icon, subject, category, totalQs,
 * subjectQs, duration, totalMarks, correctMarks, negativeMarks,
 * examType, markingScheme, instructions, createdBy) stay 100%
 * backward-compatible.
 */
const mongoose = require('mongoose')

const versionSnapshotSchema = new mongoose.Schema({
  name:          String,
  titleFormat:   String,
  category:      String,   // exam format — Full Mock / Chapter Test / etc.
  examType:      String,   // NEET / JEE / CUET / Custom
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
  titleFormat:    { type: String, default: '{name}' },                  // 29.2 — tokens: {name} {date} {category} {format} {n}
  examType:       { type: String, default: 'NEET' },                    // 29.3 — NEET/JEE/CUET/Custom (the "Category" pills in UI)
  examTypeColor:  { type: String, default: '#4D9FFF' },                 // 29.10 — colour tied to examType
  category:       { type: String, default: 'Full Mock' },               // exam FORMAT — Full Mock/Chapter Test/etc (29.2 "Exam Format")
  subject:        { type: String, default: 'Full Mock' },
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
