#!/bin/bash
# ProveRank — PASS 2: Remove Batch from mixed files (exam creation, listing,
# announcements, entry-proctoring, exam-flow visibility). TestSeries logic
# is kept and, where it was piggybacking on the Batch collection (a latent
# bug), fixed to use the real TestSeries collection.
# Does NOT touch: Batch.js model, examInstance.js, paperGenerator.js,
# contentForge.js (backend route), or any model files — that is Pass 3.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/pass2_backup_$ts.tar.gz \
  src/routes/examSubmission.js src/utils/examBuilder.js src/routes/adminSystem.js \
  src/routes/announcements.js src/routes/examFlow.js src/routes/examWizardRoutes.js \
  src/routes/examListing.js src/routes/entryProctoringControl.js \
  frontend/app/admin/x7k2p/CreateExamWizard.tsx frontend/app/admin/x7k2p/SmartPaperGen.tsx \
  frontend/app/admin/x7k2p/ContentForge.tsx frontend/app/admin/x7k2p/AllExams.tsx \
  frontend/app/admin/x7k2p/AdminAnnouncements.tsx 2>/dev/null || true
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/pass2_backup_$ts.tar.gz"

node << 'NODEEOF'
const fs = require('fs');
const path = require('path');

function editFile(relPath, edits) {
  const full = path.join(process.cwd(), relPath);
  let lines = fs.readFileSync(full, 'utf8').split('\n');
  for (const e of edits) {
    const actual = lines.slice(e.start - 1, e.end).join('\n');
    const expected = e.old.join('\n');
    if (actual !== expected) {
      console.error(`\nABORT: ${relPath} lines ${e.start}-${e.end} mismatch.`);
      console.error('--- EXPECTED ---\n' + expected);
      console.error('--- FOUND ---\n' + actual);
      process.exit(1);
    }
  }
  const sorted = [...edits].sort((a, b) => b.start - a.start);
  for (const e of sorted) lines.splice(e.start - 1, e.end - e.start + 1, ...e.new);
  fs.writeFileSync(full, lines.join('\n'));
  console.log(`OK — ${relPath}: applied ${edits.length} edit(s).`);
}

// ════════════════════════════════════════════════════════════
// 1) src/routes/examSubmission.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/examSubmission.js', [{
  start: 113, end: 136,
  old: [
"try {",
"  if (req.user && req.user.id) {",
"    const mongoose = require('mongoose');",
"    const User = require('../models/User');",
"    const Exam = require('../models/Exam');",
"    const exam = await Exam.findById(req.body.examId || req.params.examId).lean();",
"    if (exam && exam.batch) {",
"      const Batch = mongoose.model('Batch');",
"      // F58 FIX — exam.batch is normally an ObjectId string (per Assign System fix),",
"      // not a batch name. Try ID lookup first, fall back to legacy name-regex lookup.",
"      let batchDoc = mongoose.Types.ObjectId.isValid(exam.batch) ? await Batch.findById(exam.batch).lean() : null;",
"      if (!batchDoc) batchDoc = await Batch.findOne({ name: { $regex: exam.batch, $options: 'i' } }).lean();",
"      if (batchDoc) {",
"        const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });",
"        const meta = userDoc?.enrolledBatchesMeta || [];",
"        const mIdx = meta.findIndex(m => m.batchId && m.batchId.toString() === batchDoc._id.toString());",
"        if (mIdx >= 0) {",
"          await User.collection.updateOne({ _id: new mongoose.Types.ObjectId(req.user.id) }, { $inc: { [`enrolledBatchesMeta.${mIdx}.testsCompleted`]: 1 } });",
"          console.log('Progress synced for batch:', batchDoc.name);",
"        }",
"      }",
"    }",
"  }",
"} catch(e) { /* silent */ }",
  ],
  new: [
"// (Batch progress-sync removed — Batch system deprecated. Test Series",
"// equivalent can be added here later if needed.)",
  ],
}]);

// ════════════════════════════════════════════════════════════
// 2) src/utils/examBuilder.js
// ════════════════════════════════════════════════════════════
editFile('src/utils/examBuilder.js', [
{
  start: 3, end: 3,
  old: ["const Batch = require('../models/Batch');"],
  new: [],
},
{
  start: 67, end: 67,
  old: [" *   assignment        - { assignmentType, batch, multiBatch, seriesName, notifyStudents }"],
  new: [" *   assignment        - { assignmentType, seriesName, notifyStudents }"],
},
{
  start: 150, end: 151,
  old: [
"    batch: assignmentType === 'batch' ? (assignment.batch || '') : '',",
"    multiBatch: assignment.multiBatch || [],",
  ],
  new: [],
},
{
  start: 188, end: 201,
  old: [
"  // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually",
"  // \"uploads\" into that batch/series (same fix applied to Create Exam wizard + Smart Paper Gen).",
"  try {",
"    if (assignmentType === 'batch' && assignment.batch) {",
"      await Batch.findByIdAndUpdate(assignment.batch, { $addToSet: { exams: exam._id } });",
"    } else if (assignmentType === 'series' && assignment.testSeriesId) {",
"      await TestSeries.findByIdAndUpdate(assignment.testSeriesId, { $addToSet: { tests: exam._id } });",
"    }",
"    if (assignment.multiBatch && assignment.multiBatch.length) {",
"      await Batch.updateMany({ _id: { $in: assignment.multiBatch } }, { $addToSet: { exams: exam._id } });",
"    }",
"  } catch (linkErr) {",
"    console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);",
"  }",
  ],
  new: [
"  // 🔧 FIX (Assign System) — link the exam back into the TestSeries so it actually",
"  // \"uploads\" into that series (same fix applied to Create Exam wizard + Smart Paper Gen).",
"  try {",
"    if (assignmentType === 'series' && assignment.testSeriesId) {",
"      await TestSeries.findByIdAndUpdate(assignment.testSeriesId, { $addToSet: { tests: exam._id } });",
"    }",
"  } catch (linkErr) {",
"    console.error('Assign-link warning (exam created but series link failed):', linkErr.message);",
"  }",
  ],
},
{
  start: 203, end: 218,
  old: [
"  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle",
"  let notifiedCount = 0;",
"  if (assignment.notifyStudents && assignment.batch) {",
"    try {",
"      const students = await User.find({ batch: assignment.batch, role: 'student' }).select('_id');",
"      const notifs = students.map(s => ({",
"        userId: s._id,",
"        batchId: assignment.batch,",
"        type: 'batch_update', // reuse existing enum value (no model changes needed)",
"        title: 'New Exam Published',",
"        message: `A new exam \"${exam.title}\" has been added to your batch.`,",
"        link: `/exam/${exam._id}`,",
"      }));",
"      if (notifs.length > 0) { await StudentNotification.insertMany(notifs); notifiedCount = notifs.length; }",
"    } catch (e) { /* notification failure should never block exam creation */ }",
"  }",
  ],
  new: [
"  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle (batch-based notify removed)",
"  let notifiedCount = 0;",
  ],
},
]);

