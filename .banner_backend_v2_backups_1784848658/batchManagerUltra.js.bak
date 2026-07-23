// ══════════════════════════════════════════════════════════════════
// FPR1 — BATCH MANAGEMENT ULTRA SaaS UPGRADE (Admin)
// Mounted at: /api/admin/batch-manager
// Covers: Home (cards/search/filter/create), Detail (10 tabs), Students
// Add/Transfer by ID+Email, Pricing, Controls, Materials, Analytics,
// Announcements, Settings, Audit History, Templates, Compare, Snapshot.
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
const Coupon   = require('../models/Coupon');
const Banner   = require('../models/Banner');
const BannerAuditLog = require('../models/BannerAuditLog');
let BatchAuditLog, BatchTemplate, BatchNote;
try { BatchAuditLog = require('../models/BatchAuditLog'); } catch (e) { BatchAuditLog = null; }
try { BatchTemplate  = require('../models/BatchTemplate'); } catch (e) { BatchTemplate = null; }
try { BatchNote      = require('../models/BatchNote'); } catch (e) { BatchNote = null; }
let StudentNotification;
try { StudentNotification = require('../models/StudentNotification'); } catch (e) { StudentNotification = null; }

// Lightweight local model for Batch Manager filter presets (per-admin)
const FilterPresetSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  name: { type: String, required: true },
  filters: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });
const BatchFilterPreset = mongoose.models.BatchFilterPreset || mongoose.model('BatchFilterPreset', FilterPresetSchema);

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
function genBatchCode(name) {
  const prefix = (name || 'BAT').replace(/[^A-Za-z]/g, '').slice(0, 3).toUpperCase().padEnd(3, 'X');
  const rand = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `${prefix}-${rand}`;
}

async function logAudit({ batchId, field, oldValue, newValue, changedBy, changedByName, action, source }) {
  if (!BatchAuditLog) return;
  try {
    await BatchAuditLog.create({
      batchId, field: field || action || 'update',
      oldValue: oldValue === undefined ? null : oldValue,
      newValue: newValue === undefined ? null : newValue,
      changedBy: changedBy || null,
      changedByName: changedByName || 'Admin',
      action: action || 'update',
      source: source || 'batch-manager-ultra',
      timestamp: new Date()
    });
  } catch (e) { /* audit failures must never break main flow */ }
}

function computeHealthScore(batch, studentCount, examCount) {
  let score = 0;
  const seatUtil = batch.seatLimit > 0 ? Math.min(1, studentCount / batch.seatLimit) : (studentCount > 0 ? 0.7 : 0);
  score += seatUtil * 30;
  score += Math.min(1, examCount / 10) * 20;
  score += (batch.lifecycleStatus === 'active' ? 1 : batch.lifecycleStatus === 'paused' ? 0.4 : 0.6) * 20;
  const daysSinceActivity = batch.lastActivityAt ? (Date.now() - new Date(batch.lastActivityAt).getTime()) / 86400000 : 999;
  score += Math.max(0, 1 - Math.min(1, daysSinceActivity / 30)) * 20;
  score += (batch.isSpotlight || batch.allowFreeTrial || batch.isBundle ? 1 : 0.4) * 10;
  return Math.round(Math.min(100, Math.max(0, score)));
}

function effectivePrice(b) {
  if (b.discountPrice && (!b.discountValidTill || new Date(b.discountValidTill) >= new Date())) return b.discountPrice;
  return b.price || 0;
}

