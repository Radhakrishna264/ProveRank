'use client'
import { Suspense, useEffect, useState } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

function VerifyContent() {
  const [status, setStatus] = useState<'loading'|'success'|'error'>('loading')
  const [message, setMessage] = useState('')
  const params = useSearchParams()
  const router = useRouter()

  useEffect(() => {
    const token = params.get('token')
    if (!token) { setStatus('error'); setMessage('Invalid verification link.'); return }
    fetch(`${API}/api/auth/verify-email?token=${token}`)
      .then(r => r.json())
      .then(d => {
        if (d.message?.toLowerCase().includes('success')) {
          setStatus('success')
          setMessage('Email verified! Redirecting to login...')
          setTimeout(() => router.push('/login'), 3000)
        } else {
          setStatus('error')
          setMessage(d.message || 'Verification failed.')
        }
      })
      .catch(() => { setStatus('error'); setMessage('Server error. Try again.') })
  }, [])

  return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center'}}>
      <div style={{background:'#001628',border:'1px solid #1A3A5C',borderRadius:14,padding:40,maxWidth:420,width:'90%',textAlign:'center'}}>
        <div style={{fontSize:48,marginBottom:16}}>
          {status==='loading'?'⏳':status==='success'?'✅':'❌'}
        </div>
        <h2 style={{color:'#4D9FFF',fontFamily:'Arial',marginBottom:12}}>
          {status==='loading'?'Verifying...':status==='success'?'Email Verified!':'Verification Failed'}
        </h2>
        <p style={{color:'#E8F4FF',fontFamily:'Arial',fontSize:15}}>
          {status==='loading'?'Please wait...' : message}
        </p>
        {status==='error' && (
          <a href="/login" style={{display:'inline-block',marginTop:20,background:'#4D9FFF',color:'#fff',padding:'10px 28px',borderRadius:8,textDecoration:'none',fontWeight:'bold'}}>Go to Login</a>
        )}
      </div>
    </div>
  )
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={
      <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center'}}>
        <p style={{color:'#4D9FFF',fontFamily:'Arial',fontSize:18}}>⏳ Loading...</p>
      </div>
    }>
      <VerifyContent />
    </Suspense>
  )
}
