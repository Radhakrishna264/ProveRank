#!/bin/bash
# ProveRank — Part-01 Phase-02 Script
# Adds: Review model, adminBatchControls route, studentBatchExtras route,
#        Batch.js EMI field, index.js mounts, test-series page (autocomplete
#        + desktop sidebar + recommendations + review modal + razorpay),
#        Admin Batch Controls page
# Rules: No sed, no python, cat>EOF style, no existing feature removed

set -e
echo "🚀 ProveRank Part-01 Phase-02 — Starting..."

# ─────────────────────────────────────────────
# STEP 1 — Review.js Model (NEW FILE)
# ─────────────────────────────────────────────
echo "📝 Step 1: Creating Review.js model..."
cat > ~/workspace/src/models/Review.js << 'EOF'
const mongoose = require('mongoose');
const ReviewSchema = new mongoose.Schema({
  batchId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  studentId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User',  required: true },
  studentName: { type: String, default: 'Student' },
  rating:      { type: Number, required: true, min: 1, max: 5 },
  comment:     { type: String, default: '' },
  status:      { type: String, enum: ['pending','approved','rejected'], default: 'pending' },
  approvedBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  approvedAt:  { type: Date },
}, { timestamps: true });
module.exports = mongoose.model('Review', ReviewSchema);
EOF
echo "✅ Review.js created"

# ─────────────────────────────────────────────
# STEP 2 — Batch.js — Add allowEMI field (safe rewrite)
# ─────────────────────────────────────────────
echo "📝 Step 2: Updating Batch.js with allowEMI field..."
cat > ~/workspace/src/models/Batch.js << 'EOF'
const mongoose=require('mongoose');
const BatchSchema=new mongoose.Schema({
  name:{type:String,required:true},
  description:{type:String,default:''},
  examType:{type:String,default:'NEET',enum:['NEET','JEE','CUET','Class 11','Class 12','Foundation','Crash Course','Other']},
  category:{type:String,default:'Full Syllabus'},
  price:{type:Number,default:0},
  discountPrice:{type:Number,default:0},
  isFree:{type:Boolean,default:true},
  thumbnail:{type:String,default:''},
  totalTests:{type:Number,default:0},
  enrolledCount:{type:Number,default:0},
  language:{type:String,default:'Hindi + English'},
  difficulty:{type:String,default:'Medium',enum:['Easy','Medium','Hard','Mixed']},
  batchType:{type:String,default:'Recorded',enum:['Live','Recorded','Both']},
  isSpotlight:{type:Boolean,default:false},
  flashSaleEndTime:{type:Date},
  flashSalePrice:{type:Number},
  allowFreeTrial:{type:Boolean,default:false},
  trialDays:{type:Number,default:3},
  isBundle:{type:Boolean,default:false},
  bundleItems:[{type:String}],
  validity:{type:Number,default:365},
  tags:[{type:String}],
  status:{type:String,default:'active',enum:['active','inactive','draft']},
  createdBy:{type:mongoose.Schema.Types.ObjectId,ref:'User'},
  rating:{type:Number,default:4.5},
  ratingCount:{type:Number,default:0},
  syllabus:{type:String},
  subject:{type:String,default:'All Subjects'},
  students:[{type:mongoose.Schema.Types.ObjectId,ref:'User'}],
  notes:[{type:mongoose.Schema.Types.ObjectId,ref:'BatchNote'}],
  allowEMI:{type:Boolean,default:false},
},{timestamps:true});
module.exports=mongoose.model('Batch',BatchSchema);
EOF
echo "✅ Batch.js updated"

# ─────────────────────────────────────────────
# STEP 3 — adminBatchControls.js (NEW FILE)
# ─────────────────────────────────────────────
echo "📝 Step 3: Creating adminBatchControls.js..."
cat > ~/workspace/src/routes/adminBatchControls.js << 'EOF'
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin','superadmin'].includes(req.user?.role)) return res.status(403).json({ error: 'Admin only' });
  next();
};

