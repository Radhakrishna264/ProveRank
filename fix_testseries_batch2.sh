#!/bin/bash
echo "=== Fix Batch 2 ==="

node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// FIX 1: Hero card — make completely transparent (remove bg/border/shadow)
c = c.replace(
  `background: 'linear-gradient(135deg,rgba(4,12,30,0.97),rgba(2,8,22,0.97))', border: '1px solid rgba(77,159,255,0.17)', borderRadius: 22, padding: '22px 18px 20px', marginBottom: 16, backdropFilter: 'blur(28px)', boxShadow: '0 14px 60px rgba(0,10,40,0.5)', position: 'relative', overflow: 'hidden', animation: 'slideUp 0.5s ease'`,
  `background: 'transparent', border: 'none', borderRadius: 22, padding: '22px 18px 20px', marginBottom: 16, position: 'relative', overflow: 'hidden', animation: 'slideUp 0.5s ease'`
);

// FIX 2: Remove the two animated overlays inside hero card (gradient + grid pattern)
c = c.replace(
  `<div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(270deg,rgba(77,159,255,0.05),rgba(0,212,255,0.033),rgba(155,89,182,0.04),rgba(77,159,255,0.05))', backgroundSize: '300%', animation: 'gradShift 12s ease infinite', borderRadius: 22, pointerEvents: 'none' }} />
          <div style={{ position: 'absolute', inset: 0, backgroundImage: 'linear-gradient(rgba(77,159,255,0.022) 1px,transparent 1px),linear-gradient(90deg,rgba(77,159,255,0.022) 1px,transparent 1px)', backgroundSize: '32px 32px', borderRadius: 22, pointerEvents: 'none' }} />`,
  ``
);

// FIX 3: Remove stat cards (Test Series count + Free card) from hero
c = c.replace(
  `<div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'center' }}>
              {[
                { i: '📚', v: loading ? '--' : (batches.length > 0 ? batches.length + '+' : '0'), l: 'Test Series' },
                { i: '🆓', v: 'Free', l: 'Available' }
              ].map((s, i) => (
                <div key={i} style={{ background: 'rgba(77,159,255,0.07)', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 14, padding: '10px 18px', textAlign: 'center', animation: \`slideUp \${0.6 + i * 0.1}s ease\`, backdropFilter: 'blur(8px)' }}>
                  <div style={{ fontSize: 19, marginBottom: 2 }}>{s.i}</div>
                  <div style={{ fontSize: 16, fontWeight: 800, color: '#4D9FFF' }}>{s.v}</div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.5)' }}>{s.l}</div>
                </div>
              ))}
            </div>`,
  ``
);

// FIX 4: Move quote section to bottom (before Why Choose ProveRank)
// First extract the quote JSX
const quoteStart = `        <div key={qIdx} style={{ background: 'linear-gradient(135deg,rgba(4,12,30,0.95),rgba(8,18,45,0.95))', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 16, padding: '16px 18px', marginBottom: 16, backdropFilter: 'blur(18px)', animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 28, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.86)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{QUOTES[qIdx].q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {QUOTES[qIdx].a}</div>
          </div>
        </div>`;

const quoteNew = `        {/* QUOTE MOVED TO BOTTOM */}`;

c = c.replace(quoteStart, quoteNew);

// Insert quote before Why Choose ProveRank section
const whySection = `        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)'`;
c = c.replace(
  whySection,
  `        {/* ── MOTIVATIONAL QUOTE (bottom) ── */}
        <div key={qIdx} style={{ background: 'linear-gradient(135deg,rgba(4,12,30,0.95),rgba(8,18,45,0.95))', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 16, padding: '16px 18px', marginBottom: 16, backdropFilter: 'blur(18px)', animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 28, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.86)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{QUOTES[qIdx].q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {QUOTES[qIdx].a}</div>
          </div>
        </div>

        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)'`
);

// FIX 5: NCERT Facts — remove title/subtitle completely
c = c.replace(
  `          <div style={{ textAlign: 'center', marginBottom: 26 }}>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 19, fontWeight: 700, background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: 4 }}>🔬 NCERT Facts</div>
            <div style={{ fontSize: 11, color: 'rgba(160,200,240,0.42)' }}>NEET 2026 — 100% NCERT Based</div>
          </div>`,
  ``
);

// FIX 6: Empty state — remove bracket content from list items, remove "NEET 2026" → "NEET"
// Fix "NEET 2026" button label in empty state
c = c.replace(`'🩺 NEET 2026'`, `'🩺 NEET'`);

// Remove bracket details from What is Coming list
c = c.replace(
  `'Full Syllabus Series (180 Qs · NEET Pattern · +4/-1)'`,
  `'Full Syllabus Test Series'`
);
c = c.replace(
  `'Chapter-wise Mini Tests (15-20 min each)'`,
  `'Chapter-wise Mini Tests'`
);
c = c.replace(
  `'PYQ Bank: NEET 2015-2024'`,
  `'PYQ Bank (Previous Year Questions)'`
);

// FIX 7: Category strip — "NEET 2026" anywhere → "NEET"  (already handled via examType)

fs.writeFileSync(fp, c);
console.log('✅ All batch 2 fixes applied');
NODEEOF

echo "=== Git Push ==="
cd ~/workspace && git add -A && git commit -m "fix: batch2 — transparent hero, remove stat cards, quote to bottom, remove NCERT title, clean empty state text" && git push origin main
echo "=== DONE — deploy in ~2 min ==="
