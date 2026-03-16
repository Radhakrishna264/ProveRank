const mongoose = require('mongoose');
require('dotenv').config({path:'/home/runner/workspace/.env'});
const uri = process.env.MONGO_URI;
mongoose.connect(uri).then(async()=>{
  const FeatureFlag = require('/home/runner/workspace/src/models/FeatureFlag');
  // Purane wrong-key entries delete karo
  await FeatureFlag.deleteMany({key:{$in:['eyeTracking','faceDetection','headPose','virtualBg','vpnBlock','liveRank','socialShare','parentPortal','pyqBank','sms','twoFactor','aiFeatures','bulkImport','pdfExport','emailNotifications','antiCheat','reAttempt','leaderboard','questionAI','admitCard','grievance','darkMode','sms_notify','ai_tagger','ai_explain','two_fa','ip_lock','fullscreen','watermark','integrity','n14_pattern','onboarding','n23_encrypt','waiting_room','cert_gen','vbg_block','vpn_block','live_rank','social_share','parent_portal','pyq_bank','face_detect','head_pose','eye_tracking']}});
  // Correct keys se fresh seed
  const flags = [
    {key:'open_registration',label:'Student Registration',description:'Allow new student registrations (Superadmin only)',enabled:true},
    {key:'webcam',label:'Webcam Proctoring',description:'Camera compulsory during exams (Phase 5.2)',enabled:true},
    {key:'audio',label:'Audio Monitoring',description:'Microphone noise detection (S57)',enabled:false},
    {key:'eye_tracking',label:'Eye Tracking AI',description:'Detect looking away from screen (S-ET)',enabled:true},
    {key:'face_detect',label:'Face Detection TF.js',description:'Multi/no-face detection (Phase 5.4)',enabled:true},
    {key:'head_pose',label:'Head Pose Detection',description:'Head angle tracking (S73)',enabled:true},
    {key:'vbg_block',label:'Virtual Background Block',description:'Detect and block fake backgrounds (S74)',enabled:true},
    {key:'vpn_block',label:'VPN/Proxy Block',description:'Block VPN users from attempting (S20)',enabled:false},
    {key:'live_rank',label:'Live Rank Updates',description:'Socket.io real-time ranking (S107)',enabled:true},
    {key:'social_share',label:'Social Share Results',description:'WhatsApp/Instagram result card (S99)',enabled:true},
    {key:'parent_portal',label:'Parent Portal',description:'Read-only child progress access (N17)',enabled:false},
    {key:'pyq_bank',label:'PYQ Bank Access',description:'NEET 2015-2024 questions (S104)',enabled:true},
    {key:'maintenance',label:'Maintenance Mode',description:'Block students, keep admin accessible (S66)',enabled:false},
    {key:'sms_notify',label:'SMS Notifications',description:'Result SMS via Twilio/Fast2SMS (M19)',enabled:false},
    {key:'whatsapp',label:'WhatsApp Alerts',description:'Exam reminders via WhatsApp (S65)',enabled:false},
    {key:'ai_tagger',label:'AI Auto-Tagger',description:'Auto difficulty + subject tagging (AI-1/AI-2)',enabled:true},
    {key:'ai_explain',label:'AI Explanation Generator',description:'Auto explanation from question (AI-10)',enabled:true},
    {key:'two_fa',label:'2FA Admin Login',description:'OTP mandatory for admin accounts (S49)',enabled:true},
    {key:'ip_lock',label:'IP Lock During Exam',description:'Block IP change mid-exam (S20)',enabled:true},
    {key:'fullscreen',label:'Fullscreen Force Mode',description:'3 exits triggers auto-submit (S32)',enabled:true},
    {key:'watermark',label:'Screen Watermark',description:'Student name/ID watermark on screen (S76)',enabled:true},
    {key:'integrity',label:'AI Integrity Score',description:'0-100 score per exam attempt (AI-6)',enabled:true},
    {key:'n14_pattern',label:'Suspicious Pattern Detection',description:'Fast/identical answer flagging (N14)',enabled:true},
    {key:'onboarding',label:'Platform Onboarding Tour',description:'Guided tour for new students (S100)',enabled:true},
    {key:'n23_encrypt',label:'Paper Encryption',description:'Questions encrypted in browser (N23)',enabled:false},
    {key:'waiting_room',label:'Exam Waiting Room',description:'Students join 10 min before exam (M6)',enabled:true},
    {key:'cert_gen',label:'Certificate Generation',description:'Auto PDF certificate on completion (S21)',enabled:true},
  ];
  for(const f of flags){
    await FeatureFlag.findOneAndUpdate({key:f.key},{$set:{label:f.label,description:f.description,enabled:f.enabled}},{upsert:true,new:true});
  }
  const count = await FeatureFlag.countDocuments();
  console.log('✅ Done! Total flags in DB:', count);
  mongoose.disconnect();
}).catch(e=>console.log('❌',e.message));