// ════════════════════════════════════════════════════════════
// 3) src/routes/adminSystem.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/adminSystem.js', [
{
  start: 236, end: 236,
  old: ["    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [], batches: [] } })"],
  new: ["    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [] } })"],
},
{
  start: 240, end: 240,
  old: ["    const [students, admins, exams, questions, batches] = await Promise.all(["],
  new: ["    const [students, admins, exams, questions] = await Promise.all(["],
},
{
  start: 244, end: 245,
  old: [
"      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray(),",
"      col('batches').find({ name: rx }).limit(6).project({ name: 1, description: 1 }).toArray()",
  ],
  new: ["      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray()"],
},
{
  start: 247, end: 247,
  old: ["    res.json({ success: true, results: { students, admins, exams, questions, batches } })"],
  new: ["    res.json({ success: true, results: { students, admins, exams, questions } })"],
},
{
  start: 255, end: 255,
  old: ["    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [], batches: [] } })"],
  new: ["    if (!q || q.length < 2) return res.json({ success: true, results: { students: [], admins: [], exams: [], questions: [] } })"],
},
{
  start: 258, end: 258,
  old: ["    const [students, exams, questions, batches] = await Promise.all(["],
  new: ["    const [students, exams, questions] = await Promise.all(["],
},
{
  start: 261, end: 262,
  old: [
"      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray(),",
"      col('batches').find({ name: rx }).limit(6).project({ name: 1, description: 1 }).toArray()",
  ],
  new: ["      col('questions').find({ $or: [{ text: rx }, { subject: rx }, { chapter: rx }] }).limit(8).project({ text: 1, subject: 1, chapter: 1, difficulty: 1 }).toArray()"],
},
{
  start: 264, end: 264,
  old: ["    res.json({ success: true, results: { students, admins: [], exams, questions, batches } })"],
  new: ["    res.json({ success: true, results: { students, admins: [], exams, questions } })"],
},
]);

// ════════════════════════════════════════════════════════════
// 4) src/routes/announcements.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/announcements.js', [
{
  start: 8, end: 8,
  old: ["const Batch = require('../models/Batch')"],
  new: ["const TestSeries = require('../models/TestSeries')"],
},
{
  start: 31, end: 39,
  old: [
"  if (audience.mode === 'batch' || audience.mode === 'testseries') {",
"    const ids = (audience.mode === 'batch' ? audience.batchIds : audience.testSeriesIds || audience.batchIds) || []",
"    const filtered = ids.filter(Boolean)",
"    if (!filtered.length) return []",
"    const batches = await Batch.find({ _id: { $in: filtered } }, 'students').lean()",
"    const studentIds = [...new Set(batches.flatMap(b => (b.students || []).map(String)))]",
"    if (!studentIds.length) return []",
"    return User.find({ _id: { $in: studentIds }, role: 'student', banned: { $ne: true } }, 'name email').lean()",
"  }",
  ],
  new: [
"  if (audience.mode === 'testseries') {",
"    const ids = (audience.testSeriesIds || []).filter(Boolean)",
"    if (!ids.length) return []",
"    const series = await TestSeries.find({ _id: { $in: ids } }, 'students').lean()",
"    const studentIds = [...new Set(series.flatMap(s => (s.students || []).map(String)))]",
"    if (!studentIds.length) return []",
"    return User.find({ _id: { $in: studentIds }, role: 'student', banned: { $ne: true } }, 'name email').lean()",
"  }",
  ],
},
{
  start: 102, end: 117,
  old: [
"    const myBatches = await Batch.find({ students: uid }, '_id').lean()",
"    const myBatchIds = myBatches.map(b => b._id)",
"    const now = new Date()",
"",
"    const list = await Announcement.find({",
"      status: 'sent',",
"      $and: [",
"        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] }, // F42B §3.9 expiry check",
"        { $or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'batch', 'audience.batchIds': { $in: myBatchIds } },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { $in: myBatchIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    }).sort({ pinned: -1, createdAt: -1 }).limit(150).lean()",
  ],
  new: [
"    const mySeries = await TestSeries.find({ students: uid }, '_id').lean()",
"    const mySeriesIds = mySeries.map(s => s._id)",
"    const now = new Date()",
"",
"    const list = await Announcement.find({",
"      status: 'sent',",
"      $and: [",
"        { $or: [{ expiryDate: null }, { expiryDate: { $gte: now } }] }, // F42B §3.9 expiry check",
"        { $or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { $in: mySeriesIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    }).sort({ pinned: -1, createdAt: -1 }).limit(150).lean()",
  ],
},
{
  start: 140, end: 155,
  old: [
"    const myBatches = await Batch.find({ students: uid }, '_id').lean()",
"    const myBatchIds = myBatches.map(b => b._id)",
"    const now = new Date()",
"    const count = await Announcement.countDocuments({",
"      status: 'sent',",
"      'readBy.userId': { \$ne: uid },",
"      \$and: [",
"        { \$or: [{ expiryDate: null }, { expiryDate: { \$gte: now } }] },",
"        { \$or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'batch', 'audience.batchIds': { \$in: myBatchIds } },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { \$in: myBatchIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    })",
  ],
  new: [
"    const mySeries = await TestSeries.find({ students: uid }, '_id').lean()",
"    const mySeriesIds = mySeries.map(s => s._id)",
"    const now = new Date()",
"    const count = await Announcement.countDocuments({",
"      status: 'sent',",
"      'readBy.userId': { \$ne: uid },",
"      \$and: [",
"        { \$or: [{ expiryDate: null }, { expiryDate: { \$gte: now } }] },",
"        { \$or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { \$in: mySeriesIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    })",
  ],
},
{
  start: 176, end: 191,
  old: [
"    const myBatches = await Batch.find({ students: uid }, '_id').lean()",
"    const myBatchIds = myBatches.map(b => b._id)",
"    const now = new Date()",
"    await Announcement.updateMany({",
"      status: 'sent',",
"      'readBy.userId': { \$ne: uid },",
"      \$and: [",
"        { \$or: [{ expiryDate: null }, { expiryDate: { \$gte: now } }] },",
"        { \$or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'batch', 'audience.batchIds': { \$in: myBatchIds } },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { \$in: myBatchIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    }, { \$push: { readBy: { userId: uid, readAt: now } } })",
  ],
  new: [
"    const mySeries = await TestSeries.find({ students: uid }, '_id').lean()",
"    const mySeriesIds = mySeries.map(s => s._id)",
"    const now = new Date()",
"    await Announcement.updateMany({",
"      status: 'sent',",
"      'readBy.userId': { \$ne: uid },",
"      \$and: [",
"        { \$or: [{ expiryDate: null }, { expiryDate: { \$gte: now } }] },",
"        { \$or: [",
"            { 'audience.mode': 'all' },",
"            { 'audience.mode': 'testseries', 'audience.testSeriesIds': { \$in: mySeriesIds } },",
"            { 'audience.mode': 'students', 'audience.studentIds': uid },",
"        ] },",
"      ],",
"    }, { \$push: { readBy: { userId: uid, readAt: now } } })",
  ],
},
{
  start: 217, end: 223,
  old: [
"// GET /batches — audience picker: batches/test series with live student counts (F42A §1.2.2 / §3.1.2)",
"adminRouter.get('/batches', verifyToken, requireAdminOrSuper, async (req, res) => {",
"  try {",
"    const batches = await Batch.find({ status: { \$ne: 'inactive' } }, 'name examType students').lean()",
"    res.json(batches.map(b => ({ _id: b._id, name: b.name, examType: b.examType, studentCount: (b.students || []).length })))",
"  } catch (err) { res.status(500).json({ message: err.message }) }",
"})",
  ],
  new: [
"// GET /series — audience picker: test series with live student counts (F42A §1.2.2 / §3.1.2)",
"adminRouter.get('/series', verifyToken, requireAdminOrSuper, async (req, res) => {",
"  try {",
"    const series = await TestSeries.find({ status: { \$ne: 'inactive' } }, 'name title examType students').lean()",
"    res.json(series.map(s => ({ _id: s._id, name: s.name || s.title, examType: s.examType, studentCount: (s.students || []).length })))",
"  } catch (err) { res.status(500).json({ message: err.message }) }",
"})",
  ],
},
{
  start: 306, end: 312,
  old: [
"    // Legacy-compat: existing BatchDetailOverlay widget & old compose form",
"    // send { batch: 'all' | batchId } instead of a full audience object.",
"    let audience = req.body.audience",
"    if (!audience && req.body.batch !== undefined) {",
"      audience = req.body.batch === 'all' || !req.body.batch ? { mode: 'all' } : { mode: 'batch', batchIds: [req.body.batch] }",
"    }",
"    if (!audience || !audience.mode) audience = { mode: 'all' }",
  ],
  new: [
"    let audience = req.body.audience",
"    if (!audience || !audience.mode) audience = { mode: 'all' }",
  ],
},
{
  start: 278, end: 278,
  old: ["    const list = await Announcement.find(q).populate('audience.batchIds', 'name').sort({ createdAt: -1 }).limit(200).lean()"],
  new: ["    const list = await Announcement.find(q).populate('audience.testSeriesIds', 'name').sort({ createdAt: -1 }).limit(200).lean()"],
},
]);

