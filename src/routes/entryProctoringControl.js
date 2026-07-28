// ══════════════════════════════════════════════════════════════════
// F53–57-B — Entry & Proctoring Control Center
// Admin router mounted at:   /api/admin/entry-proctoring
// Student router mounted at: /api/entry-proctoring
//
// Design note (Rule H1 — don't break working features):
// This module is the NEW centralised admin CONFIGURATION layer for
// waiting room / instructions / T&C / webcam / fullscreen / join rules.
// It does NOT replace the existing runtime routes (examFlow.js,
// exam_patch.js) which students' attempt-flow pages already call.
// On PUBLISH, this module syncs only the 4 fields those existing
// routes already read (waitingRoomEnabled, waitingRoomMinutes,
// waitingChatMinutes, waitingAutoCloseBufferMinutes) so waiting-room
// timing actually changes for students immediately — safe, additive,
// nothing removed. All the richer config (instructions text, T&C,
// webcam/fullscreen granular rules, join rules) is fully built and
// exposed via GET /api/entry-proctoring/effective/:examId, ready to
// wire into your attempt-flow pages whenever you touch them next.
// ══════════════════════════════════════════════════════════════════
const express = require('express');
const adminRouter = express.Router();
const studentRouter = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isAdmin } = require('../middleware/auth');

const EntryProctoringPolicy = require('../models/EntryProctoringPolicy');
const EntryPolicyTemplate = require('../models/EntryPolicyTemplate');
const EntryControlLog = require('../models/EntryControlLog');
const Exam = require('../models/Exam');
let Announcement; try { Announcement = require('../models/Announcement'); } catch (e) { Announcement = null; }
let Batch; try { Batch = require('../models/Batch'); } catch (e) { Batch = null; }
let TestSeries; try { TestSeries = require('../models/TestSeries'); } catch (e) { TestSeries = null; }
let User; try { User = require('../models/User'); } catch (e) { User = null; }

const CONFIG_SECTIONS = ['waitingRoom', 'instructionsTrigger', 'permissionCheckTrigger', 'lateJoin',
  'waitingRoomLock', 'instructions', 'tnc', 'webcam', 'fullscreen', 'joinRules'];

// ──────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────
function toId(v) { try { return new mongoose.Types.ObjectId(v); } catch (e) { return null; } }

async function logActivitySafe(req, action, details) {
  try {
    const { logActivity } = require('../utils/activityLogger');
    await logActivity({ userId: req.user.id, userRole: req.user.role, action, details, module: 'entry_proctoring', status: 'success' });
  } catch (e) { /* non-fatal — activity logger is best-effort */ }
}

function resolvedWaitingMinutes(wr) {
  if (!wr) return 20;
  return wr.triggerMode === 'custom' ? (wr.customMinutes || 20) : (wr.presetMinutes || 20);
}
function resolvedInstructionsMinutes(it) {
  if (!it) return 5;
  return it.triggerMode === 'custom' ? (it.customMinutesBeforeExam || 5) : (it.presetMinutesBeforeExam || 5);
}

// Sync only the 4 fields the existing runtime (examFlow.js) reads — safe & additive.
async function syncToExam(policy) {
  if (!policy || !policy.scope || policy.scope.type !== 'exam' || !policy.scope.examId) return;
  const waitMins = resolvedWaitingMinutes(policy.waitingRoom);
  const chatMins = Math.max(0, (policy.waitingRoom?.chatStartOffsetMin || 20) - (policy.waitingRoom?.chatEndOffsetMin || 10));
  const bufferMins = resolvedInstructionsMinutes(policy.instructionsTrigger);
  try {
    await Exam.findByIdAndUpdate(policy.scope.examId, {
      waitingRoomEnabled: !!policy.waitingRoom?.enabled,
      waitingRoomMinutes: waitMins,
      waitingChatMinutes: chatMins || 10,
      waitingAutoCloseBufferMinutes: bufferMins
    });
  } catch (e) { /* non-fatal — policy still saved even if exam sync fails */ }
}

