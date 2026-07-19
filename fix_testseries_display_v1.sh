#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX 1: Student Panel "Batches & Test Series" page missing top bar
# FIX 2: Published Test Series not showing on student side
#
# ROOT CAUSE (Bug 1): test-series/page.tsx never imports/wraps
# <StudentShell> — it has its own standalone header instead.
#
# ROOT CAUSE (Bug 2): studentBatches.js (backend) only ever queried
# the Batch model. TestSeries was never merged into the student-
# facing list, so published series never reached the student UI —
# regardless of admin publishing them.
#
# FIX: Backend now merges published TestSeries into the same
# /api/student/batches response (normalized to Batch's shape, since
# TestSeries schema already mirrors Batch fields 1:1). No frontend
# card changes needed. Enroll/detail routes fall back to TestSeries
# when a Batch isn't found by that id. Frontend page now wraps in
# StudentShell so the topbar shows like other student pages.
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

BACKEND_FILE="src/routes/studentBatches.js"
FRONTEND_FILE="frontend/app/dashboard/test-series/page.tsx"

if [ ! -f "$BACKEND_FILE" ]; then echo "❌ Not found: $BACKEND_FILE"; exit 1; fi
if [ ! -f "$FRONTEND_FILE" ]; then echo "❌ Not found: $FRONTEND_FILE"; exit 1; fi

cp "$BACKEND_FILE" "${BACKEND_FILE}.bak_$(date +%s)"
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.bak_$(date +%s)"

echo "=== 1) Rewriting backend: $BACKEND_FILE ==="
cat > "$BACKEND_FILE" << 'ENDOFFILE'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const Batch=require('../models/Batch');
const TestSeries=require('../models/TestSeries');
const User=require('../models/User');
const jwt=require('jsonwebtoken');
const JWT=process.env.JWT_SECRET||'proverank_jwt_super_secret_key_2024';

const optAuth=(req,res,next)=>{
  const h=req.headers.authorization;
  if(h&&h.startsWith('Bearer ')){try{req.user=jwt.verify(h.split(' ')[1],JWT);}catch(e){}}
  next();
};
const auth=(req,res,next)=>{
  const h=req.headers.authorization;
  if(!h||!h.startsWith('Bearer '))return res.status(401).json({error:'Unauthorized'});
  try{req.user=jwt.verify(h.split(' ')[1],JWT);next();}
  catch(e){res.status(401).json({error:'Invalid token'});}
};

function effectivePrice(b){
  if(b.flashSalePrice&&b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())return b.flashSalePrice;
  return b.discountPrice||b.price||0;
}
function discountPct(b){
  const base=b.price||0,eff=effectivePrice(b);
  if(!base||base<=eff)return 0;
  return Math.round(((base-eff)/base)*100);
}
function computeFitScore(b,user){
  let score=50;
  if(user&&user.targetExam){
    if((b.examType||'').toLowerCase()===String(user.targetExam).toLowerCase())score+=30;
    else score-=10;
  }
  if(b.rating)score+=Math.round((b.rating-3)*5);
  if(b.enrolledCount>100)score+=10; else if(b.enrolledCount>20)score+=5;
  if(b.isSpotlight)score+=5;
  return Math.max(0,Math.min(100,score));
}

// ── FPR5: normalize a TestSeries doc to look like a Batch doc so the
// existing student UI (BatchCard etc.) can render it without any
// frontend changes. TestSeries schema already mirrors Batch field
// names almost 1:1 — only seriesType -> batchType needs remapping. ──
function normalizeSeries(s){
  return{
    ...s,
    _kind:'series',
    batchType:s.seriesType||'Recorded',
    enrolledCount:s.enrolledCount||(s.students?s.students.length:0)||0,
    validity:s.validity||365
  };
}

function baseSeriesFilter(){
  return{ lifecycleStatus:'active', visibility:{$ne:'private'}, isTemplate:{$ne:true} };
}

