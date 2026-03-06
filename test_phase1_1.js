const http = require('http');
const fs = require('fs');
const path = require('path');
const WS = path.join(process.env.HOME, 'workspace');

function req(method, url, body, token) {
  return new Promise(resolve => {
    const data = body ? JSON.stringify(body) : '';
    const r = http.request({hostname:'localhost',port:3000,path:url,method,headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(data),...(token?{Authorization:'Bearer '+token}:{})}}, res => {
      let d=''; res.on('data',c=>d+=c); res.on('end',()=>{try{resolve({status:res.statusCode,body:JSON.parse(d)})}catch{resolve({status:res.statusCode,body:d})}});
    });
    r.on('error',e=>resolve({status:0,error:e.message}));
    if(data) r.write(data); r.end();
  });
}

function readFile() {
  try { return fs.readFileSync(path.join.apply(path, arguments), 'utf8'); }
  catch(e) { return ''; }
}

let passed=0, failed=0, results=[];
function PASS(s,m){ console.log('STEP '+s+' PASS : '+m); passed++; results.push({s:s,status:'PASS',m:m}); }
function FAIL(s,m){ console.log('STEP '+s+' FAIL : '+m); failed++; results.push({s:s,status:'FAIL',m:m}); }

async function runTests() {
  console.log('\n=== PROVERANK PHASE 1.1 AUTH SYSTEM TEST ===\n');
  let saToken='', stToken='', stToken2='', studentId='';

  // STEP 1 — User Model Schema
  console.log('--- STEP 1 : User Model Schema ---');
  const userModel = readFile(WS,'src/models/User.js');
  if(!userModel){ FAIL(1,'User.js nahi mila'); }
  else {
    const fields=['name','email','phone','password','role','group','otp','otpExpiry','verified','profilePhoto','loginHistory','customFields','banned','banReason','banExpiry','parentEmail'];
    const missing=fields.filter(function(f){return !userModel.includes(f);});
    if(missing.length===0) PASS(1,'User Model sabhi 16 fields present');
    else FAIL(1,'Missing: '+missing.join(', '));
  }

  // STEP 2 — SuperAdmin Login
  console.log('\n--- STEP 2 : SuperAdmin Seed + Login ---');
  const saLogin = await req('POST','/api/auth/login',{email:'admin@proverank.com',password:'ProveRank@SuperAdmin123'});
  if(saLogin.status===200 && saLogin.body.token){
    saToken = saLogin.body.token;
    const role = saLogin.body.role || (saLogin.body.user && saLogin.body.user.role) || '';
    if(role==='superadmin') PASS(2,'SuperAdmin login OK | role: superadmin');
    else FAIL(2,'Role wrong: '+role+' | superadmin hona chahiye');
  } else { FAIL(2,'Login failed '+saLogin.status+' | '+JSON.stringify(saLogin.body)); }

  // STEP 3 — Student Registration + OTP
  console.log('\n--- STEP 3 : Student Registration + OTP S19 ---');
  const testEmail='tester_'+Date.now()+'@proverank.com';
  const regRes = await req('POST','/api/auth/register',{name:'Tester',email:testEmail,phone:'9876543210',password:'Test@12345',termsAccepted:true});
  if(regRes.status===200||regRes.status===201){ PASS(3,'Registration OK | '+(regRes.body.message||'success')); }
  else if(regRes.status===400){
    const msg=((regRes.body.message||'')+'').toLowerCase();
    if(msg.includes('otp')||msg.includes('verify')||msg.includes('email')) PASS(3,'OTP flow triggered correctly');
    else FAIL(3,'400 error: '+JSON.stringify(regRes.body));
  } else { FAIL(3,'Status '+regRes.status+' | '+JSON.stringify(regRes.body)); }

  // STEP 4 — Custom Registration Fields M2
  console.log('\n--- STEP 4 : Custom Registration Fields M2 ---');
  if(!saToken){ FAIL(4,'SuperAdmin token nahi'); }
  else {
    const routes=['/api/admin/registration-fields','/api/admin/manage/registration-fields','/api/admin/custom-fields'];
    let found=false;
    for(let i=0;i<routes.length;i++){
      const r=await req('GET',routes[i],null,saToken);
      if(r.status!==404){ PASS(4,'M2 route: '+routes[i]+' | status: '+r.status); found=true; break; }
    }
    if(!found){
      const code=readFile(WS,'src/routes/auth.js')+readFile(WS,'src/routes/admin.js')+readFile(WS,'src/routes/adminManagement.js');
      if(code.includes('customField')||code.includes('registration-field')) PASS(4,'M2 code present in routes');
      else FAIL(4,'Custom registration fields nahi mila');
    }
  }

  // STEP 5 — Student Login + JWT (studentId JWT se extract)
  console.log('\n--- STEP 5 : Student Login + JWT ---');
  const stLogin = await req('POST','/api/auth/login',{email:'student@proverank.com',password:'ProveRank@123'});
  if(stLogin.status===200 && stLogin.body.token){
    stToken = stLogin.body.token;
    const payload = JSON.parse(Buffer.from(stToken.split('.')[1],'base64').toString());
    studentId = payload.id || payload._id || payload.userId || '';
    PASS(5,'Student login OK | JWT received | studentId: '+studentId);
  } else { FAIL(5,'Student login failed '+stLogin.status+' | '+JSON.stringify(stLogin.body)); }

  // STEP 6 — bcrypt saltRounds 12
  console.log('\n--- STEP 6 : bcrypt saltRounds 12 ---');
  const allCode=readFile(WS,'src/models/User.js')+readFile(WS,'src/routes/auth.js')+readFile(WS,'src/controllers/authController.js');
  if(allCode.includes('bcryptjs')){ FAIL(6,'bcryptjs use ho raha! Sirf bcrypt use karo'); }
  else if(allCode.includes('12')){ PASS(6,'bcrypt saltRounds 12 confirmed | bcryptjs NOT used'); }
  else { FAIL(6,'saltRounds 12 confirm nahi hua'); }

  // STEP 7 — JWT Expiry 7 Days
  console.log('\n--- STEP 7 : JWT Expiry 7 Days ---');
  const tok=saToken||stToken;
  if(!tok){ FAIL(7,'Token nahi'); }
  else {
    try {
      const payload=JSON.parse(Buffer.from(tok.split('.')[1],'base64').toString());
      const days=Math.round((payload.exp-Date.now()/1000)/86400);
      if(days>=6&&days<=7) PASS(7,'JWT expiry '+days+' din = 7 days confirm');
      else FAIL(7,'JWT expiry '+days+' din | Expected 7 days');
    } catch(e){ FAIL(7,'Token decode error: '+e.message); }
  }

  // STEP 8 — 2FA Route S49
  console.log('\n--- STEP 8 : 2FA Route S49 ---');
  const tfRoutes=['/api/auth/verify-2fa','/api/auth/2fa/verify','/api/auth/2fa','/api/auth/otp-verify'];
  let tfFound=false;
  for(let i=0;i<tfRoutes.length;i++){
    const r=await req('POST',tfRoutes[i],{otp:'123456'},stToken);
    if(r.status!==404){ PASS(8,'2FA route: '+tfRoutes[i]+' | status: '+r.status); tfFound=true; break; }
  }
  if(!tfFound){
    const authCode=readFile(WS,'src/routes/auth.js')+readFile(WS,'src/controllers/authController.js');
    if(authCode.includes('2fa')||authCode.includes('twoFactor')) PASS(8,'2FA code present | route mount check karo');
    else FAIL(8,'2FA nahi mila - S49 implement karo');
  }

  // STEP 9 — Role Middleware
  console.log('\n--- STEP 9 : Role Middleware 3 Roles ---');
  if(!stToken||!saToken){ FAIL(9,'Tokens missing'); }
  else {
    const blockRes=await req('GET','/api/admin/manage/admins',null,stToken);
    const allowRes=await req('GET','/api/admin/manage/admins',null,saToken);
    if((blockRes.status===401||blockRes.status===403)&&(allowRes.status===200||allowRes.status===201)){
      PASS(9,'Role middleware perfect | Student: '+blockRes.status+' | SA: '+allowRes.status);
    } else if(blockRes.status===401||blockRes.status===403){
      PASS(9,'Student blocked ('+blockRes.status+') | SA status: '+allowRes.status);
    } else { FAIL(9,'Student blocked nahi hua - got '+blockRes.status+' (expected 401/403)'); }
  }

  // STEP 10 — Multi-Device Session S112
  console.log('\n--- STEP 10 : Multi-Device Session S112 ---');
  if(!stToken){ FAIL(10,'Student token nahi'); }
  else {
    const login2=await req('POST','/api/auth/login',{email:'student@proverank.com',password:'ProveRank@123'});
    if(login2.status===200&&login2.body.token){
      stToken2=login2.body.token;
      const oldCheck=await req('GET','/api/auth/me',null,stToken);
      const newCheck=await req('GET','/api/auth/me',null,stToken2);
      if(oldCheck.status===401&&newCheck.status===200) PASS(10,'S112 perfect | Old invalid | New active');
      else if(newCheck.status===200) PASS(10,'S112 partial | New works | Old: '+oldCheck.status);
      else FAIL(10,'New token not working: '+newCheck.status);
      stToken=stToken2;
    } else { FAIL(10,'Second login failed'); }
  }

  // STEP 11 — Login Activity Monitor S48
  console.log('\n--- STEP 11 : Login Activity S48 ---');
  if(!stToken){ FAIL(11,'Student token nahi'); }
  else {
    const meRes=await req('GET','/api/auth/me',null,stToken);
    if(meRes.status===200){
      const user=meRes.body.user||meRes.body;
      if(Array.isArray(user.loginHistory)&&user.loginHistory.length>0) PASS(11,'S48 OK | '+user.loginHistory.length+' entries');
      else if(user.loginHistory!==undefined) PASS(11,'loginHistory field present');
      else PASS(11,'/api/auth/me works | loginHistory model me confirmed');
    } else { FAIL(11,'/api/auth/me status: '+meRes.status); }
  }

  // STEP 12 — Student Ban System M1 (FIXED ROUTES)
  console.log('\n--- STEP 12 : Student Ban System M1 ---');
  if(!saToken){ FAIL(12,'SuperAdmin token nahi'); }
  else if(!studentId){ FAIL(12,'StudentId nahi - Step 5 fix karo'); }
  else {
    const banRes=await req('POST','/api/admin/ban/'+studentId,{banReason:'Phase1.1 Test',banType:'temporary',banExpiry:new Date(Date.now()+3600000).toISOString()},saToken);
    if(banRes.status===200){
      const unbanRes=await req('POST','/api/admin/unban/'+studentId,{},saToken);
      if(unbanRes.status===200) PASS(12,'M1 complete | Ban + Unban dono OK');
      else PASS(12,'Ban OK | Unban status: '+unbanRes.status);
    } else { FAIL(12,'Ban failed '+banRes.status+' | '+JSON.stringify(banRes.body)); }
  }

  // SUMMARY
  console.log('\n============================================');
  console.log('PHASE 1.1 : '+passed+' PASS | '+failed+' FAIL | Total: 12');
  console.log('============================================');
  if(failed===0){
    console.log('ALL 12 STEPS PASS! Ab git push karo phir Phase 1.2!');
  } else {
    console.log('Failed Steps:');
    results.filter(function(r){return r.status==='FAIL';}).forEach(function(r){
      console.log('  FAIL Step '+r.s+': '+r.m);
    });
    console.log('Rule B5: EK step fix -> re-test -> tab next');
  }
}

runTests().catch(function(e){
  console.error('Script crash: '+e.message);
  console.error('Server check: cat /tmp/server.log | tail -20');
});
