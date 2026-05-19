const fs = require('fs')
const fp = require('path').join(process.env.HOME, 'workspace/src/routes/adminSystem.js')
let c = fs.readFileSync(fp, 'utf8')
c = c.replace(
  "router.get('/global-search-admin', verifyToken, isAdmin,",
  "router.get('/global-search-admin', verifyToken, isSuperAdmin,"
)
fs.writeFileSync(fp, c)
console.log('✅ Fixed')
