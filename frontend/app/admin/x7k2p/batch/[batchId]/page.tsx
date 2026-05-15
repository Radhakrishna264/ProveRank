'use client'
import { useState, useEffect, useCallback } from 'react'
import { getToken } from '@/lib/auth'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const ACC='#4D9FFF',TS='#E8F4FF',DIM='#6B8FAF',SUC='#00C48C',DNG='#FF4D4D',WRN='#FFB84D'
const BOR='rgba(77,159,255,0.18)',BOR2='rgba(77,159,255,0.3)',CRD='rgba(0,22,40,0.75)'
const bp:any={background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:10,padding:'10px 20px',cursor:'pointer',fontWeight:700,fontSize:13,fontFamily:'Inter,sans-serif'}
const bd:any={background:'rgba(255,77,77,0.15)',color:DNG,border:'1px solid rgba(255,77,77,0.3)',borderRadius:8,padding:'7px 14px',cursor:'pointer',fontWeight:700,fontSize:12,fontFamily:'Inter,sans-serif'}
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1.5px solid '+BOR2,borderRadius:10,color:TS,fontSize:14,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box' as any}
const cs:any={background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}

function getBatchIdFromUrl(){
  if(typeof window==='undefined') return ''
  const parts = window.location.pathname.split('/')
  return parts[parts.length-1]||''
}

