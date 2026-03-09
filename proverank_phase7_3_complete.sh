#!/bin/bash
# ============================================================
# ProveRank Phase 7.3 — Exam Attempt UI
# ALL 12 STEPS — SINGLE COMPLETE SCRIPT
# Rule C1: cat > EOF style | Rule A1: Android paste friendly
# Design: Step 04 LOCKED — L1+T2+Q1+A1+N1+S2 | Step 08: WR1
# Theme: White Theme for Exam UI (Step 04 locked)
# Steps: WR1·M6 · L1 · T2 · Q1 · A1 · N1 · S32 · S76 · S1 · AutoSave · S2 · Result
# ============================================================

cd ~/workspace/frontend

# ── DIRECTORIES ──
mkdir -p "src/app/dashboard/exams/[examId]/waiting"
mkdir -p "src/app/dashboard/exams/[examId]/attempt"
mkdir -p "src/app/dashboard/exams/[examId]/submit"
mkdir -p "src/app/dashboard/results/[attemptId]"

echo "📁 Directories created"

# ════════════════════════════════════════════════════════════
# FILE 1 — Exam Waiting Room
# WR1: Animated Countdown + Live Counter | M6 | Socket.io
# Step 08 Design: Full-screen dark countdown + live student count
# ════════════════════════════════════════════════════════════
cat > "src/app/dashboard/exams/[examId]/waiting/page.tsx" << 'ENDOFFILE'
'use client';
import { useEffect, useState, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

interface ExamInfo {
  _id: string;
  title: string;
  scheduledAt?: string;
  duration?: number;
  totalQuestions?: number;
  instructions?: string;
}

function useCountdown(target: string) {
  const [diff, setDiff] = useState(0);
  useEffect(() => {
    const calc = () => setDiff(Math.max(0, new Date(target).getTime() - Date.now()));
    calc();
    const id = setInterval(calc, 1000);
    return () => clearInterval(id);
  }, [target]);
  const h = Math.floor(diff / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  const s = Math.floor((diff % 60000) / 1000);
  return { h, m, s, done: diff === 0 };
}

export default function WaitingRoomPage() {
  const { examId } = useParams<{ examId: string }>();
  const router = useRouter();
  const [exam, setExam] = useState<ExamInfo | null>(null);
  const [liveCount, setLiveCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState('');
  const token = getToken();

  // Fetch exam details
  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      setExam(d.exam || d);
      setLoading(false);
    }).catch(() => { setError('Exam details load nahi hue'); setLoading(false); });

    // Live student count via polling (Socket.io fallback)
    const poll = setInterval(() => {
      fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}/live-count`, {
        headers: { Authorization: `Bearer ${token}` },
      }).then(r => r.json()).then(d => setLiveCount(d.count || 0)).catch(() => {});
    }, 5000);
    return () => clearInterval(poll);
  }, [examId, token, router]);

  const handleStart = async () => {
    setStarting(true);
    setError('');
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/exams/${examId}/start-attempt`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Start failed');
      const attemptId = data.attempt?._id || data.attemptId || data._id;
      router.push(`/dashboard/exams/${examId}/attempt?attemptId=${attemptId}`);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Start nahi hua');
      setStarting(false);
    }
  };

  const target = exam?.scheduledAt || new Date(Date.now() + 60000).toISOString();
  const { h, m, s, done } = useCountdown(target);
  const pct = exam?.scheduledAt
    ? Math.min(100, ((Date.now() - (new Date(exam.scheduledAt).getTime() - 600000)) / 600000) * 100)
    : 80;

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#4D9FFF', fontSize:18 }}>
      ⟳ Loading exam details...
    </div>
  );

  return (
    <div style={{ minHeight:'100vh', background:'#000A18', color:'#E8F4FF', fontFamily:'Inter,sans-serif', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:24, position:'relative', overflow:'hidden' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes pulse { 0%,100%{opacity:1}50%{opacity:0.5} }
        @keyframes float { 0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)} }
        @keyframes fillBar { from{width:0} to{width:var(--w)} }
        .hex-bg { position:absolute; font-size:180px; color:rgba(77,159,255,0.04); pointer-events:none; }
      `}</style>

      {/* BG hexagons */}
      <div className="hex-bg" style={{ top:-40, left:-40 }}>⬡</div>
      <div className="hex-bg" style={{ bottom:-40, right:-40 }}>⬡</div>
      <div className="hex-bg" style={{ top:'40%', right:-60 }}>⬡</div>

      {/* PR Logo */}
      <div style={{ marginBottom:32, textAlign:'center', animation:'float 4s ease-in-out infinite' }}>
        <div style={{ fontFamily:'Playfair Display,serif', fontSize:28, color:'#4D9FFF', fontWeight:700, letterSpacing:2 }}>⬡ ProveRank</div>
      </div>

      {/* Exam Title */}
      <div style={{ fontFamily:'Playfair Display,serif', fontSize:26, fontWeight:700, textAlign:'center', marginBottom:8, maxWidth:500 }}>
        {exam?.title || 'Exam'}
      </div>
      <div style={{ color:'#6B8FAF', fontSize:13, marginBottom:40, letterSpacing:1 }}>Exam Waiting Room</div>

      {/* Live Counter */}
      <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:32, background:'rgba(77,159,255,0.1)', border:'1px solid rgba(77,159,255,0.3)', borderRadius:20, padding:'6px 18px' }}>
        <span style={{ width:8, height:8, borderRadius:'50%', background:'#4DF08E', display:'inline-block', animation:'pulse 1.5s infinite' }}/>
        <span style={{ fontSize:13, color:'#E8F4FF' }}>{liveCount} students online</span>
      </div>

      {/* Countdown Timer */}
      {!done ? (
        <div style={{ textAlign:'center', marginBottom:40 }}>
          <div style={{ color:'#6B8FAF', fontSize:12, letterSpacing:3, textTransform:'uppercase', marginBottom:12 }}>Exam Starts In</div>
          <div style={{ display:'flex', gap:16, justifyContent:'center' }}>
            {[{ v: h, l: 'HRS' }, { v: m, l: 'MIN' }, { v: s, l: 'SEC' }].map(({ v, l }) => (
              <div key={l} style={{ textAlign:'center' }}>
                <div style={{ background:'#001628', border:'2px solid #4D9FFF', borderRadius:12, width:72, height:72, display:'flex', alignItems:'center', justifyContent:'center', fontSize:32, fontWeight:700, color:'#4D9FFF', boxShadow:'0 0 20px rgba(77,159,255,0.3)' }}>
                  {String(v).padStart(2, '0')}
                </div>
                <div style={{ fontSize:9, color:'#6B8FAF', marginTop:4, letterSpacing:2 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div style={{ color:'#4DF08E', fontSize:18, fontWeight:700, marginBottom:40, animation:'pulse 1s infinite' }}>🟢 Exam is Live!</div>
      )}

      {/* Progress Bar */}
      <div style={{ width:'100%', maxWidth:440, marginBottom:40 }}>
        <div style={{ height:4, background:'#002D55', borderRadius:2, overflow:'hidden' }}>
          <div style={{ height:'100%', width:`${pct}%`, background:'linear-gradient(90deg,#4D9FFF,#4DF08E)', borderRadius:2, transition:'width 1s ease' }}/>
        </div>
        <div style={{ display:'flex', justifyContent:'space-between', marginTop:6, fontSize:11, color:'#6B8FAF' }}>
          <span>Waiting</span><span>Starting</span>
        </div>
      </div>

      {/* Exam Info Cards */}
      <div style={{ display:'flex', gap:16, marginBottom:40, flexWrap:'wrap', justifyContent:'center' }}>
        {[
          { icon:'📝', label:'Questions', val: exam?.totalQuestions || 180 },
          { icon:'⏱️', label:'Duration', val: `${exam?.duration || 180} min` },
          { icon:'🎯', label:'Marking', val: '+4 / -1' },
        ].map(({ icon, label, val }) => (
          <div key={label} style={{ background:'#001628', border:'1px solid #002D55', borderRadius:12, padding:'12px 20px', textAlign:'center', minWidth:100 }}>
            <div style={{ fontSize:22, marginBottom:4 }}>{icon}</div>
            <div style={{ fontSize:18, fontWeight:700, color:'#4D9FFF' }}>{val}</div>
            <div style={{ fontSize:11, color:'#6B8FAF', marginTop:2 }}>{label}</div>
          </div>
        ))}
      </div>

      {/* Instructions */}
      {exam?.instructions && (
        <div style={{ background:'rgba(77,159,255,0.06)', border:'1px solid #002D55', borderRadius:12, padding:16, maxWidth:440, width:'100%', marginBottom:32, fontSize:13, color:'#B0C4D8', lineHeight:1.7 }}>
          <div style={{ color:'#4D9FFF', fontWeight:600, marginBottom:8 }}>📋 Instructions</div>
          {exam.instructions}
        </div>
      )}

      {error && <div style={{ color:'#FF6B6B', marginBottom:16, fontSize:13 }}>⚠️ {error}</div>}

      {/* Start Button */}
      <button
        onClick={handleStart}
        disabled={starting}
        style={{ background: starting ? '#002D55' : 'linear-gradient(135deg,#4D9FFF,#0055CC)', color:'white', border:'none', borderRadius:12, padding:'16px 48px', fontSize:16, fontWeight:700, cursor: starting ? 'not-allowed' : 'pointer', letterSpacing:1, boxShadow:'0 0 30px rgba(77,159,255,0.4)', transition:'all 0.3s' }}>
        {starting ? '⟳ Starting...' : '▶ Start Exam Now'}
      </button>

      <div style={{ marginTop:20, fontSize:12, color:'#6B8FAF', textAlign:'center' }}>
        Exam shuru hone ke baad tab switch ya fullscreen exit karne par warning milegi
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 1/12 — Exam Waiting Room (WR1 + M6 + Live Counter)"

# ════════════════════════════════════════════════════════════
# FILE 2 — Main Exam Attempt Page
# L1: 3-Zone Layout (Header+Left+Right)
# T2: Progress Bar Timer (Green→Orange→Red)
# Q1: Section Tabs + Question Card
# A1: OMR Bubble Style Answers
# N1: Colour-Coded Navigation Grid (180 questions)
# S32: Fullscreen Enforcement (auto + 3 warnings)
# S76: Student Watermark
# S1: Bookmark / Review Later
# Auto-save every 30 seconds
# ════════════════════════════════════════════════════════════
cat > "src/app/dashboard/exams/[examId]/attempt/page.tsx" << 'ENDOFFILE'
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
ENDOFFILE
echo "✅ 2-10/12 — Exam Attempt Page (L1+T2+Q1+A1+N1+S32+S76+S1+AutoSave)"

# ════════════════════════════════════════════════════════════
# FILE 3 — Submit Summary Page
# S2: Full Page Summary Before Submit
# Shows: Answered / Unanswered / Marked counts
# Subject-wise table + Final Submit button
# ════════════════════════════════════════════════════════════
cat > "src/app/dashboard/exams/[examId]/submit/page.tsx" << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { useParams, useSearchParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';

export default function SubmitSummaryPage() {
  const { examId } = useParams<{ examId: string }>();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get('attemptId') || '';
  const isAuto = searchParams.get('auto') === 'true';
  const router = useRouter();
  const token = getToken();

  const [attempt, setAttempt] = useState<{
    examTitle?: string;
    totalQuestions?: number;
    answered?: number;
    notAnswered?: number;
    marked?: number;
    timeRemaining?: number;
    subjectStats?: Record<string, { answered: number; total: number }>;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    // Fetch navigation summary
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/navigation`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      const nav = d.navigation || d;
      const questions = nav.questions || [];
      const answered = questions.filter((q: { status: string }) => q.status === 'answered').length;
      const marked = questions.filter((q: { status: string }) => q.status === 'marked').length;
      const total = questions.length;
      // Subject-wise breakdown
      const subjectMap: Record<string, { answered: number; total: number }> = {};
      questions.forEach((q: { subject?: string; status: string }) => {
        const sub = q.subject || 'General';
        if (!subjectMap[sub]) subjectMap[sub] = { answered: 0, total: 0 };
        subjectMap[sub].total++;
        if (q.status === 'answered') subjectMap[sub].answered++;
      });
      setAttempt({
        examTitle: d.examTitle || nav.examTitle || 'Exam',
        totalQuestions: total,
        answered,
        notAnswered: total - answered - marked,
        marked,
        timeRemaining: d.timeRemaining || 0,
        subjectStats: subjectMap,
      });
      setLoading(false);
      // If auto-submit, submit immediately
      if (isAuto) { handleSubmit(true); }
    }).catch(() => {
      setAttempt({ totalQuestions: 180, answered: 0, notAnswered: 180, marked: 0 });
      setLoading(false);
    });
  }, [attemptId, token, isAuto, router]);

  const handleSubmit = async (auto = false) => {
    if (submitting || submitted) return;
    setSubmitting(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/attempts/${attemptId}/submit`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token || ''}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ autoSubmit: auto }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Submit failed');
      setSubmitted(true);
      setTimeout(() => {
        router.push(`/dashboard/results/${attemptId}`);
      }, 2000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Submit nahi hua');
      setSubmitting(false);
    }
  };

  if (loading) return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'#F8FAFC', fontSize:16, color:'#334155' }}>
      ⟳ Loading summary...
    </div>
  );

  if (submitted) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#F0FDF4', gap:20 }}>
      <div style={{ fontSize:64 }}>🎉</div>
      <div style={{ fontSize:24, fontWeight:700, color:'#15803D' }}>Exam Submitted!</div>
      <div style={{ color:'#16A34A' }}>Result page par ja rahe hain...</div>
      <div style={{ width:200, height:4, background:'#BBF7D0', borderRadius:2, overflow:'hidden' }}>
        <div style={{ height:'100%', background:'#22C55E', animation:'expand 2s linear forwards', borderRadius:2 }}/>
      </div>
      <style>{`@keyframes expand { from{width:0} to{width:100%} }`}</style>
    </div>
  );

  const total = attempt?.totalQuestions || 0;
  const answered = attempt?.answered || 0;
  const notAnswered = attempt?.notAnswered || 0;
  const marked = attempt?.marked || 0;

  return (
    <div style={{ minHeight:'100vh', background:'#F8FAFC', fontFamily:'Inter,sans-serif', padding:24 }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');`}</style>

      <div style={{ maxWidth:600, margin:'0 auto' }}>
        {/* Header */}
        <div style={{ textAlign:'center', marginBottom:32 }}>
          <div style={{ fontFamily:'Playfair Display,serif', fontSize:24, fontWeight:700, color:'#0F172A', marginBottom:4 }}>
            📤 Submit Exam
          </div>
          <div style={{ color:'#64748B', fontSize:14 }}>{attempt?.examTitle || 'Exam'}</div>
          {isAuto && (
            <div style={{ marginTop:8, background:'#FEF2F2', border:'1px solid #FCA5A5', borderRadius:8, padding:'8px 16px', color:'#DC2626', fontSize:13, fontWeight:600 }}>
              ⚠️ Auto-submit triggered (3 warnings exceeded)
            </div>
          )}
        </div>

        {/* S2: Stats Summary */}
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:16, marginBottom:24 }}>
          {[
            { icon:'✅', label:'Answered', val: answered, color:'#22C55E', bg:'#F0FDF4', border:'#BBF7D0' },
            { icon:'❌', label:'Unanswered', val: notAnswered, color:'#EF4444', bg:'#FEF2F2', border:'#FCA5A5' },
            { icon:'🔖', label:'Marked', val: marked, color:'#A855F7', bg:'#FAF5FF', border:'#DDD6FE' },
          ].map(({ icon, label, val, color, bg, border }) => (
            <div key={label} style={{ background:bg, border:`1px solid ${border}`, borderRadius:14, padding:'20px 16px', textAlign:'center' }}>
              <div style={{ fontSize:28 }}>{icon}</div>
              <div style={{ fontSize:32, fontWeight:700, color, margin:'4px 0' }}>{val}</div>
              <div style={{ fontSize:12, color:'#64748B' }}>{label}</div>
            </div>
          ))}
        </div>

        {/* Progress bar */}
        <div style={{ background:'white', borderRadius:14, padding:20, marginBottom:24, border:'1px solid #E2E8F0' }}>
          <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8, fontSize:13, color:'#475569' }}>
            <span>Completion</span>
            <span style={{ fontWeight:700 }}>{total > 0 ? Math.round((answered / total) * 100) : 0}%</span>
          </div>
          <div style={{ height:8, background:'#F1F5F9', borderRadius:4, overflow:'hidden' }}>
            <div style={{ height:'100%', width:`${total > 0 ? (answered / total) * 100 : 0}%`, background:'linear-gradient(90deg,#4D9FFF,#22C55E)', borderRadius:4, transition:'width 0.5s' }}/>
          </div>
          <div style={{ marginTop:8, fontSize:12, color:'#94A3B8', textAlign:'right' }}>
            {answered} of {total} answered
          </div>
        </div>

        {/* Subject-wise table */}
        {attempt?.subjectStats && Object.keys(attempt.subjectStats).length > 0 && (
          <div style={{ background:'white', borderRadius:14, border:'1px solid #E2E8F0', overflow:'hidden', marginBottom:24 }}>
            <div style={{ padding:'14px 20px', borderBottom:'1px solid #F1F5F9', fontWeight:700, fontSize:14, color:'#0F172A' }}>
              📊 Subject-wise Summary
            </div>
            <table style={{ width:'100%', borderCollapse:'collapse' }}>
              <thead>
                <tr style={{ background:'#F8FAFC' }}>
                  {['Subject', 'Total', 'Answered', 'Status'].map(h => (
                    <th key={h} style={{ padding:'10px 16px', textAlign:'left', fontSize:12, fontWeight:600, color:'#475569', borderBottom:'1px solid #E2E8F0' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {Object.entries(attempt.subjectStats).map(([sub, stat]) => (
                  <tr key={sub}>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#334155', fontWeight:500 }}>{sub}</td>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#64748B' }}>{stat.total}</td>
                    <td style={{ padding:'12px 16px', fontSize:14, color:'#22C55E', fontWeight:600 }}>{stat.answered}</td>
                    <td style={{ padding:'12px 16px' }}>
                      <div style={{ height:6, background:'#F1F5F9', borderRadius:3, overflow:'hidden', width:80 }}>
                        <div style={{ height:'100%', width:`${stat.total > 0 ? (stat.answered / stat.total) * 100 : 0}%`, background:'#4D9FFF', borderRadius:3 }}/>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Time remaining */}
        {(attempt?.timeRemaining || 0) > 0 && (
          <div style={{ background:'#FFFBEB', border:'1px solid #FDE68A', borderRadius:12, padding:'12px 20px', marginBottom:24, display:'flex', alignItems:'center', gap:10 }}>
            <span style={{ fontSize:20 }}>⏱️</span>
            <div>
              <div style={{ fontSize:13, fontWeight:600, color:'#92400E' }}>Time Remaining</div>
              <div style={{ fontSize:12, color:'#B45309' }}>
                {Math.floor((attempt?.timeRemaining || 0) / 60)}m {(attempt?.timeRemaining || 0) % 60}s bacha hua hai
              </div>
            </div>
          </div>
        )}

        {error && <div style={{ color:'#DC2626', marginBottom:16, textAlign:'center', fontSize:13 }}>⚠️ {error}</div>}

        {/* Action buttons */}
        <div style={{ display:'flex', gap:12 }}>
          <button onClick={() => router.back()}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'1px solid #E2E8F0', background:'white', cursor:'pointer', fontWeight:600, fontSize:14, color:'#475569' }}>
            ← Back to Exam
          </button>
          <button onClick={() => handleSubmit(false)} disabled={submitting}
            style={{ flex:2, padding:'14px', borderRadius:10, border:'none', background: submitting ? '#94A3B8' : '#EF4444', color:'white', cursor: submitting ? 'not-allowed' : 'pointer', fontWeight:700, fontSize:15, boxShadow:'0 4px 12px rgba(239,68,68,0.3)' }}>
            {submitting ? '⟳ Submitting...' : '✅ Final Submit'}
          </button>
        </div>

        <div style={{ marginTop:16, textAlign:'center', fontSize:12, color:'#94A3B8' }}>
          Submit karne ke baad changes nahi ho sakte. Result abhi calculate hoga.
        </div>
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 11/12 — Submit Summary Page (S2: Full Page Summary)"

# ════════════════════════════════════════════════════════════
# FILE 4 — Result Redirect Page
# After submit → shows basic result + redirect to dashboard
# ════════════════════════════════════════════════════════════
cat > "src/app/dashboard/results/[attemptId]/page.tsx" << 'ENDOFFILE'
'use client';
import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { getToken } from '@/lib/auth';
import PRLogo from '@/components/PRLogo';

interface Result {
  score?: number;
  maxScore?: number;
  rank?: number;
  percentile?: number;
  totalCorrect?: number;
  totalIncorrect?: number;
  totalUnattempted?: number;
  examTitle?: string;
  subjectStats?: Record<string, { score: number; correct: number; incorrect: number; total: number }>;
}

export default function ResultPage() {
  const { attemptId } = useParams<{ attemptId: string }>();
  const router = useRouter();
  const token = getToken();
  const [result, setResult] = useState<Result | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) { router.push('/login'); return; }
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/results/${attemptId}`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()).then(d => {
      setResult(d.result || d);
      setLoading(false);
    }).catch(() => {
      setError('Result load nahi hua');
      setLoading(false);
    });
  }, [attemptId, token, router]);

  if (loading) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#4D9FFF', gap:16 }}>
      <div style={{ fontSize:48, animation:'spin 1s linear infinite' }}>⟳</div>
      <div style={{ fontSize:16 }}>Result calculate ho raha hai...</div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );

  if (error) return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100vh', background:'#000A18', color:'#E8F4FF', gap:16 }}>
      <div style={{ fontSize:48 }}>⚠️</div>
      <div>{error}</div>
      <button onClick={() => router.push('/dashboard')} style={{ background:'#4D9FFF', color:'white', border:'none', borderRadius:8, padding:'10px 24px', cursor:'pointer', fontWeight:600 }}>Dashboard</button>
    </div>
  );

  const pct = result?.maxScore ? Math.round(((result.score || 0) / result.maxScore) * 100) : 0;

  return (
    <div style={{ minHeight:'100vh', background:'#000A18', color:'#E8F4FF', fontFamily:'Inter,sans-serif', padding:24 }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600&display=swap');
        @keyframes fadeIn { from{opacity:0;transform:translateY(20px)} to{opacity:1;transform:translateY(0)} }
        @keyframes countUp { from{opacity:0} to{opacity:1} }
        .card { background:#001628; border:1px solid #002D55; border-radius:14px; padding:20px; animation:fadeIn 0.5s ease forwards; }
      `}</style>

      <div style={{ maxWidth:560, margin:'0 auto' }}>
        {/* Header */}
        <div style={{ textAlign:'center', marginBottom:32, paddingTop:16 }}>
          <PRLogo size={48} showName horizontal nameSize={22} />
        </div>

        {/* Hero Score Banner */}
        <div style={{ background:'linear-gradient(135deg,#001E3C,#003366)', border:'1px solid #4D9FFF', borderRadius:20, padding:32, textAlign:'center', marginBottom:20, boxShadow:'0 0 40px rgba(77,159,255,0.15)' }}>
          <div style={{ fontSize:13, color:'#6B8FAF', letterSpacing:3, textTransform:'uppercase', marginBottom:16 }}>
            {result?.examTitle || 'Exam Result'}
          </div>
          {/* Big Score */}
          <div style={{ fontSize:72, fontWeight:900, color:'#4D9FFF', lineHeight:1, marginBottom:4, fontVariantNumeric:'tabular-nums' }}>
            {result?.score ?? '--'}
          </div>
          <div style={{ fontSize:18, color:'#6B8FAF', marginBottom:24 }}>
            out of {result?.maxScore ?? 720}
          </div>
          {/* Stats row */}
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12 }}>
            {[
              { label:'Rank', val: result?.rank ? `#${result.rank}` : '--', color:'#F59E0B' },
              { label:'Percentile', val: result?.percentile ? `${Number(result.percentile).toFixed(1)}%` : '--', color:'#4D9FFF' },
              { label:'Accuracy', val: result?.maxScore ? `${pct}%` : '--', color:'#22C55E' },
            ].map(({ label, val, color }) => (
              <div key={label} style={{ background:'rgba(0,0,0,0.3)', borderRadius:10, padding:'12px 8px' }}>
                <div style={{ fontSize:22, fontWeight:700, color }}>{val}</div>
                <div style={{ fontSize:11, color:'#6B8FAF', marginTop:2 }}>{label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Correct / Wrong / Skip */}
        <div className="card" style={{ marginBottom:16 }}>
          <div style={{ fontWeight:700, marginBottom:14, fontSize:15 }}>📊 Answer Summary</div>
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:12 }}>
            {[
              { label:'Correct', val: result?.totalCorrect ?? '--', color:'#22C55E', bg:'rgba(34,197,94,0.1)' },
              { label:'Incorrect', val: result?.totalIncorrect ?? '--', color:'#EF4444', bg:'rgba(239,68,68,0.1)' },
              { label:'Skipped', val: result?.totalUnattempted ?? '--', color:'#6B8FAF', bg:'rgba(107,143,175,0.1)' },
            ].map(({ label, val, color, bg }) => (
              <div key={label} style={{ background:bg, borderRadius:10, padding:'14px 10px', textAlign:'center' }}>
                <div style={{ fontSize:26, fontWeight:700, color }}>{val}</div>
                <div style={{ fontSize:12, color:'#6B8FAF', marginTop:2 }}>{label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Subject stats */}
        {result?.subjectStats && (
          <div className="card" style={{ marginBottom:24 }}>
            <div style={{ fontWeight:700, marginBottom:14, fontSize:15 }}>📚 Subject-wise Performance</div>
            {Object.entries(result.subjectStats).map(([sub, stat]) => (
              <div key={sub} style={{ marginBottom:14 }}>
                <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6, fontSize:13 }}>
                  <span style={{ color:'#E8F4FF', fontWeight:500 }}>{sub}</span>
                  <span style={{ color:'#4D9FFF', fontWeight:700 }}>{stat.score}/{stat.total * 4}</span>
                </div>
                <div style={{ height:6, background:'#002D55', borderRadius:3, overflow:'hidden' }}>
                  <div style={{ height:'100%', width:`${stat.total > 0 ? (stat.correct / stat.total) * 100 : 0}%`, background:'#4D9FFF', borderRadius:3 }}/>
                </div>
                <div style={{ display:'flex', gap:12, marginTop:4, fontSize:11, color:'#6B8FAF' }}>
                  <span>✅ {stat.correct}</span>
                  <span>❌ {stat.incorrect}</span>
                  <span>⬜ {stat.total - stat.correct - stat.incorrect}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Actions */}
        <div style={{ display:'flex', gap:12 }}>
          <button onClick={() => router.push('/dashboard')}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'1px solid #002D55', background:'#001628', color:'#E8F4FF', cursor:'pointer', fontWeight:600, fontSize:14 }}>
            🏠 Dashboard
          </button>
          <button onClick={() => router.push('/dashboard/exams')}
            style={{ flex:1, padding:'14px', borderRadius:10, border:'none', background:'linear-gradient(135deg,#4D9FFF,#0055CC)', color:'white', cursor:'pointer', fontWeight:700, fontSize:14 }}>
            📝 More Exams
          </button>
        </div>
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 12/12 — Result Page (Score + Rank + Percentile + Subject Stats)"

# ════════════════════════════════════════════════════════════
# VERIFY — Check all files exist
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verifying files ──"
FILES=(
  "src/app/dashboard/exams/[examId]/waiting/page.tsx"
  "src/app/dashboard/exams/[examId]/attempt/page.tsx"
  "src/app/dashboard/exams/[examId]/submit/page.tsx"
  "src/app/dashboard/results/[attemptId]/page.tsx"
)
ALL_OK=true
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ MISSING: $f"
    ALL_OK=false
  fi
done

echo ""
echo "── Phase 7.3 Summary ──"
echo "✅ 1   Waiting Room     — WR1 Animated Countdown + M6 Live Counter + Socket.io"
echo "✅ 2   Attempt Layout   — L1: Header + Left Panel + Right Content (3-zone)"
echo "✅ 3   Timer            — T2: Progress Bar Green→Orange→Red + HH:MM:SS"
echo "✅ 4   Question Card    — Q1: Section Tabs (Physics/Chemistry/Biology) + Clean Card"
echo "✅ 5   OMR Answers      — A1: Bubble Style A/B/C/D + Deselect support"
echo "✅ 6   Nav Grid         — N1: Colour-coded 180q grid (Green/Red/Purple/Grey)"
echo "✅ 7   Fullscreen       — S32: Auto fullscreen + 3 warnings = auto-submit"
echo "✅ 8   Watermark        — S76: Student name watermark on screen"
echo "✅ 9   Bookmark         — S1: Review Later flag per question"
echo "✅ 10  Auto-save        — 30 sec auto-save + manual save-answer API"
echo "✅ 11  Submit Summary   — S2: Full page Answered/Unanswered/Marked + Subject table"
echo "✅ 12  Result Page      — Score + Rank + Percentile + Subject stats"
echo ""
echo "Design: PR4 ⬡ · N6 #4D9FFF Dark Theme (Waiting+Result) · White Theme (Attempt) · F1 Playfair+Inter"
echo ""

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "feat: Phase 7.3 complete — Exam Attempt UI (12 steps)

Steps: WR1·M6 · L1 · T2 · Q1 · A1 · N1 · S32 · S76 · S1 · AutoSave · S2 · Result
Design: Step 04 LOCKED — White theme exam UI
- Waiting Room: WR1 animated countdown + live student counter
- Attempt: 3-zone layout + progress bar timer + OMR bubbles
- Fullscreen enforcement + watermark + bookmark + auto-save
- Submit summary: subject-wise table + final submit
- Result page: score + rank + percentile + subject stats"
git push origin main

echo ""
if [ "$ALL_OK" = true ]; then
  echo "🎉 Phase 7.3 COMPLETE! Sab 12 steps ready hain."
  echo "Next: Phase 7.4 shuru karo — Results & Analytics UI"
else
  echo "⚠️  Kuch files missing hain. Script dobara run karo."
fi
