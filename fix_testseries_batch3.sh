#!/bin/bash
echo "=== Fix Batch 3 ==="

node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// FIX 1: Quote card — transparent (remove bg/border/backdropFilter)
c = c.replace(
  `background: 'linear-gradient(135deg,rgba(4,12,30,0.95),rgba(8,18,45,0.95))', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 16, padding: '16px 18px', marginBottom: 16, backdropFilter: 'blur(18px)', animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13`,
  `background: 'transparent', border: 'none', borderRadius: 16, padding: '16px 18px', marginBottom: 16, animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13`
);

// FIX 2: Move quote AFTER Why Choose ProveRank (to very bottom)
// Remove quote from current position (before Why section)
const quoteBlock = `        {/* ── MOTIVATIONAL QUOTE (bottom) ── */}
        <div key={qIdx} style={{ background: 'transparent', border: 'none', borderRadius: 16, padding: '16px 18px', marginBottom: 16, animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 28, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.86)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{QUOTES[qIdx].q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {QUOTES[qIdx].a}</div>
          </div>
        </div>

        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)'`;

c = c.replace(
  quoteBlock,
  `        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)'`
);

// Now append quote after closing div of Why section (before final </div></div>)
c = c.replace(
  `      </div>\n    </div>\n  )\n}`,
  `        {/* ── MOTIVATIONAL QUOTE (very bottom) ── */}
        <div key={qIdx} style={{ background: 'transparent', border: 'none', padding: '20px 4px 8px', animation: 'fadeSlide 0.5s ease', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 28, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.75)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{QUOTES[qIdx].q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {QUOTES[qIdx].a}</div>
          </div>
        </div>

      </div>
    </div>
  )
}`
);

// FIX 3: Remove NEET Pattern card from Why Choose ProveRank grid
c = c.replace(
  `              { i: '🎯', t: 'NEET Pattern', d: '180 Qs · 720 Marks\\n+4/−1 · 200 min', c: '#4D9FFF' },\n`,
  ``
);

fs.writeFileSync(fp, c);
console.log('✅ Batch 3 fixes done');
NODEEOF

cd ~/workspace && git add -A && git commit -m "fix: batch3 — quote transparent + very bottom, remove NEET Pattern card" && git push origin main
echo "=== DONE ==="
