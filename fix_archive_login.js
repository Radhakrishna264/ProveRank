const fs = require('fs');

// ══ FIX 1: GET /admins route mein archived filter add karo ══
const amPath = 'src/routes/adminManagement.js';
let am = fs.readFileSync(amPath, 'utf8');

// Find GET /admins route - archived:false filter add karo
if(am.includes("role: { $in: ['admin','moderator','superadmin'] }") && !am.includes("archived: { $ne: true }")){
  am = am.replace(
    "role: { $in: ['admin','moderator','superadmin'] }",
    "role: { $in: ['admin','moderator','superadmin'] }, archived: { $ne: true }"
  );
  console.log('✅ Fix 1a: archived filter added (superadmin variant)');
}
if(am.includes("role: { $in: ['admin','moderator'] }") && !am.includes("archived: { $ne: true }")){
  am = am.replace(
    "role: { $in: ['admin','moderator'] }",
    "role: { $in: ['admin','moderator'] }, archived: { $ne: true }"
  );
  console.log('✅ Fix 1b: archived filter added (admin variant)');
}

// Also check simple role:'admin' pattern
am = am.replace(
  /User\.find\(\{\s*role:\s*\{\s*\$ne:\s*'superadmin'\s*\}\s*\}\)/g,
  "User.find({ role: { $ne: 'superadmin' }, archived: { $ne: true } })"
);

fs.writeFileSync(amPath, am);

// ══ FIX 2: Login route mein frozen check add karo ══
// Auth route find karo
const authFiles = ['src/routes/auth.js','src/routes/authRoutes.js'];
let authPath = '';
for(const f of authFiles){
  try{ fs.accessSync(f); authPath=f; break; }catch{}
}

if(!authPath){
  const allRoutes = fs.readdirSync('src/routes');
  console.log('Route files:', allRoutes);
} else {
  let auth = fs.readFileSync(authPath,'utf8');
  console.log('Auth file found:', authPath);
  
  // Find banned check and add frozen check after/near it
  if(auth.includes('isBanned') || auth.includes('banned')){
    if(!auth.includes('frozen') && !auth.includes('isFrozen')){
      // Add frozen check after banned check
      auth = auth.replace(
        /if\s*\(\s*(user\.banned|user\.isBanned)\s*\)/,
        `if (user.frozen) { return res.status(403).json({ message: 'Account frozen. Contact SuperAdmin.', code: 'FROZEN' }); }\n  if (user.banned || user.isBanned)`
      );
      fs.writeFileSync(authPath, auth);
      console.log('✅ Fix 2: frozen login block added to', authPath);
    } else {
      console.log('ℹ️ frozen check already exists in auth');
    }
  } else {
    console.log('⚠️ banned check not found - check auth file manually');
  }
}

// ══ VERIFY ══
const am2 = fs.readFileSync(amPath,'utf8');
console.log('\n═══ VERIFY ═══');
console.log('archived filter:', am2.includes('archived: { $ne: true }') ? '✅' : '❌');
if(authPath){
  const auth2 = fs.readFileSync(authPath,'utf8');
  console.log('frozen login block:', auth2.includes('frozen') ? '✅' : '❌');
}
