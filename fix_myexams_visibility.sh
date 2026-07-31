#!/bin/bash
set -e
cd ~/workspace

echo "=== STEP 1: Confirm current buggy canSeeExam logic exists ==="
grep -n "assignmentType === 'series'" src/routes/examFlow.js || echo "⚠️ Pattern not found — may already be fixed or code differs"

echo ""
echo "=== STEP 2: Fix canSeeExam() — check Series AND Batch (not either/or exclusive) ==="
echo "    (Using Node fs read/replace/write — NOT sed -i, per Rule C2)"
mkdir -p ~/workspace/_fixscripts
cat > ~/workspace/_fixscripts/fix_cansee_exam.js << 'EOF'
const fs = require('fs');
const path = require('path');
const filePath = path.join(process.env.HOME, 'workspace/src/routes/examFlow.js');

let content = fs.readFileSync(filePath, 'utf8');

const oldBlock = `function canSeeExam(exam, studentId, student, enrollment) {
  if (exam.isArchived) return false;

  if (exam.whitelistEnabled) {
    const inStudentList = (exam.whitelistedStudents || []).some(id => String(id) === String(studentId));
    const inGroupList = student && student.group && (exam.whitelistedGroups || []).includes(student.group);
    return !!(inStudentList || inGroupList);
  }
  if (Array.isArray(exam.whitelist) && exam.whitelist.length > 0) {
    return exam.whitelist.some(id => String(id) === String(studentId));
  }
  if (exam.assignmentType === 'series' && exam.testSeriesId) {
    return enrollment.seriesIds.includes(String(exam.testSeriesId));
  }
  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);
  if (hasBatchTarget) {
    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean).map(String);
    return targets.some(t => enrollment.batchIds.includes(t) || enrollment.batchNames.includes(t));
  }
  return false; // F52 fix — no restriction configured means NOT linked to any enrolled batch/series, so it must NOT show on My Exams (only enrolled-batch/series exams are visible)
}`;

const newBlock = `function canSeeExam(exam, studentId, student, enrollment) {
  if (exam.isArchived) return false;

  if (exam.whitelistEnabled) {
    const inStudentList = (exam.whitelistedStudents || []).some(id => String(id) === String(studentId));
    const inGroupList = student && student.group && (exam.whitelistedGroups || []).includes(student.group);
    return !!(inStudentList || inGroupList);
  }
  if (Array.isArray(exam.whitelist) && exam.whitelist.length > 0) {
    return exam.whitelist.some(id => String(id) === String(studentId));
  }
  // F54 FIX — an exam can be linked to BOTH a series and a batch at once.
  // Previously assignmentType==='series' short-circuited and skipped the
  // batch check entirely, hiding the exam from batch-only-enrolled students.
  // Now check series AND batch independently — visible if EITHER matches.
  if (exam.testSeriesId && enrollment.seriesIds.includes(String(exam.testSeriesId))) {
    return true;
  }
  const hasBatchTarget = !!exam.batch || (exam.multiBatch && exam.multiBatch.length > 0);
  if (hasBatchTarget) {
    const targets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean).map(String);
    if (targets.some(t => enrollment.batchIds.includes(t) || enrollment.batchNames.includes(t))) {
      return true;
    }
  }
  return false; // F52/F54 — not linked to any enrolled batch or series, so must NOT show on My Exams
}`;

if (!content.includes(oldBlock)) {
  console.log('⚠️ Exact old block not found — file may already be modified. No changes made. Manual check needed.');
  process.exit(1);
}

content = content.replace(oldBlock, newBlock);
fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ canSeeExam() function updated — series and batch now checked independently.');
EOF
node ~/workspace/_fixscripts/fix_cansee_exam.js

echo ""
echo "=== STEP 3: Verify the fix landed ==="
grep -n "F54 FIX" src/routes/examFlow.js

echo ""
echo "=== STEP 4: Cleanup temp scripts ==="
rm -rf ~/workspace/_fixscripts

echo ""
echo "=== STEP 5: Git commit + push ==="
git add src/routes/examFlow.js
git commit -m "Fix: canSeeExam() now checks series AND batch independently instead of exclusive assignmentType branch (fixes exam missing from My Exams when linked to both a batch and a series)"
git push origin main

echo ""
echo "--- DONE: Pushed. Wait ~1-2 min for Render backend to auto-redeploy, then refresh Student My Exams page. ---"