// ════════════════════════════════════════════════════════════
// 5) src/routes/examFlow.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/examFlow.js', [
{
  start: 7, end: 7,
  old: ["const Batch = require('../models/Batch');"],
  new: [],
},
{
  start: 30, end: 44,
  old: [
"async function getEnrollment(studentId) {",
"  const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(studentId) });",
"  const ids = (userDoc && userDoc.enrolledBatches) || [];",
"  const [batches, series] = await Promise.all([",
"    Batch.find({ _id: { \$in: ids } }).select('_id name').lean(),",
"    TestSeries ? TestSeries.find({ _id: { \$in: ids } }).select('_id title name').lean() : Promise.resolve([])",
"  ]);",
"  return {",
"    userDoc,",
"    batchIds: batches.map(b => String(b._id)),",
"    batchNames: batches.map(b => b.name).filter(Boolean),",
"    seriesIds: series.map(s => String(s._id)),",
"    seriesNames: series.map(s => s.title || s.name).filter(Boolean)",
"  };",
"}",
  ],
  new: [
"async function getEnrollment(studentId) {",
"  const userDoc = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(studentId) });",
"  const ids = (userDoc && userDoc.enrolledBatches) || [];",
"  const series = TestSeries ? await TestSeries.find({ _id: { \$in: ids } }).select('_id title name').lean() : [];",
"  return {",
"    userDoc,",
"    seriesIds: series.map(s => String(s._id)),",
"    seriesNames: series.map(s => s.title || s.name).filter(Boolean)",
"  };",
"}",
  ],
},
{
  start: 58, end: 72,
  old: [
"  // F54 FIX — an exam can be linked to BOTH a series and a batch at once.",
"  // Previously assignmentType==='series' short-circuited and skipped the",
"  // batch check entirely, hiding the exam from batch-only-enrolled students.",
"  // Now check series AND batch independently — visible if EITHER matches.",
"  if (exam.testSeriesId && enrollment.seriesIds.includes(String(exam.testSeriesId))) {",
"    return true;",
"  }",
"  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);",
"  if (hasBatchTarget) {",
"    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean).map(String);",
"    if (targets.some(t => enrollment.batchIds.includes(t) || enrollment.batchNames.includes(t))) {",
"      return true;",
"    }",
"  }",
"  return false; // F52/F54 — not linked to any enrolled batch or series, so must NOT show on My Exams",
  ],
  new: [
"  if (exam.testSeriesId && enrollment.seriesIds.includes(String(exam.testSeriesId))) {",
"    return true;",
"  }",
"  return false; // not linked to any enrolled series, so must NOT show on My Exams",
  ],
},
{
  start: 202, end: 206,
  old: [
"        assignmentType: e.assignmentType || 'individual',",
"        batch: e.batch,",
"        multiBatch: e.multiBatch,",
"        testSeriesId: e.testSeriesId || null,",
"        seriesName: e.seriesName || '',",
  ],
  new: [
"        assignmentType: e.assignmentType || 'individual',",
"        testSeriesId: e.testSeriesId || null,",
"        seriesName: e.seriesName || '',",
  ],
},
{
  start: 219, end: 224,
  old: [
"    res.json({",
"      success: true,",
"      exams: result,",
"      syncedBatches: enrollment.batchNames,",
"      syncedSeries: enrollment.seriesNames",
"    });",
  ],
  new: [
"    res.json({",
"      success: true,",
"      exams: result,",
"      syncedSeries: enrollment.seriesNames",
"    });",
  ],
},
]);

// ════════════════════════════════════════════════════════════
// 6) src/routes/examWizardRoutes.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/examWizardRoutes.js', [
{
  start: 20, end: 20,
  old: ["const getBatch      = () => mongoose.model('Batch');"],
  new: [],
},
{
  start: 115, end: 115,
  old: ["      liveQsRange, assignType, batchId, testSeriesId, multiBatches,"],
  new: ["      liveQsRange, assignType, testSeriesId,"],
},
{
  start: 160, end: 165,
  old: [
"      // 🔧 FIX — batch/multiBatch/testSeriesId now match actual Exam schema field names",
"      batch: assignType === 'batch' ? (batchId || '') : '',",
"      multiBatch: multiBatches || [],",
"      testSeriesId: assignType === 'series' ? (testSeriesId || null) : null,",
"      seriesName: resolvedSeriesName,",
"      assignmentType: assignType === 'batch' ? 'batch' : assignType === 'series' ? 'series' : 'individual',",
  ],
  new: [
"      testSeriesId: assignType === 'series' ? (testSeriesId || null) : null,",
"      seriesName: resolvedSeriesName,",
"      assignmentType: assignType === 'series' ? 'series' : 'individual',",
  ],
},
{
  start: 173, end: 185,
  old: [
"    // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually",
"    // \"uploads\" into that batch/series (previously this reverse-link never happened).",
"    try {",
"      if (assignType === 'batch' && batchId) {",
"        const Batch = getBatch();",
"        await Batch.findByIdAndUpdate(batchId, { \$addToSet: { exams: exam._id } });",
"      } else if (assignType === 'series' && testSeriesId) {",
"        const TestSeries = getTestSeries();",
"        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });",
"      }",
"    } catch (linkErr) {",
"      console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);",
"    }",
  ],
  new: [
"    // 🔧 FIX (Assign System) — link the exam back into the TestSeries so it actually",
"    // \"uploads\" into that series (previously this reverse-link never happened).",
"    try {",
"      if (assignType === 'series' && testSeriesId) {",
"        const TestSeries = getTestSeries();",
"        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });",
"      }",
"    } catch (linkErr) {",
"      console.error('Assign-link warning (exam created but series link failed):', linkErr.message);",
"    }",
  ],
},
{
  start: 362, end: 366,
  old: [
"    // Student count if batch assigned",
"    let studentCount = 0;",
"    try {",
"      if (exam.batch) { const User = getUser(); studentCount = await User.countDocuments({ role: 'student', batch: exam.batch }); }",
"    } catch {}",
  ],
  new: ["    let studentCount = 0;"],
},
{
  start: 435, end: 439,
  old: [
"    try {",
"      const Notification = mongoose.model('Notification');",
"      const User = getUser();",
"      const filter = exam.batch ? { role: 'student', batch: exam.batch } : { role: 'student' };",
"      const students = await User.find(filter).select('_id');",
  ],
  new: [
"    try {",
"      const Notification = mongoose.model('Notification');",
"      const User = getUser();",
"      const filter = { role: 'student' };",
"      const students = await User.find(filter).select('_id');",
  ],
},
]);

