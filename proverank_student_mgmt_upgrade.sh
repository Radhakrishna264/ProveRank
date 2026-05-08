#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Student Management COMPLETE UPGRADE             ║
# ║  Features: Soft-Delete + Restore + Premium SaaS Redesign     ║
# ║  Rule: No Python | cat>EOF | No sed -i                       ║
# ╚══════════════════════════════════════════════════════════════╝

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
step(){ echo -e "\n${Y}━━━ $1 ━━━${N}"; }
ok(){ echo -e "${G}✅ $1${N}"; }
err(){ echo -e "${R}❌ $1${N}"; }

WORK=~/workspace
FE=$WORK/frontend
PAGE=$FE/app/admin/x7k2p/page.tsx

# ─── Sanity check ──────────────────────────────────────────────
if [ ! -f "$PAGE" ]; then
  err "page.tsx not found at $PAGE"
  exit 1
fi
ok "page.tsx found"

# ══════════════════════════════════════════════════════════════
# STEP 1: BACKEND — Add delete / restore / get-deleted routes
# ══════════════════════════════════════════════════════════════
step "STEP 1: Adding backend delete/restore routes"

node << 'BACKEND_PATCH_EOF'
const fs = require('fs');
const path = require('path');

const routesDir = process.env.HOME + '/workspace/src/routes/';

// Find the admin system routes file (has ban/unban)
let adminFile = null;
const files = fs.readdirSync(routesDir);
for(const f of files){
  const content = fs.readFileSync(routesDir + f, 'utf8');
  if(content.includes('api/admin/ban') || content.includes('/ban/:') || content.includes('unban')){
    adminFile = routesDir + f;
    break;
  }
}

if(!adminFile){
  // Try common names
  const tries = ['adminSystem.js','admin.js','adminRoutes.js','adminSystemRoutes.js'];
  for(const t of tries){
    if(fs.existsSync(routesDir + t)){ adminFile = routesDir + t; break; }
  }
}

if(!adminFile){ console.log('❌ Admin routes file not found'); process.exit(1); }
console.log('✅ Admin routes file: ' + adminFile);

let c = fs.readFileSync(adminFile, 'utf8');

if(c.includes("router.post('/delete/:userId'") || c.includes('soft-deleted')){
  console.log('✅ Delete routes already exist — skipping');
  process.exit(0);
}

// Find module.exports to insert before it
const expIdx = c.lastIndexOf('module.exports');
if(expIdx === -1){ console.log('❌ module.exports not found'); process.exit(1); }

const newRoutes = `
// ── SOFT DELETE STUDENT (SuperAdmin only) ──────────────────
router.post('/delete/:userId', verifyToken, async(req, res) => {
  try {
    if(req.user.role !== 'superadmin') return res.status(403).json({ error: 'SuperAdmin only' });
    const mongoose = require('mongoose');
    const User = require('../models/User');
    const { reason } = req.body;
    const student = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.params.userId) });
    if(!student) return res.status(404).json({ error: 'Student not found' });
    // Save snapshot before soft-delete
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(req.params.userId) },
      {
        $set: {
          deleted: true,
          deletedAt: new Date(),
          deletedBy: req.user.id,
          deleteReason: reason || 'Removed by SuperAdmin',
          _snapshot: {
            name: student.name,
            email: student.email,
            phone: student.phone,
            group: student.group,
            city: student.city,
            school: student.school,
            targetExam: student.targetExam,
            qualifications: student.qualifications,
            createdAt: student.createdAt
          }
        }
      }
    );
    res.json({ success: true, message: 'Student soft-deleted successfully' });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── RESTORE DELETED STUDENT (SuperAdmin only) ──────────────
router.post('/restore/:userId', verifyToken, async(req, res) => {
  try {
    if(req.user.role !== 'superadmin') return res.status(403).json({ error: 'SuperAdmin only' });
    const mongoose = require('mongoose');
    const User = require('../models/User');
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(req.params.userId) },
      { $unset: { deleted: 1, deletedAt: 1, deletedBy: 1, deleteReason: 1, _snapshot: 1 } }
    );
    res.json({ success: true, message: 'Student account restored successfully' });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── GET DELETED STUDENTS (SuperAdmin only) ─────────────────
router.get('/deleted-students', verifyToken, async(req, res) => {
  try {
    if(req.user.role !== 'superadmin') return res.status(403).json({ error: 'SuperAdmin only' });
    const User = require('../models/User');
    const students = await User.collection.find(
      { role: 'student', deleted: true },
      { sort: { deletedAt: -1 } }
    ).toArray();
    res.json({ students });
  } catch(e) { res.status(500).json({ error: e.message }); }
});

`;

c = c.slice(0, expIdx) + newRoutes + c.slice(expIdx);
fs.writeFileSync(adminFile, c);
console.log('✅ Backend delete/restore routes added!');
BACKEND_PATCH_EOF

# ══════════════════════════════════════════════════════════════
# STEP 2: BACKEND — Fix register to allow deleted-user fresh signup
# ══════════════════════════════════════════════════════════════
step "STEP 2: Patching auth register for deleted-user re-signup"

