#!/bin/bash
# ProveRank — URGENT HOTFIX: Restore the Test Series marketplace/payment API
# that Pass 1 accidentally deleted. studentBatches.js, studentBatchExtras.js,
# and studentBatchUltra.js were NOT Batch-only — they served the LIVE
# /dashboard/test-series page (browse, enroll, wishlist, reviews, Razorpay
# payment + receipts, price-watch, fit-score, compare). This restores them,
# fully stripped of Batch logic, keeping the exact same endpoint paths so
# the frontend needs ZERO changes.
set -e
cd ~/workspace

echo "═══════════════════════════════════════════"
echo "STEP 0 — Backup current index.js"
echo "═══════════════════════════════════════════"
mkdir -p ~/workspace/.pre_batch_removal_backup
ts=$(date +%Y%m%d_%H%M%S)
cp src/index.js ~/workspace/.pre_batch_removal_backup/index_before_urgent_hotfix_$ts.js
echo "Backup saved."

echo "═══════════════════════════════════════════"
echo "STEP 1 — Write restored route files"
echo "═══════════════════════════════════════════"

cat > src/routes/studentBatches.js << 'FILEEOF'
const express=require('express');
const router=express.Router();
const mongoose=require('mongoose');
const TestSeries=require('../models/TestSeries');
const Banner=require('../models/Banner');
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

// normalize a TestSeries doc for the marketplace UI (field-name mapping only)
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
// Marketplace-only filter (adds isPublished check) — NOT used for /my so already-enrolled
// students keep access to their series even if it's later unpublished from marketplace.
function marketplaceSeriesFilter(){
  return{ ...baseSeriesFilter(), isPublished:{$ne:false} };
}

