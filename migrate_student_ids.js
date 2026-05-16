
// Run once: node migrate_student_ids.js
require('dotenv').config();
const mongoose=require('mongoose');
const User=require('./src/models/User');
const generateStudentId=require('./src/utils/generateStudentId');

async function migrate(){
  await mongoose.connect(process.env.MONGODB_URI||process.env.MONGO_URI);
  console.log('Connected');
  const students=await User.find({role:'student',studentId:{$exists:false}});
  console.log('Students without ID:',students.length);
  for(const s of students){
    const id=await generateStudentId();
    await User.findByIdAndUpdate(s._id,{studentId:id,welcomeSeen:true}); // existing = already welcomed
    console.log('Assigned',id,'to',s.email);
  }
  console.log('Migration done');
  process.exit(0);
}
migrate().catch(e=>{console.error(e);process.exit(1);});
