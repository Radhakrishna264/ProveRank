#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — Feature 25: QB Stats Dashboard (Frontend)     ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
FE=/home/runner/workspace/frontend/app/admin/x7k2p
PAGE=$FE/page.tsx
echo "🚀 Feature 25 Frontend setup..."

# ── Create QBankStatsDashboard.tsx ────────────────────────────────────────────
cat > $FE/QBankStatsDashboard.tsx << 'ENDOFFILE'
'use client'
import { useState, useEffect, useCallback } from 'react'

// ── Design tokens ──────────────────────────────────────────────────────────────
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', PRP='#A78BFA'
const PHY='#60A5FA', CHM='#F472B6', BIO='#34D399', MTH='#FBBF24'
const BOR='rgba(77,159,255,0.15)', CRD='rgba(0,15,35,0.85)'
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:9,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:12,transition:'all 0.2s'}
const bg_:any={background:'rgba(0,25,55,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:9,padding:'8px 14px',cursor:'pointer',fontSize:12,transition:'all 0.2s'}
const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:16,padding:'18px',backdropFilter:'blur(14px)'}

interface Props { token:string; API:string; T:(m:string,t?:'s'|'e'|'w')=>void }

// ── SVG Donut Chart (no external lib) ──────────────────────────────────────────
function DonutChart({data,size=130,strokeW=22}:{data:{label:string;value:number;color:string}[];size?:number;strokeW?:number}){
  const total = data.reduce((s,d)=>s+d.value,0)||1
  const r = (size-strokeW)/2, cx=size/2, cy=size/2, circ=2*Math.PI*r
  let offset=0
  return(
    <svg width={size} height={size} style={{transform:'rotate(-90deg)'}}>
      <circle cx={cx} cy={cy} r={r} fill='none' stroke='rgba(255,255,255,0.05)' strokeWidth={strokeW}/>
      {data.map((d,i)=>{
        const pct=d.value/total
        const dash=pct*circ, gap=circ-dash, o=offset
        offset+=dash
        return <circle key={i} cx={cx} cy={cy} r={r} fill='none' stroke={d.color} strokeWidth={strokeW}
          strokeDasharray={`${dash} ${gap}`} strokeDashoffset={-o} strokeLinecap='round'
          style={{transition:'stroke-dasharray 0.8s ease'}}/>
      })}
    </svg>
  )
}

// ── Mini Bar Chart ────────────────────────────────────────────────────────────
function BarChart({data,height=80}:{data:{label:string;value:number;color:string}[];height?:number}){
  const max=Math.max(...data.map(d=>d.value),1)
  return(
    <div style={{display:'flex',alignItems:'flex-end',gap:6,height,justifyContent:'space-around'}}>
      {data.map((d,i)=>{
        const h=Math.max(4,Math.round((d.value/max)*height))
        return(
          <div key={i} style={{display:'flex',flexDirection:'column' as any,alignItems:'center',gap:3,flex:1}}>
            <span style={{fontSize:9,color:DIM,fontWeight:700}}>{d.value}</span>
            <div style={{width:'100%',height:h,background:`linear-gradient(180deg,${d.color},${d.color}66)`,borderRadius:'4px 4px 0 0',transition:'height 0.7s ease',boxShadow:`0 0 8px ${d.color}33`}}/>
            <span style={{fontSize:8,color:DIM,whiteSpace:'nowrap' as any,overflow:'hidden',maxWidth:'100%',textAlign:'center' as any}}>{d.label}</span>
          </div>
        )
      })}
    </div>
  )
}

