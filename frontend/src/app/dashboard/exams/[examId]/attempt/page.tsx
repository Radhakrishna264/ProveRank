'use client';
import { useEffect, useState, useCallback, useRef } from 'react';
import { useParams, useSearchParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

/* ── Types ── */
interface Question {
  _id: string;
  questionText: string;
  options: { label: string; text: string }[];
  subject?: string;
  chapter?: string;
  imageUrl?: string;
  type?: string;
}
interface Attempt {
  _id: string;
  totalDurationSec: number;
  elapsedSec: number;
  remainingSec: number;
  questions?: Question[];
  studentName?: string;
  studentId?: string;
  examTitle?: string;
}
type QStatus = 'not-visited' | 'not-answered' | 'answered' | 'marked';

export default function ExamAttemptPage() {
  const { examId } = useParams<{ examId: string }>();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get('attemptId') || '';
  const router = useRouter();
  const token = getToken();

  const [attempt, setAttempt] = useState<Attempt | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [statuses, setStatuses] = useState<Record<string, QStatus>>({});
  const [bookmarks, setBookmarks] = useState<Record<string, boolean>>({});
  const [timeLeft, setTimeLeft] = useState(0);
  const [warnings, setWarnings] = useState(0);
  const [showWarning, setShowWarning] = useState(false);
  const [warningMsg, setWarningMsg] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [section, setSection] = useState('All');
  const [studentName, setStudentName] = useState('');
  const [showSubmitConfirm, setShowSubmitConfirm] = useState(false);
  const autoSaveRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastSavedRef = useRef<Record<string, string>>({});

  const sections = ['All', 'Physics', 'Chemistry', 'Biology'];

  /* ── Load attempt ── */
  useEffect(() => {
    if (!token || !attemptId) { router.push('/dashboard/exams'); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      const att = d.attempt || d;
      setAttempt(att);
      setTimeLeft(att.remainingSec || att.totalDurationSec || 10800);
      setStudentName(att.studentName || 'Student');
      const qs: Question[] = att.questions || att.exam?.questions || [];
      setQuestions(qs);
      const initStatus: Record<string, QStatus> = {};
      qs.forEach((q: Question) => { initStatus[q._id] = 'not-visited'; });
      setStatuses(initStatus);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [attemptId, token, router]);

  /* ── S32: Fullscreen enforcement ── */
  useEffect(() => {
    const enterFS = () => { document.documentElement.requestFullscreen?.(); };
    enterFS();
    const handleFSChange = () => {
      if (!document.fullscreenElement) { triggerWarning('fullscreen'); }
    };
    const handleVisibility = () => {
      if (document.hidden) { triggerWarning('tab-switch'); }
    };
    const handleBlur = () => { triggerWarning('window-blur'); };
    document.addEventListener('fullscreenchange', handleFSChange);
    document.addEventListener('visibilitychange', handleVisibility);
    window.addEventListener('blur', handleBlur);
    return () => {
      document.removeEventListener('fullscreenchange', handleFSChange);
      document.removeEventListener('visibilitychange', handleVisibility);
      window.removeEventListener('blur', handleBlur);
    };
  }, []);

  const triggerWarning = useCallback((type: string) => {
    setWarnings(w => {
      const next = w + 1;
      const msgs: Record<string, string> = {
        'fullscreen': '⚠️ Fullscreen exit detected!',
        'tab-switch': '⚠️ Tab switch detected!',
        'window-blur': '⚠️ Window focus lost!',
      };
      setWarningMsg(`${msgs[type] || '⚠️ Suspicious activity!'} Warning ${next}/3`);
      setShowWarning(true);
      setTimeout(() => setShowWarning(false), 3000);
      if (next >= 3) { setTimeout(() => handleAutoSubmit(), 1000); }
      // Report to backend
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/warning`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token || ''}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ type, warningCount: next }),
      }).catch(() => {});
      return next;
    });
  }, [attemptId, token]);

  /* ── Timer countdown ── */
  useEffect(() => {
    if (timeLeft <= 0) return;
    timerRef.current = setInterval(() => {
      setTimeLeft(t => {
        if (t <= 1) { clearInterval(timerRef.current!); handleAutoSubmit(); return 0; }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(timerRef.current!);
  }, [timeLeft > 0]);

  /* ── Auto-save every 30 sec ── */
  useEffect(() => {
    autoSaveRef.current = setInterval(() => {
      const changed = Object.entries(answers).filter(([k, v]) => lastSavedRef.current[k] !== v);
      if (changed.length === 0) return;
      setSaving(true);
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/auto-save`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token || ''}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ answers }),
      }).then(() => {
        lastSavedRef.current = { ...answers };
        setSaving(false);
      }).catch(() => setSaving(false));
    }, 30000);
    return () => clearInterval(autoSaveRef.current!);
  }, [answers, attemptId, token]);

  /* ── Save single answer ── */
  const saveAnswer = async (qId: string, answer: string) => {
    await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/save-answer`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token || ''}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ questionId: qId, answer }),
    }).catch(() => {});
  };

  const handleAnswer = (qId: string, opt: string) => {
    const same = answers[qId] === opt;
    const newAns = { ...answers };
    const newStat = { ...statuses };
    if (same) {
      delete newAns[qId];
      newStat[qId] = 'not-answered';
    } else {
      newAns[qId] = opt;
      newStat[qId] = 'answered';
    }
    setAnswers(newAns);
    setStatuses(newStat);
    saveAnswer(qId, same ? '' : opt);
  };

  const handleNav = (idx: number) => {
    const q = filteredQs[currentIdx];
    if (q && statuses[q._id] === 'not-visited') {
      setStatuses(p => ({ ...p, [q._id]: 'not-answered' }));
    }
    setCurrentIdx(idx);
    const next = filteredQs[idx];
    if (next && statuses[next._id] === 'not-visited') {
      setStatuses(p => ({ ...p, [next._id]: 'not-answered' }));
    }
  };

  const toggleBookmark = (qId: string) => {
    setBookmarks(b => ({ ...b, [qId]: !b[qId] }));
    setStatuses(p => ({
      ...p,
      [qId]: p[qId] === 'marked' ? (answers[qId] ? 'answered' : 'not-answered') : 'marked',
    }));
  };

  const handleAutoSubmit = () => {
    router.push(`/dashboard/exams/${examId}/submit?attemptId=${attemptId}&auto=true`);
  };

  const filteredQs = section === 'All' ? questions : questions.filter(q => q.subject?.toLowerCase() === section.toLowerCase());
  const currentQ = filteredQs[currentIdx];

  // Timer color
  const pct = attempt ? (timeLeft / (attempt.totalDurationSec || 10800)) * 100 : 100;
  const timerColor = pct > 50 ? '#22C55E' : pct > 20 ? '#F59E0B' : '#EF4444';
  const mm = String(Math.floor(timeLeft / 60)).padStart(2, '0');
  const ss = String(timeLeft % 60).padStart(2, '0');
  const hh = String(Math.floor(timeLeft / 3600)).padStart(2, '0');

  // N1 color coding
  const statusColor: Record<QStatus, string> = {
    'not-visited': '#6B8FAF',
    'not-answered': '#EF4444',
    'answered': '#22C55E',
    'marked': '#A855F7',
  };

  const answered = Object.values(statuses).filter(s => s === 'answered').length;
  const notAnswered = Object.values(statuses).filter(s => s === 'not-answered').length;
  const marked = Object.values(statuses).filter(s => s === 'marked').length;
  const notVisited = Object.values(statuses).filter(s => s === 'not-visited').length;

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'#f8fafc', fontSize:18, color:'#334155' }}>
      ⟳ Loading exam...
    </div>
  );

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100vh', background:'#F8FAFC', fontFamily:'Inter,sans-serif', position:'relative', overflow:'hidden' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: #f1f5f9; }
        ::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 2px; }
        @keyframes slideDown { from{transform:translateY(-100%);opacity:0} to{transform:translateY(0);opacity:1} }
        @keyframes pulse { 0%,100%{opacity:1}50%{opacity:0.5} }
        .nav-btn { width:32px;height:32px;border-radius:6px;border:none;cursor:pointer;font-size:12px;font-weight:600;transition:all 0.15s; }
        .nav-btn:hover { transform:scale(1.1); }
        .opt-btn { display:flex;align-items:center;gap:14px;padding:14px 18px;border-radius:10px;border:2px solid #E2E8F0;background:white;cursor:pointer;margin-bottom:10px;transition:all 0.2s;text-align:left;width:100%; }
        .opt-btn:hover { border-color:#4D9FFF;background:#EFF6FF; }
        .opt-btn.selected { border-color:#4D9FFF;background:#EFF6FF; }
        .bubble { width:28px;height:28px;border-radius:50%;border:2px solid #94A3B8;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;flex-shrink:0;transition:all 0.2s; }
        .bubble.selected { background:#4D9FFF;border-color:#4D9FFF;color:white; }
      `}</style>

      {/* ── S76: Student Watermark ── */}
      <div style={{ position:'fixed', inset:0, pointerEvents:'none', zIndex:999, display:'flex', alignItems:'center', justifyContent:'center', transform:'rotate(-30deg)', opacity:0.04, fontSize:28, fontWeight:700, color:'#000', letterSpacing:4, whiteSpace:'nowrap' }}>
        {studentName} &nbsp;&nbsp;&nbsp; {studentName} &nbsp;&nbsp;&nbsp; {studentName}
      </div>

      {/* ── Warning Banner (S32) ── */}
      {showWarning && (
        <div style={{ position:'fixed', top:0, left:0, right:0, background:'#EF4444', color:'white', padding:'12px 24px', textAlign:'center', fontWeight:700, fontSize:14, zIndex:9999, animation:'slideDown 0.3s ease' }}>
          {warningMsg} — {3 - warnings} warnings remaining before auto-submit!
        </div>
      )}

      {/* ══ TOP HEADER — T2 Timer + Exam Info ══ */}
      <header style={{ background:'white', borderBottom:'1px solid #E2E8F0', padding:'0 16px', flexShrink:0 }}>
        {/* T2: Progress bar timer */}
        <div style={{ height:5, background:'#F1F5F9', position:'relative' }}>
          <div style={{ height:'100%', width:`${pct}%`, background:timerColor, transition:'width 1s linear, background 1s ease', borderRadius:'0 3px 3px 0' }}/>
        </div>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', height:52 }}>
          {/* Exam title */}
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:15, fontWeight:700, color:'#0F172A', maxWidth:260, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>
            {attempt?.examTitle || 'NEET Exam'}
          </div>
          {/* Timer display */}
          <div style={{ display:'flex', alignItems:'center', gap:10 }}>
            {saving && <span style={{ fontSize:11, color:'#94A3B8', animation:'pulse 1s infinite' }}>💾 Saving...</span>}
            <div style={{ background: pct > 50 ? '#F0FDF4' : pct > 20 ? '#FFFBEB' : '#FEF2F2', border:`2px solid ${timerColor}`, borderRadius:10, padding:'6px 14px', display:'flex', alignItems:'center', gap:6 }}>
              <span style={{ fontSize:11, color:timerColor }}>⏱</span>
              <span style={{ fontSize:18, fontWeight:700, color:timerColor, fontVariantNumeric:'tabular-nums' }}>
                {hh}:{mm}:{ss}
              </span>
            </div>
            <button
              onClick={() => setShowSubmitConfirm(true)}
              style={{ background:'#EF4444', color:'white', border:'none', borderRadius:8, padding:'8px 16px', fontSize:13, fontWeight:700, cursor:'pointer' }}>
              Submit
            </button>
          </div>
        </div>
      </header>

      {/* ══ MAIN 3-ZONE LAYOUT (L1) ══ */}
      <div style={{ display:'flex', flex:1, overflow:'hidden' }}>

        {/* ── LEFT PANEL — N1: Colour-Coded Grid ── */}
        <aside style={{ width:220, background:'white', borderRight:'1px solid #E2E8F0', display:'flex', flexDirection:'column', flexShrink:0, overflow:'hidden' }}>
          {/* Legend */}
          <div style={{ padding:'10px 12px', borderBottom:'1px solid #F1F5F9', display:'flex', flexWrap:'wrap', gap:6 }}>
            {[
              { color:'#22C55E', label:`✓ ${answered}` },
              { color:'#EF4444', label:`✕ ${notAnswered}` },
              { color:'#A855F7', label:`🔖 ${marked}` },
              { color:'#6B8FAF', label:`□ ${notVisited}` },
            ].map(({ color, label }) => (
              <div key={label} style={{ display:'flex', alignItems:'center', gap:4, fontSize:11, color:'#475569' }}>
                <div style={{ width:10, height:10, borderRadius:2, background:color }}/>
                {label}
              </div>
            ))}
          </div>
          {/* Section filter */}
          <div style={{ padding:'8px 10px', borderBottom:'1px solid #F1F5F9', display:'flex', gap:4, flexWrap:'wrap' }}>
            {sections.map(sec => (
              <button key={sec} onClick={() => { setSection(sec); setCurrentIdx(0); }}
                style={{ fontSize:10, padding:'3px 8px', borderRadius:20, border:'1px solid', borderColor: section === sec ? '#4D9FFF' : '#E2E8F0', background: section === sec ? '#EFF6FF' : 'white', color: section === sec ? '#4D9FFF' : '#64748B', cursor:'pointer', fontWeight: section === sec ? 600 : 400 }}>
                {sec}
              </button>
            ))}
          </div>
          {/* Grid */}
          <div style={{ padding:10, display:'grid', gridTemplateColumns:'repeat(5,1fr)', gap:5, overflowY:'auto', flex:1 }}>
            {filteredQs.map((q, i) => (
              <button key={q._id} className="nav-btn"
                onClick={() => handleNav(i)}
                style={{ background: i === currentIdx ? '#1D4ED8' : statusColor[statuses[q._id] || 'not-visited'], color:'white', position:'relative' }}>
                {i + 1}
                {bookmarks[q._id] && <span style={{ position:'absolute', top:0, right:0, fontSize:7 }}>🔖</span>}
              </button>
            ))}
          </div>
        </aside>

        {/* ── RIGHT PANEL — Q1: Question + A1: Options ── */}
        <main style={{ flex:1, overflowY:'auto', padding:24, display:'flex', flexDirection:'column', gap:20 }}>
          {/* Section tabs — Q1 */}
          <div style={{ display:'flex', gap:8 }}>
            {['Physics', 'Chemistry', 'Biology'].map(s => (
              <button key={s} onClick={() => { setSection(s); setCurrentIdx(0); }}
                style={{ padding:'6px 16px', borderRadius:20, border:'2px solid', borderColor: currentQ?.subject?.toLowerCase() === s.toLowerCase() ? '#4D9FFF' : '#E2E8F0', background: currentQ?.subject?.toLowerCase() === s.toLowerCase() ? '#EFF6FF' : 'white', color: currentQ?.subject?.toLowerCase() === s.toLowerCase() ? '#4D9FFF' : '#64748B', fontSize:13, fontWeight:600, cursor:'pointer' }}>
                {s}
              </button>
            ))}
          </div>

          {currentQ ? (
            <>
              {/* Q1: Question Card */}
              <div style={{ background:'white', borderRadius:14, padding:24, boxShadow:'0 2px 12px rgba(0,0,0,0.06)', border:'1px solid #F1F5F9' }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:16 }}>
                  <div style={{ display:'flex', gap:10, alignItems:'center' }}>
                    <span style={{ background:'#EFF6FF', color:'#4D9FFF', fontSize:12, fontWeight:700, padding:'3px 10px', borderRadius:20 }}>Q {currentIdx + 1}</span>
                    <span style={{ background:'#F0FDF4', color:'#16A34A', fontSize:11, padding:'3px 8px', borderRadius:20 }}>+4</span>
                    <span style={{ background:'#FEF2F2', color:'#DC2626', fontSize:11, padding:'3px 8px', borderRadius:20 }}>-1</span>
                  </div>
                  {/* S1: Bookmark */}
                  <button onClick={() => toggleBookmark(currentQ._id)}
                    style={{ background: bookmarks[currentQ._id] ? '#FEF9C3' : '#F8FAFC', border:'1px solid', borderColor: bookmarks[currentQ._id] ? '#EAB308' : '#E2E8F0', borderRadius:8, padding:'6px 12px', cursor:'pointer', fontSize:12, fontWeight:600, color: bookmarks[currentQ._id] ? '#B45309' : '#64748B' }}>
                    {bookmarks[currentQ._id] ? '🔖 Marked' : '🔖 Mark for Review'}
                  </button>
                </div>

                {/* Question text */}
                <div style={{ fontSize:15, lineHeight:1.8, color:'#0F172A', marginBottom:20, fontWeight:500 }}>
                  {currentQ.questionText}
                </div>

                {/* Image support (S33) */}
                {currentQ.imageUrl && (
                  <img src={currentQ.imageUrl} alt="question" style={{ maxWidth:'100%', borderRadius:8, marginBottom:16, border:'1px solid #E2E8F0' }}/>
                )}

                {/* A1: OMR Bubble Options */}
                <div>
                  {(currentQ.options || []).map((opt) => {
                    const isSelected = answers[currentQ._id] === opt.label;
                    return (
                      <button key={opt.label} className={`opt-btn${isSelected ? ' selected' : ''}`}
                        onClick={() => handleAnswer(currentQ._id, opt.label)}>
                        <div className={`bubble${isSelected ? ' selected' : ''}`}>{opt.label}</div>
                        <span style={{ fontSize:14, color:'#334155', lineHeight:1.5 }}>{opt.text}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Navigation buttons */}
              <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <button onClick={() => handleNav(Math.max(0, currentIdx - 1))} disabled={currentIdx === 0}
                  style={{ background: currentIdx === 0 ? '#F1F5F9' : '#EFF6FF', color: currentIdx === 0 ? '#94A3B8' : '#4D9FFF', border:'1px solid', borderColor: currentIdx === 0 ? '#E2E8F0' : '#4D9FFF', borderRadius:8, padding:'10px 20px', cursor: currentIdx === 0 ? 'not-allowed' : 'pointer', fontWeight:600, fontSize:13 }}>
                  ← Previous
                </button>
                <span style={{ fontSize:13, color:'#64748B' }}>{currentIdx + 1} / {filteredQs.length}</span>
                <button onClick={() => handleNav(Math.min(filteredQs.length - 1, currentIdx + 1))} disabled={currentIdx === filteredQs.length - 1}
                  style={{ background: currentIdx === filteredQs.length - 1 ? '#F1F5F9' : '#4D9FFF', color: currentIdx === filteredQs.length - 1 ? '#94A3B8' : 'white', border:'none', borderRadius:8, padding:'10px 20px', cursor: currentIdx === filteredQs.length - 1 ? 'not-allowed' : 'pointer', fontWeight:600, fontSize:13 }}>
                  Next →
                </button>
              </div>
            </>
          ) : (
            <div style={{ textAlign:'center', padding:60, color:'#94A3B8' }}>
              <div style={{ fontSize:48, marginBottom:16 }}>📭</div>
              <div>Is section mein koi question nahi</div>
            </div>
          )}
        </main>
      </div>

      {/* ══ Submit Confirm Modal (S2 trigger) ══ */}
      {showSubmitConfirm && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.6)', display:'flex', alignItems:'center', justifyContent:'center', zIndex:9000, padding:20 }}>
          <div style={{ background:'white', borderRadius:16, padding:32, maxWidth:360, width:'100%', textAlign:'center' }}>
            <div style={{ fontSize:40, marginBottom:12 }}>📤</div>
            <div style={{ fontSize:18, fontWeight:700, marginBottom:8 }}>Submit Exam?</div>
            <div style={{ fontSize:14, color:'#64748B', marginBottom:20 }}>
              Answered: <b style={{ color:'#22C55E' }}>{answered}</b> &nbsp;|&nbsp;
              Unanswered: <b style={{ color:'#EF4444' }}>{notAnswered + notVisited}</b> &nbsp;|&nbsp;
              Marked: <b style={{ color:'#A855F7' }}>{marked}</b>
            </div>
            <div style={{ display:'flex', gap:12 }}>
              <button onClick={() => setShowSubmitConfirm(false)}
                style={{ flex:1, padding:'12px', borderRadius:8, border:'1px solid #E2E8F0', background:'white', cursor:'pointer', fontWeight:600, color:'#475569' }}>
                Cancel
              </button>
              <button onClick={() => router.push(`/dashboard/exams/${examId}/submit?attemptId=${attemptId}`)}
                style={{ flex:1, padding:'12px', borderRadius:8, border:'none', background:'#EF4444', color:'white', cursor:'pointer', fontWeight:700 }}>
                Submit Now
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
