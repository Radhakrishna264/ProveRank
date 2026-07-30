#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX v2: Route 1 patch used examDoc.save() which triggers FULL
# document schema validation. Some legacy exam docs have corrupt
# pre-existing data (e.g. sections=string instead of array, status
# with invalid enum value) causing save() to throw and the assign
# action to fail with 500.
#
# This patch switches those sync blocks to Exam.updateOne($set,
# {runValidators:false}) — updates ONLY the batch/testSeriesId
# fields, doesn't touch/validate the rest of the (already broken)
# document. Also fixes the backfill script the same way.
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_v2.js << 'NODEEOF'
const fs = require('fs');

function patchFile(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error('❌ FAILED — anchor not found for: ' + label + ' in ' + path);
      process.exit(1);
    }
    const count = src.split(oldStr).length - 1;
    if (count > 1) {
      console.error('❌ FAILED — anchor for "' + label + '" is not unique (' + count + ') in ' + path);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src, 'utf8');
  console.log('✅ Patched: ' + path);
}

// ── batchManagerUltra.js ────────────────────────────────────────
patchFile('src/routes/batchManagerUltra.js', [
  [
    'assign sync block -> updateOne',
`    // F53 FIX — dual-write Exam.batch/multiBatch so My Exams (examFlow.js)
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
    } catch (syncErr) { console.error('F53 exam-batch sync failed:', syncErr.message); }`,
`    // F53 FIX — dual-write Exam.batch/multiBatch so My Exams (examFlow.js)
    // and Batch Workspace (studentBatchWorkspace.js) can see this exam.
    // updateOne($set, runValidators:false) — avoids full-doc validation
    // crash on legacy exam docs with pre-existing invalid data.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(examId).select('batch multiBatch').lean();
      if (examDoc) {
        const bid = String(batch._id);
        const upd = {};
        if (!examDoc.batch) {
          upd.batch = bid;
        } else if (String(examDoc.batch) !== bid) {
          const mb = examDoc.multiBatch || [];
          if (!mb.some(b => String(b) === bid)) upd.multiBatch = [...mb, bid];
        }
        if (Object.keys(upd).length) {
          await Exam.updateOne({ _id: examId }, { $set: upd }, { runValidators: false });
        }
      }
    } catch (syncErr) { console.error('F53 exam-batch sync failed:', syncErr.message); }`
  ],
  [
    'unassign sync block -> updateOne',
`    // F53 FIX — unlink Exam.batch/multiBatch on unassign
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
    } catch (syncErr) { console.error('F53 exam-batch unsync failed:', syncErr.message); }`,
`    // F53 FIX — unlink Exam.batch/multiBatch on unassign
    // updateOne($set, runValidators:false) — avoids full-doc validation crash.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(req.params.examId).select('batch multiBatch').lean();
      if (examDoc) {
        const bid = String(req.params.id);
        const upd = {};
        let mb = examDoc.multiBatch || [];
        if (String(examDoc.batch) === bid) {
          upd.batch = mb.length ? String(mb[0]) : '';
          mb = mb.slice(1);
        }
        upd.multiBatch = mb.filter(b => String(b) !== bid);
        await Exam.updateOne({ _id: req.params.examId }, { $set: upd }, { runValidators: false });
      }
    } catch (syncErr) { console.error('F53 exam-batch unsync failed:', syncErr.message); }`
  ]
]);

