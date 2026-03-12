const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
const lines = fs.readFileSync(PAGE, 'utf8').split('\n')

// Line 324 ke aaspaas exact content print karo
console.log('=== Lines 320-330 ===')
for(let i=319; i<=329; i++){
  console.log((i+1) + '|' + lines[i])
}
