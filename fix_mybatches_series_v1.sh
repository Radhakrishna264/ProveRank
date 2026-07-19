#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX: Enrolled Test Series not showing on "My Batches & Test Series"
# page, even though student is enrolled (visible on the browse page).
#
# ROOT CAUSE: src/routes/myBatches.js only ever queries the Batch
# model for every route (list, renew, renewal, certificate-status,
# milestones, compare, wishlist). Since a previous fix made TestSeries
# enrollment also push the series id into user.enrolledBatches, those
# ids exist in the array — but Batch.find({_id:{$in:ids}}) silently
# skips any id that isn't actually a Batch document, so enrolled
# series just vanish from every "My Batches" route.
#
# FIX: Merge TestSeries (normalized to Batch's shape) into the same
# id-driven queries. Detail routes (renew/renewal/certificate-status/
# milestones) fall back to TestSeries when Batch.findById misses.
# stats/access/enroll-meta/leaderboard routes are already id-agnostic
# and untouched.
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

FILE="src/routes/myBatches.js"
if [ ! -f "$FILE" ]; then echo "❌ Not found: $FILE"; exit 1; fi
cp "$FILE" "${FILE}.bak_$(date +%s)"

echo "=== Rewriting $FILE ==="
cat > "$FILE" << 'ENDOFFILE'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const Batch=require('../models/Batch');
const TestSeries=require('../models/TestSeries');
const User=require('../models/User');
const jwt=require('jsonwebtoken');
const JWT=process.env.JWT_SECRET||'proverank_jwt_super_secret_key_2024';
let BatchActivity;
try{BatchActivity=require('../models/BatchActivity');}catch(e){BatchActivity=null;}

const auth=(req,res,next)=>{
  const h=req.headers.authorization;
  if(!h||!h.startsWith('Bearer '))return res.status(401).json({error:'Unauthorized'});
  try{req.user=jwt.verify(h.split(' ')[1],JWT);next();}
  catch(e){res.status(401).json({error:'Invalid token'});}
};

// ── FPR6: normalize a TestSeries doc to look like a Batch doc so the
// existing "My Batches" UI can render it without frontend changes. ──
function normalizeSeries(s){
  return{
    ...s,
    _kind:'series',
    batchType:s.seriesType||'Recorded',
    enrolledCount:s.enrolledCount||(s.students?s.students.length:0)||0,
    validity:s.validity||365
  };
}

// Fetch a single enrolled item by id, trying Batch first then TestSeries.
async function findEnrolledDoc(id){
  let doc=await Batch.findById(id).lean();
  if(doc)return doc;
  doc=await TestSeries.findById(id).lean();
  if(doc)return normalizeSeries(doc);
  return null;
}

// Enrollment meta schema (stored in user doc)
// enrolledBatchesMeta: [{batchId, enrolledAt, expiresAt, progress, testsCompleted, lastAccessedAt, streak, streakLastDate, avgScore, bestRank}]

function buildEnriched(b,m,now){
  const enrolledAt=m.enrolledAt?new Date(m.enrolledAt):new Date();
  const validityDays=b.validity||365;
  const expiresAt=m.expiresAt?new Date(m.expiresAt):new Date(enrolledAt.getTime()+validityDays*86400000);
  const daysLeft=Math.max(0,Math.ceil((expiresAt-now)/86400000));
  const testsCompleted=m.testsCompleted||0;
  const totalTests=b.totalTests||0;
  const progress=totalTests>0?Math.round((testsCompleted/totalTests)*100):0;
  const lastAccessedAt=m.lastAccessedAt?new Date(m.lastAccessedAt):enrolledAt;
  const daysSinceAccess=Math.floor((now-lastAccessedAt)/86400000);
  const streak=m.streak||0;
  // Simple linear forecast: days needed to reach 100% at current pace
  const daysActive=Math.max(1,Math.floor((now-enrolledAt)/86400000));
  const rate=testsCompleted/daysActive;
  const testsRemaining=Math.max(0,totalTests-testsCompleted);
  const forecastDays=rate>0?Math.ceil(testsRemaining/rate):null;
  return{
    ...b, enrolledAt, expiresAt, daysLeft, testsCompleted, totalTests,
    progress, lastAccessedAt, daysSinceAccess, streak,
    avgScore:m.avgScore||0, bestRank:m.bestRank||null,
    isExpiring:daysLeft<=7&&daysLeft>0, isExpired:daysLeft===0,
    isCompleted:progress>=100,
    renewalState:daysLeft===0?'expired':daysLeft<=7?'expiring_soon':'active',
    progressForecastDays:forecastDays,
    certificateEligible:progress>=100&&totalTests>0,
    healthScore:Math.min(100,Math.round((progress*0.5)+(Math.min(streak,30)/30*30)+(daysSinceAccess<=2?20:daysSinceAccess<=7?10:0)))
  };
}

