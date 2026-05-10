const fs = require('fs');

// ══ FIX 1: User model mein frozen + archived field add karo ══
const uPath = 'src/models/User.js';
let u = fs.readFileSync(uPath, 'utf8');

if(!u.includes('frozen:') && !u.includes('frozen :')){
  u = u.replace(
    'banned: { type: Boolean, default: false },',
    'banned: { type: Boolean, default: false },\n  frozen: { type: Boolean, default: false },\n  archived: { type: Boolean, default: false },'
  );
  fs.writeFileSync(uPath, u);
  console.log('✅ User model: frozen + archived fields added');
} else {
  console.log('ℹ️ frozen field already exists in User model');
}

// ══ FIX 2: adminManagement.js mein duplicate freeze route remove karo ══
const amPath = 'src/routes/adminManagement.js';
let am = fs.readFileSync(amPath, 'utf8');

// Count occurrences of freeze route
const freezeCount = (am.match(/router\.put\(['"`]\/freeze\/:id/g)||[]).length;
console.log('Freeze routes found:', freezeCount);

if(freezeCount >= 2){
  // Remove FIRST freeze route block (lines ~89-115 region)
  // Pattern: from first router.put('/freeze/:id' to its closing });
  am = am.replace(
    /\/\/[^\n]*[Ff]reeze[^\n]*\n([\s\S]*?)router\.put\(['"`]\/freeze\/:id['"`][^)]*\)\s*\{[\s\S]*?\}\s*\);\s*\n([\s\S]*?)router\.put\(['"`]\/freeze\/:id/,
    (match, before, between) => {
      console.log('Removed duplicate freeze route block');
      return `router.put('/freeze/:id`;
    }
  );
  
  // Simpler approach - split and rejoin
  const lines = am.split('\n');
  let firstFreezeStart = -1, firstFreezeEnd = -1;
  let depth = 0, inFirst = false;
  
  for(let i = 0; i < lines.length; i++){
    if(!inFirst && lines[i].includes("router.put('/freeze/:id") || lines[i].includes('router.put("/freeze/:id')){
      firstFreezeStart = i;
      inFirst = true;
    }
    if(inFirst){
      depth += (lines[i].match(/\{/g)||[]).length;
      depth -= (lines[i].match(/\}/g)||[]).length;
      if(depth <= 0 && i > firstFreezeStart){
        firstFreezeEnd = i;
        break;
      }
    }
  }
  
  if(firstFreezeStart >= 0 && firstFreezeEnd >= 0){
    // Remove lines from firstFreezeStart to firstFreezeEnd
    const removed = lines.splice(firstFreezeStart, firstFreezeEnd - firstFreezeStart + 1);
    console.log(`✅ Removed duplicate freeze route (lines ${firstFreezeStart+1}-${firstFreezeEnd+1})`);
    am = lines.join('\n');
    fs.writeFileSync(amPath, am);
  }
} else {
  console.log('ℹ️ Only one freeze route found - no duplicate to remove');
}

// ══ VERIFY ══
const u2 = fs.readFileSync(uPath,'utf8');
const am2 = fs.readFileSync(amPath,'utf8');
const freezeRoutes = (am2.match(/router\.put\(['"`]\/freeze\/:id/g)||[]).length;
const hasFrozen = u2.includes('frozen:') || u2.includes('frozen :');
const hasArchived = u2.includes('archived:') || u2.includes('archived :');

console.log('\n═══ VERIFICATION ═══');
console.log('User.frozen field:', hasFrozen ? '✅ EXISTS' : '❌ MISSING');
console.log('User.archived field:', hasArchived ? '✅ EXISTS' : '❌ MISSING');
console.log('Freeze routes in adminManagement.js:', freezeRoutes, freezeRoutes===1?'✅ OK':'⚠️ CHECK');