// ════════════════════════════════════════════════════════════
// 7) src/routes/examListing.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/examListing.js', [
{
  start: 53, end: 75,
  old: [
"function buildFilter(req) {",
"  const { search, status, category, subject, batch, series, startDate, endDate, needsAttention } = req.query",
"  const filter = visibilityFilter(req)",
"  filter.isArchived = { \$ne: true } // Feature 34 — archived exams only show in the Recycle Bin (/trash)",
"  if (search && String(search).trim()) filter.title = new RegExp(String(search).trim(), 'i')",
"  if (status) {",
"    const statuses = String(status).split(',').map(s => s.trim()).filter(Boolean)",
"    if (statuses.length) filter.status = { \$in: statuses }",
"  }",
"  if (category) filter.category = category",
"  if (subject) filter.subject = subject",
"  if (batch) filter.batch = batch",
"  if (series) filter.seriesName = series",
"  if (startDate || endDate) {",
"    filter['schedule.startTime'] = {}",
"    if (startDate) filter['schedule.startTime'].\$gte = new Date(startDate)",
"    if (endDate) filter['schedule.startTime'].\$lte = new Date(endDate)",
"  }",
"  if (needsAttention === 'true') {",
"    filter.\$or = [{ batch: '' }, { batch: null }, { questions: { \$size: 0 } }]",
"  }",
"  return filter",
"}",
  ],
  new: [
"function buildFilter(req) {",
"  const { search, status, category, subject, series, startDate, endDate, needsAttention } = req.query",
"  const filter = visibilityFilter(req)",
"  filter.isArchived = { \$ne: true } // Feature 34 — archived exams only show in the Recycle Bin (/trash)",
"  if (search && String(search).trim()) filter.title = new RegExp(String(search).trim(), 'i')",
"  if (status) {",
"    const statuses = String(status).split(',').map(s => s.trim()).filter(Boolean)",
"    if (statuses.length) filter.status = { \$in: statuses }",
"  }",
"  if (category) filter.category = category",
"  if (subject) filter.subject = subject",
"  if (series) filter.seriesName = series",
"  if (startDate || endDate) {",
"    filter['schedule.startTime'] = {}",
"    if (startDate) filter['schedule.startTime'].\$gte = new Date(startDate)",
"    if (endDate) filter['schedule.startTime'].\$lte = new Date(endDate)",
"  }",
"  if (needsAttention === 'true') {",
"    filter.\$or = [{ questions: { \$size: 0 } }]",
"  }",
"  return filter",
"}",
  ],
},
{
  start: 80, end: 95,
  old: [
"router.get('/filter-options', verifyToken, isAdmin, async (req, res) => {",
"  try {",
"    const filter = req.user.role === 'superadmin' ? {} : { createdBy: req.user.id }",
"    const [categories, subjects, batches, series] = await Promise.all([",
"      Exam.distinct('category', filter),",
"      Exam.distinct('subject', filter),",
"      Exam.distinct('batch', filter),",
"      Exam.distinct('seriesName', filter)",
"    ])",
"    res.json({",
"      success: true,",
"      categories: categories.filter(Boolean),",
"      subjects: subjects.filter(Boolean),",
"      batches: batches.filter(Boolean),",
"      series: series.filter(Boolean)",
"    })",
  ],
  new: [
"router.get('/filter-options', verifyToken, isAdmin, async (req, res) => {",
"  try {",
"    const filter = req.user.role === 'superadmin' ? {} : { createdBy: req.user.id }",
"    const [categories, subjects, series] = await Promise.all([",
"      Exam.distinct('category', filter),",
"      Exam.distinct('subject', filter),",
"      Exam.distinct('seriesName', filter)",
"    ])",
"    res.json({",
"      success: true,",
"      categories: categories.filter(Boolean),",
"      subjects: subjects.filter(Boolean),",
"      series: series.filter(Boolean)",
"    })",
  ],
},
{
  start: 135, end: 135,
  old: ["      .select('title category subject type duration totalMarks status batch seriesName schedule createdAt isPinned questions createdBy markingScheme assignmentType clonedFrom')"],
  new: ["      .select('title category subject type duration totalMarks status seriesName schedule createdAt isPinned questions createdBy markingScheme assignmentType clonedFrom')"],
},
{
  start: 310, end: 310,
  old: ["    if (b.batch !== undefined) exam.batch = b.batch"],
  new: [],
},
{
  start: 421, end: 421,
  old: ["      .select('title category subject type duration totalMarks status batch seriesName schedule createdAt isPinned questions')"],
  new: ["      .select('title category subject type duration totalMarks status seriesName schedule createdAt isPinned questions')"],
},
{
  start: 432, end: 432,
  old: ["      Batch: e.batch,"],
  new: [],
},
{
  start: 499, end: 504,
  old: [
"    // 31.8 — clone to a different batch if provided, else keep original's batch",
"    if (b.targetBatch !== undefined) {",
"      obj.batch = b.targetBatch",
"      obj.multiBatch = []",
"      if (b.targetBatch) obj.assignmentType = 'batch'",
"    }",
  ],
  new: [],
},
{
  start: 519, end: 530,
  old: [
"    // F61 FIX — reverse-link the clone into Batch.exams / TestSeries.tests so it",
"    // immediately shows up in the Assigned list, mirroring the normal assign flow.",
"    try {",
"      if (b.targetBatch) {",
"        const Batch = require('../models/Batch')",
"        await Batch.updateOne({ _id: b.targetBatch }, { \$addToSet: { exams: cloned._id } })",
"      }",
"      if (b.targetSeries) {",
"        const TestSeries = require('../models/TestSeries')",
"        await TestSeries.updateOne({ _id: b.targetSeries }, { \$addToSet: { tests: cloned._id } })",
"      }",
"    } catch (linkErr) { console.error('clone-advanced reverse-link warning:', linkErr.message) }",
  ],
  new: [
"    // F61 FIX — reverse-link the clone into TestSeries.tests so it",
"    // immediately shows up in the Assigned list, mirroring the normal assign flow.",
"    try {",
"      if (b.targetSeries) {",
"        const TestSeries = require('../models/TestSeries')",
"        await TestSeries.updateOne({ _id: b.targetSeries }, { \$addToSet: { tests: cloned._id } })",
"      }",
"    } catch (linkErr) { console.error('clone-advanced reverse-link warning:', linkErr.message) }",
  ],
},
]);

