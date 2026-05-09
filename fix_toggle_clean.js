const fs = require('fs'), path = require('path')
const FILE = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx')
let code = fs.readFileSync(FILE, 'utf8')

// toggleMaint poora dhundo aur replace karo
const START = 'const toggleMaint=useCallback(async()=>{'
const END = '},[mainOn,token,T])'

const si = code.indexOf(START)
const ei = code.indexOf(END, si) + END.length

if(si===-1||ei===END.length-1){
  console.log('❌ toggleMaint not found')
  process.exit(1)
}

console.log('✅ Found toggleMaint at lines', si, '-', ei)

const NEW_TOGGLE = `const toggleMaint=useCallback(async()=>{
    const nm=!mainOn
    setMainOn(nm)
    const doPost=async()=>{
      const r=await fetch(\`\${API}/api/admin/maintenance\`,{
        method:'POST',
        headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},
        body:JSON.stringify({enabled:nm,message:mainMsgR.current})
      })
      return r.ok?r.json():null
    }
    try{
      let md=await doPost()
      if(!md||!md.success){
        await new Promise(r=>setTimeout(r,3000))
        md=await doPost()
      }
      if(md&&md.success){
        T(nm?'🔴 Maintenance ON — Students blocked':'🟢 Platform Live — Students can access','s')
      }else{
        setMainOn(!nm)
        T('Save failed — Render server busy, try again','e')
      }
    }catch(e){
      setMainOn(!nm)
      T('Network error — please try again','e')
    }
  },[mainOn,token,T])`

code = code.slice(0, si) + NEW_TOGGLE + code.slice(ei)
fs.writeFileSync(FILE, code)
console.log('✅ Clean toggle fix applied!')
const v = fs.readFileSync(FILE,'utf8')
console.log('New toggle present:', v.includes('Render server busy') ? '✅' : '❌')
console.log('No verify loop:', !v.includes('Render server waking') ? '✅' : '❌')
