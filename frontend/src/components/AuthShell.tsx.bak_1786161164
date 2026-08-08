'use client'
import PRLogo from '@/components/PRLogo'
import { ReactNode } from 'react'

// ── Design Tokens — Ultra Premium Neon Blue (matches globals.css --primary #4D9FFF / --bg-dark #000A18) ──
export const T = {
  bg: 'linear-gradient(165deg,#000A18 0%,#020F22 45%,#00050D 100%)',
  panel: 'linear-gradient(180deg, rgba(0,20,38,0.95), rgba(0,8,18,0.98))',
  pri: '#4D9FFF',
  priDark: '#0066CC',
  cyan: '#00D4FF',
  card: 'rgba(0,20,38,0.72)',
  cardBorder: 'rgba(77,159,255,0.22)',
  txt: '#E8F4FF',
  sub: '#6B8BAF',
  dark: '#031320',
  success: '#00C48C',
  danger: '#FF4757',
  inputBg: 'rgba(0,14,28,0.85)',
  inputBorder: '#002D55',
}

export const inp: any = {
  width: '100%', padding: '12px 14px', background: T.inputBg,
  border: `1.5px solid ${T.inputBorder}`, borderRadius: 10, color: T.txt,
  fontSize: 14, fontFamily: 'Inter,sans-serif', outline: 'none',
  boxSizing: 'border-box', transition: 'border-color .2s, box-shadow .2s',
}

export function inpErr(hasError: boolean): any {
  return { ...inp, border: hasError ? `1.5px solid ${T.danger}` : inp.border }
}

const EXAM_BADGES = ['NEET', 'JEE', 'CUET', 'SSC', 'CLAT', 'BANK']

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

