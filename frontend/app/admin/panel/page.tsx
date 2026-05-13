'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function AdminPanel() {
  const router = useRouter()
  useEffect(() => {
    router.replace('/admin/x7k2p')
  }, [router])
  return null
}
