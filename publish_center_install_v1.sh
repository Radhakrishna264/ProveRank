#!/bin/bash
set -e
echo "ProveRank -- Publish Center (Go-Live Control Center) Installer"
cd ~/workspace
STAGE=~/workspace/.proverank-publish-center-stage
mkdir -p "$STAGE"

# 1) Batch.js model fields
cat > "$STAGE/batch_model_fields.txt" << 'BATCHFIELDS_EOF'

  // ── Publish Center (Go-Live Control Center) ──
  isPublished:{type:Boolean,default:true},
  publishState:{type:String,default:'draft',enum:['draft','ready','scheduled','published','unpublished','republish_pending','blocked']},
  publishVersion:{type:Number,default:0},
  lastPublishedAt:{type:Date,default:null},
  lastPublishedBy:{type:String,default:''},
  scheduledPublishAt:{type:Date,default:null},
  scheduledPublishTimezone:{type:String,default:'Asia/Kolkata'},
  scheduledAutoActivate:{type:Boolean,default:true},
  scheduledAutoUnpublishAt:{type:Date,default:null},
  draftChangesPending:{type:Boolean,default:false},
  publishIgnoredIssues:[{type:String}],
  publishSnapshots:[{
    version:Number,
    publishedAt:{type:Date,default:Date.now},
    publishedBy:String,
    status:String,
    action:String,
    notes:String,
    reason:String,
    visibilityMode:String,
    snapshotData:mongoose.Schema.Types.Mixed
  }],

BATCHFIELDS_EOF

# 2) TestSeries.js model fields
cat > "$STAGE/testseries_model_fields.txt" << 'SERIESFIELDS_EOF'

  // ── Publish Center (Go-Live Control Center) ──
  isPublished:{type:Boolean,default:true},
  publishState:{type:String,default:'draft',enum:['draft','ready','scheduled','published','unpublished','republish_pending','blocked']},
  publishVersion:{type:Number,default:0},
  lastPublishedAt:{type:Date,default:null},
  lastPublishedBy:{type:String,default:''},
  scheduledPublishAt:{type:Date,default:null},
  scheduledPublishTimezone:{type:String,default:'Asia/Kolkata'},
  scheduledAutoActivate:{type:Boolean,default:true},
  scheduledAutoUnpublishAt:{type:Date,default:null},
  draftChangesPending:{type:Boolean,default:false},
  publishIgnoredIssues:[{type:String}],
  publishSnapshots:[{
    version:Number,
    publishedAt:{type:Date,default:Date.now},
    publishedBy:String,
    status:String,
    action:String,
    notes:String,
    reason:String,
    visibilityMode:String,
    snapshotData:mongoose.Schema.Types.Mixed
  }],

SERIESFIELDS_EOF

# 3) Batch Publish Center backend routes
cat > "$STAGE/publish_center_batch_routes.txt" << 'BATCHROUTES_EOF'

// ══════════════════════════════════════════════════════════════════
// 16) PUBLISH CENTER — Go-Live Control Center
// ══════════════════════════════════════════════════════════════════
function scoreStatusLabel(score) {
  if (score >= 95) return 'Ready to Publish';
  if (score >= 80) return 'Almost Ready';
  if (score >= 50) return 'Partially Ready';
  return 'Not Ready';
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

  const mandatory = [
    { key: 'basicInfo', label: 'Basic Information complete', done: !!(batch.name && batch.description && batch.examType), reason: 'Name, description & exam type required' },
    { key: 'banner', label: 'Banner ready', done: !!bannerGate.ready, reason: bannerGate.reason || '' },
    { key: 'pricing', label: 'Pricing configured', done: !!(batch.isFree || (batch.price && batch.price > 0)), reason: 'Set a price or mark as Free' },
    { key: 'startDate', label: 'Start Date set', done: !!batch.startDate, reason: 'Start Date missing in Settings' },
    { key: 'endDate', label: 'End Date / Validity set', done: !!(batch.endDate || (batch.validity && batch.validity > 0)), reason: 'End Date or Validity missing' },
    { key: 'controls', label: 'Controls configured', done: true, reason: '' },
    { key: 'coupons', label: 'Coupon configuration checked', done: coupons.length === 0 || expiredButActive.length === 0, reason: couponIssue }
  ];
  const optional = [
    { key: 'exams', label: 'Exams added', done: examCount > 0, count: examCount },
    { key: 'materials', label: 'Materials added', done: materialsCount > 0, count: materialsCount },
    { key: 'announcements', label: 'Announcements prepared', done: announcementsCount > 0, count: announcementsCount },
    { key: 'faq', label: 'FAQ / Help content', done: true },
    { key: 'leaderboard', label: 'Leaderboard enabled', done: true },
    { key: 'analytics', label: 'Analytics enabled', done: true }
  ];

  const weights = { basicInfo: 15, banner: 20, pricing: 15, startDate: 8, endDate: 7, controls: 10, coupons: 5 };
  let score = 0;
  mandatory.forEach(m => { if (m.done) score += (weights[m.key] || 0); });
  score += examCount > 0 ? 15 : 0;
  score += (batch.thumbnail || batch.colorIcon) ? 5 : 0;
  score = Math.max(0, Math.min(100, Math.round(score)));

  const blockingIssues = mandatory.filter(m => !m.done && !(batch.publishIgnoredIssues || []).includes(m.key))
    .map(m => ({ key: m.key, message: m.reason || (m.label + ' missing') }));

  return { mandatory, optional, score, scoreStatus: scoreStatusLabel(score), blockingIssues, studentCount, examCount, bannerGate };
}