export default function AuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1
  return (
    <div style={{ minHeight: '100vh', background: T.bg, fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden' }}>
      <style>{`
        @keyframes glowPulse{0%,100%{filter:drop-shadow(0 0 6px #4D9FFF66)}50%{filter:drop-shadow(0 0 18px #00D4FFaa)}}
        @keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0deg);opacity:1}100%{transform:translateY(420px) rotate(360deg);opacity:0}}
        @keyframes radarSpin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        @keyframes bgPulse{0%,100%{opacity:.55;transform:scale(1)}50%{opacity:.85;transform:scale(1.08)}}
        @keyframes badgeFade{from{opacity:0;transform:scale(.6)}to{opacity:1;transform:scale(1)}}
        *{box-sizing:border-box}
        .pr-input:focus{border-color:${T.pri} !important;box-shadow:0 0 0 3px rgba(77,159,255,0.16)}
        .pr-btn{transition:transform .18s ease, box-shadow .18s ease, filter .18s ease}
        .pr-btn:hover:not(:disabled){transform:translateY(-1px);filter:brightness(1.07)}
        .pr-btn:active:not(:disabled){transform:translateY(0)}
        a:focus-visible, button:focus-visible{outline:2px solid ${T.cyan};outline-offset:2px}
        .auth-mobile-bar{display:none}
        @media (max-width: 860px){
          .auth-left-panel, .auth-step-rail{display:none !important}
          .auth-mobile-bar{display:flex !important}
          .auth-row{flex-direction:column !important}
          .auth-form-area{padding:20px 16px 48px !important}
        }
        @media (prefers-reduced-motion: reduce){
          *{animation:none !important;transition:none !important}
        }
      `}</style>

      {/* ── Ambient background: OMR bubble-grid texture + soft glow blobs (fixed, decorative) ── */}
      <div aria-hidden style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none', opacity: 0.55, backgroundImage: 'radial-gradient(rgba(77,159,255,0.14) 1px, transparent 1.5px)', backgroundSize: '26px 26px' }} />
      <div aria-hidden style={{ position: 'fixed', top: '-12%', left: '-10%', width: '48%', height: '48%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(77,159,255,0.20), transparent 70%)', filter: 'blur(60px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite' }} />
      <div aria-hidden style={{ position: 'fixed', bottom: '-16%', right: '-10%', width: '52%', height: '52%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(0,212,255,0.16), transparent 70%)', filter: 'blur(70px)', zIndex: 0, pointerEvents: 'none', animation: 'bgPulse 9s ease-in-out infinite 3s' }} />

      {/* Mobile sticky top bar — logo + step dots */}
      <div className="auth-mobile-bar" style={{ position: 'sticky', top: 0, zIndex: 30, height: 54, alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', background: 'rgba(0,8,16,0.92)', backdropFilter: 'blur(16px)', borderBottom: `1px solid ${T.cardBorder}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite' }}><PRLogo size={24} /></div>
          <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, color: T.pri }}>ProveRank</span>
        </div>
        {hasSteps && (
          <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
            {steps.map((_, i) => (
              <div key={i} style={{ width: i === current ? 16 : 6, height: 6, borderRadius: 3, background: i <= current ? `linear-gradient(90deg,${T.pri},${T.cyan})` : 'rgba(107,139,175,0.28)', transition: 'all .3s' }} />
            ))}
          </div>
        )}
      </div>

      {/* Desktop: 3-column row — branding | step rail | form */}
      <div className="auth-row" style={{ display: 'flex', minHeight: '100vh', position: 'relative', zIndex: 1 }}>

        <div className="auth-left-panel" style={{ width: 236, flexShrink: 0, background: T.panel, borderRight: `1px solid ${T.cardBorder}`, padding: '38px 22px', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ animation: 'glowPulse 3s ease-in-out infinite', width: 'fit-content' }}>
            <PRLogo size={38} />
          </div>
          <div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 21, fontWeight: 700, color: T.txt, lineHeight: 1.25, letterSpacing: 0.2 }}>ProveRank</div>
            <div style={{ fontSize: 11, color: T.pri, marginTop: 3, fontWeight: 600, letterSpacing: 0.5 }}>Rise to the Top</div>
          </div>

          {/* Eyebrow — multi-exam positioning */}
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, width: 'fit-content', padding: '4px 10px', borderRadius: 20, background: 'rgba(0,212,255,0.08)', border: '1px solid rgba(0,212,255,0.3)' }}>
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: T.cyan, boxShadow: `0 0 6px ${T.cyan}` }} />
            <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: 0.8, color: T.cyan, textTransform: 'uppercase' }}>Multi-Exam Platform</span>
          </div>

          {/* Signature — radar ring of competitive exams */}
          <div style={{ position: 'relative', width: 132, height: 132, margin: '6px auto 2px' }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'conic-gradient(from 0deg, rgba(0,212,255,0.4), transparent 28%, transparent 100%)', animation: 'radarSpin 7s linear infinite', filter: 'blur(1px)' }} />
            <div style={{ position: 'absolute', inset: 14, borderRadius: '50%', border: '1px dashed rgba(77,159,255,0.3)' }} />
            <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', animation: 'glowPulse 3s ease-in-out infinite' }}>
              <PRLogo size={26} />
            </div>
            {EXAM_BADGES.map((b, i) => {
              const angle = -90 + i * 60
              return (
                <div key={b} style={{
                  position: 'absolute', top: '50%', left: '50%',
                  transform: `rotate(${angle}deg) translate(52px) rotate(${-angle}deg) translate(-50%,-50%)`,
                  fontSize: 8.5, fontWeight: 800, letterSpacing: 0.3, padding: '3px 6px', borderRadius: 20,
                  background: 'rgba(0,10,22,0.92)', border: '1px solid rgba(77,159,255,0.4)', color: '#8FC3FF',
                  whiteSpace: 'nowrap', animation: `badgeFade .5s ease ${i * 0.08}s backwards`,
                }}>{b}</div>
              )
            })}
          </div>

          <div style={{ height: 1, background: T.cardBorder, margin: '2px 0' }} />
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
              <span style={{ width: 24, height: 24, borderRadius: 7, background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, flexShrink: 0 }}>{ic}</span>
              <span style={{ fontSize: 11, color: T.txt, fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>

        {hasSteps && (
          <div className="auth-step-rail" style={{ width: 168, flexShrink: 0, padding: '38px 16px', display: 'flex', flexDirection: 'column', gap: 4, borderRight: `1px solid ${T.cardBorder}` }}>
            {steps.map((s, i) => {
              const active = i === current, done = i < current
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 8px', borderRadius: 10, background: active ? 'rgba(77,159,255,0.1)' : 'transparent' }}>
                  <div style={{
                    width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, flexShrink: 0,
                    background: done ? `linear-gradient(135deg,${T.pri},${T.cyan})` : active ? 'rgba(77,159,255,0.2)' : 'rgba(107,139,175,0.1)',
                    color: done ? T.dark : active ? T.pri : T.sub,
                    border: active ? `1.5px solid ${T.pri}` : '1px solid rgba(107,139,175,0.25)',
                  }}>
                    {done ? '✓' : i + 1}
                  </div>
                  <span style={{ fontSize: 11, color: active ? T.txt : T.sub, fontWeight: active ? 700 : 400 }}>{s.label}</span>
                </div>
              )
            })}
          </div>
        )}

        <div className="auth-form-area" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '44px 20px', overflowY: 'auto' }}>
          <div style={{ width: '100%', maxWidth: 420, animation: 'fadeIn .5s ease' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
