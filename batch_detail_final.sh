#!/bin/bash
# ProveRank — Batch Detail Inline Overlay (S5/M3)
# Upload this file to Replit and run: bash batch_detail_final.sh

node << 'JSEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// ── STEP 1: Remove old test/broken batch route page ──
const batchDir = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/batch';
try {
  const rmrf = (d) => {
    if (!fs.existsSync(d)) return;
    fs.readdirSync(d).forEach(f => {
      const p = d + '/' + f;
      fs.statSync(p).isDirectory() ? rmrf(p) : fs.unlinkSync(p);
    });
    fs.rmdirSync(d);
  };
  rmrf(batchDir);
  console.log('Removed old batch route dir');
} catch(e) { console.log('batch dir cleanup:', e.message); }

// ── STEP 2: Add selectedBatch state (if missing) ──
if (!c.includes('selectedBatch')) {
  c = c.replace(
    'const [batches,setBatches]=useState<Batch[]>([])',
    'const [batches,setBatches]=useState<Batch[]>([])\n  const [selectedBatch,setSelectedBatch]=useState<any>(null)'
  );
  if (!c.includes('selectedBatch')) {
    // Try alternate spacing
    c = c.replace(
      'const [batches, setBatches] = useState<Batch[]>([])',
      'const [batches, setBatches] = useState<Batch[]>([])\n  const [selectedBatch,setSelectedBatch]=useState<any>(null)'
    );
  }
  console.log('selectedBatch state:', c.includes('selectedBatch') ? 'added' : 'FAILED - manual needed');
} else {
  console.log('selectedBatch state: already exists');
}

// ── STEP 3: Fix batch card click handler ──
const clickPatterns = [
  "onClick={()=>{ window.location.href='/admin/x7k2p/batch/'+b._id }}",
  "onClick={()=>setSelectedBatch(b)}",
];
let clickFixed = c.includes("onClick={()=>setSelectedBatch(b)}");
if (!clickFixed) {
  // Try to find and replace window.location approach
  c = c.replace(
    /onClick=\{[^}]*window\.location\.href[^}]*\}/,
    "onClick={()=>setSelectedBatch(b)}"
  );
  clickFixed = c.includes("onClick={()=>setSelectedBatch(b)}");
  if (!clickFixed) {
    // Try router.push approach
    c = c.replace(
      /onClick=\{[^}]*router\.push[^}]*batchId[^}]*\}/,
      "onClick={()=>setSelectedBatch(b)}"
    );
    clickFixed = c.includes("onClick={()=>setSelectedBatch(b)}");
  }
}
console.log('Click handler fixed:', clickFixed);

// ── STEP 4: Inject overlay call in JSX (if missing) ──
if (!c.includes('BD_OVERLAY_INJECTED')) {
  const retIdx = c.lastIndexOf('return (');
  if (retIdx > -1) {
    const insertAt = c.indexOf('\n', retIdx) + 1;
    const overlay = `{/* BD_OVERLAY_INJECTED */}
{selectedBatch != null && <BatchDetailOverlay
  batch={selectedBatch}
  token={token}
  API={API}
  onClose={()=>setSelectedBatch(null)}
  onBatchDelete={(id:string)=>{setBatches((p:Batch[])=>p.filter((b:Batch)=>b._id!==id));setSelectedBatch(null)}}
  onBatchRename={(id:string,name:string)=>{setBatches((p:Batch[])=>p.map((b:Batch)=>b._id===id?{...b,name}:b));setSelectedBatch((p:any)=>({...p,name}))}}
  T={T}
/>}
`;
    c = c.slice(0, insertAt) + overlay + c.slice(insertAt);
    console.log('Overlay call injected at pos:', insertAt);
  } else {
    console.log('ERROR: Could not find return statement');
  }
}

