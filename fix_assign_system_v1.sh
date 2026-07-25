#!/bin/bash
set -e
cd ~/workspace

echo "🔎 Step 0 — Verifying target files exist..."
for f in src/models/Exam.js src/routes/examWizardRoutes.js frontend/app/admin/x7k2p/CreateExamWizard.tsx frontend/app/admin/x7k2p/page.tsx; do
  if [ ! -f "$f" ]; then echo "❌ Missing: $f — abort"; exit 1; fi
done
echo "✅ All target files found"

echo "🗄️  Step 1 — Backups..."
mkdir -p .fix_backups
cp src/models/Exam.js .fix_backups/Exam.js.bak
cp src/routes/examWizardRoutes.js .fix_backups/examWizardRoutes.js.bak
cp frontend/app/admin/x7k2p/CreateExamWizard.tsx .fix_backups/CreateExamWizard.tsx.bak
cp frontend/app/admin/x7k2p/page.tsx .fix_backups/page.tsx.bak
echo "✅ Backups saved in .fix_backups/"

echo "🛠️  Step 2 — Full rewrite: src/models/Exam.js (adding missing testSeriesId field)..."
cat > src/models/Exam.js << 'EOF'
const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title:        { type: String, required: true, trim: true },
  subject:      { type: String, default: 'NEET' },
  duration:     { type: Number, required: true },
  totalMarks:   { type: Number, default: 720 },
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration

  sections: [{
    name:          String,
    subject:       String,
    questionCount: Number,
    timeLimit:     Number,
    marks:         Number,
    fromQNo:       Number, // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range start
    toQNo:         Number  // F19B.5.21 / F20B.5.21 / F21B.8.21 — subject Q-no range end
  }],

  markingScheme: {
    correct:     { type: Number, default: 4 },
    incorrect:   { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 },
    msqMode:     { type: String, enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'], default: 'ALL_OR_NOTHING' }
  },

  password:   { type: String, default: '' },

  schedule: {
    startTime:  Date,
    endTime:    Date,
    resultTime: Date  // when result/scorecard becomes visible to students
  },

  audioMonitoringEnabled: { type: Boolean, default: false },
  status: { type: String, enum: ['draft', 'scheduled', 'live', 'ended'], default: 'draft' },

  batch:    { type: String, default: '' },

  // F19B.6.8 / F20B.6.8 / F21B.9.7 — Multi-batch assign toggle (additional batch IDs besides primary `batch`)
  multiBatch: [{ type: String, default: [] }],

  // F19B.6 / F20B.6 / F21B.9 — Assignment Type selector
  assignmentType: { type: String, enum: ['batch', 'series', 'mini_test', 'individual'], default: 'individual' },

  // F19B.6.2/6.3 / F20B.6.2/6.3 / F21B.9.2/9.3 — Test Series label (grouping, also used for Step-8 "exam series/group")
  seriesName: { type: String, default: '' },

  // 🔧 FIX (Assign System) — was missing from schema; route was writing this field but Mongoose
  // silently dropped it since it wasn't declared here. This is why Test Series assignment never saved.
  testSeriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', default: null },

  category: { type: String, enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'], default: 'Full Mock' },

  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  watermark:          { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled:         { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 },
  fullscreenForce: { type: Boolean, default: false },
  fullscreenWarnings: { type: Number, default: 0 }
  },

  template:   { type: String, default: '' },
  difficulty: { type: String, default: 'Mixed' },
  type:       { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },
  waitingRoomMinutes: { type: Number, default: 10 },

  maxAttempts:    { type: Number, default: 1 },
  reattemptCount: { type: String, enum: ['best', 'last'], default: 'last' },
  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempt option (maxAttempts auto-set to a large number when true)
  unlimitedAttempts: { type: Boolean, default: false },
  questionSnapshot:  { type: Array, default: [] },
  snapshotLocked:    { type: Boolean, default: false },
  snapshotLockedAt:  { type: Date, default: null },

  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],

  // F19B.5.5 / F20B.5.5 / F21B.8.5 — Subject wise Qs count input
  subjectWiseCount: [{ subject: String, count: Number }],
  // F19B.5.4 / F20B.5.4 / F21B.8.4 — Total Questions requested (auto-select N out of M parsed)
  totalQuestionsRequested: { type: Number, default: 0 },

  // F19B.8.1 / F20B.8.1 / F21B.11.1 — Scheduled auto-publish
  scheduledPublish: {
    enabled:   { type: Boolean, default: false },
    publishAt: { type: Date, default: null }
  },
  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle
  notifyStudents: { type: Boolean, default: false },
  // F19B.8.4 / F20B.8.4 / F21B.11.4 — Save as Template
  isTemplate: { type: Boolean, default: false },

  // F19B.7 / F20B / F21B — source tracking (which method created this exam + parse stats)
  sourceMeta: {
    sourceType:     { type: String, enum: ['paste', 'excel', 'pdf', 'manual', ''], default: '' },
    fileName:        { type: String, default: '' },
    uploadedAt:      { type: Date, default: null },
    pageCount:       { type: Number, default: 0 },
    totalParsed:     { type: Number, default: 0 },
    totalErrors:     { type: Number, default: 0 },
    totalDuplicates: { type: Number, default: 0 }
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // Feature 33.20 — Pinned exams (important exams shown at top of All Exams list)
  isPinned: { type: Boolean, default: false },

  // Feature 31 — Exam Clone/Duplicate: tracks which exam this was cloned from
  clonedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },

  // Feature 34 — Exam Delete: soft-delete / Recycle Bin (34.5 / 34.9 / 34.10 / 34.24)
  isArchived:  { type: Boolean, default: false },
  archivedAt:  { type: Date, default: null },
  archivedBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
EOF
node -c src/models/Exam.js && echo "✅ Exam.js syntax OK"

echo "🛠️  Step 3 — Patching src/routes/examWizardRoutes.js (Node script, exact-anchor replace, no sed)..."
cat > /tmp/patch_examwizard.js << 'NODEEOF'
const fs = require('fs');
const file = 'src/routes/examWizardRoutes.js';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Add Batch/TestSeries model helpers near existing helpers
must(
`const getUser     = () => mongoose.model('User');`,
`const getUser     = () => mongoose.model('User');
const getBatch      = () => mongoose.model('Batch');
const getTestSeries = () => mongoose.model('TestSeries');`,
'add getBatch/getTestSeries helpers'
);

// 2) Replace the entire Create Exam route block
const oldBlock = `router.post('/exam-wizard/create', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const {
      title, subject, category, totalQs, subjectQs, examType, duration,
      totalMarks, correctMarks, negativeMarks, startDate, endDate,
      instructions, passwordEnabled, password,
      whitelist, waitingRoom, waitingMinutes,
      reattempt, reattemptUnlimited, reviewWindow, sectionWise, watermark,
      liveQsRange, assignType, batchId, testSeriesId, miniSeriesId, multiBatches,
      status
    } = req.body;

    if (!title || !title.trim())   return res.status(400).json({ success: false, message: 'Exam title is required' });
    if (!duration || duration < 1) return res.status(400).json({ success: false, message: 'Duration is required' });

    const examData = {
      title: title.trim(),
      subject: subject || 'NEET',
      type: examType || 'NEET',
      category: category || 'Full Mock',
      totalQs: parseInt(totalQs) || 180,
      subjectQs: subjectQs || {},
      duration: parseInt(duration),
      totalMarks: parseInt(totalMarks) || 720,
      correctMarks: parseFloat(correctMarks) || 4,
      negativeMarks: parseFloat(negativeMarks) || 1,
      schedule: {
        startTime: startDate ? new Date(startDate) : null,
        endTime: endDate ? new Date(endDate) : null
      },
      customInstructions: instructions || '',
      password: passwordEnabled ? (password || '') : '',
      whitelist: whitelist || false,
      waitingRoom: waitingRoom || false,
      waitingMinutes: parseInt(waitingMinutes) || 0,
      reattempt: reattemptUnlimited ? -1 : (parseInt(reattempt) || 1),
      reviewWindow: reviewWindow !== false,
      sectionWise: sectionWise || false,
      watermark: watermark || false,
      liveQsRange: liveQsRange || [],
      batch: batchId || '',
      batches: multiBatches || [],
      testSeriesId: testSeriesId || null,
      miniSeriesId: miniSeriesId || null,
      seriesName: testSeriesId || miniSeriesId || '', // Feature 33.5 — real schema field for series-based filtering
      assignType: assignType || 'open',
      status: status || 'draft',
      questions: [],
      createdBy: req.user.id,
    };

    const exam = await Exam.create(examData);
    res.status(201).json({ success: true, message: 'Exam created!', exam, examId: exam._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`;

const newBlock = `router.post('/exam-wizard/create', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const {
      title, subject, category, totalQs, subjectQs, examType, duration,
      totalMarks, correctMarks, negativeMarks, startDate, endDate,
      instructions, passwordEnabled, password,
      whitelist, waitingRoom, waitingMinutes,
      reattempt, reattemptUnlimited, reviewWindow, sectionWise, watermark,
      liveQsRange, assignType, batchId, testSeriesId, multiBatches,
      status
    } = req.body;

    if (!title || !title.trim())   return res.status(400).json({ success: false, message: 'Exam title is required' });
    if (!duration || duration < 1) return res.status(400).json({ success: false, message: 'Duration is required' });

    // 🔧 FIX (Assign System) — resolve real Test Series name instead of storing raw ID in seriesName
    let resolvedSeriesName = '';
    if (assignType === 'series' && testSeriesId) {
      try {
        const TestSeries = getTestSeries();
        const seriesDoc = await TestSeries.findById(testSeriesId).select('name title').lean();
        resolvedSeriesName = seriesDoc ? (seriesDoc.name || seriesDoc.title || '') : '';
      } catch {}
    }

    const examData = {
      title: title.trim(),
      subject: subject || 'NEET',
      type: examType || 'NEET',
      category: category || 'Full Mock',
      totalQs: parseInt(totalQs) || 180,
      subjectQs: subjectQs || {},
      duration: parseInt(duration),
      totalMarks: parseInt(totalMarks) || 720,
      correctMarks: parseFloat(correctMarks) || 4,
      negativeMarks: parseFloat(negativeMarks) || 1,
      schedule: {
        startTime: startDate ? new Date(startDate) : null,
        endTime: endDate ? new Date(endDate) : null
      },
      customInstructions: instructions || '',
      password: passwordEnabled ? (password || '') : '',
      whitelist: whitelist || false,
      waitingRoom: waitingRoom || false,
      waitingMinutes: parseInt(waitingMinutes) || 0,
      reattempt: reattemptUnlimited ? -1 : (parseInt(reattempt) || 1),
      reviewWindow: reviewWindow !== false,
      sectionWise: sectionWise || false,
      watermark: watermark || false,
      liveQsRange: liveQsRange || [],
      // 🔧 FIX — batch/multiBatch/testSeriesId now match actual Exam schema field names
      batch: assignType === 'batch' ? (batchId || '') : '',
      multiBatch: multiBatches || [],
      testSeriesId: assignType === 'series' ? (testSeriesId || null) : null,
      seriesName: resolvedSeriesName,
      assignmentType: assignType === 'batch' ? 'batch' : assignType === 'series' ? 'series' : 'individual',
      status: status || 'draft',
      questions: [],
      createdBy: req.user.id,
    };

    const exam = await Exam.create(examData);

    // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually
    // "uploads" into that batch/series (previously this reverse-link never happened).
    try {
      if (assignType === 'batch' && batchId) {
        const Batch = getBatch();
        await Batch.findByIdAndUpdate(batchId, { \$addToSet: { exams: exam._id } });
      } else if (assignType === 'series' && testSeriesId) {
        const TestSeries = getTestSeries();
        await TestSeries.findByIdAndUpdate(testSeriesId, { \$addToSet: { tests: exam._id } });
      }
    } catch (linkErr) {
      console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);
    }

    res.status(201).json({ success: true, message: 'Exam created!', exam, examId: exam._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});`;

must(oldBlock, newBlock, 'rewrite create-exam route with batch/series linking');

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_examwizard.js
node -c src/routes/examWizardRoutes.js && echo "✅ examWizardRoutes.js syntax OK"

echo "🛠️  Step 4 — Patching frontend/app/admin/x7k2p/CreateExamWizard.tsx..."
cat > /tmp/patch_wizard_tsx.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/CreateExamWizard.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Props interface — add testSeries
must(
`interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; fetchAll:()=>void; batches:any[]; exams:any[]; questions:any[]; pendingTemplate?:any; onTemplateConsumed?:()=>void }`,
`interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void; fetchAll:()=>void; batches:any[]; testSeries:any[]; exams:any[]; questions:any[]; pendingTemplate?:any; onTemplateConsumed?:()=>void }`,
'Props interface + testSeries'
);

// 2) Function signature destructure — add testSeries
must(
`export default function CreateExamWizard({ token, API, T, fetchAll, batches, exams, questions, pendingTemplate, onTemplateConsumed }:Props) {`,
`export default function CreateExamWizard({ token, API, T, fetchAll, batches, testSeries, exams, questions, pendingTemplate, onTemplateConsumed }:Props) {`,
'function signature + testSeries'
);

// 3) assignType state — remove 'mini' from union type
must(
`  const [assignType, setAssignType]   = useState<'batch'|'series'|'mini'|'open'>('open')`,
`  const [assignType, setAssignType]   = useState<'batch'|'series'|'open'>('open')`,
'remove mini from assignType union'
);

// 4) Assign To block — remove Mini Series option, add Test Series dropdown, reset unused id on switch
const oldAssignBlock = `              {/* Batch assignment */}
              <div style={cs}>
                <div style={{fontWeight:700,fontSize:13,color:PRP,marginBottom:14}}>🏫 Assign To</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>
                  {([['open','🌐 Open','All students'],['batch','🏫 Batch','Specific batch'],['series','📚 Test Series','Series group'],['mini','🧪 Mini Series','Mini test series']] as const).map(([v,l,d])=>(
                    <div key={v} onClick={()=>setAssignType(v)} style={{padding:'10px',borderRadius:10,border:\`1.5px solid \${assignType===v?PRP:BOR}\`,background:assignType===v?\`\${PRP}12\`:'transparent',cursor:'pointer',transition:'all 0.15s'}}>
                      <div style={{fontSize:13,fontWeight:700,color:assignType===v?PRP:TS,marginBottom:2}}>{l}</div>
                      <div style={{fontSize:10,color:DIM}}>{d}</div>
                    </div>
                  ))}
                </div>
                {assignType === 'batch' && (
                  <Field label="Select Batch">
                    <select value={batchId} onChange={e=>setBatchId(e.target.value)} style={inp}>
                      <option value="">— Select Batch —</option>
                      {batches.map((b:any)=><option key={b._id} value={b._id}>{b.name}</option>)}
                    </select>
                  </Field>
                )}
              </div>`;

const newAssignBlock = `              {/* Batch / Test Series assignment */}
              <div style={cs}>
                <div style={{fontWeight:700,fontSize:13,color:PRP,marginBottom:14}}>🏫 Assign To</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:12}}>
                  {([['open','🌐 Open','All students'],['batch','🏫 Batch','Specific batch'],['series','📚 Test Series','Series group']] as const).map(([v,l,d])=>(
                    <div key={v} onClick={()=>{setAssignType(v);if(v!=='batch')setBatchId('');if(v!=='series')setTestSeriesId('')}} style={{padding:'10px',borderRadius:10,border:\`1.5px solid \${assignType===v?PRP:BOR}\`,background:assignType===v?\`\${PRP}12\`:'transparent',cursor:'pointer',transition:'all 0.15s'}}>
                      <div style={{fontSize:13,fontWeight:700,color:assignType===v?PRP:TS,marginBottom:2}}>{l}</div>
                      <div style={{fontSize:10,color:DIM}}>{d}</div>
                    </div>
                  ))}
                </div>
                {assignType === 'batch' && (
                  <Field label="Select Batch">
                    <select value={batchId} onChange={e=>setBatchId(e.target.value)} style={inp}>
                      <option value="">— Select Batch —</option>
                      {batches.map((b:any)=><option key={b._id} value={b._id}>{b.name}{b.lifecycleStatus?\` · \${b.lifecycleStatus}\`:''}</option>)}
                    </select>
                  </Field>
                )}
                {assignType === 'series' && (
                  <Field label="Select Test Series">
                    <select value={testSeriesId} onChange={e=>setTestSeriesId(e.target.value)} style={inp}>
                      <option value="">— Select Test Series —</option>
                      {testSeries.map((s:any)=><option key={s._id} value={s._id}>{s.name||s.title}{s.lifecycleStatus?\` · \${s.lifecycleStatus}\`:''}</option>)}
                    </select>
                  </Field>
                )}
              </div>`;

must(oldAssignBlock, newAssignBlock, 'Assign To block — remove mini, add series dropdown');

// 5) Live preview (step 1) — show series name too
must(
`                    ['🏫',assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch not chosen'):'Open Access'],`,
`                    ['🏫',assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch not chosen'):assignType==='series'?(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series not chosen'):'Open Access'],`,
'live preview assignment line'
);

// 6) Review step preview — show series name too
must(
`                    ['🏫 Assignment',assignType==='open'?'Open Access':assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch'):'Series'],`,
`                    ['🏫 Assignment',assignType==='open'?'Open Access':assignType==='batch'?(batches.find((b:any)=>b._id===batchId)?.name||'Batch'):(testSeries.find((s:any)=>s._id===testSeriesId)?.name||'Series')],`,
'review step assignment line'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_wizard_tsx.js

echo "🛠️  Step 5 — Patching frontend/app/admin/x7k2p/page.tsx (fetch testSeries + pass to wizard)..."
cat > /tmp/patch_page_tsx.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

// 1) Add testSeries state next to batches state
must(
`  const [batches,setBatches]=useState<Batch[]>([])`,
`  const [batches,setBatches]=useState<Batch[]>([])
  const [testSeries,setTestSeries]=useState<any[]>([])`,
'add testSeries state'
);

// 2) Add ts to Promise.all destructure
must(
`    const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs,mn]=await Promise.all([`,
`    const [us,ex,qs,st,fl,al,tk,sn,ft,nf,bt,au,rs,mn,tsr]=await Promise.all([`,
'add tsr to Promise.all destructure'
);

// 3) Add test series fetch call right after batches fetch call
must(
`      getFirst(\`\${API}/api/admin/batches\`,\`\${API}/api/admin/manage/batches\`),`,
`      getFirst(\`\${API}/api/admin/batches\`,\`\${API}/api/admin/manage/batches\`),
      getFirst(\`\${API}/api/admin/test-series-manager?limit=200\`,\`\${API}/api/testseries\`),`,
'add test series fetch call'
);

// 4) Set testSeries state after batches are set
must(
`    if(Array.isArray(bt))setBatches(bt)`,
`    if(Array.isArray(bt))setBatches(bt)
    if(tsr&&Array.isArray(tsr.series))setTestSeries(tsr.series)
    else if(Array.isArray(tsr))setTestSeries(tsr)`,
'set testSeries state from fetch result'
);

// 5) Pass testSeries prop into CreateExamWizard
must(
`            <CreateExamWizard
              token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''}
              API={API}
              T={T}
              fetchAll={fetchAll}
              batches={batches||[]}
              exams={exams||[]}
              questions={questions||[]}
              pendingTemplate={pendingTemplate}
              onTemplateConsumed={()=>setPendingTemplate(null)}
            />`,
`            <CreateExamWizard
              token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''}
              API={API}
              T={T}
              fetchAll={fetchAll}
              batches={batches||[]}
              testSeries={testSeries||[]}
              exams={exams||[]}
              questions={questions||[]}
              pendingTemplate={pendingTemplate}
              onTemplateConsumed={()=>setPendingTemplate(null)}
            />`,
'pass testSeries prop to CreateExamWizard'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_page_tsx.js

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ ALL PATCHES APPLIED SUCCESSFULLY"
echo "═══════════════════════════════════════════════════"
echo "Changed files:"
echo "  1. src/models/Exam.js               — added testSeriesId field"
echo "  2. src/routes/examWizardRoutes.js   — fixed field mapping + Batch/TestSeries back-link + removed miniSeriesId"
echo "  3. frontend/app/admin/x7k2p/CreateExamWizard.tsx — removed Mini Series option, added Test Series dropdown"
echo "  4. frontend/app/admin/x7k2p/page.tsx — fetches Test Series list, passes to wizard"
echo ""
echo "👉 Next steps:"
echo "   1. Restart backend: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js"
echo "   2. Test Create Exam wizard — Batch dropdown, Test Series dropdown (drafts included), assign & verify"
echo "      exam appears inside that Batch's/Test Series's exams list."
echo "   3. If all good: git add -A && git commit -m 'Fix: Exam Assign To system - batch/testseries sync + backlink, removed mini series' && git push"
