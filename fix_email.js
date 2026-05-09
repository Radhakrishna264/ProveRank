const fs = require('fs')
const f = '/home/runner/workspace/src/utils/emailService.js'
let s = fs.readFileSync(f,'utf8')
const fixed = s.replace(
  ".slice(0,50).map(c=>{email:typeof c==='string'?c:c.email})",
  ".slice(0,50).map(c=>({email:typeof c==='string'?c:c.email})).filter(r=>r.email)"
)
if(fixed!==s){
  fs.writeFileSync(f,fixed)
  console.log('Fixed!')
  fixed.split('\n').filter(l=>l.includes('map(c=>')).forEach(l=>console.log(l))
}else{
  console.log('Not matched')
  s.split('\n').filter(l=>l.includes('map(c=>')).forEach(l=>console.log(l))
}
