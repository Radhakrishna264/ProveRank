'use client'
import { useState, useEffect, useCallback, useRef } from 'react'

const PAPI = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── Design tokens (matching main admin panel) ─────────────────────────────────
const ACC='#4D9FFF', TS='#E8F4FF', DIM='#6B8FAF', GOLD='#FFD700'
const SUC='#00C48C', DNG='#FF4D4D', WRN='#FFB84D', PRP='#A78BFA'
const BOR='rgba(77,159,255,0.2)', CRD='rgba(0,18,36,0.75)'
const GRD='linear-gradient(135deg,rgba(0,22,44,0.95),rgba(0,10,30,0.98))'

const cs:any={background:CRD,border:`1px solid ${BOR}`,borderRadius:14,padding:18,marginBottom:14,backdropFilter:'blur(12px)'}
const bp:any={background:`linear-gradient(135deg,${ACC},#0055CC)`,color:'#fff',border:'none',borderRadius:10,padding:'10px 18px',cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}
const bg_:any={background:'rgba(0,30,60,0.7)',color:TS,border:`1px solid ${BOR}`,borderRadius:10,padding:'10px 18px',cursor:'pointer',fontSize:13,transition:'all 0.2s'}
const inp:any={width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:`1.5px solid ${BOR}`,borderRadius:10,color:TS,fontSize:13,outline:'none',boxSizing:'border-box',fontFamily:'Inter,sans-serif'}
const lbl:any={display:'block',fontSize:11,color:DIM,marginBottom:5,fontWeight:600,letterSpacing:0.5,textTransform:'uppercase' as any}
const pt:any={fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:TS,margin:'0 0 4px',background:`linear-gradient(90deg,${ACC},#fff)`,WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}
const ps:any={fontSize:12,color:DIM,marginBottom:20,fontFamily:'Inter,sans-serif'}


// ── Emoji options for exam cards ─────────────────────────────────────────────
const EMOJI_OPTIONS = [
  { v:'🩺', l:'🩺 Medical/NEET' },
  { v:'⚙️', l:'⚙️ Engineering/JEE' },
  { v:'🚀', l:'🚀 Advanced/Space' },
  { v:'🎓', l:'🎓 University/CUET' },
  { v:'🏛️', l:'🏛️ Government/RPSC' },
  { v:'🏫', l:'🏫 School/Board' },
  { v:'📗', l:'📗 Class 10' },
  { v:'📘', l:'📘 Class 11-12' },
  { v:'📕', l:'📕 CBSE' },
  { v:'📚', l:'📚 General' },
  { v:'⚖️', l:'⚖️ Law/Legal' },
  { v:'💼', l:'💼 Management/MBA' },
  { v:'🏥', l:'🏥 Pharmacy' },
  { v:'🔬', l:'🔬 Science' },
  { v:'🧮', l:'🧮 Mathematics' },
  { v:'💻', l:'💻 Computer/IT' },
  { v:'🌍', l:'🌍 Geography/UPSC' },
  { v:'📐', l:'📐 Architecture' },
  { v:'🎨', l:'🎨 Arts' },
  { v:'⭐', l:'⭐ Custom/Other' },
];

// ── Color options for exam cards ──────────────────────────────────────────────
const COLOR_OPTIONS = [
  { v:'#00C48C', l:'Emerald Green',  bg:'#00C48C' },
  { v:'#4D9FFF', l:'Sky Blue',       bg:'#4D9FFF' },
  { v:'#A78BFA', l:'Purple',         bg:'#A78BFA' },
  { v:'#FFD700', l:'Golden',         bg:'#FFD700' },
  { v:'#FF6B6B', l:'Coral Red',      bg:'#FF6B6B' },
  { v:'#FF9F43', l:'Orange',         bg:'#FF9F43' },
  { v:'#00D2D3', l:'Teal Cyan',      bg:'#00D2D3' },
  { v:'#5F27CD', l:'Deep Purple',    bg:'#5F27CD' },
  { v:'#ee5a24', l:'Burnt Orange',   bg:'#ee5a24' },
  { v:'#0abde3', l:'Light Blue',     bg:'#0abde3' },
  { v:'#10ac84', l:'Jade Green',     bg:'#10ac84' },
  { v:'#ff9ff3', l:'Pink',           bg:'#ff9ff3' },
  { v:'#ffeaa7', l:'Lemon',          bg:'#ffeaa7' },
  { v:'#fd79a8', l:'Rose',           bg:'#fd79a8' },
  { v:'#6c5ce7', l:'Violet',         bg:'#6c5ce7' },
  { v:'#e17055', l:'Terracotta',     bg:'#e17055' },
];

interface Props { token:string; API:string; toast:(m:string,t?:'s'|'e'|'w')=>void }
interface ExamCard { _id?:string; name:string; icon:string; color:string; desc:string; isDefault?:boolean; stats?:{totalYears:number;totalQuestions:number;lastUpdated:string|null} }
interface YearCard { _id:string; year:number; examName:string; paperCount:number; status:string; updatedAt:string; questionCount?:number; notes?:string }
interface Question { _id:string; text:string; hindiText?:string; options:string[]; hindiOptions?:string[]; correct:number[]; subject:string; chapter:string; difficulty:string; explanation?:string; hindiExplanation?:string }

const Badge=({label,col}:{label:string;col:string})=>(
  <span style={{background:`${col}22`,border:`1px solid ${col}55`,color:col,borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:600,whiteSpace:'nowrap' as any}}>{label}</span>
)
const StatusBadge=({s}:{s:string})=>{
  const c=s==='Complete'?SUC:s==='Partial'?WRN:DIM
  return <Badge label={s} col={c}/>
}

