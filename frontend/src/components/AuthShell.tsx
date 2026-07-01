'use client'
import PRLogo from '@/components/PRLogo'
import { ReactNode } from 'react'

export const T = {
  bg: 'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)',
  panel: 'rgba(0,50,44,0.9)',
  pri: '#2DD4BF',
  card: 'rgba(0,35,30,0.78)',
  cardBorder: 'rgba(0,200,160,0.22)',
  txt: '#CCFBF1',
  sub: '#5EEAD4',
  inputBg: 'rgba(0,20,18,0.8)',
  inputBorder: 'rgba(0,200,160,0.3)',
}

export const inp: any = {
  width: '100%', padding: '12px 14px', background: T.inputBg,
  border: `1.5px solid ${T.inputBorder}`, borderRadius: 10, color: T.txt,
  fontSize: 14, fontFamily: 'Inter,sans-serif', outline: 'none',
  boxSizing: 'border-box', transition: 'border-color .2s',
}

export function inpErr(hasError: boolean): any {
  return { ...inp, border: hasError ? '1.5px solid #FF4D4D' : inp.border }
}

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

export default function AuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1
  return (
    <div style={{ minHeight: '100vh', background: T.bg, fontFamily: 'Inter,sans-serif' }}>
      <style>{`
        @keyframes glowTeal{0%,100%{filter:drop-shadow(0 0 6px #2DD4BF66)}50%{filter:drop-shadow(0 0 20px #2DD4BFaa)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0deg);opacity:1}100%{transform:translateY(420px) rotate(360deg);opacity:0}}
        *{box-sizing:border-box}
        .auth-mobile-bar{display:none}
        @media (max-width: 860px){
          .auth-left-panel, .auth-step-rail{display:none !important}
          .auth-mobile-bar{display:flex !important}
          .auth-row{flex-direction:column !important}
          .auth-form-area{padding:20px 16px 48px !important}
        }
      `}</style>

      {/* Mobile sticky top bar — logo + step dots (35.27) */}
      <div className="auth-mobile-bar" style={{ position: 'sticky', top: 0, zIndex: 30, height: 52, alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', background: 'rgba(0,18,16,0.94)', backdropFilter: 'blur(14px)', borderBottom: `1px solid ${T.cardBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ animation: 'glowTeal 3s ease-in-out infinite' }}><PRLogo size={24} /></div>
          <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, color: T.pri }}>ProveRank</span>
        </div>
        {hasSteps && (
          <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
            {steps.map((_, i) => (
              <div key={i} style={{ width: i === current ? 16 : 6, height: 6, borderRadius: 3, background: i <= current ? T.pri : 'rgba(94,234,212,0.22)', transition: 'all .3s' }} />
            ))}
          </div>
        )}
      </div>

      {/* Desktop: 3-column row — branding | step rail | form (35.27) */}
      <div className="auth-row" style={{ display: 'flex', minHeight: '100vh' }}>

        <div className="auth-left-panel" style={{ width: 220, flexShrink: 0, background: T.panel, padding: '40px 22px', display: 'flex', flexDirection: 'column', gap: 22 }}>
          <div style={{ animation: 'glowTeal 3s ease-in-out infinite', width: 'fit-content' }}>
            <PRLogo size={40} />
          </div>
          <div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: T.pri, lineHeight: 1.3 }}>ProveRank</div>
            <div style={{ fontSize: 11, color: T.sub, marginTop: 4, fontWeight: 600, letterSpacing: 0.4 }}>Rise to the Top</div>
          </div>
          <div style={{ height: 1, background: T.cardBorder }} />
          {[
            ['🎯', 'Multi Exam Platform'],
            ['🤖', 'AI Proctoring'],
            ['👨‍🏫', 'Designed By Experts'],
            ['📊', 'Deep AI Analytics'],
            ['🏆', 'All India Ranking'],
            ['⚡', 'Instant Results'],
            ['📱', 'Mobile Friendly'],
          ].map(([ic, l]) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 15 }}>{ic}</span>
              <span style={{ fontSize: 11, color: T.txt, fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>

        {hasSteps && (
          <div className="auth-step-rail" style={{ width: 160, flexShrink: 0, padding: '40px 16px', display: 'flex', flexDirection: 'column', gap: 4 }}>
            {steps.map((s, i) => {
              const active = i === current, done = i < current
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 8px', borderRadius: 10, background: active ? 'rgba(45,212,191,0.1)' : 'transparent' }}>
                  <div style={{ width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0, background: done ? T.pri : active ? 'rgba(45,212,191,0.2)' : 'rgba(94,234,212,0.08)', color: done ? '#001A1A' : active ? T.pri : T.sub, border: active ? `1.5px solid ${T.pri}` : '1px solid rgba(94,234,212,0.2)' }}>
                    {done ? '✓' : i + 1}
                  </div>
                  <span style={{ fontSize: 11, color: active ? T.txt : T.sub, fontWeight: active ? 700 : 400 }}>{s.label}</span>
                </div>
              )
            })}
          </div>
        )}

        <div className="auth-form-area" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '40px 20px', overflowY: 'auto' }}>
          <div style={{ width: '100%', maxWidth: 420, animation: 'fadeIn .5s ease' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
