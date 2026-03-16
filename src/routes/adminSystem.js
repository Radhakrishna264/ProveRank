const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// In-memory store (MongoDB mein save karna ho toh model banao)
let maintenanceState = { enabled: false, message: '', updatedAt: null };
let featureFlags = {
  darkMode: true, liveRank: true, webcam: true,
  twoFactor: true, aiFeatures: true, pyqBank: true,
  bulkImport: true, pdfExport: true, emailNotifications: false
};

// ── S66: MAINTENANCE MODE ────────────────────────────────────
router.post('/maintenance', verifyToken, isSuperAdmin, (req, res) => {
  const { enabled, message } = req.body;
  maintenanceState = { enabled: enabled === true, message: message || '', updatedAt: new Date() };
  res.json({ success: true, message: `Maintenance mode ${enabled ? 'ON' : 'OFF'} ho gaya`, state: maintenanceState });
});

router.get('/maintenance', (req, res) => {
  res.json({ success: true, maintenance: maintenanceState });
});

// ── N21: FEATURE FLAG SYSTEM ─────────────────────────────────
router.get('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  res.json({ success: true, flags: featureFlags });
});

router.put('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  const { feature, enabled } = req.body;
  if (!feature) return res.status(400).json({ message: 'feature name required' });
  featureFlags[feature] = enabled === true;
  res.json({ success: true, message: `Feature '${feature}' ${enabled ? 'ON' : 'OFF'} ho gaya`, flags: featureFlags });
});

router.put('/feature-flags/bulk', verifyToken, isSuperAdmin, (req, res) => {
  const { flags } = req.body;
  if (!flags || typeof flags !== 'object')
    return res.status(400).json({ message: 'flags object required' });
  Object.assign(featureFlags, flags);
  res.json({ success: true, message: 'Bulk flags update ho gaye', flags: featureFlags });
});


// ── N21: FEATURE FLAGS - MongoDB Persistent (/features) ──────
const FeatureFlag = require('../models/FeatureFlag');
const DEFAULT_FLAGS = [
  {key:'open_registration',label:'Student Registration',description:'Allow new student registrations. Toggle OFF to close (Superadmin only)',enabled:true},
  {key:'webcam',label:'Webcam Proctoring',description:'Camera compulsory during exams (Phase 5.2)',enabled:true},
  {key:'audio',label:'Audio Monitoring',description:'Microphone noise detection (S57)',enabled:false},
  {key:'eyeTracking',label:'Eye Tracking AI',description:'Detect looking away from screen (S-ET)',enabled:false},
  {key:'faceDetection',label:'Face Detection TF.js',description:'Multi/no-face detection (Phase 5.4)',enabled:false},
  {key:'headPose',label:'Head Pose Detection',description:'Head angle tracking (S73)',enabled:false},
  {key:'virtualBg',label:'Virtual Background Block',description:'Detect and block fake backgrounds (S74)',enabled:false},
  {key:'vpnBlock',label:'VPN/Proxy Block',description:'Block VPN users from attempting (S20)',enabled:false},
  {key:'liveRank',label:'Live Rank Updates',description:'Socket.io real-time ranking (S107)',enabled:true},
  {key:'socialShare',label:'Social Share Results',description:'WhatsApp/Instagram result card (S99)',enabled:true},
  {key:'parentPortal',label:'Parent Portal',description:'Read-only child progress access (N17)',enabled:false},
  {key:'pyqBank',label:'PYQ Bank Access',description:'NEET 2015-2024 questions (S104)',enabled:true},
  {key:'maintenance',label:'Maintenance Mode',description:'Block students, keep admin accessible (S66)',enabled:false},
  {key:'sms',label:'SMS Notifications',description:'Result SMS via Textlocal/2SMS (M19)',enabled:false},
  {key:'whatsapp',label:'WhatsApp Alerts',description:'Exam reminders via WhatsApp (S65)',enabled:false},
  {key:'twoFactor',label:'Two Factor Auth',description:'Admin mandatory 2FA (Phase 1.1)',enabled:true},
  {key:'aiFeatures',label:'AI Features',description:'AI tagging, difficulty, classifier',enabled:true},
  {key:'bulkImport',label:'Bulk Import',description:'Excel/PDF/Copy-paste upload',enabled:true},
  {key:'pdfExport',label:'PDF Export',description:'Result/report PDF download',enabled:true},
  {key:'emailNotifications',label:'Email Notifications',description:'Email templates active (S109)',enabled:false},
  {key:'antiCheat',label:'Anti-Cheat System',description:'Full proctoring system active',enabled:true},
  {key:'reAttempt',label:'Re-Attempt System',description:'Admin can allow re-attempts (S31)',enabled:true},
  {key:'leaderboard',label:'Leaderboard',description:'Public rank leaderboard visible',enabled:true},
  {key:'questionAI',label:'Question AI Generator',description:'AI question generation (S101)',enabled:true},
  {key:'admitCard',label:'Admit Card',description:'Digital admit card system (S106)',enabled:true},
  {key:'grievance',label:'Grievance System',description:'Student grievance submission (S92)',enabled:true},
  {key:'darkMode',label:'Dark Mode',description:'Platform dark theme default',enabled:true}
];
async function seedDefaultFlags(){
  try{
    for(const f of DEFAULT_FLAGS){
      await FeatureFlag.findOneAndUpdate({key:f.key},{$setOnInsert:{key:f.key,label:f.label,description:f.description,enabled:f.enabled}},{upsert:true,new:false});
    }
  }catch(e){console.log('Flag seed error:',e.message);}
}
setTimeout(()=>seedDefaultFlags(),3000);

router.get('/features', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    let flags = await FeatureFlag.find({}).lean();
    if(!flags||flags.length===0){ await seedDefaultFlags(); flags=await FeatureFlag.find({}).lean(); }
    const flagsObj={};
    flags.forEach(f=>{flagsObj[f.key]=f.enabled;});
    global.featureFlags=flagsObj;
    res.json(flags);
  } catch(e){ res.status(500).json({success:false,message:e.message}); }
});

router.post('/features', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const {key,enabled}=req.body;
    if(!key) return res.status(400).json({message:'key required'});
    const flag=await FeatureFlag.findOneAndUpdate(
      {key},
      {enabled:enabled===true,updatedAt:new Date()},
      {upsert:true,new:true}
    );
    if(!global.featureFlags) global.featureFlags={};
    global.featureFlags[key]=enabled===true;
    res.json({success:true,message:key+' '+(enabled?'enabled':'disabled'),flag});
  } catch(e){ res.status(500).json({success:false,message:e.message}); }
});

module.exports = router;
