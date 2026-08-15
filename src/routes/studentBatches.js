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
