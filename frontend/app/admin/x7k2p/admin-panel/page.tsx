'use client';
import React,{useState,useEffect,useCallback,useRef}from'react';
import{useRouter}from'next/navigation';
const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com';
type Perms={create_exam:boolean;edit_exam:boolean;delete_exam:boolean;manage_students:boolean;access_results:boolean;export_data:boolean;manage_questions:boolean;send_announcements:boolean;view_audit_logs:boolean;manage_features:boolean;manage_admins:boolean;impersonate:boolean;manage_branding:boolean;view_snapshots:boolean};
type User={_id:string;name:string;email:string;role:string;permissions?:Perms};
const NP:Perms={create_exam:false,edit_exam:false,delete_exam:false,manage_students:false,access_results:false,export_data:false,manage_questions:false,send_announcements:false,view_audit_logs:false,manage_features:false,manage_admins:false,impersonate:false,manage_branding:false,view_snapshots:false};
function Galaxy(){
  const ref=useRef<HTMLCanvasElement>(null);
  useEffect(()=>{
    const c=ref.current;if(!c)return;
    const ctx=c.getContext('2d');if(!ctx)return;
    const resize=()=>{c.width=window.innerWidth;c.height=window.innerHeight;};
    resize();window.addEventListener('resize',resize);
    const stars=Array.from({length:200},()=>({x:Math.random()*c.width,y:Math.random()*c.height,r:Math.random()*1.5+0.3,a:Math.random(),d:(Math.random()-0.5)*0.015}));
    const pts=Array.from({length:60},()=>({x:Math.random()*c.width,y:Math.random()*c.height,vx:(Math.random()-0.5)*0.45,vy:(Math.random()-0.5)*0.45,a:Math.random()*0.5+0.15}));
    let id:number;
    function frame(){
      if(!ctx||!c)return;
      ctx.clearRect(0,0,c.width,c.height);
      const g=ctx.createRadialGradient(c.width/2,c.height/2,0,c.width/2,c.height/2,c.width);
      g.addColorStop(0,'#091524');g.addColorStop(0.55,'#060C18');g.addColorStop(1,'#020508');
      ctx.fillStyle=g;ctx.fillRect(0,0,c.width,c.height);
      const n=ctx.createRadialGradient(c.width*0.3,c.height*0.4,0,c.width*0.3,c.height*0.4,c.width*0.45);
      n.addColorStop(0,'rgba(0,60,140,0.09)');n.addColorStop(1,'transparent');
      ctx.fillStyle=n;ctx.fillRect(0,0,c.width,c.height);
      stars.forEach(s=>{s.a+=s.d;if(s.a<=0||s.a>=1)s.d*=-1;ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=`rgba(180,220,255,${Math.max(0,Math.min(1,s.a))})`;ctx.fill();});
      pts.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0)p.x=c.width;if(p.x>c.width)p.x=0;if(p.y<0)p.y=c.height;if(p.y>c.height)p.y=0;ctx.beginPath();ctx.arc(p.x,p.y,1.5,0,Math.PI*2);ctx.fillStyle=`rgba(0,180,255,${p.a*0.35})`;ctx.fill();});
      id=requestAnimationFrame(frame);
    }
    frame();
    return()=>{cancelAnimationFrame(id);window.removeEventListener('resize',resize);};
  },[]);
  return<canvas ref={ref} style={{position:'fixed',inset:0,zIndex:0,pointerEvents:'none'}}/>;
}
const CS:React.CSSProperties={background:'rgba(8,16,32,0.75)',backdropFilter:'blur(18px)',border:'1px solid rgba(0,150,255,0.16)',borderRadius:14,padding:20};
const HS:React.CSSProperties={fontSize:17,fontWeight:700,color:'#E8F4FD',marginBottom:14,display:'flex',alignItems:'center',gap:8};
const IS:React.CSSProperties={width:'100%',padding:'9px 12px',background:'rgba(0,150,255,0.07)',border:'1px solid rgba(0,150,255,0.25)',borderRadius:8,color:'#E8F4FD',fontSize:13,outline:'none',boxSizing:'border-box'};
const BP:React.CSSProperties={padding:'8px 18px',background:'linear-gradient(135deg,#0060D0,#00B4FF)',border:'none',borderRadius:8,color:'#fff',cursor:'pointer',fontWeight:700,fontSize:13};
const BS:React.CSSProperties={padding:'7px 14px',background:'rgba(0,90,180,0.2)',border:'1px solid rgba(0,150,255,0.3)',borderRadius:8,color:'#00B4FF',cursor:'pointer',fontSize:12,fontWeight:600};
function Toast({msg,type}:{msg:string;type:string}){
  const bg=type==='error'?'rgba(200,30,30,0.94)':type==='info'?'rgba(0,80,180,0.94)':'rgba(5,140,70,0.94)';
  return<div style={{position:'fixed',top:18,right:18,zIndex:9999,padding:'11px 20px',borderRadius:10,background:bg,color:'#fff',fontWeight:700,boxShadow:'0 4px 24px rgba(0,0,0,0.5)',fontSize:13,maxWidth:280,wordBreak:'break-word'}}>{msg}</div>;
}
function DashSect({user,token,T}:{user:User|null;token:string;T:(m:string,t?:string)=>void}){
  const[stats,setSt]=useState<any>(null);
  useEffect(()=>{if(!token)return;fetch(`${API}/api/admin/stats`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setSt(d)).catch(()=>{});},[token]);
  const v=(x:any)=>x!=null?x:'—';
  return(
    <div>
      <div style={{marginBottom:22}}>
        <div style={{fontSize:22,fontWeight:800,color:'#E8F4FD'}}>Welcome, {user?.name||'Admin'} 👋</div>
        <div style={{color:'#4A6880',fontSize:13,marginTop:4}}>ProveRank Admin Panel · {user?.email}</div>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(130px,1fr))',gap:12,marginBottom:22}}>
        {[{ico:'👥',lbl:'Students',val:v(stats?.totalStudents||stats?.students)},{ico:'📝',lbl:'Exams',val:v(stats?.totalExams||stats?.exams)},{ico:'📚',lbl:'Questions',val:v(stats?.totalQuestions||stats?.questions)},{ico:'✅',lbl:'Attempts',val:v(stats?.totalAttempts||stats?.attempts)}].map(s=>(
          <div key={s.lbl} style={{...CS,textAlign:'center',padding:16}}>
            <div style={{fontSize:26}}>{s.ico}</div>
            <div style={{fontSize:24,fontWeight:800,color:'#00B4FF',margin:'6px 0 4px'}}>{s.val}</div>
            <div style={{color:'#4A6880',fontSize:11}}>{s.lbl}</div>
          </div>
        ))}
      </div>
      <div style={CS}>
        <div style={HS}>⚡ Your Role</div>
        <div style={{color:'#4A6880',fontSize:13,lineHeight:1.8}}>Logged in as <span style={{color:'#00B4FF',fontWeight:700}}>Admin</span>. Use sidebar to navigate permitted features. Permissions set by SuperAdmin.</div>
      </div>
    </div>
  );
}
function ExamSect({perms,token,T}:{perms:Perms;token:string;T:(m:string,t?:string)=>void}){
  const[exams,setEx]=useState<any[]>([]);
  const[view,setV]=useState<'list'|'create'>('list');
  const[f,setF]=useState({title:'',duration:'200',totalMarks:'720',startDate:'',endDate:''});
  const[busy,setBusy]=useState(false);
  useEffect(()=>{fetch(`${API}/api/exams`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setEx(Array.isArray(d)?d:(d.exams||d.data||[]))).catch(()=>{});},[token]);
  const create=async()=>{
    if(!f.title.trim()){T('Enter exam title','error');return;}
    setBusy(true);
    try{const r=await fetch(`${API}/api/exams`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({title:f.title,duration:parseInt(f.duration)||200,totalMarks:parseInt(f.totalMarks)||720,startDate:f.startDate||undefined,endDate:f.endDate||undefined})});const d=await r.json();if(d.exam||d.success||d._id){T('Exam created! ✅');setV('list');setF({title:'',duration:'200',totalMarks:'720',startDate:'',endDate:''});}else T(d.message||'Error','error');}catch{T('Network error','error');}
    setBusy(false);
  };
  const del=async(id:string)=>{if(!perms.delete_exam){T('No delete permission','error');return;}if(!confirm('Delete this exam?'))return;await fetch(`${API}/api/exams/${id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}});setEx(ex=>ex.filter(e=>e._id!==id));T('Deleted');};
  return(
    <div>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18}}>
        <div style={{...HS,marginBottom:0}}>📝 Exam Management</div>
        {perms.create_exam&&<button style={BP} onClick={()=>setV(v=>v==='create'?'list':'create')}>{view==='create'?'← Back':'+ New Exam'}</button>}
      </div>
      {view==='create'&&perms.create_exam&&(
        <div style={{...CS,marginBottom:14}}>
          <div style={HS}>✨ Create Exam</div>
          <div style={{display:'flex',flexDirection:'column',gap:10}}>
            <div><label style={{color:'#6A8AAA',fontSize:11}}>Title *</label><input style={{...IS,marginTop:4}} value={f.title} onChange={e=>setF({...f,title:e.target.value})} placeholder="e.g. NEET Full Mock Test 1"/></div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              <div><label style={{color:'#6A8AAA',fontSize:11}}>Duration (min)</label><input style={{...IS,marginTop:4}} type="number" value={f.duration} onChange={e=>setF({...f,duration:e.target.value})}/></div>
              <div><label style={{color:'#6A8AAA',fontSize:11}}>Total Marks</label><input style={{...IS,marginTop:4}} type="number" value={f.totalMarks} onChange={e=>setF({...f,totalMarks:e.target.value})}/></div>
              <div><label style={{color:'#6A8AAA',fontSize:11}}>Start Date</label><input style={{...IS,marginTop:4}} type="datetime-local" value={f.startDate} onChange={e=>setF({...f,startDate:e.target.value})}/></div>
              <div><label style={{color:'#6A8AAA',fontSize:11}}>End Date</label><input style={{...IS,marginTop:4}} type="datetime-local" value={f.endDate} onChange={e=>setF({...f,endDate:e.target.value})}/></div>
            </div>
            <button style={{...BP,marginTop:4}} onClick={create} disabled={busy}>{busy?'Creating...':'Create Exam ✅'}</button>
          </div>
        </div>
      )}
      <div style={CS}>
        <div style={HS}>📋 All Exams ({exams.length})</div>
        {exams.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:28}}>No exams</div>:(
          <div style={{display:'flex',flexDirection:'column',gap:9,maxHeight:420,overflowY:'auto'}}>
            {exams.map((e:any)=>(
              <div key={e._id} style={{background:'rgba(0,90,180,0.09)',border:'1px solid rgba(0,150,255,0.11)',borderRadius:10,padding:'11px 15px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div>
                  <div style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{e.title}</div>
                  <div style={{color:'#4A6880',fontSize:11,marginTop:3}}>{e.duration||200}min · {e.totalMarks||720}M · <span style={{color:e.status==='active'?'#00FF88':'#6A8AAA'}}>{e.status||'draft'}</span></div>
                </div>
                {perms.delete_exam&&<button style={{...BS,color:'#FF6B6B',borderColor:'rgba(255,60,60,0.3)',fontSize:11}} onClick={()=>del(e._id)}>🗑</button>}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
function QSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[qs,setQs]=useState<any[]>([]);
  const[search,setSrch]=useState('');
  const[f,setF]=useState({text:'',a:'',b:'',c:'',d:'',ans:'0',subj:'Biology',diff:'medium'});
  const[busy,setBusy]=useState(false);
  useEffect(()=>{fetch(`${API}/api/questions?limit=50`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setQs(Array.isArray(d)?d:(d.questions||d.data||[]))).catch(()=>{});},[token]);
  const add=async()=>{
    if(!f.text.trim()||!f.a.trim()){T('Fill question + options','error');return;}
    setBusy(true);
    try{const r=await fetch(`${API}/api/questions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({text:f.text,options:[{text:f.a},{text:f.b},{text:f.c},{text:f.d}],correct:parseInt(f.ans),subject:f.subj,difficulty:f.diff,type:'SCQ'})});const d=await r.json();if(d._id||d.success||d.question){T('Question added! ✅');setQs(q=>[d.question||d,...q]);setF({text:'',a:'',b:'',c:'',d:'',ans:'0',subj:'Biology',diff:'medium'});}else T(d.message||'Error','error');}catch{T('Network error','error');}
    setBusy(false);
  };
  const filtered=qs.filter(q=>(q.text||'').toLowerCase().includes(search.toLowerCase()));
  return(
    <div>
      <div style={HS}>📚 Question Bank</div>
      <div style={{...CS,marginBottom:14}}>
        <div style={HS}>➕ Add Question</div>
        <div style={{display:'flex',flexDirection:'column',gap:9}}>
          <textarea style={{...IS,minHeight:75,resize:'vertical'}} value={f.text} onChange={e=>setF({...f,text:e.target.value})} placeholder="Question text..."/>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
            <input style={IS} value={f.a} onChange={e=>setF({...f,a:e.target.value})} placeholder="Option A"/>
            <input style={IS} value={f.b} onChange={e=>setF({...f,b:e.target.value})} placeholder="Option B"/>
            <input style={IS} value={f.c} onChange={e=>setF({...f,c:e.target.value})} placeholder="Option C"/>
            <input style={IS} value={f.d} onChange={e=>setF({...f,d:e.target.value})} placeholder="Option D"/>
          </div>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:8}}>
            <select style={IS} value={f.ans} onChange={e=>setF({...f,ans:e.target.value})}>{['A','B','C','D'].map((o,i)=><option key={o} value={String(i)}>Correct: {o}</option>)}</select>
            <select style={IS} value={f.subj} onChange={e=>setF({...f,subj:e.target.value})}>{['Physics','Chemistry','Biology'].map(s=><option key={s}>{s}</option>)}</select>
            <select style={IS} value={f.diff} onChange={e=>setF({...f,diff:e.target.value})}><option value="easy">Easy</option><option value="medium">Medium</option><option value="hard">Hard</option></select>
          </div>
          <button style={{...BP,alignSelf:'flex-start'}} onClick={add} disabled={busy}>{busy?'Saving...':'Add Question'}</button>
        </div>
      </div>
      <div style={CS}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
          <div style={{...HS,marginBottom:0}}>📋 Questions ({qs.length})</div>
          <input style={{...IS,width:180}} value={search} onChange={e=>setSrch(e.target.value)} placeholder="Search..."/>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:7,maxHeight:380,overflowY:'auto'}}>
          {filtered.slice(0,30).map((q:any)=>(
            <div key={q._id} style={{background:'rgba(0,90,180,0.07)',border:'1px solid rgba(0,150,255,0.1)',borderRadius:8,padding:'9px 13px'}}>
              <div style={{color:'#E8F4FD',fontSize:12,lineHeight:1.5}}>{(q.text||'').slice(0,130)}{(q.text||'').length>130?'...':''}</div>
              <div style={{color:'#4A6880',fontSize:10,marginTop:3}}>{q.subject} · {q.difficulty} · {q.type||'SCQ'}</div>
            </div>
          ))}
          {filtered.length===0&&<div style={{color:'#4A6880',textAlign:'center',padding:24}}>No questions</div>}
        </div>
      </div>
    </div>
  );
}
function StudSect({perms,token,T}:{perms:Perms;token:string;T:(m:string,t?:string)=>void}){
  const[studs,setSt]=useState<any[]>([]);
  const[search,setSrch]=useState('');
  const[loading,setLoad]=useState(true);
  const load=useCallback(()=>{setLoad(true);fetch(`${API}/api/admin/students`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setSt(Array.isArray(d)?d:(d.students||d.data||d.users||[]))).catch(()=>{}).finally(()=>setLoad(false));},[token]);
  useEffect(()=>{load();},[load]);
  const ban=async(id:string,isBanned:boolean)=>{await fetch(isBanned?`${API}/api/admin/unban/${id}`:`${API}/api/admin/ban/${id}`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(isBanned?{}:{reason:'Banned by admin'})});T(isBanned?'Unbanned ✅':'Banned 🚫');load();};
  const filtered=studs.filter(s=>(s.name||'').toLowerCase().includes(search.toLowerCase())||(s.email||'').toLowerCase().includes(search.toLowerCase()));
  return(
    <div>
      <div style={HS}>👥 Student Management</div>
      <div style={CS}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
          <div style={{color:'#6A8AAA',fontSize:13}}>Total: <span style={{color:'#00B4FF',fontWeight:700}}>{studs.length}</span></div>
          <input style={{...IS,width:190}} value={search} onChange={e=>setSrch(e.target.value)} placeholder="Search..."/>
        </div>
        {loading?<div style={{color:'#4A6880',textAlign:'center',padding:28}}>Loading...</div>:(
          <div style={{display:'flex',flexDirection:'column',gap:8,maxHeight:500,overflowY:'auto'}}>
            {filtered.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:24}}>No students found</div>:filtered.slice(0,50).map((s:any)=>(
              <div key={s._id} style={{background:s.banned?'rgba(200,30,30,0.07)':'rgba(0,90,180,0.08)',border:`1px solid ${s.banned?'rgba(220,50,50,0.18)':'rgba(0,150,255,0.1)'}`,borderRadius:10,padding:'11px 15px',display:'flex',justifyContent:'space-between',alignItems:'center',gap:8}}>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{s.name||'Unknown'} {s.banned&&<span style={{background:'rgba(200,30,30,0.25)',color:'#FF6B6B',padding:'1px 7px',borderRadius:10,fontSize:9,fontWeight:800}}>BANNED</span>}</div>
                  <div style={{color:'#4A6880',fontSize:11,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',marginTop:2}}>{s.email}</div>
                </div>
                <div style={{display:'flex',gap:6,flexShrink:0}}>
                  {perms.impersonate&&<a href={`/impersonate?id=${s._id}`} style={{...BS,fontSize:10,padding:'5px 10px',textDecoration:'none'}}>👁</a>}
                  <button style={{...BS,color:s.banned?'#00FF88':'#FF6B6B',borderColor:s.banned?'rgba(0,255,100,0.3)':'rgba(220,50,50,0.3)',fontSize:11}} onClick={()=>ban(s._id,s.banned)}>{s.banned?'Unban':'Ban'}</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
function ResSect({perms,token,T}:{perms:Perms;token:string;T:(m:string,t?:string)=>void}){
  const[res,setRes]=useState<any[]>([]);
  const[lb,setLb]=useState<any[]>([]);
  const[view,setV]=useState<'results'|'lb'>('results');
  useEffect(()=>{
    fetch(`${API}/api/results?limit=30`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setRes(Array.isArray(d)?d:(d.results||d.data||[]))).catch(()=>{});
    fetch(`${API}/api/results/leaderboard`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setLb(Array.isArray(d)?d:(d.leaderboard||d.data||[]))).catch(()=>{});
  },[token]);
  const exportCSV=()=>{if(!perms.export_data){T('No export permission','error');return;}const csv=[['Name','Exam','Score','Rank','Date'],...res.map((r:any)=>[r.studentName||'—',r.examTitle||'—',r.totalScore||0,r.rank||'—',r.createdAt?new Date(r.createdAt).toLocaleDateString('en-IN'):'-'])].map(r=>r.join(',')).join('\n');const a=document.createElement('a');a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);a.download='results.csv';a.click();T('CSV downloaded ✅');};
  const medals=['🥇','🥈','🥉'];
  return(
    <div>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
        <div style={{...HS,marginBottom:0}}>📊 Results & Analytics</div>
        <div style={{display:'flex',gap:7}}>
          <button style={{...BS,background:view==='results'?'rgba(0,100,200,0.3)':'transparent'}} onClick={()=>setV('results')}>Results</button>
          <button style={{...BS,background:view==='lb'?'rgba(0,100,200,0.3)':'transparent'}} onClick={()=>setV('lb')}>Leaderboard</button>
          {perms.export_data&&<button style={BP} onClick={exportCSV}>⬇ CSV</button>}
        </div>
      </div>
      {view==='results'&&(
        <div style={CS}>
<div style={HS}>📋 Recent Results</div>
          <div style={{display:'flex',flexDirection:'column',gap:8,maxHeight:450,overflowY:'auto'}}>
            {res.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:28}}>No results yet</div>:res.slice(0,25).map((r:any,i:number)=>(
              <div key={r._id||i} style={{background:'rgba(0,90,180,0.08)',border:'1px solid rgba(0,150,255,0.1)',borderRadius:9,padding:'10px 15px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div><div style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{r.studentName||r.student?.name||'Unknown'}</div><div style={{color:'#4A6880',fontSize:11,marginTop:2}}>{r.examTitle||r.exam?.title||'—'}</div></div>
                <div style={{textAlign:'right'}}><div style={{color:'#00B4FF',fontWeight:800,fontSize:14}}>{r.totalScore||r.score||0}</div><div style={{color:'#4A6880',fontSize:10}}>Rank #{r.rank||'—'}</div></div>
              </div>
            ))}
          </div>
        </div>
      )}
      {view==='lb'&&(
        <div style={CS}>
          <div style={HS}>🏆 Leaderboard</div>
          <div style={{display:'flex',flexDirection:'column',gap:7,maxHeight:450,overflowY:'auto'}}>
            {lb.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:28}}>No data yet</div>:lb.slice(0,20).map((s:any,i:number)=>(
              <div key={s._id||i} style={{background:i<3?'rgba(0,160,90,0.08)':'rgba(0,90,180,0.06)',border:`1px solid ${i<3?'rgba(0,220,100,0.15)':'rgba(0,150,255,0.09)'}`,borderRadius:8,padding:'10px 15px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                <div style={{display:'flex',alignItems:'center',gap:10}}><span style={{fontSize:i<3?20:13,minWidth:24,textAlign:'center'}}>{i<3?medals[i]:`#${i+1}`}</span><div><div style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{s.studentName||s.name||'—'}</div><div style={{color:'#4A6880',fontSize:11}}>{s.examTitle||'—'}</div></div></div>
                <div style={{color:'#00B4FF',fontWeight:800,fontSize:15}}>{s.totalScore||s.score||0}</div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
function AnnSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[anns,setAnns]=useState<any[]>([]);
  const[f,setF]=useState({title:'',message:'',type:'update'});
  const[busy,setBusy]=useState(false);
  useEffect(()=>{fetch(`${API}/api/announcements`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setAnns(Array.isArray(d)?d:(d.announcements||d.data||[]))).catch(()=>{});},[token]);
  const send=async()=>{if(!f.title.trim()||!f.message.trim()){T('Fill title & message','error');return;}setBusy(true);try{const r=await fetch(`${API}/api/announcements`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(f)});const d=await r.json();if(d._id||d.success||d.announcement){T('Sent! 📢');setAnns(a=>[d.announcement||d,...a]);setF({title:'',message:'',type:'update'});}else T(d.message||'Error','error');}catch{T('Network error','error');}setBusy(false);};
  const tc:Record<string,string>={exam:'#00B4FF',update:'#00FF88',result:'#FFD700',urgent:'#FF6060'};
  return(
    <div>
      <div style={HS}>📢 Announcements</div>
      <div style={{...CS,marginBottom:14}}>
        <div style={HS}>✉️ Send to All Students</div>
        <div style={{display:'flex',flexDirection:'column',gap:9}}>
          <input style={IS} value={f.title} onChange={e=>setF({...f,title:e.target.value})} placeholder="Title..."/>
          <textarea style={{...IS,minHeight:80,resize:'vertical'}} value={f.message} onChange={e=>setF({...f,message:e.target.value})} placeholder="Message..."/>
          <select style={IS} value={f.type} onChange={e=>setF({...f,type:e.target.value})}><option value="update">📗 Update</option><option value="exam">📘 Exam Alert</option><option value="result">🏆 Result</option><option value="urgent">🔴 Urgent</option></select>
          <button style={{...BP,alignSelf:'flex-start'}} onClick={send} disabled={busy}>{busy?'Sending...':'Send Announcement'}</button>
        </div>
      </div>
      <div style={CS}>
        <div style={HS}>📋 Recent</div>
        <div style={{display:'flex',flexDirection:'column',gap:8,maxHeight:320,overflowY:'auto'}}>
          {anns.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:24}}>No announcements</div>:anns.slice(0,15).map((a:any)=>(
            <div key={a._id} style={{background:'rgba(0,90,180,0.08)',border:'1px solid rgba(0,150,255,0.1)',borderRadius:9,padding:'10px 14px'}}>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:5}}><span style={{background:`${tc[a.type]||'#00B4FF'}22`,color:tc[a.type]||'#00B4FF',padding:'1px 8px',borderRadius:10,fontSize:9,fontWeight:800}}>{(a.type||'update').toUpperCase()}</span><span style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{a.title}</span></div>
              <div style={{color:'#8AAABB',fontSize:12}}>{a.message}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
function ACSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[logs,setLogs]=useState<any[]>([]);
  useEffect(()=>{fetch(`${API}/api/admin/cheat-logs?limit=30`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setLogs(Array.isArray(d)?d:(d.logs||d.data||[]))).catch(()=>{});},[token]);
  return(
    <div>
      <div style={HS}>🔒 Anti-Cheat Logs</div>
      <div style={CS}>
        <div style={{display:'flex',flexDirection:'column',gap:8,maxHeight:500,overflowY:'auto'}}>
          {logs.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:32}}>🎉 No cheat flags yet!</div>:logs.map((l:any,i:number)=>(
            <div key={l._id||i} style={{background:'rgba(180,30,30,0.07)',border:'1px solid rgba(200,50,50,0.15)',borderRadius:9,padding:'10px 14px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <div><div style={{fontWeight:700,color:'#E8F4FD',fontSize:13}}>{l.studentName||l.student||'Unknown'}</div><div style={{color:'#FF9090',fontSize:12,marginTop:3}}>{l.type||l.action||'Suspicious Activity'}</div></div>
              <div style={{color:'#4A6880',fontSize:10}}>{l.createdAt?new Date(l.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):'-'}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
function AuditSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[logs,setLogs]=useState<any[]>([]);
  useEffect(()=>{fetch(`${API}/api/admin/audit-logs?limit=40`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>setLogs(Array.isArray(d)?d:(d.logs||d.data||[]))).catch(()=>{});},[token]);
  return(
    <div>
      <div style={HS}>📋 Activity Logs</div>
      <div style={CS}>
        <div style={{display:'flex',flexDirection:'column',gap:7,maxHeight:560,overflowY:'auto'}}>
          {logs.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:32}}>No logs yet</div>:logs.map((l:any,i:number)=>(
            <div key={l._id||i} style={{background:'rgba(0,90,180,0.07)',border:'1px solid rgba(0,150,255,0.09)',borderRadius:8,padding:'9px 14px',display:'flex',justifyContent:'space-between',alignItems:'center',gap:8}}>
              <div style={{flex:1,minWidth:0}}><div style={{fontWeight:600,color:'#E8F4FD',fontSize:12}}>{l.action||l.type||'—'}</div><div style={{color:'#4A6880',fontSize:11,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',marginTop:2}}>{l.details||''}{l.userName?` · ${l.userName}`:''}</div></div>
              <div style={{color:'#4A6880',fontSize:10,minWidth:75,textAlign:'right',flexShrink:0}}>{l.createdAt?new Date(l.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):'-'}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
function BrandSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[f,setF]=useState({platformName:'ProveRank',tagline:'Prove Yourself · Rise to the Top',supportEmail:'ProveRank.support@gmail.com'});
  const[busy,setBusy]=useState(false);
  useEffect(()=>{fetch(`${API}/api/admin/branding`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>{if(d.platformName)setF({platformName:d.platformName,tagline:d.tagline||'',supportEmail:d.supportEmail||'ProveRank.support@gmail.com'});}).catch(()=>{});},[token]);
  const save=async()=>{setBusy(true);try{const r=await fetch(`${API}/api/admin/branding`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(f)});const d=await r.json();if(d.success)T('Saved! ✅');else T(d.message||'Error','error');}catch{T('Network error','error');}setBusy(false);};
  return(
    <div>
      <div style={HS}>🎨 Branding</div>
      <div style={CS}>
        <div style={{display:'flex',flexDirection:'column',gap:14}}>
          <div><label style={{color:'#6A8AAA',fontSize:12,display:'block',marginBottom:5}}>Platform Name</label><input style={IS} value={f.platformName} onChange={e=>setF({...f,platformName:e.target.value})}/></div>
          <div><label style={{color:'#6A8AAA',fontSize:12,display:'block',marginBottom:5}}>Tagline</label><input style={IS} value={f.tagline} onChange={e=>setF({...f,tagline:e.target.value})}/></div>
          <div><label style={{color:'#6A8AAA',fontSize:12,display:'block',marginBottom:5}}>Support Email</label><input style={IS} value={f.supportEmail} onChange={e=>setF({...f,supportEmail:e.target.value})} type="email"/></div>
          <button style={{...BP,alignSelf:'flex-start'}} onClick={save} disabled={busy}>{busy?'Saving...':'Save Branding'}</button>
        </div>
      </div>
    </div>
  );
}
function FlagSect({token,T}:{token:string;T:(m:string,t?:string)=>void}){
  const[flags,setFlags]=useState<Record<string,boolean>>({});
  const[load,setLoad]=useState(true);
  useEffect(()=>{fetch(`${API}/api/admin/features`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.json()).then(d=>{if(d.flags||d.features)setFlags(d.flags||d.features||{});}).catch(()=>{}).finally(()=>setLoad(false));},[token]);
  const toggle=async(k:string)=>{const nf={...flags,[k]:!flags[k]};setFlags(nf);try{await fetch(`${API}/api/admin/features`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({flags:nf})});T(`${k.replace(/_/g,' ')}: ${nf[k]?'ON ✅':'OFF'}`);}catch{T('Save failed','error');setFlags(flags);}};
  const keys=Object.keys(flags);
  return(
    <div>
      <div style={HS}>🚩 Feature Flags ({keys.length})</div>
      <div style={CS}>
        {load?<div style={{color:'#4A6880',textAlign:'center',padding:32}}>Loading...</div>:keys.length===0?<div style={{color:'#4A6880',textAlign:'center',padding:32}}>No flags</div>:(
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(200px,1fr))',gap:9}}>
            {keys.map(k=>(
              <div key={k} style={{background:'rgba(0,90,180,0.09)',border:'1px solid rgba(0,150,255,0.11)',borderRadius:9,padding:'10px 14px',display:'flex',justifyContent:'space-between',alignItems:'center',gap:8}}>
                <span style={{color:'#C0D4E8',fontSize:12}}>{k.replace(/_/g,' ').replace(/\b\w/g,(c:string)=>c.toUpperCase())}</span>
                <button onClick={()=>toggle(k)} style={{padding:'3px 11px',background:flags[k]?'rgba(0,200,100,0.25)':'rgba(80,80,80,0.25)',border:`1px solid ${flags[k]?'rgba(0,255,130,0.4)':'rgba(120,120,120,0.3)'}`,borderRadius:20,color:flags[k]?'#00FF88':'#8AAABB',cursor:'pointer',fontSize:11,fontWeight:800,minWidth:40}}>{flags[k]?'ON':'OFF'}</button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
export default function AdminPanelPage(){
  const router=useRouter();
  const[user,setUser]=useState<User|null>(null);
  const[perms,setPerms]=useState<Perms>(NP);
  const[tab,setTab]=useState('dashboard');
  const[loading,setLoading]=useState(true);
  const[sideOpen,setSide]=useState(true);
  const[toast,setToast]=useState<{msg:string;type:string}|null>(null);
  const token=typeof window!=='undefined'?localStorage.getItem('pr_token')||'':'';
  const T=useCallback((msg:string,type='success')=>{setToast({msg,type});setTimeout(()=>setToast(null),4000);},[]);
  useEffect(()=>{
    const role=localStorage.getItem('pr_role');
    const tok=localStorage.getItem('pr_token');
    if(!tok||!role){router.replace('/login');return;}
    if(role==='superadmin'){router.replace('/admin/x7k2p');return;}
    fetch(`${API}/api/auth/me`,{headers:{Authorization:`Bearer ${tok}`}})
    .then(r=>r.json()).then(data=>{const u=data.user||data;if(u._id){setUser(u);if(u.permissions)setPerms({...NP,...u.permissions});}else router.replace('/login');})
    .catch(()=>T('Could not load profile','error')).finally(()=>setLoading(false));
  },[router,T]);
  const nav=[
    {id:'dashboard',ico:'🏠',lbl:'Dashboard',show:true},
    {id:'exams',ico:'📝',lbl:'Exams',show:perms.create_exam||perms.edit_exam},
    {id:'questions',ico:'📚',lbl:'Question Bank',show:perms.manage_questions},
    {id:'students',ico:'👥',lbl:'Students',show:perms.manage_students},
    {id:'results',ico:'📊',lbl:'Results',show:perms.access_results},
    {id:'announcements',ico:'📢',lbl:'Announcements',show:perms.send_announcements},
    {id:'anticheat',ico:'🔒',lbl:'Anti-Cheat',show:perms.view_snapshots},
    {id:'auditlogs',ico:'📋',lbl:'Activity Logs',show:perms.view_audit_logs},
    {id:'branding',ico:'🎨',lbl:'Branding',show:perms.manage_branding},
    {id:'flags',ico:'🚩',lbl:'Feature Flags',show:perms.manage_features},
  ].filter(n=>n.show);
  const logout=()=>{localStorage.removeItem('pr_token');localStorage.removeItem('pr_role');router.replace('/login');};
  if(loading)return(<div style={{minHeight:'100vh',display:'flex',alignItems:'center',justifyContent:'center',background:'#060C18',color:'#00B4FF'}}><Galaxy/><div style={{position:'relative',zIndex:1,textAlign:'center'}}><div style={{fontSize:52,marginBottom:14}}>⬡PR⬡</div><div style={{fontSize:16,fontWeight:600}}>Loading your panel...</div></div></div>);
  return(
    <div style={{minHeight:'100vh',background:'#060C18',color:'#E8F4FD',fontFamily:'Inter,system-ui,sans-serif',position:'relative'}}>
      <Galaxy/>
      {toast&&<Toast msg={toast.msg} type={toast.type}/>}
      <div style={{position:'fixed',top:0,left:0,right:0,height:56,background:'rgba(4,9,18,0.96)',backdropFilter:'blur(20px)',borderBottom:'1px solid rgba(0,140,255,0.16)',display:'flex',alignItems:'center',padding:'0 14px',zIndex:200,justifyContent:'space-between',gap:10}}>
        <div style={{display:'flex',alignItems:'center',gap:9}}>
          <button onClick={()=>setSide(s=>!s)} style={{background:'none',border:'none',color:'#8AAABB',fontSize:19,cursor:'pointer',padding:'3px 7px',lineHeight:'1'}}>☰</button>
          <div style={{display:'flex',gap:2}}>
            <div style={{width:17,height:24,background:'linear-gradient(135deg,#0050B0,#0090E0)',borderRadius:'3px 0 0 3px',display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:900,color:'#fff'}}>P</div>
            <div style={{width:17,height:24,background:'linear-gradient(135deg,#0090E0,#00FFE0)',borderRadius:'0 3px 3px 0',display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:900,color:'#050F20'}}>R</div>
          </div>
          <span style={{fontWeight:800,fontSize:15,color:'#E8F4FD'}}>ProveRank</span>
          <span style={{background:'rgba(0,80,180,0.28)',border:'1px solid rgba(0,160,255,0.32)',color:'#00B4FF',padding:'2px 9px',borderRadius:20,fontSize:10,fontWeight:800}}>⚡ ADMIN</span>
        </div>
        <div style={{display:'flex',alignItems:'center',gap:9}}>
          <span style={{color:'#5A7A9A',fontSize:12,maxWidth:100,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{user?.name}</span>
          <button onClick={logout} style={{padding:'5px 11px',background:'rgba(180,25,25,0.18)',border:'1px solid rgba(220,50,50,0.24)',color:'#FF6B6B',borderRadius:8,cursor:'pointer',fontSize:11,fontWeight:700}}>Logout</button>
        </div>
      </div>
      <div style={{display:'flex',paddingTop:56,position:'relative',zIndex:1}}>
        <div style={{width:sideOpen?205:0,overflow:'hidden',transition:'width 0.28s ease',background:'rgba(4,9,18,0.9)',backdropFilter:'blur(20px)',borderRight:'1px solid rgba(0,140,255,0.12)',position:'fixed',top:56,bottom:0,zIndex:100}}>
          <div style={{padding:'14px 0',minWidth:205,height:'100%',display:'flex',flexDirection:'column'}}>
            <div style={{padding:'0 15px 11px',borderBottom:'1px solid rgba(0,140,255,0.09)',marginBottom:5}}>
              <div style={{fontSize:9,color:'#2A5070',fontWeight:800,textTransform:'uppercase',letterSpacing:'1.5px'}}>Navigation</div>
            </div>
            <div style={{flex:1,overflowY:'auto'}}>
              {nav.map(n=>(
                <button key={n.id} onClick={()=>setTab(n.id)} style={{width:'100%',padding:'10px 16px',background:tab===n.id?'rgba(0,80,180,0.26)':'transparent',border:'none',borderLeft:`3px solid ${tab===n.id?'#00B4FF':'transparent'}`,color:tab===n.id?'#00C4FF':'#7A9AB0',textAlign:'left',cursor:'pointer',fontSize:13,fontWeight:tab===n.id?700:400,display:'flex',alignItems:'center',gap:10,transition:'all 0.16s',whiteSpace:'nowrap'}}>
                  <span style={{fontSize:15}}>{n.ico}</span><span>{n.lbl}</span>
                </button>
              ))}
              {nav.length===1&&<div style={{padding:'20px 14px',color:'#2A5070',fontSize:12,textAlign:'center',lineHeight:'1.6'}}>🔐<br/>No features enabled.<br/>Ask SuperAdmin.</div>}
            </div>
            <div style={{padding:'11px 14px',borderTop:'1px solid rgba(0,140,255,0.09)'}}>
              <div style={{display:'flex',alignItems:'center',gap:6}}><div style={{width:7,height:7,borderRadius:'50%',background:'#00FF88',boxShadow:'0 0 7px #00FF88'}}/><span style={{fontSize:9,color:'#2A5070',fontWeight:600}}>All Systems Live</span></div>
            </div>
          </div>
        </div>
        <div style={{marginLeft:sideOpen?205:0,flex:1,padding:'18px 14px 48px',transition:'margin-left 0.28s ease',minHeight:'calc(100vh - 56px)',overflowX:'hidden'}}>
          {tab==='dashboard'&&<DashSect user={user} token={token} T={T}/>}
          {tab==='exams'&&<ExamSect perms={perms} token={token} T={T}/>}
          {tab==='questions'&&<QSect token={token} T={T}/>}
          {tab==='students'&&<StudSect perms={perms} token={token} T={T}/>}
          {tab==='results'&&<ResSect perms={perms} token={token} T={T}/>}
          {tab==='announcements'&&<AnnSect token={token} T={T}/>}
          {tab==='anticheat'&&<ACSect token={token} T={T}/>}
          {tab==='auditlogs'&&<AuditSect token={token} T={T}/>}
          {tab==='branding'&&<BrandSect token={token} T={T}/>}
          {tab==='flags'&&<FlagSect token={token} T={T}/>}
        </div>
      </div>
    </div>
  );
}
