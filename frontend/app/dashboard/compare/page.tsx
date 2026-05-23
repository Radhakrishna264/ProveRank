'use client'
import{useState,useEffect}from'react'
import{useRouter}from'next/navigation'

const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com'

export default function ComparePerformancePage(){
  const router=useRouter()
  const[data,setData]=useState<{examTitle:string;myScore:number;maxScore:number;topperScore:number;avgScore:number;subjects:{name:string;my:number;topper:number;avg:number}[]}[]>([])
  const[loading,setLoading]=useState(true)
  const[tok,setTok]=useState('')

  useEffect(()=>{
    const t=localStorage.getItem('pr_token')||'';setTok(t)
    if(t)fetchData(t)
    else setLoading(false)
  },[])

  const fetchData=async(t:string)=>{
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/results/compare`,{headers:{Authorization:`Bearer ${t}`}})
      const d=await r.json()
      setData(d.comparisons||[])
    }catch{setData([])}finally{setLoading(false)}
  }

  return(
    <div style={{minHeight:'100vh',color:'#F0F8FF',fontFamily:'Inter,sans-serif',background:'transparent',position:'relative'}}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes slideUp{from{opacity:0;transform:translateY(22px)}to{opacity:1;transform:translateY(0)}}
        *{box-sizing:border-box}
      `}</style>

      <div style={{position:'sticky',top:0,zIndex:50,background:'rgba(2,8,22,0.94)',backdropFilter:'blur(22px)',borderBottom:'1px solid rgba(77,159,255,0.15)',padding:'10px 14px',display:'flex',alignItems:'center',gap:10}}>
        <button onClick={()=>router.back()} style={{background:'rgba(77,159,255,0.1)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:10,width:36,height:36,display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',color:'#4D9FFF',fontSize:20,flexShrink:0}}
          onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.2)')}
          onMouseLeave={e=>(e.currentTarget.style.background='rgba(77,159,255,0.1)')}>←</button>
        <div>
          <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#4D9FFF'}}>⚖️ Compare Performance</div>
          <div style={{fontSize:10,color:'rgba(160,200,240,0.45)'}}>Your score vs topper vs class average — subject wise</div>
        </div>
        <div style={{flex:1}}/>
        <button onClick={()=>router.push('/dashboard/batch-compare')} style={{background:'linear-gradient(135deg,#9B59B6,#7D3C98)',border:'none',borderRadius:10,padding:'8px 14px',color:'#fff',fontSize:11,fontWeight:700,cursor:'pointer'}}>
          ⚖️ Compare Batches →
        </button>
      </div>

      <div style={{maxWidth:900,margin:'0 auto',padding:'16px 14px 80px',position:'relative',zIndex:2}}>

        {/* Motivation quote */}
        <div style={{background:'rgba(4,12,30,0.9)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:16,padding:'14px 18px',marginBottom:18,display:'flex',gap:12,alignItems:'center',animation:'slideUp 0.4s ease',backdropFilter:'blur(16px)'}}>
          <span style={{fontSize:28,flexShrink:0}}>📊</span>
          <div>
            <div style={{fontSize:13,fontStyle:'italic',color:'rgba(200,220,240,0.85)',fontFamily:'Playfair Display,serif',marginBottom:4}}>"Know your competition — aim higher every day."</div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.5)'}}>Give exams to see comparisons</div>
          </div>
        </div>

        {loading?(
          <div style={{textAlign:'center',padding:'40px',color:'rgba(160,200,240,0.6)'}}>
            <div style={{fontSize:32,marginBottom:12,animation:'spin 1s linear infinite',display:'inline-block'}}>⏳</div>
            <div>Loading comparison data...</div>
          </div>
        ):!tok?(
          <div style={{background:'rgba(4,12,30,0.92)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:18,padding:'40px 20px',textAlign:'center',backdropFilter:'blur(16px)'}}>
            <div style={{fontSize:52,marginBottom:14}}>🔐</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#F0F8FF',marginBottom:8}}>Login Required</div>
            <div style={{fontSize:13,color:'rgba(160,200,240,0.6)',marginBottom:20}}>Please login to view your performance comparisons</div>
            <button onClick={()=>router.push('/login')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'12px 28px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13}}>Login →</button>
          </div>
        ):data.length===0?(
          <div style={{background:'rgba(4,12,30,0.92)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:18,padding:'48px 20px',textAlign:'center',backdropFilter:'blur(16px)',animation:'slideUp 0.5s ease'}}>
            <div style={{fontSize:60,marginBottom:16}}>⚖️</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#F0F8FF',marginBottom:8}}>No comparison data yet!</div>
            <div style={{fontSize:13,color:'rgba(160,200,240,0.6)',maxWidth:340,margin:'0 auto 24px',lineHeight:1.75}}>Give your first exam to compare your performance with toppers and class average.</div>
            <button onClick={()=>router.push('/dashboard/exams')} style={{background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:12,padding:'12px 28px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.35)'}}>📝 Give First Exam →</button>
          </div>
        ):(
          <div style={{display:'flex',flexDirection:'column',gap:16}}>
            {data.map((item,i)=>(
              <div key={i} style={{background:'rgba(4,12,30,0.92)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:18,padding:'18px',backdropFilter:'blur(16px)',animation:`slideUp ${0.3+i*0.08}s ease`}}>
                <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#F0F8FF',marginBottom:4}}>{item.examTitle}</div>
                <div style={{display:'flex',gap:12,marginBottom:14,flexWrap:'wrap'}}>
                  {[{l:'Your Score',v:`${item.myScore}/${item.maxScore}`,c:'#4D9FFF'},{l:'Topper',v:`${item.topperScore}/${item.maxScore}`,c:'#FFD700'},{l:'Class Avg',v:`${item.avgScore}/${item.maxScore}`,c:'#27AE60'}].map((s,j)=>(
                    <div key={j} style={{background:`${s.c}12`,border:`1px solid ${s.c}28`,borderRadius:12,padding:'8px 14px',textAlign:'center',flex:1,minWidth:80}}>
                      <div style={{fontSize:16,fontWeight:800,color:s.c}}>{s.v}</div>
                      <div style={{fontSize:10,color:'rgba(160,200,240,0.55)'}}>{s.l}</div>
                    </div>
                  ))}
                </div>
                {item.subjects?.length>0&&(
                  <div>
                    <div style={{fontSize:11,fontWeight:700,color:'rgba(160,200,240,0.5)',textTransform:'uppercase',letterSpacing:1,marginBottom:8}}>Subject Breakdown</div>
                    {item.subjects.map((s,j)=>(
                      <div key={j} style={{marginBottom:10}}>
                        <div style={{display:'flex',justifyContent:'space-between',marginBottom:3}}>
                          <span style={{fontSize:11,color:'#F0F8FF',fontWeight:600}}>{s.name}</span>
                          <span style={{fontSize:11,color:'rgba(160,200,240,0.6)'}}>You: {s.my} · Topper: {s.topper} · Avg: {s.avg}</span>
                        </div>
                        <div style={{height:6,background:'rgba(255,255,255,0.07)',borderRadius:3,overflow:'hidden',position:'relative'}}>
                          <div style={{position:'absolute',height:'100%',left:0,width:`${(s.topper/item.maxScore)*100}%`,background:'rgba(255,215,0,0.3)',borderRadius:3}}/>
                          <div style={{position:'absolute',height:'100%',left:0,width:`${(s.avg/item.maxScore)*100}%`,background:'rgba(39,174,96,0.4)',borderRadius:3}}/>
                          <div style={{position:'absolute',height:'100%',left:0,width:`${(s.my/item.maxScore)*100}%`,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',borderRadius:3}}/>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Link to Batch Compare */}
        <div style={{marginTop:24,background:'rgba(155,89,182,0.08)',border:'1px solid rgba(155,89,182,0.2)',borderRadius:16,padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:10}}>
          <div>
            <div style={{fontSize:13,fontWeight:700,color:'#9B59B6',marginBottom:2}}>⚖️ Compare Batches</div>
            <div style={{fontSize:11,color:'rgba(160,200,240,0.55)'}}>Compare Test Series & Batches side-by-side before enrolling</div>
          </div>
          <button onClick={()=>router.push('/dashboard/batch-compare')} style={{background:'linear-gradient(135deg,#9B59B6,#7D3C98)',border:'none',borderRadius:10,padding:'9px 18px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12}}>Go to Batch Compare →</button>
        </div>

      </div>
    </div>
  )
}
