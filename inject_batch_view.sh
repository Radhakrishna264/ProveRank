#!/bin/bash
node << 'EOF'
const fs=require('fs');
const fp=process.env.HOME+'/workspace/frontend/app/admin/x7k2p/page.tsx';
let c=fs.readFileSync(fp,'utf8');

if(c.includes('// BATCH_DETAIL_VIEW_INJECTED')){console.log('Already done');process.exit(0);}

// ─── 1. ADD BATCH DETAIL FUNCTIONS after selectedBatch state ───
const funcToAdd=`
// BATCH_DETAIL_VIEW_INJECTED
const [bdStudents,setBdStudents]=useState<any[]>([])
const [bdExams,setBdExams]=useState<any[]>([])
const [bdLoading,setBdLoading]=useState(false)
const [bdTab,setBdTab]=useState('overview')
const [bdAddEmail,setBdAddEmail]=useState('')
const [bdAdding,setBdAdding]=useState(false)
const [bdSearch,setBdSearch]=useState('')
const [bdAnnTitle,setBdAnnTitle]=useState('')
const [bdAnnMsg,setBdAnnMsg]=useState('')
const [bdRenaming,setBdRenaming]=useState(false)
const [bdNewName,setBdNewName]=useState('')

const loadBatchDetail=useCallback(async(bId:string)=>{
  if(!token||!bId)return
  setBdLoading(true)
  try{
    const h={Authorization:'Bearer '+token}
    const[sr,er]=await Promise.all([
      fetch(API+'/api/admin/batches/'+bId+'/students',{headers:h}),
      fetch(API+'/api/admin/batches/'+bId+'/exams',{headers:h})
    ])
    if(sr.ok){const s=await sr.json();if(Array.isArray(s))setBdStudents(s)}
    if(er.ok){const e=await er.json();if(Array.isArray(e))setBdExams(e)}
  }catch(e){console.error(e)}
  setBdLoading(false)
},[token])

useEffect(()=>{if(selectedBatch)loadBatchDetail(selectedBatch._id)},[selectedBatch,loadBatchDetail])

const bdAddStudent=async()=>{
  if(!bdAddEmail.trim())return
  setBdAdding(true)
  try{
    const r=await fetch(API+'/api/admin/batches/'+selectedBatch._id+'/students/add',{
      method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
      body:JSON.stringify({studentEmail:bdAddEmail.trim()})
    })
    const d=await r.json()
    if(r.ok){T('Student added ✅','s');setBdAddEmail('');loadBatchDetail(selectedBatch._id)}
    else T(d.message||'Failed','e')
  }catch{T('Error','e')}finally{setBdAdding(false)}
}

const bdRemoveStudent=async(sid:string,name:string)=>{
  if(!window.confirm('Remove '+name+' from batch?'))return
  const r=await fetch(API+'/api/admin/batches/'+selectedBatch._id+'/students/'+sid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
  if(r.ok){T('Removed','s');setBdStudents(p=>p.filter((s:any)=>s._id!==sid))}else T('Failed','e')
}

const bdRenameBatch=async()=>{
  if(!bdNewName.trim())return
  const r=await fetch(API+'/api/admin/batches/'+selectedBatch._id,{
    method:'PATCH',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
    body:JSON.stringify({name:bdNewName.trim()})
  })
  const d=await r.json()
  if(r.ok){T('Renamed ✅','s');setSelectedBatch((p:any)=>({...p,name:bdNewName}));setBdRenaming(false);const idx=batches.findIndex((b:any)=>b._id===selectedBatch._id);if(idx>-1){const nb=[...batches];nb[idx]={...nb[idx],name:bdNewName};setBatches(nb)}}
  else T(d.message||'Failed','e')
}

const bdDeleteBatch=async()=>{
  if(!window.confirm('DELETE batch "'+selectedBatch?.name+'"? Cannot be undone.'))return
  const r=await fetch(API+'/api/admin/batches/'+selectedBatch._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
  if(r.ok){T('Deleted','s');setBatches((p:any[])=>p.filter((b:any)=>b._id!==selectedBatch._id));setSelectedBatch(null)}else T('Failed','e')
}

const bdSendAnn=async()=>{
  if(!bdAnnTitle||!bdAnnMsg){T('Fill all fields','e');return}
  const r=await fetch(API+'/api/admin/announcements',{
    method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
    body:JSON.stringify({title:bdAnnTitle,message:bdAnnMsg,batch:selectedBatch._id})
  })
  if(r.ok){T('Sent ✅','s');setBdAnnTitle('');setBdAnnMsg('')}else T('Failed','e')
}

const bdExportCSV=()=>{
  const rows=[['Name','Email','Phone','Joined'],...bdStudents.map((s:any)=>[s.name||'',s.email||'',s.phone||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():''])]
  const csv=rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\\n')
  const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='batch_students.csv';a.click();T('Exported ✅','s')
}
`;

