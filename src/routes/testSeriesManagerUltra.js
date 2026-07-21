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
const Coupon   = require('../models/Coupon');
const Banner   = require('../models/Banner');
const BannerAuditLog = require('../models/BannerAuditLog');
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
  score += (series.isSpotlight || series.allowFreeTrial || series.isBundle ? 1 : 0.4) * 10;
  return Math.round(Math.min(100, Math.max(0, score)));
}

function effectivePrice(b) {
  if (b.discountPrice && (!b.discountValidTill || new Date(b.discountValidTill) >= new Date())) return b.discountPrice;
  return b.price || 0;
}

// ── FPR3 Publish Gate: block launch (lifecycleStatus -> 'active') without a ready banner ──
async function checkBannerGate(seriesId) {
  try {
    let Banner;
    try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: seriesId, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return { ready: false, reason: 'No banner has been created for this test series yet. Open Banner Management to generate one before launching.' };
    const ready = (['ready', 'scheduled', 'published'].includes(banner.status) || banner.published);
    return { ready, reason: ready ? '' : 'Banner draft is not marked ready/approved yet. Open Banner Management to complete it before launching.', bannerId: banner._id };
  } catch (e) { return { ready: true, reason: '' }; }
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
      series: paged, total,
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
    if (!body.name || !body.name.trim()) return res.status(400).json({ error: 'Test series name required' });

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
        ...(series.seatLimit > 0 && studentCount >= series.seatLimit ? [{ type: 'warning', message: 'Test series at full seat capacity' }] : []),
        ...(series.endDate && new Date(series.endDate) < new Date() && series.lifecycleStatus !== 'archived' ? [{ type: 'warning', message: 'Test series end date has passed — consider archiving' }] : []),
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
      return res.status(409).json({ error: 'Test series at full seat capacity — cannot add more students' });
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
    res.json({ assigned, available, testCount: assigned.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/tests/assign', auth, isAdmin, async (req, res) => {
  try {
    const { testId } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = series.tests || [];
    if (!series.tests.some(e => String(e) === String(testId))) series.tests.push(testId);
    series.lastActivityAt = new Date();
    await series.save();
    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_assigned', newValue: { testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
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
        discountValidTill: series.discountValidTill || null,
        priceLocked: !!series.priceLocked,
        effectivePrice: effectivePrice(series)
      },
      history: series.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(series) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (series.isSpotlight || series.isBundle) ? 'High' : 'Moderate'
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
    const fields = ['price', 'discountPrice'];
    series.priceHistory = series.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(series[f]) !== String(req.body[f])) {
        series.priceHistory.push({ oldPrice: series[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        series[f] = req.body[f];
      }
    }
    if (req.body.discountValidTill !== undefined) {
      series.discountValidTill = req.body.discountValidTill ? new Date(req.body.discountValidTill) : null;
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
// COUPON MANAGEMENT TAB — series-scoped coupons only (no global system)
// ══════════════════════════════════════════════════════════════════
function getEffectiveCouponStatus(c) {
  if (c.isDeleted) return 'deleted';
  if (c.status === 'disabled') return 'disabled';
  if (c.status === 'draft') return 'draft';
  const now = new Date();
  if (c.validFrom && new Date(c.validFrom) > now) return 'scheduled';
  if (c.validTill && new Date(c.validTill) < now) return 'expired';
  return 'active';
}
function computeCouponDiscount(c, baseAmount) {
  let discount = c.type === 'percent' ? (baseAmount * c.value / 100) : c.value;
  if (c.type === 'percent' && c.maxDiscount) discount = Math.min(discount, c.maxDiscount);
  discount = Math.min(discount, baseAmount);
  return Math.round(discount * 100) / 100;
}

router.get('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const { status, sort } = req.query;
    const all = await Coupon.find({ scopeType: 'series', scopeId, isDeleted: false }).lean();
    const withStatus = all.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    let coupons = withStatus;
    if (status && status !== 'all') coupons = coupons.filter(c => c.effectiveStatus === status);
    if (sort === 'usage') coupons = coupons.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    else if (sort === 'discount') coupons = coupons.slice().sort((a, b) => (b.value || 0) - (a.value || 0));
    else if (sort === 'expiring') coupons = coupons.slice().sort((a, b) => new Date(a.validTill) - new Date(b.validTill));
    else if (sort === 'updated') coupons = coupons.slice().sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    else coupons = coupons.slice().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const kpis = {
      total: withStatus.length,
      active: withStatus.filter(c => c.effectiveStatus === 'active').length,
      scheduled: withStatus.filter(c => c.effectiveStatus === 'scheduled').length,
      expired: withStatus.filter(c => c.effectiveStatus === 'expired').length,
      disabled: withStatus.filter(c => c.effectiveStatus === 'disabled').length,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0),
      revenueViaCoupons: withStatus.reduce((s, c) => s + (c.revenueGenerated || 0), 0),
      conversionRate: withStatus.length ? Math.round((withStatus.filter(c => c.usageCount > 0).length / withStatus.length) * 100) : 0
    };
    res.json({ coupons, kpis });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons', auth, isAdmin, async (req, res) => {
  try {
    const scopeId = req.params.id;
    const series = await TestSeries.findById(scopeId).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const b = req.body;
    if (!b.code || !b.code.trim()) return res.status(400).json({ error: 'Coupon code required' });
    const code = b.code.trim().toUpperCase();
    if (!b.validFrom || !b.validTill) return res.status(400).json({ error: 'Valid From and Valid Till required' });
    if (new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (!b.value || Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.type === 'percent' && b.maxDiscount !== undefined && b.maxDiscount !== null && b.maxDiscount !== '' && Number(b.maxDiscount) <= 0) return res.status(400).json({ error: 'Max discount must be greater than 0' });
    if (b.usageLimit !== undefined && b.usageLimit !== '' && Number(b.usageLimit) <= 0) return res.status(400).json({ error: 'Usage limit must be greater than 0' });
    const dup = await Coupon.findOne({ scopeType: 'series', scopeId, code, isDeleted: false });
    if (dup) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    const doc = await Coupon.create({
      code, scopeType: 'series', scopeId,
      type: b.type === 'flat' ? 'flat' : 'percent',
      value: Number(b.value),
      maxDiscount: b.type === 'percent' && b.maxDiscount ? Number(b.maxDiscount) : null,
      usageLimit: Number(b.usageLimit) || 100,
      perStudentLimitType: ['once', 'unlimited', 'custom'].includes(b.perStudentLimitType) ? b.perStudentLimitType : 'once',
      perStudentLimitCustom: b.perStudentLimitType === 'custom' ? (Number(b.perStudentLimitCustom) || 1) : 1,
      validFrom: new Date(b.validFrom),
      validTill: new Date(b.validTill),
      description: b.description || '',
      status: (b.status === 'active' || b.status === 'disabled') ? b.status : 'draft',
      visibility: b.visibility === 'hidden' ? 'hidden' : 'public',
      autoApplyBest: !!b.autoApplyBest,
      applicablePlan: b.applicablePlan === 'base_price' ? 'base_price' : 'entire',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'created', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: code }]
    });
    await logAudit({ seriesId: scopeId, field: 'coupon', action: 'coupon_created', newValue: { code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const b = req.body;
    if (b.validFrom && b.validTill && new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (b.value !== undefined && Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.code && b.code.trim().toUpperCase() !== c.code) {
      const newCode = b.code.trim().toUpperCase();
      const dup = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: newCode, isDeleted: false, _id: { $ne: c._id } });
      if (dup) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
      c.history.push({ field: 'code', oldValue: c.code, newValue: newCode, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
      c.code = newCode;
    }
    const editable = ['type', 'value', 'maxDiscount', 'usageLimit', 'perStudentLimitType', 'perStudentLimitCustom', 'validFrom', 'validTill', 'description', 'visibility', 'autoApplyBest', 'applicablePlan'];
    for (const f of editable) {
      if (b[f] !== undefined) {
        let newV = b[f];
        if (f === 'validFrom' || f === 'validTill') newV = new Date(newV);
        if (String(c[f]) !== String(newV)) {
          c.history.push({ field: f, oldValue: c[f], newValue: newV, action: 'edited', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
          c[f] = newV;
        }
      }
    }
    c.updatedBy = req.user.id; c.updatedByName = req.user.name || 'Admin';
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_updated', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: c });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this test series' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId/status', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const { status } = req.body;
    if (!['draft', 'active', 'disabled'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    const old = c.status;
    c.status = status;
    c.statusChangedBy = req.user.name || 'Admin';
    c.statusChangedAt = new Date();
    c.history.push({ field: 'status', oldValue: old, newValue: status, action: 'status_changed', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon_status', action: 'coupon_status_changed', newValue: { code: c.code, status }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, status: c.status, effectiveStatus: getEffectiveCouponStatus(c) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/:couponId/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!src) return res.status(404).json({ error: 'Coupon not found' });
    let newCode = src.code + '-COPY';
    let n = 1;
    while (await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: newCode, isDeleted: false })) {
      n++; newCode = src.code + '-COPY' + n;
    }
    const { _id, createdAt, updatedAt, __v, usageCount, uniqueStudents, revenueGenerated, discountGiven, firstUsedAt, lastUsedAt, usageHistory, history, statusChangedBy, statusChangedAt, ...rest } = src;
    const doc = await Coupon.create({
      ...rest, code: newCode, status: 'draft',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'duplicated', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: newCode, oldValue: src.code }]
    });
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_duplicated', newValue: { from: src.code, to: newCode }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    c.isDeleted = true;
    c.deletedBy = req.user.name || 'Admin';
    c.deletedAt = new Date();
    c.history.push({ field: 'coupon', action: 'deleted', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ seriesId: req.params.id, field: 'coupon', action: 'coupon_deleted', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/analytics', auth, isAdmin, async (req, res) => {
  try {
    const coupons = await Coupon.find({ scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    const withStatus = coupons.map(c => ({ ...c, effectiveStatus: getEffectiveCouponStatus(c) }));
    const sorted = withStatus.slice().sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    const best = sorted[0] || null;
    const worst = sorted.length ? sorted[sorted.length - 1] : null;
    const expiringSoon = withStatus.filter(c => {
      if (c.effectiveStatus !== 'active') return false;
      const days = Math.ceil((new Date(c.validTill) - new Date()) / 86400000);
      return days <= 7 && days >= 0;
    });
    const totalRevenueLoss = withStatus.reduce((s, c) => s + (c.discountGiven || 0), 0);
    res.json({
      bestPerforming: best ? { code: best.code, usageCount: best.usageCount, revenueGenerated: best.revenueGenerated } : null,
      lowestPerforming: worst ? { code: worst.code, usageCount: worst.usageCount, revenueGenerated: worst.revenueGenerated } : null,
      expiringSoon: expiringSoon.map(c => ({ code: c.code, validTill: c.validTill })),
      totalRevenueLoss,
      totalRedemptions: withStatus.reduce((s, c) => s + (c.usageCount || 0), 0)
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/usage', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    res.json({
      usage: (c.usageHistory || []).slice().reverse(),
      summary: {
        totalUses: c.usageCount || 0,
        uniqueStudents: (c.uniqueStudents || []).length,
        firstUsedAt: c.firstUsedAt || null,
        lastUsedAt: c.lastUsedAt || null,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/:couponId/analytics', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'series', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const series = await TestSeries.findById(req.params.id).lean();
    const enrolledCount = (series && series.enrolledCount) || 0;
    const conversionRate = enrolledCount > 0 ? Math.min(100, Math.round(((c.usageCount || 0) / enrolledCount) * 100)) : 0;
    const now = new Date();
    const daysToExpiry = c.validTill ? Math.ceil((new Date(c.validTill) - now) / 86400000) : null;
    const trend = {};
    (c.usageHistory || []).forEach(u => {
      const day = new Date(u.timestamp).toISOString().slice(0, 10);
      trend[day] = (trend[day] || 0) + 1;
    });
    res.json({
      analytics: {
        uses: c.usageCount || 0,
        revenueGenerated: c.revenueGenerated || 0,
        discountGiven: c.discountGiven || 0,
        conversionRate,
        daysToExpiry,
        isExpiringSoon: daysToExpiry !== null && daysToExpiry <= 7 && daysToExpiry >= 0,
        usageTrend: Object.entries(trend).map(([date, count]) => ({ date, count })).sort((a, b) => a.date.localeCompare(b.date))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/validate', auth, async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'Coupon code required' });
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const c = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: code.trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: `Coupon is ${eff}` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'You have already used this coupon the maximum number of times' });
    }
    const base = series.price || 0;
    const discount = computeCouponDiscount(c, base);
    res.json({ valid: true, code: c.code, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/redeem', auth, async (req, res) => {
  try {
    const { code, appliedAmount, orderRef } = req.body;
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const c = await Coupon.findOne({ scopeType: 'series', scopeId: req.params.id, code: (code || '').trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: `Coupon is ${eff}` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'Coupon usage limit reached for this student' });
    }
    const base = Number(appliedAmount) || series.price || 0;
    const discount = computeCouponDiscount(c, base);
    c.usageCount += 1;
    if (!c.uniqueStudents.some(s => String(s) === String(req.user.id))) c.uniqueStudents.push(req.user.id);
    c.revenueGenerated += Math.max(0, base - discount);
    c.discountGiven += discount;
    if (!c.firstUsedAt) c.firstUsedAt = new Date();
    c.lastUsedAt = new Date();
    c.usageHistory.push({ student: req.user.id, studentName: req.user.name || 'Student', appliedAmount: base, discountAmount: discount, orderRef: orderRef || '', status: 'success' });
    await c.save();
    res.json({ success: true, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// BANNER MANAGEMENT TAB — series-scoped banner only (no global list).
// Publish/Launch is intentionally NOT done here — reserved for a
// future Publish Center. This tab only manages the ONE banner linked
// to this series: create/auto-generate/edit/sync/version/analyze.
// ══════════════════════════════════════════════════════════════════
function computeBannerQualityScore(b) {
  let score = 0;
  if (b.title && b.title.trim()) score += 20;
  if (b.ctaText && b.ctaText.trim()) score += 15;
  if (b.price && String(b.price).trim()) score += 15;
  if (b.tagline && b.tagline.trim()) score += 10;
  if (b.highlights && b.highlights.filter(Boolean).length >= 2) score += 15;
  if (b.bgImage && b.bgImage.trim()) score += 10;
  if (b.template) score += 10;
  if (b.primaryColor && b.accentColor) score += 5;
  return Math.min(100, score);
}
function buildBannerSyncFields(series) {
  let validity, duration;
  if (series.startDate && series.endDate) {
    const days = Math.max(1, Math.round((new Date(series.endDate) - new Date(series.startDate)) / 86400000));
    validity = new Date(series.startDate).toLocaleDateString() + ' → ' + new Date(series.endDate).toLocaleDateString();
    duration = days + ' days';
  } else {
    const days = series.validity || 365;
    validity = days + ' days';
    duration = days + ' days';
  }
  const eff = (series.discountPrice && (!series.discountValidTill || new Date(series.discountValidTill) >= new Date())) ? series.discountPrice : (series.price || 0);
  return {
    batchName: series.name || '',
    title: series.name || '',
    examType: series.examType || 'NEET',
    price: String(eff || 0),
    totalTests: String(series.totalTests || 0),
    validity, duration,
    highlights: [
      (series.totalTests || 0) + ' Practice Tests',
      duration + ' Validity',
      series.language || 'Hindi + English'
    ],
    badge: series.isSpotlight ? 'trending' : 'none'
  };
}
function checkBannerSyncState(banner, series) {
  if (banner.syncState === 'manual_override') return 'manual_override';
  const live = buildBannerSyncFields(series);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  return mismatch ? 'pending_sync' : 'synced';
}
async function logBannerAudit({ bannerId, action, oldValue, newValue, performedBy, performedByName, linkedType, linkedBatchId, reason }) {
  try {
    await BannerAuditLog.create({ bannerId, action, oldValue, newValue, performedBy, performedByName: performedByName || 'Admin', linkedType, linkedBatchId, reason: reason || '', timestamp: new Date() });
  } catch (e) { /* audit must never break main flow */ }
}

router.get('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    const syncPreview = buildBannerSyncFields(series);
    if (!banner) return res.json({ banner: null, overview: { status: 'none', readiness: 'banner_required' }, syncPreview, batchName: series.name });
    const liveSyncState = checkBannerSyncState(banner, series);
    const qualityScore = banner.qualityScore || computeBannerQualityScore(banner);
    res.json({
      banner: { ...banner, syncState: liveSyncState, qualityScore },
      overview: {
        status: banner.status, lastUpdated: banner.updatedAt,
        draftState: banner.status === 'draft' ? 'Draft' : banner.status === 'ready' ? 'Ready' : banner.status,
        qualityScore, syncState: liveSyncState,
        recentVersion: banner.versions && banner.versions.length ? banner.versions[banner.versions.length - 1] : null,
        readiness: qualityScore >= 60 && banner.status !== 'draft' ? 'ready' : 'incomplete'
      },
      syncPreview, batchName: series.name
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/auto-generate', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const existing = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } });
    if (existing) return res.status(409).json({ error: 'A banner already exists for this test series. Edit or replace it instead.' });
    const fields = buildBannerSyncFields(series);
    const banner = await Banner.create({
      ...fields, batchId: String(req.params.id),
      tagline: '', ctaText: 'Enroll Now', template: 'classic',
      primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
      fontStyle: 'modern', bgImage: '', published: false,
      linkedType: 'series', linkedBatchId: req.params.id, status: 'draft', syncState: 'synced',
      createdBy: req.user.id
    });
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'created', newValue: { title: banner.title }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    if (banner.status === 'published' && !req.body.forceUnlock) {
      const lockedFields = ['title', 'price', 'examType'];
      const touchingLocked = lockedFields.some(f => req.body[f] !== undefined && req.body[f] !== banner[f]);
      if (touchingLocked) return res.status(423).json({ error: 'Banner is published — critical fields are locked. Use forceUnlock to override.' });
    }
    const versionSnap = banner.toObject();
    delete versionSnap._id; delete versionSnap.versions; delete versionSnap.__v;
    banner.versions = banner.versions || [];
    banner.versions.push({ data: versionSnap, savedAt: new Date(), label: 'v' + (banner.versions.length + 1) });
    const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride'];
    for (const f of editable) { if (req.body[f] !== undefined) banner[f] = req.body[f]; }
    if (req.body.markReady) banner.status = 'ready';
    else if (req.body.saveAsDraft) banner.status = 'draft';
    banner.syncState = 'manual_override';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'edited', linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/sync', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    const oldVal = { title: banner.title, price: banner.price };
    const fields = buildBannerSyncFields(series);
    Object.assign(banner, fields);
    banner.syncState = 'synced';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'synced', oldValue: oldVal, newValue: { title: banner.title, price: banner.price }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const orig = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!orig) return res.status(404).json({ error: 'No banner found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false; orig.status = 'draft'; orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    orig.linkedType = 'none'; orig.linkedBatchId = null;
    const dup = await Banner.create(orig);
    await logBannerAudit({ bannerId: dup._id, action: 'duplicated', oldValue: { from: req.params.id }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/remove', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    banner.status = 'removed';
    banner.removedAt = new Date();
    banner.published = false;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'removed', reason: req.body.reason, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-removed', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: 'removed' }).sort({ removedAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No removed banner found' });
    banner.status = 'draft';
    banner.removedAt = null;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'restored_from_removed', linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/replace', auth, isAdmin, async (req, res) => {
  try {
    const old = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!old) return res.status(404).json({ error: 'No banner found to replace' });
    const oldObj = old.toObject();
    delete oldObj._id; delete oldObj.createdAt; delete oldObj.updatedAt; delete oldObj.versions; delete oldObj.__v;
    const replacement = await Banner.create({
      ...oldObj, ...req.body, status: 'draft', published: false, replacedFrom: old._id,
      linkedType: 'series', linkedBatchId: req.params.id,
      versions: [], analytics: { views: 0, clicks: 0, enrolls: 0 }
    });
    old.status = 'replaced';
    old.replacedBy = replacement._id;
    old.published = false;
    await old.save();
    await logBannerAudit({ bannerId: replacement._id, action: 'replaced', oldValue: { replacedFrom: old._id }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: replacement });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/analytics', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return res.json({ analytics: null });
    const a = banner.analytics || { views: 0, clicks: 0, enrolls: 0 };
    res.json({ analytics: { views: a.views || 0, clicks: a.clicks || 0, enrolls: a.enrolls || 0, clickRate: a.views ? +((a.clicks / a.views) * 100).toFixed(1) : 0, conversionRate: a.views ? +((a.enrolls / a.views) * 100).toFixed(1) : 0, template: banner.template, ctaText: banner.ctaText } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/track', async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.json({ success: false });
    const { type } = req.body;
    const inc = {};
    if (type === 'view') inc['analytics.views'] = 1;
    if (type === 'click') inc['analytics.clicks'] = 1;
    if (type === 'enroll') inc['analytics.enrolls'] = 1;
    if (Object.keys(inc).length) await Banner.findByIdAndUpdate(banner._id, { $inc: inc });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/audit', auth, isAdmin, async (req, res) => {
  try {
    const audit = await BannerAuditLog.find({ linkedType: 'series', linkedBatchId: req.params.id }).sort({ timestamp: -1 }).limit(100).lean();
    res.json({ audit });
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
        flashSaleActive: !!(series.flashSaleEndTime && new Date(series.flashSaleEndTime) > new Date()),
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
    if (req.body.lifecycleStatus === 'active' && series.lifecycleStatus !== 'active') {
      const gate = await checkBannerGate(series._id);
      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });
    }
    const fields = ['isSpotlight', 'isBundle', 'allowFreeTrial', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'];
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
    if (wasPaused) {
      const gate = await checkBannerGate(series._id);
      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });
    }
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
        userId: sid, type: 'announcement', title: title || '📢 Test Series Update', message,
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
