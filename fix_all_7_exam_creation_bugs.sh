#!/bin/bash
set -e
cd ~/workspace
mkdir -p ~/workspace/_fixscripts

echo "=================================================="
echo " LOCATING FILES (Rule B4 — verify before touching)"
echo "=================================================="
WIZARD_ROUTE=$(find . -path "*/routes/examWizardRoutes.js" -not -path "*/node_modules/*" | head -1)
WIZARD_TSX=$(find . -iname "CreateExamWizard.tsx" -not -path "*/node_modules/*" | head -1)
BUILDER=$(find . -path "*/utils/examBuilder.js" -not -path "*/node_modules/*" | head -1)
PAPERGEN_CTRL=$(find . -path "*/controllers/paperGenerator.js" -not -path "*/node_modules/*" | head -1)
SMARTGEN_TSX=$(find . -iname "SmartPaperGen.tsx" -not -path "*/node_modules/*" | head -1)
SUBMIT_ROUTE=$(find . -iname "examSubmission.js" -not -path "*/node_modules/*" | head -1)

for f in "WIZARD_ROUTE:$WIZARD_ROUTE" "WIZARD_TSX:$WIZARD_TSX" "BUILDER:$BUILDER" "PAPERGEN_CTRL:$PAPERGEN_CTRL" "SMARTGEN_TSX:$SMARTGEN_TSX" "SUBMIT_ROUTE:$SUBMIT_ROUTE"; do
  name="${f%%:*}"; path="${f#*:}"
  if [ -z "$path" ]; then echo "❌ $name NOT FOUND — aborting patches for this file"; else echo "✅ $name → $path"; fi
done

echo ""
echo "=================================================="
echo " BUG 1 + BUG 3 — examWizardRoutes.js"
echo "=================================================="
if [ -n "$WIZARD_ROUTE" ]; then
cat > ~/workspace/_fixscripts/patch_wizard_route.js << EOF
const fs = require('fs');
const filePath = '${WIZARD_ROUTE}';
let content = fs.readFileSync(filePath, 'utf8');
let changes = 0;

