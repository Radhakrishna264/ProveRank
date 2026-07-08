const fs = require('fs')
let c = fs.readFileSync('src/components/StudentShell.tsx', 'utf8')
let fixed = 0

// 1. Add silverShimmer keyframe + desktop center CSS
const cssOld = '@media(max-width:360px){.hide-xs{display:none!important}}'
const cssNew = '@media(max-width:360px){.hide-xs{display:none!important}}' +
  '\n          @keyframes silverShimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}' +
  '\n          @media(min-width:768px){.pr-brand-center{position:absolute!important;left:50%!important;transform:translateX(-50%)!important;z-index:1}}'

if (c.includes(cssOld) && !c.includes('silverShimmer')) {
  c = c.replace(cssOld, cssNew)
  fixed++
  console.log('✅ Added silverShimmer + desktop center CSS')
} else console.log('ℹ️  CSS already updated')

// 2. Add class to logo container
const logoOld = "<div style={{display:'flex',alignItems:'center',gap:7,minWidth:0}}>"
const logoNew = '<div className="pr-brand-center" style={{display:\'flex\',alignItems:\'center\',gap:7,minWidth:0}}>'

if (c.includes(logoOld) && !c.includes('pr-brand-center')) {
  c = c.replace(logoOld, logoNew)
  fixed++
  console.log('✅ Added pr-brand-center class to logo container')
} else console.log('ℹ️  Logo class already added')

// 3. STUDENT text → silver shimmer
const stuReg = /fontSize:8\.5,color:th\.logoTag,fontWeight:700,letterSpacing:\.6,whiteSpace:'nowrap'/
const stuNew = "fontSize:8.5,fontWeight:700,letterSpacing:.6,whiteSpace:'nowrap'," +
  "background:'linear-gradient(90deg,#909090,#E8E8E8,#C0C0C0,#FFFFFF,#C0C0C0,#909090)'," +
  "backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'," +
  "animation:'silverShimmer 3s linear infinite'"

if (stuReg.test(c)) {
  c = c.replace(stuReg, stuNew)
  fixed++
  console.log('✅ STUDENT text → silver shimmer')
} else console.log('ℹ️  STUDENT style already updated')

fs.writeFileSync('src/components/StudentShell.tsx', c)
console.log('\nTotal fixes applied:', fixed)
console.log('Done!')
