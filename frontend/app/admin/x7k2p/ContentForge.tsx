'use client';
import { useState, useEffect, useRef, useCallback } from 'react';

// ═══ Types ═══
interface ParsedQ {
  id: string;
  num: number;
  text: string;
  hindiText: string;
  options: string[];
  hindiOptions: string[];
  correct: number[];
  correctLetter: string;
  explanation: string;
  hasError: boolean;
  error: string;
  subject?: string;
  chapter?: string;
  difficulty?: string;
  type?: string;
}

type View = 'home' | 'cp_home' | 'cp_qs' | 'cp_exam';

// ═══ Design Constants ═══
const C = {
  acc:   '#4D9FFF',
  gold:  '#F59E0B',
  suc:   '#00C48C',
  err:   '#FF4D4D',
  wrn:   '#FFB84D',
  ts:    '#E8F4FF',
  dim:   '#6B8FAF',
  card:  'rgba(0,22,40,0.8)',
  bor:   'rgba(77,159,255,0.15)',
};
const S = {
  card: { background:C.card, border:`1px solid ${C.bor}`, borderRadius:16, padding:20, backdropFilter:'blur(12px)', marginBottom:14 } as React.CSSProperties,
  bp:   { background:`linear-gradient(135deg,${C.acc},#0055CC)`, color:'#fff', border:'none', borderRadius:10, padding:'10px 20px', fontWeight:700, fontSize:13, cursor:'pointer', boxShadow:'0 4px 16px rgba(77,159,255,0.3)' } as React.CSSProperties,
  bg:   { background:'rgba(77,159,255,0.1)', color:C.acc, border:`1px solid ${C.bor}`, borderRadius:10, padding:'8px 16px', fontSize:12, cursor:'pointer', fontWeight:600 } as React.CSSProperties,
  bs:   { background:'linear-gradient(135deg,#00C48C,#00955E)', color:'#fff', border:'none', borderRadius:10, padding:'10px 20px', fontWeight:700, fontSize:13, cursor:'pointer' } as React.CSSProperties,
  inp:  { width:'100%', padding:'10px 12px', background:'rgba(0,22,40,0.85)', border:`1.5px solid ${C.bor}`, borderRadius:10, color:C.ts, fontSize:12, outline:'none', boxSizing:'border-box' as const, fontFamily:'Inter,monospace', resize:'vertical' as const },
  lbl:  { fontSize:10, color:C.dim, fontWeight:700, letterSpacing:'0.5px', textTransform:'uppercase' as const, display:'block', marginBottom:5 },
};

// ═══════════════════════════════════════════════════════
// PARSING ENGINE (Feature 19.4 / 19.5 / 19.12 / 19.14)
// ═══════════════════════════════════════════════════════
function smartClean(text: string): string {
  return text
    .replace(/\*\*(.+?)\*\*/g, '$1')   // WhatsApp bold
    .replace(/\*(.+?)\*/g, '$1')        // WhatsApp italic
    .replace(/_{2}(.+?)_{2}/g, '$1')    // WhatsApp underline
    .replace(/[ \t]{2,}/g, ' ')         // Multiple spaces
    .replace(/\r\n/g, '\n')             // Windows newlines
    .replace(/[ \t]+\n/g, '\n')         // Trailing spaces
    .replace(/\n{3,}/g, '\n\n')         // Multiple blank lines
    .trim();
}

function parseAnswerKey(text: string): Record<number, string> {
  const map: Record<number, string> = {};
  if (!text.trim()) return map;
  const lines = text.trim().split('\n').map(l => l.trim()).filter(Boolean);
  // Format 1: "1. A" or "1) B" or "1: C"
  if (lines[0]?.match(/^\d+[\.\)\:\-\s]+[A-Da-d]/)) {
    lines.forEach(l => {
      const m = l.match(/^(\d+)[\.\)\:\-\s]+([A-Da-d])/);
      if (m) map[parseInt(m[1])] = m[2].toUpperCase();
    });
  }
  // Format 2: One letter per line "A\nB\nC"
  else if (lines.every(l => l.match(/^[A-Da-d]$/))) {
    lines.forEach((l, i) => { map[i + 1] = l.toUpperCase(); });
  }
  // Format 3: All together "ABCDA..."
  else if (lines.length === 1 && lines[0].match(/^[A-Da-d]+$/)) {
    lines[0].split('').forEach((ch, i) => { map[i + 1] = ch.toUpperCase(); });
  }
  // Format 4: "Q1-A, Q2-B" or "Q1:A Q2:B"
  else {
    const combined = lines.join(' ');
    const matches = combined.matchAll(/Q?\s*(\d+)\s*[\-\:\.\)]\s*([A-Da-d])/gi);
    for (const m of matches) map[parseInt(m[1])] = m[2].toUpperCase();
    // Fallback: just letters per line
    if (Object.keys(map).length === 0) {
      lines.forEach((l, i) => {
        const m = l.match(/([A-Da-d])/);
        if (m) map[i + 1] = m[1].toUpperCase();
      });
    }
  }
  return map;
}

