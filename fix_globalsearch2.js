const fs = require('fs')
const fp = require('path').join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let c = fs.readFileSync(fp, 'utf8')

const OLD = `  return(
    <div style={S.wrap}>
      <div style={{position:'relative',display:'flex',alignItems:'center'}}>
        <span style={{position:'absolute',left:16,fontSize:18,color:'#4D9FFF'}}>🔎</span>
        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, batches, admins..."/>
        {q.length>=2&&<span style={{position:'absolute',right:16,background:'rgba(77,159,255,0.2)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'2px 10px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>{loading?'…':totalCount+' results'}</span>}
      </div>
      {q.length>=2&&(`

const NEW = `  return(
    <div style={S.wrap}>
      {/* Search Input */}
      <div style={{position:'relative',display:'flex',alignItems:'center',marginBottom:32}}>
        <span style={{position:'absolute',left:16,fontSize:20,color:'#4D9FFF',zIndex:1}}>🔎</span>
        <input style={S.input} value={q} onChange={e=>setQ(e.target.value)} placeholder="Search tabs, students, exams, questions, batches, admins..."/>
        {q.length>=2&&<span style={{position:'absolute',right:16,background:'rgba(77,159,255,0.2)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:'2px 10px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>{loading?'…':totalCount+' results'}</span>}
      </div>

      {/* Empty State — Rich Content */}
      {q.length<2&&(
        <div>
          {/* Stats Row */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(140px,1fr))',gap:12,marginBottom:28}}>
            {[{icon:'👥',label:'Students',color:'#00C864'},{icon:'📋',label:'Exams',color:'#4D9FFF'},{icon:'📚',label:'Questions',color:'#964DFF'},{icon:'🗂️',label:'Batches',color:'#00C8C8'},{icon:'👤',label:'Admins',color:'#FFA500'},{icon:'🗂️',label:'Tabs',color:'#E8F4FF'}].map((s,i)=>(
              <div key={i} style={{background:'rgba(0,28,52,0.7)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'16px 12px',textAlign:'center',cursor:'pointer'}} onClick={()=>setActiveSection(s.label.toLowerCase())}>
                <div style={{fontSize:28,marginBottom:6}}>{s.icon}</div>
                <div style={{fontSize:12,color:s.color,fontWeight:600}}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* SVG Illustration + Info */}
          <div style={{background:'rgba(0,28,52,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:16,padding:24,marginBottom:20,textAlign:'center'}}>
            <svg width="80" height="80" viewBox="0 0 80 80" style={{marginBottom:12,opacity:0.8}}>
              <circle cx="34" cy="34" r="22" fill="none" stroke="#4D9FFF" strokeWidth="3"/>
              <circle cx="34" cy="34" r="14" fill="none" stroke="rgba(77,159,255,0.3)" strokeWidth="1.5"/>
              <line x1="50" y1="50" x2="68" y2="68" stroke="#4D9FFF" strokeWidth="3" strokeLinecap="round"/>
              <circle cx="34" cy="34" r="5" fill="rgba(77,159,255,0.5)"/>
            </svg>
            <div style={{fontSize:16,color:'#E8F4FF',fontWeight:600,marginBottom:8}}>Global Search — M12</div>
            <div style={{fontSize:12,color:'#6B8BAF',lineHeight:1.6}}>Type at least 2 characters to search across<br/>Students · Admins · Exams · Questions · Batches · Navigation Tabs</div>
          </div>

          {/* Quick Nav Tiles */}
          <div style={{marginBottom:12}}>
            <div style={{fontSize:11,color:'#4D9FFF',fontWeight:700,letterSpacing:1.2,textTransform:'uppercase',marginBottom:10}}>⚡ Quick Navigation</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(130px,1fr))',gap:8}}>
              {NAV_TABS.slice(0,12).map((t,i)=>(
                <div key={i} onClick={()=>setTab(t.tab)} style={{background:'rgba(0,28,52,0.6)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:10,padding:'10px 12px',cursor:'pointer',display:'flex',alignItems:'center',gap:8,transition:'all 0.15s'}}
                  onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='rgba(0,28,52,0.6)')}>
                  <span style={{fontSize:16}}>{t.icon}</span>
                  <span style={{fontSize:11,color:'#E8F4FF',fontWeight:500}}>{t.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Science Fact */}
          <div style={{background:'linear-gradient(135deg,rgba(0,28,52,0.8),rgba(0,50,80,0.6))',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'14px 16px',display:'flex',gap:12,alignItems:'flex-start'}}>
            <span style={{fontSize:24}}>🔬</span>
            <div>
              <div style={{fontSize:10,color:'#4D9FFF',fontWeight:700,letterSpacing:1,marginBottom:4}}>SCIENCE FACT</div>
              <div style={{fontSize:12,color:'#B0C8E0',lineHeight:1.5}}>The human brain processes visual information 60,000× faster than text — that&apos;s why ProveRank uses visual dashboards for instant insights.</div>
            </div>
          </div>
        </div>
      )}

      {q.length>=2&&(`

if(c.includes(OLD)){
  c=c.replace(OLD,NEW)
  // Fix dropdown position — make it static not absolute
  c=c.replace(
    "dropdown:{position:'absolute',top:'calc(100% + 8px)',left:0,right:0,",
    "dropdown:{position:'relative',marginTop:8,"
  )
  fs.writeFileSync(fp,c)
  console.log('✅ Done')
}else{
  // Try partial match
  const idx=c.indexOf("return(\n    <div style={S.wrap}>")
  console.log('❌ OLD not found. return( index:',idx)
  const li=c.indexOf('<input style={S.input}')
  console.log('input line area:',c.substring(li-50,li+100))
}
