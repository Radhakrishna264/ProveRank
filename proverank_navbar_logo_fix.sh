#!/bin/bash
# Fix Landing page navbar top-left logo

node << 'EOF'
const fs = require('fs')
const FILE = process.env.HOME + '/workspace/frontend/app/page.tsx'
let c = fs.readFileSync(FILE, 'utf8')
const orig = c

// Line 144 area — navbar ProveRank text span
// Replace: gradient text span "ProveRank" in navbar with PRLogo + text
const oldNavLogo = `<span style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>`

const newNavLogo = `<div style={{display:'flex',alignItems:'center',gap:8}}>
            <PRLogo size={34}/>
            <span style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:800,background:'linear-gradient(90deg,#4D9FFF,#fff,#4D9FFF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</span>
          </div>`

if (c.includes(oldNavLogo)) {
  c = c.replace(oldNavLogo, newNavLogo)
  console.log('✅ Exact match replaced!')
} else {
  // Fallback — find ProveRank span near line 144
  // Look for any span with ProveRank in navbar area
  const navbarIdx = c.indexOf("position:'fixed',top:0,left:0,right:0")
  if (navbarIdx === -1) {
    console.log('❌ Navbar not found by position style')
  } else {
    // Find ProveRank text span within navbar (first 2000 chars after navbar start)
    const navSection = c.slice(navbarIdx, navbarIdx + 3000)
    const prIdx = navSection.indexOf('>ProveRank<')
    if (prIdx > -1) {
      const absIdx = navbarIdx + prIdx
      // Find start of this span/div
      const spanStart = c.lastIndexOf('<span', absIdx)
      const spanEnd = absIdx + '>ProveRank</span>'.length
      const oldSpan = c.slice(spanStart, spanEnd)
      c = c.replace(oldSpan, newNavLogo)
      console.log('✅ Fallback: navbar ProveRank span replaced!')
    } else {
      console.log('❌ ProveRank text not found in navbar section')
      // Show what IS in navbar
      console.log('Navbar preview:', navSection.slice(0, 500))
    }
  }
}

if (c !== orig) {
  fs.writeFileSync(FILE, c, 'utf8')
  console.log('💾 Saved!')
} else {
  console.log('⚠️ No change made')
}
EOF

echo ""
echo "🚀 Run:"
echo "   git add frontend/app/page.tsx"
echo "   git commit -m 'Fix navbar logo top-left landing page'"
echo "   git push origin main"
