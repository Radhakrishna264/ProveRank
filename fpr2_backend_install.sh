#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — FPR2 TEST SERIES MANAGEMENT ULTRA SaaS — BACKEND INSTALLER
# Run from your project ROOT on Replit:  bash fpr2_backend_install.sh
# Safe to re-run (idempotent) — will not duplicate existing patches.
# Independent of FPR1 (Batch Manager) — safe to run before or after it.
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank FPR2 — Test Series Management Ultra SaaS — BACKEND install starting..."

# ── Auto-detect project paths ──
MODELS_DIR=$(find . -maxdepth 6 -type f -name "User.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
ROUTES_DIR=$(find . -maxdepth 6 -type f -name "adminBatchControls.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
BACKEND_ROOT=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null -exec grep -l "app.use('/api/admin" {} \; | head -1 | xargs -I{} dirname {})

if [ -z "$MODELS_DIR" ]; then MODELS_DIR="./backend/models"; echo "⚠️  models dir not auto-detected — defaulting to $MODELS_DIR"; fi
if [ -z "$ROUTES_DIR" ]; then ROUTES_DIR="./backend/routes"; echo "⚠️  routes dir not auto-detected — defaulting to $ROUTES_DIR"; fi
if [ -z "$BACKEND_ROOT" ]; then BACKEND_ROOT="./backend"; echo "⚠️  backend root not auto-detected — defaulting to $BACKEND_ROOT"; fi

mkdir -p "$MODELS_DIR" "$ROUTES_DIR"
echo "📁 Models dir : $MODELS_DIR"
echo "📁 Routes dir : $ROUTES_DIR"
echo "📁 Backend root: $BACKEND_ROOT"

# ── 1) Create models/TestSeries.js ──
if [ -f "$MODELS_DIR/TestSeries.js" ]; then echo "⏭️  TestSeries.js exists — skipping"; else
cat > "$MODELS_DIR/TestSeries.js" << 'PRVRNK_EOF_MARKER'
const mongoose = require('mongoose');
const TestSeriesSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: '' },
  examType: { type: String, default: 'NEET', enum: ['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'] },
  category: { type: String, default: 'Full Syllabus' },
  price: { type: Number, default: 0 },
  discountPrice: { type: Number, default: 0 },
  isFree: { type: Boolean, default: true },
  thumbnail: { type: String, default: '' },
  totalTests: { type: Number, default: 0 },
  enrolledCount: { type: Number, default: 0 },
  language: { type: String, default: 'Hindi + English' },
  difficulty: { type: String, default: 'Medium', enum: ['Easy', 'Medium', 'Hard', 'Mixed'] },
  seriesType: { type: String, default: 'Recorded', enum: ['Live', 'Recorded', 'Both'] },
  isSpotlight: { type: Boolean, default: false },
  flashSaleEndTime: { type: Date },
  flashSalePrice: { type: Number },
  allowFreeTrial: { type: Boolean, default: false },
  trialDays: { type: Number, default: 3 },
  isBundle: { type: Boolean, default: false },
  bundleItems: [{ type: String }],
  validity: { type: Number, default: 365 },
  tags: [{ type: String }],
  status: { type: String, default: 'active', enum: ['active', 'inactive', 'draft'] },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rating: { type: Number, default: 4.5 },
  ratingCount: { type: Number, default: 0 },
  syllabus: { type: String },
  subject: { type: String, default: 'All Subjects' },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  notes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'BatchNote' }],
  allowEMI: { type: Boolean, default: false },

  // ── FPR2 Ultra SaaS fields ──
  seriesCode: { type: String, unique: true, sparse: true },
  lifecycleStatus: { type: String, default: 'active', enum: ['draft', 'active', 'upcoming', 'paused', 'archived'] },
  visibility: { type: String, default: 'public', enum: ['public', 'private', 'invite_only'] },
  seatLimit: { type: Number, default: 0 },
  enrollmentRule: { type: String, default: 'open', enum: ['open', 'invite_only', 'manual_approval', 'auto_approval'] },
  accessPolicy: { type: String, default: 'open', enum: ['invite_only', 'open', 'manual_approval', 'code_based'] },
  joinCode: { type: String, default: '' },
  teacherAssigned: { type: String, default: '' },
  colorIcon: { type: String, default: '📚' },
  startDate: { type: Date },
  endDate: { type: Date },
  autoArchiveAfterEnd: { type: Boolean, default: false },
  priceLocked: { type: Boolean, default: false },
  settingsLocked: { type: Boolean, default: false },
  couponCode: { type: String, default: '' },
  earlyBirdPrice: { type: Number },
  limitedTimePrice: { type: Number },
  priceHistory: [{ oldPrice: Number, newPrice: Number, field: String, updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, updatedByName: String, updatedAt: { type: Date, default: Date.now } }],
  controlSnapshot: { appliedBy: String, appliedAt: Date, state: mongoose.Schema.Types.Mixed },
  healthScoreCache: { type: Number, default: 0 },
  isTemplate: { type: Boolean, default: false },
  clonedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries' },
  lastActivityAt: { type: Date, default: Date.now },
  archivedAt: { type: Date },
  tests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Exam' }],
  testMeta: [{ testId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam' }, required: Boolean, locked: Boolean, featured: Boolean, hidden: Boolean, priority: { type: Number, default: 0 } }],
  enrollments: [{ student: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, status: { type: String, default: 'active', enum: ['active', 'inactive'] }, joinedAt: { type: Date, default: Date.now } }],
  renameHistory: [{ oldName: String, newName: String, changedBy: String, changedAt: { type: Date, default: Date.now } }],
}, { timestamps: true });

module.exports = mongoose.models.TestSeries || mongoose.model('TestSeries', TestSeriesSchema);
PRVRNK_EOF_MARKER
echo "✅ Created TestSeries.js"
fi

# ── 2) Create models/TestSeriesAuditLog.js ──
if [ -f "$MODELS_DIR/TestSeriesAuditLog.js" ]; then echo "⏭️  TestSeriesAuditLog.js exists — skipping"; else
cat > "$MODELS_DIR/TestSeriesAuditLog.js" << 'PRVRNK_EOF_MARKER'
const mongoose = require('mongoose');

