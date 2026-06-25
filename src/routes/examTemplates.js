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
