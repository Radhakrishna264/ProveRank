#!/bin/bash
# ProveRank — Logo Fix (Pure Bash, No Python needed)
# Fixes PRLogo on Landing + Auth pages

G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'

FE="./frontend"
[ ! -d "$FE" ] && FE="../frontend"
[ ! -d "$FE" ] && FE="$HOME/workspace/frontend"

echo -e "${Y}📁 Using: $FE${N}"

# Find all tsx files with PRLogo
FILES=$(grep -rl "PRLogo" "$FE/app" "$FE/components" 2>/dev/null | grep -v node_modules | grep -v ".next")

echo "Files with PRLogo:"
echo "$FILES"
echo ""

for FILE in $FILES; do
  echo -e "🔧 Fixing: $FILE"

  # Use node to fix the file (Replit has node)
  node -e "
const fs = require('fs');
let c = fs.readFileSync('$FILE', 'utf8');
const orig = c;

// New Split Block Monogram logo
const newLogo = \`function PRLogo({size=36}:{size?:number}) {
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
}\`;

const newLogoExport = \`export \` + newLogo;

// Replace patterns
const patterns = [
  // export function PRLogo with size=40 (student)
  /export function PRLogo\(\{size=\d+\}[^)]*\)\s*\{[\s\S]*?(?=\nexport|\nfunction|\nconst|\nlet|\nvar|\ntype|\ninterface|$)/,
  // function PRLogo with size=36 (admin)
  /(?<!export )function PRLogo\(\{size=\d+\}[^)]*\)\s*\{[\s\S]*?(?=\nexport|\nfunction|\nconst|\nlet|\nvar|\ntype|\ninterface|$)/,
];

// Try simple string-based find for export version
if (c.includes('export function PRLogo(')) {
  const start = c.indexOf('export function PRLogo(');
  // Find matching closing brace
  let depth = 0, i = start, end = start;
  let foundFirst = false;
  while (i < c.length) {
    if (c[i] === '{') { depth++; foundFirst = true; }
    else if (c[i] === '}') { 
      depth--;
      if (foundFirst && depth === 0) { end = i + 1; break; }
    }
    i++;
  }
  if (end > start) {
    c = c.slice(0, start) + newLogoExport + c.slice(end);
    console.log('  ✅ Replaced export PRLogo');
  }
} else if (c.includes('function PRLogo(')) {
  const start = c.indexOf('function PRLogo(');
  let depth = 0, i = start, end = start;
  let foundFirst = false;
  while (i < c.length) {
    if (c[i] === '{') { depth++; foundFirst = true; }
    else if (c[i] === '}') {
      depth--;
      if (foundFirst && depth === 0) { end = i + 1; break; }
    }
    i++;
  }
  if (end > start) {
    c = c.slice(0, start) + newLogo + c.slice(end);
    console.log('  ✅ Replaced PRLogo');
  }
}

if (c !== orig) {
  fs.writeFileSync('$FILE', c, 'utf8');
  console.log('  💾 Saved!');
} else {
  console.log('  ⚠️  No change (pattern not matched)');
}
" 2>&1

done

echo ""
echo -e "${G}✅ Done! Now run:${N}"
echo "   git add ."
echo "   git commit -m 'Fix logo auth pages - node fix'"
echo "   git push origin main"
