#!/bin/bash
set -e
cd ~/workspace

echo "🔎 Step 0 — Verifying target files exist..."
for f in src/routes/studentBatches.js frontend/app/dashboard/test-series/page.tsx; do
  if [ ! -f "$f" ]; then echo "❌ Missing: $f — abort"; exit 1; fi
done
echo "✅ All target files found"

echo "🗄️  Step 1 — Backups..."
mkdir -p .fix_backups
ts=$(date +%Y%m%d_%H%M%S)
cp src/routes/studentBatches.js ".fix_backups/studentBatches.js.bak_$ts"
cp frontend/app/dashboard/test-series/page.tsx ".fix_backups/test-series-page.tsx.bak_$ts"
echo "✅ Backups saved"

echo "🛠️  Step 2 — Patching src/routes/studentBatches.js (attach banner to /:id detail route)..."
cat > /tmp/patch_studentbatches_detail.js << 'NODEEOF'
const fs = require('fs');
const file = 'src/routes/studentBatches.js';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

const oldBlock = `router.get('/:id',optAuth,async(req,res)=>{
  try{
    let batch=await Batch.findById(req.params.id).lean();
    if(!batch){
      const s=await TestSeries.findById(req.params.id).lean();
      if(s)batch=normalizeSeries(s);
    }
    if(!batch)return res.status(404).json({error:'Not found'});
    let user=null;
    if(req.user){
      user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    }
    const totalTests=batch.totalTests||0;
    const validityDays=batch.validity||365;
    const studyLoadPerWeek=totalTests>0?Math.max(1,Math.round((totalTests/(validityDays/7)))):0;
    res.json({
      batch:{
        ...batch,
        effectivePrice:effectivePrice(batch),
        discountPct:discountPct(batch),
        fitScore:computeFitScore(batch,user),
        instructorHighlight:batch.teacherAssigned?\`Faculty: \${batch.teacherAssigned} — subject expert, curates \${batch.subject||'this'} content for \${batch.examType||'this exam'} aspirants.\`:'',
        faqPreview:[
          {q:'Can I access this on mobile?',a:'Yes, fully accessible on the ProveRank mobile web app.'},
          {q:'Is there a refund policy?',a:'Refunds are handled per platform policy — contact support within 7 days.'},
          {q:'Do I get a certificate?',a:batch.totalTests>0?'Yes, on completing all tests in this batch.':'Certificate availability depends on batch configuration.'}
        ],
        socialProof:{enrolledCount:batch.enrolledCount||0,rating:batch.rating||0,ratingCount:batch.ratingCount||0},
        syllabusCoveragePct:Math.min(100,Math.round(((batch.totalTests||0)/60)*100))||(batch.totalTests?100:0),
        studyLoadPerWeek
      }
    });
  }catch(e){res.status(500).json({error:e.message});}
});`;

const newBlock = `router.get('/:id',optAuth,async(req,res)=>{
  try{
    let batch=await Batch.findById(req.params.id).lean();
    if(!batch){
      const s=await TestSeries.findById(req.params.id).lean();
      if(s)batch=normalizeSeries(s);
    }
    if(!batch)return res.status(404).json({error:'Not found'});
    let user=null;
    if(req.user){
      user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    }
    // 🔧 FIX (Banner not showing in preview modal) — this route never attached the
    // linked Banner (Creative Studio design) like the list route (GET /) already does.
    const banner=await Banner.findOne({ linkedBatchId:batch._id, status:{ \$nin:['removed','replaced'] } }).sort({ createdAt:-1 }).lean();
    const totalTests=batch.totalTests||0;
    const validityDays=batch.validity||365;
    const studyLoadPerWeek=totalTests>0?Math.max(1,Math.round((totalTests/(validityDays/7)))):0;
    res.json({
      batch:{
        ...batch,
        banner:banner||null,
        effectivePrice:effectivePrice(batch),
        discountPct:discountPct(batch),
        fitScore:computeFitScore(batch,user),
        instructorHighlight:batch.teacherAssigned?\`Faculty: \${batch.teacherAssigned} — subject expert, curates \${batch.subject||'this'} content for \${batch.examType||'this exam'} aspirants.\`:'',
        faqPreview:[
          {q:'Can I access this on mobile?',a:'Yes, fully accessible on the ProveRank mobile web app.'},
          {q:'Is there a refund policy?',a:'Refunds are handled per platform policy — contact support within 7 days.'},
          {q:'Do I get a certificate?',a:batch.totalTests>0?'Yes, on completing all tests in this batch.':'Certificate availability depends on batch configuration.'}
        ],
        socialProof:{enrolledCount:batch.enrolledCount||0,rating:batch.rating||0,ratingCount:batch.ratingCount||0},
        syllabusCoveragePct:Math.min(100,Math.round(((batch.totalTests||0)/60)*100))||(batch.totalTests?100:0),
        studyLoadPerWeek
      }
    });
  }catch(e){res.status(500).json({error:e.message});}
});`;

