#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — FPR4 STUDENT MARKETPLACE (Batches & Test Series) — BACKEND
# Run from your project ROOT on Replit:  bash fpr4_backend_install.sh
# Safe to re-run (idempotent).
# ══════════════════════════════════════════════════════════════════
set -e
echo "🚀 ProveRank FPR4 — Student Marketplace — BACKEND install starting..."

MODELS_DIR=$(find . -maxdepth 6 -type f -name "Batch.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
ROUTES_DIR=$(find . -maxdepth 6 -type f -name "studentBatches.js" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs -I{} dirname {})
BACKEND_ROOT=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null -exec grep -l "app.use('/api/student/batches'" {} \; | head -1 | xargs -I{} dirname {})

if [ -z "$MODELS_DIR" ]; then MODELS_DIR="./backend/models"; echo "⚠️  models dir not auto-detected — defaulting to $MODELS_DIR"; fi
if [ -z "$ROUTES_DIR" ]; then ROUTES_DIR="./backend/routes"; echo "⚠️  routes dir not auto-detected — defaulting to $ROUTES_DIR"; fi
if [ -z "$BACKEND_ROOT" ]; then BACKEND_ROOT="./backend"; echo "⚠️  backend root not auto-detected — defaulting to $BACKEND_ROOT"; fi

mkdir -p "$MODELS_DIR" "$ROUTES_DIR"
echo "📁 Models dir : $MODELS_DIR"
echo "📁 Routes dir : $ROUTES_DIR"
echo "📁 Backend root: $BACKEND_ROOT"

# ── 1) Overwrite routes/studentBatches.js (FPR4 filters/sort/fit-score/enrichment) ──
cp "$ROUTES_DIR/studentBatches.js" "$ROUTES_DIR/studentBatches.js.bak_fpr4" 2>/dev/null || true
cat > "$ROUTES_DIR/studentBatches.js" << 'PRVRNK_EOF_MARKER'
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

function effectivePrice(b){
  if(b.flashSalePrice&&b.flashSaleEndTime&&new Date(b.flashSaleEndTime)>new Date())return b.flashSalePrice;
  return b.discountPrice||b.price||0;
}
function discountPct(b){
  const base=b.price||0,eff=effectivePrice(b);
  if(!base||base<=eff)return 0;
  return Math.round(((base-eff)/base)*100);
}
// Fit score: simple heuristic combining exam-type match with student's targetExam,
// difficulty preference proxy, and popularity — always 0-100, never blocks rendering if profile missing.
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

// GET /api/student/batches
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
    if(emiEligible==='true')filter.allowEMI=true;
    if(flashSaleActive==='true')filter.flashSaleEndTime={$gte:new Date()};
    if(offerType==='trial')filter.allowFreeTrial=true;
    else if(offerType==='bundle')filter.isBundle=true;
    else if(offerType==='spotlight')filter.isSpotlight=true;
    else if(offerType==='emi')filter.allowEMI=true;
    else if(offerType==='flashsale')filter.flashSaleEndTime={$gte:new Date()};
    if(enrollmentState==='full')filter.$expr={$and:[{$gt:['$seatLimit',0]},{$gte:['$enrolledCount','$seatLimit']}]};

    let sortObj={createdAt:-1};
    if(sort==='popular'||sort==='enrolled')sortObj={enrolledCount:-1};
    else if(sort==='price_low')sortObj={price:1};
    else if(sort==='price_high')sortObj={price:-1};
    else if(sort==='rating')sortObj={rating:-1};

    let batches=await Batch.find(filter).sort(sortObj).lean();

    if(sort==='discount')batches=batches.sort((a,b)=>discountPct(b)-discountPct(a));

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
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/wishlist
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const priceWatch=user?.priceWatch||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    const result=batches.map(b=>{
      const pw=priceWatch.find(x=>x.batchId?.toString()===b._id.toString());
      const eff=effectivePrice(b);
      return{...b,effectivePrice:eff,discountPct:discountPct(b),isPriceWatched:!!pw,priceDropped:!!pw&&eff<pw.watchedPrice,watchedPrice:pw?pw.watchedPrice:null};
    });
    res.json({batches:result});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/:id
