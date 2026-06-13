#!/bin/bash
set -e
cd ~/workspace

echo "================================================================"
echo "🔧 QsBank Feature Implementation Starting..."
echo "================================================================"

# ============================================================
# BACKEND 1: models/Exam.js — add questions[] field
# ============================================================
cat > /tmp/fix_exam_model.js << 'NODEEOF'
const fs=require('fs');
const f='src/models/Exam.js';
let c=fs.readFileSync(f,'utf8');
const anchor=`  totalMarks:   { type: Number, default: 720 },`;
if(!c.includes(anchor)) throw new Error('Anchor not found in '+f);
if(!c.includes('questions: [{ type: mongoose.Schema.Types.ObjectId')){
  c=c.replace(anchor, anchor+`
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration`);
  fs.writeFileSync(f,c);
  console.log('✅ Exam.js: questions[] field added');
}else console.log('⏭️  Exam.js: questions[] field already exists');
NODEEOF
node /tmp/fix_exam_model.js

# ============================================================
# BACKEND 2: routes/exam.js — usageCount increment on create
#            + PATCH /:id/questions (Add to Existing Exam - Feature 1.3a)
# ============================================================
cat > /tmp/fix_exam_routes.js << 'NODEEOF'
const fs=require('fs');
const f='src/routes/exam.js';
let c=fs.readFileSync(f,'utf8');

// 2a. usageCount increment on exam create (Feature 1.3b)
const a1=`    const exam = await Exam.create({ ...req.body, createdBy: req.user.id });`;
if(!c.includes(a1)) throw new Error('Anchor a1 not found in '+f);
if(!c.includes('QsBank: increment usageCount on create')){
  const r1=a1+`
    if (Array.isArray(exam.questions) && exam.questions.length > 0) {
      const Question = require('../models/Question');
      await Question.updateMany({ _id: { $in: exam.questions } }, { $inc: { usageCount: 1 } }); // QsBank: increment usageCount on create
    }`;
  c=c.replace(a1,r1);
  console.log('✅ exam.js: usageCount increment on create added (1.3b)');
}else console.log('⏭️  exam.js: create-usageCount already present');

// 2b. PATCH /:id/questions — Add to Existing Exam (Feature 1.3a)
const a2=`module.exports = router;`;
const cnt=(c.match(/module\.exports = router;/g)||[]).length;
if(cnt!==1) throw new Error('module.exports anchor not unique in '+f);
if(!c.includes(`router.patch('/:id/questions'`)){
  const newRoute=`
// ── QsBank -> Exam Integration: Add multiple questions to existing exam (Feature 1.3a) ──
router.patch('/:id/questions', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questionIds } = req.body;
    if (!Array.isArray(questionIds) || questionIds.length === 0) {
      return res.status(400).json({ message: 'questionIds array required' });
    }
    const objIds = questionIds.map(id => new mongoose.Types.ObjectId(id));
    const exam = await Exam.findByIdAndUpdate(
      req.params.id,
      { \$addToSet: { questions: { \$each: objIds } } },
      { new: true }
    );
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    const Question = require('../models/Question');
    await Question.updateMany({ _id: { \$in: objIds } }, { \$inc: { usageCount: 1 } });
    res.json({ success: true, message: questionIds.length + ' questions added to exam', exam });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

`;
  c=c.replace(a2, newRoute+a2);
  console.log('✅ exam.js: PATCH /:id/questions route added (1.3a)');
}else console.log('⏭️  exam.js: PATCH /:id/questions already exists');

fs.writeFileSync(f,c);
NODEEOF
node /tmp/fix_exam_routes.js

# ============================================================
# BACKEND 3: routes/questions.js — examLevel/format in allowedFields
#            + PATCH /bulk-update (Bulk Edit - Feature 4)
# ============================================================
cat > /tmp/fix_questions_routes.js << 'NODEEOF'
const fs=require('fs');
const f='src/routes/questions.js';
let c=fs.readFileSync(f,'utf8');

// 3a. allow examLevel & format in PUT /:id update (Feature 4)
if(!c.includes(`'examLevel'`)){
  const a1=`    const allowedFields = [
      'text', 'hindiText', 'options', 'hindiOptions', 'correct',
      'subject', 'chapter', 'topic', 'difficulty', 'type', 'image',
      'explanation', 'hindiExplanation', 'videoLink', 'tags', 'approvalStatus'
    ];`;
  if(!c.includes(a1)) throw new Error('Anchor a1 not found in '+f);
  const r1=`    const allowedFields = [
      'text', 'hindiText', 'options', 'hindiOptions', 'correct',
      'subject', 'chapter', 'topic', 'difficulty', 'type', 'image',
      'explanation', 'hindiExplanation', 'videoLink', 'tags', 'approvalStatus', 'examLevel', 'format'
    ];`;
  c=c.replace(a1,r1);
  console.log('✅ questions.js: examLevel/format added to allowedFields');
}else console.log('⏭️  questions.js: allowedFields already has examLevel');

