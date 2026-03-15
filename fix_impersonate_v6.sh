#!/bin/bash
node << 'NODEOF'
const fs = require('fs')

const path = '/home/runner/workspace/frontend/app/impersonate/page.tsx'
fs.mkdirSync('/home/runner/workspace/frontend/app/impersonate', { recursive: true })

fs.writeFileSync(path, `'use client'
import { Suspense, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'

function ImpersonateInner() {
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

    try {
      sessionStorage.setItem('imp_token', token)
      sessionStorage.setItem('imp_id', id)
      sessionStorage.setItem('imp_name', decodeURIComponent(name || 'Student'))
      sessionStorage.setItem('imp_mode', '1')
    } catch(e) {}

    router.replace('/dashboard')
  }, [params, router])

  return (
    <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16}}>
      Loading student view...
    </div>
  )
}

export default function ImpersonatePage() {
  return (
    <Suspense fallback={
      <div style={{minHeight:'100vh',background:'#000A18',display:'flex',alignItems:'center',justifyContent:'center',color:'#4D9FFF',fontFamily:'Inter,sans-serif',fontSize:16}}>
        Loading...
      </div>
    }>
      <ImpersonateInner />
    </Suspense>
  )
}
`)
console.log('✅ /impersonate page fixed with Suspense')
NODEOF

cd /home/runner/workspace
git add -A
git commit -m "fix: impersonate page — wrap useSearchParams in Suspense boundary"
git push origin main
echo "✅ Done"
