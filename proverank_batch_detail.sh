#!/bin/bash
# ProveRank — Batch Detail Page + Backend Routes + Clickable Cards
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }
err(){ echo -e "\033[0;31m[ERR]\033[0m $1"; }

WS=~/workspace

# ══════════════════════════════════════════════════════
# STEP 1 — BACKEND: Add batch detail routes
# ══════════════════════════════════════════════════════
step "STEP 1: Backend Routes"
node << 'BEPATCH'
const fs = require('fs'), path = require('path');
const WS = process.env.HOME + '/workspace';
const routeDirs = [WS+'/src/routes', WS+'/routes'];
let target = null;
for (const dir of routeDirs) {
  if (!fs.existsSync(dir)) continue;
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.js')) continue;
    const fp = path.join(dir, f);
    const c = fs.readFileSync(fp, 'utf8');
    if (c.includes('BATCH_CRUD_FIX')) { target = fp; break; }
  }
  if (target) break;
}
if (!target) { console.log('ERROR: Batch route file not found. Check STEP 1 in previous script ran.'); process.exit(1); }
console.log('Target:', target);
let c = fs.readFileSync(target, 'utf8');
if (c.includes('BATCH_DETAIL_FIX')) { console.log('Already patched'); process.exit(0); }
const mp = c.includes("require('../models/") ? '../models/' : '../../models/';
const patch = `
// BATCH_DETAIL_FIX — ProveRank S5/M3 Extended
router.get('/batches/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Batch = require('${mp}Batch'), User = require('${mp}User');
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ success: false, message: 'Batch not found' });
    const studentCount = await User.countDocuments({ batch: req.params.id, role: 'student' });
    res.json({ ...batch, studentCount });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.get('/batches/:id/students', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('${mp}User');
    const students = await User.find({ batch: req.params.id, role: 'student' })
      .select('-password -__v').sort({ name: 1 }).lean();
    res.json(students);
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.post('/batches/:id/students/add', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('${mp}User');
    const { studentId, studentEmail } = req.body;
    let filter = {};
    if (studentId && studentId.trim()) filter = { _id: studentId.trim() };
    else if (studentEmail && studentEmail.trim()) filter = { email: studentEmail.toLowerCase().trim() };
    else return res.status(400).json({ success: false, message: 'studentId or studentEmail required' });
    const student = await User.findOneAndUpdate(
      { ...filter, role: 'student' },
      { $set: { batch: req.params.id } },
      { new: true }
    ).select('-password');
    if (!student) return res.status(404).json({ success: false, message: 'Student not found or not a student account' });
    res.json({ success: true, student });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.delete('/batches/:id/students/:sid', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const User = require('${mp}User');
    await User.findByIdAndUpdate(req.params.sid, { $unset: { batch: 1 } });
    res.json({ success: true, message: 'Student removed from batch' });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.patch('/batches/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Batch = require('${mp}Batch');
    const { name } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Name required' });
    const batch = await Batch.findByIdAndUpdate(req.params.id, { name: name.trim() }, { new: true });
    if (!batch) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, batch });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.get('/batches/:id/exams', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = require('${mp}Exam');
    const exams = await Exam.find({ batch: req.params.id }).sort({ scheduledAt: -1 }).lean();
    res.json(exams);
  } catch(e) { res.json([]); }
});

router.post('/batches/:id/exams/assign', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = require('${mp}Exam');
    const { examId } = req.body;
    await Exam.findByIdAndUpdate(examId, { $set: { batch: req.params.id } });
    res.json({ success: true });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

router.delete('/batches/:id/exams/:eid', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const Exam = require('${mp}Exam');
    await Exam.findByIdAndUpdate(req.params.eid, { $unset: { batch: 1 } });
    res.json({ success: true });
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});
`;
c = c.replace('// BATCH_CRUD_FIX', patch + '\n// BATCH_CRUD_FIX');
fs.writeFileSync(target, c);
console.log('✅ Backend detail routes added');
BEPATCH

# ══════════════════════════════════════════════════════
# STEP 2 — FRONTEND: Create Batch Detail Page
# ══════════════════════════════════════════════════════
step "STEP 2: Batch Detail Page"
node << 'CREATEFE'
const fs = require('fs');
const HOME = process.env.HOME;
const outDir = `${HOME}/workspace/frontend/app/admin/x7k2p/batch/[batchId]`;
fs.mkdirSync(outDir, { recursive: true });

const L = [];
L.push(`'use client'`);
L.push(`import {useState,useEffect,useCallback,useRef} from 'react'`);
L.push(`import {useRouter,useParams} from 'next/navigation'`);
L.push(`import {getToken,getRole} from '@/lib/auth'`);
L.push(``);
L.push(`const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'`);
L.push(`const BG='radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'`);
L.push(`const CRD='rgba(0,22,40,0.75)'`);
L.push(`const CRD2='rgba(0,31,58,0.85)'`);
L.push(`const ACC='#4D9FFF'`);
L.push(`const BOR='rgba(77,159,255,0.18)'`);
L.push(`const BOR2='rgba(77,159,255,0.3)'`);
L.push(`const TS='#E8F4FF'`);
L.push(`const DIM='#6B8FAF'`);
L.push(`const SUC='#00C48C'`);
L.push(`const DNG='#FF4D4D'`);
L.push(`const WRN='#FFB84D'`);
L.push(`const GOLD='#FFD700'`);
L.push(`const cs:any={background:CRD,border:\`1px solid \${BOR}\`,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}`);
L.push(`const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:\`1.5px solid \${BOR2}\`,borderRadius:10,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box' as any}`);
L.push(`const bp:any={background:\`linear-gradient(135deg,\${ACC},#0055CC)\`,color:'#fff',border:'none',borderRadius:10,padding:'11px 22px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',boxShadow:\`0 4px 16px rgba(77,159,255,0.35)\`}`);
L.push(`const bd:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}`);
L.push(`const bs:any={background:'rgba(0,196,140,0.12)',color:SUC,border:\`1px solid rgba(0,196,140,0.3)\`,borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}`);
L.push(`const bg_:any={background:'rgba(77,159,255,0.1)',color:ACC,border:\`1px solid \${BOR2}\`,borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:600,fontSize:12,fontFamily:'Inter,sans-serif'}`);
L.push(`const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,letterSpacing:0.5,textTransform:'uppercase' as any,fontFamily:'Inter,sans-serif'}`);
L.push(``);