function applyPublishState(batch, isPublished) {
  batch.status = isPublished ? 'active' : (batch.status === 'draft' ? 'draft' : 'inactive');
}

function pushPublishSnapshot(batch, { action, notes, reason, visibilityMode, publishedByName }) {
  batch.publishSnapshots = batch.publishSnapshots || [];
  batch.publishSnapshots.push({
    version: batch.publishVersion || 0,
    publishedAt: new Date(),
    publishedBy: publishedByName || 'Admin',
    status: batch.publishState,
    action,
    notes: notes || '',
    reason: reason || '',
    visibilityMode: visibilityMode || batch.visibility || 'public',
    snapshotData: {
      name: batch.name, description: batch.description, examType: batch.examType, category: batch.category,
      price: batch.price, discountPrice: batch.discountPrice, thumbnail: batch.thumbnail, colorIcon: batch.colorIcon,
      startDate: batch.startDate, endDate: batch.endDate, validity: batch.validity, seatLimit: batch.seatLimit,
      enrollmentRule: batch.enrollmentRule, accessPolicy: batch.accessPolicy, visibility: batch.visibility,
      teacherAssigned: batch.teacherAssigned, isSpotlight: batch.isSpotlight, isBundle: batch.isBundle,
      allowFreeTrial: batch.allowFreeTrial, lifecycleStatus: batch.lifecycleStatus, status: batch.status
    }
  });
  if (batch.publishSnapshots.length > 30) batch.publishSnapshots = batch.publishSnapshots.slice(-30);
}

// GET /:id/publish-center — full readiness + status dashboard
router.get('/:id/publish-center', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { mandatory, optional, score, scoreStatus, blockingIssues, examCount, bannerGate } = await buildPublishChecklist(batch);

    let couponsActive = false;
    try { couponsActive = !!(await Coupon.exists({ scopeType: 'batch', scopeId: batch._id, isDeleted: false, status: 'active' })); } catch (e) {}
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
        : couponsActive ? 'Live with Offer Active' : 'Fully Live'
    };

    res.json({
      summary: {
        readinessScore: score, scoreStatus,
        publishStatus: batch.publishState || 'draft',
        publishVersion: batch.publishVersion || 0,
        lastPublished: batch.lastPublishedAt || null,
        lastPublishedBy: batch.lastPublishedBy || '',
        draftChangesPending: !!batch.draftChangesPending,
        blockingIssuesCount: blockingIssues.length
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
      history: (batch.publishSnapshots || []).slice().reverse().slice(0, 50)
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/publish
router.put('/:id/publish-center/publish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { mandatory, blockingIssues } = await buildPublishChecklist(batch.toObject());
    if (blockingIssues.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues, gate: 'publish_blocked' });
    const oldState = batch.publishState;
    batch.isPublished = true;
    batch.publishState = 'published';
    batch.publishVersion = (batch.publishVersion || 0) + 1;
    batch.lastPublishedAt = new Date();
    batch.lastPublishedBy = req.user.name || 'Admin';
    batch.draftChangesPending = false;
    applyPublishState(batch, true);
    pushPublishSnapshot(batch, { action: 'publish', notes: req.body.notes, visibilityMode: req.body.visibilityMode, publishedByName: req.user.name });
    batch.lastActivityAt = new Date();
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'publish_completed', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: batch.publishState, publishVersion: batch.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/unpublish
router.put('/:id/publish-center/unpublish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const oldState = batch.publishState;
    batch.isPublished = false;
    batch.publishState = 'unpublished';
    applyPublishState(batch, false);
    pushPublishSnapshot(batch, { action: 'unpublish', reason: req.body.reason, publishedByName: req.user.name });
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'unpublished', action: 'unpublish_initiated', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: batch.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/republish
router.put('/:id/publish-center/republish', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { blockingIssues } = await buildPublishChecklist(batch.toObject());
    if (blockingIssues.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues, gate: 'publish_blocked' });
    const oldState = batch.publishState;
    batch.isPublished = true;
    batch.publishState = 'published';
    batch.publishVersion = (batch.publishVersion || 0) + 1;
    batch.lastPublishedAt = new Date();
    batch.lastPublishedBy = req.user.name || 'Admin';
    batch.draftChangesPending = false;
    applyPublishState(batch, true);
    pushPublishSnapshot(batch, { action: 'republish', notes: req.body.notes, publishedByName: req.user.name });
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'republish_initiated', changedBy: req.user.id, changedByName: req.user.name });
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
    batch.isPublished = false;
    batch.publishState = 'unpublished';
    batch.lifecycleStatus = 'archived';
    batch.archivedAt = new Date();
    applyPublishState(batch, false);
    pushPublishSnapshot(batch, { action: 'archive', reason: req.body.reason, publishedByName: req.user.name });
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'lifecycleStatus', newValue: 'archived', action: 'publish_center_archive', changedBy: req.user.id, changedByName: req.user.name });
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