// ════════════════════════════════════════════════════════════
// 8) src/routes/entryProctoringControl.js
// ════════════════════════════════════════════════════════════
editFile('src/routes/entryProctoringControl.js', [
{
  start: 31, end: 31,
  old: ["let Batch; try { Batch = require('../models/Batch'); } catch (e) { Batch = null; }"],
  new: [],
},
{
  start: 110, end: 114,
  old: [
"  const batchTargets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean);",
"  if (batchTargets.length) {",
"    policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'batch', 'scope.batchId': { \$in: batchTargets.map(toId).filter(Boolean) } }).sort({ version: -1 }).lean();",
"    if (policy) return { exam, policy, resolvedFrom: 'batch' };",
"  }",
  ],
  new: [],
},
{
  start: 223, end: 223,
  old: ["    const { scopeType, examId, batchId, testSeriesId, status, search } = req.query;"],
  new: ["    const { scopeType, examId, testSeriesId, status, search } = req.query;"],
},
{
  start: 227, end: 227,
  old: ["    if (batchId) filter['scope.batchId'] = toId(batchId);"],
  new: [],
},
{
  start: 609, end: 615,
  old: [
"    const { examId, batchId, broadcastType, title, message, channel, scheduledAt } = req.body;",
"    if (!title || !message) return res.status(400).json({ error: 'title and message required' });",
"    const validTypes = ['waiting_room_announcement', 'instruction_update', 'consent_reminder', 'camera_reminder', 'fullscreen_reminder', 'join_window_warning', 'emergency_notice'];",
"    if (!validTypes.includes(broadcastType)) return res.status(400).json({ error: 'Invalid broadcastType' });",
"",
"    let audience = { mode: 'all' };",
"    if (batchId) audience = { mode: 'batch', batchIds: [batchId] };",
  ],
  new: [
"    const { examId, broadcastType, title, message, channel, scheduledAt } = req.body;",
"    if (!title || !message) return res.status(400).json({ error: 'title and message required' });",
"    const validTypes = ['waiting_room_announcement', 'instruction_update', 'consent_reminder', 'camera_reminder', 'fullscreen_reminder', 'join_window_warning', 'emergency_notice'];",
"    if (!validTypes.includes(broadcastType)) return res.status(400).json({ error: 'Invalid broadcastType' });",
"",
"    let audience = { mode: 'all' };",
  ],
},
{
  start: 715, end: 715,
  old: ["// Effective (resolved) policy for a given exam — exam → batch → series → global → schema defaults"],
  new: ["// Effective (resolved) policy for a given exam — exam → series → global → schema defaults"],
},
]);