c=c.replace(
  'const [selectedBatch,setSelectedBatch]=useState<any>(null)',
  'const [selectedBatch,setSelectedBatch]=useState<any>(null)'+funcToAdd
);
console.log('Functions injected:', c.includes('BATCH_DETAIL_VIEW_INJECTED'));

// ─── 2. INJECT RENDER before main return content ───
// Find the batches section render and add selectedBatch overlay before it
const BD_VIEW=`
{selectedBatch&&(()=>{
  const bdFiltered=bdStudents.filter((s:any)=>!bdSearch||s.name?.toLowerCase().includes(bdSearch.toLowerCase())||s.email?.toLowerCase().includes(bdSearch.toLowerCase()))
  const BDTABS=[{id:'overview',l:'📊 Overview'},{id:'students',l:'👥 Students ('+bdStudents.length+')'},{id:'exams',l:'📝 Exams ('+bdExams.length+')'},{id:'analytics',l:'📈 Analytics'},{id:'announce',l:'📢 Announce'},{id:'settings',l:'⚙️ Settings'}]
  return(
  <div style={{position:'fixed',inset:0,background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',zIndex:999,overflowY:'auto',fontFamily:'Inter,sans-serif'}}>
    <style>{'.bdt:hover{opacity:0.82} .bdr:hover{background:rgba(77,159,255,0.05)!important} @keyframes bds{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}'}</style>
    <div style={{position:'sticky',top:0,background:'rgba(0,10,24,0.95)',backdropFilter:'blur(16px)',borderBottom:'1px solid rgba(77,159,255,0.18)',padding:'12px 16px',zIndex:10}}>
      <div style={{maxWidth:900,margin:'0 auto'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap',marginBottom:10}}>
          <button onClick={()=>{setSelectedBatch(null);setBdTab('overview');setBdStudents([]);setBdExams([])}} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.3)',borderRadius:8,padding:'7px 12px',cursor:'pointer',fontSize:12,fontWeight:600}} className="bdt">← Back</button>
          <div style={{flex:1}}>
            <div style={{fontSize:18,fontWeight:800,fontFamily:'Playfair Display,serif',background:'linear-gradient(90deg,#4D9FFF,#A8D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>📦 {selectedBatch.name}</div>
            <div style={{fontSize:10,color:'#6B8FAF',marginTop:1}}>ID: {selectedBatch._id} · {selectedBatch.createdAt?new Date(selectedBatch.createdAt).toLocaleDateString():'-'}</div>
          </div>
          <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:'#4D9FFF',padding:'4px 10px',borderRadius:20,border:'1px solid rgba(77,159,255,0.3)'}}>👥 {bdStudents.length}</span>
          <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:'#00C48C',padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)'}}>📝 {bdExams.length}</span>
        </div>
        <div style={{display:'flex',gap:4,overflowX:'auto',paddingBottom:2}}>
          {BDTABS.map((t:any)=>(<button key={t.id} onClick={()=>setBdTab(t.id)} style={{background:bdTab===t.id?'rgba(77,159,255,0.18)':'transparent',border:'1px solid '+(bdTab===t.id?'rgba(77,159,255,0.3)':'transparent'),color:bdTab===t.id?'#4D9FFF':'#6B8FAF',borderRadius:8,padding:'6px 11px',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap',transition:'all 0.2s'}} className="bdt">{t.l}</button>))}
        </div>
      </div>
    </div>
    <div style={{maxWidth:900,margin:'0 auto',padding:'16px 14px'}}>
      {bdLoading&&<div style={{textAlign:'center',padding:40,color:'#6B8FAF'}}>Loading...</div>}
      {!bdLoading&&bdTab==='overview'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:14}}>
          {([{i:'👥',l:'Students',v:bdStudents.length,c:'#4D9FFF'},{i:'📝',l:'Exams',v:bdExams.length,c:'#FFB84D'},{i:'✅',l:'Active',v:bdStudents.filter((s:any)=>!s.banned).length,c:'#00C48C'},{i:'🚫',l:'Banned',v:bdStudents.filter((s:any)=>s.banned).length,c:'#FF4D4D'}] as any[]).map((x:any)=>(
            <div key={x.l} style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:'16px 12px',flex:1,minWidth:90,textAlign:'center'}}>
              <div style={{fontSize:22,marginBottom:4}}>{x.i}</div>
              <div style={{fontSize:22,fontWeight:800,color:x.c,fontFamily:'Playfair Display,serif'}}>{x.v}</div>
              <div style={{fontSize:10,color:'#6B8FAF',marginTop:2,fontWeight:600}}>{x.l}</div>
            </div>
          ))}
        </div>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18,marginBottom:14}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:10}}>⚡ Quick Actions</div>
          <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            <button onClick={()=>setBdTab('students')} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">👥 Students</button>
            <button onClick={()=>setBdTab('announce')} style={{background:'linear-gradient(135deg,#7C3AED,#4C1D95)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">📢 Announce</button>
            <button onClick={bdExportCSV} style={{background:'rgba(0,196,140,0.12)',color:'#00C48C',border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">📤 Export CSV</button>
          </div>
        </div>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:10}}>🕐 Recent Students</div>
          {bdStudents.slice(0,5).map((s:any)=>(<div key={s._id} className="bdr" style={{display:'flex',alignItems:'center',gap:10,padding:'8px 6px',borderRadius:8}}>
            <div style={{width:30,height:30,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid rgba(77,159,255,0.3)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:'#4D9FFF',flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
            <div style={{flex:1}}><div style={{fontSize:12,fontWeight:600,color:'#E8F4FF'}}>{s.name||'—'}</div><div style={{fontSize:10,color:'#6B8FAF'}}>{s.email}</div></div>
            <div style={{fontSize:10,color:'#6B8FAF'}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>
          </div>))}
          {!bdStudents.length&&<div style={{textAlign:'center',padding:24,color:'#6B8FAF',fontSize:12}}>No students yet</div>}
        </div>
      </div>}
      {!bdLoading&&bdTab==='students'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18}}>
          <div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
            <input value={bdSearch} onChange={(e:any)=>setBdSearch(e.target.value)} placeholder="Search..." style={{padding:'9px 12px',background:'rgba(0,22,40,0.85)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',flex:1,maxWidth:240}}/>
            <button onClick={bdExportCSV} style={{background:'rgba(0,196,140,0.12)',color:'#00C48C',border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,padding:'9px 14px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">📤 Export</button>
          </div>
          <div style={{background:'rgba(77,159,255,0.05)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:10,padding:12,marginBottom:12}}>
            <div style={{fontSize:11,fontWeight:700,color:'#4D9FFF',marginBottom:8}}>➕ Add by Email</div>
            <div style={{display:'flex',gap:8}}>
              <input value={bdAddEmail} onChange={(e:any)=>setBdAddEmail(e.target.value)} onKeyDown={(e:any)=>e.key==='Enter'&&bdAddStudent()} placeholder="student@email.com" style={{flex:1,padding:'9px 12px',background:'rgba(0,22,40,0.85)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none'}}/>
              <button onClick={bdAddStudent} disabled={bdAdding} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:13,opacity:bdAdding?0.7:1}} className="bdt">{bdAdding?'...':'Add'}</button>
            </div>
          </div>
          {bdFiltered.length?(<div style={{overflowX:'auto'}}>
            <table style={{width:'100%',borderCollapse:'collapse',fontSize:12}}>
              <thead><tr style={{borderBottom:'1px solid rgba(77,159,255,0.18)'}}>
                {['#','Name','Email','Joined',''].map((h:string)=><th key={h} style={{padding:'8px',textAlign:'left',color:'#6B8FAF',fontWeight:600,fontSize:10}}>{h}</th>)}
              </tr></thead>
              <tbody>{bdFiltered.map((s:any,i:number)=>(<tr key={s._id} className="bdr" style={{borderBottom:'1px solid rgba(77,159,255,0.1)'}}>
                <td style={{padding:'9px 8px',color:'#6B8FAF'}}>{i+1}</td>
                <td style={{padding:'9px 8px'}}><div style={{display:'flex',alignItems:'center',gap:7}}><div style={{width:26,height:26,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:'#4D9FFF'}}>{(s.name||'?')[0].toUpperCase()}</div><span style={{color:'#E8F4FF',fontWeight:600}}>{s.name||'—'}</span></div></td>
                <td style={{padding:'9px 8px',color:'#6B8FAF',fontSize:11}}>{s.email}</td>
                <td style={{padding:'9px 8px',color:'#6B8FAF',whiteSpace:'nowrap'}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
                <td style={{padding:'9px 8px'}}><button onClick={()=>bdRemoveStudent(s._id,s.name||s.email)} style={{background:'rgba(255,77,77,0.15)',color:'#FF4D4D',border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'5px 12px',cursor:'pointer',fontWeight:700,fontSize:11}} className="bdt">Remove</button></td>
              </tr>))}</tbody>
            </table>
          </div>):<div style={{textAlign:'center',padding:32,color:'#6B8FAF'}}><div style={{fontSize:40,marginBottom:8}}>👥</div><div style={{fontSize:13,fontWeight:600,color:'#E8F4FF',marginBottom:4}}>No students</div></div>}
        </div>
      </div>}
      {!bdLoading&&bdTab==='exams'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:10}}>📝 Assigned Exams ({bdExams.length})</div>
          {bdExams.map((e:any)=>(<div key={e._id} style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:12,padding:14,marginBottom:10}}>
            <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>{e.title}</div>
            <div style={{display:'flex',gap:8,marginTop:6,flexWrap:'wrap'}}>
              <span style={{fontSize:10,color:'#4D9FFF'}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
              <span style={{fontSize:10,color:'#6B8FAF'}}>⏱ {e.duration||'-'} min</span>
              <span style={{fontSize:10,color:e.status==='active'?'#00C48C':'#FFB84D'}}>{e.status||'draft'}</span>
            </div>
          </div>))}
          {!bdExams.length&&<div style={{textAlign:'center',padding:32,color:'#6B8FAF',fontSize:12}}>No exams assigned</div>}
        </div>
      </div>}
      {!bdLoading&&bdTab==='analytics'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18,marginBottom:14}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:14}}>📈 Batch Analytics</div>
          {([{l:'Active Students',v:bdStudents.filter((s:any)=>!s.banned).length,t:bdStudents.length,c:'#00C48C'},{l:'Banned',v:bdStudents.filter((s:any)=>s.banned).length,t:bdStudents.length,c:'#FF4D4D'}] as any[]).map((x:any)=>(<div key={x.l} style={{marginBottom:14}}><div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}><span style={{fontSize:12,color:'#E8F4FF',fontWeight:600}}>{x.l}</span><span style={{fontSize:11,color:'#6B8FAF'}}>{x.v}/{x.t}</span></div><div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}><div style={{width:(x.t>0?Math.round(x.v/x.t*100):0)+'%',height:'100%',background:'linear-gradient(90deg,'+x.c+','+x.c+'88)',borderRadius:8}}/></div></div>))}
        </div>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18}}>
          {bdStudents.map((s:any,i:number)=>(<div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.1)'}}><span style={{color:'#6B8FAF',fontSize:12,minWidth:24}}>#{i+1}</span><div style={{width:28,height:28,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:'#4D9FFF'}}>{(s.name||'?')[0].toUpperCase()}</div><div style={{flex:1}}><div style={{fontSize:12,fontWeight:600,color:'#E8F4FF'}}>{s.name||'—'}</div><div style={{fontSize:10,color:'#6B8FAF'}}>{s.email}</div></div><span style={{fontSize:10,color:s.banned?'#FF4D4D':'#00C48C'}}>{s.banned?'🚫':'✅'}</span></div>))}
          {!bdStudents.length&&<div style={{textAlign:'center',padding:24,color:'#6B8FAF',fontSize:12}}>No students</div>}
        </div>
      </div>}
      {!bdLoading&&bdTab==='announce'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:4}}>📢 Announcement</div>
          <div style={{fontSize:11,color:'#6B8FAF',marginBottom:14}}>To <strong style={{color:'#4D9FFF'}}>{bdStudents.length} students</strong> in {selectedBatch.name}</div>
          <div style={{marginBottom:10}}><label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Title</label><input value={bdAnnTitle} onChange={(e:any)=>setBdAnnTitle(e.target.value)} placeholder="Title" style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',boxSizing:'border-box'}}/></div>
          <div style={{marginBottom:14}}><label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:4,fontWeight:600,textTransform:'uppercase',letterSpacing:0.5}}>Message</label><textarea value={bdAnnMsg} onChange={(e:any)=>setBdAnnMsg(e.target.value)} placeholder="Message..." style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',minHeight:100,resize:'vertical',boxSizing:'border-box'}}/></div>
          <button onClick={bdSendAnn} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13,opacity:(!bdAnnTitle||!bdAnnMsg)?0.6:1}} className="bdt">📢 Send</button>
        </div>
      </div>}
      {!bdLoading&&bdTab==='settings'&&<div style={{animation:'bds 0.3s ease'}}>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18,marginBottom:14}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:10}}>✏️ Rename Batch</div>
          {!bdRenaming?<div style={{display:'flex',gap:10,alignItems:'center'}}><span style={{fontSize:15,fontWeight:700,color:'#4D9FFF',flex:1}}>"{selectedBatch.name}"</span><button onClick={()=>{setBdRenaming(true);setBdNewName(selectedBatch.name)}} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">Rename</button></div>:<div><input value={bdNewName} onChange={(e:any)=>setBdNewName(e.target.value)} onKeyDown={(e:any)=>e.key==='Enter'&&bdRenameBatch()} style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:10,color:'#E8F4FF',fontSize:13,outline:'none',marginBottom:10,boxSizing:'border-box'}}/><div style={{display:'flex',gap:8}}><button onClick={bdRenameBatch} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bdt">Save</button><button onClick={()=>setBdRenaming(false)} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.3)',borderRadius:8,padding:'9px 16px',cursor:'pointer',fontSize:12}} className="bdt">Cancel</button></div></div>}
        </div>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(77,159,255,0.18)',borderRadius:14,padding:18,marginBottom:14}}>
          <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',marginBottom:10}}>ℹ️ Info</div>
          {([['ID',selectedBatch._id],['Name',selectedBatch.name],['Students',bdStudents.length],['Exams',bdExams.length],['Created',selectedBatch.createdAt?new Date(selectedBatch.createdAt).toLocaleString():'-']] as [string,any][]).map(([k,v])=>(<div key={k} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid rgba(77,159,255,0.1)',flexWrap:'wrap',gap:4}}><span style={{fontSize:11,color:'#6B8FAF',fontWeight:600}}>{k}</span><span style={{fontSize:11,color:'#E8F4FF',fontFamily:'monospace'}}>{String(v)}</span></div>))}
        </div>
        <div style={{background:'rgba(0,22,40,0.75)',border:'1px solid rgba(255,77,77,0.25)',borderRadius:14,padding:18}}>
          <div style={{fontWeight:700,fontSize:13,color:'#FF4D4D',marginBottom:4}}>🚨 Danger Zone</div>
          <div style={{fontSize:11,color:'#6B8FAF',marginBottom:12}}>Permanently deletes batch and unassigns all students.</div>
          <button onClick={bdDeleteBatch} style={{background:'rgba(255,77,77,0.15)',color:'#FF4D4D',border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13}} className="bdt">🗑️ Delete Batch</button>
        </div>
      </div>}
    </div>
  </div>)
})()}
`;