// GET /api/student/batches  (Test Series marketplace listing)
router.get('/',optAuth,async(req,res)=>{
  try{
    const{
      examType,isFree,search,sort='newest',category,subject,
      batchType,difficulty,language,minPrice,maxPrice,
      offerType,flashSaleActive,emiEligible,enrollmentState
    }=req.query;

    const seriesFilter=marketplaceSeriesFilter();
    if(examType)seriesFilter.examType=examType;
    if(isFree!==undefined)seriesFilter.isFree=isFree==='true';
    if(category)seriesFilter.category=category;
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
    if(enrollmentState==='full')seriesFilter.$expr={$and:[{$gt:['$seatLimit',0]},{$gte:['$enrolledCount','$seatLimit']}]};

    let sortObj={createdAt:-1};
    if(sort==='popular'||sort==='enrolled')sortObj={enrolledCount:-1};
    else if(sort==='price_low')sortObj={price:1};
    else if(sort==='price_high')sortObj={price:-1};
    else if(sort==='rating')sortObj={rating:-1};

    let series=await TestSeries.find(seriesFilter).sort(sortObj).lean();
    let batches=series.map(normalizeSeries);

    // ── Attach latest linked Banner (Creative Studio design) to each card ──
    const bannerIds=batches.map(x=>x._id);
    const banners=await Banner.find({ linkedBatchId:{ $in:bannerIds }, status:{ $nin:['removed','replaced'] } }).sort({ createdAt:-1 }).lean();
    const bannerMap={};
    banners.forEach(bn=>{ const key=String(bn.linkedBatchId); if(!bannerMap[key])bannerMap[key]=bn; });

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
        banner:bannerMap[b._id.toString()]||null,
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
    let series=await TestSeries.find({_id:{$in:ids},...baseSeriesFilter()}).lean();
    const batches=series.map(normalizeSeries);
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/wishlist
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const priceWatch=user?.priceWatch||[];
    let series=await TestSeries.find({_id:{$in:ids}}).lean();
    const merged=series.map(normalizeSeries);
    const result=merged.map(b=>{
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
    const s=await TestSeries.findById(req.params.id).lean();
    if(!s)return res.status(404).json({error:'Not found'});
    const batch=normalizeSeries(s);
    let user=null;
    if(req.user){
      user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    }
    const banner=await Banner.findOne({ linkedBatchId:batch._id, status:{ $nin:['removed','replaced'] } }).sort({ createdAt:-1 }).lean();
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
        instructorHighlight:batch.teacherAssigned?`Faculty: ${batch.teacherAssigned} — subject expert, curates ${batch.subject||'this'} content for ${batch.examType||'this exam'} aspirants.`:'',
        faqPreview:[
          {q:'Can I access this on mobile?',a:'Yes, fully accessible on the ProveRank mobile web app.'},
          {q:'Is there a refund policy?',a:'Refunds are handled per platform policy — contact support within 7 days.'},
          {q:'Do I get a certificate?',a:batch.totalTests>0?'Yes, on completing all tests in this series.':'Certificate availability depends on series configuration.'}
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
    const doc=await TestSeries.findById(req.params.id);
    if(!doc)return res.status(404).json({error:'Not found'});
    if(!doc.isFree&&!doc.allowFreeTrial)return res.status(400).json({error:'Paid series'});
    await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$addToSet:{enrolledBatches:doc._id}});
    await TestSeries.findByIdAndUpdate(req.params.id,{$inc:{enrolledCount:1},$addToSet:{students:new mongoose.Types.ObjectId(req.user.id)}});
    res.json({success:true,message:'Enrolled!'});
  }catch(e){res.status(500).json({error:e.message});}
});

// POST /api/student/batches/:id/wishlist (toggle) — generic, stores raw ObjectId
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
FILEEOF
echo "OK — wrote src/routes/studentBatches.js"

cat > src/routes/studentBatchExtras.js << 'FILEEOF'
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const TestSeries=require('../models/TestSeries');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';
const crypto   = require('crypto');
const BatchPayment = require('../models/BatchPayment');

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

// GET /autocomplete?q= — series name suggestions (debounced from frontend)
router.get('/autocomplete', async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q || q.length < 2) return res.json({ suggestions: [] });
    const series = await TestSeries.find({
      name:   { $regex: q, $options: 'i' },
      lifecycleStatus: 'active'
    }).select('name examType isFree').limit(6).lean();
    res.json({ suggestions: series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /recommendations?examType=NEET&excludeId=xxx
router.get('/recommendations', optAuth, async (req, res) => {
  try {
    const { examType, excludeId } = req.query;
    const filter = { lifecycleStatus: 'active', visibility: { $ne: 'private' } };
    if (examType) filter.examType = examType;
    if (excludeId) {
      try { filter._id = { $ne: new mongoose.Types.ObjectId(excludeId) }; } catch (e) {}
    }
    const series = await TestSeries.find(filter).sort({ enrolledCount: -1, rating: -1 }).limit(4).lean();
    res.json({ batches: series });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/review — student submits review (pending admin approval)
router.post('/:id/review', auth, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: 'Rating 1-5 required' });
    const existing = await Review.findOne({ batchId: req.params.id, studentId: req.user.id });
    if (existing) return res.status(400).json({ error: 'You have already reviewed this series' });
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

// GET /:id/reviews — approved reviews for a series
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
    const item = await TestSeries.findById(req.params.id);
    if (!item) return res.status(404).json({ error: 'Series not found' });
    const amount = ((item.discountPrice || item.price) * 100);
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.json({
        success:  true,
        orderId:  'order_test_' + Date.now(),
        amount,
        currency: 'INR',
        key:      'rzp_test_placeholder',
        testMode: true,
        batchName: item.name
      });
    }
    const Razorpay = require('razorpay');
    const rzp   = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
    const order = await rzp.orders.create({ amount, currency: 'INR', notes: { seriesId: req.params.id } });
    res.json({ success: true, orderId: order.id, amount, currency: 'INR', key: process.env.RAZORPAY_KEY_ID, batchName: item.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/razorpay-verify — verify payment signature, enroll student, create receipt
router.post('/:id/razorpay-verify', auth, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!razorpay_order_id || !razorpay_payment_id) return res.status(400).json({ error: 'Missing payment details' });

    const isTestOrder = String(razorpay_order_id).startsWith('order_test_');
    if (!isTestOrder) {
      if (!process.env.RAZORPAY_KEY_SECRET) return res.status(500).json({ error: 'Razorpay secret missing on server' });
      const sigBody = razorpay_order_id + '|' + razorpay_payment_id;
      const expectedSig = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(sigBody).digest('hex');
      if (expectedSig !== razorpay_signature) return res.status(400).json({ error: 'Signature mismatch — payment verification failed' });
    }

    const item = await TestSeries.findById(req.params.id);
    if (!item) return res.status(404).json({ error: 'Series not found' });
    const itemType = 'series';

    const amount = item.discountPrice || item.price;
    const userObjId = new mongoose.Types.ObjectId(req.user.id);

    await User.collection.updateOne({ _id: userObjId }, { $addToSet: { enrolledBatches: item._id } });
    await TestSeries.findByIdAndUpdate(item._id, { $inc: { enrolledCount: 1 }, $addToSet: { students: userObjId } });

    const user = await User.collection.findOne({ _id: userObjId });
    const receiptNo = 'PR-' + Date.now().toString(36).toUpperCase();

    const payment = await BatchPayment.create({
      student: req.user.id,
      studentName: user?.name || 'Student',
      studentEmail: user?.email || '',
      itemId: item._id,
      itemType,
      itemName: item.name,
      examType: item.examType || '',
      amount,
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      testMode: isTestOrder,
      receiptNo
    });

    res.json({
      success: true,
      receipt: {
        receiptNo: payment.receiptNo,
        paymentId: payment._id,
        studentName: payment.studentName,
        studentEmail: payment.studentEmail,
        itemName: payment.itemName,
        examType: payment.examType,
        amount: payment.amount,
        razorpayPaymentId: payment.razorpayPaymentId,
        createdAt: payment.createdAt,
        testMode: payment.testMode
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/receipt/:paymentId/pdf — download official payment receipt PDF
router.get('/:id/receipt/:paymentId/pdf', auth, async (req, res) => {
  try {
    const payment = await BatchPayment.findById(req.params.paymentId).lean();
    if (!payment) return res.status(404).json({ error: 'Receipt not found' });
    if (String(payment.student) !== String(req.user.id)) return res.status(403).json({ error: 'Not authorized' });

    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=receipt_${payment.receiptNo}.pdf`);
    doc.pipe(res);

    const logoSize = 46;
    const pSize = Math.round(logoSize * 0.63);
    const rd = Math.round(pSize * 0.28);
    const cx = doc.page.width / 2;
    const startX = cx - logoSize / 2;
    const startY = 45;

    doc.roundedRect(startX, startY, pSize, pSize, rd).fill('#4D9FFF');
    doc.fillColor('#030810').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('P', startX, startY + pSize * 0.22, { width: pSize, align: 'center' });

    doc.roundedRect(startX + logoSize - pSize, startY + logoSize - pSize, pSize, pSize, rd).fillOpacity(0.85).fill('#00D4FF');
    doc.fillOpacity(1).fillColor('#00647A').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('R', startX + logoSize - pSize, startY + logoSize - pSize + pSize * 0.22, { width: pSize, align: 'center' });

    doc.y = startY + logoSize + 14;
    doc.fontSize(20).fillColor('#111').font('Helvetica-Bold').text('ProveRank', { align: 'center' });
    doc.fontSize(10).fillColor('#666').font('Helvetica').text('Online Test Platform', { align: 'center' });
    doc.moveDown(1.2);

    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(16).fillColor('#111').font('Helvetica-Bold').text('Payment Receipt', { align: 'center' });
    if (payment.testMode) { doc.moveDown(0.3); doc.fontSize(9).fillColor('#E67E22').font('Helvetica').text('(Test Mode — no real payment was charged)', { align: 'center' }); }
    doc.moveDown(1.5);

    let y = doc.y;
    const rowH = 22;
    const row = (label, value) => {
      doc.fontSize(11).fillColor('#666').font('Helvetica').text(label, 50, y);
      doc.fontSize(11).fillColor('#111').font('Helvetica-Bold').text(String(value), 300, y, { width: doc.page.width - 350, align: 'right' });
      y += rowH;
    };

    row('Receipt No.', payment.receiptNo);
    row('Date', new Date(payment.createdAt).toLocaleString('en-IN'));
    row('Student Name', payment.studentName);
    if (payment.studentEmail) row('Email', payment.studentEmail);
    row('Item Purchased', payment.itemName);
    if (payment.examType) row('Exam Type', payment.examType);
    row('Payment ID', payment.razorpayPaymentId);
    row('Order ID', payment.razorpayOrderId);

    doc.y = y + 10;
    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(14).fillColor('#111').font('Helvetica-Bold').text('Amount Paid', 50, doc.y);
    doc.fontSize(18).fillColor('#27AE60').font('Helvetica-Bold').text('₹' + payment.amount, 300, doc.y - 18, { width: doc.page.width - 350, align: 'right' });

    doc.moveDown(3);
    doc.fontSize(9).fillColor('#999').font('Helvetica').text('This is a system-generated receipt. For queries, contact ProveRank.support@gmail.com', { align: 'center' });
    doc.moveDown(0.4);
    doc.fontSize(9).fillColor('#999').text('ProveRank — Prove Yourself · Rise to the Top', { align: 'center' });

    doc.end();
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
FILEEOF
echo "OK — wrote src/routes/studentBatchExtras.js"

cat > src/routes/studentBatchUltra.js << 'FILEEOF'
// ══════════════════════════════════════════════════════════════════
// STUDENT MARKETPLACE ULTRA APIs (Test Series)
// Mounted at: /api/student/batch-ultra
// Price Watch · Fit Score · Compare Save/Share · Preview Analytics ·
// Activity Feed · Exam Calendar View
// ══════════════════════════════════════════════════════════════════
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const crypto   = require('crypto');
const TestSeries = require('../models/TestSeries');
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

const CompareSetSchema = new mongoose.Schema({
  shareId: { type: String, unique: true, index: true },
  batchIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries' }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
const CompareSet = mongoose.models.CompareSet || mongoose.model('CompareSet', CompareSetSchema);

router.post('/:id/price-watch', auth, async (req, res) => {
  try {
    const batch = await TestSeries.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Series not found' });
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
    const series = await TestSeries.find({ _id: { $in: watches.map(w => w.batchId) } }).lean();
    const alerts = series.map(b => {
      const w = watches.find(x => x.batchId?.toString() === b._id.toString());
      const eff = effectivePrice(b);
      return { batchId: b._id, name: b.name, watchedPrice: w?.watchedPrice || 0, currentPrice: eff, dropped: eff < (w?.watchedPrice || 0) };
    }).filter(a => a.dropped);
    res.json({ alerts });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/fit-score', async (req, res) => {
  try {
    const batch = await TestSeries.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Series not found' });
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
    const series = await TestSeries.find({ _id: { $in: set.batchIds } }).lean();
    res.json({ batches: series.map(b => ({ ...b, effectivePrice: effectivePrice(b) })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/preview-track', async (req, res) => {
  try {
    await TestSeries.findByIdAndUpdate(req.params.id, { $inc: { previewCount: 1 } });
    res.json({ success: true });
  } catch (e) { res.json({ success: true }); }
});

router.get('/:id/activity', async (req, res) => {
  try {
    if (!BatchActivity) return res.json({ activity: [] });
    const activity = await BatchActivity.find({ batchId: req.params.id, isActive: true }).sort({ createdAt: -1 }).limit(20).lean();
    res.json({ activity });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/calendar/upcoming', auth, async (req, res) => {
  try {
    const user = await User.collection.findOne({ _id: new mongoose.Types.ObjectId(req.user.id) });
    const ids = user?.enrolledBatches || [];
    let Exam;
    try { Exam = mongoose.model('Exam'); } catch (e) { Exam = null; }
    if (!Exam || !ids.length) return res.json({ upcoming: [] });
    const series = await TestSeries.find({ _id: { $in: ids } }).select('tests name').lean();
    const examIds = series.flatMap(b => b.tests || []);
    const exams = await Exam.find({ _id: { $in: examIds }, scheduledDate: { $gte: new Date() } }).sort({ scheduledDate: 1 }).limit(20).lean().catch(() => []);
    res.json({ upcoming: exams || [] });
  } catch (e) { res.json({ upcoming: [] }); }
});

module.exports = router;
FILEEOF
echo "OK — wrote src/routes/studentBatchUltra.js"

echo "═══════════════════════════════════════════"
echo "STEP 2 — Re-mount the 3 routes in index.js"
echo "═══════════════════════════════════════════"
node << 'NODEEOF'
const fs = require('fs');
const path = 'src/index.js';
let content = fs.readFileSync(path, 'utf8');

if (content.includes("require('./routes/studentBatches')")) {
  console.log('SKIP — index.js already mounts these routes (nothing to do).');
} else {
  const anchor = 'app.listen(';
  const idx = content.indexOf(anchor);
  if (idx === -1) {
    console.error("ABORT — could not find 'app.listen(' anchor in index.js.");
    process.exit(1);
  }
  const insertion =
`// ── URGENT HOTFIX: restore Test Series marketplace/payment API ──
const studentBatchRoutes = require('./routes/studentBatches');
const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');
const studentBatchUltraRoutes = require('./routes/studentBatchUltra');
app.use('/api/student/batches', studentBatchRoutes);
app.use('/api/student/batch-extras', studentBatchExtrasRoutes);
app.use('/api/student/batch-ultra', studentBatchUltraRoutes);

`;
  content = content.slice(0, idx) + insertion + content.slice(idx);
  fs.writeFileSync(path, content);
  console.log('OK — index.js: re-mounted 3 routes before app.listen().');
}
NODEEOF

echo "═══════════════════════════════════════════"
echo "STEP — Sanity checks"
echo "═══════════════════════════════════════════"
for f in src/routes/studentBatches.js src/routes/studentBatchExtras.js src/routes/studentBatchUltra.js src/index.js; do
  echo "-- node -c $f --"
  node -c "$f" && echo "OK"
done

echo ""
echo "═══════════════════════════════════════════"
echo "DONE. NEXT STEPS (URGENT — this restores a live broken payment page):"
echo "1. cd ~/workspace && node src/index.js   (confirm boots clean, no route errors)"
echo "2. Test in browser: /dashboard/test-series — browse, enroll, wishlist should work again"
echo "3. git add, commit, push IMMEDIATELY once verified"
echo "Backup: ~/workspace/.pre_batch_removal_backup/"
echo "═══════════════════════════════════════════"
