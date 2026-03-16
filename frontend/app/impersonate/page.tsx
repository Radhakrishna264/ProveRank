'use client'
import { Suspense, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function Inner() {
  const router = useRouter()
  const params = useSearchParams()
  useEffect(() => {
    const token = params.get('token')
    const id    = params.get('id')
    const name  = params.get('name') || 'Student'
    if (!token || !id) { router.replace('/admin/x7k2p'); return }
    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name))
    } catch(e) {}
    router.replace('/dashboard')
  }, [params, router])
  return <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Opening student view...</div>
}

export default function ImpersonatePage() {
  return (
    <Suspense fallback={<div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif'}}>Loading...</div>}>
      <Inner/>
    </Suspense>
  )
}