// 3b. PATCH /bulk-update — Bulk Edit (Feature 4)
const a2=`module.exports = router;`;
const cnt=(c.match(/module\.exports = router;/g)||[]).length;
if(cnt!==1) throw new Error('module.exports anchor not unique in '+f);
if(!c.includes(`router.patch('/bulk-update'`)){
  const newRoute=`
// ── QsBank Bulk Edit: update subject/difficulty/type/chapter/examLevel for multiple questions (Feature 4) ──
router.patch('/bulk-update', verifyToken, isAdmin, async (req, res) => {
  try {
    const { ids, fields } = req.body;
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ success: false, message: 'ids array required' });
    }
    const allowed = ['subject','difficulty','type','chapter','examLevel'];
    const update = {};
    allowed.forEach(k => {
      if (fields && fields[k] !== undefined && fields[k] !== '') update[k] = fields[k];
    });
    if (Object.keys(update).length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }
    const result = await Question.updateMany({ _id: { \$in: ids } }, { \$set: update });
    res.json({ success: true, message: result.modifiedCount + ' questions updated', modifiedCount: result.modifiedCount });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

`;
  c=c.replace(a2, newRoute+a2);
  console.log('✅ questions.js: PATCH /bulk-update route added (Feature 4)');
}else console.log('⏭️  questions.js: PATCH /bulk-update already exists');

fs.writeFileSync(f,c);
NODEEOF
node /tmp/fix_questions_routes.js

# ============================================================
# BACKEND 4: routes/questionFeatures.js — GET /:id/usage-stats (Feature 2)
# ============================================================
cat > /tmp/fix_question_features.js << 'NODEEOF'
const fs=require('fs');
const f='src/routes/questionFeatures.js';
let c=fs.readFileSync(f,'utf8');

const a1=`// ── BULK SAVE QUESTIONS ────────────────────────────────────`;
if(!c.includes(a1)) throw new Error('Anchor not found in '+f);
if(!c.includes(`/:id/usage-stats`)){
  const newRoute=`// ── Per-Question Usage Stats: exams used in, attempts, success rate (Feature 2) ──
router.get('/:id/usage-stats', verifyToken, async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const Exam = require('../models/Exam');
    const Attempt = require('../models/Attempt');
    const qId = new mongoose.Types.ObjectId(req.params.id);
    const question = await Question.findById(qId).select('text usageCount correct type');
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    const examsUsedIn = await Exam.countDocuments({ questions: qId });

    const attempts = await Attempt.find({ 'answers.questionId': qId }).select('answers');
    let timesAttempted = 0, correctCount = 0;
    attempts.forEach(a => {
      (a.answers || []).forEach(ans => {
        if (String(ans.questionId) === String(qId) && ans.selectedOption !== null && ans.selectedOption !== undefined) {
          timesAttempted++;
          const correct = Array.isArray(question.correct) ? question.correct : [question.correct];
          const sel = ans.selectedOption;
          const selArr = Array.isArray(sel) ? sel : [sel];
          const isCorrect = correct.length === selArr.length && correct.every(cv => selArr.includes(cv));
          if (isCorrect) correctCount++;
        }
      });
    });
    const successRate = timesAttempted > 0 ? Math.round((correctCount / timesAttempted) * 100) : 0;

    res.json({
      success: true,
      questionId: req.params.id,
      usageCount: question.usageCount || 0,
      examsUsedIn,
      timesAttempted,
      successRate
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

`;
  c=c.replace(a1, newRoute+a1);
  console.log('✅ questionFeatures.js: GET /:id/usage-stats added (Feature 2)');
}else console.log('⏭️  questionFeatures.js: /:id/usage-stats already exists');

fs.writeFileSync(f,c);
NODEEOF
node /tmp/fix_question_features.js

# ============================================================
# FRONTEND: app/admin/x7k2p/page.tsx
# ============================================================
cat > /tmp/fix_qb_frontend.js << 'NODEEOF'
const fs=require('fs');
const f='frontend/app/admin/x7k2p/page.tsx';
let c=fs.readFileSync(f,'utf8');
let changes=0;