// Particles component
L.push(`function Stars(){`);
L.push(`  const stars=Array.from({length:55},(_,i)=>({`);
L.push(`    w:i%5===0?3:i%3===0?2:1,`);
L.push(`    x:((i*137.508)%100).toFixed(2),`);
L.push(`    y:((i*97.31)%100).toFixed(2),`);
L.push(`    op:(0.08+((i*0.07)%0.45)).toFixed(2),`);
L.push(`    dur:(2+(i%5)).toFixed(1)`);
L.push(`  }))`);
L.push(`  return <div style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none',overflow:'hidden'}}>`);
L.push(`    {stars.map((s,i)=>(`);
L.push(`      <div key={i} style={{position:'absolute',width:s.w,height:s.w,background:'white',borderRadius:'50%',`);
L.push(`        left:\`\${s.x}%\`,top:\`\${s.y}%\`,opacity:Number(s.op),`);
L.push(`        animation:\`bdtwinkle \${s.dur}s ease-in-out infinite\`,animationDelay:\`\${(i*0.11)%3}s\`}}/>`);
L.push(`    ))}`);
L.push(`  </div>`);
L.push(`}`);
L.push(``);

// StatBox component
L.push(`function StatBox({ico,label,val,sub='',col=ACC}:{ico:string,label:string,val:any,sub?:string,col?:string}){`);
L.push(`  return <div style={{background:CRD2,border:\`1px solid \${BOR}\`,borderRadius:14,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden'}}>`);
L.push(`    <div style={{position:'absolute',right:-8,bottom:-8,fontSize:44,opacity:0.06,pointerEvents:'none'}}>{ico}</div>`);
L.push(`    <div style={{fontSize:24,marginBottom:6}}>{ico}</div>`);
L.push(`    <div style={{fontSize:24,fontWeight:800,color:col,fontFamily:'Playfair Display,Georgia,serif',lineHeight:1}}>{val}</div>`);
L.push(`    <div style={{fontSize:11,color:DIM,marginTop:4,fontWeight:600,letterSpacing:0.4}}>{label}</div>`);
L.push(`    {sub&&<div style={{fontSize:10,color:col,marginTop:2,opacity:0.8}}>{sub}</div>}`);
L.push(`  </div>`);
L.push(`}`);
L.push(``);

// ScoreBar for analytics
L.push(`function ScoreBar({label,count,max,col}:{label:string,count:number,max:number,col:string}){`);
L.push(`  const pct=max>0?Math.round((count/max)*100):0`);
L.push(`  return <div style={{marginBottom:12}}>`);
L.push(`    <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>`);
L.push(`      <span style={{fontSize:12,color:TS,fontWeight:600}}>{label}</span>`);
L.push(`      <span style={{fontSize:12,color:DIM}}>{count} students ({pct}%)</span>`);
L.push(`    </div>`);
L.push(`    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>`);
L.push(`      <div style={{width:\`\${pct}%\`,height:'100%',background:\`linear-gradient(90deg,\${col},\${col}88)\`,borderRadius:8,transition:'width 1s ease'}}/>`);
L.push(`    </div>`);
L.push(`  </div>`);
L.push(`}`);
L.push(``);