export default function AdminPYQBankTab({token,API:_API,toast}:Props){
  const API=_API||PAPI
  const hdrs={Authorization:`Bearer ${token}`,'Content-Type':'application/json'}

  // ── View state ───────────────────────────────────────────────────────────────
  const [view,setView]=useState<'home'|'years'|'yearDetail'>('home')
  const [selectedExam,setSelectedExam]=useState<ExamCard|null>(null)
  const [selectedYear,setSelectedYear]=useState<YearCard|null>(null)
  const [ydTab,setYdTab]=useState<'view'|'add'>('view')

  // ── Data ─────────────────────────────────────────────────────────────────────
  const [examCards,setExamCards]=useState<ExamCard[]>([])
  const [yearCards,setYearCards]=useState<YearCard[]>([])
  const [questions,setQuestions]=useState<Question[]>([])
  const [availSubjs,setAvailSubjs]=useState<string[]>([])
  const [availChaps,setAvailChaps]=useState<string[]>([])

  // ── Loading ───────────────────────────────────────────────────────────────────
  const [loading,setLoading]=useState(false)
  const [yearsLoading,setYearsLoading]=useState(false)
  const [qLoading,setQLoading]=useState(false)
  const [uploading,setUploading]=useState(false)

  // ── Modals ───────────────────────────────────────────────────────────────────
  const [showAddExam,setShowAddExam]=useState(false)
  const [showAddYear,setShowAddYear]=useState(false)
  const [editExam,setEditExam]=useState<ExamCard|null>(null)
  const [editYear,setEditYear]=useState<YearCard|null>(null)
  const [expandedQ,setExpandedQ]=useState<Set<string>>(new Set())

  // ── Upload ───────────────────────────────────────────────────────────────────
  const [addMethod,setAddMethod]=useState<'copypaste'|'excel'|'pdf'|'manual'>('copypaste')
  const [upResult,setUpResult]=useState<any>(null)
  const cpTextRef=useRef('')
  const cpKeyRef=useRef('')
  const [excelFile,setExcelFile]=useState<File|null>(null)
  const [pdfFile,setPdfFile]=useState<File|null>(null)
  const [manQ,setManQ]=useState({text:'',hindiText:'',opts:['','','',''],correct:0,subject:'Physics',chapter:'',difficulty:'Medium',explanation:'',hindiExplanation:''})

  // ── Filters ──────────────────────────────────────────────────────────────────
  const [fSubj,setFSubj]=useState('all')
  const [fDiff,setFDiff]=useState('all')
  const [fLang,setFLang]=useState<'en'|'hi'>('en')
  const [fSearch,setFSearch]=useState('')

  // ── Form state ───────────────────────────────────────────────────────────────
  const [neName,setNeName]=useState(''); const [neIcon,setNeIcon]=useState('📚'); const [neColor,setNeColor]=useState('#4D9FFF'); const [neDesc,setNeDesc]=useState('')
  const [nyYear,setNyYear]=useState(''); const [nyStatus,setNyStatus]=useState('Empty')

  // ── API calls ─────────────────────────────────────────────────────────────────
  const loadExamCards=useCallback(async()=>{
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards`,{headers:hdrs})
      const d=await r.json()
      if(d.success) setExamCards(d.examCards||[])
      else setExamCards([])
    }catch{ setExamCards([]) }
    finally{ setLoading(false) }
  },[token,API])

  useEffect(()=>{ loadExamCards() },[loadExamCards])

  const loadYears=useCallback(async(exam:ExamCard)=>{
    setYearsLoading(true); setYearCards([])
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards/${encodeURIComponent(exam.name)}/years`,{headers:hdrs})
      const d=await r.json()
      if(d.success) setYearCards(d.yearCards||[])
    }catch{}
    finally{ setYearsLoading(false) }
  },[token,API])

  const loadQuestions=useCallback(async(yearId:string)=>{
    setQLoading(true); setQuestions([])
    try{
      const p=new URLSearchParams()
      if(fSubj!=='all') p.set('subject',fSubj)
      if(fDiff!=='all') p.set('difficulty',fDiff)
      if(fSearch.trim()) p.set('search',fSearch.trim())
      const r=await fetch(`${API}/api/pyq-bank/years/${yearId}/questions?${p}`,{headers:hdrs})
      const d=await r.json()
      if(d.success){
        setQuestions(d.questions||[])
        setAvailSubjs(d.availableSubjects||[])
        setAvailChaps(d.availableChapters||[])
      }
    }catch{}
    finally{ setQLoading(false) }
  },[token,API,fSubj,fDiff,fSearch])

  // Navigation
  const goYears=(exam:ExamCard)=>{ setSelectedExam(exam); setView('years'); loadYears(exam) }
  const goYearDetail=(yr:YearCard)=>{ setSelectedYear(yr); setView('yearDetail'); setYdTab('view'); loadQuestions(yr._id); setExpandedQ(new Set()) }
  const goHome=()=>{ setView('home'); setSelectedExam(null); setSelectedYear(null) }
  const goYearsList=()=>{ setView('years'); setSelectedYear(null); setExpandedQ(new Set()); if(selectedExam) loadYears(selectedExam) }

  // CRUD
  const createExam=async()=>{
    if(!neName.trim()){toast('Exam name required','e');return}
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards`,{method:'POST',headers:hdrs,body:JSON.stringify({name:neName.trim(),icon:neIcon,color:neColor,desc:neDesc})})
      const d=await r.json()
      if(d.success){toast('Exam card created! ✨');setShowAddExam(false);setNeName('');setNeDesc('');loadExamCards()}
      else toast(d.message||'Failed','e')
    }catch{toast('Server error','e')}
  }

  const updateExam=async()=>{
    if(!editExam||!editExam._id) return
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards/${editExam._id}`,{method:'PUT',headers:hdrs,body:JSON.stringify({name:editExam.name,icon:editExam.icon,color:editExam.color,desc:editExam.desc})})
      const d=await r.json()
      if(d.success){toast('Updated!');setEditExam(null);loadExamCards()}
      else toast(d.message||'Failed','e')
    }catch{toast('Server error','e')}
  }

  const deleteExam=async(id:string,name:string)=>{
    if(!confirm(`Delete "${name}"? All associated year cards and questions will also be deleted permanently.`)) return
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards/${id}`,{method:'DELETE',headers:hdrs})
      const d=await r.json()
      if(d.success){toast(`Deleted "${name}" — ${d.deletedQuestions||0} questions removed`,'w');loadExamCards()}
      else toast(d.message||'Failed','e')
    }catch{toast('Server error','e')}
  }

  const createYear=async()=>{
    if(!nyYear||!selectedExam){toast('Year required','e');return}
    const yr=parseInt(nyYear)
    if(isNaN(yr)||yr<1990||yr>2030){toast('Enter valid year (1990–2030)','e');return}
    try{
      const r=await fetch(`${API}/api/pyq-bank/exam-cards/${encodeURIComponent(selectedExam.name)}/years`,{method:'POST',headers:hdrs,body:JSON.stringify({year:yr,status:nyStatus})})
      const d=await r.json()
      if(d.success){toast('Year card created!');setShowAddYear(false);setNyYear('');loadYears(selectedExam)}
      else toast(d.message||'Failed','e')
    }catch{toast('Server error','e')}
  }

  const deleteYear=async(id:string,year:number)=>{
    if(!confirm(`Delete year ${year}? All ${year} questions will be permanently deleted.`)) return
    try{
      const r=await fetch(`${API}/api/pyq-bank/years/${id}`,{method:'DELETE',headers:hdrs})
      const d=await r.json()
      if(d.success){toast(`Year ${year} deleted — ${d.deletedQuestions||0} questions removed`,'w');if(selectedExam) loadYears(selectedExam)}
      else toast(d.message||'Failed','e')
    }catch{toast('Server error','e')}
  }

  const uploadQs=async()=>{
    if(!selectedYear){return}
    setUploading(true); setUpResult(null)
    try{
      if(addMethod==='copypaste'){
        const body={questionsText:cpTextRef.current,answerKeyText:cpKeyRef.current}
        const r=await fetch(`${API}/api/pyq-bank/years/${selectedYear._id}/upload/copypaste`,{method:'POST',headers:hdrs,body:JSON.stringify(body)})
        const d=await r.json(); setUpResult(d)
        if(d.success){toast(`${d.saved||0} questions uploaded! ✅`);loadQuestions(selectedYear._id);if(selectedExam)loadYears(selectedExam)}
        else toast(d.message||'Upload failed','e')
      } else if(addMethod==='excel'){
        if(!excelFile){toast('Select Excel file first','e');return}
        const fd=new FormData(); fd.append('file',excelFile)
        const r=await fetch(`${API}/api/pyq-bank/years/${selectedYear._id}/upload/excel`,{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd})
        const d=await r.json(); setUpResult(d)
        if(d.success){toast(`${d.saved||0} questions uploaded! ✅`);loadQuestions(selectedYear._id);if(selectedExam)loadYears(selectedExam)}
        else toast(d.message||'Upload failed','e')
      } else if(addMethod==='pdf'){
        if(!pdfFile){toast('Select PDF file first','e');return}
        const fd=new FormData(); fd.append('file',pdfFile)
        const r=await fetch(`${API}/api/pyq-bank/years/${selectedYear._id}/upload/pdf`,{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd})
        const d=await r.json(); setUpResult(d)
        if(d.success){toast(`${d.saved||0} questions extracted from PDF! ✅`);loadQuestions(selectedYear._id);if(selectedExam)loadYears(selectedExam)}
        else toast(d.message||'Upload failed','e')
      } else if(addMethod==='manual'){
        if(!manQ.text.trim()){toast('Question text required','e');return}
        const body={text:manQ.text,hindiText:manQ.hindiText,options:manQ.opts.filter(o=>o.trim()),correct:[manQ.correct],subject:manQ.subject,chapter:manQ.chapter,difficulty:manQ.difficulty,explanation:manQ.explanation,hindiExplanation:manQ.hindiExplanation}
        const r=await fetch(`${API}/api/pyq-bank/years/${selectedYear._id}/questions`,{method:'POST',headers:hdrs,body:JSON.stringify(body)})
        const d=await r.json()
        if(d.success){toast('Question added! ✅');setManQ({text:'',hindiText:'',opts:['','','',''],correct:0,subject:'Physics',chapter:'',difficulty:'Medium',explanation:'',hindiExplanation:''});loadQuestions(selectedYear._id);if(selectedExam)loadYears(selectedExam)}
        else toast(d.message||'Failed','e')
      }
    }catch{toast('Upload error','e')}
    finally{setUploading(false)}
  }

  const toggleQ=(id:string)=>setExpandedQ(p=>{const n=new Set(p);if(n.has(id))n.delete(id);else n.add(id);return n})
  const filteredQs=questions.filter(q=>{
    if(fSubj!=='all'&&q.subject!==fSubj) return false
    if(fDiff!=='all'&&q.difficulty!==fDiff) return false
    if(fSearch.trim()){
      const s=fSearch.toLowerCase()
      return (fLang==='hi'?(q.hindiText||q.text):q.text).toLowerCase().includes(s)||(q.chapter||'').toLowerCase().includes(s)
    }
    return true
  })

  // ═══════════════════════ RENDER ══════════════════════════════════════════════
  return (
    <div style={{fontFamily:'Inter,sans-serif'}}>

      {/* ── HOME VIEW ─────────────────────────────────────────────────────────── */}
      {view==='home'&&(
        <div>
          {/* Header */}
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:12,marginBottom:20}}>
            <div>
              <div style={pt}>📜 PYQ Bank Management</div>
              <div style={ps}>Manage previous year question papers — 3 level system: Exam → Year → Questions</div>
            </div>
            <button onClick={()=>setShowAddExam(true)} style={{...bp,background:`linear-gradient(135deg,${GOLD},#cc8800)`}}>➕ Add Exam Card</button>
          </div>

          {/* Hero Stats Strip */}
          {examCards.length>0&&(
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:10,marginBottom:20}}>
              {[
                ['🗂️','Total Exams',String(examCards.length)],
                ['📅','Total Years',String(examCards.reduce((s,c)=>s+(c.stats?.totalYears||0),0))],
                ['❓','Total Questions',String(examCards.reduce((s,c)=>s+(c.stats?.totalQuestions||0),0))],
                ['✨','Platform','ProveRank PYQ']
              ].map(([ico,lbl2,val])=>(
                <div key={lbl2} style={{...cs,padding:'14px',textAlign:'center',marginBottom:0}}>
                  <div style={{fontSize:22,marginBottom:4}}>{ico}</div>
                  <div style={{fontWeight:800,fontSize:16,color:ACC}}>{val}</div>
                  <div style={{fontSize:11,color:DIM,marginTop:2}}>{lbl2}</div>
                </div>
              ))}
            </div>
          )}

          {/* Exam Cards Grid */}
          {loading?(
            <div style={{textAlign:'center',padding:'60px',color:DIM}}>
              <div style={{fontSize:40,marginBottom:10,animation:'spin 1s linear infinite'}}>⟳</div>
              <div>Loading exam cards...</div>
            </div>
          ):(
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(260px,1fr))',gap:16}}>
              {examCards.map((card,i)=>(
                <div key={card.name||i} style={{...cs,cursor:'pointer',borderColor:`${card.color}44`,transition:'all 0.25s',position:'relative',overflow:'hidden',marginBottom:0}}
                  onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-4px)';(e.currentTarget as HTMLDivElement).style.boxShadow=`0 8px 32px ${card.color}33`}}
                  onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(0)';(e.currentTarget as HTMLDivElement).style.boxShadow='none'}}>
                  {/* Color accent bar */}
                  <div style={{position:'absolute',top:0,left:0,right:0,height:3,background:`linear-gradient(90deg,${card.color},${card.color}44)`}}/>
                  {/* Card top row */}
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:10,paddingTop:4}}>
                    <div style={{display:'flex',gap:10,alignItems:'center'}}>
                      <div style={{fontSize:32,lineHeight:1}}>{card.icon}</div>
                      <div>
                        <div style={{fontWeight:800,fontSize:15,color:TS}}>{card.name}</div>
                        <div style={{fontSize:11,color:DIM,marginTop:1}}>{card.desc}</div>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:4}}>
                      <button onClick={e=>{e.stopPropagation();setEditExam({...card})}} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BOR}`,color:ACC,borderRadius:7,width:28,height:28,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center'}}>✏️</button>
                      {!card.isDefault&&card._id&&(
                        <button onClick={e=>{e.stopPropagation();deleteExam(card._id!,card.name)}} style={{background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.3)',color:DNG,borderRadius:7,width:28,height:28,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center'}}>🗑️</button>
                      )}
                    </div>
                  </div>
                  {/* Stats row */}
                  <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:6,marginBottom:12}}>
                    {[
                      ['Years',card.stats?.totalYears||0],
                      ['Questions',card.stats?.totalQuestions||0],
                      ['Updated',card.stats?.lastUpdated?new Date(card.stats.lastUpdated).toLocaleDateString('en-IN',{day:'2-digit',month:'short'}):'—']
                    ].map(([l,v])=>(
                      <div key={String(l)} style={{background:'rgba(0,0,0,0.3)',borderRadius:8,padding:'6px',textAlign:'center'}}>
                        <div style={{fontWeight:700,fontSize:13,color:card.color}}>{String(v)}</div>
                        <div style={{fontSize:10,color:DIM}}>{l}</div>
                      </div>
                    ))}
                  </div>
                  <button onClick={()=>goYears(card)} style={{...bp,width:'100%',fontSize:12,padding:'9px',background:`linear-gradient(135deg,${card.color},${card.color}cc)`}}>
                    View Years →
                  </button>
                </div>
              ))}

              {/* Add New Card tile */}
              <div onClick={()=>setShowAddExam(true)} style={{...cs,cursor:'pointer',border:`2px dashed ${BOR}`,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',minHeight:180,marginBottom:0,transition:'all 0.2s'}}
                onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.borderColor=ACC;(e.currentTarget as HTMLDivElement).style.background='rgba(77,159,255,0.05)'}}
                onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.borderColor=BOR;(e.currentTarget as HTMLDivElement).style.background=CRD}}>
                <div style={{fontSize:36,marginBottom:8,color:DIM}}>➕</div>
                <div style={{fontWeight:600,color:DIM,fontSize:13}}>Add Exam Card</div>
                <div style={{fontSize:11,color:`${DIM}88`,marginTop:4}}>Custom exam category</div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ── YEARS VIEW ────────────────────────────────────────────────────────── */}
      {view==='years'&&selectedExam&&(
        <div>
          {/* Breadcrumb + header */}
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:12,marginBottom:20}}>
            <div>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4}}>
                <button onClick={goHome} style={{...bg_,padding:'5px 12px',fontSize:12}}>← All Exams</button>
                <span style={{color:DIM,fontSize:12}}>›</span>
                <span style={{color:ACC,fontWeight:700,fontSize:13}}>{selectedExam.icon} {selectedExam.name}</span>
              </div>
              <div style={pt}>{selectedExam.icon} {selectedExam.name} — Year Papers</div>
              <div style={ps}>{selectedExam.desc}</div>
            </div>
            <button onClick={()=>setShowAddYear(true)} style={{...bp,background:`linear-gradient(135deg,${GOLD},#cc8800)`}}>➕ Add Year</button>
          </div>

          {/* Exam summary card */}
          <div style={{...cs,background:`linear-gradient(135deg,${selectedExam.color}11,rgba(0,18,36,0.9))`,borderColor:`${selectedExam.color}44`,marginBottom:20}}>
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(120px,1fr))',gap:12}}>
              {[
                ['📅','Years',String(yearCards.length)],
                ['❓','Questions',String(yearCards.reduce((s,y)=>s+(y.questionCount||0),0))],
                ['✅','Complete',String(yearCards.filter(y=>y.status==='Complete').length)],
                ['⏳','Partial',String(yearCards.filter(y=>y.status==='Partial').length)],
                ['🆕','Empty',String(yearCards.filter(y=>y.status==='Empty').length)]
              ].map(([ico,l,v])=>(
                <div key={l} style={{textAlign:'center'}}>
                  <div style={{fontSize:20}}>{ico}</div>
                  <div style={{fontWeight:800,fontSize:16,color:selectedExam.color}}>{v}</div>
                  <div style={{fontSize:11,color:DIM}}>{l}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Year Cards Grid */}
          {yearsLoading?(
            <div style={{textAlign:'center',padding:'50px',color:DIM}}>
              <div style={{fontSize:36,marginBottom:8}}>⟳</div>Loading years...
            </div>
          ):yearCards.length===0?(
            <div style={{...cs,textAlign:'center',padding:'50px'}}>
              <div style={{fontSize:56,marginBottom:12}}>📅</div>
              <div style={{fontWeight:700,fontSize:16,color:TS,marginBottom:8}}>No years added yet</div>
              <div style={{color:DIM,fontSize:13,marginBottom:20}}>Add year cards to start uploading question papers</div>
              <button onClick={()=>setShowAddYear(true)} style={bp}>➕ Add First Year</button>
            </div>
          ):(
            <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(220px,1fr))',gap:14}}>
              {yearCards.sort((a,b)=>b.year-a.year).map(yc=>(
                <div key={yc._id} style={{...cs,cursor:'pointer',border:`1px solid ${yc.status==='Complete'?`${SUC}44`:yc.status==='Partial'?`${WRN}44`:BOR}`,transition:'all 0.2s',marginBottom:0,position:'relative',overflow:'hidden'}}
                  onMouseEnter={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(-3px)'}}
                  onMouseLeave={e=>{(e.currentTarget as HTMLDivElement).style.transform='translateY(0)'}}>
                  {/* Status accent */}
                  <div style={{position:'absolute',top:0,left:0,right:0,height:3,background:yc.status==='Complete'?SUC:yc.status==='Partial'?WRN:DIM}}/>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:10,paddingTop:4}}>
                    <div>
                      <div style={{fontWeight:800,fontSize:24,color:GOLD,fontFamily:'Playfair Display,serif'}}>{yc.year}</div>
                      <StatusBadge s={yc.status}/>
                    </div>
                    <div style={{display:'flex',gap:4}}>
                      <button onClick={e=>{e.stopPropagation();setEditYear(yc)}} style={{background:'rgba(77,159,255,0.1)',border:`1px solid ${BOR}`,color:ACC,borderRadius:7,width:26,height:26,cursor:'pointer',fontSize:12,display:'flex',alignItems:'center',justifyContent:'center'}}>✏️</button>
                      <button onClick={e=>{e.stopPropagation();deleteYear(yc._id,yc.year)}} style={{background:'rgba(255,77,77,0.1)',border:'1px solid rgba(255,77,77,0.3)',color:DNG,borderRadius:7,width:26,height:26,cursor:'pointer',fontSize:12,display:'flex',alignItems:'center',justifyContent:'center'}}>🗑️</button>
                    </div>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6,marginBottom:12}}>
                    <div style={{background:'rgba(0,0,0,0.3)',borderRadius:7,padding:'6px',textAlign:'center'}}>
                      <div style={{fontWeight:700,color:ACC,fontSize:14}}>{yc.questionCount||0}</div>
                      <div style={{fontSize:10,color:DIM}}>Questions</div>
                    </div>
                    <div style={{background:'rgba(0,0,0,0.3)',borderRadius:7,padding:'6px',textAlign:'center'}}>
                      <div style={{fontWeight:700,color:WRN,fontSize:12}}>{yc.updatedAt?new Date(yc.updatedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short'}):'—'}</div>
                      <div style={{fontSize:10,color:DIM}}>Updated</div>
                    </div>
                  </div>
                  <div style={{display:'flex',gap:6}}>
                    <button onClick={()=>{goYearDetail(yc);setYdTab('view')}} style={{...bg_,flex:1,fontSize:11,padding:'7px'}}>👁 View</button>
                    <button onClick={()=>{goYearDetail(yc);setYdTab('add')}}  style={{...bp,flex:1,fontSize:11,padding:'7px'}}>➕ Add</button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ── YEAR DETAIL VIEW ──────────────────────────────────────────────────── */}
      {view==='yearDetail'&&selectedExam&&selectedYear&&(
        <div>
          {/* Breadcrumb */}
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:16,flexWrap:'wrap'}}>
            <button onClick={goHome}  style={{...bg_,padding:'5px 12px',fontSize:12}}>All Exams</button>
            <span style={{color:DIM}}>›</span>
            <button onClick={goYearsList} style={{...bg_,padding:'5px 12px',fontSize:12}}>{selectedExam.icon} {selectedExam.name}</button>
            <span style={{color:DIM}}>›</span>
            <span style={{color:GOLD,fontWeight:700,fontSize:13}}>{selectedYear.year} Paper</span>
          </div>

          {/* Year detail header */}
          <div style={{...cs,background:`linear-gradient(135deg,rgba(0,30,60,0.9),rgba(0,15,40,0.95))`,borderColor:`${GOLD}44`,marginBottom:16}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:12}}>
              <div>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:GOLD}}>{selectedExam.icon} {selectedExam.name} {selectedYear.year}</div>
                <div style={{display:'flex',gap:8,marginTop:6,flexWrap:'wrap'}}>
                  <StatusBadge s={selectedYear.status}/>
                  <Badge label={`${filteredQs.length} Questions`} col={ACC}/>
                  {availSubjs.map(s=><Badge key={s} label={s} col={PRP}/>)}
                </div>
              </div>
              <div style={{display:'flex',gap:8}}>
                <button onClick={()=>setYdTab('view')} style={{...(ydTab==='view'?bp:bg_),fontSize:12,padding:'8px 16px'}}>👁 View Paper</button>
                <button onClick={()=>setYdTab('add')}  style={{...(ydTab==='add' ?bp:bg_),fontSize:12,padding:'8px 16px'}}>➕ Add Questions</button>
              </div>
            </div>
          </div>

          {/* ──── VIEW PAPER TAB ─────────────────────────────────────── */}
          {ydTab==='view'&&(
            <div>
              {/* Filter Bar */}
              <div style={{...cs,padding:'14px',marginBottom:12}}>
                <div style={{display:'flex',gap:8,flexWrap:'wrap',alignItems:'center'}}>
                  {/* Lang toggle */}
                  <div style={{display:'flex',border:`1px solid ${BOR}`,borderRadius:8,overflow:'hidden'}}>
                    {(['en','hi'] as const).map(l=>(
                      <button key={l} onClick={()=>setFLang(l)} style={{padding:'7px 14px',background:fLang===l?ACC:'transparent',color:fLang===l?'#fff':DIM,border:'none',cursor:'pointer',fontSize:12,fontWeight:fLang===l?700:400,transition:'all 0.2s'}}>
                        {l==='en'?'🇺🇸 English':'🇮🇳 Hindi'}
                      </button>
                    ))}
                  </div>
                  <select value={fSubj} onChange={e=>setFSubj(e.target.value)} style={{...inp,width:'auto',padding:'7px 12px'}}>
                    <option value="all">All Subjects</option>
                    {availSubjs.map(s=><option key={s} value={s}>{s}</option>)}
                  </select>
                  <select value={fDiff} onChange={e=>setFDiff(e.target.value)} style={{...inp,width:'auto',padding:'7px 12px'}}>
                    <option value="all">All Difficulty</option>
                    {['Easy','Medium','Hard'].map(d=><option key={d} value={d}>{d}</option>)}
                  </select>
                  <input value={fSearch} onChange={e=>setFSearch(e.target.value)} placeholder="🔍 Search questions..." style={{...inp,width:200,padding:'7px 12px'}}/>
                  <button onClick={()=>selectedYear&&loadQuestions(selectedYear._id)} style={{...bg_,padding:'7px 14px',fontSize:12}}>🔄 Refresh</button>
                </div>
                {filteredQs.length>0&&(
                  <div style={{display:'flex',gap:6,marginTop:8,flexWrap:'wrap',fontSize:11,color:DIM}}>
                    <span>{filteredQs.length} questions shown</span>
                    <span>·</span>
                    <span style={{color:SUC,cursor:'pointer'}} onClick={()=>setExpandedQ(new Set(filteredQs.map(q=>q._id)))}>Show all answers</span>
                    <span>·</span>
                    <span style={{color:DNG,cursor:'pointer'}} onClick={()=>setExpandedQ(new Set())}>Hide all answers</span>
                  </div>
                )}
              </div>

              {/* Questions */}
              {qLoading?(
                <div style={{textAlign:'center',padding:'50px',color:DIM}}>
                  <div style={{fontSize:36,marginBottom:8}}>⟳</div>Loading questions...
                </div>
              ):filteredQs.length===0?(
                <div style={{...cs,textAlign:'center',padding:'50px'}}>
                  <div style={{fontSize:56,marginBottom:12}}>📄</div>
                  <div style={{fontWeight:700,color:TS,marginBottom:8}}>{questions.length===0?'No questions uploaded yet':'No questions match your filter'}</div>
                  <div style={{color:DIM,marginBottom:20,fontSize:13}}>{questions.length===0?'Use the "Add Questions" tab to upload questions for this year.':'Try changing the filters above.'}</div>
                  {questions.length===0&&<button onClick={()=>setYdTab('add')} style={bp}>➕ Add Questions Now</button>}
                </div>
              ):(
                <div>
                  {filteredQs.map((q,idx)=>{
                    const qText=fLang==='hi'&&q.hindiText?q.hindiText:q.text
                    const qOpts=fLang==='hi'&&q.hindiOptions&&q.hindiOptions.length>0?q.hindiOptions:q.options
                    const isExpanded=expandedQ.has(q._id)
                    return(
                      <div key={q._id} style={{...cs,marginBottom:10,borderLeft:`3px solid ${q.difficulty==='Hard'?DNG:q.difficulty==='Easy'?SUC:WRN}`}}>
                        <div style={{display:'flex',gap:8,marginBottom:8,flexWrap:'wrap'}}>
                          <Badge label={`Q${idx+1}`} col={GOLD}/>
                          {q.subject&&<Badge label={q.subject} col={ACC}/>}
                          {q.chapter&&<Badge label={q.chapter} col={PRP}/>}
                          {q.difficulty&&<Badge label={q.difficulty} col={q.difficulty==='Hard'?DNG:q.difficulty==='Easy'?SUC:WRN}/>}
                        </div>
                        <div style={{fontSize:14,color:TS,lineHeight:1.6,marginBottom:12,fontFamily:'Georgia,serif'}}
                          dangerouslySetInnerHTML={{__html:qText||''}}/>
                        {/* Options */}
                        {qOpts&&qOpts.length>0&&(
                          <div style={{display:'grid',gridTemplateColumns:qOpts.length<=2?'1fr 1fr':'1fr 1fr',gap:6,marginBottom:10}}>
                            {qOpts.map((opt,oi)=>{
                              const isCorrect=isExpanded&&q.correct&&q.correct.includes(oi)
                              return(
                                <div key={oi} style={{padding:'8px 12px',borderRadius:8,fontSize:13,background:isCorrect?'rgba(0,196,140,0.15)':'rgba(0,10,30,0.5)',border:`1px solid ${isCorrect?SUC:BOR}`,color:isCorrect?SUC:TS,transition:'all 0.3s',display:'flex',gap:8}}>
                                  <span style={{color:isCorrect?SUC:DIM,fontWeight:700,minWidth:18}}>{String.fromCharCode(65+oi)}.</span>
                                  <span>{opt}</span>
                                  {isCorrect&&<span style={{marginLeft:'auto'}}>✅</span>}
                                </div>
                              )
                            })}
                          </div>
                        )}
                        {/* Answer/Explanation toggle */}
                        <div style={{display:'flex',gap:8,alignItems:'center'}}>
                          <button onClick={()=>toggleQ(q._id)} style={{...bg_,fontSize:11,padding:'5px 14px',background:isExpanded?'rgba(0,196,140,0.1)':'rgba(0,30,60,0.7)',borderColor:isExpanded?`${SUC}44`:BOR,color:isExpanded?SUC:DIM}}>
                            {isExpanded?'🙈 Hide Answer':'👁 Show Answer'}
                          </button>
                          {isExpanded&&(q.explanation||(fLang==='hi'&&q.hindiExplanation))&&(
                            <div style={{flex:1,background:'rgba(0,100,50,0.1)',border:`1px solid ${SUC}33`,borderRadius:8,padding:'8px 12px',fontSize:12,color:SUC,lineHeight:1.5}}>
                              💡 {fLang==='hi'&&q.hindiExplanation?q.hindiExplanation:q.explanation}
                            </div>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          )}

          {/* ──── ADD QUESTIONS TAB ──────────────────────────────────── */}
          {ydTab==='add'&&(
            <div>
              {/* Method selector */}
              <div style={{...cs,padding:'16px',marginBottom:16}}>
                <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:12}}>📤 Upload Method</div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8}}>
                  {([['copypaste','📋','Copy-Paste'],['excel','📊','Excel File'],['pdf','📄','PDF Parse'],['manual','✏️','Manual Form']] as const).map(([v,ico,l])=>(
                    <button key={v} onClick={()=>{setAddMethod(v);setUpResult(null)}} style={{padding:'12px 8px',background:addMethod===v?`linear-gradient(135deg,${ACC},#0055CC)`:'rgba(0,22,40,0.6)',border:`1px solid ${addMethod===v?ACC:BOR}`,borderRadius:10,color:addMethod===v?'#fff':DIM,cursor:'pointer',textAlign:'center',fontSize:12,fontWeight:addMethod===v?700:400,transition:'all 0.2s'}}>
                      <div style={{fontSize:22,marginBottom:4}}>{ico}</div>{l}
                    </button>
                  ))}
                </div>
              </div>

              {/* Copy-Paste */}
              {addMethod==='copypaste'&&(
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:12,color:TS,display:'flex',gap:8,alignItems:'center'}}>📋 Copy-Paste Questions<Badge label={`${selectedExam.name} ${selectedYear.year}`} col={GOLD}/></div>
                  <div style={{background:'rgba(0,50,100,0.2)',border:`1px solid ${ACC}33`,borderRadius:10,padding:'12px',marginBottom:14,fontSize:12,color:DIM}}>
                    <strong style={{color:ACC}}>Format:</strong> Paste numbered questions with options A. B. C. D. each on new line. E.g.:<br/>
                    <code style={{color:WRN}}>1. Which element has atomic number 6?<br/>A. Hydrogen&nbsp;&nbsp;B. Carbon&nbsp;&nbsp;C. Nitrogen&nbsp;&nbsp;D. Oxygen</code>
                  </div>
                  <div style={{marginBottom:12}}>
                    <label style={lbl}>Questions Text (paste all questions)</label>
                    <textarea rows={10} onChange={e=>cpTextRef.current=e.target.value} placeholder={'1. Which of the following...\nA. Option 1\nB. Option 2\nC. Option 3\nD. Option 4\n\n2. Next question...'} style={{...inp,resize:'vertical' as any}}/>
                  </div>
                  <div>
                    <label style={lbl}>Answer Key (optional) — Format: 1-B, 2-A or one per line</label>
                    <textarea rows={4} onChange={e=>cpKeyRef.current=e.target.value} placeholder={'1-B\n2-A\n3-D\n4-C'} style={{...inp,resize:'vertical' as any}}/>
                  </div>
                </div>
              )}

              {/* Excel */}
              {addMethod==='excel'&&(
                <div style={{...cs,textAlign:'center',padding:'30px'}}>
                  <div style={{fontSize:48,marginBottom:10}}>📊</div>
                  <div style={{fontWeight:700,fontSize:15,color:TS,marginBottom:6}}>Upload Excel / CSV File</div>
                  <div style={{fontSize:12,color:DIM,marginBottom:6}}>Required columns: <span style={{color:ACC}}>Question, Option A, Option B, Option C, Option D, Correct Answer</span></div>
                  <div style={{fontSize:11,color:DIM,marginBottom:16}}>Optional: Subject, Chapter, Difficulty, Explanation, Hindi Question</div>
                  <div style={{background:'rgba(0,50,100,0.15)',border:`1px solid ${ACC}33`,borderRadius:8,padding:'10px',marginBottom:16,fontSize:11,color:DIM}}>
                    Correct Answer column: use A/B/C/D format
                  </div>
                  <input type="file" accept=".xlsx,.xls,.csv" onChange={e=>setExcelFile(e.target.files?.[0]||null)} style={{color:TS,fontSize:13,marginBottom:12}}/>
                  {excelFile&&<div style={{fontSize:12,color:SUC,marginTop:6}}>✅ Selected: {excelFile.name}</div>}
                </div>
              )}

              {/* PDF */}
              {addMethod==='pdf'&&(
                <div style={{...cs,textAlign:'center',padding:'30px'}}>
                  <div style={{fontSize:48,marginBottom:10}}>📄</div>
                  <div style={{fontWeight:700,fontSize:15,color:TS,marginBottom:6}}>Upload PDF Question Paper</div>
                  <div style={{fontSize:12,color:DIM,marginBottom:6}}>AI will automatically parse numbered questions and options from the PDF</div>
                  <div style={{background:'rgba(255,184,77,0.1)',border:`1px solid ${WRN}44`,borderRadius:8,padding:'10px',marginBottom:16,fontSize:11,color:WRN}}>
                    ⚠️ Works best with selectable text PDFs — scanned images not supported
                  </div>
                  <input type="file" accept=".pdf" onChange={e=>setPdfFile(e.target.files?.[0]||null)} style={{color:TS,fontSize:13,marginBottom:12}}/>
                  {pdfFile&&<div style={{fontSize:12,color:SUC,marginTop:6}}>✅ Selected: {pdfFile.name}</div>}
                </div>
              )}

              {/* Manual Form */}
              {addMethod==='manual'&&(
                <div style={cs}>
                  <div style={{fontWeight:700,marginBottom:14,color:TS}}>✏️ Add Question Manually</div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:12}}>
                    <div style={{gridColumn:'1/-1'}}>
                      <label style={lbl}>Question Text (English) *</label>
                      <textarea rows={3} value={manQ.text} onChange={e=>setManQ(p=>({...p,text:e.target.value}))} placeholder="Enter question text..." style={{...inp,resize:'vertical' as any}}/>
                    </div>
                    <div style={{gridColumn:'1/-1'}}>
                      <label style={lbl}>Question Text (Hindi - optional)</label>
                      <textarea rows={2} value={manQ.hindiText} onChange={e=>setManQ(p=>({...p,hindiText:e.target.value}))} placeholder="प्रश्न यहाँ लिखें..." style={{...inp,resize:'vertical' as any,fontFamily:'inherit'}}/>
                    </div>
                  </div>
                  <div style={{marginBottom:12}}>
                    <label style={lbl}>Options (A, B, C, D) *</label>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                      {manQ.opts.map((opt,i)=>(
                        <div key={i} style={{display:'flex',gap:6,alignItems:'center'}}>
                          <span style={{color:GOLD,fontWeight:700,minWidth:18}}>{String.fromCharCode(65+i)}.</span>
                          <input value={opt} onChange={e=>setManQ(p=>{const o=[...p.opts];o[i]=e.target.value;return{...p,opts:o}})} placeholder={`Option ${String.fromCharCode(65+i)}`} style={{...inp}}/>
                        </div>
                      ))}
                    </div>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(160px,1fr))',gap:12,marginBottom:12}}>
                    <div>
                      <label style={lbl}>Correct Answer *</label>
                      <select value={manQ.correct} onChange={e=>setManQ(p=>({...p,correct:parseInt(e.target.value)}))} style={inp}>
                        {manQ.opts.map((_,i)=><option key={i} value={i}>{String.fromCharCode(65+i)}. {manQ.opts[i]||`Option ${String.fromCharCode(65+i)}`}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={lbl}>Subject</label>
                      <select value={manQ.subject} onChange={e=>setManQ(p=>({...p,subject:e.target.value}))} style={inp}>
                        {['Physics','Chemistry','Biology','Mathematics','General'].map(s=><option key={s} value={s}>{s}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={lbl}>Difficulty</label>
                      <select value={manQ.difficulty} onChange={e=>setManQ(p=>({...p,difficulty:e.target.value}))} style={inp}>
                        {['Easy','Medium','Hard'].map(d=><option key={d} value={d}>{d}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={lbl}>Chapter</label>
                      <input value={manQ.chapter} onChange={e=>setManQ(p=>({...p,chapter:e.target.value}))} placeholder="Chapter name..." style={inp}/>
                    </div>
                    <div style={{gridColumn:'1/-1'}}>
                      <label style={lbl}>Explanation (optional)</label>
                      <textarea rows={2} value={manQ.explanation} onChange={e=>setManQ(p=>({...p,explanation:e.target.value}))} placeholder="Explain the correct answer..." style={{...inp,resize:'vertical' as any}}/>
                    </div>
                  </div>
                </div>
              )}

              {/* Upload result */}
              {upResult&&(
                <div style={{background:upResult.success?'rgba(0,196,140,0.1)':'rgba(255,77,77,0.1)',border:`1px solid ${upResult.success?SUC:DNG}44`,borderRadius:10,padding:'12px 16px',margin:'14px 0',fontSize:13}}>
                  {upResult.success?`✅ ${upResult.message}`:`❌ ${upResult.message}`}
                  {upResult.saved!==undefined&&<div style={{fontSize:11,color:DIM,marginTop:4}}>Saved: {upResult.saved} | Failed: {upResult.failed||0} | Parsed: {upResult.parsed||upResult.saved}</div>}
                </div>
              )}

              <div style={{display:'flex',gap:8,marginTop:16}}>
                <button onClick={uploadQs} disabled={uploading} style={{...bp,flex:1,opacity:uploading?0.7:1}}>
                  {uploading?'⟳ Uploading...':addMethod==='manual'?'➕ Add Question':'⬆️ Upload Questions'}
                </button>
                <button onClick={()=>setYdTab('view')} style={bg_}>👁 View Paper</button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ══════════════════ MODALS ═══════════════════════════════════════════════ */}

      {/* Add Exam Card Modal */}
      {showAddExam&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:9990,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setShowAddExam(false)}>
          <div style={{...cs,width:'100%',maxWidth:480,maxHeight:'90vh',overflowY:'auto' as any}} onClick={e=>e.stopPropagation()}>
            <div style={{fontWeight:700,fontSize:16,color:GOLD,marginBottom:16}}>➕ Add New Exam Card</div>
            <div style={{display:'grid',gap:12}}>
              <div><label style={lbl}>Exam Name *</label><input value={neName} onChange={e=>setNeName(e.target.value)} placeholder="e.g. NEET PG, AIIMS, SSC CGL..." style={inp}/></div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Icon / Emoji</label><div style={{display:"grid",gridTemplateColumns:"repeat(5,1fr)",gap:6}}>{EMOJI_OPTIONS.map(o=>(<button key={o.v} type="button" onClick={()=>setNeIcon(o.v)} title={o.l} style={{padding:"8px 4px",background:neIcon===o.v?"rgba(77,159,255,0.25)":"rgba(0,22,40,0.6)",border:`1.5px solid ${neIcon===o.v?ACC:BOR}`,borderRadius:8,cursor:"pointer",fontSize:20}}>{o.v}</button>))}</div><div style={{fontSize:11,color:DIM,marginTop:4}}>Selected: <span style={{color:ACC}}>{neIcon}</span></div></div>
                <div><label style={lbl}>Color (hex)</label><div style={{display:'flex',gap:6}}><input value={neColor} onChange={e=>setNeColor(e.target.value)} placeholder="#4D9FFF" style={{...inp,flex:1}}/><div style={{width:40,borderRadius:8,background:neColor,border:`1px solid ${BOR}`}}/></div></div>
              </div>
              <div><label style={lbl}>Description</label><input value={neDesc} onChange={e=>setNeDesc(e.target.value)} placeholder="Short description..." style={inp}/></div>
            </div>
            <div style={{display:'flex',gap:8,marginTop:16}}>
              <button onClick={createExam} style={{...bp,flex:1}}>✅ Create Card</button>
              <button onClick={()=>setShowAddExam(false)} style={bg_}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Exam Modal */}
      {editExam&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:9990,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setEditExam(null)}>
          <div style={{...cs,width:'100%',maxWidth:480}} onClick={e=>e.stopPropagation()}>
            <div style={{fontWeight:700,fontSize:16,color:ACC,marginBottom:16}}>✏️ Edit — {editExam.name}</div>
            <div style={{display:'grid',gap:12}}>
              <div><label style={lbl}>Exam Name</label><input value={editExam.name} onChange={e=>setEditExam(p=>p?{...p,name:e.target.value}:null)} style={inp}/></div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                <div><label style={lbl}>Icon / Emoji</label>
                <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:5,marginBottom:6}}>
                  {EMOJI_OPTIONS.map(o=>(
                    <button key={o.v} type="button" onClick={()=>setEditExam(p=>p?{...p,icon:o.v}:null)} title={o.l} style={{padding:'7px 3px',background:editExam.icon===o.v?'rgba(77,159,255,0.25)':'rgba(0,22,40,0.6)',border:`1.5px solid ${editExam.icon===o.v?ACC:BOR}`,borderRadius:7,cursor:'pointer',fontSize:18,transition:'all 0.15s'}}>{o.v}</button>
                  ))}
                </div>
              </div>
                <div><label style={lbl}>Card Color</label>
                <div style={{display:'grid',gridTemplateColumns:'repeat(8,1fr)',gap:5,marginBottom:6}}>
                  {COLOR_OPTIONS.map(o=>(
                    <button key={o.v} type="button" onClick={()=>setEditExam(p=>p?{...p,color:o.v}:null)} title={o.l} style={{width:'100%',aspectRatio:'1',background:o.bg,borderRadius:7,border:editExam.color===o.v?'3px solid #fff':'2px solid transparent',cursor:'pointer',boxShadow:editExam.color===o.v?`0 0 10px ${o.bg}88`:''}}/>
                  ))}
                </div>
                <div style={{display:'flex',gap:6}}><input value={editExam.color} onChange={e=>setEditExam(p=>p?{...p,color:e.target.value}:null)} style={{...inp,flex:1,padding:'8px 12px'}}/><div style={{width:34,height:34,borderRadius:7,background:editExam.color,border:`2px solid ${BOR}`}}/></div>
              </div>
              </div>
              <div><label style={lbl}>Description</label><input value={editExam.desc} onChange={e=>setEditExam(p=>p?{...p,desc:e.target.value}:null)} style={inp}/></div>
            </div>
            <div style={{display:'flex',gap:8,marginTop:16}}>
              <button onClick={updateExam} style={{...bp,flex:1}}>💾 Save Changes</button>
              <button onClick={()=>setEditExam(null)} style={bg_}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Add Year Modal */}
      {showAddYear&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:9990,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setShowAddYear(false)}>
          <div style={{...cs,width:'100%',maxWidth:400}} onClick={e=>e.stopPropagation()}>
            <div style={{fontWeight:700,fontSize:16,color:GOLD,marginBottom:16}}>📅 Add Year Card — {selectedExam?.name}</div>
            <div style={{display:'grid',gap:12}}>
              <div><label style={lbl}>Year *</label><input value={nyYear} onChange={e=>setNyYear(e.target.value)} placeholder="e.g. 2024" type="number" min="1990" max="2030" style={inp}/></div>
              <div>
                <label style={lbl}>Status</label>
                <select value={nyStatus} onChange={e=>setNyStatus(e.target.value)} style={inp}>
                  {['Empty','Partial','Complete'].map(s=><option key={s} value={s}>{s}</option>)}
                </select>
              </div>
            </div>
            <div style={{display:'flex',gap:8,marginTop:16}}>
              <button onClick={createYear} style={{...bp,flex:1}}>✅ Create Year Card</button>
              <button onClick={()=>setShowAddYear(false)} style={bg_}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Year Modal */}
      {editYear&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:9990,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={()=>setEditYear(null)}>
          <div style={{...cs,width:'100%',maxWidth:400}} onClick={e=>e.stopPropagation()}>
            <div style={{fontWeight:700,fontSize:16,color:ACC,marginBottom:16}}>✏️ Edit Year — {editYear.year}</div>
            <div style={{display:'grid',gap:12}}>
              <div>
                <label style={lbl}>Status</label>
                <select value={editYear.status} onChange={e=>setEditYear(p=>p?{...p,status:e.target.value}:null)} style={inp}>
                  {['Empty','Partial','Complete'].map(s=><option key={s} value={s}>{s}</option>)}
                </select>
              </div>
              <div><label style={lbl}>Notes</label><input value={editYear.notes||''} onChange={e=>setEditYear(p=>p?{...p,notes:e.target.value}:null)} placeholder="Internal notes..." style={inp}/></div>
            </div>
            <div style={{display:'flex',gap:8,marginTop:16}}>
              <button onClick={async()=>{
                try{
                  const r=await fetch(`${API}/api/pyq-bank/years/${editYear._id}`,{method:'PUT',headers:hdrs,body:JSON.stringify({status:editYear.status,notes:editYear.notes})})
                  const d=await r.json()
                  if(d.success){toast('Year updated!');setEditYear(null);if(selectedExam)loadYears(selectedExam)}
                  else toast(d.message||'Failed','e')
                }catch{toast('Error','e')}
              }} style={{...bp,flex:1}}>💾 Save</button>
              <button onClick={()=>setEditYear(null)} style={bg_}>Cancel</button>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
