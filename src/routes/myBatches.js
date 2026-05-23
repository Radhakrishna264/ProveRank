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

// Enrollment meta schema (stored in user doc)
// enrolledBatchesMeta: [{batchId, enrolledAt, expiresAt, progress, testsCompleted, lastAccessedAt, streak, streakLastDate, avgScore, bestRank}]

// GET /api/my-batches — all enrolled batches with meta
router.get('/',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=(user?.enrolledBatches||[]);
    const meta=user?.enrolledBatchesMeta||[];
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
      return{
        ...b, enrolledAt, expiresAt, daysLeft, testsCompleted, totalTests,
        progress, lastAccessedAt, daysSinceAccess, streak,
        avgScore:m.avgScore||0, bestRank:m.bestRank||null,
        isExpiring:daysLeft<=7&&daysLeft>0, isExpired:daysLeft===0,
        isCompleted:progress>=100,
      };
    });
    // Sort: last accessed first
    result.sort((a,b)=>new Date(b.lastAccessedAt).getTime()-new Date(a.lastAccessedAt).getTime());
    res.json({batches:result,total:result.length});
  }catch(e){console.error(e);res.status(500).json({error:e.message});}
});

// GET /api/my-batches/stats — summary stats
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
    res.json({total,testsCompleted,activeBatches,certificates});
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

// GET /api/my-batches/wishlist — wishlist batches (separate from test-series wishlist UI)
router.get('/wishlist',auth,async(req,res)=>{
  try{
    const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
    const ids=user?.wishlistBatches||[];
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

module.exports=router;