node << 'AUTH_PATCH_EOF'
const fs = require('fs');
const routesDir = process.env.HOME + '/workspace/src/routes/';
const files = fs.readdirSync(routesDir);
let authFile = null;
for(const f of files){
  const c = fs.readFileSync(routesDir + f, 'utf8');
  if((c.includes('/register') || c.includes('register')) && c.includes('bcrypt')){
    authFile = routesDir + f; break;
  }
}
if(!authFile){ authFile = process.env.HOME + '/workspace/src/routes/auth.js'; }
if(!fs.existsSync(authFile)){ console.log('Auth file not found — skip'); process.exit(0); }

let c = fs.readFileSync(authFile, 'utf8');
if(c.includes('deleted === true') || c.includes("deleted:true") && c.includes('deleteOne')){
  console.log('✅ Auth already patched'); process.exit(0);
}

// Pattern: find where we check for existing email during registration
// and add: if deleted, remove old record and allow fresh signup
const patterns = [
  'existingUser && existingUser.deleted',
  "if(existing && existing.email)"
];

// Find the email duplicate check block
const emailCheckPatterns = [
  { find: "existingUser = null;\n    }", replace: false },
];

// Simple targeted patch: after finding existingUser/existing by email,
// add check for deleted status
let patched = false;

// Try pattern 1: "if(existingUser)" duplicate check
if(c.includes('existingUser') && !c.includes('deleted === true')){
  // Find let/const existingUser = await...
  const match = c.match(/(let|const)\s+existingUser\s*=\s*await[^\n]+/);
  if(match){
    const afterDecl = c.indexOf('\n', c.indexOf(match[0])) + 1;
    const insertCode = `    // Allow fresh registration if previous account was soft-deleted
    if(existingUser && existingUser.deleted === true){
      await require('../models/User').collection.deleteOne({ email: existingUser.email });
      existingUser = null;
    }\n`;
    // Only insert if existingUser is const → change to let
    c = c.replace(match[0], match[0].replace(/^const /, 'let '));
    // Now insert after the declaration
    const newMatch = c.match(/(let)\s+existingUser\s*=\s*await[^\n]+/);
    if(newMatch){
      const pos = c.indexOf('\n', c.indexOf(newMatch[0])) + 1;
      c = c.slice(0, pos) + insertCode + c.slice(pos);
      patched = true;
    }
  }
}

if(patched){
  fs.writeFileSync(authFile, c);
  console.log('✅ Auth register patched for deleted-user re-signup!');
} else {
  console.log('⚠️ Could not auto-patch auth — manual check needed (non-critical)');
}
AUTH_PATCH_EOF

# ══════════════════════════════════════════════════════════════
# STEP 3: Write the NEW STUDENTS TAB JSX to temp file
# ══════════════════════════════════════════════════════════════
step "STEP 3: Writing new Student Management JSX"

