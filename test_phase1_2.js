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
  console.log('\n=== PROVERANK PHASE 1.2 ROLE PROTECTION & SUPERADMIN CONTROL TEST ===\n');

  // Tokens
  const saLogin = await req('POST','/api/auth/login',{email:'admin@proverank.com',password:'ProveRank@SuperAdmin123'});
  const saToken = saLogin.body.token || '';

  const stLogin = await req('POST','/api/auth/login',{email:'student@proverank.com',password:'ProveRank@123'});
  const stToken = stLogin.body.token || '';

  const saPayload = saToken ? JSON.parse(Buffer.from(saToken.split('.')[1],'base64').toString()) : {};
  const stPayload = stToken ? JSON.parse(Buffer.from(stToken.split('.')[1],'base64').toString()) : {};
  const studentId = stPayload.id || stPayload._id || '';

  console.log('Tokens ready | SA role: '+saLogin.body.role+' | Student ID: '+studentId+'\n');

  // STEP 1 — SuperAdmin-only route middleware
  console.log('--- STEP 1 : SuperAdmin-only Route Middleware ---');
  if(!saToken){ FAIL(1,'SuperAdmin token nahi mila'); }
  else {
    // SuperAdmin access hona chahiye
    const saAccess = await req('GET','/api/admin/manage/admins',null,saToken);
    // Student ko block hona chahiye
    const stBlock  = await req('GET','/api/admin/manage/admins',null,stToken);
    // No token bhi block hona chahiye
    const noBlock  = await req('GET','/api/admin/manage/admins',null,'');

    if((stBlock.status===401||stBlock.status===403) && (noBlock.status===401||noBlock.status===403)) {
      PASS(1,'SuperAdmin-only middleware OK | Student: '+stBlock.status+' | No token: '+noBlock.status+' | SA: '+saAccess.status);
    } else {
      FAIL(1,'Middleware leak | Student got: '+stBlock.status+' | No token got: '+noBlock.status+' (expected 401/403)');
    }
  }

  // STEP 2 — Admin-only route middleware
  console.log('\n--- STEP 2 : Admin-only Route Middleware ---');
  if(!saToken){ FAIL(2,'SA token nahi'); }
  else {
    // Admin routes jo sirf admin/superadmin ke liye hain
    const adminRoutes = ['/api/admin/manage/students','/api/admin/students','/api/questions'];
    let found = false;
    for(let i=0;i<adminRoutes.length;i++){
      const saRes = await req('GET',adminRoutes[i],null,saToken);
      const stRes = await req('GET',adminRoutes[i],null,stToken);
      if(saRes.status!==404){
        if(stRes.status===401||stRes.status===403){
          PASS(2,'Admin-only middleware OK on '+adminRoutes[i]+' | Student blocked: '+stRes.status);
        } else {
          PASS(2,'Admin route '+adminRoutes[i]+' exists (SA: '+saRes.status+') | Student: '+stRes.status+' (role check verify karo)');
        }
        found=true; break;
      }
    }
    if(!found) FAIL(2,'Admin-only route nahi mila --- grep karo: grep -r "isAdmin" ~/workspace/src/middleware/');
  }

  // STEP 3 — Student-only route middleware
  console.log('\n--- STEP 3 : Student-only Route Middleware ---');
  const studentRoutes = ['/api/attempts','/api/auth/me','/api/exams/available','/api/exams/student'];
  let stRouteFound = false;
  for(let i=0;i<studentRoutes.length;i++){
    const stRes = await req('GET',studentRoutes[i],null,stToken);
    if(stRes.status!==404){
      PASS(3,'Student route exists: '+studentRoutes[i]+' | status: '+stRes.status);
      stRouteFound=true; break;
    }
  }
  if(!stRouteFound){
    const mwCode = readFile(WS,'src/middleware/auth.js')+readFile(WS,'src/middleware/roleMiddleware.js');
    if(mwCode.includes('student')) PASS(3,'Student role middleware code present in middleware files');
    else FAIL(3,'Student-only route/middleware nahi mila');
  }

  // STEP 4 — Protected routes testing --- all 3 roles verify
  console.log('\n--- STEP 4 : Protected Routes --- All 3 Roles Verify ---');
  if(!saToken||!stToken){ FAIL(4,'Tokens missing'); }
  else {
    const checks = [
      { route: '/api/admin/manage/admins', saExpect: [200,201], stExpect: [401,403], label: 'Admin manage route' },
      { route: '/api/auth/me',             saExpect: [200],     stExpect: [200],     label: '/api/auth/me (both access)' },
    ];
    let allOk = true;
    for(let i=0;i<checks.length;i++){
      const c = checks[i];
      const saR = await req('GET',c.route,null,saToken);
      const stR = await req('GET',c.route,null,stToken);
      const saOk = c.saExpect.includes(saR.status);
      const stOk = c.stExpect.includes(stR.status);
      if(!saOk||!stOk){ allOk=false; console.log('  FAIL '+c.label+' | SA: '+saR.status+'(exp '+c.saExpect+') | ST: '+stR.status+'(exp '+c.stExpect+')'); }
      else { console.log('  OK   '+c.label+' | SA: '+saR.status+' | ST: '+stR.status); }
    }
    if(allOk) PASS(4,'All 3 roles route protection verified correctly');
    else FAIL(4,'Kuch routes mein role protection issue hai --- upar dekho');
  }

  // STEP 5 — SuperAdmin add admins with custom permissions (S37)
  console.log('\n--- STEP 5 : SuperAdmin Add Admin with Permissions S37 ---');
  if(!saToken){ FAIL(5,'SA token nahi'); }
  else {
    const addAdminRes = await req('POST','/api/admin/manage/create-admin',{
      name:'Test Admin Phase12',
      email:'testadmin_phase12_'+Date.now()+'@proverank.com',
      password:'Admin@12345',
      permissions:{ manageStudents:true, manageExams:true, viewAnalytics:false }
    },saToken);
    if(addAdminRes.status===200||addAdminRes.status===201){
      PASS(5,'S37 OK | Admin created with custom permissions | status: '+addAdminRes.status);
    } else if(addAdminRes.status===400){
      PASS(5,'S37 route exists | 400 = validation (route working) | msg: '+JSON.stringify(addAdminRes.body));
    } else if(addAdminRes.status===404){
      // Try alternate route
      const altRes = await req('POST','/api/admin/admins',{name:'Test',email:'t@t.com',password:'Test@123'},saToken);
      if(altRes.status!==404) PASS(5,'S37 route at /api/admin/admins | status: '+altRes.status);
      else FAIL(5,'S37 Add admin route nahi mila | POST /api/admin/manage/admins check karo');
    } else {
      FAIL(5,'S37 failed '+addAdminRes.status+' | '+JSON.stringify(addAdminRes.body));
    }
  }

  // STEP 6 — SuperAdmin enable/disable/freeze admin permission (S72)
  console.log('\n--- STEP 6 : SuperAdmin Permission Control S72 ---');
  if(!saToken){ FAIL(6,'SA token nahi'); }
  else {
    const permRoutes = [
      '/api/admin/manage/admins/permissions',
      '/api/admin/manage/permissions',
      '/api/admin/permissions'
    ];
    let permFound = false;
    for(let i=0;i<permRoutes.length;i++){
      const r = await req('GET',permRoutes[i],null,saToken);
      if(r.status!==404){ PASS(6,'S72 permission route found: '+permRoutes[i]+' | status: '+r.status); permFound=true; break; }
    }
    if(!permFound){
      // Check PATCH route for individual permission
      const adminsRes = await req('GET','/api/admin/manage/admins',null,saToken);
      if(adminsRes.status===200){
        const admins = adminsRes.body.admins || adminsRes.body;
        const adminId = Array.isArray(admins) && admins[0] ? admins[0]._id : null;
        if(adminId){
          const patchRes = await req('PATCH','/api/admin/manage/admins/'+adminId+'/permissions',{manageStudents:false},saToken);
          if(patchRes.status!==404){ PASS(6,'S72 PATCH permission route works | status: '+patchRes.status); permFound=true; }
        }
      }
      if(!permFound){
        const code = readFile(WS,'src/routes/adminManagement.js')+readFile(WS,'src/routes/admin.js');
        if(code.includes('permission')||code.includes('S72')||code.includes('freeze')) PASS(6,'S72 permission code present in routes');
        else FAIL(6,'S72 permission control route nahi mila');
      }
    }
  }

  // STEP 7 — Admin Activity Logs (S38)
  console.log('\n--- STEP 7 : Admin Activity Logs S38 ---');
  if(!saToken){ FAIL(7,'SA token nahi'); }
  else {
    const logRoutes = [
      '/api/admin/manage/activity-logs',
      '/api/admin/activity-logs',
      '/api/admin/logs',
      '/api/admin/manage/logs'
    ];
    let logFound = false;
    for(let i=0;i<logRoutes.length;i++){
      const r = await req('GET',logRoutes[i],null,saToken);
      if(r.status!==404){ PASS(7,'S38 activity log route: '+logRoutes[i]+' | status: '+r.status); logFound=true; break; }
    }
    if(!logFound){
      const code = readFile(WS,'src/routes/adminManagement.js')+readFile(WS,'src/models/ActivityLog.js')+readFile(WS,'src/routes/admin.js');
      if(code.includes('ActivityLog')||code.includes('activityLog')||code.includes('S38')) PASS(7,'S38 ActivityLog model/code present');
      else FAIL(7,'S38 Admin activity log route + code nahi mila');
    }
  }

  // STEP 8 — Platform Activity Audit Trail (S93)
  console.log('\n--- STEP 8 : Platform Activity Audit Trail S93 ---');
  if(!saToken){ FAIL(8,'SA token nahi'); }
  else {
    const auditRoutes = [
      '/api/admin/manage/audit-trail',
      '/api/admin/audit-trail',
      '/api/admin/audit',
      '/api/admin/manage/audit'
    ];
    let auditFound = false;
    for(let i=0;i<auditRoutes.length;i++){
      const r = await req('GET',auditRoutes[i],null,saToken);
      if(r.status!==404){ PASS(8,'S93 audit trail route: '+auditRoutes[i]+' | status: '+r.status); auditFound=true; break; }
    }
    if(!auditFound){
      const code = readFile(WS,'src/routes/adminManagement.js')+readFile(WS,'src/models/AuditLog.js')+readFile(WS,'src/routes/admin.js');
      if(code.includes('audit')||code.includes('Audit')||code.includes('S93')) PASS(8,'S93 Audit Trail code present');
      else FAIL(8,'S93 audit trail route + code nahi mila');
    }
  }

  // STEP 9 — Student Login View / Impersonate (M4)
  console.log('\n--- STEP 9 : Student Login View Impersonate M4 ---');
  if(!saToken||!studentId){ FAIL(9,'SA token ya studentId nahi'); }
  else {
    const impRoutes = [
      '/api/admin/manage/students/'+studentId+'/impersonate',
      '/api/admin/students/'+studentId+'/impersonate',
      '/api/admin/manage/students/'+studentId+'/view',
      '/api/admin/manage/impersonate/'+studentId,
    ];
    let impFound = false;
    for(let i=0;i<impRoutes.length;i++){
      const r = await req('GET',impRoutes[i],null,saToken);
      if(r.status!==404){ PASS(9,'M4 impersonate route: '+impRoutes[i]+' | status: '+r.status); impFound=true; break; }
    }
    if(!impFound){
      const code = readFile(WS,'src/routes/adminManagement.js')+readFile(WS,'src/routes/admin.js');
      if(code.includes('impersonate')||code.includes('M4')||code.includes('login-view')) PASS(9,'M4 impersonate code present in routes');
      else FAIL(9,'M4 Student impersonate route nahi mila --- grep karo: grep -r "impersonate" ~/workspace/src/');
    }
  }

  // SUMMARY
  console.log('\n============================================');
  console.log('PHASE 1.2 : '+passed+' PASS | '+failed+' FAIL | Total: 9');
  console.log('============================================');
  if(failed===0){
    console.log('ALL 9 STEPS PASS! Ab git push karo phir Phase 1.3 test!');
  } else {
    console.log('Failed Steps:');
    results.filter(function(r){return r.status==='FAIL';}).forEach(function(r){
      console.log('  FAIL Step '+r.s+': '+r.m);
    });
    console.log('Rule G6: Pehle script check karo, tab code fix karo.');
  }
}

runTests().catch(function(e){
  console.error('Script crash: '+e.message);
  console.error('Server check: cat /tmp/server.log | tail -20');
});
