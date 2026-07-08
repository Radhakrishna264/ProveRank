const fs = require('fs')
let c = fs.readFileSync('src/components/StudentShell.tsx', 'utf8')

// 1. Add greenBadge keyframe to existing CSS
c = c.replace(
  '@keyframes silverShimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}',
  '@keyframes silverShimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}' +
  '\n          @keyframes greenBadge{0%,100%{box-shadow:0 0 4px rgba(0,196,140,0.35),inset 0 0 4px rgba(0,196,140,0.1)}50%{box-shadow:0 0 12px rgba(0,196,140,0.75),inset 0 0 8px rgba(0,255,136,0.2)}}'
)

// 2. Wrap ProveRank + STUDENT in column div (header only — fontSize:14.5 is unique to header)
// Replace the two sibling divs with a column wrapper
const headerBrand = `<div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14.5,lineHeight:1,whiteSpace:'nowrap',...(th.isDark?{background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}:{color:'#2563EB'})}}>ProveRank</div>
                <div style={{fontSize:8.5,fontWeight:700,letterSpacing:.6,whiteSpace:'nowrap',background:'linear-gradient(90deg,#909090,#E8E8E8,#C0C0C0,#FFFFFF,#C0C0C0,#909090)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 3s linear infinite'}}>{lang==='en'?'STUDENT':'छात्र'}</div>`

const headerBrandNew = `<div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:2}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontWeight:700,fontSize:14.5,lineHeight:1,whiteSpace:'nowrap',...(th.isDark?{background:th.brandGrad,backgroundSize:'200% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}:{color:'#2563EB'})}}>ProveRank</div>
                  <div style={{fontSize:7,fontWeight:800,letterSpacing:1.4,whiteSpace:'nowrap',padding:'1px 7px',borderRadius:20,border:'1.5px solid rgba(0,196,140,0.7)',background:'linear-gradient(90deg,#00A86B,#00FF88,#00C48C,#00FF88,#00A86B)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 2.5s linear infinite, greenBadge 2s ease-in-out infinite'}}>{lang==='en'?'STUDENT':'छात्र'}</div>
                </div>`

if (c.includes(headerBrand)) {
  c = c.replace(headerBrand, headerBrandNew)
  console.log('✅ ProveRank + STUDENT wrapped in column, green badge applied')
} else {
  console.log('⚠️  Header brand pattern not found — trying regex...')
  // Fallback: just update STUDENT style
  c = c.replace(
    /fontSize:8\.5,fontWeight:700,letterSpacing:\.6,whiteSpace:'nowrap',background:'linear-gradient\(90deg,#909090[^']*\)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 3s linear infinite'/,
    "fontSize:7,fontWeight:800,letterSpacing:1.4,whiteSpace:'nowrap',padding:'1px 7px',borderRadius:20,border:'1.5px solid rgba(0,196,140,0.7)',background:'linear-gradient(90deg,#00A86B,#00FF88,#00C48C,#00FF88,#00A86B)',backgroundSize:'300% 100%',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',animation:'silverShimmer 2.5s linear infinite, greenBadge 2s ease-in-out infinite'"
  )
  console.log('✅ STUDENT green badge applied (fallback)')
}

fs.writeFileSync('src/components/StudentShell.tsx', c)
console.log('Done!')
