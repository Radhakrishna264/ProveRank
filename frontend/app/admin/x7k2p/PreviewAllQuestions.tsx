'use client'
import { useState, useCallback } from 'react'
import { DeleteConfirmModal, RecycleBinModal, ArchivedModal, UndoToast } from './DeleteQuestionSystem'

// ── Design tokens ─────────────────────────────────────────────────────────────
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', PRP='#A78BFA'
const BIO='#34D399', PHY='#60A5FA', CHM='#F472B6', MTH='#FBBF24'
const BOR='rgba(77,159,255,0.18)'
const CRD='rgba(0,18,36,0.82)'
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:9,padding:'9px 18px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const bg_:any={background:'rgba(0,25,50,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:9,padding:'8px 14px',cursor:'pointer',fontSize:12,transition:'all 0.2s'}
const inp:any={width:'100%',padding:'10px 13px',background:'rgba(0,15,35,0.9)',border:`1.5px solid ${BOR}`,borderRadius:9,color:TS,fontSize:13,outline:'none',boxSizing:'border-box' as any}
const lbl:any={display:'block',fontSize:10,color:DIM,marginBottom:4,fontWeight:700,letterSpacing:0.5,textTransform:'uppercase' as any}

const sColor=(s:string)=>s==='Physics'?PHY:s==='Chemistry'?CHM:s==='Biology'?BIO:s==='Math'?MTH:'#94A3B8'
const dColor=(d:string)=>d==='hard'||d==='Hard'?DNG:d==='easy'||d==='Easy'?SUC:WRN

function Badge({label,col}:{label:string;col:string}){
  return <span style={{background:`${col}18`,border:`1px solid ${col}33`,color:col,borderRadius:12,padding:'2px 8px',fontSize:10,fontWeight:600,whiteSpace:'nowrap' as any}}>{label}</span>
}

function ConfirmModal({title,msg,onOk,onCancel,danger=true}:{title:string;msg:string;onOk:()=>void;onCancel:()=>void;danger?:boolean}){
  return(
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:99990,display:'flex',alignItems:'center',justifyContent:'center',padding:16}} onClick={onCancel}>
      <div style={{background:'linear-gradient(135deg,#0A1628,#0D1E36)',border:`2px solid ${danger?`${DNG}55`:`${ACC}44`}`,borderRadius:16,padding:24,width:'100%',maxWidth:400,boxShadow:`0 20px 60px rgba(0,0,0,0.6)`}} onClick={e=>e.stopPropagation()}>
        <div style={{fontSize:28,marginBottom:12,textAlign:'center' as any}}>{danger?'⚠️':'💬'}</div>
        <div style={{fontWeight:800,fontSize:16,color:danger?DNG:ACC,marginBottom:8,textAlign:'center' as any}}>{title}</div>
        <div style={{fontSize:13,color:DIM,textAlign:'center' as any,marginBottom:20,lineHeight:1.6}}>{msg}</div>
        <div style={{display:'flex',gap:10}}>
          <button onClick={onOk} style={{...bp,flex:1,background:danger?`linear-gradient(135deg,${DNG},#aa0000)`:`linear-gradient(135deg,${SUC},#007a40)`}}>{danger?'Yes, Proceed':'Confirm'}</button>
          <button onClick={onCancel} style={{...bg_,flex:1}}>Cancel</button>
        </div>
      </div>
    </div>
  )
}

interface Props {
  questions: any[]
  exams: any[]
  token: string
  API: string
  T: (m:string,t?:'s'|'e'|'w')=>void
  fetchAll: ()=>void
  onBack: ()=>void
  onGoAdd: ()=>void
  // state from parent
  qLang: string; setQLang: (v:string)=>void
  qSec: string; setQSec: (v:string)=>void
  qBioSub: string; setQBioSub: (v:string)=>void
  qChapFilter: string; setQChapFilter: (v:string)=>void
  qSearch: string; setQSearch: (v:string)=>void
  qPage: number; setQPage: (v:number|((p:number)=>number))=>void
  qfApproval: string; setQfApproval: (v:string)=>void
  qfDiff2: string; setQfDiff2: (v:string)=>void
  qfType: string; setQfType: (v:string)=>void
  qfUsage: string; setQfUsage: (v:string)=>void
  qfLevel: string; setQfLevel: (v:string)=>void
  qfFormat: string; setQfFormat: (v:string)=>void
  qfDate: string; setQfDate: (v:string)=>void
  stdPrv: boolean; setStdPrv: (v:boolean)=>void
  bulkSel: string[]; setBulkSel: (v:string[]|((p:string[])=>string[]))=>void
  openA2E: ()=>void
  fQs: any[]; pagedQs: any[]; _fQsSorted: any[]; _qPg: number; _qTP: number
  setSelQId: (id:string)=>void
  fetchUsageStats: (q:any)=>void
  setEditQD: (q:any)=>void
  copyToAddForm: (q:any)=>void
  expQB: ()=>void
  expQBPdf: ()=>void
  longPressTimerRef: any; longPressFiredRef: any
  blkApproveQs: ()=>void
}

