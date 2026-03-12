const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(PAGE, 'utf8')

const OLD = `} else { throw new Error('Failed') }
    }catch(e:any){
      showToast('❌ Exam create failed — Retry karo','error')
    }
  }`

const NEW = `} else {
        const errData = await res.json().catch(()=>({}))
        showToast(\`❌ \${res.status}: \${errData.message||errData.error||'Exam create failed'}\`,'error')
        return
      }
    }catch(e:any){
      showToast(\`❌ Network: \${e?.message||'Check connection'}\`,'error')
    }
  }`

if(code.includes(OLD)){
  code = code.replace(OLD, NEW)
  fs.writeFileSync(PAGE, code)
  console.log('[✓] Real error visible hoga ab')
} else {
  console.log('[!] Pattern not found — exact lines print karta hoon:')
  const lines = code.split('\n')
  lines.forEach((l,i) => {
    if(l.includes('Exam create') || l.includes('throw new Error') || l.includes('Exam created')) 
      console.log((i+1) + ': ' + l)
  })
}