// Find a good injection point — right before the closing of the main return
// Look for the batch section render to inject BEFORE main return
const INJECT_BEFORE='// BATCH_DETAIL_VIEW_INJECTED';
// We need to inject in the JSX return. Find the outermost div start in return
// Safe approach: add after the toast notification render
const toastPattern=/{toast&&(<div|{toast &&(<div/;
if(!c.includes('// BD_RENDER_DONE')){
  // Find where batches section is rendered and add the overlay there
  // Look for the batches section wrapper
  let injected=false;

  // Strategy: find the section that renders batches list and add overlay before it
  // The batch cards section should have "All Batches" or similar text
  const markers=[
    'All Batches',
    'allBatches',
    'batches.map(',
    '(batches||[]).map(',
    '{batches.map',
    'batch-manager',
    'Batch Manager',
  ];
  
  for(const m of markers){
    const idx=c.indexOf(m);
    if(idx>-1){
      // Find the closest JSX opening tag before this marker (within last 500 chars)
      const before=c.slice(Math.max(0,idx-200),idx);
      // Find a safe spot - look for a div start
      const divIdx=c.lastIndexOf('<div',idx);
      if(divIdx>-1 && divIdx>idx-500){
        // Check if we're inside a render section
        c=c.slice(0,divIdx)+BD_VIEW+c.slice(divIdx);
        c=c.replace(BD_VIEW,BD_VIEW+'\n// BD_RENDER_DONE\n');
        injected=true;
        console.log('Injected at marker:',m,'pos:',divIdx);
        break;
      }
    }
  }
  
  if(!injected){
    // Fallback: find return( and inject at start of JSX
    const retIdx=c.lastIndexOf('return (');
    if(retIdx>-1){
      const afterReturn=c.indexOf('\n',retIdx)+1;
      c=c.slice(0,afterReturn)+BD_VIEW+'\n// BD_RENDER_DONE\n'+c.slice(afterReturn);
      injected=true;
      console.log('Injected at return, pos:',afterReturn);
    }
  }
  
  if(!injected) console.log('WARNING: Could not find injection point. Manual check needed.');
}

fs.writeFileSync(fp,c);
console.log('Final size:',fs.statSync(fp).size);
console.log('BD_RENDER_DONE:',c.includes('BD_RENDER_DONE'));
EOF

cd ~/workspace && git add . && git commit -m "feat: batch detail inline overlay view S5/M3" && git push
echo "Done!"