// Main component start
L.push(`export default function BatchDetailPage(){`);
L.push(`  const router=useRouter()`);
L.push(`  const params=useParams()`);
L.push(`  const batchId=params?.batchId as string`);
L.push(`  const [token,setToken]=useState('')`);
L.push(`  const [tab,setTab]=useState('overview')`);
L.push(`  const [batch,setBatch]=useState<any>(null)`);
L.push(`  const [students,setStudents]=useState<any[]>([])`);
L.push(`  const [exams,setExams]=useState<any[]>([])`);
L.push(`  const [allExams,setAllExams]=useState<any[]>([])`);
L.push(`  const [loading,setLoading]=useState(true)`);
L.push(`  const [searchQ,setSearchQ]=useState('')`);
L.push(`  const [addOpen,setAddOpen]=useState(false)`);
L.push(`  const [addInput,setAddInput]=useState('')`);
L.push(`  const [addMode,setAddMode]=useState<'id'|'email'>('email')`);
L.push(`  const [adding,setAdding]=useState(false)`);
L.push(`  const [renaming,setRenaming]=useState(false)`);
L.push(`  const [newName,setNewName]=useState('')`);
L.push(`  const [saving,setSaving]=useState(false)`);
L.push(`  const [annTitle,setAnnTitle]=useState('')`);
L.push(`  const [annMsg,setAnnMsg]=useState('')`);
L.push(`  const [annSending,setAnnSending]=useState(false)`);
L.push(`  const [assignExamId,setAssignExamId]=useState('')`);
L.push(`  const [toast,setToast]=useState<{msg:string,tp:'s'|'e'|'w'}|null>(null)`);
L.push(`  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToast({msg,tp});setTimeout(()=>setToast(null),4200)},[]) `);
L.push(`  const H=useCallback(()=>({Authorization:\`Bearer \${token}\`}),[token])`);
L.push(`  const HJ=useCallback(()=>({'Content-Type':'application/json',Authorization:\`Bearer \${token}\`}),[token])`);
L.push(``);
L.push(`  useEffect(()=>{`);
L.push(`    const t=getToken(),r=getRole()`);
L.push(`    if(!t||!['admin','superadmin'].includes(r)){router.replace('/login');return}`);
L.push(`    setToken(t)`);
L.push(`  },[router])`);
L.push(``);
L.push(`  const fetchAll=useCallback(async()=>{`);
L.push(`    if(!token||!batchId)return`);
L.push(`    setLoading(true)`);
L.push(`    const get=async(u:string)=>{try{const r=await fetch(u,{headers:H()});return r.ok?r.json():null}catch{return null}}`);
L.push(`    const [b,st,ex,ae]=await Promise.all([`);
L.push(`      get(\`\${API}/api/admin/batches/\${batchId}\`),`);
L.push(`      get(\`\${API}/api/admin/batches/\${batchId}/students\`),`);
L.push(`      get(\`\${API}/api/admin/batches/\${batchId}/exams\`),`);
L.push(`      get(\`\${API}/api/exams\`)`);
L.push(`    ])`);
L.push(`    if(b)setBatch(b)`);
L.push(`    if(Array.isArray(st))setStudents(st)`);
L.push(`    if(Array.isArray(ex))setExams(ex)`);
L.push(`    if(Array.isArray(ae))setAllExams(ae)`);
L.push(`    setLoading(false)`);
L.push(`  },[token,batchId,H])`);
L.push(`  useEffect(()=>{if(token)fetchAll()},[token,fetchAll])`);
L.push(``);
// Functions
L.push(`  const addStudent=async()=>{`);
L.push(`    if(!addInput.trim()){T('Enter Student ID or Email','e');return}`);
L.push(`    setAdding(true)`);
L.push(`    try{`);
L.push(`      const body=addMode==='id'?{studentId:addInput.trim()}:{studentEmail:addInput.trim()}`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}/students/add\`,{method:'POST',headers:HJ(),body:JSON.stringify(body)})`);
L.push(`      const d=await r.json()`);
L.push(`      if(r.ok){T('Student added to batch ✅');setAddInput('');setAddOpen(false);fetchAll()}`);
L.push(`      else T(d.message||'Failed','e')`);
L.push(`    }catch{T('Network error','e')}finally{setAdding(false)}`);
L.push(`  }`);
L.push(``);
L.push(`  const removeStudent=async(sid:string,name:string)=>{`);
L.push(`    if(!window.confirm(\`Remove "\${name}" from this batch?\`))return`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}/students/\${sid}\`,{method:'DELETE',headers:H()})`);
L.push(`      if(r.ok){T('Student removed');setStudents(p=>p.filter(s=>s._id!==sid))}`);
L.push(`      else T('Failed to remove','e')`);
L.push(`    }catch{T('Network error','e')}`);
L.push(`  }`);
L.push(``);
L.push(`  const renameBatch=async()=>{`);
L.push(`    if(!newName.trim()){T('Enter a name','e');return}`);
L.push(`    setSaving(true)`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}\`,{method:'PATCH',headers:HJ(),body:JSON.stringify({name:newName.trim()})})`);
L.push(`      const d=await r.json()`);
L.push(`      if(r.ok){T('Batch renamed ✅');setBatch((p:any)=>({...p,name:newName.trim()}));setRenaming(false)}`);
L.push(`      else T(d.message||'Failed','e')`);
L.push(`    }catch{T('Network error','e')}finally{setSaving(false)}`);
L.push(`  }`);
L.push(``);
L.push(`  const deleteBatch=async()=>{`);
L.push(`    if(!window.confirm(\`DELETE batch "\${batch?.name}"? All students will be unassigned. This cannot be undone.\`))return`);
L.push(`    if(!window.confirm('Are you absolutely sure? Type-confirm by pressing OK again.'))return`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}\`,{method:'DELETE',headers:H()})`);
L.push(`      if(r.ok){T('Batch deleted');router.replace('/admin/x7k2p')}`);
L.push(`      else T('Failed','e')`);
L.push(`    }catch{T('Network error','e')}`);
L.push(`  }`);
L.push(``);
L.push(`  const assignExam=async()=>{`);
L.push(`    if(!assignExamId){T('Select an exam','e');return}`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}/exams/assign\`,{method:'POST',headers:HJ(),body:JSON.stringify({examId:assignExamId})})`);
L.push(`      if(r.ok){T('Exam assigned ✅');setAssignExamId('');fetchAll()}`);
L.push(`      else T('Failed','e')`);
L.push(`    }catch{T('Network error','e')}`);
L.push(`  }`);
L.push(``);
L.push(`  const unassignExam=async(eid:string,title:string)=>{`);
L.push(`    if(!window.confirm(\`Unassign "\${title}" from this batch?\`))return`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/batches/\${batchId}/exams/\${eid}\`,{method:'DELETE',headers:H()})`);
L.push(`      if(r.ok){T('Exam unassigned');setExams(p=>p.filter(e=>e._id!==eid))}`);
L.push(`      else T('Failed','e')`);
L.push(`    }catch{T('Network error','e')}`);
L.push(`  }`);
L.push(``);
L.push(`  const sendAnnouncement=async()=>{`);
L.push(`    if(!annTitle.trim()||!annMsg.trim()){T('Enter title and message','e');return}`);
L.push(`    setAnnSending(true)`);
L.push(`    try{`);
L.push(`      const r=await fetch(\`\${API}/api/admin/announcements\`,{method:'POST',headers:HJ(),`);
L.push(`        body:JSON.stringify({title:annTitle.trim(),message:annMsg.trim(),batch:batchId,targetBatch:batchId})})`);
L.push(`      if(r.ok){T('Announcement sent ✅');setAnnTitle('');setAnnMsg('')}`);
L.push(`      else T('Failed to send','e')`);
L.push(`    }catch{T('Network error','e')}finally{setAnnSending(false)}`);
L.push(`  }`);
L.push(``);
L.push(`  const exportCSV=()=>{`);
L.push(`    if(!students.length){T('No students to export','w');return}`);
L.push(`    const rows=[['Name','Email','Phone','Role','Joined','Batch'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.role||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():'',batch?.name||''])]`);
L.push(`    const csv=rows.map(r=>r.map(v=>\`"\${String(v).replace(/"/g,'""')}"\`).join(',')).join('\\n')`);
L.push(`    const a=document.createElement('a')`);
L.push(`    a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv)`);
L.push(`    a.download=\`batch_\${batch?.name||batchId}_students.csv\``);
L.push(`    a.click()`);
L.push(`    T('CSV exported ✅')`);
L.push(`  }`);
L.push(``);
// Analytics helpers
L.push(`  const filteredStudents=students.filter(s=>`);
L.push(`    !searchQ||s.name?.toLowerCase().includes(searchQ.toLowerCase())||s.email?.toLowerCase().includes(searchQ.toLowerCase())`);
L.push(`  )`);
L.push(`  const recentStudents=students.slice().sort((a,b)=>new Date(b.createdAt||0).getTime()-new Date(a.createdAt||0).getTime()).slice(0,5)`);
L.push(`  const unassignedExams=allExams.filter(ae=>!exams.find(e=>e._id===ae._id))`);
L.push(``);

