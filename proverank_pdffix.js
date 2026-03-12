const fs = require('fs')
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let code = fs.readFileSync(PAGE, 'utf8')

// PDF field name fix: 'file' → 'pdf'
const OLD = `const fd=new FormData(); fd.append('file',pdfFile); fd.append('examId',createdExamId)
        res = await fetch(\`\${API}/api/upload/pdf\``

const NEW = `const fd=new FormData(); fd.append('pdf',pdfFile); fd.append('examId',createdExamId)
        res = await fetch(\`\${API}/api/upload/pdf\``

if(code.includes(OLD)){
  code = code.replace(OLD, NEW)
  fs.writeFileSync(PAGE, code)
  console.log('[✓] FIXED: pdf field name corrected')
} else {
  console.log('[!] Pattern not found — checking...')
  code.split('\n').forEach((l,i)=>{
    if(l.includes('pdfFile')||l.includes('upload/pdf'))
      console.log((i+1)+'|'+l)
  })
}
