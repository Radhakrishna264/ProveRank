#!/bin/bash
# ══════════════════════════════════════════════════════
# ProveRank — Backend Fix: Permissions Map Serialization
# Bug: admin.toObject() → Map serializes as {} in JSON
# Fix: Convert Map → plain object before sending
# ══════════════════════════════════════════════════════
export BEFILE="$HOME/workspace/src/routes/adminManagement.js"

if [ ! -f "$BEFILE" ]; then echo "❌ File not found: $BEFILE"; exit 1; fi
cp "$BEFILE" "${BEFILE}.bak.$(date +%s)"
echo "✅ Backup created"

node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.BEFILE;
let c=fs.readFileSync(FILE,'utf8');

// ── FIX 1: Profile route — convert Map to plain object ──
// Old: admin: admin.toObject()
// New: admin: { ...admin.toObject(), permissions: Object.fromEntries(admin.permissions||new Map()) }
const OLD1=`admin: admin.toObject(),`;
const NEW1=`admin: { ...admin.toObject(), permissions: Object.fromEntries(admin.permissions||new Map()) },`;
if(c.includes(OLD1)){
  c=c.replace(OLD1,NEW1);
  console.log('✅ Fix 1: Profile route — Map → plain object');
}else{
  // Try alternate format without trailing comma
  const OLD1b=`admin: admin.toObject()`;
  if(c.includes(OLD1b)){
    c=c.replace(OLD1b,`admin: { ...admin.toObject(), permissions: Object.fromEntries(admin.permissions||new Map()) }`);
    console.log('✅ Fix 1 (alt): Profile route — Map → plain object');
  }else{
    console.warn('⚠️  Fix 1: admin.toObject() not found — check manually at line 263');
  }
}

// ── FIX 2: PUT permissions route — ensure Map saves correctly ──
// Old: await User.findByIdAndUpdate(req.params.id, { permissions });
// New: proper Map-aware save
const OLD2=`await User.findByIdAndUpdate(req.params.id, { permissions });`;
const NEW2=`const adminToUpdate=await User.findById(req.params.id);
    if(!adminToUpdate) return res.status(404).json({message:'Admin nahi mila'});
    if(!adminToUpdate.permissions) adminToUpdate.permissions=new Map();
    Object.entries(permissions).forEach(([k,v])=>adminToUpdate.permissions.set(k,v));
    await adminToUpdate.save();`;
if(c.includes(OLD2)){
  c=c.replace(OLD2,NEW2);
  console.log('✅ Fix 2: PUT permissions — using Map.set() for correct save');
}else{
  console.warn('⚠️  Fix 2: findByIdAndUpdate permissions line not found — might already be fine');
}

fs.writeFileSync(FILE,c,'utf8');
console.log('\n✅ Backend permissions fix applied!');
NODEEOF

echo ""
echo "══════════════════════════════════════════════════"
echo "✅ Now run:"
echo "   git add -A && git commit -m 'Fix: permissions Map serialization backend' && git push"
echo "══════════════════════════════════════════════════"
