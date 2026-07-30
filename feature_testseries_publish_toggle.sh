#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# NEW FEATURE: Publish / Unpublish button per exam — Test Series
# Manager → Tests Tab. Same pattern as Batch Manager Exams tab.
#
# Uses ALREADY EXISTING exam-wizard endpoints (verified via
# CreateExamWizard.tsx usage):
#   PATCH /api/exam-wizard/:id/publish   (draft -> live)
#   PATCH /api/exam-wizard/:id/draft     (live/scheduled -> draft)
# No backend route changes needed — frontend only.
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_publish_btn_series.js << 'NODEEOF'
const fs = require('fs');
const path = 'frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx';
let src = fs.readFileSync(path, 'utf8');

const oldStr = `  const assign = async (testId: string) => { await fetch(base + '/' + id + '/tests/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ testId }) }); showToast('✅ Test assigned'); load() }
  const unassign = async (testId: string) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Test removed'); load() }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Tests ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No tests assigned yet." /> : data.assigned.map((e: any) => (
          <div key={e._id} style={{ padding: '8px 0', borderBottom: \`1px solid \${BOR}\` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 6 }}>
              <span style={{ color: TS, fontWeight: 600, fontSize: 12.5 }}>{e.title || e.name}</span>
              <button style={{ ...bd, padding: '3px 8px' }} onClick={() => unassign(e._id)}>Remove</button>
            </div>
          </div>
        ))}
      </div>`;

const newStr = `  const assign = async (testId: string) => { await fetch(base + '/' + id + '/tests/assign', { method: 'POST', headers: authHeaders, body: JSON.stringify({ testId }) }); showToast('✅ Test assigned'); load() }
  const unassign = async (testId: string) => { await fetch(base + '/' + id + '/tests/' + testId, { method: 'DELETE', headers: authHeaders }); showToast('✅ Test removed'); load() }
  const examWizardBase = base.replace('/api/admin/test-series-manager', '')
  const publishExam = async (testId: string) => {
    if (!window.confirm('Publish this test? It will become visible & attemptable to enrolled students immediately.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + testId + '/publish', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Test published'); load() } else showToast('⚠️ ' + (d.message || 'Publish failed'))
    } catch { showToast('⚠️ Publish failed') }
  }
  const unpublishExam = async (testId: string) => {
    if (!window.confirm('Unpublish this test? Students will immediately lose access to it.')) return
    try {
      const r = await fetch(examWizardBase + '/api/exam-wizard/' + testId + '/draft', { method: 'PATCH', headers: authHeaders })
      const d = await r.json().catch(() => ({}))
      if (d.success) { showToast('✅ Test unpublished'); load() } else showToast('⚠️ ' + (d.message || 'Unpublish failed'))
    } catch { showToast('⚠️ Unpublish failed') }
  }

  return (
    <div>
      <div style={cs}>
        <div style={{ fontWeight: 700, marginBottom: 8, color: TS }}>Assigned Tests ({data.assigned?.length || 0})</div>
        {(!data.assigned || data.assigned.length === 0) ? <EmptyMsg text="No tests assigned yet." /> : data.assigned.map((e: any) => (
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

node /tmp/patch_publish_btn_series.js
rm /tmp/patch_publish_btn_series.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'Feature: inline Publish/Unpublish per test in Test Series Manager Tests tab' && git push"
