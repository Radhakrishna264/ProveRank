'use client'
import { useState, useEffect, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; examType: string; price: number; discountPrice: number;
  isFree: boolean; totalTests: number; validity: number; rating: number;
  enrolledCount: number; batchType: string; language: string; difficulty: string;
  allowFreeTrial: boolean; syllabus?: string; subject?: string;
}

const ROWS = [
  { key:'price',      label:'Price',           fmt:(b:Batch)=>b.isFree?'Free':`₹${b.discountPrice||b.price}`, better:'lower' },
  { key:'totalTests', label:'Total Tests',      fmt:(b:Batch)=>`${b.totalTests}`,                               better:'higher' },
  { key:'validity',   label:'Validity',         fmt:(b:Batch)=>`${b.validity} days`,                            better:'higher' },
  { key:'rating',     label:'Rating',           fmt:(b:Batch)=>`⭐ ${b.rating}/5`,                              better:'higher' },
  { key:'enrolled',   label:'Enrolled Students',fmt:(b:Batch)=>b.enrolledCount.toLocaleString(),                better:'higher' },
  { key:'type',       label:'Batch Type',       fmt:(b:Batch)=>b.batchType,                                     better:'none' },
  { key:'language',   label:'Language',         fmt:(b:Batch)=>b.language,                                      better:'none' },
  { key:'difficulty', label:'Difficulty',       fmt:(b:Batch)=>b.difficulty,                                    better:'none' },
  { key:'free',       label:'Free Available',   fmt:(b:Batch)=>b.isFree?'✅ Yes':'❌ No',                       better:'none' },
  { key:'trial',      label:'Free Trial',       fmt:(b:Batch)=>b.allowFreeTrial?'✅ Yes':'❌ No',               better:'none' },
]

const ECOLS: Record<string,string> = {
  NEET:'#4D9FFF',JEE:'#9B59B6',CUET:'#27AE60','Class 11':'#E67E22','Class 12':'#E74C3C',
  Foundation:'#00D4FF','Crash Course':'#FF6B6B',Other:'#7F8C8D'
}

function getNumVal(b: Batch, key: string): number {
  if (key==='price')    return b.isFree?0:(b.discountPrice||b.price)
  if (key==='totalTests') return b.totalTests
  if (key==='validity') return b.validity
  if (key==='rating')   return b.rating
  if (key==='enrolled') return b.enrolledCount
  return 0
}

function getBestIdx(batches: Batch[], row: typeof ROWS[0]): number {
  if (row.better==='none') return -1
  const vals = batches.map(b => getNumVal(b, row.key))
  if (vals.every(v=>v===vals[0])) return -1
  const best = row.better==='lower' ? Math.min(...vals) : Math.max(...vals)
  return vals.indexOf(best)
}

function getPct(batches: Batch[], row: typeof ROWS[0], idx: number): string {
  if (row.better==='none') return ''
  const vals = batches.map(b => getNumVal(b, row.key))
  const bestIdx = getBestIdx(batches, row)
  if (bestIdx===-1) return ''
  const bestVal = vals[bestIdx]
  const myVal = vals[idx]
  if (myVal===0&&bestVal===0) return ''
  if (idx===bestIdx) {
    const others = vals.filter((_,i)=>i!==idx)
    const worstOther = row.better==='lower' ? Math.max(...others) : Math.min(...others)
    if (worstOther===0) return ''
    const pct = Math.abs(Math.round(((worstOther-myVal)/worstOther)*100))
    return pct>0 ? `+${pct}% better` : ''
  } else {
    if (bestVal===0) return ''
    const pct = Math.abs(Math.round(((myVal-bestVal)/bestVal)*100))
    return pct>0 ? `-${pct}% lower` : ''
  }
}

function getBestValueBatch(batches: Batch[]): number {
  const scores = batches.map(b => {
    let s = 0
    if (b.isFree) s += 50
    else { const p=b.discountPrice||b.price; s += p>0?Math.round(1000/p):0 }
    s += b.totalTests * 0.5
    s += b.rating * 10
    return s
  })
  return scores.indexOf(Math.max(...scores))
}

export default function PublicComparePage() {
  return (
    <Suspense fallback={<div style={{minHeight:'100vh',background:'#020816',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontSize:14}}>Loading...</div>}>
      <PublicCompareInner />
    </Suspense>
  )
}