function parseExplanations(text: string): Record<number, string> {
  const map: Record<number, string> = {};
  if (!text.trim()) return map;
  const blocks = text.split(/(?=(?:^|\n)\s*Q?\d+[\.\)\:\-\s])/im);
  blocks.forEach(block => {
    const m = block.trim().match(/^Q?\s*(\d+)[\.\)\:\-\s]+(.+)/is);
    if (m) map[parseInt(m[1])] = m[2].trim();
  });
  return map;
}

function detectDelimiter(text: string): string | null {
  const delimiters = ['---', '***', '===', '###', '///'];
  for (const d of delimiters) {
    if (text.includes(d)) return d;
  }
  return null;
}

function splitIntoBlocks(text: string, customDelim?: string): string[] {
  if (customDelim && text.includes(customDelim)) {
    return text.split(customDelim).map(s => s.trim()).filter(Boolean);
  }
  // Auto-detect format (19.12)
  // Pattern: Q1. / Q 1. / 1. / **1.** / i. / •
  const patterns = [
    { re: /(?=(?:^|\n)\s*Q\s*\.?\s*\d+[\s\.\)\:\-])/im, name: 'Q-number' },
    { re: /(?=(?:^|\n)\s*\*\*\s*Q?\d+[\s\.\)\:\-])/m,   name: 'WhatsApp-bold' },
    { re: /(?=(?:^|\n)\s*\d+[\.\)\:\-\s])/m,             name: 'numbered' },
    { re: /(?=(?:^|\n)\s*[ivxlc]+[\.\)\:\-\s])/im,       name: 'roman' },
  ];
  for (const p of patterns) {
    if (p.re.test(text)) {
      const blocks = text.split(p.re).map(s => s.trim()).filter(Boolean);
      if (blocks.length > 1) return blocks;
    }
  }
  // Fallback: double newline
  return text.split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
}

function parseOneBlock(block: string, idx: number): Omit<ParsedQ, 'id'|'hindiText'|'hindiOptions'|'explanation'|'correctLetter'|'correct'|'hasError'|'error'> {
  const lines = block.split('\n').map(l => l.trim()).filter(Boolean);
  // Extract question number
  const numMatch = lines[0]?.match(/^(?:\*{1,2})?\s*Q?\s*(\d+)[\s\.\)\:\-](?:\*{1,2})?/i);
  const qNum = numMatch ? parseInt(numMatch[1]) : idx + 1;
  // Extract text (remove number prefix + WhatsApp formatting)
  let qText = lines[0]?.replace(/^(?:\*{1,2})?\s*Q?\s*\d+[\s\.\)\:\-](?:\*{1,2})?\s*/i, '').replace(/\*\*/g,'').trim() || '';
  // Collect continuation text until options
  let i = 1;
  while (i < lines.length) {
    const l = lines[i];
    if (l.match(/^(?:\*{1,2})?\s*[\(\[]?[A-Da-d][\)\]\.\:\-\s]/)) break;
    qText += ' ' + l.replace(/\*\*/g,'');
    i++;
  }
  // Extract options
  const options: string[] = [];
  while (i < lines.length) {
    const l = lines[i];
    const m = l.match(/^(?:\*{1,2})?\s*[\(\[]?\s*([A-Da-d])\s*[\)\]\.\:\-\s]+(?:\*{1,2})?\s*(.+)/i);
    if (m) { options.push(m[2].replace(/\*\*/g,'').trim()); }
    i++;
  }
  return { num: qNum, text: qText.trim(), options, subject:undefined, chapter:undefined, difficulty:undefined, type:undefined };
}

function parseHindiBlocks(hindiText: string, customDelim?: string): Record<number, { text:string; options:string[] }> {
  const map: Record<number, { text:string; options:string[] }> = {};
  if (!hindiText.trim()) return map;
  const blocks = splitIntoBlocks(hindiText, customDelim);
  blocks.forEach((block, idx) => {
    const parsed = parseOneBlock(block, idx);
    map[parsed.num] = { text: parsed.text, options: parsed.options };
  });
  return map;
}

function parseAll(engText: string, hindiText: string, ansKeyText: string, explText: string, customDelim: string): ParsedQ[] {
  if (!engText.trim()) return [];
  const delim = customDelim || detectDelimiter(engText) || undefined;
  const blocks = splitIntoBlocks(engText, delim);
  const ansMap  = parseAnswerKey(ansKeyText);
  const explMap = parseExplanations(explText);
  const hindiMap = parseHindiBlocks(hindiText, delim);

  return blocks.map((block, idx) => {
    const base = parseOneBlock(block, idx);
    const hindi = hindiMap[base.num] || { text:'', options:[] };
    const ansLetter = ansMap[base.num] || '';
    const correctIdx = ansLetter ? ['A','B','C','D'].indexOf(ansLetter) : -1;
    const correct = correctIdx >= 0 ? [correctIdx] : [];
    const hasEngOpts = base.options.length >= 2;
    const hasAns = correct.length > 0;
    const errors: string[] = [];
    if (!base.text) errors.push('English text missing');
    if (!hasEngOpts) errors.push('Options not detected (<2)');
    if (!hasAns) errors.push(`Answer missing for Q${base.num}`);
    return {
      id:           'q_'+base.num+'_'+idx,
      num:          base.num,
      text:         base.text,
      hindiText:    hindi.text,
      options:      base.options,
      hindiOptions: hindi.options,
      correct,
      correctLetter: ansLetter,
      explanation:  explMap[base.num] || '',
      hasError:     errors.length > 0,
      error:        errors.join('; '),
    };
  }).sort((a,b) => a.num - b.num);
}

