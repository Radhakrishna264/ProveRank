'use client'
import{useState,useEffect}from 'react'

interface WelcomeBannerProps{
  studentName:string
  studentId:string
  onClose:()=>void
}

export default function WelcomeBanner({studentName,studentId,onClose}:WelcomeBannerProps){
  const[visible,setVisible]=useState(false)
  const[copied,setCopied]=useState(false)
  
  useEffect(()=>{setTimeout(()=>setVisible(true),100)},[])

  const copyId=()=>{
    navigator.clipboard.writeText(studentId).then(()=>{setCopied(true);setTimeout(()=>setCopied(false),2000)})
  }

  const handleClose=async()=>{
    setVisible(false)
    setTimeout(onClose,400)
    try{
      const token=localStorage.getItem('pr_token')
      if(token)await fetch((process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com')+'/api/welcome-seen',{
        method:'POST',headers:{Authorization:'Bearer '+token}
      })
    }catch(e){}
  }

  return(
    <div style={{
      position:'fixed',inset:0,zIndex:9999,
      background:'rgba(0,0,0,0.85)',backdropFilter:'blur(8px)',
      display:'flex',alignItems:'center',justifyContent:'center',padding:16,
      opacity:visible?1:0,transition:'opacity 0.4s ease'
    }}>
      <div style={{
        background:'linear-gradient(135deg,#001628 0%,#000D20 50%,#001028 100%)',
        border:'1px solid rgba(77,159,255,0.4)',borderRadius:24,
        padding:'40px 28px',maxWidth:420,width:'100%',
        boxShadow:'0 0 80px rgba(77,159,255,0.15),0 0 200px rgba(77,159,255,0.05)',
        transform:visible?'scale(1) translateY(0)':'scale(0.9) translateY(20px)',
        transition:'all 0.4s cubic-bezier(0.34,1.56,0.64,1)',
        fontFamily:'Inter,sans-serif',textAlign:'center',position:'relative',overflow:'hidden'
      }}>
        {/* Glow effects */}
        <div style={{position:'absolute',top:-60,left:'50%',transform:'translateX(-50%)',width:200,height:200,background:'radial-gradient(circle,rgba(77,159,255,0.15),transparent 70%)',pointerEvents:'none'}}/>
        <div style={{position:'absolute',bottom:-40,right:-40,width:150,height:150,background:'radial-gradient(circle,rgba(99,102,241,0.1),transparent 70%)',pointerEvents:'none'}}/>
        
        {/* Stars animation */}
        <style>{`
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=Playfair+Display:wght@700;800&display=swap');
          @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
          @keyframes pulse{0%,100%{opacity:0.6}50%{opacity:1}}
          @keyframes shimmer{0%{background-position:-200% center}100%{background-position:200% center}}
          .welcome-badge:hover{transform:scale(1.02)}
        `}</style>
        
        {/* Rocket / Welcome Icon */}
        <div style={{fontSize:56,marginBottom:16,animation:'float 3s ease-in-out infinite',display:'block'}}>🎉</div>
        
        {/* Welcome text */}
        <div style={{fontSize:13,fontWeight:600,color:'#4D9FFF',letterSpacing:2,textTransform:'uppercase',marginBottom:8}}>Welcome to ProveRank</div>
        <div style={{fontSize:24,fontWeight:800,fontFamily:'Playfair Display,serif',color:'#E8F4FF',marginBottom:6,lineHeight:1.2}}>
          Namaste, {studentName?.split(' ')[0] || 'Student'}! 🙏
        </div>
        <div style={{fontSize:13,color:'#6B8FAF',marginBottom:28,lineHeight:1.6}}>
          Your journey to NEET success starts here.<br/>Your unique Student ID is ready!
        </div>
        
        {/* Student ID Card */}
        <div className="welcome-badge" style={{
          background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(99,102,241,0.08))',
          border:'1.5px solid rgba(77,159,255,0.35)',
          borderRadius:16,padding:'20px 24px',marginBottom:24,
          cursor:'pointer',transition:'all 0.2s',position:'relative',overflow:'hidden'
        }} onClick={copyId}>
          <div style={{position:'absolute',inset:0,background:'linear-gradient(135deg,transparent 30%,rgba(77,159,255,0.05) 100%)',pointerEvents:'none'}}/>
          <div style={{fontSize:10,fontWeight:700,color:'#6B8FAF',letterSpacing:2,textTransform:'uppercase',marginBottom:10}}>Your Student ID</div>
          <div style={{
            fontSize:28,fontWeight:800,
            background:'linear-gradient(90deg,#4D9FFF,#818CF8,#A78BFA)',
            WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',
            backgroundSize:'200% auto',animation:'shimmer 3s linear infinite',
            letterSpacing:4,fontFamily:'monospace',marginBottom:10
          }}>{studentId}</div>
          <div style={{fontSize:11,color:copied?'#00C48C':'#6B8FAF',transition:'color 0.2s',display:'flex',alignItems:'center',justifyContent:'center',gap:4}}>
            {copied?'✅ Copied to clipboard!':'📋 Tap to copy ID'}
          </div>
        </div>
        
        {/* Info points */}
        <div style={{display:'flex',flexDirection:'column',gap:8,marginBottom:28,textAlign:'left'}}>
          {[
            {i:'🔐',t:'Save your Student ID',d:'Use it to login and for admin reference'},
            {i:'📊',t:'Track your Progress',d:'View ranks, scores & analytics'},
            {i:'📚',t:'Access Study Material',d:'Batches, exams & notes await you'},
          ].map(x=>(
            <div key={x.i} style={{display:'flex',gap:10,alignItems:'flex-start',padding:'8px 10px',borderRadius:10,background:'rgba(77,159,255,0.04)',border:'1px solid rgba(77,159,255,0.08)'}}>
              <span style={{fontSize:16,flexShrink:0}}>{x.i}</span>
              <div>
                <div style={{fontSize:12,fontWeight:700,color:'#E8F4FF'}}>{x.t}</div>
                <div style={{fontSize:11,color:'#6B8FAF'}}>{x.d}</div>
              </div>
            </div>
          ))}
        </div>
        
        {/* CTA Button */}
        <button onClick={handleClose} style={{
          width:'100%',padding:'14px',
          background:'linear-gradient(135deg,#4D9FFF,#6366F1)',
          color:'#fff',border:'none',borderRadius:12,
          fontSize:14,fontWeight:700,cursor:'pointer',
          boxShadow:'0 8px 32px rgba(77,159,255,0.35)',
          transition:'all 0.2s',letterSpacing:0.5
        }}>
          🚀 Start My NEET Journey!
        </button>
        
        <div style={{fontSize:10,color:'rgba(107,143,175,0.5)',marginTop:12}}>
          ProveRank · India's Most Advanced NEET Platform
        </div>
      </div>
    </div>
  )
}
