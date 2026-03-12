const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'

if (!fs.existsSync(PAGE)) {
  console.log('ERROR: page.tsx nahi mila at: ' + PAGE)
  process.exit(1)
}

let code = fs.readFileSync(PAGE, 'utf8')
let changed = 0

// BUG 1 FIX — fake local_ ID hatao
const OLD1 = `    }catch{
      const fakeId=\`local_\${Date.now()}\`
      setCreatedExamId(fakeId)
      setExams(p=>[{_id:fakeId,attempts:0,...payload} as any,...p])
      setExamStep(2)
      showToast('Exam saved (pending sync)')
    }
  }`

const NEW1 = `    }catch(e:any){
      showToast(\`❌ Exam create failed — Retry karo\`,'error')
    }
  }`

if (code.includes(OLD1)) {
  code = code.replace(OLD1, NEW1)
  console.log('[✓] BUG 1 FIXED: fake local_ ID removed')
  changed++
} else {
  console.log('[!] Bug 1 pattern not found — already fixed?')
}

// BUG 2 FIX — Excel route fix
const OLD2 = `\`\${API}/api/excel/upload\``
const NEW2 = `\`\${API}/api/excel/questions\``

if (code.includes(OLD2)) {
  code = code.replace(OLD2, NEW2)
  console.log('[✓] BUG 2 FIXED: /api/excel/upload → /api/excel/questions')
  changed++
} else {
  console.log('[!] Bug 2 pattern not found — already fixed?')
}

if (changed > 0) {
  fs.writeFileSync(PAGE, code)
  console.log('\n[✓] page.tsx updated successfully!')
} else {
  console.log('\n[!] No changes made — check manually')
}