// ---- 1. New state variables (after bulkSel) ----
const sAnchor=`  const [bulkSel,setBulkSel]=useState([])`;
if(!c.includes(sAnchor)) throw new Error('State anchor not found');
if(!c.includes('const [qfOpen,setQfOpen]')){
  c=c.replace(sAnchor, sAnchor+`
  // ── QsBank Smart Filters (Feature 3) ──
  const [qfOpen,setQfOpen]=useState(false)
  const [qfApproval,setQfApproval]=useState('all')
  const [qfDiff2,setQfDiff2]=useState('all')
  const [qfType,setQfType]=useState('all')
  const [qfUsage,setQfUsage]=useState('all')
  const [qfLevel,setQfLevel]=useState('all')
  const [qfFormat,setQfFormat]=useState('all')
  const [qfDate,setQfDate]=useState('all')
  // ── QsBank -> Exam Integration (Feature 1) ──
  const [showA2E,setShowA2E]=useState(false)
  const [a2eTab,setA2eTab]=useState('existing')
  const [a2eExamId,setA2eExamId]=useState('')
  const [a2eTitle,setA2eTitle]=useState('')
  const [a2eDuration,setA2eDuration]=useState('180')
  const [a2eMarks,setA2eMarks]=useState('720')
  const [a2eExamsList,setA2eExamsList]=useState([])
  const [a2eSaving,setA2eSaving]=useState(false)
  // ── Bulk Edit (Feature 4) ──
  const [showBulkEdit,setShowBulkEdit]=useState(false)
  const [beFields,setBeFields]=useState({subject:'',difficulty:'',type:'',chapter:'',examLevel:''})
  const [beSaving,setBeSaving]=useState(false)
  // ── Per-Question Usage Stats (Feature 2) ──
  const [usageStatsQ,setUsageStatsQ]=useState(null)
  const [usageStatsData,setUsageStatsData]=useState(null)
  const [usageStatsLoading,setUsageStatsLoading]=useState(false)`);
  changes++; console.log('✅ Frontend: new state vars added');
}else console.log('⏭️  Frontend: state vars already exist');

// ---- 2. New handler functions (after blkApproveQs) ----
const fAnchor=`    setBulkSel([]);T('✅ Bulk approved.')
  }`;
if(!c.includes(fAnchor)) throw new Error('Function anchor not found');
if(!c.includes('const fetchExamsForA2E')){
  c=c.replace(fAnchor, fAnchor+`
  // ── Feature 1: QsBank -> Exam Integration ──
  const fetchExamsForA2E=async()=>{
    try{
      const r=await fetch(API+'/api/exams',{headers:{Authorization:'Bearer '+token}})
      const d=await r.json()
      const list=Array.isArray(d)?d:(d.exams||[])
      setA2eExamsList(list)
    }catch(e){setA2eExamsList([])}
  }
  const openA2E=()=>{
    if(!bulkSel.length)return
    setA2eTab('existing');setA2eExamId('');setA2eTitle('');setA2eDuration('180');setA2eMarks('720')
    fetchExamsForA2E();setShowA2E(true)
  }
  const submitA2EExisting=async()=>{
    if(!a2eExamId)return T('Select an exam','e')
    setA2eSaving(true)
    try{
      const r=await fetch(API+'/api/exams/'+a2eExamId+'/questions',{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({questionIds:bulkSel})})
      if(r.ok){T(bulkSel.length+' questions added to exam!');setBulkSel([]);setShowA2E(false);setTimeout(function(){fetchAll()},500)}
      else{const d=await r.json().catch(function(){return{}});T(d.message||'Failed to add questions','e')}
    }catch(e){T('Failed: '+e.message,'e')}
    setA2eSaving(false)
  }
  const submitA2ENew=async()=>{
    if(!a2eTitle.trim())return T('Exam title required','e')
    if(!a2eDuration||Number(a2eDuration)<=0)return T('Valid duration required','e')
    setA2eSaving(true)
    try{
      const r=await fetch(API+'/api/exams',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:a2eTitle,duration:Number(a2eDuration),totalMarks:Number(a2eMarks)||720,questions:bulkSel})})
      const d=await r.json().catch(function(){return{}})
      if(r.ok){T('New exam created with '+bulkSel.length+' questions!');setBulkSel([]);setShowA2E(false);setTimeout(function(){fetchAll()},500)}
      else T(d.message||'Failed to create exam','e')
    }catch(e){T('Failed: '+e.message,'e')}
    setA2eSaving(false)
  }
  // ── Feature 4: Bulk Edit ──
  const openBulkEdit=()=>{
    if(!bulkSel.length)return
    setBeFields({subject:'',difficulty:'',type:'',chapter:'',examLevel:''});setShowBulkEdit(true)
  }
  const submitBulkEdit=async()=>{
    const fields={}
    Object.keys(beFields).forEach(function(k){if(beFields[k])fields[k]=beFields[k]})
    if(Object.keys(fields).length===0)return T('Fill at least 1 field','e')
    setBeSaving(true)
    try{
      const r=await fetch(API+'/api/questions/bulk-update',{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({ids:bulkSel,fields:fields})})
      const d=await r.json().catch(function(){return{}})
      if(r.ok){T(bulkSel.length+' questions updated!');setBulkSel([]);setShowBulkEdit(false);setTimeout(function(){fetchAll()},500)}
      else T(d.message||'Bulk edit failed','e')
    }catch(e){T('Failed: '+e.message,'e')}
    setBeSaving(false)
  }
  // ── Feature 2: Per-Question Usage Stats ──
  const fetchUsageStats=async(q)=>{
    setUsageStatsQ(q);setUsageStatsData(null);setUsageStatsLoading(true)
    try{
      const r=await fetch(API+'/api/questions/'+q._id+'/usage-stats',{headers:{Authorization:'Bearer '+token}})
      const d=await r.json()
      setUsageStatsData(d)
    }catch(e){setUsageStatsData({success:false,message:'Failed to load'})}
    setUsageStatsLoading(false)
  }`);
  changes++; console.log('✅ Frontend: new handler functions added');
}else console.log('⏭️  Frontend: handler functions already exist');

