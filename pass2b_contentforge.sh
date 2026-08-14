#!/bin/bash
# ProveRank — PASS 2B: Remove Batch from ContentForge.tsx
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
tar czf ~/workspace/.pre_batch_removal_backup/pass2b_backup_$ts.tar.gz \
  frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || true
echo "Backup saved: ~/workspace/.pre_batch_removal_backup/pass2b_backup_$ts.tar.gz"

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

editFile('frontend/app/admin/x7k2p/ContentForge.tsx', [
{
  start: 67, end: 74,
  old: [
"interface AssignmentState {",
"  assignmentType: 'batch' | 'series' | 'individual';",
"  batch: string;",
"  multiBatchEnabled: boolean;",
"  multiBatch: string[];",
"  testSeriesId: string;",
"  notifyStudents: boolean;",
"}",
  ],
  new: [
"interface AssignmentState {",
"  assignmentType: 'series' | 'individual';",
"  testSeriesId: string;",
"  notifyStudents: boolean;",
"}",
  ],
},
{
  start: 95, end: 96,
  old: [
"function defaultAssignment(): AssignmentState {",
"  return { assignmentType: 'individual', batch: '', multiBatchEnabled: false, multiBatch: [], testSeriesId: '', notifyStudents: false };",
  ],
  new: [
"function defaultAssignment(): AssignmentState {",
"  return { assignmentType: 'individual', testSeriesId: '', notifyStudents: false };",
  ],
},
{
  start: 571, end: 657,
  old: [
"function AssignmentSelector({ a, setA, API, token }: { a:AssignmentState; setA:React.Dispatch<React.SetStateAction<AssignmentState>>; API:string; token:string }) {",
"  const upd = (patch: Partial<AssignmentState>) => setA(prev => ({ ...prev, ...patch }));",
"  const [batches, setBatches] = useState<{_id:string; name:string; studentCount?:number}[]>([]);",
"  const [seriesList, setSeriesList] = useState<{_id:string; name:string; title?:string; lifecycleStatus?:string}[]>([]);",
"",
"  useEffect(() => {",
"    fetch(`${API}/api/admin/batches`, { headers:{ Authorization:`Bearer ${token}` } })",
"      .then(r=>r.json()).then(d=>setBatches(d.batches||d||[])).catch(()=>{});",
"    fetch(`${API}/api/content-forge/series`, { headers:{ Authorization:`Bearer ${token}` } })",
"      .then(r=>r.json()).then(d=>setSeriesList(d.series||[])).catch(()=>{});",
"  }, [API, token]);",
"",
"  const cards: { key:AssignmentState['assignmentType']; icon:string; label:string }[] = [",
"    { key:'batch', icon:'🏫', label:'Assign to Batch' },",
"    { key:'series', icon:'📚', label:'Test Series' },",
"    { key:'individual', icon:'👤', label:'Individual / Open' },",
"  ];",
"",
"  return (",
"    <div style={{ ...S.card }}>",
"      <div style={{ fontSize:13, fontWeight:800, color:C.ts, marginBottom:14 }}>🎯 Step — Assignment</div>",
"      <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:8, marginBottom:14 }}>",
"        {cards.map(c=>(",
"          <div key={c.key} onClick={()=>upd({assignmentType:c.key})}",
"            style={{ textAlign:'center', padding:'14px 8px', borderRadius:12, cursor:'pointer',",
"              border:`1.5px solid ${a.assignmentType===c.key?C.acc:C.bor}`,",
"              background:a.assignmentType===c.key?'rgba(77,159,255,0.12)':'rgba(0,22,40,0.5)',",
"              boxShadow:a.assignmentType===c.key?`0 0 0 2px ${C.acc}33`:'none', transition:'all 0.2s' }}>",
"            <div style={{ fontSize:22, marginBottom:4 }}>{c.icon}</div>",
"            <div style={{ fontSize:10, fontWeight:700, color:a.assignmentType===c.key?C.acc:C.dim }}>{c.label}</div>",
"            {a.assignmentType===c.key && <div style={{ fontSize:10, color:C.acc, marginTop:2 }}>✓</div>}",
"          </div>",
"        ))}",
"      </div>",
"",
"      {a.assignmentType==='batch' && (",
"        <div style={{ marginBottom:10 }}>",
"          <label style={S.lbl}>Batch</label>",
"          <select value={a.batch} onChange={e=>upd({batch:e.target.value})} style={S.inp}>",
"            <option value=\"\">— Select Batch —</option>",
"            {batches.map(b=><option key={b._id} value={b._id}>{b.name} {b.studentCount?`(${b.studentCount} students)`:''}</option>)}",
"          </select>",
"          {a.assignmentType==='batch' && (",
"            <div style={{ marginTop:8, display:'flex', justifyContent:'space-between', alignItems:'center' }}>",
"              <span style={{ fontSize:11, color:C.dim }}>Multi-batch assign</span>",
"              <Toggle on={a.multiBatchEnabled} onClick={()=>upd({multiBatchEnabled:!a.multiBatchEnabled})} />",
"            </div>",
"          )}",
"          {a.multiBatchEnabled && a.assignmentType==='batch' && (",
"            <select multiple value={a.multiBatch} onChange={e=>upd({multiBatch:Array.from(e.target.selectedOptions).map(o=>o.value)})} style={{ ...S.inp, height:90, marginTop:6 }}>",
"              {batches.map(b=><option key={b._id} value={b._id}>{b.name}</option>)}",
"            </select>",
"          )}",
"        </div>",
"      )}",
"",
"      {a.assignmentType==='series' && (",
"        <div style={{ marginBottom:10 }}>",
"          <label style={S.lbl}>Test Series</label>",
"          <select value={a.testSeriesId} onChange={e=>upd({testSeriesId:e.target.value})} style={S.inp}>",
"            <option value=\"\">— Select Test Series —</option>",
"            {seriesList.map(s=><option key={s._id} value={s._id}>{s.name||s.title}{s.lifecycleStatus?` · ${s.lifecycleStatus}`:''}</option>)}",
"          </select>",
"          <label style={{ ...S.lbl, marginTop:8 }}>Batch (optional)</label>",
"          <select value={a.batch} onChange={e=>upd({batch:e.target.value})} style={S.inp}>",
"            <option value=\"\">— Select Batch —</option>",
"            {batches.map(b=><option key={b._id} value={b._id}>{b.name}</option>)}",
"          </select>",
"        </div>",
"      )}",
"",
"      {a.assignmentType==='individual' && (",
"        <div style={{ fontSize:11, color:C.dim }}>No batch restriction — exam will be open to all students.</div>",
"      )}",
"",
"      <div style={{ marginTop:10, display:'flex', justifyContent:'space-between', alignItems:'center' }}>",
"        <span style={{ fontSize:11, color:C.dim }}>🔔 Notify students in batch</span>",
"        <Toggle on={a.notifyStudents} onClick={()=>upd({notifyStudents:!a.notifyStudents})} />",
"      </div>",
"      {a.notifyStudents && a.batch && (",
"        <div style={{ marginTop:6, fontSize:10, color:C.gold }}>",
"          🔔 {batches.find(b=>b._id===a.batch)?.studentCount ?? '?'} students in selected batch will be notified",
"        </div>",
"      )}",
"    </div>",
"  );",
"}",
  ],
  new: [
"function AssignmentSelector({ a, setA, API, token }: { a:AssignmentState; setA:React.Dispatch<React.SetStateAction<AssignmentState>>; API:string; token:string }) {",
"  const upd = (patch: Partial<AssignmentState>) => setA(prev => ({ ...prev, ...patch }));",
"  const [seriesList, setSeriesList] = useState<{_id:string; name:string; title?:string; lifecycleStatus?:string}[]>([]);",
"",
"  useEffect(() => {",
"    fetch(`${API}/api/content-forge/series`, { headers:{ Authorization:`Bearer ${token}` } })",
"      .then(r=>r.json()).then(d=>setSeriesList(d.series||[])).catch(()=>{});",
"  }, [API, token]);",
"",
"  const cards: { key:AssignmentState['assignmentType']; icon:string; label:string }[] = [",
"    { key:'series', icon:'📚', label:'Test Series' },",
"    { key:'individual', icon:'👤', label:'Individual / Open' },",
"  ];",
"",
"  return (",
"    <div style={{ ...S.card }}>",
"      <div style={{ fontSize:13, fontWeight:800, color:C.ts, marginBottom:14 }}>🎯 Step — Assignment</div>",
"      <div style={{ display:'grid', gridTemplateColumns:'repeat(2,1fr)', gap:8, marginBottom:14 }}>",
"        {cards.map(c=>(",
"          <div key={c.key} onClick={()=>upd({assignmentType:c.key})}",
"            style={{ textAlign:'center', padding:'14px 8px', borderRadius:12, cursor:'pointer',",
"              border:`1.5px solid ${a.assignmentType===c.key?C.acc:C.bor}`,",
"              background:a.assignmentType===c.key?'rgba(77,159,255,0.12)':'rgba(0,22,40,0.5)',",
"              boxShadow:a.assignmentType===c.key?`0 0 0 2px ${C.acc}33`:'none', transition:'all 0.2s' }}>",
"            <div style={{ fontSize:22, marginBottom:4 }}>{c.icon}</div>",
"            <div style={{ fontSize:10, fontWeight:700, color:a.assignmentType===c.key?C.acc:C.dim }}>{c.label}</div>",
"            {a.assignmentType===c.key && <div style={{ fontSize:10, color:C.acc, marginTop:2 }}>✓</div>}",
"          </div>",
"        ))}",
"      </div>",
"",
"      {a.assignmentType==='series' && (",
"        <div style={{ marginBottom:10 }}>",
"          <label style={S.lbl}>Test Series</label>",
"          <select value={a.testSeriesId} onChange={e=>upd({testSeriesId:e.target.value})} style={S.inp}>",
"            <option value=\"\">— Select Test Series —</option>",
"            {seriesList.map(s=><option key={s._id} value={s._id}>{s.name||s.title}{s.lifecycleStatus?` · ${s.lifecycleStatus}`:''}</option>)}",
"          </select>",
"        </div>",
"      )}",
"",
"      {a.assignmentType==='individual' && (",
"        <div style={{ fontSize:11, color:C.dim }}>Open to all students — no test series restriction.</div>",
"      )}",
"",
"      <div style={{ marginTop:10, display:'flex', justifyContent:'space-between', alignItems:'center' }}>",
"        <span style={{ fontSize:11, color:C.dim }}>🔔 Notify students on publish</span>",
"        <Toggle on={a.notifyStudents} onClick={()=>upd({notifyStudents:!a.notifyStudents})} />",
"      </div>",
"    </div>",
"  );",
"}",
  ],
},
{
  start: 843, end: 843,
  old: ["    { icon:'🎯', title:'Create Exam', sub:'Parse → build full exam with sections, marking scheme, schedule & batch assignment', grad:'linear-gradient(135deg,#A78BFA22,#7C3AED11)', bor:'rgba(167,139,250,0.3)', view:examView },"],
  new: ["    { icon:'🎯', title:'Create Exam', sub:'Parse → build full exam with sections, marking scheme, schedule & assignment', grad:'linear-gradient(135deg,#A78BFA22,#7C3AED11)', bor:'rgba(167,139,250,0.3)', view:examView },"],
},
{
  start: 748, end: 748,
  old: ["function PreSubmitChecklist({ questionsOk, titleOk, dateOk, batchOk }: { questionsOk:boolean; titleOk:boolean; dateOk:boolean; batchOk:boolean }) {"],
  new: ["function PreSubmitChecklist({ questionsOk, titleOk, dateOk, assignOk }: { questionsOk:boolean; titleOk:boolean; dateOk:boolean; assignOk:boolean }) {"],
},
{
  start: 753, end: 753,
  old: ["    { ok:batchOk, label:'Assignment' },"],
  new: ["    { ok:assignOk, label:'Assignment' },"],
},
{
  start: 764, end: 796,
  old: [
"// F19B.4.7 / F20B.3.7 / F21B.7.6 — Duplicate-in-exam/batch check (wires the backend",
"// /check-duplicates endpoint into the UI, shared across all 3 Create-Exam wizards)",
"function DuplicateCheckPanel({ texts, batch, API, token }: { texts:string[]; batch:string; API:string; token:string }) {",
"  const [checking, setChecking] = useState(false);",
"  const [result, setResult] = useState<{text:string; inSameBatch:boolean}[]|null>(null);",
"",
"  const runCheck = async () => {",
"    if (texts.length === 0) return;",
"    setChecking(true); setResult(null);",
"    try {",
"      const res = await fetch(`${API}/api/content-forge/check-duplicates`, {",
"        method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${token}` },",
"        body: JSON.stringify({ texts, batch }),",
"      });",
"      const d = await res.json();",
"      setResult(d.duplicates || []);",
"    } catch (e) { setResult([]); }",
"    setChecking(false);",
"  };",
"",
"  return (",
"    <div style={{ marginBottom:10 }}>",
"      <button onClick={runCheck} disabled={checking||texts.length===0} style={{ ...S.bg, fontSize:11, opacity:checking?0.6:1 }}>",
"        {checking ? '⟳ Checking...' : '🔍 Check Duplicates (vs Question Bank & this batch)'}",
"      </button>",
"      {result && (",
"        result.length === 0",
"          ? <div style={{ marginTop:6, fontSize:11, color:C.suc }}>✅ No duplicates found</div>",
"          : <div style={{ marginTop:6, fontSize:11, color:C.wrn }}>⚠️ {result.length} question(s) already exist {result.some(r=>r.inSameBatch)?'(some in this batch!)':'elsewhere in Question Bank'}</div>",
"      )}",
"    </div>",
"  );",
"}",
  ],
  new: [
"// F19B.4.7 / F20B.3.7 / F21B.7.6 — Duplicate check (wires the backend",
"// /check-duplicates endpoint into the UI, shared across all 3 Create-Exam wizards)",
"function DuplicateCheckPanel({ texts, API, token }: { texts:string[]; API:string; token:string }) {",
"  const [checking, setChecking] = useState(false);",
"  const [result, setResult] = useState<{text:string; inSameBatch:boolean}[]|null>(null);",
"",
"  const runCheck = async () => {",
"    if (texts.length === 0) return;",
"    setChecking(true); setResult(null);",
"    try {",
"      const res = await fetch(`${API}/api/content-forge/check-duplicates`, {",
"        method:'POST', headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${token}` },",
"        body: JSON.stringify({ texts }),",
"      });",
"      const d = await res.json();",
"      setResult(d.duplicates || []);",
"    } catch (e) { setResult([]); }",
"    setChecking(false);",
"  };",
"",
"  return (",
"    <div style={{ marginBottom:10 }}>",
"      <button onClick={runCheck} disabled={checking||texts.length===0} style={{ ...S.bg, fontSize:11, opacity:checking?0.6:1 }}>",
"        {checking ? '⟳ Checking...' : '🔍 Check Duplicates (vs Question Bank)'}",
"      </button>",
"      {result && (",
"        result.length === 0",
"          ? <div style={{ marginTop:6, fontSize:11, color:C.suc }}>✅ No duplicates found</div>",
"          : <div style={{ marginTop:6, fontSize:11, color:C.wrn }}>⚠️ {result.length} question(s) already exist in Question Bank</div>",
"      )}",
"    </div>",
"  );",
"}",
  ],
},
{
  start: 1349, end: 1351,
  old: [
"          assignmentType: assign.assignmentType, batch: assign.batch,",
"          multiBatch: assign.multiBatchEnabled ? assign.multiBatch : [],",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
  new: [
"          assignmentType: assign.assignmentType,",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
},
{
  start: 1427, end: 1428,
  old: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} batch={assign.batch} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} batchOk={assign.assignmentType==='individual'||!!assign.batch||!!assign.seriesName} />",
  ],
  new: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} assignOk={assign.assignmentType==='individual'||!!assign.testSeriesId} />",
  ],
},
{
  start: 1824, end: 1826,
  old: [
"          assignmentType: assign.assignmentType, batch: assign.batch,",
"          multiBatch: assign.multiBatchEnabled ? assign.multiBatch : [],",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
  new: [
"          assignmentType: assign.assignmentType,",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
},
{
  start: 1878, end: 1879,
  old: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} batch={assign.batch} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} batchOk={assign.assignmentType==='individual'||!!assign.batch||!!assign.seriesName} />",
  ],
  new: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} assignOk={assign.assignmentType==='individual'||!!assign.testSeriesId} />",
  ],
},
{
  start: 2189, end: 2191,
  old: [
"          assignmentType: assign.assignmentType, batch: assign.batch,",
"          multiBatch: assign.multiBatchEnabled ? assign.multiBatch : [],",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
  new: [
"          assignmentType: assign.assignmentType,",
"          testSeriesId: assign.testSeriesId, notifyStudents: assign.notifyStudents,",
  ],
},
{
  start: 2243, end: 2244,
  old: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} batch={assign.batch} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} batchOk={assign.assignmentType==='individual'||!!assign.batch||!!assign.seriesName} />",
  ],
  new: [
"          <DuplicateCheckPanel texts={goodQs.map(q=>q.text)} API={API} token={getToken()} />",
"          <PreSubmitChecklist questionsOk={goodQs.length>0} titleOk={!!examD.title.trim()} dateOk={!!examD.startTime} assignOk={assign.assignmentType==='individual'||!!assign.testSeriesId} />",
  ],
},
]);

console.log('\\n✅ ContentForge.tsx done.');
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity check"
echo "═══════════════════════════════════════════"
echo "-- remaining 'batch' occurrences --"
grep -n -i "batch" frontend/app/admin/x7k2p/ContentForge.tsx || echo "(none found)"

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS:"
echo "1. cd ~/workspace/frontend && npm run build"
echo "2. Only after it passes — git add, commit, push"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
