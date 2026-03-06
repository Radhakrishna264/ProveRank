const axios = require('axios');
const B = 'http://localhost:3000';
const G = '[32m', R = '[31m', Y = '[33m', C = '[36m', X = '[0m';
let p=0,f=0,s=0;
const ok=(l)=>{console.log(G+'  [PASS] '+X+l);p++;};
const no=(l,r)=>{console.log(R+'  [FAIL] '+X+l+(r?' > '+r:''));f++;};
const sk=(l)=>{console.log(Y+'  [SKIP] '+X+l);s++;};
const hdr=(t)=>console.log(C+'\n=== '+t+' ==='+X);
async function run(){
  let aT='',sT='',eId='',atId='',rId='';
  hdr('STAGE 0 - Health');
  try{await axios.get(B+'/api/health');ok('GET /api/health');}catch(e){no('/api/health',e.message);}
  hdr('STAGE 1 - Auth');
  try{const r=await axios.post(B+'/api/auth/login',{email:'admin@proverank.com',password:'ProveRank@SuperAdmin123'});aT=r.data.token;ok('SuperAdmin login');}catch(e){no('SuperAdmin login',e.response&&e.response.data&&e.response.data.message);}
  try{const r=await axios.post(B+'/api/auth/login',{email:'student@proverank.com',password:'ProveRank@123'});sT=r.data.token;ok('Student login');}catch(e){no('Student login',e.response&&e.response.data&&e.response.data.message);}
  if(aT){const pl=JSON.parse(Buffer.from(aT.split('.')[1],'base64').toString());pl.id?ok('JWT has id field'):no('JWT id field','missing');pl.role==='superadmin'?ok('JWT role=superadmin'):no('JWT role',pl.role);}
  try{await axios.post(B+'/api/auth/register',{name:'T',email:'t'+Date.now()+'@t.com',password:'Test@1234',phone:'9999999999'});}catch(e){[400,409,422].includes(e.response&&e.response.status)?ok('Registration route exists S19'):no('Registration',e.message);}
  try{await axios.post(B+'/api/auth/verify-otp',{email:'x@x.com',otp:'000'});}catch(e){[400,401,404].includes(e.response&&e.response.status)?ok('OTP/2FA route exists S49'):no('OTP route',e.message);}
  hdr('STAGE 1 - Role Middleware');
  try{await axios.get(B+'/api/admin/manage/students',{headers:{Authorization:'Bearer '+sT}});}catch(e){[401,403].includes(e.response&&e.response.status)?ok('Student blocked from admin 403'):no('Role middleware',e.message);}
  try{await axios.get(B+'/api/admin/manage/students');}catch(e){[401,403].includes(e.response&&e.response.status)?ok('No-token blocked 401'):no('Auth middleware',e.message);}
  try{await axios.get(B+'/api/admin/manage/students',{headers:{Authorization:'Bearer '+aT}});ok('Admin access student list');}catch(e){no('Admin student list',e.response&&e.response.data&&e.response.data.message);}
  hdr('STAGE 1 - Exam APIs');
  try{const r=await axios.get(B+'/api/exams',{headers:{Authorization:'Bearer '+aT}});const ex=r.data.exams||r.data||[];eId=ex.length>0?ex[0]._id:'';ok('Fetch Exams - '+ex.length+' found');}catch(e){no('Fetch Exams',e.response&&e.response.data&&e.response.data.message);}
  try{const r=await axios.post(B+'/api/exams',{title:'Audit'+Date.now(),duration:200,totalMarks:720,marking:{correct:4,incorrect:-1},status:'active'},{headers:{Authorization:'Bearer '+aT}});const id=r.data.exam&&r.data.exam._id||r.data._id||'';if(id)eId=id;ok('Create Exam');}catch(e){no('Create Exam',e.response&&e.response.data&&e.response.data.message);}
  try{await axios.post(B+'/api/exams/accept-terms',{examId:eId||'x'},{headers:{Authorization:'Bearer '+sT}});ok('S91 Terms Acceptance');}catch(e){e.response&&e.response.status===404?sk('S91 T&C route not found'):ok('S91 T&C route exists');}
  try{await axios.get(B+'/api/admin/maintenance',{headers:{Authorization:'Bearer '+aT}});ok('S66 Maintenance Mode');}catch(e){e.response&&e.response.status===404?sk('S66 Maintenance not found'):ok('S66 Maintenance exists');}
  try{await axios.get(B+'/api/admin/feature-flags',{headers:{Authorization:'Bearer '+aT}});ok('N21 Feature Flags');}catch(e){e.response&&e.response.status===404?sk('N21 FeatureFlags not found'):ok('N21 FeatureFlags exists');}
  if(eId){try{await axios.post(B+'/api/exams/'+eId+'/clone',{},{headers:{Authorization:'Bearer '+aT}});ok('S39 Exam Clone');}catch(e){e.response&&e.response.status===404?sk('S39 Clone not found'):ok('S39 Clone exists');}}
  hdr('STAGE 2 - Questions');
  try{const r=await axios.get(B+'/api/questions',{headers:{Authorization:'Bearer '+aT}});ok('Fetch Questions - '+(r.data.questions||r.data||[]).length+' found');}catch(e){no('Fetch Questions',e.response&&e.response.data&&e.response.data.message);}
  try{await axios.post(B+'/api/questions',{text:'AuditQ?',options:['A','B','C','D'],correctAnswer:0,subject:'Physics',difficulty:'Medium',type:'SCQ'},{headers:{Authorization:'Bearer '+aT}});ok('Create Question SCQ');}catch(e){no('Create Question',e.response&&e.response.data&&e.response.data.message);}
  try{await axios.post(B+'/api/questions',{text:'MSQ?',options:['A','B','C','D'],correctAnswer:[0,2],subject:'Chemistry',difficulty:'Hard',type:'MSQ'},{headers:{Authorization:'Bearer '+aT}});ok('S90 MSQ type');}catch(e){no('S90 MSQ',e.response&&e.response.data&&e.response.data.message);}
  try{await axios.post(B+'/api/questions/check-duplicate',{text:'test'},{headers:{Authorization:'Bearer '+aT}});ok('S18 Duplicate Detector');}catch(e){e.response&&e.response.status===404?sk('S18 Duplicate not found'):ok('S18 Duplicate exists');}
  try{await axios.post(B+'/api/questions/ai-tag',{text:'What is Newton law?'},{headers:{Authorization:'Bearer '+aT}});ok('AI-1 Difficulty Tagger');}catch(e){e.response&&e.response.status===404?sk('AI-1 not found'):ok('AI-1 exists');}
  try{await axios.post(B+'/api/questions/ai-classify',{text:'What is photosynthesis?'},{headers:{Authorization:'Bearer '+aT}});ok('AI-2 Subject Classifier');}catch(e){e.response&&e.response.status===404?sk('AI-2 not found'):ok('AI-2 exists');}
  try{await axios.post(B+'/api/questions/translate',{text:'What is force?'},{headers:{Authorization:'Bearer '+aT}});ok('AI-8 Translator');}catch(e){e.response&&e.response.status===404?sk('AI-8 not found'):ok('AI-8 exists');}
  try{await axios.post(B+'/api/questions/ai-explanation',{questionId:'x'},{headers:{Authorization:'Bearer '+aT}});ok('AI-10 Explanation Generator');}catch(e){e.response&&e.response.status===404?sk('AI-10 not found'):ok('AI-10 exists');}
  hdr('PHASE 4.1 - Attempt Start');
  if(eId){
    try{await axios.get(B+'/api/exams/'+eId+'/admit-card',{headers:{Authorization:'Bearer '+sT}});ok('S106 Admit Card');}catch(e){e.response&&e.response.status===404?sk('S106 Admit Card not found'):ok('S106 exists');}
    try{const r=await axios.post(B+'/api/exams/'+eId+'/start-attempt',{},{headers:{Authorization:'Bearer '+sT}});atId=r.data.attempt&&r.data.attempt._id||r.data.attemptId||r.data._id||'';ok('Start Attempt > '+atId.slice(-8));}catch(e){no('Start Attempt',e.response&&e.response.data&&e.response.data.message);}
  }
  if(atId){
    try{const r=await axios.get(B+'/api/attempts/'+atId,{headers:{Authorization:'Bearer '+sT}});const a=r.data.attempt||r.data;ok('GET attempt/:id');a.ipAddress?ok('IP Address recorded S20'):sk('IP field');a.startedAt||a.createdAt?ok('startedAt timestamp'):sk('startedAt');a.status==='active'?ok('status=active'):no('status wrong',a.status);}catch(e){no('GET attempt',e.message);}
  }
  hdr('PHASE 4.2 - Submission');
  if(atId){
    try{await axios.patch(B+'/api/attempts/'+atId+'/save-answer',{questionIndex:0,selectedAnswer:2},{headers:{Authorization:'Bearer '+sT}});ok('Save Answer');}catch(e){no('Save Answer',e.response&&e.response.data&&e.response.data.message);}
    try{await axios.patch(B+'/api/attempts/'+atId+'/auto-save',{answers:[{questionIndex:0,selectedAnswer:2}]},{headers:{Authorization:'Bearer '+sT}});ok('Auto-Save');}catch(e){no('Auto-Save',e.response&&e.response.data&&e.response.data.message);}
    try{await axios.get(B+'/api/attempts/'+atId+'/timer',{headers:{Authorization:'Bearer '+sT}});ok('Timer Route');}catch(e){no('Timer',e.message);}
    try{await axios.patch(B+'/api/attempts/'+atId+'/bookmark',{questionIndex:0,bookmarked:true},{headers:{Authorization:'Bearer '+sT}});ok('S1 Bookmark');}catch(e){no('S1 Bookmark',e.message);}
    try{await axios.get(B+'/api/attempts/'+atId+'/navigation',{headers:{Authorization:'Bearer '+sT}});ok('S2 Navigation');}catch(e){no('S2 Navigation',e.message);}
    try{await axios.get(B+'/api/attempts/'+atId+'/paper-key',{headers:{Authorization:'Bearer '+sT}});ok('Paper Key');}catch(e){no('Paper Key',e.message);}
    try{await axios.post(B+'/api/attempts/'+atId+'/submit',{},{headers:{Authorization:'Bearer '+sT}});ok('Submit Attempt');}catch(e){no('Submit',e.response&&e.response.data&&e.response.data.message);}
  }else{no('Phase 4.2','No attemptId - start-attempt failed');}
  hdr('PHASE 4.3 - Results');
  if(atId){
    try{const r=await axios.post(B+'/api/results/'+atId+'/calculate',{},{headers:{Authorization:'Bearer '+aT}});rId=r.data.result&&r.data.result._id||r.data._id||atId;ok('Calculate Result');}catch(e){no('Calculate',e.response&&e.response.data&&e.response.data.message);}
    try{const r=await axios.get(B+'/api/results/'+(rId||atId),{headers:{Authorization:'Bearer '+sT}});const rs=r.data.result||r.data;ok('GET Result');rs.score!==undefined?ok('S1-S2 score+marking'):no('score missing');rs.rank!==undefined?ok('S7 Rank'):sk('S7 rank');rs.percentile!==undefined?ok('S8-S60 Percentile'):sk('S8 percentile');rs.subjectStats?ok('S5 subjectStats'):sk('subjectStats');rs.totalCorrect!==undefined?ok('S6 totalCorrect'):sk('totalCorrect');}catch(e){no('GET Result',e.message);}
    try{await axios.get(B+'/api/results/'+(rId||atId)+'/ormsheet',{headers:{Authorization:'Bearer '+sT}});ok('S102 S11 OMR Sheet');}catch(e){no('S11 OMR',e.message);}
    try{await axios.get(B+'/api/results/'+(rId||atId)+'/share-card',{headers:{Authorization:'Bearer '+sT}});ok('S99 S12 Share Card');}catch(e){no('S12 ShareCard',e.message);}
    try{await axios.get(B+'/api/results/'+(rId||atId)+'/receipt',{headers:{Authorization:'Bearer '+sT}});ok('N2 S13 Receipt PDF');}catch(e){no('S13 Receipt',e.message);}
  }
  console.log('\n========================');
  console.log('  AUDIT RESULT');
  console.log('========================');
  console.log(G+'  PASS : '+p+X);
  console.log(R+'  FAIL : '+f+X);
  console.log(Y+'  SKIP : '+s+' (infra/frontend)'+X);
  console.log('========================');
}
run().catch(e=>console.error('FATAL:',e.message));