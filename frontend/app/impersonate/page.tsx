'use client'
import { useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

export default function ImpersonatePage() {
  const router = useRouter()
  const params = useSearchParams()

  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name')

    if (!token || !id) {
      router.replace('/admin/x7k2p')
      return
    }

    // Store in sessionStorage (not localStorage) — isolated to this tab
    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name || 'Student'))
      sessionStorage.setItem('imp_mode', '1')
    } catch(e) {}

    router.replace('/dashboard')
  }, [params, router])

  return (
    <div style={{
      minHeight:'100vh',
      background:'#000A18',
      display:'flex',
      alignItems:'center',
      justifyContent:'center',
      color:'#4D9FFF',
      fontFamily:'Inter,sans-serif',
      fontSize:16
    }}>
      Loading student view...
    </div>
  )
}
