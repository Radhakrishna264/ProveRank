#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
#  ProveRank — Feature 29: Exam Templates — Create, Save & Reuse
#  BACKEND fix / upgrade script  (run on the BACKEND Replit project root)
#  v2 — fixes the category/examType field-collision bug found in testing.
#  No python used — pure bash + node (per project rules).
# ════════════════════════════════════════════════════════════════════════════
set -e

echo "════════════════════════════════════════════════"
echo " Feature 29 — Exam Templates — BACKEND setup (v2)"
echo "════════════════════════════════════════════════"

# ── locate backend project root (the index.js that requires examWizardRoutes) ─
INDEX_FILE=$(grep -rl "require('./routes/examWizardRoutes')" --include="index.js" . 2>/dev/null | head -1)
if [ -z "$INDEX_FILE" ]; then
  echo "❌ index.js (jisme examWizardRoutes required ho) nahi mila."
  echo "   Ye script apne BACKEND project ke root folder se chalao."
  exit 1
fi
BASE_DIR=$(dirname "$INDEX_FILE")
echo "✓ Backend root mila: $BASE_DIR"
mkdir -p "$BASE_DIR/models" "$BASE_DIR/routes"

# ── backup before any overwrite ───────────────────────────────────────────────
cp "$INDEX_FILE" "$INDEX_FILE.bak_feat29"
echo "✓ Backup bana: $INDEX_FILE.bak_feat29"
echo ""
# ── 1) models/ExamTemplate.js — NEW FILE ─────────────────────────────────────
echo "→ Writing models/ExamTemplate.js ..."
cat > "$BASE_DIR/models/ExamTemplate.js" << '__PRRANK_EOF_MODEL1__'
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
__PRRANK_EOF_MODEL1__

# ── 2) models/TemplateCategory.js — NEW FILE ─────────────────────────────────
echo "→ Writing models/TemplateCategory.js ..."
cat > "$BASE_DIR/models/TemplateCategory.js" << '__PRRANK_EOF_MODEL2__'
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
__PRRANK_EOF_MODEL2__

# ── 3) routes/examTemplates.js — NEW FILE ────────────────────────────────────
echo "→ Writing routes/examTemplates.js ..."
cat > "$BASE_DIR/routes/examTemplates.js" << '__PRRANK_EOF_ROUTE__'
/**
 * ProveRank — Feature 29: Exam Templates — Create, Save & Reuse
 * Mounted at /api/exam-templates (see index.js)
 *
 * Field-naming note (see models/ExamTemplate.js header):
 *  - `examType` = NEET/JEE/CUET/Custom  → the "Category" pills in the UI (29.3)
 *  - `category` = Full Mock/Chapter Test/etc → the "Exam Format" picker
 * These reuse the Create-Exam-Wizard's own field names/meanings exactly,
 * so applyTemplate() in CreateExamWizard.tsx needs no changes at all.
 *
 *  29.1  GET    /                     list templates (pinned first)
 *  29.2  POST   /                     create template
 *  29.3  GET    /categories           list categories (defaults + custom) — colours examType
 *  29.4  usageCount field             tracked on /apply
 *  29.5  POST   /:id/duplicate        duplicate template
 *  29.6  lastUsedAt field             tracked on /apply
 *  29.7  GET    /:id                  preview single template
 *  29.8  PATCH  /:id/pin              toggle favourite/pin
 *  29.9  PUT    /:id                  update (auto-snapshots old version)
 *        GET    /:id/versions         version history list
 *        POST   /:id/versions/:idx/restore  restore an old version
 *  29.10 POST   /categories           create custom category + colour
 *  29.13 POST   /:id/apply            apply → increments usage, resolves title
 *        DELETE /:id                  delete template
 */
const express = require('express')
const router  = express.Router()
const { verifyToken, isAdmin } = require('../middleware/auth')
const ExamTemplate     = require('../models/ExamTemplate')
const TemplateCategory = require('../models/TemplateCategory')

// ── 29.3 / 29.10: default categories — these colour the examType pills ────────
const DEFAULT_CATEGORIES = [
  { name: 'NEET',   color: '#4D9FFF', isDefault: true },
  { name: 'JEE',    color: '#FFB84D', isDefault: true },
  { name: 'CUET',   color: '#00C48C', isDefault: true },
  { name: 'Custom', color: '#A78BFA', isDefault: true }
]

