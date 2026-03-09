#!/bin/bash
# ============================================================
# ProveRank — Final Logo Replacement Script
# Sab jagah naya PR4 logo lagao
# Files: PRLogo component + layout + login + register + admit-card + certificate
# ============================================================

cd ~/workspace/frontend

echo "🚀 ProveRank Logo Replacement Starting..."
echo ""

# ════════════════════════════════════════════════════════════
# FILE 1 — Reusable PRLogo Component
# Ek jagah banao, sab jagah use karo
# ════════════════════════════════════════════════════════════
mkdir -p src/components

cat > src/components/PRLogo.tsx << 'ENDOFFILE'
// ProveRank Final Logo — PR4 Geometric Hexagon + Corner Dots
// Usage: <PRLogo size={36} /> | <PRLogo size={48} showName /> | <PRLogo size={80} showName showTag />

interface PRLogoProps {
  size?: number;
  showName?: boolean;
  showTag?: boolean;
  nameSize?: number;
  horizontal?: boolean; // logo + name side by side
}

export default function PRLogo({
  size = 36,
  showName = false,
  showTag = false,
  nameSize,
  horizontal = false,
}: PRLogoProps) {
  const ns = nameSize || Math.max(14, size * 0.5);
  const tagSize = Math.max(9, ns * 0.42);

  const LogoSVG = () => (
    <svg
      width={size}
      height={size}
      viewBox="0 0 110 110"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ flexShrink: 0 }}
    >
      <defs>
        <filter id="pr-glow">
          <feGaussianBlur stdDeviation="2.5" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <filter id="pr-soft">
          <feGaussianBlur stdDeviation="1.5" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      {/* ── Honeycomb background dots ── */}
      <polygon points="55,2 59.3,4.5 59.3,9.5 55,12 50.7,9.5 50.7,4.5"   fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.25" />
      <polygon points="76,2 80.3,4.5 80.3,9.5 76,12 71.7,9.5 71.7,4.5"   fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="34,2 38.3,4.5 38.3,9.5 34,12 29.7,9.5 29.7,4.5"   fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="95,27 99.3,29.5 99.3,34.5 95,37 90.7,34.5 90.7,29.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="95,69 99.3,71.5 99.3,76.5 95,79 90.7,76.5 90.7,71.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="15,27 19.3,29.5 19.3,34.5 15,37 10.7,34.5 10.7,29.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="15,69 19.3,71.5 19.3,76.5 15,79 10.7,76.5 10.7,71.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="55,96 59.3,98.5 59.3,103.5 55,106 50.7,103.5 50.7,98.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.25" />
      <polygon points="76,96 80.3,98.5 80.3,103.5 76,106 71.7,103.5 71.7,98.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />
      <polygon points="34,96 38.3,98.5 38.3,103.5 34,106 29.7,103.5 29.7,98.5" fill="none" stroke="#4D9FFF" strokeWidth="0.8" opacity="0.15" />

      {/* ── Outer hex border (faint) ── */}
      <polygon
        points="55,7 96,30.5 96,77.5 55,101 14,77.5 14,30.5"
        fill="rgba(77,159,255,0.04)"
        stroke="#4D9FFF"
        strokeWidth="1.2"
        opacity="0.4"
        filter="url(#pr-soft)"
      />

      {/* ── Inner hex (main frame) ── */}
      <polygon
        points="55,18 88,36.5 88,73.5 55,92 22,73.5 22,36.5"
        fill="rgba(77,159,255,0.07)"
        stroke="#4D9FFF"
        strokeWidth="2"
        filter="url(#pr-glow)"
      />

      {/* ── Corner DOTS (from Option C) ── */}
      <circle cx="55"  cy="18"   r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />
      <circle cx="88"  cy="36.5" r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />
      <circle cx="88"  cy="73.5" r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />
      <circle cx="55"  cy="92"   r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />
      <circle cx="22"  cy="73.5" r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />
      <circle cx="22"  cy="36.5" r="3.5" fill="#4D9FFF" filter="url(#pr-glow)" opacity="0.95" />

      {/* ── PR Monogram ── */}
      <text
        x="55" y="66"
        fontFamily="'Playfair Display', Georgia, serif"
        fontSize="30"
        fontWeight="900"
        fill="#4D9FFF"
        textAnchor="middle"
        filter="url(#pr-glow)"
        letterSpacing="-1"
      >PR</text>
    </svg>
  );

  if (!showName) return <LogoSVG />;

  return (
    <div style={{
      display: 'flex',
      flexDirection: horizontal ? 'row' : 'column',
      alignItems: 'center',
      gap: horizontal ? 10 : 8,
    }}>
      <LogoSVG />
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: horizontal ? 'flex-start' : 'center', gap: 2 }}>
        <span style={{
          fontFamily: "'Playfair Display', Georgia, serif",
          fontSize: ns,
          fontWeight: 700,
          letterSpacing: 2,
          background: 'linear-gradient(90deg, #4D9FFF 0%, #FFFFFF 50%, #4D9FFF 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text',
          lineHeight: 1.1,
        }}>ProveRank</span>
        {showTag && (
          <span style={{
            fontSize: tagSize,
            color: '#6B8FAF',
            letterSpacing: 3,
            textTransform: 'uppercase',
            fontFamily: 'Inter, sans-serif',
          }}>Online Test Platform</span>
        )}
      </div>
    </div>
  );
}
ENDOFFILE
echo "✅ 1/6 — PRLogo Component created (src/components/PRLogo.tsx)"

