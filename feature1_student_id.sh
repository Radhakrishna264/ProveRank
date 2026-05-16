#!/bin/bash
# ProveRank — Feature 1: Student ID (PRxxABCD format) + Welcome Banner Backend
# Run: bash feature1_student_id.sh

echo "=== FEATURE 1: Student ID Backend ==="

node << 'EOF'
const fs=require('fs'),path=require('path');
const WS=process.env.HOME+'/workspace';

// ── Find model and route directories ──
const modelDirs=[WS+'/src/models',WS+'/models'];
const routeDirs=[WS+'/src/routes',WS+'/routes'];
let modelDir=null,routeDir=null;
for(const d of modelDirs){if(fs.existsSync(d)){modelDir=d;break;}}
for(const d of routeDirs){if(fs.existsSync(d)){routeDir=d;break;}}
console.log('Model dir:',modelDir,'Route dir:',routeDir);

// ── 1. Update User model to add studentId + welcomeSeen ──
const userModelPath=modelDir+'/User.js';
if(!fs.existsSync(userModelPath)){console.log('ERROR: User.js not found');process.exit(1);}
let um=fs.readFileSync(userModelPath,'utf8');

if(!um.includes('studentId')){
  // Add studentId field - try different patterns
  const patterns=[
    ['role:{',`studentId:{type:String,unique:true,sparse:true,trim:true},\n  welcomeSeen:{type:Boolean,default:false},\n  role:{`],
    ['role: {',`studentId: { type: String, unique: true, sparse: true, trim: true },\n  welcomeSeen: { type: Boolean, default: false },\n  role: {`],
    ['email:{',`studentId:{type:String,unique:true,sparse:true,trim:true},\n  welcomeSeen:{type:Boolean,default:false},\n  email:{`],
  ];
  let applied=false;
  for(const[old,rep] of patterns){
    if(um.includes(old)){um=um.replace(old,rep);applied=true;console.log('User model patched with pattern:',old.slice(0,20));break;}
  }
  if(!applied)console.log('WARN: Could not auto-patch User model. Add studentId manually.');
  fs.writeFileSync(userModelPath,um);
}else{console.log('studentId already in User model');}

// ── 2. Create studentId generator utility ──
const utilDir=WS+'/src/utils';
if(!fs.existsSync(utilDir))fs.mkdirSync(utilDir,{recursive:true});
fs.writeFileSync(utilDir+'/generateStudentId.js',`
const User = require('../models/User');

async function generateStudentId() {
  const year = new Date().getFullYear().toString().slice(-2); // "25" or "26"
  const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let id, exists, attempts = 0;
  do {
    const rand = Array.from({length:4}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join('');
    id = 'PR' + year + rand; // e.g. PR25A4B9
    exists = await User.findOne({ studentId: id }).lean();
    attempts++;
    if(attempts > 100) { id = 'PR' + year + Date.now().toString(36).toUpperCase().slice(-4); break; }
  } while(exists);
  return id;
}

module.exports = generateStudentId;
`);
console.log('generateStudentId utility created');

// ── 3. Patch registration route to assign studentId ──
let regFile=null;
const regNames=['auth.js','authRoutes.js','register.js','user.js','users.js'];
for(const f of fs.readdirSync(routeDir)){
  const fp=path.join(routeDir,f);
  const content=fs.readFileSync(fp,'utf8');
  if(content.includes('register')||content.includes('signup')||content.includes('password')){
    if(content.includes('User.create')||content.includes('new User')||content.includes('user.save')){
      regFile=fp;break;
    }
  }
}
// Also check for auth file specifically
for(const name of regNames){
  const fp=path.join(routeDir,name);
  if(fs.existsSync(fp)&&!regFile){regFile=fp;break;}
}
console.log('Registration route file:',regFile);

if(regFile){
  let rf=fs.readFileSync(regFile,'utf8');
  if(!rf.includes('generateStudentId')&&!rf.includes('studentId')){
    // Add import
    const utilPath=rf.includes("require('../utils/")?'../utils/':'../../utils/';
    if(!rf.includes('generateStudentId')){
      rf="const generateStudentId=require('"+utilPath+"generateStudentId');\n"+rf;
    }
    // Find where new user is created and add studentId
    const createPatterns=[
      ['await User.create({',`const _sid = await generateStudentId();\n  const newUser = await User.create({`],
      ['const user = new User({',`const _sid = await generateStudentId();\n  const user = new User({`],
      ['user = new User({',`const _sid = await generateStudentId();\n  user = new User({`],
    ];
    let regPatched=false;
    for(const[old,rep] of createPatterns){
      if(rf.includes(old)){
        // Also need to add studentId to the object
        rf=rf.replace(old,rep);
        // Find the closing of User.create object and add studentId
        // Look for common fields and add after
        const namePatterns=['name:req.body.name','name: req.body.name','email:req.body.email','email: req.body.email'];
        for(const np of namePatterns){
          if(rf.includes(np)){
            rf=rf.replace(np,np+',\n      studentId: _sid,\n      welcomeSeen: false');
            break;
          }
        }
        console.log('Registration patched with pattern:',old.slice(0,30));
        regPatched=true;break;
      }
    }
    if(!regPatched)console.log('WARN: Could not auto-patch registration. Pattern not found. Check manually.');
    fs.writeFileSync(regFile,rf);
  }else{console.log('Registration already has studentId');}
}

