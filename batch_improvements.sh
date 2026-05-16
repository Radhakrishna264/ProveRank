#!/bin/bash
# ProveRank — Batch Detail: Exams Assign + Notes/Material Section
# Run: bash batch_improvements.sh

echo "=== Step 1: Backend Routes ==="
node << 'BEJS'
const fs=require('fs'),path=require('path');
const WS=process.env.HOME+'/workspace';

// Find models dir
const modelDirs=[WS+'/src/models',WS+'/models'];
let modelDir=null;
for(const d of modelDirs){if(fs.existsSync(d)){modelDir=d;break;}}
console.log('Model dir:',modelDir);

// Create BatchNote model
if(modelDir&&!fs.existsSync(modelDir+'/BatchNote.js')){
fs.writeFileSync(modelDir+'/BatchNote.js',`const mongoose=require('mongoose');
const BatchNoteSchema=new mongoose.Schema({
  batch:{type:mongoose.Schema.Types.ObjectId,ref:'Batch',required:true},
  title:{type:String,required:true,trim:true},
  description:{type:String,default:''},
  url:{type:String,default:''},
  type:{type:String,enum:['pdf','video','doc','link','image','other'],default:'link'},
  subject:{type:String,default:'General'},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
},{timestamps:true});
module.exports=mongoose.model('BatchNote',BatchNoteSchema);`);
console.log('BatchNote model created');
}else{console.log('BatchNote model exists or modelDir not found');}

// Find batch routes file
const routeDirs=[WS+'/src/routes',WS+'/routes'];
let target=null;
for(const dir of routeDirs){
  if(!fs.existsSync(dir))continue;
  for(const f of fs.readdirSync(dir)){
    const fp=path.join(dir,f);
    if(fs.readFileSync(fp,'utf8').includes('BATCH_CRUD_FIX')){target=fp;break;}
  }
  if(target)break;
}
if(!target){console.log('ERROR: batch route file not found');process.exit(1);}
console.log('Patching:',target);

let c=fs.readFileSync(target,'utf8');
if(c.includes('BATCH_NOTES_FIX')){console.log('Already patched');process.exit(0);}

const mp=c.includes("require('../models/")?'../models/':'../../models/';

const patch=`
// BATCH_NOTES_FIX — Notes/Study Material + Exam Assign routes
// GET all notes for a batch
router.get('/batches/:id/notes',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const BatchNote=require('${mp}BatchNote');
    const notes=await BatchNote.find({batch:req.params.id}).sort({createdAt:-1}).lean();
    res.json(notes);
  }catch(e){res.status(500).json({success:false,message:e.message});}
});

// POST add note to batch
router.post('/batches/:id/notes',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const BatchNote=require('${mp}BatchNote');
    const{title,description,url,type,subject}=req.body;
    if(!title||!title.trim())return res.status(400).json({success:false,message:'Title required'});
    const note=await BatchNote.create({
      batch:req.params.id,title:title.trim(),
      description:description||'',url:url||'',
      type:type||'link',subject:subject||'General',
      createdBy:req.user&&req.user.id
    });
    res.json({success:true,note});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});

// DELETE note
router.delete('/batches/:id/notes/:nid',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const BatchNote=require('${mp}BatchNote');
    await BatchNote.findByIdAndDelete(req.params.nid);
    res.json({success:true});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});

// GET all exams (for assign dropdown)
router.get('/batches/all-exams',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const Exam=require('${mp}Exam');
    const exams=await Exam.find({}).select('title status scheduledAt duration totalMarks').sort({createdAt:-1}).lean();
    res.json(exams);
  }catch(e){res.json([]);}
});

// POST assign exam to batch
router.post('/batches/:id/exams/assign',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const Exam=require('${mp}Exam');
    const{examId}=req.body;
    if(!examId)return res.status(400).json({success:false,message:'examId required'});
    await Exam.findByIdAndUpdate(examId,{$set:{batch:req.params.id}});
    res.json({success:true,message:'Exam assigned'});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});

// DELETE unassign exam from batch
router.delete('/batches/:id/exams/:eid',verifyToken,isSuperAdmin,async(req,res)=>{
  try{
    const Exam=require('${mp}Exam');
    await Exam.findByIdAndUpdate(req.params.eid,{$unset:{batch:1}});
    res.json({success:true});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});
`;

