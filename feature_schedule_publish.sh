#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX + FEATURE: Schedule Publish
#
# BUG FOUND: examWizardRoutes.js's /schedule-publish route sets a
# field called `scheduledPublishAt` — but Exam schema has NO such
# field (only `schedule: {startTime,endTime,resultTime}` and a
# separate unrelated `scheduledPublish: {enabled,publishAt}`).
# Mongoose's default strict mode silently drops fields not in the
# schema on findByIdAndUpdate, so the date was NEVER actually saved.
# Even the status:'scheduled' flip alone did nothing useful, because
# computeExamState() (examFlow.js / studentBatchWorkspace.js) reads
# `exam.schedule.startTime` — a completely different field that
# stayed null forever. Net effect: Schedule Publish has silently
# never worked at all, for ANY exam, since this route was written.
#
# FIX: write to schema's actual `schedule.startTime` field.
#
# FEATURE: adds an inline date-time picker + "📅 Schedule" button
# next to Publish/Unpublish in Batch Manager (Exams tab) and Test
# Series Manager (Tests tab), so admin can schedule directly there
# without opening the full Create Exam Wizard.
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_schedule.js << 'NODEEOF'
const fs = require('fs');

function patchFile(path, oldStr, newStr, label) {
  if (!fs.existsSync(path)) {
    console.error('❌ File not found: ' + path);
    process.exit(1);
  }
  let src = fs.readFileSync(path, 'utf8');
  if (!src.includes(oldStr)) {
    console.error('❌ FAILED — anchor not found for "' + label + '" in ' + path + '. ABORTING (no changes written).');
    process.exit(1);
  }
  const count = src.split(oldStr).length - 1;
  if (count > 1) {
    console.error('❌ FAILED — anchor for "' + label + '" not unique (' + count + ' matches) in ' + path + '. ABORTING.');
    process.exit(1);
  }
  src = src.replace(oldStr, newStr);
  fs.writeFileSync(path, src, 'utf8');
  console.log('✅ Patched: ' + path + ' (' + label + ')');
}

// ── 1. Backend fix — write to schema-correct field ─────────────────
patchFile(
  'src/routes/examWizardRoutes.js',
  `router.patch('/exam-wizard/:id/schedule-publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { publishAt } = req.body;
    if (!publishAt) return res.status(400).json({ success: false, message: 'publishAt date required' });
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'scheduled', scheduledPublishAt: new Date(publishAt) }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: \`Exam scheduled to publish at \${new Date(publishAt).toLocaleString()}\`, exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`,
  `router.patch('/exam-wizard/:id/schedule-publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { publishAt } = req.body;
    if (!publishAt) return res.status(400).json({ success: false, message: 'publishAt date required' });
    // F53-e FIX: schema has no 'scheduledPublishAt' field — computeExamState()
    // (examFlow.js / studentBatchWorkspace.js) reads exam.schedule.startTime.
    // Writing to the wrong field meant Schedule Publish never actually worked.
    const exam = await Exam.findByIdAndUpdate(
      req.params.id,
      { status: 'scheduled', 'schedule.startTime': new Date(publishAt) },
      { new: true, runValidators: true }
    );
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: \`Exam scheduled to publish at \${new Date(publishAt).toLocaleString()}\`, exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`,
  'schedule-publish field fix'
);

// ── 2. Backfill — one-time repair for any docs that already have the
//    (dead) scheduledPublishAt but status:'scheduled' with no schedule.startTime
// (handled separately below via a plain script, not needed here since
//  the dead field was never actually persisted — nothing to backfill.)

// ── 3. Frontend — Batch Manager Exams tab: add Schedule button ────
patchFile(
  'frontend/app/admin/x7k2p/BatchManagerUltra.tsx',
  `  const unpublishExam = async (examId: string) => {
    if (!window.confirm('Unpublish this exam? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + examId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Exam unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }`,
  `  const unpublishExam = async (examId: string) => {
    if (!window.confirm('Unpublish this exam? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + examId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Exam unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }
  const [scheduleDrafts, setScheduleDrafts] = useState<{ [k: string]: string }>({})
  const scheduleExam = async (examId: string) => {
    const val = scheduleDrafts[examId]
    if (!val) { showToast('⚠️ Pick a date & time first'); return }
    const publishAt = new Date(val)
    if (isNaN(publishAt.getTime()) || publishAt.getTime() <= Date.now()) { showToast('⚠️ Pick a future date & time'); return }
    if (!window.confirm('Schedule this exam to go live at ' + publishAt.toLocaleString() + '?')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + examId + '/schedule-publish', { method: 'PATCH', headers: authHeaders, body: JSON.stringify({ publishAt: publishAt.toISOString() }) })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Exam scheduled'); load() } else showToast('⚠️ ' + (d.message || 'Schedule failed'))
    } catch { showToast('⚠️ Schedule failed') }
  }`,
  'BatchManagerUltra: add scheduleExam handler'
);