// TABS config
L.push(`  const TABS=[`);
L.push(`    {id:'overview',ico:'📊',label:'Overview'},`);
L.push(`    {id:'students',ico:'👥',label:\`Students (\${students.length})\`},`);
L.push(`    {id:'exams',ico:'📝',label:\`Exams (\${exams.length})\`},`);
L.push(`    {id:'analytics',ico:'📈',label:'Analytics'},`);
L.push(`    {id:'announce',ico:'📢',label:'Announce'},`);
L.push(`    {id:'settings',ico:'⚙️',label:'Settings'},`);
L.push(`  ]`);
L.push(``);

// Loading state
L.push(`  if(loading)return(`);
L.push(`    <div style={{minHeight:'100vh',background:BG,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:16}}>`);
L.push(`      <Stars/>`);
L.push(`      <div style={{width:48,height:48,border:\`3px solid \${BOR2}\`,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite'}}/>`);
L.push(`      <div style={{color:DIM,fontSize:13,fontFamily:'Inter,sans-serif'}}>Loading Batch...</div>`);
L.push(`    </div>`);
L.push(`  )`);
L.push(``);
L.push(`  if(!batch&&!loading)return(`);
L.push(`    <div style={{minHeight:'100vh',background:BG,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:16}}>`);
L.push(`      <Stars/>`);
L.push(`      <div style={{fontSize:48}}>📭</div>`);
L.push(`      <div style={{color:TS,fontSize:16,fontWeight:700,fontFamily:'Inter,sans-serif'}}>Batch not found</div>`);
L.push(`      <button onClick={()=>router.replace('/admin/x7k2p')} style={bp}>← Back to Admin</button>`);
L.push(`    </div>`);
L.push(`  )`);
L.push(``);

// Main return
L.push(`  return(`);
L.push(`    <div style={{minHeight:'100vh',background:BG,fontFamily:'Inter,sans-serif',position:'relative'}}>`);
L.push(`      <Stars/>`);
// CSS
L.push(`      <style>{\``);
L.push(`        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:wght@700;800&display=swap');`);
L.push(`        @keyframes bdtwinkle{0%,100%{opacity:0.1}50%{opacity:0.7}}`);
L.push(`        @keyframes spin{to{transform:rotate(360deg)}}`);
L.push(`        @keyframes fadein{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}`);
L.push(`        @keyframes slideup{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}`);
L.push(`        .bd-tab:hover{background:rgba(77,159,255,0.12)!important;border-color:rgba(77,159,255,0.4)!important}`);
L.push(`        .bd-card:hover{border-color:rgba(77,159,255,0.3)!important;transform:translateY(-2px);transition:all 0.2s}`);
L.push(`        .bd-btn:hover{opacity:0.85;transform:translateY(-1px)}`);
L.push(`        .bd-row:hover{background:rgba(77,159,255,0.05)!important}`);
L.push(`        ::-webkit-scrollbar{width:4px;height:4px}`);
L.push(`        ::-webkit-scrollbar-track{background:transparent}`);
L.push(`        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}`);
L.push(`      \`}</style>`);
// Toast
L.push(`      {toast&&<div style={{position:'fixed',top:16,left:'50%',transform:'translateX(-50%)',zIndex:9999,`);
L.push(`        background:toast.tp==='s'?'rgba(0,196,140,0.95)':toast.tp==='e'?'rgba(255,77,77,0.95)':'rgba(255,184,77,0.95)',`);
L.push(`        color:'#fff',padding:'12px 24px',borderRadius:12,fontSize:13,fontWeight:700,`);
L.push(`        boxShadow:'0 8px 32px rgba(0,0,0,0.4)',animation:'fadein 0.3s ease',whiteSpace:'nowrap'}}>{toast.msg}</div>}`);
// Header
L.push(`      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.92)',backdropFilter:'blur(16px)',`);
L.push(`        borderBottom:\`1px solid \${BOR}\`,padding:'12px 16px'}}>`);
L.push(`        <div style={{maxWidth:900,margin:'0 auto'}}>`);
L.push(`          <div style={{display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>`);
L.push(`            <button onClick={()=>router.push('/admin/x7k2p')} style={{...bg_,padding:'8px 14px',fontSize:12}} className="bd-btn">← Admin</button>`);
L.push(`            <div style={{flex:1}}>`);
L.push(`              <div style={{fontSize:20,fontWeight:800,fontFamily:'Playfair Display,serif',`);
L.push(`                background:\`linear-gradient(90deg,\${ACC},#A8D4FF)\`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.2}}>`);
L.push(`                📦 {batch?.name}`);
L.push(`              </div>`);
L.push(`              <div style={{fontSize:11,color:DIM,marginTop:2}}>Batch Manager · Created {batch?.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</div>`);
L.push(`            </div>`);
L.push(`            <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>`);
L.push(`              <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:ACC,padding:'4px 10px',borderRadius:20,border:\`1px solid \${BOR2}\`}}>👥 {students.length}</span>`);
L.push(`              <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:SUC,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)'}}>📝 {exams.length}</span>`);
L.push(`            </div>`);
L.push(`          </div>`);
// Tab bar
L.push(`          <div style={{display:'flex',gap:4,marginTop:12,overflowX:'auto' as any,paddingBottom:4}}>`);
L.push(`            {TABS.map(t=>(`);
L.push(`              <button key={t.id} onClick={()=>setTab(t.id)} className="bd-tab" style={{`);
L.push(`                background:tab===t.id?\`rgba(77,159,255,0.18)\`:'transparent',`);
L.push(`                border:\`1px solid \${tab===t.id?BOR2:'transparent'}\`,`);
L.push(`                color:tab===t.id?ACC:DIM,borderRadius:8,padding:'7px 12px',cursor:'pointer',`);
L.push(`                fontSize:12,fontWeight:600,whiteSpace:'nowrap' as any,fontFamily:'Inter,sans-serif',`);
L.push(`                transition:'all 0.2s'}}>`)
L.push(`                {t.ico} {t.label}`);
L.push(`              </button>`);
L.push(`            ))}`);
L.push(`          </div>`);
L.push(`        </div>`);
L.push(`      </div>`);
// Content area
L.push(`      <div style={{maxWidth:900,margin:'0 auto',padding:'20px 16px',position:'relative',zIndex:1}}>`);

