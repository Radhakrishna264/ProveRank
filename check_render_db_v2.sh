#!/bin/bash
# Render ke actual production DB se users fetch karta hai
# Backend API call karta hai — koi URI copy nahi karna

TOKEN=""

# Step 1: Superadmin login karke token lo
echo "=== Logging in as SuperAdmin ==="
RESPONSE=$(curl -s -X POST https://proverank.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@proverank.com","password":"ProveRank@123"}')

echo "Login response: $RESPONSE"
TOKEN=$(echo $RESPONSE | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token||'')}catch{console.log('')}})")

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed — check credentials"
  exit 1
fi
echo "✅ Token received"

# Step 2: Admin students list fetch karo
echo ""
echo "=== STUDENTS FROM RENDER PRODUCTION DB ==="
curl -s https://proverank.onrender.com/api/admin/students \
  -H "Authorization: Bearer $TOKEN" | node -e "
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const res = JSON.parse(d)
    const students = Array.isArray(res) ? res : (res.students||res.data||[])
    console.log('Total students:', students.length)
    students.forEach((u,i)=>{
      console.log('['+i+'] '+u.email+' | '+u.name+' | verified: '+(u.emailVerified||u.verified||false)+' | role: '+(u.role||'?'))
    })
  }catch(e){
    console.log('Raw response:', d.substring(0,500))
  }
})"

# Step 3: All users (including admins)
echo ""
echo "=== ALL USERS FROM RENDER DB ==="
curl -s "https://proverank.onrender.com/api/admin/manage/students?limit=100" \
  -H "Authorization: Bearer $TOKEN" | node -e "
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const res = JSON.parse(d)
    const users = Array.isArray(res) ? res : (res.students||res.users||res.data||[])
    if(users.length===0){console.log('No data from this endpoint, trying next...');return}
    console.log('Total:', users.length)
    users.forEach((u,i)=>console.log('['+i+'] '+u.email+' | '+(u.role||'?')+' | verified: '+(u.emailVerified||u.verified||false)))
  }catch(e){
    console.log('Response:', d.substring(0,300))
  }
})"
