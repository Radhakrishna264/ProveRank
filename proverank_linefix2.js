const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let lines = fs.readFileSync(PAGE, 'utf8').split('\n')

// Line 324 (index 323): } else { throw new Error('Failed') }
// Line 325 (index 324): }catch(e:any){
// Line 326 (index 325): showToast('❌ Exam create failed — Retry karo','error')
// Line 327 (index 326): }
// Line 328 (index 327): }

lines[323] = `      } else {`
lines[324] = `        const errData = await res.json().catch(()=>({}))`
lines[325] = `        showToast('❌ ' + res.status + ': ' + (errData.message||errData.error||'Exam create failed'),'error')`
lines[326] = `        return`
lines[327] = `      }`
// Insert catch after
lines.splice(328, 0, `    }catch(e:any){`)
lines.splice(329, 0, `      showToast('❌ Network: ' + (e?.message||'Check connection'),'error')`)
lines.splice(330, 0, `    }`)
lines.splice(331, 0, `  }`)

// Remove old closing }
// lines 328 was original } — now shifted to 332, remove it
lines.splice(332, 1)

fs.writeFileSync(PAGE, lines.join('\n'))
console.log('[✓] Done! Lines updated.')

// Verify
const updated = fs.readFileSync(PAGE,'utf8').split('\n')
console.log('=== Updated 320-335 ===')
for(let i=319;i<=334;i++) console.log((i+1)+'|'+updated[i])
