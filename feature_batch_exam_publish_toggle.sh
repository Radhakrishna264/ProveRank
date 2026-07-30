#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# NEW FEATURE: Publish / Unpublish button per exam — Batch Manager
# → Exams Tab. No need to republish the whole Batch anymore.
#
# Uses the ALREADY EXISTING exam-wizard endpoints (same ones used by
# Create Exam Wizard's Step 3 "Publish Now" button — verified via
# CreateExamWizard.tsx):
#   PATCH /api/exam-wizard/:id/publish   (draft -> live)
#   PATCH /api/exam-wizard/:id/draft     (live/scheduled -> draft)
# No backend route changes needed for this — only frontend.
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_publish_btn.js << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/BatchManagerUltra.tsx';
let src = fs.readFileSync(path, 'utf8');

const oldStr = `  const assign = async (examId: string) => { await fetch(base + '/' + id + '/exams/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ examId }) }); showToast('✅ Exam assigned'); load() }
  const unassign = async (examId: string) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Exam removed'); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Exams ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No exams assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: \`1px solid \${BOR}\` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
          </div>
        ))}
      </div>`;

const newStr = `  const assign = async (examId: string) => { await fetch(base + '/' + id + '/exams/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ examId }) }); showToast('✅ Exam assigned'); load() }
  const unassign = async (examId: string) => { await fetch(base + '/' + id + '/exams/' + examId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Exam removed'); load() }
  const examWizardBase = base.replace('/api/admin/batch-manager', '')
  const publishExam = async (examId: string) => {
    if (!window.confirm('Publish this exam? It will become visible & attemptable to enrolled students immediately.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + examId + '/publish', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Exam published'); load() } else showToast('⚠️ ' + (d.message || 'Publish failed'))
    } catch { showToast('⚠️ Publish failed') }
  }
  const unpublishExam = async (examId: string) => {
    if (!window.confirm('Unpublish this exam? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + examId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Exam unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Exams ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No exams assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: \`1px solid \${BOR}\` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>
                {e.title || e.name}
                <span style={{ marginLeft: 8, fontSize: 10, fontWeight: 700, padding: '2px 6px', borderRadius: 5, color: e.status === 'draft' ? WARN : GOOD, background: e.status === 'draft' ? 'rgba(251,191,36,0.12)' : 'rgba(52,211,153,0.12)' }}>
                  {(e.status || 'draft').toUpperCase()}
                </span>
              </span>
              <div style={{ display: 'flex', gap: 6 }}>
                {e.status === 'draft'
                  ? <button style={{ ...bs, color: GOOD, borderColor: 'rgba(52,211,153,0.35)', padding: '3px 8px' }} onClick={() => publishExam(e._id)}>🚀 Publish</button>
                  : <button style={{ ...bs, color: WARN, borderColor: 'rgba(251,191,36,0.35)', padding: '3px 8px' }} onClick={() => unpublishExam(e._id)}>⏸ Unpublish</button>}
                <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
              </div>
            </div>
          </div>
        ))}
      </div>`;

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

node /tmp/patch_publish_btn.js
rm /tmp/patch_publish_btn.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'Feature: inline Publish/Unpublish per exam in Batch Manager Exams tab' && git push"