// ---- 3. fQs filter — add Smart Filters conditions ----
if(!c.includes('const fApp=qfApproval')){
  const qAnchor=`  const fQs=(questions||[]).filter(q=>{
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())||q.chapter?.toLowerCase().includes(qSearch.toLowerCase())||q.topic?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    const OS=['Physics','Chemistry','Biology','Math']
    const sec=qSec==='all'||(qSec==='Other'?!OS.includes(q.subject||''):q.subject===qSec)
    const bio=qSec!=='Biology'||qBioSub==='all'||(q.chapter||'').toLowerCase().includes(qBioSub.toLowerCase())||(q.topic||'').toLowerCase().includes(qBioSub.toLowerCase())
    const chap=qChapFilter==='all'||!q.chapter||(q.chapter||'')===(qChapFilter)
    return mq&&ms&&sec&&bio&&chap
  })`;
  if(!c.includes(qAnchor)) throw new Error('fQs anchor not found');
  const qReplace=`  const fQs=(questions||[]).filter(q=>{
    const mq=!qSearch||q.text?.toLowerCase().includes(qSearch.toLowerCase())||q.subject?.toLowerCase().includes(qSearch.toLowerCase())||q.chapter?.toLowerCase().includes(qSearch.toLowerCase())||q.topic?.toLowerCase().includes(qSearch.toLowerCase())
    const ms=qSubjFilter==='all'||q.subject===qSubjFilter
    const OS=['Physics','Chemistry','Biology','Math']
    const sec=qSec==='all'||(qSec==='Other'?!OS.includes(q.subject||''):q.subject===qSec)
    const bio=qSec!=='Biology'||qBioSub==='all'||(q.chapter||'').toLowerCase().includes(qBioSub.toLowerCase())||(q.topic||'').toLowerCase().includes(qBioSub.toLowerCase())
    const chap=qChapFilter==='all'||!q.chapter||(q.chapter||'')===(qChapFilter)
    // ── Smart Filters (Feature 3) ──
    const fApp=qfApproval==='all'||(q.approvalStatus||'approved')===qfApproval
    const fDiff=qfDiff2==='all'||(q.difficulty||'').toLowerCase()===qfDiff2.toLowerCase()
    const fType=qfType==='all'||q.type===qfType
    const uc=q.usageCount||0
    const fUsage=qfUsage==='all'||(qfUsage==='never'?uc===0:qfUsage==='1-5'?(uc>=1&&uc<=5):qfUsage==='5+'?uc>5:true)
    const fLevel=qfLevel==='all'||q.examLevel===qfLevel
    const fFormat=qfFormat==='all'||q.format===qfFormat
    const fDate=(function(){
      if(qfDate==='all')return true
      if(!q.createdAt)return false
      const days=qfDate==='7d'?7:30
      return (Date.now()-new Date(q.createdAt).getTime())<=days*24*60*60*1000
    })()
    return mq&&ms&&sec&&bio&&chap&&fApp&&fDiff&&fType&&fUsage&&fLevel&&fFormat&&fDate
  })`;
  c=c.replace(qAnchor,qReplace);
  changes++; console.log('✅ Frontend: fQs Smart Filters logic added');
}else console.log('⏭️  Frontend: fQs Smart Filters already present');

