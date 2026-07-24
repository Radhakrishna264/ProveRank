#!/bin/bash
set -e
echo "ProveRank -- Publish Center v2 Installer (Full Gap-Fix Upgrade)"
echo "Requires: publish_center_install_v1.sh already run once."
cd ~/workspace
STAGE=~/workspace/.proverank-publish-center-v2-stage
mkdir -p "$STAGE"

# 1) Batch.js model hooks (edit lock + draft-changes-pending)
cat > "$STAGE/batch_model_hooks.txt" << 'BATCHHOOKS_EOF'

// ── Publish Center v2: Edit Lock + Draft-Changes-Pending (auto, via pre-save hook) ──
const PUBLISH_CRITICAL_FIELDS = ['examType', 'price', 'discountPrice', 'startDate', 'endDate', 'validity'];
const PUBLISH_WATCHED_FIELDS = ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
  'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility', 'teacherAssigned',
  'isSpotlight', 'isBundle', 'allowFreeTrial'];
BatchSchema.pre('save', function (next) {
  const locked = (this.isPublished || this.publishState === 'scheduled') && !(this.$locals && this.$locals.allowCriticalEdit);
  if (locked) {
    const lockedField = PUBLISH_CRITICAL_FIELDS.find(f => this.isModified(f));
    if (lockedField) return next(new Error('EDIT_LOCKED: Cannot change "' + lockedField + '" while Batch is Published/Scheduled. Unpublish it or use Publish Center to make critical changes.'));
  }
  if (this.isPublished && !this.isNew && !this.isModified('draftChangesPending') && !this.isModified('publishState')) {
    if (PUBLISH_WATCHED_FIELDS.some(f => this.isModified(f))) {
      this.draftChangesPending = true;
      if (this.publishState === 'published') this.publishState = 'republish_pending';
    }
  }
  next();
});

BATCHHOOKS_EOF

# 2) TestSeries.js model hooks
cat > "$STAGE/testseries_model_hooks.txt" << 'SERIESHOOKS_EOF'

// ── Publish Center v2: Edit Lock + Draft-Changes-Pending (auto, via pre-save hook) ──
const PUBLISH_CRITICAL_FIELDS = ['examType', 'price', 'discountPrice', 'startDate', 'endDate', 'validity'];
const PUBLISH_WATCHED_FIELDS = ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
  'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility', 'teacherAssigned',
  'isSpotlight', 'isBundle', 'allowFreeTrial'];
TestSeriesSchema.pre('save', function (next) {
  const locked = (this.isPublished || this.publishState === 'scheduled') && !(this.$locals && this.$locals.allowCriticalEdit);
  if (locked) {
    const lockedField = PUBLISH_CRITICAL_FIELDS.find(f => this.isModified(f));
    if (lockedField) return next(new Error('EDIT_LOCKED: Cannot change "' + lockedField + '" while Batch is Published/Scheduled. Unpublish it or use Publish Center to make critical changes.'));
  }
  if (this.isPublished && !this.isNew && !this.isModified('draftChangesPending') && !this.isModified('publishState')) {
    if (PUBLISH_WATCHED_FIELDS.some(f => this.isModified(f))) {
      this.draftChangesPending = true;
      if (this.publishState === 'published') this.publishState = 'republish_pending';
    }
  }
  next();
});

SERIESHOOKS_EOF

# 3) Audit log reason/snapshotVersion fields
cat > "$STAGE/auditlog_fields.txt" << 'AUDITFIELDS_EOF'
,
  reason: { type: String, default: '' },
  snapshotVersion: { type: mongoose.Schema.Types.Mixed, default: null }

AUDITFIELDS_EOF

# 4) Batch Publish Center v2 backend routes
cat > "$STAGE/publish_center_batch_v2.js" << 'BATCHV2_EOF'

// ══════════════════════════════════════════════════════════════════
// 16) PUBLISH CENTER — Go-Live Control Center  [v2]
// ══════════════════════════════════════════════════════════════════
function scoreStatusLabel(score) {
  if (score >= 95) return 'Ready to Publish';
  if (score >= 80) return 'Almost Ready';
  if (score >= 50) return 'Partially Ready';
  return 'Not Ready';
}

const CRITICAL_FIELDS = ['examType', 'price', 'discountPrice', 'startDate', 'endDate', 'validity'];
const SNAPSHOT_FIELDS = ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
  'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility',
  'teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial', 'lifecycleStatus', 'status'];
const SECTION_MAP = { basicInfo: 'settings', banner: 'banner', pricing: 'pricing', dateRange: 'settings', startDate: 'settings', endDate: 'settings', controls: 'controls', coupons: 'coupons', scheduleConflict: 'publish' };

async function gatherSnapshotExtras(batch) {
  let bannerSnap = null, couponIds = [], materialsCount = 0, announcementsCount = 0;
  try {
    const Banner = mongoose.model('Banner');
    const b = await Banner.findOne({ linkedType: 'batch', linkedBatchId: batch._id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (b) bannerSnap = { id: b._id, title: b.title, tagline: b.tagline, status: b.status, primaryColor: b.primaryColor };
  } catch (e) {}
  try { couponIds = (await Coupon.find({ scopeType: 'batch', scopeId: batch._id, isDeleted: false }).select('_id code status').lean()).map(c => ({ id: c._id, code: c.code, status: c.status })); } catch (e) {}
  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: batch._id }); } catch (e) {}
  try { let A; try { A = mongoose.model('Announcement'); } catch (e) { A = null; } if (A) announcementsCount = await A.countDocuments({ batchId: batch._id }); } catch (e) {}
  return { banner: bannerSnap, coupons: couponIds, examsCount: (batch.exams && batch.exams.length) || 0, exams: (batch.exams || []).map(String), materialsCount, announcementsCount };
}

async function buildPublishChecklist(batch) {
  const studentCount = (batch.students && batch.students.length) || 0;
  const examCount = (batch.exams && batch.exams.length) || 0;
  const bannerGate = await checkBannerGate(batch._id);
  let materialsCount = 0;
  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: batch._id }); } catch (e) {}
  let announcementsCount = 0;
  try {
    let Announcement; try { Announcement = mongoose.model('Announcement'); } catch (e) { Announcement = null; }
    if (Announcement) announcementsCount = await Announcement.countDocuments({ batchId: batch._id });
  } catch (e) {}
  let coupons = [];
  try { coupons = await Coupon.find({ scopeType: 'batch', scopeId: batch._id, isDeleted: false }).lean(); } catch (e) {}
  const now = new Date();
  const expiredButActive = coupons.filter(c => c.status === 'active' && c.validTill && new Date(c.validTill) < now);
  const couponIssue = expiredButActive.length > 0 ? `${expiredButActive.length} active coupon(s) already expired` : '';

  const dateRangeOk = !(batch.startDate && batch.endDate) || (new Date(batch.endDate) > new Date(batch.startDate));
  let scheduleConflict = '';
  if (batch.scheduledPublishAt && batch.startDate && new Date(batch.scheduledPublishAt) > new Date(batch.startDate)) {
    scheduleConflict = 'Scheduled publish time is AFTER the batch Start Date — students will miss the start.';
  }
  let controlMismatch = '';
  if (batch.seatLimit > 0 && studentCount > batch.seatLimit) controlMismatch = `Enrolled students (${studentCount}) already exceed Seat Limit (${batch.seatLimit})`;

  const ignored = batch.publishIgnoredIssues || [];
  const mandatory = [
    { key: 'basicInfo', label: 'Basic Information complete', done: !!(batch.name && batch.description && batch.examType), reason: 'Name, description & exam type required', ignorable: false, section: 'settings' },
    { key: 'banner', label: 'Banner ready', done: !!bannerGate.ready, reason: bannerGate.reason || '', ignorable: false, section: 'banner' },
    { key: 'pricing', label: 'Pricing configured', done: !!(batch.isFree || (batch.price && batch.price > 0)), reason: 'Set a price or mark as Free', ignorable: false, section: 'pricing' },
    { key: 'startDate', label: 'Start Date set', done: !!batch.startDate, reason: 'Start Date missing in Settings', ignorable: false, section: 'settings' },
    { key: 'endDate', label: 'End Date / Validity set', done: !!(batch.endDate || (batch.validity && batch.validity > 0)), reason: 'End Date or Validity missing', ignorable: false, section: 'settings' },
    { key: 'dateRange', label: 'Date range valid (End after Start)', done: dateRangeOk, reason: dateRangeOk ? '' : 'End Date must be after Start Date', ignorable: false, section: 'settings' },
    { key: 'scheduleConflict', label: 'No publish-time conflict', done: !scheduleConflict, reason: scheduleConflict, ignorable: true, section: 'publish' },
    { key: 'controls', label: 'Controls configured (no mismatch)', done: !controlMismatch, reason: controlMismatch, ignorable: true, section: 'controls' },
    { key: 'coupons', label: 'Coupon configuration checked', done: coupons.length === 0 || expiredButActive.length === 0, reason: couponIssue, ignorable: true, section: 'coupons' }
  ].map(m => ({ ...m, done: m.done || (m.ignorable && ignored.includes(m.key)) }));
  const optional = [
    { key: 'exams', label: 'Exams added', done: examCount > 0, count: examCount },
    { key: 'materials', label: 'Materials added', done: materialsCount > 0, count: materialsCount },
    { key: 'announcements', label: 'Announcements prepared', done: announcementsCount > 0, count: announcementsCount },
    { key: 'faq', label: 'FAQ / Help content', done: true },
    { key: 'leaderboard', label: 'Leaderboard enabled', done: true },
    { key: 'analytics', label: 'Analytics enabled', done: true }
  ];

  const weights = { basicInfo: 12, banner: 18, pricing: 12, startDate: 6, endDate: 6, dateRange: 5, controls: 8, coupons: 5, scheduleConflict: 3 };
  let score = 0;
  mandatory.forEach(m => { if (m.done) score += (weights[m.key] || 0); });
  score += examCount > 0 ? 15 : 0;
  score += (batch.thumbnail || batch.colorIcon) ? 10 : 0;
  score = Math.max(0, Math.min(100, Math.round(score)));

  const blockingIssues = mandatory.filter(m => !m.done)
    .map(m => ({ key: m.key, message: m.reason || (m.label + ' missing'), ignorable: m.ignorable, section: SECTION_MAP[m.key] || 'overview' }));

  return { mandatory, optional, score, scoreStatus: scoreStatusLabel(score), blockingIssues, studentCount, examCount, bannerGate, ignored };
}

function syncEffectivePublishState(currentState, isPublished, blockingIssues, publishVersion) {
  if (currentState === 'scheduled' || isPublished) return currentState;
  const hasIssues = blockingIssues.some(b => !b.ignorable || true) && blockingIssues.length > 0;
  if (hasIssues) return publishVersion > 0 ? 'blocked' : 'draft';
  return 'ready';
}

function applyPublishState(batch, isPublished) {
  batch.status = isPublished ? 'active' : (batch.status === 'draft' ? 'draft' : 'inactive');
}

function pushPublishSnapshot(batch, { action, notes, reason, visibilityMode, publishedByName, extras }) {
  batch.publishSnapshots = batch.publishSnapshots || [];
  const version = batch.publishVersion || 0;
  batch.publishSnapshots.push({
    version,
    snapshotId: 'v' + version + '-' + Date.now(),
    publishedAt: new Date(),
    publishedBy: publishedByName || 'Admin',
    status: batch.publishState,
    action,
    notes: notes || '',
    reason: reason || '',
    visibilityMode: visibilityMode || batch.visibility || 'public',
    snapshotData: {
      ...Object.fromEntries(SNAPSHOT_FIELDS.map(f => [f, batch[f]])),
      banner: extras?.banner || null, coupons: extras?.coupons || [], exams: extras?.exams || [],
      examsCount: extras?.examsCount || 0, materialsCount: extras?.materialsCount || 0, announcementsCount: extras?.announcementsCount || 0
    }
  });
  if (batch.publishSnapshots.length > 40) batch.publishSnapshots = batch.publishSnapshots.slice(-40);
}