// ── Health Score Gauge ────────────────────────────────────────────────────────
function HealthGauge({score,label}:{score:number;label:string}){
  const col=score>=85?SUC:score>=70?'#34D399':score>=50?WRN:DNG
  const pct=score/100
  const r=54,cx=70,cy=70,circ=2*Math.PI*r
  const half=circ/2 // semicircle
  return(
    <div style={{textAlign:'center' as any}}>
      <svg width={140} height={80} style={{overflow:'visible'}}>
        {/* Track */}
        <path d={`M 16,70 A ${r},${r} 0 0 1 124,70`} fill='none' stroke='rgba(255,255,255,0.06)' strokeWidth={14} strokeLinecap='round'/>
        {/* Fill */}
        <path d={`M 16,70 A ${r},${r} 0 0 1 124,70`} fill='none' stroke={col} strokeWidth={14} strokeLinecap='round'
          strokeDasharray={`${pct*half*0.98} ${half}`} style={{transition:'stroke-dasharray 1s ease',filter:`drop-shadow(0 0 6px ${col}88)`}}/>
        {/* Score text */}
        <text x={70} y={66} textAnchor='middle' fill={col} fontSize={22} fontWeight={900} fontFamily='Inter,sans-serif'>{score}</text>
        <text x={70} y={80} textAnchor='middle' fill={DIM} fontSize={10} fontFamily='Inter,sans-serif'>/100</text>
      </svg>
      <div style={{fontSize:11,fontWeight:700,color:col,marginTop:-6}}>{label}</div>
    </div>
  )
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
function StatCard({ico,label,value,sub,col,onClick}:{ico:string;label:string;value:number|string;sub?:string;col:string;onClick?:()=>void}){
  return(
    <div onClick={onClick} style={{...cs,cursor:onClick?'pointer':'default',borderColor:`${col}25`,transition:'all 0.2s'}}
      onMouseEnter={e=>onClick&&((e.currentTarget as HTMLElement).style.borderColor=`${col}55`)}
      onMouseLeave={e=>onClick&&((e.currentTarget as HTMLElement).style.borderColor=`${col}25`)}>
      <div style={{display:'flex',alignItems:'flex-start',justifyContent:'space-between',marginBottom:6}}>
        <div style={{fontSize:24}}>{ico}</div>
        <div style={{width:8,height:8,borderRadius:'50%',background:col,boxShadow:`0 0 8px ${col}`}}/>
      </div>
      <div style={{fontSize:26,fontWeight:900,color:col,lineHeight:1,marginBottom:4,fontFamily:'Inter,sans-serif'}}>{value}</div>
      <div style={{fontSize:12,color:TS,fontWeight:600}}>{label}</div>
      {sub&&<div style={{fontSize:10,color:DIM,marginTop:3}}>{sub}</div>}
    </div>
  )
}

export default function QBankStatsDashboard({token,API,T}:Props){
  const [stats, setStats]     = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [tab, setTab]         = useState<'overview'|'quality'|'growth'|'contributors'>('overview')
  const [exporting, setExporting] = useState(false)
  const [showNeverUsed, setShowNeverUsed] = useState(false)
  const [neverUsed, setNeverUsed] = useState<any[]>([])
  const hdrs = { Authorization: `Bearer ${token}` }

  const loadStats = useCallback(async()=>{
    setLoading(true)
    try{
      const r = await fetch(`${API}/api/question-bank/stats`, { headers: hdrs })
      const d = await r.json()
      if(d.success) setStats(d)
      else T(d.message||'Failed to load stats','e')
    }catch{ T('Network error','e') }
    setLoading(false)
  },[token, API])

  useEffect(()=>{ loadStats() },[loadStats])

  // 25.8 — Export as Excel (CSV)
  const exportExcel = async()=>{
    setExporting(true)
    try{
      const r = await fetch(`${API}/api/question-bank/stats/export`, { headers: hdrs })
      const d = await r.json()
      if(!d.success){ T('Export failed','e'); return }
      const rows:any[] = d.rows
      const header = Object.keys(rows[0]||{}).join(',')
      const body   = rows.map((r:any)=>Object.values(r).map((v:any)=>`"${String(v).replace(/"/g,'""')}"`).join(',')).join('\n')
      const csv    = header + '\n' + body
      const blob   = new Blob([csv],{type:'text/csv'})
      const url    = URL.createObjectURL(blob)
      const a      = document.createElement('a')
      a.href=url; a.download=`QB_Stats_${new Date().toISOString().slice(0,10)}.csv`
      document.body.appendChild(a); a.click(); document.body.removeChild(a)
      URL.revokeObjectURL(url)
      T('Stats exported as CSV ✅')
    }catch{ T('Export error','e') }
    setExporting(false)
  }

  // 25.8 — Export as PDF (print window)
  const exportPDF = ()=>{
    if(!stats) return
    const h = stats.health
    const win = window.open('','_blank')
    if(!win) return
    win.document.write(`
      <html><head><title>QB Stats Report</title>
      <style>body{font-family:Arial,sans-serif;padding:20px;color:#222}
      h1{color:#1a1a2e}table{border-collapse:collapse;width:100%;margin:16px 0}
      th{background:#0055CC;color:#fff;padding:8px 12px;text-align:left}
      td{padding:8px 12px;border-bottom:1px solid #eee}
      .health{font-size:32px;font-weight:900;color:${h.score>=70?'green':'orange'}}
      </style></head><body>
      <h1>📊 Question Bank Statistics Report</h1>
      <p>Generated: ${new Date().toLocaleString('en-IN')}</p>
      <h2>Overview</h2>
      <table><tr><th>Metric</th><th>Value</th></tr>
        <tr><td>Total Questions</td><td>${stats.overview.total}</td></tr>
        <tr><td>Added This Week</td><td>${stats.overview.addedThisWeek}</td></tr>
        <tr><td>Added This Month</td><td>${stats.overview.addedThisMonth}</td></tr>
        <tr><td>With Explanation</td><td>${stats.overview.withExplanation}</td></tr>
        <tr><td>With Image</td><td>${stats.overview.withImage}</td></tr>
        <tr><td>Never Used</td><td>${stats.overview.neverUsed}</td></tr>
        <tr><td>PYQ Count</td><td>${stats.overview.pyqCount}</td></tr>
      </table>
      <h2>Bank Health Score</h2>
      <div class="health">${h.score}/100 — ${h.label}</div>
      <h2>Type Distribution</h2>
      <table><tr><th>Type</th><th>Count</th></tr>
        ${Object.entries(stats.byType||{}).map(([k,v])=>`<tr><td>${k}</td><td>${v}</td></tr>`).join('')}
      </table>
      <h2>Approval Status</h2>
      <table><tr><th>Status</th><th>Count</th></tr>
        ${Object.entries(stats.byApproval||{}).map(([k,v])=>`<tr><td>${k}</td><td>${v}</td></tr>`).join('')}
      </table>
      <h2>Top Contributors</h2>
      <table><tr><th>Name</th><th>Questions Added</th></tr>
        ${(stats.contributors||[]).map((c:any)=>`<tr><td>${c.name}</td><td>${c.count}</td></tr>`).join('')}
      </table>
      <h2>Most Used Questions (Top 10)</h2>
      <table><tr><th>#</th><th>Question</th><th>Subject</th><th>Uses</th></tr>
        ${(stats.mostUsed||[]).map((q:any,i:number)=>`<tr><td>${i+1}</td><td>${q.text}</td><td>${q.subject}</td><td>${q.usageCount}</td></tr>`).join('')}
      </table>
      <script>window.print();window.close();</script>
      </body></html>
    `)
    win.document.close()
  }

  // Load never-used list
  const loadNeverUsed = async()=>{
    try{
      const r = await fetch(`${API}/api/question-bank/never-used?limit=20`, { headers: hdrs })
      const d = await r.json()
      if(d.success) setNeverUsed(d.questions||[])
    }catch{}
    setShowNeverUsed(true)
  }

  if(loading) return(
    <div style={{textAlign:'center' as any,padding:'80px 20px'}}>
      <div style={{fontSize:48,marginBottom:12,animation:'spin 1s linear infinite'}}>⟳</div>
      <div style={{color:DIM,fontSize:13}}>Loading stats dashboard...</div>
    </div>
  )

  if(!stats) return(
    <div style={{textAlign:'center' as any,padding:'60px 20px'}}>
      <div style={{fontSize:48,marginBottom:12}}>📊</div>
      <div style={{color:TS,fontWeight:700,marginBottom:8}}>Stats not loaded</div>
      <button onClick={loadStats} style={bp}>🔄 Load Stats</button>
    </div>
  )

  const ov = stats.overview
  const h  = stats.health

  const typeData = Object.entries(stats.byType||{}).map(([k,v]:any)=>({
    label:k, value:v,
    color:k==='SCQ'?ACC:k==='MSQ'?PRP:k==='Integer'?WRN:'#94A3B8'
  }))
  const approvalData = [
    {label:'Approved',value:stats.byApproval.approved||0,color:SUC},
    {label:'Pending', value:stats.byApproval.pending||0, color:WRN},
    {label:'Rejected',value:stats.byApproval.rejected||0,color:DNG},
  ]
  const subjData = Object.entries(stats.bySubject||{}).slice(0,6).map(([k,v]:any)=>({
    label:k.slice(0,4), value:v,
    color:k==='Physics'?PHY:k==='Chemistry'?CHM:k==='Biology'?BIO:k==='Math'?MTH:'#94A3B8'
  }))
  const diffData = [
    {label:'Easy',  value:stats.byDifficulty?.Easy||stats.byDifficulty?.easy||0,  color:SUC},
    {label:'Med',   value:stats.byDifficulty?.Medium||stats.byDifficulty?.medium||0,color:WRN},
    {label:'Hard',  value:stats.byDifficulty?.Hard||stats.byDifficulty?.hard||0,  color:DNG},
  ]

  return(
    <div style={{fontFamily:'Inter,sans-serif'}}>
      {/* ── Header ────────────────────────────────────────────────────────────── */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap' as any,gap:12,marginBottom:20}}>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,background:`linear-gradient(90deg,${ACC},${PRP})`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',marginBottom:3}}>
            📊 Question Bank Stats Dashboard
          </div>
          <div style={{fontSize:11,color:DIM}}>
            Last updated: {new Date(stats.fetchedAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'})}
          </div>
        </div>
        <div style={{display:'flex',gap:8,flexWrap:'wrap' as any}}>
          <button onClick={loadStats} style={{...bg_,fontSize:11,padding:'7px 12px'}}>🔄 Refresh</button>
          <button onClick={exportExcel} disabled={exporting} style={{...bg_,fontSize:11,padding:'7px 12px',color:SUC,borderColor:`${SUC}33`}}>
            {exporting?'⟳':'📊'} Export CSV
          </button>
          <button onClick={exportPDF} style={{...bg_,fontSize:11,padding:'7px 12px',color:WRN,borderColor:`${WRN}33`}}>🖨️ PDF Report</button>
        </div>
      </div>

      {/* ── Tab Nav ───────────────────────────────────────────────────────────── */}
      <div style={{display:'flex',gap:4,marginBottom:18,background:'rgba(0,10,30,0.6)',borderRadius:12,padding:5,border:`1px solid ${BOR}`}}>
        {([['overview','📊 Overview'],['quality','🏅 Quality'],['growth','📈 Growth'],['contributors','👤 Contributors']] as const).map(([v,l])=>(
          <button key={v} onClick={()=>setTab(v as any)}
            style={{flex:1,padding:'8px 6px',borderRadius:9,border:'none',cursor:'pointer',fontSize:11,fontWeight:tab===v?700:400,transition:'all 0.2s',
              background:tab===v?`linear-gradient(135deg,${ACC},${PRP})`:'transparent',
              color:tab===v?'#fff':DIM}}>
            {l}
          </button>
        ))}
      </div>

      {/* ════════════════ OVERVIEW TAB ════════════════════════════════════════ */}
      {tab==='overview'&&(
        <div>
          {/* Stat cards grid */}
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(150px,1fr))',gap:10,marginBottom:16}}>
            <StatCard ico='❓' label='Total Questions' value={ov.total} col={ACC}/>
            <StatCard ico='📅' label='This Week' value={ov.addedThisWeek} sub='New additions' col={SUC}/>
            <StatCard ico='📆' label='This Month' value={ov.addedThisMonth} sub='New additions' col={PHY}/>
            <StatCard ico='🖼️' label='With Image' value={ov.withImage} sub={`${Math.round(ov.withImage/ov.total*100)||0}% coverage`} col={PRP}/>
            <StatCard ico='💡' label='Explained' value={ov.withExplanation} sub={`${Math.round(ov.withExplanation/ov.total*100)||0}% coverage`} col={WRN}/>
            <StatCard ico='😴' label='Never Used' value={ov.neverUsed} sub='Click to view' col={DNG} onClick={loadNeverUsed}/>
            <StatCard ico='📜' label='PYQ Count' value={ov.pyqCount} col={GOLD}/>
            <StatCard ico='✅' label='Used 1+ times' value={ov.usedAtLeastOnce} col={SUC}/>
          </div>

          {/* Charts row */}
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
            {/* Type distribution donut — 25.1 */}
            <div style={cs}>
              <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📋 Type Distribution</div>
              <div style={{display:'flex',justifyContent:'center',marginBottom:10}}>
                <DonutChart data={typeData} size={130} strokeW={22}/>
              </div>
              <div style={{display:'flex',flexDirection:'column' as any,gap:6}}>
                {typeData.map(d=>(
                  <div key={d.label} style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <div style={{display:'flex',alignItems:'center',gap:7}}>
                      <div style={{width:8,height:8,borderRadius:'50%',background:d.color,flexShrink:0}}/>
                      <span style={{fontSize:11,color:TS}}>{d.label}</span>
                    </div>
                    <div style={{display:'flex',gap:6,alignItems:'center'}}>
                      <span style={{fontSize:11,fontWeight:700,color:d.color}}>{d.value}</span>
                      <span style={{fontSize:10,color:DIM}}>({Math.round(d.value/ov.total*100)||0}%)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Approval breakdown donut — 25.2 */}
            <div style={cs}>
              <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>✅ Approval Status</div>
              <div style={{display:'flex',justifyContent:'center',marginBottom:10}}>
                <DonutChart data={approvalData} size={130} strokeW={22}/>
              </div>
              <div style={{display:'flex',flexDirection:'column' as any,gap:6}}>
                {approvalData.map(d=>(
                  <div key={d.label} style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                    <div style={{display:'flex',alignItems:'center',gap:7}}>
                      <div style={{width:8,height:8,borderRadius:'50%',background:d.color,flexShrink:0}}/>
                      <span style={{fontSize:11,color:TS}}>{d.label}</span>
                    </div>
                    <div style={{display:'flex',gap:6,alignItems:'center'}}>
                      <span style={{fontSize:11,fontWeight:700,color:d.color}}>{d.value}</span>
                      <span style={{fontSize:10,color:DIM}}>({Math.round(d.value/ov.total*100)||0}%)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Subject + Difficulty bar charts */}
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
            <div style={cs}>
              <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>🔬 By Subject</div>
              <BarChart data={subjData} height={80}/>
            </div>
            <div style={cs}>
              <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📊 By Difficulty</div>
              <BarChart data={diffData} height={80}/>
            </div>
          </div>

          {/* Quality quick-stats — 25.3 25.4 */}
          <div style={{...cs,background:'rgba(0,10,30,0.9)',borderColor:`${WRN}22`}}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>⚡ Quick Quality Checks</div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              {[
                {l:'✅ With Explanation',v:ov.withExplanation,t:ov.total,col:SUC},
                {l:'❌ Missing Explanation',v:ov.total-ov.withExplanation,t:ov.total,col:DNG},
                {l:'🖼️ With Image',v:ov.withImage,t:ov.total,col:PHY},
                {l:'😴 Never Used',v:ov.neverUsed,t:ov.total,col:WRN},
              ].map(x=>{
                const pct=Math.round(x.v/x.t*100)||0
                return(
                  <div key={x.l} style={{background:'rgba(255,255,255,0.02)',borderRadius:10,padding:'10px 12px',border:`1px solid ${x.col}18`}}>
                    <div style={{fontSize:11,color:DIM,marginBottom:4}}>{x.l}</div>
                    <div style={{fontSize:18,fontWeight:800,color:x.col,marginBottom:4}}>{x.v}</div>
                    <div style={{background:'rgba(255,255,255,0.05)',borderRadius:4,height:4,overflow:'hidden'}}>
                      <div style={{width:`${pct}%`,height:'100%',background:x.col,borderRadius:4,transition:'width 0.7s ease'}}/>
                    </div>
                    <div style={{fontSize:9,color:DIM,marginTop:3,textAlign:'right' as any}}>{pct}%</div>
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      )}

      {/* ════════════════ QUALITY TAB ═════════════════════════════════════════ */}
      {tab==='quality'&&(
        <div>
          {/* Health Score — 25.9 */}
          <div style={{...cs,marginBottom:14,background:'rgba(0,10,30,0.95)',border:`1px solid ${h.score>=70?SUC:WRN}33`}}>
            <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:16,display:'flex',alignItems:'center',gap:8}}>
              🏅 Bank Quality Score
              <span style={{fontSize:10,color:DIM,fontWeight:400}}>Based on explanations, images, approval rate, usage</span>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'auto 1fr',gap:24,alignItems:'center'}}>
              <HealthGauge score={h.score} label={h.label}/>
              <div>
                <div style={{display:'flex',flexDirection:'column' as any,gap:8}}>
                  {[
                    {l:'Explanations',v:h.breakdown.explScore,max:30,col:ACC},
                    {l:'Images',v:h.breakdown.imgScore,max:20,col:PRP},
                    {l:'Approval Rate',v:h.breakdown.apprScore,max:25,col:SUC},
                    {l:'Usage Rate',v:h.breakdown.usageScore,max:15,col:WRN},
                    {l:'PYQ Coverage',v:h.breakdown.pyqScore,max:10,col:GOLD},
                  ].map(x=>(
                    <div key={x.l}>
                      <div style={{display:'flex',justifyContent:'space-between',fontSize:10,marginBottom:3}}>
                        <span style={{color:DIM}}>{x.l}</span>
                        <span style={{color:x.col,fontWeight:700}}>{x.v}/{x.max}</span>
                      </div>
                      <div style={{background:'rgba(255,255,255,0.05)',borderRadius:4,height:5,overflow:'hidden'}}>
                        <div style={{width:`${(x.v/x.max)*100}%`,height:'100%',background:`linear-gradient(90deg,${x.col}88,${x.col})`,borderRadius:4,transition:'width 0.8s ease'}}/>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <div style={{marginTop:14,padding:'10px 14px',background:`rgba(${h.score>=70?'0,196,140':'255,184,77'},0.06)`,borderRadius:10,border:`1px solid ${h.score>=70?SUC:WRN}22`,fontSize:11,color:h.score>=70?SUC:WRN}}>
              {h.score>=85?'🌟 Excellent quality bank! Keep maintaining explanations and images for every question.'
              :h.score>=70?'👍 Good bank quality. Focus on adding explanations to questions missing them.'
              :h.score>=50?'⚠️ Fair quality. Add explanations, images, and get questions approved.'
              :'🚨 Bank needs attention. Many questions lack explanations or approval.'}
            </div>
          </div>

          {/* Most used questions — 25.6 */}
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>🔥 Most Used Questions (Top 10)</div>
            {(stats.mostUsed||[]).length===0?(
              <div style={{textAlign:'center' as any,padding:'30px',color:DIM}}>No usage data yet</div>
            ):(
              <div style={{display:'flex',flexDirection:'column' as any,gap:6}}>
                {(stats.mostUsed||[]).map((q:any,i:number)=>(
                  <div key={q._id} style={{display:'flex',gap:10,alignItems:'center',padding:'8px 10px',background:'rgba(255,255,255,0.02)',borderRadius:10,border:`1px solid ${BOR}`}}>
                    <div style={{width:24,height:24,borderRadius:'50%',background:`linear-gradient(135deg,${ACC},${PRP})`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:10,fontWeight:900,color:'#fff',flexShrink:0}}>
                      {i+1}
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontSize:11,color:TS,overflow:'hidden',whiteSpace:'nowrap' as any,textOverflow:'ellipsis'}}>{q.text}</div>
                      <div style={{fontSize:9,color:DIM,marginTop:2}}>{q.subject} · {q.chapter||'—'}</div>
                    </div>
                    <div style={{flexShrink:0,textAlign:'center' as any}}>
                      <div style={{fontSize:14,fontWeight:800,color:ACC}}>{q.usageCount}</div>
                      <div style={{fontSize:8,color:DIM}}>uses</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ════════════════ GROWTH TAB ══════════════════════════════════════════ */}
      {tab==='growth'&&(
        <div>
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:14}}>
            <div style={{...cs,borderColor:`${SUC}22`,textAlign:'center' as any}}>
              <div style={{fontSize:32,fontWeight:900,color:SUC}}>{ov.addedThisWeek}</div>
              <div style={{fontSize:12,color:TS,fontWeight:600}}>Questions This Week</div>
              <div style={{fontSize:10,color:DIM,marginTop:3}}>Last 7 days</div>
            </div>
            <div style={{...cs,borderColor:`${PHY}22`,textAlign:'center' as any}}>
              <div style={{fontSize:32,fontWeight:900,color:PHY}}>{ov.addedThisMonth}</div>
              <div style={{fontSize:12,color:TS,fontWeight:600}}>Questions This Month</div>
              <div style={{fontSize:10,color:DIM,marginTop:3}}>Last 30 days</div>
            </div>
          </div>

          {/* 25.10 — Week-over-week growth graph */}
          <div style={{...cs,marginBottom:14}}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:16}}>📈 Week-over-Week Growth (Last 12 Weeks)</div>
            {(stats.weeklyGrowth||[]).length===0?(
              <div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>Not enough data yet</div>
            ):(()=>{
              const maxV = Math.max(...(stats.weeklyGrowth||[]).map((w:any)=>w.count),1)
              return(
                <div>
                  <div style={{display:'flex',alignItems:'flex-end',gap:4,height:100,marginBottom:8}}>
                    {(stats.weeklyGrowth||[]).map((w:any,i:number)=>{
                      const h=Math.max(4,Math.round((w.count/maxV)*100))
                      const isLast=i===(stats.weeklyGrowth.length-1)
                      return(
                        <div key={i} style={{flex:1,display:'flex',flexDirection:'column' as any,alignItems:'center',justifyContent:'flex-end',height:'100%',gap:3}} title={`${w.week}: ${w.count} questions`}>
                          <span style={{fontSize:8,color:DIM,fontWeight:isLast?700:400}}>{w.count}</span>
                          <div style={{width:'100%',height:`${h}%`,background:isLast?`linear-gradient(180deg,${SUC},${SUC}88)`:`linear-gradient(180deg,${ACC}88,${ACC}44)`,borderRadius:'4px 4px 0 0',transition:'height 0.7s ease'}}/>
                        </div>
                      )
                    })}
                  </div>
                  <div style={{display:'flex',gap:4}}>
                    {(stats.weeklyGrowth||[]).map((w:any,i:number)=>(
                      <div key={i} style={{flex:1,fontSize:7,color:DIM,textAlign:'center' as any,overflow:'hidden'}}>
                        {w.week.split('/')[0]}
                      </div>
                    ))}
                  </div>
                </div>
              )
            })()}
          </div>

          {/* Trend summary */}
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:12}}>📊 Activity Summary</div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:10}}>
              {[
                {l:'Total Active',v:ov.total,col:ACC},
                {l:'PYQ Added',v:ov.pyqCount,col:GOLD},
                {l:'Used 1+x',v:ov.usedAtLeastOnce,col:SUC},
              ].map(x=>(
                <div key={x.l} style={{textAlign:'center' as any,padding:12,background:'rgba(255,255,255,0.02)',borderRadius:10,border:`1px solid ${x.col}18`}}>
                  <div style={{fontSize:22,fontWeight:900,color:x.col}}>{x.v}</div>
                  <div style={{fontSize:10,color:DIM,marginTop:3}}>{x.l}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ════════════════ CONTRIBUTORS TAB ═══════════════════════════════════ */}
      {tab==='contributors'&&(
        <div>
          <div style={cs}>
            <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:14}}>👤 Top Contributors (25.11)</div>
            {(stats.contributors||[]).length===0?(
              <div style={{textAlign:'center' as any,padding:'40px',color:DIM}}>No contributor data</div>
            ):(
              <div style={{display:'flex',flexDirection:'column' as any,gap:8}}>
                {(stats.contributors||[]).map((c:any,i:number)=>{
                  const pct=Math.round(c.count/ov.total*100)||0
                  const podiumCol=i===0?GOLD:i===1?'#C0C0C0':i===2?'#CD7F32':ACC
                  return(
                    <div key={c._id||i} style={{display:'flex',gap:12,alignItems:'center',padding:'10px 14px',background:i<3?`rgba(${i===0?'255,215,0':i===1?'192,192,192':'205,127,50'},0.05)`:'rgba(255,255,255,0.02)',borderRadius:12,border:`1px solid ${podiumCol}22`}}>
                      <div style={{width:30,height:30,borderRadius:'50%',background:`linear-gradient(135deg,${podiumCol},${podiumCol}88)`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:12,fontWeight:900,color:'#000',flexShrink:0,boxShadow:`0 2px 8px ${podiumCol}44`}}>
                        {i===0?'🥇':i===1?'🥈':i===2?'🥉':i+1}
                      </div>
                      <div style={{flex:1,minWidth:0}}>
                        <div style={{fontSize:12,color:TS,fontWeight:600,marginBottom:2}}>{c.name||'Unknown'}</div>
                        <div style={{fontSize:9,color:DIM,marginBottom:4}}>{c.email||c.role}</div>
                        <div style={{background:'rgba(255,255,255,0.05)',borderRadius:3,height:4,overflow:'hidden'}}>
                          <div style={{width:`${pct}%`,height:'100%',background:`linear-gradient(90deg,${podiumCol}88,${podiumCol})`,borderRadius:3,transition:'width 0.8s ease'}}/>
                        </div>
                      </div>
                      <div style={{textAlign:'center' as any,flexShrink:0}}>
                        <div style={{fontSize:18,fontWeight:900,color:podiumCol}}>{c.count}</div>
                        <div style={{fontSize:9,color:DIM}}>questions</div>
                        <div style={{fontSize:8,color:DIM}}>{pct}%</div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ══ Never Used Modal — 25.5 ══════════════════════════════════════════ */}
      {showNeverUsed&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99990,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}
          onClick={()=>setShowNeverUsed(false)}>
          <div style={{...cs,width:'100%',maxWidth:540,maxHeight:'88vh',overflowY:'auto' as any,border:`1.5px solid ${DNG}33`}}
            onClick={e=>e.stopPropagation()}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
              <div>
                <div style={{fontWeight:800,fontSize:15,color:DNG}}>😴 Never Used Questions</div>
                <div style={{fontSize:10,color:DIM,marginTop:2}}>{ov.neverUsed} questions never added to any exam</div>
              </div>
              <button onClick={()=>setShowNeverUsed(false)} style={{background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:22}}>✕</button>
            </div>
            {neverUsed.length===0?(
              <div style={{textAlign:'center' as any,padding:'30px',color:DIM}}>Loading...</div>
            ):(
              neverUsed.map((q:any,i:number)=>(
                <div key={q._id||i} style={{padding:'10px 12px',borderRadius:10,background:'rgba(255,255,255,0.02)',border:`1px solid ${BOR}`,marginBottom:7}}>
                  <div style={{fontSize:12,color:'#CBD5E1',lineHeight:1.5,marginBottom:5}}>
                    {(q.text||'').slice(0,100)}{(q.text||'').length>100?'…':''}
                  </div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap' as any}}>
                    {q.subject&&<span style={{fontSize:9,color:PHY,background:`${PHY}10`,borderRadius:8,padding:'1px 7px',border:`1px solid ${PHY}22`}}>{q.subject}</span>}
                    {q.chapter&&<span style={{fontSize:9,color:DIM,background:'rgba(255,255,255,0.03)',borderRadius:8,padding:'1px 7px'}}>{q.chapter}</span>}
                    {q.difficulty&&<span style={{fontSize:9,color:WRN}}>{q.difficulty}</span>}
                    <span style={{fontSize:9,color:DIM,marginLeft:'auto'}}>Added {new Date(q.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'2-digit'})}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
ENDOFFILE
echo "✅ QBankStatsDashboard.tsx created"

# ── Patch page.tsx: import + replace qbank_stats tab ─────────────────────────
node << 'EOF'
const fs   = require('fs');
const file = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');

// 1. Add import
if (!c.includes('QBankStatsDashboard')) {
  c = c.replace("'use client'", "'use client'\nimport QBankStatsDashboard from './QBankStatsDashboard'");
  console.log('✅ QBankStatsDashboard imported');
} else { console.log('✅ Import present'); }

// 2. Replace qbank_stats tab content
const START = "          {tab==='qbank_stats'&&(\n            <div>";
const END   = "            </div>\n          )}";

const si = c.indexOf(START);
const ei = c.indexOf(END, si);
if (si === -1 || ei === -1) {
  console.log('❌ qbank_stats section not found');
  console.log('Start found:', si !== -1, 'End found:', ei !== -1);
  process.exit(1);
}

const NEW_TAB = `          {tab==='qbank_stats'&&(
            <QBankStatsDashboard
              token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''}
              API={API}
              T={T}
            />
          )}`;

c = c.substring(0, si) + NEW_TAB + c.substring(ei + END.length);
fs.writeFileSync(file, c);
console.log('✅ qbank_stats tab replaced with QBankStatsDashboard component');
EOF

# ── Verification ──────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Feature 25 Frontend — Verification"
echo "════════════════════════════════════════════════════════════"
F=$FE/QBankStatsDashboard.tsx

grep -q "DonutChart"          "$F" && echo "  ✅ 25.1  Type distribution donut chart"    || echo "  ❌ 25.1"
grep -q "byApproval"          "$F" && echo "  ✅ 25.2  Approval status breakdown"        || echo "  ❌ 25.2"
grep -q "withImage"           "$F" && echo "  ✅ 25.3  Questions with image count"       || echo "  ❌ 25.3"
grep -q "withoutExplanation\|Missing Explanation" "$F" && echo "  ✅ 25.4  Without explanation count" || echo "  ❌ 25.4"
grep -q "neverUsed\|Never Used" "$F" && echo "  ✅ 25.5  Never used questions"          || echo "  ❌ 25.5"
grep -q "mostUsed\|Most Used" "$F" && echo "  ✅ 25.6  Most used questions top 10"      || echo "  ❌ 25.6"
grep -q "addedThisWeek\|This Week" "$F" && echo "  ✅ 25.7  Added this week/month"      || echo "  ❌ 25.7"
grep -q "exportExcel\|exportPDF" "$F" && echo "  ✅ 25.8  Export as CSV + PDF"         || echo "  ❌ 25.8"
grep -q "HealthGauge\|healthScore\|Health Score" "$F" && echo "  ✅ 25.9  Bank quality health score" || echo "  ❌ 25.9"
grep -q "weeklyGrowth\|Week-over-Week" "$F" && echo "  ✅ 25.10 Week-over-week growth"  || echo "  ❌ 25.10"
grep -q "contributors\|Contributors" "$F" && echo "  ✅ 25.11 Contributor stats"        || echo "  ❌ 25.11"
grep -q "QBankStatsDashboard" "$PAGE" && echo "  ✅ Component used in page.tsx"        || echo "  ❌ Not in page.tsx"
grep -q "BarChart"            "$F" && echo "  ✅ Bar charts (subject/difficulty)"       || echo "  ❌ Bar charts"
grep -q "tab==='quality'"     "$F" && echo "  ✅ Quality tab"                           || echo "  ❌ Quality tab"
grep -q "tab==='growth'"      "$F" && echo "  ✅ Growth tab"                            || echo "  ❌ Growth tab"
grep -q "tab==='contributors'" "$F" && echo "  ✅ Contributors tab"                     || echo "  ❌ Contributors tab"

echo ""
echo "  Features Summary:"
echo "  ✅ 25.1  Type Distribution — Donut Chart (SCQ/MSQ/Integer)"
echo "  ✅ 25.2  Approval Breakdown — Donut Chart (Approved/Pending/Rejected)"
echo "  ✅ 25.3  Questions With Image Count"
echo "  ✅ 25.4  Questions Without Explanation Count"
echo "  ✅ 25.5  Never Used Questions — Click to view list"
echo "  ✅ 25.6  Most Used Top 10 — Quality tab"
echo "  ✅ 25.7  Added This Week / Month stat cards"
echo "  ✅ 25.8  Export as CSV + PDF Report"
echo "  ✅ 25.9  Health Score Gauge (0-100) with breakdown"
echo "  ✅ 25.10 Week-over-Week Growth Bar Graph (12 weeks)"
echo "  ✅ 25.11 Contributor Leaderboard (Gold/Silver/Bronze)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "🎉 git add . && git commit -m 'feat: Feature 25 QB Stats Dashboard' && git push"
echo "════════════════════════════════════════════════════════════"
