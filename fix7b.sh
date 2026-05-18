#!/bin/bash
echo "🔧 Fix#7B Starting..."

# Step 1: adminManagement.js — inline generateAdminId + fix User.create
node - << 'JS'
const fs = require('fs');
const p = '/home/runner/workspace/src/routes/adminManagement.js';
let c = fs.readFileSync(p,'utf8');

// Add inline generateAdminId after imports (if not exists)
if(!c.includes('generateAdminId')){
  const fn = `\nasync function generateAdminId(){\n  const yr=new Date().getFullYear().toString().slice(-2);\n  const ch='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';\n  let id,ex;\n  do{\n    let r='';\n    for(let i=0;i<3;i++)r+=ch[Math.floor(Math.random()*ch.length)];\n    id='PRA'+yr+r;\n    ex=await User.findOne({adminId:id});\n  }while(ex);\n  return id;\n}\n`;
  c = c.replace('// — S37: CREATE ADMIN', fn + '// — S37: CREATE ADMIN');
  console.log('✅ generateAdminId function added');
} else { console.log('✅ generateAdminId already present'); }

// Replace _sid line with adminId
if(c.includes('const _sid = await generateStudentId()')){
  c = c.replace('const _sid = await generateStudentId();','const adminId = await generateAdminId();');
  console.log('✅ _sid replaced with adminId');
} else if(!c.includes('await generateAdminId()')){
  c = c.replace('const newUser = await User.create({','const adminId = await generateAdminId();\n    const newUser = await User.create({');
  console.log('✅ adminId generation added before User.create');
} else { console.log('✅ generateAdminId call already present'); }

// Add adminId to User.create object
if(!c.includes('adminId,') && !c.includes('adminId: adminId')){
  c = c.replace("verified: true,\n      permissions: permissions || {},","verified: true,\n      adminId,\n      permissions: permissions || {},");
  console.log('✅ adminId added to User.create');
} else { console.log('✅ adminId already in User.create'); }

fs.writeFileSync(p,c);
console.log('✅ adminManagement.js saved');
JS

# Step 2: Frontend — adminId badge in profileAdmin modal
node - << 'JS'
const fs = require('fs');
const p = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(p,'utf8');

if(c.includes('profileAdmin.adminId')){
  console.log('✅ adminId badge already in frontend');
} else {
  const t1 = `fontWeight:700,fontSize:16,color:'#E8F4FF'}}>{profileAdmin.name||'-'}</div>`;
  const t2 = `{profileAdmin.name||'-'}</div>`;
  const badge = `\n                  {profileAdmin.adminId&&<div style={{fontSize:11,color:'#00B4FF',background:'rgba(0,180,255,0.1)',border:'1px solid rgba(0,180,255,0.3)',borderRadius:12,padding:'3px 12px',marginTop:6,fontWeight:700,letterSpacing:1,display:'inline-block'}}>🪪 {profileAdmin.adminId}</div>}`;

  if(c.includes(t1)){
    c = c.replace(t1, t1 + badge);
    fs.writeFileSync(p,c);
    console.log('✅ adminId badge added (pattern 1)');
  } else if(c.includes(t2)){
    // Use last occurrence (profile modal, not list cards)
    const idx = c.lastIndexOf(t2);
    c = c.slice(0,idx+t2.length) + badge + c.slice(idx+t2.length);
    fs.writeFileSync(p,c);
    console.log('✅ adminId badge added (pattern 2)');
  } else {
    console.log('❌ Pattern not found');
  }
}
JS

# Step 3: Git push
cd ~/workspace
git add -A
git commit -m "Fix#7 Final: Admin ID generate in create-admin route + profile modal display"
git push
echo "✅ Fix#7 done! Vercel deploying (~2 min)"
