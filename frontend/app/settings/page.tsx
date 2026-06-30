'use client'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
import { useState, useEffect } from 'react'

type ColorTheme = 'white'|'dark'|'teal'

function SettingsContent() {
  const { lang, toast } = useShell()
  const [activeTheme, setActiveTheme] = useState<ColorTheme>('dark')
  const t = (en: string, hi: string) => lang === 'en' ? en : hi

  useEffect(() => {
    try {
      const ct = localStorage.getItem('pr_color_theme') as ColorTheme | null
      if (ct && ['white','dark','teal'].includes(ct)) setActiveTheme(ct)
    } catch {}
  }, [])

  const applyTheme = (theme: ColorTheme) => {
    setActiveTheme(theme)
    try {
      localStorage.setItem('pr_color_theme', theme)
      window.dispatchEvent(new StorageEvent('storage', { key: 'pr_color_theme', newValue: theme }))
      toast?.(t('Theme updated!', 'थीम अपडेट हो गई!'), 's')
    } catch {}
  }

  return (
    <div style={{ maxWidth: 720, margin: '0 auto' }}>
      <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 4 }}>⚙️ {t('Settings', 'सेटिंग्स')}</div>
      <div style={{ fontSize: 13, color: C.sub, marginBottom: 24 }}>
        {t('Manage your app preferences', 'अपनी ऐप प्राथमिकताएं प्रबंधित करें')}
      </div>

      {/* 🎨 Theme Picker */}
      <div style={{ background: 'rgba(0,18,36,0.5)', border: '1px solid rgba(77,159,255,0.14)', borderRadius: 16, padding: 20 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: C.primary, marginBottom: 4 }}>
          🎨 {t('App Color Theme', 'ऐप कलर थीम')}
        </div>
        <div style={{ fontSize: 11, color: C.sub, marginBottom: 16 }}>
          {t('Choose how ProveRank looks across all your pages', 'चुनें कि ProveRank सभी पेजों पर कैसा दिखे')}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 12 }}>
          {([
            { id: 'white' as ColorTheme, lbl: t('Pure White','शुद्ध सफेद'), sub: t('Bright & Clean','चमकीला'), bg: '#FFFFFF', acc: '#2563EB', ico: '☀️', tcl:'#0F172A' },
            { id: 'dark'  as ColorTheme, lbl: t('Pure Dark','शुद्ध काला'),  sub: t('Bold & Dark','गहरा'),     bg: '#0A0A0A', acc: '#4D9FFF', ico: '🌑', tcl:'#FFFFFF' },
            { id: 'teal'  as ColorTheme, lbl: t('Neon Teal','नियॉन टील'),   sub: t('Deep & Vibrant','जीवंत'), bg: 'linear-gradient(135deg,#001A1A,#002E2E)', acc: '#2DD4BF', ico: '🌊', tcl:'#CCFBF1' },
          ]).map(th => {
            const active = activeTheme === th.id
            return (
              <button key={th.id} onClick={() => applyTheme(th.id)}
                style={{
                  background: th.bg,
                  border: `2px solid ${active ? th.acc : 'rgba(255,255,255,0.1)'}`,
                  borderRadius: 14, padding: '16px 8px', cursor: 'pointer', textAlign: 'center',
                  boxShadow: active ? `0 0 22px ${th.acc}55` : 'none',
                  transition: 'all .25s', position: 'relative', minHeight: 100,
                }}>
                {active && <span style={{ position:'absolute',top:8,right:10,fontSize:12,color:th.acc,fontWeight:800 }}>✓</span>}
                <div style={{ fontSize: 26, marginBottom: 8 }}>{th.ico}</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: th.acc }}>{th.lbl}</div>
                <div style={{ fontSize: 9, marginTop: 4, color: th.tcl==='#FFFFFF' ? 'rgba(255,255,255,0.45)' : 'rgba(0,0,0,0.35)' }}>{th.sub}</div>
              </button>
            )
          })}
        </div>

        <div style={{ fontSize: 10, color: C.sub, textAlign: 'center', marginTop: 14 }}>
          {t('Applies instantly to all student pages. Test Series keeps its own theme.', 'सभी पेजों पर तुरंत लागू होता है। टेस्ट सीरीज अपनी थीम रखता है।')}
        </div>
      </div>
    </div>
  )
}

export default function SettingsPage() {
  return <StudentShell pageKey="settings"><SettingsContent/></StudentShell>
}