patchFile(
  'frontend/app/admin/x7k2p/BatchManagerUltra.tsx',
  `              <div style={{ display: 'flex', gap: 6 }}>
                {e.status === 'draft'
                  ? <button style={{ ...bs, color: GOOD, borderColor: 'rgba(52,211,153,0.35)', padding: '3px 8px' }} onClick={() => publishExam(e._id)}>🚀 Publish</button>
                  : <button style={{ ...bs, color: WARN, borderColor: 'rgba(251,191,36,0.35)', padding: '3px 8px' }} onClick={() => unpublishExam(e._id)}>⏸ Unpublish</button>}
                <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
              </div>`,
  `              <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                {e.status === 'draft' && (
                  <>
                    <input type="datetime-local" value={scheduleDrafts[e._id] || ''} onChange={ev => setScheduleDrafts(s => ({ ...s, [e._id]: ev.target.value }))} style={{ fontSize: 11, padding: '3px 6px', borderRadius: 6, border: \`1px solid \${BOR}\`, background: 'transparent', color: TS }} />
                    <button style={{ ...bs, padding: '3px 8px' }} onClick={() => scheduleExam(e._id)}>📅 Schedule</button>
                  </>
                )}
                {e.status === 'scheduled' && e.schedule?.startTime && (
                  <span style={{ fontSize: 10, color: ACC }}>⏰ {new Date(e.schedule.startTime).toLocaleString()}</span>
                )}
                {e.status === 'draft'
                  ? <button style={{ ...bs, color: GOOD, borderColor: 'rgba(52,211,153,0.35)', padding: '3px 8px' }} onClick={() => publishExam(e._id)}>🚀 Publish Now</button>
                  : <button style={{ ...bs, color: WARN, borderColor: 'rgba(251,191,36,0.35)', padding: '3px 8px' }} onClick={() => unpublishExam(e._id)}>⏸ Unpublish</button>}
                <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
              </div>`,
  'BatchManagerUltra: add Schedule UI to row'
);

// ── 4. Frontend — Test Series Manager Tests tab: add Schedule button
patchFile(
  'frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx',
  `  const unpublishExam = async (testId: string) => {
    if (!window.confirm('Unpublish this test? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + testId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Test unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }`,
  `  const unpublishExam = async (testId: string) => {
    if (!window.confirm('Unpublish this test? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + testId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Test unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }
  const [scheduleDrafts, setScheduleDrafts] = useState<{ [k: string]: string }>({})
  const scheduleExam = async (testId: string) => {
    const val = scheduleDrafts[testId]
    if (!val) { showToast('⚠️ Pick a date & time first'); return }
    const publishAt = new Date(val)
    if (isNaN(publishAt.getTime()) || publishAt.getTime() <= Date.now()) { showToast('⚠️ Pick a future date & time'); return }
    if (!window.confirm('Schedule this test to go live at ' + publishAt.toLocaleString() + '?')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + testId + '/schedule-publish', { method: 'PATCH', headers: authHeaders, body: JSON.stringify({ publishAt: publishAt.toISOString() }) })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Test scheduled'); load() } else showToast('⚠️ ' + (d.message || 'Schedule failed'))
    } catch { showToast('⚠️ Schedule failed') }
  }`,
  'TestSeriesManagerUltra: add scheduleExam handler'
);

patchFile(
  'frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx',
  `              <div style={{ display: 'flex', gap: 6 }}>
                {e.status === 'draft'
                  ? <button style={{ ...bs, color: GOOD, borderColor: 'rgba(52,211,153,0.35)', padding: '3px 8px' }} onClick={() => publishExam(e._id)}>🚀 Publish</button>
                  : <button style={{ ...bs, color: WARN, borderColor: 'rgba(251,191,36,0.35)', padding: '3px 8px' }} onClick={() => unpublishExam(e._id)}>⏸ Unpublish</button>}
                <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
              </div>`,
  `              <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                {e.status === 'draft' && (
                  <>
                    <input type="datetime-local" value={scheduleDrafts[e._id] || ''} onChange={ev => setScheduleDrafts(s => ({ ...s, [e._id]: ev.target.value }))} style={{ fontSize: 11, padding: '3px 6px', borderRadius: 6, border: \`1px solid \${BOR}\`, background: 'transparent', color: TS }} />
                    <button style={{ ...bs, padding: '3px 8px' }} onClick={() => scheduleExam(e._id)}>📅 Schedule</button>
                  </>
                )}
                {e.status === 'scheduled' && e.schedule?.startTime && (
                  <span style={{ fontSize: 10, color: ACC }}>⏰ {new Date(e.schedule.startTime).toLocaleString()}</span>
                )}
                {e.status === 'draft'
                  ? <button style={{ ...bs, color: GOOD, borderColor: 'rgba(52,211,153,0.35)', padding: '3px 8px' }} onClick={() => publishExam(e._id)}>🚀 Publish Now</button>
                  : <button style={{ ...bs, color: WARN, borderColor: 'rgba(251,191,36,0.35)', padding: '3px 8px' }} onClick={() => unpublishExam(e._id)}>⏸ Unpublish</button>}
                <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
              </div>`,
  'TestSeriesManagerUltra: add Schedule UI to row'
);

console.log('✅ All patches applied.');
NODEEOF

node /tmp/patch_schedule.js
rm /tmp/patch_schedule.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'F53-e: fix schedule-publish field mismatch + add inline Schedule UI in Batch/Series Manager' && git push"