export default function PreviewAllQuestions(props:Props){
  const {questions,exams,token,API,T,fetchAll,onBack,onGoAdd,
    qLang,setQLang,qSec,setQSec,qBioSub,setQBioSub,qChapFilter,setQChapFilter,
    qSearch,setQSearch,qPage,setQPage,qfApproval,setQfApproval,qfDiff2,setQfDiff2,
    qfType,setQfType,qfUsage,setQfUsage,qfLevel,setQfLevel,qfFormat,setQfFormat,
    qfDate,setQfDate,stdPrv,setStdPrv,bulkSel,setBulkSel,openA2E,
    fQs,pagedQs,_fQsSorted,_qPg,_qTP,setSelQId,fetchUsageStats,setEditQD,copyToAddForm,
    expQB,expQBPdf,longPressTimerRef,longPressFiredRef,blkApproveQs} = props

  const hdrs={'Content-Type':'application/json',Authorization:`Bearer ${token}`}

  // ── Local state ──────────────────────────────────────────────────────────────
  const [filtersOpen,setFiltersOpen] = useState(false)
  const [delModal,setDelModal]       = useState<any|null>(null)
  const [delImpact,setDelImpact]     = useState<any|null>(null)
  const [delLoading,setDelLoading]   = useState(false)
  const [undoToast,setUndoToast]     = useState<{msg:string;id:string}|null>(null)
  const [showBin,setShowBin]         = useState(false)
  const [showArchived,setShowArchived] = useState(false)
  const [confirmModal,setConfirmModal] = useState<{title:string;msg:string;onOk:()=>void}|null>(null)
  const [approveLoading,setApproveLoading] = useState(false)

  // ── Delete functions ──────────────────────────────────────────────────────────
  const openDeleteModal = useCallback(async(q:any)=>{
    setDelModal(q); setDelImpact(null)
    try{const r=await fetch(`${API}/api/questions/${q._id}/delete-impact`,{headers:{Authorization:`Bearer ${token}`}});const d=await r.json();if(d.success)setDelImpact(d)}catch{}
  },[token,API])

  const confirmDelete = useCallback(async(reason:string)=>{
    if(!delModal) return; setDelLoading(true)
    try{
      const r=await fetch(`${API}/api/questions/${delModal._id}/permanent`,{method:'DELETE',headers:hdrs,body:JSON.stringify({reason})})
      const d=await r.json()
      if(d.success){T('Moved to Recycle Bin 🗑️','w');setUndoToast({msg:'Question deleted',id:delModal._id});setDelModal(null);setTimeout(fetchAll,400)}
      else T(d.message||'Delete failed','e')
    }catch{T('Error','e')}
    setDelLoading(false)
  },[delModal,token,API,fetchAll])

  const confirmArchive = useCallback(async(reason:string)=>{
    if(!delModal) return; setDelLoading(true)
    try{
      const r=await fetch(`${API}/api/questions/${delModal._id}/archive`,{method:'PATCH',headers:hdrs,body:JSON.stringify({reason})})
      const d=await r.json()
      if(d.success){T('Archived 🗂️','w');setUndoToast({msg:'Question archived',id:delModal._id});setDelModal(null);setTimeout(fetchAll,400)}
      else T(d.message||'Archive failed','e')
    }catch{T('Error','e')}
    setDelLoading(false)
  },[delModal,token,API,fetchAll])

  const undoDeleteFn = useCallback(async()=>{
    if(!undoToast) return
    try{
      const r=await fetch(`${API}/api/questions/${undoToast.id}/restore`,{method:'PATCH',headers:hdrs})
      const d=await r.json()
      if(d.success){T('↩️ Restored!','s');setUndoToast(null);setTimeout(fetchAll,400)}
      else T(d.message||'Undo failed','e')
    }catch{T('Error','e')}
  },[undoToast,token,API,fetchAll])

  const bulkDeleteFn = useCallback(async()=>{
    if(!bulkSel.length) return
    try{
      const r=await fetch(`${API}/api/questions/bulk/delete`,{method:'PATCH',headers:hdrs,body:JSON.stringify({ids:bulkSel})})
      const d=await r.json()
      if(d.success){T(`${d.modifiedCount} Qs → Recycle Bin`,'w');setBulkSel([]);setTimeout(fetchAll,400)}
      else T(d.message||'Failed','e')
    }catch{T('Error','e')}
  },[bulkSel,token,API,fetchAll])

  const bulkArchiveFn = useCallback(async()=>{
    if(!bulkSel.length) return
    try{
      const r=await fetch(`${API}/api/questions/bulk/archive`,{method:'PATCH',headers:hdrs,body:JSON.stringify({ids:bulkSel})})
      const d=await r.json()
      if(d.success){T(`${d.modifiedCount} Qs archived 🗂️`,'w');setBulkSel([]);setTimeout(fetchAll,400)}
      else T(d.message||'Failed','e')
    }catch{T('Error','e')}
  },[bulkSel,token,API,fetchAll])

  const bulkApproveFn = useCallback(async()=>{
    setApproveLoading(true)
    await blkApproveQs()
    setApproveLoading(false)
  },[blkApproveQs])

  // ── Derived ───────────────────────────────────────────────────────────────────
  const activeCnt = [qfApproval,qfDiff2,qfType,qfUsage,qfLevel,qfFormat,qfDate].filter(v=>v!=='all').length
  const chapBase = (questions||[]).filter(q=>{const OS=['Physics','Chemistry','Biology','Math'];return qSec==='all'||(qSec==='Other'?!OS.includes(q.subject||''):q.subject===qSec)})
  const chapOpts = [...new Set(chapBase.map((q:any)=>q.chapter||'').filter(Boolean))].sort() as string[]
  const tot = fQs.length||1
  const ez = fQs.filter((q:any)=>q.difficulty==='easy'||q.difficulty==='Easy').length
  const md = fQs.filter((q:any)=>q.difficulty==='medium'||q.difficulty==='Medium').length
  const hd = fQs.filter((q:any)=>q.difficulty==='hard'||q.difficulty==='Hard').length

  const subjectTabs = [
    {k:'all',l:'All',col:PRP,cnt:(questions||[]).length},
    {k:'Physics',l:'⚛️ Physics',col:PHY,cnt:(questions||[]).filter((q:any)=>q.subject==='Physics').length},
    {k:'Chemistry',l:'🧪 Chem',col:CHM,cnt:(questions||[]).filter((q:any)=>q.subject==='Chemistry').length},
    {k:'Biology',l:'🧬 Bio',col:BIO,cnt:(questions||[]).filter((q:any)=>q.subject==='Biology').length},
    {k:'Math',l:'📐 Math',col:MTH,cnt:(questions||[]).filter((q:any)=>q.subject==='Math').length},
    {k:'Other',l:'📚 Other',col:'#94A3B8',cnt:(questions||[]).filter((q:any)=>!['Physics','Chemistry','Biology','Math'].includes(q.subject||'')).length},
  ]

  return(
    <div style={{fontFamily:'Inter,sans-serif',minHeight:'100vh'}}>

      {/* ══════════ HEADER ══════════════════════════════════════════════════════ */}
      <div style={{background:'linear-gradient(135deg,rgba(0,15,35,0.98),rgba(0,25,55,0.95))',borderBottom:`1px solid ${BOR}`,padding:'14px 16px',position:'sticky',top:0,zIndex:100,backdropFilter:'blur(20px)'}}>
        {/* Top row */}
        <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:10,flexWrap:'wrap' as any}}>
          <button onClick={onBack} style={{...bg_,padding:'7px 12px',fontSize:11,display:'flex',alignItems:'center',gap:5}}>
            ← Back
          </button>
          <div style={{flex:1,minWidth:0}}>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:800,background:`linear-gradient(90deg,${PRP},${PHY})`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',letterSpacing:0.2}}>
              📚 Preview All Questions
            </div>
            <div style={{display:'flex',alignItems:'center',gap:6,marginTop:2,flexWrap:'wrap' as any}}>
              <span style={{fontSize:10,color:DIM}}>Showing</span>
              <span style={{fontSize:11,fontWeight:800,color:PRP,background:'rgba(167,139,250,0.12)',padding:'1px 8px',borderRadius:8,border:`1px solid ${PRP}33`}}>{fQs.length}</span>
              <span style={{fontSize:10,color:DIM}}>of {(questions||[]).length} Questions</span>
            </div>
          </div>
          {/* Action buttons */}
          <div style={{display:'flex',gap:6,flexWrap:'wrap' as any,alignItems:'center'}}>
            <button onClick={()=>{const nl=qLang==='en'?'hi':'en';setQLang(nl);try{localStorage.setItem('pr_qb_lang',nl)}catch{}}}
              style={{padding:'6px 10px',borderRadius:8,fontSize:11,fontWeight:700,cursor:'pointer',background:qLang==='hi'?'rgba(251,146,60,0.15)':'rgba(255,255,255,0.05)',color:qLang==='hi'?'#FB923C':'#94A3B8',border:`1px solid ${qLang==='hi'?'rgba(251,146,60,0.4)':'rgba(255,255,255,0.1)'}`,transition:'all 0.2s'}}>
              {qLang==='hi'?'🇮🇳 हिंदी':'🌐 EN'}
            </button>
            <button onClick={()=>setStdPrv(!stdPrv)} style={{...bg_,padding:'6px 10px',fontSize:11,background:stdPrv?'rgba(0,196,140,0.12)':'rgba(255,255,255,0.05)',color:stdPrv?SUC:'#94A3B8',border:`1px solid ${stdPrv?`${SUC}44`:BOR}`}}>
              🎓 {stdPrv?'ON':'View'}
            </button>
            <button onClick={expQB} style={{...bg_,padding:'6px 9px',fontSize:11}} title='Export CSV'>📄</button>
            <button onClick={expQBPdf} style={{...bg_,padding:'6px 9px',fontSize:11}} title='Export PDF'>🖨️</button>
            <button onClick={onGoAdd} style={{...bp,padding:'7px 14px',fontSize:11}}>➕ Add</button>
            <button onClick={()=>setShowBin(true)} style={{background:'rgba(255,77,77,0.1)',border:`1px solid rgba(255,77,77,0.3)`,color:DNG,borderRadius:8,padding:'6px 9px',cursor:'pointer',fontSize:11,fontWeight:700}}>🗑️</button>
            <button onClick={()=>setShowArchived(true)} style={{background:'rgba(255,184,77,0.1)',border:`1px solid rgba(255,184,77,0.3)`,color:WRN,borderRadius:8,padding:'6px 9px',cursor:'pointer',fontSize:11,fontWeight:700}}>🗂️</button>
          </div>
        </div>

        {/* Search */}
        <div style={{position:'relative'}}>
          <input value={qSearch} onChange={e=>{setQSearch(e.target.value);setQPage(1)}} placeholder='🔍 Search questions, chapter, topic…'
            style={{...inp,paddingLeft:14,fontSize:12,border:`1.5px solid ${qSearch?ACC:BOR}`}}/>
          {qSearch&&<button onClick={()=>{setQSearch('');setQPage(1)}} style={{position:'absolute',right:10,top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:DIM,cursor:'pointer',fontSize:16}}>✕</button>}
        </div>
      </div>

      <div style={{padding:'12px 14px'}}>

        {/* ══════════ STATS STRIP ════════════════════════════════════════════════ */}
        <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:6,marginBottom:12}}>
          {[{l:'Total',v:(questions||[]).length,c:PRP},{l:'Physics',v:(questions||[]).filter((q:any)=>q.subject==='Physics').length,c:PHY},{l:'Chemistry',v:(questions||[]).filter((q:any)=>q.subject==='Chemistry').length,c:CHM},{l:'Biology',v:(questions||[]).filter((q:any)=>q.subject==='Biology').length,c:BIO},{l:'Math',v:(questions||[]).filter((q:any)=>q.subject==='Math').length,c:MTH}].map(x=>(
            <div key={x.l} style={{background:`${x.c}09`,border:`1px solid ${x.c}22`,borderRadius:10,padding:'8px 4px',textAlign:'center' as any,cursor:'pointer',transition:'all 0.2s'}}
              onClick={()=>{setQSec(x.l==='Total'?'all':x.l);setQPage(1)}}>
              <div style={{fontSize:17,fontWeight:800,color:x.c}}>{x.v}</div>
              <div style={{fontSize:9,color:DIM,marginTop:1}}>{x.l}</div>
            </div>
          ))}
        </div>

        {/* ══════════ DIFFICULTY DISTRIBUTION ═══════════════════════════════════ */}
        {fQs.length>0&&(
          <div style={{background:'rgba(255,255,255,0.02)',border:`1px solid ${BOR}`,borderRadius:12,padding:'12px 14px',marginBottom:12}}>
            <div style={{fontSize:10,color:DIM,fontWeight:700,marginBottom:8,textTransform:'uppercase' as any,letterSpacing:1}}>📊 Difficulty Distribution</div>
            {[{l:'Easy',v:ez,col:SUC},{l:'Medium',v:md,col:WRN},{l:'Hard',v:hd,col:DNG}].map(x=>{
              const pct=Math.round((x.v/tot)*100)
              return(
                <div key={x.l} style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
                  <div style={{width:48,fontSize:10,color:x.col,fontWeight:700}}>{x.l}</div>
                  <div style={{flex:1,height:5,background:'rgba(255,255,255,0.05)',borderRadius:3,overflow:'hidden'}}>
                    <div style={{width:`${pct}%`,height:'100%',background:`linear-gradient(90deg,${x.col}88,${x.col})`,borderRadius:3,transition:'width 0.5s ease'}}/>
                  </div>
                  <div style={{width:60,fontSize:10,color:DIM,textAlign:'right' as any}}>{x.v} ({pct}%)</div>
                </div>
              )
            })}
          </div>
        )}

        {/* ══════════ SUBJECT TABS ═══════════════════════════════════════════════ */}
        <div style={{display:'flex',gap:5,flexWrap:'wrap' as any,marginBottom:10}}>
          {subjectTabs.map(x=>{
            const isA=qSec===x.k
            return(
              <button key={x.k} onClick={()=>{setQSec(x.k);setQBioSub('all');setQChapFilter('all');setQPage(1)}}
                style={{padding:'5px 11px',borderRadius:20,border:`1.5px solid ${isA?x.col:x.col+'22'}`,background:isA?`${x.col}18`:'transparent',color:isA?x.col:DIM,fontSize:10,fontWeight:isA?700:400,cursor:'pointer',transition:'all 0.2s'}}>
                {x.l} ({x.cnt})
              </button>
            )
          })}
        </div>

        {/* Biology sub-filter */}
        {qSec==='Biology'&&(
          <div style={{display:'flex',gap:5,marginBottom:8}}>
            {[{k:'all',l:'All Bio'},{k:'Zoology',l:'🦁 Zoo'},{k:'Botany',l:'🌿 Bot'}].map(x=>{
              const isA=qBioSub===x.k
              return <button key={x.k} onClick={()=>{setQBioSub(x.k);setQPage(1)}} style={{padding:'3px 10px',borderRadius:12,border:`1px solid ${isA?BIO:`${BIO}22`}`,background:isA?`${BIO}12`:'transparent',color:isA?BIO:DIM,fontSize:10,cursor:'pointer'}}>{x.l}</button>
            })}
          </div>
        )}

        {/* Chapter filter */}
        {chapOpts.length>0&&(
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:10,flexWrap:'wrap' as any}}>
            <span style={{fontSize:10,color:DIM,fontWeight:600}}>📖</span>
            <select value={qChapFilter} onChange={e=>{setQChapFilter(e.target.value);setQPage(1)}}
              style={{...inp,width:'auto',flex:1,maxWidth:240,fontSize:11,padding:'6px 10px',color:qChapFilter!=='all'?PRP:DIM}}>
              <option value='all'>All Chapters ({chapBase.length})</option>
              {chapOpts.map((ch:string)=>{
                const cnt=chapBase.filter((q:any)=>q.chapter===ch).length
                const dn=ch.includes(' - ')?ch.split(' - ').slice(1).join(' - '):ch
                return <option key={ch} value={ch}>{dn} ({cnt})</option>
              })}
            </select>
            {qChapFilter!=='all'&&<button onClick={()=>{setQChapFilter('all');setQPage(1)}} style={{fontSize:10,padding:'4px 8px',borderRadius:7,border:`1px solid ${DNG}44`,background:'transparent',color:DNG,cursor:'pointer'}}>✕</button>}
          </div>
        )}

        {/* ══════════ SMART FILTERS ══════════════════════════════════════════════ */}
        <div style={{marginBottom:12}}>
          <button onClick={()=>setFiltersOpen(p=>!p)}
            style={{...bg_,width:'100%',display:'flex',alignItems:'center',justifyContent:'space-between',padding:'10px 14px',borderColor:activeCnt>0?`${ACC}55`:BOR,background:activeCnt>0?'rgba(77,159,255,0.06)':'rgba(0,25,50,0.7)'}}>
            <span style={{display:'flex',alignItems:'center',gap:8}}>
              <span>🧰 Smart Filters</span>
              {activeCnt>0&&<span style={{background:ACC,color:'#fff',borderRadius:10,padding:'1px 8px',fontSize:10,fontWeight:700}}>{activeCnt}</span>}
            </span>
            <span style={{color:DIM,fontSize:11}}>{filtersOpen?'▲':'▼'}</span>
          </button>
          {filtersOpen&&(
            <div style={{marginTop:8,background:'rgba(0,10,30,0.8)',border:`1px solid ${BOR}`,borderRadius:12,padding:14,display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
              {[
                {l:'Approval',v:qfApproval,fn:setQfApproval,opts:[['all','All'],['approved','✅ Approved'],['pending','⏳ Pending'],['rejected','❌ Rejected']]},
                {l:'Difficulty',v:qfDiff2,fn:setQfDiff2,opts:[['all','All'],['easy','Easy'],['medium','Medium'],['hard','Hard']]},
                {l:'Type',v:qfType,fn:setQfType,opts:[['all','All'],['SCQ','SCQ'],['MSQ','MSQ'],['Integer','Integer']]},
                {l:'Usage',v:qfUsage,fn:setQfUsage,opts:[['all','All'],['never','Never Used'],['1-5','1-5x'],['5+','5x+']]},
                {l:'Exam Level',v:qfLevel,fn:setQfLevel,opts:[['all','All'],['NEET','NEET'],['JEE_MAINS','JEE Mains'],['JEE_ADVANCED','JEE Adv'],['CUET','CUET'],['BOARD','Board']]},
                {l:'Format',v:qfFormat,fn:setQfFormat,opts:[['all','All'],['Random','Random'],['Match_Column','Match Col'],['Assertion_Reason','A-R'],['Numerical','Numerical'],['Diagram_Based','Diagram']]},
              ].map(f=>(
                <div key={f.l}>
                  <label style={lbl}>{f.l}</label>
                  <select value={f.v} onChange={e=>{f.fn(e.target.value);setQPage(1)}} style={{...inp,padding:'7px 8px',fontSize:11,color:f.v!=='all'?ACC:DIM}}>
                    {f.opts.map(([v,l])=><option key={v} value={v}>{l}</option>)}
                  </select>
                </div>
              ))}
              <div style={{gridColumn:'span 2'}}>
                <label style={lbl}>Date Added</label>
                <select value={qfDate} onChange={e=>{setQfDate(e.target.value);setQPage(1)}} style={{...inp,padding:'7px 8px',fontSize:11,color:qfDate!=='all'?ACC:DIM}}>
                  {[['all','All Time'],['7d','Last 7 Days'],['30d','Last 30 Days']].map(([v,l])=><option key={v} value={v}>{l}</option>)}
                </select>
              </div>
              {activeCnt>0&&(
                <div style={{gridColumn:'span 2'}}>
                  <button onClick={()=>{setQfApproval('all');setQfDiff2('all');setQfType('all');setQfUsage('all');setQfLevel('all');setQfFormat('all');setQfDate('all');setQPage(1)}}
                    style={{background:'rgba(255,77,77,0.1)',border:`1px solid ${DNG}33`,color:DNG,borderRadius:8,padding:'7px',width:'100%',cursor:'pointer',fontSize:11,fontWeight:600}}>
                    ✕ Clear All Filters
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* ══════════ BULK ACTION BAR ════════════════════════════════════════════ */}
        {bulkSel.length>0&&(
          <div style={{background:'rgba(77,159,255,0.06)',border:`1.5px solid ${ACC}33`,borderRadius:12,padding:'10px 14px',marginBottom:12,display:'flex',alignItems:'center',gap:8,flexWrap:'wrap' as any}}>
            <span style={{fontSize:12,color:ACC,fontWeight:800,background:`${ACC}15`,padding:'3px 10px',borderRadius:8}}>{bulkSel.length} selected</span>
            <button onClick={()=>setConfirmModal({title:`Approve ${bulkSel.length} Questions?`,msg:'Selected questions will be marked as approved.',onOk:async()=>{setConfirmModal(null);await bulkApproveFn()}})}
              style={{fontSize:11,padding:'5px 12px',borderRadius:7,border:`1px solid ${SUC}44`,background:`${SUC}10`,color:SUC,cursor:'pointer',fontWeight:600}}>
              ✅ Approve
            </button>
            <button onClick={()=>setConfirmModal({title:`Delete ${bulkSel.length} Questions?`,msg:'Questions will be moved to Recycle Bin. Recoverable for 30 days.',onOk:()=>{setConfirmModal(null);bulkDeleteFn()}})}
              style={{fontSize:11,padding:'5px 12px',borderRadius:7,border:`1px solid ${DNG}44`,background:`${DNG}10`,color:DNG,cursor:'pointer',fontWeight:600}}>
              🗑️ Delete
            </button>
            <button onClick={()=>setConfirmModal({title:`Archive ${bulkSel.length} Questions?`,msg:'Questions will be archived and hidden from main bank.',onOk:()=>{setConfirmModal(null);bulkArchiveFn()},danger:false} as any)}
              style={{fontSize:11,padding:'5px 12px',borderRadius:7,border:`1px solid ${WRN}44`,background:`${WRN}10`,color:WRN,cursor:'pointer',fontWeight:600}}>
              🗂️ Archive
            </button>
            <button onClick={()=>setBulkSel([])} style={{...bg_,fontSize:11,padding:'5px 10px',marginLeft:'auto'}}>✕ Clear</button>
          </div>
        )}

        {/* ══════════ PAGINATION TOP ═════════════════════════════════════════════ */}
        {_fQsSorted.length>25&&(
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:10,padding:'6px 4px'}}>
            <span style={{fontSize:11,color:DIM}}>
              {_fQsSorted.length>0?`${(_qPg-1)*25+1}–${Math.min(_qPg*25,_fQsSorted.length)} of ${_fQsSorted.length}`:''}
            </span>
            <div style={{display:'flex',gap:4,alignItems:'center'}}>
              <button onClick={()=>setQPage(p=>Math.max(1,p-1))} disabled={_qPg<=1} style={{...bg_,padding:'4px 10px',fontSize:11,opacity:_qPg<=1?0.3:1}}>←</button>
              <span style={{fontSize:11,color:ACC,fontWeight:700,background:`${ACC}12`,padding:'3px 10px',borderRadius:8}}>P{_qPg}/{_qTP}</span>
              <button onClick={()=>setQPage(p=>Math.min(_qTP,p+1))} disabled={_qPg>=_qTP} style={{...bg_,padding:'4px 10px',fontSize:11,opacity:_qPg>=_qTP?0.3:1}}>→</button>
            </div>
          </div>
        )}

        {/* ══════════ QUESTION CARDS ═════════════════════════════════════════════ */}
        {fQs.length===0?(
          <div style={{textAlign:'center' as any,padding:'60px 20px'}}>
            <div style={{fontSize:56,marginBottom:12}}>❓</div>
            <div style={{fontWeight:700,fontSize:16,color:TS,marginBottom:6}}>{(questions||[]).length===0?'Loading questions…':'No Questions Found'}</div>
            <div style={{fontSize:12,color:DIM}}>{(questions||[]).length>0?'Try different search or filter.':''}</div>
          </div>
        ):(
          <div style={{display:'flex',flexDirection:'column' as any,gap:8}}>
            {/* ══ CSS for card animations ══ */}
            <style dangerouslySetInnerHTML={{__html:`
              .qcard{transition:all 0.22s cubic-bezier(0.4,0,0.2,1);}
              .qcard:hover{transform:translateY(-1px);}
              .qact-btn{transition:all 0.18s ease;}
              .qact-btn:hover{transform:scale(1.12);}
              .del-btn{opacity:0;transition:all 0.18s ease;}
              .qcard:hover .del-btn,.del-btn:focus{opacity:1;}
              @keyframes fadeSlideIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
              .qcard{animation:fadeSlideIn 0.25s ease both;}
            `}}/>

            {pagedQs.map((q:any,qi:number)=>{
              const isChk = bulkSel.includes(q._id)
              const usedIn = (exams||[]).filter((e:any)=>(e.questionIds||e.questions||[]).includes(q._id)).length
              const sc = sColor(q.subject||'')
              const dc = dColor(q.difficulty||'')
              const qNum = _fQsSorted.length-((_qPg-1)*25+qi)
              const qText = qLang==='hi'&&q.hindiText?q.hindiText:q.text||''
              const isPending = q.approvalStatus==='pending'||!q.approvalStatus
              const isRejected = q.approvalStatus==='rejected'
              const ltrs=['A','B','C','D']
              const ci = Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)

              return(
                <div key={q._id||qi} className="qcard" style={{
                  position:'relative',
                  background: isChk
                    ? `linear-gradient(135deg,${sc}08,rgba(0,18,40,0.95))`
                    : 'linear-gradient(135deg,rgba(5,18,40,0.92),rgba(2,12,32,0.97))',
                  border: `1px solid ${isChk?sc+'55':sc+'18'}`,
                  borderRadius:16,
                  overflow:'hidden',
                  boxShadow: isChk
                    ? `0 0 0 2px ${sc}33, 0 6px 24px ${sc}14`
                    : `0 2px 12px rgba(0,0,0,0.3)`,
                  animationDelay:`${qi*0.04}s`
                }}>

                  {/* ── Left subject glow strip ────────────────────────── */}
                  <div style={{
                    position:'absolute',top:0,left:0,bottom:0,width:4,
                    background:`linear-gradient(180deg,${sc},${sc}44)`,
                    borderRadius:'16px 0 0 16px'
                  }}/>

                  {/* ── Top accent line (selected) ─────────────────────── */}
                  {isChk&&<div style={{position:'absolute',top:0,left:4,right:0,height:2,background:`linear-gradient(90deg,${sc}88,transparent)`}}/>}

                  {/* ── CARD BODY ──────────────────────────────────────── */}
                  <div style={{padding:'13px 12px 11px 16px'}}>

                    {/* ── ROW 1: Checkbox · Q# · Badges · Status ────────── */}
                    <div style={{display:'flex',alignItems:'center',gap:7,marginBottom:9,flexWrap:'wrap' as any}}>

                      {/* Checkbox */}
                      <input type='checkbox' checked={isChk}
                        onChange={e=>{if(e.target.checked)setBulkSel((p:string[])=>[...p,q._id]);else setBulkSel((p:string[])=>p.filter((x:string)=>x!==q._id))}}
                        style={{cursor:'pointer',accentColor:sc,width:14,height:14,flexShrink:0,marginRight:2}}/>

                      {/* Q Number badge */}
                      <div style={{
                        background:`linear-gradient(135deg,${sc},${sc}88)`,
                        color:'#fff',fontSize:10,fontWeight:900,
                        borderRadius:8,padding:'3px 9px',flexShrink:0,letterSpacing:0.3,
                        boxShadow:`0 2px 8px ${sc}44`
                      }}>#{qNum}</div>

                      {/* Subject */}
                      <span style={{background:`${sc}12`,border:`1px solid ${sc}30`,color:sc,borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:700,letterSpacing:0.2}}>{q.subject||'General'}</span>

                      {/* Difficulty */}
                      <span style={{background:`${dc}10`,border:`1px solid ${dc}30`,color:dc,borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:600}}>{q.difficulty||'?'}</span>

                      {/* Type */}
                      <span style={{background:'rgba(148,163,184,0.08)',border:'1px solid rgba(148,163,184,0.2)',color:'#94A3B8',borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:500}}>{q.type||'SCQ'}</span>

                      {/* Used in exams */}
                      {usedIn>0&&(
                        <span style={{background:'rgba(96,165,250,0.1)',border:'1px solid rgba(96,165,250,0.25)',color:'#60A5FA',borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:600,display:'flex',alignItems:'center',gap:3}}>
                          <span style={{width:5,height:5,borderRadius:'50%',background:'#60A5FA',display:'inline-block'}}/>
                          {usedIn} exam{usedIn>1?'s':''}
                        </span>
                      )}

                      {/* Approval status */}
                      {isPending&&(
                        <span style={{background:'rgba(251,191,36,0.08)',border:'1px solid rgba(251,191,36,0.25)',color:'#FBBF24',borderRadius:8,padding:'2px 8px',fontSize:9,fontWeight:700,letterSpacing:0.3,textTransform:'uppercase' as any}}>⏳ pending</span>
                      )}
                      {isRejected&&(
                        <span style={{background:'rgba(255,77,77,0.08)',border:'1px solid rgba(255,77,77,0.25)',color:'#FF4D4D',borderRadius:8,padding:'2px 8px',fontSize:9,fontWeight:700,letterSpacing:0.3,textTransform:'uppercase' as any}}>✕ rejected</span>
                      )}
                    </div>

                    {/* ── ROW 2: Question Text ───────────────────────────── */}
                    <div
                      onClick={()=>{if(longPressFiredRef.current){longPressFiredRef.current=false;return}setSelQId(q._id)}}
                      onTouchStart={()=>{longPressFiredRef.current=false;longPressTimerRef.current=setTimeout(()=>{longPressFiredRef.current=true;setBulkSel((p:string[])=>p.includes(q._id)?p.filter((x:string)=>x!==q._id):[...p,q._id]);if(navigator.vibrate)navigator.vibrate(30)},500)}}
                      onTouchEnd={()=>clearTimeout(longPressTimerRef.current)}
                      onTouchMove={()=>clearTimeout(longPressTimerRef.current)}
                      onContextMenu={e=>{e.preventDefault();setBulkSel((p:string[])=>p.includes(q._id)?p.filter((x:string)=>x!==q._id):[...p,q._id])}}
                      style={{
                        cursor:'pointer',
                        fontSize:13.5,
                        color:'#D1E0F5',
                        lineHeight:1.65,
                        fontFamily:'Inter,sans-serif',
                        fontWeight:450,
                        letterSpacing:0.1,
                        marginBottom:8,
                        display:'-webkit-box' as any,
                        WebkitLineClamp:3,
                        WebkitBoxOrient:'vertical' as any,
                        overflow:'hidden',
                        WebkitUserSelect:'none' as any,
                        userSelect:'none' as any,
                      }}>
                      {qText}
                    </div>

                    {/* Hindi pending indicator */}
                    {qLang==='hi'&&!q.hindiText&&(
                      <div style={{display:'flex',alignItems:'center',gap:5,marginBottom:6}}>
                        <div style={{width:4,height:4,borderRadius:'50%',background:'#818CF8',animation:'pulse 1.5s ease infinite'}}/>
                        <span style={{fontSize:9,color:'#818CF8',fontWeight:500}}>हिंदी अनुवाद प्रतीक्षा में...</span>
                      </div>
                    )}

                    {/* ── ROW 3: Chapter breadcrumb ──────────────────────── */}
                    {(q.chapter||q.topic)&&(
                      <div style={{display:'flex',alignItems:'center',gap:4,marginBottom:9}}>
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#6B8FAF" strokeWidth="2"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
                        <span style={{fontSize:10,color:'#6B8FAF',letterSpacing:0.2}}>
                          {[q.chapter,q.topic].filter(Boolean).join(' › ')}
                        </span>
                      </div>
                    )}

                    {/* ── Options (student preview mode) ────────────────── */}
                    {stdPrv&&(q.options||[]).length>0&&(
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:5,marginBottom:10}}>
                        {(q.options||[]).map((opt:string,oi:number)=>{
                          const ltr=String.fromCharCode(65+oi)
                          const cIdx=Array.isArray(q.correct)?q.correct:q.correct!==undefined?[q.correct]:[]
                          const isC=cIdx.includes(oi)||(q.correctAnswer&&q.correctAnswer===ltr)
                          const optText=((qLang==='hi'&&(q.hindiOptions||[])[oi])?q.hindiOptions[oi]:opt||'').replace(/^[A-Da-d][\.\)\:]\s*/,'').trim()
                          return(
                            <div key={oi} style={{
                              padding:'5px 8px',borderRadius:8,fontSize:10,
                              border:`1px solid ${isC?'rgba(0,196,140,0.4)':'rgba(255,255,255,0.05)'}`,
                              background:isC?'rgba(0,196,140,0.08)':'rgba(255,255,255,0.02)',
                              color:isC?'#00C48C':'#7B8FA8',
                              display:'flex',alignItems:'flex-start',gap:5
                            }}>
                              <span style={{fontWeight:800,color:isC?'#00C48C':'#4D9FFF',flexShrink:0,fontSize:9,marginTop:1}}>{ltr}</span>
                              <span style={{lineHeight:1.4}}>{optText.slice(0,40)}{optText.length>40?'…':''}</span>
                              {isC&&<span style={{marginLeft:'auto',flexShrink:0}}>✓</span>}
                            </div>
                          )
                        })}
                      </div>
                    )}

                    {/* ── ROW 4: Bottom action bar ───────────────────────── */}
                    <div style={{
                      display:'flex',alignItems:'center',gap:5,
                      paddingTop:8,
                      borderTop:'1px solid rgba(255,255,255,0.04)',
                      marginTop:2
                    }}>
                      {/* Left: quick info */}
                      <div style={{flex:1,display:'flex',gap:6,alignItems:'center'}}>
                        {q.level&&<span style={{fontSize:9,color:'#475569',background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:5,padding:'1px 6px'}}>{q.level}</span>}
                        {q.format&&<span style={{fontSize:9,color:'#475569',background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:5,padding:'1px 6px'}}>{q.format}</span>}
                      </div>

                      {/* Right: action buttons */}
                      <div style={{display:'flex',gap:4,alignItems:'center'}}>
                        {[
                          {ico:'👁',fn:()=>setSelQId(q._id),title:'Preview',col:'#4D9FFF'},
                          {ico:'📊',fn:()=>fetchUsageStats(q),title:'Usage',col:'#A78BFA'},
                          {ico:'✏️',fn:()=>setEditQD({...q,correctLetter:ltrs[ci>=0?ci:0]||'A'}),title:'Edit',col:'#34D399'},
                          {ico:'📋',fn:()=>copyToAddForm(q),title:'Copy',col:'#FBBF24'},
                        ].map(btn=>(
                          <button key={btn.title} onClick={btn.fn} title={btn.title} className="qact-btn"
                            style={{
                              background:'rgba(255,255,255,0.03)',
                              border:'1px solid rgba(255,255,255,0.07)',
                              color:'#475569',borderRadius:7,
                              width:28,height:26,cursor:'pointer',fontSize:13,
                              display:'flex',alignItems:'center',justifyContent:'center',
                              flexShrink:0
                            }}
                            onMouseEnter={e=>{const b=e.currentTarget as HTMLElement;b.style.background=`${btn.col}12`;b.style.color=btn.col;b.style.borderColor=`${btn.col}30`}}
                            onMouseLeave={e=>{const b=e.currentTarget as HTMLElement;b.style.background='rgba(255,255,255,0.03)';b.style.color='#475569';b.style.borderColor='rgba(255,255,255,0.07)'}}>
                            {btn.ico}
                          </button>
                        ))}

                        {/* Delete — appears on hover via CSS class */}
                        <button onClick={()=>openDeleteModal(q)} title='Delete' className="qact-btn del-btn"
                          style={{
                            background:'rgba(255,77,77,0.05)',
                            border:'1px solid rgba(255,77,77,0.15)',
                            color:'#FF4D4D',borderRadius:7,
                            width:28,height:26,cursor:'pointer',fontSize:13,
                            display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0
                          }}
                          onMouseEnter={e=>{const b=e.currentTarget as HTMLElement;b.style.background='linear-gradient(135deg,#FF4D4D,#aa0000)';b.style.color='#fff';b.style.borderColor='transparent';b.style.boxShadow='0 2px 10px rgba(255,77,77,0.4)'}}
                          onMouseLeave={e=>{const b=e.currentTarget as HTMLElement;b.style.background='rgba(255,77,77,0.05)';b.style.color='#FF4D4D';b.style.borderColor='rgba(255,77,77,0.15)';b.style.boxShadow='none'}}>
                          🗑️
                        </button>
                      </div>
                    </div>

                  </div>
                </div>
              )
            })}
          </div>
        )}

        {/* ══════════ PAGINATION BOTTOM ══════════════════════════════════════════ */}
        {_qTP>1&&(
          <div style={{display:'flex',justifyContent:'center',alignItems:'center',gap:5,marginTop:16,padding:'12px 0',flexWrap:'wrap' as any}}>
            <button onClick={()=>setQPage(p=>Math.max(1,p-1))} disabled={_qPg<=1}
              style={{...bg_,padding:'7px 14px',fontSize:12,opacity:_qPg<=1?0.3:1}}>← Prev</button>
            {Array.from({length:_qTP},(_,i)=>i+1)
              .filter(p=>p===1||p===_qTP||Math.abs(p-_qPg)<=1)
              .reduce((acc:any[],p,i,arr)=>{if(i>0&&p-(arr[i-1] as number)>1)acc.push('…');acc.push(p);return acc;},[])
              .map((p:any,idx:number)=>typeof p==='string'
                ?<span key={`d${idx}`} style={{color:DIM,padding:'0 2px'}}>…</span>
                :<button key={p} onClick={()=>setQPage(p)}
                  style={{fontSize:12,color:_qPg===p?'#fff':ACC,background:_qPg===p?`linear-gradient(135deg,${ACC},${PRP})`:`${ACC}0A`,border:`1px solid ${_qPg===p?'transparent':`${ACC}25`}`,borderRadius:8,padding:'6px 10px',cursor:'pointer',fontWeight:_qPg===p?800:500,minWidth:34,textAlign:'center' as any,boxShadow:_qPg===p?`0 2px 10px ${ACC}55`:'none'}}>
                  {p}
                </button>
              )}
            <button onClick={()=>setQPage(p=>Math.min(_qTP,p+1))} disabled={_qPg>=_qTP}
              style={{...bg_,padding:'7px 14px',fontSize:12,opacity:_qPg>=_qTP?0.3:1}}>Next →</button>
          </div>
        )}
      </div>

      {/* ══════════ FLOATING BOTTOM BAR (Add to Exam) ══════════════════════════ */}
      {bulkSel.length>0&&(
        <div style={{position:'fixed',bottom:0,left:0,right:0,zIndex:998,background:'linear-gradient(135deg,#0D1B2A,#142840)',borderTop:`1.5px solid ${ACC}44`,padding:'10px 16px',display:'flex',alignItems:'center',justifyContent:'center',gap:12,boxShadow:'0 -4px 20px rgba(0,0,0,0.5)',flexWrap:'wrap' as any}}>
          <span style={{fontSize:12,color:TS,fontWeight:700}}>{bulkSel.length} Questions Selected</span>
          <button onClick={openA2E} style={{...bp,fontSize:12,padding:'9px 20px'}}>➕ Add to Exam →</button>
        </div>
      )}

      {/* ══════════ MODALS ══════════════════════════════════════════════════════ */}
      {delModal&&<DeleteConfirmModal question={delModal} impact={delImpact} onArchive={confirmArchive} onDelete={confirmDelete} onCancel={()=>setDelModal(null)} loading={delLoading}/>}
      {showBin&&<RecycleBinModal token={token} API={API} onClose={()=>setShowBin(false)} onRestore={fetchAll} toast={T}/>}
      {showArchived&&<ArchivedModal token={token} API={API} onClose={()=>setShowArchived(false)} onRestore={fetchAll} toast={T}/>}
      {undoToast&&<UndoToast message={undoToast.msg} onUndo={undoDeleteFn} onDismiss={()=>setUndoToast(null)} seconds={15}/>}
      {confirmModal&&<ConfirmModal title={confirmModal.title} msg={confirmModal.msg} onOk={confirmModal.onOk} onCancel={()=>setConfirmModal(null)}/>}
    </div>
  )
}