// ── 4. Patch login/auth to return welcomeSeen + studentId ──
// Find where JWT is signed/user is returned and ensure studentId is included
if(regFile){
  let rf=fs.readFileSync(regFile,'utf8');
  // Common token response patterns - add studentId to response
  const tokenPatterns=[
    ['{token, user}','{ token, user: {...user._doc||user, studentId:user.studentId, welcomeSeen:user.welcomeSeen} }'],
  ];
  // We'll just make sure select doesn't exclude studentId
  if(rf.includes('-password')&&!rf.includes('studentId')){
    rf=rf.replace('.select(\'-password\')','.select(\'-password\').lean()');
  }
  fs.writeFileSync(regFile,rf);
}

// ── 5. Add API endpoint to mark welcome as seen ──
// Find admin/student management route
let userRoute=null;
for(const f of fs.readdirSync(routeDir)){
  const fp=path.join(routeDir,f);
  const content=fs.readFileSync(fp,'utf8');
  if(content.includes('/profile')||content.includes('getProfile')){userRoute=fp;break;}
}
if(!userRoute){
  // Add to auth file
  userRoute=regFile;
}
console.log('User route for welcome-seen:',userRoute);
if(userRoute){
  let uf=fs.readFileSync(userRoute,'utf8');
  if(!uf.includes('/welcome-seen')&&!uf.includes('welcomeSeen')){
    const mp=uf.includes("require('../models/")?'../models/':'../../models/';
    const endpointCode=`
// Mark welcome banner as seen
router.post('/welcome-seen', async(req,res)=>{
  try{
    const token=req.headers.authorization?.split(' ')[1];
    if(!token)return res.status(401).json({success:false});
    const jwt=require('jsonwebtoken');
    const decoded=jwt.verify(token,process.env.JWT_SECRET||'proverank_secret');
    const User=require('${mp}User');
    await User.findByIdAndUpdate(decoded.id||decoded._id,{welcomeSeen:true});
    res.json({success:true});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});
`;
    // Add before module.exports
    uf=uf.replace('module.exports',endpointCode+'\nmodule.exports');
    fs.writeFileSync(userRoute,uf);
    console.log('welcome-seen endpoint added');
  }else{console.log('welcome-seen already exists');}
}

// ── 6. Migration: Generate IDs for existing students without one ──
fs.writeFileSync(WS+'/migrate_student_ids.js',`
// Run once: node migrate_student_ids.js
require('dotenv').config();
const mongoose=require('mongoose');
const User=require('./src/models/User');
const generateStudentId=require('./src/utils/generateStudentId');

async function migrate(){
  await mongoose.connect(process.env.MONGODB_URI||process.env.MONGO_URI);
  console.log('Connected');
  const students=await User.find({role:'student',studentId:{$exists:false}});
  console.log('Students without ID:',students.length);
  for(const s of students){
    const id=await generateStudentId();
    await User.findByIdAndUpdate(s._id,{studentId:id,welcomeSeen:true}); // existing = already welcomed
    console.log('Assigned',id,'to',s.email);
  }
  console.log('Migration done');
  process.exit(0);
}
migrate().catch(e=>{console.error(e);process.exit(1);});
`);
console.log('Migration script created: migrate_student_ids.js');
console.log('Run: node migrate_student_ids.js (to assign IDs to existing students)');
EOF

echo ""
echo "=== Step 2: Run Migration (assigns IDs to existing students) ==="
cd ~/workspace
if [ -f "migrate_student_ids.js" ]; then
  node migrate_student_ids.js && echo "Migration done" || echo "Migration failed - run manually after deploy"
fi

echo ""
echo "=== Pushing to Git ==="
cd ~/workspace && git add . && git commit -m "feat: Student ID PRxxABCD format generation + welcomeSeen + migration" && git push
echo "Feature 1 backend done!"
