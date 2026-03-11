#!/bin/bash
# ProveRank — Live Exam Attempt Page (Demo)
set -e
G='\033[0;32m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'
log()  { echo -e "${G}[✓]${N} $1"; }
step() { echo -e "\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n${C}  $1${N}\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }

FE=~/workspace/frontend
mkdir -p $FE/app/exam/demo/attempt

step "Live Exam Attempt Page"
cat > $FE/app/exam/demo/attempt/page.tsx << 'EXAMEOF'
'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'

/* ─── 30 Demo NEET Questions ──────────────────────────────── */
const QUESTIONS = [
  // PHYSICS
  { id:1, subject:'Physics', chapter:'Laws of Motion', text:'A block of mass 5 kg is placed on a frictionless surface. A force of 20 N is applied horizontally. What is the acceleration?', options:['2 m/s²','4 m/s²','5 m/s²','10 m/s²'], correct:1 },
  { id:2, subject:'Physics', chapter:'Work & Energy', text:'A body of mass 2 kg moves with velocity 3 m/s. Its kinetic energy is:', options:['3 J','6 J','9 J','12 J'], correct:2 },
  { id:3, subject:'Physics', chapter:'Gravitation', text:'The escape velocity from the surface of Earth (radius R, mass M) is:', options:['√(GM/R)','√(2GM/R)','√(GM/2R)','2√(GM/R)'], correct:1 },
  { id:4, subject:'Physics', chapter:'Thermodynamics', text:'Which process is represented by PV = constant?', options:['Adiabatic','Isochoric','Isothermal','Isobaric'], correct:2 },
  { id:5, subject:'Physics', chapter:'Waves', text:'The speed of sound in air at 0°C is approximately:', options:['232 m/s','332 m/s','432 m/s','532 m/s'], correct:1 },
  { id:6, subject:'Physics', chapter:'Electrostatics', text:'The SI unit of electric field is:', options:['N/C','V·m','C/N','J/C'], correct:0 },
  { id:7, subject:'Physics', chapter:'Current Electricity', text:'Ohm\'s law is valid for:', options:['Semiconductors','Electrolytes','Metallic conductors','Vacuum tubes'], correct:2 },
  { id:8, subject:'Physics', chapter:'Optics', text:'The refractive index of glass with respect to air is 1.5. The critical angle is:', options:['sin⁻¹(2/3)','sin⁻¹(1/2)','sin⁻¹(1/3)','sin⁻¹(3/4)'], correct:0 },
  { id:9, subject:'Physics', chapter:'Modern Physics', text:'The photoelectric effect was explained by:', options:['Maxwell','Hertz','Einstein','Bohr'], correct:2 },
  { id:10, subject:'Physics', chapter:'Semiconductor', text:'The majority carriers in n-type semiconductor are:', options:['Holes','Electrons','Protons','Neutrons'], correct:1 },

  // CHEMISTRY
  { id:11, subject:'Chemistry', chapter:'Atomic Structure', text:'The number of electrons in the outermost shell of Na⁺ ion is:', options:['1','8','11','2'], correct:1 },
  { id:12, subject:'Chemistry', chapter:'Periodic Table', text:'Which element has the highest electronegativity?', options:['Oxygen','Chlorine','Fluorine','Nitrogen'], correct:2 },
  { id:13, subject:'Chemistry', chapter:'Chemical Bonding', text:'The shape of water molecule is:', options:['Linear','Trigonal planar','Bent/Angular','Tetrahedral'], correct:2 },
  { id:14, subject:'Chemistry', chapter:'Equilibrium', text:'Le Chatelier\'s principle is applicable to:', options:['Only physical equilibrium','Only chemical equilibrium','Both physical and chemical','None'], correct:2 },
  { id:15, subject:'Chemistry', chapter:'Thermodynamics', text:'For a spontaneous reaction at constant T and P:', options:['ΔG > 0','ΔG = 0','ΔG < 0','ΔH > 0'], correct:2 },
  { id:16, subject:'Chemistry', chapter:'Redox', text:'Oxidation number of Cr in K₂Cr₂O₇ is:', options:['+3','+6','+7','+4'], correct:1 },
  { id:17, subject:'Chemistry', chapter:'Organic — Basics', text:'IUPAC name of CH₃-CH₂-OH is:', options:['Methanol','Propanol','Ethanol','Butanol'], correct:2 },
  { id:18, subject:'Chemistry', chapter:'Hydrocarbons', text:'Benzene undergoes preferentially:', options:['Addition','Substitution','Elimination','Polymerisation'], correct:1 },
  { id:19, subject:'Chemistry', chapter:'Coordination', text:'The oxidation state of Fe in [Fe(CN)₆]³⁻ is:', options:['+2','+3','+4','+1'], correct:1 },
  { id:20, subject:'Chemistry', chapter:'Polymers', text:'Nylon-6,6 is obtained from:', options:['Caprolactam','Hexamethylene diamine + Adipic acid','Ethylene + HCl','Styrene'], correct:1 },

  // BIOLOGY — Botany
  { id:21, subject:'Biology', chapter:'Cell Biology', text:'The powerhouse of the cell is:', options:['Nucleus','Ribosome','Mitochondria','Golgi body'], correct:2 },
  { id:22, subject:'Biology', chapter:'Plant Physiology', text:'Stomata are mainly responsible for:', options:['Photosynthesis','Transpiration','Respiration','Absorption'], correct:1 },
  { id:23, subject:'Biology', chapter:'Photosynthesis', text:'The light-independent reactions of photosynthesis occur in:', options:['Thylakoid membrane','Stroma','Cytoplasm','Nucleus'], correct:1 },
  { id:24, subject:'Biology', chapter:'Plant Kingdom', text:'Which division includes mosses?', options:['Pteridophyta','Bryophyta','Gymnospermae','Angiospermae'], correct:1 },
  { id:25, subject:'Biology', chapter:'Reproduction in Plants', text:'Double fertilization is characteristic of:', options:['Gymnosperms','Pteridophytes','Angiosperms','Bryophytes'], correct:2 },

  // BIOLOGY — Zoology
  { id:26, subject:'Biology', chapter:'Human Physiology', text:'The normal blood pressure of a healthy adult is:', options:['100/70 mmHg','120/80 mmHg','140/90 mmHg','160/100 mmHg'], correct:1 },
  { id:27, subject:'Biology', chapter:'Genetics', text:'A cross between homozygous dominant and homozygous recessive gives:', options:['All dominant phenotype','All recessive','3:1 ratio','1:1 ratio'], correct:0 },
  { id:28, subject:'Biology', chapter:'Evolution', text:'The theory of Natural Selection was proposed by:', options:['Lamarck','Mendel','Darwin','De Vries'], correct:2 },
  { id:29, subject:'Biology', chapter:'Human Reproduction', text:'Fertilization in humans occurs in the:', options:['Uterus','Cervix','Fallopian tube','Ovary'], correct:2 },
  { id:30, subject:'Biology', chapter:'Ecology', text:'The pyramid of energy is always:', options:['Inverted','Upright','Spindle-shaped','Irregular'], correct:1 },
]

const SECTIONS = [
  { name:'Physics',   color:'#4D9FFF', range:[0,9]  },
  { name:'Chemistry', color:'#00C48C', range:[10,19] },
  { name:'Botany',    color:'#A855F7', range:[20,24] },
  { name:'Zoology',   color:'#FF6B9D', range:[25,29] },
]
const TOTAL_SECS = 200 * 60 // 200 minutes

type Status = 'unseen' | 'seen' | 'answered' | 'markedReview' | 'answeredMarked'

export default function ExamAttempt() {
  const router = useRouter()
  const [current, setCurrent]   = useState(0)
  const [answers, setAnswers]   = useState<(number|null)[]>(Array(30).fill(null))
  const [status, setStatus]     = useState<Status[]>(Array(30).fill('unseen'))
  const [timeLeft, setTimeLeft] = useState(TOTAL_SECS)
  const [section, setSection]   = useState(0)
  const [paletteOpen, setPaletteOpen] = useState(false)
  const [confirmSubmit, setConfirmSubmit] = useState(false)
  const [lang, setLang]         = useState<'en'|'hi'>('en')
  const [mounted, setMounted]   = useState(false)
  const intervalRef = useRef<NodeJS.Timeout>()

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    // Mark Q0 as seen
    setStatus(s => { const n=[...s]; n[0]='seen'; return n })
    // Timer
    intervalRef.current = setInterval(() => {
      setTimeLeft(t => {
        if (t <= 1) { clearInterval(intervalRef.current); handleSubmit(); return 0 }
        return t - 1
      })
    }, 1000)
    return () => clearInterval(intervalRef.current)
  }, [])

  const fmt = (s: number) => {
    const h = Math.floor(s/3600), m = Math.floor((s%3600)/60), sec = s%60
    return `${h.toString().padStart(2,'0')}:${m.toString().padStart(2,'0')}:${sec.toString().padStart(2,'0')}`
  }
  const timerColor = timeLeft < 300 ? '#FF4757' : timeLeft < 900 ? '#FFA502' : '#00C48C'

  const goTo = (idx: number) => {
    setCurrent(idx)
    setStatus(s => { const n=[...s]; if(n[idx]==='unseen') n[idx]='seen'; return n })
    setPaletteOpen(false)
  }

  const selectAnswer = (optIdx: number) => {
    setAnswers(a => { const n=[...a]; n[current]=optIdx; return n })
    setStatus(s => { const n=[...s]; n[current]=n[current]==='markedReview'?'answeredMarked':'answered'; return n })
  }

  const clearAnswer = () => {
    setAnswers(a => { const n=[...a]; n[current]=null; return n })
    setStatus(s => { const n=[...s]; n[current]='seen'; return n })
  }

  const markReview = () => {
    setStatus(s => { const n=[...s]; n[current]=answers[current]!==null?'answeredMarked':'markedReview'; return n })
    if (current < 29) goTo(current+1)
  }

  const saveNext = () => {
    if (answers[current] === null) { setStatus(s=>{const n=[...s];n[current]='seen';return n}) }
    if (current < 29) goTo(current+1)
  }

  const handleSubmit = () => {
    clearInterval(intervalRef.current)
    const answered = answers.filter(a=>a!==null).length
    const correct  = answers.filter((a,i)=>a===QUESTIONS[i].correct).length
    const wrong    = answered - correct
    const score    = correct*4 - wrong
    localStorage.setItem('pr_exam_result', JSON.stringify({ score, correct, wrong, skipped:30-answered, total:30, timeUsed:TOTAL_SECS-timeLeft }))
    router.push('/exam/demo/result')
  }

  const statusColor: Record<Status, string> = {
    unseen:        '#1E3A5A',
    seen:          '#FFA502',
    answered:      '#00C48C',
    markedReview:  '#A855F7',
    answeredMarked:'#4D9FFF',
  }
  const statusLabel: Record<Status, string> = {
    unseen: 'Not Visited', seen: 'Not Answered', answered: 'Answered',
    markedReview: 'Marked for Review', answeredMarked: 'Answered & Marked',
  }

  const counts = {
    answered: status.filter(s=>s==='answered'||s==='answeredMarked').length,
    notAnswered: status.filter(s=>s==='seen').length,
    markedReview: status.filter(s=>s==='markedReview'||s==='answeredMarked').length,
    notVisited: status.filter(s=>s==='unseen').length,
  }

  const q = QUESTIONS[current]
  const sec = SECTIONS[section]

  if (!mounted) return <div style={{minHeight:'100vh',background:'#000A18'}}/>

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF',userSelect:'none'}}>
      <style>{`
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes pulse{0%,100%{opacity:1}50%{opacity:.6}}
        * { box-sizing: border-box; }

        /* ── MOBILE palette overlay ── */
        .palette-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:90;backdrop-filter:blur(3px);}
        .palette-drawer{display:none;position:fixed;bottom:0;left:0;right:0;background:#001628;border-top:2px solid rgba(77,159,255,0.3);border-radius:20px 20px 0 0;padding:16px;z-index:91;max-height:65vh;overflow-y:auto;}

        @media(max-width:768px){
          .exam-layout{flex-direction:column!important;}
          .right-panel{display:none!important;}
          .mob-bottom-bar{display:flex!important;}
          .palette-btn{display:flex!important;}
          .q-nav-btns{flex-wrap:wrap!important;gap:6px!important;}
          .q-nav-btns button{flex:1!important;min-width:80px!important;font-size:12px!important;padding:9px 8px!important;}
        }
        @media(min-width:769px){
          .mob-bottom-bar{display:none!important;}
          .palette-btn{display:none!important;}
        }

        .opt-btn{width:100%;text-align:left;padding:14px 18px;border-radius:12px;border:2px solid rgba(77,159,255,0.15);background:rgba(0,22,40,0.6);color:#E8F4FF;cursor:pointer;font-size:14px;font-family:Inter,sans-serif;transition:all 0.2s;display:flex;align-items:flex-start;gap:14px;line-height:1.5;}
        .opt-btn:hover{border-color:rgba(77,159,255,0.4);background:rgba(77,159,255,0.06);}
        .opt-btn.selected{border-color:#4D9FFF;background:rgba(77,159,255,0.15);color:#E8F4FF;}
        .qnum{width:28px;height:28px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;cursor:pointer;flex-shrink:0;transition:all 0.15s;border:1.5px solid transparent;}
        .qnum:hover{transform:scale(1.1);}
        .sec-tab{padding:8px 16px;border-radius:8px;border:none;cursor:pointer;font-weight:600;font-size:12px;font-family:Inter,sans-serif;transition:all 0.2s;}
        .action-btn{padding:11px 18px;border-radius:10px;border:none;font-weight:700;font-size:13px;cursor:pointer;font-family:Inter,sans-serif;transition:all 0.2s;white-space:nowrap;}
        .action-btn:hover{opacity:0.88;transform:translateY(-1px);}
      `}</style>

      {/* ══════════ TOP BAR ══════════ */}
      <header style={{background:'rgba(0,4,14,0.97)',borderBottom:'1px solid rgba(77,159,255,0.18)',padding:'0 16px',height:56,display:'flex',alignItems:'center',justifyContent:'space-between',gap:12,position:'sticky',top:0,zIndex:50,backdropFilter:'blur(20px)'}}>
        {/* Left: logo + exam name */}
        <div style={{display:'flex',alignItems:'center',gap:10,minWidth:0}}>
          <svg width={26} height={26} viewBox="0 0 64 64" style={{flexShrink:0}}>
            <polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/>
            <text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text>
          </svg>
          <div style={{minWidth:0}}>
            <div style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:14,color:'#4D9FFF',whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'}}>NEET Full Mock Test #13</div>
            <div style={{fontSize:10,color:'#5A7A9A',whiteSpace:'nowrap'}}>{lang==='en'?'180 Questions · 720 Marks · NEET 2026':'180 प्रश्न · 720 अंक'}</div>
          </div>
        </div>

        {/* Center: Timer */}
        <div style={{display:'flex',flexDirection:'column',alignItems:'center',flexShrink:0}}>
          <div style={{fontSize:10,color:'#5A7A9A',letterSpacing:'0.08em',textTransform:'uppercase',marginBottom:1}}>{lang==='en'?'TIME LEFT':'समय शेष'}</div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:timerColor,letterSpacing:'0.04em',animation:timeLeft<300?'pulse 1s infinite':'none',fontVariantNumeric:'tabular-nums'}}>
            {fmt(timeLeft)}
          </div>
        </div>

        {/* Right: lang + submit */}
        <div style={{display:'flex',gap:8,alignItems:'center',flexShrink:0}}>
          <button onClick={()=>setLang(l=>l==='en'?'hi':'en')} style={{padding:'5px 12px',borderRadius:20,border:'1.5px solid rgba(77,159,255,0.3)',background:'rgba(77,159,255,0.06)',color:'#6B8BAF',fontSize:11,fontWeight:600,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
            {lang==='en'?'🇮🇳':'🌐'}
          </button>
          <button onClick={()=>setConfirmSubmit(true)} style={{padding:'8px 16px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#FF4757,#CC0020)',color:'#fff',fontWeight:700,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif',boxShadow:'0 2px 12px rgba(255,71,87,0.4)'}}>
            {lang==='en'?'Submit':'सबमिट'}
          </button>
        </div>
      </header>

      {/* ══════════ SECTION TABS ══════════ */}
      <div style={{background:'rgba(0,8,20,0.95)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'8px 16px',display:'flex',gap:8,overflowX:'auto',scrollbarWidth:'none'}}>
        {SECTIONS.map((s,i)=>(
          <button key={i} className="sec-tab" onClick={()=>{setSection(i);goTo(s.range[0])}}
            style={{background:section===i?`${s.color}22`:'transparent',color:section===i?s.color:'#5A7A9A',border:section===i?`1.5px solid ${s.color}55`:'1.5px solid transparent',whiteSpace:'nowrap'}}>
            <span style={{marginRight:4}}>{['⚡','🧪','🌿','🦁'][i]}</span>
            {s.name}
            <span style={{marginLeft:6,background:`${s.color}22`,color:s.color,padding:'1px 7px',borderRadius:99,fontSize:10,fontWeight:700}}>
              {status.filter((st,qi)=>qi>=s.range[0]&&qi<=s.range[1]&&(st==='answered'||st==='answeredMarked')).length}/{s.range[1]-s.range[0]+1}
            </span>
          </button>
        ))}
      </div>

      {/* ══════════ BODY ══════════ */}
      <div className="exam-layout" style={{display:'flex',height:'calc(100vh - 106px)'}}>

        {/* ── LEFT: Question Panel ───────────────────────────── */}
        <div style={{flex:1,overflowY:'auto',padding:'20px 16px 100px',scrollbarWidth:'thin',scrollbarColor:'rgba(77,159,255,0.2) transparent'}}>

          {/* Q header */}
          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16,flexWrap:'wrap',gap:8}}>
            <div style={{display:'flex',alignItems:'center',gap:10}}>
              <div style={{width:36,height:36,borderRadius:10,background:`${sec.color}22`,border:`1.5px solid ${sec.color}44`,display:'flex',alignItems:'center',justifyContent:'center',fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:16,color:sec.color}}>{current+1}</div>
              <div>
                <div style={{fontSize:12,fontWeight:700,color:sec.color}}>{q.subject} — {q.chapter}</div>
                <div style={{fontSize:10,color:'#5A7A9A'}}>{lang==='en'?`Question ${current+1} of 30`:`प्रश्न ${current+1} / 30`} · +4 / -1</div>
              </div>
            </div>
            <div style={{display:'flex',alignItems:'center',gap:6}}>
              <div style={{width:10,height:10,borderRadius:'50%',background:statusColor[status[current]]}}/>
              <span style={{fontSize:11,color:'#5A7A9A'}}>{statusLabel[status[current]]}</span>
            </div>
          </div>

          {/* Question */}
          <div style={{background:'rgba(0,18,38,0.8)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:16,padding:'20px',marginBottom:20,lineHeight:1.8,fontSize:15,color:'#E8F4FF',boxShadow:'inset 0 1px 0 rgba(77,159,255,0.08)'}}>
            {q.text}
          </div>

          {/* Options */}
          <div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:24}}>
            {q.options.map((opt,i)=>(
              <button key={i} className={`opt-btn ${answers[current]===i?'selected':''}`} onClick={()=>selectAnswer(i)}>
                <div style={{width:28,height:28,borderRadius:8,background:answers[current]===i?'#4D9FFF':'rgba(77,159,255,0.1)',border:`1.5px solid ${answers[current]===i?'#4D9FFF':'rgba(77,159,255,0.2)'}`,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:12,color:answers[current]===i?'#fff':'#4D9FFF',flexShrink:0,transition:'all 0.2s'}}>
                  {'ABCD'[i]}
                </div>
                <span>{opt}</span>
              </button>
            ))}
          </div>

          {/* Nav buttons */}
          <div className="q-nav-btns" style={{display:'flex',gap:8,flexWrap:'wrap'}}>
            <button className="action-btn" onClick={clearAnswer} style={{background:'rgba(255,71,87,0.1)',color:'#FF6B7A',border:'1.5px solid rgba(255,71,87,0.25)'}}>
              🗑 {lang==='en'?'Clear':'साफ़'}
            </button>
            <button className="action-btn" onClick={markReview} style={{background:'rgba(168,85,247,0.1)',color:'#A855F7',border:'1.5px solid rgba(168,85,247,0.25)'}}>
              🔖 {lang==='en'?'Mark & Next':'मार्क करें'}
            </button>
            <button className="action-btn palette-btn" onClick={()=>setPaletteOpen(true)} style={{background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1.5px solid rgba(77,159,255,0.25)'}}>
              ◉ {lang==='en'?'Palette':'पैलेट'}
            </button>
            <button className="action-btn" onClick={()=>current>0&&goTo(current-1)} disabled={current===0} style={{background:'rgba(77,159,255,0.06)',color:'#4D9FFF',border:'1.5px solid rgba(77,159,255,0.2)',opacity:current===0?0.4:1}}>
              ← {lang==='en'?'Prev':'पिछला'}
            </button>
            <button className="action-btn" onClick={saveNext} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',boxShadow:'0 3px 12px rgba(77,159,255,0.3)'}}>
              {lang==='en'?'Save & Next':'सेव करें'} →
            </button>
          </div>
        </div>

        {/* ── RIGHT: Question Palette (desktop only) ─────────── */}
        <div className="right-panel" style={{width:280,background:'rgba(0,8,20,0.97)',borderLeft:'1px solid rgba(77,159,255,0.14)',overflowY:'auto',flexShrink:0,scrollbarWidth:'thin',scrollbarColor:'rgba(77,159,255,0.15) transparent'}}>
          <div style={{padding:'16px 14px'}}>

            {/* Student info */}
            <div style={{background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:12,padding:'12px 14px',marginBottom:16,display:'flex',alignItems:'center',gap:10}}>
              <div style={{width:36,height:36,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:14,color:'#fff',flexShrink:0}}>S</div>
              <div>
                <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>Student</div>
                <div style={{fontSize:10,color:'#5A7A9A'}}>NEET 2026 Aspirant</div>
              </div>
            </div>

            {/* Legend */}
            <div style={{marginBottom:14}}>
              {Object.entries(statusLabel).map(([st,label])=>(
                <div key={st} style={{display:'flex',alignItems:'center',gap:8,marginBottom:5}}>
                  <div style={{width:18,height:18,borderRadius:4,background:statusColor[st as Status],flexShrink:0}}/>
                  <span style={{fontSize:11,color:'#5A7A9A'}}>{label}</span>
                  <span style={{marginLeft:'auto',fontWeight:700,fontSize:11,color:'#E8F4FF'}}>
                    {status.filter(s=>s===st).length}
                  </span>
                </div>
              ))}
            </div>

            {/* Summary counts */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6,marginBottom:16}}>
              {[
                {label:lang==='en'?'Answered':'उत्तरित', val:counts.answered, color:'#00C48C'},
                {label:lang==='en'?'Not Ans.':'नहीं',  val:counts.notAnswered, color:'#FFA502'},
                {label:lang==='en'?'Marked':'मार्क',   val:counts.markedReview, color:'#A855F7'},
                {label:lang==='en'?'Unvisited':'बाकी', val:counts.notVisited, color:'#3A5A7A'},
              ].map(c=>(
                <div key={c.label} style={{background:`${c.color}11`,border:`1px solid ${c.color}33`,borderRadius:8,padding:'8px 10px',textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:c.color}}>{c.val}</div>
                  <div style={{fontSize:10,color:'#5A7A9A'}}>{c.label}</div>
                </div>
              ))}
            </div>

            {/* Section palette */}
            {SECTIONS.map((s,si)=>(
              <div key={si} style={{marginBottom:14}}>
                <div style={{fontSize:10,fontWeight:700,color:s.color,letterSpacing:'0.08em',textTransform:'uppercase',marginBottom:8,display:'flex',justifyContent:'space-between'}}>
                  <span>{s.name}</span>
                  <span style={{color:'#5A7A9A'}}>{status.filter((st,qi)=>qi>=s.range[0]&&qi<=s.range[1]&&(st==='answered'||st==='answeredMarked')).length}/{s.range[1]-s.range[0]+1}</span>
                </div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:4}}>
                  {QUESTIONS.slice(s.range[0],s.range[1]+1).map((q2,qi)=>{
                    const absIdx = s.range[0]+qi
                    return (
                      <div key={qi} className="qnum" onClick={()=>goTo(absIdx)}
                        style={{background:statusColor[status[absIdx]],color:'#fff',borderColor:current===absIdx?'#fff':'transparent',boxShadow:current===absIdx?`0 0 0 2px ${s.color}`:'none',fontSize:11}}>
                        {absIdx+1}
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}

            {/* Submit */}
            <button onClick={()=>setConfirmSubmit(true)} style={{width:'100%',padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#FF4757,#CC0020)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',boxShadow:'0 4px 20px rgba(255,71,87,0.35)',marginTop:8}}>
              🚀 {lang==='en'?'Submit Exam':'परीक्षा जमा करें'}
            </button>
          </div>
        </div>
      </div>

      {/* ══ MOBILE BOTTOM BAR ══ */}
      <div className="mob-bottom-bar" style={{display:'none',position:'fixed',bottom:0,left:0,right:0,background:'rgba(0,4,14,0.97)',borderTop:'1px solid rgba(77,159,255,0.2)',padding:'10px 14px',gap:8,zIndex:80,alignItems:'center'}}>
        <div style={{display:'flex',alignItems:'center',gap:6,flex:1,minWidth:0}}>
          <div style={{width:10,height:10,borderRadius:'50%',background:statusColor[status[current]],flexShrink:0}}/>
          <span style={{fontSize:11,color:'#5A7A9A',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{counts.answered}/30 {lang==='en'?'answered':'उत्तरित'}</span>
        </div>
        <button onClick={()=>setPaletteOpen(true)} style={{padding:'9px 14px',borderRadius:10,border:'1.5px solid rgba(77,159,255,0.3)',background:'rgba(77,159,255,0.08)',color:'#4D9FFF',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>
          ◉ {lang==='en'?'Q-Grid':'प्रश्न'}
        </button>
        <button onClick={()=>setConfirmSubmit(true)} style={{padding:'9px 16px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#FF4757,#CC0020)',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>
          🚀 {lang==='en'?'Submit':'जमा'}
        </button>
      </div>

      {/* ══ MOBILE PALETTE DRAWER ══ */}
      {paletteOpen && (
        <>
          <div className="palette-overlay" style={{display:'block'}} onClick={()=>setPaletteOpen(false)}/>
          <div className="palette-drawer" style={{display:'block'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:12}}>
              <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:'#E8F4FF'}}>{lang==='en'?'Question Grid':'प्रश्न ग्रिड'}</div>
              <button onClick={()=>setPaletteOpen(false)} style={{background:'none',border:'none',color:'#5A7A9A',fontSize:22,cursor:'pointer'}}>✕</button>
            </div>
            {/* Mini legend */}
            <div style={{display:'flex',gap:10,flexWrap:'wrap',marginBottom:12}}>
              {[['#00C48C',lang==='en'?'Answered':'उत्तरित'],['#FFA502',lang==='en'?'Seen':'देखा'],['#A855F7',lang==='en'?'Marked':'मार्क'],['#1E3A5A',lang==='en'?'Unvisited':'बाकी']].map(([c,l])=>(
                <div key={l} style={{display:'flex',alignItems:'center',gap:4}}>
                  <div style={{width:10,height:10,borderRadius:3,background:String(c)}}/>
                  <span style={{fontSize:10,color:'#5A7A9A'}}>{l}</span>
                </div>
              ))}
            </div>
            {/* Counts */}
            <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:6,marginBottom:14}}>
              {[{label:lang==='en'?'Ans':'उत्तरित',val:counts.answered,c:'#00C48C'},{label:lang==='en'?'Seen':'देखा',val:counts.notAnswered,c:'#FFA502'},{label:lang==='en'?'Marked':'मार्क',val:counts.markedReview,c:'#A855F7'},{label:lang==='en'?'Left':'बाकी',val:counts.notVisited,c:'#3A5A7A'}].map(c=>(
                <div key={c.label} style={{background:`${c.c}15`,border:`1px solid ${c.c}33`,borderRadius:8,padding:'6px',textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:800,color:c.c}}>{c.val}</div>
                  <div style={{fontSize:9,color:'#5A7A9A'}}>{c.label}</div>
                </div>
              ))}
            </div>
            {/* Full grid */}
            {SECTIONS.map((s,si)=>(
              <div key={si} style={{marginBottom:14}}>
                <div style={{fontSize:10,fontWeight:700,color:s.color,letterSpacing:'0.08em',textTransform:'uppercase',marginBottom:8}}>{s.name}</div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(6,1fr)',gap:5}}>
                  {QUESTIONS.slice(s.range[0],s.range[1]+1).map((_,qi)=>{
                    const absIdx=s.range[0]+qi
                    return (
                      <div key={qi} className="qnum" onClick={()=>goTo(absIdx)}
                        style={{background:statusColor[status[absIdx]],color:'#fff',borderColor:current===absIdx?'#fff':'transparent',boxShadow:current===absIdx?`0 0 0 2px ${s.color}`:'none',width:'100%',aspectRatio:'1',fontSize:11}}>
                        {absIdx+1}
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* ══ SUBMIT CONFIRM MODAL ══ */}
      {confirmSubmit && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:200,backdropFilter:'blur(6px)',padding:16}}>
          <div style={{background:'#001628',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:28,width:'100%',maxWidth:400,animation:'fadeIn 0.25s ease'}}>
            <div style={{textAlign:'center',marginBottom:20}}>
              <div style={{fontSize:42,marginBottom:10}}>⚠️</div>
              <h2 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:800,color:'#E8F4FF',marginBottom:8}}>{lang==='en'?'Submit Exam?':'परीक्षा सबमिट करें?'}</h2>
              <p style={{color:'#6B8BAF',fontSize:13,lineHeight:1.7}}>
                {lang==='en'?'Once submitted, you cannot go back.':'एक बार सबमिट करने के बाद वापस नहीं जा सकते।'}
              </p>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(2,1fr)',gap:12,marginBottom:20}}>
              {[
                {label:lang==='en'?'Answered':'उत्तरित',   val:counts.answered,    color:'#00C48C'},
                {label:lang==='en'?'Not Answered':'बिना उत्तर',val:counts.notAnswered,color:'#FFA502'},
                {label:lang==='en'?'Marked':'मार्क',        val:counts.markedReview,color:'#A855F7'},
                {label:lang==='en'?'Not Visited':'बाकी',    val:counts.notVisited,  color:'#3A5A7A'},
              ].map(c=>(
                <div key={c.label} style={{background:`${c.color}11`,border:`1px solid ${c.color}33`,borderRadius:10,padding:'10px 14px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                  <span style={{fontSize:12,color:'#6B8BAF'}}>{c.label}</span>
                  <span style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:800,color:c.color}}>{c.val}</span>
                </div>
              ))}
            </div>
            <div style={{fontSize:12,color:'#5A7A9A',textAlign:'center',marginBottom:20}}>
              ⏱ {lang==='en'?'Time remaining:':'समय शेष:'} <strong style={{color:timerColor}}>{fmt(timeLeft)}</strong>
            </div>
            <div style={{display:'flex',gap:10}}>
              <button onClick={()=>setConfirmSubmit(false)} style={{flex:1,padding:'13px',borderRadius:12,border:'1px solid rgba(77,159,255,0.3)',background:'transparent',color:'#4D9FFF',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
                {lang==='en'?'← Go Back':'← वापस'}
              </button>
              <button onClick={handleSubmit} style={{flex:1,padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#FF4757,#CC0020)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',boxShadow:'0 4px 16px rgba(255,71,87,0.4)'}}>
                {lang==='en'?'Submit Now 🚀':'जमा करें 🚀'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
EXAMEOF
log "Exam attempt page ✓"

# Result page for demo exam
mkdir -p $FE/app/exam/demo/result
cat > $FE/app/exam/demo/result/page.tsx << 'RESEOF'
'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function ExamResult() {
  const router = useRouter()
  const [result, setResult] = useState<any>(null)
  const [lang, setLang]     = useState<'en'|'hi'>('en')
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    const raw = localStorage.getItem('pr_exam_result')
    if (raw) setResult(JSON.parse(raw))
    else setResult({ score:610, correct:152, wrong:18, skipped:10, total:180, timeUsed:9540 })
  }, [])

  if (!mounted || !result) return <div style={{minHeight:'100vh',background:'#000A18'}}/>

  const pct = Math.round((result.correct/result.total)*100)
  const grade = result.score >= 600 ? 'A+' : result.score >= 500 ? 'A' : result.score >= 400 ? 'B' : 'C'
  const gradeColor = result.score >= 600 ? '#00C48C' : result.score >= 500 ? '#4D9FFF' : result.score >= 400 ? '#FFA502' : '#FF4757'
  const timeUsedMin = Math.floor(result.timeUsed/60)

  return (
    <div style={{minHeight:'100vh',background:'#000A18',fontFamily:'Inter,sans-serif',color:'#E8F4FF',padding:'0 0 40px'}}>
      <style>{`
        @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
        @keyframes scaleIn{from{opacity:0;transform:scale(0.85)}to{opacity:1;transform:scale(1)}}
        * { box-sizing: border-box; }
        @media(max-width:600px){
          .res-grid{grid-template-columns:repeat(2,1fr)!important;}
          .res-body{padding:16px!important;}
          .score-num{font-size:clamp(2.5rem,12vw,5rem)!important;}
          .share-row{flex-direction:column!important;}
          .share-row button{width:100%!important;}
        }
      `}</style>

      {/* Header */}
      <div style={{background:'rgba(0,4,14,0.97)',borderBottom:'1px solid rgba(77,159,255,0.15)',padding:'14px 20px',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,zIndex:50}}>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_,i)=>{const a=(Math.PI/180)*(60*i-30);return`${32+26*Math.cos(a)},${32+26*Math.sin(a)}`}).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2"/><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
          <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:800,color:'#4D9FFF'}}>Result</span>
        </div>
        <div style={{display:'flex',gap:8}}>
          <Link href="/dashboard/analytics" style={{padding:'7px 14px',borderRadius:10,border:'1px solid rgba(77,159,255,0.3)',background:'transparent',color:'#4D9FFF',fontSize:12,fontWeight:600,textDecoration:'none'}}>📊 {lang==='en'?'Analytics':'विश्लेषण'}</Link>
          <Link href="/dashboard" style={{padding:'7px 14px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontSize:12,fontWeight:700,textDecoration:'none'}}>🏠 {lang==='en'?'Dashboard':'डैशबोर्ड'}</Link>
        </div>
      </div>

      <div className="res-body" style={{maxWidth:700,margin:'0 auto',padding:'28px 16px',animation:'fadeUp 0.5s ease forwards'}}>

        {/* Score Hero */}
        <div style={{background:'linear-gradient(135deg,rgba(0,40,100,0.6),rgba(0,22,55,0.6))',border:'2px solid rgba(77,159,255,0.3)',borderRadius:24,padding:'32px 24px',textAlign:'center',marginBottom:20,position:'relative',overflow:'hidden',animation:'scaleIn 0.4s ease forwards'}}>
          <div style={{position:'absolute',top:-20,right:-20,fontSize:150,opacity:.04,color:'#4D9FFF',fontFamily:'monospace',pointerEvents:'none'}}>⬡</div>
          <div style={{fontSize:12,letterSpacing:'0.15em',textTransform:'uppercase',color:'#4D9FFF',fontWeight:700,marginBottom:8}}>NEET FULL MOCK TEST #13</div>
          <div className="score-num" style={{fontFamily:'Playfair Display,serif',fontSize:'clamp(3rem,12vw,5.5rem)',fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#FFFFFF,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1,marginBottom:4}}>
            {result.score}
          </div>
          <div style={{fontSize:16,color:'#6B8BAF',marginBottom:16}}>/ 720</div>
          <div style={{display:'inline-flex',gap:20,flexWrap:'wrap',justifyContent:'center'}}>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#FFD700'}}>#234</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'AIR Rank':'AIR रैंक'}</div>
            </div>
            <div style={{width:1,background:'rgba(77,159,255,0.2)'}}/>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:'#00C48C'}}>96.8%</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'Percentile':'प्रतिशतक'}</div>
            </div>
            <div style={{width:1,background:'rgba(77,159,255,0.2)'}}/>
            <div style={{textAlign:'center'}}>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:28,fontWeight:800,color:gradeColor}}>{grade}</div>
              <div style={{fontSize:10,color:'#6B8BAF',textTransform:'uppercase',letterSpacing:'0.08em'}}>{lang==='en'?'Grade':'ग्रेड'}</div>
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="res-grid" style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:20}}>
          {[
            {label:lang==='en'?'Correct':'सही',   val:result.correct, color:'#00C48C', icon:'✓'},
            {label:lang==='en'?'Wrong':'गलत',     val:result.wrong,   color:'#FF4757', icon:'✗'},
            {label:lang==='en'?'Skipped':'छोड़े',  val:result.skipped, color:'#FFA502', icon:'—'},
            {label:lang==='en'?'Accuracy':'सटीकता',val:`${pct}%`,    color:'#4D9FFF', icon:'🎯'},
          ].map((s,i)=>(
            <div key={i} style={{background:`${s.color}10`,border:`1px solid ${s.color}33`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
              <div style={{fontSize:20,marginBottom:4}}>{s.icon}</div>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:s.color}}>{s.val}</div>
              <div style={{fontSize:11,color:'#6B8BAF'}}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Time used */}
        <div style={{background:'rgba(0,18,36,0.8)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:14,padding:'14px 18px',marginBottom:20,display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:10}}>
          <span style={{color:'#6B8BAF',fontSize:13}}>⏱ {lang==='en'?'Time Used':'समय लगा'}</span>
          <span style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:16,color:'#E8F4FF'}}>{timeUsedMin} {lang==='en'?`min (${200-Math.floor((200*60-result.timeUsed)/60)} min remaining)`:`मिनट`}</span>
        </div>

        {/* Subject breakdown */}
        <div style={{background:'rgba(0,18,36,0.8)',border:'1px solid rgba(77,159,255,0.14)',borderRadius:16,padding:'18px',marginBottom:20}}>
          <h3 style={{fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,marginBottom:16,color:'#E8F4FF'}}>🧪 {lang==='en'?'Subject-wise Score':'विषय-वार स्कोर'}</h3>
          {[
            {sub:lang==='en'?'Physics':'भौतिकी',       score:148,max:180,color:'#4D9FFF'},
            {sub:lang==='en'?'Chemistry':'रसायन',      score:152,max:180,color:'#00C48C'},
            {sub:lang==='en'?'Botany':'वनस्पति विज्ञान',score:152,max:180,color:'#A855F7'},
            {sub:lang==='en'?'Zoology':'प्राणी विज्ञान',score:158,max:180,color:'#FF6B9D'},
          ].map((s,i)=>(
            <div key={i} style={{marginBottom:14}}>
              <div style={{display:'flex',justifyContent:'space-between',marginBottom:6}}>
                <span style={{fontWeight:600,fontSize:13,color:'#E8F4FF'}}>{s.sub}</span>
                <span style={{fontFamily:'Playfair Display,serif',fontWeight:800,fontSize:14,color:s.color}}>{s.score}<span style={{fontSize:11,color:'#5A7A9A'}}>/{s.max}</span></span>
              </div>
              <div style={{background:'rgba(77,159,255,0.08)',borderRadius:99,height:8,overflow:'hidden'}}>
                <div style={{height:'100%',width:`${(s.score/s.max)*100}%`,background:`linear-gradient(90deg,${s.color}77,${s.color})`,borderRadius:99,boxShadow:`0 0 8px ${s.color}44`}}/>
              </div>
            </div>
          ))}
        </div>

        {/* Action buttons */}
        <div className="share-row" style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          <button onClick={()=>router.push('/exam/demo/attempt')} style={{flex:1,padding:'13px',borderRadius:12,border:'1.5px solid rgba(77,159,255,0.3)',background:'transparent',color:'#4D9FFF',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif',minWidth:120}}>
            🔄 {lang==='en'?'Reattempt':'दोबारा दें'}
          </button>
          <Link href="/dashboard/analytics" style={{flex:1,minWidth:120}}>
            <button style={{width:'100%',padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#00C48C,#007A5C)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              📊 {lang==='en'?'Full Analysis':'विश्लेषण'}
            </button>
          </Link>
          <Link href="/dashboard" style={{flex:1,minWidth:120}}>
            <button style={{width:'100%',padding:'13px',borderRadius:12,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
              🏠 {lang==='en'?'Dashboard':'डैशबोर्ड'}
            </button>
          </Link>
        </div>
      </div>
    </div>
  )
}
RESEOF
log "Result page ✓"

step "GIT PUSH"
cd $FE
git add -A
git commit -m "Add: Live Exam Attempt page (30 NEET Qs, timer, palette, mobile) + Result page"
git push origin main

echo ""
echo -e "${G}╔═════════════════════════════════════════════════════════╗"
echo -e "║  ✅ LIVE EXAM PAGE PUSHED!                              ║"
echo -e "║                                                         ║"
echo -e "║  🔗 Try it: /exam/demo/attempt                         ║"
echo -e "║                                                         ║"
echo -e "║  ✓ 30 real NEET questions (Phy+Chem+Bio)               ║"
echo -e "║  ✓ 200 min countdown timer (auto-submit)               ║"
echo -e "║  ✓ Section tabs: Physics/Chemistry/Botany/Zoology      ║"
echo -e "║  ✓ OMR-style options (A B C D bubble)                  ║"
echo -e "║  ✓ Question palette — color coded status               ║"
echo -e "║  ✓ Save & Next / Mark for Review / Clear               ║"
echo -e "║  ✓ Submit modal with full summary                      ║"
echo -e "║  ✓ Mobile: bottom bar + sliding palette drawer         ║"
echo -e "║  ✓ Result page with AIR rank, score, subject breakdown ║"
echo -e "║  ✓ EN/HI language toggle                               ║"
echo -e "╚═════════════════════════════════════════════════════════╝${N}"