function computeReadiness(policy) {
  const warnings = [];
  let score = 0;
  const checks = [
    { ok: (policy.instructions?.points || []).length > 0, weight: 15, warn: 'No instruction points added yet' },
    { ok: !!policy.instructions?.published, weight: 10, warn: 'Instructions not published' },
    { ok: !!(policy.tnc?.text && policy.tnc.text.trim().length > 20), weight: 15, warn: 'T&C text is missing or too short' },
    { ok: !!policy.tnc?.published, weight: 10, warn: 'T&C not published' },
    { ok: typeof policy.waitingRoom?.enabled === 'boolean', weight: 10, warn: 'Waiting room not configured' },
    { ok: policy.webcam?.mandatory !== undefined, weight: 10, warn: 'Webcam policy not configured' },
    { ok: policy.fullscreen?.enabled !== undefined, weight: 10, warn: 'Fullscreen policy not configured' },
    { ok: (policy.joinRules?.joinGraceMinutes || 0) >= 0, weight: 10, warn: 'Join rules not configured' },
    { ok: policy.status === 'published', weight: 10, warn: 'Policy still in draft' }
  ];
  checks.forEach(c => { if (c.ok) score += c.weight; else warnings.push(c.warn); });
  return { readinessScore: score, warnings };
}

function diffSections(oldDoc, newDoc) {
  const diffs = [];
  CONFIG_SECTIONS.forEach(sec => {
    const a = JSON.stringify((oldDoc && oldDoc[sec]) || {});
    const b = JSON.stringify((newDoc && newDoc[sec]) || {});
    if (a !== b) diffs.push({ section: sec, oldValue: (oldDoc && oldDoc[sec]) || {}, newValue: (newDoc && newDoc[sec]) || {} });
  });
  return diffs;
}

async function findApplicablePolicy(examId) {
  const exam = await Exam.findById(examId).lean();
  if (!exam) return { exam: null, policy: null };

  let policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'exam', 'scope.examId': examId }).sort({ version: -1 }).lean();
  if (policy) return { exam, policy, resolvedFrom: 'exam' };

  const batchTargets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean);
  if (batchTargets.length) {
    policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'batch', 'scope.batchId': { $in: batchTargets.map(toId).filter(Boolean) } }).sort({ version: -1 }).lean();
    if (policy) return { exam, policy, resolvedFrom: 'batch' };
  }
  if (exam.testSeriesId) {
    policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'series', 'scope.testSeriesId': exam.testSeriesId }).sort({ version: -1 }).lean();
    if (policy) return { exam, policy, resolvedFrom: 'series' };
  }
  policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'global' }).sort({ version: -1 }).lean();
  if (policy) return { exam, policy, resolvedFrom: 'global' };

  return { exam, policy: null, resolvedFrom: 'defaults' };
}

// Opportunistic scheduled-publish promoter (16.5) — runs on KPI/list fetch, no cron needed
async function promoteScheduledPolicies() {
  try {
    const due = await EntryProctoringPolicy.find({ status: 'draft', scheduledPublishAt: { $lte: new Date(), $ne: null } });
    for (const p of due) {
      p.status = 'published';
      p.publishedAt = new Date();
      p.version = (p.version || 1) + (p.draftChangesPending ? 1 : 0);
      p.draftChangesPending = false;
      p.scheduledPublishAt = null;
      await p.save();
      await syncToExam(p);
    }
  } catch (e) { /* non-fatal */ }
}

