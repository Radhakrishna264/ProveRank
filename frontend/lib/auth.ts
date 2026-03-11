export const getToken = (): string | null =>
  typeof window !== 'undefined' ? localStorage.getItem('pr_token') : null

export const getRole = (): string | null =>
  typeof window !== 'undefined' ? localStorage.getItem('pr_role') : null

export const setToken = (t: string) => localStorage.setItem('pr_token', t)
export const setRole  = (r: string) => localStorage.setItem('pr_role',  r)

export const clearAuth = () => {
  localStorage.removeItem('pr_token')
  localStorage.removeItem('pr_role')
}

export const isLoggedIn    = () => !!getToken()
export const isStudent     = () => getRole() === 'student'
export const isAdmin       = () => ['admin','superadmin'].includes(getRole() || '')
export const isSuperAdmin  = () => getRole() === 'superadmin'
