#!/bin/bash
# ProveRank Fix: Closing bracket mismatch after arrow function rewrite
# =>(JSX)) was changed to =>{...return(JSX)) — needs to be )})
# Current: ))  }   →   Correct: ) } )  }

echo "========================================"
echo " ProveRank — Closing Bracket Fix"
echo "========================================"

PAGE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'JSEOF'
const fs = require('fs');
const filePath = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(filePath, 'utf8');

// ── Find the exact position of our modified map ──
const MARKER = 'const _hasT=!!(o&&o.trim()),_hasI=!!(q.optionImages&&q.optionImages[j]&&String(q.optionImages[j]).trim());if(!_hasT&&!_hasI)return null;return(';

const markerIdx = content.indexOf(MARKER);
if (markerIdx === -1) {
  console.log('❌ Marker not found! Searching for partial...');
  const partial = content.indexOf('_hasT=!!');
  if (partial > -1) {
    console.log('Partial found at:', partial);
    console.log('Context:', content.slice(partial, partial + 200).replace(/\n/g,'↵'));
  }
  process.exit(1);
}
console.log('✅ Map marker found at index:', markerIdx);

// ── Find the closing )) after our map's JSX ──
// From markerIdx, scan forward to find )) which is the wrong closing
// Current structure: ...return( JSX ) ) }
// We need:          ...return( JSX ) } ) }
//
// Strategy: find the FIRST occurrence of "))" after markerIdx
// This )) should be the closing of return( and the old =>( 
// Change )) to }) (inserting } between the two ))

const searchFrom = markerIdx + MARKER.length;
const doubleParenIdx = content.indexOf('))', searchFrom);

if (doubleParenIdx === -1) {
  console.log('❌ Closing )) not found after marker!');
  process.exit(1);
}

console.log('Found )) at index:', doubleParenIdx);
console.log('Context around )):', content.slice(doubleParenIdx - 30, doubleParenIdx + 10).replace(/\n/g,'↵'));

// Check: it should be followed by } (closing JSX expression)
const afterDouble = content.slice(doubleParenIdx + 2).trimStart();
console.log('After )) :', afterDouble.slice(0, 30).replace(/\n/g,'↵'));

// Verify this is our target (should have </div> nearby before it)
const before = content.slice(Math.max(0, doubleParenIdx - 100), doubleParenIdx);
const hasDiv = before.includes('</div>');
console.log('Has </div> before:', hasDiv ? '✅' : '⚠️');

// ── Apply fix: change )) to }) ──
// Current: ...JSX ) ) } 
// Correct: ...JSX ) } ) }
// So: replace )) with }) at doubleParenIdx
const OLD = content.slice(doubleParenIdx, doubleParenIdx + 2);
const NEW = '})'; // ) closes return(, } closes =>{, ) closes .map(... wait

// Actually: 
// )) → )} means: first ) closes return(, then } closes the arrow fn block
// But then we still need ) to close .map( — which is the } before it? No.
//
// Let me re-analyze the EXACT structure:
// {  ← JSX expression open
//   (...).map(  ← map call open  
//     (o,j)=>{  ← arrow block open  (was =>(  before fix)
//       return(  ← return open
//         <JSX>
//       )   ← closes return(   [was: closing of =>(]
//     )   ← was: closes .map( ; now: WRONG (arrow block not closed)
//   }   ← closes JSX { expression
//
// Need to change:
//   )   [return close]
//   )   [should be: } to close arrow block]
//   }   [should be: ) to close .map, then } to close JSX expression]
//
// So: 
//   Current:  ))  }
//   Correct:  )}  )}
//   (4→4 chars but different arrangement)
//
// )) }  →  )} )}
// Position: doubleParenIdx = )  doubleParenIdx+1 = ) then some whitespace then }

// Find the } that closes JSX expression (right after the ))
let closingBracePos = -1;
for (let i = doubleParenIdx + 2; i < content.length; i++) {
  if (content[i] === '}') {
    closingBracePos = i;
    break;
  }
  if (content[i] !== ' ' && content[i] !== '\n' && content[i] !== '\r') {
    // Something unexpected between )) and }
    console.log('⚠️  Unexpected char between )) and }:', content[i], 'at', i);
    break;
  }
}

if (closingBracePos === -1) {
  console.log('❌ Could not find } after ))');
  process.exit(1);
}

console.log('Found } (JSX expression close) at:', closingBracePos);
const between = content.slice(doubleParenIdx + 2, closingBracePos);
console.log('Between )) and }:', JSON.stringify(between));

// The fix: 
// Replace the sequence: ) ) [whitespace] }
// With:                 ) } ) [whitespace] }
// 
// Specifically: insert "}" before the second ")" (at doubleParenIdx+1)
const beforeFix = content.slice(0, doubleParenIdx + 1); // includes first )
const afterFix  = content.slice(doubleParenIdx + 1);    // starts with second )

const newContent = beforeFix + '\n            }' + afterFix;

fs.writeFileSync(filePath, newContent, 'utf8');
console.log('\n✅ Fix DONE: Inserted } to close arrow function');
console.log('New closing sequence:');
const verifyCtx = newContent.slice(doubleParenIdx - 30, doubleParenIdx + 50);
console.log(verifyCtx.replace(/\n/g,'↵'));
JSEOF

echo ""
echo "--- TypeScript Check ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep "x7k2p\|admin" | head -10

echo ""
echo "--- Login page errors (pre-existing check) ---"
cd ~/workspace/frontend && npx tsc --noEmit 2>&1 | grep "login" | head -5

echo ""
echo "========================================"
echo "If x7k2p errors clear: git add -A && git commit -m 'fix: bracket mismatch' && git push"
echo "========================================"