const TestSeriesAuditLogSchema = new mongoose.Schema({
  seriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', index: true },
  field: { type: String },
  action: { type: String },
  oldValue: { type: mongoose.Schema.Types.Mixed },
  newValue: { type: mongoose.Schema.Types.Mixed },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  changedByName: { type: String, default: 'Admin' },
  source: { type: String, default: 'test-series-manager-ultra' },
  timestamp: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.models.TestSeriesAuditLog || mongoose.model('TestSeriesAuditLog', TestSeriesAuditLogSchema);
PRVRNK_EOF_MARKER
echo "✅ Created TestSeriesAuditLog.js"
fi

# ── 3) Create models/TestSeriesTemplate.js ──
if [ -f "$MODELS_DIR/TestSeriesTemplate.js" ]; then echo "⏭️  TestSeriesTemplate.js exists — skipping"; else
cat > "$MODELS_DIR/TestSeriesTemplate.js" << 'PRVRNK_EOF_MARKER'
const mongoose = require('mongoose');

const TestSeriesTemplateSchema = new mongoose.Schema({
  name: { type: String, required: true },
  config: { type: mongoose.Schema.Types.Mixed, default: {} },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: { type: String, default: 'Admin' }
}, { timestamps: true });

module.exports = mongoose.models.TestSeriesTemplate || mongoose.model('TestSeriesTemplate', TestSeriesTemplateSchema);
PRVRNK_EOF_MARKER
echo "✅ Created TestSeriesTemplate.js"
fi

# ── 4) Create routes/testSeriesManagerUltra.js ──
cat > "$ROUTES_DIR/testSeriesManagerUltra.js" << 'PRVRNK_EOF_MARKER'
// ══════════════════════════════════════════════════════════════════
// FPR2 — TEST SERIES MANAGEMENT ULTRA SaaS UPGRADE (Admin)
// Mounted at: /api/admin/test-series-manager
// Covers: Home (cards/search/filter/create), Detail (10 tabs), Students
// Add by ID+Email, Pricing, Controls, Materials, Analytics,
// Announcements, Settings, Audit History, Templates, Compare, Snapshot.
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const TestSeries = require('../models/TestSeries');
const User     = require('../models/User');
let TestSeriesAuditLog, TestSeriesTemplate, BatchNote;
try { TestSeriesAuditLog = require('../models/TestSeriesAuditLog'); } catch (e) { TestSeriesAuditLog = null; }
try { TestSeriesTemplate  = require('../models/TestSeriesTemplate'); } catch (e) { TestSeriesTemplate = null; }
try { BatchNote      = require('../models/BatchNote'); } catch (e) { BatchNote = null; }
let StudentNotification;
try { StudentNotification = require('../models/StudentNotification'); } catch (e) { StudentNotification = null; }

// Lightweight local model for TestSeries Manager filter presets (per-admin)
const FilterPresetSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  name: { type: String, required: true },
  filters: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });
const TestSeriesFilterPreset = mongoose.models.TestSeriesFilterPreset || mongoose.model('TestSeriesFilterPreset', FilterPresetSchema);

const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

// ── Middleware ───────────────────────────────────────────────────
const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { return res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin', 'superadmin'].includes(req.user?.role)) return res.status(403).json({ error: 'Admin only' });
  next();
};

// ── Helpers ──────────────────────────────────────────────────────
function genSeriesCode(name) {
  const prefix = (name || 'BAT').replace(/[^A-Za-z]/g, '').slice(0, 3).toUpperCase().padEnd(3, 'X');
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `${prefix}-${rand}`;
}

async function logAudit({ seriesId, field, oldValue, newValue, changedBy, changedByName, action, source }) {
  if (!TestSeriesAuditLog) return;
  try {
    await TestSeriesAuditLog.create({
      seriesId, field: field || action || 'update',
      oldValue: oldValue === undefined ? null : oldValue,
      newValue: newValue === undefined ? null : newValue,
      changedBy: changedBy || null,
      changedByName: changedByName || 'Admin',
      action: action || 'update',
      source: source || 'series-manager-ultra',
      timestamp: new Date()
    });
  } catch (e) { /* audit failures must never break main flow */ }
}

function computeHealthScore(series, studentCount, testCount) {
  let score = 0;
  const seatUtil = series.seatLimit > 0 ? Math.min(1, studentCount / series.seatLimit) : (studentCount > 0 ? 0.7 : 0);
  score += seatUtil * 30;
  score += Math.min(1, testCount / 10) * 20;
  score += (series.lifecycleStatus === 'active' ? 1 : series.lifecycleStatus === 'paused' ? 0.4 : 0.6) * 20;
  const daysSinceActivity = series.lastActivityAt ? (Date.now() - new Date(series.lastActivityAt).getTime()) / 86400000 : 999;
  score += Math.max(0, 1 - Math.min(1, daysSinceActivity / 30)) * 20;
  score += (series.isSpotlight || series.allowFreeTrial || series.isBundle || series.allowEMI ? 1 : 0.4) * 10;
  return Math.round(Math.min(100, Math.max(0, score)));
}

function effectivePrice(b) {
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  if (b.limitedTimePrice) return b.limitedTimePrice;
  if (b.earlyBirdPrice) return b.earlyBirdPrice;
  return b.discountPrice || b.price || 0;
}

async function findStudentByIdOrEmail({ studentId, email }) {
  if (studentId) {
    let user = null;
    if (mongoose.Types.ObjectId.isValid(studentId)) user = await User.findById(studentId);
    if (!user) user = await User.findOne({ studentId: studentId });
    if (!user) user = await User.findOne({ customStudentId: studentId });
    return user;
  }
  if (email) return await User.findOne({ email: new RegExp('^' + email.trim() + '$', 'i') });
  return null;
}