// ---- 4. Collapsible Smart Filters bar UI (after SInput) ----
const sinAnchor=`                  <SInput init='' onSet={v=>{setQSearch(v);setQPage(1)}} ph='🔍 Search questions, chapter, topic…' style={{...inp,marginBottom:8,fontSize:12}}/>`;
if(!c.includes(sinAnchor)) throw new Error('SInput anchor not found');
if(!c.includes('🧰 Smart Filters')){
  const filterBar=`
                  {(function(){
                    const activeCnt=[qfApproval,qfDiff2,qfType,qfUsage,qfLevel,qfFormat,qfDate].filter(function(v){return v!=='all'}).length
                    return(<div style={{marginBottom:8}}>
                      <button onClick={function(){setQfOpen(function(p){return !p})}} style={{...bg_,fontSize:11,padding:'6px 14px',display:'flex',alignItems:'center',gap:6,width:'100%',justifyContent:'space-between'}}>
                        <span>🧰 Smart Filters{activeCnt>0?' ('+activeCnt+' active)':''}</span>
                        <span>{qfOpen?'▲':'▼'}</span>
                      </button>
                      {qfOpen&&(<div style={{marginTop:8,padding:10,background:'rgba(255,255,255,0.02)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:10,display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:8}}>
                        <div><label style={{...lbl,fontSize:9}}>Approval Status</label>
                          <select value={qfApproval} onChange={function(e){setQfApproval(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='approved'>Approved</option><option value='pending'>Pending</option><option value='rejected'>Rejected</option>
                          </select></div>
                        <div><label style={{...lbl,fontSize:9}}>Difficulty</label>
                          <select value={qfDiff2} onChange={function(e){setQfDiff2(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='easy'>Easy</option><option value='medium'>Medium</option><option value='hard'>Hard</option>
                          </select></div>
                        <div><label style={{...lbl,fontSize:9}}>Type</label>
                          <select value={qfType} onChange={function(e){setQfType(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='SCQ'>SCQ</option><option value='MSQ'>MSQ</option><option value='Integer'>Integer</option>
                          </select></div>
                        <div><label style={{...lbl,fontSize:9}}>Usage</label>
                          <select value={qfUsage} onChange={function(e){setQfUsage(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='never'>Never Used</option><option value='1-5'>Used 1-5x</option><option value='5+'>Used 5x+</option>
                          </select></div>
                        <div><label style={{...lbl,fontSize:9}}>Exam Level</label>
                          <select value={qfLevel} onChange={function(e){setQfLevel(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='NEET'>NEET</option><option value='JEE_MAINS'>JEE_MAINS</option><option value='JEE_ADVANCED'>JEE_ADVANCED</option><option value='CUET'>CUET</option><option value='BOARD'>BOARD</option>
                          </select></div>
                        <div><label style={{...lbl,fontSize:9}}>Format</label>
                          <select value={qfFormat} onChange={function(e){setQfFormat(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All</option><option value='Random'>Random</option><option value='Match_Column'>Match Column</option><option value='Assertion_Reason'>Assertion-Reason</option><option value='Numerical'>Numerical</option><option value='Diagram_Based'>Diagram Based</option>
                          </select></div>
                        <div style={{gridColumn:'span 2'}}><label style={{...lbl,fontSize:9}}>Date Added</label>
                          <select value={qfDate} onChange={function(e){setQfDate(e.target.value);setQPage(1)}} style={{...inp,width:'100%',fontSize:11,padding:'6px 8px'}}>
                            <option value='all'>All Time</option><option value='7d'>Last 7 Days</option><option value='30d'>Last 30 Days</option>
                          </select></div>
                        {activeCnt>0&&(<div style={{gridColumn:'span 2'}}><button onClick={function(){setQfApproval('all');setQfDiff2('all');setQfType('all');setQfUsage('all');setQfLevel('all');setQfFormat('all');setQfDate('all');setQPage(1)}} style={{...bd,fontSize:10,padding:'5px 12px',width:'100%'}}>✕ Clear All Filters</button></div>)}
                      </div>)}
                    </div>)
                  })()}`;
  c=c.replace(sinAnchor, sinAnchor+filterBar);
  changes++; console.log('✅ Frontend: Smart Filters bar UI added');
}else console.log('⏭️  Frontend: Smart Filters bar UI already present');

// ---- 5. Bulk Edit button in bulkSel inline bar ----
const beAnchor=`                    <button onClick={blkApproveQs} style={{fontSize:10,padding:'3px 12px',borderRadius:6,border:'1px solid rgba(0,200,100,0.35)',background:'rgba(0,200,100,0.1)',color:'#00C864',cursor:'pointer',fontWeight:600}}>✅ Approve</button>`;
if(!c.includes(beAnchor)) throw new Error('Bulk approve button anchor not found');
if(!c.includes('✏️ Bulk Edit')){
  c=c.replace(beAnchor, beAnchor+`
                    <button onClick={openBulkEdit} style={{fontSize:10,padding:'3px 12px',borderRadius:6,border:'1px solid rgba(167,139,250,0.35)',background:'rgba(167,139,250,0.1)',color:'#A78BFA',cursor:'pointer',fontWeight:600}}>✏️ Bulk Edit</button>`);
  changes++; console.log('✅ Frontend: Bulk Edit button added');
}else console.log('⏭️  Frontend: Bulk Edit button already present');

