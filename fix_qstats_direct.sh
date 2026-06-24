#!/bin/bash
set -e

FILE=~/workspace/src/routes/questionStatsRoutes.js

[ ! -f "$FILE" ] && { echo "❌ File not found: $FILE"; exit 1; }

cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup done"

node << 'JSEOF'
const path = require('path');
const os   = require('os');
const fs   = require('fs');

const file = path.join(os.homedir(), 'workspace/src/routes/questionStatsRoutes.js');
let c = fs.readFileSync(file, 'utf8');

// Remove ALL TypeScript type annotations like (a:any), (x:string), etc.
const before = c;
c = c.replace(/([a-zA-Z_$][a-zA-Z0-9_$]*)\s*:\s*(any|string|number|boolean|void|object|never|Array<[^>]*>)/g, '$1');

if (c !== before) {
  fs.writeFileSync(file, c);
  console.log('✅ Fixed! All :any / :string / :number etc. removed');
} else {
  console.log('⚠️  No change made — checking manually...');
  const lines = c.split('\n');
  lines.forEach((l, i) => {
    if (l.includes(':any') || l.includes(':string') || l.includes(':number')) {
      console.log('  Line ' + (i+1) + ': ' + l.trim());
    }
  });
}
JSEOF

echo ""
echo "🔍 Verifying syntax..."
node --check ~/workspace/src/routes/questionStatsRoutes.js && echo "✅ Syntax OK — no errors!" || echo "❌ Still has errors"