c=c.replace('// BATCH_CRUD_FIX',patch+'\n// BATCH_CRUD_FIX');
fs.writeFileSync(target,c);
console.log('Backend routes added');
BEJS

echo ""
echo "=== Step 2: Frontend Update ==="
node << 'FEJS'
const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let c=fs.readFileSync(fp,'utf8');

if(c.includes('BATCH_IMPROVEMENTS_V2')){console.log('Already done');process.exit(0);}

// Find BatchDetailOverlay function and replace it entirely
const startMarker='// ═══════════════════════════════════════════════════\n// BatchDetailOverlay — S5/M3 Inline Batch Detail View';
const endMarker='\n}\n';

const startIdx=c.indexOf(startMarker);
if(startIdx<0){console.log('ERROR: BatchDetailOverlay marker not found. Check file.');process.exit(1);}

// Find the matching closing brace of the component
// Count from the function start
let braceCount=0,inComp=false,endIdx=-1;
const funcStart=c.indexOf('function BatchDetailOverlay',startIdx);
for(let i=funcStart;i<c.length;i++){
  if(c[i]==='{'){braceCount++;inComp=true;}
  else if(c[i]==='}'){braceCount--;if(inComp&&braceCount===0){endIdx=i+1;break;}}
}
console.log('Component found at:',funcStart,'ends at:',endIdx);