// GET /:id/publish-center — full readiness + status dashboard
router.get('/:id/publish-center', auth, isAdmin, async (req, res) => {
  try {
    let batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { mandatory, optional, score, scoreStatus, blockingIssues, examCount, bannerGate } = await buildPublishChecklist(batch);

    const nextState = syncEffectivePublishState(batch.publishState || 'draft', !!batch.isPublished, blockingIssues, batch.publishVersion || 0);
    if (nextState !== batch.publishState) {
      await Batch.updateOne({ _id: batch._id }, { $set: { publishState: nextState } });
      batch.publishState = nextState;
    }

    let couponsActive = false;
    try { couponsActive = !!(await Coupon.exists({ scopeType: 'batch', scopeId: batch._id, isDeleted: false, status: 'active' })); } catch (e) {}
    let scheduledExamsCount = 0;
    try {
      let ExamModel; try { ExamModel = mongoose.model('Exam'); } catch (e) { ExamModel = null; }
      if (ExamModel && examCount > 0) scheduledExamsCount = await ExamModel.countDocuments({ _id: { $in: batch.exams }, 'schedule.startTime': { $gt: new Date() } });
    } catch (e) {}
    const visibleInMarketplace = batch.status === 'active' && batch.visibility !== 'private';
    const postPublishChecks = !batch.isPublished ? null : {
      visibleInMarketplace,
      bannerLoaded: !!bannerGate.ready,
      examsAccessible: examCount > 0,
      couponsActive,
      controlsApplied: true,
      searchable: batch.visibility === 'public',
      notificationEnabled: true,
      launchStatusUpdated: true,
      state: !visibleInMarketplace ? 'Live but Hidden'
        : (batch.enrollmentRule === 'invite_only' || batch.accessPolicy !== 'open') ? 'Live but Enrollment Closed'
        : scheduledExamsCount > 0 ? 'Live with Scheduled Exams'
        : couponsActive ? 'Live with Offer Active' : 'Fully Live'
    };

    const stateMeaning = {
      draft: 'Setup incomplete or not yet launched', ready: 'All mandatory requirements complete — ready to go live',
      scheduled: 'Publish time is set in the future', published: 'Live and visible to students',
      unpublished: 'Temporarily hidden from marketplace', republish_pending: 'Live update made — re-publish required to reflect changes',
      blocked: 'Mandatory items missing / broken after being live before'
    };

    res.json({
      summary: {
        readinessScore: score, scoreStatus,
        publishStatus: batch.publishState || 'draft',
        publishStatusMeaning: stateMeaning[batch.publishState] || '',
        publishVersion: batch.publishVersion || 0,
        lastPublished: batch.lastPublishedAt || null,
        lastPublishedBy: batch.lastPublishedBy || '',
        draftChangesPending: !!batch.draftChangesPending,
        blockingIssuesCount: blockingIssues.filter(b => !b.ignorable).length,
        ignorableIssuesCount: blockingIssues.filter(b => b.ignorable).length
      },
      isPublished: !!batch.isPublished,
      checklist: { mandatory, optional },
      blockingIssues,
      scheduled: {
        scheduledPublishAt: batch.scheduledPublishAt || null,
        scheduledPublishTimezone: batch.scheduledPublishTimezone || 'Asia/Kolkata',
        scheduledAutoActivate: batch.scheduledAutoActivate !== false,
        scheduledAutoUnpublishAt: batch.scheduledAutoUnpublishAt || null,
        isScheduleActive: batch.publishState === 'scheduled'
      },
      postPublishChecks,
      editLock: { active: !!batch.isPublished || batch.publishState === 'scheduled', fields: CRITICAL_FIELDS },
      history: (batch.publishSnapshots || []).slice().reverse().slice(0, 50),
      studentCount: (batch.students && batch.students.length) || 0
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/publish
router.put('/:id/publish-center/publish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { mandatory, blockingIssues } = await buildPublishChecklist(batch.toObject());
    const hardBlocking = blockingIssues.filter(b => !b.ignorable);
    if (hardBlocking.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues: hardBlocking, gate: 'publish_blocked' });
    const oldState = batch.publishState;
    const extras = await gatherSnapshotExtras(batch);
    batch.isPublished = true;
    batch.publishState = 'published';
    batch.publishVersion = (batch.publishVersion || 0) + 1;
    batch.lastPublishedAt = new Date();
    batch.lastPublishedBy = req.user.name || 'Admin';
    batch.draftChangesPending = false;
    applyPublishState(batch, true);
    pushPublishSnapshot(batch, { action: 'publish', notes: req.body.notes, visibilityMode: req.body.visibilityMode, publishedByName: req.user.name, extras });
    batch.lastActivityAt = new Date();
    batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'publish_completed', changedBy: req.user.id, changedByName: req.user.name, snapshotVersion: batch.publishVersion });
    res.json({ success: true, publishState: batch.publishState, publishVersion: batch.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/unpublish
router.put('/:id/publish-center/unpublish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    if (!req.body.reason) return res.status(400).json({ error: 'Reason is required to unpublish' });
    const oldState = batch.publishState;
    const extras = await gatherSnapshotExtras(batch);
    batch.isPublished = false;
    batch.publishState = 'unpublished';
    applyPublishState(batch, false);
    pushPublishSnapshot(batch, { action: 'unpublish', reason: req.body.reason, publishedByName: req.user.name, extras });
    batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'unpublished', action: 'unpublish_initiated', changedBy: req.user.id, changedByName: req.user.name, reason: req.body.reason });
    res.json({ success: true, publishState: batch.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/republish
router.put('/:id/publish-center/republish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { blockingIssues } = await buildPublishChecklist(batch.toObject());
    const hardBlocking = blockingIssues.filter(b => !b.ignorable);
    if (hardBlocking.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues: hardBlocking, gate: 'publish_blocked' });
    const oldState = batch.publishState;
    const extras = await gatherSnapshotExtras(batch);
    batch.isPublished = true;
    batch.publishState = 'published';
    batch.publishVersion = (batch.publishVersion || 0) + 1;
    batch.lastPublishedAt = new Date();
    batch.lastPublishedBy = req.user.name || 'Admin';
    batch.draftChangesPending = false;
    applyPublishState(batch, true);
    pushPublishSnapshot(batch, { action: 'republish', notes: req.body.notes, publishedByName: req.user.name, extras });
    batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'republish_initiated', changedBy: req.user.id, changedByName: req.user.name, snapshotVersion: batch.publishVersion });
    res.json({ success: true, publishState: batch.publishState, publishVersion: batch.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/schedule
router.put('/:id/publish-center/schedule', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { publishAt, timezone, autoActivate, autoUnpublishAt } = req.body;
    if (!publishAt || new Date(publishAt) <= new Date()) return res.status(400).json({ error: 'Publish Date/Time must be in the future' });
    if (batch.startDate && new Date(publishAt) > new Date(batch.startDate)) return res.status(400).json({ error: 'Publish time conflict: scheduled time is after the batch Start Date' });
    batch.scheduledPublishAt = new Date(publishAt);
    batch.scheduledPublishTimezone = timezone || 'Asia/Kolkata';
    batch.scheduledAutoActivate = autoActivate !== false;
    batch.scheduledAutoUnpublishAt = autoUnpublishAt ? new Date(autoUnpublishAt) : null;
    batch.publishState = 'scheduled';
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'scheduledPublishAt', newValue: batch.scheduledPublishAt, action: 'scheduled_publish_set', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, scheduledPublishAt: batch.scheduledPublishAt });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/schedule/cancel
router.put('/:id/publish-center/schedule/cancel', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.scheduledPublishAt = null;
    batch.scheduledAutoUnpublishAt = null;
    batch.publishState = batch.isPublished ? 'published' : 'draft';
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'scheduledPublishAt', newValue: null, action: 'scheduled_publish_cancelled', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: batch.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/archive
router.put('/:id/publish-center/archive', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const extras = await gatherSnapshotExtras(batch);
    batch.isPublished = false;
    batch.publishState = 'unpublished';
    batch.lifecycleStatus = 'archived';
    batch.archivedAt = new Date();
    applyPublishState(batch, false);
    pushPublishSnapshot(batch, { action: 'archive', reason: req.body.reason, publishedByName: req.user.name, extras });
    batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'lifecycleStatus', newValue: 'archived', action: 'publish_center_archive', changedBy: req.user.id, changedByName: req.user.name, reason: req.body.reason });
    res.json({ success: true, publishState: batch.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/restore-draft
router.put('/:id/publish-center/restore-draft', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.publishState = 'draft';
    batch.draftChangesPending = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', newValue: 'draft', action: 'restore_draft', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: batch.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/ignore-issue — mark an ignorable optional/soft issue as ignored
router.put('/:id/publish-center/ignore-issue', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { key } = req.body;
    if (!key) return res.status(400).json({ error: 'key required' });
    batch.publishIgnoredIssues = batch.publishIgnoredIssues || [];
    if (!batch.publishIgnoredIssues.includes(key)) batch.publishIgnoredIssues.push(key);
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishIgnoredIssues', newValue: key, action: 'issue_ignored', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishIgnoredIssues: batch.publishIgnoredIssues });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.delete('/:id/publish-center/ignore-issue/:key', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.publishIgnoredIssues = (batch.publishIgnoredIssues || []).filter(k => k !== req.params.key);
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishIgnoredIssues', newValue: 'un-ignored:' + req.params.key, action: 'issue_unignored', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishIgnoredIssues: batch.publishIgnoredIssues });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/history
router.get('/:id/publish-center/history', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.json({ history: (batch.publishSnapshots || []).slice().reverse() });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/history/export — download publish log
router.get('/:id/publish-center/history/export', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="publish-log-${batch.batchCode || batch._id}.json"`);
    res.send(JSON.stringify((batch.publishSnapshots || []).slice().reverse(), null, 2));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/snapshot/:version
router.get('/:id/publish-center/snapshot/:version', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const snap = (batch.publishSnapshots || []).find(s => String(s.version) === String(req.params.version));
    if (!snap) return res.status(404).json({ error: 'Snapshot not found' });
    res.json({ snapshot: snap });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/compare?from=X&to=Y — field-level diff between two snapshot versions
router.get('/:id/publish-center/compare', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { from, to } = req.query;
    const a = (batch.publishSnapshots || []).find(s => String(s.version) === String(from));
    const b = (batch.publishSnapshots || []).find(s => String(s.version) === String(to));
    if (!a || !b) return res.status(404).json({ error: 'One or both snapshot versions not found' });
    const diff = [];
    const keys = new Set([...Object.keys(a.snapshotData || {}), ...Object.keys(b.snapshotData || {})]);
    keys.forEach(k => {
      const av = JSON.stringify(a.snapshotData?.[k]), bv = JSON.stringify(b.snapshotData?.[k]);
      if (av !== bv) diff.push({ field: k, from: a.snapshotData?.[k], to: b.snapshotData?.[k] });
    });
    res.json({ from: a.version, to: b.version, diff });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/publish-center/rollback
router.post('/:id/publish-center/rollback', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { toVersion, reason, scope, sections, confirmLiveImpact } = req.body;
    if (!reason) return res.status(400).json({ error: 'Reason is mandatory for rollback' });
    const studentCount = (batch.students && batch.students.length) || 0;
    if (studentCount > 0 && !confirmLiveImpact) {
      return res.status(409).json({ warning: 'live_students_affected', studentCount, message: `This batch has ${studentCount} enrolled student(s). Confirm to proceed with rollback.` });
    }
    const snap = (batch.publishSnapshots || []).find(s => String(s.version) === String(toVersion));
    if (!snap) return res.status(404).json({ error: 'Snapshot version not found' });
    const d = snap.snapshotData || {};
    const SECTION_FIELD_GROUPS = {
      basicInfo: ['name', 'description', 'examType', 'category'],
      pricing: ['price', 'discountPrice'],
      banner: ['thumbnail', 'colorIcon'],
      dates: ['startDate', 'endDate', 'validity'],
      controls: ['seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility'],
      other: ['teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial']
    };
    const fieldsToRestore = (Array.isArray(sections) && sections.length > 0)
      ? sections.flatMap(s => SECTION_FIELD_GROUPS[s] || [])
      : SNAPSHOT_FIELDS;
    fieldsToRestore.forEach(f => { if (d[f] !== undefined) batch[f] = d[f]; });
    if (scope === 'draft_only') {
      batch.publishState = 'draft';
      batch.draftChangesPending = true;
    } else {
      batch.isPublished = true;
      batch.publishState = 'published';
      batch.publishVersion = (batch.publishVersion || 0) + 1;
      batch.lastPublishedAt = new Date();
      batch.lastPublishedBy = req.user.name || 'Admin';
      applyPublishState(batch, true);
    }
    const extras = await gatherSnapshotExtras(batch);
    pushPublishSnapshot(batch, { action: 'rollback', reason, publishedByName: req.user.name, extras });
    batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishVersion', oldValue: batch.publishVersion, newValue: toVersion, action: 'rollback_executed', changedBy: req.user.id, changedByName: req.user.name, reason, snapshotVersion: toVersion });
    res.json({ success: true, publishState: batch.publishState, publishVersion: batch.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/preview — student-facing preview (marketplace/card/detail/mobile/desktop/mybatches)
router.get('/:id/publish-center/preview', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const eff = effectivePrice(batch);
    const base = batch.price || 0;
    const discountPct = (!base || base <= eff) ? 0 : Math.round(((base - eff) / base) * 100);
    let banner = null;
    try {
      const Banner = mongoose.model('Banner');
      banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: batch._id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    } catch (e) {}
    const examCount = (batch.exams && batch.exams.length) || 0;
    res.json({
      mode: req.query.mode || 'marketplace',
      preview: {
        title: batch.name, banner: banner ? { title: banner.title, tagline: banner.tagline, bgImage: banner.bgImage, primaryColor: banner.primaryColor } : null,
        price: base, effectivePrice: eff, discountPct,
        cta: batch.isFree ? 'Enroll Free' : (batch.allowFreeTrial ? 'Start Free Trial' : 'Enroll Now'),
        examsSummary: { count: examCount }, validity: batch.validity, offerBadges: [batch.isSpotlight && 'Spotlight', batch.isBundle && 'Bundle', batch.allowFreeTrial && 'Free Trial'].filter(Boolean),
        enrollmentState: batch.enrollmentRule
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/publish-center/simulate-enroll — simulated enrollment flow (no real enrollment created)
router.post('/:id/publish-center/simulate-enroll', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const eff = effectivePrice(batch);
    res.json({
      simulated: true,
      steps: [
        { step: 'View Batch', ok: true },
        { step: 'Click ' + (batch.isFree ? 'Enroll Free' : 'Enroll Now'), ok: true },
        { step: batch.isFree ? 'Free enrollment confirmed' : `Payment of ₹${eff} simulated`, ok: true },
        { step: 'Access granted to My Batches', ok: true }
      ],
      note: 'This is a simulation only — no real enrollment or payment was created.'
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Scheduler: in-process check every 60s for due scheduled publishes / auto-unpublish ──
if (!global.__proveRankBatchSchedulerStarted) {
  global.__proveRankBatchSchedulerStarted = true;
  setInterval(async () => {
    try {
      const now = new Date();
      const due = await Batch.find({ publishState: 'scheduled', scheduledPublishAt: { $lte: now } });
      for (const batch of due) {
        try {
          if (batch.scheduledAutoActivate === false) continue;
          const { blockingIssues } = await buildPublishChecklist(batch.toObject());
          const hardBlocking = blockingIssues.filter(b => !b.ignorable);
          if (hardBlocking.length > 0) { batch.publishState = 'blocked'; await batch.save(); continue; }
          const extras = await gatherSnapshotExtras(batch);
          batch.isPublished = true; batch.publishState = 'published';
          batch.publishVersion = (batch.publishVersion || 0) + 1;
          batch.lastPublishedAt = new Date(); batch.lastPublishedBy = 'Scheduler (auto)';
          batch.draftChangesPending = false;
          applyPublishState(batch, true);
          pushPublishSnapshot(batch, { action: 'publish', notes: 'Auto-published via schedule', publishedByName: 'Scheduler (auto)', extras });
          batch.scheduledPublishAt = null;
          batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
          await batch.save();
          await logAudit({ batchId: batch._id, field: 'publishState', newValue: 'published', action: 'publish_completed', changedByName: 'Scheduler (auto)', snapshotVersion: batch.publishVersion });
        } catch (e) { /* per-batch failure must not break the loop */ }
      }
      const dueUnpub = await Batch.find({ isPublished: true, scheduledAutoUnpublishAt: { $lte: now, $ne: null } });
      for (const batch of dueUnpub) {
        try {
          batch.isPublished = false; batch.publishState = 'unpublished';
          applyPublishState(batch, false);
          const extras = await gatherSnapshotExtras(batch);
          pushPublishSnapshot(batch, { action: 'unpublish', reason: 'Auto-unpublish (scheduled)', publishedByName: 'Scheduler (auto)', extras });
          batch.scheduledAutoUnpublishAt = null;
          batch.$locals = batch.$locals || {}; batch.$locals.allowCriticalEdit = true;
          await batch.save();
          await logAudit({ batchId: batch._id, field: 'publishState', newValue: 'unpublished', action: 'unpublish_initiated', changedByName: 'Scheduler (auto)', reason: 'Auto-unpublish (scheduled)' });
        } catch (e) {}
      }
    } catch (e) { /* scheduler tick failure must never crash the server */ }
  }, 60000);
}

BATCHV2_EOF

# 5) TestSeries Publish Center v2 backend routes
cat > "$STAGE/publish_center_series_v2.js" << 'SERIESV2_EOF'

// ══════════════════════════════════════════════════════════════════
// 16) PUBLISH CENTER — Go-Live Control Center  [v2]
// ══════════════════════════════════════════════════════════════════
function scoreStatusLabel(score) {
  if (score >= 95) return 'Ready to Publish';
  if (score >= 80) return 'Almost Ready';
  if (score >= 50) return 'Partially Ready';
  return 'Not Ready';
}

const CRITICAL_FIELDS = ['examType', 'price', 'discountPrice', 'startDate', 'endDate', 'validity'];
const SNAPSHOT_FIELDS = ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
  'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility',
  'teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial', 'lifecycleStatus', 'status'];
const SECTION_MAP = { basicInfo: 'settings', banner: 'banner', pricing: 'pricing', dateRange: 'settings', startDate: 'settings', endDate: 'settings', controls: 'controls', coupons: 'coupons', scheduleConflict: 'publish' };

async function gatherSnapshotExtras(series) {
  let bannerSnap = null, couponIds = [], materialsCount = 0, announcementsCount = 0;
  try {
    const Banner = mongoose.model('Banner');
    const b = await Banner.findOne({ linkedType: 'series', linkedBatchId: series._id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (b) bannerSnap = { id: b._id, title: b.title, tagline: b.tagline, status: b.status, primaryColor: b.primaryColor };
  } catch (e) {}
  try { couponIds = (await Coupon.find({ scopeType: 'series', scopeId: series._id, isDeleted: false }).select('_id code status').lean()).map(c => ({ id: c._id, code: c.code, status: c.status })); } catch (e) {}
  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: series._id }); } catch (e) {}
  try { let A; try { A = mongoose.model('Announcement'); } catch (e) { A = null; } if (A) announcementsCount = await A.countDocuments({ seriesId: series._id }); } catch (e) {}
  return { banner: bannerSnap, coupons: couponIds, examsCount: (series.exams && series.exams.length) || 0, exams: (series.exams || []).map(String), materialsCount, announcementsCount };
}

async function buildPublishChecklist(series) {
  const studentCount = (series.students && series.students.length) || 0;
  const examCount = (series.exams && series.exams.length) || 0;
  const bannerGate = await checkBannerGate(series._id);
  let materialsCount = 0;
  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ batch: series._id }); } catch (e) {}
  let announcementsCount = 0;
  try {
    let Announcement; try { Announcement = mongoose.model('Announcement'); } catch (e) { Announcement = null; }
    if (Announcement) announcementsCount = await Announcement.countDocuments({ seriesId: series._id });
  } catch (e) {}
  let coupons = [];
  try { coupons = await Coupon.find({ scopeType: 'series', scopeId: series._id, isDeleted: false }).lean(); } catch (e) {}
  const now = new Date();
  const expiredButActive = coupons.filter(c => c.status === 'active' && c.validTill && new Date(c.validTill) < now);
  const couponIssue = expiredButActive.length > 0 ? `${expiredButActive.length} active coupon(s) already expired` : '';

  const dateRangeOk = !(series.startDate && series.endDate) || (new Date(series.endDate) > new Date(series.startDate));
  let scheduleConflict = '';
  if (series.scheduledPublishAt && series.startDate && new Date(series.scheduledPublishAt) > new Date(series.startDate)) {
    scheduleConflict = 'Scheduled publish time is AFTER the series Start Date — students will miss the start.';
  }
  let controlMismatch = '';
  if (series.seatLimit > 0 && studentCount > series.seatLimit) controlMismatch = `Enrolled students (${studentCount}) already exceed Seat Limit (${series.seatLimit})`;

  const ignored = series.publishIgnoredIssues || [];
  const mandatory = [
    { key: 'basicInfo', label: 'Basic Information complete', done: !!(series.name && series.description && series.examType), reason: 'Name, description & exam type required', ignorable: false, section: 'settings' },
    { key: 'banner', label: 'Banner ready', done: !!bannerGate.ready, reason: bannerGate.reason || '', ignorable: false, section: 'banner' },
    { key: 'pricing', label: 'Pricing configured', done: !!(series.isFree || (series.price && series.price > 0)), reason: 'Set a price or mark as Free', ignorable: false, section: 'pricing' },
    { key: 'startDate', label: 'Start Date set', done: !!series.startDate, reason: 'Start Date missing in Settings', ignorable: false, section: 'settings' },
    { key: 'endDate', label: 'End Date / Validity set', done: !!(series.endDate || (series.validity && series.validity > 0)), reason: 'End Date or Validity missing', ignorable: false, section: 'settings' },
    { key: 'dateRange', label: 'Date range valid (End after Start)', done: dateRangeOk, reason: dateRangeOk ? '' : 'End Date must be after Start Date', ignorable: false, section: 'settings' },
    { key: 'scheduleConflict', label: 'No publish-time conflict', done: !scheduleConflict, reason: scheduleConflict, ignorable: true, section: 'publish' },
    { key: 'controls', label: 'Controls configured (no mismatch)', done: !controlMismatch, reason: controlMismatch, ignorable: true, section: 'controls' },
    { key: 'coupons', label: 'Coupon configuration checked', done: coupons.length === 0 || expiredButActive.length === 0, reason: couponIssue, ignorable: true, section: 'coupons' }
  ].map(m => ({ ...m, done: m.done || (m.ignorable && ignored.includes(m.key)) }));
  const optional = [
    { key: 'exams', label: 'Exams added', done: examCount > 0, count: examCount },
    { key: 'materials', label: 'Materials added', done: materialsCount > 0, count: materialsCount },
    { key: 'announcements', label: 'Announcements prepared', done: announcementsCount > 0, count: announcementsCount },
    { key: 'faq', label: 'FAQ / Help content', done: true },
    { key: 'leaderboard', label: 'Leaderboard enabled', done: true },
    { key: 'analytics', label: 'Analytics enabled', done: true }
  ];

  const weights = { basicInfo: 12, banner: 18, pricing: 12, startDate: 6, endDate: 6, dateRange: 5, controls: 8, coupons: 5, scheduleConflict: 3 };
  let score = 0;
  mandatory.forEach(m => { if (m.done) score += (weights[m.key] || 0); });
  score += examCount > 0 ? 15 : 0;
  score += (series.thumbnail || series.colorIcon) ? 10 : 0;
  score = Math.max(0, Math.min(100, Math.round(score)));

  const blockingIssues = mandatory.filter(m => !m.done)
    .map(m => ({ key: m.key, message: m.reason || (m.label + ' missing'), ignorable: m.ignorable, section: SECTION_MAP[m.key] || 'overview' }));

  return { mandatory, optional, score, scoreStatus: scoreStatusLabel(score), blockingIssues, studentCount, examCount, bannerGate, ignored };
}

function syncEffectivePublishState(currentState, isPublished, blockingIssues, publishVersion) {
  if (currentState === 'scheduled' || isPublished) return currentState;
  const hasIssues = blockingIssues.some(b => !b.ignorable || true) && blockingIssues.length > 0;
  if (hasIssues) return publishVersion > 0 ? 'blocked' : 'draft';
  return 'ready';
}

function applyPublishState(series, isPublished) {
  series.status = isPublished ? 'active' : (series.status === 'draft' ? 'draft' : 'inactive');
}

function pushPublishSnapshot(series, { action, notes, reason, visibilityMode, publishedByName, extras }) {
  series.publishSnapshots = series.publishSnapshots || [];
  const version = series.publishVersion || 0;
  series.publishSnapshots.push({
    version,
    snapshotId: 'v' + version + '-' + Date.now(),
    publishedAt: new Date(),
    publishedBy: publishedByName || 'Admin',
    status: series.publishState,
    action,
    notes: notes || '',
    reason: reason || '',
    visibilityMode: visibilityMode || series.visibility || 'public',
    snapshotData: {
      ...Object.fromEntries(SNAPSHOT_FIELDS.map(f => [f, series[f]])),
      banner: extras?.banner || null, coupons: extras?.coupons || [], exams: extras?.exams || [],
      examsCount: extras?.examsCount || 0, materialsCount: extras?.materialsCount || 0, announcementsCount: extras?.announcementsCount || 0
    }
  });
  if (series.publishSnapshots.length > 40) series.publishSnapshots = series.publishSnapshots.slice(-40);
}

// GET /:id/publish-center — full readiness + status dashboard
router.get('/:id/publish-center', auth, isAdmin, async (req, res) => {
  try {
    let series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { mandatory, optional, score, scoreStatus, blockingIssues, examCount, bannerGate } = await buildPublishChecklist(series);

    const nextState = syncEffectivePublishState(series.publishState || 'draft', !!series.isPublished, blockingIssues, series.publishVersion || 0);
    if (nextState !== series.publishState) {
      await TestSeries.updateOne({ _id: series._id }, { $set: { publishState: nextState } });
      series.publishState = nextState;
    }

    let couponsActive = false;
    try { couponsActive = !!(await Coupon.exists({ scopeType: 'series', scopeId: series._id, isDeleted: false, status: 'active' })); } catch (e) {}
    let scheduledExamsCount = 0;
    try {
      let ExamModel; try { ExamModel = mongoose.model('Exam'); } catch (e) { ExamModel = null; }
      if (ExamModel && examCount > 0) scheduledExamsCount = await ExamModel.countDocuments({ _id: { $in: series.exams }, 'schedule.startTime': { $gt: new Date() } });
    } catch (e) {}
    const visibleInMarketplace = series.status === 'active' && series.visibility !== 'private';
    const postPublishChecks = !series.isPublished ? null : {
      visibleInMarketplace,
      bannerLoaded: !!bannerGate.ready,
      examsAccessible: examCount > 0,
      couponsActive,
      controlsApplied: true,
      searchable: series.visibility === 'public',
      notificationEnabled: true,
      launchStatusUpdated: true,
      state: !visibleInMarketplace ? 'Live but Hidden'
        : (series.enrollmentRule === 'invite_only' || series.accessPolicy !== 'open') ? 'Live but Enrollment Closed'
        : scheduledExamsCount > 0 ? 'Live with Scheduled Exams'
        : couponsActive ? 'Live with Offer Active' : 'Fully Live'
    };

    const stateMeaning = {
      draft: 'Setup incomplete or not yet launched', ready: 'All mandatory requirements complete — ready to go live',
      scheduled: 'Publish time is set in the future', published: 'Live and visible to students',
      unpublished: 'Temporarily hidden from marketplace', republish_pending: 'Live update made — re-publish required to reflect changes',
      blocked: 'Mandatory items missing / broken after being live before'
    };

    res.json({
      summary: {
        readinessScore: score, scoreStatus,
        publishStatus: series.publishState || 'draft',
        publishStatusMeaning: stateMeaning[series.publishState] || '',
        publishVersion: series.publishVersion || 0,
        lastPublished: series.lastPublishedAt || null,
        lastPublishedBy: series.lastPublishedBy || '',
        draftChangesPending: !!series.draftChangesPending,
        blockingIssuesCount: blockingIssues.filter(b => !b.ignorable).length,
        ignorableIssuesCount: blockingIssues.filter(b => b.ignorable).length
      },
      isPublished: !!series.isPublished,
      checklist: { mandatory, optional },
      blockingIssues,
      scheduled: {
        scheduledPublishAt: series.scheduledPublishAt || null,
        scheduledPublishTimezone: series.scheduledPublishTimezone || 'Asia/Kolkata',
        scheduledAutoActivate: series.scheduledAutoActivate !== false,
        scheduledAutoUnpublishAt: series.scheduledAutoUnpublishAt || null,
        isScheduleActive: series.publishState === 'scheduled'
      },
      postPublishChecks,
      editLock: { active: !!series.isPublished || series.publishState === 'scheduled', fields: CRITICAL_FIELDS },
      history: (series.publishSnapshots || []).slice().reverse().slice(0, 50),
      studentCount: (series.students && series.students.length) || 0
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/publish
router.put('/:id/publish-center/publish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { mandatory, blockingIssues } = await buildPublishChecklist(series.toObject());
    const hardBlocking = blockingIssues.filter(b => !b.ignorable);
    if (hardBlocking.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues: hardBlocking, gate: 'publish_blocked' });
    const oldState = series.publishState;
    const extras = await gatherSnapshotExtras(series);
    series.isPublished = true;
    series.publishState = 'published';
    series.publishVersion = (series.publishVersion || 0) + 1;
    series.lastPublishedAt = new Date();
    series.lastPublishedBy = req.user.name || 'Admin';
    series.draftChangesPending = false;
    applyPublishState(series, true);
    pushPublishSnapshot(series, { action: 'publish', notes: req.body.notes, visibilityMode: req.body.visibilityMode, publishedByName: req.user.name, extras });
    series.lastActivityAt = new Date();
    series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'publish_completed', changedBy: req.user.id, changedByName: req.user.name, snapshotVersion: series.publishVersion });
    res.json({ success: true, publishState: series.publishState, publishVersion: series.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/unpublish
router.put('/:id/publish-center/unpublish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    if (!req.body.reason) return res.status(400).json({ error: 'Reason is required to unpublish' });
    const oldState = series.publishState;
    const extras = await gatherSnapshotExtras(series);
    series.isPublished = false;
    series.publishState = 'unpublished';
    applyPublishState(series, false);
    pushPublishSnapshot(series, { action: 'unpublish', reason: req.body.reason, publishedByName: req.user.name, extras });
    series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'unpublished', action: 'unpublish_initiated', changedBy: req.user.id, changedByName: req.user.name, reason: req.body.reason });
    res.json({ success: true, publishState: series.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/republish
router.put('/:id/publish-center/republish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { blockingIssues } = await buildPublishChecklist(series.toObject());
    const hardBlocking = blockingIssues.filter(b => !b.ignorable);
    if (hardBlocking.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues: hardBlocking, gate: 'publish_blocked' });
    const oldState = series.publishState;
    const extras = await gatherSnapshotExtras(series);
    series.isPublished = true;
    series.publishState = 'published';
    series.publishVersion = (series.publishVersion || 0) + 1;
    series.lastPublishedAt = new Date();
    series.lastPublishedBy = req.user.name || 'Admin';
    series.draftChangesPending = false;
    applyPublishState(series, true);
    pushPublishSnapshot(series, { action: 'republish', notes: req.body.notes, publishedByName: req.user.name, extras });
    series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'republish_initiated', changedBy: req.user.id, changedByName: req.user.name, snapshotVersion: series.publishVersion });
    res.json({ success: true, publishState: series.publishState, publishVersion: series.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/schedule
router.put('/:id/publish-center/schedule', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { publishAt, timezone, autoActivate, autoUnpublishAt } = req.body;
    if (!publishAt || new Date(publishAt) <= new Date()) return res.status(400).json({ error: 'Publish Date/Time must be in the future' });
    if (series.startDate && new Date(publishAt) > new Date(series.startDate)) return res.status(400).json({ error: 'Publish time conflict: scheduled time is after the series Start Date' });
    series.scheduledPublishAt = new Date(publishAt);
    series.scheduledPublishTimezone = timezone || 'Asia/Kolkata';
    series.scheduledAutoActivate = autoActivate !== false;
    series.scheduledAutoUnpublishAt = autoUnpublishAt ? new Date(autoUnpublishAt) : null;
    series.publishState = 'scheduled';
    await series.save();
    await logAudit({ seriesId: series._id, field: 'scheduledPublishAt', newValue: series.scheduledPublishAt, action: 'scheduled_publish_set', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, scheduledPublishAt: series.scheduledPublishAt });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/schedule/cancel
router.put('/:id/publish-center/schedule/cancel', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.scheduledPublishAt = null;
    series.scheduledAutoUnpublishAt = null;
    series.publishState = series.isPublished ? 'published' : 'draft';
    await series.save();
    await logAudit({ seriesId: series._id, field: 'scheduledPublishAt', newValue: null, action: 'scheduled_publish_cancelled', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: series.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/archive
router.put('/:id/publish-center/archive', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const extras = await gatherSnapshotExtras(series);
    series.isPublished = false;
    series.publishState = 'unpublished';
    series.lifecycleStatus = 'archived';
    series.archivedAt = new Date();
    applyPublishState(series, false);
    pushPublishSnapshot(series, { action: 'archive', reason: req.body.reason, publishedByName: req.user.name, extras });
    series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'lifecycleStatus', newValue: 'archived', action: 'publish_center_archive', changedBy: req.user.id, changedByName: req.user.name, reason: req.body.reason });
    res.json({ success: true, publishState: series.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/restore-draft
router.put('/:id/publish-center/restore-draft', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.publishState = 'draft';
    series.draftChangesPending = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', newValue: 'draft', action: 'restore_draft', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: series.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/ignore-issue — mark an ignorable optional/soft issue as ignored
router.put('/:id/publish-center/ignore-issue', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { key } = req.body;
    if (!key) return res.status(400).json({ error: 'key required' });
    series.publishIgnoredIssues = series.publishIgnoredIssues || [];
    if (!series.publishIgnoredIssues.includes(key)) series.publishIgnoredIssues.push(key);
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishIgnoredIssues', newValue: key, action: 'issue_ignored', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishIgnoredIssues: series.publishIgnoredIssues });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
router.delete('/:id/publish-center/ignore-issue/:key', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.publishIgnoredIssues = (series.publishIgnoredIssues || []).filter(k => k !== req.params.key);
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishIgnoredIssues', newValue: 'un-ignored:' + req.params.key, action: 'issue_unignored', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishIgnoredIssues: series.publishIgnoredIssues });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/history
router.get('/:id/publish-center/history', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.json({ history: (series.publishSnapshots || []).slice().reverse() });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/history/export — download publish log
router.get('/:id/publish-center/history/export', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="publish-log-${series.seriesCode || series._id}.json"`);
    res.send(JSON.stringify((series.publishSnapshots || []).slice().reverse(), null, 2));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/snapshot/:version
router.get('/:id/publish-center/snapshot/:version', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const snap = (series.publishSnapshots || []).find(s => String(s.version) === String(req.params.version));
    if (!snap) return res.status(404).json({ error: 'Snapshot not found' });
    res.json({ snapshot: snap });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/compare?from=X&to=Y — field-level diff between two snapshot versions
router.get('/:id/publish-center/compare', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { from, to } = req.query;
    const a = (series.publishSnapshots || []).find(s => String(s.version) === String(from));
    const b = (series.publishSnapshots || []).find(s => String(s.version) === String(to));
    if (!a || !b) return res.status(404).json({ error: 'One or both snapshot versions not found' });
    const diff = [];
    const keys = new Set([...Object.keys(a.snapshotData || {}), ...Object.keys(b.snapshotData || {})]);
    keys.forEach(k => {
      const av = JSON.stringify(a.snapshotData?.[k]), bv = JSON.stringify(b.snapshotData?.[k]);
      if (av !== bv) diff.push({ field: k, from: a.snapshotData?.[k], to: b.snapshotData?.[k] });
    });
    res.json({ from: a.version, to: b.version, diff });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/publish-center/rollback
router.post('/:id/publish-center/rollback', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { toVersion, reason, scope, sections, confirmLiveImpact } = req.body;
    if (!reason) return res.status(400).json({ error: 'Reason is mandatory for rollback' });
    const studentCount = (series.students && series.students.length) || 0;
    if (studentCount > 0 && !confirmLiveImpact) {
      return res.status(409).json({ warning: 'live_students_affected', studentCount, message: `This series has ${studentCount} enrolled student(s). Confirm to proceed with rollback.` });
    }
    const snap = (series.publishSnapshots || []).find(s => String(s.version) === String(toVersion));
    if (!snap) return res.status(404).json({ error: 'Snapshot version not found' });
    const d = snap.snapshotData || {};
    const SECTION_FIELD_GROUPS = {
      basicInfo: ['name', 'description', 'examType', 'category'],
      pricing: ['price', 'discountPrice'],
      banner: ['thumbnail', 'colorIcon'],
      dates: ['startDate', 'endDate', 'validity'],
      controls: ['seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility'],
      other: ['teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial']
    };
    const fieldsToRestore = (Array.isArray(sections) && sections.length > 0)
      ? sections.flatMap(s => SECTION_FIELD_GROUPS[s] || [])
      : SNAPSHOT_FIELDS;
    fieldsToRestore.forEach(f => { if (d[f] !== undefined) series[f] = d[f]; });
    if (scope === 'draft_only') {
      series.publishState = 'draft';
      series.draftChangesPending = true;
    } else {
      series.isPublished = true;
      series.publishState = 'published';
      series.publishVersion = (series.publishVersion || 0) + 1;
      series.lastPublishedAt = new Date();
      series.lastPublishedBy = req.user.name || 'Admin';
      applyPublishState(series, true);
    }
    const extras = await gatherSnapshotExtras(series);
    pushPublishSnapshot(series, { action: 'rollback', reason, publishedByName: req.user.name, extras });
    series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishVersion', oldValue: series.publishVersion, newValue: toVersion, action: 'rollback_executed', changedBy: req.user.id, changedByName: req.user.name, reason, snapshotVersion: toVersion });
    res.json({ success: true, publishState: series.publishState, publishVersion: series.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/preview — student-facing preview (marketplace/card/detail/mobile/desktop/mybatches)
router.get('/:id/publish-center/preview', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const eff = effectivePrice(series);
    const base = series.price || 0;
    const discountPct = (!base || base <= eff) ? 0 : Math.round(((base - eff) / base) * 100);
    let banner = null;
    try {
      const Banner = mongoose.model('Banner');
      banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: series._id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    } catch (e) {}
    const examCount = (series.exams && series.exams.length) || 0;
    res.json({
      mode: req.query.mode || 'marketplace',
      preview: {
        title: series.name, banner: banner ? { title: banner.title, tagline: banner.tagline, bgImage: banner.bgImage, primaryColor: banner.primaryColor } : null,
        price: base, effectivePrice: eff, discountPct,
        cta: series.isFree ? 'Enroll Free' : (series.allowFreeTrial ? 'Start Free Trial' : 'Enroll Now'),
        examsSummary: { count: examCount }, validity: series.validity, offerBadges: [series.isSpotlight && 'Spotlight', series.isBundle && 'Bundle', series.allowFreeTrial && 'Free Trial'].filter(Boolean),
        enrollmentState: series.enrollmentRule
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/publish-center/simulate-enroll — simulated enrollment flow (no real enrollment created)
router.post('/:id/publish-center/simulate-enroll', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const eff = effectivePrice(series);
    res.json({
      simulated: true,
      steps: [
        { step: 'View Batch', ok: true },
        { step: 'Click ' + (series.isFree ? 'Enroll Free' : 'Enroll Now'), ok: true },
        { step: series.isFree ? 'Free enrollment confirmed' : `Payment of ₹${eff} simulated`, ok: true },
        { step: 'Access granted to My Batches', ok: true }
      ],
      note: 'This is a simulation only — no real enrollment or payment was created.'
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Scheduler: in-process check every 60s for due scheduled publishes / auto-unpublish ──
if (!global.__proveRankSeriesSchedulerStarted) {
  global.__proveRankSeriesSchedulerStarted = true;
  setInterval(async () => {
    try {
      const now = new Date();
      const due = await TestSeries.find({ publishState: 'scheduled', scheduledPublishAt: { $lte: now } });
      for (const series of due) {
        try {
          if (series.scheduledAutoActivate === false) continue;
          const { blockingIssues } = await buildPublishChecklist(series.toObject());
          const hardBlocking = blockingIssues.filter(b => !b.ignorable);
          if (hardBlocking.length > 0) { series.publishState = 'blocked'; await series.save(); continue; }
          const extras = await gatherSnapshotExtras(series);
          series.isPublished = true; series.publishState = 'published';
          series.publishVersion = (series.publishVersion || 0) + 1;
          series.lastPublishedAt = new Date(); series.lastPublishedBy = 'Scheduler (auto)';
          series.draftChangesPending = false;
          applyPublishState(series, true);
          pushPublishSnapshot(series, { action: 'publish', notes: 'Auto-published via schedule', publishedByName: 'Scheduler (auto)', extras });
          series.scheduledPublishAt = null;
          series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
          await series.save();
          await logAudit({ seriesId: series._id, field: 'publishState', newValue: 'published', action: 'publish_completed', changedByName: 'Scheduler (auto)', snapshotVersion: series.publishVersion });
        } catch (e) { /* per-batch failure must not break the loop */ }
      }
      const dueUnpub = await TestSeries.find({ isPublished: true, scheduledAutoUnpublishAt: { $lte: now, $ne: null } });
      for (const series of dueUnpub) {
        try {
          series.isPublished = false; series.publishState = 'unpublished';
          applyPublishState(series, false);
          const extras = await gatherSnapshotExtras(series);
          pushPublishSnapshot(series, { action: 'unpublish', reason: 'Auto-unpublish (scheduled)', publishedByName: 'Scheduler (auto)', extras });
          series.scheduledAutoUnpublishAt = null;
          series.$locals = series.$locals || {}; series.$locals.allowCriticalEdit = true;
          await series.save();
          await logAudit({ seriesId: series._id, field: 'publishState', newValue: 'unpublished', action: 'unpublish_initiated', changedByName: 'Scheduler (auto)', reason: 'Auto-unpublish (scheduled)' });
        } catch (e) {}
      }
    } catch (e) { /* scheduler tick failure must never crash the server */ }
  }, 60000);
}

SERIESV2_EOF

# 6) Batch logAudit() v2 replacement
cat > "$STAGE/logaudit_patch_batch.txt" << 'LABATCH_EOF'
async function logAudit({ batchId, field, oldValue, newValue, changedBy, changedByName, action, source, reason, snapshotVersion }) {
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
      reason: reason || '',
      snapshotVersion: snapshotVersion === undefined ? null : snapshotVersion,
      timestamp: new Date()
    });
  } catch (e) { /* audit failures must never break main flow */ }
}

LABATCH_EOF

# 7) TestSeries logAudit() v2 replacement
cat > "$STAGE/logaudit_patch_series.txt" << 'LASERIES_EOF'
async function logAudit({ seriesId, field, oldValue, newValue, changedBy, changedByName, action, source, reason, snapshotVersion }) {
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
      reason: reason || '',
      snapshotVersion: snapshotVersion === undefined ? null : snapshotVersion,
      timestamp: new Date()
    });
  } catch (e) { /* audit failures must never break main flow */ }
}

LASERIES_EOF

# 8) Publish Center frontend tab v2 (shared)
cat > "$STAGE/publish_center_tab_v2.tsx" << 'PUBTABV2_EOF'

// ── 16) PUBLISH CENTER TAB — Go-Live Control Center [v2] ──
function PublishCenterTab({ base, authHeaders, id, showToast, load: loadParent, setParentTab }: any) {
  const isMobile = useIsMobile()
  const [data, setData] = useState<any>(null)
  const [previewMode, setPreviewMode] = useState('marketplace')
  const [preview, setPreview] = useState<any>(null)
  const [showPreview, setShowPreview] = useState(false)
  const [previewDrawer, setPreviewDrawer] = useState(false)
  const [simResult, setSimResult] = useState<any>(null)
  const [notes, setNotes] = useState('')
  const [showSchedule, setShowSchedule] = useState(false)
  const [sched, setSched] = useState<any>({ publishAt: '', timezone: 'Asia/Kolkata', autoActivate: true, autoUnpublishAt: '' })
  const [rollbackFor, setRollbackFor] = useState<any>(null)
  const [rollbackReason, setRollbackReason] = useState('')
  const [rollbackScope, setRollbackScope] = useState('full')
  const [rollbackSections, setRollbackSections] = useState<string[]>([])
  const [rollbackWarning, setRollbackWarning] = useState<any>(null)
  const [unpublishReason, setUnpublishReason] = useState('')
  const [showUnpublishBox, setShowUnpublishBox] = useState(false)
  const [busy, setBusy] = useState(false)
  const [historyOpen, setHistoryOpen] = useState(!isMobile)
  const [checklistOpen, setChecklistOpen] = useState(true)
  const [stateInfoOpen, setStateInfoOpen] = useState(false)
  const [compareFrom, setCompareFrom] = useState('')
  const [compareTo, setCompareTo] = useState('')
  const [compareResult, setCompareResult] = useState<any>(null)
  const [showCompare, setShowCompare] = useState(false)

  const load = useCallback(() => fetch(base + '/' + id + '/publish-center', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])

  const loadPreview = async (mode: string) => {
    setPreviewMode(mode)
    const d = await fetch(base + '/' + id + '/publish-center/preview?mode=' + mode, { headers: authHeaders }).then(r => r.json()).catch(() => null)
    setPreview(d?.preview || null)
    setShowPreview(true)
    if (isMobile) setPreviewDrawer(true)
  }

  const runSimulateEnroll = async () => {
    const d = await fetch(base + '/' + id + '/publish-center/simulate-enroll', { method: 'POST', headers: authHeaders }).then(r => r.json()).catch(() => null)
    setSimResult(d)
  }

  const act = async (path: string, method: string, body?: any, okMsg?: string) => {
    setBusy(true)
    try {
      const r = await fetch(base + '/' + id + '/publish-center/' + path, { method, headers: authHeaders, body: body ? JSON.stringify(body) : undefined })
      const d = await r.json()
      if (!r.ok) { showToast('⚠️ ' + (d.error || d.message || 'Action failed')); setBusy(false); return d }
      showToast(okMsg || '✅ Done')
      await load(); loadParent && loadParent()
      setBusy(false)
      return d
    } catch (e) { showToast('⚠️ Network error'); setBusy(false); return null }
  }

  const doPublish = () => act('publish', 'PUT', { notes }, '🚀 Published successfully')
  const doRepublish = () => act('republish', 'PUT', { notes }, '🚀 Republished successfully')
  const doUnpublish = async () => {
    if (!unpublishReason.trim()) return showToast('⚠️ Reason is required')
    await act('unpublish', 'PUT', { reason: unpublishReason }, '⛔ Unpublished'); setShowUnpublishBox(false); setUnpublishReason('')
  }
  const doArchive = () => { if (!window.confirm('Archive this batch? It will be hidden from marketplace and moved to Archived.')) return; act('archive', 'PUT', { reason: 'Archived from Publish Center' }, '📦 Archived') }
  const doRestoreDraft = () => { if (!window.confirm('Restore to Draft? This will keep it unpublished for further editing.')) return; act('restore-draft', 'PUT', {}, '📝 Restored to Draft') }
  const doSchedule = async () => {
    if (!sched.publishAt) return showToast('⚠️ Select publish date & time')
    const iso = new Date(sched.publishAt).toISOString()
    await act('schedule', 'PUT', { publishAt: iso, timezone: sched.timezone, autoActivate: sched.autoActivate, autoUnpublishAt: sched.autoUnpublishAt ? new Date(sched.autoUnpublishAt).toISOString() : null }, '📅 Publish scheduled')
    setShowSchedule(false)
  }
  const doCancelSchedule = () => act('schedule/cancel', 'PUT', {}, '✅ Scheduled publish cancelled')
  const doIgnoreIssue = (key: string) => act('ignore-issue', 'PUT', { key }, '✅ Issue marked as ignored')
  const doUnignoreIssue = (key: string) => act('ignore-issue/' + key, 'DELETE', undefined, '↩️ Un-ignored')

  const doRollback = async (force?: boolean) => {
    if (!rollbackReason.trim()) return showToast('⚠️ Reason is mandatory for rollback')
    if (!force && !window.confirm(`Rollback to version ${rollbackFor.version}? This will overwrite current draft/live data.`)) return
    const body: any = { toVersion: rollbackFor.version, reason: rollbackReason, scope: rollbackScope, sections: rollbackSections }
    if (force) body.confirmLiveImpact = true
    const r = await act('rollback', 'POST', body, '↩️ Rolled back to v' + rollbackFor.version)
    if (r && r.warning === 'live_students_affected') { setRollbackWarning(r); return }
    setRollbackFor(null); setRollbackReason(''); setRollbackSections([]); setRollbackWarning(null)
  }

  const loadCompare = async () => {
    if (!compareFrom || !compareTo) return showToast('⚠️ Select both versions')
    const d = await fetch(base + '/' + id + '/publish-center/compare?from=' + compareFrom + '&to=' + compareTo, { headers: authHeaders }).then(r => r.json()).catch(() => null)
    setCompareResult(d)
  }

  const jumpToSection = (section: string) => { if (section && setParentTab) setParentTab(section) }
  const downloadLog = () => { window.open(base + '/' + id + '/publish-center/history/export', '_blank') }

  if (!data) return <EmptyMsg text="⟳ Loading Publish Center…" />
  const s = data.summary
  const scoreColor = s.readinessScore >= 95 ? GOOD : s.readinessScore >= 80 ? ACC : s.readinessScore >= 50 ? WARN : BAD
  const stateColor: any = { draft: DIM, ready: ACC, scheduled: WARN, published: GOOD, unpublished: BAD, republish_pending: WARN, blocked: BAD }
  const hardBlocking = (data.blockingIssues || []).filter((b: any) => !b.ignorable)
  const softBlocking = (data.blockingIssues || []).filter((b: any) => b.ignorable)

  const SummaryCards = () => (
    <div style={{ ...cs, display: 'grid', gridTemplateColumns: isMobile ? 'repeat(2,1fr)' : 'repeat(6,1fr)', gap: 10 }}>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setChecklistOpen(true)}>
        <div style={{ fontSize: 22, fontWeight: 800, color: scoreColor }}>{s.readinessScore}%</div>
        <div style={{ fontSize: 9, color: DIM }}>READINESS · {s.scoreStatus}</div>
      </div>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setStateInfoOpen(!stateInfoOpen)}>
        <div style={{ fontSize: 14, fontWeight: 800, color: stateColor[s.publishStatus] || TS, textTransform: 'capitalize' }}>{(s.publishStatus || 'draft').replace('_', ' ')}</div>
        <div style={{ fontSize: 9, color: DIM }}>PUBLISH STATUS ℹ️</div>
      </div>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setHistoryOpen(true)}>
        <div style={{ fontSize: 20, fontWeight: 800, color: '#7DD3FC' }}>v{s.publishVersion}</div>
        <div style={{ fontSize: 9, color: DIM }}>VERSION</div>
      </div>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setHistoryOpen(true)}>
        <div style={{ fontSize: 12, fontWeight: 700, color: TS }}>{s.lastPublished ? new Date(s.lastPublished).toLocaleDateString() : '—'}</div>
        <div style={{ fontSize: 9, color: DIM }}>LAST PUBLISHED</div>
      </div>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 14, fontWeight: 800, color: s.draftChangesPending ? WARN : GOOD }}>{s.draftChangesPending ? 'Pending' : 'None'}</div>
        <div style={{ fontSize: 9, color: DIM }}>DRAFT CHANGES</div>
      </div>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setChecklistOpen(true)}>
        <div style={{ fontSize: 20, fontWeight: 800, color: s.blockingIssuesCount > 0 ? BAD : GOOD }}>{s.blockingIssuesCount}{s.ignorableIssuesCount > 0 ? <span style={{ fontSize: 10, color: WARN }}> +{s.ignorableIssuesCount}</span> : ''}</div>
        <div style={{ fontSize: 9, color: DIM }}>BLOCKING ISSUES</div>
      </div>
      {stateInfoOpen && <div style={{ gridColumn: isMobile ? 'span 2' : 'span 6', fontSize: 11.5, color: DIM, background: 'rgba(0,22,40,0.6)', borderRadius: 8, padding: 8, marginTop: 4 }}>ℹ️ {s.publishStatusMeaning}</div>}
    </div>
  )

  const ChecklistPanel = () => (
    <div style={cs}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: isMobile ? 'pointer' : 'default' }} onClick={() => isMobile && setChecklistOpen(!checklistOpen)}>
        <div style={{ fontWeight: 700, color: TS, marginBottom: checklistOpen ? 10 : 0 }}>✅ Pre-Publish Checklist</div>
        {isMobile && <span style={{ color: DIM }}>{checklistOpen ? '▲' : '▼'}</span>}
      </div>
      {checklistOpen && <>
        <div style={{ fontSize: 10.5, color: DIM, marginBottom: 6, textTransform: 'uppercase', fontWeight: 700 }}>Mandatory</div>
        {data.checklist.mandatory.map((m: any) => (
          <div key={m.key} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 0', borderBottom: `1px solid ${BOR}`, gap: 6 }}>
            <div style={{ fontSize: 12.5, color: m.done ? TS : (m.ignorable ? WARN : BAD), flex: 1 }}>{m.done ? '✅' : (m.ignorable ? '🟡' : '🔴')} {m.label}{!m.done && <div style={{ fontSize: 10, color: DIM }}>{m.reason}</div>}</div>
            {!m.done && <div style={{ display: 'flex', gap: 4, flexShrink: 0 }}>
              <button style={{ ...bs, fontSize: 10, padding: '3px 8px' }} onClick={() => jumpToSection(m.section)}>Fix Now</button>
              {m.ignorable && <button style={{ ...bs, fontSize: 10, padding: '3px 8px' }} onClick={() => doIgnoreIssue(m.key)}>Ignore</button>}
            </div>}
          </div>
        ))}
        <div style={{ fontSize: 10.5, color: DIM, margin: '10px 0 6px', textTransform: 'uppercase', fontWeight: 700 }}>Optional</div>
        {data.checklist.optional.map((o: any) => (
          <div key={o.key} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '5px 0' }}>
            <div style={{ fontSize: 12, color: o.done ? '#7DD3FC' : DIM }}>{o.done ? '☑️' : '⬜'} {o.label}</div>
            {o.count !== undefined && <span style={{ fontSize: 10, color: DIM }}>{o.count}</span>}
          </div>
        ))}
        <button style={{ ...bs, marginTop: 10, width: '100%' }} onClick={load}>🔄 Recheck Readiness</button>
      </>}
    </div>
  )

  const BlockingPanel = () => hardBlocking.length === 0 && softBlocking.length === 0 ? null : (
    <div style={{ ...cs, border: `1px solid rgba(239,68,68,0.35)` }}>
      <div style={{ fontWeight: 700, color: BAD, marginBottom: 8 }}>🚫 Blocking Issues ({hardBlocking.length}{softBlocking.length > 0 ? ' + ' + softBlocking.length + ' ignorable' : ''})</div>
      {hardBlocking.map((b: any) => (
        <div key={b.key} style={{ fontSize: 12, color: TS, padding: '4px 0', display: 'flex', justifyContent: 'space-between', gap: 6 }}>
          <span>• {b.message}</span>
          <button style={{ ...bs, fontSize: 10, padding: '3px 8px', flexShrink: 0 }} onClick={() => jumpToSection(b.section)}>Open Section</button>
        </div>
      ))}
      {softBlocking.map((b: any) => (
        <div key={b.key} style={{ fontSize: 12, color: WARN, padding: '4px 0', display: 'flex', justifyContent: 'space-between', gap: 6 }}>
          <span>• {b.message}</span>
          <button style={{ ...bs, fontSize: 10, padding: '3px 8px', flexShrink: 0 }} onClick={() => doIgnoreIssue(b.key)}>Ignore</button>
        </div>
      ))}
      <button style={{ ...bs, marginTop: 8, width: '100%' }} onClick={load}>🔄 Recheck</button>
    </div>
  )

  const IgnoredPanel = () => (data.checklist.mandatory.filter((m: any) => m.ignorable && data.summary && (data.checklist.mandatory.find((x: any) => x.key === m.key)?.done) && (data as any).ignoredKeys?.includes?.(m.key)).length === 0) ? null : null

  const PreviewContent = () => (
    <>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
        {['marketplace', 'card', 'detail', 'mybatches', 'mobile', 'desktop'].map(m => (
          <button key={m} style={previewMode === m && showPreview ? bp : bs} onClick={() => loadPreview(m)}>{m === 'marketplace' ? '🏪 Marketplace' : m === 'card' ? '🃏 Card' : m === 'detail' ? '📄 Detail' : m === 'mybatches' ? '📚 My Batches' : m === 'mobile' ? '📱 Mobile' : '🖥️ Desktop'}</button>
        ))}
      </div>
      {showPreview && preview && (
        <div style={{ background: 'rgba(0,22,40,0.85)', border: `1px solid ${BOR2}`, borderRadius: 12, padding: 14, maxWidth: previewMode === 'mobile' ? 260 : '100%', margin: previewMode === 'mobile' ? '0 auto' : 0 }}>
          {preview.banner?.bgImage && <div style={{ height: 90, borderRadius: 8, marginBottom: 8, background: `linear-gradient(135deg,${preview.banner.primaryColor || '#4D9FFF'},#00263F) center/cover` }} />}
          <div style={{ fontWeight: 800, fontSize: 14, color: '#93C5FD' }}>{preview.title}</div>
          {preview.banner?.tagline && <div style={{ fontSize: 11, color: DIM }}>{preview.banner.tagline}</div>}
          <div style={{ display: 'flex', gap: 6, margin: '8px 0', flexWrap: 'wrap' }}>
            {preview.offerBadges?.map((b: string) => <span key={b} style={chip(ACC, 'rgba(77,159,255,0.1)')}>{b}</span>)}
          </div>
          <div style={{ fontSize: 16, fontWeight: 800, color: GOOD }}>₹{preview.effectivePrice}{preview.discountPct > 0 && <span style={{ fontSize: 11, color: DIM, marginLeft: 6, textDecoration: 'line-through' }}>₹{preview.price}</span>}{preview.discountPct > 0 && <span style={{ fontSize: 10, color: WARN, marginLeft: 6 }}>{preview.discountPct}% OFF</span>}</div>
          <div style={{ fontSize: 11, color: DIM, marginTop: 4 }}>📝 {preview.examsSummary?.count || 0} Exams · ⏳ {preview.validity} days validity · 🔓 {preview.enrollmentState}</div>
          <button style={{ ...bp, marginTop: 10, width: '100%' }} onClick={runSimulateEnroll}>{preview.cta} (Simulate)</button>
          {simResult && (
            <div style={{ marginTop: 10, background: 'rgba(52,211,153,0.08)', borderRadius: 8, padding: 8 }}>
              {simResult.steps?.map((st: any, i: number) => <div key={i} style={{ fontSize: 11, color: GOOD }}>✓ {st.step}</div>)}
              <div style={{ fontSize: 10, color: DIM, marginTop: 4 }}>{simResult.note}</div>
            </div>
          )}
        </div>
      )}
      {!showPreview && <div style={{ fontSize: 11.5, color: DIM }}>Select a preview mode to see exactly what students will see before you publish.</div>}
    </>
  )

  const PreviewPanel = () => (
    <div style={cs}>
      <div style={{ fontWeight: 700, color: TS, marginBottom: 8 }}>👁 Student Preview</div>
      <PreviewContent />
    </div>
  )

  const PostPublishPanel = () => !data.postPublishChecks ? null : (
    <div style={cs}>
      <div style={{ fontWeight: 700, color: TS, marginBottom: 8 }}>📡 Post-Publish Status — <span style={{ color: GOOD }}>{data.postPublishChecks.state}</span></div>
      <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr 1fr' : 'repeat(4,1fr)', gap: 8 }}>
        {[['Visible in Marketplace', data.postPublishChecks.visibleInMarketplace], ['Banner Loaded', data.postPublishChecks.bannerLoaded], ['Exams Accessible', data.postPublishChecks.examsAccessible],
        ['Coupons Active', data.postPublishChecks.couponsActive], ['Controls Applied', data.postPublishChecks.controlsApplied], ['Searchable', data.postPublishChecks.searchable],
        ['Notifications On', data.postPublishChecks.notificationEnabled], ['Launch Status Updated', data.postPublishChecks.launchStatusUpdated]].map(([l, v]: any) => (
          <div key={l as string} style={{ fontSize: 11, color: v ? GOOD : DIM }}>{v ? '✅' : '⬜'} {l}</div>
        ))}
      </div>
    </div>
  )

  const EditLockPanel = () => !data.editLock?.active ? null : (
    <div style={{ ...cs, border: `1px solid rgba(251,191,36,0.3)` }}>
      <div style={{ fontWeight: 700, color: WARN, marginBottom: 4 }}>🔒 Edit Lock Active</div>
      <div style={{ fontSize: 11.5, color: DIM }}>Critical fields are locked while Published/Scheduled: {data.editLock.fields.join(', ')}. Unpublish to edit them, or use Rollback for controlled changes.</div>
    </div>
  )

  const ActionsPanel = () => (
    <div style={cs}>
      <div style={{ fontWeight: 700, color: TS, marginBottom: 10 }}>🚀 Publish Actions</div>
      <textarea style={{ ...inp, minHeight: 50, marginBottom: 8 }} placeholder="Notes for this publish (optional)" value={notes} onChange={e => setNotes(e.target.value)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {!data.isPublished ? (
          <button style={bp} disabled={busy || hardBlocking.length > 0} onClick={doPublish}>🚀 Publish{hardBlocking.length > 0 ? ' (Blocked)' : ''}</button>
        ) : (
          <button style={bp} disabled={busy || hardBlocking.length > 0} onClick={doRepublish}>🔁 Republish{s.draftChangesPending ? ' (Changes Pending)' : ''}</button>
        )}
        {data.isPublished && !showUnpublishBox && <button style={bd} disabled={busy} onClick={() => setShowUnpublishBox(true)}>⛔ Unpublish</button>}
        {showUnpublishBox && (
          <div>
            <textarea style={{ ...inp, minHeight: 50, marginBottom: 6 }} placeholder="Reason for unpublishing (required)" value={unpublishReason} onChange={e => setUnpublishReason(e.target.value)} />
            <div style={{ display: 'flex', gap: 8 }}>
              <button style={{ ...bd, flex: 1 }} onClick={doUnpublish}>Confirm Unpublish</button>
              <button style={{ ...bs, flex: 1 }} onClick={() => setShowUnpublishBox(false)}>Cancel</button>
            </div>
          </div>
        )}
        {!showSchedule ? (
          <button style={bs} disabled={busy} onClick={() => setShowSchedule(true)}>📅 Schedule Publish</button>
        ) : (
          <div style={{ background: 'rgba(0,22,40,0.6)', borderRadius: 10, padding: 10 }}>
            <label style={lbl}>Publish Date & Time</label>
            <input style={{ ...inp, marginBottom: 8 }} type="datetime-local" value={sched.publishAt} onChange={e => setSched({ ...sched, publishAt: e.target.value })} />
            <label style={lbl}>Timezone</label>
            <input style={{ ...inp, marginBottom: 8 }} value={sched.timezone} onChange={e => setSched({ ...sched, timezone: e.target.value })} />
            <div style={{ marginBottom: 8 }}><Toggle on={sched.autoActivate} onChange={(v: boolean) => setSched({ ...sched, autoActivate: v })} label="Auto-activate at publish time" /></div>
            <label style={lbl}>Auto-Unpublish At (optional)</label>
            <input style={{ ...inp, marginBottom: 8 }} type="datetime-local" value={sched.autoUnpublishAt} onChange={e => setSched({ ...sched, autoUnpublishAt: e.target.value })} />
            <div style={{ display: 'flex', gap: 8 }}>
              <button style={{ ...bp, flex: 1 }} onClick={doSchedule}>Confirm Schedule</button>
              <button style={{ ...bs, flex: 1 }} onClick={() => setShowSchedule(false)}>Cancel</button>
            </div>
          </div>
        )}
        {data.scheduled.isScheduleActive && (
          <div style={{ fontSize: 11.5, color: WARN, background: 'rgba(251,191,36,0.08)', borderRadius: 8, padding: 8 }}>
            ⏳ Scheduled for {new Date(data.scheduled.scheduledPublishAt).toLocaleString()} ({data.scheduled.scheduledPublishTimezone}) — auto-publishes via background scheduler.
            <button style={{ ...bd, marginTop: 6, width: '100%' }} onClick={doCancelSchedule}>Cancel Scheduled Publish</button>
          </div>
        )}
        <button style={bs} disabled={busy} onClick={doArchive}>🗄️ Archive</button>
        <button style={bs} disabled={busy} onClick={doRestoreDraft}>📝 Restore as Draft</button>
      </div>
    </div>
  )

  const HistoryPanel = () => (
    <div style={cs}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: isMobile ? 'pointer' : 'default' }} onClick={() => isMobile && setHistoryOpen(!historyOpen)}>
        <div style={{ fontWeight: 700, color: TS }}>🕐 Publish History</div>
        <div style={{ display: 'flex', gap: 6 }}>
          {!isMobile && data.history.length > 0 && <button style={{ ...bs, fontSize: 10.5, padding: '4px 8px' }} onClick={(e) => { e.stopPropagation(); setShowCompare(!showCompare) }}>⚖️ Compare</button>}
          {data.history.length > 0 && <button style={{ ...bs, fontSize: 10.5, padding: '4px 8px' }} onClick={(e) => { e.stopPropagation(); downloadLog() }}>⬇️ Log</button>}
          {isMobile && <span style={{ color: DIM }}>{historyOpen ? '▲' : '▼'}</span>}
        </div>
      </div>
      {showCompare && (
        <div style={{ background: 'rgba(0,22,40,0.6)', borderRadius: 8, padding: 8, margin: '8px 0' }}>
          <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
            <select style={inp} value={compareFrom} onChange={e => setCompareFrom(e.target.value)}><option value="">From v...</option>{data.history.map((h: any) => <option key={h.version} value={h.version}>v{h.version}</option>)}</select>
            <select style={inp} value={compareTo} onChange={e => setCompareTo(e.target.value)}><option value="">To v...</option>{data.history.map((h: any) => <option key={h.version} value={h.version}>v{h.version}</option>)}</select>
          </div>
          <button style={{ ...bs, width: '100%' }} onClick={loadCompare}>Compare</button>
          {compareResult && !compareResult.error && (
            <div style={{ marginTop: 8 }}>
              {compareResult.diff.length === 0 ? <div style={{ fontSize: 11, color: DIM }}>No differences.</div> : compareResult.diff.map((d: any, i: number) => (
                <div key={i} style={{ fontSize: 11, color: TS, padding: '3px 0', borderBottom: `1px solid ${BOR}` }}>
                  <b>{d.field}</b>: <span style={{ color: BAD }}>{JSON.stringify(d.from)}</span> → <span style={{ color: GOOD }}>{JSON.stringify(d.to)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
      {historyOpen && (data.history.length === 0 ? <EmptyMsg text="No publish history yet." /> : (
        <div style={{ marginTop: 8 }}>
          {data.history.map((h: any, i: number) => (
            <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div style={{ color: TS, fontWeight: 700, fontSize: 12.5 }}>v{h.version} · {h.action}</div>
                <div style={{ color: DIM, fontSize: 10.5 }}>{new Date(h.publishedAt).toLocaleString()}</div>
              </div>
              <div style={{ color: DIM, fontSize: 11 }}>by {h.publishedBy} · {h.status}{h.notes ? ' · ' + h.notes : ''}{h.reason ? ' · reason: ' + h.reason : ''}</div>
              <div style={{ color: DIM, fontSize: 10 }}>id: {h.snapshotId}</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                <button style={{ ...bs, fontSize: 10.5, padding: '4px 8px' }} onClick={() => { setRollbackFor(h); setRollbackScope('full'); setRollbackSections([]) }}>↩️ Rollback to this</button>
              </div>
            </div>
          ))}
        </div>
      ))}
    </div>
  )

  const RollbackModal = () => !rollbackFor ? null : (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={() => { setRollbackFor(null); setRollbackWarning(null) }}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 440, width: '100%', border: `1px solid ${BOR2}`, maxHeight: '85vh', overflowY: 'auto' }} onClick={e => e.stopPropagation()}>
        <div style={{ fontWeight: 700, color: TS, marginBottom: 10 }}>↩️ Rollback to v{rollbackFor.version}</div>
        {rollbackWarning && (
          <div style={{ background: 'rgba(251,191,36,0.1)', border: `1px solid ${WARN}`, borderRadius: 8, padding: 10, marginBottom: 10, fontSize: 12, color: WARN }}>
            ⚠️ {rollbackWarning.message}
          </div>
        )}
        <label style={lbl}>Scope</label>
        <select style={{ ...inp, marginBottom: 10 }} value={rollbackScope} onChange={e => setRollbackScope(e.target.value)}>
          <option value="full">Rollback & Republish (Full)</option>
          <option value="draft_only">Restore as Draft only</option>
        </select>
        <label style={lbl}>Restore Sections (leave empty = all)</label>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 10 }}>
          {['basicInfo', 'pricing', 'banner', 'dates', 'controls', 'other'].map(sec => (
            <button key={sec} style={rollbackSections.includes(sec) ? bp : bs} onClick={() => setRollbackSections(rollbackSections.includes(sec) ? rollbackSections.filter(s2 => s2 !== sec) : [...rollbackSections, sec])}>{sec}</button>
          ))}
        </div>
        <label style={lbl}>Reason (mandatory)</label>
        <textarea style={{ ...inp, minHeight: 60, marginBottom: 12 }} value={rollbackReason} onChange={e => setRollbackReason(e.target.value)} placeholder="Why are you rolling back?" />
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{ ...bs, flex: 1 }} onClick={() => { setRollbackFor(null); setRollbackWarning(null) }}>Cancel</button>
          <button style={{ ...bd, flex: 1 }} onClick={() => doRollback(!!rollbackWarning)}>{rollbackWarning ? 'Confirm Anyway' : 'Confirm Rollback'}</button>
        </div>
      </div>
    </div>
  )

  const MobilePreviewDrawer = () => !previewDrawer ? null : (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.85)', zIndex: 998, display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: 12, borderBottom: `1px solid ${BOR}` }}>
        <div style={{ color: TS, fontWeight: 700 }}>👁 Student Preview</div>
        <button style={bs} onClick={() => setPreviewDrawer(false)}>✕ Close</button>
      </div>
      <div style={{ padding: 14, overflowY: 'auto', flex: 1 }}><PreviewContent /></div>
    </div>
  )

  if (isMobile) {
    return (
      <div style={{ paddingBottom: 70 }}>
        <SummaryCards />
        <ChecklistPanel />
        <BlockingPanel />
        <EditLockPanel />
        <PostPublishPanel />
        <HistoryPanel />
        <div style={{ position: 'fixed', left: 0, right: 0, bottom: 0, background: CRD2, borderTop: `1px solid ${BOR2}`, padding: 10, zIndex: 50, display: 'flex', gap: 8 }}>
          {!data.isPublished
            ? <button style={{ ...bp, flex: 1 }} disabled={busy || hardBlocking.length > 0} onClick={doPublish}>🚀 Publish</button>
            : <button style={{ ...bp, flex: 1 }} disabled={busy || hardBlocking.length > 0} onClick={doRepublish}>🔁 Republish</button>}
          <button style={{ ...bs, flex: 1 }} onClick={() => loadPreview(previewMode)}>👁 Preview</button>
          <button style={{ ...bs, flex: 1 }} onClick={() => setShowSchedule(true)}>📅</button>
        </div>
        {showSchedule && <ActionsPanel />}
        <MobilePreviewDrawer />
        <RollbackModal />
      </div>
    )
  }

  return (
    <div>
      <SummaryCards />
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.3fr 1fr', gap: 14, alignItems: 'start' }}>
        <div>
          <ChecklistPanel />
          <BlockingPanel />
          <EditLockPanel />
        </div>
        <div>
          <PreviewPanel />
          <PostPublishPanel />
        </div>
        <div>
          <ActionsPanel />
          <HistoryPanel />
        </div>
      </div>
      <RollbackModal />
    </div>
  )
}

PUBTABV2_EOF

# 9) Node patcher v2 (anchor-based, upgrades v1 in place)
cat > "$STAGE/patch-publish-center-v2.cjs" << 'PATCHERV2_EOF'
// ProveRank — Publish Center v2 installer (anchor-based, upgrades v1 in place)
const fs = require('fs');
const path = require('path');

const ROOT = process.env.WORKSPACE_ROOT || process.cwd();
const STAGE = __dirname;

let failures = 0;
let skipped = 0;

function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, c) { fs.writeFileSync(p, c, 'utf8'); }
function stage(name) { return read(path.join(STAGE, name)); }

function patchFile(label, filePath, alreadyMarker, requireMarker, steps) {
  console.log('\n── ' + label + ' (' + filePath + ') ──');
  if (!fs.existsSync(filePath)) { console.log('  ✗ SKIPPED — file not found at this path.'); failures++; return; }
  let content = read(filePath);
  if (alreadyMarker && content.includes(alreadyMarker)) {
    console.log('  ⏭  Already on v2 — skipping (idempotent).');
    skipped++;
    return;
  }
  if (requireMarker && !content.includes(requireMarker)) {
    console.log('  ✗ v1 NOT FOUND — please run publish_center_install_v1.sh first, then re-run this.');
    failures++;
    return;
  }
  let ok = true;
  for (const step of steps) {
    const result = step(content);
    if (result === null) {
      console.log('  ✗ ANCHOR NOT FOUND: ' + step.name + ' — this file may already be modified differently.');
      console.log('    Please share this file again so the patch can be adjusted manually.');
      ok = false;
      break;
    }
    content = result;
  }
  if (!ok) { failures++; return; }
  write(filePath, content);
  console.log('  ✅ Patched successfully.');
}

// ══════════════════════════════════════════════════════════════
// 1) Batch.js model — add pre-save hook (edit lock + draft-changes-pending)
// ══════════════════════════════════════════════════════════════
patchFile('Batch.js model — edit lock + draft-changes hook', path.join(ROOT, 'src/models/Batch.js'), 'Publish Center v2: Edit Lock', 'Publish Center (Go-Live', [
  function insertHook(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const insertPos = m.index + m[0].length;
    const hook = stage('batch_model_hooks.txt');
    return content.slice(0, insertPos) + hook + content.slice(insertPos);
  }
]);

// ══════════════════════════════════════════════════════════════
// 2) TestSeries.js model — add pre-save hook
// ══════════════════════════════════════════════════════════════
patchFile('TestSeries.js model — edit lock + draft-changes hook', path.join(ROOT, 'src/models/TestSeries.js'), 'Publish Center v2: Edit Lock', 'Publish Center (Go-Live', [
  function insertHook(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const insertPos = m.index + m[0].length;
    const hook = stage('testseries_model_hooks.txt');
    return content.slice(0, insertPos) + hook + content.slice(insertPos);
  }
]);

// ══════════════════════════════════════════════════════════════
// 3) BatchAuditLog.js — add reason + snapshotVersion fields
// ══════════════════════════════════════════════════════════════
patchFile('BatchAuditLog.js model — reason/snapshotVersion fields', path.join(ROOT, 'src/models/BatchAuditLog.js'), 'snapshotVersion', null, [
  function insertFields(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const fields = stage('auditlog_fields.txt');
    return content.slice(0, m.index) + fields + content.slice(m.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 4) TestSeriesAuditLog.js — add reason + snapshotVersion fields
// ══════════════════════════════════════════════════════════════
patchFile('TestSeriesAuditLog.js model — reason/snapshotVersion fields', path.join(ROOT, 'src/models/TestSeriesAuditLog.js'), 'snapshotVersion', null, [
  function insertFields(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const fields = stage('auditlog_fields.txt');
    return content.slice(0, m.index) + fields + content.slice(m.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 5) batchManagerUltra.js — replace logAudit() + replace v1 Publish Center block with v2
// ══════════════════════════════════════════════════════════════
patchFile('batchManagerUltra.js routes → v2', path.join(ROOT, 'src/routes/batchManagerUltra.js'), '[v2]', 'PUBLISH CENTER — Go-Live Control Center', [
  function replaceLogAudit(content) {
    const re = /async function logAudit\(\{ batchId, field, oldValue, newValue, changedBy, changedByName, action, source \}\) \{[\s\S]*?\n\}\n/;
    const m = content.match(re);
    if (!m) return null;
    return content.slice(0, m.index) + stage('logaudit_patch_batch.txt') + '\n' + content.slice(m.index + m[0].length);
  },
  function replaceBlock(content) {
    const startRe = /\n\/\/ ══+\n\/\/ 16\) PUBLISH CENTER[\s\S]*?\n\/\/ ══+\n/;
    const startM = content.match(startRe);
    const endRe = /\nmodule\.exports\s*=\s*router\s*;\s*$/;
    const endM = content.match(endRe);
    if (!startM || !endM) return null;
    const v2block = stage('publish_center_batch_v2.js');
    return content.slice(0, startM.index) + '\n' + v2block + '\n' + content.slice(endM.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 6) testSeriesManagerUltra.js — replace logAudit() + replace v1 block with v2
// ══════════════════════════════════════════════════════════════
patchFile('testSeriesManagerUltra.js routes → v2', path.join(ROOT, 'src/routes/testSeriesManagerUltra.js'), '[v2]', 'PUBLISH CENTER — Go-Live Control Center', [
  function replaceLogAudit(content) {
    const re = /async function logAudit\(\{ seriesId, field, oldValue, newValue, changedBy, changedByName, action, source \}\) \{[\s\S]*?\n\}\n/;
    const m = content.match(re);
    if (!m) return null;
    return content.slice(0, m.index) + stage('logaudit_patch_series.txt') + '\n' + content.slice(m.index + m[0].length);
  },
  function replaceBlock(content) {
    const startRe = /\n\/\/ ══+\n\/\/ 16\) PUBLISH CENTER[\s\S]*?\n\/\/ ══+\n/;
    const startM = content.match(startRe);
    const endRe = /\nmodule\.exports\s*=\s*router\s*;\s*$/;
    const endM = content.match(endRe);
    if (!startM || !endM) return null;
    const v2block = stage('publish_center_series_v2.js');
    return content.slice(0, startM.index) + '\n' + v2block + '\n' + content.slice(endM.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 7) BatchManagerUltra.tsx — replace v1 tab component with v2 + pass setParentTab
// ══════════════════════════════════════════════════════════════
patchFile('BatchManagerUltra.tsx → v2', path.join(ROOT, 'frontend/app/admin/x7k2p/BatchManagerUltra.tsx'), '[v2]', 'PUBLISH CENTER TAB', [
  function updateRenderLine(content) {
    const re = /\{tab === 'publish' && <PublishCenterTab[^\n]*\/>\}/;
    const m = content.match(re);
    if (!m) return null;
    const line = "{tab === 'publish' && <PublishCenterTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} setParentTab={setTab} />}";
    return content.slice(0, m.index) + line + content.slice(m.index + m[0].length);
  },
  function replaceComponent(content) {
    const startRe = /\n\/\/ ── 16\) PUBLISH CENTER TAB[\s\S]*?\nfunction PublishCenterTab\(/;
    const startM = content.match(startRe);
    const endRe = /\nfunction AuditTab\(/;
    const endM = content.match(endRe);
    if (!startM || !endM) return null;
    // find the start of the comment line, not the function keyword offset
    const blockStart = content.lastIndexOf('\n// ── 16) PUBLISH CENTER TAB', startM.index + startM[0].length);
    const v2comp = stage('publish_center_tab_v2.tsx');
    return content.slice(0, blockStart) + '\n' + v2comp + content.slice(endM.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 8) TestSeriesManagerUltra.tsx — replace v1 tab component with v2 + pass setParentTab
// ══════════════════════════════════════════════════════════════
patchFile('TestSeriesManagerUltra.tsx → v2', path.join(ROOT, 'frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx'), '[v2]', 'PUBLISH CENTER TAB', [
  function updateRenderLine(content) {
    const re = /\{tab === 'publish' && <PublishCenterTab[^\n]*\/>\}/;
    const m = content.match(re);
    if (!m) return null;
    const line = "{tab === 'publish' && <PublishCenterTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} setParentTab={setTab} />}";
    return content.slice(0, m.index) + line + content.slice(m.index + m[0].length);
  },
  function replaceComponent(content) {
    const startRe = /\n\/\/ ── 16\) PUBLISH CENTER TAB[\s\S]*?\nfunction PublishCenterTab\(/;
    const startM = content.match(startRe);
    const endRe = /\nfunction AuditTab\(/;
    const endM = content.match(endRe);
    if (!startM || !endM) return null;
    const blockStart = content.lastIndexOf('\n// ── 16) PUBLISH CENTER TAB', startM.index + startM[0].length);
    const v2comp = stage('publish_center_tab_v2.tsx');
    return content.slice(0, blockStart) + '\n' + v2comp + content.slice(endM.index);
  }
]);

console.log('\n══════════════════════════════════════════');
if (failures > 0) {
  console.log('⚠️  ' + failures + ' file(s) could NOT be patched automatically. Please re-share those files.');
  process.exitCode = 1;
} else {
  console.log('✅ Publish Center v2 installed (' + (8 - skipped - failures) + ' file(s) patched, ' + skipped + ' already up to date).');
}

PATCHERV2_EOF

echo ""
echo "Running v2 installer..."
WORKSPACE_ROOT=~/workspace node "$STAGE/patch-publish-center-v2.cjs"
INSTALL_STATUS=$?

echo ""
echo "Syntax-checking backend files..."
node -c ~/workspace/src/models/Batch.js && echo "  OK: src/models/Batch.js"
node -c ~/workspace/src/models/TestSeries.js && echo "  OK: src/models/TestSeries.js"
node -c ~/workspace/src/models/BatchAuditLog.js && echo "  OK: src/models/BatchAuditLog.js"
node -c ~/workspace/src/models/TestSeriesAuditLog.js && echo "  OK: src/models/TestSeriesAuditLog.js"
node -c ~/workspace/src/routes/batchManagerUltra.js && echo "  OK: src/routes/batchManagerUltra.js"
node -c ~/workspace/src/routes/testSeriesManagerUltra.js && echo "  OK: src/routes/testSeriesManagerUltra.js"

rm -rf "$STAGE"

if [ "$INSTALL_STATUS" -eq 0 ]; then
  echo ""
  echo "DONE -- Publish Center v2 installed:"
  echo " - Scheduler automation (auto publish/unpublish at scheduled time, checks every 60s)"
  echo " - Effective status sync (Ready to Publish / Blocked auto-computed)"
  echo " - Draft-Changes-Pending auto-detected on any edit while live"
  echo " - Edit Lock on critical fields (examType, price, discountPrice, dates) while published/scheduled"
  echo " - Ignore optional issue button (Coupons / Controls)"
  echo " - Date range + schedule-conflict + control-mismatch checklist checks"
  echo " - Fuller snapshots (banner, coupons, exams, materials, announcements)"
  echo " - Compare versions, Download publish log, Restore-selected-section rollback, Live-student rollback warning"
  echo " - My Batches preview mode + Simulated enrollment flow + full-screen mobile preview drawer"
  echo " - Live with Scheduled Exams post-publish state"
  echo " - Publish Status card click -> state meaning info"
  echo " - Full audit trail with reason + snapshot reference"
  echo "Ab server restart karo: pkill -f \"node src/index.js\" 2>/dev/null; cd ~/workspace && node src/index.js"
else
  echo ""
  echo "WARNING -- kuch file(s) auto-patch nahi ho payi, upar dekho kaunsi, aur wo file dobara share karo."
fi
