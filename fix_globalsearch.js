const fs = require('fs')
const path = require('path')
const filePath = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let c = fs.readFileSync(filePath, 'utf8')

const START = '// GLOBAL SEARCH COMPONENT (M12)'
const END = '// THEME CONSTANTS'

const si = c.indexOf(START)
const ei = c.indexOf(END)

if (si === -1 || ei === -1) {
  console.log('❌ si='+si+' ei='+ei); process.exit(1)
}

const NEW = `// GLOBAL SEARCH COMPONENT (M12) — Premium Rewrite

const NAV_TABS=[
  {label:'Dashboard',tab:'dashboard',icon:'📊'},{label:'Live Monitor',tab:'live_monitor',icon:'🔴'},
  {label:'All Exams',tab:'exams',icon:'📋'},{label:'Create Exam',tab:'create_exam',icon:'➕'},
  {label:'Question Bank',tab:'questions',icon:'📚'},{label:'Smart Generator',tab:'smart_gen',icon:'🤖'},
  {label:'PYQ Bank',tab:'pyq',icon:'📜'},{label:'Bulk Upload',tab:'bulk_upload',icon:'📤'},
  {label:'All Students',tab:'students',icon:'👥'},{label:'Batch Manager',tab:'batches',icon:'🗂️'},
  {label:'Results',tab:'results',icon:'🏆'},{label:'Leaderboard',tab:'leaderboard',icon:'🥇'},
  {label:'Analytics',tab:'analytics',icon:'📈'},{label:'Anti-Cheat',tab:'anticheat',icon:'🛡️'},
  {label:'Grievances',tab:'grievances',icon:'⚖️'},{label:'Announcements',tab:'announcements',icon:'📢'},
  {label:'Email Templates',tab:'email_tmpl',icon:'📧'},{label:'Feature Flags',tab:'feature_flags',icon:'🚩'},
  {label:'Branding',tab:'branding',icon:'🎨'},{label:'SEO Settings',tab:'seo',icon:'🔍'},
  {label:'Maintenance',tab:'maintenance',icon:'🔧'},{label:'Backup',tab:'backup',icon:'💾'},
  {label:'Audit Logs',tab:'audit',icon:'🔏'},{label:'Task Manager',tab:'tasks',icon:'✅'},
  {label:'Changelog',tab:'changelog',icon:'📝'},{label:'Permissions',tab:'permissions',icon:'🔐'},
  {label:'Multi-Admin',tab:'admins',icon:'👤'},{label:'Parent Portal',tab:'parent_portal',icon:'👨‍👩‍👧'},
  {label:'Transparency',tab:'transparency',icon:'👁️'},{label:'OMR View',tab:'omr_view',icon:'📄'},
  {label:'Global Search',tab:'global_search',icon:'🔎'}
]

const GlobalSearch=memo(function GlobalSearch({setTab,token}:{setTab:(t:string)=>void;token:string}){
  const [q,setQ]=useState('')
  const [results,setResults]=useState<any>(null)
  const [loading,setLoading]=useState(false)
  const [activeSection,setActiveSection]=useState('all')
  const debRef=useRef<any>(null)

  const sections=[
    {key:'all',label:'All',icon:'🔎'},
    {key:'navigation',label:'Tabs',icon:'🗂️'},
    {key:'students',label:'Students',icon:'👥'},
    {key:'admins',label:'Admins',icon:'👤'},
    {key:'exams',label:'Exams',icon:'📋'},
    {key:'questions',label:'Questions',icon:'📚'},
    {key:'batches',label:'Batches',icon:'🗂️'},
  ]

  useEffect(()=>{
    if(debRef.current) clearTimeout(debRef.current)
    if(!q||q.length<2){setResults(null);return}
    debRef.current=setTimeout(async()=>{
      setLoading(true)
      try{
        const r=await fetch(\`\${process.env.NEXT_PUBLIC_API_URL}/api/admin/global-search?q=\${encodeURIComponent(q)}\`,{headers:{Authorization:\`Bearer \${token}\`}})
        const d=await r.json()
        if(d.success) setResults(d.results)
      }catch(e){}finally{setLoading(false)}
    },350)
  },[q])

  const navResults=NAV_TABS.filter(t=>t.label.toLowerCase().includes(q.toLowerCase()))
  const totalCount=(results?((results.students?.length||0)+(results.admins?.length||0)+(results.exams?.length||0)+(results.questions?.length||0)+(results.batches?.length||0)):0)+navResults.length

  const S:any={
    wrap:{position:'relative',width:'100%',maxWidth:720,margin:'0 auto'},
    input:{width:'100%',padding:'14px 20px 14px 48px',background:'rgba(0,28,52,0.85)',border:'1.5px solid rgba(77,159,255,0.35)',borderRadius:14,color:'#E8F4FF',fontSize:15,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box',backdropFilter:'blur(12px)'},
    dropdown:{position:'absolute',top:'calc(100% + 8px)',left:0,right:0,background:'rgba(0,20,45,0.97)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:16,boxShadow:'0 20px 60px rgba(0,0,0,0.6)',backdropFilter:'blur(20px)',zIndex:9999,maxHeight:520,overflowY:'auto'},
    tabs:{display:'flex',gap:6,padding:'12px 14px 8px',borderBottom:'1px solid rgba(77,159,255,0.1)',flexWrap:'wrap'},
    secTitle:{fontSize:10,fontWeight:700,color:'#4D9FFF',letterSpacing:1.5,textTransform:'uppercase',margin:'10px 14px 4px',display:'flex',alignItems:'center',gap:6},
    item:{display:'flex',alignItems:'center',gap:10,padding:'8px 14px',cursor:'pointer',transition:'background 0.15s'},
    label:{fontSize:13,color:'#E8F4FF',fontWeight:500,flex:1},
    sub:{fontSize:11,color:'#6B8BAF'},
    chip:(bg:string,col:string)=>({fontSize:10,padding:'2px 7px',borderRadius:10,fontWeight:600,background:bg,color:col}),
    divider:{height:1,background:'rgba(77,159,255,0.08)',margin:'4px 14px'},
  }

  const tabBtn=(active:boolean)=>({padding:'4px 12px',borderRadius:20,fontSize:11,fontWeight:600,cursor:'pointer',border:'1px solid '+(active?'#4D9FFF':'rgba(77,159,255,0.2)'),background:active?'rgba(77,159,255,0.2)':'transparent',color:active?'#4D9FFF':'#6B8BAF'})

  const show=(key:string)=>activeSection==='all'||activeSection===key

  return(
    <div style={S.wrap}>
      <div style={{position:'relative',display:'flex',alignItems:'center'}}>
        <span style={{position:'absolute',left:16,fontSize:18,color:'#4D9FFF'}}>🔎</span>
        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, batches, admins..."/>
        {q.length>=2&&<span style={{position:'absolute',right:16,background:'rgba(77,159,255,0.2)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'2px 10px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>{loading?'…':totalCount+' results'}</span>}
      </div>
      {q.length>=2&&(
        <div style={S.dropdown}>
          <div style={S.tabs}>
            {sections.map(s=><button key={s.key} onClick={()=>setActiveSection(s.key)} style={tabBtn(activeSection===s.key)}>{s.icon} {s.label}</button>)}
          </div>
          {loading&&<div style={{textAlign:'center',padding:'20px',color:'#4D9FFF'}}>⏳ Searching...</div>}
          {!loading&&totalCount===0&&<div style={{textAlign:'center',padding:'28px',color:'#6B8BAF'}}>🔍 No results for "<span style={{color:'#4D9FFF'}}>{q}</span>"</div>}
          {!loading&&totalCount>0&&<div>
            {show('navigation')&&navResults.length>0&&<div>
              <div style={S.secTitle}>🗂️ Navigation / Tabs</div>
              {navResults.slice(0,6).map((t,i)=>(
                <div key={i} style={S.item} onClick={()=>setTab(t.tab)}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>{t.icon}</span>
                  <span style={S.label}>{t.label}</span>
                  <span style={S.chip('rgba(77,159,255,0.15)','#4D9FFF')}>Tab</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('students')&&results?.students?.length>0&&<div>
              <div style={S.secTitle}>👥 Students ({results.students.length})</div>
              {results.students.map((s:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('students')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>👤</span>
                  <div style={{flex:1}}><div style={S.label}>{s.name||'—'}</div><div style={S.sub}>{s.email}{s.studentId?' · '+s.studentId:''}</div></div>
                  <span style={S.chip('rgba(0,200,100,0.15)','#00C864')}>Student</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('admins')&&results?.admins?.length>0&&<div>
              <div style={S.secTitle}>👤 Admins ({results.admins.length})</div>
              {results.admins.map((a:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('admins')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>🔑</span>
                  <div style={{flex:1}}><div style={S.label}>{a.name||'—'}</div><div style={S.sub}>{a.email}{a.adminId?' · '+a.adminId:''}</div></div>
                  <span style={S.chip('rgba(255,165,0,0.15)','#FFA500')}>{a.role==='superadmin'?'SuperAdmin':'Admin'}</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('exams')&&results?.exams?.length>0&&<div>
              <div style={S.secTitle}>📋 Exams ({results.exams.length})</div>
              {results.exams.map((ex:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('exams')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>📋</span>
                  <div style={{flex:1}}><div style={S.label}>{ex.title}</div><div style={S.sub}>{ex.status}</div></div>
                  <span style={S.chip('rgba(77,159,255,0.15)','#4D9FFF')}>Exam</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('questions')&&results?.questions?.length>0&&<div>
              <div style={S.secTitle}>📚 Questions ({results.questions.length})</div>
              {results.questions.map((qu:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('questions')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>❓</span>
                  <div style={{flex:1}}><div style={S.label}>{(qu.text||'').slice(0,65)}{(qu.text||'').length>65?'…':''}</div><div style={S.sub}>{qu.subject}{qu.chapter?' · '+qu.chapter:''}{qu.difficulty?' · '+qu.difficulty:''}</div></div>
                  <span style={S.chip('rgba(150,77,255,0.15)','#964DFF')}>Q</span>
                </div>
              ))}
              <div style={S.divider}/>
            </div>}
            {show('batches')&&results?.batches?.length>0&&<div>
              <div style={S.secTitle}>🗂️ Batches ({results.batches.length})</div>
              {results.batches.map((b:any,i:number)=>(
                <div key={i} style={S.item} onClick={()=>setTab('batches')}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                  <span style={{fontSize:18}}>🗂️</span>
                  <div style={{flex:1}}><div style={S.label}>{b.name}</div><div style={S.sub}>{b.description||''}</div></div>
                  <span style={S.chip('rgba(0,200,200,0.15)','#00C8C8')}>Batch</span>
                </div>
              ))}
            </div>}
          </div>}
        </div>
      )}
    </div>
  )
})

`

c = c.slice(0, si) + NEW + c.slice(ei)
fs.writeFileSync(filePath, c)
console.log('✅ Done! Lines: ' + c.split('\n').length)