// GET / — all batches list for admin controls page
router.get('/', auth, isAdmin, async (req, res) => {
  try {
    const batches = await Batch.find({}).sort({ createdAt: -1 }).lean();
    res.json({ batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/spotlight — toggle spotlight
router.put('/:id/spotlight', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.isSpotlight = !batch.isSpotlight;
    await batch.save();
    res.json({ success: true, isSpotlight: batch.isSpotlight });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/flashsale — set or remove flash sale
router.put('/:id/flashsale', auth, isAdmin, async (req, res) => {
  try {
    const { flashSalePrice, flashSaleEndTime, remove } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    if (remove) {
      await Batch.findByIdAndUpdate(req.params.id, { $unset: { flashSalePrice: 1, flashSaleEndTime: 1 } });
    } else {
      batch.flashSalePrice   = flashSalePrice;
      batch.flashSaleEndTime = new Date(flashSaleEndTime);
      await batch.save();
    }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/bundle — toggle bundle
router.put('/:id/bundle', auth, isAdmin, async (req, res) => {
  try {
    const { bundleItems, bundlePrice } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.isBundle = !batch.isBundle;
    if (bundleItems) batch.bundleItems = bundleItems;
    if (bundlePrice) batch.price       = bundlePrice;
    await batch.save();
    res.json({ success: true, isBundle: batch.isBundle });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/trial — toggle free trial
router.put('/:id/trial', auth, isAdmin, async (req, res) => {
  try {
    const { trialDays } = req.body;
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.allowFreeTrial = !batch.allowFreeTrial;
    if (trialDays) batch.trialDays = Number(trialDays);
    await batch.save();
    res.json({ success: true, allowFreeTrial: batch.allowFreeTrial, trialDays: batch.trialDays });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /:id/emi — toggle EMI
router.put('/:id/emi', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    batch.allowEMI = !batch.allowEMI;
    await batch.save();
    res.json({ success: true, allowEMI: batch.allowEMI });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /reviews — all reviews (filter by status)
router.get('/reviews', auth, isAdmin, async (req, res) => {
  try {
    const status  = req.query.status || 'pending';
    const reviews = await Review.find({ status }).sort({ createdAt: -1 }).lean();
    res.json({ reviews });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /reviews/:id/approve — approve review + recalculate rating
router.put('/reviews/:id/approve', auth, isAdmin, async (req, res) => {
  try {
    const review = await Review.findById(req.params.id);
    if (!review) return res.status(404).json({ error: 'Review not found' });
    review.status     = 'approved';
    review.approvedBy = req.user.id;
    review.approvedAt = new Date();
    await review.save();
    const approved = await Review.find({ batchId: review.batchId, status: 'approved' });
    if (approved.length > 0) {
      const avg = approved.reduce((s, r) => s + r.rating, 0) / approved.length;
      await Batch.findByIdAndUpdate(review.batchId, {
        rating:      Math.round(avg * 10) / 10,
        ratingCount: approved.length
      });
    }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /reviews/:id — reject review
router.delete('/reviews/:id', auth, isAdmin, async (req, res) => {
  try {
    await Review.findByIdAndUpdate(req.params.id, { status: 'rejected' });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/price-drop-notify — count wishlisted users (in-app alert ready)
router.post('/:id/price-drop-notify', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const bObjId = new mongoose.Types.ObjectId(req.params.id);
    const users  = await User.collection.find({ wishlistBatches: { $in: [bObjId] } }).toArray();
    res.json({ success: true, notified: users.length, batchName: batch.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
EOF
echo "✅ adminBatchControls.js created"

# ─────────────────────────────────────────────
# STEP 4 — studentBatchExtras.js (NEW FILE)
# ─────────────────────────────────────────────
echo "📝 Step 4: Creating studentBatchExtras.js..."
cat > ~/workspace/src/routes/studentBatchExtras.js << 'EOF'
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Batch    = require('../models/Batch');
const User     = require('../models/User');
const Review   = require('../models/Review');
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

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

// GET /autocomplete?q= — batch name suggestions (debounced from frontend)
router.get('/autocomplete', async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q || q.length < 2) return res.json({ suggestions: [] });
    const batches = await Batch.find({
      name:   { $regex: q, $options: 'i' },
      status: 'active'
    }).select('name examType isFree').limit(6).lean();
    res.json({ suggestions: batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /recommendations?examType=NEET&excludeId=xxx
router.get('/recommendations', optAuth, async (req, res) => {
  try {
    const { examType, excludeId } = req.query;
    const filter = { status: 'active' };
    if (examType) filter.examType = examType;
    if (excludeId) {
      try { filter._id = { $ne: new mongoose.Types.ObjectId(excludeId) }; } catch (e) {}
    }
    const batches = await Batch.find(filter).sort({ enrolledCount: -1, rating: -1 }).limit(4).lean();
    res.json({ batches });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /:id/review — student submits review (pending admin approval)
router.post('/:id/review', auth, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: 'Rating 1-5 required' });
    const existing = await Review.findOne({ batchId: req.params.id, studentId: req.user.id });
    if (existing) return res.status(400).json({ error: 'You have already reviewed this batch' });
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

// GET /:id/reviews — approved reviews for a batch
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
    const batch = await Batch.findById(req.params.id);
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const amount = ((batch.discountPrice || batch.price) * 100);
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      return res.json({
        success:  true,
        orderId:  'order_test_' + Date.now(),
        amount,
        currency: 'INR',
        key:      'rzp_test_placeholder',
        testMode: true,
        batchName: batch.name
      });
    }
    const Razorpay = require('razorpay');
    const rzp   = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
    const order = await rzp.orders.create({ amount, currency: 'INR', notes: { batchId: req.params.id } });
    res.json({ success: true, orderId: order.id, amount, currency: 'INR', key: process.env.RAZORPAY_KEY_ID, batchName: batch.name });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
EOF
echo "✅ studentBatchExtras.js created"

# ─────────────────────────────────────────────
# STEP 5 — index.js — Add 4 new lines safely
# ─────────────────────────────────────────────
echo "📝 Step 5: Mounting new routes in index.js..."
cd ~/workspace && node -e "
const fs = require('fs');
let c = fs.readFileSync('src/index.js', 'utf8');
if (c.includes('adminBatchControlRoutes')) {
  console.log('Routes already mounted — skipping');
  process.exit(0);
}
const ins = \`
const adminBatchControlRoutes  = require('./routes/adminBatchControls');
const studentBatchExtrasRoutes = require('./routes/studentBatchExtras');
app.use('/api/admin/batch-controls',  adminBatchControlRoutes);
app.use('/api/student/batch-extras',  studentBatchExtrasRoutes);
\`;
// Insert just before app.listen
c = c.replace('app.listen(', ins + 'app.listen(');
fs.writeFileSync('src/index.js', c);
console.log('index.js updated — 4 lines added');
"
echo "✅ index.js updated"

# ─────────────────────────────────────────────
# STEP 6 — Test Series Page (full rewrite + additions)
# ─────────────────────────────────────────────
echo "📝 Step 6: Rewriting test-series page with all new features..."
cat > ~/workspace/frontend/app/dashboard/test-series/page.tsx << 'EOF'
'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; description: string; examType: string;
  price: number; discountPrice: number; isFree: boolean; thumbnail: string;
  totalTests: number; enrolledCount: number; language: string; batchType: string;
  isSpotlight: boolean; flashSaleEndTime?: string; flashSalePrice?: number;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; validity: number;
  rating: number; isEnrolled?: boolean; isWishlisted?: boolean; createdAt: string;
  allowEMI?: boolean;
}
type AcSuggestion = { _id: string; name: string; examType: string; isFree: boolean }

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60',
  'Class 11': '#E67E22', 'Class 12': '#E74C3C',
  Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}
const CATS = ['All', 'NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course']
const CICONS: Record<string, string> = {
  All: '🌟', NEET: '🩺', JEE: '⚙️', CUET: '📖',
  'Class 11': '📗', 'Class 12': '📘', Foundation: '🏛️', 'Crash Course': '🚀'
}
const QUOTES = [
  { q: "Champions aren't made in gyms. They are made from something deep inside them.", a: "Muhammad Ali" },
  { q: "The secret of getting ahead is getting started. Every expert was once a beginner.", a: "Mark Twain" },
  { q: "In the middle of every difficulty lies opportunity. Stay focused, stay strong.", a: "Albert Einstein" },
  { q: "Success is not final, failure is not fatal — it is the courage to continue that counts.", a: "Winston Churchill" },
]
const FACTS = [
  { icon: '🧬', t: 'DNA Replication', f: 'Semi-conservative — each new DNA retains one original strand (Meselson-Stahl, 1958). 3 billion base pairs in human genome.', c: '#4D9FFF' },
  { icon: '⚡', t: 'ATP Synthesis', f: 'Mitochondria produce 36-38 ATP per glucose via oxidative phosphorylation. F0F1 ATP synthase rotates at 100 rpm.', c: '#00D4FF' },
]

// ── Razorpay loader ──
function loadRazorpay(): Promise<boolean> {
  return new Promise(resolve => {
    if ((window as any).Razorpay) return resolve(true)
    const s = document.createElement('script')
    s.src = 'https://checkout.razorpay.com/v1/checkout.js'
    s.onload = () => resolve(true)
    s.onerror = () => resolve(false)
    document.body.appendChild(s)
  })
}

// ── PRLogo ──
function PRLogo({ size = 36 }: { size?: number }) {
  const b = Math.round(size * 0.94)
  const p = Math.round(b * 0.63)
  const f = Math.round(p * 0.52)
  const radius = Math.round(p * 0.28)
  return (
    <div style={{ position: 'relative', width: b, height: b, flexShrink: 0, display: 'inline-flex' }}>
      <div style={{ position: 'absolute', top: 0, left: 0, width: p, height: p, borderRadius: radius, background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: f, fontWeight: 900, fontFamily: 'Inter,sans-serif', color: '#030810' }}>P</div>
      <div style={{ position: 'absolute', bottom: 0, right: 0, width: p, height: p, borderRadius: radius, background: 'rgba(0,212,255,0.15)', border: '1.5px solid rgba(0,212,255,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: f, fontWeight: 900, fontFamily: 'Inter,sans-serif', color: '#00D4FF' }}>R</div>
    </div>
  )
}

// ── MilkyWayCanvas ──
function MilkyWayCanvas() {
  const r = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = r.current; if (!cv) return
    const ctx = cv.getContext('2d'); if (!ctx) return
    let af: number, t = 0
    const resize = () => { cv.width = window.innerWidth; cv.height = window.innerHeight }
    resize(); window.addEventListener('resize', resize)
    const stars = Array.from({ length: 1100 }, () => {
      const cls = Math.random()
      return { x: Math.random(), y: Math.random(), r: cls < 0.005 ? 2.4 : cls < 0.02 ? 1.5 : cls < 0.08 ? 0.9 : 0.42, phase: Math.random() * Math.PI * 2, spd: 0.3 + Math.random() * 3, col: cls < 0.003 ? '#9BB0FF' : cls < 0.015 ? '#CAD7FF' : cls < 0.06 ? '#F8F7FF' : '#FFF4EA', inArm: Math.random() < 0.55 }
    })
    const draw = () => {
      t += 0.003
      const W = cv.width, H = cv.height, cx = W / 2, cy = H * 0.44
      ctx.clearRect(0, 0, W, H)
      ctx.fillStyle = '#020816'; ctx.fillRect(0, 0, W, H)
      const mw = ctx.createLinearGradient(0, H * 0.2, W, H * 0.8)
      mw.addColorStop(0, 'transparent'); mw.addColorStop(0.5, 'rgba(140,155,220,0.055)'); mw.addColorStop(1, 'transparent')
      ctx.fillStyle = mw; ctx.fillRect(0, 0, W, H)
      const sz = Math.min(W, H)
      const core = ctx.createRadialGradient(cx, cy, 0, cx, cy, sz * 0.18)
      core.addColorStop(0, 'rgba(255,215,120,0.15)'); core.addColorStop(0.4, 'rgba(255,170,70,0.07)'); core.addColorStop(1, 'transparent')
      ctx.fillStyle = core; ctx.fillRect(0, 0, W, H)
      const armCols = ['rgba(100,160,255,', 'rgba(180,120,255,', 'rgba(80,200,255,', 'rgba(120,200,140,']
      for (let arm = 0; arm < 4; arm++) {
        for (let seg = 0; seg < 8; seg++) {
          const angle = arm * (Math.PI / 2) + (0.25 + seg * 0.38) * 1.35 + t * 0.04
          const dist = sz * 0.055 + sz * 0.062 * seg
          const nx = cx + Math.cos(angle) * dist, ny = cy + Math.sin(angle) * dist * (H / W)
          const bsz = sz * 0.038 + sz * 0.02 * seg
          const neb = ctx.createRadialGradient(nx, ny, 0, nx, ny, bsz * (1 + 0.1 * Math.sin(t + seg + arm)))
          neb.addColorStop(0, armCols[arm] + '0.09)'); neb.addColorStop(1, 'transparent')
          ctx.fillStyle = neb; ctx.fillRect(0, 0, W, H)
        }
      }
      const nebCols: [number, number, number][] = [[77,159,255],[155,89,182],[231,76,60],[39,174,96],[0,212,255]]
      nebCols.forEach(([rr,gg,bb], i) => {
        const nx = W * (0.1 + i * 0.2) + Math.cos(t * 0.09 + i) * W * 0.025
        const ny = H * (0.08 + i * 0.19) + Math.sin(t * 0.07 + i) * H * 0.025
        const ng = ctx.createRadialGradient(nx, ny, 0, nx, ny, sz * (0.065 + 0.025 * Math.sin(t * 0.12 + i)))
        ng.addColorStop(0, `rgba(${rr},${gg},${bb},0.06)`); ng.addColorStop(1, 'transparent')
        ctx.fillStyle = ng; ctx.fillRect(0, 0, W, H)
      })
      stars.forEach(s => {
        const x = s.x * W, y = s.y * H
        const tw = 0.3 + 0.7 * Math.abs(Math.sin(t * s.spd + s.phase))
        const alpha = s.inArm ? tw * 0.72 : tw * 0.5
        if (s.r > 1.3) {
          const gl = ctx.createRadialGradient(x, y, 0, x, y, s.r * 3.2)
          gl.addColorStop(0, 'rgba(255,255,255,0.18)'); gl.addColorStop(1, 'transparent')
          ctx.fillStyle = gl; ctx.beginPath(); ctx.arc(x, y, s.r * 3.2, 0, Math.PI * 2); ctx.fill()
        }
        ctx.beginPath(); ctx.arc(x, y, s.r, 0, Math.PI * 2)
        const hex = Math.round(alpha * 255).toString(16).padStart(2, '0')
        ctx.fillStyle = s.col + hex; ctx.fill()
      })
      af = requestAnimationFrame(draw)
    }
    draw()
    return () => { cancelAnimationFrame(af); window.removeEventListener('resize', resize) }
  }, [])
  return <canvas ref={r} style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }} />
}

// ── SolarSystem ──
function SolarSystem() {
  const planets = [
    { sz: 7, col: '#9E9E9E', o: 110, dur: 47, dl: 0 },
    { sz: 13, col: 'radial-gradient(circle at 35% 35%,#F5D5A0,#C4A265)', o: 170, dur: 35, dl: -8 },
    { sz: 14, col: 'radial-gradient(circle at 35% 35%,#5BC8FA,#1565C0)', o: 240, dur: 29, dl: -14 },
    { sz: 9,  col: 'radial-gradient(circle at 35% 35%,#FF7043,#BF360C)', o: 308, dur: 24, dl: -20 },
  ]
  return (
    <div style={{ position: 'fixed', top: '42%', left: '50%', transform: 'translate(-50%,-50%)', zIndex: 1, pointerEvents: 'none', width: 0, height: 0 }}>
      <div style={{ position: 'absolute', width: 24, height: 24, marginLeft: -12, marginTop: -12, borderRadius: '50%', background: 'radial-gradient(circle at 40% 40%,#FFF9C4,#FFD600,#FF8F00)', boxShadow: '0 0 34px rgba(255,200,0,0.5)' }} />
      {planets.map((p, i) => (
        <div key={i} style={{ position: 'absolute', width: p.o * 2, height: p.o * 2, marginLeft: -p.o, marginTop: -p.o, borderRadius: '50%', border: '1px solid rgba(77,159,255,0.05)', animation: `orb ${p.dur}s linear infinite`, animationDelay: `${p.dl}s` }}>
          <div style={{ position: 'absolute', top: -p.sz / 2, left: '50%', marginLeft: -p.sz / 2, width: p.sz, height: p.sz, borderRadius: '50%', background: p.col }} />
        </div>
      ))}
    </div>
  )
}

// ── FlashTimer ──
function FlashTimer({ end }: { end: string }) {
  const [s, setS] = useState({ h: 0, m: 0, s: 0 })
  useEffect(() => {
    const tick = () => {
      const d = new Date(end).getTime() - Date.now()
      if (d <= 0) { setS({ h: 0, m: 0, s: 0 }); return }
      setS({ h: Math.floor(d / 3600000), m: Math.floor(d % 3600000 / 60000), s: Math.floor(d % 60000 / 1000) })
    }
    tick(); const iv = setInterval(tick, 1000); return () => clearInterval(iv)
  }, [end])
  const p = (n: number) => n.toString().padStart(2, '0')
  return <span style={{ fontFamily: 'monospace', fontSize: 13, fontWeight: 800, color: '#FF6B6B', letterSpacing: 2 }}>{p(s.h)}:{p(s.m)}:{p(s.s)}</span>
}

// ── Stars ──
function Stars({ r }: { r: number }) {
  return (
    <span>
      {[1,2,3,4,5].map(i => <span key={i} style={{ color: i <= Math.round(r) ? '#FFD700' : 'rgba(255,215,0,0.15)', fontSize: 11 }}>★</span>)}
      <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.3)', marginLeft: 3 }}>{r.toFixed(1)}</span>
    </span>
  )
}

// ── ReviewModal ──
function ReviewModal({ batchId, batchName, tok, onClose }: { batchId: string; batchName: string; tok: string; onClose: () => void }) {
  const [rating, setRating]   = useState(0)
  const [hov, setHov]         = useState(0)
  const [comment, setComment] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone]       = useState(false)
  const submit = async () => {
    if (!rating) return alert('Please select a rating')
    setLoading(true)
    try {
      const r = await fetch(`${API}/api/student/batch-extras/${batchId}/review`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ rating, comment })
      })
      const d = await r.json()
      if (d.success) setDone(true)
      else alert(d.error || 'Error submitting review')
    } finally { setLoading(false) }
  }
  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, background: 'rgba(0,0,0,0.85)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ background: 'rgba(4,12,30,0.99)', border: '1px solid rgba(77,159,255,0.25)', borderRadius: 22, padding: 26, maxWidth: 380, width: '100%', backdropFilter: 'blur(30px)', boxShadow: '0 30px 80px rgba(0,0,0,0.6)' }}>
        {done ? (
          <div style={{ textAlign: 'center', padding: '20px 0' }}>
            <div style={{ fontSize: 52, marginBottom: 14 }}>⭐</div>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, color: '#F0F8FF', marginBottom: 8 }}>Review Submitted!</div>
            <div style={{ fontSize: 12, color: 'rgba(160,200,240,0.6)', marginBottom: 20 }}>Pending admin approval — will appear once approved.</div>
            <button onClick={onClose} style={{ background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', border: 'none', borderRadius: 12, padding: '11px 28px', color: '#fff', fontWeight: 700, cursor: 'pointer' }}>Done</button>
          </div>
        ) : (
          <>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
              <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF' }}>Rate this Batch</div>
              <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'rgba(160,200,240,0.5)', cursor: 'pointer', fontSize: 20 }}>×</button>
            </div>
            <div style={{ fontSize: 12, color: 'rgba(160,200,240,0.55)', marginBottom: 16, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{batchName}</div>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginBottom: 18 }}>
              {[1,2,3,4,5].map(i => (
                <span key={i} onClick={() => setRating(i)} onMouseEnter={() => setHov(i)} onMouseLeave={() => setHov(0)}
                  style={{ fontSize: 36, cursor: 'pointer', transition: 'transform 0.15s', transform: i <= (hov || rating) ? 'scale(1.2)' : 'scale(1)', color: i <= (hov || rating) ? '#FFD700' : 'rgba(255,215,0,0.18)' }}>★</span>
              ))}
            </div>
            <textarea value={comment} onChange={e => setComment(e.target.value)} placeholder="Share your experience (optional)..." rows={3}
              style={{ width: '100%', padding: '10px 12px', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(77,159,255,0.15)', borderRadius: 12, color: '#F0F8FF', fontSize: 12, resize: 'none', marginBottom: 16, fontFamily: 'Inter,sans-serif' }} />
            <button onClick={submit} disabled={loading || !rating}
              style={{ width: '100%', padding: '12px', background: rating ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.15)', border: 'none', borderRadius: 12, color: rating ? '#fff' : 'rgba(160,200,240,0.4)', fontWeight: 700, cursor: rating ? 'pointer' : 'not-allowed', fontSize: 13 }}>
              {loading ? 'Submitting...' : '⭐ Submit Review'}
            </button>
          </>
        )}
      </div>
    </div>
  )
}

// ── BatchCard ──
function BatchCard({ b, tok, onUpdate, compareList, toggleCompare, onBuy, onReview }: {
  b: Batch; tok: string | null; onUpdate: () => void;
  compareList?: Batch[]; toggleCompare?: (b: Batch) => void;
  onBuy?: (b: Batch) => void; onReview?: (b: Batch) => void;
}) {
  const [loading, setLoading] = useState(false)
  const [hov, setHov]         = useState(false)
  const isFlash    = !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date())
  const isNew      = Date.now() - new Date(b.createdAt).getTime() < 7 * 86400000
  const ec         = ECOLS[b.examType] || '#4D9FFF'
  const finalPrice = isFlash && b.flashSalePrice ? b.flashSalePrice : (b.discountPrice || b.price)
  const disc       = b.price > 0 && finalPrice < b.price ? Math.round((1 - finalPrice / b.price) * 100) : 0
  const enroll = async () => {
    if (!tok) return alert('Please login')
    setLoading(true)
    try {
      const res = await fetch(`${API}/api/student/batches/${b._id}/enroll`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await res.json()
      if (d.success) onUpdate(); else alert(d.error || 'Error')
    } finally { setLoading(false) }
  }
  const toggleWish = async () => {
    if (!tok) return alert('Please login')
    await fetch(`${API}/api/student/batches/${b._id}/wishlist`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
    onUpdate()
  }
  return (
    <div onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ background: 'rgba(4,12,30,0.95)', border: `1px solid ${hov ? ec + '50' : ec + '18'}`, borderRadius: 20, overflow: 'hidden', backdropFilter: 'blur(22px)', position: 'relative', transition: 'all 0.3s', transform: hov ? 'translateY(-5px)' : 'none', boxShadow: hov ? `0 20px 50px ${ec}18` : '0 4px 18px rgba(0,10,40,0.4)' }}>
      {/* Ribbons */}
      <div style={{ position: 'absolute', top: 10, left: 10, zIndex: 5, display: 'flex', flexDirection: 'column', gap: 4 }}>
        {isNew && <span style={{ background: 'linear-gradient(135deg,#27AE60,#1E8449)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>✨ NEW</span>}
        {b.enrolledCount > 100 && <span style={{ background: 'linear-gradient(135deg,#E67E22,#CA6F1E)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>🔥 HOT</span>}
        {b.isBundle && <span style={{ background: 'linear-gradient(135deg,#9B59B6,#7D3C98)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>📦 BUNDLE</span>}
        {b.allowEMI && <span style={{ background: 'linear-gradient(135deg,#00D4FF,#0090B0)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 20 }}>💳 EMI</span>}
      </div>
      {/* Compare + Wishlist buttons */}
      {toggleCompare && compareList && (
        <button onClick={e => { e.stopPropagation(); toggleCompare(b) }}
          style={{ position: 'absolute', top: 10, right: 48, zIndex: 5, background: compareList.find(x => x._id === b._id) ? 'rgba(155,89,182,0.9)' : 'rgba(0,0,20,0.6)', border: '1px solid rgba(155,89,182,0.4)', borderRadius: '50%', width: 32, height: 32, cursor: 'pointer', fontSize: 13, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 900, transition: 'all 0.2s' }}>
          {compareList.find(x => x._id === b._id) ? '✓' : '⚖'}
        </button>
      )}
      <button onClick={toggleWish}
        style={{ position: 'absolute', top: 10, right: 10, zIndex: 5, background: 'rgba(0,0,20,0.6)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '50%', width: 36, height: 36, cursor: 'pointer', fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {b.isWishlisted ? '❤️' : '🤍'}
      </button>
      {/* Thumbnail */}
      <div style={{ height: 140, background: b.thumbnail ? `url(${b.thumbnail}) center/cover` : `linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))', zIndex: 1 }} />
        {!b.thumbnail && <span style={{ fontSize: 46, filter: `drop-shadow(0 0 16px ${ec})`, zIndex: 2, opacity: 0.88 }}>{b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : b.examType === 'CUET' ? '📖' : b.examType === 'Crash Course' ? '🚀' : '📚'}</span>}
        {isFlash && b.flashSaleEndTime && <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(200,40,40,0.92)', padding: '4px 0', textAlign: 'center', fontSize: 10, fontWeight: 700, color: '#fff', zIndex: 3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled && <div style={{ position: 'absolute', inset: 0, background: 'rgba(39,174,96,0.16)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2 }}><span style={{ background: 'rgba(39,174,96,0.9)', color: '#fff', padding: '5px 14px', borderRadius: 20, fontSize: 11, fontWeight: 800 }}>✅ Enrolled</span></div>}
      </div>
      {/* Body */}
      <div style={{ padding: '13px 14px 15px' }}>
        <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', marginBottom: 7 }}>
          <span style={{ background: `${ec}16`, color: ec, fontSize: 9, fontWeight: 700, padding: '3px 9px', borderRadius: 20, border: `1px solid ${ec}25` }}>{b.examType}</span>
          <span style={{ background: b.isFree ? 'rgba(39,174,96,0.13)' : 'rgba(230,126,34,0.13)', color: b.isFree ? '#27AE60' : '#E67E22', fontSize: 9, fontWeight: 700, padding: '3px 9px', borderRadius: 20 }}>{b.isFree ? '🆓 FREE' : b.allowFreeTrial ? `🎯 ${b.trialDays}-Day Trial` : '💎 PAID'}</span>
        </div>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#F0F8FF', marginBottom: 4, fontFamily: 'Playfair Display,serif', lineHeight: 1.4, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{b.name}</div>
        <div style={{ fontSize: 11, color: 'rgba(180,210,240,0.55)', lineHeight: 1.5, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', marginBottom: 9 }}>{b.description || 'Premium test series — NCERT based, expert curated.'}</div>
        <Stars r={b.rating} />
        <div style={{ display: 'flex', gap: 7, marginTop: 7, flexWrap: 'wrap' }}>
          {[{ i: '📝', v: `${b.totalTests} Tests` }, { i: '👥', v: b.enrolledCount.toLocaleString() }, { i: '📅', v: `${b.validity}d` }].map((it, idx) => (
            <span key={idx} style={{ fontSize: 10, color: 'rgba(180,210,240,0.45)' }}>{it.i} {it.v}</span>
          ))}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, margin: '9px 0 11px' }}>
          {b.isFree
            ? <span style={{ fontSize: 21, fontWeight: 900, color: '#27AE60', fontFamily: 'Playfair Display,serif' }}>FREE</span>
            : <><span style={{ fontSize: 21, fontWeight: 900, color: '#F0F8FF', fontFamily: 'Playfair Display,serif' }}>₹{finalPrice}</span>{disc > 0 && <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.26)', textDecoration: 'line-through' }}>₹{b.price}</span>}{disc > 0 && <span style={{ fontSize: 9, background: 'rgba(39,174,96,0.16)', color: '#27AE60', padding: '2px 7px', borderRadius: 20, fontWeight: 700 }}>{disc}% OFF</span>}</>}
        </div>
        {/* CTA buttons */}
        {b.isEnrolled ? (
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={{ flex: 1, padding: '10px', background: `linear-gradient(135deg,${ec}20,${ec}10)`, border: `1px solid ${ec}40`, borderRadius: 11, color: ec, fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>Continue →</button>
            {onReview && <button onClick={() => onReview(b)} style={{ padding: '10px 10px', background: 'rgba(255,215,0,0.08)', border: '1px solid rgba(255,215,0,0.2)', borderRadius: 11, color: '#FFD700', cursor: 'pointer', fontSize: 11 }}>⭐ Rate</button>}
          </div>
        ) : b.isFree ? (
          <button onClick={enroll} disabled={loading} style={{ width: '100%', padding: '10px', background: 'linear-gradient(135deg,#27AE60,#1E8449)', border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>{loading ? 'Enrolling...' : '🚀 Enroll Free'}</button>
        ) : b.allowFreeTrial ? (
          <button onClick={enroll} disabled={loading} style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>{loading ? 'Starting...' : '🎯 Free Trial'}</button>
        ) : (
          <button onClick={() => onBuy && onBuy(b)} style={{ width: '100%', padding: '10px', background: `linear-gradient(135deg,${ec},${ec}BB)`, border: 'none', borderRadius: 11, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 }}>
            {b.allowEMI ? `🛒 Buy ₹${finalPrice} (EMI avail.)` : `🛒 Buy ₹${finalPrice}`}
          </button>
        )}
      </div>
    </div>
  )
}

// ── EmptyState ──
function EmptyState() {
  return (
    <div style={{ textAlign: 'center', padding: '55px 16px' }}>
      <div style={{ fontSize: 72, marginBottom: 18, display: 'inline-block', animation: 'floatBob 3s ease infinite' }}>🚀</div>
      <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, background: 'linear-gradient(135deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: 10 }}>Batches Launching Soon!</div>
      <div style={{ fontSize: 12, color: 'rgba(160,200,240,0.6)', maxWidth: 360, margin: '0 auto 24px', lineHeight: 1.8 }}>Premium Test Series will appear here once created by the Admin.</div>
    </div>
  )
}

// ══════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════
export default function TestSeriesPage() {
  const router = useRouter()

  // Existing state
  const [batches, setBatches]       = useState<Batch[]>([])
  const [loading, setLoading]       = useState(true)
  const [search, setSearch]         = useState('')
  const [cat, setCat]               = useState('All')
  const [sort, setSort]             = useState('newest')
  const [filterOpen, setFilterOpen] = useState(false)
  const [filters, setFilters]       = useState({ isFree: '', batchType: '' })
  const [tab, setTab]               = useState<'all' | 'enrolled' | 'wishlist'>('all')
  const [tok, setTok]               = useState<string | null>(null)
  const [qIdx, setQIdx]             = useState(0)
  const [compareList, setCompareList] = useState<Batch[]>([])
  const [spotlights, setSpotlights]   = useState<Batch[]>([])

  // NEW state
  const [acSuggestions, setAcSuggestions] = useState<AcSuggestion[]>([])
  const [showAc, setShowAc]               = useState(false)
  const [recommendations, setRecommendations] = useState<Batch[]>([])
  const [isDesktop, setIsDesktop]         = useState(false)
  const [reviewBatch, setReviewBatch]     = useState<Batch | null>(null)

  const toggleCompare = (b: Batch) =>
    setCompareList(prev =>
      prev.find(x => x._id === b._id)
        ? prev.filter(x => x._id !== b._id)
        : prev.length >= 3 ? prev : [...prev, b]
    )

  // Init + quote rotation
  useEffect(() => {
    setTok(localStorage.getItem('pr_token'))
    const iv = setInterval(() => setQIdx(i => (i + 1) % QUOTES.length), 5000)
    return () => clearInterval(iv)
  }, [])

  // Desktop check
  useEffect(() => {
    const check = () => setIsDesktop(window.innerWidth >= 900)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  // Autocomplete debounce
  useEffect(() => {
    if (!search || search.length < 2) { setAcSuggestions([]); setShowAc(false); return }
    const timer = setTimeout(async () => {
      try {
        const r = await fetch(`${API}/api/student/batch-extras/autocomplete?q=${encodeURIComponent(search)}`)
        const d = await r.json()
        setAcSuggestions(d.suggestions || [])
        setShowAc((d.suggestions || []).length > 0)
      } catch { setShowAc(false) }
    }, 300)
    return () => clearTimeout(timer)
  }, [search])

  // Recommendations
  useEffect(() => {
    const examType = cat !== 'All' ? cat : ''
    fetch(`${API}/api/student/batch-extras/recommendations?examType=${examType}`)
      .then(r => r.json()).then(d => setRecommendations(d.batches || [])).catch(() => {})
  }, [cat])

  // Fetch batches
  const fetchBatches = useCallback(async () => {
    setLoading(true)
    try {
      const p = new URLSearchParams({ sort })
      if (cat !== 'All') p.set('examType', cat)
      if (search) p.set('search', search)
      if (filters.isFree) p.set('isFree', filters.isFree)
      if (filters.batchType) p.set('batchType', filters.batchType)
      const token = localStorage.getItem('pr_token')
      const h = token ? { Authorization: `Bearer ${token}` } : {} as Record<string, string>
      const url = tab === 'enrolled' ? `${API}/api/student/batches/my` : tab === 'wishlist' ? `${API}/api/student/batches/wishlist` : `${API}/api/student/batches?${p}`
      const res = await fetch(url, { headers: h })
      const d = await res.json()
      const all = d.batches || []
      setBatches(all)
      setSpotlights(all.filter((b: Batch) => b.isSpotlight).slice(0, 3))
    } catch { setBatches([]) } finally { setLoading(false) }
  }, [cat, sort, search, filters, tab])

  useEffect(() => { fetchBatches() }, [fetchBatches])

  // Razorpay buy handler
  const handleBuy = async (b: Batch) => {
    if (!tok) return alert('Please login to purchase')
    try {
      const r = await fetch(`${API}/api/student/batch-extras/${b._id}/razorpay-order`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' }
      })
      const d = await r.json()
      if (!d.success) return alert(d.error || 'Could not create order')
      if (d.testMode) {
        alert(`TEST MODE\n\nBatch: ${d.batchName}\nAmount: ₹${Math.round(d.amount / 100)}\nOrder ID: ${d.orderId}\n\nTo enable real payments:\nAdd RAZORPAY_KEY_ID + RAZORPAY_KEY_SECRET to Render ENV Variables.`)
        return
      }
      const loaded = await loadRazorpay()
      if (!loaded) return alert('Could not load payment gateway')
      const options = {
        key: d.key, amount: d.amount, currency: d.currency, order_id: d.orderId,
        name: 'ProveRank', description: b.name,
        handler: () => { alert('Payment successful! You are now enrolled.'); fetchBatches() },
        theme: { color: '#4D9FFF' }
      }
      const rzp = new (window as any).Razorpay(options)
      rzp.open()
    } catch { alert('Payment error. Please try again.') }
  }

  const currentQuote = QUOTES[qIdx]

  // ── Filter Sidebar content (reused for both mobile panel and desktop sidebar) ──
  const FilterContent = () => (
    <>
      <div style={{ fontWeight: 700, fontSize: 11, color: 'rgba(160,200,240,0.5)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 14 }}>🔧 Filters</div>
      {[
        { label: 'Price', key: 'isFree', opts: [{ v: '', l: 'All' }, { v: 'true', l: '🆓 Free' }, { v: 'false', l: '💎 Paid' }] },
        { label: 'Format', key: 'batchType', opts: [{ v: '', l: 'Any' }, { v: 'Live', l: '🔴 Live' }, { v: 'Recorded', l: '📹 Recorded' }, { v: 'Both', l: '🔄 Both' }] },
      ].map(f => (
        <div key={f.key} style={{ marginBottom: 18 }}>
          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)', marginBottom: 8, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1 }}>{f.label}</div>
          <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
            {f.opts.map(o => {
              const active = (filters as Record<string, string>)[f.key] === o.v
              return <button key={o.v} onClick={() => setFilters(prev => ({ ...prev, [f.key]: o.v }))}
                style={{ padding: '5px 10px', borderRadius: 20, fontSize: 10, cursor: 'pointer', background: active ? 'rgba(77,159,255,0.18)' : 'rgba(77,159,255,0.05)', border: `1px solid ${active ? 'rgba(77,159,255,0.42)' : 'rgba(77,159,255,0.1)'}`, color: active ? '#4D9FFF' : 'rgba(160,200,240,0.42)' }}>{o.l}</button>
            })}
          </div>
        </div>
      ))}
      <div style={{ marginBottom: 18 }}>
        <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)', marginBottom: 8, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1 }}>Sort By</div>
        <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
          {[{ v: 'newest', l: '🆕 Newest' }, { v: 'popular', l: '🔥 Popular' }, { v: 'rating', l: '⭐ Top Rated' }, { v: 'price_low', l: '💰 Low Price' }, { v: 'price_high', l: '💎 High Price' }].map(o => {
            const active = sort === o.v
            return <button key={o.v} onClick={() => setSort(o.v)}
              style={{ padding: '5px 10px', borderRadius: 20, fontSize: 10, cursor: 'pointer', background: active ? 'rgba(77,159,255,0.18)' : 'rgba(77,159,255,0.05)', border: `1px solid ${active ? 'rgba(77,159,255,0.42)' : 'rgba(77,159,255,0.1)'}`, color: active ? '#4D9FFF' : 'rgba(160,200,240,0.42)' }}>{o.l}</button>
          })}
        </div>
      </div>
    </>
  )

  return (
    <div style={{ minHeight: '100vh', color: '#F0F8FF', fontFamily: 'Inter,sans-serif', position: 'relative', overflowX: 'hidden', background: 'transparent' }}>
      <MilkyWayCanvas />
      <SolarSystem />
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap');
        @keyframes floatBob{0%,100%{transform:translateY(0)}50%{transform:translateY(-13px)}}
        @keyframes slideUp{from{opacity:0;transform:translateY(26px)}to{opacity:1;transform:translateY(0)}}
        @keyframes fadeSlide{from{opacity:0;transform:translateX(16px)}to{opacity:1;transform:translateX(0)}}
        @keyframes gradShift{0%,100%{background-position:0% 50%}50%{background-position:100% 50%}}
        @keyframes shimmer{0%,100%{opacity:0.3}50%{opacity:0.7}}
        @keyframes orb{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px;height:3px}
        ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.26);border-radius:4px}
        input,select,textarea{outline:none}
        input::placeholder{color:rgba(100,150,200,0.42)}
      `}</style>

      {/* STICKY TOP BAR */}
      <div style={{ position: 'sticky', top: 0, zIndex: 50, background: 'rgba(2,8,22,0.94)', backdropFilter: 'blur(22px)', borderBottom: '1px solid rgba(77,159,255,0.1)', padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => router.back()} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20, flexShrink: 0 }} onMouseEnter={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.2)')} onMouseLeave={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.1)')}>←</button>
        <PRLogo size={32} />
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 14, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>Test Series & Batches</div>
          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.42)' }}>NEET / JEE / CUET</div>
        </div>
      </div>

      <div style={{ position: 'relative', zIndex: 2, padding: '14px 14px 80px', maxWidth: 1300, margin: '0 auto' }}>

        {/* HERO */}
        <div style={{ padding: '22px 18px 20px', marginBottom: 16, textAlign: 'center', animation: 'slideUp 0.5s ease' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 4, justifyContent: 'center' }}>
            <span style={{ fontSize: 34, filter: 'drop-shadow(0 0 13px rgba(77,159,255,0.5))' }}>🎓</span>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 25, fontWeight: 700, background: 'linear-gradient(135deg,#4D9FFF 0%,#00D4FF 45%,#9B59B6 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundSize: '200%', animation: 'gradShift 6s ease infinite' }}>Test Series & Batches</div>
          </div>
        </div>

        {/* CATEGORY STRIP */}
        <div style={{ display: 'flex', gap: 7, overflowX: 'auto', paddingBottom: 7, marginBottom: 14, scrollbarWidth: 'none' }}>
          {CATS.map(c => {
            const active = cat === c
            return <button key={c} onClick={() => setCat(c)} style={{ flexShrink: 0, padding: '8px 15px', borderRadius: 22, background: active ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.07)', border: active ? 'none' : '1px solid rgba(77,159,255,0.13)', color: active ? '#fff' : 'rgba(160,200,240,0.62)', fontWeight: active ? 700 : 400, cursor: 'pointer', fontSize: 11, transition: 'all 0.2s', whiteSpace: 'nowrap', boxShadow: active ? '0 4px 13px rgba(77,159,255,0.26)' : 'none' }}>{CICONS[c]} {c}</button>
          })}
        </div>

        {/* SPOTLIGHT */}
        {spotlights.length > 0 && (
          <div style={{ marginBottom: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 11 }}>
              <span style={{ fontSize: 17 }}>⭐</span>
              <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF' }}>Spotlight Picks</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 14 }}>
              {spotlights.map(b => <BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} />)}
            </div>
          </div>
        )}

        {/* TABS */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 7, marginBottom: 13 }}>
          {(['all', 'enrolled', 'wishlist'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{ padding: '10px', borderRadius: 12, background: tab === t ? 'rgba(77,159,255,0.13)' : 'rgba(4,12,30,0.8)', border: `1px solid ${tab === t ? 'rgba(77,159,255,0.36)' : 'rgba(77,159,255,0.1)'}`, color: tab === t ? '#4D9FFF' : 'rgba(160,200,240,0.42)', fontWeight: tab === t ? 700 : 400, cursor: 'pointer', fontSize: 11, backdropFilter: 'blur(12px)' }}>
              {t === 'all' ? '🌟 All' : t === 'enrolled' ? '✅ My Batches' : '❤️ Wishlist'}
            </button>
          ))}
        </div>

        {/* DESKTOP LAYOUT: sidebar + content OR mobile: stacked */}
        <div style={{ display: isDesktop ? 'flex' : 'block', gap: 22, alignItems: 'flex-start' }}>

          {/* DESKTOP STICKY SIDEBAR FILTER */}
          {isDesktop && (
            <div style={{ width: 210, flexShrink: 0, position: 'sticky', top: 70, background: 'rgba(4,12,30,0.97)', border: '1px solid rgba(77,159,255,0.12)', borderRadius: 18, padding: '18px 16px', backdropFilter: 'blur(22px)', boxShadow: '0 10px 40px rgba(0,10,40,0.35)', animation: 'slideUp 0.4s ease' }}>
              <FilterContent />
            </div>
          )}

          {/* MAIN CONTENT */}
          <div style={{ flex: 1, minWidth: 0 }}>

            {/* SEARCH + SORT + FILTER (mobile) */}
            <div style={{ display: 'flex', gap: 7, marginBottom: 12, flexWrap: 'wrap' }}>
              <div style={{ flex: 1, minWidth: 150, position: 'relative' }}>
                <span style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', fontSize: 12, opacity: 0.42, zIndex: 2 }}>🔍</span>
                <input value={search} onChange={e => { setSearch(e.target.value); }} onFocus={() => acSuggestions.length > 0 && setShowAc(true)} onBlur={() => setTimeout(() => setShowAc(false), 200)}
                  placeholder="Search batches..." style={{ width: '100%', padding: '10px 10px 10px 32px', background: 'rgba(4,12,30,0.9)', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 12, color: '#F0F8FF', fontSize: 12, backdropFilter: 'blur(12px)' }} />
                {/* AUTOCOMPLETE DROPDOWN */}
                {showAc && acSuggestions.length > 0 && (
                  <div style={{ position: 'absolute', top: '100%', left: 0, right: 0, marginTop: 4, background: 'rgba(4,12,30,0.99)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 12, overflow: 'hidden', zIndex: 100, boxShadow: '0 12px 40px rgba(0,0,0,0.5)', backdropFilter: 'blur(24px)', animation: 'slideUp 0.18s ease' }}>
                    {acSuggestions.map(s => (
                      <div key={s._id} onClick={() => { setSearch(s.name); setShowAc(false); }}
                        style={{ padding: '10px 14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10, borderBottom: '1px solid rgba(77,159,255,0.06)', transition: 'background 0.15s' }}
                        onMouseEnter={e => (e.currentTarget.style.background = 'rgba(77,159,255,0.08)')}
                        onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}>
                        <span style={{ fontSize: 16 }}>{s.examType === 'NEET' ? '🩺' : s.examType === 'JEE' ? '⚙️' : '📚'}</span>
                        <div>
                          <div style={{ fontSize: 12, color: '#F0F8FF', fontWeight: 600 }}>{s.name}</div>
                          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)' }}>{s.examType} · {s.isFree ? 'Free' : 'Paid'}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              {!isDesktop && (
                <>
                  <select value={sort} onChange={e => setSort(e.target.value)} style={{ padding: '10px 7px', background: 'rgba(4,12,30,0.9)', border: '1px solid rgba(77,159,255,0.13)', borderRadius: 12, color: '#F0F8FF', fontSize: 11, cursor: 'pointer' }}>
                    <option value="newest">🆕 Newest</option>
                    <option value="popular">🔥 Popular</option>
                    <option value="rating">⭐ Top Rated</option>
                    <option value="price_low">💰 Low Price</option>
                    <option value="price_high">💎 High Price</option>
                  </select>
                  <button onClick={() => setFilterOpen(o => !o)} style={{ padding: '10px 12px', background: filterOpen ? 'rgba(77,159,255,0.13)' : 'rgba(4,12,30,0.9)', border: `1px solid ${filterOpen ? 'rgba(77,159,255,0.36)' : 'rgba(77,159,255,0.13)'}`, borderRadius: 12, color: '#4D9FFF', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>⚙️ Filter</button>
                </>
              )}
            </div>

            {/* MOBILE FILTER PANEL */}
            {!isDesktop && filterOpen && (
              <div style={{ background: 'rgba(4,12,30,0.97)', border: '1px solid rgba(77,159,255,0.14)', borderRadius: 15, padding: 15, marginBottom: 12, backdropFilter: 'blur(22px)', animation: 'slideUp 0.22s ease' }}>
                <FilterContent />
              </div>
            )}

            {/* BATCH GRID */}
            {loading ? (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 16 }}>
                {[1,2,3,4].map(i => <div key={i} style={{ height: 380, background: 'rgba(4,12,30,0.8)', borderRadius: 20, border: '1px solid rgba(77,159,255,0.06)', animation: 'shimmer 1.5s ease infinite', animationDelay: `${i * 0.14}s` }} />)}
              </div>
            ) : batches.length === 0 ? <EmptyState /> : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(230px,1fr))', gap: 16 }}>
                {batches.map((b, i) => (
                  <div key={b._id} style={{ animation: `slideUp ${0.28 + i * 0.04}s ease both` }}>
                    <BatchCard b={b} tok={tok} onUpdate={fetchBatches} compareList={compareList} toggleCompare={toggleCompare} onBuy={handleBuy} onReview={setReviewBatch} />
                  </div>
                ))}
              </div>
            )}

            {/* RECOMMENDATIONS */}
            {recommendations.length > 0 && (
              <div style={{ marginTop: 40 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
                  <span style={{ fontSize: 18 }}>💡</span>
                  <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: '#F0F8FF' }}>Recommended For You</span>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(220px,1fr))', gap: 14 }}>
                  {recommendations.map(b => (
                    <BatchCard key={b._id} b={b} tok={tok} onUpdate={fetchBatches} onBuy={handleBuy} onReview={setReviewBatch} />
                  ))}
                </div>
              </div>
            )}

          </div>
        </div>

        {/* NCERT FACTS */}
        <div style={{ marginTop: 50, padding: '0 4px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(230px,1fr))', gap: 26, maxWidth: 640, margin: '0 auto' }}>
            {FACTS.map((f, i) => (
              <div key={i} style={{ display: 'flex', gap: 13, alignItems: 'flex-start', animation: `slideUp ${1.1 + i * 0.12}s ease` }}>
                <div style={{ fontSize: 30, filter: `drop-shadow(0 0 11px ${f.c}80)`, flexShrink: 0 }}>{f.icon}</div>
                <div>
                  <div style={{ fontWeight: 700, color: f.c, fontSize: 12, marginBottom: 4, fontFamily: 'Playfair Display,serif' }}>{f.t}</div>
                  <div style={{ fontSize: 11, color: 'rgba(180,210,240,0.58)', lineHeight: 1.7 }}>{f.f}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* WHY PROVERANK */}
        <div style={{ marginTop: 42, background: 'rgba(4,12,30,0.97)', border: '1px solid rgba(77,159,255,0.12)', borderRadius: 20, padding: '24px 16px', backdropFilter: 'blur(22px)', boxShadow: '0 10px 40px rgba(0,10,40,0.42)' }}>
          <div style={{ textAlign: 'center', marginBottom: 20 }}>
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 19, fontWeight: 700, color: '#F0F8FF', marginBottom: 3 }}>✨ Why Choose ProveRank?</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(130px,1fr))', gap: 10 }}>
            {[
              { i: '🤖', t: 'AI Analytics', d: 'Weak area detection\nSmart revision', c: '#9B59B6' },
              { i: '🔒', t: 'Anti-Cheat', d: 'Webcam · Face AI\nIP Lock', c: '#E74C3C' },
              { i: '📊', t: 'Live Ranks', d: 'Real-time AIR\nPercentile', c: '#27AE60' },
              { i: '📄', t: 'OMR + PDFs', d: 'Bubble sheet\nCertificates', c: '#E67E22' },
              { i: '🆓', t: '100% Free', d: 'Free hosting\nNo charges', c: '#00D4FF' },
            ].map((f, i) => (
              <div key={i} style={{ background: 'rgba(4,12,30,0.72)', border: `1px solid ${f.c}14`, borderRadius: 14, padding: '14px 10px', textAlign: 'center', transition: 'all 0.3s' }} onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-3px)'; (e.currentTarget as HTMLDivElement).style.borderColor = f.c + '36' }} onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.transform = ''; (e.currentTarget as HTMLDivElement).style.borderColor = f.c + '14' }}>
                <div style={{ fontSize: 26, marginBottom: 8, filter: `drop-shadow(0 0 6px ${f.c}75)` }}>{f.i}</div>
                <div style={{ fontWeight: 700, color: f.c, fontSize: 11, marginBottom: 4 }}>{f.t}</div>
                <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.46)', lineHeight: 1.62, whiteSpace: 'pre-line' }}>{f.d}</div>
              </div>
            ))}
          </div>
        </div>

        {/* QUOTE */}
        <div style={{ padding: '24px 4px 8px', display: 'flex', alignItems: 'center', gap: 13 }}>
          <span style={{ fontSize: 26, flexShrink: 0 }}>💫</span>
          <div>
            <div style={{ fontSize: 13, color: 'rgba(200,220,240,0.72)', fontStyle: 'italic', lineHeight: 1.65, fontFamily: 'Playfair Display,serif' }}>"{currentQuote.q}"</div>
            <div style={{ fontSize: 11, color: '#4D9FFF', fontWeight: 700, marginTop: 5 }}>— {currentQuote.a}</div>
          </div>
        </div>

        {/* COMPARE FLOATING TRAY */}
        {compareList.length >= 1 && (
          <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 200, background: 'rgba(4,12,30,0.98)', borderTop: `1px solid ${compareList.length === 3 ? 'rgba(155,89,182,0.5)' : 'rgba(77,159,255,0.2)'}`, backdropFilter: 'blur(24px)', padding: '12px 16px', boxShadow: compareList.length === 3 ? '0 -8px 40px rgba(155,89,182,0.2)' : '0 -4px 20px rgba(0,0,0,0.4)' }}>
            <div style={{ maxWidth: 1200, margin: '0 auto', display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 12, color: 'rgba(160,200,240,0.6)', flexShrink: 0 }}>⚖️ <strong style={{ color: '#9B59B6' }}>{compareList.length}</strong>/3</span>
              <div style={{ display: 'flex', gap: 6, flex: 1, overflow: 'hidden' }}>
                {compareList.map(b => <span key={b._id} style={{ fontSize: 11, background: 'rgba(155,89,182,0.15)', border: '1px solid rgba(155,89,182,0.3)', borderRadius: 20, padding: '4px 10px', color: '#9B59B6', maxWidth: 110, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis', flexShrink: 0 }}>{b.name}</span>)}
              </div>
              <button onClick={() => setCompareList([])} style={{ background: 'rgba(231,76,60,0.1)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 8, padding: '7px 10px', color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 600, flexShrink: 0 }}>Clear</button>
              {compareList.length >= 2
                ? <button onClick={() => router.push('/dashboard/batch-compare?ids=' + compareList.map(b => b._id).join(','))} style={{ background: 'linear-gradient(135deg,#9B59B6,#7D3C98)', border: 'none', borderRadius: 10, padding: '9px 16px', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12, flexShrink: 0 }}>Compare Now →</button>
                : <span style={{ fontSize: 11, color: 'rgba(160,200,240,0.4)', flexShrink: 0 }}>+{2 - compareList.length} more needed</span>}
            </div>
          </div>
        )}

      </div>

      {/* REVIEW MODAL */}
      {reviewBatch && tok && (
        <ReviewModal batchId={reviewBatch._id} batchName={reviewBatch.name} tok={tok} onClose={() => setReviewBatch(null)} />
      )}

    </div>
  )
}
EOF
echo "✅ test-series page updated"

# ─────────────────────────────────────────────
# STEP 7 — Admin Batch Controls Page (NEW FILE)
# ─────────────────────────────────────────────
echo "📝 Step 7: Creating admin batch-controls page..."
mkdir -p ~/workspace/frontend/app/admin/x7k2p/batch-controls
cat > ~/workspace/frontend/app/admin/x7k2p/batch-controls/page.tsx << 'EOF'
'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

type Batch = {
  _id: string; name: string; examType: string; price: number; discountPrice: number;
  isFree: boolean; isSpotlight: boolean; flashSalePrice?: number; flashSaleEndTime?: string;
  allowFreeTrial: boolean; trialDays: number; isBundle: boolean; allowEMI: boolean;
  enrolledCount: number; rating: number; status: string;
}
type Review = {
  _id: string; batchId: string; studentName: string; rating: number; comment: string;
  status: string; createdAt: string;
}

const ECOLS: Record<string, string> = {
  NEET: '#4D9FFF', JEE: '#9B59B6', CUET: '#27AE60', 'Class 11': '#E67E22',
  'Class 12': '#E74C3C', Foundation: '#00D4FF', 'Crash Course': '#FF6B6B', Other: '#7F8C8D'
}

function ToggleSwitch({ on, onToggle, loading }: { on: boolean; onToggle: () => void; loading?: boolean }) {
  return (
    <div onClick={!loading ? onToggle : undefined}
      style={{ width: 44, height: 24, borderRadius: 12, background: on ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(255,255,255,0.08)', border: `1px solid ${on ? '#4D9FFF' : 'rgba(255,255,255,0.14)'}`, cursor: loading ? 'wait' : 'pointer', position: 'relative', transition: 'all 0.3s', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: 2, left: on ? 22 : 2, width: 18, height: 18, borderRadius: '50%', background: on ? '#fff' : 'rgba(255,255,255,0.3)', transition: 'left 0.3s', boxShadow: on ? '0 2px 8px rgba(77,159,255,0.5)' : 'none' }} />
    </div>
  )
}

export default function BatchControlsPage() {
  const router  = useRouter()
  const [tok, setTok]           = useState('')
  const [batches, setBatches]   = useState<Batch[]>([])
  const [reviews, setReviews]   = useState<Review[]>([])
  const [loading, setLoading]   = useState(true)
  const [activeTab, setActiveTab] = useState<'controls' | 'reviews' | 'flashsale'>('controls')
  const [toggling, setToggling] = useState<string | null>(null)
  const [toast, setToast]       = useState('')
  // Flash sale form
  const [fsId, setFsId]         = useState('')
  const [fsPrice, setFsPrice]   = useState('')
  const [fsEnd, setFsEnd]       = useState('')
  // Notify price drop
  const [notifying, setNotifying] = useState<string | null>(null)

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000) }

  useEffect(() => {
    const t = localStorage.getItem('pr_token') || ''
    setTok(t); fetchAll(t)
  }, [])

  const fetchAll = async (t: string) => {
    setLoading(true)
    try {
      const [bRes, rRes] = await Promise.all([
        fetch(`${API}/api/admin/batch-controls`, { headers: { Authorization: `Bearer ${t}` } }),
        fetch(`${API}/api/admin/batch-controls/reviews?status=pending`, { headers: { Authorization: `Bearer ${t}` } }),
      ])
      const bd = await bRes.json(); const rd = await rRes.json()
      setBatches(bd.batches || [])
      setReviews(rd.reviews || [])
    } catch { } finally { setLoading(false) }
  }

  const toggle = async (id: string, action: string, body?: object) => {
    setToggling(id + action)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/${action}`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined
      })
      const d = await r.json()
      if (d.success) { showToast('Updated ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error ❌')
    } catch { showToast('Network error ❌') } finally { setToggling(null) }
  }

  const setFlashSale = async () => {
    if (!fsId || !fsPrice || !fsEnd) return showToast('Fill all flash sale fields')
    await toggle(fsId, 'flashsale', { flashSalePrice: Number(fsPrice), flashSaleEndTime: fsEnd })
    setFsId(''); setFsPrice(''); setFsEnd('')
  }

  const removeFlashSale = async (id: string) => {
    await toggle(id, 'flashsale', { remove: true })
  }

  const approveReview = async (rid: string) => {
    setToggling(rid)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}/approve`, { method: 'PUT', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review approved ✅'); fetchAll(tok) }
      else showToast(d.error || 'Error')
    } finally { setToggling(null) }
  }

  const rejectReview = async (rid: string) => {
    setToggling(rid + 'r')
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/reviews/${rid}`, { method: 'DELETE', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) { showToast('Review rejected'); fetchAll(tok) }
    } finally { setToggling(null) }
  }

  const notifyPriceDrop = async (id: string) => {
    setNotifying(id)
    try {
      const r = await fetch(`${API}/api/admin/batch-controls/${id}/price-drop-notify`, { method: 'POST', headers: { Authorization: `Bearer ${tok}` } })
      const d = await r.json()
      if (d.success) showToast(`📣 ${d.notified} wishlisted users notified!`)
      else showToast(d.error || 'Error')
    } finally { setNotifying(null) }
  }

  const inp = { padding: '9px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(77,159,255,0.18)', borderRadius: 10, color: '#F0F8FF', fontSize: 12, outline: 'none' }
  const btn = (col: string) => ({ padding: '9px 16px', background: `linear-gradient(135deg,${col},${col}BB)`, border: 'none', borderRadius: 10, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 11 })

  return (
    <div style={{ minHeight: '100vh', background: 'linear-gradient(135deg,#020816 0%,#030c1a 100%)', color: '#F0F8FF', fontFamily: 'Inter,sans-serif', padding: '0 0 60px' }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Inter:wght@400;500;600;700&display=swap'); *{box-sizing:border-box} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:rgba(77,159,255,0.3);border-radius:4px} input,select{outline:none}`}</style>

      {/* TOAST */}
      {toast && (
        <div style={{ position: 'fixed', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 9999, background: 'rgba(4,12,30,0.98)', border: '1px solid rgba(77,159,255,0.3)', borderRadius: 12, padding: '12px 24px', fontSize: 13, fontWeight: 600, boxShadow: '0 8px 40px rgba(0,0,0,0.5)', backdropFilter: 'blur(20px)', whiteSpace: 'nowrap' }}>{toast}</div>
      )}

      {/* HEADER */}
      <div style={{ background: 'rgba(2,8,22,0.96)', backdropFilter: 'blur(22px)', borderBottom: '1px solid rgba(77,159,255,0.1)', padding: '14px 20px', display: 'flex', alignItems: 'center', gap: 12, position: 'sticky', top: 0, zIndex: 50 }}>
        <button onClick={() => router.push('/admin/x7k2p')} style={{ background: 'rgba(77,159,255,0.1)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 10, width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#4D9FFF', fontSize: 20 }}>←</button>
        <div>
          <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 18, fontWeight: 700, background: 'linear-gradient(90deg,#4D9FFF,#00D4FF)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚙️ Batch Controls</div>
          <div style={{ fontSize: 11, color: 'rgba(160,200,240,0.42)' }}>Spotlight · Flash Sale · Bundle · Trial · EMI · Reviews · Price Drop</div>
        </div>
        <div style={{ marginLeft: 'auto', fontSize: 11, color: 'rgba(160,200,240,0.45)' }}>{batches.length} batches · {reviews.length} pending reviews</div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '20px 16px' }}>

        {/* TABS */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {(['controls', 'flashsale', 'reviews'] as const).map(t => (
            <button key={t} onClick={() => setActiveTab(t)} style={{ padding: '9px 18px', borderRadius: 12, background: activeTab === t ? 'linear-gradient(135deg,#4D9FFF,#00D4FF)' : 'rgba(77,159,255,0.07)', border: 'none', color: activeTab === t ? '#fff' : 'rgba(160,200,240,0.5)', fontWeight: activeTab === t ? 700 : 400, cursor: 'pointer', fontSize: 11 }}>
              {t === 'controls' ? '🔧 Batch Toggles' : t === 'flashsale' ? '⚡ Flash Sale' : `⭐ Reviews (${reviews.length})`}
            </button>
          ))}
        </div>

        {/* ── TAB: BATCH TOGGLES ── */}
        {activeTab === 'controls' && (
          <div>
            {loading ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>Loading batches...</div>
            ) : batches.length === 0 ? (
              <div style={{ textAlign: 'center', padding: 40, color: 'rgba(160,200,240,0.4)' }}>No batches found. Create batches from the main Admin Panel first.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {batches.map(b => {
                  const ec = ECOLS[b.examType] || '#4D9FFF'
                  const isFlashActive = !!(b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date())
                  return (
                    <div key={b._id} style={{ background: 'rgba(4,12,30,0.95)', border: `1px solid ${ec}18`, borderRadius: 18, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14, flexWrap: 'wrap' }}>
                        <div style={{ width: 38, height: 38, borderRadius: 10, background: `${ec}18`, border: `1px solid ${ec}28`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 }}>
                          {b.examType === 'NEET' ? '🩺' : b.examType === 'JEE' ? '⚙️' : '📚'}
                        </div>
                        <div style={{ flex: 1, minWidth: 120 }}>
                          <div style={{ fontWeight: 700, fontSize: 13, color: '#F0F8FF', fontFamily: 'Playfair Display,serif' }}>{b.name}</div>
                          <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginTop: 2 }}>
                            <span style={{ color: ec }}>{b.examType}</span> · {b.isFree ? 'Free' : `₹${b.discountPrice || b.price}`} · {b.enrolledCount} enrolled · ⭐ {b.rating}
                          </div>
                        </div>
                        {isFlashActive && <span style={{ fontSize: 9, background: 'rgba(231,76,60,0.18)', color: '#E74C3C', padding: '3px 10px', borderRadius: 20, fontWeight: 700 }}>⚡ FLASH ACTIVE</span>}
                        <button onClick={() => notifyPriceDrop(b._id)} disabled={notifying === b._id}
                          style={{ padding: '6px 12px', background: 'rgba(255,215,0,0.08)', border: '1px solid rgba(255,215,0,0.2)', borderRadius: 8, color: '#FFD700', cursor: 'pointer', fontSize: 10, fontWeight: 600, whiteSpace: 'nowrap' }}>
                          {notifying === b._id ? '...' : '📣 Notify Price Drop'}
                        </button>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 10 }}>
                        {[
                          { label: '⭐ Spotlight', desc: 'Show in featured section', key: 'spotlight', val: b.isSpotlight },
                          { label: '📦 Bundle', desc: 'Mark as bundle product', key: 'bundle', val: b.isBundle },
                          { label: '🎯 Free Trial', desc: `${b.trialDays}-day trial access`, key: 'trial', val: b.allowFreeTrial },
                          { label: '💳 EMI', desc: 'Show EMI badge & option', key: 'emi', val: b.allowEMI },
                          { label: '⚡ Remove Flash', desc: 'Clear active flash sale', key: 'flashsale_remove', val: isFlashActive },
                        ].map(ctrl => (
                          <div key={ctrl.key} style={{ background: 'rgba(255,255,255,0.03)', border: `1px solid ${ctrl.val ? ec + '30' : 'rgba(255,255,255,0.06)'}`, borderRadius: 12, padding: '11px 13px', display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'space-between' }}>
                            <div>
                              <div style={{ fontSize: 11, fontWeight: 700, color: ctrl.val ? '#F0F8FF' : 'rgba(160,200,240,0.5)' }}>{ctrl.label}</div>
                              <div style={{ fontSize: 9, color: 'rgba(160,200,240,0.35)', marginTop: 2 }}>{ctrl.desc}</div>
                            </div>
                            {ctrl.key === 'flashsale_remove' ? (
                              <button onClick={() => removeFlashSale(b._id)} disabled={!isFlashActive || toggling === b._id + 'flashsale'}
                                style={{ padding: '5px 10px', background: isFlashActive ? 'rgba(231,76,60,0.15)' : 'rgba(255,255,255,0.04)', border: `1px solid ${isFlashActive ? 'rgba(231,76,60,0.3)' : 'rgba(255,255,255,0.08)'}`, borderRadius: 8, color: isFlashActive ? '#E74C3C' : 'rgba(160,200,240,0.25)', cursor: isFlashActive ? 'pointer' : 'not-allowed', fontSize: 9, fontWeight: 700 }}>
                                Remove
                              </button>
                            ) : (
                              <ToggleSwitch on={ctrl.val as boolean} loading={toggling === b._id + ctrl.key} onToggle={() => toggle(b._id, ctrl.key)} />
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}

        {/* ── TAB: FLASH SALE ── */}
        {activeTab === 'flashsale' && (
          <div>
            <div style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 20, padding: '22px 20px', marginBottom: 22, backdropFilter: 'blur(20px)' }}>
              <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 16, fontWeight: 700, color: '#F0F8FF', marginBottom: 18 }}>⚡ Set Flash Sale</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 12, marginBottom: 14 }}>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Select Batch</div>
                  <select value={fsId} onChange={e => setFsId(e.target.value)} style={{ ...inp, width: '100%' }}>
                    <option value="">Choose batch...</option>
                    {batches.filter(b => !b.isFree).map(b => <option key={b._id} value={b._id}>{b.name}</option>)}
                  </select>
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>Flash Price (₹)</div>
                  <input type="number" value={fsPrice} onChange={e => setFsPrice(e.target.value)} placeholder="e.g. 299" style={{ ...inp, width: '100%' }} />
                </div>
                <div>
                  <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.45)', marginBottom: 6, fontWeight: 700, textTransform: 'uppercase' }}>End Date & Time</div>
                  <input type="datetime-local" value={fsEnd} onChange={e => setFsEnd(e.target.value)} style={{ ...inp, width: '100%' }} />
                </div>
              </div>
              <button onClick={setFlashSale} style={btn('#E74C3C')}>⚡ Set Flash Sale</button>
            </div>
            {/* Active flash sales */}
            <div style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: '#F0F8FF', marginBottom: 14 }}>Active Flash Sales</div>
            {batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).length === 0
              ? <div style={{ color: 'rgba(160,200,240,0.4)', fontSize: 12, padding: '20px 0' }}>No active flash sales.</div>
              : batches.filter(b => b.flashSaleEndTime && new Date(b.flashSaleEndTime) > new Date()).map(b => (
                <div key={b._id} style={{ background: 'rgba(231,76,60,0.06)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 14, padding: '14px 16px', marginBottom: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{b.name}</div>
                    <div style={{ fontSize: 11, color: '#E74C3C', marginTop: 3 }}>⚡ ₹{b.flashSalePrice} · Ends {new Date(b.flashSaleEndTime!).toLocaleString()}</div>
                  </div>
                  <button onClick={() => removeFlashSale(b._id)} style={{ padding: '7px 14px', background: 'rgba(231,76,60,0.12)', border: '1px solid rgba(231,76,60,0.25)', borderRadius: 8, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>Remove</button>
                </div>
              ))
            }
          </div>
        )}

        {/* ── TAB: REVIEWS ── */}
        {activeTab === 'reviews' && (
          <div>
            {reviews.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 0', color: 'rgba(160,200,240,0.4)', fontSize: 13 }}>✅ No pending reviews</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {reviews.map(rv => (
                  <div key={rv._id} style={{ background: 'rgba(4,12,30,0.95)', border: '1px solid rgba(255,215,0,0.12)', borderRadius: 16, padding: '16px 18px', backdropFilter: 'blur(20px)' }}>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, justifyContent: 'space-between', flexWrap: 'wrap' }}>
                      <div style={{ flex: 1, minWidth: 160 }}>
                        <div style={{ display: 'flex', gap: 6, alignItems: 'center', marginBottom: 6 }}>
                          <span style={{ fontSize: 13, fontWeight: 700, color: '#F0F8FF' }}>{rv.studentName}</span>
                          <span style={{ display: 'inline-flex', gap: 1 }}>{[1,2,3,4,5].map(i => <span key={i} style={{ color: i <= rv.rating ? '#FFD700' : 'rgba(255,215,0,0.15)', fontSize: 12 }}>★</span>)}</span>
                        </div>
                        {rv.comment && <div style={{ fontSize: 12, color: 'rgba(180,210,240,0.65)', lineHeight: 1.6, marginBottom: 6 }}>"{rv.comment}"</div>}
                        <div style={{ fontSize: 10, color: 'rgba(160,200,240,0.35)' }}>{new Date(rv.createdAt).toLocaleDateString()}</div>
                      </div>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button onClick={() => approveReview(rv._id)} disabled={toggling === rv._id}
                          style={{ padding: '8px 14px', background: 'rgba(39,174,96,0.12)', border: '1px solid rgba(39,174,96,0.25)', borderRadius: 10, color: '#27AE60', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id ? '...' : '✅ Approve'}
                        </button>
                        <button onClick={() => rejectReview(rv._id)} disabled={toggling === rv._id + 'r'}
                          style={{ padding: '8px 14px', background: 'rgba(231,76,60,0.08)', border: '1px solid rgba(231,76,60,0.2)', borderRadius: 10, color: '#E74C3C', cursor: 'pointer', fontSize: 11, fontWeight: 700 }}>
                          {toggling === rv._id + 'r' ? '...' : '❌ Reject'}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  )
}
EOF
echo "✅ Admin Batch Controls page created"

# ─────────────────────────────────────────────
# STEP 8 — Install Razorpay package
# ─────────────────────────────────────────────
echo "📦 Step 8: Installing razorpay package..."
cd ~/workspace && npm list razorpay 2>/dev/null | grep -q razorpay \
  && echo "razorpay already installed" \
  || npm install razorpay --save 2>&1 | tail -4
echo "✅ razorpay done"

# ─────────────────────────────────────────────
# VERIFY
# ─────────────────────────────────────────────
echo ""
echo "=== VERIFICATION ==="
echo "Review model:"     && ls ~/workspace/src/models/Review.js
echo "adminBatchCtrls:"  && ls ~/workspace/src/routes/adminBatchControls.js
echo "studentExtras:"    && ls ~/workspace/src/routes/studentBatchExtras.js
echo "Batch.js EMI:"     && grep -c "allowEMI" ~/workspace/src/models/Batch.js
echo "index.js routes:"  && grep "batch-controls\|batch-extras" ~/workspace/src/index.js
echo "test-series page:" && ls ~/workspace/frontend/app/dashboard/test-series/page.tsx
echo "batch-controls pg:"&& ls ~/workspace/frontend/app/admin/x7k2p/batch-controls/page.tsx
echo ""
echo "✅✅✅ Part-01 Phase-02 COMPLETE!"
echo ""
echo "Admin Batch Controls URL: https://prove-rank.vercel.app/admin/x7k2p/batch-controls"
echo "Test Series URL:          https://prove-rank.vercel.app/dashboard/test-series"