export default function BatchDetail(){
  const [batchId,setBatchId]=useState('')
  const [token,setToken]=useState('')
  const [tab,setTab]=useState('overview')
  const [batch,setBatch]=useState<any>(null)
  const [students,setStudents]=useState<any[]>([])
  const [exams,setExams]=useState<any[]>([])
  const [loading,setLoading]=useState(true)
  const [error,setError]=useState('')
  const [searchQ,setSearchQ]=useState('')
  const [addEmail,setAddEmail]=useState('')
  const [adding,setAdding]=useState(false)
  const [newName,setNewName]=useState('')
  const [renaming,setRenaming]=useState(false)
  const [annTitle,setAnnTitle]=useState('')
  const [annMsg,setAnnMsg]=useState('')
  const [toast,setToast]=useState<{m:string,t:'s'|'e'|'w'}|null>(null)
  const T=(m:string,t:'s'|'e'|'w'='s')=>{setToast({m,t});setTimeout(()=>setToast(null),4000)}

  useEffect(()=>{
    const tk = getToken()
    const id = getBatchIdFromUrl()
    if(!tk){ window.location.href='/login'; return }
    if(!id){ setError('Invalid batch ID'); setLoading(false); return }
    setToken(tk)
    setBatchId(id)
  },[])

  const load = useCallback(async(tk:string, id:string)=>{
    if(!tk||!id) return
    setLoading(true)
    try {
      const h = {Authorization:'Bearer '+tk}
      const [br,sr,er] = await Promise.all([
        fetch(API+'/api/admin/batches/'+id,{headers:h}),
        fetch(API+'/api/admin/batches/'+id+'/students',{headers:h}),
        fetch(API+'/api/admin/batches/'+id+'/exams',{headers:h})
      ])
      if(br.ok){ const b=await br.json(); setBatch(b) }
      else { setError('Batch not found ('+br.status+')') }
      if(sr.ok){ const s=await sr.json(); if(Array.isArray(s))setStudents(s) }
      if(er.ok){ const e=await er.json(); if(Array.isArray(e))setExams(e) }
    } catch(e:any){ setError('Network error: '+e.message) }
    setLoading(false)
  },[])

  useEffect(()=>{ if(token&&batchId) load(token,batchId) },[token,batchId,load])

  const addStudent=async()=>{
    if(!addEmail.trim()){T('Enter email','e');return}
    setAdding(true)
    try{
      const r=await fetch(API+'/api/admin/batches/'+batchId+'/students/add',{
        method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
        body:JSON.stringify({studentEmail:addEmail.trim()})
      })
      const d=await r.json()
      if(r.ok){T('Student added ✅');setAddEmail('');load(token,batchId)}
      else T(d.message||'Failed','e')
    }catch{T('Error','e')}finally{setAdding(false)}
  }

  const removeStudent=async(sid:string,name:string)=>{
    if(!confirm('Remove '+name+' from batch?'))return
    const r=await fetch(API+'/api/admin/batches/'+batchId+'/students/'+sid,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Removed');setStudents(p=>p.filter(s=>s._id!==sid))}else T('Failed','e')
  }

  const renameBatch=async()=>{
    if(!newName.trim()){T('Enter name','e');return}
    const r=await fetch(API+'/api/admin/batches/'+batchId,{method:'PATCH',
      headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
      body:JSON.stringify({name:newName.trim()})})
    const d=await r.json()
    if(r.ok){T('Renamed ✅');setBatch((p:any)=>({...p,name:newName}));setRenaming(false)}else T(d.message||'Failed','e')
  }

  const deleteBatch=async()=>{
    if(!confirm('DELETE batch "'+batch?.name+'"? Cannot be undone.'))return
    const r=await fetch(API+'/api/admin/batches/'+batchId,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){T('Deleted');setTimeout(()=>{window.location.href='/admin/x7k2p'},1200)}else T('Failed','e')
  }

  const sendAnn=async()=>{
    if(!annTitle||!annMsg){T('Fill all fields','e');return}
    const r=await fetch(API+'/api/admin/announcements',{method:'POST',
      headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
      body:JSON.stringify({title:annTitle,message:annMsg,batch:batchId})})
    if(r.ok){T('Sent ✅');setAnnTitle('');setAnnMsg('')}else T('Failed','e')
  }

  const exportCSV=()=>{
    const rows=[['Name','Email','Phone','Joined'],...students.map(s=>[s.name||'',s.email||'',s.phone||'',s.createdAt?new Date(s.createdAt).toLocaleDateString():''])]
    const csv=rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\n')
    const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='batch_students.csv';a.click()
    T('Exported ✅')
  }

  const filtered=students.filter(s=>!searchQ||s.name?.toLowerCase().includes(searchQ.toLowerCase())||s.email?.toLowerCase().includes(searchQ.toLowerCase()))
  const TABS=[{id:'overview',l:'📊 Overview'},{id:'students',l:'👥 Students ('+students.length+')'},{id:'exams',l:'📝 Exams ('+exams.length+')'},{id:'analytics',l:'📈 Analytics'},{id:'announce',l:'📢 Announce'},{id:'settings',l:'⚙️ Settings'}]

  if(loading) return(
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column' as any,gap:16}}>
      <div style={{width:44,height:44,border:'3px solid '+BOR2,borderTopColor:ACC,borderRadius:'50%',animation:'spin 1s linear infinite'}}/>
      <div style={{color:DIM,fontSize:13,fontFamily:'Inter,sans-serif'}}>Loading Batch...</div>
      <style>{'@keyframes spin{to{transform:rotate(360deg)}}'}</style>
    </div>
  )

  if(error||!batch) return(
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',display:'flex',alignItems:'center',justifyContent:'center',flexDirection:'column' as any,gap:16,fontFamily:'Inter,sans-serif'}}>
      <div style={{fontSize:48}}>📭</div>
      <div style={{color:TS,fontSize:16,fontWeight:700}}>{error||'Batch not found'}</div>
      <div style={{color:DIM,fontSize:12}}>ID: {batchId}</div>
      <button onClick={()=>{window.location.href='/admin/x7k2p'}} style={bp}>← Back to Admin</button>
    </div>
  )

  return(
    <div style={{minHeight:'100vh',background:'radial-gradient(ellipse at 20% 50%,#001628 0%,#000A18 60%,#000510 100%)',fontFamily:'Inter,sans-serif'}}>
      <style>{'@import url(\'https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=Playfair+Display:wght@700&display=swap\'); @keyframes su{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}} .bt:hover{opacity:0.85} .tr:hover{background:rgba(77,159,255,0.05)!important}'}</style>
      {toast&&<div style={{position:'fixed',top:14,left:'50%',transform:'translateX(-50%)',zIndex:9999,background:toast.t==='s'?'rgba(0,196,140,0.95)':toast.t==='e'?'rgba(255,77,77,0.95)':'rgba(255,184,77,0.95)',color:'#fff',padding:'11px 24px',borderRadius:12,fontSize:13,fontWeight:700,boxShadow:'0 8px 24px rgba(0,0,0,0.4)',whiteSpace:'nowrap' as any}}>{toast.m}</div>}
      {/* HEADER */}
      <div style={{position:'sticky' as any,top:0,zIndex:100,background:'rgba(0,10,24,0.92)',backdropFilter:'blur(16px)',borderBottom:'1px solid '+BOR,padding:'12px 16px'}}>
        <div style={{maxWidth:900,margin:'0 auto'}}>
          <div style={{display:'flex',alignItems:'center',gap:10,flexWrap:'wrap' as any,marginBottom:10}}>
            <button onClick={()=>{window.location.href='/admin/x7k2p'}} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'7px 12px',cursor:'pointer',fontSize:12,fontWeight:600}} className="bt">← Admin</button>
            <div style={{flex:1}}>
              <div style={{fontSize:18,fontWeight:800,fontFamily:'Playfair Display,serif',background:'linear-gradient(90deg,'+ACC+',#A8D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>📦 {batch.name}</div>
              <div style={{fontSize:10,color:DIM,marginTop:1}}>ID: {batchId} · Created {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():'-'}</div>
            </div>
            <span style={{fontSize:11,background:'rgba(77,159,255,0.1)',color:ACC,padding:'4px 10px',borderRadius:20,border:'1px solid '+BOR2}}>👥 {students.length}</span>
            <span style={{fontSize:11,background:'rgba(0,196,140,0.1)',color:SUC,padding:'4px 10px',borderRadius:20,border:'1px solid rgba(0,196,140,0.25)'}}>📝 {exams.length}</span>
          </div>
          <div style={{display:'flex',gap:4,overflowX:'auto' as any,paddingBottom:2}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setTab(t.id)} style={{background:tab===t.id?'rgba(77,159,255,0.18)':'transparent',border:'1px solid '+(tab===t.id?BOR2:'transparent'),color:tab===t.id?ACC:DIM,borderRadius:8,padding:'6px 11px',cursor:'pointer',fontSize:11,fontWeight:600,whiteSpace:'nowrap' as any,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}} className="bt">{t.l}</button>
            ))}
          </div>
        </div>
      </div>
{/* CONTENT */}
      <div style={{maxWidth:900,margin:'0 auto',padding:'18px 14px'}}>
        {/* OVERVIEW */}
        {tab==='overview'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={{display:'flex',gap:10,flexWrap:'wrap' as any,marginBottom:14}}>
            {[{i:'👥',l:'Students',v:students.length,c:ACC},{i:'📝',l:'Exams',v:exams.length,c:WRN},{i:'✅',l:'Active',v:students.filter(s=>!s.banned).length,c:SUC},{i:'🚫',l:'Banned',v:students.filter(s=>s.banned).length,c:DNG}].map(x=>(
              <div key={x.l} style={{background:CRD,border:'1px solid '+BOR,borderRadius:14,padding:'16px 14px',flex:1,minWidth:100,backdropFilter:'blur(12px)',textAlign:'center' as any}}>
                <div style={{fontSize:24,marginBottom:4}}>{x.i}</div>
                <div style={{fontSize:22,fontWeight:800,color:x.c,fontFamily:'Playfair Display,serif'}}>{x.v}</div>
                <div style={{fontSize:10,color:DIM,marginTop:2,fontWeight:600}}>{x.l}</div>
              </div>
            ))}
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>⚡ Quick Actions</div>
            <div style={{display:'flex',gap:8,flexWrap:'wrap' as any}}>
              <button onClick={()=>setTab('students')} style={bp} className="bt">👥 Students</button>
              <button onClick={()=>setTab('exams')} style={bp} className="bt">📝 Exams</button>
              <button onClick={()=>setTab('announce')} style={{...bp,background:'linear-gradient(135deg,#7C3AED,#4C1D95)'}} className="bt">📢 Announce</button>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bt">📤 Export CSV</button>
            </div>
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>🕐 Recent Students</div>
            {students.slice(0,5).length?students.slice(0,5).map(s=>(
              <div key={s._id} className="tr" style={{display:'flex',alignItems:'center',gap:10,padding:'8px 6px',borderRadius:8}}>
                <div style={{width:32,height:32,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:12,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' as any}}>{s.name||'—'}</div>
                  <div style={{fontSize:10,color:DIM,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' as any}}>{s.email}</div>
                </div>
                <div style={{fontSize:10,color:DIM}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</div>
              </div>
            )):<div style={{textAlign:'center' as any,padding:24,color:DIM,fontSize:12}}>No students yet</div>}
          </div>
        </div>}
        {/* STUDENTS */}
        {tab==='students'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={cs}>
            <div style={{display:'flex',gap:8,flexWrap:'wrap' as any,marginBottom:12}}>
              <input value={searchQ} onChange={e=>setSearchQ(e.target.value)} placeholder="🔍 Search name/email" style={{...inp,maxWidth:260,padding:'9px 12px'}}/>
              <button onClick={exportCSV} style={{background:'rgba(0,196,140,0.12)',color:SUC,border:'1px solid rgba(0,196,140,0.3)',borderRadius:8,padding:'9px 14px',cursor:'pointer',fontWeight:700,fontSize:12}} className="bt">📤 Export</button>
              <span style={{marginLeft:'auto',fontSize:11,color:DIM,lineHeight:'36px'}}>{filtered.length} students</span>
            </div>
            <div style={{marginBottom:12,background:'rgba(77,159,255,0.05)',border:'1px solid '+BOR,borderRadius:10,padding:12}}>
              <div style={{fontSize:11,fontWeight:700,color:ACC,marginBottom:8}}>➕ Add Student by Email</div>
              <div style={{display:'flex',gap:8}}>
                <input value={addEmail} onChange={e=>setAddEmail(e.target.value)} onKeyDown={e=>e.key==='Enter'&&addStudent()} placeholder="student@email.com" style={{...inp,flex:1,padding:'9px 12px'}}/>
                <button onClick={addStudent} disabled={adding} style={{...bp,opacity:adding?0.7:1}} className="bt">{adding?'...':'Add'}</button>
              </div>
            </div>
            {filtered.length?(
              <div style={{overflowX:'auto' as any}}>
                <table style={{width:'100%',borderCollapse:'collapse' as any,fontSize:12}}>
                  <thead><tr style={{borderBottom:'1px solid '+BOR}}>
                    {['#','Name','Email','Joined','Action'].map(h=><th key={h} style={{padding:'8px 8px',textAlign:'left' as any,color:DIM,fontWeight:600,fontSize:10,letterSpacing:0.4}}>{h}</th>)}
                  </tr></thead>
                  <tbody>{filtered.map((s,i)=>(
                    <tr key={s._id} className="tr" style={{borderBottom:'1px solid '+BOR}}>
                      <td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>
                      <td style={{padding:'9px 8px'}}>
                        <div style={{display:'flex',alignItems:'center',gap:7}}>
                          <div style={{width:26,height:26,borderRadius:'50%',background:'rgba(77,159,255,0.12)',border:'1px solid '+BOR2,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'?')[0].toUpperCase()}</div>
                          <span style={{color:TS,fontWeight:600,whiteSpace:'nowrap' as any}}>{s.name||'—'}</span>
                          {s.banned&&<span style={{fontSize:9,background:'rgba(255,77,77,0.2)',color:DNG,padding:'2px 6px',borderRadius:10}}>BANNED</span>}
                        </div>
                      </td>
                      <td style={{padding:'9px 8px',color:DIM,fontSize:11}}>{s.email}</td>
                      <td style={{padding:'9px 8px',color:DIM,whiteSpace:'nowrap' as any}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():'-'}</td>
                      <td style={{padding:'9px 8px'}}><button onClick={()=>removeStudent(s._id,s.name||s.email)} style={bd} className="bt">Remove</button></td>
                    </tr>
                  ))}</tbody>
                </table>
              </div>
            ):<div style={{textAlign:'center' as any,padding:32,color:DIM}}>
              <div style={{fontSize:40,marginBottom:8}}>👥</div>
              <div style={{fontSize:13,fontWeight:600,color:TS,marginBottom:4}}>No students enrolled</div>
              <div style={{fontSize:11}}>Add students using email above</div>
            </div>}
          </div>
        </div>}
        {/* EXAMS */}
        {tab==='exams'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>📝 Assigned Exams ({exams.length})</div>
            {exams.length?exams.map(e=>(
              <div key={e._id} style={{...cs,marginBottom:10,display:'flex',gap:10,alignItems:'center',flexWrap:'wrap' as any}}>
                <div style={{flex:1}}>
                  <div style={{fontWeight:700,fontSize:13,color:TS}}>{e.title}</div>
                  <div style={{display:'flex',gap:8,marginTop:4,flexWrap:'wrap' as any}}>
                    <span style={{fontSize:10,color:ACC}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString():'-'}</span>
                    <span style={{fontSize:10,color:DIM}}>⏱ {e.duration||'-'} min</span>
                    <span style={{fontSize:10,color:e.status==='active'?SUC:WRN}}>{e.status||'draft'}</span>
                  </div>
                </div>
              </div>
            )):<div style={{textAlign:'center' as any,padding:32,color:DIM,fontSize:12}}>No exams assigned to this batch</div>}
          </div>
        </div>}
        {/* ANALYTICS */}
        {tab==='analytics'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📈 Batch Analytics</div>
            {[{l:'Active Students',v:students.filter(s=>!s.banned).length,t:students.length,c:SUC},{l:'Banned Students',v:students.filter(s=>s.banned).length,t:students.length,c:DNG}].map(x=>(
              <div key={x.l} style={{marginBottom:14}}>
                <div style={{display:'flex',justifyContent:'space-between',marginBottom:4}}>
                  <span style={{fontSize:12,color:TS,fontWeight:600}}>{x.l}</span>
                  <span style={{fontSize:11,color:DIM}}>{x.v}/{x.t}</span>
                </div>
                <div style={{background:'rgba(255,255,255,0.06)',borderRadius:8,height:10,overflow:'hidden'}}>
                  <div style={{width:(x.t>0?Math.round(x.v/x.t*100):0)+'%',height:'100%',background:'linear-gradient(90deg,'+x.c+','+x.c+'88)',borderRadius:8}}/>
                </div>
              </div>
            ))}
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>👥 All Students</div>
            {students.map((s,i)=>(
              <div key={s._id} style={{display:'flex',alignItems:'center',gap:8,padding:'7px 0',borderBottom:'1px solid '+BOR}}>
                <span style={{color:DIM,fontSize:12,minWidth:24}}>#{i+1}</span>
                <div style={{width:28,height:28,borderRadius:'50%',background:'rgba(77,159,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:11,fontWeight:700,color:ACC}}>{(s.name||'?')[0].toUpperCase()}</div>
                <div style={{flex:1}}>
                  <div style={{fontSize:12,fontWeight:600,color:TS}}>{s.name||'—'}</div>
                  <div style={{fontSize:10,color:DIM}}>{s.email}</div>
                </div>
                <span style={{fontSize:10,color:s.banned?DNG:SUC}}>{s.banned?'🚫':'✅'}</span>
              </div>
            ))}
            {!students.length&&<div style={{textAlign:'center' as any,padding:24,color:DIM,fontSize:12}}>No students</div>}
          </div>
        </div>}
        {/* ANNOUNCE */}
        {tab==='announce'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>📢 Send Announcement</div>
            <div style={{fontSize:11,color:DIM,marginBottom:14}}>To all <strong style={{color:ACC}}>{students.length} students</strong> in "{batch.name}"</div>
            <div style={{marginBottom:10}}><label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Title</label>
              <input value={annTitle} onChange={e=>setAnnTitle(e.target.value)} placeholder="e.g. Test Tomorrow 10 AM" style={inp}/></div>
            <div style={{marginBottom:14}}><label style={{display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:600,textTransform:'uppercase' as any,letterSpacing:0.5}}>Message</label>
              <textarea value={annMsg} onChange={e=>setAnnMsg(e.target.value)} placeholder="Write message..." style={{...inp,minHeight:100,resize:'vertical' as any}}/></div>
            <button onClick={sendAnn} style={{...bp,opacity:(!annTitle||!annMsg)?0.6:1}} className="bt">📢 Send to Batch</button>
          </div>
        </div>}
        {/* SETTINGS */}
        {tab==='settings'&&<div style={{animation:'su 0.3s ease'}}>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>✏️ Rename Batch</div>
            {!renaming?<div style={{display:'flex',gap:10,alignItems:'center'}}>
              <span style={{fontSize:15,fontWeight:700,color:ACC,flex:1}}>"{batch.name}"</span>
              <button onClick={()=>{setRenaming(true);setNewName(batch.name)}} style={bp} className="bt">Rename</button>
            </div>:<div>
              <input value={newName} onChange={e=>setNewName(e.target.value)} onKeyDown={e=>e.key==='Enter'&&renameBatch()} style={{...inp,marginBottom:10}}/>
              <div style={{display:'flex',gap:8}}>
                <button onClick={renameBatch} style={bp} className="bt">💾 Save</button>
                <button onClick={()=>setRenaming(false)} style={{background:'rgba(77,159,255,0.1)',color:ACC,border:'1px solid '+BOR2,borderRadius:8,padding:'9px 16px',cursor:'pointer',fontSize:12}} className="bt">Cancel</button>
              </div>
            </div>}
          </div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:10}}>ℹ️ Batch Info</div>
            {[['Batch ID',batchId],['Name',batch.name],['Students',students.length],['Exams',exams.length],['Created',batch.createdAt?new Date(batch.createdAt).toLocaleString():'-']].map(([k,v])=>(
              <div key={String(k)} style={{display:'flex',justifyContent:'space-between',padding:'7px 0',borderBottom:'1px solid '+BOR,flexWrap:'wrap' as any,gap:4}}>
                <span style={{fontSize:11,color:DIM,fontWeight:600}}>{k}</span>
                <span style={{fontSize:11,color:TS,fontFamily:'monospace'}}>{String(v)}</span>
              </div>
            ))}
          </div>
          <div style={{...cs,border:'1px solid rgba(255,77,77,0.25)',background:'rgba(255,77,77,0.03)'}}>
            <div style={{fontWeight:700,fontSize:13,color:DNG,marginBottom:4}}>🚨 Danger Zone</div>
            <div style={{fontSize:11,color:DIM,marginBottom:12}}>Permanently deletes batch. All students will be unassigned.</div>
            <button onClick={deleteBatch} style={{...bd,padding:'10px 20px',fontSize:13}} className="bt">🗑️ Delete This Batch</button>
          </div>
        </div>}
      </div>
    </div>
  )
}