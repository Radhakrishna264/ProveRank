const mongoose=require('mongoose');
const SeriesNoteSchema=new mongoose.Schema({
  series:{type:mongoose.Schema.Types.ObjectId,ref:'TestSeries',required:true},
  title:{type:String,required:true,trim:true},
  description:{type:String,default:''},
  url:{type:String,default:''},
  type:{type:String,enum:['pdf','video','doc','link','image','other'],default:'link'},
  subject:{type:String,default:'General'},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
  pinned:{type:Boolean,default:false},
  expiryDate:{type:Date,default:null},
  version:{type:Number,default:1},
  // ── Series Workspace (student read-tracking) — additive, non-breaking ──
  viewedBy:[{
    studentId:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
    viewedAt:{type:Date,default:Date.now}
  }],
},{timestamps:true});
module.exports=mongoose.model('SeriesNote',SeriesNoteSchema);