function PublicCompareInner() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [batches, setBatches] = useState<Batch[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    const ids = searchParams.get('ids')?.split(',').filter(Boolean) || []
    if (ids.length < 2) { setError('Need at least 2 batch IDs in URL (?ids=x,y)'); setLoading(false); return }
    fetch(`${API}/api/student/batches`)
      .then(r=>r.json())
      .then(d => {
        const all = d.batches || []
        const filtered = all.filter((b:Batch) => ids.includes(b._id)).slice(0,3)
        if (filtered.length < 2) setError('Batches not found or unavailable')
        setBatches(filtered)
      })
      .catch(()=>setError('Could not load batch data'))
      .finally(()=>setLoading(false))
  }, [])

  const bestValueIdx = batches.length >= 2 ? getBestValueBatch(batches) : -1

  const copyLink = () => {
    navigator.clipboard.writeText(window.location.href)
    setCopied(true); setTimeout(()=>setCopied(false),2500)
  }

  if (loading) return (
    <div style={{minHeight:'100vh',background:'#020816',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>
      <div style={{textAlign:'center'}}>
        <div style={{fontSize:40,marginBottom:16}}>⚖️</div>
        <div style={{fontSize:14}}>Loading comparison...</div>
      </div>
    </div>
  )

  if (error) return (
    <div style={{minHeight:'100vh',background:'#020816',display:'flex',alignItems:'center',justifyContent:'center',color:'#F0F8FF',fontFamily:'Inter,sans-serif'}}>
      <div style={{textAlign:'center',padding:24}}>
        <div style={{fontSize:48,marginBottom:16}}>⚠️</div>
        <div style={{fontSize:16,fontWeight:700,marginBottom:8}}>Invalid Comparison Link</div>
        <div style={{fontSize:12,color:'rgba(160,200,240,0.5)',marginBottom:24}}>{error}</div>
        <button onClick={()=>router.push('/dashboard/test-series')}
          style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'12px 28px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13}}>
          Browse Batches →
        </button>
      </div>
    </div>
  )

  return (
    <div style={{minHeight:'100vh',background:'#020816',color:'#F0F8FF',fontFamily:'Inter,sans-serif',padding:'0 0 60px'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700;800&display=swap');
        *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px}
        @keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
      `}</style>

      {/* HEADER */}
      <div style={{background:'rgba(2,8,22,0.98)',backdropFilter:'blur(20px)',borderBottom:'1px solid rgba(77,159,255,0.1)',padding:'14px 20px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:10}}>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>⚖️ Batch Comparison</div>
          <div style={{fontSize:11,color:'rgba(160,200,240,0.45)',marginTop:2}}>ProveRank — Public View · No login required</div>
        </div>
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          <button onClick={copyLink}
            style={{padding:'8px 14px',background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:10,color:copied?'#27AE60':'#4D9FFF',cursor:'pointer',fontSize:11,fontWeight:700}}>
            {copied?'✅ Copied!':'🔗 Copy Link'}
          </button>
          <button onClick={()=>router.push('/dashboard/test-series')}
            style={{padding:'8px 14px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:10,color:'#fff',cursor:'pointer',fontSize:11,fontWeight:700}}>
            Explore All Batches →
          </button>
        </div>
      </div>

      <div style={{maxWidth:900,margin:'0 auto',padding:'20px 16px'}}>

        {/* Guest notice */}
        <div style={{background:'rgba(255,215,0,0.06)',border:'1px solid rgba(255,215,0,0.18)',borderRadius:14,padding:'12px 16px',marginBottom:20,display:'flex',gap:10,alignItems:'center'}}>
          <span style={{fontSize:18}}>👀</span>
          <div>
            <div style={{fontSize:12,fontWeight:700,color:'#FFD700'}}>Public Comparison View</div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.55)'}}>You are viewing a shared comparison. Login to enroll in any batch.</div>
          </div>
          <button onClick={()=>router.push('/auth/login')}
            style={{marginLeft:'auto',padding:'7px 14px',background:'rgba(255,215,0,0.12)',border:'1px solid rgba(255,215,0,0.25)',borderRadius:10,color:'#FFD700',cursor:'pointer',fontSize:11,fontWeight:700,flexShrink:0}}>
            Login / Sign Up
          </button>
        </div>

        {/* Batch headers */}
        <div style={{display:'grid',gridTemplateColumns:`repeat(${batches.length},1fr)`,gap:12,marginBottom:20}}>
          {batches.map((b,i)=>{
            const ec=ECOLS[b.examType]||'#4D9FFF'
            const isBest=i===bestValueIdx
            return (
              <div key={b._id} style={{background:'rgba(4,12,30,0.95)',border:`2px solid ${isBest?'rgba(255,215,0,0.5)':ec+'25'}`,borderRadius:18,padding:'18px 14px',textAlign:'center',backdropFilter:'blur(16px)',position:'relative',animation:`slideUp ${0.2+i*0.1}s ease`}}>
                {isBest&&<div style={{position:'absolute',top:-10,left:'50%',transform:'translateX(-50%)',background:'linear-gradient(135deg,#FFD700,#FFA000)',color:'#000',fontSize:9,fontWeight:900,padding:'3px 12px',borderRadius:20,whiteSpace:'nowrap'}}>✨ BEST VALUE</div>}
                <div style={{width:48,height:48,borderRadius:14,background:`${ec}18`,border:`1px solid ${ec}28`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:24,margin:'0 auto 10px'}}>
                  {b.examType==='NEET'?'🩺':b.examType==='JEE'?'⚙️':b.examType==='CUET'?'📖':'📚'}
                </div>
                <div style={{fontSize:13,fontWeight:700,color:'#F0F8FF',fontFamily:'Playfair Display,serif',marginBottom:6,lineHeight:1.3}}>{b.name}</div>
                <span style={{fontSize:9,background:`${ec}16`,color:ec,padding:'2px 8px',borderRadius:20,fontWeight:700,border:`1px solid ${ec}25`}}>{b.examType}</span>
                <div style={{marginTop:14}}>
                  <div style={{fontSize:22,fontWeight:900,color:b.isFree?'#27AE60':'#F0F8FF',fontFamily:'Playfair Display,serif'}}>{b.isFree?'FREE':`₹${b.discountPrice||b.price}`}</div>
                </div>
                <button onClick={()=>router.push('/auth/login')}
                  style={{width:'100%',marginTop:12,padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11}}>
                  {b.isFree?'🚀 Enroll Free':'🛒 Login to Enroll'}
                </button>
              </div>
            )
          })}
        </div>

        {/* Comparison Table */}
        <div style={{background:'rgba(4,12,30,0.95)',border:'1px solid rgba(77,159,255,0.12)',borderRadius:20,overflow:'hidden',backdropFilter:'blur(16px)'}}>
          {ROWS.map((row,ri)=>(
            <div key={row.key} style={{display:'grid',gridTemplateColumns:`140px repeat(${batches.length},1fr)`,borderBottom:'1px solid rgba(77,159,255,0.06)',background:ri%2===0?'transparent':'rgba(77,159,255,0.02)'}}>
              <div style={{padding:'13px 16px',display:'flex',alignItems:'center',borderRight:'1px solid rgba(77,159,255,0.08)'}}>
                <span style={{fontSize:11,fontWeight:700,color:'rgba(160,200,240,0.55)',textTransform:'uppercase',letterSpacing:0.6}}>{row.label}</span>
              </div>
              {batches.map((b,bi)=>{
                const bestIdx=getBestIdx(batches,row)
                const isBest=bestIdx===bi
                const isWorst=row.better!=='none'&&bestIdx!==-1&&bi!==bestIdx&&batches.length>2?getBestIdx(batches,row)!==bi:false
                const pctText=getPct(batches,row,bi)
                return (
                  <div key={b._id} style={{padding:'13px 12px',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',textAlign:'center',background:isBest?'rgba(39,174,96,0.08)':isWorst?'rgba(231,76,60,0.04)':'transparent',borderRight:'1px solid rgba(77,159,255,0.06)',position:'relative',transition:'background 0.3s'}}>
                    {isBest&&row.better!=='none'&&<div style={{position:'absolute',top:3,right:3,background:'rgba(39,174,96,0.2)',color:'#27AE60',fontSize:7,fontWeight:800,padding:'1px 5px',borderRadius:8}}>BEST</div>}
                    <span style={{fontSize:12,fontWeight:isBest?700:400,color:isBest?'#27AE60':isWorst?'rgba(231,76,60,0.6)':'rgba(200,220,240,0.75)',opacity:isWorst?0.6:1}}>{row.fmt(b)}</span>
                    {pctText&&<span style={{fontSize:9,marginTop:3,color:isBest?'#27AE60':'rgba(231,76,60,0.7)',fontWeight:700}}>{pctText}</span>}
                  </div>
                )
              })}
            </div>
          ))}
        </div>

        {/* Footer CTA */}
        <div style={{textAlign:'center',marginTop:32,padding:'20px',background:'rgba(4,12,30,0.8)',border:'1px solid rgba(77,159,255,0.1)',borderRadius:18,backdropFilter:'blur(16px)'}}>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#F0F8FF',marginBottom:8}}>Ready to Enroll?</div>
          <div style={{fontSize:12,color:'rgba(160,200,240,0.5)',marginBottom:18}}>Create a free account and enroll in any batch in under 2 minutes.</div>
          <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
            <button onClick={()=>router.push('/auth/login')}
              style={{padding:'12px 28px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:14,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.3)'}}>
              Login / Sign Up Free →
            </button>
            <button onClick={()=>router.push('/dashboard/test-series')}
              style={{padding:'12px 20px',background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:14,color:'#4D9FFF',fontWeight:700,cursor:'pointer',fontSize:13}}>
              Browse All Batches
            </button>
          </div>
        </div>

      </div>
    </div>
  )
}
