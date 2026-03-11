'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { getRole, getToken } from '@/lib/auth'

export default function AdminRedirect() {
  const router = useRouter()
  useEffect(()=>{
    const t=getToken(); const r=getRole()
    if(!t||!['admin','superadmin'].includes(r)){
      router.replace('/login')
    } else {
      router.replace('/admin/x7k2p')
    }
  },[])
  return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center'}}>
      <div style={{width:40,height:40,border:'3px solid rgba(77,159,255,0.2)',borderTopColor:'#4D9FFF',borderRadius:'50%',animation:'spin 0.8s linear infinite'}}/>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  )
}
