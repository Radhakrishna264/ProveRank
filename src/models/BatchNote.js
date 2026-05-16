const mongoose=require('mongoose');
const BatchNoteSchema=new mongoose.Schema({
  batch:{type:mongoose.Schema.Types.ObjectId,ref:'Batch',required:true},
  title:{type:String,required:true,trim:true},
  description:{type:String,default:''},
  url:{type:String,default:''},
  type:{type:String,enum:['pdf','video','doc','link','image','other'],default:'link'},
  subject:{type:String,default:'General'},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
},{timestamps:true});
module.exports=mongoose.model('BatchNote',BatchNoteSchema);