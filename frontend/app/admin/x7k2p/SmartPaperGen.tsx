'use client';
import { useState, useEffect, useCallback } from 'react';

// ═══ Types ═══
interface DiffMix   { easy: number; medium: number; hard: number; }
interface FmtConf   { format: string; percent: number; }
interface SubjConf  { name: string; count: number; chapters: string[]; difficultyMix: DiffMix; formats: FmtConf[]; }
interface GenSet    { setLabel: string; totalQuestions: number; questions: any[]; }
interface GenPaper  { sets: GenSet[]; meta: any; answerKey: Record<string,any>; selectionLog: any[]; subjectSummary: any; setComparison: any[]; }

// ═══ Constants ═══
const ALL_SUBJECTS = ['Physics','Chemistry','Biology','Mathematics','Zoology','Botany'];
const ALL_FORMATS  = ['Assertion_Reason','Match_Column','True_False','Statement_Based','Numerical','Fill_Blanks','Passage_Based','Sequence_Based','Graph_Data_Based','Diagram_Based'];
const FORMAT_EMOJI: Record<string,string> = {
  Assertion_Reason:'🔗', Match_Column:'📊', True_False:'✅', Statement_Based:'📋',
  Numerical:'🔢', Fill_Blanks:'📝', Passage_Based:'📖', Sequence_Based:'🔄',
  Graph_Data_Based:'📈', Diagram_Based:'🖼️'
};
const SUBJ_EMOJI: Record<string,string> = { Physics:'⚛️', Chemistry:'🧪', Biology:'🧬', Mathematics:'📐', Zoology:'🦎', Botany:'🌿' };
const SUBJ_COLOR: Record<string,string> = { Physics:'#6366F1', Chemistry:'#10B981', Biology:'#F59E0B', Mathematics:'#EF4444', Zoology:'#8B5CF6', Botany:'#06B6D4' };

// ═══ Styles ═══
const S = {
  wrap:  { color:'#E2E8F0', fontFamily:'Inter,system-ui,sans-serif', minHeight:'100vh' },
  card:  { background:'rgba(255,255,255,0.04)', border:'1px solid rgba(255,255,255,0.09)', borderRadius:16, padding:'18px 16px', backdropFilter:'blur(12px)', marginBottom:14 },
  cardHi:{ background:'rgba(99,102,241,0.08)', border:'1px solid rgba(99,102,241,0.25)', borderRadius:16, padding:'18px 16px', backdropFilter:'blur(12px)', marginBottom:14 },
  label: { fontSize:11, fontWeight:700, color:'#94A3B8', textTransform:'uppercase' as const, letterSpacing:'0.5px', display:'block', marginBottom:6 },
  inp:   { width:'100%', padding:'9px 12px', background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:9, color:'#E2E8F0', fontSize:12, outline:'none', boxSizing:'border-box' as const },
  bp:    { background:'linear-gradient(135deg,#6366F1,#8B5CF6)', color:'#fff', border:'none', borderRadius:10, padding:'11px 20px', fontWeight:700, fontSize:13, cursor:'pointer', transition:'all 0.2s' },
  bg:    { background:'rgba(255,255,255,0.06)', color:'#E2E8F0', border:'1px solid rgba(255,255,255,0.12)', borderRadius:10, padding:'9px 16px', fontWeight:600, fontSize:12, cursor:'pointer' },
  bs:    { background:'linear-gradient(135deg,#10B981,#059669)', color:'#fff', border:'none', borderRadius:10, padding:'10px 18px', fontWeight:700, fontSize:12, cursor:'pointer' },
  chip:  { display:'inline-flex', alignItems:'center', gap:4, padding:'4px 10px', borderRadius:20, fontSize:11, fontWeight:600, background:'rgba(99,102,241,0.15)', border:'1px solid rgba(99,102,241,0.3)', color:'#A5B4FC', marginRight:6, marginBottom:6 },
  tog:   (on:boolean) => ({ display:'inline-flex', width:40, height:22, borderRadius:11, background: on ? '#6366F1' : 'rgba(255,255,255,0.1)', position:'relative' as const, cursor:'pointer', transition:'background 0.2s', flexShrink:0 }),
  togDot:(on:boolean) => ({ position:'absolute' as const, top:3, left: on ? 21 : 3, width:16, height:16, borderRadius:8, background:'#fff', transition:'left 0.2s', boxShadow:'0 2px 4px rgba(0,0,0,0.3)' })
};

// Default subject config
const defaultSubjConf = (name: string): SubjConf => ({
  name, count: name === 'Biology' ? 90 : 45,
  chapters: [],
  difficultyMix: { easy: 33, medium: 44, hard: 23 },
  formats: []
});

// ═══ TOGGLE ═══
function Toggle({ on, onToggle }: { on: boolean; onToggle: () => void }) {
  return (
    <div style={S.tog(on)} onClick={onToggle} role="switch" aria-checked={on}>
      <div style={S.togDot(on)} />
    </div>
  );
}

