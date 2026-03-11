'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { getToken, getRole, clearAuth } from '@/lib/auth'

export interface AuthUser {
  token: string
  role: string
}

export function useAuth(requiredRole?: 'student' | 'admin' | 'superadmin' | 'any') {
  const router = useRouter()
  const [user, setUser] = useState<AuthUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = getToken()
    const role  = getRole()

    if (!token || !role) {
      router.replace('/login')
      return
    }

    // Role-based access check
    if (requiredRole && requiredRole !== 'any') {
      const adminRoles = ['admin', 'superadmin']

      if (requiredRole === 'student' && adminRoles.includes(role)) {
        // admin trying to access student page → redirect to admin panel
        router.replace('/admin/x7k2p')
        return
      }

      if (requiredRole === 'admin' && !adminRoles.includes(role)) {
        // student trying to access admin page → redirect to dashboard
        router.replace('/dashboard')
        return
      }
    }

    setUser({ token, role })
    setLoading(false)
  }, [])

  const logout = () => {
    clearAuth()
    router.replace('/login')
  }

  return { user, loading, logout }
}
