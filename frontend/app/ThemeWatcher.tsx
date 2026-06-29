'use client'
import { useEffect } from 'react'

export default function ThemeWatcher() {
  useEffect(() => {
    // Apply theme from pr_color_theme (new) or fallback to pr_theme (old)
    const applyColorTheme = (t: string) => {
      const h = document.documentElement
      h.classList.remove('white-theme', 'dark-theme', 'teal-theme')
      h.classList.add(t + '-theme')
      h.setAttribute('data-color-theme', t)
    }

    // On mount — read saved theme
    try {
      const ct = localStorage.getItem('pr_color_theme') || 'dark'
      applyColorTheme(['white','dark','teal'].includes(ct) ? ct : 'dark')
    } catch {}

    // Intercept localStorage.setItem — catch theme changes in same tab
    const orig = Storage.prototype.setItem
    Storage.prototype.setItem = function(key: string, value: string) {
      orig.call(this, key, value)
      if (key === 'pr_color_theme') {
        applyColorTheme(['white','dark','teal'].includes(value) ? value : 'dark')
      }
    }

    // Cross-tab sync
    const onStorage = (e: StorageEvent) => {
      if (e.key === 'pr_color_theme' && e.newValue) applyColorTheme(e.newValue)
    }
    window.addEventListener('storage', onStorage)

    return () => {
      Storage.prototype.setItem = orig
      window.removeEventListener('storage', onStorage)
    }
  }, [])

  return null
}
