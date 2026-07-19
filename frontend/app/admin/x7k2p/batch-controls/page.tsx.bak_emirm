'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; examType: string; price: number; discountPrice: number;
  isFree: boolean; isSpotlight: boolean; flashSalePrice?: number; flashSaleEndTime?: string;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; allowEMI: boolean;
  enrolledCount: number; rating: number; status: string;
}
type Review = {
  _id: string; batchId: string; studentName: string; rating: number; comment: string;
  status: string; createdAt: string;
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60', 'Class 11': '#E67E22',
  'Class 12': '#E74C3C', Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

function ToggleSwitch({ on, onToggle, loading }: { on: boolean; onToggle: () => void; loading?: boolean }) {
  return (
    <div onClick={!loading ? onToggle : undefined}
      style={{ width: 44, height: 24, borderRadius: 12, background: on ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(255,255,255,0.08)', border: `1px solid ${on ? '#4D9FFF' : 'rgba(255,255,255,0.14)'}`, cursor: loading ? 'wait' : 'pointer', position: 'relative', transition: 'all 0.3s', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: 2, left: on ? 22 : 2, width: 18, height: 18, borderRadius: '50%', background: on ? '#fff' : 'rgba(255,255,255,0.3)', transition: 'left 0.3s', boxShadow: on ? '0 2px 8px rgba(77,159,255,0.5)' : 'none' }} />
    </div>
  )
}

export default function BatchControlsPage() {
  const router  = useRouter()
  const [tok, setTok]           = useState('')
  const [batches, setBatches]   = useState<Batch[]>([])
  const [reviews, setReviews]   = useState<Review[]>([])
  const [loading, setLoading]   = useState(true)
  const [activeTab, setActiveTab] = useState<'controls' | 'reviews' | 'flashsale'>('controls')
  const [toggling, setToggling] = useState<string | null>(null)
  const [toast, setToast]       = useState('')
  // Flash sale form
  const [fsId, setFsId]         = useState('')
  const [fsPrice, setFsPrice]   = useState('')
  const [fsEnd, setFsEnd]       = useState('')
  // Notify price drop
  const [notifying, setNotifying] = useState<string | null>(null)

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000) }

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t); fetchAll(t)
  }, [])

  const fetchAll = async (t: string) => {
    setLoading(true)
    try {
      const [bRes, rRes] = await Promise.all([
        fetch(`${API}/api/admin/batch-controls`, { headers: { Authorization: `Bearer ${t}` } }),
        fetch(`${API}/api/admin/batch-controls/reviews?status=pending`, { headers: { Authorization: `Bearer ${t}` } }),
      ])
      const bd = await bRes.json(); const rd = await rRes.json()
      setBatches(bd.batches || [])
      setReviews(rd.reviews || [])
    } catch { } finally { setLoading(false) }
  }

  const toggle = async (id: string, action: string, body?: object) => {
    setToggling(id + action)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/${action}`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined
      })
      const d = await r.json()
      if (d.success) { showToast('Updated ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error ❌')
    } catch { showToast('Network error ❌') } finally { setToggling(null) }
  }

  const setFlashSale = async () => {
    if (!fsId || !fsPrice || !fsEnd) return showToast('Fill all flash sale fields')
    await toggle(fsId, 'flashsale', { flashSalePrice: Number(fsPrice), flashSaleEndTime: fsEnd })
    setFsId(''); setFsPrice(''); setFsEnd('')
  }

  const removeFlashSale = async (id: string) => {
    await toggle(id, 'flashsale', { remove: true })
  }

  const approveReview = async (rid: string) => {
    setToggling(rid)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}/approve`, { method: 'PUT', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review approved ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error')
    } finally { setToggling(null) }
  }

  const rejectReview = async (rid: string) => {
    setToggling(rid + 'r')
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}`, { method: 'DELETE', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review rejected'); fetchAll(tok) }
    } finally { setToggling(null) }
  }

  const notifyPriceDrop = async (id: string) => {
    setNotifying(id)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/price-drop-notify`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) showToast(`📣 ${d.notified} wishlisted users notified!`)
      else showToast(d.error || 'Error')
    } finally { setNotifying(null) }
  }

  const inp = { padding: '9px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(77,159,255,0.18)', borderRadius: 10, color: '#F0F8FF', fontSize: 12, outline: 'none' }
  const btn = (col: string) => ({ padding: '9px 16px', background: `linear-gradient(135deg,${col},${col}BB)`, border: 'none', borderRadius: 10, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 })

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(135deg,#020816 0%,#030c1a 100%)', color: '#F0F8FF', fontFamily: 'Inter,sans-serif', padding: '0 0 60px' }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap'); *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px} input,select{outline:none}`}</style>

      {/* TOAST */}
      {toast && (
        <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 9999, background: 'rgba(4,12,30,0.98)', border: '1px solid rgba(77,159,255,0.3)', borderRadius: 12, padding: '12px 24px', fontSize: 13, fontWeight: 600, boxShadow: '0 8px 40px rgba(0,0,0,0.5)', backdropFilter: 'blur(20px)', whiteSpace: 'nowrap' }}>{toast}</div>
      )}

      {/* HEADER */}
      <div style={{ background: 'rgba(2,8,22,0.96)', backdropFilter: 'blur(22px)', borderBottom: '1px solid rgba(77,159,255,0.1)', padding: '14px 20px', display: 'flex', alignItems: 'center', gap: 12, position: 'sticky', top: 0, zIndex: 50 }}>
        <button onClick={() => router.push('/admin/x7k2p')} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20 }}>←</button>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚙️ Batch Controls</div>
          <div style={{ fontSize: 11, color: 'rgba(160,200,240,0.42)' }}>Spotlight · Flash Sale · Bundle · Trial · EMI · Reviews · Price Drop</div>
        </div>
        <div style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(160,200,240,0.45)' }}>{batches.length} batches · {reviews.length} pending reviews</div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 16px' }}>

        {/* TABS */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {(['controls', 'flashsale', 'reviews'] as const).map(t => (
            <button key={t} onClick={() => setActiveTab(t)} style={{ padding: '9px 18px', borderRadius: 12, background: activeTab === t ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.07)', border: 'none', color: activeTab === t ? '#fff' : 'rgba(160,200,240,0.5)', fontWeight: activeTab === t ? 700 : 400, cursor: 'pointer', fontSize: 11 }}>
              {t === 'controls' ? '🔧 Batch Toggles' : t === 'flashsale' ? '⚡ Flash Sale' : `⭐ Reviews (${reviews.length})`}
            </button>
          ))}
        </div>

        {/* ── TAB: BATCH TOGGLES ── */}
        {activeTab === 'controls' && (
          <div>
            {loading ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>Loading batches...</div>
            ) : batches.length === 0 ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>No batches found. Create batches from the main Admin Panel first.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {batches.map(b => {
                  const ec = ECOLS[b.examType] || '#4D9FFF'
                  const isFlashActive = !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date())
                  return (
                    <div key={b._id} style={{ background: 'rgba(4,12,30,0.95)', border: `1px solid ${ec}18`, borderRadius: 18, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14, flexWrap: 'wrap' }}>
                        <div style={{ width: 38, height: 38, borderRadius: 10, background: `${ec}18`, border: `1px solid ${ec}28`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 }}>
                          {b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : '📚'}
                        </div>
                        <div style={{ flex: 1, minWidth: 120 }}>
                          <div style={{ fontWeight: 700, fontSize: 13, color: '#F0F8FF', fontFamily: 'Playfair Display,serif' }}>{b.name}</div>
                          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginTop: 2 }}>
                            <span style={{ color: ec }}>{b.examType}</span> · {b.isFree ? 'Free' : `₹${b.discountPrice || b.price}`} · {b.enrolledCount} enrolled · ⭐ {b.rating}
                          </div>
                        </div>
                        {isFlashActive && <span style={{ fontSize: 9, background: 'rgba(231,76,60,0.18)', color: '#E74C3C', padding: '3px 10px', borderRadius: 20, fontWeight: 700 }}>⚡ FLASH ACTIVE</span>}
                        <button onClick={() => notifyPriceDrop(b._id)} disabled={notifying === b._id}
                          style={{ padding: '6px 12px', background: 'rgba(255,215,0,0.08)', border: '1px solid rgba(255,215,0,0.2)', borderRadius: 8, color: '#FFD700', cursor: 'pointer', fontSize: 10, fontWeight: 600, whiteSpace: 'nowrap' }}>
                          {notifying === b._id ? '...' : '📣 Notify Price Drop'}
                        </button>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
                        {[
                          { label: '⭐ Spotlight', desc: 'Show in featured section', key: 'spotlight', val: b.isSpotlight },
                          { label: '📦 Bundle', desc: 'Mark as bundle product', key: 'bundle', val: b.isBundle },
                          { label: '🎯 Free Trial', desc: `${b.trialDays}-day trial access`, key: 'trial', val: b.allowFreeTrial },
                          { label: '💳 EMI', desc: 'Show EMI badge & option', key: 'emi', val: b.allowEMI },
                          { label: '⚡ Remove Flash', desc: 'Clear active flash sale', key: 'flashsale_remove', val: isFlashActive },
                        ].map(ctrl => (
                          <div key={ctrl.key} style={{ background: 'rgba(255,255,255,0.03)', border: `1px solid ${ctrl.val ? ec + '30' : 'rgba(255,255,255,0.06)'}`, borderRadius: 12, padding: '11px 13px', display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'space-between' }}>
                            <div>
                              <div style={{ fontSize: 11, fontWeight: 700, color: ctrl.val ? '#F0F8FF' : 'rgba(160,200,240,0.5)' }}>{ctrl.label}</div>
                              <div style={{ fontSize: 9, color: 'rgba(160,200,240,0.35)', marginTop: 2 }}>{ctrl.desc}</div>
                            </div>
                            {ctrl.key === 'flashsale_remove' ? (
                              <button onClick={() => removeFlashSale(b._id)} disabled={!isFlashActive || toggling === b._id + 'flashsale'}
                                style={{ padding: '5px 10px', background: isFlashActive ? 'rgba(231,76,60,0.15)' : 'rgba(255,255,255,0.04)', border: `1px solid ${isFlashActive ? 'rgba(231,76,60,0.3)' : 'rgba(255,255,255,0.08)'}`, borderRadius: 8, color: isFlashActive ? '#E74C3C' : 'rgba(160,200,240,0.25)', cursor: isFlashActive ? 'pointer' : 'not-allowed', fontSize: 9, fontWeight: 700 }}>
                                Remove
                              </button>
                            ) : (
                              <ToggleSwitch on={ctrl.val as boolean} loading={toggling === b._id + ctrl.key} onToggle={() => toggle(b._id, ctrl.key)} />
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}

        {/* ── TAB: FLASH SALE ── */}
        {activeTab === 'flashsale' && (
          <div>
            <div style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 20, padding: '22px 20px', marginBottom: 22, backdropFilter: 'blur(20px)' }}>
              <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF', marginBottom: 18 }}>⚡ Set Flash Sale</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 12, marginBottom: 14 }}>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Select Batch</div>
                  <select value={fsId} onChange={e => setFsId(e.target.value)} style={{ ...inp, width: '100%' }}>
                    <option value="">Choose batch...</option>
                    {batches.filter(b => !b.isFree).map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Flash Price (₹)</div>
                  <input type="number" value={fsPrice} onChange={e => setFsPrice(e.target.value)} placeholder="e.g. 299" style={{ ...inp, width: '100%' }} />
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>End Date & Time</div>
                  <input type="datetime-local" value={fsEnd} onChange={e => setFsEnd(e.target.value)} style={{ ...inp, width: '100%' }} />
                </div>
              </div>
              <button onClick={setFlashSale} style={btn('#E74C3C')}>⚡ Set Flash Sale</button>
            </div>
            {/* Active flash sales */}
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: '#F0F8FF', marginBottom: 14 }}>Active Flash Sales</div>
            {batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).length === 0
              ? <div style={{ color: 'rgba(160,200,240,0.4)', fontSize: 12, padding: '20px 0' }}>No active flash sales.</div>
              : batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).map(b => (
                <div key={b._id} style={{ background: 'rgba(231,76,60,0.06)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 14, padding: '14px 16px', marginBottom: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{b.name}</div>
                    <div style={{ fontSize: 11, color: '#E74C3C', marginTop: 3 }}>⚡ ₹{b.flashSalePrice} · Ends {new Date(b.flashSaleEndTime!).toLocaleString()}</div>
                  </div>
                  <button onClick={() => removeFlashSale(b._id)} style={{ padding: '7px 14px', background: 'rgba(231,76,60,0.12)', border: '1px solid rgba(231,76,60,0.25)', borderRadius: 8, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>Remove</button>
                </div>
              ))
            }
          </div>
        )}

        {/* ── TAB: REVIEWS ── */}
        {activeTab === 'reviews' && (
          <div>
            {reviews.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 0', color: 'rgba(160,200,240,0.4)', fontSize: 13 }}>✅ No pending reviews</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {reviews.map(rv => (
                  <div key={rv._id} style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(255,215,0,0.12)', borderRadius: 16, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, justifyContent: 'space-between', flexWrap: 'wrap' }}>
                      <div style={{ flex: 1, minWidth: 160 }}>
                        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 6 }}>
                          <span style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{rv.studentName}</span>
                          <span style={{ display: 'inline-flex', gap: 1 }}>{[1,2,3,4,5].map(i => <span key={i} style={{ color: i <= rv.rating ? '#FFD700' : 'rgba(255,215,0,0.15)', fontSize: 12 }}>★</span>)}</span>
                        </div>
                        {rv.comment && <div style={{ fontSize: 12, color: 'rgba(180,210,240,0.65)', lineHeight: 1.6, marginBottom: 6 }}>"{rv.comment}"</div>}
                        <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.35)' }}>{new Date(rv.createdAt).toLocaleDateString()}</div>
                      </div>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button onClick={() => approveReview(rv._id)} disabled={toggling === rv._id}
                          style={{ padding: '8px 14px', background: 'rgba(39,174,96,0.12)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 10, color: '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id ? '...' : '✅ Approve'}
                        </button>
                        <button onClick={() => rejectReview(rv._id)} disabled={toggling === rv._id + 'r'}
                          style={{ padding: '8px 14px', background: 'rgba(231,76,60,0.08)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id + 'r' ? '...' : '❌ Reject'}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  )
}