must(oldBlock, newBlock, 'attach banner to /:id detail route');

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_studentbatches_detail.js
node -c src/routes/studentBatches.js && echo "✅ studentBatches.js syntax OK"

echo "🛠️  Step 3 — Patching frontend test-series page.tsx (render banner inside QuickPreviewModal)..."
cat > /tmp/patch_previewmodal.js << 'NODEEOF'
const fs = require('fs');
const file = 'frontend/app/dashboard/test-series/page.tsx';
let c = fs.readFileSync(file, 'utf8');

function must(oldStr, newStr, label) {
  const count = c.split(oldStr).length - 1;
  if (count !== 1) {
    console.error(`❌ FAILED [${label}] — anchor found ${count} times (expected 1). Aborting, no changes written.`);
    process.exit(1);
  }
  c = c.replace(oldStr, newStr);
  console.log(`✅ Patched: ${label}`);
}

must(
`      <div onClick={e=>e.stopPropagation()} style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:\`1px solid \${ec}30\`,borderRadius:22,padding:24,maxWidth:440,width:'100%',maxHeight:'88vh',overflowY:'auto',backdropFilter:'blur(30px)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14 }}>`,
`      <div onClick={e=>e.stopPropagation()} style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:\`1px solid \${ec}30\`,borderRadius:22,padding:24,maxWidth:440,width:'100%',maxHeight:'88vh',overflowY:'auto',backdropFilter:'blur(30px)' }}>
        {b.banner&&(
          <div style={{ height:120,borderRadius:14,overflow:'hidden',marginBottom:14,position:'relative' }}>
            <StudentBannerCard banner={b.banner} />
          </div>
        )}
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14 }}>`,
'render StudentBannerCard inside QuickPreviewModal'
);

fs.writeFileSync(file, c, 'utf8');
console.log('✅ File written:', file);
NODEEOF
node /tmp/patch_previewmodal.js

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ FIX APPLIED — Banner now shows in student preview modal too"
echo "═══════════════════════════════════════════════════"
echo "Changed files:"
echo "  1. src/routes/studentBatches.js — /:id route now attaches linked Banner (same as list route)"
echo "  2. frontend/app/dashboard/test-series/page.tsx — QuickPreviewModal now renders the banner"
echo ""
echo "Note: grid card banner was already working correctly (confirmed via diagnostic curl —"
echo "list endpoint returns banner fine). The earlier screenshot without a visible banner was"
echo "taken before the banner had been configured in Admin Panel — not a code bug."
echo ""
echo "👉 Next steps:"
echo "   1. Restart backend: pkill -f node 2>/dev/null; cd ~/workspace && node src/index.js"
echo "   2. Open a Test Series / Batch card on student side → tap to open preview modal → banner should show"
echo "   3. git add -A && git commit -m 'Fix: banner missing from student preview modal detail route' && git push"
