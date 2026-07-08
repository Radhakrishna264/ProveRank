'use client'
import StudentShell, { useShell, C } from '@/src/components/StudentShell'
import { useState, useEffect } from 'react'

type ColorTheme = 'light' | 'dark'

const migrate = (v: string | null): ColorTheme => {
  if (v === 'white') return 'light'
  if (v === 'teal') return 'dark'
  return (v === 'light' || v === 'dark') ? v : 'dark'
}

function SettingsContent() {
  const { lang, toast, theme } = useShell()
  const [activeTheme, setActiveTheme] = useState<ColorTheme>('dark')
  const t = (en: string, hi: string) => lang === 'en' ? en : hi

  useEffect(() => {
    try { setActiveTheme(migrate(localStorage.getItem('pr_color_theme'))) } catch {}
  }, [])

  const applyTheme = (th: ColorTheme) => {
    setActiveTheme(th)
    try {
      localStorage.setItem('pr_color_theme', th)
      window.dispatchEvent(new StorageEvent('storage', { key: 'pr_color_theme', newValue: th }))
      toast?.(t('Theme updated!', 'थीम अपडेट हो गई!'), 's')
    } catch {}
  }

  const cardBg = theme?.isDark ? 'rgba(255,255,255,0.03)' : 'rgba(37,99,235,0.03)'
  const cardBorder = theme?.border || 'rgba(77,159,255,0.14)'

  return (
    <div style={{ maxWidth: 720, margin: '0 auto' }}>
      <div style={{ fontSize: 20, fontWeight: 800, marginBottom: 4 }}>⚙️ {t('Settings', 'सेटिंग्स')}</div>
      <div style={{ fontSize: 13, color: theme?.sub, marginBottom: 24 }}>
        {t('Manage your app preferences', 'अपनी ऐप प्राथमिकताएं प्रबंधित करें')}
      </div>

      {/* 🎨 Theme Picker — Light / Dark only */}
      <div style={{ background: cardBg, border: `1px solid ${cardBorder}`, borderRadius: 16, padding: 20 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: theme?.primary, marginBottom: 4 }}>
          🎨 {t('App Theme', 'ऐप थीम')}
        </div>
        <div style={{ fontSize: 11, color: theme?.sub, marginBottom: 16 }}>
          {t('Choose how ProveRank looks across all your pages', 'चुनें कि ProveRank सभी पेजों पर कैसा दिखे')}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 12 }}>
          {([
            { id: 'light' as ColorTheme, lbl: t('Light', 'लाइट'), sub: t('Bright & Clean', 'चमकीला'), bg: '#FFFFFF', acc: '#2563EB', ico: '☀️', tcl: '#0F172A' },
            { id: 'dark'  as ColorTheme, lbl: t('Dark', 'डार्क'),  sub: t('Bold & Easy on eyes', 'आंखों के लिए आरामदायक'), bg: '#0A0E17', acc: '#4D9FFF', ico: '🌙', tcl: '#FFFFFF' },
          ]).map(th => {
            const active = activeTheme === th.id
            return (
              <button key={th.id} onClick={() => applyTheme(th.id)}
                style={{
                  background: th.bg,
                  border: `2px solid ${active ? th.acc : 'rgba(120,140,170,0.25)'}`,
                  borderRadius: 14, padding: '18px 8px', cursor: 'pointer', textAlign: 'center',
                  boxShadow: active ? `0 0 22px ${th.acc}55` : 'none',
                  transition: 'all .25s', position: 'relative', minHeight: 108,
                }}>
                {active && <span style={{ position: 'absolute', top: 8, right: 10, fontSize: 12, color: th.acc, fontWeight: 800 }}>✓</span>}
                <div style={{ fontSize: 28, marginBottom: 8 }}>{th.ico}</div>
                <div style={{ fontSize: 13, fontWeight: 700, color: th.acc }}>{th.lbl}</div>
                <div style={{ fontSize: 10, marginTop: 4, color: th.tcl === '#FFFFFF' ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.45)' }}>{th.sub}</div>
              </button>
            )
          })}
        </div>

        <div style={{ fontSize: 10, color: theme?.sub, textAlign: 'center', marginTop: 14 }}>
          {t('Applies instantly to all student pages. Test Series & Store keep their own look.', 'सभी पेजों पर तुरंत लागू होता है। टेस्ट सीरीज और स्टोर अपना लुक रखते हैं।')}
        </div>
      </div>
    </div>
  )
}

export default function SettingsPage() {
  return <StudentShell pageKey="settings"><SettingsContent /></StudentShell>
}