// ---- 6. Usage Stats button on each question card ----
const usAnchor=`                                <button onClick={function(){setSelQId(q._id)}} style={{...bg_,padding:'2px',fontSize:10,borderRadius:5,width:30,height:28,display:'flex',alignItems:'center',justifyContent:'center'}} title='Preview'>👁️</button>`;
if(!c.includes(usAnchor)) throw new Error('Preview button anchor not found');
if(!c.includes(`title='Usage Stats'`)){
  c=c.replace(usAnchor, usAnchor+`
                                <button onClick={function(){fetchUsageStats(q)}} style={{...bg_,padding:'2px',fontSize:10,borderRadius:5,width:30,height:28,display:'flex',alignItems:'center',justifyContent:'center'}} title='Usage Stats'>📊</button>`);
  changes++; console.log('✅ Frontend: Usage Stats button added on cards');
}else console.log('⏭️  Frontend: Usage Stats button already present');

// ---- 7. Floating bottom bar + 3 modals (before NCERT modal block) ----
const ncAnchor=`              {aiGO_ncert&&(function(){`;
if(!c.includes(ncAnchor)) throw new Error('NCERT anchor not found');
if(!c.includes('Questions Selected')){
  const block=`              {/* ── Feature 1.2: Floating Bottom Bar ── */}
              {bulkSel.length>0&&(
                <div style={{position:'fixed',bottom:0,left:0,right:0,zIndex:998,background:'linear-gradient(135deg,#0D1B2A,#142840)',borderTop:'1.5px solid rgba(77,159,255,0.35)',padding:'10px 16px',display:'flex',alignItems:'center',justifyContent:'center',gap:12,boxShadow:'0 -4px 20px rgba(0,0,0,0.4)',flexWrap:'wrap'}}>
                  <span style={{fontSize:12,color:'#E8F4FF',fontWeight:700}}>{bulkSel.length} Questions Selected</span>
                  <button onClick={openA2E} style={{...bp,fontSize:12,padding:'8px 18px'}}>➕ Add to Exam →</button>
                </div>
              )}

              {/* ── Feature 1.3: Add to Exam Modal ── */}
              {showA2E&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.35)',borderRadius:18,padding:18,width:'100%',maxWidth:440,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>➕ Add {bulkSel.length} Question(s) to Exam</div>
                      <button onClick={function(){setShowA2E(false)}} style={{...bg_,padding:'4px 10px',fontSize:12}}>✕</button>
                    </div>
                    <div style={{display:'flex',gap:6,marginBottom:14}}>
                      <button onClick={function(){setA2eTab('existing')}} style={{...(a2eTab==='existing'?bp:bg_),flex:1,fontSize:11,padding:'8px 6px'}}>📋 Existing Exam</button>
                      <button onClick={function(){setA2eTab('new')}} style={{...(a2eTab==='new'?bp:bg_),flex:1,fontSize:11,padding:'8px 6px'}}>🆕 New Exam</button>
                    </div>
                    {a2eTab==='existing'?(
                      <div>
                        <label style={lbl}>Select Exam</label>
                        <select value={a2eExamId} onChange={function(e){setA2eExamId(e.target.value)}} style={{...inp,width:'100%',marginBottom:12}}>
                          <option value=''>— Select Exam —</option>
                          {(a2eExamsList||[]).map(function(e){return <option key={e._id} value={e._id}>{e.title}{e.questions?' ('+e.questions.length+' Qs)':''}</option>})}
                        </select>
                        {a2eExamsList.length===0&&<div style={{fontSize:10,color:'#64748B',marginBottom:10}}>No exams found — create a new one in the other tab.</div>}
                        <button onClick={submitA2EExisting} disabled={a2eSaving||!a2eExamId} style={{...bp,width:'100%',opacity:(a2eSaving||!a2eExamId)?0.6:1}}>{a2eSaving?'⧐ Adding…':'✅ Add to Selected Exam'}</button>
                      </div>
                    ):(
                      <div>
                        <label style={lbl}>Exam Title *</label>
                        <input value={a2eTitle} onChange={function(e){setA2eTitle(e.target.value)}} placeholder='e.g. NEET Mock Test 12' style={{...inp,width:'100%',marginBottom:10}}/>
                        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                          <div><label style={lbl}>Duration (min) *</label><input type='number' value={a2eDuration} onChange={function(e){setA2eDuration(e.target.value)}} style={{...inp,width:'100%'}}/></div>
                          <div><label style={lbl}>Total Marks</label><input type='number' value={a2eMarks} onChange={function(e){setA2eMarks(e.target.value)}} style={{...inp,width:'100%'}}/></div>
                        </div>
                        <button onClick={submitA2ENew} disabled={a2eSaving} style={{...bp,width:'100%',opacity:a2eSaving?0.6:1}}>{a2eSaving?'⧐ Creating…':'✅ Create Exam with '+bulkSel.length+' Questions'}</button>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* ── Feature 4: Bulk Edit Modal ── */}
              {showBulkEdit&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(167,139,250,0.35)',borderRadius:18,padding:18,width:'100%',maxWidth:440,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>✏️ Bulk Edit {bulkSel.length} Question(s)</div>
                      <button onClick={function(){setShowBulkEdit(false)}} style={{...bg_,padding:'4px 10px',fontSize:12}}>✕</button>
                    </div>
                    <div style={{fontSize:10,color:'#64748B',marginBottom:10}}>Only filled fields will be applied. Leave blank to skip.</div>
                    <div style={{marginBottom:10}}><label style={lbl}>Subject</label>
                      <select value={beFields.subject} onChange={function(e){setBeFields(function(p){return Object.assign({},p,{subject:e.target.value})})}} style={{...inp,width:'100%'}}>
                        <option value=''>— Skip —</option><option value='Physics'>Physics</option><option value='Chemistry'>Chemistry</option><option value='Biology'>Biology</option><option value='Math'>Math</option>
                      </select></div>
                    <div style={{marginBottom:10}}><label style={lbl}>Difficulty</label>
                      <select value={beFields.difficulty} onChange={function(e){setBeFields(function(p){return Object.assign({},p,{difficulty:e.target.value})})}} style={{...inp,width:'100%'}}>
                        <option value=''>— Skip —</option><option value='Easy'>Easy</option><option value='Medium'>Medium</option><option value='Hard'>Hard</option>
                      </select></div>
                    <div style={{marginBottom:10}}><label style={lbl}>Type</label>
                      <select value={beFields.type} onChange={function(e){setBeFields(function(p){return Object.assign({},p,{type:e.target.value})})}} style={{...inp,width:'100%'}}>
                        <option value=''>— Skip —</option><option value='SCQ'>SCQ</option><option value='MSQ'>MSQ</option><option value='Integer'>Integer</option>
                      </select></div>
                    <div style={{marginBottom:10}}><label style={lbl}>Chapter</label>
                      <input value={beFields.chapter} onChange={function(e){setBeFields(function(p){return Object.assign({},p,{chapter:e.target.value})})}} placeholder='— Skip —' style={{...inp,width:'100%'}}/></div>
                    <div style={{marginBottom:14}}><label style={lbl}>Exam Level</label>
                      <select value={beFields.examLevel} onChange={function(e){setBeFields(function(p){return Object.assign({},p,{examLevel:e.target.value})})}} style={{...inp,width:'100%'}}>
                        <option value=''>— Skip —</option><option value='NEET'>NEET</option><option value='JEE_MAINS'>JEE_MAINS</option><option value='JEE_ADVANCED'>JEE_ADVANCED</option><option value='CUET'>CUET</option><option value='BOARD'>BOARD</option>
                      </select></div>
                    <button onClick={submitBulkEdit} disabled={beSaving} style={{...bp,width:'100%',opacity:beSaving?0.6:1}}>{beSaving?'⧐ Applying…':'✅ Apply to '+bulkSel.length+' Questions'}</button>
                  </div>
                </div>
              )}

              {/* ── Feature 2: Usage Stats Modal ── */}
              {usageStatsQ&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(96,165,250,0.35)',borderRadius:18,padding:18,width:'100%',maxWidth:400}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>📊 Question Usage Stats</div>
                      <button onClick={function(){setUsageStatsQ(null);setUsageStatsData(null)}} style={{...bg_,padding:'4px 10px',fontSize:12}}>✕</button>
                    </div>
                    <div style={{fontSize:11,color:'#94A3B8',marginBottom:12,lineHeight:1.5}}>{(usageStatsQ.text||'').slice(0,100)}{(usageStatsQ.text||'').length>100?'…':''}</div>
                    {usageStatsLoading?(
                      <div style={{textAlign:'center',padding:20,fontSize:12,color:'#64748B'}}>⧐ Loading stats…</div>
                    ):usageStatsData&&usageStatsData.success?(
                      <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8}}>
                        <div style={{background:'rgba(96,165,250,0.08)',border:'1px solid rgba(96,165,250,0.25)',borderRadius:10,padding:'12px 6px',textAlign:'center'}}>
                          <div style={{fontSize:20,fontWeight:800,color:'#60A5FA'}}>{usageStatsData.examsUsedIn}</div>
                          <div style={{fontSize:9,color:'#64748B',marginTop:2}}>Exams Used In</div>
                        </div>
                        <div style={{background:'rgba(167,139,250,0.08)',border:'1px solid rgba(167,139,250,0.25)',borderRadius:10,padding:'12px 6px',textAlign:'center'}}>
                          <div style={{fontSize:20,fontWeight:800,color:'#A78BFA'}}>{usageStatsData.timesAttempted}</div>
                          <div style={{fontSize:9,color:'#64748B',marginTop:2}}>Times Attempted</div>
                        </div>
                        <div style={{background:'rgba(0,200,100,0.08)',border:'1px solid rgba(0,200,100,0.25)',borderRadius:10,padding:'12px 6px',textAlign:'center'}}>
                          <div style={{fontSize:20,fontWeight:800,color:'#00C864'}}>{usageStatsData.successRate}%</div>
                          <div style={{fontSize:9,color:'#64748B',marginTop:2}}>Success Rate</div>
                        </div>
                      </div>
                    ):(
                      <div style={{textAlign:'center',padding:20,fontSize:12,color:'#F87171'}}>Failed to load stats</div>
                    )}
                  </div>
                </div>
              )}

`;
  c=c.replace(ncAnchor, block+ncAnchor);
  changes++; console.log('✅ Frontend: Floating bar + 3 modals added');
}else console.log('⏭️  Frontend: Floating bar + modals already present');

