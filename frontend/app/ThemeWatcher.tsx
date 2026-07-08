'use client'
import { useEffect } from 'react'

const migrate = (v: string | null): 'light' | 'dark' => {
  if (v === 'white') return 'light'
  if (v === 'teal') return 'dark'
  return (v === 'light' || v === 'dark') ? v : 'dark'
}

export default function ThemeWatcher() {
  useEffect(() => {
    // Apply theme class to BOTH <html> and <body> so all theme-based CSS
    // overrides (old + new) actually take effect across every page.
    const applyColorTheme = (raw: string) => {
      const t = migrate(raw)
      const h = document.documentElement
      const b = document.body
      h.classList.remove('white-theme', 'dark-theme', 'teal-theme', 'light-theme')
      b.classList.remove('white-theme', 'dark-theme', 'teal-theme', 'light-theme')
      h.classList.add(t + '-theme')
      b.classList.add(t + '-theme')
      h.setAttribute('data-color-theme', t)
    }

    // On mount — read saved theme (migrating legacy white/teal values)
    try {
      const ct = localStorage.getItem('pr_color_theme') || 'dark'
      applyColorTheme(ct)
    } catch {}

    // Intercept localStorage.setItem — catch theme changes in same tab
    const orig = Storage.prototype.setItem
    Storage.prototype.setItem = function (key: string, value: string) {
      orig.call(this, key, value)
      if (key === 'pr_color_theme') applyColorTheme(value)
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
