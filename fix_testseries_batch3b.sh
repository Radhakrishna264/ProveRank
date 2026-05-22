#!/bin/bash
echo "=== Fix Batch 3b — qIdx scope fix ==="

node << 'NODEEOF'
const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(fp, 'utf8');

// Find where the file ends and fix the closing structure
// The issue: quote was placed outside component. 
// Strategy: find last </div></div>) } and replace with proper closing + quote inside

// Remove any misplaced quote blocks at the very end of file
c = c.replace(/\s*\{\/\* ── MOTIVATIONAL QUOTE \(very bottom\) ── \*\/\}[\s\S]*?💫[\s\S]*?<\/div>\s*<\/div>\s*\}\s*\n\s*\n\s*<\/div>\s*\n\s*<\/div>\s*\n\s*\)\s*\n\s*\}/g, `

      </div>
    </div>
  )
}`);

// Also remove any quote block before Why section that may remain
c = c.replace(/\s*\{\/\* ── MOTIVATIONAL QUOTE \(bottom\) ── \*\/\}[\s\S]*?💫[\s\S]*?<\/div>\s*<\/div>\s*\n\n\s*<div style=\{\{ marginTop: 42/g, `

        <div style={{ marginTop: 42`);

// Now find the correct closing of Why ProveRank section and insert quote before final </div></div>
// The Why section ends with: </div>\n        </div>\n\n      </div>\n    </div>\n  )\n}
const oldEnd = `        </div>

      </div>
    </div>
  )
}`;

const newEnd = `        </div>

        {/* ── MOTIVATIONAL QUOTE ── */}
        <div style={{ padding: '20px 4px 8px', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 26, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.72)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{QUOTES[qIdx].q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {QUOTES[qIdx].a}</div>
          </div>
        </div>

      </div>
    </div>
  )
}`;

// Replace last occurrence
const lastIdx = c.lastIndexOf(oldEnd);
if (lastIdx !== -1) {
  c = c.substring(0, lastIdx) + newEnd + c.substring(lastIdx + oldEnd.length);
  console.log('✅ Quote placed correctly inside component');
} else {
  console.log('⚠️ Could not find closing pattern — check manually');
}

fs.writeFileSync(fp, c);
console.log('✅ Done');
NODEEOF

cd ~/workspace && git add -A && git commit -m "fix: qIdx scope error — quote inside component at bottom" && git push origin main
echo "=== DONE ==="