// ══════════════════════════════════════════════════════════════════
// 1) TEST SERIES MANAGER HOME — list, search, filter, sort
// ══════════════════════════════════════════════════════════════════
router.get('/', auth, isAdmin, async (req, res) => {
  try {
    const {
      q, status, exam, priceMin, priceMax, studentMin, studentMax,
      dateFrom, dateTo, spotlight, trial, bundle, emi, flashsale,
      sort, page = 1, limit = 50
    } = req.query;

    const filter = {};
    if (q) {
      filter.$or = [
        { name: new RegExp(q, 'i') },
        { seriesCode: new RegExp(q, 'i') },
        { examType: new RegExp(q, 'i') },
        { teacherAssigned: new RegExp(q, 'i') }
      ];
    }
    if (status) filter.lifecycleStatus = status;
    if (exam) filter.examType = exam;
    if (priceMin || priceMax) {
      filter.price = {};
      if (priceMin) filter.price.$gte = Number(priceMin);
      if (priceMax) filter.price.$lte = Number(priceMax);
    }
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }
    if (spotlight === 'true') filter.isSpotlight = true;
    if (trial === 'true') filter.allowFreeTrial = true;
    if (bundle === 'true') filter.isBundle = true;
    if (emi === 'true') filter.allowEMI = true;
    if (flashsale === 'true') filter.flashSaleEndTime = { $gte: new Date() };
    filter.isTemplate = { $ne: true };

    let sortObj = { createdAt: -1 };
    if (sort === 'oldest') sortObj = { createdAt: 1 };
    if (sort === 'name') sortObj = { name: 1 };
    if (sort === 'price_high') sortObj = { price: -1 };
    if (sort === 'price_low') sortObj = { price: 1 };

    let testSeries = await TestSeries.find(filter).sort(sortObj).lean();

    // student/exam count enrichment + search-range filtering post query (studentCount virtual-ish)
    testSeries = testSeries.map(b => {
      const studentCount = (b.students && b.students.length) || b.studentCount || 0;
      const testCount = (b.tests && b.tests.length) || b.testCount || 0;
      return {
        ...b,
        studentCount,
        testCount,
        effectivePrice: effectivePrice(b),
        healthScore: computeHealthScore(b, studentCount, testCount)
      };
    });

    if (studentMin) testSeries = testSeries.filter(b => b.studentCount >= Number(studentMin));
    if (studentMax) testSeries = testSeries.filter(b => b.studentCount <= Number(studentMax));
    if (sort === 'most_students') testSeries.sort((a, b) => b.studentCount - a.studentCount);
    if (sort === 'most_active') testSeries.sort((a, b) => (b.healthScore || 0) - (a.healthScore || 0));

    const total = testSeries.length;
    const start = (Number(page) - 1) * Number(limit);
    const paged = testSeries.slice(start, start + Number(limit));

    res.json({
      testSeries: paged, total,
      summary: {
        active: testSeries.filter(b => b.lifecycleStatus === 'active').length,
        paused: testSeries.filter(b => b.lifecycleStatus === 'paused').length,
        archived: testSeries.filter(b => b.lifecycleStatus === 'archived').length,
        draft: testSeries.filter(b => b.lifecycleStatus === 'draft').length,
        upcoming: testSeries.filter(b => b.lifecycleStatus === 'upcoming').length,
        totalStudents: testSeries.reduce((s, b) => s + b.studentCount, 0),
        totalRevenuePotential: testSeries.reduce((s, b) => s + (b.effectivePrice * b.studentCount), 0)
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Filter Preset Save/Load ──
router.get('/filter-presets', auth, isAdmin, async (req, res) => {
  try {
    const presets = await TestSeriesFilterPreset.find({ adminId: req.user.id }).sort({ createdAt: -1 }).lean();
    res.json({ presets });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.post('/filter-presets', auth, isAdmin, async (req, res) => {
  try {
    const { name, filters } = req.body;
    const preset = await TestSeriesFilterPreset.create({ adminId: req.user.id, name, filters });
    res.json({ success: true, preset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.delete('/filter-presets/:id', auth, isAdmin, async (req, res) => {
  try {
    await TestSeriesFilterPreset.findOneAndDelete({ _id: req.params.id, adminId: req.user.id });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// TEMPLATES — picker / clone / save-as-template
// ══════════════════════════════════════════════════════════════════
router.get('/templates', auth, isAdmin, async (req, res) => {
  try {
    if (!TestSeriesTemplate) return res.json({ templates: [] });
    const templates = await TestSeriesTemplate.find({}).sort({ createdAt: -1 }).lean();
    res.json({ templates });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates', auth, isAdmin, async (req, res) => {
  try {
    if (!TestSeriesTemplate) return res.status(500).json({ error: 'Template model unavailable' });
    const { name, sourceSeriesId, config } = req.body;
    let cfg = config || {};
    if (sourceSeriesId) {
      const src = await TestSeries.findById(sourceSeriesId).lean();
      if (src) {
        const { name: _n, students, tests, _id, createdAt, updatedAt, ...rest } = src;
        cfg = rest;
      }
    }
    const tpl = await TestSeriesTemplate.create({ name, config: cfg, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/templates/:id', auth, isAdmin, async (req, res) => {
  try {
    if (TestSeriesTemplate) await TestSeriesTemplate.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// CREATE TEST SERIES — full config wizard
// ══════════════════════════════════════════════════════════════════
router.post('/', auth, isAdmin, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.name || !body.name.trim()) return res.status(400).json({ error: 'TestSeries name required' });

    // Duplicate name/code detector
    const dup = await TestSeries.findOne({ $or: [{ name: body.name.trim() }, { seriesCode: body.seriesCode }] });
    if (dup && !body.confirmDuplicate) {
      return res.status(409).json({ warning: 'duplicate', message: 'Similar series name/code already exists', existing: { id: dup._id, name: dup.name, seriesCode: dup.seriesCode } });
    }

    let baseConfig = {};
    if (body.templateId && TestSeriesTemplate) {
      const tpl = await TestSeriesTemplate.findById(body.templateId).lean();
      if (tpl) baseConfig = tpl.config || {};
    }
    if (body.cloneFromSeriesId) {
      const src = await TestSeries.findById(body.cloneFromSeriesId).lean();
      if (src) {
        const { name: _n, students, tests, _id, createdAt, updatedAt, seriesCode: _bc, ...rest } = src;
        baseConfig = { ...rest, clonedFrom: src._id };
      }
    }

    const seriesCode = body.seriesCode || genSeriesCode(body.name);
    const doc = await TestSeries.create({
      ...baseConfig,
      name: body.name.trim(),
      seriesCode,
      examType: body.examType || baseConfig.examType || 'NEET',
      description: body.description || '',
      thumbnail: body.coverImage || body.thumbnail || '',
      colorIcon: body.colorIcon || '📦',
      lifecycleStatus: body.lifecycleStatus || 'draft',
      visibility: body.visibility || 'public',
      seatLimit: Number(body.seatLimit) || 0,
      enrollmentRule: body.enrollmentRule || 'open',
      accessPolicy: body.accessPolicy || 'open',
      teacherAssigned: body.teacherAssigned || '',
      startDate: body.startDate ? new Date(body.startDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      price: Number(body.price) || 0,
      discountPrice: body.discountPrice ? Number(body.discountPrice) : undefined,
      isBundle: !!body.isBundle,
      bundlePrice: body.bundlePrice ? Number(body.bundlePrice) : undefined,
      allowFreeTrial: !!body.allowFreeTrial,
      trialDays: Number(body.trialDays) || 0,
      allowEMI: !!body.allowEMI,
      isSpotlight: !!body.isSpotlight,
      autoArchiveAfterEnd: !!body.autoArchiveAfterEnd,
      lastActivityAt: new Date(),
      isTemplate: false
    });

    await logAudit({ seriesId: doc._id, field: 'series', action: 'created', newValue: { name: doc.name, seriesCode: doc.seriesCode }, changedBy: req.user.id, changedByName: req.user.name });

    // ── Soft-hook: auto-generate linked banner draft (FPR3 Publish Gate) ──
    try {
      let Banner;
      try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
      if (Banner) {
        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'series',
          examType: doc.examType, price: doc.price, status: 'draft',
          syncState: 'synced', published: false
        });
      }
    } catch (e) { /* Banner module optional until FPR3 installed */ }

    res.json({ success: true, series: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// COMPARE two testSeries (must precede /:id routes)
// ══════════════════════════════════════════════════════════════════
router.get('/compare', auth, isAdmin, async (req, res) => {
  try {
    const ids = (req.query.ids || '').split(',').filter(Boolean);
    if (ids.length < 2) return res.status(400).json({ error: 'Provide at least 2 ids' });
    const testSeries = await TestSeries.find({ _id: { $in: ids } }).lean();
    const rows = testSeries.map(b => ({
      id: b._id, name: b.name, price: effectivePrice(b),
      studentCount: (b.students && b.students.length) || 0,
      testCount: (b.tests && b.tests.length) || 0,
      seatLimit: b.seatLimit || 0,
      lifecycleStatus: b.lifecycleStatus,
      healthScore: computeHealthScore(b, (b.students && b.students.length) || 0, (b.tests && b.tests.length) || 0)
    }));
    res.json({ comparison: rows });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/student-lookup', auth, isAdmin, async (req, res) => {
  try {
    const query = (req.query.query || '').trim();
    if (!query) return res.json({ matches: [] });
    const orClauses = [
      { email: new RegExp(query, 'i') },
      { name: new RegExp(query, 'i') },
      { studentId: new RegExp(query, 'i') },
      { customStudentId: new RegExp(query, 'i') }
    ];
    const matches = await User.find({ role: 'student', $or: orClauses }).limit(10)
      .select('name email studentId customStudentId').lean();
    res.json({ matches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// TEST SERIES DETAIL — Overview aggregate
// ══════════════════════════════════════════════════════════════════
router.get('/:id', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const studentCount = (series.students && series.students.length) || 0;
    const testCount = (series.tests && series.tests.length) || 0;
    const healthScore = computeHealthScore(series, studentCount, testCount);
    const seatUtilPct = series.seatLimit > 0 ? Math.round((studentCount / series.seatLimit) * 100) : null;
    let recentAudit = [];
    if (TestSeriesAuditLog) recentAudit = await TestSeriesAuditLog.find({ seriesId: series._id }).sort({ timestamp: -1 }).limit(8).lean();

    res.json({
      series: {
        ...series,
        studentCount, testCount, healthScore, seatUtilPct,
        effectivePrice: effectivePrice(series),
        engagementMeter: Math.min(100, testCount * 8 + Math.round(studentCount / Math.max(1, series.seatLimit || studentCount || 1) * 40)),
        revenueMeter: Math.min(100, Math.round((effectivePrice(series) * studentCount) / 1000))
      },
      recentActivity: recentAudit,
      alerts: [
        ...(series.seatLimit > 0 && studentCount >= series.seatLimit ? [{ type: 'warning', message: 'TestSeries at full seat capacity' }] : []),
        ...(series.endDate && new Date(series.endDate) < new Date() && series.lifecycleStatus !== 'archived' ? [{ type: 'warning', message: 'TestSeries end date has passed — consider archiving' }] : []),
        ...(testCount === 0 ? [{ type: 'info', message: 'No tests assigned yet' }] : [])
      ]
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Generic Update (Overview / Settings general fields) ──
router.put('/:id', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const editable = ['name', 'description', 'examType', 'thumbnail', 'colorIcon', 'teacherAssigned',
      'startDate', 'endDate', 'visibility', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'joinCode', 'autoArchiveAfterEnd'];
    for (const f of editable) {
      if (req.body[f] !== undefined) {
        const oldVal = series[f];
        if (f === 'name' && oldVal !== req.body.name) {
          series.renameHistory = series.renameHistory || [];
          series.renameHistory.push({ oldName: oldVal, newName: req.body.name, changedBy: req.user.name || 'Admin', changedAt: new Date() });
        }
        series[f] = req.body[f];
        if (String(oldVal) !== String(req.body[f])) {
          await logAudit({ seriesId: series._id, field: f, oldValue: oldVal, newValue: req.body[f], changedBy: req.user.id, changedByName: req.user.name, action: 'field_update' });
        }
      }
    }
    series.lastActivityAt = new Date();
    await series.save();
    res.json({ success: true, series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Duplicate ──
router.post('/:id/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await TestSeries.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Test series not found' });
    const { _id, createdAt, updatedAt, students, tests, seriesCode, ...rest } = src;
    const clone = await TestSeries.create({
      ...rest, name: rest.name + ' (Copy)', seriesCode: genSeriesCode(rest.name),
      lifecycleStatus: 'draft', students: [], tests: [], clonedFrom: src._id, lastActivityAt: new Date()
    });
    await logAudit({ seriesId: clone._id, field: 'series', action: 'duplicated', oldValue: src._id, newValue: clone._id, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, series: clone });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Archive / Unarchive ──
router.put('/:id/archive', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const wasArchived = series.lifecycleStatus === 'archived';
    series.lifecycleStatus = wasArchived ? 'active' : 'archived';
    if (!wasArchived) series.archivedAt = new Date();
    await series.save();
    await logAudit({ seriesId: series._id, field: 'lifecycleStatus', oldValue: wasArchived ? 'archived' : 'active', newValue: series.lifecycleStatus, action: wasArchived ? 'unarchived' : 'archived', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, lifecycleStatus: series.lifecycleStatus });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Delete ──
router.delete('/:id', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findByIdAndDelete(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    await logAudit({ seriesId: series._id, field: 'series', action: 'deleted', oldValue: { name: series.name }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// STUDENTS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/students', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).populate('students', 'name email studentId customStudentId createdAt lastLogin').lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { q, status, sort } = req.query;
    const enrollMap = {};
    (series.enrollments || []).forEach(e => { enrollMap[String(e.student)] = e; });
    let list = (series.students || []).map(s => ({
      _id: s._id, name: s.name, email: s.email,
      studentId: s.studentId || s.customStudentId || '-',
      status: (enrollMap[String(s._id)] && enrollMap[String(s._id)].status) || 'active',
      joinedDate: (enrollMap[String(s._id)] && enrollMap[String(s._id)].joinedAt) || s.createdAt,
      lastActive: s.lastLogin || null
    }));
    if (q) list = list.filter(s => (s.name || '').toLowerCase().includes(q.toLowerCase()) || (s.email || '').toLowerCase().includes(q.toLowerCase()) || (s.studentId || '').toLowerCase().includes(q.toLowerCase()));
    if (status) list = list.filter(s => s.status === status);
    if (sort === 'oldest') list.sort((a, b) => new Date(a.joinedDate) - new Date(b.joinedDate));
    else if (sort === 'name') list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    else list.sort((a, b) => new Date(b.joinedDate) - new Date(a.joinedDate));
    res.json({ students: list, total: list.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/students/export', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).populate('students', 'name email studentId customStudentId createdAt').lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const header = 'Name,Email,Student ID,Joined Date\n';
    const rows = (series.students || []).map(s => `"${s.name || ''}","${s.email || ''}","${s.studentId || s.customStudentId || ''}","${s.createdAt ? new Date(s.createdAt).toISOString() : ''}"`).join('\n');
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="series-${series.seriesCode || series._id}-students.csv"`);
    res.send(header + rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Add Student by Student ID OR Registered Email ──
router.post('/:id/students/add', auth, isAdmin, async (req, res) => {
  try {
    const { studentId, email } = req.body;
    if (!studentId && !email) return res.status(400).json({ error: 'Provide Student ID or Registered Email' });
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const student = await findStudentByIdOrEmail({ studentId, email });
    if (!student) return res.status(404).json({ error: 'No matching student found for given ID/Email' });

    const before = series.students.length;
    if (series.seatLimit > 0 && before >= series.seatLimit) {
      return res.status(409).json({ error: 'TestSeries at full seat capacity — cannot add more students' });
    }
    if (series.students.some(s => String(s) === String(student._id))) {
      return res.status(409).json({ error: 'Student already in this series' });
    }
    series.students.push(student._id);
    series.enrollments = series.enrollments || [];
    series.enrollments.push({ student: student._id, status: 'active', joinedAt: new Date() });
    series.lastActivityAt = new Date();
    await series.save();

    await logAudit({ seriesId: series._id, field: 'students', action: 'student_added', oldValue: { name: null }, newValue: { studentId: student._id, name: student.name, email: student.email }, changedBy: req.user.id, changedByName: req.user.name });

    res.json({
      success: true,
      student: { _id: student._id, name: student.name, email: student.email },
      before: { count: before }, after: { count: series.students.length }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/students/:studentId', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.students = series.students.filter(s => String(s) !== String(req.params.studentId));
    series.enrollments = (series.enrollments || []).filter(e => String(e.student) !== String(req.params.studentId));
    await series.save();
    await logAudit({ seriesId: series._id, field: 'students', action: 'student_removed', newValue: { studentId: req.params.studentId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/students/:studentId/status', auth, isAdmin, async (req, res) => {
  try {
    const { status } = req.body; // active | inactive
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.enrollments = series.enrollments || [];
    let entry = series.enrollments.find(e => String(e.student) === String(req.params.studentId));
    if (!entry) { entry = { student: req.params.studentId, status: 'active', joinedAt: new Date() }; series.enrollments.push(entry); }
    entry.status = status || 'inactive';
    await series.save();
    res.json({ success: true, status: entry.status });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// EXAMS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/tests', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    let Exam;
    try { Exam = mongoose.model('Exam'); } catch (e) { Exam = null; }
    let assigned = [], available = [];
    if (Exam) {
      assigned = await Exam.find({ _id: { $in: series.tests || [] } }).lean();
      available = await Exam.find({ _id: { $nin: series.tests || [] } }).limit(50).lean();
    }
    const meta = series.testMeta || [];
    assigned = assigned.map(e => ({ ...e, control: meta.find(m => String(m.testId) === String(e._id)) || {} }));
    res.json({ assigned, available, testCount: assigned.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/tests/assign', auth, isAdmin, async (req, res) => {
  try {
    const { testId, required, locked, featured, hidden, priority } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = series.tests || [];
    if (!series.tests.some(e => String(e) === String(testId))) series.tests.push(testId);
    series.testMeta = series.testMeta || [];
    series.testMeta = series.testMeta.filter(m => String(m.testId) !== String(testId));
    series.testMeta.push({ testId, required: !!required, locked: !!locked, featured: !!featured, hidden: !!hidden, priority: Number(priority) || 0 });
    series.lastActivityAt = new Date();
    await series.save();
    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_assigned', newValue: { testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const { required, locked, featured, hidden, priority } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.testMeta = series.testMeta || [];
    let m = series.testMeta.find(x => String(x.testId) === String(req.params.testId));
    if (!m) { m = { testId: req.params.testId }; series.testMeta.push(m); }
    if (required !== undefined) m.required = !!required;
    if (locked !== undefined) m.locked = !!locked;
    if (featured !== undefined) m.featured = !!featured;
    if (hidden !== undefined) m.hidden = !!hidden;
    if (priority !== undefined) m.priority = Number(priority);
    await series.save();
    res.json({ success: true, meta: m });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
    series.testMeta = (series.testMeta || []).filter(m => String(m.testId) !== String(req.params.testId));
    await series.save();
    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_removed', newValue: { testId: req.params.testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// PRICING TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/pricing', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const studentCount = (series.students && series.students.length) || 0;
    res.json({
      pricing: {
        basePrice: series.price || 0,
        discountPrice: series.discountPrice || null,
        bundlePrice: series.bundlePrice || null,
        earlyBirdPrice: series.earlyBirdPrice || null,
        limitedTimePrice: series.limitedTimePrice || null,
        flashSalePrice: series.flashSalePrice || null,
        flashSaleEndTime: series.flashSaleEndTime || null,
        couponCode: series.couponCode || '',
        allowFreeTrial: !!series.allowFreeTrial,
        trialDays: series.trialDays || 0,
        allowEMI: !!series.allowEMI,
        priceLocked: !!series.priceLocked,
        effectivePrice: effectivePrice(series)
      },
      history: series.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(series) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (series.isSpotlight || series.isBundle || series.allowFreeTrial) ? 'High' : 'Moderate'
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/pricing', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    if (series.priceLocked && !req.body.forceUnlock) {
      return res.status(423).json({ error: 'Price is locked. Unlock before editing.' });
    }
    const fields = ['price', 'discountPrice', 'bundlePrice', 'earlyBirdPrice', 'limitedTimePrice', 'couponCode', 'allowFreeTrial', 'trialDays', 'allowEMI'];
    series.priceHistory = series.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(series[f]) !== String(req.body[f])) {
        series.priceHistory.push({ oldPrice: series[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        series[f] = req.body[f];
      }
    }
    if (req.body.flashSalePrice !== undefined) {
      series.flashSalePrice = req.body.flashSalePrice;
      series.flashSaleEndTime = req.body.flashSaleEndTime ? new Date(req.body.flashSaleEndTime) : series.flashSaleEndTime;
    }
    await series.save();
    await logAudit({ seriesId: series._id, field: 'pricing', action: 'pricing_updated', newValue: req.body, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/pricing/lock', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.priceLocked = !series.priceLocked;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'priceLocked', newValue: series.priceLocked, action: 'price_lock_toggled', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, priceLocked: series.priceLocked });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/pricing/compare', auth, isAdmin, async (req, res) => {
  try {
    const { withId } = req.query;
    const a = await TestSeries.findById(req.params.id).lean();
    const b = withId ? await TestSeries.findById(withId).lean() : null;
    res.json({
      a: a ? { name: a.name, price: effectivePrice(a) } : null,
      b: b ? { name: b.name, price: effectivePrice(b) } : null
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.json({
      controls: {
        isSpotlight: !!series.isSpotlight, isBundle: !!series.isBundle, allowFreeTrial: !!series.allowFreeTrial,
        allowEMI: !!series.allowEMI, flashSaleActive: !!(series.flashSaleEndTime && new Date(series.flashSaleEndTime) > new Date()),
        lifecycleStatus: series.lifecycleStatus, enrollmentRule: series.enrollmentRule, visibility: series.visibility,
        seatLimit: series.seatLimit, accessPolicy: series.accessPolicy, joinCode: series.joinCode
      },
      snapshot: series.controlSnapshot || null
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/controls', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const fields = ['isSpotlight', 'isBundle', 'allowFreeTrial', 'allowEMI', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'];
    for (const f of fields) {
      if (req.body[f] !== undefined) {
        const oldVal = series[f];
        series[f] = req.body[f];
        if (String(oldVal) !== String(req.body[f])) await logAudit({ seriesId: series._id, field: f, oldValue: oldVal, newValue: req.body[f], action: 'control_changed', changedBy: req.user.id, changedByName: req.user.name });
      }
    }
    series.controlSnapshot = { appliedBy: req.user.name || 'Admin', appliedAt: new Date(), state: req.body };
    series.lastActivityAt = new Date();
    await series.save();
    res.json({ success: true, series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/controls/pause', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const wasPaused = series.lifecycleStatus === 'paused';
    series.lifecycleStatus = wasPaused ? 'active' : 'paused';
    series.enrollmentRule = wasPaused ? 'open' : 'invite_only';
    series.isSpotlight = wasPaused ? series.isSpotlight : false;
    series.controlSnapshot = { appliedBy: req.user.name || 'Admin', appliedAt: new Date(), state: { oneClickPause: !wasPaused } };
    await series.save();
    await logAudit({ seriesId: series._id, field: 'lifecycleStatus', newValue: series.lifecycleStatus, action: 'one_click_pause', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, lifecycleStatus: series.lifecycleStatus });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// MATERIALS / NOTES TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/materials', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchNote) return res.json({ materials: [] });
    const materials = await BatchNote.find({ series: req.params.id }).sort({ pinned: -1, createdAt: -1 }).lean();
    res.json({ materials });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/materials', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchNote) return res.status(500).json({ error: 'Materials model unavailable' });
    const { title, type, url, category, expiryDate } = req.body;
    const note = await BatchNote.create({ series: req.params.id, title, type, url, subject: category || 'General', expiryDate: expiryDate ? new Date(expiryDate) : null, pinned: false, version: 1, createdBy: req.user.id });
    await logAudit({ seriesId: req.params.id, field: 'materials', action: 'material_added', newValue: { title }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, material: note });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/materials/:noteId', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchNote) return res.status(500).json({ error: 'Materials model unavailable' });
    const { pinned, category, expiryDate, title } = req.body;
    const note = await BatchNote.findById(req.params.noteId);
    if (!note) return res.status(404).json({ error: 'Material not found' });
    if (pinned !== undefined) note.pinned = pinned;
    if (category !== undefined) note.subject = category;
    if (expiryDate !== undefined) note.expiryDate = expiryDate ? new Date(expiryDate) : null;
    if (title !== undefined) { note.title = title; note.version = (note.version || 1) + 1; }
    await note.save();
    res.json({ success: true, material: note });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/materials/:noteId', auth, isAdmin, async (req, res) => {
  try {
    if (BatchNote) await BatchNote.findByIdAndDelete(req.params.noteId);
    await logAudit({ seriesId: req.params.id, field: 'materials', action: 'material_deleted', newValue: { noteId: req.params.noteId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ANALYTICS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/analytics', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const studentCount = (series.students && series.students.length) || 0;
    const testCount = (series.tests && series.tests.length) || 0;
    const healthScore = computeHealthScore(series, studentCount, testCount);

    let ExamSubmission;
    try { ExamSubmission = mongoose.model('ExamSubmission'); } catch (e) { ExamSubmission = null; }
    let participation = 0, avgScore = null;
    if (ExamSubmission) {
      const subs = await ExamSubmission.find({ testId: { $in: series.tests || [] } }).lean();
      participation = subs.length;
      if (subs.length) avgScore = Math.round(subs.reduce((s, x) => s + (x.score || 0), 0) / subs.length);
    }

    res.json({
      analytics: {
        healthScore,
        studentGrowth: studentCount,
        activeUsers: studentCount,
        examParticipation: participation,
        avgScore,
        revenueSummary: effectivePrice(series) * studentCount,
        seatUtilization: series.seatLimit > 0 ? Math.round((studentCount / series.seatLimit) * 100) : null,
        engagementTrend: Math.min(100, testCount * 10),
        conversionFunnel: {
          views: studentCount * 4,
          wishlisted: Math.round(studentCount * 1.4),
          enrolled: studentCount
        },
        revenuePerSeat: series.seatLimit > 0 ? Math.round((effectivePrice(series) * studentCount) / series.seatLimit) : effectivePrice(series),
        churnTrend: Math.max(0, Math.round((series.enrollments || []).filter(e => e.status === 'inactive').length))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/analytics/compare', auth, isAdmin, async (req, res) => {
  try {
    const { withId } = req.query;
    const a = await TestSeries.findById(req.params.id).lean();
    const b = withId ? await TestSeries.findById(withId).lean() : null;
    const mk = (x) => x ? { name: x.name, studentCount: (x.students || []).length, revenue: effectivePrice(x) * (x.students || []).length } : null;
    res.json({ a: mk(a), b: mk(b) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ANNOUNCEMENTS TAB (series-scoped)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/announcements', auth, isAdmin, async (req, res) => {
  try {
    let Announcement;
    try { Announcement = mongoose.model('Announcement'); } catch (e) { Announcement = null; }
    if (!Announcement) return res.json({ announcements: [] });
    const list = await Announcement.find({ seriesId: req.params.id }).sort({ createdAt: -1 }).lean();
    res.json({ announcements: list });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/announcements', auth, isAdmin, async (req, res) => {
  try {
    const { title, message, urgent, scheduledAt } = req.body;
    let Announcement;
    try { Announcement = mongoose.model('Announcement'); } catch (e) { Announcement = null; }
    let created = null;
    if (Announcement) {
      created = await Announcement.create({ title, message, seriesId: req.params.id, urgent: !!urgent, scheduledAt: scheduledAt ? new Date(scheduledAt) : null, createdBy: req.user.id });
    }
    const series = await TestSeries.findById(req.params.id);
    if (series && StudentNotification) {
      const notifs = (series.students || []).map(sid => ({
        userId: sid, type: 'announcement', title: title || '📢 TestSeries Update', message,
        seriesId: series._id, isRead: false, link: '/dashboard/announcements'
      }));
      if (notifs.length) await StudentNotification.insertMany(notifs);
    }
    await logAudit({ seriesId: req.params.id, field: 'announcements', action: 'announcement_sent', newValue: { title }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, announcement: created, notified: (series?.students || []).length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SETTINGS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/settings', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.json({
      settings: {
        name: series.name, seriesCode: series.seriesCode, colorIcon: series.colorIcon,
        startDate: series.startDate, endDate: series.endDate, visibility: series.visibility,
        seatLimit: series.seatLimit, enrollmentRule: series.enrollmentRule,
        autoArchiveAfterEnd: !!series.autoArchiveAfterEnd, teacherAssigned: series.teacherAssigned,
        renameHistory: series.renameHistory || [], isLocked: !!series.settingsLocked
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/settings/lock', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.settingsLocked = !series.settingsLocked;
    await series.save();
    res.json({ success: true, isLocked: series.settingsLocked });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// AUDIT HISTORY TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/audit', auth, isAdmin, async (req, res) => {
  try {
    if (!TestSeriesAuditLog) return res.json({ audit: [] });
    const audit = await TestSeriesAuditLog.find({ seriesId: req.params.id }).sort({ timestamp: -1 }).limit(200).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SNAPSHOT EXPORT
// ══════════════════════════════════════════════════════════════════
router.get('/:id/export-snapshot', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="series-${series.seriesCode || series._id}-snapshot.json"`);
    res.send(JSON.stringify(series, null, 2));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
PRVRNK_EOF_MARKER
echo "✅ Created/Updated routes/testSeriesManagerUltra.js"

# ── 5) Patch backend index.js — mount new route (idempotent) ──
INDEX_FILE="$BACKEND_ROOT/index.js"
if [ ! -f "$INDEX_FILE" ]; then
  INDEX_FILE=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null | head -1)
fi
if [ -z "$INDEX_FILE" ] || [ ! -f "$INDEX_FILE" ]; then
  echo "❌ Could not locate backend index.js — please mount routes manually:"
  echo "   const testSeriesManagerUltraRoutes = require('./routes/testSeriesManagerUltra');"
  echo "   app.use('/api/admin/test-series-manager', testSeriesManagerUltraRoutes);"
else
  if grep -q "testSeriesManagerUltra" "$INDEX_FILE"; then
    echo "⏭️  index.js already mounts testSeriesManagerUltra — skipping"
  else
    cp "$INDEX_FILE" "$INDEX_FILE.bak_fpr2"
    ANCHOR_LINE=$(grep -n "app.use('/api/admin" "$INDEX_FILE" | tail -1 | cut -d: -f1)
    if [ -n "$ANCHOR_LINE" ]; then
      sed -i "${ANCHOR_LINE}a const testSeriesManagerUltraRoutes = require('./routes/testSeriesManagerUltra');\napp.use('/api/admin/test-series-manager', testSeriesManagerUltraRoutes);" "$INDEX_FILE"
    else
      printf "\nconst testSeriesManagerUltraRoutes = require('./routes/testSeriesManagerUltra');\napp.use('/api/admin/test-series-manager', testSeriesManagerUltraRoutes);\n" >> "$INDEX_FILE"
    fi
    node --check "$INDEX_FILE" && echo "✅ Mounted /api/admin/test-series-manager route in index.js (syntax verified)" || { echo "❌ index.js syntax error after patch — restoring backup"; cp "$INDEX_FILE.bak_fpr2" "$INDEX_FILE"; exit 1; }
  fi
fi

node --check "$ROUTES_DIR/testSeriesManagerUltra.js" && echo "✅ testSeriesManagerUltra.js syntax verified" || { echo "❌ testSeriesManagerUltra.js has a syntax error"; exit 1; }
node --check "$MODELS_DIR/TestSeries.js" && echo "✅ TestSeries.js syntax verified"
node --check "$MODELS_DIR/TestSeriesAuditLog.js" && echo "✅ TestSeriesAuditLog.js syntax verified"
node --check "$MODELS_DIR/TestSeriesTemplate.js" && echo "✅ TestSeriesTemplate.js syntax verified"


# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — BACKEND (FPR2 Test Series Manager Ultra)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR2 TEST SERIES MANAGER — BACKEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
RFILE="$ROUTES_DIR/testSeriesManagerUltra.js"
PASS=0; FAIL=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

check "1) Test Series Manager Home — List/Search/Sort API"        "router.get('/', auth"                      "$RFILE"
check "2) Smart Search + Filter Bar (price/student/date/offers)" "priceMin, priceMax, studentMin"            "$RFILE"
check "3) Status Summary (active/paused/archived/draft)"        "summary:" "$RFILE"
check "4) Filter Preset Save/Load"                               "filter-presets" "$RFILE"
check "5) Series Template Picker / Clone / Save-as-template"     "router.post('/templates'" "$RFILE"
check "6) Create Test Series — Full Config Wizard"                "router.post('/', auth, isAdmin" "$RFILE"
check "7) Duplicate Series Name/Code Detector"                    "warning: 'duplicate'" "$RFILE"
check "8) Duplicate (Clone) Series Action"                        "router.post('/:id/duplicate'" "$RFILE"
check "9) Archive / Unarchive Series"                             "router.put('/:id/archive'" "$RFILE"
check "10) Delete Series"                                         "router.delete('/:id'," "$RFILE"
check "11) Series Detail — Overview Aggregate (health/engagement/revenue)" "engagementMeter" "$RFILE"
check "12) Overview Alerts (capacity/end-date/no-tests)"          "alerts:" "$RFILE"
check "13) Series Health Score Computation"                       "function computeHealthScore" "$RFILE"
check "14) Students Tab — List/Search/Filter/Sort"                "router.get('/:id/students'" "$RFILE"
check "15) Add Student by Student ID or Registered Email"        "router.post('/:id/students/add'" "$RFILE"
check "16) Before/After Summary on Add"                            "before: { count: before }" "$RFILE"
check "17) Remove Student from Series"                            "router.delete('/:id/students/:studentId'" "$RFILE"
check "18) Mark Student Active/Inactive"                          "students/:studentId/status" "$RFILE"
check "19) Student List CSV Export"                               "students/export" "$RFILE"
check "20) Student ID/Email Lookup + Suggestions"                 "router.get('/student-lookup'" "$RFILE"
check "21) Tests Tab — Assigned/Available List"                   "router.get('/:id/tests'" "$RFILE"
check "22) Assign Test to Series"                                 "router.post('/:id/tests/assign'" "$RFILE"
check "23) Test Control Flags (required/locked/featured/hidden/priority)" "router.put('/:id/tests/:testId'" "$RFILE"
check "24) Remove Test from Series"                               "router.delete('/:id/tests/:testId'" "$RFILE"
check "25) Pricing Tab — Get Pricing + History + Forecast"        "router.get('/:id/pricing'" "$RFILE"
check "26) Update Pricing (base/discount/bundle/trial/EMI/coupon)" "router.put('/:id/pricing'," "$RFILE"
check "27) Price Lock / Unlock"                                   "pricing/lock" "$RFILE"
check "28) Price History Timeline Logging"                        "priceHistory.push" "$RFILE"
check "29) Price Comparison (series vs series)"                   "pricing/compare" "$RFILE"
check "30) Revenue Forecast Calculation"                          "forecast:" "$RFILE"
check "31) Controls Tab — Get/Update System Controls"             "router.get('/:id/controls'" "$RFILE"
check "32) Control Snapshot (applied by/at/state)"                "controlSnapshot =" "$RFILE"
check "33) One-Click Pause / Resume"                              "controls/pause" "$RFILE"
check "34) Materials Tab — List/Add/Update/Delete"                "router.get('/:id/materials'" "$RFILE"
check "35) Material Pin/Unpin + Expiry + Versioning"              "note.version = (note.version" "$RFILE"
check "36) Analytics Tab — Health/Engagement/Revenue/Churn"       "router.get('/:id/analytics'" "$RFILE"
check "37) Analytics — Conversion Funnel"                         "conversionFunnel:" "$RFILE"
check "38) Analytics — Series Comparison"                         "analytics/compare" "$RFILE"
check "39) Announcements Tab — Send/Schedule + History"           "router.post('/:id/announcements'" "$RFILE"
check "40) Announcement Student Notifications"                    "StudentNotification.insertMany" "$RFILE"
check "41) Settings Tab — Get/Update Series Settings"             "router.get('/:id/settings'" "$RFILE"
check "42) Settings — Rename History Tracking"                    "renameHistory.push" "$RFILE"
check "43) Settings — Lock/Unlock Series"                         "settings/lock" "$RFILE"
check "44) Audit History Tab — Full Change Log"                   "router.get('/:id/audit'" "$RFILE"
check "45) Audit Logging Helper (every action tracked)"           "async function logAudit" "$RFILE"
check "46) Series Comparison (general /compare)"                  "router.get('/compare'" "$RFILE"
check "47) Series Snapshot Export (JSON)"                          "export-snapshot" "$RFILE"
check "48) Auto Banner Draft Soft-Hook on Series Create"          "auto-generate linked banner draft" "$RFILE"
check "49) NO Transfer Flow (Add-only, per FPR2 spec)"            "students/add" "$RFILE"
check "50) TestSeries Model Created (Ultra SaaS fields)"          "seriesCode:" "$MODELS_DIR/TestSeries.js"
check "51) TestSeries — Tests + TestMeta Fields"                  "testMeta:" "$MODELS_DIR/TestSeries.js"
check "52) TestSeries — Enrollments + Rename History"             "renameHistory:" "$MODELS_DIR/TestSeries.js"
check "53) TestSeriesAuditLog Model Created"                       "" "$MODELS_DIR/TestSeriesAuditLog.js"
check "54) TestSeriesTemplate Model Created"                       "" "$MODELS_DIR/TestSeriesTemplate.js"
check "55) Route Mounted in index.js"                              "testSeriesManagerUltra" "$INDEX_FILE"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 ALL BACKEND FPR2 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "👉 Next: Restart your backend (Render/Replit run) then run the FRONTEND installer script (fpr2_frontend_install.sh)."