// Simulate the 5.5.1.6 auto-transition flow for the Live Preview / Simulator
function simulateFlow(policy, minutesBeforeStart) {
  const m = minutesBeforeStart;
  const waitOpen = resolvedWaitingMinutes(policy.waitingRoom);
  const chatStart = policy.waitingRoom?.chatStartOffsetMin ?? 20;
  const chatEnd = policy.waitingRoom?.chatEndOffsetMin ?? 10;
  const instrOpen = resolvedInstructionsMinutes(policy.instructionsTrigger);
  const webcamAt = policy.permissionCheckTrigger?.webcamCheckOffsetMin ?? 5;
  const fsAt = policy.permissionCheckTrigger?.fullscreenCheckOffsetMin ?? 2;

  const stepState = (opensAtMin, closesAtMin) => {
    if (!policy) return 'pending';
    if (closesAtMin !== undefined && m < closesAtMin) return 'done';
    if (m <= opensAtMin && (closesAtMin === undefined || m >= closesAtMin)) return 'active';
    return 'pending';
  };

  return [
    { step: 'waiting_room', label: 'Waiting Room', state: policy.waitingRoom?.enabled ? stepState(waitOpen, chatStart) : 'skipped' },
    { step: 'chat', label: 'Chat Phase', state: policy.waitingRoom?.chatEnabled ? stepState(chatStart, chatEnd) : 'skipped' },
    { step: 'instructions', label: 'Instructions', state: policy.instructionsTrigger?.autoOpen ? stepState(instrOpen, webcamAt) : 'skipped' },
    { step: 'tnc', label: 'T&C', state: stepState(instrOpen, webcamAt) },
    { step: 'permission_check', label: 'Permission Check (Webcam/Fullscreen)', state: stepState(webcamAt, fsAt) },
    { step: 'ready', label: 'Ready Screen', state: stepState(fsAt, 0) },
    { step: 'exam_start', label: 'Exam Starts', state: m <= 0 ? 'active' : 'pending' }
  ];
}

// ══════════════════════════════════════════════════════════════════
// ADMIN ROUTES — /api/admin/entry-proctoring
// ══════════════════════════════════════════════════════════════════

