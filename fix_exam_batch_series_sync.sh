#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX: Assigned exams not showing in My Exams / Batch-Series Workspace
# Root cause: batchManagerUltra.js + testSeriesManagerUltra.js assign/
# unassign routes only wrote to Batch.exams[] / TestSeries.tests[]
# arrays, but examFlow.js (My Exams) + studentBatchWorkspace.js
# (Workspace Exams tab) only read Exam.batch / Exam.multiBatch /
# Exam.testSeriesId fields. This script dual-writes those Exam fields
# on every assign/unassign so both read-paths work.
#
# Uses a Node.js exact-string patcher (NOT sed -i, NOT python) —
# fails loudly if anchor text doesn't match, so no silent corruption.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_exam_sync.js << 'NODEEOF'
const fs = require('fs');

function patchFile(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error('❌ FAILED — anchor not found for: ' + label + ' in ' + path);
      console.error('   File may have changed since last read. ABORTING (no changes written).');
      process.exit(1);
    }
    const count = src.split(oldStr).length - 1;
    if (count > 1) {
      console.error('❌ FAILED — anchor for "' + label + '" is not unique (' + count + ' matches) in ' + path);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src, 'utf8');
  console.log('✅ Patched: ' + path);
}

// ── 1. batchManagerUltra.js — POST /:id/exams/assign ──────────────
patchFile('src/routes/batchManagerUltra.js', [
  [
    'assign route',
`router.post('/:id/exams/assign', auth, isAdmin, async (req, res) => {
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
});`,
`router.post('/:id/exams/assign', auth, isAdmin, async (req, res) => {
  try {
    const { examId } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = batch.exams || [];
    if (!batch.exams.some(e => String(e) === String(examId))) batch.exams.push(examId);
    batch.lastActivityAt = new Date();
    await batch.save();

    // F53 FIX — dual-write Exam.batch/multiBatch so My Exams (examFlow.js)
    // and Batch Workspace (studentBatchWorkspace.js) can see this exam.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(examId);
      if (examDoc) {
        const bid = String(batch._id);
        if (!examDoc.batch) {
          examDoc.batch = bid;
        } else if (String(examDoc.batch) !== bid) {
          examDoc.multiBatch = examDoc.multiBatch || [];
          if (!examDoc.multiBatch.some(b => String(b) === bid)) examDoc.multiBatch.push(bid);
        }
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-batch sync failed:', syncErr.message); }

    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_assigned', newValue: { examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
  ],
  [
    'unassign route',
`router.delete('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    await batch.save();
    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_removed', newValue: { examId: req.params.examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`,
`router.delete('/:id/exams/:examId', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.exams = (batch.exams || []).filter(e => String(e) !== String(req.params.examId));
    await batch.save();

    // F53 FIX — unlink Exam.batch/multiBatch on unassign
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(req.params.examId);
      if (examDoc) {
        const bid = String(req.params.id);
        if (String(examDoc.batch) === bid) {
          examDoc.batch = (examDoc.multiBatch && examDoc.multiBatch.length) ? examDoc.multiBatch.shift() : '';
        }
        examDoc.multiBatch = (examDoc.multiBatch || []).filter(b => String(b) !== bid);
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-batch unsync failed:', syncErr.message); }

    await logAudit({ batchId: batch._id, field: 'exams', action: 'exam_removed', newValue: { examId: req.params.examId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
  ]
]);

// ── 2. testSeriesManagerUltra.js — POST /:id/tests/assign ─────────
patchFile('src/routes/testSeriesManagerUltra.js', [
  [
    'assign route',
`router.post('/:id/tests/assign', auth, isAdmin, async (req, res) => {
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
});`,
`router.post('/:id/tests/assign', auth, isAdmin, async (req, res) => {
  try {
    const { testId } = req.body;
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = series.tests || [];
    if (!series.tests.some(e => String(e) === String(testId))) series.tests.push(testId);
    series.lastActivityAt = new Date();
    await series.save();

    // F53 FIX — dual-write Exam.testSeriesId so My Exams (examFlow.js)
    // and Batch/Series Workspace (studentBatchWorkspace.js) can see this exam.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(testId);
      if (examDoc) {
        examDoc.testSeriesId = series._id;
        if (examDoc.assignmentType !== 'series') examDoc.assignmentType = 'series';
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-series sync failed:', syncErr.message); }

    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_assigned', newValue: { testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
  ],
  [
    'unassign route',
`router.delete('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
    await series.save();
    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_removed', newValue: { testId: req.params.testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`,
`router.delete('/:id/tests/:testId', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id);
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    series.tests = (series.tests || []).filter(e => String(e) !== String(req.params.testId));
    await series.save();

    // F53 FIX — unlink Exam.testSeriesId on unassign
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(req.params.testId);
      if (examDoc && String(examDoc.testSeriesId) === String(series._id)) {
        examDoc.testSeriesId = null;
        if (examDoc.assignmentType === 'series') examDoc.assignmentType = 'individual';
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-series unsync failed:', syncErr.message); }

    await logAudit({ seriesId: series._id, field: 'tests', action: 'test_removed', newValue: { testId: req.params.testId }, changedBy: req.user.id, changedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
  ]
]);

// ── 3. One-time backfill — fix EXISTING already-assigned exams ────
NODEEOF

cat >> /tmp/patch_exam_sync.js << 'NODEEOF2'

console.log('✅ All files patched successfully.');
NODEEOF2

node /tmp/patch_exam_sync.js
rm /tmp/patch_exam_sync.js

echo ""
echo "=== Backfill: syncing EXISTING assignments (already in Batch.exams[] / TestSeries.tests[]) ==="
cat > /tmp/backfill_exam_sync.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const Batch = require('./src/models/Batch');
  let TestSeries;
  try { TestSeries = require('./src/models/TestSeries'); } catch (e) { TestSeries = null; }

  let examUpdates = 0;

  const batches = await Batch.find({ exams: { $exists: true, $ne: [] } }).select('_id exams').lean();
  for (const b of batches) {
    for (const examId of (b.exams || [])) {
      const examDoc = await Exam.findById(examId);
      if (!examDoc) continue;
      const bid = String(b._id);
      let changed = false;
      if (!examDoc.batch) { examDoc.batch = bid; changed = true; }
      else if (String(examDoc.batch) !== bid) {
        examDoc.multiBatch = examDoc.multiBatch || [];
        if (!examDoc.multiBatch.some(x => String(x) === bid)) { examDoc.multiBatch.push(bid); changed = true; }
      }
      if (changed) { await examDoc.save(); examUpdates++; }
    }
  }

  if (TestSeries) {
    const seriesList = await TestSeries.find({ tests: { $exists: true, $ne: [] } }).select('_id tests').lean();
    for (const s of seriesList) {
      for (const testId of (s.tests || [])) {
        const examDoc = await Exam.findById(testId);
        if (!examDoc) continue;
        let changed = false;
        if (String(examDoc.testSeriesId) !== String(s._id)) { examDoc.testSeriesId = s._id; changed = true; }
        if (examDoc.assignmentType !== 'series') { examDoc.assignmentType = 'series'; changed = true; }
        if (changed) { await examDoc.save(); examUpdates++; }
      }
    }
  }

  console.log('✅ Backfill complete. Exams updated: ' + examUpdates);
  process.exit(0);
}).catch(e => { console.error('ERROR:', e.message); process.exit(1); });
EOF
node /tmp/backfill_exam_sync.js
rm /tmp/backfill_exam_sync.js

echo ""
echo "=== DONE ==="
echo "Next steps:"
echo "1. git add -A && git commit -m 'F53: sync Exam.batch/multiBatch/testSeriesId on batch/series assign-unassign' && git push"
echo "2. Restart backend (Render will auto-redeploy on push)"
echo "3. NOTE: Existing test exams are all in 'draft' status — they still need to be"
echo "   Published (Admin Panel -> Create Exam Wizard -> Step 3 -> Publish Now / Schedule)"
echo "   before they'll appear anywhere on student side. This is expected behavior,"
echo "   not part of this bug."
