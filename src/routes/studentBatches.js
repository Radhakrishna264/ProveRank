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

// GET /api/student/batches
router.get('/',optAuth,async(req,res)=>{
  try{
    const{examType,isFree,search,sort='newest',category,subject}=req.query;
    const filter={status:'active'};
    if(examType)filter.examType=examType;
    if(isFree!==undefined)filter.isFree=isFree==='true';
    if(category)filter.category=category;
    if(subject)filter.subject=subject;
    if(search)filter.name={$regex:search,$options:'i'};
    let sortObj={createdAt:-1};
    if(sort==='popular')sortObj={enrolledCount:-1};
    else if(sort==='price_low')sortObj={price:1};
    else if(sort==='price_high')sortObj={price:-1};
    else if(sort==='rating')sortObj={rating:-1};
    const batches=await Batch.find(filter).sort(sortObj).lean();
    let enrolledIds=[],wishlistIds=[];
    if(req.user){
      const user=await User.collection.findOne({_id:new mongoose.Types.ObjectId(req.user.id)});
      enrolledIds=(user?.enrolledBatches||[]).map(id=>id.toString());
      wishlistIds=(user?.wishlistBatches||[]).map(id=>id.toString());
    }
    const result=batches.map(b=>({...b,isEnrolled:enrolledIds.includes(b._id.toString()),isWishlisted:wishlistIds.includes(b._id.toString())}));
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
    const batches=await Batch.find({_id:{$in:ids}}).lean();
    res.json({batches});
  }catch(e){res.status(500).json({error:e.message});}
});

// GET /api/student/batches/:id
router.get('/:id',optAuth,async(req,res)=>{
  try{
    const batch=await Batch.findById(req.params.id).lean();
    if(!batch)return res.status(404).json({error:'Not found'});
    res.json({batch});
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
    if(isW){await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$pull:{wishlistBatches:bObjId}});}
    else{await User.collection.updateOne({_id:new mongoose.Types.ObjectId(req.user.id)},{$addToSet:{wishlistBatches:bObjId}});}
    res.json({success:true,isWishlisted:!isW});
  }catch(e){res.status(500).json({error:e.message});}
});

module.exports=router;