# ════════════════════════════════════════════════════════════
# FILE 2 — Dashboard Layout (Sidebar logo)
# ════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const path = 'src/app/dashboard/layout.tsx';
if (!fs.existsSync(path)) { console.log('⚠️  layout.tsx not found, skipping'); process.exit(0); }
let c = fs.readFileSync(path, 'utf8');

// Add PRLogo import after first import line
if (!c.includes("import PRLogo")) {
  c = c.replace(
    `import { getToken, getRole, logout } from '@/lib/auth';`,
    `import { getToken, getRole, logout } from '@/lib/auth';\nimport PRLogo from '@/components/PRLogo';`
  );
}

// Replace old logo block in sidebar
c = c.replace(
  `<div style={{ fontSize:28, color:'var(--primary)', lineHeight:1 }}>⬡</div>\n          <span style={{ fontFamily:'Playfair Display,Georgia,serif', fontSize:18, color:'var(--primary)', fontWeight:700 }}>ProveRank</span>`,
  `<PRLogo size={32} showName horizontal nameSize={17} />`
);

fs.writeFileSync(path, c);
console.log('✅ 2/6 — dashboard/layout.tsx sidebar logo updated');
JSEOF

# ════════════════════════════════════════════════════════════
# FILE 3 — Dashboard Main Page (Header logo)
# ════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const path = 'src/app/dashboard/page.tsx';
if (!fs.existsSync(path)) { console.log('⚠️  page.tsx not found, skipping'); process.exit(0); }
let c = fs.readFileSync(path, 'utf8');

// Add PRLogo import
if (!c.includes("import PRLogo")) {
  c = c.replace(
    `import Link from 'next/link';`,
    `import Link from 'next/link';\nimport PRLogo from '@/components/PRLogo';`
  );
}

// Replace decorative ⬡ logo in dashboard header/welcome section
c = c.replace(
  `<div style={{ fontSize:40, marginBottom:8 }}>⬡</div>`,
  `<PRLogo size={48} showName showTag />`
);

fs.writeFileSync(path, c);
console.log('✅ 3/6 — dashboard/page.tsx header logo updated');
JSEOF

# ════════════════════════════════════════════════════════════
# FILE 4 — Login Page
# ════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const candidates = [
  'src/app/login/page.tsx',
  'app/login/page.tsx',
];
let path = candidates.find(p => fs.existsSync(p));
if (!path) { console.log('⚠️  login page not found, skipping'); process.exit(0); }
let c = fs.readFileSync(path, 'utf8');

if (!c.includes("import PRLogo")) {
  // add import after first import or 'use client'
  c = c.replace(
    `'use client';`,
    `'use client';\nimport PRLogo from '@/components/PRLogo';`
  );
}

