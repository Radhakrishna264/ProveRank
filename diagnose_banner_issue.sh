#!/bin/bash
cd ~/workspace

echo "=== 1. Login as SuperAdmin ==="
TOKEN=$(curl -s -X POST https://proverank.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@proverank.com","password":"ProveRank@SuperAdmin123"}' | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token)}catch(e){console.log('PARSE_FAIL:',d)}})")
echo "Token acquired: ${TOKEN:0:20}..."
echo ""

echo "=== 2. Find FYS series _id ==="
FYS_JSON=$(curl -s "https://proverank.onrender.com/api/admin/test-series-manager?limit=200" -H "Authorization: Bearer $TOKEN")
echo "$FYS_JSON" | node -e "
let d='';process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const j=JSON.parse(d);
    const fys=(j.series||[]).find(s=>(s.name||'').toLowerCase().includes('fys'));
    if(fys){
      console.log('FYS _id:', fys._id);
      console.log('FYS lifecycleStatus:', fys.lifecycleStatus);
      console.log('FYS isPublished:', fys.isPublished);
      console.log('FYS publishState:', fys.publishState);
    } else {
      console.log('FYS not found in series list. Raw names:', (j.series||[]).map(s=>s.name));
    }
  }catch(e){console.log('PARSE_FAIL:', d.slice(0,300))}
});
" > /tmp/fys_info.txt
cat /tmp/fys_info.txt
FYS_ID=$(grep "FYS _id:" /tmp/fys_info.txt | awk '{print $3}')
echo ""
echo "Using FYS_ID=$FYS_ID"
echo ""

if [ -z "$FYS_ID" ]; then
  echo "❌ Could not extract FYS_ID — stopping here, share the output above."
  exit 0
fi

echo "=== 3. Admin view — GET /:id/banner (raw banner doc as admin sees it) ==="
curl -s "https://proverank.onrender.com/api/admin/test-series-manager/${FYS_ID}/banner" \
  -H "Authorization: Bearer $TOKEN" | node -e "
let d='';process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const j=JSON.parse(d);
    if(!j.banner){ console.log('❌ banner is NULL in admin response'); console.log(JSON.stringify(j,null,2).slice(0,500)); }
    else {
      console.log('banner._id:', j.banner._id);
      console.log('banner.title:', j.banner.title);
      console.log('banner.status:', j.banner.status);
      console.log('banner.linkedType:', j.banner.linkedType);
      console.log('banner.linkedBatchId:', j.banner.linkedBatchId, '(type:', typeof j.banner.linkedBatchId, ')');
      console.log('banner.published (legacy bool):', j.banner.published);
    }
  }catch(e){console.log('PARSE_FAIL:', d.slice(0,500))}
});
"
echo ""

echo "=== 4. Student view — GET /api/student/batches (list) — does FYS entry have 'banner'? ==="
curl -s "https://proverank.onrender.com/api/student/batches" | node -e "
let d='';process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const j=JSON.parse(d);
    const fys=(j.batches||[]).find(b=>(b.name||'').toLowerCase().includes('fys'));
    if(!fys){ console.log('❌ FYS not found in student list response at all'); }
    else {
      console.log('FYS in list — _id:', fys._id);
      console.log('FYS in list — banner:', fys.banner ? 'PRESENT (title=' + fys.banner.title + ', status=' + fys.banner.status + ')' : 'NULL ❌');
    }
  }catch(e){console.log('PARSE_FAIL:', d.slice(0,500))}
});
"
echo ""

echo "=== 5. Student view — GET /api/student/batches/:id (detail/modal) — does it have 'banner'? ==="
curl -s "https://proverank.onrender.com/api/student/batches/${FYS_ID}" | node -e "
let d='';process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
  try{
    const j=JSON.parse(d);
    if(!j.batch){ console.log('❌ no batch object in response'); console.log(d.slice(0,500)); }
    else { console.log('detail — banner field present?', j.batch.banner !== undefined ? 'YES: ' + JSON.stringify(j.batch.banner).slice(0,200) : 'NO — key missing entirely ❌'); }
  }catch(e){console.log('PARSE_FAIL:', d.slice(0,500))}
});
"