fs.writeFileSync(f,c);
console.log('Total frontend edits applied: '+changes);
NODEEOF
node /tmp/fix_qb_frontend.js

echo "================================================================"
echo "🔄 Restarting server..."
echo "================================================================"
pkill -9 -f "node src/index.js" 2>/dev/null || true
sleep 1
cd ~/workspace && nohup node src/index.js > server.log 2>&1 &
sleep 5
tail -20 server.log

echo "================================================================"
echo "✅ VERIFICATION — Feature-wise (sequence-matched)"
echo "================================================================"

FE=frontend/app/admin/x7k2p/page.tsx
ER=src/routes/exam.js
QR=src/routes/questions.js
QF=src/routes/questionFeatures.js
EM=src/models/Exam.js

check(){ if eval "$2" >/dev/null 2>&1; then echo "✅ $1"; else echo "❌ $1"; fi }

echo "--- 1. QsBank -> Exam Direct Integration ---"
check "1.1 Checkbox on each question card (bulkSel)"      "grep -q 'checked={isChk}' $FE"
check "1.2 Floating bottom bar 'X Questions Selected'"     "grep -q 'Questions Selected' $FE"
check "1.3   Modal with 2 options (existing/new tabs)"      "grep -q \"setA2eTab('existing')\" $FE && grep -q \"setA2eTab('new')\" $FE"
check "1.3a  Add to Existing Exam -> PATCH /api/exams/:id/questions" "grep -q \"router.patch('/:id/questions'\" $ER && grep -q 'submitA2EExisting' $FE"
check "1.3b  Create New Exam -> POST /api/exams (questions[])" "grep -q 'submitA2ENew' $FE && grep -q 'questions: \\[{ type: mongoose.Schema.Types.ObjectId' $EM"
check "1.4   Success toast + selection clear"               "grep -q 'setBulkSel(\\[\\]);setShowA2E(false)' $FE"