// ── FPR3 Publish Gate: block launch (lifecycleStatus -> 'active') without a ready banner ──
async function checkBannerGate(batchId) {
  try {
    let Banner;
    try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: batchId, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return { ready: false, reason: 'No banner has been created for this batch yet. Open Banner Management to generate one before launching.' };
    const ready = (['ready', 'scheduled', 'published'].includes(banner.status) || banner.published);
    return { ready, reason: ready ? '' : 'Banner draft is not marked ready/approved yet. Open Banner Management to complete it before launching.', bannerId: banner._id };
  } catch (e) { return { ready: true, reason: '' }; } // fail-open on transient errors so a banner-service hiccup never bricks the whole batch
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
// 1) BATCH MANAGER HOME — list, search, filter, sort
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
        { batchCode: new RegExp(q, 'i') },
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

    let batches = await Batch.find(filter).sort(sortObj).lean();

    // student/exam count enrichment + search-range filtering post query (studentCount virtual-ish)
    batches = batches.map(b => {
      const studentCount = (b.students && b.students.length) || b.studentCount || 0;
      const examCount = (b.exams && b.exams.length) || b.examCount || 0;
      return {
        ...b,
        studentCount,
        examCount,
        effectivePrice: effectivePrice(b),
        healthScore: computeHealthScore(b, studentCount, examCount)
      };
    });

    if (studentMin) batches = batches.filter(b => b.studentCount >= Number(studentMin));
    if (studentMax) batches = batches.filter(b => b.studentCount <= Number(studentMax));
    if (sort === 'most_students') batches.sort((a, b) => b.studentCount - a.studentCount);
    if (sort === 'most_active') batches.sort((a, b) => (b.healthScore || 0) - (a.healthScore || 0));

    const total = batches.length;
    const start = (Number(page) - 1) * Number(limit);
    const paged = batches.slice(start, start + Number(limit));

    res.json({
      batches: paged, total,
      summary: {
        active: batches.filter(b => b.lifecycleStatus === 'active').length,
        paused: batches.filter(b => b.lifecycleStatus === 'paused').length,
        archived: batches.filter(b => b.lifecycleStatus === 'archived').length,
        draft: batches.filter(b => b.lifecycleStatus === 'draft').length,
        upcoming: batches.filter(b => b.lifecycleStatus === 'upcoming').length,
        totalStudents: batches.reduce((s, b) => s + b.studentCount, 0),
        totalRevenuePotential: batches.reduce((s, b) => s + (b.effectivePrice * b.studentCount), 0)
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Filter Preset Save/Load ──
router.get('/filter-presets', auth, isAdmin, async (req, res) => {
  try {
    const presets = await BatchFilterPreset.find({ adminId: req.user.id }).sort({ createdAt: -1 }).lean();
    res.json({ presets });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.post('/filter-presets', auth, isAdmin, async (req, res) => {
  try {
    const { name, filters } = req.body;
    const preset = await BatchFilterPreset.create({ adminId: req.user.id, name, filters });
    res.json({ success: true, preset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.delete('/filter-presets/:id', auth, isAdmin, async (req, res) => {
  try {
    await BatchFilterPreset.findOneAndDelete({ _id: req.params.id, adminId: req.user.id });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// TEMPLATES — picker / clone / save-as-template
// ══════════════════════════════════════════════════════════════════
router.get('/templates', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchTemplate) return res.json({ templates: [] });
    const templates = await BatchTemplate.find({}).sort({ createdAt: -1 }).lean();
    res.json({ templates });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchTemplate) return res.status(500).json({ error: 'Template model unavailable' });
    const { name, sourceBatchId, config } = req.body;
    let cfg = config || {};
    if (sourceBatchId) {
      const src = await Batch.findById(sourceBatchId).lean();
      if (src) {
        const { name: _n, students, exams, _id, createdAt, updatedAt, ...rest } = src;
        cfg = rest;
      }
    }
    const tpl = await BatchTemplate.create({ name, config: cfg, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/templates/:id', auth, isAdmin, async (req, res) => {
  try {
    if (BatchTemplate) await BatchTemplate.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// CREATE BATCH — full config wizard
// ══════════════════════════════════════════════════════════════════
router.post('/', auth, isAdmin, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.name || !body.name.trim()) return res.status(400).json({ error: 'Batch name required' });

    // Duplicate name/code detector
    const dup = await Batch.findOne({ $or: [{ name: body.name.trim() }, { batchCode: body.batchCode }] });
    if (dup && !body.confirmDuplicate) {
      return res.status(409).json({ warning: 'duplicate', message: 'Similar batch name/code already exists', existing: { id: dup._id, name: dup.name, batchCode: dup.batchCode } });
    }

    let baseConfig = {};
    if (body.templateId && BatchTemplate) {
      const tpl = await BatchTemplate.findById(body.templateId).lean();
      if (tpl) baseConfig = tpl.config || {};
    }
    if (body.cloneFromBatchId) {
      const src = await Batch.findById(body.cloneFromBatchId).lean();
      if (src) {
        const { name: _n, students, exams, _id, createdAt, updatedAt, batchCode: _bc, ...rest } = src;
        baseConfig = { ...rest, clonedFrom: src._id };
      }
    }

    const batchCode = body.batchCode || genBatchCode(body.name);
    const doc = await Batch.create({
      ...baseConfig,
      name: body.name.trim(),
      batchCode,
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

    await logAudit({ batchId: doc._id, field: 'batch', action: 'created', newValue: { name: doc.name, batchCode: doc.batchCode }, changedBy: req.user.id, changedByName: req.user.name });

    // ── Soft-hook: auto-generate linked banner draft (FPR3 Publish Gate) ──
    try {
      let Banner;
      try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
      if (Banner) {
        await Banner.create({
          title: doc.name, linkedBatchId: doc._id, linkedType: 'batch',
          examType: doc.examType, price: String(doc.price || 0), status: 'draft',
          syncState: 'synced', published: false,
          tagline: '', ctaText: 'Enroll Now', ctaShape: 'pill', template: 'classic',
          primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
          fontStyle: 'modern', textAlign: 'left', badge: doc.isSpotlight ? 'trending' : 'none',
          totalTests: '0', validity: (doc.validity || 365) + ' days', duration: (doc.validity || 365) + ' days',
          highlights: ['0 Practice Tests', (doc.validity || 365) + ' days Validity', doc.language || 'Hindi + English'],
          createdBy: req.user.id
        });
      }
    } catch (e) { /* Banner module optional until FPR3 installed */ }

    res.json({ success: true, batch: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// COMPARE two batches (must precede /:id routes)
// ══════════════════════════════════════════════════════════════════
router.get('/compare', auth, isAdmin, async (req, res) => {
  try {
    const ids = (req.query.ids || '').split(',').filter(Boolean);
    if (ids.length < 2) return res.status(400).json({ error: 'Provide at least 2 ids' });
    const batches = await Batch.find({ _id: { $in: ids } }).lean();
    const rows = batches.map(b => ({
      id: b._id, name: b.name, price: effectivePrice(b),
      studentCount: (b.students && b.students.length) || 0,
      examCount: (b.exams && b.exams.length) || 0,
      seatLimit: b.seatLimit || 0,
      lifecycleStatus: b.lifecycleStatus,
      healthScore: computeHealthScore(b, (b.students && b.students.length) || 0, (b.exams && b.exams.length) || 0)
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
// BATCH DETAIL — Overview aggregate
// ══════════════════════════════════════════════════════════════════
router.get('/:id', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const studentCount = (batch.students && batch.students.length) || 0;
    const examCount = (batch.exams && batch.exams.length) || 0;
    const healthScore = computeHealthScore(batch, studentCount, examCount);
    const seatUtilPct = batch.seatLimit > 0 ? Math.round((studentCount / batch.seatLimit) * 100) : null;
    let recentAudit = [];
    if (BatchAuditLog) recentAudit = await BatchAuditLog.find({ batchId: batch._id }).sort({ timestamp: -1 }).limit(8).lean();

    res.json({
      batch: {
        ...batch,
        studentCount, examCount, healthScore, seatUtilPct,
        effectivePrice: effectivePrice(batch),
        engagementMeter: Math.min(100, examCount * 8 + Math.round(studentCount / Math.max(1, batch.seatLimit || studentCount || 1) * 40)),
        revenueMeter: Math.min(100, Math.round((effectivePrice(batch) * studentCount) / 1000))
      },
      recentActivity: recentAudit,
      alerts: [
        ...(batch.seatLimit > 0 && studentCount >= batch.seatLimit ? [{ type: 'warning', message: 'Batch at full seat capacity' }] : []),
        ...(batch.endDate && new Date(batch.endDate) < new Date() && batch.lifecycleStatus !== 'archived' ? [{ type: 'warning', message: 'Batch end date has passed — consider archiving' }] : []),
        ...(examCount === 0 ? [{ type: 'info', message: 'No exams assigned yet' }] : [])
      ]
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Generic Update (Overview / Settings general fields) ──
router.put('/:id', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const editable = ['name', 'description', 'examType', 'thumbnail', 'colorIcon', 'teacherAssigned',
      'startDate', 'endDate', 'visibility', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'joinCode', 'autoArchiveAfterEnd'];
    for (const f of editable) {
      if (req.body[f] !== undefined) {
        const oldVal = batch[f];
        if (f === 'name' && oldVal !== req.body.name) {
          batch.renameHistory = batch.renameHistory || [];
          batch.renameHistory.push({ oldName: oldVal, newName: req.body.name, changedBy: req.user.name || 'Admin', changedAt: new Date() });
        }
        batch[f] = req.body[f];
        if (String(oldVal) !== String(req.body[f])) {
          await logAudit({ batchId: batch._id, field: f, oldValue: oldVal, newValue: req.body[f], changedBy: req.user.id, changedByName: req.user.name, action: 'field_update' });
        }
      }
    }
    batch.lastActivityAt = new Date();
    await batch.save();
    res.json({ success: true, batch });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Duplicate ──
router.post('/:id/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await Batch.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Batch not found' });
    const { _id, createdAt, updatedAt, students, exams, batchCode, ...rest } = src;
    const clone = await Batch.create({
      ...rest, name: rest.name + ' (Copy)', batchCode: genBatchCode(rest.name),
      lifecycleStatus: 'draft', students: [], exams: [], clonedFrom: src._id, lastActivityAt: new Date()
    });
    await logAudit({ batchId: clone._id, field: 'batch', action: 'duplicated', oldValue: src._id, newValue: clone._id, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, batch: clone });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Archive / Unarchive ──
router.put('/:id/archive', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const wasArchived = batch.lifecycleStatus === 'archived';
    batch.lifecycleStatus = wasArchived ? 'active' : 'archived';
    if (!wasArchived) batch.archivedAt = new Date();
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'lifecycleStatus', oldValue: wasArchived ? 'archived' : 'active', newValue: batch.lifecycleStatus, action: wasArchived ? 'unarchived' : 'archived', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, lifecycleStatus: batch.lifecycleStatus });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Delete ──
router.delete('/:id', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findByIdAndDelete(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    await logAudit({ batchId: batch._id, field: 'batch', action: 'deleted', oldValue: { name: batch.name }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// STUDENTS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/students', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).populate('students', 'name email studentId customStudentId createdAt lastLogin').lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { q, status, sort } = req.query;
    const enrollMap = {};
    (batch.enrollments || []).forEach(e => { enrollMap[String(e.student)] = e; });
    let list = (batch.students || []).map(s => ({
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
    const batch = await Batch.findById(req.params.id).populate('students', 'name email studentId customStudentId createdAt').lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const header = 'Name,Email,Student ID,Joined Date\n';
    const rows = (batch.students || []).map(s => `"${s.name || ''}","${s.email || ''}","${s.studentId || s.customStudentId || ''}","${s.createdAt ? new Date(s.createdAt).toISOString() : ''}"`).join('\n');
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="batch-${batch.batchCode || batch._id}-students.csv"`);
    res.send(header + rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Add Student by Student ID OR Registered Email ──
router.post('/:id/students/add', auth, isAdmin, async (req, res) => {
  try {
    const { studentId, email } = req.body;
    if (!studentId && !email) return res.status(400).json({ error: 'Provide Student ID or Registered Email' });
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const student = await findStudentByIdOrEmail({ studentId, email });
    if (!student) return res.status(404).json({ error: 'No matching student found for given ID/Email' });

    const before = batch.students.length;
    if (batch.seatLimit > 0 && before >= batch.seatLimit) {
      return res.status(409).json({ error: 'Batch at full seat capacity — cannot add more students' });
    }
    if (batch.students.some(s => String(s) === String(student._id))) {
      return res.status(409).json({ error: 'Student already in this batch' });
    }
    batch.students.push(student._id);
    batch.enrollments = batch.enrollments || [];
    batch.enrollments.push({ student: student._id, status: 'active', joinedAt: new Date() });
    batch.lastActivityAt = new Date();
    await batch.save();

    await logAudit({ batchId: batch._id, field: 'students', action: 'student_added', oldValue: { name: null }, newValue: { studentId: student._id, name: student.name, email: student.email }, changedBy: req.user.id, changedByName: req.user.name });

    res.json({
      success: true,
      student: { _id: student._id, name: student.name, email: student.email },
      before: { count: before }, after: { count: batch.students.length }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Transfer Student by Student ID OR Registered Email ──
router.post('/:id/students/transfer', auth, isAdmin, async (req, res) => {
  try {
    const { studentId, email, toBatchId } = req.body;
    if (!studentId && !email) return res.status(400).json({ error: 'Provide Student ID or Registered Email' });
    if (!toBatchId) return res.status(400).json({ error: 'Target batch required' });
    const fromBatch = await Batch.findById(req.params.id);
    const toBatch = await Batch.findById(toBatchId);
    if (!fromBatch || !toBatch) return res.status(404).json({ error: 'Batch not found' });
    if (String(fromBatch._id) === String(toBatch._id)) return res.status(400).json({ error: 'Source and target batch cannot be same' });

    const student = await findStudentByIdOrEmail({ studentId, email });
    if (!student) return res.status(404).json({ error: 'No matching student found for given ID/Email' });
    if (!fromBatch.students.some(s => String(s) === String(student._id))) {
      return res.status(409).json({ error: 'Student is not part of the source batch' });
    }
    if (toBatch.seatLimit > 0 && toBatch.students.length >= toBatch.seatLimit) {
      return res.status(409).json({ error: 'Target batch at full seat capacity' });
    }

    const beforeFrom = fromBatch.students.length;
    const beforeTo = toBatch.students.length;

    fromBatch.students = fromBatch.students.filter(s => String(s) !== String(student._id));
    fromBatch.enrollments = (fromBatch.enrollments || []).filter(e => String(e.student) !== String(student._id));
    fromBatch.lastActivityAt = new Date();
    await fromBatch.save();

    if (!toBatch.students.some(s => String(s) === String(student._id))) {
      toBatch.students.push(student._id);
      toBatch.enrollments = toBatch.enrollments || [];
      toBatch.enrollments.push({ student: student._id, status: 'active', joinedAt: new Date() });
    }
    toBatch.lastActivityAt = new Date();
    await toBatch.save();

    await logAudit({ batchId: fromBatch._id, field: 'students', action: 'student_transferred_out', newValue: { toBatch: toBatch._id, name: student.name }, changedBy: req.user.id, changedByName: req.user.name });
    await logAudit({ batchId: toBatch._id, field: 'students', action: 'student_transferred_in', newValue: { fromBatch: fromBatch._id, name: student.name }, changedBy: req.user.id, changedByName: req.user.name });

    res.json({
      success: true,
      student: { _id: student._id, name: student.name, email: student.email },
      before: { fromCount: beforeFrom, toCount: beforeTo },
      after: { fromCount: fromBatch.students.length, toCount: toBatch.students.length }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/students/:studentId', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.students = batch.students.filter(s => String(s) !== String(req.params.studentId));
    batch.enrollments = (batch.enrollments || []).filter(e => String(e.student) !== String(req.params.studentId));
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'students', action: 'student_removed', newValue: { studentId: req.params.studentId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/students/:studentId/status', auth, isAdmin, async (req, res) => {
  try {
    const { status } = req.body; // active | inactive
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.enrollments = batch.enrollments || [];
    let entry = batch.enrollments.find(e => String(e.student) === String(req.params.studentId));
    if (!entry) { entry = { student: req.params.studentId, status: 'active', joinedAt: new Date() }; batch.enrollments.push(entry); }
    entry.status = status || 'inactive';
    await batch.save();
    res.json({ success: true, status: entry.status });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// EXAMS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/exams', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    let Exam;
    try { Exam = mongoose.model('Exam'); } catch (e) { Exam = null; }
    let assigned = [], available = [];
    if (Exam) {
      assigned = await Exam.find({ _id: { $in: batch.exams || [] } }).lean();
      available = await Exam.find({ _id: { $nin: batch.exams || [] } }).limit(50).lean();
    }
    res.json({ assigned, available, examCount: assigned.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/exams/assign', auth, isAdmin, async (req, res) => {
  try {
    const { examId } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = batch.exams || [];
    if (!batch.exams.some(e => String(e) === String(examId))) batch.exams.push(examId);
    batch.lastActivityAt = new Date();
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_assigned', newValue: { examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_removed', newValue: { examId: req.params.examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// PRICING TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/pricing', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const studentCount = (batch.students && batch.students.length) || 0;
    res.json({
      pricing: {
        basePrice: batch.price || 0,
        discountPrice: batch.discountPrice || null,
        discountValidTill: batch.discountValidTill || null,
        priceLocked: !!batch.priceLocked,
        effectivePrice: effectivePrice(batch)
      },
      history: batch.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(batch) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (batch.isSpotlight || batch.isBundle) ? 'High' : 'Moderate'
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/pricing', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    if (batch.priceLocked && !req.body.forceUnlock) {
      return res.status(423).json({ error: 'Price is locked. Unlock before editing.' });
    }
    const fields = ['price', 'discountPrice'];
    batch.priceHistory = batch.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(batch[f]) !== String(req.body[f])) {
        batch.priceHistory.push({ oldPrice: batch[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        batch[f] = req.body[f];
      }
    }
    if (req.body.discountValidTill !== undefined) {
      batch.discountValidTill = req.body.discountValidTill ? new Date(req.body.discountValidTill) : null;
    }
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'pricing', action: 'pricing_updated', newValue: req.body, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, batch });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/pricing/lock', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.priceLocked = !batch.priceLocked;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'priceLocked', newValue: batch.priceLocked, action: 'price_lock_toggled', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, priceLocked: batch.priceLocked });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/pricing/compare', auth, isAdmin, async (req, res) => {
  try {
    const { withId } = req.query;
    const a = await Batch.findById(req.params.id).lean();
    const b = withId ? await Batch.findById(withId).lean() : null;
    res.json({
      a: a ? { name: a.name, price: effectivePrice(a) } : null,
      b: b ? { name: b.name, price: effectivePrice(b) } : null
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// COUPON MANAGEMENT TAB — batch-scoped coupons only (no global system)
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
    const all = await Coupon.find({ scopeType: 'batch', scopeId, isDeleted: false }).lean();
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
    const batch = await Batch.findById(scopeId).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const b = req.body;
    if (!b.code || !b.code.trim()) return res.status(400).json({ error: 'Coupon code required' });
    const code = b.code.trim().toUpperCase();
    if (!b.validFrom || !b.validTill) return res.status(400).json({ error: 'Valid From and Valid Till required' });
    if (new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (!b.value || Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.type === 'percent' && b.maxDiscount !== undefined && b.maxDiscount !== null && b.maxDiscount !== '' && Number(b.maxDiscount) <= 0) return res.status(400).json({ error: 'Max discount must be greater than 0' });
    if (b.usageLimit !== undefined && b.usageLimit !== '' && Number(b.usageLimit) <= 0) return res.status(400).json({ error: 'Usage limit must be greater than 0' });
    const dup = await Coupon.findOne({ scopeType: 'batch', scopeId, code, isDeleted: false });
    if (dup) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    const doc = await Coupon.create({
      code, scopeType: 'batch', scopeId,
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
    await logAudit({ batchId: scopeId, field: 'coupon', action: 'coupon_created', newValue: { code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const b = req.body;
    if (b.validFrom && b.validTill && new Date(b.validTill) <= new Date(b.validFrom)) return res.status(400).json({ error: 'Valid Till must be after Valid From' });
    if (b.value !== undefined && Number(b.value) <= 0) return res.status(400).json({ error: 'Value must be greater than 0' });
    if (b.code && b.code.trim().toUpperCase() !== c.code) {
      const newCode = b.code.trim().toUpperCase();
      const dup = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: newCode, isDeleted: false, _id: { $ne: c._id } });
      if (dup) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
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
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_updated', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: c });
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Coupon code already exists for this batch' });
    res.status(500).json({ error: e.message });
  }
});

router.put('/:id/coupons/:couponId/status', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const { status } = req.body;
    if (!['draft', 'active', 'disabled'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    const old = c.status;
    c.status = status;
    c.statusChangedBy = req.user.name || 'Admin';
    c.statusChangedAt = new Date();
    c.history.push({ field: 'status', oldValue: old, newValue: status, action: 'status_changed', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ batchId: req.params.id, field: 'coupon_status', action: 'coupon_status_changed', newValue: { code: c.code, status }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, status: c.status, effectiveStatus: getEffectiveCouponStatus(c) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/:couponId/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const src = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    if (!src) return res.status(404).json({ error: 'Coupon not found' });
    let newCode = src.code + '-COPY';
    let n = 1;
    while (await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: newCode, isDeleted: false })) {
      n++; newCode = src.code + '-COPY' + n;
    }
    const { _id, createdAt, updatedAt, __v, usageCount, uniqueStudents, revenueGenerated, discountGiven, firstUsedAt, lastUsedAt, usageHistory, history, statusChangedBy, statusChangedAt, ...rest } = src;
    const doc = await Coupon.create({
      ...rest, code: newCode, status: 'draft',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin',
      history: [{ field: 'coupon', action: 'duplicated', performedBy: req.user.id, performedByName: req.user.name || 'Admin', newValue: newCode, oldValue: src.code }]
    });
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_duplicated', newValue: { from: src.code, to: newCode }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, coupon: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/coupons/:couponId', auth, isAdmin, async (req, res) => {
  try {
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    c.isDeleted = true;
    c.deletedBy = req.user.name || 'Admin';
    c.deletedAt = new Date();
    c.history.push({ field: 'coupon', action: 'deleted', performedBy: req.user.id, performedByName: req.user.name || 'Admin' });
    await c.save();
    await logAudit({ batchId: req.params.id, field: 'coupon', action: 'coupon_deleted', newValue: { code: c.code }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/coupons/analytics', auth, isAdmin, async (req, res) => {
  try {
    const coupons = await Coupon.find({ scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
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
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
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
    const c = await Coupon.findOne({ _id: req.params.couponId, scopeType: 'batch', scopeId: req.params.id, isDeleted: false }).lean();
    if (!c) return res.status(404).json({ error: 'Coupon not found' });
    const batch = await Batch.findById(req.params.id).lean();
    const enrolledCount = (batch && batch.enrolledCount) || 0;
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
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const c = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: code.trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: `Coupon is ${eff}` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'You have already used this coupon the maximum number of times' });
    }
    const base = batch.price || 0;
    const discount = computeCouponDiscount(c, base);
    res.json({ valid: true, code: c.code, discount, finalPrice: Math.max(0, base - discount) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/coupons/redeem', auth, async (req, res) => {
  try {
    const { code, appliedAmount, orderRef } = req.body;
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const c = await Coupon.findOne({ scopeType: 'batch', scopeId: req.params.id, code: (code || '').trim().toUpperCase(), isDeleted: false });
    if (!c) return res.status(404).json({ error: 'Invalid coupon code' });
    const eff = getEffectiveCouponStatus(c);
    if (eff !== 'active') return res.status(400).json({ error: `Coupon is ${eff}` });
    if (c.usageLimit && c.usageCount >= c.usageLimit) return res.status(400).json({ error: 'Coupon usage limit reached' });
    if (c.perStudentLimitType !== 'unlimited') {
      const limit = c.perStudentLimitType === 'once' ? 1 : (c.perStudentLimitCustom || 1);
      const usedByStudent = (c.usageHistory || []).filter(u => String(u.student) === String(req.user.id)).length;
      if (usedByStudent >= limit) return res.status(400).json({ error: 'Coupon usage limit reached for this student' });
    }
    const base = Number(appliedAmount) || batch.price || 0;
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
// BANNER MANAGEMENT TAB — batch-scoped banner only (no global list).
// Publish/Launch is intentionally NOT done here — reserved for a
// future Publish Center. This tab only manages the ONE banner linked
// to this batch: create/auto-generate/edit/sync/version/analyze.
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
function buildBannerSyncFields(batch) {
  let validity, duration;
  if (batch.startDate && batch.endDate) {
    const days = Math.max(1, Math.round((new Date(batch.endDate) - new Date(batch.startDate)) / 86400000));
    validity = new Date(batch.startDate).toLocaleDateString() + ' → ' + new Date(batch.endDate).toLocaleDateString();
    duration = days + ' days';
  } else {
    const days = batch.validity || 365;
    validity = days + ' days';
    duration = days + ' days';
  }
  const eff = (batch.discountPrice && (!batch.discountValidTill || new Date(batch.discountValidTill) >= new Date())) ? batch.discountPrice : (batch.price || 0);
  return {
    batchName: batch.name || '',
    title: batch.name || '',
    examType: batch.examType || 'NEET',
    price: String(eff || 0),
    totalTests: String(batch.totalTests || 0),
    validity, duration,
    highlights: [
      (batch.totalTests || 0) + ' Practice Tests',
      duration + ' Validity',
      batch.language || 'Hindi + English'
    ],
    badge: batch.isSpotlight ? 'trending' : 'none'
  };
}
function checkBannerSyncState(banner, batch) {
  const live = buildBannerSyncFields(batch);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  if (banner.syncState === 'manual_override') return mismatch ? 'conflict' : 'manual_override';
  return mismatch ? 'pending_sync' : 'synced';
}
async function logBannerAudit({ bannerId, action, oldValue, newValue, performedBy, performedByName, linkedType, linkedBatchId, reason }) {
  try {
    await BannerAuditLog.create({ bannerId, action, oldValue, newValue, performedBy, performedByName: performedByName || 'Admin', linkedType, linkedBatchId, reason: reason || '', timestamp: new Date() });
  } catch (e) { /* audit must never break main flow */ }
}

router.get('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    const syncPreview = buildBannerSyncFields(batch);
    if (!banner) return res.json({ banner: null, overview: { status: 'none', readiness: 'banner_required' }, syncPreview, batchName: batch.name });
    const liveSyncState = checkBannerSyncState(banner, batch);
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
      syncPreview, batchName: batch.name
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/auto-generate', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const existing = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } });
    if (existing) return res.status(409).json({ error: 'A banner already exists for this batch. Edit or replace it instead.' });
    const fields = buildBannerSyncFields(batch);
    const banner = await Banner.create({
      ...fields, batchId: String(req.params.id),
      tagline: '', ctaText: 'Enroll Now', template: 'classic',
      primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
      fontStyle: 'modern', bgImage: '', published: false,
      linkedType: 'batch', linkedBatchId: req.params.id, status: 'draft', syncState: 'synced',
      createdBy: req.user.id
    });
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'created', newValue: { title: banner.title }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
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
    const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride', 'textAlign'];
    for (const f of editable) { if (req.body[f] !== undefined) banner[f] = req.body[f]; }
    if (req.body.markReady) banner.status = 'ready';
    else if (req.body.saveAsDraft) banner.status = 'draft';
    banner.syncState = 'manual_override';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'edited', linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/sync', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    const oldVal = { title: banner.title, price: banner.price };
    const fields = buildBannerSyncFields(batch);
    Object.assign(banner, fields);
    banner.syncState = 'synced';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'synced', oldValue: oldVal, newValue: { title: banner.title, price: banner.price }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const orig = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!orig) return res.status(404).json({ error: 'No banner found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false; orig.status = 'draft'; orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    orig.linkedType = 'none'; orig.linkedBatchId = null;
    const dup = await Banner.create(orig);
    await logBannerAudit({ bannerId: dup._id, action: 'duplicated', oldValue: { from: req.params.id }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/remove', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    banner.status = 'removed';
    banner.removedAt = new Date();
    banner.published = false;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'removed', reason: req.body.reason, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-removed', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: 'removed' }).sort({ removedAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No removed banner found' });
    banner.status = 'draft';
    banner.removedAt = null;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'restored_from_removed', linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/replace', auth, isAdmin, async (req, res) => {
  try {
    const old = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!old) return res.status(404).json({ error: 'No banner found to replace' });
    const oldObj = old.toObject();
    delete oldObj._id; delete oldObj.createdAt; delete oldObj.updatedAt; delete oldObj.versions; delete oldObj.__v;
    const replacement = await Banner.create({
      ...oldObj, ...req.body, status: 'draft', published: false, replacedFrom: old._id,
      linkedType: 'batch', linkedBatchId: req.params.id,
      versions: [], analytics: { views: 0, clicks: 0, enrolls: 0 }
    });
    old.status = 'replaced';
    old.replacedBy = replacement._id;
    old.published = false;
    await old.save();
    await logBannerAudit({ bannerId: replacement._id, action: 'replaced', oldValue: { replacedFrom: old._id }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: replacement });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/analytics', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return res.json({ analytics: null });
    const a = banner.analytics || { views: 0, clicks: 0, enrolls: 0 };
    res.json({ analytics: { views: a.views || 0, clicks: a.clicks || 0, enrolls: a.enrolls || 0, clickRate: a.views ? +((a.clicks / a.views) * 100).toFixed(1) : 0, conversionRate: a.views ? +((a.enrolls / a.views) * 100).toFixed(1) : 0, template: banner.template, ctaText: banner.ctaText } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/track', async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
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
    const audit = await BannerAuditLog.find({ linkedType: 'batch', linkedBatchId: req.params.id }).sort({ timestamp: -1 }).limit(100).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.json({
      controls: {
        isSpotlight: !!batch.isSpotlight, isBundle: !!batch.isBundle, allowFreeTrial: !!batch.allowFreeTrial,
        flashSaleActive: !!(batch.flashSaleEndTime && new Date(batch.flashSaleEndTime) > new Date()),
        lifecycleStatus: batch.lifecycleStatus, enrollmentRule: batch.enrollmentRule, visibility: batch.visibility,
        seatLimit: batch.seatLimit, accessPolicy: batch.accessPolicy, joinCode: batch.joinCode
      },
      snapshot: batch.controlSnapshot || null
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/controls', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    if (req.body.lifecycleStatus === 'active' && batch.lifecycleStatus !== 'active') {
      const gate = await checkBannerGate(batch._id);
      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });
    }
    const fields = ['isSpotlight', 'isBundle', 'allowFreeTrial', 'lifecycleStatus', 'enrollmentRule', 'visibility', 'seatLimit', 'accessPolicy', 'joinCode'];
    for (const f of fields) {
      if (req.body[f] !== undefined) {
        const oldVal = batch[f];
        batch[f] = req.body[f];
        if (String(oldVal) !== String(req.body[f])) await logAudit({ batchId: batch._id, field: f, oldValue: oldVal, newValue: req.body[f], action: 'control_changed', changedBy: req.user.id, changedByName: req.user.name });
      }
    }
    batch.controlSnapshot = { appliedBy: req.user.name || 'Admin', appliedAt: new Date(), state: req.body };
    batch.lastActivityAt = new Date();
    await batch.save();
    res.json({ success: true, batch });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/controls/pause', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const wasPaused = batch.lifecycleStatus === 'paused';
    if (wasPaused) {
      const gate = await checkBannerGate(batch._id);
      if (!gate.ready) return res.status(423).json({ error: gate.reason, gate: 'launch_blocked' });
    }
    batch.lifecycleStatus = wasPaused ? 'active' : 'paused';
    batch.enrollmentRule = wasPaused ? 'open' : 'invite_only';
    batch.isSpotlight = wasPaused ? batch.isSpotlight : false;
    batch.controlSnapshot = { appliedBy: req.user.name || 'Admin', appliedAt: new Date(), state: { oneClickPause: !wasPaused } };
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'lifecycleStatus', newValue: batch.lifecycleStatus, action: 'one_click_pause', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, lifecycleStatus: batch.lifecycleStatus });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// MATERIALS / NOTES TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/materials', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchNote) return res.json({ materials: [] });
    const materials = await BatchNote.find({ batch: req.params.id }).sort({ pinned: -1, createdAt: -1 }).lean();
    res.json({ materials });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/materials', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchNote) return res.status(500).json({ error: 'Materials model unavailable' });
    const { title, type, url, category, expiryDate } = req.body;
    const note = await BatchNote.create({ batch: req.params.id, title, type, url, subject: category || 'General', expiryDate: expiryDate ? new Date(expiryDate) : null, pinned: false, version: 1, createdBy: req.user.id });
    await logAudit({ batchId: req.params.id, field: 'materials', action: 'material_added', newValue: { title }, changedBy: req.user.id, changedByName: req.user.name });
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
    await logAudit({ batchId: req.params.id, field: 'materials', action: 'material_deleted', newValue: { noteId: req.params.noteId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ANALYTICS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/analytics', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const studentCount = (batch.students && batch.students.length) || 0;
    const examCount = (batch.exams && batch.exams.length) || 0;
    const healthScore = computeHealthScore(batch, studentCount, examCount);

    let ExamSubmission;
    try { ExamSubmission = mongoose.model('ExamSubmission'); } catch (e) { ExamSubmission = null; }
    let participation = 0, avgScore = null;
    if (ExamSubmission) {
      const subs = await ExamSubmission.find({ examId: { $in: batch.exams || [] } }).lean();
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
        revenueSummary: effectivePrice(batch) * studentCount,
        seatUtilization: batch.seatLimit > 0 ? Math.round((studentCount / batch.seatLimit) * 100) : null,
        engagementTrend: Math.min(100, examCount * 10),
        conversionFunnel: {
          views: studentCount * 4,
          wishlisted: Math.round(studentCount * 1.4),
          enrolled: studentCount
        },
        revenuePerSeat: batch.seatLimit > 0 ? Math.round((effectivePrice(batch) * studentCount) / batch.seatLimit) : effectivePrice(batch),
        churnTrend: Math.max(0, Math.round((batch.enrollments || []).filter(e => e.status === 'inactive').length))
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/analytics/compare', auth, isAdmin, async (req, res) => {
  try {
    const { withId } = req.query;
    const a = await Batch.findById(req.params.id).lean();
    const b = withId ? await Batch.findById(withId).lean() : null;
    const mk = (x) => x ? { name: x.name, studentCount: (x.students || []).length, revenue: effectivePrice(x) * (x.students || []).length } : null;
    res.json({ a: mk(a), b: mk(b) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ANNOUNCEMENTS TAB (batch-scoped)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/announcements', auth, isAdmin, async (req, res) => {
  try {
    let Announcement;
    try { Announcement = mongoose.model('Announcement'); } catch (e) { Announcement = null; }
    if (!Announcement) return res.json({ announcements: [] });
    const list = await Announcement.find({ batchId: req.params.id }).sort({ createdAt: -1 }).lean();
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
      created = await Announcement.create({ title, message, batchId: req.params.id, urgent: !!urgent, scheduledAt: scheduledAt ? new Date(scheduledAt) : null, createdBy: req.user.id });
    }
    const batch = await Batch.findById(req.params.id);
    if (batch && StudentNotification) {
      const notifs = (batch.students || []).map(sid => ({
        userId: sid, type: 'announcement', title: title || '📢 Batch Update', message,
        batchId: batch._id, isRead: false, link: '/dashboard/announcements'
      }));
      if (notifs.length) await StudentNotification.insertMany(notifs);
    }
    await logAudit({ batchId: req.params.id, field: 'announcements', action: 'announcement_sent', newValue: { title }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, announcement: created, notified: (batch?.students || []).length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SETTINGS TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/settings', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.json({
      settings: {
        name: batch.name, batchCode: batch.batchCode, colorIcon: batch.colorIcon,
        startDate: batch.startDate, endDate: batch.endDate, visibility: batch.visibility,
        seatLimit: batch.seatLimit, enrollmentRule: batch.enrollmentRule,
        autoArchiveAfterEnd: !!batch.autoArchiveAfterEnd, teacherAssigned: batch.teacherAssigned,
        renameHistory: batch.renameHistory || [], isLocked: !!batch.settingsLocked
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/settings/lock', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.settingsLocked = !batch.settingsLocked;
    await batch.save();
    res.json({ success: true, isLocked: batch.settingsLocked });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// AUDIT HISTORY TAB
// ══════════════════════════════════════════════════════════════════
router.get('/:id/audit', auth, isAdmin, async (req, res) => {
  try {
    if (!BatchAuditLog) return res.json({ audit: [] });
    const audit = await BatchAuditLog.find({ batchId: req.params.id }).sort({ timestamp: -1 }).limit(200).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SNAPSHOT EXPORT
// ══════════════════════════════════════════════════════════════════
router.get('/:id/export-snapshot', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="batch-${batch.batchCode || batch._id}-snapshot.json"`);
    res.send(JSON.stringify(batch, null, 2));
  } catch (e) { res.status(500).json({ error: e.message }); }
});


module.exports = router;
