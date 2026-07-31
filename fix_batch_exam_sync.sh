#!/bin/bash
set -e
cd ~/workspace

echo "=== STEP 1: Confirm F53 sync fix exists in current assign route ==="
grep -n "F53 FIX" src/routes/batchManagerUltra.js || echo "⚠️ F53 FIX not found in file!"

echo ""
echo "=== STEP 2: Create one-time backfill migration script (Node.js, NOT python) ==="
mkdir -p ~/workspace/_fixscripts
cat > ~/workspace/_fixscripts/backfill_batch_exam_sync.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(process.env.HOME, 'workspace/.env') });

async function run() {
  const uri = process.env.MONGO_URI;
  if (!uri) { console.error('❌ MONGO_URI not found in .env'); process.exit(1); }
  await mongoose.connect(uri);
  console.log('✅ Connected to MongoDB');

  const db = mongoose.connection.db;
  const batches = await db.collection('batches').find({}).toArray();
  console.log(`Found ${batches.length} batches to check`);

  let fixedCount = 0;
  let checkedCount = 0;

  for (const batch of batches) {
    const bid = String(batch._id);
    const examIds = batch.exams || [];
    for (const examId of examIds) {
      checkedCount++;
      const exam = await db.collection('exams').findOne({ _id: examId });
      if (!exam) continue;

      const currentBatch = exam.batch ? String(exam.batch) : '';
      const currentMulti = (exam.multiBatch || []).map(String);
      const alreadyLinked = currentBatch === bid || currentMulti.includes(bid);

      if (alreadyLinked) continue;

      const upd = {};
      if (!currentBatch) {
        upd.batch = bid;
      } else if (!currentMulti.includes(bid)) {
        upd.multiBatch = [...currentMulti, bid];
      }

      if (Object.keys(upd).length) {
        await db.collection('exams').updateOne({ _id: exam._id }, { $set: upd });
        fixedCount++;
        console.log(`  ✅ Synced exam "${exam.title}" (${exam._id}) → batch "${batch.name}" (${bid})`);
      }
    }
  }

  console.log('');
  console.log(`=== DONE — Checked ${checkedCount} assignments, Fixed ${fixedCount} missing syncs ===`);
  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => { console.error('❌ Migration failed:', err); process.exit(1); });
EOF

echo ""
echo "=== STEP 3: Run the backfill migration ==="
node ~/workspace/_fixscripts/backfill_batch_exam_sync.js

echo ""
echo "=== STEP 4: Verify — dump batch/multiBatch fields for Dropper 2.0 batch's exams ==="
cat > ~/workspace/_fixscripts/verify_sync.js << 'EOF'
const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(process.env.HOME, 'workspace/.env') });

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;
  const batch = await db.collection('batches').findOne({ name: /Dropper 2\.0/i });
  if (!batch) { console.log('⚠️ Dropper 2.0 batch not found'); process.exit(0); }
  console.log(`Batch: ${batch.name} (${batch._id}), assigned exams count: ${(batch.exams||[]).length}`);
  for (const eid of (batch.exams || [])) {
    const exam = await db.collection('exams').findOne({ _id: eid });
    if (!exam) continue;
    console.log(`  - "${exam.title}" | status: ${exam.status} | batch: ${exam.batch} | multiBatch: ${JSON.stringify(exam.multiBatch)}`);
  }
  await mongoose.disconnect();
  process.exit(0);
}
run();
EOF
node ~/workspace/_fixscripts/verify_sync.js

echo ""
echo "=== STEP 5: Cleanup temp scripts ==="
rm -rf ~/workspace/_fixscripts

echo ""
echo "=== STEP 6: Git status check (no code change expected, only DB data fixed) ==="
git status --short

echo ""
echo "--- DONE: Migration complete. Refresh Student My Exams + My Batch Workspace pages to verify. ---"