console.log('\\n✅ All backend edits applied successfully.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Frontend files (5)"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = require('path');

function editFile(relPath, edits) {
  const full = path.join(process.cwd(), relPath);
  let lines = fs.readFileSync(full, 'utf8').split('\n');
  for (const e of edits) {
    const actual = lines.slice(e.start - 1, e.end).join('\n');
    const expected = e.old.join('\n');
    if (actual !== expected) {
      console.error(`\nABORT: ${relPath} lines ${e.start}-${e.end} mismatch.`);
      console.error('--- EXPECTED ---\n' + expected);
      console.error('--- FOUND ---\n' + actual);
      process.exit(1);
    }
  }
  const sorted = [...edits].sort((a, b) => b.start - a.start);
  for (const e of sorted) lines.splice(e.start - 1, e.end - e.start + 1, ...e.new);
  fs.writeFileSync(full, lines.join('\n'));
  console.log(`OK — ${relPath}: applied ${edits.length} edit(s).`);
}

// ════════════════════════════════════════════════════════════
// 9) frontend/app/admin/x7k2p/CreateExamWizard.tsx
// ════════════════════════════════════════════════════════════
editFile('frontend/app/admin/x7k2p/CreateExamWizard.tsx', [
{
  start: 41, end: 41,
  old: ["interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; fetchAll:()=>void; batches:any[]; testSeries:any[]; exams:any[]; questions:any[]; pendingTemplate?:any; onTemplateConsumed?:()=>void }"],
  new: ["interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; fetchAll:()=>void; testSeries:any[]; exams:any[]; questions:any[]; pendingTemplate?:any; onTemplateConsumed?:()=>void }"],
},
{
  start: 47, end: 47,
  old: ["export default function CreateExamWizard({ token, API, T, fetchAll, batches, testSeries, exams, questions, pendingTemplate, onTemplateConsumed }:Props) {"],
  new: ["export default function CreateExamWizard({ token, API, T, fetchAll, testSeries, exams, questions, pendingTemplate, onTemplateConsumed }:Props) {"],
},
{
  start: 80, end: 83,
  old: [
"  const [assignType, setAssignType]   = useState<'batch'|'series'|'open'>('open')",
"  const [batchId, setBatchId]         = useState('')",
"  const [testSeriesId, setTestSeriesId] = useState('')",
"  const [multiBatches, setMultiBatches] = useState<string[]>([])",
  ],
  new: [
"  const [assignType, setAssignType]   = useState<'series'|'open'>('open')",
"  const [testSeriesId, setTestSeriesId] = useState('')",
  ],
},
{
  start: 176, end: 176,
  old: ["        sectionWise, watermark, liveQsRange, assignType, batchId, testSeriesId, multiBatches, status: 'draft'"],
  new: ["        sectionWise, watermark, liveQsRange, assignType, testSeriesId, status: 'draft'"],
},
{
  start: 384, end: 384,
  old: ["    { label: 'Assignment configured',  ok: assignType === 'open' || !!batchId || !!testSeriesId },"],
  new: ["    { label: 'Assignment configured',  ok: assignType === 'open' || !!testSeriesId },"],
},
{
  start: 670, end: 688,
  old: [
"              {/* Batch / Test Series assignment */}",
"              <div style={cs}>",
"                <div style={{fontWeight:700,fontSize:13,color:PRP,marginBottom:14}}>🏫 Assign To</div>",
"                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>",
"                  {([['open','🌐 Open','All students'],['batch','🏫 Batch','Specific batch'],['series','📚 Test Series','Series group']] as const).map(([v,l,d])=>(",
"                    <div key={v} onClick={()=>{setAssignType(v);if(v!=='batch')setBatchId('');if(v!=='series')setTestSeriesId('')}} style={{padding:'10px',borderRadius:10,border:`1.5px solid ${assignType===v?PRP:BOR}`,background:assignType===v?`${PRP}12`:'transparent',cursor:'pointer',transition:'all 0.15s'}}>",
"                      <div style={{fontSize:13,fontWeight:700,color:assignType===v?PRP:TS,marginBottom:2}}>{l}</div>",
"                      <div style={{fontSize:10,color:DIM}}>{d}</div>",
"                    </div>",
"                  ))}",
"                </div>",
"                {assignType === 'batch' && (",
"                  <Field label=\"Select Batch\">",
"                    <select value={batchId} onChange={e=>setBatchId(e.target.value)} style={inp}>",
"                      <option value=\"\">— Select Batch —</option>",
"                      {batches.map((b:any)=><option key={b._id} value={b._id}>{b.name}{b.lifecycleStatus?` · ${b.lifecycleStatus}`:''}</option>)}",
"                    </select>",
"                  </Field>",
"                )}",
  ],
  new: [
"              {/* Test Series assignment */}",
"              <div style={cs}>",
"                <div style={{fontWeight:700,fontSize:13,color:PRP,marginBottom:14}}>🏫 Assign To</div>",
"                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>",
"                  {([['open','🌐 Open','All students'],['series','📚 Test Series','Series group']] as const).map(([v,l,d])=>(",
"                    <div key={v} onClick={()=>{setAssignType(v);if(v!=='series')setTestSeriesId('')}} style={{padding:'10px',borderRadius:10,border:`1.5px solid ${assignType===v?PRP:BOR}`,background:assignType===v?`${PRP}12`:'transparent',cursor:'pointer',transition:'all 0.15s'}}>",
"                      <div style={{fontSize:13,fontWeight:700,color:assignType===v?PRP:TS,marginBottom:2}}>{l}</div>",
"                      <div style={{fontSize:10,color:DIM}}>{d}</div>",
"                    </div>",
"                  ))}",
"                </div>",
  ],
},
{
  start: 723, end: 723,
  old: ["                    ['🏫',assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch not chosen'):assignType==='series'?(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series not chosen'):'Open Access'],"],
  new: ["                    ['🏫',assignType==='series'?(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series not chosen'):'Open Access'],"],
},
{
  start: 1041, end: 1041,
  old: ["                    ['🏫 Assignment',assignType==='open'?'Open Access':assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch'):(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series')],"],
  new: ["                    ['🏫 Assignment',assignType==='open'?'Open Access':(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series')],"],
},
{
  start: 1104, end: 1104,
  old: ["                  <div style={{fontSize:10,color:DIM}}>Based on {assignType==='batch'?'selected batch':'all students'}</div>"],
  new: ["                  <div style={{fontSize:10,color:DIM}}>Based on {assignType==='series'?'selected test series':'all students'}</div>"],
},
{
  start: 1124, end: 1124,
  old: ["                <div style={{fontSize:10,color:DIM,marginTop:2}}>Send notification to all students in assigned batch</div>"],
  new: ["                <div style={{fontSize:10,color:DIM,marginTop:2}}>Send notification to all students in assigned test series</div>"],
},
]);

console.log('\\n✅ CreateExamWizard.tsx done.');

// ════════════════════════════════════════════════════════════
// 10) frontend/app/admin/x7k2p/SmartPaperGen.tsx
// ════════════════════════════════════════════════════════════
editFile('frontend/app/admin/x7k2p/SmartPaperGen.tsx', [
{
  start: 55, end: 56,
  old: [
"export default function SmartPaperGen({ API, token, batches, testSeries }: { API: string; token: string; batches?: any[]; testSeries?: any[] }) {",
"  const uaeBatches = batches || [];",
  ],
  new: [
"export default function SmartPaperGen({ API, token, testSeries }: { API: string; token: string; testSeries?: any[] }) {",
  ],
},
{
  start: 100, end: 101,
  old: [
"  const [uaeAssignType, setUaeAssignType] = useState<'open'|'batch'|'series'>('open');",
"  const [uaeBatchId,    setUaeBatchId]    = useState('');",
  ],
  new: ["  const [uaeAssignType, setUaeAssignType] = useState<'open'|'series'>('open');"],
},
{
  start: 271, end: 271,
  old: ["          batchId:          uaeBatchId,"],
  new: [],
},
{
  start: 1013, end: 1024,
  old: [
"              {([['open','🌐 Open'],['batch','🏫 Batch'],['series','📚 Test Series']] as const).map(([v,l]) => (",
"                <button key={v} onClick={() => { setUaeAssignType(v); if (v!=='batch') setUaeBatchId(''); if (v!=='series') setUaeTestSeriesId(''); }} style={{ flex:1, padding:'8px', borderRadius:8, border:`1px solid ${uaeAssignType===v ? '#6366F1':'rgba(255,255,255,0.1)'}`, background: uaeAssignType===v ? 'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: uaeAssignType===v ? '#A5B4FC':'#64748B', cursor:'pointer', fontWeight:700, fontSize:11 }}>",
"                  {l}",
"                </button>",
"              ))}",
"            </div>",
"            {uaeAssignType === 'batch' && (",
"              <select value={uaeBatchId} onChange={e => setUaeBatchId(e.target.value)} style={{ ...S.inp, marginBottom:12 }}>",
"                <option value=\"\">— Select Batch —</option>",
"                {uaeBatches.map((b:any) => <option key={b._id} value={b._id}>{b.name}{b.lifecycleStatus?` · ${b.lifecycleStatus}`:''}</option>)}",
"              </select>",
"            )}",
  ],
  new: [
"              {([['open','🌐 Open'],['series','📚 Test Series']] as const).map(([v,l]) => (",
"                <button key={v} onClick={() => { setUaeAssignType(v); if (v!=='series') setUaeTestSeriesId(''); }} style={{ flex:1, padding:'8px', borderRadius:8, border:`1px solid ${uaeAssignType===v ? '#6366F1':'rgba(255,255,255,0.1)'}`, background: uaeAssignType===v ? 'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: uaeAssignType===v ? '#A5B4FC':'#64748B', cursor:'pointer', fontWeight:700, fontSize:11 }}>",
"                  {l}",
"                </button>",
"              ))}",
"            </div>",
  ],
},
]);

console.log('\\n✅ SmartPaperGen.tsx done.');

// ════════════════════════════════════════════════════════════
// 11) frontend/app/admin/x7k2p/AllExams.tsx
// ════════════════════════════════════════════════════════════
editFile('frontend/app/admin/x7k2p/AllExams.tsx', [
{
  start: 79, end: 79,
  old: ["  const [batchFilter, setBatchFilter] = useState('')"],
  new: [],
},
{
  start: 92, end: 93,
  old: [
"  const [filterOptions, setFilterOptions] = useState<any>({categories:[],subjects:[],batches:[],series:[]})",
"  const [realBatches, setRealBatches] = useState<any[]>([]) // synced live from Batch Manager (/api/admin/batch-controls)",
  ],
  new: ["  const [filterOptions, setFilterOptions] = useState<any>({categories:[],subjects:[],series:[]})"],
},
{
  start: 127, end: 127,
  old: ["  const [cloneForm, setCloneForm] = useState<any>({newTitle:'',startTime:'',endTime:'',targetBatch:'',seriesName:''})"],
  new: ["  const [cloneForm, setCloneForm] = useState<any>({newTitle:'',startTime:'',endTime:'',seriesName:''})"],
},
{
  start: 147, end: 147,
  old: ["  useEffect(()=>{ setPage(1) },[search,statusFilter,categoryFilter,subjectFilter,batchFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention])"],
  new: ["  useEffect(()=>{ setPage(1) },[search,statusFilter,categoryFilter,subjectFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention])"],
},
{
  start: 155, end: 155,
  old: ["    if(batchFilter) p.set('batch',batchFilter)"],
  new: [],
},
{
  start: 165, end: 165,
  old: ["  },[search,statusFilter,categoryFilter,subjectFilter,batchFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention,page])"],
  new: ["  },[search,statusFilter,categoryFilter,subjectFilter,seriesFilter,dateStart,dateEnd,sort,mine,viewAsAdmin,needsAttention,page])"],
},
{
  start: 184, end: 184,
  old: ["      if(d.success) setFilterOptions({categories:d.categories||[],subjects:d.subjects||[],batches:d.batches||[],series:d.series||[]})"],
  new: ["      if(d.success) setFilterOptions({categories:d.categories||[],subjects:d.subjects||[],series:d.series||[]})"],
},
{
  start: 188, end: 197,
  old: [
"  // ── synced live from the real Batch Manager — not just batch names already",
"  // used on past exams, so a brand-new batch with zero exams still shows up ──",
"  const fetchRealBatches = useCallback(async ()=>{",
"    try {",
"      const r = await fetch(`${API}/api/admin/batch-controls`,{headers:{Authorization:`Bearer ${token}`}})",
"      const d = await r.json()",
"      setRealBatches(d.batches||[])",
"    } catch {}",
"  },[API,token])",
"",
  ],
  new: [],
},
{
  start: 207, end: 207,
  old: ["  useEffect(()=>{ fetchRealBatches() },[fetchRealBatches])"],
  new: [],
},
{
  start: 257, end: 257,
  old: ["    setCloneForm({ newTitle: `Copy of ${exam.title}`, startTime:'', endTime:'', targetBatch: exam.batch||'', seriesName: exam.seriesName||'' })"],
  new: ["    setCloneForm({ newTitle: `Copy of ${exam.title}`, startTime:'', endTime:'', seriesName: exam.seriesName||'' })"],
},
{
  start: 409, end: 409,
  old: ["      batch: exam.batch||'', seriesName: exam.seriesName||'', watermark: !!exam.watermark,"],
  new: ["      seriesName: exam.seriesName||'', watermark: !!exam.watermark,"],
},
{
  start: 499, end: 499,
  old: ["  const clearAllFilters = () => { setSearchInput(''); setStatusFilter([]); setCategoryFilter(''); setSubjectFilter(''); setBatchFilter(''); setSeriesFilter(''); setDateStart(''); setDateEnd(''); setSort('newest'); setMine(false); setViewAsAdmin(''); setNeedsAttention(false) }"],
  new: ["  const clearAllFilters = () => { setSearchInput(''); setStatusFilter([]); setCategoryFilter(''); setSubjectFilter(''); setSeriesFilter(''); setDateStart(''); setDateEnd(''); setSort('newest'); setMine(false); setViewAsAdmin(''); setNeedsAttention(false) }"],
},
{
  start: 500, end: 500,
  old: ["  const activeFilterCount = [statusFilter.length>0,!!categoryFilter,!!subjectFilter,!!batchFilter,!!seriesFilter,!!dateStart||!!dateEnd,mine,!!viewAsAdmin,needsAttention].filter(Boolean).length"],
  new: ["  const activeFilterCount = [statusFilter.length>0,!!categoryFilter,!!subjectFilter,!!seriesFilter,!!dateStart||!!dateEnd,mine,!!viewAsAdmin,needsAttention].filter(Boolean).length"],
},
{
  start: 594, end: 602,
  old: [
"            {/* batch / series — 33.5 */}",
"            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>",
"              <div>",
"                <label style={lbl}>Batch</label>",
"                <select value={batchFilter} onChange={e=>setBatchFilter(e.target.value)} style={inp}>",
"                  <option value=\"\">All Batches</option>",
"                  {filterOptions.batches.map((b:string)=><option key={b} value={b}>{b}</option>)}",
"                </select>",
"              </div>",
  ],
  new: [
"            {/* series — 33.5 */}",
"            <div>",
  ],
},
{
  start: 652, end: 652,
  old: ["              ⚠️ Needs Attention (no batch assigned / 0 questions)"],
  new: ["              ⚠️ Needs Attention (0 questions)"],
},
{
  start: 720, end: 720,
  old: ["            const needsAttn = (!e.batch) || (e.questionCount===0)"],
  new: ["            const needsAttn = (e.questionCount===0)"],
},
{
  start: 746, end: 746,
  old: ["                      {e.batch && <Chip ico=\"📦\" label={e.batch} col={DIM}/>}"],
  new: [],
},
{
  start: 911, end: 917,
  old: [
"              <div>",
"                <label style={lbl}>Batch (change this to clone into a different batch)</label>",
"                <select value={cloneForm.targetBatch} onChange={e=>setCloneForm((f:any)=>({...f,targetBatch:e.target.value}))} style={inp}>",
"                  <option value=\"\">— Open / No Batch —</option>",
"                  {realBatches.map((b:any)=><option key={b._id} value={b.name}>{b.name}{b.status!=='active'?` (${b.status})`:''}</option>)}",
"                </select>",
"              </div>",
  ],
  new: [],
},
{
  start: 986, end: 986,
  old: ["                        {key:'duration',label:'Duration'},{key:'totalMarks',label:'Total Marks'},{key:'batch',label:'Batch'},"],
  new: ["                        {key:'duration',label:'Duration'},{key:'totalMarks',label:'Total Marks'},"],
},
{
  start: 1037, end: 1044,
  old: [
"              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>",
"                <div>",
"                  <label style={lbl}>Batch</label>",
"                  <select value={editForm.batch} onChange={e=>setEditForm((f:any)=>({...f,batch:e.target.value}))} style={inp}>",
"                    <option value=\"\">— Open / No Batch —</option>",
"                    {realBatches.map((b:any)=><option key={b._id} value={b.name}>{b.name}{b.status!=='active'?` (${b.status})`:''}</option>)}",
"                  </select>",
"                </div>",
  ],
  new: [],
},
]);

console.log('\\n✅ AllExams.tsx done.');

// ════════════════════════════════════════════════════════════
// 12) frontend/app/admin/x7k2p/AdminAnnouncements.tsx
// ════════════════════════════════════════════════════════════
editFile('frontend/app/admin/x7k2p/AdminAnnouncements.tsx', [
{
  start: 57, end: 58,
  old: [
"  const [audienceMode, setAudienceMode] = useState<'all' | 'batch' | 'testseries' | 'students'>('all')",
"  const [selBatchIds, setSelBatchIds] = useState<string[]>([])",
  ],
  new: ["  const [audienceMode, setAudienceMode] = useState<'all' | 'testseries' | 'students'>('all')"],
},
{
  start: 74, end: 74,
  old: ["  const [batches, setBatches] = useState<any[]>([])"],
  new: ["  const [seriesList, setSeriesList] = useState<any[]>([])"],
},
{
  start: 89, end: 89,
  old: ["  const loadBatches = () => fetch(`${API}/api/admin/announcements/batches`, { headers }).then(r => r.json()).then(d => setBatches(Array.isArray(d) ? d : [])).catch(() => {})"],
  new: ["  const loadSeries = () => fetch(`${API}/api/admin/announcements/series`, { headers }).then(r => r.json()).then(d => setSeriesList(Array.isArray(d) ? d : [])).catch(() => {})"],
},
{
  start: 103, end: 103,
  old: ["  useEffect(() => { if (token) { loadBatches(); loadTemplates(); loadStats(); loadHistory() } }, [token])"],
  new: ["  useEffect(() => { if (token) { loadSeries(); loadTemplates(); loadStats(); loadHistory() } }, [token])"],
},
{
  start: 134, end: 134,
  old: ["    setType('update'); setAudienceMode('all'); setSelBatchIds([]); setSelTestSeriesIds([]); setSelStudents([]); setStudentQuery(''); setStudentResults([])"],
  new: ["    setType('update'); setAudienceMode('all'); setSelTestSeriesIds([]); setSelStudents([]); setStudentQuery(''); setStudentResults([])"],
},
{
  start: 139, end: 139,
  old: ["    if (audienceMode === 'batch') return { mode: 'batch', batchIds: selBatchIds }"],
  new: [],
},
{
  start: 147, end: 147,
  old: ["    if (audienceMode === 'batch' && selBatchIds.length === 0) { notify('Select at least one batch', 'e'); return }"],
  new: [],
},
{
  start: 177, end: 177,
  old: ["    setSelBatchIds(mode === 'batch' ? (a.audience.batchIds || []).map((b: any) => b._id || b) : [])"],
  new: [],
},
{
  start: 220, end: 220,
  old: ["        <div style={{ fontSize: 12, color: T.DIM, marginBottom: 16 }}>Send broadcasts to all students or specific batches</div>"],
  new: ["        <div style={{ fontSize: 12, color: T.DIM, marginBottom: 16 }}>Send broadcasts to all students or specific test series</div>"],
},
{
  start: 227, end: 227,
  old: ["            <div style={{ fontSize: 11.5, color: T.DIM, marginTop: 3 }}>Send announcements via in-app notifications, email, or both. Target all students, specific batches, or individual students. Schedule for later or save as a draft.</div>"],
  new: ["            <div style={{ fontSize: 11.5, color: T.DIM, marginTop: 3 }}>Send announcements via in-app notifications, email, or both. Target all students, specific test series, or individual students. Schedule for later or save as a draft.</div>"],
},
{
  start: 283, end: 283,
  old: ["            {[{ v: 'all', l: '🌍 All Students' }, { v: 'batch', l: '🏫 Batches' }, { v: 'testseries', l: '🎯 Test Series' }, { v: 'students', l: '👤 Specific Students' }].map(a => ("],
  new: ["            {[{ v: 'all', l: '🌍 All Students' }, { v: 'testseries', l: '🎯 Test Series' }, { v: 'students', l: '👤 Specific Students' }].map(a => ("],
},
{
  start: 291, end: 330,
  old: [
"          {audienceMode === 'batch' && (",
"            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 8, marginBottom: 14, maxHeight: 220, overflowY: 'auto', padding: 4 }}>",
"              {batches.length === 0 && <div style={{ fontSize: 11, color: T.DIM }}>No batches found.</div>}",
"              {batches.map(b => {",
"                const on = selBatchIds.includes(b._id)",
"                return (",
"                  <div key={b._id} onClick={() => setSelBatchIds(on ? selBatchIds.filter(x => x !== b._id) : [...selBatchIds, b._id])} style={{",
"                    display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderRadius: 10, cursor: 'pointer',",
"                    border: `1.5px solid ${on ? T.ACC : T.BOR}`, background: on ? 'rgba(77,159,255,0.1)' : 'rgba(255,255,255,0.02)',",
"                  }}>",
"                    <input type=\"checkbox\" checked={on} readOnly style={{ accentColor: T.ACC }} />",
"                    <div style={{ minWidth: 0 }}>",
"                      <div style={{ fontSize: 12, fontWeight: 700, color: T.TS, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🏫 {b.name}</div>",
"                      <div style={{ fontSize: 10, color: T.DIM }}>{b.studentCount} students · {b.examType}</div>",
"                    </div>",
"                  </div>",
"                )",
"              })}",
"            </div>",
"          )}",
"          {audienceMode === 'testseries' && (",
"            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 8, marginBottom: 14, maxHeight: 220, overflowY: 'auto', padding: 4 }}>",
"              {batches.length === 0 && <div style={{ fontSize: 11, color: T.DIM }}>No test series found.</div>}",
"              {batches.map(b => {",
"                const on = selTestSeriesIds.includes(b._id)",
"                return (",
"                  <div key={b._id} onClick={() => setSelTestSeriesIds(on ? selTestSeriesIds.filter(x => x !== b._id) : [...selTestSeriesIds, b._id])} style={{",
"                    display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderRadius: 10, cursor: 'pointer',",
"                    border: `1.5px solid ${on ? T.ACC : T.BOR}`, background: on ? 'rgba(77,159,255,0.1)' : 'rgba(255,255,255,0.02)',",
"                  }}>",
"                    <input type=\"checkbox\" checked={on} readOnly style={{ accentColor: T.ACC }} />",
"                    <div style={{ minWidth: 0 }}>",
"                      <div style={{ fontSize: 12, fontWeight: 700, color: T.TS, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🎯 {b.name}</div>",
"                      <div style={{ fontSize: 10, color: T.DIM }}>{b.studentCount} students · {b.examType}</div>",
"                    </div>",
"                  </div>",
"                )",
"              })}",
"            </div>",
"          )}",
  ],
  new: [
"          {audienceMode === 'testseries' && (",
"            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 8, marginBottom: 14, maxHeight: 220, overflowY: 'auto', padding: 4 }}>",
"              {seriesList.length === 0 && <div style={{ fontSize: 11, color: T.DIM }}>No test series found.</div>}",
"              {seriesList.map(b => {",
"                const on = selTestSeriesIds.includes(b._id)",
"                return (",
"                  <div key={b._id} onClick={() => setSelTestSeriesIds(on ? selTestSeriesIds.filter(x => x !== b._id) : [...selTestSeriesIds, b._id])} style={{",
"                    display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderRadius: 10, cursor: 'pointer',",
"                    border: `1.5px solid ${on ? T.ACC : T.BOR}`, background: on ? 'rgba(77,159,255,0.1)' : 'rgba(255,255,255,0.02)',",
"                  }}>",
"                    <input type=\"checkbox\" checked={on} readOnly style={{ accentColor: T.ACC }} />",
"                    <div style={{ minWidth: 0 }}>",
"                      <div style={{ fontSize: 12, fontWeight: 700, color: T.TS, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🎯 {b.name}</div>",
"                      <div style={{ fontSize: 10, color: T.DIM }}>{b.studentCount} students · {b.examType}</div>",
"                    </div>",
"                  </div>",
"                )",
"              })}",
"            </div>",
"          )}",
  ],
},
{
  start: 423, end: 423,
  old: ["              <option value=\"batch\">Batch</option>"],
  new: [],
},
{
  start: 440, end: 440,
  old: ["            const audLabel = a.audience?.mode === 'all' ? 'All Students' : a.audience?.mode === 'batch' ? `${(a.audience.batchIds || []).length} batch(es)` : a.audience?.mode === 'testseries' ? `${(a.audience.testSeriesIds || []).length} test series` : `${(a.audience.studentIds || []).length} student(s)`"],
  new: ["            const audLabel = a.audience?.mode === 'all' ? 'All Students' : a.audience?.mode === 'testseries' ? `${(a.audience.testSeriesIds || []).length} test series` : `${(a.audience.studentIds || []).length} student(s)`"],
},
]);

console.log('\\n✅ AdminAnnouncements.tsx done.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
for f in src/routes/examSubmission.js src/utils/examBuilder.js src/routes/adminSystem.js src/routes/announcements.js src/routes/examFlow.js src/routes/examWizardRoutes.js src/routes/examListing.js src/routes/entryProctoringControl.js; do
  echo "-- node -c $f --"
  node -c "$f" && echo "OK"
done

echo ""
echo "-- remaining 'batch' occurrences per file (backend) --"
for f in src/routes/examSubmission.js src/utils/examBuilder.js src/routes/adminSystem.js src/routes/announcements.js src/routes/examFlow.js src/routes/examWizardRoutes.js src/routes/examListing.js src/routes/entryProctoringControl.js; do
  echo "[$f]"; grep -n -i "batch" "$f" || echo "  (none)"
done

echo ""
echo "-- remaining 'batch' occurrences per file (frontend) --"
for f in frontend/app/admin/x7k2p/CreateExamWizard.tsx frontend/app/admin/x7k2p/SmartPaperGen.tsx frontend/app/admin/x7k2p/AllExams.tsx frontend/app/admin/x7k2p/AdminAnnouncements.tsx; do
  echo "[$f]"; grep -n -i "batch" "$f" || echo "  (none)"
done

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. cd ~/workspace && node src/index.js   (confirm boots clean)"
echo "3. Only after both pass — git add, commit, push"
echo "NOTE: ContentForge.tsx was analyzed but is NOT included in this script"
echo "(49 batch refs, needs its own careful pass — will follow separately)."
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
