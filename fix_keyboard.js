const fs = require('fs')
const path = '/root/workspace/frontend/app/admin/x7k2p/page.tsx'

if (!fs.existsSync(path)) {
  console.log('[ERROR] page.tsx nahi mila:', path)
  process.exit(1)
}

fs.copyFileSync(path, path + '.bak_keyboard')
console.log('[✓] Backup bana diya')

let content = fs.readFileSync(path, 'utf8')
let changes = 0

const fixes = [
  'manualQText',
  'answerKeyText',
  'announceText',
  'todoInput',
  'banReason',
  'newExamTitle',
  'newExamMarks',
  'newExamDur',
  'newExamCat',
  'newExamPass',
  'aiTopic',
  'globalSearch',
  'searchQuery',
  'examSearchFilter',
  'impersonateId',
  'brandName',
  'brandTagline',
  'brandSupport',
  'seoTitle',
  'seoDesc',
  'aiCount',
]

fixes.forEach(field => {
  const old1 = `value={${field}}`
  const new1 = `defaultValue={${field}}`
  if (content.includes(old1)) {
    content = content.split(old1).join(new1)
    changes++
    console.log('[✓] Fixed:', field)
  }
})

fs.writeFileSync(path, content, 'utf8')
console.log('[✓] Total fixes:', changes)
console.log('[✓] File save ho gaya!')