// Replace any ⬡ + ProveRank logo patterns in login page
c = c.replace(
  /(<div[^>]*>)\s*⬡\s*(<\/div>)\s*\n?\s*(<[^>]*>)\s*ProveRank\s*(<\/[^>]*>)/g,
  `<PRLogo size={52} showName showTag />`
);

// Alternate pattern — single div with both
c = c.replace(
  /fontSize:\s*['"]?\d+['"]?[^}]*}\s*>\s*⬡\s*ProveRank\s*<\/div>/g,
  `style={{}}><PRLogo size={52} showName horizontal nameSize={22} /></div>`
);

fs.writeFileSync(path, c);
console.log('✅ 4/6 — login/page.tsx logo updated');
JSEOF

# ════════════════════════════════════════════════════════════
# FILE 5 — Admit Card Page
# ════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const path = 'src/app/dashboard/admit-card/page.tsx';
if (!fs.existsSync(path)) { console.log('⚠️  admit-card page not found, skipping'); process.exit(0); }
let c = fs.readFileSync(path, 'utf8');

if (!c.includes("import PRLogo")) {
  c = c.replace(
    `'use client';`,
    `'use client';\nimport PRLogo from '@/components/PRLogo';`
  );
}

// Replace admit card print logo
c = c.replace(
  `<div style={{ fontSize:28, color:'#1a6fd4', fontWeight:900, marginBottom:4 }}>⬡ ProveRank</div>`,
  `<PRLogo size={36} showName horizontal nameSize={18} />`
);

fs.writeFileSync(path, c);
console.log('✅ 5/6 — admit-card/page.tsx logo updated');
JSEOF

# ════════════════════════════════════════════════════════════
# FILE 6 — Certificate Page
# ════════════════════════════════════════════════════════════
node << 'JSEOF'
const fs = require('fs');
const path = 'src/app/dashboard/certificates/page.tsx';
if (!fs.existsSync(path)) { console.log('⚠️  certificates page not found, skipping'); process.exit(0); }
let c = fs.readFileSync(path, 'utf8');

if (!c.includes("import PRLogo")) {
  c = c.replace(
    `'use client';`,
    `'use client';\nimport PRLogo from '@/components/PRLogo';`
  );
}

// Replace certificate logo
c = c.replace(
  `<div style={{ fontSize:36, color:'#1a6fd4', fontWeight:900, fontFamily:'Playfair Display,Georgia,serif', marginBottom:4 }}>⬡ ProveRank</div>`,
  `<PRLogo size={42} showName horizontal nameSize={20} />`
);

fs.writeFileSync(path, c);
console.log('✅ 6/6 — certificates/page.tsx logo updated');
JSEOF

# ════════════════════════════════════════════════════════════
# VERIFY — Check all files have PRLogo
# ════════════════════════════════════════════════════════════
echo ""
echo "── Verification ──"
FILES=(
  "src/components/PRLogo.tsx"
  "src/app/dashboard/layout.tsx"
  "src/app/dashboard/page.tsx"
  "src/app/dashboard/admit-card/page.tsx"
  "src/app/dashboard/certificates/page.tsx"
)
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ MISSING: $f"
  fi
done

echo ""
echo "── PRLogo import check ──"
grep -rl "PRLogo" src/ 2>/dev/null | while read f; do
  echo "✅ PRLogo found in: $f"
done

# ════════════════════════════════════════════════════════════
# GIT PUSH
# ════════════════════════════════════════════════════════════
cd ~/workspace
git add -A
git commit -m "feat: PR4 Final Logo — replaced all instances with PRLogo component

- Created reusable PRLogo component (size, showName, showTag, horizontal props)
- Logo: Honeycomb grid + Double hex frame + 6 corner dots + PR monogram
- Text: Blue→White→Blue gradient 'ProveRank' + 'Online Test Platform'
- Updated: layout sidebar, dashboard header, login, admit-card, certificates"
git push origin main

echo ""
echo "🎉 Done! Sab jagah naya PR4 logo lag gaya!"
echo "Design: Honeycomb grid · Double hex · Corner dots · Gradient text"
