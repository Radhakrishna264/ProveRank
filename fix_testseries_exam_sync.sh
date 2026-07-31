#!/bin/bash
set -e
cd ~/workspace

echo "=== STEP 1: Confirm F53 sync fix exists in series assign route ==="
grep -n "F53 FIX" src/routes/testSeriesManagerUltra.js || echo "⚠️ F53 FIX not found!"

echo ""
echo "=== STEP 2: Backfill migration — sync testSeriesId for already-assigned tests ==="
mkdir -p ~/workspace/_fixscripts
cat > ~/workspace/_fixscripts/backfill_series_exam_sync.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(process.env.HOME, 'workspace/.env') });

async function run() {
  const uri = process.env.MONGO_URI;
  if (!uri) { console.error('❌ MONGO_URI not found in .env'); process.exit(1); }
  await mongoose.connect(uri);
  console.log('✅ Connected to MongoDB');

  const db = mongoose.connection.db;
  const seriesList = await db.collection('testseries').find({}).toArray();
  console.log(`Found ${seriesList.length} test series to check`);

  let fixedCount = 0;
  let checkedCount = 0;

  for (const series of seriesList) {
    const sid = series._id;
    const testIds = series.tests || [];
    for (const testId of testIds) {
      checkedCount++;
      const exam = await db.collection('exams').findOne({ _id: testId });
      if (!exam) continue;

      const alreadyLinked = exam.testSeriesId && String(exam.testSeriesId) === String(sid);
      if (alreadyLinked) continue;

      await db.collection('exams').updateOne(
        { _id: exam._id },
        { $set: { testSeriesId: sid, assignmentType: 'series' } }
      );
      fixedCount++;
      console.log(`  ✅ Synced exam "${exam.title}" (${exam._id}) → series "${series.name || series.title}" (${sid})`);
    }
  }

  console.log('');
  console.log(`=== DONE — Checked ${checkedCount} assignments, Fixed ${fixedCount} missing syncs ===`);
  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => { console.error('❌ Migration failed:', err); process.exit(1); });
EOF
node ~/workspace/_fixscripts/backfill_series_exam_sync.js

echo ""
echo "=== STEP 3: Fix field-name bug — replace stale 'series.exams' with 'series.tests' (4 spots) ==="
echo "    (Using Node fs read/replace/write — NOT sed -i, per Rule C2)"
cat > ~/workspace/_fixscripts/fix_field_name.js << 'EOF'
const fs = require('fs');
const path = require('path');
const filePath = path.join(process.env.HOME, 'workspace/src/routes/testSeriesManagerUltra.js');

let content = fs.readFileSync(filePath, 'utf8');
const before = (content.match(/series\.exams/g) || []).length;

if (before === 0) {
  console.log('⚠️ No occurrences of "series.exams" found — already fixed or file structure changed. Skipping.');
  process.exit(0);
}

content = content.replace(/series\.exams/g, 'series.tests');
const after = (content.match(/series\.exams/g) || []).length;

fs.writeFileSync(filePath, content, 'utf8');
console.log(`✅ Replaced ${before} occurrence(s) of "series.exams" → "series.tests". Remaining: ${after}`);
EOF
node ~/workspace/_fixscripts/fix_field_name.js

echo ""
echo "=== STEP 4: Verify — dump testSeriesId for one sample series' tests ==="
cat > ~/workspace/_fixscripts/verify_series_sync.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(process.env.HOME, 'workspace/.env') });

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  const seriesList = await db.collection('testseries').find({ tests: { $exists: true, $ne: [] } }).limit(3).toArray();
  if (!seriesList.length) { console.log('ℹ️ No test series with assigned tests found to verify.'); process.exit(0); }
  for (const series of seriesList) {
    console.log(`Series: ${series.name || series.title} (${series._id}), tests count: ${(series.tests||[]).length}`);
    for (const tid of (series.tests || [])) {
      const exam = await db.collection('exams').findOne({ _id: tid });
      if (!exam) continue;
      console.log(`  - "${exam.title}" | status: ${exam.status} | testSeriesId: ${exam.testSeriesId} | assignmentType: ${exam.assignmentType}`);
    }
  }
  await mongoose.disconnect();
  process.exit(0);
}
run();
EOF
node ~/workspace/_fixscripts/verify_series_sync.js

echo ""
echo "=== STEP 5: Confirm no leftover 'series.exams' references ==="
grep -n "series\.exams" src/routes/testSeriesManagerUltra.js || echo "✅ Clean — no 'series.exams' left"

echo ""
echo "=== STEP 6: Cleanup temp scripts ==="
rm -rf ~/workspace/_fixscripts

echo ""
echo "=== STEP 7: Git commit + push (field-name code fix) ==="
git add src/routes/testSeriesManagerUltra.js
git commit -m "Fix: correct stale 'series.exams' field references to 'series.tests' in testSeriesManagerUltra.js (fixes wrong examsCount/checklist/scheduled-count stats)" || echo "ℹ️ Nothing to commit (already clean)"
git push origin main

echo ""
echo "--- DONE: Test Series exam-sync backfilled + field-name bug fixed + pushed. Refresh Admin Test Series dashboard + Student pages to verify. ---"