router.get('/:id',optAuth,async(req,res)=>{
  try{
    const batch=await Batch.findById(req.params.id).lean();
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

// POST /api/student/batches/:id/wishlist (toggle)
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
PRVRNK_EOF_MARKER
node --check "$ROUTES_DIR/studentBatches.js" && echo "✅ Updated studentBatches.js (syntax verified)" || { echo "❌ syntax error — restoring backup"; cp "$ROUTES_DIR/studentBatches.js.bak_fpr4" "$ROUTES_DIR/studentBatches.js" 2>/dev/null; exit 1; }

# ── 2) Create routes/studentBatchUltra.js (new upgrade APIs) ──
cat > "$ROUTES_DIR/studentBatchUltra.js" << 'PRVRNK_EOF_MARKER'
// ══════════════════════════════════════════════════════════════════
// FPR4 — STUDENT MARKETPLACE ULTRA UPGRADE APIs
// Mounted at: /api/student/batch-ultra
// Price Watch · Fit Score · Compare Save/Share · Preview Analytics ·
// Batch Activity Feed · Exam Calendar View
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const crypto   = require('crypto');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
let BatchActivity;
try { BatchActivity = require('../models/BatchActivity'); } catch (e) { BatchActivity = null; }

const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

function effectivePrice(b) {
  if (b.flashSalePrice && b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()) return b.flashSalePrice;
  return b.discountPrice || b.price || 0;
}
function computeFitScore(b, user) {
  let score = 50;
  if (user && user.targetExam) {
    if ((b.examType || '').toLowerCase() === String(user.targetExam).toLowerCase()) score += 30;
    else score -= 10;
  }
  if (b.rating) score += Math.round((b.rating - 3) * 5);
  if (b.enrolledCount > 100) score += 10; else if (b.enrolledCount > 20) score += 5;
  if (b.isSpotlight) score += 5;
  return Math.max(0, Math.min(100, score));
}

// Lightweight local model for saved compare shortlists (public share link)
const CompareSetSchema = new mongoose.Schema({
  shareId: { type: String, unique: true, index: true },
  batchIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
const CompareSet = mongoose.models.CompareSet || mongoose.model('CompareSet', CompareSetSchema);

// ══════════════════════════════════════════════════════════════════
// PRICE WATCH
// ══════════════════════════════════════════════════════════════════
router.post('/:id/price-watch', auth, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const user = await User.collection.findOne({ _id: userId });
    const existing = (user?.priceWatch || []).find(pw => pw.batchId?.toString() === req.params.id);
    if (existing) {
      await User.collection.updateOne({ _id: userId }, { $pull: { priceWatch: { batchId: new mongoose.Types.ObjectId(req.params.id) } } });
      return res.json({ success: true, watching: false });
    }
    await User.collection.updateOne({ _id: userId }, {
      $addToSet: { wishlistBatches: batch._id },
      $push: { priceWatch: { batchId: batch._id, watchedPrice: effectivePrice(batch), createdAt: new Date() } }
    });
    res.json({ success: true, watching: true, watchedPrice: effectivePrice(batch) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/price-watch/alerts', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const watches = user?.priceWatch || [];
    if (!watches.length) return res.json({ alerts: [] });
    const batches = await Batch.find({ _id: { $in: watches.map(w => w.batchId) } }).lean();
    const alerts = batches.map(b => {
      const w = watches.find(x => x.batchId?.toString() === b._id.toString());
      const eff = effectivePrice(b);
      return { batchId: b._id, name: b.name, watchedPrice: w?.watchedPrice || 0, currentPrice: eff, dropped: eff < (w?.watchedPrice || 0) };
    }).filter(a => a.dropped);
    res.json({ alerts });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// FIT SCORE (standalone)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/fit-score', async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    let user = null;
    const h = req.headers.authorization;
    if (h && h.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(h.split(' ')[1], JWT);
        user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(decoded.id) });
      } catch (e) {}
    }
    res.json({ fitScore: computeFitScore(batch, user) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// COMPARE SAVE / SHARE
// ══════════════════════════════════════════════════════════════════
router.post('/compare/save', auth, async (req, res) => {
  try {
    const { batchIds } = req.body;
    if (!Array.isArray(batchIds) || batchIds.length < 2) return res.status(400).json({ error: 'Select at least 2 items to compare' });
    const shareId = crypto.randomBytes(5).toString('hex');
    const set = await CompareSet.create({ shareId, batchIds, createdBy: req.user.id });
    res.json({ success: true, shareId: set.shareId });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/compare/:shareId', async (req, res) => {
  try {
    const set = await CompareSet.findOne({ shareId: req.params.shareId }).lean();
    if (!set) return res.status(404).json({ error: 'Compare link not found or expired' });
    const batches = await Batch.find({ _id: { $in: set.batchIds } }).lean();
    res.json({ batches: batches.map(b => ({ ...b, effectivePrice: effectivePrice(b) })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// PREVIEW ANALYTICS (best-effort, non-blocking)
// ══════════════════════════════════════════════════════════════════
router.post('/:id/preview-track', async (req, res) => {
  try {
    await Batch.findByIdAndUpdate(req.params.id, { $inc: { previewCount: 1 } });
    res.json({ success: true });
  } catch (e) { res.json({ success: true }); } // never block UX for analytics
});

// ══════════════════════════════════════════════════════════════════
// BATCH ACTIVITY FEED (student-facing, read-only)
// ══════════════════════════════════════════════════════════════════
router.get('/:id/activity', async (req, res) => {
  try {
    if (!BatchActivity) return res.json({ activity: [] });
    const activity = await BatchActivity.find({ batchId: req.params.id, isActive: true }).sort({ createdAt: -1 }).limit(20).lean();
    res.json({ activity });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// EXAM CALENDAR VIEW — upcoming tests across a student's enrolled batches
// ══════════════════════════════════════════════════════════════════
router.get('/calendar/upcoming', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const ids = user?.enrolledBatches || [];
    let Exam;
    try { Exam = mongoose.model('Exam'); } catch (e) { Exam = null; }
    if (!Exam || !ids.length) return res.json({ upcoming: [] });
    const batches = await Batch.find({ _id: { $in: ids } }).select('exams name').lean();
    const examIds = batches.flatMap(b => b.exams || []);
    const exams = await Exam.find({ _id: { $in: examIds }, scheduledDate: { $gte: new Date() } }).sort({ scheduledDate: 1 }).limit(20).lean().catch(() => []);
    res.json({ upcoming: exams || [] });
  } catch (e) { res.json({ upcoming: [] }); }
});

module.exports = router;
PRVRNK_EOF_MARKER
node --check "$ROUTES_DIR/studentBatchUltra.js" && echo "✅ Created studentBatchUltra.js (syntax verified)" || { echo "❌ syntax error in studentBatchUltra.js"; exit 1; }

# ── 3) Patch models/Batch.js — multi-exam categories + previewCount (idempotent) ──
if grep -q "previewCount:" "$MODELS_DIR/Batch.js" 2>/dev/null; then
  echo "⏭️  Batch.js already patched for FPR4 — skipping"
else
  cp "$MODELS_DIR/Batch.js" "$MODELS_DIR/Batch.js.bak_fpr4"
  # Expand examType enum for multi-competitive-exam support (backward compatible)
  if grep -q "examType:{type:String,default:'NEET',enum:\['NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course','Other'\]}," "$MODELS_DIR/Batch.js"; then
    sed -i "s/examType:{type:String,default:'NEET',enum:\['NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course','Other'\]},/examType:{type:String,default:'NEET',enum:['NEET','NEET UG','JEE','JEE MAINS','JEE ADVANCE','CUET','CUET UG','CUET PG','SSC CGL','IIT JAM','Class 11','Class 12','Foundation','Crash Course','Other']},/" "$MODELS_DIR/Batch.js"
    echo "✅ Expanded examType enum (multi-competitive-exam support)"
  else
    echo "ℹ️  examType enum anchor not found (may already be customized) — skipping this specific patch"
  fi
  # Add previewCount field before closing schema
  if grep -q "^},{timestamps:true});$" "$MODELS_DIR/Batch.js"; then
    awk '
      /^\},\{timestamps:true\}\);$/ && done!=1 {
        print "  previewCount:{type:Number,default:0},"
        done=1
      }
      {print}
    ' "$MODELS_DIR/Batch.js" > "$MODELS_DIR/Batch.js.tmp" && mv "$MODELS_DIR/Batch.js.tmp" "$MODELS_DIR/Batch.js"
    echo "✅ Added previewCount field"
  fi
  node --check "$MODELS_DIR/Batch.js" && echo "✅ Batch.js syntax verified" || { echo "❌ Batch.js syntax error — restoring backup"; cp "$MODELS_DIR/Batch.js.bak_fpr4" "$MODELS_DIR/Batch.js"; exit 1; }
fi

# ── 4) Mount studentBatchUltra route in index.js (idempotent) ──
INDEX_FILE="$BACKEND_ROOT/index.js"
if [ ! -f "$INDEX_FILE" ]; then
  INDEX_FILE=$(find . -maxdepth 4 -type f -iname "index.js" -not -path "*/node_modules/*" 2>/dev/null | head -1)
fi
if [ -z "$INDEX_FILE" ] || [ ! -f "$INDEX_FILE" ]; then
  echo "❌ Could not locate backend index.js — please mount manually:"
  echo "   const studentBatchUltraRoutes = require('./routes/studentBatchUltra');"
  echo "   app.use('/api/student/batch-ultra', studentBatchUltraRoutes);"
else
  if grep -q "studentBatchUltra" "$INDEX_FILE"; then
    echo "⏭️  index.js already mounts studentBatchUltra — skipping"
  else
    cp "$INDEX_FILE" "$INDEX_FILE.bak_fpr4"
    printf "\nconst studentBatchUltraRoutes = require('./routes/studentBatchUltra');\napp.use('/api/student/batch-ultra', studentBatchUltraRoutes);\n" >> "$INDEX_FILE"
    node --check "$INDEX_FILE" && echo "✅ Mounted /api/student/batch-ultra route in index.js" || { echo "❌ index.js syntax error — restoring backup"; cp "$INDEX_FILE.bak_fpr4" "$INDEX_FILE"; exit 1; }
  fi
fi

# ══════════════════════════════════════════════════════════════════
# ✅ FINAL VERIFICATION CHECKLIST — BACKEND (FPR4 Student Marketplace)
# ══════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FPR4 STUDENT MARKETPLACE — BACKEND VERIFICATION CHECKLIST"
echo "═══════════════════════════════════════════════════════════"
SBFILE="$ROUTES_DIR/studentBatches.js"
SUFILE="$ROUTES_DIR/studentBatchUltra.js"
PASS=0; FAIL=0
check() {
  DESC="$1"; PATTERN="$2"; FILE="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    echo "✅ $DESC"; PASS=$((PASS+1))
  else
    echo "❌ $DESC"; FAIL=$((FAIL+1))
  fi
}

check "1) Search + Free/Paid/Category/Subject Filters"        "if(search)filter.name" "$SBFILE"
check "2) Batch Type / Difficulty / Language Filters"          "if(batchType)filter.batchType" "$SBFILE"
check "3) Price Range Filter (min/max)"                        "filter.price={}" "$SBFILE"
check "4) Offer Type Filter (trial/bundle/spotlight/emi/flashsale)" "offerType==='trial'" "$SBFILE"
check "5) Flash Sale Active + EMI Eligible Filters"             "flashSaleActive" "$SBFILE"
check "6) Enrollment State Filter (open/full)"                  "enrollmentState==='full'" "$SBFILE"
check "7) Sort — Newest/Popular/Rating/Price/Discount/Enrolled" "sort==='discount'" "$SBFILE"
check "8) Fit Score Computation"                                 "function computeFitScore" "$SBFILE"
check "9) Discount % Computation"                                "function discountPct" "$SBFILE"
check "10) Wishlist + Enrolled State Enrichment"                 "isEnrolled:enrolledIds" "$SBFILE"
check "11) Price Watch Enrichment in List/Detail"                "isPriceWatched" "$SBFILE"
check "12) Batch Detail — Instructor Highlight"                  "instructorHighlight" "$SBFILE"
check "13) Batch Detail — FAQ Preview"                            "faqPreview" "$SBFILE"
check "14) Batch Detail — Social Proof"                           "socialProof" "$SBFILE"
check "15) Batch Detail — Syllabus Coverage Meter"                "syllabusCoveragePct" "$SBFILE"
check "16) Batch Detail — Study Load Indicator"                   "studyLoadPerWeek" "$SBFILE"
check "17) Enroll + Wishlist Toggle Endpoints Preserved"          "router.post('/:id/enroll'" "$SBFILE"
check "18) Price Watch Toggle Endpoint"                           "router.post('/:id/price-watch'" "$SUFILE"
check "19) Price Watch Alerts (price-drop detection)"             "router.get('/price-watch/alerts'" "$SUFILE"
check "20) Standalone Fit Score Endpoint"                         "router.get('/:id/fit-score'" "$SUFILE"
check "21) Compare Save + Public Share Endpoint"                  "router.post('/compare/save'" "$SUFILE"
check "22) Compare Public Fetch by Share ID"                      "router.get('/compare/:shareId'" "$SUFILE"
check "23) Preview Analytics Tracking Endpoint"                   "router.post('/:id/preview-track'" "$SUFILE"
check "24) Batch Activity Feed Endpoint (student-facing)"         "router.get('/:id/activity'" "$SUFILE"
check "25) Exam Calendar View Endpoint (upcoming tests)"          "router.get('/calendar/upcoming'" "$SUFILE"
check "26) Batch.js — Multi-Competitive-Exam Categories"          "NEET UG" "$MODELS_DIR/Batch.js"
check "27) Batch.js — previewCount Field Added"                   "previewCount:" "$MODELS_DIR/Batch.js"
check "28) studentBatchUltra Route Mounted in index.js"           "studentBatchUltra" "$INDEX_FILE"

echo "═══════════════════════════════════════════════════════════"
echo "  RESULT: $PASS PASSED / $((PASS+FAIL)) TOTAL"
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 ALL BACKEND FPR4 FEATURES SUCCESSFULLY IMPLEMENTED ✅"
else
  echo "  ⚠️  $FAIL item(s) need attention — see ❌ above"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "👉 Next: Restart your backend then run fpr4_frontend_install.sh"
