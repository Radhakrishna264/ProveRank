const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(PAGE, 'utf8')

// Real error message dikhao
const OLD = `    }catch(e:any){
      showToast('⏳ Server start ho raha hai (30s) — Dobara click karo','error')
    }
  }`

const NEW = `    }catch(e:any){
      const res2 = await fetch(\`\${API}/api/exams\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify(payload)}).catch(()=>null)
      const status = res2?.status||0
      const body = await res2?.text().catch(()=>'no body') || e?.message || 'unknown'
      showToast(\`❌ \${status}: \${body}\`,'error')
    }
  }`

if(code.includes(OLD)){
  code = code.replace(OLD, NEW)
  fs.writeFileSync(PAGE, code)
  console.log('[✓] Debug mode ON')
} else {
  console.log('[!] Pattern not found')
}