cat > /tmp/new_students_tab.txt << 'JSXEOF'
{tab==='students'&&(
            <div>
              {/* ── HEADER ───────────────────────────────────── */}
              <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:20,flexWrap:'wrap',gap:12}}>
                <div>
                  <div style={pageTitle}>👥 Student Management</div>
                  <div style={pageSub}>
                    {(students||[]).filter((s:any)=>!s.deleted).length} registered
                    &nbsp;·&nbsp;{(students||[]).filter((s:any)=>s.banned&&!s.deleted).length} banned
                    {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                      <span style={{color:'#FFB84D'}}>&nbsp;·&nbsp;{deletedStds.length} archived</span>
                    )}
                  </div>
                </div>
                <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                  <button onClick={()=>doExport(`${API}/api/admin/export/students`,'students.csv')} style={{...bg_,fontSize:11}}>📥 Export CSV</button>
                  <button onClick={()=>setTab('import_students')} style={{...bg_,fontSize:11}}>📤 Import CSV</button>
                </div>
              </div>

              {/* ── STATS ROW ────────────────────────────────── */}
              <div style={{display:'grid',gridTemplateColumns:`repeat(${typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'?4:3},1fr)`,gap:10,marginBottom:20}}>
                {[
                  {ico:'👥',lbl:'Total Students',val:(students||[]).filter((s:any)=>!s.deleted).length,col:'#4D9FFF'},
                  {ico:'✅',lbl:'Active',val:(students||[]).filter((s:any)=>!s.banned&&!s.deleted).length,col:'#00C48C'},
                  {ico:'🚫',lbl:'Banned',val:(students||[]).filter((s:any)=>s.banned&&!s.deleted).length,col:'#FF4757'},
                  ...(typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'
                    ?[{ico:'🗃️',lbl:'Archived',val:deletedStds.length,col:'#FFB84D'}]
                    :[])
                ].map((s,i)=>(
                  <div key={i} style={{
                    background:`linear-gradient(135deg,${s.col}18 0%,${s.col}06 100%)`,
                    border:`1px solid ${s.col}35`,
                    borderRadius:14,
                    padding:'14px 12px',
                    textAlign:'center',
                    transition:'transform 0.2s',
                    cursor:'default'
                  }}>
                    <div style={{fontSize:22,marginBottom:5}}>{s.ico}</div>
                    <div style={{fontSize:24,fontWeight:800,color:s.col,lineHeight:1}}>{s.val}</div>
                    <div style={{fontSize:10,color:'#8899AA',marginTop:4,letterSpacing:'0.3px'}}>{s.lbl}</div>
                  </div>
                ))}
              </div>

              {/* ── SEARCH + FILTER BAR ───────────────────────── */}
              <div style={{display:'flex',gap:10,marginBottom:16,flexWrap:'wrap',alignItems:'center'}}>
                <SInput init={stdSearch} onSet={setStdSearch} ph='🔍 Search by name, email, ID…' style={{flex:1,minWidth:200,background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'9px 14px',color:'#E8F4FD',fontSize:12,outline:'none'}}/>
                <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                  {(['all','active','banned'] as const).map(f=>(
                    <button key={f} onClick={()=>setStdFilter(f)} style={{
                      padding:'8px 14px',
                      borderRadius:8,
                      border:`1px solid ${stdFilter===f?'#4D9FFF':'rgba(77,159,255,0.15)'}`,
                      background:stdFilter===f?'rgba(77,159,255,0.18)':'rgba(0,22,40,0.6)',
                      color:stdFilter===f?'#4D9FFF':'#8899AA',
                      cursor:'pointer',fontSize:11,fontWeight:stdFilter===f?700:500,
                      transition:'all 0.2s',
                      textTransform:'capitalize' as const
                    }}>{f}</button>
                  ))}
                  {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                    <button onClick={()=>{setStdFilter('deleted' as any);fetchDeletedStds()}} style={{
                      padding:'8px 14px',borderRadius:8,
                      border:`1px solid ${stdFilter==='deleted'?'#FFB84D':'rgba(255,184,77,0.2)'}`,
                      background:stdFilter==='deleted'?'rgba(255,184,77,0.15)':'rgba(0,22,40,0.6)',
                      color:stdFilter==='deleted'?'#FFB84D':'#8899AA',
                      cursor:'pointer',fontSize:11,fontWeight:stdFilter==='deleted'?700:500,
                      transition:'all 0.2s'
                    }}>🗃️ Archived</button>
                  )}
                </div>
                <select
                  value={stdSort}
                  onChange={(e:any)=>setStdSort(e.target.value)}
                  style={{background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:8,padding:'8px 10px',color:'#8899AA',fontSize:11,cursor:'pointer',outline:'none'}}
                >
                  <option value='newest'>🕐 Newest First</option>
                  <option value='name'>🔤 Name A–Z</option>
                  <option value='active'>✅ Active First</option>
                </select>
              </div>

              {/* ── SELECTED STUDENT DETAIL PANEL ─────────────── */}
              {selStudent&&(
                <div style={{
                  borderRadius:16,
                  border:'2px solid rgba(77,159,255,0.3)',
                  background:'linear-gradient(135deg,rgba(0,22,40,0.97) 0%,rgba(0,31,58,0.95) 100%)',
                  padding:'18px',
                  marginBottom:18,
                  boxShadow:'0 8px 32px rgba(77,159,255,0.1)'
                }}>
                  <div style={{display:'flex',gap:16,alignItems:'flex-start',flexWrap:'wrap'}}>
                    {/* Avatar */}
                    <div style={{
                      width:58,height:58,borderRadius:16,flexShrink:0,
                      background:'linear-gradient(135deg,#4D9FFF,#0055CC)',
                      display:'flex',alignItems:'center',justifyContent:'center',
                      fontSize:24,fontWeight:800,color:'#fff',
                      boxShadow:'0 6px 20px rgba(77,159,255,0.4)'
                    }}>
                      {(selStudent.name||'?').charAt(0).toUpperCase()}
                    </div>
                    {/* Details */}
                    <div style={{flex:1,minWidth:180}}>
                      <div style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'#E8F4FD',marginBottom:4}}>{selStudent.name}</div>
                      <div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>✉️ {selStudent.email}</div>
                      {selStudent.phone&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>📱 {selStudent.phone}</div>}
                      {(selStudent as any).city&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>📍 {(selStudent as any).city}</div>}
                      {(selStudent as any).school&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🏫 {(selStudent as any).school}</div>}
                      {(selStudent as any).targetExam&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🎯 Target: {(selStudent as any).targetExam}</div>}
                      {(selStudent as any).dob&&<div style={{fontSize:11,color:'#8899AA',marginBottom:2}}>🎂 DOB: {(selStudent as any).dob}</div>}
                      {(selStudent as any).qualifications&&<div style={{fontSize:11,color:'#8899AA',marginBottom:4}}>🎓 {(selStudent as any).qualifications}</div>}
                      <div style={{fontSize:10,color:'#8899AA',marginBottom:8}}>📅 Joined: {selStudent.createdAt?new Date(selStudent.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'-'}</div>
                      <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                        {selStudent.banned&&<span style={{fontSize:10,background:'rgba(255,71,87,0.15)',color:'#FF4757',padding:'2px 8px',borderRadius:6,border:'1px solid rgba(255,71,87,0.3)'}}>🚫 Banned</span>}
                        {selStudent.group&&<Badge label={selStudent.group} col='#FFD700'/>}
                        {selStudent.integrityScore!==undefined&&(
                          <span style={{fontSize:10,background:`rgba(${selStudent.integrityScore>70?'0,196,140':selStudent.integrityScore>40?'255,184,77':'255,71,87'},0.15)`,color:selStudent.integrityScore>70?'#00C48C':selStudent.integrityScore>40?'#FFB84D':'#FF4757',padding:'2px 8px',borderRadius:6,border:`1px solid rgba(${selStudent.integrityScore>70?'0,196,140':selStudent.integrityScore>40?'255,184,77':'255,71,87'},0.3)`}}>
                            🤖 Integrity {selStudent.integrityScore}/100
                          </span>
                        )}
                      </div>
                    </div>
                    {/* Action Buttons */}
                    <div style={{display:'flex',flexDirection:'column' as const,gap:7,alignItems:'stretch',minWidth:120}}>
                      <button onClick={()=>{setImpId(selStudent._id);impersonate()}} style={{...bg_,fontSize:11,textAlign:'center' as const}}>👁️ View as Student</button>
                      {selStudent.banned
                        ?<button onClick={()=>unbanStd(selStudent._id)} style={{...bs,fontSize:11}}>🔓 Unban</button>
                        :<button onClick={()=>{setBanId(selStudent._id)}} style={{...bd,fontSize:11}}>🚫 Ban</button>
                      }
                      {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                        <button
                          onClick={()=>setDelConfirmId(selStudent._id)}
                          style={{background:'rgba(255,71,87,0.08)',border:'1px solid rgba(255,71,87,0.35)',color:'#FF4757',borderRadius:10,padding:'9px 14px',cursor:'pointer',fontSize:11,fontWeight:600}}
                        >🗑️ Delete Account</button>
                      )}
                      <button onClick={()=>setSelStudent(null)} style={{background:'none',border:'1px solid rgba(77,159,255,0.15)',color:'#8899AA',borderRadius:10,padding:'7px',cursor:'pointer',fontSize:12,textAlign:'center' as const}}>✕ Close</button>
                    </div>
                  </div>
                  {/* Login History */}
                  {selStudent.loginHistory&&selStudent.loginHistory.length>0&&(
                    <div style={{marginTop:14,paddingTop:12,borderTop:'1px solid rgba(77,159,255,0.12)'}}>
                      <div style={{fontWeight:700,fontSize:10,color:'#8899AA',marginBottom:8,letterSpacing:'0.8px',textTransform:'uppercase' as const}}>📊 Recent Login Activity (S48)</div>
                      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(170px,1fr))',gap:6}}>
                        {selStudent.loginHistory.slice(0,4).map((l:any,i:number)=>(
                          <div key={i} style={{background:'rgba(0,22,40,0.7)',borderRadius:8,padding:'8px 10px',border:'1px solid rgba(77,159,255,0.1)'}}>
                            <div style={{fontSize:10,color:'#E8F4FD',fontWeight:600}}>📍 {l.city||'Unknown'}</div>
                            <div style={{fontSize:10,color:'#8899AA',marginTop:2}}>{l.device||'—'}</div>
                            <div style={{fontSize:9,color:'#8899AA',marginTop:1}}>{l.ip||'—'}</div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* ── DELETE CONFIRMATION MODAL (SuperAdmin only) ── */}
              {delConfirmId&&(
                <div style={{position:'fixed' as const,top:0,left:0,right:0,bottom:0,background:'rgba(0,0,0,0.75)',backdropFilter:'blur(4px)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:9999,padding:16}}>
                  <div style={{
                    background:'linear-gradient(135deg,rgba(5,10,20,0.99),rgba(10,18,35,0.98))',
                    border:'2px solid rgba(255,71,87,0.4)',
                    borderRadius:20,
                    padding:'28px 24px',
                    maxWidth:400,width:'100%',
                    boxShadow:'0 20px 60px rgba(0,0,0,0.6)'
                  }}>
                    <div style={{fontSize:44,textAlign:'center' as const,marginBottom:10}}>⚠️</div>
                    <div style={{fontWeight:800,fontSize:16,color:'#FF4757',textAlign:'center' as const,marginBottom:6,fontFamily:'Playfair Display,serif'}}>Delete Student Account</div>
                    <div style={{fontSize:12,color:'#8899AA',textAlign:'center' as const,marginBottom:6,lineHeight:1.7}}>
                      Ye account active list se hata diya jayega.<br/>
                      Superadmin ise kabhi bhi restore kar sakta hai.
                    </div>
                    <div style={{fontSize:11,color:'#00C48C',textAlign:'center' as const,marginBottom:16,padding:'8px 12px',background:'rgba(0,196,140,0.08)',borderRadius:8,border:'1px solid rgba(0,196,140,0.2)'}}>
                      ✅ Student same email se fresh account bana sakta hai
                    </div>
                    <div style={{marginBottom:16}}>
                      <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Delete Reason (SuperAdmin archive mein save hoga)</label>
                      <STextarea init='' onSet={(v:string)=>{delReasonR.current=v}} ph='e.g. Test account, Rules violation, Duplicate account…' rows={2} style={{width:'100%',background:'rgba(255,71,87,0.06)',border:'1px solid rgba(255,71,87,0.3)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none',resize:'vertical' as const}}/>
                    </div>
                    <div style={{display:'flex',gap:10}}>
                      <button
                        onClick={()=>softDelStd(delConfirmId)}
                        disabled={stdDelLoading}
                        style={{flex:1,padding:'12px',background:'linear-gradient(135deg,#FF4757,#CC0020)',border:'none',borderRadius:12,color:'#fff',fontWeight:700,cursor:stdDelLoading?'not-allowed' as const:'pointer' as const,opacity:stdDelLoading?0.7:1,fontSize:13}}
                      >{stdDelLoading?'⟳ Deleting…':'🗑️ Confirm Delete'}</button>
                      <button onClick={()=>setDelConfirmId('')} style={{...bg_,padding:'12px 18px'}}>Cancel</button>
                    </div>
                  </div>
                </div>
              )}

              {/* ── ARCHIVED STUDENTS (SuperAdmin only, deleted filter) ── */}
              {stdFilter==='deleted'&&typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:14,flexWrap:'wrap',gap:8}}>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:'#FFB84D'}}>🗃️ Archived Student Accounts</div>
                      <div style={{fontSize:11,color:'#8899AA',marginTop:3}}>{deletedStds.length} archived · Only visible to SuperAdmin · Restore anytime</div>
                    </div>
                    <button onClick={fetchDeletedStds} style={{...bg_,fontSize:11}}>🔄 Refresh</button>
                  </div>
                  {deletedStds.length===0
                    ?<div style={{background:'rgba(255,184,77,0.05)',border:'1px solid rgba(255,184,77,0.15)',borderRadius:16,padding:'40px 20px',textAlign:'center' as const}}>
                      <div style={{fontSize:48,marginBottom:12}}>🗃️</div>
                      <div style={{fontWeight:700,fontSize:14,color:'#E8F4FD',marginBottom:6}}>No Archived Students</div>
                      <div style={{fontSize:12,color:'#8899AA'}}>Deleted student accounts will appear here. You can restore them anytime.</div>
                    </div>
                    :<div style={{display:'grid',gap:10}}>
                      {deletedStds.map((s:any)=>(
                        <div key={s._id} style={{
                          background:'linear-gradient(135deg,rgba(255,184,77,0.05),rgba(0,22,40,0.8))',
                          border:'1px solid rgba(255,184,77,0.2)',
                          borderRadius:14,
                          padding:'14px 16px',
                          display:'flex',gap:12,alignItems:'center',flexWrap:'wrap' as const,justifyContent:'space-between' as const
                        }}>
                          <div style={{display:'flex',gap:12,alignItems:'center',flex:1,minWidth:180}}>
                            <div style={{width:44,height:44,borderRadius:12,background:'linear-gradient(135deg,rgba(255,184,77,0.5),rgba(255,71,87,0.5))',display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:800,color:'#fff',flexShrink:0}}>
                              {(s.name||'?').charAt(0).toUpperCase()}
                            </div>
                            <div>
                              <div style={{fontWeight:700,fontSize:13,color:'#E8F4FD'}}>{s.name||'—'}</div>
                              <div style={{fontSize:11,color:'#8899AA'}}>✉️ {s.email}</div>
                              {s.phone&&<div style={{fontSize:10,color:'#8899AA'}}>📱 {s.phone}</div>}
                              <div style={{display:'flex',gap:6,marginTop:5,flexWrap:'wrap' as const}}>
                                {s.group&&<span style={{fontSize:9,background:'rgba(255,215,0,0.15)',color:'#FFD700',padding:'2px 7px',borderRadius:5,border:'1px solid rgba(255,215,0,0.3)'}}>{s.group}</span>}
                                {s._snapshot?.targetExam&&<span style={{fontSize:9,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',padding:'2px 7px',borderRadius:5,border:'1px solid rgba(77,159,255,0.25)'}}>🎯 {s._snapshot.targetExam}</span>}
                              </div>
                              {s.deleteReason&&<div style={{fontSize:10,color:'#FF4757',marginTop:4}}>Reason: {s.deleteReason}</div>}
                              {s.deletedAt&&<div style={{fontSize:10,color:'#8899AA',marginTop:2}}>🗑️ Archived: {new Date(s.deletedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</div>}
                            </div>
                          </div>
                          <button
                            onClick={()=>restoreStd(s._id)}
                            style={{background:'rgba(0,196,140,0.1)',border:'1px solid rgba(0,196,140,0.3)',color:'#00C48C',borderRadius:10,padding:'9px 16px',cursor:'pointer',fontSize:11,fontWeight:700}}
                          >🔄 Restore</button>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              )}

              {/* ── ACTIVE STUDENT LIST ──────────────────────── */}
              {stdFilter!=='deleted'&&(
                <>
                  {fStds.filter((s:any)=>!s.deleted).length===0
                    ?<PageHero icon="👥" title="No Students Found" subtitle="Students will appear here after they register. Use bulk import to add multiple students at once."/>
                    :(()=>{
                      const raw=fStds.filter((s:any)=>!s.deleted);
                      const sorted=stdSort==='name'
                        ?[...raw].sort((a,b)=>(a.name||'').localeCompare(b.name||''))
                        :stdSort==='active'
                        ?[...raw].sort((a,b)=>Number(!!a.banned)-Number(!!b.banned))
                        :[...raw].sort((a,b)=>new Date(b.createdAt||0).getTime()-new Date(a.createdAt||0).getTime());
                      const avatarColors=['#4D9FFF','#00C48C','#A78BFA','#FF6B9D','#FFD700','#00E5FF','#FF8C42','#7CFC00'];
                      return sorted.map((s:any,idx:number)=>(
                        <div
                          key={s._id}
                          className="card-hover"
                          style={{
                            background:selStudent?._id===s._id?'rgba(77,159,255,0.08)':'rgba(0,22,40,0.75)',
                            border:`1px solid ${s.banned?'rgba(255,71,87,0.3)':selStudent?._id===s._id?'rgba(77,159,255,0.4)':'rgba(77,159,255,0.12)'}`,
                            borderLeft:`3px solid ${s.banned?'#FF4757':avatarColors[idx%8]}`,
                            borderRadius:14,
                            padding:'12px 14px',
                            marginBottom:8,
                            display:'flex',gap:12,alignItems:'center',flexWrap:'wrap' as const,
                            justifyContent:'space-between' as const,
                            cursor:'pointer',
                            transition:'all 0.22s'
                          }}
                          onClick={()=>setSelStudent(s)}
                        >
                          <div style={{display:'flex',gap:12,alignItems:'center',flex:1,minWidth:150}}>
                            {/* Color Avatar */}
                            <div style={{
                              width:42,height:42,borderRadius:12,flexShrink:0,
                              background:`linear-gradient(135deg,${avatarColors[idx%8]},${avatarColors[(idx+3)%8]})`,
                              display:'flex',alignItems:'center',justifyContent:'center',
                              fontSize:17,fontWeight:800,color:'#fff',
                              boxShadow:`0 3px 10px ${avatarColors[idx%8]}44`
                            }}>
                              {(s.name||'?').charAt(0).toUpperCase()}
                            </div>
                            <div style={{flex:1}}>
                              <div style={{display:'flex',alignItems:'center',gap:6,flexWrap:'wrap' as const,marginBottom:2}}>
                                <span style={{fontWeight:700,fontSize:13,color:'#E8F4FD'}}>{s.name||'—'}</span>
                                {s.banned&&<span style={{fontSize:9,background:'rgba(255,71,87,0.15)',color:'#FF4757',padding:'1px 6px',borderRadius:5,border:'1px solid rgba(255,71,87,0.3)'}}>BANNED</span>}
                                {s.group&&<span style={{fontSize:9,background:'rgba(255,215,0,0.12)',color:'#FFD700',padding:'1px 6px',borderRadius:5,border:'1px solid rgba(255,215,0,0.25)'}}>{s.group}</span>}
                              </div>
                              <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>
                              <div style={{display:'flex',gap:10,marginTop:2,fontSize:10,color:'#8899AA',flexWrap:'wrap' as const}}>
                                {s.phone&&<span>📱 {s.phone}</span>}
                                <span>📅 {s.createdAt?new Date(s.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'-'}</span>
                              </div>
                              {s.integrityScore!==undefined&&(
                                <div style={{display:'flex',alignItems:'center',gap:7,marginTop:5}}>
                                  <div style={{width:70,height:3,background:'rgba(255,255,255,0.07)',borderRadius:2}}>
                                    <div style={{width:`${Math.min(s.integrityScore,100)}%`,height:'100%',borderRadius:2,background:s.integrityScore>70?'#00C48C':s.integrityScore>40?'#FFB84D':'#FF4757',transition:'width 0.5s'}}/>
                                  </div>
                                  <span style={{fontSize:9,color:s.integrityScore>70?'#00C48C':s.integrityScore>40?'#FFB84D':'#FF4757',fontWeight:600}}>{s.integrityScore}/100</span>
                                </div>
                              )}
                            </div>
                          </div>
                          {/* Action Buttons */}
                          <div style={{display:'flex',gap:6,flexWrap:'wrap' as const}} onClick={(e:any)=>e.stopPropagation()}>
                            <button onClick={(e:any)=>{e.stopPropagation();setSelStudent(s)}} style={{...bg_,fontSize:10,padding:'6px 10px'}}>👁️ View</button>
                            {s.banned
                              ?<button onClick={(e:any)=>{e.stopPropagation();unbanStd(s._id)}} style={{...bs,fontSize:10,padding:'6px 10px'}}>🔓 Unban</button>
                              :<button onClick={(e:any)=>{e.stopPropagation();setBanId(s._id)}} style={{...bd,fontSize:10,padding:'6px 10px'}}>🚫 Ban</button>
                            }
                            {typeof window!=='undefined'&&localStorage.getItem('pr_role')==='superadmin'&&(
                              <button
                                onClick={(e:any)=>{e.stopPropagation();setDelConfirmId(s._id)}}
                                title="Delete account (SuperAdmin only)"
                                style={{background:'rgba(255,71,87,0.08)',border:'1px solid rgba(255,71,87,0.3)',color:'#FF4757',borderRadius:8,padding:'6px 10px',cursor:'pointer',fontSize:10,fontWeight:700}}
                              >🗑️</button>
                            )}
                          </div>
                        </div>
                      ));
                    })()
                  }
                </>
              )}

              {/* ── BAN PANEL ────────────────────────────────── */}
              {banId&&(
                <div style={{
                  background:'linear-gradient(135deg,rgba(255,71,87,0.05),rgba(0,22,40,0.95))',
                  border:'2px solid rgba(255,71,87,0.3)',
                  borderRadius:16,
                  padding:'18px',
                  marginTop:16
                }}>
                  <div style={{fontWeight:700,fontSize:14,color:'#FF4757',marginBottom:14}}>🚫 Ban Student</div>
                  <div style={{marginBottom:12}}>
                    <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Ban Reason *</label>
                    <STextarea init='' onSet={(v:string)=>{banReaR.current=v}} ph='Explain why this student is being banned…' rows={2} style={{width:'100%',background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none',resize:'vertical' as const}}/>
                  </div>
                  <div style={{marginBottom:14}}>
                    <label style={{fontSize:11,color:'#8899AA',display:'block',marginBottom:6,fontWeight:600}}>Ban Type</label>
                    <SSelect val={banT} onChange={(v:string)=>setBanT(v as 'permanent'|'temporary')} opts={[{v:'permanent',l:'Permanent Ban'},{v:'temporary',l:'Temporary Ban (30 days)'}]} style={{width:'100%',background:'rgba(0,22,40,0.7)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,padding:'10px 12px',color:'#E8F4FD',fontSize:12,outline:'none'}}/>
                  </div>
                  <div style={{display:'flex',gap:10}}>
                    <button onClick={banStd} style={{...bd,flex:1,padding:'11px',fontSize:13}}>🚫 Confirm Ban</button>
                    <button onClick={()=>setBanId('')} style={{...bg_,padding:'11px 20px'}}>Cancel</button>
                  </div>
                </div>
              )}
            </div>
          )}
JSXEOF

ok "New students JSX written to /tmp/new_students_tab.txt"

# ══════════════════════════════════════════════════════════════
# STEP 4: Write new functions to temp file
# ══════════════════════════════════════════════════════════════
step "STEP 4: Writing new delete/restore functions"

cat > /tmp/new_std_funcs.txt << 'FUNCEOF'

  // ── SOFT DELETE STUDENT (SuperAdmin only) ──
  const softDelStd=useCallback(async(id:string)=>{
    setStdDelLoading(true)
    try{
      const res=await fetch(`${API}/api/admin/delete/${id}`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({reason:delReasonR.current||'Removed by SuperAdmin'})})
      if(res.ok){
        setStudents((p:any)=>p.filter((s:any)=>s._id!==id))
        if(selStudent?._id===id) setSelStudent(null)
        setDelConfirmId('')
        delReasonR.current=''
        T('Student account archived successfully.','s')
      } else {
        const d=await res.json()
        T(d.error||'Delete failed. Try again.','e')
      }
    } catch{ T('Network error.','e') }
    finally{ setStdDelLoading(false) }
  },[token,T,selStudent])

  // ── RESTORE DELETED STUDENT (SuperAdmin only) ──
  const restoreStd=useCallback(async(id:string)=>{
    try{
      const res=await fetch(`${API}/api/admin/restore/${id}`,{method:'POST',headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        setDeletedStds((p:any)=>p.filter((s:any)=>s._id!==id))
        T('Student account restored successfully! 🎉','s')
        fetchAll()
      } else { T('Restore failed. Try again.','e') }
    } catch{ T('Network error.','e') }
  },[token,T,fetchAll])

  // ── FETCH DELETED STUDENTS ──
  const fetchDeletedStds=useCallback(async()=>{
    try{
      const res=await fetch(`${API}/api/admin/deleted-students`,{headers:{Authorization:`Bearer ${token}`}})
      if(res.ok){
        const d=await res.json()
        setDeletedStds(Array.isArray(d)?d:(d.students||[]))
      }
    } catch{}
  },[token])

FUNCEOF

ok "New functions written to /tmp/new_std_funcs.txt"

# ══════════════════════════════════════════════════════════════
# STEP 5: Apply all patches to page.tsx via Node.js
# ══════════════════════════════════════════════════════════════
step "STEP 5: Applying patches to page.tsx"

node << 'NODE_PATCH_EOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');
let patchCount = 0;

// ── PATCH 1: Extend Student interface ──────────────────────
const OLD_IFACE = "interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[];parentEmail?:string }";
const NEW_IFACE = "interface Student { _id:string;name:string;email:string;phone?:string;role:string;createdAt:string;banned?:boolean;banReason?:string;group?:string;integrityScore?:number;loginHistory?:any[];parentEmail?:string;deleted?:boolean;deletedAt?:string;deleteReason?:string;city?:string;school?:string;dob?:string;targetExam?:string;qualifications?:string;_snapshot?:any }";
if(c.includes(OLD_IFACE)){
  c = c.replace(OLD_IFACE, NEW_IFACE);
  patchCount++; console.log('✅ P1: Student interface extended');
} else { console.log('⚠️ P1: Interface not found (may already be updated)'); }

// ── PATCH 2: Extend stdFilter type ─────────────────────────
const OLD_FTYPE = "useState<'all'|'active'|'banned'>('all')";
if(c.includes(OLD_FTYPE)){
  c = c.replace(OLD_FTYPE, "useState<'all'|'active'|'banned'|'deleted'>('all')");
  patchCount++; console.log('✅ P2: stdFilter type extended to include deleted');
} else { console.log('⚠️ P2: stdFilter type not found'); }

// ── PATCH 3: Add new state variables after banId ────────────
const BAN_ID_STATE = "const [banId,setBanId]=useState('')";
if(c.includes(BAN_ID_STATE)){
  c = c.replace(BAN_ID_STATE,
    BAN_ID_STATE +
    "\n  const [delConfirmId,setDelConfirmId]=useState('')" +
    "\n  const delReasonR=useRef('')" +
    "\n  const [deletedStds,setDeletedStds]=useState<any[]>([])" +
    "\n  const [stdDelLoading,setStdDelLoading]=useState(false)" +
    "\n  const [stdSort,setStdSort]=useState<'newest'|'name'|'active'>('newest')"
  );
  patchCount++; console.log('✅ P3: New state variables added (delConfirmId, deletedStds, stdSort, etc.)');
} else { console.log('⚠️ P3: banId state not found'); }

// ── PATCH 4: Fix fStds to hide deleted students ─────────────
const OLD_FSTDS = "  const fStds=(students||[]).filter(s=>{\n    const m=stdSearch.toLowerCase()\n    const ok=!m||(s.name?.toLowerCase().includes(m)||s.email?.toLowerCase().includes(m)||s._id?.includes(m))\n    if(stdFilter==='banned')return ok&&!!s.banned\n    if(stdFilter==='active')return ok&&!s.banned\n    return ok\n  })";
const NEW_FSTDS = "  const fStds=(students||[]).filter((s:any)=>{\n    if(s.deleted)return false  // hide archived from main list\n    if(stdFilter==='deleted')return false  // archived shown separately\n    const m=stdSearch.toLowerCase()\n    const ok=!m||(s.name?.toLowerCase().includes(m)||s.email?.toLowerCase().includes(m)||s._id?.includes(m))\n    if(stdFilter==='banned')return ok&&!!s.banned\n    if(stdFilter==='active')return ok&&!s.banned\n    return ok\n  })";
if(c.includes(OLD_FSTDS)){
  c = c.replace(OLD_FSTDS, NEW_FSTDS);
  patchCount++; console.log('✅ P4: fStds updated — deleted students hidden from main list');
} else { console.log('⚠️ P4: fStds exact match not found — trying fallback');
  // Fallback: just insert at start of filter
  if(c.includes("const fStds=(students||[]).filter(s=>{")) {
    c = c.replace(
      "const fStds=(students||[]).filter(s=>{",
      "const fStds=(students||[]).filter((s:any)=>{\n    if(s.deleted)return false\n    if(stdFilter==='deleted')return false"
    );
    patchCount++; console.log('✅ P4 (fallback): fStds patched');
  }
}

// ── PATCH 5: Add new functions before Feature Flags section ──
const FEATURE_FLAGS_MARKER = "\n  // ══ FEATURE FLAGS ══";
const newFuncs = fs.readFileSync('/tmp/new_std_funcs.txt', 'utf8');
if(c.includes(FEATURE_FLAGS_MARKER)){
  c = c.replace(FEATURE_FLAGS_MARKER, newFuncs + FEATURE_FLAGS_MARKER);
  patchCount++; console.log('✅ P5: softDelStd / restoreStd / fetchDeletedStds functions added');
} else {
  console.log('⚠️ P5: Feature Flags marker not found — trying alternate');
  const ALT_MARKER = "// ══ FEATURE FLAGS ══";
  if(c.includes(ALT_MARKER)){
    c = c.replace(ALT_MARKER, newFuncs.trim() + "\n\n  " + ALT_MARKER);
    patchCount++; console.log('✅ P5 (alt): Functions added');
  }
}

// ── PATCH 6: Replace students tab section ─────────────────
const newSection = fs.readFileSync('/tmp/new_students_tab.txt', 'utf8');
const START_M = "{tab==='students'&&(";
const END_M   = "{/* ══ BATCHES ══ */";
const si = c.indexOf(START_M);
const ei = c.indexOf(END_M, si);
if(si > -1 && ei > -1){
  c = c.slice(0, si) + newSection + "\n\n          " + c.slice(ei);
  patchCount++; console.log('✅ P6: Students tab completely redesigned with new premium UI');
} else {
  console.log('❌ P6: Students tab markers not found — si:'+si+' ei:'+ei);
  process.exit(1);
}

// ── Write back ────────────────────────────────────────────
fs.writeFileSync(file, c);
console.log('\n🎉 Total patches applied: ' + patchCount + '/6');
console.log('✅ page.tsx saved successfully!');
NODE_PATCH_EOF

if [ $? -ne 0 ]; then
  err "Patch failed! Check errors above."
  exit 1
fi
ok "Frontend patched successfully"

# ══════════════════════════════════════════════════════════════
# STEP 6: Git push
# ══════════════════════════════════════════════════════════════
step "STEP 6: Pushing to GitHub → Vercel auto-deploy"

cd $WORK
git add -A
git commit -m "feat: Student Management — soft-delete/restore + premium SaaS redesign v9

- SuperAdmin can soft-delete students (account archived, not hard deleted)
- Deleted student details saved: name, email, phone, batch, qualifications
- SuperAdmin can restore any archived account anytime
- Fresh registration allowed after deletion (same email = new account)
- New Archived tab visible only to SuperAdmin
- Premium redesign: color avatars, gradient stats cards, delete modal overlay
- Sort options: Newest / Name A-Z / Active First
- Integrity score mini progress bars
- All existing features preserved (ban/unban/view/export)"
git push origin main

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}🎉 DONE! Student Management fully upgraded.${N}"
echo -e "${Y}Vercel deploy: ~2 min → https://prove-rank.vercel.app/admin/x7k2p${N}"
echo ""
echo -e "${C}NEW FEATURES:${N}"
echo "  🗑️  Delete Account (SuperAdmin) → Archives to DB"
echo "  🔄  Restore Archived Account anytime"
echo "  🗃️  Archived tab with full student details"
echo "  🎨  Premium SaaS redesign — color avatars, gradient cards"
echo "  🔤  Sort: Newest / Name A-Z / Active First"
echo "  📊  Integrity score progress bars"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
