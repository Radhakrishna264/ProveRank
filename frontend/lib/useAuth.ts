'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from './auth'

export function useAuth(required?: string | string[]) {
  const router = useRouter()
  const [user, setUser] = useState<{token:string;role:string}|null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = getToken(); const role = getRole()
    if (!token || !role) { router.replace('/login'); return }
    if (required) {
      const roles = Array.isArray(required) ? required : [required]
      if (!roles.includes(role)) { router.replace('/login'); return }
    }
    setUser({ token, role })
    setLoading(false)
  }, [])

  const logout = () => { clearAuth(); router.replace('/login') }
  return { user, loading, logout }
}
