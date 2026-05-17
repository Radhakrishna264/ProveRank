'use client'
import { useState } from 'react'

interface Props {
  student: { name: string; studentId: string; email: string }
  onClose: () => void
}

const FEATURES = [
  { icon: '⚡', title: 'Real-Time All India Rankings', desc: 'Live rank updates across every exam' },
  { icon: '🧠', title: 'AI Performance Intelligence', desc: 'Smart analytics powered by machine learning' },
  { icon: '🔬', title: 'NEET Pattern Mock Tests', desc: '180-question full-length exam simulations' },
  { icon: '📊', title: 'Deep Subject Analytics', desc: 'Physics · Chemistry · Biology breakdown' },
  { icon: '🏆', title: 'Achievement Certificates', desc: 'Earn & download verified digital certificates' },
  { icon: '📚', title: 'PYQ Bank 2015–2024', desc: 'Decade of previous year questions filtered by year' },
  { icon: '🎯', title: 'Smart Revision Engine', desc: 'AI-identified weak areas with revision plans' },
  { icon: '🛡️', title: 'Advanced Proctored Exams', desc: 'Secure, fair, tamper-proof examination system' },
  { icon: '📄', title: 'Performance Report PDF', desc: 'Comprehensive downloadable progress report' },
  { icon: '🪪', title: 'Digital Admit Cards', desc: 'Auto-generated with QR code verification' },
  { icon: '👨‍👩‍👧', title: 'Parent Progress Portal', desc: 'Share your journey with your family' },
  { icon: '🔥', title: 'Streak & Milestone Tracker', desc: 'Stay consistent, earn badges, climb ranks' },
]

