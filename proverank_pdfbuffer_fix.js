const fs = require('fs')
const FILE = process.env.HOME + '/workspace/src/routes/upload.js'
let code = fs.readFileSync(FILE, 'utf8')

// Fix: buffer → fs.readFileSync(path)
const OLD = `try { parsed = await pdfParse(req.file.buffer); } catch(e) { parseError = e.message; }`
const NEW = `try { const fileBuffer = fs.readFileSync(req.file.path); parsed = await pdfParse(fileBuffer); } catch(e) { parseError = e.message; }`

if(code.includes(OLD)){
  // fs already required? check
  if(!code.includes("require('fs')")){
    code = "const fs = require('fs');\n" + code
    console.log('[✓] fs module added')
  }
  code = code.replace(OLD, NEW)
  fs.writeFileSync(FILE, code)
  console.log('[✓] FIXED: req.file.buffer → fs.readFileSync(req.file.path)')
} else {
  console.log('[!] Pattern not found — printing line 60:')
  code.split('\n').forEach((l,i)=>{
    if(l.includes('buffer')||l.includes('pdfParse'))
      console.log((i+1)+'|'+l)
  })
}
