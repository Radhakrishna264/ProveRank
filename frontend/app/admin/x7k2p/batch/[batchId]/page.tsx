'use client'
import {useState,useEffect,useCallback,useRef} from 'react'
import {useRouter,useParams} from 'next/navigation'
import {getToken,getRole} from '@/lib/auth'

const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'
const BG='radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)'
const CRD='rgba(0,22,40,0.75)'
const CRD2='rgba(0,31,58,0.85)'
const ACC='#4D9FFF'
const BOR='rgba(77,159,255,0.18)'
const BOR2='rgba(77,159,255,0.3)'
const TS='#E8F4FF'
const DIM='#6B8FAF'
const SUC='#00C48C'
const DNG='#FF4D4D'
const WRN='#FFB84D'
const GOLD='#FFD700'
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}
const inp:any={width:'100%',padding:'12px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid ${BOR2}`,borderRadius:10,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box' as any}
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:10,padding:'11px 22px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif',boxShadow:`0 4px 16px rgba(77,159,255,0.35)`}
const bd:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
const bs:any={background:'rgba(0,196,140,0.12)',color:SUC,border:`1px solid rgba(0,196,140,0.3)`,borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
const bg_:any={background:'rgba(77,159,255,0.1)',color:ACC,border:`1px solid ${BOR2}`,borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:600,fontSize:12,fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,letterSpacing:0.5,textTransform:'uppercase' as any,fontFamily:'Inter,sans-serif'}

function Stars(){
  const stars=Array.from({length:55},(_,i)=>({
    w:i%5===0?3:i%3===0?2:1,
    x:((i*137.508)%100).toFixed(2),
    y:((i*97.31)%100).toFixed(2),
    op:(0.08+((i*0.07)%0.45)).toFixed(2),
    dur:(2+(i%5)).toFixed(1)
  }))
  return <div style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none',overflow:'hidden'}}>
    {stars.map((s,i)=>(
      <div key={i} style={{position:'absolute',width:s.w,height:s.w,background:'white',borderRadius:'50%',
        left:`${s.x}%`,top:`${s.y}%`,opacity:Number(s.op),
        animation:`bdtwinkle ${s.dur}s ease-in-out infinite`,animationDelay:`${(i*0.11)%3}s`}}/>
    ))}
  </div>
}

function StatBox({ico,label,val,sub='',col=ACC}:{ico:string,label:string,val:any,sub?:string,col?:string}){
  return <div style={{background:CRD2,border:`1px solid ${BOR}`,borderRadius:14,padding:'18px 16px',flex:1,minWidth:130,backdropFilter:'blur(12px)',position:'relative',overflow:'hidden'}}>
    <div style={{position:'absolute',right:-8,bottom:-8,fontSize:44,opacity:0.06,pointerEvents:'none'}}>{ico}</div>
    <div style={{fontSize:24,marginBottom:6}}>{ico}</div>
    <div style={{fontSize:24,fontWeight:800,color:col,fontFamily:'Playfair Display,Georgia,serif',lineHeight:1}}>{val}</div>
    <div style={{fontSize:11,color:DIM,marginTop:4,fontWeight:600,letterSpacing:0.4}}>{label}</div>
    {sub&&<div style={{fontSize:10,color:col,marginTop:2,opacity:0.8}}>{sub}</div>}
  </div>
}

function ScoreBar({label,count,max,col}:{label:string,count:number,max:number,col:string}){
  const pct=max>0?Math.round((count/max)*100):0
  return <div style={{marginBottom:12}}>
    <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>
      <span style={{fontSize:12,color:TS,fontWeight:600}}>{label}</span>
      <span style={{fontSize:12,color:DIM}}>{count} students ({pct}%)</span>
    </div>
    <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>
      <div style={{width:`${pct}%`,height:'100%',background:`linear-gradient(90deg,${col},${col}88)`,borderRadius:8,transition:'width 1s ease'}}/>
    </div>
  </div>
}

export default function BatchDetailPage(){
  const router=useRouter()
  const params=useParams()
  const batchId=params?.batchId as string
  const [token,setToken]=useState('')
  const [tab,setTab]=useState('overview')
  const [batch,setBatch]=useState<any>(null)
  const [students,setStudents]=useState<any[]>([])
  const [exams,setExams]=useState<any[]>([])
  const [allExams,setAllExams]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const [searchQ,setSearchQ]=useState('')
  const [addOpen,setAddOpen]=useState(false)
  const [addInput,setAddInput]=useState('')
  const [addMode,setAddMode]=useState<'id'|'email'>('email')
  const [adding,setAdding]=useState(false)
  const [renaming,setRenaming]=useState(false)
  const [newName,setNewName]=useState('')
  const [saving,setSaving]=useState(false)
  const [annTitle,setAnnTitle]=useState('')
  const [annMsg,setAnnMsg]=useState('')
  const [annSending,setAnnSending]=useState(false)
  const [assignExamId,setAssignExamId]=useState('')
  const [toast,setToast]=useState<{msg:string,tp:'s'|'e'|'w'}|null>(null)
  const T=useCallback((msg:string,tp:'s'|'e'|'w'='s')=>{setToast({msg,tp});setTimeout(()=>setToast(null),4200)},[]) 
  const H=useCallback(()=>({Authorization:`Bearer ${token}`}),[token])
  const HJ=useCallback(()=>({'Content-Type':'application/json',Authorization:`Bearer ${token}`}),[token])

  useEffect(()=>{
    const t=getToken(),r=getRole()
    if(!t){console.warn('No token found');router.replace('/login');return}
    setToken(t)
  },[router])

  const fetchAll=useCallback(async()=>{
    if(!token||!batchId)return
    setLoading(true)
    const get=async(u:string)=>{try{const r=await fetch(u,{headers:H()});if(!r.ok){console.error('Fetch failed:',u,r.status);return null}return r.json()}catch(e){console.error('Fetch error:',u,e);return null}}
    const [b,st,ex,ae]=await Promise.all([
      get(`${API}/api/admin/batches/${batchId}`),
      get(`${API}/api/admin/batches/${batchId}/students`),
      get(`${API}/api/admin/batches/${batchId}/exams`),
      get(`${API}/api/exams`)
    ])
    if(b)setBatch(b);else console.warn('Batch not found for id:',batchId)
    if(Array.isArray(st))setStudents(st)
    if(Array.isArray(ex))setExams(ex)
    if(Array.isArray(ae))setAllExams(ae)
    setLoading(false)
  },[token,batchId,H])
  useEffect(()=>{if(token)fetchAll()},[token,fetchAll])

  const addStudent=async()=>{
    if(!addInput.trim()){T('Enter Student ID or Email','e');return}
    setAdding(true)
    try{
      const body=addMode==='id'?{studentId:addInput.trim()}:{studentEmail:addInput.trim()}
      const r=await fetch(`${API}/api/admin/batches/${batchId}/students/add`,{method:'POST',headers:HJ(),body:JSON.stringify(body)})
      const d=await r.json()
      if(r.ok){T('Student added to batch ✅');setAddInput('');setAddOpen(false);fetchAll()}
      else T(d.message||'Failed','e')
    }catch{T('Network error','e')}finally{setAdding(false)}
  }

  const removeStudent=async(sid:string,name:string)=>{
    if(!window.confirm(`Remove "${name}" from this batch?`))return
    try{
      const r=await fetch(`${API}/api/admin/batches/${batchId}/students/${sid}`,{method:'DELETE',headers:H()})
      if(r.ok){T('Student removed');setStudents(p=>p.filter(s=>s._id!==sid))}
      else T('Failed to remove','e')
    }catch{T('Network error','e')}
  }

  const renameBatch=async()=>{
    if(!newName.trim()){T('Enter a name','e');return}
    setSaving(true)
    try{
      const r=await fetch(`${API}/api/admin/batches/${batchId}`,{method:'PATCH',headers:HJ(),body:JSON.stringify({name:newName.trim()})})
      const d=await r.json()
      if(r.ok){T('Batch renamed ✅');setBatch((p:any)=>({...p,name:newName.trim()}));setRenaming(false)}
      else T(d.message||'Failed','e')
    }catch{T('Network error','e')}finally{setSaving(false)}
  }

  const deleteBatch=async()=>{
    if(!window.confirm(`DELETE batch "${batch?.name}"? All students will be unassigned. This cannot be undone.`))return
    if(!window.confirm('Are you absolutely sure? Type-confirm by pressing OK again.'))return
    try{
      const r=await fetch(`${API}/api/admin/batches/${batchId}`,{method:'DELETE',headers:H()})
      if(r.ok){T('Batch deleted');router.replace('/admin/x7k2p')}
      else T('Failed','e')
    }catch{T('Network error','e')}
  }

  const assignExam=async()=>{
    if(!assignExamId){T('Select an exam','e');return}
    try{
      const r=await fetch(`${API}/api/admin/batches/${batchId}/exams/assign`,{method:'POST',headers:HJ(),body:JSON.stringify({examId:assignExamId})})
      if(r.ok){T('Exam assigned ✅');setAssignExamId('');fetchAll()}
      else T('Failed','e')
    }catch{T('Network error','e')}
  }

  const unassignExam=async(eid:string,title:string)=>{
    if(!window.confirm(`Unassign "${title}" from this batch?`))return
    try{
      const r=await fetch(`${API}/api/admin/batches/${batchId}/exams/${eid}`,{method:'DELETE',headers:H()})
      if(r.ok){T('Exam unassigned');setExams(p=>p.filter(e=>e._id!==eid))}
      else T('Failed','e')
    }catch{T('Network error','e')}
  }

  const sendAnnouncement=async()=>{
    if(!annTitle.trim()||!annMsg.trim()){T('Enter title and message','e');return}
    setAnnSending(true)
    try{
      const r=await fetch(`${API}/api/admin/announcements`,{method:'POST',headers:HJ(),
        body:JSON.stringify({title:annTitle.trim(),message:annMsg.trim(),batch:batchId,targetBatch:batchId})})
      if(r.ok){T('Announcement sent ✅');setAnnTitle('');setAnnMsg('')}
      else T('Failed to send','e')
    }catch{T('Network error','e')}finally{setAnnSending(false)}
  }

  const exportCSV=()=>{
    if(!students.length){T('No students to export','w');return}
    const rows=[['Name','Email','Phone','Role','Joined','Batch'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.role||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():'',batch?.name||''])]
    const csv=rows.map(r=>r.map(v=>`"${String(v).replace(/"/g,'""')}"`).join(',')).join('\n')
    const a=document.createElement('a')
    a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv)
    a.download=`batch_${batch?.name||batchId}_students.csv`
    a.click()
    T('CSV exported ✅')
  }

  const filteredStudents=students.filter(s=>
    !searchQ||s.name?.toLowerCase().includes(searchQ.toLowerCase())||s.email?.toLowerCase().includes(searchQ.toLowerCase())
  )
  const recentStudents=students.slice().sort((a,b)=>new Date(b.createdAt||0).getTime()-new Date(a.createdAt||0).getTime()).slice(0,5)
  const unassignedExams=allExams.filter(ae=>!exams.find(e=>e._id===ae._id))

  const TABS=[
    {id:'overview',ico:'📊',label:'Overview'},
    {id:'students',ico:'👥',label:`Students (${students.length})`},
    {id:'exams',ico:'📝',label:`Exams (${exams.length})`},
    {id:'analytics',ico:'📈',label:'Analytics'},
    {id:'announce',ico:'📢',label:'Announce'},
    {id:'settings',ico:'⚙️',label:'Settings'},
  ]

  if(loading)return(
    <div style={{minHeight:'100vh',background:BG,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:16}}>
      <Stars/>
      <div style={{width:48,height:48,border:`3px solid ${BOR2}`,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite'}}/>
      <div style={{color:DIM,fontSize:13,fontFamily:'Inter,sans-serif'}}>Loading Batch...</div>
    </div>
  )

  if(!batch&&!loading)return(
    <div style={{minHeight:'100vh',background:BG,display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column',gap:16}}>
      <Stars/>
      <div style={{fontSize:48}}>📭</div>
      <div style={{color:TS,fontSize:16,fontWeight:700,fontFamily:'Inter,sans-serif'}}>Batch not found</div>
      <button onClick={()=>router.replace('/admin/x7k2p')} style={bp}>← Back to Admin</button>
    </div>
  )

  return(
    <div style={{minHeight:'100vh',background:BG,fontFamily:'Inter,sans-serif',position:'relative'}}>
      <Stars/>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:wght@700;800&display=swap');
        @keyframes bdtwinkle{0%,100%{opacity:0.1}50%{opacity:0.7}}
        @keyframes spin{to{transform:rotate(360deg)}}
        @keyframes fadein{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}
        @keyframes slideup{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        .bd-tab:hover{background:rgba(77,159,255,0.12)!important;border-color:rgba(77,159,255,0.4)!important}
        .bd-card:hover{border-color:rgba(77,159,255,0.3)!important;transform:translateY(-2px);transition:all 0.2s}
        .bd-btn:hover{opacity:0.85;transform:translateY(-1px)}
        .bd-row:hover{background:rgba(77,159,255,0.05)!important}
        ::-webkit-scrollbar{width:4px;height:4px}
        ::-webkit-scrollbar-track{background:transparent}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
      `}</style>
      {toast&&<div style={{position:'fixed',top:16,left:'50%',transform:'translateX(-50%)',zIndex:9999,
        background:toast.tp==='s'?'rgba(0,196,140,0.95)':toast.tp==='e'?'rgba(255,77,77,0.95)':'rgba(255,184,77,0.95)',
        color:'#fff',padding:'12px 24px',borderRadius:12,fontSize:13,fontWeight:700,
        boxShadow:'0 8px 32px rgba(0,0,0,0.4)',animation:'fadein 0.3s ease',whiteSpace:'nowrap'}}>{toast.msg}</div>}
      <div style={{position:'sticky',top:0,zIndex:100,background:'rgba(0,10,24,0.92)',backdropFilter:'blur(16px)',
        borderBottom:`1px solid ${BOR}`,padding:'12px 16px'}}>
        <div style={{maxWidth:900,margin:'0 auto'}}>
          <div style={{display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
            <button onClick={()=>router.push('/admin/x7k2p')} style={{...bg_,padding:'8px 14px',fontSize:12}} className="bd-btn">← Admin</button>
            <div style={{flex:1}}>
              <div style={{fontSize:20,fontWeight:800,fontFamily:'Playfair Display,serif',
                background:`linear-gradient(90deg,${ACC},#A8D4FF)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.2}}>
                📦 {batch?.name}
              </div>
              <div style={{fontSize:11,color:DIM,marginTop:2}}>Batch Manager · Created {batch?.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</div>
            </div>
            <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
              <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:ACC,padding:'4px 10px',borderRadius:20,border:`1px solid ${BOR2}`}}>👥 {students.length}</span>
              <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:SUC,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)'}}>📝 {exams.length}</span>
            </div>
          </div>
          <div style={{display:'flex',gap:4,marginTop:12,overflowX:'auto' as any,paddingBottom:4}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setTab(t.id)} className="bd-tab" style={{
                background:tab===t.id?`rgba(77,159,255,0.18)`:'transparent',
                border:`1px solid ${tab===t.id?BOR2:'transparent'}`,
                color:tab===t.id?ACC:DIM,borderRadius:8,padding:'7px 12px',cursor:'pointer',
                fontSize:12,fontWeight:600,whiteSpace:'nowrap' as any,fontFamily:'Inter,sans-serif',
                transition:'all 0.2s'}}>
                {t.ico} {t.label}
              </button>
            ))}
          </div>
        </div>
      </div>
      <div style={{maxWidth:900,margin:'0 auto',padding:'20px 16px',position:'relative',zIndex:1}}>
        {tab==='overview'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={{display:'flex',gap:12,flexWrap:'wrap',marginBottom:16}}>
            <StatBox ico="👥" label="Total Students" val={students.length} col={ACC}/>
            <StatBox ico="📝" label="Total Exams" val={exams.length} col={WRN}/>
            <StatBox ico="📅" label="Batch Age" val={batch?.createdAt?Math.floor((Date.now()-new Date(batch.createdAt).getTime())/(86400000))+' days':'-'} col={SUC}/>
            <StatBox ico="🏫" label="Batch ID" val={batchId?.slice(-6)} sub="Last 6 chars" col={GOLD}/>
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>🕐 Recently Added Students</div>
            {recentStudents.length?recentStudents.map(s=>(
              <div key={s._id} className="bd-row" style={{display:'flex',alignItems:'center',gap:10,padding:'10px 8px',borderRadius:8,transition:'all 0.15s'}}>
                <div style={{width:34,height:34,borderRadius:'50%',background:`linear-gradient(135deg,${ACC}44,${ACC}22)`,
                  border:`1px solid ${BOR2}`,display:'flex',alignItems:'center',justifyContent:'center',
                  fontSize:13,fontWeight:700,color:ACC,flexShrink:0}}>
                  {(s.name||'?')[0].toUpperCase()}
                </div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:13,fontWeight:600,color:TS,whiteSpace:'nowrap' as any,overflow:'hidden',textOverflow:'ellipsis'}}>{s.name||'—'}</div>
                  <div style={{fontSize:11,color:DIM,whiteSpace:'nowrap' as any,overflow:'hidden',textOverflow:'ellipsis'}}>{s.email}</div>
                </div>
                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>
              </div>
            )):<div style={{textAlign:'center' as any,padding:'30px',color:DIM,fontSize:12}}>No students added yet</div>}
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>⚡ Quick Actions</div>
            <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
              <button onClick={()=>setTab('students')} style={bp} className="bd-btn">👥 Manage Students</button>
              <button onClick={()=>setTab('exams')} style={bp} className="bd-btn">📝 Assign Exams</button>
              <button onClick={()=>setTab('announce')} style={{...bp,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bd-btn">📢 Announce</button>
              <button onClick={exportCSV} style={bs} className="bd-btn">📤 Export CSV</button>
            </div>
          </div>
        </div>}
        {tab==='students'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={{...cs,marginBottom:14}}>
            <div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap',marginBottom:12}}>
              <input value={searchQ} onChange={e=>setSearchQ(e.target.value)} placeholder="🔍 Search by name or email..." style={{...inp,maxWidth:320,padding:'10px 14px'}}/>
              <button onClick={()=>setAddOpen(p=>!p)} style={bp} className="bd-btn">➕ Add Student</button>
              <button onClick={exportCSV} style={bs} className="bd-btn">📤 Export CSV</button>
              <span style={{fontSize:12,color:DIM,marginLeft:'auto'}}>{filteredStudents.length} students</span>
            </div>
            {addOpen&&<div style={{background:'rgba(77,159,255,0.05)',border:`1px solid ${BOR2}`,borderRadius:10,padding:14,marginBottom:12}}>
              <div style={{fontSize:12,fontWeight:700,color:ACC,marginBottom:10}}>➕ Add Student to Batch</div>
              <div style={{display:'flex',gap:8,marginBottom:10}}>
                <button onClick={()=>setAddMode('email')} style={{...bg_,opacity:addMode==='email'?1:0.5}} className="bd-btn">By Email</button>
                <button onClick={()=>setAddMode('id')} style={{...bg_,opacity:addMode==='id'?1:0.5}} className="bd-btn">By Student ID</button>
              </div>
              <div style={{display:'flex',gap:8}}>
                <input value={addInput} onChange={e=>setAddInput(e.target.value)} 
                  onKeyDown={e=>e.key==='Enter'&&addStudent()}
                  placeholder={addMode==='email'?'student@email.com':'Student MongoDB ID'} 
                  style={{...inp,flex:1,padding:'10px 12px'}}/>
                <button onClick={addStudent} disabled={adding} style={{...bp,opacity:adding?0.7:1}} className="bd-btn">
                  {adding?'Adding...':'Add'}
                </button>
              </div>
            </div>}
            {filteredStudents.length?(
              <div style={{overflowX:'auto' as any}}>
                <table style={{width:'100%',borderCollapse:'collapse' as any,fontSize:12}}>
                  <thead>
                    <tr style={{borderBottom:`1px solid ${BOR}`}}>
                      {['#','Name','Email','Phone','Joined','Action'].map(h=>(
                        <th key={h} style={{padding:'8px 10px',textAlign:'left' as any,color:DIM,fontWeight:600,fontSize:11,letterSpacing:0.4}}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {filteredStudents.map((s,i)=>(
                      <tr key={s._id} className="bd-row" style={{borderBottom:`1px solid ${BOR}`,transition:'all 0.15s'}}>
                        <td style={{padding:'10px',color:DIM}}>{i+1}</td>
                        <td style={{padding:'10px'}}>
                          <div style={{display:'flex',alignItems:'center',gap:8}}>
                            <div style={{width:28,height:28,borderRadius:'50%',background:`linear-gradient(135deg,${ACC}44,${ACC}22)`,
                              border:`1px solid ${BOR2}`,display:'flex',alignItems:'center',justifyContent:'center',
                              fontSize:11,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                            <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap' as any}}>{s.name||'—'}</span>
                          </div>
                        </td>
                        <td style={{padding:'10px',color:DIM}}>{s.email}</td>
                        <td style={{padding:'10px',color:DIM}}>{s.phone||'—'}</td>
                        <td style={{padding:'10px',color:DIM,whiteSpace:'nowrap' as any}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
                        <td style={{padding:'10px'}}>
                          <button onClick={()=>removeStudent(s._id,s.name||s.email)} style={bd} className="bd-btn">Remove</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ):<div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>
              <div style={{fontSize:48,marginBottom:10}}>👥</div>
              <div style={{fontSize:14,fontWeight:600,color:TS,marginBottom:6}}>No students in this batch</div>
              <div style={{fontSize:12}}>Click "Add Student" to enroll students</div>
            </div>}
          </div>
        </div>}
        {tab==='exams'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>📌 Assign Exam to Batch</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
              <select value={assignExamId} onChange={e=>setAssignExamId(e.target.value)} style={{...inp,flex:1,maxWidth:400}}>
                <option value="">— Select exam to assign —</option>
                {unassignedExams.map(e=>(<option key={e._id} value={e._id}>{e.title}</option>))}
              </select>
              <button onClick={assignExam} style={bp} className="bd-btn">📌 Assign</button>
            </div>
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>📝 Assigned Exams ({exams.length})</div>
            {exams.length?exams.map(e=>(
              <div key={e._id} className="bd-card" style={{...cs,marginBottom:10,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{e.title}</div>
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:11,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
                    <span style={{fontSize:11,color:DIM}}>⏱️ {e.duration||'-'} min</span>
                    <span style={{fontSize:11,color:DIM}}>📊 {e.totalMarks||'-'} marks</span>
                    <span style={{fontSize:11,background:e.status==='active'?'rgba(0,196,140,0.15)':'rgba(255,184,77,0.15)',
                      color:e.status==='active'?SUC:WRN,padding:'2px 8px',borderRadius:20}}>{e.status||'draft'}</span>
                  </div>
                </div>
                <button onClick={()=>unassignExam(e._id,e.title)} style={bd} className="bd-btn">Unassign</button>
              </div>
            )):<div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>
              <div style={{fontSize:48,marginBottom:10}}>📝</div>
              <div style={{fontSize:14,fontWeight:600,color:TS,marginBottom:6}}>No exams assigned</div>
              <div style={{fontSize:12}}>Assign exams to this batch from above</div>
            </div>}
          </div>
        </div>}
        {tab==='analytics'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={{...cs,marginBottom:14}}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:4}}>📈 Batch Analytics</div>
            <div style={{fontSize:12,color:DIM,marginBottom:16}}>Based on student enrollment data</div>
            <div style={{display:'flex',gap:12,flexWrap:'wrap',marginBottom:20}}>
              <StatBox ico="👥" label="Enrolled" val={students.length} col={ACC}/>
              <StatBox ico="📝" label="Exams Linked" val={exams.length} col={WRN}/>
              <StatBox ico="📱" label="Active Students" val={students.filter(s=>!s.banned).length} col={SUC}/>
              <StatBox ico="🚫" label="Banned" val={students.filter(s=>s.banned).length} col={DNG}/>
            </div>
            <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:12}}>📊 Enrollment Distribution</div>
            <ScoreBar label="Active Students" count={students.filter(s=>!s.banned).length} max={Math.max(students.length,1)} col={SUC}/>
            <ScoreBar label="Banned Students" count={students.filter(s=>s.banned).length} max={Math.max(students.length,1)} col={DNG}/>
            <ScoreBar label="Exams Assigned" count={exams.length} max={Math.max(allExams.length,1)} col={WRN}/>
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>🏆 Enrolled Students — Quick View</div>
            {students.slice(0,10).map((s,i)=>(
              <div key={s._id} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 0',borderBottom:`1px solid ${BOR}`}}>
                <div style={{fontSize:16,width:28,textAlign:'center' as any}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':`#${i+1}`}</div>
                <div style={{width:30,height:30,borderRadius:'50%',background:`linear-gradient(135deg,${ACC}44,${ACC}22)`,
                  border:`1px solid ${BOR2}`,display:'flex',alignItems:'center',justifyContent:'center',
                  fontSize:12,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS}}>{s.name||'—'}</div>
                  <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                </div>
                <div style={{fontSize:11,color:s.banned?DNG:SUC}}>{s.banned?'🚫 Banned':'✅ Active'}</div>
              </div>
            ))}
            {students.length>10&&<div style={{textAlign:'center' as any,padding:'10px',fontSize:12,color:DIM}}>+{students.length-10} more students</div>}
            {!students.length&&<div style={{textAlign:'center' as any,padding:'30px',color:DIM,fontSize:12}}>No students enrolled yet</div>}
          </div>
        </div>}
        {tab==='announce'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:4}}>📢 Send Announcement</div>
            <div style={{fontSize:12,color:DIM,marginBottom:16}}>This announcement will be sent to all <strong style={{color:ACC}}>{students.length} students</strong> in batch "{batch?.name}"</div>
            <div style={{marginBottom:12}}>
              <label style={{display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Announcement Title</label>
              <input value={annTitle} onChange={e=>setAnnTitle(e.target.value)} placeholder="e.g. Test Tomorrow at 10 AM" style={inp}/>
            </div>
            <div style={{marginBottom:16}}>
              <label style={{display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Message</label>
              <textarea value={annMsg} onChange={e=>setAnnMsg(e.target.value)} 
                placeholder="Write your announcement here... (supports full message)" 
                style={{...inp,minHeight:120,resize:'vertical' as any}}/>
            </div>
            {(annTitle||annMsg)&&<div style={{background:'rgba(77,159,255,0.06)',border:`1px solid ${BOR}`,borderRadius:10,padding:14,marginBottom:14}}>
              <div style={{fontSize:11,color:DIM,marginBottom:6,fontWeight:600}}>PREVIEW</div>
              <div style={{fontWeight:700,fontSize:14,color:TS}}>{annTitle||'—'}</div>
              <div style={{fontSize:12,color:DIM,marginTop:4,whiteSpace:'pre-wrap' as any}}>{annMsg||'—'}</div>
            </div>}
            <button onClick={sendAnnouncement} disabled={annSending||!annTitle||!annMsg} 
              style={{...bp,opacity:(annSending||!annTitle||!annMsg)?0.6:1}} className="bd-btn">
              {annSending?'Sending...':'📢 Send to Batch'}
            </button>
          </div>
        </div>}
        {tab==='settings'&&<div style={{animation:'slideup 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>✏️ Rename Batch</div>
            {!renaming?(
              <div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap'}}>
                <div style={{fontSize:16,fontWeight:700,color:ACC,flex:1}}>"{batch?.name}"</div>
                <button onClick={()=>{setRenaming(true);setNewName(batch?.name||'')}} style={bp} className="bd-btn">✏️ Rename</button>
              </div>
            ):(
              <div>
                <input value={newName} onChange={e=>setNewName(e.target.value)} 
                  onKeyDown={e=>e.key==='Enter'&&renameBatch()}
                  placeholder="New batch name" style={{...inp,marginBottom:10}}/>
                <div style={{display:'flex',gap:8}}>
                  <button onClick={renameBatch} disabled={saving} style={{...bp,opacity:saving?0.7:1}} className="bd-btn">{saving?'Saving...':'💾 Save'}</button>
                  <button onClick={()=>setRenaming(false)} style={bg_} className="bd-btn">Cancel</button>
                </div>
              </div>
            )}
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>ℹ️ Batch Information</div>
            {[
              {k:'Batch ID',v:batchId},
              {k:'Created At',v:batch?.createdAt?new Date(batch.createdAt).toLocaleString():'-'},
              {k:'Last Updated',v:batch?.updatedAt?new Date(batch.updatedAt).toLocaleString():'-'},
              {k:'Total Students',v:students.length},
              {k:'Total Exams',v:exams.length},
            ].map(({k,v})=>(
              <div key={k} style={{display:'flex',justifyContent:'space-between',padding:'8px 0',borderBottom:`1px solid ${BOR}`,flexWrap:'wrap',gap:4}}>
                <span style={{fontSize:12,color:DIM,fontWeight:600}}>{k}</span>
                <span style={{fontSize:12,color:TS,fontFamily:'monospace'}}>{String(v)}</span>
              </div>
            ))}
          </div>
          <div style={{...cs,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.04)'}}>
            <div style={{fontWeight:700,fontSize:14,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>
            <div style={{fontSize:12,color:DIM,marginBottom:14}}>Deleting a batch is permanent. All students will be unassigned from this batch.</div>
            <button onClick={deleteBatch} style={{...bd,padding:'11px 22px',fontSize:13}} className="bd-btn">🗑️ Delete This Batch</button>
          </div>
        </div>}
      </div>
    </div>
  )
}