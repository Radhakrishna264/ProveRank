#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX: Publishing an exam sets status:'published' — a value that
# does NOT exist in Exam schema's enum (['draft','scheduled','live',
# 'ended']) and is NOT recognized by examFlow.js (My Exams) or
# studentBatchWorkspace.js (Batch/Series Workspace) — both only
# check for 'scheduled'/'live'/'ended'. So published exams never
# appeared to students, even via the original Create Exam Wizard
# "Publish Now" button (pre-existing bug, unrelated to batch-assign
# fix — that one is separately confirmed fixed already).
#
# Fix: publish route now sets status:'live' (schema-valid, and
# exactly what student routes already look for).
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_publish_status.js << 'NODEEOF'
const fs = require('fs');
const path = 'src/routes/examWizardRoutes.js';
let src = fs.readFileSync(path, 'utf8');

const oldStr = `router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'published', publishedAt: new Date() }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Exam published!', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`;

const newStr = `router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    // F53-b FIX: 'published' is NOT a valid Exam.status enum value
    // (valid: draft/scheduled/live/ended) and was invisible to every
    // student-facing route. 'live' is schema-valid and is what
    // examFlow.js / studentBatchWorkspace.js already filter for.
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'live', publishedAt: new Date() }, { new: true, runValidators: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Exam published!', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`;

if (!src.includes(oldStr)) {
  console.error('❌ FAILED — anchor not found. File may have changed. ABORTING (no changes written).');
  process.exit(1);
}
const count = src.split(oldStr).length - 1;
if (count > 1) {
  console.error('❌ FAILED — anchor not unique (' + count + ' matches). ABORTING.');
  process.exit(1);
}
src = src.replace(oldStr, newStr);
fs.writeFileSync(path, src, 'utf8');
console.log('✅ Patched: ' + path);
NODEEOF

node /tmp/patch_publish_status.js
rm /tmp/patch_publish_status.js

echo ""
echo "=== Backfill: fixing EXISTING exams already stuck with status:'published' ==="
cat > backfill_published_status.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const Exam = require('./src/models/Exam');
  const r = await Exam.updateMany(
    { status: 'published' },
    { $set: { status: 'live' } },
    { runValidators: false }
  );
  console.log('✅ Backfill complete. Exams updated:', r.modifiedCount);
  process.exit(0);
}).catch(e => { console.error('ERROR:', e.message); process.exit(1); });
EOF
node backfill_published_status.js
rm backfill_published_status.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'F53-b: fix exam publish status - published to live (schema-valid, student-visible)' && git push"