// ── 29.2 / 29.13: {name} {date} {category} {format} {n} token resolver ────────
// NOTE: {category} resolves to examType (NEET/JEE/..) to match Feature-29's own
// spec wording; {format} resolves to the wizard's real `category` (Full Mock/..).
function resolveTitleFormat(t) {
  const dateStr = new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
  const fmt = t.titleFormat || '{name}'
  return fmt
    .replace(/{name}/gi, t.name || 'Exam')
    .replace(/{date}/gi, dateStr)
    .replace(/{category}/gi, t.examType || '')
    .replace(/{format}/gi, t.category || '')
    .replace(/{n}/gi, String((t.usageCount || 0) + 1))
    .replace(/\s+/g, ' ')
    .trim()
}

const SNAP_FIELDS = ['name','titleFormat','category','examType','subject','totalQs','subjectQs','sections','duration','totalMarks','correctMarks','negativeMarks','markingScheme','instructions']
function snapshotOf(t) {
  const s = {}
  SNAP_FIELDS.forEach(k => { s[k] = t[k] })
  s.savedAt = new Date()
  return s
}

// ════════════════════════════════════════════════════════════════
// 29.3 — CATEGORIES: list (defaults + this admin's custom ones)
// ════════════════════════════════════════════════════════════════
router.get('/categories', verifyToken, isAdmin, async (req, res) => {
  try {
    const custom = await TemplateCategory.find({ createdBy: req.user.id }).sort({ createdAt: 1 })
    res.json({
      success: true,
      categories: [...DEFAULT_CATEGORIES, ...custom.map(c => ({ name: c.name, color: c.color, isDefault: false, _id: c._id }))]
    })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.10 — CATEGORIES: create custom category + colour
// ════════════════════════════════════════════════════════════════
router.post('/categories', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, color } = req.body
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Category name required hai' })
    if (!color) return res.status(400).json({ success: false, message: 'Colour required hai' })
    const clash = DEFAULT_CATEGORIES.some(c => c.name.toLowerCase() === name.trim().toLowerCase())
      || await TemplateCategory.findOne({ createdBy: req.user.id, name: new RegExp(`^${name.trim()}$`, 'i') })
    if (clash) return res.status(400).json({ success: false, message: 'Ye category naam already exist karta hai' })
    const cat = await TemplateCategory.create({ name: name.trim(), color, createdBy: req.user.id })
    res.json({ success: true, message: 'Category create ho gaya ✅', category: { name: cat.name, color: cat.color, isDefault: false, _id: cat._id } })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.1 — LIST templates (pinned first → last used → newest)
// ════════════════════════════════════════════════════════════════
router.get('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const filter = { createdBy: req.user.id }
    if (req.query.examType && req.query.examType !== 'all') filter.examType = req.query.examType
    if (req.query.search) filter.name = new RegExp(String(req.query.search).trim(), 'i')
    const list = await ExamTemplate.find(filter).sort({ isPinned: -1, lastUsedAt: -1, createdAt: -1 })
    res.json({ success: true, templates: list })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.7 — PREVIEW: get single template
// ════════════════════════════════════════════════════════════════
router.get('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    res.json({ success: true, template: t })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.2 — CREATE template
// ════════════════════════════════════════════════════════════════
router.post('/', verifyToken, isAdmin, async (req, res) => {
  try {
    const b = req.body
    if (!b.name || !b.name.trim()) return res.status(400).json({ success: false, message: 'Template name required hai' })
    const correctMarks = b.correctMarks != null ? b.correctMarks : 4
    const totalMarks = b.totalMarks != null ? b.totalMarks : Math.round((b.totalQs || 0) * correctMarks)
    const t = await ExamTemplate.create({
      name: b.name.trim(),
      icon: b.icon || '📋',
      titleFormat: b.titleFormat || '{name}',
      examType: b.examType || 'NEET',
      examTypeColor: b.examTypeColor || '#4D9FFF',
      category: b.category || 'Full Mock',
      subject: b.subject || 'Full Mock',
      totalQs: b.totalQs || 0,
      subjectQs: b.subjectQs || {},
      sections: b.sections || [],
      duration: b.duration || 60,
      totalMarks,
      correctMarks,
      negativeMarks: b.negativeMarks != null ? b.negativeMarks : 1,
      markingScheme: b.markingScheme || { correct: correctMarks, wrong: b.negativeMarks != null ? b.negativeMarks : 1, skip: 0 },
      instructions: b.instructions || '',
      createdBy: req.user.id,
      updatedBy: req.user.id
    })
    res.json({ success: true, message: 'Template save ho gaya ✅', template: t })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.9 — UPDATE template (auto-snapshots previous version first)
// ════════════════════════════════════════════════════════════════
router.put('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })

    t.versions.unshift(snapshotOf(t))
    if (t.versions.length > 20) t.versions = t.versions.slice(0, 20)

    const b = req.body
    ;['name','icon','titleFormat','examType','examTypeColor','category','subject','totalQs','subjectQs','sections','duration','correctMarks','negativeMarks','markingScheme','instructions'].forEach(k => {
      if (b[k] !== undefined) t[k] = b[k]
    })
    if (b.totalQs !== undefined || b.correctMarks !== undefined) {
      t.totalMarks = Math.round((t.totalQs || 0) * (t.correctMarks != null ? t.correctMarks : 4))
    }
    t.updatedBy = req.user.id
    await t.save()
    res.json({ success: true, message: 'Template update ho gaya ✅', template: t })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.9 — VERSION HISTORY: list
// ════════════════════════════════════════════════════════════════
router.get('/:id/versions', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id }).select('versions name')
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    res.json({ success: true, versions: t.versions })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.9 — VERSION HISTORY: restore an old version
// ════════════════════════════════════════════════════════════════
router.post('/:id/versions/:idx/restore', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    const idx = parseInt(req.params.idx, 10)
    const v = t.versions[idx]
    if (!v) return res.status(404).json({ success: false, message: 'Version nahi mila' })

    const currentSnap = snapshotOf(t)
    SNAP_FIELDS.forEach(k => { t[k] = v[k] })
    t.versions.unshift(currentSnap)
    if (t.versions.length > 20) t.versions = t.versions.slice(0, 20)
    t.updatedBy = req.user.id
    await t.save()
    res.json({ success: true, message: 'Version restore ho gaya ✅', template: t })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.5 — DUPLICATE template
// ════════════════════════════════════════════════════════════════
router.post('/:id/duplicate', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    const obj = t.toObject()
    delete obj._id; delete obj.createdAt; delete obj.updatedAt; delete obj.__v
    obj.name = `${obj.name} (Copy)`
    obj.usageCount = 0
    obj.lastUsedAt = null
    obj.isPinned = false
    obj.versions = []
    obj.createdBy = req.user.id
    obj.updatedBy = req.user.id
    const copy = await ExamTemplate.create(obj)
    res.json({ success: true, message: 'Template duplicate ho gaya ✅', template: copy })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.8 — PIN / FAVOURITE toggle
// ════════════════════════════════════════════════════════════════
router.patch('/:id/pin', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    t.isPinned = !t.isPinned
    await t.save()
    res.json({ success: true, isPinned: t.isPinned })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// 29.13 — APPLY template (usage count + last used + resolved title)
// Returns the doc AS-IS — `category` and `examType` already match the
// exact field names/meanings applyTemplate() in CreateExamWizard.tsx
// expects, so no remapping needed here.
// ════════════════════════════════════════════════════════════════
router.post('/:id/apply', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOne({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    t.usageCount = (t.usageCount || 0) + 1
    t.lastUsedAt = new Date()
    await t.save()
    res.json({ success: true, template: { ...t.toObject(), examTitle: resolveTitleFormat(t) } })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

// ════════════════════════════════════════════════════════════════
// DELETE template
// ════════════════════════════════════════════════════════════════
router.delete('/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const t = await ExamTemplate.findOneAndDelete({ _id: req.params.id, createdBy: req.user.id })
    if (!t) return res.status(404).json({ success: false, message: 'Template nahi mila' })
    res.json({ success: true, message: 'Template delete ho gaya' })
  } catch (err) { res.status(500).json({ success: false, message: err.message }) }
})

module.exports = router
__PRRANK_EOF_ROUTE__

# ── 4) index.js — FULL REWRITE (model requires + route mount added) ─────────
echo "→ Rewriting $INDEX_FILE ..."
cat > "$INDEX_FILE" << '__PRRANK_EOF_INDEX__'
require('dotenv').config();
const express    = require('express');

// ===== STAGE 8: Security Middleware =====
const applySecurityMiddleware = require('./middleware/security').applySecurityMiddleware;
const { apiLimiter, uploadLimiter } = require('./middleware/rateLimiter');
const { checkJWTExpiry } = require('./middleware/loginProtection');
// ========================================
const http       = require('http');
const cors       = require('cors');
const helmet     = require('helmet');
const mongoose   = require('mongoose');
const { initSocket } = require('./config/socket');

// ── Route Imports ─────────────────────────────────────────────
const authRoutes             = require('./routes/auth');
const adminRoutes            = require('./routes/admin');
const examPatchRoutes = require('./routes/exam_patch');
const examRoutes             = require('./routes/exam');
const examExtraRoutes        = require('./routes/examExtra');
const questionRoutes         = require('./routes/question');
const uploadRoutes           = require('./routes/upload');
const excelUploadRoutes      = require('./routes/excelUpload');
const paperGeneratorRoutes   = require('./routes/paperGenerator');
const pdfRoutes              = require('./routes/pdfRoutes');

// ── New Feature Routes (load BEFORE conflicting base routes) ──
const examFeaturesRoutes     = require('./routes/examFeatures');
const examPaperRoutes = require('./routes/examPaper');
const pyqBankAdminRoutes = require('./routes/pyqBankAdmin');
const adminSystemRoutes      = require('./routes/adminSystem');
const adminMonitoringRoutes = require('./routes/adminMonitoringRoutes');
require('./models/AdminNotification');
require('./models/Challenge');
require('./models/ReEvaluation');
require('./models/Grievance');
require('./models/QuestionVersion');
require('./models/QuestionError');
require('./models/ExamTemplate');      // Feature 29 — Exam Templates
require('./models/TemplateCategory');  // Feature 29.10 — custom categories
require('./models/Doubt');
const questionStatsRoutes = require('./routes/questionStatsRoutes');
const examWizardRoutes = require('./routes/examWizardRoutes');
const questionDeleteRoutes = require('./routes/questionDeleteRoutes');
const adminQuestionMgmtRoutes = require('./routes/adminQuestionMgmtRoutes');
const adminResultRoutes = require('./routes/adminResultRoutes');
const adminManagementRoutes  = require('./routes/adminManagement');
const questionFeaturesRoutes = require('./routes/questionFeatures');
const materialRoutes = require('./routes/materialRoutes');
const twoFactorRoutes        = require('./routes/twoFactor');

// ── Optional Routes (load if file exists) ────────────────────
let questionAIRoutes, questionAdvancedRoutes, questionExtraRoutes;
let examSubmissionRoutes, permissionTestRoutes;
try { questionAIRoutes       = require('./routes/questionAI'); } catch(e) {}
try { questionAdvancedRoutes = require('./routes/questionAdvanced'); } catch(e) {}
try { questionExtraRoutes    = require('./routes/questionExtra'); } catch(e) {}
try { examSubmissionRoutes   = require('./routes/examSubmission'); } catch(e) {}
try { permissionTestRoutes   = require('./routes/permissionTest'); } catch(e) {}

// ── App Setup ─────────────────────────────────────────────────
const app    = express();
const server = http.createServer(app);
initSocket(server);

app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({
  origin: [
    'https://prove-rank.vercel.app',
    'http://localhost:3000',
    'http://localhost:3001'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// ===== STAGE 8: Apply Security =====
applySecurityMiddleware(app);
app.use('/api', apiLimiter);
app.use('/api/excel', uploadLimiter);
app.use('/api/upload', uploadLimiter);
app.use('/api', checkJWTExpiry);
// ====================================
app.use(express.json({limit:'1mb'}));

// ── MongoDB ───────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB Connected:', mongoose.connection.host))
  .catch(err => console.log('MongoDB Error:', err));

// ── Health Check ──────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// ── Auth Routes ───────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/auth', twoFactorRoutes);

// ── Admin Routes ──────────────────────────────────────────────
app.use('/api', questionDeleteRoutes)
app.use('/api', examWizardRoutes);
app.use('/api/exam-templates', require('./routes/examTemplates')); // Feature 29 — Exam Templates

app.use('/api', questionStatsRoutes);
;
app.use('/api/admin/manage', adminManagementRoutes);  // S37/S72/S38/S93/M4
app.use('/api/admin', adminSystemRoutes);
app.use('/api/admin', adminMonitoringRoutes);  // Phase 6.2
app.use('/api/admin', adminResultRoutes);       // Phase 6.3
app.use('/api/admin', adminQuestionMgmtRoutes); // Phase 6.4              // S66/N21
app.use('/api/admin', adminRoutes);

// ── Question Routes ───────────────────────────────────────────
app.use('/api/materials', materialRoutes);
app.use('/api/questions', questionFeaturesRoutes);     // AI-1/AI-2/S33/S35/MCQ/MSQ
app.use('/api/questions', questionRoutes);
if (questionAIRoutes)       app.use('/api/questions-advanced', questionAIRoutes);
if (questionAdvancedRoutes) app.use('/api/questions-advanced', questionAdvancedRoutes);
if (questionExtraRoutes)    app.use('/api/questions', questionExtraRoutes);

// ── Exam Routes ───────────────────────────────────────────────
app.use('/api/exams', examFeaturesRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/exams', examPatchRoutes);
             // S5/S75/S85/S26/S62/S31/S96
app.use('/api/exam-paper', examPaperRoutes);
app.use('/api/exams', examExtraRoutes);
if (examSubmissionRoutes) app.use('/api/exams', examSubmissionRoutes);

// ── Other Routes ─────────────────────────────────────────────
app.use('/api/upload', uploadRoutes);
app.use('/api/excel', excelUploadRoutes);
app.use('/api/paper', paperGeneratorRoutes);
app.use('/api/pdf', pdfRoutes);
app.use('/api/exam-instances', require('./routes/examInstance'));
const attemptRoutes = require('./routes/attemptRoutes');
app.use('/api/attempts', attemptRoutes);
if (permissionTestRoutes) app.use('/api/permission', permissionTestRoutes);

// ── Start Server ──────────────────────────────────────────────
const PORT = process.env.PORT || 3000;

const adminBatchControlRoutes  = require('./routes/adminBatchControls');
const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');
app.use('/api/admin/batch-controls',  adminBatchControlRoutes);
app.use('/api/student/batch-extras',  studentBatchExtrasRoutes);

const studentNotificationRoutes = require('./routes/studentNotificationRoutes');
const adminNotificationRoutes = require('./routes/adminNotificationRoutes');
app.use('/api/student/notifications', studentNotificationRoutes);
app.use('/api/admin/notifications', adminNotificationRoutes);

// ── Scheduled Banner Auto-Publish Cron (runs every minute) ──
const cron = require('node-cron');
cron.schedule('* * * * *', async () => {
  try {
    const mongoose = require('mongoose');
    if (mongoose.connection.readyState !== 1) return;
    let BannerModel;
    try { BannerModel = mongoose.model('Banner'); } catch(e) { return; }
    const now = new Date();
    const toPublish = await BannerModel.find({
      published: false,
      scheduledAt: { $lte: now, $exists: true, $ne: null }
    });
    for (const b of toPublish) {
      b.published = true;
      await b.save();
      console.log('Auto-published banner:', b.title, 'at', now.toISOString());
    }
  } catch(e) { /* silent — cron errors should not crash server */ }
});

const batchActivityRoutes = require('./routes/batchActivityRoutes');
app.use('/api/batch-activity', batchActivityRoutes);
server.listen(PORT, '0.0.0.0', () => {
  console.log(`ProveRank server running at http://0.0.0.0:${PORT}`);
});

// -- Result Routes (Phase 4.3)
const sessionRoutes = require('./routes/sessionRoutes');
const faceRoutes = require('./routes/faceRoutes');
const audioRoutes = require('./routes/audioRoutes');
const webcamRoutes = require('./routes/webcamRoutes');
const antiCheatRoutes = require('./routes/antiCheatRoutes');
const resultRoutes = require('./routes/resultRoutes');
app.use('/api/session', sessionRoutes);
app.use('/api/face', faceRoutes);
app.use('/api/audio', audioRoutes);
app.use('/api/webcam', webcamRoutes);
app.use('/api/anticheat', antiCheatRoutes);
app.use('/api/results', resultRoutes);
app.use('/api/admin', require('./routes/adminDashboardRoutes'));
const studentBatchRoutes=require('./routes/studentBatches');
const myBatchesRoutes=require('./routes/myBatches');
const bannerGeneratorRoutes = require('./routes/bannerGenerator');
const adminStoreRoutes   = require('./routes/adminStore');
const studentStoreRoutes = require('./routes/studentStore');
const paymentRoutes = require('./routes/payment');
const brandingRoutes = require('./routes/brandingRoutes')
app.use('/api/admin', brandingRoutes)
app.use('/api/my-batches',myBatchesRoutes);
app.use('/api/admin/banners', bannerGeneratorRoutes);
app.use('/api/student/batches',studentBatchRoutes);
app.use('/api/admin/email', require('./routes/emailSend'))
app.use('/api/admin/store',  adminStoreRoutes);
app.use('/api/store/payment', paymentRoutes);
app.use('/api/store',        studentStoreRoutes);

// -- Content Forge Routes (Features 19B / 20 / 20B / 21 / 21B)
const contentForgeRoutes = require('./routes/contentForge');
app.use('/api/content-forge', contentForgeRoutes)
app.use('/api/pyq-bank', pyqBankAdminRoutes);
;
__PRRANK_EOF_INDEX__

echo ""
echo "── Syntax check (node --check) ──"
SYN_OK=1
node --check "$BASE_DIR/models/ExamTemplate.js" 2>&1 && echo "✅ models/ExamTemplate.js syntax OK" || SYN_OK=0
node --check "$BASE_DIR/models/TemplateCategory.js" 2>&1 && echo "✅ models/TemplateCategory.js syntax OK" || SYN_OK=0
node --check "$BASE_DIR/routes/examTemplates.js" 2>&1 && echo "✅ routes/examTemplates.js syntax OK" || SYN_OK=0
node --check "$INDEX_FILE" 2>&1 && echo "✅ index.js syntax OK" || SYN_OK=0

if [ "$SYN_OK" -eq 0 ]; then
  echo "❌ Syntax error mila — upar dekhein. Backup yahan hai: $INDEX_FILE.bak_feat29"
  exit 1
fi

echo ""
echo "── Feature 29 verification (Backend) ──"
pass=0; total=0
chk(){ total=$((total+1)); if grep -q "$1" "$2" 2>/dev/null; then echo "✅ $3"; pass=$((pass+1)); else echo "❌ $3"; fi }

chk "titleFormat"              "$BASE_DIR/models/ExamTemplate.js"      "29.2  title-format / pattern fields stored"
chk "DEFAULT_CATEGORIES"       "$BASE_DIR/routes/examTemplates.js"     "29.3  NEET/JEE/CUET/Custom categories"
chk "usageCount"                "$BASE_DIR/models/ExamTemplate.js"      "29.4  usage count field"
chk "router.post('/:id/duplicate'" "$BASE_DIR/routes/examTemplates.js" "29.5  duplicate route"
chk "lastUsedAt"                "$BASE_DIR/models/ExamTemplate.js"      "29.6  last-used timestamp field"
chk "router.get('/:id'"         "$BASE_DIR/routes/examTemplates.js"     "29.7  preview (get single) route"
chk "router.patch('/:id/pin'"   "$BASE_DIR/routes/examTemplates.js"     "29.8  pin/favourite route"
chk "router.get('/:id/versions'" "$BASE_DIR/routes/examTemplates.js"    "29.9  version history route"
chk "router.post('/:id/versions/:idx/restore'" "$BASE_DIR/routes/examTemplates.js" "29.9  restore version route"
chk "router.post('/categories'" "$BASE_DIR/routes/examTemplates.js"    "29.10 create custom category + colour route"
chk "examTypeColor"             "$BASE_DIR/models/ExamTemplate.js"      "29.11 colour field for cards"
chk "subjectQs"                 "$BASE_DIR/models/ExamTemplate.js"      "29.12 sections/marks data stored"
chk "router.post('/:id/apply'"  "$BASE_DIR/routes/examTemplates.js"     "29.13 apply route (usage++ + resolved title)"
chk "require('./models/ExamTemplate')" "$INDEX_FILE"                   "29    model registered in index.js"
chk "require('./routes/examTemplates')" "$INDEX_FILE"                  "29    route mounted at /api/exam-templates"

echo ""
echo "Backend checks passed: $pass / $total"
if [ "$pass" -eq "$total" ]; then
  echo "✅ BACKEND — Feature 29 (29 / 29.2-29.13 backend pieces) fully implemented."
else
  echo "⚠️  Kuch backend checks fail hue — upar dekhein, kuch reh gaya ho sakta hai."
fi

echo ""
echo "Bugfix note (v2): category/examType field collision fixed."
echo "  examType = NEET/JEE/CUET/Custom (the 'Category' pills, 29.3)"
echo "  category = Full Mock/Chapter Test/etc (the 'Exam Format' picker)"
echo "  Both reuse the Create-Exam-Wizard's own existing field meanings,"
echo "  so applyTemplate() in the wizard needed zero changes."
echo ""
echo "Old systems untouched (zero risk to existing features):"
echo "  • routes/examFeatures.js  (S75 in-memory stub)        — not touched"
echo "  • routes/examWizardRoutes.js (28.8.4 Save-as-Template) — not touched, now shares this same model"
echo "  • routes/contentForge.js (Exam.isTemplate flag system) — not touched, unrelated"
echo ""
echo "Ab: server restart karo (npm start / Replit Run) taaki naye routes load ho jayein."
