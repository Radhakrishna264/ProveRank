'use client'
import { useEffect } from 'react'

/**
 * ThemeWatcher — safely syncs localStorage pr_theme → html class
 * Intercepts localStorage.setItem so theme toggles apply instantly
 * Place once in layout.tsx, requires no changes to any other file
 */
export default function ThemeWatcher() {
  useEffect(() => {
    const apply = (t: string) => {
      const h = document.documentElement
      h.classList.remove('dark-theme', 'light-theme', 'aurora-theme')
      h.classList.add(
        t === 'light' ? 'light-theme' :
        t === 'aurora' ? 'aurora-theme' :
        'dark-theme'
      )
      h.setAttribute('data-theme', t)
    }

    // Apply on mount
    try {
      apply(localStorage.getItem('pr_theme') || 'dark')
    } catch {}

    // Intercept localStorage.setItem to catch theme toggles in same tab
    const orig = Storage.prototype.setItem
    Storage.prototype.setItem = function(key: string, value: string) {
      orig.call(this, key, value)
      if (key === 'pr_theme') apply(value)
    }

    // Also listen for cross-tab changes
    const onStorage = (e: StorageEvent) => {
      if (e.key === 'pr_theme' && e.newValue) apply(e.newValue)
    }
    window.addEventListener('storage', onStorage)

    return () => {
      Storage.prototype.setItem = orig
      window.removeEventListener('storage', onStorage)
    }
  }, [])

  return null
}