export default function WelcomeBanner({ student, onClose }: Props) {
  const [copied, setCopied] = useState(false)

  const copyId = () => {
    try { navigator.clipboard.writeText(student.studentId) } catch(e) {}
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div style={{
      position:'fixed',inset:0,zIndex:9999,
      background:'rgba(0,0,0,0.88)',
      backdropFilter:'blur(14px)',
      display:'flex',alignItems:'center',justifyContent:'center',
      padding:'16px',overflowY:'auto'
    }}>
      <div style={{
        width:'100%',maxWidth:'660px',
        background:'linear-gradient(145deg,rgba(10,14,28,0.99),rgba(6,10,22,0.99))',
        border:'1px solid rgba(212,175,55,0.35)',
        borderRadius:'24px',padding:'36px 28px',
        boxShadow:'0 0 80px rgba(212,175,55,0.12),0 0 140px rgba(77,159,255,0.07)',
        position:'relative',maxHeight:'92vh',overflowY:'auto'
      }}>

        {/* Gold top line */}
        <div style={{
          position:'absolute',top:0,left:'15%',right:'15%',height:'2px',
          background:'linear-gradient(90deg,transparent,#D4AF37,#FFD700,#D4AF37,transparent)',
          borderRadius:'2px'
        }}/>

        {/* Header */}
        <div style={{textAlign:'center',marginBottom:'24px'}}>
          <div style={{fontSize:'46px',marginBottom:'8px'}}>🎉</div>
          <h1 style={{
            fontSize:'25px',fontWeight:900,fontFamily:'Inter,sans-serif',
            background:'linear-gradient(135deg,#FFD700,#FFF8DC,#D4AF37)',
            WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',
            marginBottom:'6px',letterSpacing:'-0.5px'
          }}>Welcome to ProveRank!</h1>
          <p style={{color:'#7A8FAA',fontSize:'13px',fontFamily:'Inter,sans-serif'}}>
            Your journey to{' '}
            <span style={{color:'#4D9FFF',fontWeight:700}}>All India Rank #1</span>{' '}
            begins today
          </p>
        </div>

        {/* Student Name */}
        <div style={{textAlign:'center',marginBottom:'18px'}}>
          <p style={{color:'#4B6080',fontSize:'11px',letterSpacing:'2px',textTransform:'uppercase',marginBottom:'4px',fontFamily:'Inter,sans-serif'}}>
            Registered As
          </p>
          <p style={{
            fontSize:'21px',fontWeight:800,fontFamily:'Inter,sans-serif',
            background:'linear-gradient(135deg,#E8F4FF,#4D9FFF)',
            WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'
          }}>{student.name}</p>
          <p style={{color:'#4B6080',fontSize:'12px',marginTop:'3px',fontFamily:'Inter,sans-serif'}}>{student.email}</p>
        </div>

        {/* Student ID Card */}
        <div style={{
          background:'linear-gradient(135deg,rgba(212,175,55,0.07),rgba(192,192,192,0.04))',
          border:'1px solid rgba(212,175,55,0.3)',
          borderRadius:'14px',padding:'16px 20px',
          marginBottom:'24px',textAlign:'center',
          boxShadow:'0 0 24px rgba(212,175,55,0.07)'
        }}>
          <p style={{color:'#7A8FAA',fontSize:'10px',letterSpacing:'2.5px',textTransform:'uppercase',marginBottom:'10px',fontFamily:'Inter,sans-serif'}}>
            Your Unique Student ID
          </p>
          <div style={{display:'flex',alignItems:'center',justifyContent:'center',gap:'12px',flexWrap:'wrap'}}>
            <span style={{
              fontSize:'26px',fontWeight:900,letterSpacing:'5px',
              fontFamily:'monospace',
              background:'linear-gradient(135deg,#B8B8B8,#FFFFFF,#C8C8C8,#A0A0A0)',
              WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'
            }}>{student.studentId || 'Generating...'}</span>
            {student.studentId && (
              <button onClick={copyId} style={{
                background:copied?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.12)',
                border:`1px solid ${copied?'rgba(0,196,140,0.45)':'rgba(77,159,255,0.35)'}`,
                borderRadius:'8px',padding:'6px 14px',cursor:'pointer',
                color:copied?'#00C48C':'#4D9FFF',fontSize:'12px',fontWeight:700,
                fontFamily:'Inter,sans-serif',transition:'all 0.2s'
              }}>{copied?'✓ Copied!':'⎘ Copy'}</button>
            )}
          </div>
          <p style={{color:'#3A5070',fontSize:'11px',marginTop:'10px',fontFamily:'Inter,sans-serif'}}>
            Save this ID — required for admit cards &amp; support
          </p>
        </div>

        {/* Features Grid */}
        <div style={{marginBottom:'26px'}}>
          <p style={{
            textAlign:'center',color:'#7A8FAA',fontSize:'10px',
            letterSpacing:'2px',textTransform:'uppercase',marginBottom:'14px',
            fontFamily:'Inter,sans-serif'
          }}>Everything You Unlock with ProveRank</p>
          <div style={{
            display:'grid',
            gridTemplateColumns:'repeat(auto-fill,minmax(185px,1fr))',
            gap:'9px'
          }}>
            {FEATURES.map((f,i) => (
              <div key={i} style={{
                background:'rgba(77,159,255,0.03)',
                border:'1px solid rgba(192,192,192,0.09)',
                borderRadius:'10px',padding:'11px 12px',
                display:'flex',gap:'9px',alignItems:'flex-start'
              }}>
                <span style={{fontSize:'18px',lineHeight:1,flexShrink:0}}>{f.icon}</span>
                <div>
                  <p style={{
                    fontSize:'11.5px',fontWeight:700,
                    background:'linear-gradient(135deg,#CCCCCC,#F0F0F0)',
                    WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',
                    fontFamily:'Inter,sans-serif',marginBottom:'2px',lineHeight:1.3
                  }}>{f.title}</p>
                  <p style={{fontSize:'10.5px',color:'#3A5070',fontFamily:'Inter,sans-serif',lineHeight:1.4}}>{f.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* CTA */}
        <button onClick={onClose} style={{
          width:'100%',padding:'14px',
          background:'linear-gradient(135deg,#1448b8,#4D9FFF,#1a5fd4)',
          border:'none',borderRadius:'12px',
          color:'#fff',fontSize:'15px',fontWeight:700,
          fontFamily:'Inter,sans-serif',cursor:'pointer',
          letterSpacing:'0.5px',
          boxShadow:'0 4px 28px rgba(77,159,255,0.3)'
        }}>Begin Your Journey →</button>

        <p style={{textAlign:'center',color:'#2A3A50',fontSize:'11px',marginTop:'12px',fontFamily:'Inter,sans-serif'}}>
          ProveRank · Advanced NEET Preparation Platform
        </p>
      </div>
    </div>
  )
}