echo "--- 2. Per-Question Usage Stats ---"
check "2. GET /:id/usage-stats + frontend modal"            "grep -q '/:id/usage-stats' $QF && grep -q 'fetchUsageStats' $FE"

echo "--- 3. Smart Filters (collapsible) ---"
check "3.0   Collapsible filter bar + active count badge"   "grep -q '🧰 Smart Filters' $FE && grep -q 'activeCnt' $FE"
check "3.1   Never used in any exam filter"                 "grep -q \"qfUsage==='never'\" $FE"
check "3.2   Most attempted (Used 5x+) filter"               "grep -q \"qfUsage==='5+'\" $FE"
check "3.3   By exam level (NEET/JEE/CUET)"                  "grep -q 'qfLevel' $FE"
check "3.4   By format (Match_Column/Assertion_Reason/Numerical)" "grep -q 'qfFormat' $FE"
check "3.5   By approval status"                             "grep -q 'qfApproval' $FE"
check "3.6   Date range filter"                              "grep -q 'qfDate' $FE"

echo "--- 4. Bulk Edit ---"
check "4. Bulk Edit button + modal + PATCH /api/questions/bulk-update" "grep -q '✏️ Bulk Edit' $FE && grep -q 'submitBulkEdit' $FE && grep -q \"router.patch('/bulk-update'\" $QR"

echo "================================================================"
echo "🏁 Done. Check server.log for errors. Test on live URL now."
echo "================================================================"
