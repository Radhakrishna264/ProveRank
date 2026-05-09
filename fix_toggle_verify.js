const fs = require('fs'), path = require('path')
const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let code = fs.readFileSync(FILE, 'utf8')

const OLD = `const nm=!mainOn;setMainOn(nm)`

const NEW = `const nm=!mainOn;setMainOn(nm)
    try{
      const mr=await fetch(\`\${API}/api/admin/maintenance\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify({enabled:nm,message:mainMsgR.current})})
      const md=await mr.json()
      if(md.success){
        await new Promise(r=>setTimeout(r,800))
        const vr=await fetch(\`\${API}/api/admin/maintenance\`,{headers:{Authorization:\`Bearer \${token}\`}})
        const vd=await vr.json()
        const real=vd.enabled===true
        setMainOn(real)
        if(real===nm) T(nm?'🔴 Maintenance Mode ON':'🟢 Platform is Live','s')
        else{T('Save failed — Render server waking up, try again in 30s','e');setMainOn(!nm)}
      }else{setMainOn(!nm);T('Failed to save — try again','e')}
    }catch(e){setMainOn(!nm);T('Network error — try again','e')}`

// Purani toggle logic hatao (fetch wali line bhi)
const OLD_FULL = code.substring(
  code.indexOf(OLD),
  code.indexOf('},[mainOn,token,T])')
)
console.log('OLD section found:', OLD_FULL.length > 0 ? '✅' : '❌')

// Replace karo
code = code.replace(OLD, NEW)

// Purani fetch line hatao (jo ab duplicate hogi)
code = code.replace(
  /\s*const mr=await fetch\(`\$\{API\}\/api\/admin\/maintenance`[\s\S]*?mainMsgR\.current\}\}\)\)/,
  ''
)

// T() duplicate call bhi hatao agar hai
code = code.replace(/\s*if\(md\.success\)\s*T\([^)]+\)\s*T\([^)]+\)/, '')

fs.writeFileSync(FILE, code)
console.log('✅ Toggle verify fix applied!')
console.log('Verify present:', fs.readFileSync(FILE,'utf8').includes('Render server waking') ? '✅' : '❌')