const NEW_COMP=`// BATCH_IMPROVEMENTS_V2
// ═══════════════════════════════════════════════════
// BatchDetailOverlay — S5/M3 Complete Batch Detail
// ═══════════════════════════════════════════════════
function BatchDetailOverlay({batch,token,API,onClose,onBatchDelete,onBatchRename,T}:{
  batch:any,token:string,API:string,onClose:()=>void,
  onBatchDelete:(id:string)=>void,onBatchRename:(id:string,name:string)=>void,
  T:(m:string,t?:any)=>void
}){
  const[tab,setTab]=useState('overview')
  const[students,setStudents]=useState<any[]>([])
  const[exams,setExams]=useState<any[]>([])
  const[allExams,setAllExams]=useState<any[]>([])
  const[notes,setNotes]=useState<any[]>([])
  const[loading,setLoading]=useState(false)
  const[addEmail,setAddEmail]=useState('')
  const[adding,setAdding]=useState(false)
  const[search,setSearch]=useState('')
  const[annTitle,setAnnTitle]=useState('')
  const[annMsg,setAnnMsg]=useState('')
  const[renaming,setRenaming]=useState(false)
  const[newName,setNewName]=useState('')
  const[assignExamId,setAssignExamId]=useState('')
  const[noteTitle,setNoteTitle]=useState('')
  const[noteDesc,setNoteDesc]=useState('')
  const[noteUrl,setNoteUrl]=useState('')
  const[noteType,setNoteType]=useState('link')
  const[noteSub,setNoteSub]=useState('General')
  const[addingNote,setAddingNote]=useState(false)
  const ACC='#4D9FFF',TS='#E8F4FF',DIM='#6B8FAF',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D',PRP='#A78BFA'
  const BOR='rgba(77,159,255,0.18)',BOR2='rgba(77,159,255,0.3)',CRD='rgba(0,22,40,0.75)'
  const bp2:any={background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
  const bd2:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'6px 12px',cursor:'pointer',fontWeight:700,fontSize:11}
  const inp2:any={width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box'as const,fontFamily:'Inter,sans-serif'}
  const cs2:any={background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}
  const sel2:any={padding:'10px 12px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:13,outline:'none',fontFamily:'Inter,sans-serif'}

  const loadAll=useCallback(async()=>{
    if(!batch||!token)return
    setLoading(true)
    const h={Authorization:'Bearer '+token}
    const gets=(u:string)=>fetch(API+u,{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[])
    const[s,e,n,ae]=await Promise.all([
      gets('/api/admin/batches/'+batch._id+'/students'),
      gets('/api/admin/batches/'+batch._id+'/exams'),
      gets('/api/admin/batches/'+batch._id+'/notes'),
      gets('/api/admin/batches/all-exams'),
    ])
    setStudents(Array.isArray(s)?s:[])
    setExams(Array.isArray(e)?e:[])
    setNotes(Array.isArray(n)?n:[])
    setAllExams(Array.isArray(ae)?ae:[])
    setLoading(false)
  },[batch,token,API])

  useEffect(()=>{if(batch&&token){setTab('overview');loadAll()}},[batch,token,loadAll])

  const addStudent=async()=>{
    if(!addEmail.trim()){T('Enter email','e');return}
    setAdding(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/add',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({studentEmail:addEmail.trim()})})
      const d=await r.json()
      if(r.ok){T('Student added ✅','s');setAddEmail('');loadAll()}else T(d.message||'Failed','e')
    }catch{T('Error','e')}finally{setAdding(false)}
  }

  const removeStudent=async(sid:string,name:string)=>{
    if(!window.confirm('Remove '+name+' from batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/'+sid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Removed','s');setStudents(p=>p.filter(s=>s._id!==sid))}else T('Failed','e')
  }

  const assignExam=async()=>{
    if(!assignExamId){T('Select an exam','e');return}
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/exams/assign',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({examId:assignExamId})})
    if(r.ok){T('Exam assigned ✅','s');setAssignExamId('');loadAll()}else T('Failed','e')
  }

  const unassignExam=async(eid:string,title:string)=>{
    if(!window.confirm('Unassign "'+title+'" from this batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/exams/'+eid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Unassigned','s');setExams(p=>p.filter(e=>e._id!==eid))}else T('Failed','e')
  }

  const addNote=async()=>{
    if(!noteTitle.trim()){T('Enter title','e');return}
    setAddingNote(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batch._id+'/notes',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:noteTitle.trim(),description:noteDesc,url:noteUrl,type:noteType,subject:noteSub})})
      const d=await r.json()
      if(r.ok){T('Material added ✅','s');setNoteTitle('');setNoteDesc('');setNoteUrl('');loadAll()}else T(d.message||'Failed','e')
    }catch{T('Error','e')}finally{setAddingNote(false)}
  }

  const deleteNote=async(nid:string,title:string)=>{
    if(!window.confirm('Delete "'+title+'"?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/notes/'+nid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted','s');setNotes(p=>p.filter(n=>n._id!==nid))}else T('Failed','e')
  }

  const renameBatch=async()=>{
    if(!newName.trim())return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'PATCH',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({name:newName.trim()})})
    const d=await r.json()
    if(r.ok){T('Renamed ✅','s');onBatchRename(batch._id,newName.trim());setRenaming(false)}else T(d.message||'Failed','e')
  }

  const deleteBatch=async()=>{
    if(!window.confirm('DELETE "'+batch.name+'"?\\nAll students unassigned. Cannot be undone.'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted','s');onBatchDelete(batch._id)}else T('Failed','e')
  }

  const sendAnn=async()=>{
    if(!annTitle||!annMsg){T('Fill all fields','e');return}
    const r=await fetch(API+'/api/admin/announcements',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:annTitle,message:annMsg,batch:batch._id})})
    if(r.ok){T('Sent ✅','s');setAnnTitle('');setAnnMsg('')}else T('Failed','e')
  }

  const exportCSV=()=>{
    const rows=[['Name','Email','Phone','Joined'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():''])]
    const csv=rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\\n')
    const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='batch_'+batch.name+'.csv';a.click();T('Exported ✅','s')
  }

  const getNoteIcon=(type:string)=>{
    const icons:any={pdf:'📄',video:'🎥',doc:'📝',link:'🔗',image:'🖼️',other:'📎'}
    return icons[type]||'📎'
  }

  const unassignedExams=allExams.filter(ae=>!exams.find(e=>e._id===ae._id))
  const filtered=students.filter(s=>!search||s.name?.toLowerCase().includes(search.toLowerCase())||s.email?.toLowerCase().includes(search.toLowerCase()))
  const TABS=[
    {id:'overview',l:'📊 Overview'},
    {id:'students',l:'👥 Students ('+students.length+')'},
    {id:'exams',l:'📝 Exams ('+exams.length+')'},
    {id:'notes',l:'📚 Materials ('+notes.length+')'},
    {id:'analytics',l:'📈 Analytics'},
    {id:'announce',l:'📢 Announce'},
    {id:'settings',l:'⚙️ Settings'},
  ]

  return(
    <div style={{position:'fixed',inset:0,background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',zIndex:998,overflowY:'auto',fontFamily:'Inter,sans-serif'}}>
      <style>{'.bdt2:hover{opacity:0.82;transform:translateY(-1px)} .bdr2:hover{background:rgba(77,159,255,0.05)!important} @keyframes bds{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}} @keyframes spin{to{transform:rotate(360deg)}}'}</style>

      <div style={{position:'sticky',top:0,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(16px)',borderBottom:'1px solid '+BOR,padding:'12px 16px',zIndex:10}}>
        <div style={{maxWidth:940,margin:'0 auto'}}>
          <div style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap',marginBottom:10}}>
            <button onClick={onClose} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'7px 12px',cursor:'pointer',fontSize:12,fontWeight:600,transition:'all 0.2s'}} className="bdt2">← Back</button>
            <div style={{flex:1,minWidth:0}}>
              <div style={{fontSize:17,fontWeight:800,fontFamily:'Playfair Display,serif',background:'linear-gradient(90deg,'+ACC+',#A8D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>📦 {batch.name}</div>
              <div style={{fontSize:10,color:DIM,marginTop:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>ID: {batch._id} · {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</div>
            </div>
            <div style={{display:'flex',gap:6,flexShrink:0,flexWrap:'wrap'}}>
              <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:ACC,padding:'4px 10px',borderRadius:20,border:'1px solid '+BOR2}}>👥 {students.length}</span>
              <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:SUC,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)'}}>📝 {exams.length}</span>
              <span style={{fontSize:11,background:'rgba(167,139,250,0.1)',color:PRP,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(167,139,250,0.25)'}}>📚 {notes.length}</span>
            </div>
          </div>
          <div style={{display:'flex',gap:3,overflowX:'auto',paddingBottom:2}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setTab(t.id)} className="bdt2" style={{background:tab===t.id?'rgba(77,159,255,0.18)':'transparent',border:'1px solid '+(tab===t.id?BOR2:'transparent'),color:tab===t.id?ACC:DIM,borderRadius:8,padding:'6px 10px',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap',transition:'all 0.2s',fontFamily:'Inter,sans-serif'}}>{t.l}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{maxWidth:940,margin:'0 auto',padding:'16px 14px'}}>
        {loading&&<div style={{textAlign:'center',padding:48,color:DIM}}>
          <div style={{width:36,height:36,border:'3px solid '+BOR2,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite',margin:'0 auto 12px'}}/>
          <div style={{fontSize:13}}>Loading...</div>
        </div>}

        {/* ── OVERVIEW ── */}
        {!loading&&tab==='overview'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:14}}>
            {[{i:'👥',l:'Students',v:students.length,c:ACC},{i:'📝',l:'Exams',v:exams.length,c:WRN},{i:'📚',l:'Materials',v:notes.length,c:PRP},{i:'✅',l:'Active',v:students.filter(s=>!s.banned).length,c:SUC}].map(x=>(
              <div key={x.l} style={{background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:'16px 12px',flex:1,minWidth:90,textAlign:'center',backdropFilter:'blur(12px)'}}>
                <div style={{fontSize:22,marginBottom:4}}>{x.i}</div>
                <div style={{fontSize:22,fontWeight:800,color:x.c,fontFamily:'Playfair Display,serif'}}>{x.v}</div>
                <div style={{fontSize:10,color:DIM,marginTop:2,fontWeight:600}}>{x.l}</div>
              </div>
            ))}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>⚡ Quick Actions</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
              <button onClick={()=>setTab('students')} style={bp2} className="bdt2">👥 Students</button>
              <button onClick={()=>setTab('exams')} style={bp2} className="bdt2">📝 Exams</button>
              <button onClick={()=>setTab('notes')} style={{...bp2,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bdt2">📚 Materials</button>
              <button onClick={()=>setTab('announce')} style={{...bp2,background:'linear-gradient(135deg,#059669,#047857)'}} className="bdt2">📢 Announce</button>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export CSV</button>
            </div>
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🕐 Recent Students</div>
            {students.slice(0,5).map(s=>(
              <div key={s._id} className="bdr2" style={{display:'flex',alignItems:'center',gap:10,padding:'8px 6px',borderRadius:8,transition:'all 0.15s'}}>
                <div style={{width:30,height:30,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</div>
                  <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                </div>
                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center',padding:24,color:DIM,fontSize:12}}>No students yet — add from Students tab</div>}
          </div>
        </div>}

        {/* ── STUDENTS ── */}
        {!loading&&tab==='students'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
              <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search name/email" style={{...inp2,maxWidth:240,padding:'9px 12px'}}/>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,padding:'9px 14px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export</button>
              <span style={{marginLeft:'auto',fontSize:11,color:DIM,alignSelf:'center'}}>{filtered.length} students</span>
            </div>
            <div style={{background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:14,marginBottom:12}}>
              <div style={{fontSize:11,fontWeight:700,color:ACC,marginBottom:8}}>➕ Add Student by Email</div>
              <div style={{display:'flex',gap:8}}>
                <input value={addEmail} onChange={e=>setAddEmail(e.target.value)} onKeyDown={e=>e.key==='Enter'&&addStudent()} placeholder="student@email.com" style={{...inp2,flex:1,padding:'9px 12px'}}/>
                <button onClick={addStudent} disabled={adding} style={{...bp2,opacity:adding?0.7:1}} className="bdt2">{adding?'Adding...':'Add'}</button>
              </div>
            </div>
            {filtered.length?(
              <div style={{overflowX:'auto'}}>
                <table style={{width:'100%',borderCollapse:'collapse',fontSize:12}}>
                  <thead><tr style={{borderBottom:'1px solid '+BOR}}>
                    {['#','Name','Email','Joined','Status','Action'].map(h=><th key={h} style={{padding:'8px',textAlign:'left',color:DIM,fontWeight:600,fontSize:10,letterSpacing:0.4}}>{h}</th>)}
                  </tr></thead>
                  <tbody>{filtered.map((s,i)=>(
                    <tr key={s._id} className="bdr2" style={{borderBottom:'1px solid '+BOR,transition:'all 0.15s'}}>
                      <td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>
                      <td style={{padding:'9px 8px'}}>
                        <div style={{display:'flex',alignItems:'center',gap:7}}>
                          <div style={{width:26,height:26,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                          <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap'}}>{s.name||'—'}</span>
                        </div>
                      </td>
                      <td style={{padding:'9px 8px',color:DIM,fontSize:11}}>{s.email}</td>
                      <td style={{padding:'9px 8px',color:DIM,whiteSpace:'nowrap'}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
                      <td style={{padding:'9px 8px'}}><span style={{fontSize:10,color:s.banned?DNG:SUC,background:s.banned?'rgba(255,77,77,0.1)':'rgba(0,196,140,0.1)',padding:'2px 8px',borderRadius:20}}>{s.banned?'🚫 Banned':'✅ Active'}</span></td>
                      <td style={{padding:'9px 8px'}}><button onClick={()=>removeStudent(s._id,s.name||s.email)} style={bd2} className="bdt2">Remove</button></td>
                    </tr>
                  ))}</tbody>
                </table>
              </div>
            ):<div style={{textAlign:'center',padding:32,color:DIM}}>
              <div style={{fontSize:40,marginBottom:8}}>👥</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No students enrolled</div>
              <div style={{fontSize:11}}>Add using email above</div>
            </div>}
          </div>
        </div>}

        {/* ── EXAMS ── */}
        {!loading&&tab==='exams'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>📌 Assign Exam to Batch</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
              <select value={assignExamId} onChange={e=>setAssignExamId(e.target.value)} style={{...sel2,flex:1,maxWidth:380}}>
                <option value="">— Select exam to assign —</option>
                {unassignedExams.map(e=><option key={e._id} value={e._id}>{e.title}</option>)}
              </select>
              <button onClick={assignExam} style={bp2} className="bdt2">📌 Assign</button>
            </div>
            {!unassignedExams.length&&<div style={{fontSize:11,color:DIM,marginTop:8}}>All available exams are already assigned, or no exams created yet.</div>}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📝 Assigned Exams ({exams.length})</div>
            {exams.map(e=>(
              <div key={e._id} className="bdr2" style={{display:'flex',gap:12,alignItems:'center',padding:'12px 10px',borderRadius:10,border:'1px solid '+BOR,marginBottom:10,flexWrap:'wrap',transition:'all 0.15s'}}>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{e.title}</div>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:10,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
                    <span style={{fontSize:10,color:DIM}}>⏱ {e.duration||'-'} min</span>
                    <span style={{fontSize:10,color:DIM}}>📊 {e.totalMarks||'-'} marks</span>
                    <span style={{fontSize:10,color:e.status==='active'?SUC:WRN,background:e.status==='active'?'rgba(0,196,140,0.12)':'rgba(255,184,77,0.12)',padding:'2px 8px',borderRadius:20}}>{e.status||'draft'}</span>
                  </div>
                </div>
                <button onClick={()=>unassignExam(e._id,e.title)} style={bd2} className="bdt2">Unassign</button>
              </div>
            ))}
            {!exams.length&&<div style={{textAlign:'center',padding:32,color:DIM,fontSize:12}}>
              <div style={{fontSize:40,marginBottom:8}}>📝</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No exams assigned</div>
              <div>Assign exams from the dropdown above</div>
            </div>}
          </div>
        </div>}

        {/* ── NOTES / STUDY MATERIAL ── */}
        {!loading&&tab==='notes'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>➕ Add Study Material</div>
            <div style={{display:'grid',gap:10,marginBottom:12}}>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Title *</label>
                <input value={noteTitle} onChange={e=>setNoteTitle(e.target.value)} placeholder="e.g. NCERT Biology Chapter 1 Notes" style={inp2}/>
              </div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div>
                  <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Type</label>
                  <select value={noteType} onChange={e=>setNoteType(e.target.value)} style={{...sel2,width:'100%'}}>
                    <option value="pdf">📄 PDF</option>
                    <option value="video">🎥 Video</option>
                    <option value="doc">📝 Document</option>
                    <option value="link">🔗 Link</option>
                    <option value="image">🖼️ Image</option>
                    <option value="other">📎 Other</option>
                  </select>
                </div>
                <div>
                  <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Subject</label>
                  <select value={noteSub} onChange={e=>setNoteSub(e.target.value)} style={{...sel2,width:'100%'}}>
                    {['General','Biology','Physics','Chemistry','Mathematics','English','Hindi','Other'].map(s=><option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Resource URL (Google Drive / YouTube / Direct Link)</label>
                <input value={noteUrl} onChange={e=>setNoteUrl(e.target.value)} placeholder="https://drive.google.com/..." style={inp2}/>
              </div>
              <div>
                <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Description (optional)</label>
                <textarea value={noteDesc} onChange={e=>setNoteDesc(e.target.value)} placeholder="Brief description of this material..." style={{...inp2,minHeight:70,resize:'vertical'}}/>
              </div>
            </div>
            <button onClick={addNote} disabled={addingNote||!noteTitle.trim()} style={{...bp2,background:'linear-gradient(135deg,#7C3AED,#4C1D95)',opacity:(addingNote||!noteTitle.trim())?0.6:1}} className="bdt2">{addingNote?'Adding...':'➕ Add Material'}</button>
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📚 Study Materials ({notes.length})</div>
            {notes.map(n=>(
              <div key={n._id} className="bdr2" style={{display:'flex',gap:12,padding:'12px 10px',borderRadius:10,border:'1px solid '+BOR,marginBottom:10,flexWrap:'wrap',transition:'all 0.15s'}}>
                <div style={{fontSize:28,flexShrink:0,alignSelf:'center'}}>{getNoteIcon(n.type)}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{n.title}</div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap',marginBottom:n.description?4:0}}>
                    <span style={{fontSize:10,color:PRP,background:'rgba(167,139,250,0.1)',padding:'2px 8px',borderRadius:20,border:'1px solid rgba(167,139,250,0.2)'}}>{n.subject}</span>
                    <span style={{fontSize:10,color:DIM,background:'rgba(255,255,255,0.05)',padding:'2px 8px',borderRadius:20}}>{n.type?.toUpperCase()}</span>
                    <span style={{fontSize:10,color:DIM}}>📅 {n.createdAt?new Date(n.createdAt).toLocaleDateString():'-'}</span>
                  </div>
                  {n.description&&<div style={{fontSize:11,color:DIM,marginBottom:6,lineHeight:1.5}}>{n.description}</div>}
                  {n.url&&<a href={n.url} target="_blank" rel="noopener noreferrer" style={{fontSize:11,color:ACC,textDecoration:'none',display:'inline-flex',alignItems:'center',gap:4,background:'rgba(77,159,255,0.08)',padding:'4px 10px',borderRadius:8,border:'1px solid '+BOR2}}>🔗 Open Resource</a>}
                </div>
                <button onClick={()=>deleteNote(n._id,n.title)} style={bd2} className="bdt2">Delete</button>
              </div>
            ))}
            {!notes.length&&<div style={{textAlign:'center',padding:32,color:DIM}}>
              <div style={{fontSize:40,marginBottom:8}}>📚</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No materials added</div>
              <div style={{fontSize:11}}>Add PDFs, videos, docs, links above</div>
            </div>}
          </div>
        </div>}

        {/* ── ANALYTICS ── */}
        {!loading&&tab==='analytics'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:14}}>📈 Batch Analytics</div>
            {[{l:'Active Students',v:students.filter(s=>!s.banned).length,t:Math.max(students.length,1),c:SUC},{l:'Banned Students',v:students.filter(s=>s.banned).length,t:Math.max(students.length,1),c:DNG},{l:'Exams Assigned',v:exams.length,t:Math.max(allExams.length,1),c:WRN},{l:'Materials Added',v:notes.length,t:Math.max(notes.length,1),c:PRP}].map(x=>(
              <div key={x.l} style={{marginBottom:14}}>
                <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}><span style={{fontSize:12,color:TS,fontWeight:600}}>{x.l}</span><span style={{fontSize:11,color:DIM}}>{x.v}</span></div>
                <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>
                  <div style={{width:Math.round(x.v/x.t*100)+'%',height:'100%',background:'linear-gradient(90deg,'+x.c+','+x.c+'88)',borderRadius:8,transition:'width 1s ease'}}/>
                </div>
              </div>
            ))}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🏆 Student Roster</div>
            {students.map((s,i)=>(
              <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'7px 0',borderBottom:'1px solid '+BOR}}>
                <span style={{color:DIM,fontSize:12,minWidth:28}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':'#'+(i+1)}</span>
                <div style={{width:28,height:28,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}><div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</div><div style={{fontSize:10,color:DIM}}>{s.email}</div></div>
                <span style={{fontSize:10,color:s.banned?DNG:SUC,flexShrink:0}}>{s.banned?'🚫':'✅'}</span>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center',padding:24,color:DIM,fontSize:12}}>No students</div>}
          </div>
        </div>}

        {/* ── ANNOUNCE ── */}
        {!loading&&tab==='announce'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>📢 Send Announcement</div>
            <div style={{fontSize:11,color:DIM,marginBottom:14}}>To all <strong style={{color:ACC}}>{students.length} students</strong> in "{batch.name}"</div>
            <div style={{marginBottom:10}}>
              <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Title</label>
              <input value={annTitle} onChange={e=>setAnnTitle(e.target.value)} placeholder="e.g. Test Tomorrow at 10 AM" style={inp2}/>
            </div>
            <div style={{marginBottom:16}}>
              <label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Message</label>
              <textarea value={annMsg} onChange={e=>setAnnMsg(e.target.value)} placeholder="Write your announcement..." style={{...inp2,minHeight:110,resize:'vertical'}}/>
            </div>
            {(annTitle||annMsg)&&<div style={{background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:14,marginBottom:14}}>
              <div style={{fontSize:10,color:DIM,marginBottom:6,fontWeight:600,letterSpacing:0.4}}>PREVIEW</div>
              <div style={{fontWeight:700,fontSize:14,color:TS}}>{annTitle||'—'}</div>
              <div style={{fontSize:12,color:DIM,marginTop:4,whiteSpace:'pre-wrap'}}>{annMsg||'—'}</div>
            </div>}
            <button onClick={sendAnn} style={{...bp2,opacity:(!annTitle||!annMsg)?0.6:1}} className="bdt2">📢 Send to All Students</button>
          </div>
        </div>}

        {/* ── SETTINGS ── */}
        {!loading&&tab==='settings'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>✏️ Rename Batch</div>
            {!renaming?
              <div style={{display:'flex',gap:10,alignItems:'center'}}>
                <span style={{fontSize:15,fontWeight:700,color:ACC,flex:1}}>"{batch.name}"</span>
                <button onClick={()=>{setRenaming(true);setNewName(batch.name)}} style={bp2} className="bdt2">✏️ Rename</button>
              </div>:
              <div>
                <input value={newName} onChange={e=>setNewName(e.target.value)} onKeyDown={e=>e.key==='Enter'&&renameBatch()} style={{...inp2,marginBottom:10}}/>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={renameBatch} style={bp2} className="bdt2">💾 Save</button>
                  <button onClick={()=>setRenaming(false)} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'9px 16px',cursor:'pointer',fontSize:12}} className="bdt2">Cancel</button>
                </div>
              </div>}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>ℹ️ Batch Info</div>
            {([['Batch ID',batch._id],['Name',batch.name],['Students',students.length],['Exams',exams.length],['Materials',notes.length],['Created',batch.createdAt?new Date(batch.createdAt).toLocaleString():'-']] as [string,any][]).map(([k,v])=>(
              <div key={k} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid '+BOR,flexWrap:'wrap',gap:4}}>
                <span style={{fontSize:11,color:DIM,fontWeight:600}}>{k}</span>
                <span style={{fontSize:11,color:TS,fontFamily:'monospace'}}>{String(v)}</span>
              </div>
            ))}
          </div>
          <div style={{...cs2,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.03)'}}>
            <div style={{fontWeight:700,fontSize:13,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>
            <div style={{fontSize:11,color:DIM,marginBottom:12}}>Permanently deletes this batch and unassigns all students.</div>
            <button onClick={deleteBatch} style={{...bd2,padding:'10px 20px',fontSize:13}} className="bdt2">🗑️ Delete This Batch</button>
          </div>
        </div>}
      </div>
    </div>
  )
}`;

// Replace old component
c=c.slice(0,startIdx)+NEW_COMP+c.slice(endIdx);
fs.writeFileSync(fp,c);
console.log('Component replaced. Final size:',fs.statSync(fp).size);
FEJS

cd ~/workspace && git add . && git commit -m "feat: batch detail - Exams assign/unassign + Notes/Study Material S5/M3" && git push
echo ""
echo "DONE! Vercel deploy hone ke baad test karo:"
echo "Tabs: Overview | Students | Exams (assign!) | Materials (PDF/Video/Link) | Analytics | Announce | Settings"