// GET /api/student/batches  (now also returns published Test Series, merged in)
router.get('/',optAuth,async(req,res)=>{
  try{
    const{
      examType,isFree,search,sort='newest',category,subject,
      batchType,difficulty,language,minPrice,maxPrice,
      offerType,flashSaleActive,emiEligible,enrollmentState
    }=req.query;

    const filter={status:'active'};
    if(examType)filter.examType=examType;
    if(isFree!==undefined)filter.isFree=isFree==='true';
    if(category)filter.category=category;
    if(subject)filter.subject=subject;
    if(batchType)filter.batchType=batchType;
    if(difficulty)filter.difficulty=difficulty;
    if(language)filter.language=language;
    if(search)filter.name={$regex:search,$options:'i'};
    if(minPrice||maxPrice){
      filter.price={};
      if(minPrice)filter.price.$gte=Number(minPrice);
      if(maxPrice)filter.price.$lte=Number(maxPrice);
    }
    if(flashSaleActive==='true')filter.flashSaleEndTime={$gte:new Date()};
    if(offerType==='trial')filter.allowFreeTrial=true;
    else if(offerType==='bundle')filter.isBundle=true;
    else if(offerType==='spotlight')filter.isSpotlight=true;
    else if(offerType==='flashsale')filter.flashSaleEndTime={$gte:new Date()};
    if(enrollmentState==='full')filter.$expr={$and:[{$gt:['$seatLimit',0]},{$gte:['$enrolledCount','$seatLimit']}]};

    // ── Series filter mirrors the Batch filter above, mapped to TestSeries fields ──
    const seriesFilter=baseSeriesFilter();
    if(examType)seriesFilter.examType=examType;
    if(isFree!==undefined)seriesFilter.isFree=isFree==='true';
    if(subject)seriesFilter.subject=subject;
    if(batchType)seriesFilter.seriesType=batchType;
    if(difficulty)seriesFilter.difficulty=difficulty;
    if(language)seriesFilter.language=language;
    if(search)seriesFilter.name={$regex:search,$options:'i'};
    if(minPrice||maxPrice){
      seriesFilter.price={};
      if(minPrice)seriesFilter.price.$gte=Number(minPrice);
      if(maxPrice)seriesFilter.price.$lte=Number(maxPrice);
    }
    if(flashSaleActive==='true')seriesFilter.flashSaleEndTime={$gte:new Date()};
    if(offerType==='trial')seriesFilter.allowFreeTrial=true;
    else if(offerType==='bundle')seriesFilter.isBundle=true;
    else if(offerType==='spotlight')seriesFilter.isSpotlight=true;
    else if(offerType==='flashsale')seriesFilter.flashSaleEndTime={$gte:new Date()};

    let sortObj={createdAt:-1};
    if(sort==='popular'||sort==='enrolled')sortObj={enrolledCount:-1};
    else if(sort==='price_low')sortObj={price:1};
    else if(sort==='price_high')sortObj={price:-1};
    else if(sort==='rating')sortObj={rating:-1};

    let batches=await Batch.find(filter).sort(sortObj).lean();
    let series=await TestSeries.find(seriesFilter).sort(sortObj).lean();
    series=series.map(normalizeSeries);
    batches=batches.concat(series);

    if(sort==='discount')batches=batches.sort((a,b)=>discountPct(b)-discountPct(a));
    else if(sort==='newest')batches=batches.sort((a,b)=>new Date(b.createdAt)-new Date(a.createdAt));

    let enrolledIds=[],wishlistIds=[],priceWatchMap={},user=null;
    if(req.user){
      user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
      enrolledIds=(user?.enrolledBatches||[]).map(id=>id.toString());
      wishlistIds=(user?.wishlistBatches||[]).map(id=>id.toString());
      (user?.priceWatch||[]).forEach(pw=>{priceWatchMap[pw.batchId?.toString()]=pw.watchedPrice;});
    }
    const result=batches.map(b=>{
      const eff=effectivePrice(b);
      const watched=priceWatchMap[b._id.toString()];
      return{
        ...b,
        isEnrolled:enrolledIds.includes(b._id.toString()),
        isWishlisted:wishlistIds.includes(b._id.toString()),
        effectivePrice:eff,
        discountPct:discountPct(b),
        fitScore:computeFitScore(b,user),
        isPriceWatched:watched!==undefined,
        priceDropped:watched!==undefined&&eff<watched
      };
    });
    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/student/batches/my
router.get('/my',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.enrolledBatches||[];
    const batches=await Batch.find({_id:{$in:ids},status:'active'}).lean();
    let series=await TestSeries.find({_id:{$in:ids},...baseSeriesFilter()}).lean();
    series=series.map(normalizeSeries);
    res.json({batches:batches.concat(series)});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/wishlist
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const priceWatch=user?.priceWatch||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    let series=await TestSeries.find({_id:{$in:ids}}).lean();
    series=series.map(normalizeSeries);
    const merged=batches.concat(series);
    const result=merged.map(b=>{
      const pw=priceWatch.find(x=>x.batchId?.toString()===b._id.toString());
      const eff=effectivePrice(b);
      return{...b,effectivePrice:eff,discountPct:discountPct(b),isPriceWatched:!!pw,priceDropped:!!pw&&eff<pw.watchedPrice,watchedPrice:pw?pw.watchedPrice:null};
    });
    res.json({batches:result});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/:id  (Batch first, TestSeries fallback)
router.get('/:id',optAuth,async(req,res)=>{
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
        instructorHighlight:batch.teacherAssigned?`Faculty: ${batch.teacherAssigned} — subject expert, curates ${batch.subject||'this'} content for ${batch.examType||'this exam'} aspirants.`:'',
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
});

// POST /api/student/batches/:id/enroll  (Batch first, TestSeries fallback)
router.post('/:id/enroll',auth,async(req,res)=>{
  try{
    let doc=await Batch.findById(req.params.id);
    let Model=Batch;
    if(!doc){
      doc=await TestSeries.findById(req.params.id);
      Model=TestSeries;
    }
    if(!doc)return res.status(404).json({error:'Not found'});
    if(!doc.isFree&&!doc.allowFreeTrial)return res.status(400).json({error:'Paid batch'});
    await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$addToSet:{enrolledBatches:doc._id}});
    const inc={enrolledCount:1};
    if(Model===TestSeries){
      await Model.findByIdAndUpdate(req.params.id,{$inc:inc,$addToSet:{students:new mongoose.Types.ObjectId(req.user.id)}});
    }else{
      await Model.findByIdAndUpdate(req.params.id,{$inc:inc});
    }
    res.json({success:true,message:'Enrolled!'});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/student/batches/:id/wishlist (toggle) — works for Batch or TestSeries ids
// since it only stores raw ObjectIds in user.wishlistBatches without a Model check.
router.post('/:id/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const wishlist=user?.wishlistBatches||[];
    const bObjId=new mongoose.Types.ObjectId(req.params.id);
    const isW=wishlist.some(id=>id.toString()===req.params.id);
    if(isW){
      await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$pull:{wishlistBatches:bObjId,priceWatch:{batchId:bObjId}}});
    }else{
      await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$addToSet:{wishlistBatches:bObjId}});
    }
    res.json({success:true,isWishlisted:!isW});
  }catch(e){res.status(500).json({error:e.message});}
});