// ── STEP 5: Add BatchDetailOverlay component at end of file ──
if (!c.includes('function BatchDetailOverlay')) {
  const COMP = `

// ═══════════════════════════════════════════════════
// BatchDetailOverlay — S5/M3 Inline Batch Detail View
// ═══════════════════════════════════════════════════
function BatchDetailOverlay({batch,token,API,onClose,onBatchDelete,onBatchRename,T}:{
  batch:any,token:string,API:string,onClose:()=>void,
  onBatchDelete:(id:string)=>void,onBatchRename:(id:string,name:string)=>void,T:(m:string,t?:any)=>void
}){
  const[tab,setTab]=useState('overview')
  const[students,setStudents]=useState<any[]>([])
  const[exams,setExams]=useState<any[]>([])
  const[loading,setLoading]=useState(false)
  const[addEmail,setAddEmail]=useState('')
  const[adding,setAdding]=useState(false)
  const[search,setSearch]=useState('')
  const[annTitle,setAnnTitle]=useState('')
  const[annMsg,setAnnMsg]=useState('')
  const[renaming,setRenaming]=useState(false)
  const[newName,setNewName]=useState('')
  const ACC='#4D9FFF',TS='#E8F4FF',DIM='#6B8FAF',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D'
  const BOR='rgba(77,159,255,0.18)',BOR2='rgba(77,159,255,0.3)',CRD='rgba(0,22,40,0.75)'
  const bp2:any={background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
  const bd2:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12}
  const inp2:any={width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box'as const}
  const cs2:any={background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}

  useEffect(()=>{
    if(!batch||!token)return
    setLoading(true);setStudents([]);setExams([]);setTab('overview')
    const h={Authorization:'Bearer '+token}
    Promise.all([
      fetch(API+'/api/admin/batches/'+batch._id+'/students',{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[]),
      fetch(API+'/api/admin/batches/'+batch._id+'/exams',{headers:h}).then(r=>r.ok?r.json():[]).catch(()=>[])
    ]).then(([s,e])=>{setStudents(Array.isArray(s)?s:[]);setExams(Array.isArray(e)?e:[])}).finally(()=>setLoading(false))
  },[batch,token,API])

  const addStudent=async()=>{
    if(!addEmail.trim()){T('Enter email','e');return}
    setAdding(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/add',{method:'POST',
        headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
        body:JSON.stringify({studentEmail:addEmail.trim()})})
      const d=await r.json()
      if(r.ok){T('Student added ✅','s');setAddEmail('');setStudents(p=>[...p,d.student].filter(Boolean))}
      else T(d.message||'Failed','e')
    }catch{T('Network error','e')}finally{setAdding(false)}
  }

  const removeStudent=async(sid:string,name:string)=>{
    if(!window.confirm('Remove '+name+' from batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id+'/students/'+sid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Removed','s');setStudents(p=>p.filter(s=>s._id!==sid))}else T('Failed','e')
  }

  const renameBatch=async()=>{
    if(!newName.trim())return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'PATCH',
      headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
      body:JSON.stringify({name:newName.trim()})})
    const d=await r.json()
    if(r.ok){T('Renamed ✅','s');onBatchRename(batch._id,newName.trim());setRenaming(false)}
    else T(d.message||'Failed','e')
  }

  const deleteBatch=async()=>{
    if(!window.confirm('DELETE "'+batch.name+'"?\\nAll students will be unassigned. Cannot be undone.'))return
    const r=await fetch(API+'/api/admin/batches/'+batch._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted','s');onBatchDelete(batch._id)}else T('Failed','e')
  }

  const sendAnn=async()=>{
    if(!annTitle||!annMsg){T('Fill all fields','e');return}
    const r=await fetch(API+'/api/admin/announcements',{method:'POST',
      headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
      body:JSON.stringify({title:annTitle,message:annMsg,batch:batch._id})})
    if(r.ok){T('Sent ✅','s');setAnnTitle('');setAnnMsg('')}else T('Failed','e')
  }

  const exportCSV=()=>{
    const rows=[['Name','Email','Phone','Joined'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():''])]
    const csv=rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\\n')
    const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='batch_'+batch.name+'.csv';a.click();T('Exported ✅','s')
  }

  const filtered=students.filter(s=>!search||s.name?.toLowerCase().includes(search.toLowerCase())||s.email?.toLowerCase().includes(search.toLowerCase()))
  const TABS=[{id:'overview',l:'📊 Overview'},{id:'students',l:'👥 Students ('+students.length+')'},{id:'exams',l:'📝 Exams ('+exams.length+')'},{id:'analytics',l:'📈 Analytics'},{id:'announce',l:'📢 Announce'},{id:'settings',l:'⚙️ Settings'}]

  return(
    <div style={{position:'fixed',inset:0,background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',zIndex:998,overflowY:'auto',fontFamily:'Inter,sans-serif'}}>
      <style>{'.bdt2:hover{opacity:0.82} .bdr2:hover{background:rgba(77,159,255,0.05)!important} @keyframes bds{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}'}</style>

      {/* ── HEADER ── */}
      <div style={{position:'sticky',top:0,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(16px)',borderBottom:'1px solid '+BOR,padding:'12px 16px',zIndex:10}}>
        <div style={{maxWidth:900,margin:'0 auto'}}>
          <div style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap',marginBottom:10}}>
            <button onClick={onClose} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'7px 12px',cursor:'pointer',fontSize:12,fontWeight:600}} className="bdt2">← Back</button>
            <div style={{flex:1,minWidth:0}}>
              <div style={{fontSize:18,fontWeight:800,fontFamily:'Playfair Display,serif',background:'linear-gradient(90deg,'+ACC+',#A8D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>📦 {batch.name}</div>
              <div style={{fontSize:10,color:DIM,marginTop:1}}>ID: {batch._id} · {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</div>
            </div>
            <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:ACC,padding:'4px 10px',borderRadius:20,border:'1px solid '+BOR2,flexShrink:0}}>👥 {students.length}</span>
            <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:SUC,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)',flexShrink:0}}>📝 {exams.length}</span>
          </div>
          <div style={{display:'flex',gap:4,overflowX:'auto',paddingBottom:2}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setTab(t.id)} className="bdt2" style={{background:tab===t.id?'rgba(77,159,255,0.18)':'transparent',border:'1px solid '+(tab===t.id?BOR2:'transparent'),color:tab===t.id?ACC:DIM,borderRadius:8,padding:'6px 10px',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap',transition:'all 0.2s',fontFamily:'Inter,sans-serif'}}>{t.l}</button>
            ))}
          </div>
        </div>
      </div>

      {/* ── CONTENT ── */}
      <div style={{maxWidth:900,margin:'0 auto',padding:'16px 14px'}}>
        {loading&&<div style={{textAlign:'center',padding:48,color:DIM}}>
          <div style={{width:36,height:36,border:'3px solid '+BOR2,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite',margin:'0 auto 12px'}}/>
          <div style={{fontSize:13}}>Loading batch data...</div>
        </div>}

        {/* OVERVIEW */}
        {!loading&&tab==='overview'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:14}}>
            {[{i:'👥',l:'Students',v:students.length,c:ACC},{i:'📝',l:'Exams',v:exams.length,c:WRN},{i:'✅',l:'Active',v:students.filter(s=>!s.banned).length,c:SUC},{i:'🚫',l:'Banned',v:students.filter(s=>s.banned).length,c:DNG}].map(x=>(
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
              <button onClick={()=>setTab('students')} style={bp2} className="bdt2">👥 Manage Students</button>
              <button onClick={()=>setTab('announce')} style={{...bp2,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bdt2">📢 Announce</button>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export CSV</button>
            </div>
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🕐 Recent Students</div>
            {students.slice(0,5).map(s=>(
              <div key={s._id} className="bdr2" style={{display:'flex',alignItems:'center',gap:10,padding:'8px 6px',borderRadius:8}}>
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

        {/* STUDENTS */}
        {!loading&&tab==='students'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
              <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="🔍 Search name/email" style={{...inp2,maxWidth:240,padding:'9px 12px'}}/>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,padding:'9px 14px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt2">📤 Export</button>
              <span style={{marginLeft:'auto',fontSize:11,color:DIM,alignSelf:'center'}}>{filtered.length} students</span>
            </div>
            <div style={{background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:12,marginBottom:12}}>
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
                    {['#','Name','Email','Joined','Action'].map(h=><th key={h} style={{padding:'8px',textAlign:'left',color:DIM,fontWeight:600,fontSize:10,letterSpacing:0.4}}>{h}</th>)}
                  </tr></thead>
                  <tbody>{filtered.map((s,i)=>(
                    <tr key={s._id} className="bdr2" style={{borderBottom:'1px solid '+BOR}}>
                      <td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>
                      <td style={{padding:'9px 8px'}}>
                        <div style={{display:'flex',alignItems:'center',gap:7}}>
                          <div style={{width:26,height:26,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                          <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap'}}>{s.name||'—'}</span>
                          {s.banned&&<span style={{fontSize:9,background:'rgba(255,77,77,0.2)',color:DNG,padding:'2px 6px',borderRadius:10}}>BANNED</span>}
                        </div>
                      </td>
                      <td style={{padding:'9px 8px',color:DIM,fontSize:11}}>{s.email}</td>
                      <td style={{padding:'9px 8px',color:DIM,whiteSpace:'nowrap'}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
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

        {/* EXAMS */}
        {!loading&&tab==='exams'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>📝 Assigned Exams ({exams.length})</div>
            {exams.map(e=>(
              <div key={e._id} style={{...cs2,marginBottom:10}}>
                <div style={{fontWeight:700,fontSize:13,color:TS}}>{e.title}</div>
                <div style={{display:'flex',gap:8,marginTop:6,flexWrap:'wrap'}}>
                  <span style={{fontSize:10,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
                  <span style={{fontSize:10,color:DIM}}>⏱ {e.duration||'-'} min</span>
                  <span style={{fontSize:10,color:DIM}}>📊 {e.totalMarks||'-'} marks</span>
                  <span style={{fontSize:10,color:e.status==='active'?SUC:WRN,background:e.status==='active'?'rgba(0,196,140,0.12)':'rgba(255,184,77,0.12)',padding:'2px 8px',borderRadius:20}}>{e.status||'draft'}</span>
                </div>
              </div>
            ))}
            {!exams.length&&<div style={{textAlign:'center',padding:32,color:DIM,fontSize:12}}>No exams assigned to this batch</div>}
          </div>
        </div>}

        {/* ANALYTICS */}
        {!loading&&tab==='analytics'&&<div style={{animation:'bds 0.3s ease'}}>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:14}}>📈 Batch Analytics</div>
            {[{l:'Active Students',v:students.filter(s=>!s.banned).length,t:students.length,c:SUC},{l:'Banned Students',v:students.filter(s=>s.banned).length,t:students.length,c:DNG},{l:'Exams Assigned',v:exams.length,t:Math.max(exams.length,1),c:WRN}].map(x=>(
              <div key={x.l} style={{marginBottom:14}}>
                <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>
                  <span style={{fontSize:12,color:TS,fontWeight:600}}>{x.l}</span>
                  <span style={{fontSize:11,color:DIM}}>{x.v}/{x.t}</span>
                </div>
                <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>
                  <div style={{width:(x.t>0?Math.round(x.v/x.t*100):0)+'%',height:'100%',background:'linear-gradient(90deg,'+x.c+','+x.c+'88)',borderRadius:8,transition:'width 1s ease'}}/>
                </div>
              </div>
            ))}
          </div>
          <div style={cs2}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🏆 Student List</div>
            {students.map((s,i)=>(
              <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'7px 0',borderBottom:'1px solid '+BOR}}>
                <span style={{color:DIM,fontSize:12,minWidth:28}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':'#'+(i+1)}</span>
                <div style={{width:28,height:28,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'—'}</div>
                  <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                </div>
                <span style={{fontSize:10,color:s.banned?DNG:SUC,flexShrink:0}}>{s.banned?'🚫 Banned':'✅ Active'}</span>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center',padding:24,color:DIM,fontSize:12}}>No students enrolled</div>}
          </div>
        </div>}

        {/* ANNOUNCE */}
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
            <button onClick={sendAnn} style={{...bp2,opacity:(!annTitle||!annMsg)?0.6:1}} className="bdt2">📢 Send to Batch</button>
          </div>
        </div>}

        {/* SETTINGS */}
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
            {([['Batch ID',batch._id],['Name',batch.name],['Students',students.length],['Exams',exams.length],['Created',batch.createdAt?new Date(batch.createdAt).toLocaleString():'-']] as [string,any][]).map(([k,v])=>(
              <div key={k} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid '+BOR,flexWrap:'wrap',gap:4}}>
                <span style={{fontSize:11,color:DIM,fontWeight:600}}>{k}</span>
                <span style={{fontSize:11,color:TS,fontFamily:'monospace'}}>{String(v)}</span>
              </div>
            ))}
          </div>
          <div style={{...cs2,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.03)'}}>
            <div style={{fontWeight:700,fontSize:13,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>
            <div style={{fontSize:11,color:DIM,marginBottom:12}}>Permanently deletes this batch. All students will be unassigned.</div>
            <button onClick={deleteBatch} style={{...bd2,padding:'10px 20px',fontSize:13}} className="bdt2">🗑️ Delete This Batch</button>
          </div>
        </div>}
      </div>
    </div>
  )
}
`;
  c = c + COMP;
  console.log('BatchDetailOverlay component added');
} else {
  console.log('BatchDetailOverlay already exists');
}

fs.writeFileSync(fp, c);
console.log('File saved. Final size:', fs.statSync(fp).size);
console.log('BD_OVERLAY_INJECTED:', c.includes('BD_OVERLAY_INJECTED'));
console.log('BatchDetailOverlay:', c.includes('function BatchDetailOverlay'));
JSEOF

cd ~/workspace && git add . && git commit -m "feat: batch detail overlay inline S5/M3 complete" && git push
echo ""
echo "ALL DONE! Wait 2 min for Vercel, then click any batch card"