// GET /api/my-batches — all enrolled batches + series with meta (+ search/filter/sort — FPR5)
router.get('/',auth,async(req,res)=>{
  try{
    const{q,filter,sort}=req.query;
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=(user?.enrolledBatches||[]);
    const meta=user?.enrolledBatchesMeta||[];
    let batches=await Batch.find({_id:{$in:ids},status:'active'}).lean();
    let series=await TestSeries.find({_id:{$in:ids}}).lean();
    series=series.map(normalizeSeries);
    batches=batches.concat(series);
    if(q)batches=batches.filter(b=>(b.name||'').toLowerCase().includes(q.toLowerCase())||(b.examType||'').toLowerCase().includes(q.toLowerCase())||(b.subject||'').toLowerCase().includes(q.toLowerCase())||(b.teacherAssigned||'').toLowerCase().includes(q.toLowerCase()));
    const now=new Date();
    let result=batches.map(b=>{
      const m=meta.find(x=>x.batchId?.toString()===b._id.toString())||{};
      return buildEnriched(b,m,now);
    });

    if(filter==='active')result=result.filter(x=>!x.isExpired&&!x.isCompleted);
    else if(filter==='completed')result=result.filter(x=>x.isCompleted);
    else if(filter==='free')result=result.filter(x=>x.isFree);
    else if(filter==='paid')result=result.filter(x=>!x.isFree);
    else if(filter==='expiring_soon')result=result.filter(x=>x.isExpiring);
    else if(filter==='certificate_available')result=result.filter(x=>x.certificateEligible);
    else if(filter==='streak_active')result=result.filter(x=>x.streak>0);
    else if(filter==='high_progress')result=result.filter(x=>x.progress>=70);
    else if(filter==='low_progress')result=result.filter(x=>x.progress<30);
    else if(filter==='top_rated')result=result.filter(x=>(x.rating||0)>=4.5);

    if(sort==='progress')result.sort((a,b)=>b.progress-a.progress);
    else if(sort==='score')result.sort((a,b)=>b.avgScore-a.avgScore);
    else if(sort==='streak')result.sort((a,b)=>b.streak-a.streak);
    else if(sort==='expiry')result.sort((a,b)=>a.daysLeft-b.daysLeft);
    else if(sort==='rating')result.sort((a,b)=>(b.rating||0)-(a.rating||0));
    else if(sort==='newest')result.sort((a,b)=>new Date(b.enrolledAt).getTime()-new Date(a.enrolledAt).getTime());
    else result.sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime());

    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/my-batches/stats — summary stats (enriched — FPR5 hero strip)
// (id-agnostic: works for both Batch and TestSeries ids already, no change needed)
router.get('/stats',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=user?.enrolledBatchesMeta||[];
    const ids=user?.enrolledBatches||[];
    const total=ids.length;
    const testsCompleted=meta.reduce((s,m)=>s+(m.testsCompleted||0),0);
    const now=new Date();
    const activeBatches=meta.filter(m=>{
      if(!m.expiresAt)return true;
      return new Date(m.expiresAt)>now;
    }).length;
    const certificates=meta.filter(m=>(m.testsCompleted||0)>=(m.totalTests||1)&&m.totalTests>0).length;
    const wishlistCount=(user?.wishlistBatches||[]).length;
    const avgProgress=meta.length?Math.round(meta.reduce((s,m)=>{
      const pct=m.totalTests>0?(m.testsCompleted/m.totalTests)*100:0;return s+pct;
    },0)/meta.length):0;
    const currentStreak=meta.length?Math.max(...meta.map(m=>m.streak||0)):0;
    const renewalDueSoon=meta.filter(m=>{
      if(!m.expiresAt)return false;
      const days=Math.ceil((new Date(m.expiresAt)-now)/86400000);
      return days<=7&&days>0;
    }).length;
    res.json({total,testsCompleted,activeBatches,certificates,wishlistCount,avgProgress,currentStreak,renewalDueSoon});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/:id/access — update last accessed + streak
// (id-agnostic: no change needed)
router.post('/:id/access',auth,async(req,res)=>{
  try{
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const idx=meta.findIndex(m=>m.batchId?.toString()===req.params.id);
    const now=new Date();
    const today=now.toDateString();
    if(idx>=0){
      const last=meta[idx].streakLastDate?new Date(meta[idx].streakLastDate).toDateString():null;
      const yesterday=new Date(now-86400000).toDateString();
      if(last===today){/* same day, no streak change */}
      else if(last===yesterday){meta[idx].streak=(meta[idx].streak||0)+1;}
      else{meta[idx].streak=1;}
      meta[idx].streakLastDate=now;
      meta[idx].lastAccessedAt=now;
    }else{
      meta.push({batchId:req.params.id,enrolledAt:now,streak:1,streakLastDate:now,lastAccessedAt:now,testsCompleted:0,avgScore:0});
    }
    await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    res.json({success:true,streak:idx>=0?meta[idx].streak:1});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/enroll-meta — store enrollment meta when enrolling
// (id-agnostic: no change needed)
router.post('/enroll-meta',auth,async(req,res)=>{
  try{
    const{batchId,validity=365}=req.body;
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const exists=meta.find(m=>m.batchId?.toString()===batchId);
    if(!exists){
      const now=new Date();
      const expiresAt=new Date(now.getTime()+validity*86400000);
      meta.push({batchId,enrolledAt:now,expiresAt,streak:0,testsCompleted:0,avgScore:0,bestRank:null,lastAccessedAt:now});
      await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    }
    res.json({success:true});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/wishlist — wishlist batches + series (separate from test-series wishlist UI)
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    let series=await TestSeries.find({_id:{$in:ids}}).lean();
    series=series.map(normalizeSeries);
    res.json({batches:batches.concat(series)});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/:id/renew — one-tap renew (extends validity from now)
router.post('/:id/renew',auth,async(req,res)=>{
  try{
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const doc=await findEnrolledDoc(req.params.id);
    if(!doc)return res.status(404).json({error:'Batch not found'});
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const idx=meta.findIndex(m=>m.batchId?.toString()===req.params.id);
    // SECURITY FIX: renew must not act as a free-enrollment bypass.
    // Only an already-enrolled student may renew; otherwise reject.
    if(idx<0)return res.status(404).json({error:'You are not enrolled in this batch — enroll first before renewing'});
    const now=new Date();
    const validityDays=doc.validity||365;
    const newExpiry=new Date(now.getTime()+validityDays*86400000);
    meta[idx].renewalHistory=meta[idx].renewalHistory||[];
    meta[idx].renewalHistory.push({renewedAt:now,previousExpiry:meta[idx].expiresAt||null,newExpiry});
    meta[idx].expiresAt=newExpiry;
    await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    res.json({success:true,newExpiry});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:id/renewal — renewal state + price
router.get('/:id/renewal',auth,async(req,res)=>{
  try{
    const doc=await findEnrolledDoc(req.params.id);
    if(!doc)return res.status(404).json({error:'Batch not found'});
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=(user?.enrolledBatchesMeta||[]).find(m=>m.batchId?.toString()===req.params.id)||{};
    const now=new Date();
    const daysLeft=meta.expiresAt?Math.max(0,Math.ceil((new Date(meta.expiresAt)-now)/86400000)):null;
    res.json({
      renewalState:daysLeft===0?'expired':daysLeft!==null&&daysLeft<=7?'expiring_soon':'active',
      daysLeft, expiresAt:meta.expiresAt||null,
      price:doc.isFree?0:(doc.discountPrice||doc.price||0),
      renewalHistory:meta.renewalHistory||[]
    });
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:id/certificate-status
router.get('/:id/certificate-status',auth,async(req,res)=>{
  try{
    const doc=await findEnrolledDoc(req.params.id);
    if(!doc)return res.status(404).json({error:'Batch not found'});
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=(user?.enrolledBatchesMeta||[]).find(m=>m.batchId?.toString()===req.params.id)||{};
    const totalTests=doc.totalTests||0;
    const testsCompleted=meta.testsCompleted||0;
    const progress=totalTests>0?Math.round((testsCompleted/totalTests)*100):0;
    res.json({
      eligible:progress>=100&&totalTests>0,
      progress, testsCompleted, totalTests,
      missingRequirements:progress<100?[`Complete ${totalTests-testsCompleted} more test(s)`]:[],
      issueDate:progress>=100?(meta.completedAt||new Date()):null
    });
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/compare?ids=a,b — compare 2 enrolled batches/series
router.get('/compare',auth,async(req,res)=>{
  try{
    const ids=(req.query.ids||'').split(',').filter(Boolean);
    if(ids.length<2)return res.status(400).json({error:'Provide at least 2 ids'});
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=user?.enrolledBatchesMeta||[];
    let batches=await Batch.find({_id:{$in:ids}}).lean();
    let series=await TestSeries.find({_id:{$in:ids}}).lean();
    series=series.map(normalizeSeries);
    batches=batches.concat(series);
    const now=new Date();
    const rows=batches.map(b=>{
      const m=meta.find(x=>x.batchId?.toString()===b._id.toString())||{};
      return buildEnriched(b,m,now);
    });
    res.json({comparison:rows});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:id/milestones — achievement milestones
router.get('/:id/milestones',auth,async(req,res)=>{
  try{
    const doc=await findEnrolledDoc(req.params.id);
    if(!doc)return res.status(404).json({error:'Batch not found'});
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=(user?.enrolledBatchesMeta||[]).find(m=>m.batchId?.toString()===req.params.id)||{};
    const testsCompleted=meta.testsCompleted||0;
    const totalTests=doc.totalTests||0;
    const progress=totalTests>0?Math.round((testsCompleted/totalTests)*100):0;
    const milestones=[
      {label:'First Test',achieved:testsCompleted>=1},
      {label:'25% Complete',achieved:progress>=25},
      {label:'50% Complete',achieved:progress>=50},
      {label:'75% Complete',achieved:progress>=75},
      {label:'7-Day Streak',achieved:(meta.streak||0)>=7},
      {label:'Completed',achieved:progress>=100}
    ];
    res.json({milestones});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/activity-feed — combined activity feed across all enrolled batches
// (BatchActivity is admin-authored per Batch only — series won't have entries yet; unchanged)
router.get('/activity-feed',auth,async(req,res)=>{
  try{
    if(!BatchActivity)return res.json({activity:[]});
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.enrolledBatches||[];
    const activity=await BatchActivity.find({batchId:{$in:ids},isActive:true}).sort({createdAt:-1}).limit(30).lean();
    res.json({activity});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:batchId/leaderboard — batch/series-specific leaderboard
// (id-agnostic: matched purely via enrolledBatchesMeta.batchId, no change needed)
router.get('/:batchId/leaderboard', auth, async (req, res) => {
  try {
    const batchId = req.params.batchId;
    const users = await User.collection.find({
      'enrolledBatchesMeta.batchId': new (require('mongoose').Types.ObjectId)(batchId)
    }).toArray();
    const lb = users.map(u => {
      const meta = (u.enrolledBatchesMeta || []).find(m => m.batchId && m.batchId.toString() === batchId);
      return {
        name: u.name || 'Student',
        testsCompleted: meta ? (meta.testsCompleted || 0) : 0,
        avgScore:       meta ? (meta.avgScore || 0) : 0,
        streak:         meta ? (meta.streak || 0) : 0,
        bestRank:       meta ? (meta.bestRank || null) : null,
      };
    }).sort((a, b) => b.testsCompleted - a.testsCompleted || b.avgScore - a.avgScore);
    const myIdx = lb.findIndex((_, i) => {
      const u = users[i];
      return u && u._id && req.user && u._id.toString() === req.user.id;
    });
    res.json({ leaderboard: lb.slice(0, 20), myRank: myIdx + 1, total: lb.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});
module.exports=router;
ENDOFFILE

echo "✅ Rewritten"
grep -n "TestSeries\|findEnrolledDoc" "$FILE"

echo ""
echo "✅ DONE. Git push karke Render pe deploy karo, phir My Batches & Test Series page refresh karke check karo — enrolled series bhi dikhni chahiye."