// 2) TOP KPI CARDS
adminRouter.get('/kpis', verifyToken, isAdmin, async (req, res) => {
  try {
    await promoteScheduledPolicies();
    const [activePolicies, waitingRoomEnabled, instructionsPublished, tncActive, webcamMandatory,
      fullscreenEnabled, liveJoinBlocks, policyChangesToday] = await Promise.all([
      EntryProctoringPolicy.countDocuments({ status: 'published' }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'waitingRoom.enabled': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'instructions.published': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'tnc.published': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'webcam.mandatory': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'fullscreen.enabled': true }),
      EntryControlLog.countDocuments({ eventType: 'join_blocked', createdAt: { $gte: new Date(Date.now() - 7 * 86400000) } }),
      EntryProctoringPolicy.countDocuments({ updatedAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) } })
    ]);
    res.json({
      kpis: {
        activeExamPolicies: activePolicies,
        waitingRoomEnabled, instructionsPublished, tncActiveVersions: tncActive,
        webcamMandatoryExams: webcamMandatory, fullscreenEnabledExams: fullscreenEnabled,
        liveJoinBlocks7d: liveJoinBlocks, policyChangesToday
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 3) OVERVIEW
adminRouter.get('/overview/:policyId', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.policyId).populate('publishedBy', 'name').lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const { readinessScore, warnings } = computeReadiness(policy);
    res.json({
      overview: {
        scope: policy.scope, status: policy.status, readinessScore, warnings,
        lastPublishedAt: policy.publishedAt, lastEditedBy: policy.updatedBy,
        liveEnforcement: policy.status === 'published' && !policy.draftChangesPending,
        policySummary: {
          waitingRoom: !!policy.waitingRoom?.enabled, instructions: !!policy.instructions?.published,
          tnc: !!policy.tnc?.published, webcam: !!policy.webcam?.mandatory, fullscreen: !!policy.fullscreen?.enabled
        }
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 4) POLICIES — list / CRUD
adminRouter.get('/policies', verifyToken, isAdmin, async (req, res) => {
  try {
    await promoteScheduledPolicies();
    const { scopeType, examId, batchId, testSeriesId, status, search } = req.query;
    const filter = {};
    if (scopeType) filter['scope.type'] = scopeType;
    if (examId) filter['scope.examId'] = toId(examId);
    if (batchId) filter['scope.batchId'] = toId(batchId);
    if (testSeriesId) filter['scope.testSeriesId'] = toId(testSeriesId);
    if (status) filter.status = status;
    if (search) filter.name = { $regex: search, $options: 'i' };
    const list = await EntryProctoringPolicy.find(filter).sort({ updatedAt: -1 }).limit(200).lean();
    const out = list.map(p => ({ ...p, ...computeReadiness(p) }));
    res.json({ policies: out, total: out.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    res.json({ policy: { ...policy, ...computeReadiness(policy) } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, scope } = req.body;
    if (!scope || !scope.type) return res.status(400).json({ error: 'scope.type is required' });
    if (scope.type === 'exam' && scope.examId) {
      const existing = await EntryProctoringPolicy.findOne({ 'scope.type': 'exam', 'scope.examId': scope.examId, status: { $ne: 'archived' } });
      if (existing) return res.status(409).json({ error: 'A policy already exists for this exam. Edit it instead of creating a new one.', existingId: existing._id });
    }
    const policy = await EntryProctoringPolicy.create({
      name: name || 'Untitled Policy', scope, status: 'draft', version: 1,
      createdBy: req.user.id, updatedBy: req.user.id
    });
    await logActivitySafe(req, 'ENTRY_POLICY_CREATE', `Created policy "${policy.name}" (scope: ${scope.type})`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.put('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked — unlock it before editing' });

    const before = policy.toObject();
    const { name, reason } = req.body;
    if (name !== undefined) policy.name = name;

    CONFIG_SECTIONS.forEach(sec => {
      if (req.body[sec] !== undefined && typeof req.body[sec] === 'object') {
        policy[sec] = { ...(policy[sec] ? policy[sec].toObject ? policy[sec].toObject() : policy[sec] : {}), ...req.body[sec] };
      }
    });

    const diffs = diffSections(before, policy.toObject());
    diffs.forEach(d => {
      policy.history.push({
        version: policy.version, section: d.section, oldValue: d.oldValue, newValue: d.newValue,
        reason: reason || '', changedBy: req.user.id, changedByName: req.user.name || '', changedAt: new Date()
      });
    });

    if (policy.status === 'published' && diffs.length) policy.draftChangesPending = true;
    policy.updatedBy = req.user.id;
    await policy.save();
    await logActivitySafe(req, 'ENTRY_POLICY_UPDATE', `Updated policy "${policy.name}" — ${diffs.map(d => d.section).join(', ') || 'no field changes'}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/clone', verifyToken, isAdmin, async (req, res) => {
  try {
    const src = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Policy not found' });
    delete src._id; delete src.createdAt; delete src.updatedAt; delete src.history;
    const clone = await EntryProctoringPolicy.create({
      ...src, name: `${src.name} (Copy)`, status: 'draft', version: 1, locked: false,
      publishedAt: null, publishedBy: null, draftChangesPending: false, history: [],
      createdBy: req.user.id, updatedBy: req.user.id
    });
    await logActivitySafe(req, 'ENTRY_POLICY_CLONE', `Cloned policy "${src.name}" → "${clone.name}"`);
    res.json({ success: true, policy: clone });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.delete('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.status === 'published') return res.status(400).json({ error: 'Unpublish before deleting a published policy' });
    await EntryProctoringPolicy.findByIdAndDelete(req.params.id);
    await logActivitySafe(req, 'ENTRY_POLICY_DELETE', `Deleted draft policy "${policy.name}"`);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 4.4 Publish (snapshot + lock rules)
adminRouter.post('/policies/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked' });

    policy.version = (policy.version || 1) + (policy.status === 'published' ? 1 : 0);
    policy.status = 'published';
    policy.publishedAt = new Date();
    policy.publishedBy = req.user.id;
    policy.draftChangesPending = false;
    policy.history.push({
      version: policy.version, section: 'general', oldValue: null, newValue: { published: true },
      reason: req.body.reason || 'Published', changedBy: req.user.id, changedByName: req.user.name || '',
      changedAt: new Date(), snapshot: policy.toObject()
    });
    await policy.save();
    await syncToExam(policy);
    await logActivitySafe(req, 'ENTRY_POLICY_PUBLISH', `Published policy "${policy.name}" v${policy.version}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/lock', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findByIdAndUpdate(req.params.id, { locked: true, updatedBy: req.user.id }, { new: true });
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    await logActivitySafe(req, 'ENTRY_POLICY_LOCK', `Locked policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/unlock', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findByIdAndUpdate(req.params.id, { locked: false, updatedBy: req.user.id }, { new: true });
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    await logActivitySafe(req, 'ENTRY_POLICY_UNLOCK', `Unlocked policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/policies/:id/readiness', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    res.json(computeReadiness(policy));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 14) Audit & Version History
adminRouter.get('/policies/:id/history', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).select('history name version').lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const history = (policy.history || []).slice().sort((a, b) => new Date(b.changedAt) - new Date(a.changedAt));
    res.json({ history, currentVersion: policy.version });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.2 Policy Diff Viewer — compare two logged versions (by history index) or draft vs published
adminRouter.get('/policies/:id/diff', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const { v1, v2 } = req.query;
    const snapA = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(v1));
    const snapB = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(v2));
    const oldDoc = snapA ? snapA.snapshot : {};
    const newDoc = snapB ? snapB.snapshot : policy;
    res.json({ diff: diffSections(oldDoc, newDoc) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/rollback/:version', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const entry = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(req.params.version));
    if (!entry) return res.status(404).json({ error: 'No snapshot found for that version' });
    const snap = entry.snapshot;
    CONFIG_SECTIONS.forEach(sec => { if (snap[sec] !== undefined) policy[sec] = snap[sec]; });
    policy.version = (policy.version || 1) + 1;
    policy.draftChangesPending = policy.status === 'published';
    policy.updatedBy = req.user.id;
    policy.history.push({
      version: policy.version, section: 'general', oldValue: null, newValue: { rolledBackTo: req.params.version },
      reason: `Rollback to v${req.params.version}`, changedBy: req.user.id, changedByName: req.user.name || '', changedAt: new Date()
    });
    await policy.save();
    await logActivitySafe(req, 'ENTRY_POLICY_ROLLBACK', `Rolled back "${policy.name}" to v${req.params.version}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 13) Live Preview / Simulator
adminRouter.post('/policies/:id/preview', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const minutesBeforeStart = typeof req.body.minutesBeforeStart === 'number' ? req.body.minutesBeforeStart : resolvedWaitingMinutes(policy.waitingRoom);
    const flow = simulateFlow(policy, minutesBeforeStart);
    res.json({ flow, minutesBeforeStart });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.6 Batch / Test Series Mass Apply
adminRouter.post('/policies/:id/mass-apply', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examIds } = req.body;
    if (!Array.isArray(examIds) || !examIds.length) return res.status(400).json({ error: 'examIds array required' });
    const source = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!source) return res.status(404).json({ error: 'Source policy not found' });

    const results = [];
    for (const examId of examIds) {
      try {
        const clean = { ...source };
        delete clean._id; delete clean.createdAt; delete clean.updatedAt; delete clean.history;
        let target = await EntryProctoringPolicy.findOne({ 'scope.type': 'exam', 'scope.examId': examId, status: { $ne: 'archived' } });
        if (target) {
          CONFIG_SECTIONS.forEach(sec => { target[sec] = clean[sec]; });
          target.massAppliedFrom = source._id;
          target.status = 'published';
          target.publishedAt = new Date();
          target.publishedBy = req.user.id;
          target.version = (target.version || 1) + 1;
          await target.save();
        } else {
          target = await EntryProctoringPolicy.create({
            ...clean, name: `${source.name} (Mass Applied)`, scope: { type: 'exam', examId },
            status: 'published', version: 1, publishedAt: new Date(), publishedBy: req.user.id,
            massAppliedFrom: source._id, createdBy: req.user.id, updatedBy: req.user.id
          });
        }
        await syncToExam(target);
        results.push({ examId, success: true, policyId: target._id });
      } catch (innerErr) { results.push({ examId, success: false, error: innerErr.message }); }
    }
    await logActivitySafe(req, 'ENTRY_POLICY_MASS_APPLY', `Mass-applied "${source.name}" to ${examIds.length} exam(s)`);
    res.json({ success: true, results });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.4 Emergency Override + 5.5.1.9 Admin Override
adminRouter.post('/policies/:id/emergency-override', verifyToken, isAdmin, async (req, res) => {
  try {
    const { action } = req.body; // open_waiting_room_now | close_waiting_room | skip_to_instructions | skip_to_permission_check | force_exam_start
    const validActions = ['open_waiting_room_now', 'close_waiting_room', 'skip_to_instructions', 'skip_to_permission_check', 'force_exam_start'];
    if (!validActions.includes(action)) return res.status(400).json({ error: 'Invalid override action' });
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const examId = policy.scope && policy.scope.examId;

    let socketEmitted = false;
    if (examId) {
      try {
        const { getIO } = require('../config/socket');
        getIO().to(`waiting-${examId}`).emit('entry-override', { examId: String(examId), action, at: new Date() });
        socketEmitted = true;
      } catch (e) { /* socket not initialized — non-fatal */ }
    }
    await logActivitySafe(req, 'ENTRY_POLICY_EMERGENCY_OVERRIDE', `Emergency override "${action}" on policy "${policy.name}"${examId ? ' (exam ' + examId + ')' : ''}`);
    res.json({ success: true, action, examId, socketEmitted });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 12) POLICY TEMPLATES
// ══════════════════════════════════════════════════════════════════
const BUILTIN_TEMPLATES = [
  { name: 'Standard Exam', kind: 'standard_exam', icon: '📋', description: 'Balanced defaults — waiting room, webcam mandatory, standard fullscreen.' },
  { name: 'Strict Proctoring', kind: 'strict_proctoring', icon: '🔒', description: 'Maximum enforcement — webcam + fullscreen strict, no late join, no rejoin.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: false }, fullscreen: { warningThreshold: 1 }, lateJoin: { allowLateJoin: false, allowRejoin: false } } },
  { name: 'Relaxed Entry', kind: 'relaxed_entry', icon: '🕊️', description: 'Lenient entry — generous grace period, rejoin allowed, optional webcam.', overrides: { webcam: { mandatory: false, blockOnDenial: false }, lateJoin: { graceMinutes: 15, allowRejoin: true, rejoinWindowMinutes: 20 } } },
  { name: 'Webcam Mandatory', kind: 'webcam_mandatory', icon: '📷', description: 'Webcam strictly required, all other rules standard.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: true, retryCount: 2 } } },
  { name: 'Full Lockdown', kind: 'full_lockdown', icon: '🛡️', description: 'Every control at maximum — webcam, fullscreen, no late join/rejoin, waiting room locked.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: false }, fullscreen: { warningThreshold: 1, gracePeriodSec: 0 }, lateJoin: { allowLateJoin: false, allowRejoin: false }, waitingRoomLock: { lockWaitingRoom: true, forceStudentToStay: true, disableNavigation: true } } }
];

async function seedBuiltinTemplates() {
  for (const t of BUILTIN_TEMPLATES) {
    const exists = await EntryPolicyTemplate.findOne({ kind: t.kind, isBuiltIn: true });
    if (!exists) {
      const base = new EntryProctoringPolicy();
      const settings = {};
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = { ...(base[sec] ? base[sec].toObject ? base[sec].toObject() : base[sec] : {}), ...((t.overrides || {})[sec] || {}) }; });
      await EntryPolicyTemplate.create({ name: t.name, kind: t.kind, icon: t.icon, description: t.description, settings, isBuiltIn: true });
    }
  }
}

adminRouter.get('/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    await seedBuiltinTemplates().catch(() => {});
    const templates = await EntryPolicyTemplate.find({}).sort({ isPinned: -1, isBuiltIn: -1, usageCount: -1 }).lean();
    res.json({ templates });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, sourcePolicyId, description } = req.body;
    if (!name) return res.status(400).json({ error: 'name required' });
    let settings = {};
    if (sourcePolicyId) {
      const src = await EntryProctoringPolicy.findById(sourcePolicyId).lean();
      if (!src) return res.status(404).json({ error: 'Source policy not found' });
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = src[sec] || {}; });
    }
    const template = await EntryPolicyTemplate.create({ name, description: description || '', settings, createdBy: req.user.id, updatedBy: req.user.id });
    await logActivitySafe(req, 'ENTRY_TEMPLATE_CREATE', `Created entry-policy template "${name}"`);
    res.json({ success: true, template });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates/:id/apply/:policyId', verifyToken, isAdmin, async (req, res) => {
  try {
    const template = await EntryPolicyTemplate.findById(req.params.id).lean();
    if (!template) return res.status(404).json({ error: 'Template not found' });
    const policy = await EntryProctoringPolicy.findById(req.params.policyId);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked' });
    CONFIG_SECTIONS.forEach(sec => { if (template.settings[sec]) policy[sec] = template.settings[sec]; });
    policy.templateSource = template._id;
    policy.draftChangesPending = policy.status === 'published';
    policy.updatedBy = req.user.id;
    await policy.save();
    await EntryPolicyTemplate.findByIdAndUpdate(req.params.id, { $inc: { usageCount: 1 }, lastUsedAt: new Date() });
    await logActivitySafe(req, 'ENTRY_TEMPLATE_APPLY', `Applied template "${template.name}" to policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates/:id/duplicate', verifyToken, isAdmin, async (req, res) => {
  try {
    const src = await EntryPolicyTemplate.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Template not found' });
    delete src._id; delete src.createdAt; delete src.updatedAt;
    const dup = await EntryPolicyTemplate.create({ ...src, name: `${src.name} (Copy)`, isBuiltIn: false, usageCount: 0, createdBy: req.user.id });
    res.json({ success: true, template: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.put('/templates/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const allowed = ['name', 'description', 'isPinned'];
    const update = { updatedBy: req.user.id };
    allowed.forEach(k => { if (req.body[k] !== undefined) update[k] = req.body[k]; });
    const template = await EntryPolicyTemplate.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!template) return res.status(404).json({ error: 'Template not found' });
    res.json({ success: true, template });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.delete('/templates/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const template = await EntryPolicyTemplate.findById(req.params.id);
    if (!template) return res.status(404).json({ error: 'Template not found' });
    if (template.isBuiltIn) return res.status(400).json({ error: 'Built-in templates cannot be deleted' });
    await EntryPolicyTemplate.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/templates/compare', verifyToken, isAdmin, async (req, res) => {
  try {
    const { a, b } = req.query;
    if (!a || !b) return res.status(400).json({ error: 'a and b template ids required' });
    const [ta, tb] = await Promise.all([EntryPolicyTemplate.findById(a).lean(), EntryPolicyTemplate.findById(b).lean()]);
    if (!ta || !tb) return res.status(404).json({ error: 'One or both templates not found' });
    res.json({ diff: diffSections(ta.settings, tb.settings) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 11) BROADCASTS & NOTIFICATIONS (entry-stage, uses Announcement model)
// ══════════════════════════════════════════════════════════════════
adminRouter.get('/policies/:id/broadcasts', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.json({ broadcasts: [] });
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy || !policy.scope || !policy.scope.examId) return res.json({ broadcasts: [] });
    const broadcasts = await Announcement.find({ examId: policy.scope.examId, 'entryContext.isEntryBroadcast': true }).sort({ createdAt: -1 }).limit(50).lean();
    res.json({ broadcasts });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/broadcasts', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.status(501).json({ error: 'Announcement model unavailable' });
    const { examId, batchId, broadcastType, title, message, channel, scheduledAt } = req.body;
    if (!title || !message) return res.status(400).json({ error: 'title and message required' });
    const validTypes = ['waiting_room_announcement', 'instruction_update', 'consent_reminder', 'camera_reminder', 'fullscreen_reminder', 'join_window_warning', 'emergency_notice'];
    if (!validTypes.includes(broadcastType)) return res.status(400).json({ error: 'Invalid broadcastType' });

    let audience = { mode: 'all' };
    if (batchId) audience = { mode: 'batch', batchIds: [batchId] };

    const status = scheduledAt && new Date(scheduledAt) > new Date() ? 'scheduled' : 'sent';
    const doc = await Announcement.create({
      title, message, type: 'exam', audience, sendVia: channel === 'email' ? 'both' : 'in-app',
      status, scheduledAt: status === 'scheduled' ? new Date(scheduledAt) : null,
      examId: examId || null, entryContext: { isEntryBroadcast: true, broadcastType, channel: channel || 'in-app' },
      createdBy: req.user.id
    });

    if (examId) {
      try {
        const { getIO } = require('../config/socket');
        getIO().to(`waiting-${examId}`).emit('waiting-broadcast', { title, message, broadcastType, at: new Date() });
      } catch (e) { /* socket not initialized — non-fatal */ }
    }
    await logActivitySafe(req, 'ENTRY_BROADCAST_SEND', `Sent entry broadcast "${title}" (${broadcastType})`);
    res.json({ success: true, broadcast: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/broadcasts/:id/cancel', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.status(501).json({ error: 'Announcement model unavailable' });
    const doc = await Announcement.findOneAndUpdate({ _id: req.params.id, status: 'scheduled' }, { status: 'draft', scheduledAt: null }, { new: true });
    if (!doc) return res.status(404).json({ error: 'Scheduled broadcast not found' });
    res.json({ success: true, broadcast: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 15) CONTROL LOGS + 16.8/16.9/16.10 ANALYTICS
// ══════════════════════════════════════════════════════════════════
adminRouter.get('/control-logs', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId, eventType, severity, dateFrom, dateTo, page = 1, limit = 50 } = req.query;
    const filter = {};
    if (examId) filter.examId = toId(examId);
    if (eventType) filter.eventType = eventType;
    if (severity) filter.severity = severity;
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo + 'T23:59:59');
    }
    const skip = (Math.max(1, Number(page)) - 1) * Number(limit);
    const [logs, total] = await Promise.all([
      EntryControlLog.find(filter).sort({ createdAt: -1 }).skip(skip).limit(Number(limit)).populate('studentId', 'name email').lean(),
      EntryControlLog.countDocuments(filter)
    ]);
    res.json({ logs, total, page: Number(page), limit: Number(limit) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.8 Student Flow Heatmap — counts per step (where students are / drop off)
adminRouter.get('/analytics/flow-heatmap', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const agg = await EntryControlLog.aggregate([
      { $match: { ...match, eventType: { $in: ['step_reached', 'step_failed'] } } },
      { $group: { _id: { step: '$step', eventType: '$eventType' }, count: { $sum: 1 } } }
    ]);
    res.json({ heatmap: agg.map(a => ({ step: a._id.step, eventType: a._id.eventType, count: a.count })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.9 Join Attempt Analytics
adminRouter.get('/analytics/join-attempts', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const [lateJoins, blocked, retries, rejoins] = await Promise.all([
      EntryControlLog.countDocuments({ ...match, eventType: 'late_join_attempt' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'join_blocked' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'retry_attempt' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'rejoin_attempt' })
    ]);
    res.json({ lateJoinAttempts: lateJoins, blockedAttempts: blocked, retryAttempts: retries, rejoinAttempts: rejoins });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.10 Failure Reason Summary
adminRouter.get('/analytics/failure-summary', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const agg = await EntryControlLog.aggregate([
      { $match: { ...match, status: { $in: ['failed', 'blocked'] } } },
      { $group: { _id: '$eventType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    res.json({ summary: agg.map(a => ({ reason: a._id, count: a.count })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// STUDENT ROUTES — /api/entry-proctoring
// ══════════════════════════════════════════════════════════════════

// Effective (resolved) policy for a given exam — exam → batch → series → global → schema defaults
studentRouter.get('/effective/:examId', verifyToken, async (req, res) => {
  try {
    const { exam, policy, resolvedFrom } = await findApplicablePolicy(req.params.examId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    if (!policy) {
      const def = new EntryProctoringPolicy();
      const settings = {};
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = def[sec] && def[sec].toObject ? def[sec].toObject() : def[sec]; });
      return res.json({ resolvedFrom: 'defaults', settings });
    }
    const settings = {};
    CONFIG_SECTIONS.forEach(sec => { settings[sec] = policy[sec] || {}; });
    res.json({ resolvedFrom, policyId: policy._id, settings });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Student-side event logger (feeds Control Logs + analytics)
studentRouter.post('/log-event', verifyToken, async (req, res) => {
  try {
    const { examId, eventType, step, severity, status, details, meta } = req.body;
    if (!examId || !eventType) return res.status(400).json({ error: 'examId and eventType required' });
    const log = await EntryControlLog.create({
      examId, studentId: req.user.id, eventType, step: step || '', severity: severity || 'info',
      status: status || 'success', details: details || '', meta: meta || {}
    });
    res.json({ success: true, logId: log._id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = { adminEntryProctoringRoutes: adminRouter, studentEntryProctoringRoutes: studentRouter };