// ═══ MAIN COMPONENT ═══
export default function SmartPaperGen({ API, token }: { API: string; token: string }) {
  const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pr_token') || '' : token;

  // ── 17.1 Subject select
  const [selSubjects, setSelSubjects]   = useState<string[]>(['Physics','Chemistry','Biology']);
  // ── 17.2 / 17.3 / 17.5 Per-subject config
  const [subjConfs,   setSubjConfs]     = useState<Record<string,SubjConf>>({
    Physics:   defaultSubjConf('Physics'),
    Chemistry: defaultSubjConf('Chemistry'),
    Biology:   defaultSubjConf('Biology')
  });
  // ── 17.4 Marking scheme
  const [marking,     setMarking]       = useState({ correct:4, incorrect:-1, unattempted:0 });
  // ── 17.6 / 17.7 Template
  const [templates,   setTemplates]     = useState<any[]>([]);
  const [selTmpl,     setSelTmpl]       = useState('');
  // ── 17.9 Sets
  const [setsCount,   setSetsCount]     = useState(1);
  // ── 17.12 Exclude used
  const [exUsed,      setExUsed]        = useState(false);
  const [exUsedPct,   setExUsedPct]     = useState(100);
  // ── 17.13 Exclude PYQ
  const [exPYQ,       setExPYQ]         = useState(false);
  const [exPYQPct,    setExPYQPct]      = useState(100);
  // ── 17.26 Global format mix
  const [fmtConfs,    setFmtConfs]      = useState<FmtConf[]>([]);
  const [fmtMode,     setFmtMode]       = useState(false); // toggle format section
  // ── 17.15 Surprise Me
  const [surpriseMode,setSurpriseMode]  = useState(false);
  // ── Mode
  const [mode,        setMode]          = useState<'neet'|'jee'|'cuet'|'custom'|'surprise'>('neet');
  // ── Generation state
  const [loading,     setLoading]       = useState(false);
  const [progress,    setProgress]      = useState<string[]>([]);
  const [paper,       setPaper]         = useState<GenPaper|null>(null);
  const [genError,    setGenError]      = useState('');
  // ── 17.10 Preview — active set tab
  const [activeSet,   setActiveSet]     = useState('A');
  // ── 17.17 Set comparison
  const [showComp,    setShowComp]      = useState(false);
  // ── 17.11 Use as Exam modal
  const [showUAE,     setShowUAE]       = useState(false);
  const [uaeTitle,    setUaeTitle]      = useState('');
  const [uaeBatch,    setUaeBatch]      = useState('');
  const [uaeType,     setUaeType]       = useState('Full Mock');
  const [uaeSet,      setUaeSet]        = useState('A');
  const [uaeSaving,   setUaeSaving]     = useState(false);
  const [uaeSuccess,  setUaeSuccess]    = useState('');
  // ── 17.18 Save template
  const [showSaveTmpl,setShowSaveTmpl] = useState(false);
  const [saveTmplName,setSaveTmplName] = useState('');
  const [savedTmpls,  setSavedTmpls]   = useState<any[]>([]);
  // ── Bank stats
  const [bankStats,   setBankStats]     = useState<any>(null);
  // ── 17.30 Language medium
  const [langMode,    setLangMode]      = useState<'english'|'hindi'|'bilingual'>('bilingual');
  const [examMedium,  setExamMedium]    = useState<'english'|'hindi'|'bilingual'>('bilingual');
  // ── 17.29 Completeness + edit/replace
  const [showReport,  setShowReport]    = useState(false);
  const [editingQ,    setEditingQ]      = useState<Record<string,any>>({});
  const [replacing,   setReplacing]     = useState<string|null>(null);
  // ── Exam title
  const [examTitle,   setExamTitle]     = useState('');

  // Load templates + stats on mount
  useEffect(() => {
    const tok = getToken();
    // 17.7 — Sync with S75 exam template system
    fetch(`${API}/api/exams/templates`, { headers:{ Authorization:`Bearer ${tok}` } })
      .then(r => r.json()).then(d => { if (d.templates) setTemplates(d.templates); }).catch(()=>{});
    // Bank stats
    fetch(`${API}/api/paper/stats`, { headers:{ Authorization:`Bearer ${tok}` } })
      .then(r => r.json()).then(d => { if (d.success) setBankStats(d); }).catch(()=>{});
    // Saved templates (17.18)
    fetch(`${API}/api/paper/saved-templates`, { headers:{ Authorization:`Bearer ${tok}` } })
      .then(r => r.json()).then(d => { if (d.templates) setSavedTmpls(d.templates); }).catch(()=>{});
  }, []);

  // ── 17.6 / 17.7 Template select → auto-fill
  const handleTemplateSelect = useCallback((tmplId: string) => {
    setSelTmpl(tmplId);
    const tmpl = templates.find(t => t.id === tmplId);
    if (!tmpl) return;
    const tMode = (tmpl.pattern || tmpl.id || 'custom').toLowerCase() as any;
    setMode(tMode === 'neet' || tMode === 'jee' || tMode === 'cuet' ? tMode : 'custom');
    setMarking({ correct: tmpl.marking?.correct || 4, incorrect: tmpl.marking?.wrong || tmpl.marking?.incorrect || -1, unattempted: 0 });
    if (tmpl.sections && tmpl.sections.length > 0) {
      const newSubjs: string[] = [];
      const newConfs: Record<string,SubjConf> = {};
      tmpl.sections.forEach((s: any) => {
        newSubjs.push(s.name);
        newConfs[s.name] = { ...defaultSubjConf(s.name), count: s.count || 30 };
      });
      setSelSubjects(newSubjs);
      setSubjConfs(prev => ({ ...prev, ...newConfs }));
    }
    setExamTitle(`${tmpl.name} — Practice`);
  }, [templates]);

  // ── 17.15 Surprise Me
  const handleSurprise = () => {
    setSurpriseMode(true);
    setMode('surprise');
    setSelSubjects(['Physics','Chemistry','Biology']);
    setMarking({ correct: [4,3,2][Math.floor(Math.random()*3)], incorrect: -1, unattempted: 0 });
    setSetsCount(Math.floor(Math.random()*3)+1);
    setExamTitle('Surprise Mock Test 🎲');
  };

  // ── Toggle subject
  const toggleSubject = (s: string) => {
    setSelSubjects(prev => {
      if (prev.includes(s)) return prev.filter(x => x !== s);
      const next = [...prev, s];
      if (!subjConfs[s]) setSubjConfs(c => ({ ...c, [s]: defaultSubjConf(s) }));
      return next;
    });
  };

  // ── Update subject config field
  const updSubj = (name: string, field: string, val: any) => {
    setSubjConfs(prev => ({ ...prev, [name]: { ...prev[name], [field]: val } }));
  };

  // ── 17.26 Format toggle
  const toggleFormat = (fmt: string) => {
    setFmtConfs(prev => {
      if (prev.find(f => f.format === fmt)) return prev.filter(f => f.format !== fmt);
      return [...prev, { format: fmt, percent: Math.floor(100 / (prev.length + 1)) }];
    });
  };
  const updateFmtPct = (fmt: string, pct: number) => {
    setFmtConfs(prev => prev.map(f => f.format === fmt ? { ...f, percent: pct } : f));
  };

  // ── Build request body
  const buildBody = () => {
    const subjectsArr = selSubjects.map(s => ({
      name:          s,
      count:         subjConfs[s]?.count || 45,
      chapters:      subjConfs[s]?.chapters || [],
      difficultyMix: subjConfs[s]?.difficultyMix || { easy:33, medium:44, hard:23 },
      formats:       subjConfs[s]?.formats || fmtConfs
    }));
    return {
      mode:           mode,
      subjects:       subjectsArr,
      markingScheme:  marking,
      sets:           setsCount,
      examTitle:      examTitle || 'Smart Generated Paper',
      excludeUsed:    exUsed,
      excludeUsedPct: exUsedPct,
      excludePYQ:     exPYQ,
      excludePYQPct:  exPYQPct,
      questionFormats: fmtConfs.length > 0 ? fmtConfs : undefined,
      totalCount:     selSubjects.reduce((acc,s) => acc + (subjConfs[s]?.count || 45), 0)
    };
  };

  // ── 17.8 Generate Paper
  const generatePaper = async () => {
    setLoading(true);
    setPaper(null);
    setGenError('');
    setUaeSuccess('');
    const steps: string[] = [];
    const addStep = (msg: string) => { steps.push(msg); setProgress([...steps]); };
    try {
      addStep('🔍 Analysing Question Bank...');
      await new Promise(r => setTimeout(r, 400));
      addStep(`📚 Selecting from ${selSubjects.join(', ')}...`);
      await new Promise(r => setTimeout(r, 300));
      if (fmtConfs.length > 0) addStep(`🎯 Applying format filters: ${fmtConfs.map(f=>f.format).join(', ')}...`);
      addStep('🤖 AI Smart Selection in progress...');
      const tok = getToken();
      const res = await fetch(`${API}/api/paper/generate`, {
        method:'POST',
        headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${tok}` },
        body: JSON.stringify(buildBody())
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Generation failed');
      addStep(`✅ ${data.meta.totalQuestions} questions selected — ${data.meta.setsGenerated} set(s) ready!`);
      await new Promise(r => setTimeout(r, 300));
      setPaper(data);
      setActiveSet('A');
    } catch (e: any) {
      setGenError(e.message);
    } finally {
      setLoading(false);
      setTimeout(() => setProgress([]), 2000);
    }
  };

  // ── 17.11 Use as Exam
  const handleUseAsExam = async () => {
    if (!paper) return;
    setUaeSaving(true);
    setUaeSuccess('');
    try {
      const tok = getToken();
      const res = await fetch(`${API}/api/paper/use-as-exam`, {
        method:'POST',
        headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${tok}` },
        body: JSON.stringify({
          sets:             paper.sets,
          meta:             paper.meta,
          answerKey:        paper.answerKey,
          examTitle:        uaeTitle || paper.meta.examTitle,
          batch:            uaeBatch,
          type:             uaeType,
          selectedSetLabel: uaeSet,
          medium:           examMedium
        })
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message);
      setUaeSuccess(`✅ Exam created! ID: ${data.examId}`);
      setShowUAE(false);
    } catch (e: any) {
      setUaeSuccess(`❌ ${e.message}`);
    } finally {
      setUaeSaving(false);
    }
  };

  // ── 17.18 Save Template
  const handleSaveTemplate = async () => {
    if (!paper) return;
    const tok = getToken();
    const res = await fetch(`${API}/api/paper/save-template`, {
      method:'POST',
      headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${tok}` },
      body: JSON.stringify({ templateName: saveTmplName || 'My Template', criteria: buildBody(), meta: paper.meta })
    });
    const data = await res.json();
    if (data.success) { setSavedTmpls(prev => [data.template, ...prev]); setShowSaveTmpl(false); setSaveTmplName(''); }
  };

  // ── 17.19 Export
  const handleExport = async (fmt: 'pdf' | 'excel') => {
    if (!paper) return;
    const tok = getToken();
    const res = await fetch(`${API}/api/paper/export`, {
      method:'POST',
      headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${tok}` },
      body: JSON.stringify({ format: fmt, sets: paper.sets, meta: paper.meta, selectedSet: activeSet })
    });
    const blob = await res.blob();
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url;
    a.download = `Paper_Set${activeSet}.${fmt === 'pdf' ? 'pdf' : 'xlsx'}`;
    a.click();
    URL.revokeObjectURL(url);
  };

  // ── 17.29 Replace question
  const replaceQuestion = async (q: any, setLabel: string) => {
    if (!paper) return;
    setReplacing(q.questionId);
    try {
      const tok = getToken();
      const allIds = paper.sets.flatMap(s => s.questions.map((qq:any) => qq.questionId));
      const res = await fetch(`${API}/api/paper/replace-question`, {
        method:'POST',
        headers:{'Content-Type':'application/json', Authorization:`Bearer ${tok}`},
        body: JSON.stringify({ questionId: q.questionId, subject: q.subject, chapter: q.chapter, difficulty: q.difficulty, excludeIds: allIds })
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message);
      const newQ = { ...data.question, questionId: data.question._id, serialNo: q.serialNo };
      setPaper(prev => {
        if (!prev) return prev;
        const updSets = prev.sets.map(s => ({
          ...s,
          questions: s.questions.map((qq:any) => qq.questionId === q.questionId && s.setLabel === setLabel ? newQ : qq)
        }));
        const newKey: Record<string,any> = { ...prev.answerKey };
        delete newKey[String(q.questionId)];
        newKey[String(data.question._id)] = { correct: data.question.correct, explanation: data.question.explanation || '' };
        return { ...prev, sets: updSets, answerKey: newKey };
      });
    } catch(e:any) { alert('Replace failed: ' + e.message); }
    finally { setReplacing(null); }
  };

  // ── 17.29 Completeness check
  const checkQ = (q: any) => ({
    engText:     !!q.text,
    hindiText:   !!q.hindiText,
    mainImage:   !!(q.imageUrl),
    engOptions:  (q.options||[]).length >= 2,
    hindiOptions:(q.hindiOptions||[]).some((o:string)=>!!o),
    optionImages:(q.optionImages||[]).some((o:string)=>!!o),
    explanation: !!q.explanation,
    correctAns:  (q.correct||[]).length > 0
  });
  const qScore = (chk: any) => {
    const required = [chk.engText, chk.engOptions, chk.correctAns];
    const optional = [chk.hindiText, chk.hindiOptions, chk.explanation];
    const reqOk = required.every(Boolean);
    const optCount = optional.filter(Boolean).length;
    return { reqOk, optCount, total: optional.length };
  };

  // ── 17.30 Get display text based on langMode
  const getQText = (q: any) => {
    if (langMode === 'hindi' && q.hindiText) return q.hindiText;
    if (langMode === 'bilingual' && q.hindiText) return q.text + '\n' + q.hindiText;
    return q.text;
  };
  const getOptText = (q: any, j: number) => {
    const eng  = (q.options||[])[j] || '';
    const hind = (q.hindiOptions||[])[j] || '';
    if (langMode === 'hindi' && hind) return hind;
    if (langMode === 'bilingual' && hind) return eng + ' / ' + hind;
    return eng;
  };
  const getExplanation = (q: any) => {
    if (langMode === 'hindi' && q.hindiExplanation) return q.hindiExplanation;
    return q.explanation || '';
  };

  // ── Total count for right panel preview
  const totalCountPreview = selSubjects.reduce((acc,s) => acc + (subjConfs[s]?.count || 0), 0);
  const activeSetData = paper?.sets.find(s => s.setLabel === activeSet);

  return (
    <div style={S.wrap}>
      {/* ── HEADER ── */}
      <div style={{ marginBottom:20 }}>
        <div style={{ fontSize:22, fontWeight:800, background:'linear-gradient(135deg,#6366F1,#A78BFA)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', marginBottom:4 }}>
          🤖 Smart Paper Generator
        </div>
        <div style={{ fontSize:12, color:'#64748B' }}>
          AI picks questions from your QB · Multi-set · One-click exam · S101
        </div>
        {bankStats && (
          <div style={{ display:'flex', gap:10, marginTop:10, flexWrap:'wrap' }}>
            {['Physics','Chemistry','Biology'].map(s => (
              <div key={s} style={{ fontSize:11, padding:'3px 10px', borderRadius:20, background:`${SUBJ_COLOR[s]}18`, border:`1px solid ${SUBJ_COLOR[s]}40`, color: SUBJ_COLOR[s] }}>
                {SUBJ_EMOJI[s]} {s}: {bankStats.subjectWise?.[s]?.total || 0} Qs
              </div>
            ))}
            <div style={{ fontSize:11, padding:'3px 10px', borderRadius:20, background:'rgba(255,255,255,0.06)', color:'#94A3B8' }}>
              📦 Total: {bankStats.totalQuestions || 0}
            </div>
          </div>
        )}
      </div>

      {/* ── 17.20 TWO COLUMN WIZARD LAYOUT ── */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:16, marginBottom:16 }}>

        {/* ══ LEFT: CRITERIA FORM ══ */}
        <div>

          {/* 17.6 / 17.7 — Template Selector */}
          <div style={S.card}>
            <label style={S.label}>📋 Exam Pattern / Template (17.6–17.7)</label>
            <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:templates.length > 0 ? 10 : 0 }}>
              {(['neet','jee','cuet','custom'] as const).map(m => (
                <button key={m} onClick={() => { setMode(m); setSurpriseMode(false); }} style={{ ...S.bg, background: mode === m ? 'rgba(99,102,241,0.3)' : 'rgba(255,255,255,0.06)', border: mode === m ? '1px solid #6366F1' : '1px solid rgba(255,255,255,0.12)', fontSize:11, padding:'6px 12px' }}>
                  {m === 'neet' ? '🩺 NEET' : m === 'jee' ? '⚡ JEE' : m === 'cuet' ? '🏛️ CUET' : '⚙️ Custom'}
                </button>
              ))}
              {/* 17.15 — Surprise Me */}
              <button onClick={handleSurprise} style={{ ...S.bg, background:'rgba(245,158,11,0.12)', border:'1px solid rgba(245,158,11,0.35)', color:'#F59E0B', fontSize:11, padding:'6px 12px' }}>
                🎲 Surprise Me!
              </button>
            </div>
            {templates.length > 0 && (
              <select value={selTmpl} onChange={e => handleTemplateSelect(e.target.value)} style={{ ...S.inp, marginTop:4 }}>
                <option value="">— Or pick saved template —</option>
                {templates.map((t:any) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            )}
            {surpriseMode && (
              <div style={{ fontSize:11, color:'#F59E0B', marginTop:6, padding:'6px 10px', background:'rgba(245,158,11,0.08)', borderRadius:8 }}>
                🎲 Surprise mode active — AI chooses everything automatically!
              </div>
            )}
          </div>

          {/* 17.1 — Subject Multi-Select */}
          <div style={S.card}>
            <label style={S.label}>🔬 Subjects (17.1)</label>
            <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:10 }}>
              {ALL_SUBJECTS.map(s => (
                <button key={s} onClick={() => toggleSubject(s)} style={{ fontSize:11, padding:'5px 12px', borderRadius:20, border:`1px solid ${selSubjects.includes(s) ? SUBJ_COLOR[s] : 'rgba(255,255,255,0.12)'}`, background: selSubjects.includes(s) ? `${SUBJ_COLOR[s]}22` : 'rgba(255,255,255,0.04)', color: selSubjects.includes(s) ? SUBJ_COLOR[s] : '#94A3B8', cursor:'pointer', fontWeight: selSubjects.includes(s) ? 700 : 400 }}>
                  {SUBJ_EMOJI[s]} {s}
                </button>
              ))}
            </div>

            {/* 17.2 / 17.3 / 17.5 Per-subject settings */}
            {selSubjects.map(s => {
              const conf = subjConfs[s] || defaultSubjConf(s);
              return (
                <div key={s} style={{ background:`${SUBJ_COLOR[s]}0A`, border:`1px solid ${SUBJ_COLOR[s]}25`, borderRadius:12, padding:'10px 12px', marginBottom:8 }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:8 }}>
                    <span style={{ fontSize:12, fontWeight:700, color: SUBJ_COLOR[s] }}>{SUBJ_EMOJI[s]} {s}</span>
                    <div style={{ display:'flex', alignItems:'center', gap:6 }}>
                      <span style={{ fontSize:11, color:'#94A3B8' }}>Count:</span>
                      <input type="number" value={conf.count} min={1} max={200}
                        onChange={e => updSubj(s,'count',parseInt(e.target.value)||0)}
                        style={{ ...S.inp, width:60, padding:'4px 8px', textAlign:'center' }} />
                    </div>
                  </div>
                  {/* 17.3 — Difficulty mix */}
                  <div style={{ fontSize:10, color:'#94A3B8', marginBottom:4, fontWeight:600 }}>DIFFICULTY MIX % (17.3)</div>
                  <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:6 }}>
                    {(['easy','medium','hard'] as const).map(d => (
                      <div key={d}>
                        <div style={{ fontSize:10, color: d==='easy'?'#10B981':d==='medium'?'#F59E0B':'#EF4444', fontWeight:600, marginBottom:2 }}>{d==='easy'?'🟢':d==='medium'?'🟡':'🔴'} {d} %</div>
                        <input type="number" min={0} max={100} value={conf.difficultyMix?.[d]||0}
                          onChange={e => { const v=parseInt(e.target.value)||0; updSubj(s,'difficultyMix',{...conf.difficultyMix,[d]:v}); }}
                          style={{ ...S.inp, padding:'5px 8px', fontSize:12, textAlign:'center' }} />
                      </div>
                    ))}
                  </div>
                  {/* 17.2 — Chapter multi-select (text input comma-separated) */}
                  <div style={{ marginTop:8 }}>
                    <div style={{ fontSize:10, color:'#94A3B8', fontWeight:600, marginBottom:2 }}>CHAPTERS (17.2) — comma separated, blank = all</div>
                    <input type="text" value={conf.chapters.join(', ')}
                      onChange={e => updSubj(s,'chapters', e.target.value.split(',').map(c=>c.trim()).filter(Boolean))}
                      placeholder="e.g. Thermodynamics, Optics"
                      style={{ ...S.inp, fontSize:11 }} />
                  </div>
                </div>
              );
            })}
          </div>

          {/* 17.4 — Marking Scheme */}
          <div style={S.card}>
            <label style={S.label}>📊 Marking Scheme (17.4)</label>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:8 }}>
              <div>
                <div style={{ fontSize:10, color:'#10B981', fontWeight:700, marginBottom:4 }}>✅ Correct</div>
                <input type="number" value={marking.correct} onChange={e => setMarking(p=>({...p,correct:parseFloat(e.target.value)||0}))} style={{ ...S.inp, textAlign:'center', fontSize:13, fontWeight:700, color:'#10B981' }} />
              </div>
              <div>
                <div style={{ fontSize:10, color:'#EF4444', fontWeight:700, marginBottom:4 }}>❌ Wrong</div>
                <input type="number" value={marking.incorrect} onChange={e => setMarking(p=>({...p,incorrect:parseFloat(e.target.value)||0}))} style={{ ...S.inp, textAlign:'center', fontSize:13, fontWeight:700, color:'#EF4444' }} />
              </div>
              <div>
                <div style={{ fontSize:10, color:'#94A3B8', fontWeight:700, marginBottom:4 }}>⬜ Skip</div>
                <input type="number" value={marking.unattempted} onChange={e => setMarking(p=>({...p,unattempted:parseFloat(e.target.value)||0}))} style={{ ...S.inp, textAlign:'center', fontSize:13, fontWeight:700 }} />
              </div>
            </div>
          </div>

          {/* 17.26 — Question Formats */}
          <div style={S.card}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:fmtMode?12:0 }}>
              <label style={{ ...S.label, margin:0 }}>🎭 Question Formats (17.26)</label>
              <Toggle on={fmtMode} onToggle={() => setFmtMode(p=>!p)} />
            </div>
            {fmtMode && (
              <div>
                <div style={{ fontSize:10, color:'#94A3B8', marginBottom:8 }}>Select formats + set % (total should = 100%)</div>
                <div style={{ display:'flex', flexWrap:'wrap', gap:6, marginBottom:10 }}>
                  {ALL_FORMATS.map(fmt => {
                    const active = fmtConfs.some(f => f.format === fmt);
                    return (
                      <button key={fmt} onClick={() => toggleFormat(fmt)} style={{ fontSize:10, padding:'4px 10px', borderRadius:16, border:`1px solid ${active ? '#6366F1':'rgba(255,255,255,0.12)'}`, background: active ? 'rgba(99,102,241,0.2)' : 'rgba(255,255,255,0.04)', color: active ? '#A5B4FC':'#94A3B8', cursor:'pointer' }}>
                        {FORMAT_EMOJI[fmt]} {fmt.replace(/_/g,' ')}
                      </button>
                    );
                  })}
                </div>
                {fmtConfs.length > 0 && (
                  <div>
                    {fmtConfs.map(f => (
                      <div key={f.format} style={{ display:'flex', alignItems:'center', gap:8, marginBottom:6 }}>
                        <span style={{ fontSize:11, color:'#A5B4FC', flex:1 }}>{FORMAT_EMOJI[f.format]} {f.format.replace(/_/g,' ')}</span>
                        <input type="number" min={0} max={100} value={f.percent}
                          onChange={e => updateFmtPct(f.format, parseInt(e.target.value)||0)}
                          style={{ ...S.inp, width:60, padding:'4px 8px', textAlign:'center' }} />
                        <span style={{ fontSize:10, color:'#64748B' }}>%</span>
                      </div>
                    ))}
                    <div style={{ fontSize:10, color: fmtConfs.reduce((a,f)=>a+f.percent,0) === 100 ? '#10B981' : '#F59E0B', marginTop:4 }}>
                      Total: {fmtConfs.reduce((a,f)=>a+f.percent,0)}% {fmtConfs.reduce((a,f)=>a+f.percent,0) === 100 ? '✅' : '⚠️ should be 100'}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* 17.9 / 17.12 / 17.13 — Advanced Options */}
          <div style={S.card}>
            <label style={S.label}>⚙️ Advanced Options</label>
            <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:6 }}>
              <span style={{ fontSize:12 }}>Sets to generate (17.9)</span>
              <div style={{ display:'flex', gap:6 }}>
                {[1,2,3].map(n => (
                  <button key={n} onClick={() => setSetsCount(n)} style={{ width:34, height:34, borderRadius:8, border:`1px solid ${setsCount===n?'#6366F1':'rgba(255,255,255,0.12)'}`, background: setsCount===n ? 'rgba(99,102,241,0.25)' : 'rgba(255,255,255,0.04)', color: setsCount===n ? '#A5B4FC':'#64748B', cursor:'pointer', fontWeight:700, fontSize:13 }}>
                    {['A','A/B','A/B/C'][n-1]}
                  </button>
                ))}
              </div>
            </div>
            {/* 17.12 Exclude Used */}
            <div style={{ padding:'8px 0', borderTop:'1px solid rgba(255,255,255,0.06)', marginTop:6 }}>
              <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: exUsed ? 8 : 0 }}>
                <div>
                  <div style={{ fontSize:12, fontWeight:600 }}>Exclude already-used Qs (17.12)</div>
                  <div style={{ fontSize:10, color:'#64748B' }}>Skip Qs that appeared in previous exams</div>
                </div>
                <Toggle on={exUsed} onToggle={() => setExUsed(p=>!p)} />
              </div>
              {exUsed && (
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ fontSize:11, color:'#94A3B8' }}>Allow up to</span>
                  <input type="number" min={0} max={100} value={exUsedPct} onChange={e => setExUsedPct(parseInt(e.target.value)||0)} style={{ ...S.inp, width:60, padding:'4px 8px', textAlign:'center' }} />
                  <span style={{ fontSize:11, color:'#94A3B8' }}>% used Qs (100 = fully exclude)</span>
                </div>
              )}
            </div>
            {/* 17.13 Exclude PYQ */}
            <div style={{ padding:'8px 0', borderTop:'1px solid rgba(255,255,255,0.06)', marginTop:4 }}>
              <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: exPYQ ? 8 : 0 }}>
                <div>
                  <div style={{ fontSize:12, fontWeight:600 }}>Exclude PYQs (17.13)</div>
                  <div style={{ fontSize:10, color:'#64748B' }}>Avoid previous year questions</div>
                </div>
                <Toggle on={exPYQ} onToggle={() => setExPYQ(p=>!p)} />
              </div>
              {exPYQ && (
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ fontSize:11, color:'#94A3B8' }}>Allow up to</span>
                  <input type="number" min={0} max={100} value={exPYQPct} onChange={e => setExPYQPct(parseInt(e.target.value)||0)} style={{ ...S.inp, width:60, padding:'4px 8px', textAlign:'center' }} />
                  <span style={{ fontSize:11, color:'#94A3B8' }}>% PYQs (100 = fully exclude)</span>
                </div>
              )}
            </div>
          </div>

          {/* Exam Title */}
          <div style={S.card}>
            <label style={S.label}>📌 Exam Title</label>
            <input value={examTitle} onChange={e => setExamTitle(e.target.value)} placeholder="e.g. NEET Mock Test — June 2025" style={S.inp} />
          </div>

          {/* Generate Button */}
          <button onClick={generatePaper} disabled={loading || selSubjects.length === 0} style={{ ...S.bp, width:'100%', padding:'14px', fontSize:14, opacity: loading || selSubjects.length===0 ? 0.6 : 1, boxShadow: loading ? 'none' : '0 4px 24px rgba(99,102,241,0.35)' }}>
            {loading ? '⟳ AI Selecting Questions...' : '🤖 Generate Paper'}
          </button>
          {genError && <div style={{ color:'#EF4444', fontSize:12, marginTop:8, padding:'8px 12px', background:'rgba(239,68,68,0.08)', borderRadius:8 }}>❌ {genError}</div>}
        </div>

        {/* ══ RIGHT: LIVE PREVIEW (17.20) ══ */}
        <div>
          {/* 17.23 — Criteria Chips */}
          <div style={S.card}>
            <label style={S.label}>🏷️ Active Criteria (17.23)</label>
            <div>
              {selSubjects.map(s => (
                <span key={s} style={{ ...S.chip, background:`${SUBJ_COLOR[s]}18`, border:`1px solid ${SUBJ_COLOR[s]}35`, color: SUBJ_COLOR[s] }}>
                  {SUBJ_EMOJI[s]} {s} • {subjConfs[s]?.count || 0}Q
                </span>
              ))}
              {exUsed && <span style={{ ...S.chip, background:'rgba(239,68,68,0.12)', border:'1px solid rgba(239,68,68,0.3)', color:'#FCA5A5' }}>🚫 No Used</span>}
              {exPYQ  && <span style={{ ...S.chip, background:'rgba(245,158,11,0.12)', border:'1px solid rgba(245,158,11,0.3)', color:'#FCD34D' }}>📚 No PYQ</span>}
              {fmtConfs.length > 0 && <span style={{ ...S.chip }}>🎭 {fmtConfs.length} Formats</span>}
              <span style={{ ...S.chip }}>
                {setsCount === 1 ? '📄 Set A' : setsCount === 2 ? '📄 Sets A/B' : '📄 Sets A/B/C'}
              </span>
              <span style={{ ...S.chip, background:'rgba(16,185,129,0.12)', border:'1px solid rgba(16,185,129,0.3)', color:'#6EE7B7' }}>
                ✅+{marking.correct} ❌{marking.incorrect}
              </span>
            </div>
          </div>

          {/* Live count preview */}
          <div style={S.cardHi}>
            <label style={S.label}>📊 Paper Preview (17.5)</label>
            <div style={{ fontSize:32, fontWeight:800, color:'#6366F1', textAlign:'center', marginBottom:6 }}>{totalCountPreview}</div>
            <div style={{ fontSize:11, color:'#64748B', textAlign:'center', marginBottom:14 }}>Total Questions</div>
            {selSubjects.map(s => {
              const cnt = subjConfs[s]?.count || 0;
              const pct = totalCountPreview > 0 ? (cnt / totalCountPreview) * 100 : 0;
              return (
                <div key={s} style={{ marginBottom:8 }}>
                  <div style={{ display:'flex', justifyContent:'space-between', fontSize:11, marginBottom:3 }}>
                    <span style={{ color: SUBJ_COLOR[s], fontWeight:600 }}>{SUBJ_EMOJI[s]} {s}</span>
                    <span style={{ color:'#94A3B8' }}>{cnt}Q ({Math.round(pct)}%)</span>
                  </div>
                  <div style={{ height:6, borderRadius:3, background:'rgba(255,255,255,0.08)', overflow:'hidden' }}>
                    <div style={{ height:'100%', width:`${pct}%`, background: SUBJ_COLOR[s], borderRadius:3, transition:'width 0.3s' }} />
                  </div>
                </div>
              );
            })}
            <div style={{ marginTop:14, padding:'10px 12px', background:'rgba(255,255,255,0.04)', borderRadius:10 }}>
              <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8, fontSize:11 }}>
                <div><span style={{ color:'#64748B' }}>Total Marks:</span> <span style={{ color:'#6366F1', fontWeight:700 }}>{totalCountPreview * marking.correct}</span></div>
                <div><span style={{ color:'#64748B' }}>Sets:</span> <span style={{ color:'#A5B4FC', fontWeight:700 }}>{setsCount}</span></div>
                <div><span style={{ color:'#64748B' }}>Mode:</span> <span style={{ color:'#A5B4FC', fontWeight:700 }}>{mode.toUpperCase()}</span></div>
                <div><span style={{ color:'#64748B' }}>Marking:</span> <span style={{ color:'#6EE7B7', fontWeight:700 }}>+{marking.correct}/{marking.incorrect}</span></div>
              </div>
            </div>
          </div>

          {/* Bank availability */}
          {bankStats && (
            <div style={S.card}>
              <label style={S.label}>🏦 Bank Availability</label>
              {selSubjects.map(s => {
                const avail = bankStats.subjectWise?.[s]?.total || 0;
                const need  = subjConfs[s]?.count || 0;
                const ok    = avail >= need;
                return (
                  <div key={s} style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:6, padding:'6px 8px', borderRadius:8, background: ok ? 'rgba(16,185,129,0.06)' : 'rgba(239,68,68,0.06)' }}>
                    <span style={{ fontSize:11, color: SUBJ_COLOR[s] }}>{SUBJ_EMOJI[s]} {s}</span>
                    <span style={{ fontSize:11 }}>
                      <span style={{ color:'#94A3B8' }}>Have </span>
                      <span style={{ color: ok ? '#10B981' : '#EF4444', fontWeight:700 }}>{avail}</span>
                      <span style={{ color:'#94A3B8' }}> / Need </span>
                      <span style={{ fontWeight:700 }}>{need}</span>
                      <span style={{ marginLeft:4 }}>{ok ? '✅' : '⚠️'}</span>
                    </span>
                  </div>
                );
              })}
              {bankStats.formatWise && bankStats.formatWise.length > 0 && (
                <div style={{ marginTop:8, borderTop:'1px solid rgba(255,255,255,0.06)', paddingTop:8 }}>
                  <div style={{ fontSize:10, color:'#64748B', fontWeight:600, marginBottom:6 }}>FORMAT BREAKDOWN (17.26)</div>
                  {bankStats.formatWise.slice(0,6).map((f:any) => (
                    <div key={f._id} style={{ display:'flex', justifyContent:'space-between', fontSize:10, marginBottom:3 }}>
                      <span style={{ color:'#94A3B8' }}>{FORMAT_EMOJI[f._id] || '📝'} {f._id || 'No Format'}</span>
                      <span style={{ color:'#6366F1', fontWeight:600 }}>{f.count}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Saved templates (17.18) */}
          {savedTmpls.length > 0 && (
            <div style={S.card}>
              <label style={S.label}>💾 Saved Templates (17.18)</label>
              {savedTmpls.slice(0,3).map(t => (
                <div key={t.id} style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'7px 10px', borderRadius:8, background:'rgba(255,255,255,0.04)', marginBottom:5 }}>
                  <div>
                    <div style={{ fontSize:12, fontWeight:600 }}>{t.name}</div>
                    <div style={{ fontSize:10, color:'#64748B' }}>{t.meta?.totalQuestions || '—'} Qs · {new Date(t.savedAt).toLocaleDateString()}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── 17.21 ANIMATED PROGRESS BAR ── */}
      {(loading || progress.length > 0) && (
        <div style={{ ...S.card, marginBottom:16, borderColor:'rgba(99,102,241,0.3)' }}>
          <div style={{ marginBottom:10, display:'flex', alignItems:'center', gap:8 }}>
            <div style={{ width:16, height:16, borderRadius:'50%', border:'2px solid #6366F1', borderTopColor:'transparent', animation:'spin 0.8s linear infinite' }} />
            <span style={{ fontSize:12, fontWeight:700, color:'#A5B4FC' }}>AI Selection in Progress...</span>
          </div>
          {progress.map((p,i) => (
            <div key={i} style={{ fontSize:11, color: i === progress.length-1 ? '#E2E8F0' : '#475569', padding:'3px 0', display:'flex', alignItems:'center', gap:6 }}>
              <span style={{ color: i === progress.length-1 ? '#6366F1' : '#10B981', fontSize:10 }}>{ i === progress.length-1 ? '▶' : '✓'}</span>
              {p}
            </div>
          ))}
          <div style={{ marginTop:10, height:4, borderRadius:2, background:'rgba(255,255,255,0.08)', overflow:'hidden' }}>
            <div style={{ height:'100%', width:`${Math.min((progress.length / 5) * 100, 90)}%`, background:'linear-gradient(90deg,#6366F1,#A78BFA)', borderRadius:2, transition:'width 0.5s' }} />
          </div>
        </div>
      )}

      {/* ── 17.10 GENERATED PAPER PREVIEW ── */}
      {paper && (
        <div>
          {/* Success banner */}
          <div style={{ background:'linear-gradient(135deg,rgba(16,185,129,0.12),rgba(6,182,212,0.08))', border:'1px solid rgba(16,185,129,0.3)', borderRadius:14, padding:'14px 16px', marginBottom:16, display:'flex', justifyContent:'space-between', alignItems:'center', flexWrap:'wrap', gap:10 }}>
            <div>
              <div style={{ fontSize:14, fontWeight:700, color:'#6EE7B7' }}>✅ Paper Generated Successfully!</div>
              <div style={{ fontSize:11, color:'#64748B', marginTop:2 }}>
                {paper.meta.totalQuestions} questions · {paper.meta.setsGenerated} set(s) · Total marks: {paper.meta.totalMarks}
              </div>
            </div>
            <div style={{ display:'flex', gap:8, flexWrap:'wrap' }}>
              {/* 17.17 — Set Comparison */}
              {paper.setComparison && paper.setComparison.length > 0 && (
                <button onClick={() => setShowComp(p=>!p)} style={{ ...S.bg, fontSize:11 }}>
                  🔍 Set Comparison
                </button>
              )}
              {/* 17.19 — Export */}
              <button onClick={() => handleExport('pdf')} style={{ ...S.bg, fontSize:11 }}>📄 PDF</button>
              <button onClick={() => handleExport('excel')} style={{ ...S.bg, fontSize:11 }}>📊 Excel</button>
              {/* 17.18 — Save template */}
              <button onClick={() => setShowSaveTmpl(p=>!p)} style={{ ...S.bg, fontSize:11 }}>💾 Save Template</button>
              {/* 17.11 — Use as Exam */}
              <button onClick={() => setShowUAE(true)} style={{ ...S.bs, fontSize:12 }}>
                🚀 Use as Exam
              </button>
            </div>
          </div>

          {uaeSuccess && (
            <div style={{ padding:'10px 14px', borderRadius:10, marginBottom:12, background: uaeSuccess.startsWith('✅') ? 'rgba(16,185,129,0.12)' : 'rgba(239,68,68,0.12)', border:`1px solid ${uaeSuccess.startsWith('✅') ? 'rgba(16,185,129,0.3)' : 'rgba(239,68,68,0.3)'}`, fontSize:13, color: uaeSuccess.startsWith('✅') ? '#6EE7B7' : '#FCA5A5' }}>
              {/* 17.24 — Green checkmark animation on confirm */}
              {uaeSuccess}
            </div>
          )}

          {/* 17.17 — Set Comparison */}
          {showComp && paper.setComparison && paper.setComparison.length > 0 && (
            <div style={{ ...S.card, borderColor:'rgba(245,158,11,0.3)', marginBottom:12 }}>
              <label style={{ ...S.label, color:'#F59E0B' }}>🔍 Set Comparison (17.17)</label>
              {paper.setComparison.map((c:any, i:number) => (
                <div key={i} style={{ display:'flex', justifyContent:'space-between', padding:'8px 10px', borderRadius:8, background:'rgba(245,158,11,0.06)', marginBottom:6 }}>
                  <span style={{ fontSize:12, fontWeight:600 }}>{c.pair}</span>
                  <span style={{ fontSize:12, color: c.overlap === 0 ? '#10B981' : '#F59E0B' }}>
                    Overlap: <strong>{c.overlap}</strong> questions ({c.overlapPercent}%)
                  </span>
                </div>
              ))}
            </div>
          )}

          {/* 17.18 — Save Template form */}
          {showSaveTmpl && (
            <div style={{ ...S.card, borderColor:'rgba(99,102,241,0.3)', marginBottom:12 }}>
              <label style={S.label}>💾 Save as Template (17.18)</label>
              <input value={saveTmplName} onChange={e => setSaveTmplName(e.target.value)} placeholder="Template name..." style={{ ...S.inp, marginBottom:8 }} />
              <div style={{ display:'flex', gap:8 }}>
                <button onClick={handleSaveTemplate} style={{ ...S.bp, flex:1 }}>Save</button>
                <button onClick={() => setShowSaveTmpl(false)} style={{ ...S.bg, flex:1 }}>Cancel</button>
              </div>
            </div>
          )}

          {/* 17.22 — Set A/B/C tabs with shuffle icon */}
          <div style={{ display:'flex', gap:8, marginBottom:14, flexWrap:'wrap' }}>
            {paper.sets.map(s => (
              <button key={s.setLabel} onClick={() => setActiveSet(s.setLabel)} style={{ display:'flex', alignItems:'center', gap:6, padding:'8px 16px', borderRadius:10, border:`1px solid ${activeSet === s.setLabel ? '#6366F1' : 'rgba(255,255,255,0.1)'}`, background: activeSet === s.setLabel ? 'rgba(99,102,241,0.2)' : 'rgba(255,255,255,0.04)', color: activeSet === s.setLabel ? '#A5B4FC' : '#64748B', cursor:'pointer', fontWeight:700, fontSize:13, transition:'all 0.2s' }}>
                🔀 Set {s.setLabel}
                <span style={{ fontSize:11, fontWeight:400, color:'#64748B' }}>({s.totalQuestions}Q)</span>
              </button>
            ))}
            {/* Selection log summary */}
            {paper.selectionLog && paper.selectionLog.map((log:any) => (
              log.shortfall > 0 ? (
                <span key={log.subject} style={{ fontSize:10, padding:'6px 10px', borderRadius:8, background:'rgba(245,158,11,0.1)', color:'#FCD34D', border:'1px solid rgba(245,158,11,0.2)', display:'flex', alignItems:'center' }}>
                  ⚠️ {log.subject}: {log.found}/{log.requested} (auto-balanced 17.16)
                </span>
              ) : null
            ))}
          </div>

          {/* ── 17.30 Language Medium Toggle ── */}
          {paper && (
            <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12, padding:'10px 14px', background:'rgba(99,102,241,0.06)', border:'1px solid rgba(99,102,241,0.2)', borderRadius:12 }}>
              <span style={{ fontSize:11, color:'#94A3B8', fontWeight:700 }}>🌐 PREVIEW LANGUAGE (17.30):</span>
              {(['english','hindi','bilingual'] as const).map(m => (
                <button key={m} onClick={() => setLangMode(m)} style={{ fontSize:11, padding:'5px 12px', borderRadius:16, border:`1px solid ${langMode===m?'#6366F1':'rgba(255,255,255,0.12)'}`, background: langMode===m?'rgba(99,102,241,0.25)':'rgba(255,255,255,0.04)', color: langMode===m?'#A5B4FC':'#64748B', cursor:'pointer', fontWeight: langMode===m?700:400 }}>
                  {m==='english'?'🇬🇧 English':m==='hindi'?'🇮🇳 Hindi':'🌐 Bilingual'}
                </button>
              ))}
              <button onClick={() => setShowReport(p=>!p)} style={{ marginLeft:'auto', fontSize:11, padding:'5px 12px', borderRadius:16, border:'1px solid rgba(245,158,11,0.3)', background:'rgba(245,158,11,0.08)', color:'#FCD34D', cursor:'pointer' }}>
                📊 {showReport ? 'Hide' : 'Show'} Completeness Report (17.29)
              </button>
            </div>
          )}

          {/* ── 17.29 Data Completeness Report ── */}
          {paper && showReport && activeSetData && (
            <div style={{ marginBottom:16, background:'rgba(15,17,32,0.95)', border:'1px solid rgba(99,102,241,0.25)', borderRadius:14, overflow:'hidden' }}>
              <div style={{ padding:'12px 16px', background:'rgba(99,102,241,0.1)', borderBottom:'1px solid rgba(99,102,241,0.2)' }}>
                <span style={{ fontSize:13, fontWeight:700, color:'#A5B4FC' }}>📊 Data Completeness Report — Set {activeSet}</span>
                <span style={{ fontSize:11, color:'#64748B', marginLeft:8 }}>Required: EngText+Options+CorrectAns | Optional: Hindi+Explanation+Images</span>
              </div>
              <div style={{ overflowX:'auto' }}>
                <table style={{ width:'100%', borderCollapse:'collapse', fontSize:10 }}>
                  <thead>
                    <tr style={{ background:'rgba(255,255,255,0.03)' }}>
                      {['#','Subject','Eng✏️','Hindi✏️','Img🖼️','EngOpts','HindiOpts','OptImgs','Exp💡','Ans✅','Status','Action'].map(h=>(
                        <th key={h} style={{ padding:'7px 8px', color:'#94A3B8', fontWeight:700, textAlign:'left', borderBottom:'1px solid rgba(255,255,255,0.06)', whiteSpace:'nowrap' }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {activeSetData.questions.map((q:any) => {
                      const chk = checkQ(q);
                      const sc  = qScore(chk);
                      return (
                        <tr key={q.questionId} style={{ borderBottom:'1px solid rgba(255,255,255,0.04)', background: !sc.reqOk ? 'rgba(239,68,68,0.05)' : sc.optCount < 2 ? 'rgba(245,158,11,0.03)' : 'transparent' }}>
                          <td style={{ padding:'6px 8px', color:'#64748B' }}>{q.serialNo}</td>
                          <td style={{ padding:'6px 8px', color: SUBJ_COLOR[q.subject]||'#A5B4FC', fontWeight:600 }}>{q.subject?.slice(0,4)}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.engText?'✅':'❌'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.hindiText?'✅':'⚠️'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.mainImage?'✅':'—'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.engOptions?'✅':'❌'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.hindiOptions?'✅':'⚠️'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.optionImages?'✅':'—'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.explanation?'✅':'⚠️'}</td>
                          <td style={{ padding:'6px 8px' }}>{chk.correctAns?'✅':'❌'}</td>
                          <td style={{ padding:'6px 8px' }}>
                            <span style={{ fontSize:10, padding:'2px 7px', borderRadius:10, background: !sc.reqOk?'rgba(239,68,68,0.15)':sc.optCount>=2?'rgba(16,185,129,0.15)':'rgba(245,158,11,0.15)', color: !sc.reqOk?'#FCA5A5':sc.optCount>=2?'#6EE7B7':'#FCD34D', fontWeight:700 }}>
                              {!sc.reqOk?'❌ Missing':sc.optCount>=2?'✅ Good':'⚠️ Partial'}
                            </span>
                          </td>
                          <td style={{ padding:'6px 8px', whiteSpace:'nowrap' }}>
                            <button onClick={() => replaceQuestion(q, activeSet)} disabled={replacing===q.questionId} style={{ fontSize:9, padding:'3px 8px', borderRadius:8, border:'1px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.1)', color:'#FCA5A5', cursor:'pointer', marginRight:4 }}>
                              {replacing===q.questionId?'⟳':'🔄 Replace'}
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
              <div style={{ padding:'10px 16px', borderTop:'1px solid rgba(255,255,255,0.06)', display:'flex', gap:16, fontSize:11 }}>
                {[
                  { label:'Total', val: activeSetData.questions.length, color:'#E2E8F0' },
                  { label:'✅ Complete', val: activeSetData.questions.filter((q:any)=>qScore(checkQ(q)).reqOk&&qScore(checkQ(q)).optCount>=2).length, color:'#6EE7B7' },
                  { label:'⚠️ Partial', val: activeSetData.questions.filter((q:any)=>qScore(checkQ(q)).reqOk&&qScore(checkQ(q)).optCount<2).length, color:'#FCD34D' },
                  { label:'❌ Issues', val: activeSetData.questions.filter((q:any)=>!qScore(checkQ(q)).reqOk).length, color:'#FCA5A5' },
                  { label:'Hindi✅', val: activeSetData.questions.filter((q:any)=>checkQ(q).hindiText).length, color:'#A5B4FC' },
                  { label:'Images✅', val: activeSetData.questions.filter((q:any)=>checkQ(q).mainImage).length, color:'#67E8F9' },
                ].map(s=>(
                  <div key={s.label} style={{ textAlign:'center' }}>
                    <div style={{ fontSize:16, fontWeight:800, color:s.color }}>{s.val}</div>
                    <div style={{ color:'#64748B' }}>{s.label}</div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ── Questions list — active set */}
          {activeSetData && (
            <div>
              <div style={{ fontSize:12, color:'#64748B', marginBottom:10 }}>
                Showing Set {activeSet} — {activeSetData.totalQuestions} questions (answers hidden for students, stored in DB ✅ 17.14)
              </div>
              {activeSetData.questions.slice(0, 20).map((q: any, i: number) => (
                <div key={i} style={{ ...S.card, marginBottom:8, padding:'12px 14px' }}>
                  <div style={{ display:'flex', gap:8, marginBottom:6, flexWrap:'wrap' }}>
                    <span style={{ fontSize:10, fontWeight:700, color:'#64748B' }}>#{q.serialNo}</span>
                    <span style={{ fontSize:10, padding:'2px 8px', borderRadius:12, background:`${SUBJ_COLOR[q.subject]||'#6366F1'}18`, color: SUBJ_COLOR[q.subject]||'#A5B4FC', border:`1px solid ${SUBJ_COLOR[q.subject]||'#6366F1'}30` }}>{q.subject}</span>
                    <span style={{ fontSize:10, padding:'2px 8px', borderRadius:12, background: q.difficulty==='Hard'?'rgba(239,68,68,0.12)':q.difficulty==='Medium'?'rgba(245,158,11,0.12)':'rgba(16,185,129,0.12)', color: q.difficulty==='Hard'?'#FCA5A5':q.difficulty==='Medium'?'#FCD34D':'#6EE7B7' }}>{q.difficulty}</span>
                    {q.format && <span style={{ fontSize:10, padding:'2px 8px', borderRadius:12, background:'rgba(99,102,241,0.1)', color:'#A5B4FC' }}>{q.format.replace(/_/g,' ')}</span>}
                    {q.isPYQ && <span style={{ fontSize:10, padding:'2px 8px', borderRadius:12, background:'rgba(245,158,11,0.1)', color:'#FCD34D' }}>📚 PYQ</span>}
                    <span style={{ fontSize:10, padding:'2px 8px', borderRadius:12, background:'rgba(255,255,255,0.05)', color:'#64748B' }}>{q.type}</span>
                  </div>
                  {/* 17.27 — Main image */}
                  {q.imageUrl && (
                    <img src={q.imageUrl} alt="Q img" style={{ maxWidth:'100%', maxHeight:180, borderRadius:8, marginBottom:6, objectFit:'contain', background:'rgba(255,255,255,0.04)' }} onError={e=>(e.currentTarget.style.display='none')} />
                  )}
                  {/* 17.27 — English + Hindi text */}
                  <div style={{ fontSize:12, color:'#E2E8F0', lineHeight:1.7, marginBottom: langMode!=='english'&&q.hindiText?4:8 }}>
                    {langMode !== 'hindi' && (q.text?.slice(0,200) || '')}
                    {q.text?.length > 200 && langMode !== 'hindi' ? '...' : ''}
                  </div>
                  {(langMode === 'hindi' || langMode === 'bilingual') && q.hindiText && (
                    <div style={{ fontSize:12, color:'#C4B5FD', lineHeight:1.7, marginBottom:8, fontFamily:'serif', borderLeft:'2px solid #6366F1', paddingLeft:8 }}>
                      {q.hindiText.slice(0,200)}{q.hindiText.length>200?'...':''}
                    </div>
                  )}
                  <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:4 }}>
                    {(q.options || []).slice(0,4).map((opt: string, j: number) => {
                      const isCorrect   = (q.correct || []).includes(j);
                      const hindiOpt    = (q.hindiOptions||[])[j] || '';
                      const optImg      = (q.optionImages||[])[j] || '';
                      return (
                        <div key={j} style={{ fontSize:11, padding:'6px 8px', borderRadius:6, background: isCorrect ? 'rgba(16,185,129,0.15)' : 'rgba(255,255,255,0.03)', border: isCorrect ? '1px solid rgba(16,185,129,0.5)' : '1px solid transparent', color: isCorrect ? '#6EE7B7' : '#94A3B8' }}>
                          <div style={{ display:'flex', alignItems:'flex-start', gap:4 }}>
                            <span style={{ fontWeight:700, flexShrink:0 }}>{String.fromCharCode(65+j)})</span>
                            <div style={{ flex:1 }}>
                              {/* 17.28 — Option image */}
                              {optImg && <img src={optImg} alt="" style={{ maxWidth:'100%', maxHeight:60, borderRadius:4, marginBottom:3, display:'block' }} onError={e=>(e.currentTarget.style.display='none')} />}
                              {/* English option */}
                              {langMode !== 'hindi' && <div>{opt?.slice(0,70)}</div>}
                              {/* 17.28 — Hindi option */}
                              {(langMode === 'hindi' || langMode === 'bilingual') && hindiOpt && (
                                <div style={{ color: isCorrect?'#86EFAC':'#C4B5FD', fontSize:10, fontFamily:'serif', marginTop:2 }}>{hindiOpt.slice(0,70)}</div>
                              )}
                              {langMode === 'hindi' && !hindiOpt && <div style={{ color:'rgba(148,163,184,0.4)', fontSize:9 }}>{opt?.slice(0,70)}</div>}
                            </div>
                            {isCorrect && <span style={{ fontSize:10, flexShrink:0 }}>✅</span>}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  {(q.explanation || q.hindiExplanation) && (
                    <div style={{ marginTop:6, padding:'6px 10px', borderRadius:8, background:'rgba(99,102,241,0.08)', border:'1px solid rgba(99,102,241,0.2)', fontSize:11, color:'#A5B4FC' }}>
                      <span style={{ fontWeight:700, color:'#6366F1' }}>💡 Explanation: </span>
                      {/* 17.30 — show hindi explanation if hindi mode, else English */}
                      {langMode === 'hindi' && q.hindiExplanation ? q.hindiExplanation : q.explanation}
                      {langMode === 'bilingual' && q.hindiExplanation && q.explanation !== q.hindiExplanation && (
                        <div style={{ color:'#C4B5FD', fontFamily:'serif', marginTop:4, borderTop:'1px solid rgba(99,102,241,0.2)', paddingTop:4 }}>{q.hindiExplanation}</div>
                      )}
                    </div>
                  )}
                </div>
              ))}
              {activeSetData.questions.length > 20 && (
                <div style={{ textAlign:'center', padding:'14px', color:'#64748B', fontSize:12 }}>
                  ... and {activeSetData.questions.length - 20} more questions in Set {activeSet}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* ── 17.11 USE AS EXAM MODAL ── */}
      {showUAE && paper && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.7)', backdropFilter:'blur(8px)', zIndex:9999, display:'flex', alignItems:'center', justifyContent:'center', padding:20 }} onClick={e => e.target === e.currentTarget && setShowUAE(false)}>
          <div style={{ background:'#0F1120', border:'1px solid rgba(99,102,241,0.4)', borderRadius:20, padding:28, width:'100%', maxWidth:480, maxHeight:'90vh', overflowY:'auto' }}>
            <div style={{ fontSize:18, fontWeight:800, marginBottom:4, color:'#E2E8F0' }}>🚀 Create Exam from Paper</div>
            <div style={{ fontSize:11, color:'#64748B', marginBottom:20 }}>Exam will be in draft — answers stored securely in DB</div>

            <label style={S.label}>Exam Title</label>
            <input value={uaeTitle} onChange={e => setUaeTitle(e.target.value)} placeholder={paper.meta.examTitle || 'Enter exam title'} style={{ ...S.inp, marginBottom:12 }} />

            <label style={S.label}>Use Set</label>
            <div style={{ display:'flex', gap:8, marginBottom:12 }}>
              {paper.sets.map(s => (
                <button key={s.setLabel} onClick={() => setUaeSet(s.setLabel)} style={{ flex:1, padding:'8px', borderRadius:8, border:`1px solid ${uaeSet===s.setLabel ? '#6366F1':'rgba(255,255,255,0.1)'}`, background: uaeSet===s.setLabel ? 'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: uaeSet===s.setLabel ? '#A5B4FC':'#64748B', cursor:'pointer', fontWeight:700 }}>
                  Set {s.setLabel}
                </button>
              ))}
            </div>

            <label style={S.label}>Exam Type</label>
            <select value={uaeType} onChange={e => setUaeType(e.target.value)} style={{ ...S.inp, marginBottom:12 }}>
              {['Full Mock','Chapter Test','Part Test','Grand Test'].map(t => <option key={t} value={t}>{t}</option>)}
            </select>

            <label style={S.label}>Assign to Batch (optional, 17.11)</label>
            <input value={uaeBatch} onChange={e => setUaeBatch(e.target.value)} placeholder="e.g. Batch A, NEET 2025..." style={{ ...S.inp, marginBottom:12 }} />

            <label style={S.label}>Default Language Medium (17.30)</label>
            <div style={{ display:'flex', gap:8, marginBottom:20 }}>
              {(['english','hindi','bilingual'] as const).map(m => (
                <button key={m} onClick={() => setExamMedium(m)} style={{ flex:1, padding:'8px', borderRadius:8, border:`1px solid ${examMedium===m?'#6366F1':'rgba(255,255,255,0.1)'}`, background: examMedium===m?'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: examMedium===m?'#A5B4FC':'#64748B', cursor:'pointer', fontWeight: examMedium===m?700:400, fontSize:11 }}>
                  {m==='english'?'🇬🇧 English':m==='hindi'?'🇮🇳 Hindi':'🌐 Both'}
                </button>
              ))}
            </div>

            <div style={{ display:'flex', gap:10 }}>
              <button onClick={handleUseAsExam} disabled={uaeSaving} style={{ ...S.bs, flex:2, opacity: uaeSaving ? 0.7 : 1, fontSize:14 }}>
                {/* 17.24 — checkmark animation on confirm */}
                {uaeSaving ? '⟳ Creating...' : '✅ Create Exam'}
              </button>
              <button onClick={() => setShowUAE(false)} style={{ ...S.bg, flex:1 }}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* 17.14: answerKey + explanation stored in DB — result system uses these */}
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
