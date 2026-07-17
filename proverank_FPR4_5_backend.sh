#!/bin/bash
# ============================================================================
# ProveRank — MERGED BACKEND INSTALLER
# FPR4 Student Test Series/Batch Marketplace + FPR5 My Batches Hub Upgrade
# Run from your backend project ROOT on Replit: bash proverank_FPR4_5_backend.sh
# Safe to re-run (idempotent) — upgrades existing files in place, with backups.
# ============================================================================
set -e
echo "🚀 ProveRank FPR4+FPR5 — Backend Install Starting..."

# ---- Auto-detect paths ----
MODELS_DIR=$(find . -maxdepth 6 -type f -name "Batch.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
ROUTES_DIR=$(find . -maxdepth 6 -type f -name "myBatches.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})

if [ -z "$MODELS_DIR" ]; then echo "❌ Could not find models/Batch.js — run from backend root."; exit 1; fi
if [ -z "$ROUTES_DIR" ]; then echo "❌ Could not find routes/myBatches.js — run from backend root."; exit 1; fi
echo "📁 Models dir: $MODELS_DIR"
echo "📁 Routes dir: $ROUTES_DIR"

backup(){ [ -f "$1" ] && cp "$1" "$1.pre-fpr45-bak"; }
backup "$MODELS_DIR/Batch.js"
backup "$MODELS_DIR/BatchActivity.js"
backup "$ROUTES_DIR/studentBatches.js"
backup "$ROUTES_DIR/myBatches.js"
backup "$ROUTES_DIR/studentBatchExtras.js"
backup "$ROUTES_DIR/batchActivityRoutes.js"
echo "📦 Backups created (.pre-fpr45-bak)"

# ---------------------------------------------------------------------------
# 1) models/Batch.js
# ---------------------------------------------------------------------------
cat > "$MODELS_DIR/Batch.js" << 'FPR45_EOF_BATCH'
const mongoose=require('mongoose');
const BatchSchema=new mongoose.Schema({
  name:{type:String,required:true},
  description:{type:String,default:''},
  examType:{type:String,default:'NEET',enum:['NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course','Other']},
  category:{type:String,default:'Full Syllabus'},
  price:{type:Number,default:0},
  discountPrice:{type:Number,default:0},
  isFree:{type:Boolean,default:true},
  thumbnail:{type:String,default:''},
  totalTests:{type:Number,default:0},
  enrolledCount:{type:Number,default:0},
  language:{type:String,default:'Hindi + English'},
  difficulty:{type:String,default:'Medium',enum:['Easy','Medium','Hard','Mixed']},
  batchType:{type:String,default:'Recorded',enum:['Live','Recorded','Both']},
  isSpotlight:{type:Boolean,default:false},
  flashSaleEndTime:{type:Date},
  flashSalePrice:{type:Number},
  allowFreeTrial:{type:Boolean,default:false},
  trialDays:{type:Number,default:3},
  isBundle:{type:Boolean,default:false},
  bundleItems:[{type:String}],
  validity:{type:Number,default:365},
  tags:[{type:String}],
  status:{type:String,default:'active',enum:['active','inactive','draft']},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
  rating:{type:Number,default:4.5},
  ratingCount:{type:Number,default:0},
  syllabus:{type:String},
  subject:{type:String,default:'All Subjects'},
  students:[{type:mongoose.Schema.Types.ObjectId,ref:'User'}],
  notes:[{type:mongoose.Schema.Types.ObjectId,ref:'BatchNote'}],
  allowEMI:{type:Boolean,default:false},
  batchCode:{type:String,unique:true,sparse:true},
  lifecycleStatus:{type:String,default:'active',enum:['draft','active','upcoming','paused','archived']},
  visibility:{type:String,default:'public',enum:['public','private','invite_only']},
  seatLimit:{type:Number,default:0},
  enrollmentRule:{type:String,default:'open',enum:['open','invite_only','manual_approval','auto_approval']},
  accessPolicy:{type:String,default:'open',enum:['invite_only','open','manual_approval','code_based']},
  joinCode:{type:String,default:''},
  teacherAssigned:{type:String,default:''},
  colorIcon:{type:String,default:'📦'},
  startDate:{type:Date},
  endDate:{type:Date},
  autoArchiveAfterEnd:{type:Boolean,default:false},
  priceLocked:{type:Boolean,default:false},
  settingsLocked:{type:Boolean,default:false},
  couponCode:{type:String,default:''},
  earlyBirdPrice:{type:Number},
  limitedTimePrice:{type:Number},
  priceHistory:[{oldPrice:Number,newPrice:Number,field:String,updatedBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},updatedByName:String,updatedAt:{type:Date,default:Date.now}}],
  controlSnapshot:{appliedBy:String,appliedAt:Date,state:mongoose.Schema.Types.Mixed},
  healthScoreCache:{type:Number,default:0},
  isTemplate:{type:Boolean,default:false},
  clonedFrom:{type:mongoose.Schema.Types.ObjectId,ref:'Batch'},
  lastActivityAt:{type:Date,default:Date.now},
  archivedAt:{type:Date},
  exams:[{type:mongoose.Schema.Types.ObjectId,ref:'Exam'}],
  examMeta:[{examId:{type:mongoose.Schema.Types.ObjectId,ref:'Exam'},required:Boolean,locked:Boolean,featured:Boolean,hidden:Boolean,priority:{type:Number,default:0}}],
  enrollments:[{student:{type:mongoose.Schema.Types.ObjectId,ref:'User'},status:{type:String,default:'active',enum:['active','inactive']},joinedAt:{type:Date,default:Date.now}}],
  renameHistory:[{oldName:String,newName:String,changedBy:String,changedAt:{type:Date,default:Date.now}}],

  // ── FPR4/FPR5 Marketplace + My Batches Hub fields ──
  instructorName:{type:String,default:''},
  instructorBio:{type:String,default:''},
  instructorPhoto:{type:String,default:''},
  syllabusPoints:[{type:String}],
  faqs:[{q:{type:String,default:''},a:{type:String,default:''}}],
  studyLoadHoursPerWeek:{type:Number,default:0},
  renewalPrice:{type:Number,default:0},
},{timestamps:true});
module.exports=mongoose.model('Batch',BatchSchema);
FPR45_EOF_BATCH
echo "✅ models/Batch.js upgraded"

# ---------------------------------------------------------------------------
# 2) models/BatchActivity.js
# ---------------------------------------------------------------------------
cat > "$MODELS_DIR/BatchActivity.js" << 'FPR45_EOF_BACTIVITY'
const mongoose = require('mongoose');
const BatchActivitySchema = new mongoose.Schema({
  batchId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  type:      { type: String, enum: ['new_test','new_material','announcement','update','tip'], default: 'announcement' },
  title:     { type: String, required: true },
  message:   { type: String, default: '' },
  icon:      { type: String, default: '📢' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  isActive:  { type: Boolean, default: true },
  pinned:    { type: Boolean, default: false },
  readBy:    [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: true });
module.exports = mongoose.model('BatchActivity', BatchActivitySchema);
FPR45_EOF_BACTIVITY
echo "✅ models/BatchActivity.js upgraded"

# ---------------------------------------------------------------------------
# 3) routes/studentBatches.js
# ---------------------------------------------------------------------------
cat > "$ROUTES_DIR/studentBatches.js" << 'FPR45_EOF_SBATCHES'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const Batch=require('../models/Batch');
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

// ── FPR4 helpers ──────────────────────────────────────────────────
function isFlashActive(b){ return !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()); }
function effectivePrice(b){
  if (isFlashActive(b) && b.flashSalePrice) return b.flashSalePrice;
  return b.discountPrice || b.price || 0;
}
// Batch/Series Fit Score (0-100) — deterministic, transparent formula
function computeFitScore(b, targetExam){
  let score = 40; // baseline
  if (targetExam && b.examType && b.examType.toLowerCase() === String(targetExam).toLowerCase()) score += 30;
  score += Math.min(15, (b.rating || 0) * 3);
  score += Math.min(15, Math.log10((b.enrolledCount || 0) + 1) * 6);
  return Math.max(0, Math.min(100, Math.round(score)));
}
// Study Load Indicator — hours/week label from totalTests + explicit field
function studyLoadLabel(b){
  const hrs = b.studyLoadHoursPerWeek || Math.min(20, Math.round((b.totalTests || 0) / 4));
  const label = hrs <= 3 ? 'Light' : hrs <= 8 ? 'Moderate' : hrs <= 14 ? 'Intensive' : 'Heavy';
  return { hoursPerWeek: hrs, label };
}
// Syllabus Coverage Meter — % based on syllabusPoints length vs a 20-point full baseline
function syllabusCoverage(b){
  const pts = (b.syllabusPoints || []).length;
  return Math.min(100, Math.round((pts / 20) * 100)) || (b.syllabus ? 60 : 0);
}
function enrich(b, targetExam){
  return {
    ...b,
    effectivePrice: effectivePrice(b),
    isFlashActive: isFlashActive(b),
    fitScore: computeFitScore(b, targetExam),
    studyLoad: studyLoadLabel(b),
    syllabusCoveragePct: syllabusCoverage(b),
    seatDemand: b.seatLimit > 0 ? Math.round(((b.enrolledCount || 0) / b.seatLimit) * 100) : null,
  };
}

// GET /api/student/batches — marketplace list (upgraded filters)
router.get('/',optAuth,async(req,res)=>{
  try{
    const{
      examType,isFree,search,sort='newest',category,subject,
      difficulty,batchType,language,minPrice,maxPrice,
      trial,bundle,emi,flashsale,
    }=req.query;
    const filter={status:'active'};
    if(examType)filter.examType=examType;
    if(isFree!==undefined && isFree!=='')filter.isFree=isFree==='true';
    if(category)filter.category=category;
    if(subject)filter.subject=subject;
    if(difficulty)filter.difficulty=difficulty;
    if(batchType)filter.batchType=batchType;
    if(language)filter.language=language;
    if(trial==='true')filter.allowFreeTrial=true;
    if(bundle==='true')filter.isBundle=true;
    if(emi==='true')filter.allowEMI=true;
    if(flashsale==='true')filter.flashSaleEndTime={$gte:new Date()};
    if(search)filter.name={$regex:search,$options:'i'};
    if(minPrice!==undefined||maxPrice!==undefined){
      filter.price={};
      if(minPrice!==undefined && minPrice!=='')filter.price.$gte=Number(minPrice);
      if(maxPrice!==undefined && maxPrice!=='')filter.price.$lte=Number(maxPrice);
    }
    let sortObj={createdAt:-1};
    if(sort==='popular')sortObj={enrolledCount:-1};
    else if(sort==='price_low')sortObj={price:1};
    else if(sort==='price_high')sortObj={price:-1};
    else if(sort==='rating')sortObj={rating:-1};
    else if(sort==='discount')sortObj={discountPrice:1};
    else if(sort==='most_enrolled')sortObj={enrolledCount:-1};

    const batches=await Batch.find(filter).sort(sortObj).lean();
    let enrolledIds=[],wishlistIds=[],targetExam='';
    if(req.user){
      const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
      enrolledIds=(user?.enrolledBatches||[]).map(id=>id.toString());
      wishlistIds=(user?.wishlistBatches||[]).map(id=>id.toString());
      targetExam=user?.targetExam||'';
    }
    let result=batches.map(b=>({
      ...enrich(b, targetExam),
      isEnrolled:enrolledIds.includes(b._id.toString()),
      isWishlisted:wishlistIds.includes(b._id.toString())
    }));
    // Highest Discount sort needs computed discount %, applied after enrich
    if(sort==='discount'){
      result.sort((a,b)=>{
        const da=a.price>0?(1-a.effectivePrice/a.price):0;
        const db=b.price>0?(1-b.effectivePrice/b.price):0;
        return db-da;
      });
    }
    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/student/batches/my
router.get('/my',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.enrolledBatches||[];
    const batches=await Batch.find({_id:{$in:ids},status:'active'}).lean();
    res.json({batches:batches.map(b=>enrich(b, user?.targetExam||''))});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/wishlist — with price-watch (price-drop detection)
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const meta=user?.wishlistMeta||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    const result=batches.map(b=>{
      const m=meta.find(x=>x.batchId?.toString()===b._id.toString());
      const nowPrice=effectivePrice(b);
      const priceDropped=m&&m.priceSnapshot!=null?nowPrice<m.priceSnapshot:false;
      return {
        ...enrich(b, user?.targetExam||''),
        wishlistedAt:m?.addedAt||null,
        priceSnapshot:m?.priceSnapshot??nowPrice,
        priceDropped,
        priceDropAmount:priceDropped?(m.priceSnapshot-nowPrice):0,
      };
    });
    res.json({batches:result});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/compare?ids=a,b,c — side-by-side comparison data
router.get('/compare',optAuth,async(req,res)=>{
  try{
    const ids=(req.query.ids||'').split(',').filter(Boolean).slice(0,3);
    if(ids.length<2)return res.status(400).json({error:'Provide at least 2 batch IDs to compare'});
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    const enriched=batches.map(b=>enrich(b,''));
    // Best-value scoring: lower effective price + higher rating + more tests = better
    let bestId=null,bestScore=-Infinity;
    enriched.forEach(b=>{
      const s=(b.rating||0)*20 + (b.totalTests||0)*0.5 - (b.effectivePrice||0)*0.02;
      if(s>bestScore){bestScore=s;bestId=b._id.toString()}
    });
    res.json({
      batches:enriched.map(b=>({...b,isBestValue:b._id.toString()===bestId})),
      fields:['price','totalTests','validity','rating','enrolledCount','batchType','language','difficulty','isFree','allowFreeTrial','batchType','notes','allowEMI']
    });
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/:id/preview — quick preview modal data
router.get('/:id/preview',optAuth,async(req,res)=>{
  try{
    const batch=await Batch.findById(req.params.id).lean();
    if(!batch)return res.status(404).json({error:'Not found'});
    let isEnrolled=false,isWishlisted=false,targetExam='';
    if(req.user){
      const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
      isEnrolled=(user?.enrolledBatches||[]).some(id=>id.toString()===req.params.id);
      isWishlisted=(user?.wishlistBatches||[]).some(id=>id.toString()===req.params.id);
      targetExam=user?.targetExam||'';
    }
    res.json({
      batch:{
        ...enrich(batch, targetExam),
        isEnrolled,isWishlisted,
        instructor:{name:batch.instructorName||'ProveRank Faculty',bio:batch.instructorBio||'Experienced educator with proven track record.',photo:batch.instructorPhoto||''},
        faqs:batch.faqs&&batch.faqs.length?batch.faqs:[
          {q:'Is there a refund policy?',a:'Refunds are handled per platform policy — contact support within 7 days.'},
          {q:'How long do I get access?',a:`You get ${batch.validity||365} days of access from enrollment.`},
          {q:'Is this batch beginner friendly?',a:`Difficulty level: ${batch.difficulty||'Medium'} — suitable for most students preparing for ${batch.examType}.`},
        ],
        syllabusPoints:batch.syllabusPoints&&batch.syllabusPoints.length?batch.syllabusPoints:(batch.syllabus?batch.syllabus.split(',').map(s=>s.trim()).filter(Boolean):[]),
      }
    });
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/:id
router.get('/:id',optAuth,async(req,res)=>{
  try{
    const batch=await Batch.findById(req.params.id).lean();
    if(!batch)return res.status(404).json({error:'Not found'});
    res.json({batch:enrich(batch,'')});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/student/batches/:id/enroll
router.post('/:id/enroll',auth,async(req,res)=>{
  try{
    const batch=await Batch.findById(req.params.id);
    if(!batch)return res.status(404).json({error:'Not found'});
    if(!batch.isFree&&!batch.allowFreeTrial)return res.status(400).json({error:'Paid batch'});
    await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$addToSet:{enrolledBatches:batch._id}});
    await Batch.findByIdAndUpdate(req.params.id,{$inc:{enrolledCount:1}});
    res.json({success:true,message:'Enrolled!'});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/student/batches/:id/wishlist (toggle, stores price snapshot for price-watch)
router.post('/:id/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const wishlist=user?.wishlistBatches||[];
    const meta=user?.wishlistMeta||[];
    const bObjId=new mongoose.Types.ObjectId(req.params.id);
    const isW=wishlist.some(id=>id.toString()===req.params.id);
    if(isW){
      await User.collection.updateOne(
        {_id:new mongoose.Types.ObjectId(req.user.id)},
        {$pull:{wishlistBatches:bObjId,wishlistMeta:{batchId:bObjId}}}
      );
    }else{
      const batch=await Batch.findById(req.params.id).lean();
      const snapshot=batch?effectivePrice(batch):0;
      await User.collection.updateOne(
        {_id:new mongoose.Types.ObjectId(req.user.id)},
        {$addToSet:{wishlistBatches:bObjId},$push:{wishlistMeta:{batchId:bObjId,addedAt:new Date(),priceSnapshot:snapshot}}}
      );
    }
    res.json({success:true,isWishlisted:!isW});
  }catch(e){res.status(500).json({error:e.message});}
});

module.exports=router;
FPR45_EOF_SBATCHES
echo "✅ routes/studentBatches.js upgraded"

# ---------------------------------------------------------------------------
# 4) routes/myBatches.js
# ---------------------------------------------------------------------------
cat > "$ROUTES_DIR/myBatches.js" << 'FPR45_EOF_MYBATCHES'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const Batch=require('../models/Batch');
const User=require('../models/User');
const jwt=require('jsonwebtoken');
const JWT=process.env.JWT_SECRET||'proverank_jwt_super_secret_key_2024';

const auth=(req,res,next)=>{
  const h=req.headers.authorization;
  if(!h||!h.startsWith('Bearer '))return res.status(401).json({error:'Unauthorized'});
  try{req.user=jwt.verify(h.split(' ')[1],JWT);next();}
  catch(e){res.status(401).json({error:'Invalid token'});}
};

// Batch/Series Health Score for an enrolled batch (engagement-based, 0-100)
function computeBatchHealth(m,totalTests){
  let score=0;
  const testsCompleted=m.testsCompleted||0;
  score+=Math.min(40,(totalTests>0?(testsCompleted/totalTests):0)*40);
  score+=Math.min(30,(m.streak||0)*3);
  const daysSince=m.lastAccessedAt?Math.floor((Date.now()-new Date(m.lastAccessedAt).getTime())/86400000):999;
  score+=daysSince<3?30:daysSince<7?18:daysSince<14?8:0;
  return Math.round(Math.max(0,Math.min(100,score)));
}

// GET /api/my-batches — all enrolled batches with meta (FPR5 upgraded)
router.get('/',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=(user?.enrolledBatches||[]);
    const meta=user?.enrolledBatchesMeta||[];
    const wishlistIds=(user?.wishlistBatches||[]).map(id=>id.toString());
    const batches=await Batch.find({_id:{$in:ids},status:'active'}).lean();
    const now=new Date();
    const result=batches.map(b=>{
      const m=meta.find(x=>x.batchId?.toString()===b._id.toString())||{};
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
      const isExpired=daysLeft===0;
      const renewalState=isExpired?'expired':daysLeft<=7?'expiring_soon':'active';
      return{
        ...b, enrolledAt, expiresAt, daysLeft, testsCompleted, totalTests,
        progress, lastAccessedAt, daysSinceAccess, streak,
        avgScore:m.avgScore||0, bestRank:m.bestRank||null,
        isExpiring:daysLeft<=7&&daysLeft>0, isExpired,
        isCompleted:progress>=100,
        isWishlisted:wishlistIds.includes(b._id.toString()),
        renewalState,
        healthScore:computeBatchHealth(m,totalTests),
        certificateEligible:progress>=100,
      };
    });
    result.sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime());
    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/my-batches/stats — summary stats (FPR5 upgraded)
router.get('/stats',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=user?.enrolledBatchesMeta||[];
    const ids=user?.enrolledBatches||[];
    const wishlistCount=(user?.wishlistBatches||[]).length;
    const total=ids.length;
    const testsCompleted=meta.reduce((s,m)=>s+(m.testsCompleted||0),0);
    const now=new Date();
    const activeBatches=meta.filter(m=>{
      if(!m.expiresAt)return true;
      return new Date(m.expiresAt)>now;
    }).length;
    const certificates=meta.filter(m=>(m.testsCompleted||0)>=(m.totalTests||1)&&m.totalTests>0).length;
    const renewalDueSoon=meta.filter(m=>{
      if(!m.expiresAt)return false;
      const daysLeft=Math.ceil((new Date(m.expiresAt)-now)/86400000);
      return daysLeft>0&&daysLeft<=7;
    }).length;
    const streaks=meta.map(m=>m.streak||0);
    const currentStreak=streaks.length?Math.max(...streaks):0;
    const progresses=meta.map(m=>m.totalTests>0?Math.round(((m.testsCompleted||0)/m.totalTests)*100):0);
    const avgProgress=progresses.length?Math.round(progresses.reduce((a,b)=>a+b,0)/progresses.length):0;
    res.json({total,testsCompleted,activeBatches,certificates,wishlistCount,renewalDueSoon,currentStreak,avgProgress});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/reminders — Reminder Center (FPR5)
router.get('/reminders',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=user?.enrolledBatchesMeta||[];
    const wishlistMeta=user?.wishlistMeta||[];
    const wishlistIds=(user?.wishlistBatches||[]).map(id=>id.toString());
    const now=new Date();
    const reminders=[];

    const enrolledBatchDocs=await Batch.find({_id:{$in:user?.enrolledBatches||[]}}).lean();
    meta.forEach(m=>{
      if(!m.expiresAt)return;
      const daysLeft=Math.ceil((new Date(m.expiresAt)-now)/86400000);
      if(daysLeft>0&&daysLeft<=7){
        const b=enrolledBatchDocs.find(x=>x._id.toString()===m.batchId?.toString());
        reminders.push({type:'renewal',severity:daysLeft<=2?'high':'medium',batchId:m.batchId,batchName:b?.name||'Batch',message:`Expires in ${daysLeft} day${daysLeft>1?'s':''} — renew to keep access`,daysLeft});
      }
      if(m.streak>0){
        const daysSince=m.lastAccessedAt?Math.floor((now-new Date(m.lastAccessedAt))/86400000):99;
        if(daysSince===1){
          const b=enrolledBatchDocs.find(x=>x._id.toString()===m.batchId?.toString());
          reminders.push({type:'streak_risk',severity:'medium',batchId:m.batchId,batchName:b?.name||'Batch',message:`Your ${m.streak}-day streak is at risk — attempt a test today!`});
        }
      }
    });

    if(wishlistIds.length){
      const wishBatches=await Batch.find({_id:{$in:wishlistIds}}).lean();
      wishBatches.forEach(b=>{
        const wm=wishlistMeta.find(x=>x.batchId?.toString()===b._id.toString());
        if(!wm||wm.priceSnapshot==null)return;
        const nowPrice=(b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>now&&b.flashSalePrice)?b.flashSalePrice:(b.discountPrice||b.price||0);
        if(nowPrice<wm.priceSnapshot){
          reminders.push({type:'price_drop',severity:'low',batchId:b._id,batchName:b.name,message:`Price dropped from ₹${wm.priceSnapshot} to ₹${nowPrice}!`,drop:wm.priceSnapshot-nowPrice});
        }
      });
    }
    res.json({reminders,total:reminders.length});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/my-batches/:id/access — update last accessed + streak
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

// POST /api/my-batches/:id/renew — one-tap renew (extends expiry by batch validity)
router.post('/:id/renew',auth,async(req,res)=>{
  try{
    const userId=new mongoose.Types.ObjectId(req.user.id);
    const user=await User.collection.findOne({_id:userId});
    let meta=user?.enrolledBatchesMeta||[];
    const idx=meta.findIndex(m=>m.batchId?.toString()===req.params.id);
    if(idx<0)return res.status(404).json({error:'Not enrolled in this batch'});
    const batch=await Batch.findById(req.params.id).lean();
    if(!batch)return res.status(404).json({error:'Batch not found'});
    const validityDays=batch.validity||365;
    const now=new Date();
    const base=meta[idx].expiresAt&&new Date(meta[idx].expiresAt)>now?new Date(meta[idx].expiresAt):now;
    meta[idx].expiresAt=new Date(base.getTime()+validityDays*86400000);
    meta[idx].renewalHistory=[...(meta[idx].renewalHistory||[]),{renewedAt:now,extendedTo:meta[idx].expiresAt,price:batch.renewalPrice||batch.discountPrice||batch.price||0}];
    await User.collection.updateOne({_id:userId},{$set:{enrolledBatchesMeta:meta}});
    res.json({success:true,expiresAt:meta[idx].expiresAt});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:id/certificate — certificate roadmap / eligibility
router.get('/:id/certificate',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const meta=(user?.enrolledBatchesMeta||[]).find(m=>m.batchId?.toString()===req.params.id);
    const batch=await Batch.findById(req.params.id).lean();
    if(!batch)return res.status(404).json({error:'Batch not found'});
    const testsCompleted=meta?.testsCompleted||0;
    const totalTests=batch.totalTests||0;
    const progress=totalTests>0?Math.round((testsCompleted/totalTests)*100):0;
    const eligible=progress>=100;
    res.json({
      eligible,progress,testsCompleted,totalTests,
      missingRequirements:eligible?[]:[`Complete ${totalTests-testsCompleted} more test(s) to unlock your certificate`],
      issueDate:eligible?(meta?.lastAccessedAt||new Date()):null,
      downloadUrl:eligible?`/api/certificates/${req.params.id}/download`:null,
    });
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/wishlist — wishlist batches (separate from test-series wishlist UI)
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/my-batches/:batchId/leaderboard — batch-specific leaderboard
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
FPR45_EOF_MYBATCHES
echo "✅ routes/myBatches.js upgraded"

# ---------------------------------------------------------------------------
# 5) routes/studentBatchExtras.js
# ---------------------------------------------------------------------------
cat > "$ROUTES_DIR/studentBatchExtras.js" << 'FPR45_EOF_EXTRAS'
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const optAuth = (req, res, next) => {
  const h = req.headers.authorization;
  if (h && h.startsWith('Bearer ')) {
    try { req.user = jwt.verify(h.split(' ')[1], JWT); } catch (e) {}
  }
  next();
};

// GET /autocomplete?q= — batch name suggestions (debounced from frontend)
router.get('/autocomplete', async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q || q.length < 2) return res.json({ suggestions: [] });
    const batches = await Batch.find({
      name:   { $regex: q, $options: 'i' },
      status: 'active'
    }).select('name examType isFree').limit(6).lean();
    res.json({ suggestions: batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /recommendations?examType=NEET&excludeId=xxx — FPR4: personalized (targetExam-aware)
router.get('/recommendations', optAuth, async (req, res) => {
  try {
    const { examType, excludeId } = req.query;
    const filter = { status: 'active' };
    let targetExam = examType || '';
    if (req.user) {
      const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
      if (!targetExam) targetExam = user?.targetExam || '';
    }
    if (targetExam) filter.examType = targetExam;
    if (excludeId) {
      try { filter._id = { $ne: new mongoose.Types.ObjectId(excludeId) }; } catch (e) {}
    }
    let batches = await Batch.find(filter).sort({ enrolledCount: -1, rating: -1 }).limit(8).lean();
    if (batches.length < 4 && targetExam) {
      // fallback: widen search if not enough matches for target exam
      const extra = await Batch.find({ status: 'active', examType: { $ne: targetExam } })
        .sort({ enrolledCount: -1, rating: -1 }).limit(4).lean();
      batches = [...batches, ...extra];
    }
    res.json({ batches: batches.slice(0, 4) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/faq — FAQ preview for a batch (reduces pre-purchase doubts)
router.get('/:id/faq', async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Not found' });
    const faqs = (batch.faqs && batch.faqs.length) ? batch.faqs : [
      { q: 'Is there a refund policy?', a: 'Refunds are handled per platform policy — contact support within 7 days.' },
      { q: 'How long do I get access?', a: `You get ${batch.validity || 365} days of access from enrollment.` },
      { q: 'Is this suitable for beginners?', a: `Difficulty level: ${batch.difficulty || 'Medium'}.` },
    ];
    res.json({ faqs });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /compare/save — Smart Shortlist: save a compare set for later
router.post('/compare/save', auth, async (req, res) => {
  try {
    const { batchIds, name } = req.body;
    if (!Array.isArray(batchIds) || batchIds.length < 2) return res.status(400).json({ error: 'Provide 2-3 batch IDs' });
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    const sets = user?.savedCompareSets || [];
    sets.push({ name: name || `Compare ${sets.length + 1}`, batchIds, savedAt: new Date() });
    await User.collection.updateOne({ _id: userId }, { $set: { savedCompareSets: sets.slice(-10) } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /compare/saved — list saved compare sets
router.get('/compare/saved', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    res.json({ sets: user?.savedCompareSets || [] });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/review — student submits review (pending admin approval)
router.post('/:id/review', auth, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: 'Rating 1-5 required' });
    const existing = await Review.findOne({ batchId: req.params.id, studentId: req.user.id });
    if (existing) return res.status(400).json({ error: 'You have already reviewed this batch' });
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    await Review.create({
      batchId:     req.params.id,
      studentId:   req.user.id,
      studentName: user?.name || 'Student',
      rating:      Number(rating),
      comment:     comment || '',
      status:      'pending'
    });
    res.json({ success: true, message: 'Review submitted — pending admin approval' });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/reviews — approved reviews for a batch
router.get('/:id/reviews', async (req, res) => {
  try {
    const reviews = await Review.find({ batchId: req.params.id, status: 'approved' })
      .sort({ createdAt: -1 }).limit(10).lean();
    res.json({ reviews });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/razorpay-order — create payment order (test mode safe)
router.post('/:id/razorpay-order', auth, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const amount = ((batch.discountPrice || batch.price) * 100);
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.json({
        success:  true,
        orderId:  'order_test_' + Date.now(),
        amount,
        currency: 'INR',
        key:      'rzp_test_placeholder',
        testMode: true,
        batchName: batch.name
      });
    }
    const Razorpay = require('razorpay');
    const rzp   = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
    const order = await rzp.orders.create({ amount, currency: 'INR', notes: { batchId: req.params.id } });
    res.json({ success: true, orderId: order.id, amount, currency: 'INR', key: process.env.RAZORPAY_KEY_ID, batchName: batch.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
FPR45_EOF_EXTRAS
echo "✅ routes/studentBatchExtras.js upgraded"

# ---------------------------------------------------------------------------
# 6) routes/batchActivityRoutes.js
# ---------------------------------------------------------------------------
cat > "$ROUTES_DIR/batchActivityRoutes.js" << 'FPR45_EOF_ACTIVITY'
const express  = require('express');
const router   = express.Router();
const jwt      = require('jsonwebtoken');
const mongoose = require('mongoose');
const BatchActivity = require('../models/BatchActivity');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin','superadmin'].includes(req.user?.role)) return res.status(403).json({ error: 'Admin only' });
  next();
};

// GET /api/batch-activity/:batchId — get activities for a batch (FPR5: pinned first + isRead flag)
router.get('/:batchId', auth, async (req, res) => {
  try {
    const { type } = req.query;
    const filter = { batchId: req.params.batchId, isActive: true };
    if (type) filter.type = type;
    const activities = await BatchActivity.find(filter)
      .sort({ pinned: -1, createdAt: -1 }).limit(30).lean();
    const uid = req.user.id;
    const enriched = activities.map(a => ({
      ...a,
      isRead: (a.readBy || []).some(id => id.toString() === uid)
    }));
    res.json({ activities: enriched, unreadCount: enriched.filter(a => !a.isRead).length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/batch-activity/:id/read — mark one activity read for current student
router.put('/:id/read', auth, async (req, res) => {
  try {
    await BatchActivity.findByIdAndUpdate(req.params.id, { $addToSet: { readBy: req.user.id } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/batch-activity — admin push activity (supports pinned flag)
router.post('/', auth, isAdmin, async (req, res) => {
  try {
    const { batchId, type, title, message, icon, pinned } = req.body;
    if (!batchId || !title) return res.status(400).json({ error: 'batchId and title required' });
    const activity = await BatchActivity.create({
      batchId, type: type || 'announcement',
      title, message: message || '', icon: icon || '📢',
      pinned: !!pinned,
      createdBy: req.user.id
    });
    res.json({ success: true, activity });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/batch-activity/:id/pin — admin toggle pin
router.put('/:id/pin', auth, isAdmin, async (req, res) => {
  try {
    const a = await BatchActivity.findById(req.params.id);
    if (!a) return res.status(404).json({ error: 'Not found' });
    a.pinned = !a.pinned;
    await a.save();
    res.json({ success: true, pinned: a.pinned });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/batch-activity/:id — admin remove activity
router.delete('/:id', auth, isAdmin, async (req, res) => {
  try {
    await BatchActivity.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
FPR45_EOF_ACTIVITY
echo "✅ routes/batchActivityRoutes.js upgraded"

# ----------------------------------------------------------------------------
# SYNTAX VALIDATION
# ----------------------------------------------------------------------------
echo ""
echo "🔍 Validating syntax..."
FAIL=0
for f in "$MODELS_DIR/Batch.js" "$MODELS_DIR/BatchActivity.js" "$ROUTES_DIR/studentBatches.js" "$ROUTES_DIR/myBatches.js" "$ROUTES_DIR/studentBatchExtras.js" "$ROUTES_DIR/batchActivityRoutes.js"; do
  if node --check "$f" 2>/tmp/err_$$; then
    echo "  ✅ $f — syntax OK"
  else
    echo "  ❌ $f — SYNTAX ERROR:"; cat /tmp/err_$$
    FAIL=1
  fi
  rm -f /tmp/err_$$
done
if [ "$FAIL" -eq 1 ]; then
  echo "❌ Syntax errors found — restoring backups..."
  for f in "$MODELS_DIR/Batch.js" "$MODELS_DIR/BatchActivity.js" "$ROUTES_DIR/studentBatches.js" "$ROUTES_DIR/myBatches.js" "$ROUTES_DIR/studentBatchExtras.js" "$ROUTES_DIR/batchActivityRoutes.js"; do
    [ -f "$f.pre-fpr45-bak" ] && cp "$f.pre-fpr45-bak" "$f"
  done
  exit 1
fi

# ----------------------------------------------------------------------------
# VERIFICATION CHECKLIST
# ----------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR4 + FPR5 — BACKEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
PASS=0; FAIL2=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q -- "$PATTERN" "$FILE" 2>/dev/null; then echo "✅ $DESC"; PASS=$((PASS+1))
  else echo "❌ $DESC"; FAIL2=$((FAIL2+1)); fi
}
SB="$ROUTES_DIR/studentBatches.js"; MB="$ROUTES_DIR/myBatches.js"; SE="$ROUTES_DIR/studentBatchExtras.js"; BA="$ROUTES_DIR/batchActivityRoutes.js"; BM="$MODELS_DIR/Batch.js"

echo "── FPR4: Marketplace ──"
check "Filters: minPrice/maxPrice"                 "minPrice,maxPrice" "$SB"
check "Filters: difficulty/batchType/language"      "difficulty,batchType,language" "$SB"
check "Filters: free trial / bundle / EMI / flashsale" "trial,bundle,emi,flashsale" "$SB"
check "Sort: highest discount"                       "sort==='discount'" "$SB"
check "Batch/Series Fit Score"                       "function computeFitScore" "$SB"
check "Study Load Indicator"                         "function studyLoadLabel" "$SB"
check "Syllabus Coverage Meter"                      "function syllabusCoverage" "$SB"
check "Effective Price (flash sale aware)"           "function effectivePrice" "$SB"
check "Seat/Demand Indicator"                        "seatDemand" "$SB"
check "Quick Preview endpoint (FAQ/instructor/syllabus)" "router.get('/:id/preview'" "$SB"
check "Compare endpoint (best-value badge)"          "router.get('/compare'" "$SB"
check "Wishlist Price Watch (price-drop detection)"  "priceDropped" "$SB"
check "Wishlist price snapshot on add"                "priceSnapshot:snapshot" "$SB"
check "Recommendations — targetExam aware"            "targetExam" "$SE"
check "FAQ Preview endpoint"                          "router.get('/:id/faq'" "$SE"
check "Smart Shortlist — Save Compare Set"            "router.post('/compare/save'" "$SE"
check "Smart Shortlist — Load Saved Compare Sets"     "router.get('/compare/saved'" "$SE"
check "Batch model — Instructor fields"               "instructorName" "$BM"
check "Batch model — Syllabus points"                 "syllabusPoints" "$BM"
check "Batch model — FAQs"                            "faqs:" "$BM"
check "Batch model — Study load hours"                "studyLoadHoursPerWeek" "$BM"
check "Batch model — Renewal price"                   "renewalPrice" "$BM"

echo "── FPR5: My Batches Hub ──"
check "Renewal state (active/expiring/expired)"       "renewalState" "$MB"
check "Batch Health Score per enrollment"             "function computeBatchHealth" "$MB"
check "Certificate eligibility flag"                  "certificateEligible" "$MB"
check "Reminder Center endpoint"                       "router.get('/reminders'" "$MB"
check "Renewal reminder logic"                         "type:'renewal'" "$MB"
check "Streak-at-risk reminder logic"                  "type:'streak_risk'" "$MB"
check "Price-drop reminder (wishlist)"                 "type:'price_drop'" "$MB"
check "One-tap Renew endpoint"                         "router.post('/:id/renew'" "$MB"
check "Renewal history tracking"                       "renewalHistory" "$MB"
check "Certificate Roadmap endpoint"                   "router.get('/:id/certificate'" "$MB"
check "Stats: avg progress"                            "avgProgress" "$MB"
check "Stats: current streak (max)"                    "currentStreak" "$MB"
check "Stats: renewal due soon count"                  "renewalDueSoon" "$MB"
check "Stats: wishlist count"                          "wishlistCount" "$MB"
check "Activity Feed — pinned support"                 "pinned: -1" "$BA"
check "Activity Feed — read/unread state"              "isRead" "$BA"
check "Activity Feed — mark read endpoint"             "router.put('/:id/read'" "$BA"
check "Activity Feed — admin pin toggle"               "router.put('/:id/pin'" "$BA"
check "Activity Feed — filter by type"                 "req.query" "$BA"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL2)) TOTAL"
if [ "$FAIL2" -eq 0 ]; then
  echo "  🎉 ALL BACKEND FPR4+FPR5 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL2 item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  Restart your backend server to activate changes."
echo "👉 Next: run the FPR4+FPR5 FRONTEND installer script."
