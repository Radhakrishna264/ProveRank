'use client'
import { useState, useEffect } from 'react'
import DashLayout from '@/components/DashLayout'
import { useAuth } from '@/lib/useAuth'

type ColorTheme = 'white'|'dark'|'teal'

export default function SettingsPage() {
  const { user } = useAuth('student')
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [mounted, setMounted] = useState(false)
  const [activeTheme, setActiveTheme] = useState<ColorTheme>('dark')

  useEffect(() => {
    setMounted(true)
    try {
      const sl = localStorage.getItem('pr_lang') as 'en'|'hi'|null
      if (sl) setLang(sl)
      const ct = localStorage.getItem('pr_color_theme') as ColorTheme | null
      if (ct && ['white','dark','teal'].includes(ct)) setActiveTheme(ct)
    } catch {}
  }, [])

  const t = (en: string, hi: string) => lang === 'en' ? en : hi

  const applyTheme = (theme: ColorTheme) => {
    setActiveTheme(theme)
    try {
      localStorage.setItem('pr_color_theme', theme)
      const h = document.documentElement
      h.classList.remove('white-theme', 'dark-theme', 'teal-theme')
      h.classList.add(theme + '-theme')
      h.setAttribute('data-color-theme', theme)
      window.dispatchEvent(new StorageEvent('storage', { key: 'pr_color_theme', newValue: theme }))
    } catch {}
  }

  const C = {
    white: { primary: '#2563EB', card: 'rgba(255,255,255,0.95)', border: 'rgba(0,0,0,0.06)', text: '#0F172A', sub: '#64748B' },
    dark:  { primary: '#4D9FFF', card: 'rgba(0,18,36,0.9)',      border: 'rgba(77,159,255,0.14)', text: '#E8F4FF', sub: '#6B8BAF' },
    teal:  { primary: '#2DD4BF', card: 'rgba(0,35,30,0.85)',     border: 'rgba(45,212,191,0.18)', text: '#CCFBF1', sub: '#5EEAD4' },
  }[activeTheme]

  if (!mounted) return null

  return (
    <DashLayout title={t('Settings', 'सेटिंग्स')} subtitle={t('Manage your app preferences', 'अपनी ऐप प्राथमिकताएं प्रबंधित करें')}>

      {/* ── Language Toggle ───────────────────────────────── */}
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: C.primary, marginBottom: 12 }}>
          🌐 {t('Language', 'भाषा')}
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          {(['en','hi'] as const).map(l => (
            <button
              key={l}
              onClick={() => { setLang(l); try { localStorage.setItem('pr_lang', l) } catch {} }}
              style={{
                flex: 1,
                background: lang === l ? C.primary + '22' : 'transparent',
                border: `1.5px solid ${lang === l ? C.primary : C.border}`,
                color: lang === l ? C.primary : C.sub,
                borderRadius: 10,
                padding: '10px',
                fontSize: 13,
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              {l === 'en' ? 'English' : 'हिन्दी'}
            </button>
          ))}
        </div>
      </div>

      {/* ── 🎨 Color Theme Picker ───────────────────────────── */}
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: C.primary, marginBottom: 4 }}>
          🎨 {t('App Color Theme', 'ऐप कलर थीम')}
        </div>
        <div style={{ fontSize: 11, color: C.sub, marginBottom: 16 }}>
          {t('Choose how ProveRank looks across all your pages', 'चुनें कि ProveRank सभी पेजों पर कैसा दिखे')}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 12 }}>
          {([
            { id: 'white' as ColorTheme, lbl: t('Pure White', 'शुद्ध सफेद'), sub: t('Bright & Clean','चमकीला'), bg: '#FFFFFF', acc: '#2563EB', ico: '☀️', tcl:'#0F172A' },
            { id: 'dark'  as ColorTheme, lbl: t('Pure Dark', 'शुद्ध काला'),  sub: t('Bold & Dark','गहरा'),     bg: '#0A0A0A', acc: '#4D9FFF', ico: '🌑', tcl:'#FFFFFF' },
            { id: 'teal'  as ColorTheme, lbl: t('Neon Teal', 'नियॉन टील'),   sub: t('Deep & Vibrant','जीवंत'), bg: 'linear-gradient(135deg,#001A1A,#002E2E)', acc: '#2DD4BF', ico: '🌊', tcl:'#CCFBF1' },
          ]).map(th => {
            const active = activeTheme === th.id
            return (
              <button
                key={th.id}
                onClick={() => applyTheme(th.id)}
                style={{
                  background: th.bg,
                  border: `2px solid ${active ? th.acc : 'rgba(255,255,255,0.1)'}`,
                  borderRadius: 14,
                  padding: '16px 8px',
                  cursor: 'pointer',
                  textAlign: 'center',
                  boxShadow: active ? `0 0 22px ${th.acc}55` : 'none',
                  transition: 'all .25s',
                  position: 'relative',
                  minHeight: 100,
                }}
              >
                {active && (
                  <span style={{ position: 'absolute', top: 8, right: 10, fontSize: 12, color: th.acc, fontWeight: 800 }}>
                    ✓
                  </span>
                )}
                <div style={{ fontSize: 26, marginBottom: 8 }}>{th.ico}</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: th.acc }}>{th.lbl}</div>
                <div style={{ fontSize: 9, marginTop: 4, color: th.tcl === '#FFFFFF' ? 'rgba(255,255,255,0.45)' : 'rgba(0,0,0,0.35)' }}>
                  {th.sub}
                </div>
              </button>
            )
          })}
        </div>

        <div style={{ fontSize: 10, color: C.sub, textAlign: 'center', marginTop: 14, lineHeight: 1.5 }}>
          {t(
            'Applies instantly to all student pages. Test Series page keeps its own theme.',
            'सभी स्टूडेंट पेजों पर तुरंत लागू होता है। टेस्ट सीरीज पेज अपनी थीम रखता है।'
          )}
        </div>
      </div>

      {/* ── About / Version (placeholder for future settings) ── */}
      <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 16, padding: 20 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: C.primary, marginBottom: 10 }}>
          ℹ️ {t('About', 'के बारे में')}
        </div>
        <div style={{ fontSize: 12, color: C.sub }}>
          ProveRank v1.0 — {t('NEET Test Platform', 'NEET टेस्ट प्लेटफॉर्म')}
        </div>
      </div>

    </DashLayout>
  )
}
