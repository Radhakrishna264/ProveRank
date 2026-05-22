const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

const BannerSchema = new mongoose.Schema({
  batchId: { type: String, default: '' },
  batchName: { type: String, default: '' },
  title: { type: String, required: true },
  tagline: { type: String, default: '' },
  examType: { type: String, default: 'NEET' },
  price: { type: String, default: '' },
  totalTests: { type: String, default: '' },
  duration: { type: String, default: '' },
  validity: { type: String, default: '' },
  highlights: [{ type: String }],
  ctaText: { type: String, default: 'Enroll Now' },
  badge: { type: String, default: 'none' },
  template: { type: String, default: 'classic' },
  primaryColor: { type: String, default: '#4D9FFF' },
  secondaryColor: { type: String, default: '#00D4FF' },
  textColor: { type: String, default: '#FFFFFF' },
  accentColor: { type: String, default: '#FFD700' },
  fontStyle: { type: String, default: 'modern' },
  bgImage: { type: String, default: '' },
  published: { type: Boolean, default: false },
  scheduledAt: { type: Date },
  versions: [{
    data: { type: mongoose.Schema.Types.Mixed },
    savedAt: { type: Date, default: Date.now },
    label: { type: String, default: '' }
  }],
  analytics: {
    views: { type: Number, default: 0 },
    clicks: { type: Number, default: 0 },
    enrolls: { type: Number, default: 0 }
  },
  createdBy: { type: String, default: '' },
}, { timestamps: true });

let BannerModel;
try { BannerModel = mongoose.model('Banner'); }
catch (e) { BannerModel = mongoose.model('Banner', BannerSchema); }

// GET all banners
router.get('/', auth, async (req, res) => {
  try {
    const banners = await BannerModel.find().sort({ createdAt: -1 }).lean();
    res.json({ banners });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET single banner
router.get('/:id', auth, async (req, res) => {
  try {
    const banner = await BannerModel.findById(req.params.id).lean();
    if (!banner) return res.status(404).json({ error: 'Not found' });
    res.json({ banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST create
router.post('/', auth, async (req, res) => {
  try {
    const banner = await BannerModel.create({ ...req.body, createdBy: req.user.id });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT update (saves version history)
router.put('/:id', auth, async (req, res) => {
  try {
    const existing = await BannerModel.findById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Not found' });
    // Save current as version before update
    const versionSnap = existing.toObject();
    delete versionSnap._id; delete versionSnap.versions; delete versionSnap.__v;
    existing.versions.push({ data: versionSnap, savedAt: new Date(), label: `v${existing.versions.length + 1}` });
    // Apply updates
    Object.assign(existing, req.body);
    await existing.save();
    res.json({ success: true, banner: existing });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE
router.delete('/:id', auth, async (req, res) => {
  try {
    await BannerModel.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST duplicate
router.post('/:id/duplicate', auth, async (req, res) => {
  try {
    const orig = await BannerModel.findById(req.params.id).lean();
    if (!orig) return res.status(404).json({ error: 'Not found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false;
    orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    const dup = await BannerModel.create(orig);
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST restore version
router.post('/:id/restore/:vIdx', auth, async (req, res) => {
  try {
    const banner = await BannerModel.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    await banner.save();
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST publish toggle
router.post('/:id/publish', auth, async (req, res) => {
  try {
    const banner = await BannerModel.findById(req.params.id);
    if (!banner) return res.status(404).json({ error: 'Not found' });
    banner.published = !banner.published;
    await banner.save();
    res.json({ success: true, published: banner.published });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST track view/click
router.post('/:id/track', async (req, res) => {
  try {
    const { type } = req.body;
    const inc = {};
    if (type === 'view') inc['analytics.views'] = 1;
    if (type === 'click') inc['analytics.clicks'] = 1;
    if (type === 'enroll') inc['analytics.enrolls'] = 1;
    await BannerModel.findByIdAndUpdate(req.params.id, { $inc: inc });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