// ═══════════════════════════════════════════════════════
// VIEWS
// ═══════════════════════════════════════════════════════

// ── Premium 3-Card Home (Feature 19.22)
function HomeView({ onNav }: { onNav:(v:View)=>void }) {
  const cards = [
    { icon:'📋', title:'Copy-Paste Method', sub:'Paste raw question text — AI auto-parses, syncs answers & explanations', grad:'linear-gradient(135deg,#4D9FFF22,#0055CC11)', bor:'rgba(77,159,255,0.3)', accent:'#4D9FFF', view:'cp_home' as View, badge:'Feature 19' },
    { icon:'📊', title:'Excel / CSV Upload', sub:'Upload structured .xlsx or .csv file with questions in columns', grad:'linear-gradient(135deg,#00C48C22,#00955E11)', bor:'rgba(0,196,140,0.3)', accent:'#00C48C', view:null, badge:'Feature 20' },
    { icon:'📄', title:'PDF Parsing', sub:'Upload PDF — AI extracts questions, options and answers automatically', grad:'linear-gradient(135deg,#F59E0B22,#D9770011)', bor:'rgba(245,158,11,0.3)', accent:'#F59E0B', view:null, badge:'Feature 21' },
  ];
  return (
    <div style={{ maxWidth:900, margin:'0 auto' }}>
      <div style={{ textAlign:'center', marginBottom:36 }}>
        <div style={{ fontSize:28, fontWeight:800, background:'linear-gradient(135deg,#4D9FFF,#A78BFA)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', marginBottom:8 }}>
          ⚡ Creation Studio
        </div>
        <div style={{ fontSize:14, color:C.dim }}>Choose your preferred method to create questions at scale</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit,minmax(260px,1fr))', gap:20 }}>
        {cards.map(card => (
          <div key={card.title}
            onClick={() => card.view && onNav(card.view)}
            style={{ background:card.grad, border:`1px solid ${card.bor}`, borderRadius:20, padding:'32px 24px', cursor:card.view?'pointer':'default', opacity:card.view?1:0.65, transition:'all 0.25s', backdropFilter:'blur(16px)', position:'relative', overflow:'hidden' }}
            onMouseEnter={e => card.view && ((e.currentTarget as HTMLDivElement).style.transform='translateY(-4px)', (e.currentTarget as HTMLDivElement).style.boxShadow=`0 16px 40px ${card.bor}`)}
            onMouseLeave={e => ((e.currentTarget as HTMLDivElement).style.transform='translateY(0)', (e.currentTarget as HTMLDivElement).style.boxShadow='none')}
          >
            <div style={{ position:'absolute', top:14, right:14, fontSize:10, padding:'3px 10px', borderRadius:20, background:`${card.accent}22`, border:`1px solid ${card.accent}44`, color:card.accent, fontWeight:700 }}>{card.badge}</div>
            <div style={{ fontSize:40, marginBottom:16 }}>{card.icon}</div>
            <div style={{ fontSize:17, fontWeight:800, color:C.ts, marginBottom:8 }}>{card.title}</div>
            <div style={{ fontSize:12, color:C.dim, lineHeight:1.7 }}>{card.sub}</div>
            {card.view && <div style={{ marginTop:20, fontSize:12, color:card.accent, fontWeight:700 }}>Get Started →</div>}
            {!card.view && <div style={{ marginTop:20, fontSize:11, color:C.dim, fontStyle:'italic' }}>Coming soon</div>}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Copy-Paste Sub-Home (2 cards)
function CopyPasteHome({ onNav }: { onNav:(v:View)=>void }) {
  const cards = [
    { icon:'📚', title:'Upload to QB / PYQ Bank', sub:'Parse pasted text → auto-sync answers & explanations → bulk save to Question Bank or PYQ Bank', grad:'linear-gradient(135deg,#4D9FFF22,#0055CC11)', bor:'rgba(77,159,255,0.3)', accent:'#4D9FFF', view:'cp_qs' as View },
    { icon:'🎯', title:'Create Exam', sub:'Paste questions directly → auto-parse → generate a live exam with answer key (Coming Soon)', grad:'linear-gradient(135deg,#A78BFA22,#7C3AED11)', bor:'rgba(167,139,250,0.3)', accent:'#A78BFA', view:'cp_exam' as View },
  ];
  return (
    <div style={{ maxWidth:760, margin:'0 auto' }}>
      <button onClick={() => onNav('home')} style={{ ...S.bg, marginBottom:24, fontSize:11 }}>← Back to Creation Studio</button>
      <div style={{ textAlign:'center', marginBottom:32 }}>
        <div style={{ fontSize:24, fontWeight:800, color:C.ts, marginBottom:6 }}>📋 Copy-Paste Method</div>
        <div style={{ fontSize:13, color:C.dim }}>What would you like to create from pasted content?</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:20 }}>
        {cards.map(card => (
          <div key={card.title}
            onClick={() => onNav(card.view)}
            style={{ background:card.grad, border:`1px solid ${card.bor}`, borderRadius:20, padding:'36px 24px', cursor:'pointer', transition:'all 0.25s', backdropFilter:'blur(16px)', textAlign:'center' }}
            onMouseEnter={e => ((e.currentTarget as HTMLDivElement).style.transform='translateY(-4px)', (e.currentTarget as HTMLDivElement).style.boxShadow=`0 16px 40px ${card.bor}`)}
            onMouseLeave={e => ((e.currentTarget as HTMLDivElement).style.transform='translateY(0)', (e.currentTarget as HTMLDivElement).style.boxShadow='none')}
          >
            <div style={{ fontSize:48, marginBottom:16 }}>{card.icon}</div>
            <div style={{ fontSize:16, fontWeight:800, color:C.ts, marginBottom:10 }}>{card.title}</div>
            <div style={{ fontSize:12, color:C.dim, lineHeight:1.7 }}>{card.sub}</div>
            <div style={{ marginTop:20, fontSize:12, color:card.accent, fontWeight:700 }}>Open →</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Create Exam Placeholder
function CreateExamView({ onNav }: { onNav:(v:View)=>void }) {
  return (
    <div style={{ textAlign:'center', padding:'60px 20px' }}>
      <button onClick={() => onNav('cp_home')} style={{ ...S.bg, marginBottom:32 }}>← Back</button>
      <div style={{ fontSize:40, marginBottom:16 }}>🎯</div>
      <div style={{ fontSize:20, fontWeight:700, color:C.ts, marginBottom:10 }}>Create Exam from Paste</div>
      <div style={{ fontSize:13, color:C.dim }}>This feature is coming soon. Base is ready for integration.</div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════
// MAIN QB UPLOAD VIEW — Full Feature 19
// ═══════════════════════════════════════════════════════
function CopyPasteQBView({ API, token, onNav }: { API:string; token:string; onNav:(v:View)=>void }) {
  const getToken = () => typeof window !== 'undefined' ? localStorage.getItem('pr_token')||'' : token;

  // Inputs
  const [engText,    setEngText]    = useState('');
  const [hindiText,  setHindiText]  = useState('');
  const [ansKey,     setAnsKey]     = useState('');
  const [explText,   setExplText]   = useState('');
  const [customDelim,setCustomDelim]= useState('');

  // Parse state
  const [parsedQs,   setParsedQs]   = useState<ParsedQ[]>([]);
  const [isParsing,  setIsParsing]  = useState(false);
  const [parseAnim,  setParseAnim]  = useState(false);

  // Bulk assign (19.10)
  const [subject,    setSubject]    = useState('Physics');
  const [chapter,    setChapter]    = useState('');
  const [difficulty, setDifficulty] = useState('Medium');
  const [qtype,      setQtype]      = useState('SCQ');

  // Upload target (19.23)
  const [target,     setTarget]     = useState<'qs_bank'|'pyq_bank'>('qs_bank');

  // Edit (19.9)
  const [editingQ,   setEditingQ]   = useState<ParsedQ|null>(null);
  const [editDraft,  setEditDraft]  = useState<ParsedQ|null>(null);

  // Drag (19.15)
  const [dragIdx,    setDragIdx]    = useState<number|null>(null);
  const [dragOverIdx,setDragOverIdx]= useState<number|null>(null);

  // Save
  const [saving,     setSaving]     = useState(false);
  const [saveMsg,    setSaveMsg]    = useState('');
  const [tooltip,    setTooltip]    = useState<{idx:number;msg:string}|null>(null);

  // Auto-parse on text change (19.4 / 19.5 / 19.19)
  useEffect(() => {
    if (!engText.trim()) { setParsedQs([]); return; }
    setIsParsing(true);
    setParseAnim(true);
    const t = setTimeout(() => {
      const result = parseAll(engText, hindiText, ansKey, explText, customDelim);
      // Apply bulk subject/difficulty
      const withMeta = result.map(q => ({ ...q, subject: q.subject||subject, chapter: q.chapter||chapter, difficulty: q.difficulty||difficulty, type: q.type||qtype }));
      setParsedQs(withMeta);
      setIsParsing(false);
      setTimeout(() => setParseAnim(false), 500);
    }, 400);
    return () => clearTimeout(t);
  }, [engText, hindiText, ansKey, explText, customDelim]);

  // Re-apply bulk meta when changed (19.10)
  const applyBulkMeta = () => {
    setParsedQs(prev => prev.map(q => ({ ...q, subject, chapter, difficulty, type:qtype })));
  };

  // Smart Clean (19.13)
  const handleSmartClean = () => {
    setEngText(smartClean(engText));
    setHindiText(smartClean(hindiText));
    setAnsKey(ansKey.trim());
    setExplText(explText.trim());
  };

  // Drag-drop (19.15)
  const handleDragStart = (idx:number) => setDragIdx(idx);
  const handleDragOver  = (e:React.DragEvent, idx:number) => { e.preventDefault(); setDragOverIdx(idx); };
  const handleDrop      = (idx:number) => {
    if (dragIdx === null || dragIdx === idx) { setDragIdx(null); setDragOverIdx(null); return; }
    const arr = [...parsedQs];
    const [moved] = arr.splice(dragIdx, 1);
    arr.splice(idx, 0, moved);
    setParsedQs(arr.map((q,i) => ({...q, num:i+1})));
    setDragIdx(null); setDragOverIdx(null);
  };

  // Edit save (19.9)
  const saveEdit = () => {
    if (!editDraft) return;
    setParsedQs(prev => prev.map(q => q.id === editDraft.id ? editDraft : q));
    setEditingQ(null); setEditDraft(null);
  };

  // Final save (19.11)
  const handleSave = async () => {
    const toSave = parsedQs.filter(q => !q.hasError || q.text);
    if (!toSave.length) return;
    setSaving(true); setSaveMsg('');
    try {
      const res = await fetch(`${API}/api/questions/bulk-paste-save`, {
        method:'POST',
        headers:{ 'Content-Type':'application/json', Authorization:`Bearer ${getToken()}` },
        body: JSON.stringify({ questions:toSave, target, subject, chapter, difficulty, type:qtype })
      });
      const d = await res.json();
      setSaveMsg(d.success ? `✅ ${d.saved} questions saved to ${target==='pyq_bank'?'PYQ Bank':'Question Bank'}!` : `❌ ${d.message}`);
    } catch(e:any) { setSaveMsg('❌ '+e.message); }
    setSaving(false);
  };

  const errQs   = parsedQs.filter(q => q.hasError).length;
  const goodQs  = parsedQs.length - errQs;

  return (
    <div style={{ color:C.ts, fontFamily:'Inter,sans-serif' }}>
      {/* Header */}
      <div style={{ display:'flex', alignItems:'center', gap:12, marginBottom:20 }}>
        <button onClick={()=>onNav('cp_home')} style={{ ...S.bg, fontSize:11 }}>← Back</button>
        <div>
          <div style={{ fontSize:20, fontWeight:800, background:`linear-gradient(135deg,${C.acc},#A78BFA)`, WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>
            📋 Upload via Copy-Paste
          </div>
          <div style={{ fontSize:11, color:C.dim }}>Paste questions → auto-parse → save to QB / PYQ Bank · Feature 19</div>
        </div>
        {/* 19.20 Counter badge */}
        {parsedQs.length > 0 && (
          <div style={{ marginLeft:'auto', display:'flex', gap:8 }}>
            <span style={{ padding:'4px 12px', borderRadius:20, background:'rgba(77,159,255,0.15)', border:`1px solid ${C.bor}`, fontSize:12, fontWeight:700, color:C.acc }}>
              📊 {parsedQs.length} detected
            </span>
            {goodQs > 0 && <span style={{ padding:'4px 12px', borderRadius:20, background:'rgba(0,196,140,0.12)', border:'1px solid rgba(0,196,140,0.3)', fontSize:12, fontWeight:700, color:C.suc }}>{goodQs} ✅</span>}
            {errQs > 0  && <span style={{ padding:'4px 12px', borderRadius:20, background:'rgba(255,77,77,0.1)', border:'1px solid rgba(255,77,77,0.3)', fontSize:12, fontWeight:700, color:C.err }}>{errQs} ❌</span>}
          </div>
        )}
      </div>

      {/* 19.17 Split Screen */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:16, marginBottom:16 }}>

        {/* ── LEFT: Input Textareas ── */}
        <div>
          {/* Tools row */}
          <div style={{ display:'flex', gap:8, marginBottom:10, flexWrap:'wrap' }}>
            {/* 19.13 Smart Clean */}
            <button onClick={handleSmartClean} style={{ ...S.bg, fontSize:11, padding:'6px 12px' }}>🧹 Smart Clean (19.13)</button>
            {/* 19.16 Custom delimiter */}
            <input value={customDelim} onChange={e=>setCustomDelim(e.target.value)} placeholder="Custom delimiter e.g. ---" style={{ ...S.inp, width:170, padding:'5px 10px', fontSize:11 }} />
          </div>

          {/* 19.1 English Questions textarea */}
          <div style={{ marginBottom:10 }}>
            <label style={S.lbl}>📝 English Questions Text (19.1) — Paste Q1. Q2. format</label>
            <textarea value={engText} onChange={e=>setEngText(e.target.value)} rows={10} placeholder={`Paste questions here...\n\nQ1. What is osmosis?\nA) Water moves high to low\nB) Water moves low to high\nC) Both A and B\nD) None\n\nQ2. Newton's first law states...`}
              style={{ ...S.inp, height:200, lineHeight:1.6 }} />
          </div>

          {/* 19.1 Hindi Questions textarea */}
          <div style={{ marginBottom:10 }}>
            <label style={S.lbl}>🇮🇳 Hindi Questions Text (19.1) — Optional, same Q numbering</label>
            <textarea value={hindiText} onChange={e=>setHindiText(e.target.value)} rows={6} placeholder="Q1. ऑस्मोसिस क्या है?\nA) पानी उच्च से निम्न की ओर जाता है\n..."
              style={{ ...S.inp, height:130, lineHeight:1.6 }} />
          </div>

          {/* 19.2 Answer Key */}
          <div style={{ marginBottom:10 }}>
            <label style={S.lbl}>🔑 Answer Key (19.2) — A/B/C/D per line OR "1. A" OR "ABCD..."</label>
            <textarea value={ansKey} onChange={e=>setAnsKey(e.target.value)} rows={5} placeholder={"A\nB\nA\nC\nD\n\nOR:\n1. A\n2. B\n3. A\n\nOR: ABACD"}
              style={{ ...S.inp, height:110, fontFamily:'monospace', color:'#6EE7B7' }} />
          </div>

          {/* 19.3 Explanation (Optional) */}
          <div style={{ marginBottom:10 }}>
            <label style={S.lbl}>💡 Explanations (19.3) — Optional · Format: "1. explanation text"</label>
            <textarea value={explText} onChange={e=>setExplText(e.target.value)} rows={5} placeholder={"1. Osmosis is the movement of water...\n2. Newton's first law also called law of inertia...\n(Leave blank if not available)"}
              style={{ ...S.inp, height:110, color:'#FCA5A5' }} />
          </div>

          {/* 19.10 Bulk Assign */}
          <div style={{ ...S.card, padding:'14px 16px' }}>
            <label style={{ ...S.lbl, marginBottom:10 }}>⚙️ Bulk Assign to All Questions (19.10)</label>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8, marginBottom:8 }}>
              <div>
                <label style={S.lbl}>Subject</label>
                <select value={subject} onChange={e=>setSubject(e.target.value)} style={{ ...S.inp }}>
                  {['Physics','Chemistry','Biology','Mathematics','Zoology','Botany','General'].map(s=><option key={s} value={s}>{s}</option>)}
                </select>
              </div>
              <div>
                <label style={S.lbl}>Difficulty</label>
                <select value={difficulty} onChange={e=>setDifficulty(e.target.value)} style={{ ...S.inp }}>
                  {['Easy','Medium','Hard'].map(d=><option key={d} value={d}>{d}</option>)}
                </select>
              </div>
              <div>
                <label style={S.lbl}>Chapter</label>
                <input value={chapter} onChange={e=>setChapter(e.target.value)} placeholder="e.g. Thermodynamics" style={{ ...S.inp }} />
              </div>
              <div>
                <label style={S.lbl}>Type</label>
                <select value={qtype} onChange={e=>setQtype(e.target.value)} style={{ ...S.inp }}>
                  {['SCQ','MSQ','Integer'].map(t=><option key={t} value={t}>{t}</option>)}
                </select>
              </div>
            </div>
            <button onClick={applyBulkMeta} style={{ ...S.bg, fontSize:11, width:'100%' }}>↻ Apply to All Parsed Questions</button>
          </div>

          {/* 19.23 Upload Target */}
          <div style={{ ...S.card, padding:'14px 16px' }}>
            <label style={S.lbl}>📤 Upload Target (19.23)</label>
            <div style={{ display:'flex', gap:8 }}>
              {[{v:'qs_bank',l:'📚 Question Bank'},{v:'pyq_bank',l:'📜 PYQ Bank (base ready)'}].map(t=>(
                <button key={t.v} onClick={()=>setTarget(t.v as any)} style={{ flex:1, padding:'9px', borderRadius:9, border:`1px solid ${target===t.v?C.acc:C.bor}`, background:target===t.v?'rgba(77,159,255,0.15)':'transparent', color:target===t.v?C.acc:C.dim, cursor:'pointer', fontSize:12, fontWeight:700, transition:'all 0.2s' }}>
                  {t.l}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* ── RIGHT: Live Preview ── */}
        <div>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10 }}>
            <span style={{ fontSize:12, fontWeight:700, color:C.ts }}>
              {/* 19.19 parsing animation */}
              {isParsing ? '⟳ Parsing...' : `👁️ Live Preview (${parsedQs.length} questions)`}
            </span>
            {/* 19.18 color legend */}
            <div style={{ display:'flex', gap:8, fontSize:10 }}>
              {[['#E8F4FF','Q Text'],['#93C5FD','Options'],['#6EE7B7','Answer'],['#FCA5A5','Expl'],['#F87171','Error']].map(([col,lbl])=>(
                <span key={lbl} style={{ display:'flex', alignItems:'center', gap:3 }}>
                  <span style={{ width:8, height:8, borderRadius:2, background:col, display:'inline-block' }}/>
                  <span style={{ color:C.dim }}>{lbl}</span>
                </span>
              ))}
            </div>
          </div>

          {/* 19.19 Line parsing animation */}
          {parseAnim && (
            <div style={{ height:3, borderRadius:2, background:`linear-gradient(90deg,${C.acc},#A78BFA,${C.acc})`, backgroundSize:'200%', animation:'shimmer 1s linear infinite', marginBottom:8 }} />
          )}

          <div style={{ height:'calc(100vh - 280px)', overflowY:'auto', paddingRight:4 }}>
            {parsedQs.length === 0 && !isParsing && (
              <div style={{ textAlign:'center', padding:'60px 20px', color:C.dim }}>
                <div style={{ fontSize:32, marginBottom:8 }}>📋</div>
                <div>Paste questions on the left — live preview appears here</div>
                <div style={{ fontSize:11, marginTop:8, color:'rgba(107,143,175,0.6)' }}>Supports Q1./1./WhatsApp bold format</div>
              </div>
            )}

            {/* 19.15 Drag-drop reorder */}
            {parsedQs.map((q, idx) => (
              <div key={q.id}
                draggable
                onDragStart={()=>handleDragStart(idx)}
                onDragOver={e=>handleDragOver(e,idx)}
                onDrop={()=>handleDrop(idx)}
                onDragEnd={()=>{setDragIdx(null);setDragOverIdx(null);}}
                style={{
                  border:`1px solid ${q.hasError?'rgba(255,77,77,0.45)':dragOverIdx===idx?C.acc:C.bor}`,
                  borderRadius:10, padding:'10px 12px', marginBottom:8,
                  background: q.hasError?'rgba(255,77,77,0.05)':'rgba(0,22,40,0.7)',
                  cursor:'grab', transition:'all 0.15s',
                  opacity: dragIdx===idx ? 0.5 : 1,
                  boxShadow: dragOverIdx===idx ? `0 0 0 2px ${C.acc}` : 'none'
                }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:6 }}>
                  <div style={{ display:'flex', gap:6, alignItems:'center', flexWrap:'wrap' }}>
                    <span style={{ fontSize:10, color:C.acc, fontWeight:800 }}>Q{q.num}</span>
                    <span style={{ fontSize:9, padding:'2px 7px', borderRadius:8, background:'rgba(77,159,255,0.1)', color:C.acc }}>{q.subject||subject}</span>
                    <span style={{ fontSize:9, padding:'2px 7px', borderRadius:8, background:'rgba(0,22,40,0.5)', color:C.dim }}>{q.difficulty||difficulty}</span>
                    <span style={{ fontSize:9, padding:'2px 7px', borderRadius:8, background:'rgba(0,22,40,0.5)', color:C.dim }}>{q.type||qtype}</span>
                    {/* 19.7 Error badge */}
                    {q.hasError && (
                      <span
                        style={{ fontSize:9, padding:'2px 7px', borderRadius:8, background:'rgba(255,77,77,0.15)', color:'#FF4D4D', cursor:'help', fontWeight:700 }}
                        onMouseEnter={()=>setTooltip({idx,msg:q.error})}
                        onMouseLeave={()=>setTooltip(null)}
                        title={q.error}
                      >
                        {/* 19.21 Error tooltip */}
                        ⚠️ {q.error.length>30?q.error.slice(0,30)+'...':q.error}
                      </span>
                    )}
                  </div>
                  <div style={{ display:'flex', gap:4 }}>
                    {/* 19.9 Edit individual */}
                    <button onClick={()=>{setEditingQ(q);setEditDraft({...q});}} style={{ fontSize:10, padding:'3px 8px', borderRadius:6, border:`1px solid ${C.bor}`, background:'transparent', color:C.acc, cursor:'pointer' }}>✏️ Edit</button>
                    <button onClick={()=>setParsedQs(prev=>prev.filter(x=>x.id!==q.id))} style={{ fontSize:10, padding:'3px 8px', borderRadius:6, border:'1px solid rgba(255,77,77,0.3)', background:'transparent', color:'#FF4D4D', cursor:'pointer' }}>✕</button>
                    <span style={{ fontSize:12, cursor:'grab', color:C.dim, paddingLeft:4 }}>⠿</span>
                  </div>
                </div>

                {/* 19.18 Color-coded: Q text white */}
                <div style={{ fontSize:11, color:'#E8F4FF', lineHeight:1.6, marginBottom:q.options.length?6:0 }}>{q.text?.slice(0,150)}{q.text?.length>150?'...':''}</div>
                {q.hindiText && <div style={{ fontSize:10, color:'#C4B5FD', lineHeight:1.5, marginBottom:4, fontFamily:'serif' }}>{q.hindiText?.slice(0,100)}</div>}

                {/* 19.18 Options: blue */}
                {q.options.length > 0 && (
                  <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:3, marginBottom:4 }}>
                    {q.options.slice(0,4).map((opt,j) => {
                      const isCor = q.correct.includes(j);
                      return (
                        <div key={j} style={{ fontSize:10, padding:'3px 7px', borderRadius:5, background:isCor?'rgba(0,196,140,0.12)':'rgba(77,159,255,0.08)', border:`1px solid ${isCor?'rgba(0,196,140,0.4)':'rgba(77,159,255,0.15)'}`, color:isCor?C.suc:'#93C5FD' }}>
                          {/* 19.18 Answer: green, Options: blue */}
                          <b>{String.fromCharCode(65+j)})</b> {opt.slice(0,45)} {isCor&&'✅'}
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* 19.6 Validation indicators */}
                <div style={{ display:'flex', gap:6, fontSize:9, flexWrap:'wrap' }}>
                  <span style={{ color: q.text?C.suc:C.err }}>Eng{q.text?'✓':'✗'}</span>
                  <span style={{ color: q.hindiText?C.suc:C.dim }}>Hindi{q.hindiText?'✓':'⚠'}</span>
                  <span style={{ color: q.options.length>=2?C.suc:C.err }}>Opts{q.options.length>=2?'✓':'✗'}</span>
                  <span style={{ color: q.correct.length?C.suc:C.err }}>Ans{q.correct.length?`(${q.correctLetter})✓`:'✗'}</span>
                  {/* 19.18 Explanation: light pink */}
                  <span style={{ color: q.explanation?'#FCA5A5':C.dim }}>Expl{q.explanation?'✓':'—'}</span>
                </div>
              </div>
            ))}
          </div>

          {/* 19.8 Preview save bar */}
          {parsedQs.length > 0 && (
            <div style={{ marginTop:12, padding:'12px 14px', background:'rgba(0,22,40,0.9)', border:`1px solid ${C.bor}`, borderRadius:12, display:'flex', justifyContent:'space-between', alignItems:'center', gap:10, flexWrap:'wrap' }}>
              <div style={{ fontSize:11, color:C.dim }}>
                {/* 19.11 Final bulk save */}
                {goodQs} ready · {errQs} errors · Target: <span style={{ color:C.acc, fontWeight:700 }}>{target==='pyq_bank'?'PYQ Bank':'QB'}</span>
              </div>
              <div style={{ display:'flex', gap:8 }}>
                <button onClick={()=>setParsedQs(parseAll(engText,hindiText,ansKey,explText,customDelim))} style={{ ...S.bg, fontSize:11, padding:'7px 14px' }}>🔄 Re-parse</button>
                <button onClick={handleSave} disabled={saving||goodQs===0} style={{ ...S.bs, opacity:saving||goodQs===0?0.6:1, fontSize:12 }}>
                  {saving?'⟳ Saving...':'💾 Save '+goodQs+' Questions'}
                </button>
              </div>
            </div>
          )}
          {saveMsg && <div style={{ marginTop:8, padding:'8px 12px', borderRadius:9, fontSize:12, background:saveMsg.startsWith('✅')?'rgba(0,196,140,0.1)':'rgba(255,77,77,0.1)', color:saveMsg.startsWith('✅')?C.suc:C.err }}>{saveMsg}</div>}
        </div>
      </div>

      {/* 19.9 Edit Modal */}
      {editingQ && editDraft && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.85)', backdropFilter:'blur(8px)', zIndex:9999, display:'flex', alignItems:'center', justifyContent:'center', padding:16 }}
          onClick={e=>e.target===e.currentTarget&&setEditingQ(null)}>
          <div style={{ width:'100%', maxWidth:580, maxHeight:'90vh', overflowY:'auto', background:'#020D18', border:`1px solid ${C.bor}`, borderRadius:18, padding:24 }}>
            <div style={{ fontSize:15, fontWeight:700, color:C.ts, marginBottom:16 }}>✏️ Edit Q{editDraft.num}</div>
            <label style={S.lbl}>English Text</label>
            <textarea value={editDraft.text} onChange={e=>setEditDraft(p=>p?{...p,text:e.target.value}:null)} rows={3} style={{ ...S.inp, marginBottom:10 }}/>
            <label style={S.lbl}>Hindi Text</label>
            <textarea value={editDraft.hindiText} onChange={e=>setEditDraft(p=>p?{...p,hindiText:e.target.value}:null)} rows={2} style={{ ...S.inp, marginBottom:10 }}/>
            {editDraft.options.map((opt,j)=>(
              <div key={j} style={{ display:'flex', gap:8, alignItems:'center', marginBottom:6 }}>
                <span style={{ color:C.acc, fontWeight:700, width:20 }}>{String.fromCharCode(65+j)})</span>
                <input value={opt} onChange={e=>{const o=[...editDraft.options];o[j]=e.target.value;setEditDraft(p=>p?{...p,options:o}:null);}} style={{ ...S.inp }}/>
                <button onClick={()=>{const correct=editDraft.correct.includes(j)?editDraft.correct.filter(x=>x!==j):[...editDraft.correct,j];const cl=['A','B','C','D'][correct[0]]||'';setEditDraft(p=>p?{...p,correct,correctLetter:cl}:null);}} style={{ fontSize:11, padding:'4px 8px', borderRadius:6, border:`1px solid ${editDraft.correct.includes(j)?'rgba(0,196,140,0.5)':C.bor}`, background:editDraft.correct.includes(j)?'rgba(0,196,140,0.1)':'transparent', color:editDraft.correct.includes(j)?C.suc:C.dim, cursor:'pointer' }}>
                  {editDraft.correct.includes(j)?'✅ Correct':'Set Correct'}
                </button>
              </div>
            ))}
            <label style={{ ...S.lbl, marginTop:8 }}>Explanation</label>
            <textarea value={editDraft.explanation} onChange={e=>setEditDraft(p=>p?{...p,explanation:e.target.value}:null)} rows={2} style={{ ...S.inp, marginBottom:12 }}/>
            <div style={{ display:'flex', gap:8 }}>
              <button onClick={saveEdit} style={{ ...S.bs, flex:1 }}>💾 Save Changes</button>
              <button onClick={()=>{setEditingQ(null);setEditDraft(null);}} style={{ ...S.bg, flex:1 }}>Cancel</button>
            </div>
          </div>
        </div>
      )}
      <style>{`@keyframes shimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}`}</style>
    </div>
  );
}

// ═══════════════════════════════════════════════════════
// MAIN ContentForge Component
// ═══════════════════════════════════════════════════════
export default function ContentForge({ API, token }: { API:string; token:string }) {
  const [view, setView] = useState<View>('home');
  return (
    <div style={{ color:C.ts, fontFamily:'Inter,system-ui,sans-serif', minHeight:'70vh' }}>
      {view === 'home'    && <HomeView onNav={setView} />}
      {view === 'cp_home' && <CopyPasteHome onNav={setView} />}
      {view === 'cp_qs'   && <CopyPasteQBView API={API} token={token} onNav={setView} />}
      {view === 'cp_exam' && <CreateExamView onNav={setView} />}
    </div>
  );
}