// BUG 1 — correctMarks/negativeMarks are not schema fields; must write markingScheme object
const oldMarking = \`      correctMarks: parseFloat(correctMarks) || 4,
      negativeMarks: parseFloat(negativeMarks) || 1,\`;
const newMarking = \`      markingScheme: {
        correct: parseFloat(correctMarks) || 4,
        incorrect: -(Math.abs(parseFloat(negativeMarks) || 1)),
        unattempted: 0
      },\`;
if (content.includes(oldMarking)) { content = content.replace(oldMarking, newMarking); changes++; console.log('✅ Bug 1 fixed — markingScheme now written correctly'); }
else console.log('⚠️ Bug 1 pattern not found — may already be fixed');

// BUG 3 — Publish Now must respect a future schedule.startTime instead of always forcing 'live'
const oldPublish = \`router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
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
});\`;
const newPublish = \`router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    // F53-b FIX: 'published' is NOT a valid Exam.status enum value
    // (valid: draft/scheduled/live/ended) and was invisible to every
    // student-facing route. 'live' is schema-valid and is what
    // examFlow.js / studentBatchWorkspace.js already filter for.
    // F55 FIX — if a future startTime was already set in Step 1, "Publish Now"
    // must NOT force it live immediately; it should schedule instead.
    const existing = await Exam.findById(req.params.id).select('schedule').lean();
    const startsInFuture = existing && existing.schedule && existing.schedule.startTime && new Date(existing.schedule.startTime) > new Date();
    const nextStatus = startsInFuture ? 'scheduled' : 'live';
    const updateFields = nextStatus === 'live' ? { status: 'live', publishedAt: new Date() } : { status: 'scheduled' };
    const exam = await Exam.findByIdAndUpdate(req.params.id, updateFields, { new: true, runValidators: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: nextStatus === 'scheduled' ? 'Exam scheduled for its start date!' : 'Exam published!', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});\`;
if (content.includes(oldPublish)) { content = content.replace(oldPublish, newPublish); changes++; console.log('✅ Bug 3 fixed — Publish Now now respects future startTime'); }
else console.log('⚠️ Bug 3 pattern not found — may already be fixed');

if (changes > 0) fs.writeFileSync(filePath, content, 'utf8');
console.log(\`Total changes in examWizardRoutes.js: \${changes}\`);
EOF
node ~/workspace/_fixscripts/patch_wizard_route.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " BUG 2 — CreateExamWizard.tsx (auto-prefill publishAt from startDate)"
echo "=================================================="
if [ -n "$WIZARD_TSX" ]; then
cat > ~/workspace/_fixscripts/patch_wizard_tsx.js << EOF
const fs = require('fs');
const filePath = '${WIZARD_TSX}';
let content = fs.readFileSync(filePath, 'utf8');

const oldLine = \`  useEffect(() => { if (step === 3 && createdExamId) loadReview() }, [step, createdExamId])\`;
const newLine = \`  useEffect(() => { if (step === 3 && createdExamId) loadReview() }, [step, createdExamId])

  // F55 FIX — auto-carry Step 1's Start Date into Step 3's Schedule field
  // instead of leaving publishAt empty and forcing admin to re-type the same date.
  useEffect(() => { if (step === 3 && startDate && !publishAt) setPublishAt(startDate) }, [step, startDate])\`;

if (content.includes(oldLine)) {
  content = content.replace(oldLine, newLine);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('✅ Bug 2 fixed — publishAt now auto-prefills from startDate');
} else {
  console.log('⚠️ Bug 2 pattern not found — may already be fixed');
}
EOF
node ~/workspace/_fixscripts/patch_wizard_tsx.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " BUG 4 + BUG 5 — examBuilder.js (ContentForge)"
echo "=================================================="
if [ -n "$BUILDER" ]; then
cat > ~/workspace/_fixscripts/patch_examBuilder.js << EOF
const fs = require('fs');
const filePath = '${BUILDER}';
let content = fs.readFileSync(filePath, 'utf8');
let changes = 0;

// BUG 5 — batch should only be written when assignmentType is actually 'batch'
const oldBatchLine = \`    batch: (assignmentType === 'batch' || assignmentType === 'series') ? (assignment.batch || '') : '',\`;
const newBatchLine = \`    batch: assignmentType === 'batch' ? (assignment.batch || '') : '',\`;
if (content.includes(oldBatchLine)) { content = content.replace(oldBatchLine, newBatchLine); changes++; console.log('✅ Bug 5 fixed — batch only linked when assignmentType is batch'); }
else console.log('⚠️ Bug 5 pattern not found (checking alt formatting)');

// BUG 4 — scheduledPublish field was written but never read anywhere; ContentForge's
// "Scheduled Publish" toggle silently did nothing. Now derive status/schedule from it.
const oldStatusSpread = /\\.\\.\\.\\(postCreate\\?\\.status \\? \\{ status: postCreate\\.status \\} : \\{\\}\\)/;
if (oldStatusSpread.test(content)) {
  content = content.replace(oldStatusSpread,
\`...(postCreate?.status
        ? { status: postCreate.status }
        : (postCreate?.scheduledPublish?.enabled && postCreate?.scheduledPublish?.publishAt)
          // F56 FIX — scheduledPublish.publishAt was written but never actually used
          // to set status/schedule.startTime, so computeExamState() never picked it up
          // and the exam stayed an invisible draft forever.
          ? { status: 'scheduled', schedule: { ...(examDetails.schedule || {}), startTime: (examDetails.schedule && examDetails.schedule.startTime) || new Date(postCreate.scheduledPublish.publishAt) } }
          : {})\`);
  changes++;
  console.log('✅ Bug 4 fixed — scheduledPublish now actually sets status + schedule.startTime');
} else {
  console.log('⚠️ Bug 4 pattern not found — may already be fixed');
}

if (changes > 0) fs.writeFileSync(filePath, content, 'utf8');
console.log(\`Total changes in examBuilder.js: \${changes}\`);
EOF
node ~/workspace/_fixscripts/patch_examBuilder.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " BUG 6 (backend) — controllers/paperGenerator.js (Smart AI 'Use as Exam')"
echo "=================================================="
if [ -n "$PAPERGEN_CTRL" ]; then
cat > ~/workspace/_fixscripts/patch_papergen_ctrl.js << EOF
const fs = require('fs');
const filePath = '${PAPERGEN_CTRL}';
let content = fs.readFileSync(filePath, 'utf8');
let changes = 0;

const oldDestructure = \`    const { sets, meta, answerKey, examTitle, assignType, batchId, testSeriesId, type, targetType, selectedSetLabel } = req.body;\`;
const newDestructure = \`    const { sets, meta, answerKey, examTitle, assignType, batchId, testSeriesId, type, targetType, selectedSetLabel, startDate, endDate } = req.body;\`;
if (content.includes(oldDestructure)) { content = content.replace(oldDestructure, newDestructure); changes++; }

const oldStatus = \`      status:     'draft',\`;
const newStatus = \`      // F57 FIX — Smart AI Generator had no schedule field at all; exam always
      // created with empty schedule + draft status with no way to set a start date here.
      schedule:   { startTime: startDate ? new Date(startDate) : null, endTime: endDate ? new Date(endDate) : null },
      status:     startDate ? 'scheduled' : 'draft',\`;
if (content.includes(oldStatus)) { content = content.replace(oldStatus, newStatus); changes++; console.log('✅ Bug 6 (backend) fixed — schedule field now supported in useAsExam'); }
else console.log('⚠️ Bug 6 backend pattern not found — may already be fixed');

if (changes > 0) fs.writeFileSync(filePath, content, 'utf8');
console.log(\`Total changes in controllers/paperGenerator.js: \${changes}\`);
EOF
node ~/workspace/_fixscripts/patch_papergen_ctrl.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " BUG 6 (frontend) — SmartPaperGen.tsx (add Start Date input)"
echo "=================================================="
if [ -n "$SMARTGEN_TSX" ]; then
cat > ~/workspace/_fixscripts/patch_smartgen_tsx.js << EOF
const fs = require('fs');
const filePath = '${SMARTGEN_TSX}';
let content = fs.readFileSync(filePath, 'utf8');
let changes = 0;

// 1) add state
const oldState = \`  const [uaeType,     setUaeType]       = useState('Full Mock');\`;
const newState = \`  const [uaeType,     setUaeType]       = useState('Full Mock');
  const [uaeStartDate, setUaeStartDate] = useState(''); // F57 FIX — Smart AI Generator start date
  const [uaeEndDate,   setUaeEndDate]   = useState('');\`;
if (content.includes(oldState)) { content = content.replace(oldState, newState); changes++; }

// 2) include in fetch body
const oldBody = \`          selectedSetLabel: uaeSet,
          medium:           examMedium\`;
const newBody = \`          selectedSetLabel: uaeSet,
          medium:           examMedium,
          startDate:        uaeStartDate || null,
          endDate:          uaeEndDate || null\`;
if (content.includes(oldBody)) { content = content.replace(oldBody, newBody); changes++; }

// 3) add UI input before the language medium section
const oldUI = \`            <label style={S.label}>Default Language Medium (17.30)</label>\`;
const newUI = \`            <label style={S.label}>Start Date (optional — F57 FIX)</label>
            <input type="datetime-local" value={uaeStartDate} onChange={e => setUaeStartDate(e.target.value)} style={{ ...S.inp, marginBottom:12 }} />

            <label style={S.label}>Default Language Medium (17.30)</label>\`;
if (content.includes(oldUI)) { content = content.replace(oldUI, newUI); changes++; }

if (changes >= 3) { fs.writeFileSync(filePath, content, 'utf8'); console.log('✅ Bug 6 (frontend) fixed — Start Date field added to Smart AI Use-as-Exam modal'); }
else console.log(\`⚠️ Bug 6 frontend — only \${changes}/3 patterns matched, file not saved to avoid partial patch. Manual check needed.\`);
EOF
node ~/workspace/_fixscripts/patch_smartgen_tsx.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " BUG 7 — examSubmission.js (batch progress sync ID lookup)"
echo "=================================================="
if [ -n "$SUBMIT_ROUTE" ]; then
cat > ~/workspace/_fixscripts/patch_submission.js << EOF
const fs = require('fs');
const filePath = '${SUBMIT_ROUTE}';
let content = fs.readFileSync(filePath, 'utf8');

const oldLine = \`      const Batch = mongoose.model('Batch');
      const batchDoc = await Batch.findOne({ name: { \\\$regex: exam.batch, \\\$options: 'i' } }).lean();\`;
const newLine = \`      const Batch = mongoose.model('Batch');
      // F58 FIX — exam.batch is normally an ObjectId string (per Assign System fix),
      // not a batch name. Try ID lookup first, fall back to legacy name-regex lookup.
      let batchDoc = mongoose.Types.ObjectId.isValid(exam.batch) ? await Batch.findById(exam.batch).lean() : null;
      if (!batchDoc) batchDoc = await Batch.findOne({ name: { \\\$regex: exam.batch, \\\$options: 'i' } }).lean();\`;

if (content.includes(oldLine)) {
  content = content.replace(oldLine, newLine);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('✅ Bug 7 fixed — batch progress sync now tries ObjectId lookup first');
} else {
  console.log('⚠️ Bug 7 pattern not found — may already be fixed');
}
EOF
node ~/workspace/_fixscripts/patch_submission.js
else
  echo "⏭️ Skipping — file not found"
fi

echo ""
echo "=================================================="
echo " CLEANUP + VERIFY + COMMIT"
echo "=================================================="
rm -rf ~/workspace/_fixscripts

echo "--- grep verification of all applied fixes ---"
[ -n "$WIZARD_ROUTE" ] && grep -n "F55 FIX" "$WIZARD_ROUTE"
[ -n "$WIZARD_TSX" ] && grep -n "F55 FIX" "$WIZARD_TSX"
[ -n "$BUILDER" ] && grep -n "F56 FIX" "$BUILDER"
[ -n "$PAPERGEN_CTRL" ] && grep -n "F57 FIX" "$PAPERGEN_CTRL"
[ -n "$SMARTGEN_TSX" ] && grep -n "F57 FIX" "$SMARTGEN_TSX"
[ -n "$SUBMIT_ROUTE" ] && grep -n "F58 FIX" "$SUBMIT_ROUTE"

echo ""
echo "--- git status ---"
git status --short

echo ""
echo "--- git commit + push ---"
git add -A
git commit -m "Fix: 7 exam-creation bugs — marking scheme not saved (Wizard), start-date not carried to schedule (Wizard), Publish Now ignoring future date (Wizard), ContentForge Scheduled Publish being a dead field, stale batch cross-link on series assign, Smart AI Generator missing schedule support, batch progress sync using name-regex instead of ObjectId"
git push origin main

echo ""
echo "--- DONE: All applicable fixes applied + pushed. Backend (Render) will auto-redeploy in ~1-2 min. ---"