module.exports=router;
ENDOFFILE

echo "✅ Backend rewritten"
grep -n "TestSeries" "$BACKEND_FILE" | head -5

echo ""
echo "=== 2) Patching frontend: $FRONTEND_FILE ==="

# 2a. Add StudentShell import
sed -i "/from 'next\/navigation'/a import StudentShell from '@/src/components/StudentShell'" "$FRONTEND_FILE"

# 2b. Insert opening <StudentShell> tag right before the root page div
sed -i "/minHeight:'100vh'/i\\      <StudentShell pageKey=\"test-series\">" "$FRONTEND_FILE"

# 2c. Insert closing </StudentShell> right after the outer div closes (line after QuickPreviewModal)
LINE=$(grep -n "previewBatchId&&<QuickPreviewModal" "$FRONTEND_FILE" | head -1 | cut -d: -f1)
CLOSE_LINE=$((LINE+1))
sed -i "${CLOSE_LINE}a\\      </StudentShell>" "$FRONTEND_FILE"

echo "✅ Frontend patched"
echo ""
echo "=== Verifying frontend changes ==="
grep -n "StudentShell" "$FRONTEND_FILE"

echo ""
echo "✅ DONE. Git push karke Render + Vercel pe deploy karo, phir:"
echo "   1. Admin panel se ek Test Series active/publish karo"
echo "   2. Student panel > Batches & Test Series page refresh karo"
echo "   3. Topbar + published series dono dikhni chahiye"