// ── OVERVIEW TAB ──
L.push(`        {tab==='overview'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={{display:'flex',gap:12,flexWrap:'wrap',marginBottom:16}}>`);
L.push(`            <StatBox ico="👥" label="Total Students" val={students.length} col={ACC}/>`);
L.push(`            <StatBox ico="📝" label="Total Exams" val={exams.length} col={WRN}/>`);
L.push(`            <StatBox ico="📅" label="Batch Age" val={batch?.createdAt?Math.floor((Date.now()-new Date(batch.createdAt).getTime())/(86400000))+' days':'-'} col={SUC}/>`);
L.push(`            <StatBox ico="🏫" label="Batch ID" val={batchId?.slice(-6)} sub="Last 6 chars" col={GOLD}/>`);
L.push(`          </div>`);
// Recent students
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>🕐 Recently Added Students</div>`);
L.push(`            {recentStudents.length?recentStudents.map(s=>(`);
L.push(`              <div key={s._id} className="bd-row" style={{display:'flex',alignItems:'center',gap:10,padding:'10px 8px',borderRadius:8,transition:'all 0.15s'}}>`);
L.push(`                <div style={{width:34,height:34,borderRadius:'50%',background:\`linear-gradient(135deg,\${ACC}44,\${ACC}22)\`,`);
L.push(`                  border:\`1px solid \${BOR2}\`,display:'flex',alignItems:'center',justifyContent:'center',`);
L.push(`                  fontSize:13,fontWeight:700,color:ACC,flexShrink:0}}>`);
L.push(`                  {(s.name||'?')[0].toUpperCase()}`);
L.push(`                </div>`);
L.push(`                <div style={{flex:1,minWidth:0}}>`);
L.push(`                  <div style={{fontSize:13,fontWeight:600,color:TS,whiteSpace:'nowrap' as any,overflow:'hidden',textOverflow:'ellipsis'}}>{s.name||'—'}</div>`);
L.push(`                  <div style={{fontSize:11,color:DIM,whiteSpace:'nowrap' as any,overflow:'hidden',textOverflow:'ellipsis'}}>{s.email}</div>`);
L.push(`                </div>`);
L.push(`                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>`);
L.push(`              </div>`);
L.push(`            )):<div style={{textAlign:'center' as any,padding:'30px',color:DIM,fontSize:12}}>No students added yet</div>}`);
L.push(`          </div>`);
// Quick actions
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>⚡ Quick Actions</div>`);
L.push(`            <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>`);
L.push(`              <button onClick={()=>setTab('students')} style={bp} className="bd-btn">👥 Manage Students</button>`);
L.push(`              <button onClick={()=>setTab('exams')} style={bp} className="bd-btn">📝 Assign Exams</button>`);
L.push(`              <button onClick={()=>setTab('announce')} style={{...bp,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bd-btn">📢 Announce</button>`);
L.push(`              <button onClick={exportCSV} style={bs} className="bd-btn">📤 Export CSV</button>`);
L.push(`            </div>`);
L.push(`          </div>`);
L.push(`        </div>}`);

// ── STUDENTS TAB ──
L.push(`        {tab==='students'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={{...cs,marginBottom:14}}>`);
L.push(`            <div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap',marginBottom:12}}>`);
L.push(`              <input value={searchQ} onChange={e=>setSearchQ(e.target.value)} placeholder="🔍 Search by name or email..." style={{...inp,maxWidth:320,padding:'10px 14px'}}/>`);
L.push(`              <button onClick={()=>setAddOpen(p=>!p)} style={bp} className="bd-btn">➕ Add Student</button>`);
L.push(`              <button onClick={exportCSV} style={bs} className="bd-btn">📤 Export CSV</button>`);
L.push(`              <span style={{fontSize:12,color:DIM,marginLeft:'auto'}}>{filteredStudents.length} students</span>`);
L.push(`            </div>`);
// Add student form
L.push(`            {addOpen&&<div style={{background:'rgba(77,159,255,0.05)',border:\`1px solid \${BOR2}\`,borderRadius:10,padding:14,marginBottom:12}}>`);
L.push(`              <div style={{fontSize:12,fontWeight:700,color:ACC,marginBottom:10}}>➕ Add Student to Batch</div>`);
L.push(`              <div style={{display:'flex',gap:8,marginBottom:10}}>`);
L.push(`                <button onClick={()=>setAddMode('email')} style={{...bg_,opacity:addMode==='email'?1:0.5}} className="bd-btn">By Email</button>`);
L.push(`                <button onClick={()=>setAddMode('id')} style={{...bg_,opacity:addMode==='id'?1:0.5}} className="bd-btn">By Student ID</button>`);
L.push(`              </div>`);
L.push(`              <div style={{display:'flex',gap:8}}>`);
L.push(`                <input value={addInput} onChange={e=>setAddInput(e.target.value)} `);
L.push(`                  onKeyDown={e=>e.key==='Enter'&&addStudent()}`);
L.push(`                  placeholder={addMode==='email'?'student@email.com':'Student MongoDB ID'} `);
L.push(`                  style={{...inp,flex:1,padding:'10px 12px'}}/>`);
L.push(`                <button onClick={addStudent} disabled={adding} style={{...bp,opacity:adding?0.7:1}} className="bd-btn">`);
L.push(`                  {adding?'Adding...':'Add'}`);
L.push(`                </button>`);
L.push(`              </div>`);
L.push(`            </div>}`);
// Student list
L.push(`            {filteredStudents.length?(`);
L.push(`              <div style={{overflowX:'auto' as any}}>`);
L.push(`                <table style={{width:'100%',borderCollapse:'collapse' as any,fontSize:12}}>`);
L.push(`                  <thead>`);
L.push(`                    <tr style={{borderBottom:\`1px solid \${BOR}\`}}>`);
L.push(`                      {['#','Name','Email','Phone','Joined','Action'].map(h=>(`);
L.push(`                        <th key={h} style={{padding:'8px 10px',textAlign:'left' as any,color:DIM,fontWeight:600,fontSize:11,letterSpacing:0.4}}>{h}</th>`);
L.push(`                      ))}`);
L.push(`                    </tr>`);
L.push(`                  </thead>`);
L.push(`                  <tbody>`);
L.push(`                    {filteredStudents.map((s,i)=>(`);
L.push(`                      <tr key={s._id} className="bd-row" style={{borderBottom:\`1px solid \${BOR}\`,transition:'all 0.15s'}}>`);
L.push(`                        <td style={{padding:'10px',color:DIM}}>{i+1}</td>`);
L.push(`                        <td style={{padding:'10px'}}>`);
L.push(`                          <div style={{display:'flex',alignItems:'center',gap:8}}>`);
L.push(`                            <div style={{width:28,height:28,borderRadius:'50%',background:\`linear-gradient(135deg,\${ACC}44,\${ACC}22)\`,`);
L.push(`                              border:\`1px solid \${BOR2}\`,display:'flex',alignItems:'center',justifyContent:'center',`);
L.push(`                              fontSize:11,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>`);
L.push(`                            <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap' as any}}>{s.name||'—'}</span>`);
L.push(`                          </div>`);
L.push(`                        </td>`);
L.push(`                        <td style={{padding:'10px',color:DIM}}>{s.email}</td>`);
L.push(`                        <td style={{padding:'10px',color:DIM}}>{s.phone||'—'}</td>`);
L.push(`                        <td style={{padding:'10px',color:DIM,whiteSpace:'nowrap' as any}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>`);
L.push(`                        <td style={{padding:'10px'}}>`);
L.push(`                          <button onClick={()=>removeStudent(s._id,s.name||s.email)} style={bd} className="bd-btn">Remove</button>`);
L.push(`                        </td>`);
L.push(`                      </tr>`);
L.push(`                    ))}`);
L.push(`                  </tbody>`);
L.push(`                </table>`);
L.push(`              </div>`);
L.push(`            ):<div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>`);
L.push(`              <div style={{fontSize:48,marginBottom:10}}>👥</div>`);
L.push(`              <div style={{fontSize:14,fontWeight:600,color:TS,marginBottom:6}}>No students in this batch</div>`);
L.push(`              <div style={{fontSize:12}}>Click "Add Student" to enroll students</div>`);
L.push(`            </div>}`);
L.push(`          </div>`);
L.push(`        </div>}`);

// ── EXAMS TAB ──
L.push(`        {tab==='exams'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>📌 Assign Exam to Batch</div>`);
L.push(`            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>`);
L.push(`              <select value={assignExamId} onChange={e=>setAssignExamId(e.target.value)} style={{...inp,flex:1,maxWidth:400}}>`);
L.push(`                <option value="">— Select exam to assign —</option>`);
L.push(`                {unassignedExams.map(e=>(<option key={e._id} value={e._id}>{e.title}</option>))}`);
L.push(`              </select>`);
L.push(`              <button onClick={assignExam} style={bp} className="bd-btn">📌 Assign</button>`);
L.push(`            </div>`);
L.push(`          </div>`);
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>📝 Assigned Exams ({exams.length})</div>`);
L.push(`            {exams.length?exams.map(e=>(`);
L.push(`              <div key={e._id} className="bd-card" style={{...cs,marginBottom:10,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>`);
L.push(`                <div style={{flex:1,minWidth:0}}>`);
L.push(`                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{e.title}</div>`);
L.push(`                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>`);
L.push(`                    <span style={{fontSize:11,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>`);
L.push(`                    <span style={{fontSize:11,color:DIM}}>⏱️ {e.duration||'-'} min</span>`);
L.push(`                    <span style={{fontSize:11,color:DIM}}>📊 {e.totalMarks||'-'} marks</span>`);
L.push(`                    <span style={{fontSize:11,background:e.status==='active'?'rgba(0,196,140,0.15)':'rgba(255,184,77,0.15)',`);
L.push(`                      color:e.status==='active'?SUC:WRN,padding:'2px 8px',borderRadius:20}}>{e.status||'draft'}</span>`);
L.push(`                  </div>`);
L.push(`                </div>`);
L.push(`                <button onClick={()=>unassignExam(e._id,e.title)} style={bd} className="bd-btn">Unassign</button>`);
L.push(`              </div>`);
L.push(`            )):<div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>`);
L.push(`              <div style={{fontSize:48,marginBottom:10}}>📝</div>`);
L.push(`              <div style={{fontSize:14,fontWeight:600,color:TS,marginBottom:6}}>No exams assigned</div>`);
L.push(`              <div style={{fontSize:12}}>Assign exams to this batch from above</div>`);
L.push(`            </div>}`);
L.push(`          </div>`);
L.push(`        </div>}`);

// ── ANALYTICS TAB ──
L.push(`        {tab==='analytics'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={{...cs,marginBottom:14}}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:4}}>📈 Batch Analytics</div>`);
L.push(`            <div style={{fontSize:12,color:DIM,marginBottom:16}}>Based on student enrollment data</div>`);
L.push(`            <div style={{display:'flex',gap:12,flexWrap:'wrap',marginBottom:20}}>`);
L.push(`              <StatBox ico="👥" label="Enrolled" val={students.length} col={ACC}/>`);
L.push(`              <StatBox ico="📝" label="Exams Linked" val={exams.length} col={WRN}/>`);
L.push(`              <StatBox ico="📱" label="Active Students" val={students.filter(s=>!s.banned).length} col={SUC}/>`);
L.push(`              <StatBox ico="🚫" label="Banned" val={students.filter(s=>s.banned).length} col={DNG}/>`);
L.push(`            </div>`);
L.push(`            <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:12}}>📊 Enrollment Distribution</div>`);
L.push(`            <ScoreBar label="Active Students" count={students.filter(s=>!s.banned).length} max={Math.max(students.length,1)} col={SUC}/>`);
L.push(`            <ScoreBar label="Banned Students" count={students.filter(s=>s.banned).length} max={Math.max(students.length,1)} col={DNG}/>`);
L.push(`            <ScoreBar label="Exams Assigned" count={exams.length} max={Math.max(allExams.length,1)} col={WRN}/>`);
L.push(`          </div>`);
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>🏆 Enrolled Students — Quick View</div>`);
L.push(`            {students.slice(0,10).map((s,i)=>(`);
L.push(`              <div key={s._id} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 0',borderBottom:\`1px solid \${BOR}\`}}>`);
L.push(`                <div style={{fontSize:16,width:28,textAlign:'center' as any}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':\`#\${i+1}\`}</div>`);
L.push(`                <div style={{width:30,height:30,borderRadius:'50%',background:\`linear-gradient(135deg,\${ACC}44,\${ACC}22)\`,`);
L.push(`                  border:\`1px solid \${BOR2}\`,display:'flex',alignItems:'center',justifyContent:'center',`);
L.push(`                  fontSize:12,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>`);
L.push(`                <div style={{flex:1}}>`);
L.push(`                  <div style={{fontSize:12,fontWeight:600,color:TS}}>{s.name||'—'}</div>`);
L.push(`                  <div style={{fontSize:10,color:DIM}}>{s.email}</div>`);
L.push(`                </div>`);
L.push(`                <div style={{fontSize:11,color:s.banned?DNG:SUC}}>{s.banned?'🚫 Banned':'✅ Active'}</div>`);
L.push(`              </div>`);
L.push(`            ))}`);
L.push(`            {students.length>10&&<div style={{textAlign:'center' as any,padding:'10px',fontSize:12,color:DIM}}>+{students.length-10} more students</div>}`);
L.push(`            {!students.length&&<div style={{textAlign:'center' as any,padding:'30px',color:DIM,fontSize:12}}>No students enrolled yet</div>}`);
L.push(`          </div>`);
L.push(`        </div>}`);

// ── ANNOUNCE TAB ──
L.push(`        {tab==='announce'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:4}}>📢 Send Announcement</div>`);
L.push(`            <div style={{fontSize:12,color:DIM,marginBottom:16}}>This announcement will be sent to all <strong style={{color:ACC}}>{students.length} students</strong> in batch "{batch?.name}"</div>`);
L.push(`            <div style={{marginBottom:12}}>`);
L.push(`              <label style={{display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Announcement Title</label>`);
L.push(`              <input value={annTitle} onChange={e=>setAnnTitle(e.target.value)} placeholder="e.g. Test Tomorrow at 10 AM" style={inp}/>`);
L.push(`            </div>`);
L.push(`            <div style={{marginBottom:16}}>`);
L.push(`              <label style={{display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Message</label>`);
L.push(`              <textarea value={annMsg} onChange={e=>setAnnMsg(e.target.value)} `);
L.push(`                placeholder="Write your announcement here... (supports full message)" `);
L.push(`                style={{...inp,minHeight:120,resize:'vertical' as any}}/>`);
L.push(`            </div>`);
L.push(`            {(annTitle||annMsg)&&<div style={{background:'rgba(77,159,255,0.06)',border:\`1px solid \${BOR}\`,borderRadius:10,padding:14,marginBottom:14}}>`);
L.push(`              <div style={{fontSize:11,color:DIM,marginBottom:6,fontWeight:600}}>PREVIEW</div>`);
L.push(`              <div style={{fontWeight:700,fontSize:14,color:TS}}>{annTitle||'—'}</div>`);
L.push(`              <div style={{fontSize:12,color:DIM,marginTop:4,whiteSpace:'pre-wrap' as any}}>{annMsg||'—'}</div>`);
L.push(`            </div>}`);
L.push(`            <button onClick={sendAnnouncement} disabled={annSending||!annTitle||!annMsg} `);
L.push(`              style={{...bp,opacity:(annSending||!annTitle||!annMsg)?0.6:1}} className="bd-btn">`);
L.push(`              {annSending?'Sending...':'📢 Send to Batch'}`);
L.push(`            </button>`);
L.push(`          </div>`);
L.push(`        </div>}`);

// ── SETTINGS TAB ──
L.push(`        {tab==='settings'&&<div style={{animation:'slideup 0.3s ease'}}>`);
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>✏️ Rename Batch</div>`);
L.push(`            {!renaming?(`);
L.push(`              <div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap'}}>`);
L.push(`                <div style={{fontSize:16,fontWeight:700,color:ACC,flex:1}}>"{batch?.name}"</div>`);
L.push(`                <button onClick={()=>{setRenaming(true);setNewName(batch?.name||'')}} style={bp} className="bd-btn">✏️ Rename</button>`);
L.push(`              </div>`);
L.push(`            ):(`);
L.push(`              <div>`);
L.push(`                <input value={newName} onChange={e=>setNewName(e.target.value)} `);
L.push(`                  onKeyDown={e=>e.key==='Enter'&&renameBatch()}`);
L.push(`                  placeholder="New batch name" style={{...inp,marginBottom:10}}/>`);
L.push(`                <div style={{display:'flex',gap:8}}>`);
L.push(`                  <button onClick={renameBatch} disabled={saving} style={{...bp,opacity:saving?0.7:1}} className="bd-btn">{saving?'Saving...':'💾 Save'}</button>`);
L.push(`                  <button onClick={()=>setRenaming(false)} style={bg_} className="bd-btn">Cancel</button>`);
L.push(`                </div>`);
L.push(`              </div>`);
L.push(`            )}`);
L.push(`          </div>`);
// Batch info
L.push(`          <div style={cs}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>ℹ️ Batch Information</div>`);
L.push(`            {[`);
L.push(`              {k:'Batch ID',v:batchId},`);
L.push(`              {k:'Created At',v:batch?.createdAt?new Date(batch.createdAt).toLocaleString():'-'},`);
L.push(`              {k:'Last Updated',v:batch?.updatedAt?new Date(batch.updatedAt).toLocaleString():'-'},`);
L.push(`              {k:'Total Students',v:students.length},`);
L.push(`              {k:'Total Exams',v:exams.length},`);
L.push(`            ].map(({k,v})=>(`);
L.push(`              <div key={k} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:\`1px solid \${BOR}\`,flexWrap:'wrap',gap:4}}>`);
L.push(`                <span style={{fontSize:12,color:DIM,fontWeight:600}}>{k}</span>`);
L.push(`                <span style={{fontSize:12,color:TS,fontFamily:'monospace'}}>{String(v)}</span>`);
L.push(`              </div>`);
L.push(`            ))}`);
L.push(`          </div>`);
// Danger zone
L.push(`          <div style={{...cs,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.04)'}}>`);
L.push(`            <div style={{fontWeight:700,fontSize:14,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>`);
L.push(`            <div style={{fontSize:12,color:DIM,marginBottom:14}}>Deleting a batch is permanent. All students will be unassigned from this batch.</div>`);
L.push(`            <button onClick={deleteBatch} style={{...bd,padding:'11px 22px',fontSize:13}} className="bd-btn">🗑️ Delete This Batch</button>`);
L.push(`          </div>`);
L.push(`        </div>}`);

L.push(`      </div>`); // content area
L.push(`    </div>`); // main container
L.push(`  )`); // return
L.push(`}`); // component end

const content = L.join('\n');
fs.writeFileSync(`${outDir}/page.tsx`, content);
console.log(`✅ Batch detail page created: ${outDir}/page.tsx`);
CREATEFE

# ══════════════════════════════════════════════════════
# STEP 3 — Patch main page: make batch cards clickable
# ══════════════════════════════════════════════════════
step "STEP 3: Make Batch Cards Clickable"
node << 'PATCHMAIN'
const fs = require('fs'), path = require('path');
const WS = process.env.HOME + '/workspace';
const fp = `${WS}/frontend/app/admin/x7k2p/page.tsx`;
if (!fs.existsSync(fp)) { console.log('ERROR: Main admin page not found at '+fp); process.exit(1); }
let c = fs.readFileSync(fp, 'utf8');
if (c.includes('BATCH_CLICK_FIX')) { console.log('Already clickable'); process.exit(0); }

// Add useRouter import if not present - it should be already
// Find the batch card old code and replace with clickable version
const OLD = `<div key={b._id} style={{...cs,borderLeft:'3px solid #3B82F6',position:'relative',overflow:'hidden'}}>`;
const NEW = `<div key={b._id} onClick={()=>router.push(\`/admin/x7k2p/batch/\${b._id}\`)} style={{...cs,borderLeft:'3px solid #3B82F6',position:'relative',overflow:'hidden',cursor:'pointer',transition:'all 0.2s'}} title="Click to manage batch">{/* BATCH_CLICK_FIX */}`;

if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  fs.writeFileSync(fp, c);
  console.log('✅ Batch cards are now clickable');
} else {
  // Try alternate pattern - the original unpatched one
  const OLD2 = `<div key={b._id} style={cs}>`;
  const NEW2 = `<div key={b._id} onClick={()=>router.push(\`/admin/x7k2p/batch/\${b._id}\`)} style={{...cs,cursor:'pointer',transition:'all 0.2s',borderLeft:'3px solid rgba(77,159,255,0.5)'}} title="Click to manage">{/* BATCH_CLICK_FIX */}`;
  if (c.includes(OLD2)) {
    // Only replace inside batch map context
    const batchMapIdx = c.indexOf('(batches||[]).map(b=>');
    if (batchMapIdx > -1) {
      const chunk = c.slice(batchMapIdx, batchMapIdx + 300);
      const patchedChunk = chunk.replace(OLD2, NEW2);
      c = c.slice(0, batchMapIdx) + patchedChunk + c.slice(batchMapIdx + 300);
      fs.writeFileSync(fp, c);
      console.log('✅ Batch cards patched (alt pattern)');
    } else { console.log('WARNING: Could not locate batch map - manual patch needed'); }
  } else { console.log('WARNING: Batch card pattern not found in main page. Share screenshot of batch map code for manual fix.'); }
}
PATCHMAIN

# ══════════════════════════════════════════════════════
# STEP 4 — Git Push
# ══════════════════════════════════════════════════════
step "STEP 4: Git Push"
cd ~/workspace
git add .
git commit -m "feat: batch detail page S5/M3 - SaaS UI + backend routes + clickable cards"
git push

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ ALL DONE! After Vercel deploys (1-2 min):       ║"
echo "║  1. Go to Batch Manager                             ║"
echo "║  2. Click any batch card → opens detail page        ║"
echo "║  Tabs: Overview | Students | Exams | Analytics      ║"
echo "║        Announce | Settings                          ║"
echo "╚══════════════════════════════════════════════════════╝"