// GET /:id/publish-center/history
router.get('/:id/publish-center/history', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    res.json({ history: (batch.publishSnapshots || []).slice().reverse() });
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

// POST /:id/publish-center/rollback
router.post('/:id/publish-center/rollback', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const { toVersion, reason, scope } = req.body;
    if (!reason) return res.status(400).json({ error: 'Reason is mandatory for rollback' });
    const snap = (batch.publishSnapshots || []).find(s => String(s.version) === String(toVersion));
    if (!snap) return res.status(404).json({ error: 'Snapshot version not found' });
    const d = snap.snapshotData || {};
    ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
      'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility',
      'teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial'].forEach(f => { if (d[f] !== undefined) batch[f] = d[f]; });
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
    pushPublishSnapshot(batch, { action: 'rollback', reason, publishedByName: req.user.name });
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'publishVersion', oldValue: batch.publishVersion, newValue: toVersion, action: 'rollback_executed', changedBy: req.user.id, changedByName: req.user.name, source: 'rollback:' + reason });
    res.json({ success: true, publishState: batch.publishState, publishVersion: batch.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/preview — student-facing preview (marketplace/card/detail/mobile/desktop)
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

BATCHROUTES_EOF

# 4) TestSeries Publish Center backend routes
cat > "$STAGE/publish_center_series_routes.txt" << 'SERIESROUTES_EOF'

// ══════════════════════════════════════════════════════════════════
// 16) PUBLISH CENTER — Go-Live Control Center
// ══════════════════════════════════════════════════════════════════
function scoreStatusLabel(score) {
  if (score >= 95) return 'Ready to Publish';
  if (score >= 80) return 'Almost Ready';
  if (score >= 50) return 'Partially Ready';
  return 'Not Ready';
}

async function buildPublishChecklist(series) {
  const studentCount = (series.students && series.students.length) || 0;
  const examCount = (series.tests && series.tests.length) || 0;
  const bannerGate = await checkBannerGate(series._id);
  let materialsCount = 0;
  try { if (BatchNote) materialsCount = await BatchNote.countDocuments({ series: series._id }); } catch (e) {}
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

  const mandatory = [
    { key: 'basicInfo', label: 'Basic Information complete', done: !!(series.name && series.description && series.examType), reason: 'Name, description & exam type required' },
    { key: 'banner', label: 'Banner ready', done: !!bannerGate.ready, reason: bannerGate.reason || '' },
    { key: 'pricing', label: 'Pricing configured', done: !!(series.isFree || (series.price && series.price > 0)), reason: 'Set a price or mark as Free' },
    { key: 'startDate', label: 'Start Date set', done: !!series.startDate, reason: 'Start Date missing in Settings' },
    { key: 'endDate', label: 'End Date / Validity set', done: !!(series.endDate || (series.validity && series.validity > 0)), reason: 'End Date or Validity missing' },
    { key: 'controls', label: 'Controls configured', done: true, reason: '' },
    { key: 'coupons', label: 'Coupon configuration checked', done: coupons.length === 0 || expiredButActive.length === 0, reason: couponIssue }
  ];
  const optional = [
    { key: 'exams', label: 'Exams added', done: examCount > 0, count: examCount },
    { key: 'materials', label: 'Materials added', done: materialsCount > 0, count: materialsCount },
    { key: 'announcements', label: 'Announcements prepared', done: announcementsCount > 0, count: announcementsCount },
    { key: 'faq', label: 'FAQ / Help content', done: true },
    { key: 'leaderboard', label: 'Leaderboard enabled', done: true },
    { key: 'analytics', label: 'Analytics enabled', done: true }
  ];

  const weights = { basicInfo: 15, banner: 20, pricing: 15, startDate: 8, endDate: 7, controls: 10, coupons: 5 };
  let score = 0;
  mandatory.forEach(m => { if (m.done) score += (weights[m.key] || 0); });
  score += examCount > 0 ? 15 : 0;
  score += (series.thumbnail || series.colorIcon) ? 5 : 0;
  score = Math.max(0, Math.min(100, Math.round(score)));

  const blockingIssues = mandatory.filter(m => !m.done && !(series.publishIgnoredIssues || []).includes(m.key))
    .map(m => ({ key: m.key, message: m.reason || (m.label + ' missing') }));

  return { mandatory, optional, score, scoreStatus: scoreStatusLabel(score), blockingIssues, studentCount, examCount, bannerGate };
}

function applyPublishState(series, isPublished) {
  series.status = isPublished ? 'active' : (series.status === 'draft' ? 'draft' : 'inactive');
}

function pushPublishSnapshot(series, { action, notes, reason, visibilityMode, publishedByName }) {
  series.publishSnapshots = series.publishSnapshots || [];
  series.publishSnapshots.push({
    version: series.publishVersion || 0,
    publishedAt: new Date(),
    publishedBy: publishedByName || 'Admin',
    status: series.publishState,
    action,
    notes: notes || '',
    reason: reason || '',
    visibilityMode: visibilityMode || series.visibility || 'public',
    snapshotData: {
      name: series.name, description: series.description, examType: series.examType, category: series.category,
      price: series.price, discountPrice: series.discountPrice, thumbnail: series.thumbnail, colorIcon: series.colorIcon,
      startDate: series.startDate, endDate: series.endDate, validity: series.validity, seatLimit: series.seatLimit,
      enrollmentRule: series.enrollmentRule, accessPolicy: series.accessPolicy, visibility: series.visibility,
      teacherAssigned: series.teacherAssigned, isSpotlight: series.isSpotlight, isBundle: series.isBundle,
      allowFreeTrial: series.allowFreeTrial, lifecycleStatus: series.lifecycleStatus, status: series.status
    }
  });
  if (series.publishSnapshots.length > 30) series.publishSnapshots = series.publishSnapshots.slice(-30);
}

// GET /:id/publish-center — full readiness + status dashboard
router.get('/:id/publish-center', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { mandatory, optional, score, scoreStatus, blockingIssues, examCount, bannerGate } = await buildPublishChecklist(series);

    let couponsActive = false;
    try { couponsActive = !!(await Coupon.exists({ scopeType: 'series', scopeId: series._id, isDeleted: false, status: 'active' })); } catch (e) {}
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
        : couponsActive ? 'Live with Offer Active' : 'Fully Live'
    };

    res.json({
      summary: {
        readinessScore: score, scoreStatus,
        publishStatus: series.publishState || 'draft',
        publishVersion: series.publishVersion || 0,
        lastPublished: series.lastPublishedAt || null,
        lastPublishedBy: series.lastPublishedBy || '',
        draftChangesPending: !!series.draftChangesPending,
        blockingIssuesCount: blockingIssues.length
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
      history: (series.publishSnapshots || []).slice().reverse().slice(0, 50)
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/publish
router.put('/:id/publish-center/publish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { mandatory, blockingIssues } = await buildPublishChecklist(series.toObject());
    if (blockingIssues.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues, gate: 'publish_blocked' });
    const oldState = series.publishState;
    series.isPublished = true;
    series.publishState = 'published';
    series.publishVersion = (series.publishVersion || 0) + 1;
    series.lastPublishedAt = new Date();
    series.lastPublishedBy = req.user.name || 'Admin';
    series.draftChangesPending = false;
    applyPublishState(series, true);
    pushPublishSnapshot(series, { action: 'publish', notes: req.body.notes, visibilityMode: req.body.visibilityMode, publishedByName: req.user.name });
    series.lastActivityAt = new Date();
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'publish_completed', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: series.publishState, publishVersion: series.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/unpublish
router.put('/:id/publish-center/unpublish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const oldState = series.publishState;
    series.isPublished = false;
    series.publishState = 'unpublished';
    applyPublishState(series, false);
    pushPublishSnapshot(series, { action: 'unpublish', reason: req.body.reason, publishedByName: req.user.name });
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'unpublished', action: 'unpublish_initiated', changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true, publishState: series.publishState });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/publish-center/republish
router.put('/:id/publish-center/republish', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { blockingIssues } = await buildPublishChecklist(series.toObject());
    if (blockingIssues.length > 0) return res.status(423).json({ error: 'Mandatory checklist incomplete', blockingIssues, gate: 'publish_blocked' });
    const oldState = series.publishState;
    series.isPublished = true;
    series.publishState = 'published';
    series.publishVersion = (series.publishVersion || 0) + 1;
    series.lastPublishedAt = new Date();
    series.lastPublishedBy = req.user.name || 'Admin';
    series.draftChangesPending = false;
    applyPublishState(series, true);
    pushPublishSnapshot(series, { action: 'republish', notes: req.body.notes, publishedByName: req.user.name });
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishState', oldValue: oldState, newValue: 'published', action: 'republish_initiated', changedBy: req.user.id, changedByName: req.user.name });
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
    series.isPublished = false;
    series.publishState = 'unpublished';
    series.lifecycleStatus = 'archived';
    series.archivedAt = new Date();
    applyPublishState(series, false);
    pushPublishSnapshot(series, { action: 'archive', reason: req.body.reason, publishedByName: req.user.name });
    await series.save();
    await logAudit({ seriesId: series._id, field: 'lifecycleStatus', newValue: 'archived', action: 'publish_center_archive', changedBy: req.user.id, changedByName: req.user.name });
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

// GET /:id/publish-center/history
router.get('/:id/publish-center/history', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    res.json({ history: (series.publishSnapshots || []).slice().reverse() });
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

// POST /:id/publish-center/rollback
router.post('/:id/publish-center/rollback', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const { toVersion, reason, scope } = req.body;
    if (!reason) return res.status(400).json({ error: 'Reason is mandatory for rollback' });
    const snap = (series.publishSnapshots || []).find(s => String(s.version) === String(toVersion));
    if (!snap) return res.status(404).json({ error: 'Snapshot version not found' });
    const d = snap.snapshotData || {};
    ['name', 'description', 'examType', 'category', 'price', 'discountPrice', 'thumbnail', 'colorIcon',
      'startDate', 'endDate', 'validity', 'seatLimit', 'enrollmentRule', 'accessPolicy', 'visibility',
      'teacherAssigned', 'isSpotlight', 'isBundle', 'allowFreeTrial'].forEach(f => { if (d[f] !== undefined) series[f] = d[f]; });
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
    pushPublishSnapshot(series, { action: 'rollback', reason, publishedByName: req.user.name });
    await series.save();
    await logAudit({ seriesId: series._id, field: 'publishVersion', oldValue: series.publishVersion, newValue: toVersion, action: 'rollback_executed', changedBy: req.user.id, changedByName: req.user.name, source: 'rollback:' + reason });
    res.json({ success: true, publishState: series.publishState, publishVersion: series.publishVersion });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/publish-center/preview — student-facing preview (marketplace/card/detail/mobile/desktop)
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
    const examCount = (series.tests && series.tests.length) || 0;
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

SERIESROUTES_EOF

# 5) Publish Center frontend tab component (shared)
cat > "$STAGE/publish_center_tab.txt" << 'PUBTAB_EOF'

// ── 16) PUBLISH CENTER TAB — Go-Live Control Center ──
function PublishCenterTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const isMobile = useIsMobile()
  const [data, setData] = useState<any>(null)
  const [previewMode, setPreviewMode] = useState('marketplace')
  const [preview, setPreview] = useState<any>(null)
  const [showPreview, setShowPreview] = useState(false)
  const [notes, setNotes] = useState('')
  const [showSchedule, setShowSchedule] = useState(false)
  const [sched, setSched] = useState<any>({ publishAt: '', timezone: 'Asia/Kolkata', autoActivate: true, autoUnpublishAt: '' })
  const [rollbackFor, setRollbackFor] = useState<any>(null)
  const [rollbackReason, setRollbackReason] = useState('')
  const [rollbackScope, setRollbackScope] = useState('full')
  const [unpublishReason, setUnpublishReason] = useState('')
  const [showUnpublishBox, setShowUnpublishBox] = useState(false)
  const [busy, setBusy] = useState(false)
  const [historyOpen, setHistoryOpen] = useState(!isMobile)
  const [checklistOpen, setChecklistOpen] = useState(true)

  const load = useCallback(() => fetch(base + '/' + id + '/publish-center', { headers: authHeaders }).then(r => r.json()).then(setData).catch(() => {}), [])
  useEffect(() => { load() }, [load])

  const loadPreview = async (mode: string) => {
    setPreviewMode(mode)
    const d = await fetch(base + '/' + id + '/publish-center/preview?mode=' + mode, { headers: authHeaders }).then(r => r.json()).catch(() => null)
    setPreview(d?.preview || null)
    setShowPreview(true)
  }

  const act = async (path: string, method: string, body?: any, okMsg?: string) => {
    setBusy(true)
    try {
      const r = await fetch(base + '/' + id + '/publish-center/' + path, { method, headers: authHeaders, body: body ? JSON.stringify(body) : undefined })
      const d = await r.json()
      if (!r.ok) { showToast('⚠️ ' + (d.error || 'Action failed')); setBusy(false); return d }
      showToast(okMsg || '✅ Done')
      await load(); loadParent && loadParent()
      setBusy(false)
      return d
    } catch (e) { showToast('⚠️ Network error'); setBusy(false); return null }
  }

  const doPublish = () => act('publish', 'PUT', { notes }, '🚀 Published successfully')
  const doRepublish = () => act('republish', 'PUT', { notes }, '🚀 Republished successfully')
  const doUnpublish = async () => { await act('unpublish', 'PUT', { reason: unpublishReason }, '⛔ Unpublished'); setShowUnpublishBox(false); setUnpublishReason('') }
  const doArchive = () => { if (!window.confirm('Archive this batch? It will be hidden from marketplace and moved to Archived.')) return; act('archive', 'PUT', {}, '📦 Archived') }
  const doRestoreDraft = () => { if (!window.confirm('Restore to Draft? This will keep it unpublished for further editing.')) return; act('restore-draft', 'PUT', {}, '📝 Restored to Draft') }
  const doSchedule = async () => {
    if (!sched.publishAt) return showToast('⚠️ Select publish date & time')
    const iso = new Date(sched.publishAt).toISOString()
    await act('schedule', 'PUT', { publishAt: iso, timezone: sched.timezone, autoActivate: sched.autoActivate, autoUnpublishAt: sched.autoUnpublishAt ? new Date(sched.autoUnpublishAt).toISOString() : null }, '📅 Publish scheduled')
    setShowSchedule(false)
  }
  const doCancelSchedule = () => act('schedule/cancel', 'PUT', {}, '✅ Scheduled publish cancelled')
  const doRollback = async () => {
    if (!rollbackReason.trim()) return showToast('⚠️ Reason is mandatory for rollback')
    if (!window.confirm(`Rollback to version ${rollbackFor.version}? This will overwrite current draft/live data.`)) return
    await act('rollback', 'POST', { toVersion: rollbackFor.version, reason: rollbackReason, scope: rollbackScope }, '↩️ Rolled back to v' + rollbackFor.version)
    setRollbackFor(null); setRollbackReason('')
  }

  if (!data) return <EmptyMsg text="⟳ Loading Publish Center…" />
  const s = data.summary
  const scoreColor = s.readinessScore >= 95 ? GOOD : s.readinessScore >= 80 ? ACC : s.readinessScore >= 50 ? WARN : BAD
  const statusChip = (label: string, color: string) => <span style={chip(color, 'rgba(255,255,255,0.05)')}>{label}</span>
  const stateColor: any = { draft: DIM, ready: ACC, scheduled: WARN, published: GOOD, unpublished: BAD, republish_pending: WARN, blocked: BAD }

  const SummaryCards = () => (
    <div style={{ ...cs, display: 'grid', gridTemplateColumns: isMobile ? 'repeat(2,1fr)' : 'repeat(6,1fr)', gap: 10 }}>
      <div style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => setChecklistOpen(true)}>
        <div style={{ fontSize: 22, fontWeight: 800, color: scoreColor }}>{s.readinessScore}%</div>
        <div style={{ fontSize: 9, color: DIM }}>READINESS · {s.scoreStatus}</div>
      </div>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 14, fontWeight: 800, color: stateColor[s.publishStatus] || TS, textTransform: 'capitalize' }}>{(s.publishStatus || 'draft').replace('_', ' ')}</div>
        <div style={{ fontSize: 9, color: DIM }}>PUBLISH STATUS</div>
      </div>
      <div style={{ textAlign: 'center' }}>
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
        <div style={{ fontSize: 20, fontWeight: 800, color: s.blockingIssuesCount > 0 ? BAD : GOOD }}>{s.blockingIssuesCount}</div>
        <div style={{ fontSize: 9, color: DIM }}>BLOCKING ISSUES</div>
      </div>
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
          <div key={m.key} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 0', borderBottom: `1px solid ${BOR}` }}>
            <div style={{ fontSize: 12.5, color: m.done ? TS : BAD }}>{m.done ? '✅' : '🔴'} {m.label}</div>
            {!m.done && <span style={{ fontSize: 10, color: DIM }}>{m.reason}</span>}
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

  const BlockingPanel = () => data.blockingIssues.length === 0 ? null : (
    <div style={{ ...cs, border: `1px solid rgba(239,68,68,0.35)` }}>
      <div style={{ fontWeight: 700, color: BAD, marginBottom: 8 }}>🚫 Blocking Issues ({data.blockingIssues.length})</div>
      {data.blockingIssues.map((b: any) => <div key={b.key} style={{ fontSize: 12, color: TS, padding: '4px 0' }}>• {b.message}</div>)}
    </div>
  )

  const PreviewPanel = () => (
    <div style={cs}>
      <div style={{ fontWeight: 700, color: TS, marginBottom: 8 }}>👁 Student Preview</div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
        {['marketplace', 'card', 'detail', 'mobile', 'desktop'].map(m => (
          <button key={m} style={previewMode === m && showPreview ? bp : bs} onClick={() => loadPreview(m)}>{m === 'marketplace' ? '🏪 Marketplace' : m === 'card' ? '🃏 Card' : m === 'detail' ? '📄 Detail Page' : m === 'mobile' ? '📱 Mobile' : '🖥️ Desktop'}</button>
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
          <button style={{ ...bp, marginTop: 10, width: '100%' }} disabled>{preview.cta}</button>
        </div>
      )}
      {!showPreview && <div style={{ fontSize: 11.5, color: DIM }}>Select a preview mode to see exactly what students will see before you publish.</div>}
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

  const ActionsPanel = () => (
    <div style={cs}>
      <div style={{ fontWeight: 700, color: TS, marginBottom: 10 }}>🚀 Publish Actions</div>
      <textarea style={{ ...inp, minHeight: 50, marginBottom: 8 }} placeholder="Notes for this publish (optional)" value={notes} onChange={e => setNotes(e.target.value)} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {!data.isPublished ? (
          <button style={bp} disabled={busy || data.blockingIssues.length > 0} onClick={doPublish}>🚀 Publish{data.blockingIssues.length > 0 ? ' (Blocked)' : ''}</button>
        ) : (
          <button style={bp} disabled={busy || data.blockingIssues.length > 0} onClick={doRepublish}>🔁 Republish</button>
        )}
        {data.isPublished && !showUnpublishBox && <button style={bd} disabled={busy} onClick={() => setShowUnpublishBox(true)}>⛔ Unpublish</button>}
        {showUnpublishBox && (
          <div>
            <textarea style={{ ...inp, minHeight: 50, marginBottom: 6 }} placeholder="Reason for unpublishing" value={unpublishReason} onChange={e => setUnpublishReason(e.target.value)} />
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
            ⏳ Scheduled for {new Date(data.scheduled.scheduledPublishAt).toLocaleString()} ({data.scheduled.scheduledPublishTimezone})
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
        {isMobile && <span style={{ color: DIM }}>{historyOpen ? '▲' : '▼'}</span>}
      </div>
      {historyOpen && (data.history.length === 0 ? <EmptyMsg text="No publish history yet." /> : (
        <div style={{ marginTop: 8 }}>
          {data.history.map((h: any, i: number) => (
            <div key={i} style={{ padding: '8px 0', borderBottom: `1px solid ${BOR}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div style={{ color: TS, fontWeight: 700, fontSize: 12.5 }}>v{h.version} · {h.action}</div>
                <div style={{ color: DIM, fontSize: 10.5 }}>{new Date(h.publishedAt).toLocaleString()}</div>
              </div>
              <div style={{ color: DIM, fontSize: 11 }}>by {h.publishedBy} · {h.status}{h.notes ? ' · ' + h.notes : ''}{h.reason ? ' · reason: ' + h.reason : ''}</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                <button style={{ ...bs, fontSize: 10.5, padding: '4px 8px' }} onClick={() => { setRollbackFor(h); setRollbackScope('full') }}>↩️ Rollback to this</button>
              </div>
            </div>
          ))}
        </div>
      ))}
    </div>
  )

  const RollbackModal = () => !rollbackFor ? null : (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }} onClick={() => setRollbackFor(null)}>
      <div style={{ background: CRD, borderRadius: 16, padding: 20, maxWidth: 420, width: '100%', border: `1px solid ${BOR2}` }} onClick={e => e.stopPropagation()}>
        <div style={{ fontWeight: 700, color: TS, marginBottom: 10 }}>↩️ Rollback to v{rollbackFor.version}</div>
        <label style={lbl}>Scope</label>
        <select style={{ ...inp, marginBottom: 10 }} value={rollbackScope} onChange={e => setRollbackScope(e.target.value)}>
          <option value="full">Rollback & Republish (Full)</option>
          <option value="draft_only">Restore as Draft only</option>
        </select>
        <label style={lbl}>Reason (mandatory)</label>
        <textarea style={{ ...inp, minHeight: 60, marginBottom: 12 }} value={rollbackReason} onChange={e => setRollbackReason(e.target.value)} placeholder="Why are you rolling back?" />
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={{ ...bs, flex: 1 }} onClick={() => setRollbackFor(null)}>Cancel</button>
          <button style={{ ...bd, flex: 1 }} onClick={doRollback}>Confirm Rollback</button>
        </div>
      </div>
    </div>
  )

  if (isMobile) {
    return (
      <div style={{ paddingBottom: 70 }}>
        <SummaryCards />
        <ChecklistPanel />
        <BlockingPanel />
        <PreviewPanel />
        <PostPublishPanel />
        <HistoryPanel />
        <div style={{ position: 'fixed', left: 0, right: 0, bottom: 0, background: CRD2, borderTop: `1px solid ${BOR2}`, padding: 10, zIndex: 50, display: 'flex', gap: 8 }}>
          {!data.isPublished
            ? <button style={{ ...bp, flex: 1 }} disabled={busy || data.blockingIssues.length > 0} onClick={doPublish}>🚀 Publish</button>
            : <button style={{ ...bp, flex: 1 }} disabled={busy || data.blockingIssues.length > 0} onClick={doRepublish}>🔁 Republish</button>}
          <button style={{ ...bs, flex: 1 }} onClick={() => setShowSchedule(true)}>📅 Schedule</button>
        </div>
        {showSchedule && <ActionsPanel />}
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

PUBTAB_EOF

# 6) Node patcher (anchor-based, never removes existing code)
cat > "$STAGE/patch-publish-center.cjs" << 'PATCHER_EOF'
// ProveRank — Publish Center installer (anchor-based, never removes existing code)
const fs = require('fs');
const path = require('path');

const ROOT = process.env.WORKSPACE_ROOT || process.cwd();
const STAGE = __dirname;

let failures = 0;
let skipped = 0;

function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, c) { fs.writeFileSync(p, c, 'utf8'); }
function stage(name) { return read(path.join(STAGE, name)); }

function patchFile(label, filePath, alreadyMarker, steps) {
  console.log('\n── ' + label + ' (' + filePath + ') ──');
  if (!fs.existsSync(filePath)) { console.log('  ✗ SKIPPED — file not found at this path.'); failures++; return; }
  let content = read(filePath);
  if (alreadyMarker && content.includes(alreadyMarker)) {
    console.log('  ⏭  Already patched earlier — skipping (idempotent).');
    skipped++;
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
// 1) Batch.js model — add Publish Center fields
// ══════════════════════════════════════════════════════════════
patchFile('Batch.js model', path.join(ROOT, 'src/models/Batch.js'), 'Publish Center (Go-Live', [
  function insertFields(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const fields = stage('batch_model_fields.txt');
    return content.slice(0, m.index) + fields + '\n' + content.slice(m.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 2) TestSeries.js model — add Publish Center fields
// ══════════════════════════════════════════════════════════════
patchFile('TestSeries.js model', path.join(ROOT, 'src/models/TestSeries.js'), 'Publish Center (Go-Live', [
  function insertFields(content) {
    const re = /\}\s*,\s*\{\s*timestamps\s*:\s*true\s*\}\s*\)\s*;/;
    const m = content.match(re);
    if (!m) return null;
    const fields = stage('testseries_model_fields.txt');
    return content.slice(0, m.index) + fields + '\n' + content.slice(m.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 3) batchManagerUltra.js — add Publish Center routes
// ══════════════════════════════════════════════════════════════
patchFile('batchManagerUltra.js routes', path.join(ROOT, 'src/routes/batchManagerUltra.js'), 'PUBLISH CENTER — Go-Live Control Center', [
  function insertRoutes(content) {
    const re = /\nmodule\.exports\s*=\s*router\s*;\s*$/;
    const m = content.match(re);
    if (!m) return null;
    const block = stage('publish_center_batch_routes.txt');
    return content.slice(0, m.index) + '\n' + block + '\n' + content.slice(m.index).replace(/^\n/, '\n');
  }
]);

// ══════════════════════════════════════════════════════════════
// 4) testSeriesManagerUltra.js — add Publish Center routes
// ══════════════════════════════════════════════════════════════
patchFile('testSeriesManagerUltra.js routes', path.join(ROOT, 'src/routes/testSeriesManagerUltra.js'), 'PUBLISH CENTER — Go-Live Control Center', [
  function insertRoutes(content) {
    const re = /\nmodule\.exports\s*=\s*router\s*;\s*$/;
    const m = content.match(re);
    if (!m) return null;
    const block = stage('publish_center_series_routes.txt');
    return content.slice(0, m.index) + '\n' + block + '\n' + content.slice(m.index).replace(/^\n/, '\n');
  }
]);

// ══════════════════════════════════════════════════════════════
// 5) studentBatches.js — respect isPublished on marketplace listing only
// ══════════════════════════════════════════════════════════════
patchFile('studentBatches.js marketplace filter', path.join(ROOT, 'src/routes/studentBatches.js'), 'marketplaceSeriesFilter', [
  function insertMarketplaceSeriesFilterFn(content) {
    const re = /function baseSeriesFilter\(\)\{[\s\S]*?\n\}\n/;
    const m = content.match(re);
    if (!m) return null;
    const addition = "// Marketplace-only filter (adds isPublished check) — NOT used for /my so already-enrolled\n// students keep access to their batch/series even if it's later unpublished from marketplace.\nfunction marketplaceSeriesFilter(){\n  return{ ...baseSeriesFilter(), isPublished:{$ne:false} };\n}\n";
    const insertPos = m.index + m[0].length;
    return content.slice(0, insertPos) + addition + content.slice(insertPos);
  },
  function patchBatchFilter(content) {
    const re = /const filter=\{status:'active'\};/;
    const m = content.match(re);
    if (!m) return null;
    return content.slice(0, m.index) + "const filter={status:'active',isPublished:{$ne:false}};" + content.slice(m.index + m[0].length);
  },
  function patchSeriesFilterUsage(content) {
    const re = /const seriesFilter=baseSeriesFilter\(\);/;
    const m = content.match(re);
    if (!m) return null;
    return content.slice(0, m.index) + "const seriesFilter=marketplaceSeriesFilter();" + content.slice(m.index + m[0].length);
  }
]);

// ══════════════════════════════════════════════════════════════
// 6) BatchManagerUltra.tsx — add Publish Center tab (frontend)
// ══════════════════════════════════════════════════════════════
patchFile('BatchManagerUltra.tsx frontend tab', path.join(ROOT, 'frontend/app/admin/x7k2p/BatchManagerUltra.tsx'), 'PUBLISH CENTER TAB', [
  function insertTabEntry(content) {
    const re = /\['settings',\s*'[^']*Settings'\],\s*\['audit',\s*'[^']*Audit History'\]/;
    const m = content.match(re);
    if (!m) return null;
    const replacement = m[0].replace("['audit'", "['publish', '🚀 Publish Center'], ['audit'");
    return content.slice(0, m.index) + replacement + content.slice(m.index + m[0].length);
  },
  function insertRenderLine(content) {
    const re = /\{tab === 'settings' && <SettingsTab[^\n]*\/>\}/;
    const m = content.match(re);
    if (!m) return null;
    const insertPos = m.index + m[0].length;
    const line = "\n      {tab === 'publish' && <PublishCenterTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}";
    return content.slice(0, insertPos) + line + content.slice(insertPos);
  },
  function insertComponent(content) {
    const re = /\nfunction AuditTab\(/;
    const m = content.match(re);
    if (!m) return null;
    const component = stage('publish_center_tab.txt');
    return content.slice(0, m.index) + '\n' + component + content.slice(m.index);
  }
]);

// ══════════════════════════════════════════════════════════════
// 7) TestSeriesManagerUltra.tsx — add Publish Center tab (frontend)
// ══════════════════════════════════════════════════════════════
patchFile('TestSeriesManagerUltra.tsx frontend tab', path.join(ROOT, 'frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx'), 'PUBLISH CENTER TAB', [
  function insertTabEntry(content) {
    const re = /\['settings',\s*'[^']*Settings'\],\s*\['audit',\s*'[^']*Audit History'\]/;
    const m = content.match(re);
    if (!m) return null;
    const replacement = m[0].replace("['audit'", "['publish', '🚀 Publish Center'], ['audit'");
    return content.slice(0, m.index) + replacement + content.slice(m.index + m[0].length);
  },
  function insertRenderLine(content) {
    const re = /\{tab === 'settings' && <SettingsTab[^\n]*\/>\}/;
    const m = content.match(re);
    if (!m) return null;
    const insertPos = m.index + m[0].length;
    const line = "\n      {tab === 'publish' && <PublishCenterTab base={base} authHeaders={authHeaders} id={id} showToast={showToast} load={load} />}";
    return content.slice(0, insertPos) + line + content.slice(insertPos);
  },
  function insertComponent(content) {
    const re = /\nfunction AuditTab\(/;
    const m = content.match(re);
    if (!m) return null;
    const component = stage('publish_center_tab.txt');
    return content.slice(0, m.index) + '\n' + component + content.slice(m.index);
  }
]);

console.log('\n══════════════════════════════════════════');
if (failures > 0) {
  console.log('⚠️  ' + failures + ' file(s) could NOT be patched automatically. Please re-share those files.');
  process.exitCode = 1;
} else {
  console.log('✅ Publish Center installed (' + (7 - skipped - failures) + ' file(s) patched, ' + skipped + ' already up to date).');
}

PATCHER_EOF

echo ""
echo "Running installer..."
WORKSPACE_ROOT=~/workspace node "$STAGE/patch-publish-center.cjs"
INSTALL_STATUS=$?

echo ""
echo "Syntax-checking backend files..."
node -c ~/workspace/src/models/Batch.js && echo "  OK: Batch.js"
node -c ~/workspace/src/models/TestSeries.js && echo "  OK: TestSeries.js"
node -c ~/workspace/src/routes/batchManagerUltra.js && echo "  OK: batchManagerUltra.js"
node -c ~/workspace/src/routes/testSeriesManagerUltra.js && echo "  OK: testSeriesManagerUltra.js"
node -c ~/workspace/src/routes/studentBatches.js && echo "  OK: studentBatches.js"

rm -rf "$STAGE"

if [ "$INSTALL_STATUS" -eq 0 ]; then
  echo ""
  echo "DONE -- Publish Center installed. Batch Detail Page and Test Series Detail Page ke Settings tab ke baad ab PUBLISH CENTER tab dikhega."
  echo "Ab server restart karo: pkill -f \"node src/index.js\" 2>/dev/null; cd ~/workspace && node src/index.js"
else
  echo ""
  echo "WARNING -- kuch file(s) auto-patch nahi ho payi, upar dekho kaunsi, aur wo file dobara share karo."
fi
