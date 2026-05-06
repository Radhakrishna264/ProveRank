#!/bin/bash
# ProveRank — Clean page.tsx Logo Fix
# Uses node with EXACT string matching — no regex

echo "🔧 Fixing admin page.tsx..."

FILE="./frontend/app/admin/x7k2p/page.tsx"
[ ! -f "$FILE" ] && FILE="../frontend/app/admin/x7k2p/page.tsx"
[ ! -f "$FILE" ] && FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then
  echo "❌ page.tsx not found!"
  exit 1
fi

echo "✅ Found: $FILE"

node << 'NODEOF'
const fs = require('fs');
const path = require('path');

// Find file
let FILE = './frontend/app/admin/x7k2p/page.tsx';
if (!fs.existsSync(FILE)) FILE = '../frontend/app/admin/x7k2p/page.tsx';
if (!fs.existsSync(FILE)) FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';

console.log('Reading:', FILE);
let content = fs.readFileSync(FILE, 'utf8');

// ── NEW LOGO ──
const NEW_LOGO = `function PRLogo({size=36}:{size?:number}) {
  const blockSize = size * 0.94
  const pSize = Math.round(blockSize * 0.63)
  const rSize = Math.round(blockSize * 0.63)
  const fontSize = Math.round(pSize * 0.52)
  const radius = Math.round(pSize * 0.28)
  return (
    <div style={{position:'relative',width:blockSize,height:blockSize,flexShrink:0,display:'inline-flex'}}>
      <div style={{
        position:'absolute',top:0,left:0,
        width:pSize,height:pSize,
        borderRadius:radius,
        background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#030810',
        boxShadow:'0 4px 16px rgba(77,159,255,0.4)'
      }}>P</div>
      <div style={{
        position:'absolute',bottom:0,right:0,
        width:rSize,height:rSize,
        borderRadius:radius,
        background:'rgba(0,212,255,0.1)',
        border:'1.5px solid rgba(0,212,255,0.45)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#00D4FF',
        backdropFilter:'blur(8px)'
      }}>R</div>
    </div>
  )
}`;

// Count how many PRLogo functions exist
const count = (content.match(/function PRLogo\(/g) || []).length;
console.log('PRLogo functions found:', count);

if (count === 0) {
  console.log('❌ No PRLogo function found!');
  process.exit(1);
}

if (count > 1) {
  // Multiple copies — keep only ONE correct version
  // Remove ALL existing PRLogo functions first
  while (content.includes('function PRLogo(')) {
    const start = content.indexOf('function PRLogo(');
    // Go back to check for 'export '
    const exportStart = content.lastIndexOf('export ', start);
    const realStart = (exportStart !== -1 && start - exportStart <= 8) ? exportStart : start;
    
    // Find closing brace
    let depth = 0, i = start, end = start, found = false;
    while (i < content.length) {
      if (content[i] === '{') { depth++; found = true; }
      else if (content[i] === '}') {
        depth--;
        if (found && depth === 0) { end = i + 1; break; }
      }
      i++;
    }
    content = content.slice(0, realStart) + content.slice(end);
    console.log('  Removed a PRLogo instance');
  }
  // Now insert NEW_LOGO at correct position (after comments block at top)
  // Find the ParticlesBg or first function after imports
  const insertAt = content.indexOf('\nfunction ParticlesBg');
  if (insertAt > -1) {
    content = content.slice(0, insertAt) + '\n' + NEW_LOGO + '\n' + content.slice(insertAt);
    console.log('✅ Inserted new PRLogo before ParticlesBg');
  } else {
    // Fallback: insert after last import
    const lastImport = content.lastIndexOf('\nimport ');
    const afterImports = content.indexOf('\n', lastImport + 1);
    content = content.slice(0, afterImports) + '\n\n' + NEW_LOGO + '\n' + content.slice(afterImports);
    console.log('✅ Inserted new PRLogo after imports');
  }
} else {
  // Single copy — just replace it
  const start = content.indexOf('function PRLogo(');
  const exportStart = content.lastIndexOf('export ', start);
  const realStart = (exportStart !== -1 && start - exportStart <= 8) ? exportStart : start;
  
  let depth = 0, i = start, end = start, found = false;
  while (i < content.length) {
    if (content[i] === '{') { depth++; found = true; }
    else if (content[i] === '}') {
      depth--;
      if (found && depth === 0) { end = i + 1; break; }
    }
    i++;
  }
  content = content.slice(0, realStart) + NEW_LOGO + content.slice(end);
  console.log('✅ Replaced single PRLogo');
}

// ALSO fix High Trust / Low Trust JSX issues
content = content.replace(/>High Trust \(>70\)</g, '>High Trust (&gt;70)<');
content = content.replace(/>Low Trust \(<40\)</g, '>Low Trust (&lt;40)<');
console.log('✅ Trust labels fixed');

// Fix broken object literal
content = content.replace(
  "l:'Total Students',(students||[]).length}",
  "l:'Total Students',v:(students||[]).length}"
);
content = content.replace(
  "l:'Exams Conducted',(exams||[]).length}",
  "l:'Exams Conducted',v:(exams||[]).length}"
);
content = content.replace(
  "(s as any)[(students||[]).length]||s[(exams||[]).length]||s[stats?.avgScore]||s[stats?.completionRate]||Object.values(s)[2]||'—'",
  "s.v"
);
console.log('✅ Object literal fixed');

fs.writeFileSync(FILE, content, 'utf8');
console.log('💾 File saved!');

// Final check
const remaining = (content.match(/function PRLogo\(/g) || []).length;
console.log('PRLogo functions after fix:', remaining);
if (remaining === 1) console.log('✅ Perfect — exactly 1 PRLogo!');
else console.log('⚠️  Check manually');
NODEOF

echo ""
echo "🚀 Now run:"
echo "   git add frontend/app/admin/x7k2p/page.tsx"
echo "   git commit -m 'Clean logo fix - remove duplicates'"
echo "   git push origin main"