// ── testSeriesManagerUltra.js ───────────────────────────────────
patchFile('src/routes/testSeriesManagerUltra.js', [
  [
    'assign sync block -> updateOne',
`    // F53 FIX — dual-write Exam.testSeriesId so My Exams (examFlow.js)
    // and Batch/Series Workspace (studentBatchWorkspace.js) can see this exam.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(testId);
      if (examDoc) {
        examDoc.testSeriesId = series._id;
        if (examDoc.assignmentType !== 'series') examDoc.assignmentType = 'series';
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-series sync failed:', syncErr.message); }`,
`    // F53 FIX — dual-write Exam.testSeriesId so My Exams (examFlow.js)
    // and Batch/Series Workspace (studentBatchWorkspace.js) can see this exam.
    // updateOne($set, runValidators:false) — avoids full-doc validation crash.
    try {
      const Exam = mongoose.model('Exam');
      await Exam.updateOne(
        { _id: testId },
        { $set: { testSeriesId: series._id, assignmentType: 'series' } },
        { runValidators: false }
      );
    } catch (syncErr) { console.error('F53 exam-series sync failed:', syncErr.message); }`
  ],
  [
    'unassign sync block -> updateOne',
`    // F53 FIX — unlink Exam.testSeriesId on unassign
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(req.params.testId);
      if (examDoc && String(examDoc.testSeriesId) === String(series._id)) {
        examDoc.testSeriesId = null;
        if (examDoc.assignmentType === 'series') examDoc.assignmentType = 'individual';
        await examDoc.save();
      }
    } catch (syncErr) { console.error('F53 exam-series unsync failed:', syncErr.message); }`,
`    // F53 FIX — unlink Exam.testSeriesId on unassign
    // updateOne($set, runValidators:false) — avoids full-doc validation crash.
    try {
      const Exam = mongoose.model('Exam');
      const examDoc = await Exam.findById(req.params.testId).select('testSeriesId assignmentType').lean();
      if (examDoc && String(examDoc.testSeriesId) === String(series._id)) {
        const upd = { testSeriesId: null };
        if (examDoc.assignmentType === 'series') upd.assignmentType = 'individual';
        await Exam.updateOne({ _id: req.params.testId }, { $set: upd }, { runValidators: false });
      }
    } catch (syncErr) { console.error('F53 exam-series unsync failed:', syncErr.message); }`
  ]
]);

console.log('✅ v2 patch complete.');
NODEEOF

node /tmp/patch_v2.js
rm /tmp/patch_v2.js

echo ""
echo "=== Re-running backfill (fixed: updateOne instead of .save()) ==="
cat > backfill_exam_sync_v2.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const Batch = require('./src/models/Batch');
  let TestSeries;
  try { TestSeries = require('./src/models/TestSeries'); } catch (e) { TestSeries = null; }

  let examUpdates = 0;
  let skipped = 0;

  const batches = await Batch.find({ exams: { $exists: true, $ne: [] } }).select('_id exams').lean();
  for (const b of batches) {
    for (const examId of (b.exams || [])) {
      const examDoc = await Exam.findById(examId).select('batch multiBatch').lean();
      if (!examDoc) { skipped++; continue; }
      const bid = String(b._id);
      const upd = {};
      if (!examDoc.batch) { upd.batch = bid; }
      else if (String(examDoc.batch) !== bid) {
        const mb = examDoc.multiBatch || [];
        if (!mb.some(x => String(x) === bid)) upd.multiBatch = [...mb, bid];
      }
      if (Object.keys(upd).length) {
        await Exam.updateOne({ _id: examId }, { $set: upd }, { runValidators: false });
        examUpdates++;
      }
    }
  }

  if (TestSeries) {
    const seriesList = await TestSeries.find({ tests: { $exists: true, $ne: [] } }).select('_id tests').lean();
    for (const s of seriesList) {
      for (const testId of (s.tests || [])) {
        const examDoc = await Exam.findById(testId).select('testSeriesId assignmentType').lean();
        if (!examDoc) { skipped++; continue; }
        const upd = {};
        if (String(examDoc.testSeriesId) !== String(s._id)) upd.testSeriesId = s._id;
        if (examDoc.assignmentType !== 'series') upd.assignmentType = 'series';
        if (Object.keys(upd).length) {
          await Exam.updateOne({ _id: testId }, { $set: upd }, { runValidators: false });
          examUpdates++;
        }
      }
    }
  }

  console.log('✅ Backfill complete. Exams updated: ' + examUpdates + ' | Skipped (not found): ' + skipped);
  process.exit(0);
}).catch(e => { console.error('ERROR:', e.message); process.exit(1); });
EOF
node backfill_exam_sync_v2.js
rm backfill_exam_sync_v2.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'F53 v2: use updateOne to avoid full-doc validation crash' && git push"
