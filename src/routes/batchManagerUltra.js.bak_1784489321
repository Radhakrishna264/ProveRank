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
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  if (b.limitedTimePrice) return b.limitedTimePrice;
  if (b.earlyBirdPrice) return b.earlyBirdPrice;
  return b.discountPrice || b.price || 0;
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
          examType: doc.examType, price: doc.price, status: 'draft',
          syncState: 'synced', published: false
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
    const meta = batch.examMeta || [];
    assigned = assigned.map(e => ({ ...e, control: meta.find(m => String(m.examId) === String(e._id)) || {} }));
    res.json({ assigned, available, examCount: assigned.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/exams/assign', auth, isAdmin, async (req, res) => {
  try {
    const { examId, required, locked, featured, hidden, priority } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = batch.exams || [];
    if (!batch.exams.some(e => String(e) === String(examId))) batch.exams.push(examId);
    batch.examMeta = batch.examMeta || [];
    batch.examMeta = batch.examMeta.filter(m => String(m.examId) !== String(examId));
    batch.examMeta.push({ examId, required: !!required, locked: !!locked, featured: !!featured, hidden: !!hidden, priority: Number(priority) || 0 });
    batch.lastActivityAt = new Date();
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_assigned', newValue: { examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const { required, locked, featured, hidden, priority } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.examMeta = batch.examMeta || [];
    let m = batch.examMeta.find(x => String(x.examId) === String(req.params.examId));
    if (!m) { m = { examId: req.params.examId }; batch.examMeta.push(m); }
    if (required !== undefined) m.required = !!required;
    if (locked !== undefined) m.locked = !!locked;
    if (featured !== undefined) m.featured = !!featured;
    if (hidden !== undefined) m.hidden = !!hidden;
    if (priority !== undefined) m.priority = Number(priority);
    await batch.save();
    res.json({ success: true, meta: m });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    batch.examMeta = (batch.examMeta || []).filter(m => String(m.examId) !== String(req.params.examId));
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
        bundlePrice: batch.bundlePrice || null,
        earlyBirdPrice: batch.earlyBirdPrice || null,
        limitedTimePrice: batch.limitedTimePrice || null,
        flashSalePrice: batch.flashSalePrice || null,
        flashSaleEndTime: batch.flashSaleEndTime || null,
        couponCode: batch.couponCode || '',
        allowFreeTrial: !!batch.allowFreeTrial,
        trialDays: batch.trialDays || 0,
        priceLocked: !!batch.priceLocked,
        effectivePrice: effectivePrice(batch)
      },
      history: batch.priceHistory || [],
      forecast: {
        expectedIncome: effectivePrice(batch) * Math.max(studentCount, 1) * 1.15,
        conversionEstimate: Math.min(95, 20 + studentCount * 2),
        offerPerformance: (batch.isSpotlight || batch.isBundle || batch.allowFreeTrial) ? 'High' : 'Moderate'
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
    const fields = ['price', 'discountPrice', 'bundlePrice', 'earlyBirdPrice', 'limitedTimePrice', 'couponCode', 'allowFreeTrial', 'trialDays'];
    batch.priceHistory = batch.priceHistory || [];
    for (const f of fields) {
      if (req.body[f] !== undefined && String(batch[f]) !== String(req.body[f])) {
        batch.priceHistory.push({ oldPrice: batch[f], newPrice: req.body[f], field: f, updatedBy: req.user.id, updatedByName: req.user.name || 'Admin', updatedAt: new Date() });
        batch[f] = req.body[f];
      }
    }
    if (req.body.flashSalePrice !== undefined) {
      batch.flashSalePrice = req.body.flashSalePrice;
      batch.flashSaleEndTime = req.body.flashSaleEndTime ? new Date(req.body.flashSaleEndTime) : batch.flashSaleEndTime;
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

// ══════════════════════════════════════════════════════════════════
// FPR3 — BANNER PANEL (for Batch Detail page integration)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/banner-panel', auth, isAdmin, async (req, res) => {
  try {
    let Banner;
    try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id }).sort({ createdAt: -1 }).lean();
    const gate = await checkBannerGate(req.params.id);
    res.json({ banner: banner || null, gate });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner-panel/regenerate', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    let Banner;
    try { Banner = mongoose.model('Banner'); } catch (e) { Banner = require('../models/Banner'); }
    const draft = await Banner.create({
      title: batch.name, linkedBatchId: batch._id, linkedType: 'batch',
      examType: batch.examType, price: String(effectivePrice(batch) || ''), status: 'draft',
      syncState: 'synced', published: false, createdBy: req.user.id
    });
    res.json({ success: true, banner: draft });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
