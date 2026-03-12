const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(PAGE, 'utf8')

// FIX: Wrong payload fields
const OLD = `    const payload = {
      title, scheduledAt:new Date(date).toISOString(),
      totalMarks:parseInt(marks), totalDurationSec:parseInt(dur)*60,
      status:'upcoming', category:newExamCat, password:pass||undefined
    }`

const NEW = `    const durMins = parseInt(dur)
    const payload = {
      title,
      scheduledAt: new Date(date).toISOString(),
      totalMarks: parseInt(marks),
      duration: durMins * 60,
      durationMinutes: durMins,
      status: 'scheduled',
      category: newExamCat,
      password: pass||undefined
    }`

if(code.includes(OLD)){
  code = code.replace(OLD, NEW)
  fs.writeFileSync(PAGE, code)
  console.log('[✓] FIXED: payload corrected — duration + status sahi ho gaya')
} else {
  console.log('[!] Pattern not found — printing payload lines:')
  code.split('\n').forEach((l,i)=>{
    if(l.includes('totalDurationSec')||l.includes('upcoming')||l.includes('payload'))
      console.log((i+1)+'|'+l)
  })
}
