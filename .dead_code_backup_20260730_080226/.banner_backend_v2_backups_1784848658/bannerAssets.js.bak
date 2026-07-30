const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const BrandKit = require('../models/BrandKit');
const BannerTemplate = require('../models/BannerTemplate');
const SavedAsset = require('../models/SavedAsset');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin', 'superadmin'].includes(req.user.role)) return res.status(403).json({ error: 'Admin access required' });
  next();
};

// ══════════════════════════════════════════════════════════════════
// BRAND KIT — one shared org-wide brand kit
// ══════════════════════════════════════════════════════════════════
router.get('/brand-kit', auth, isAdmin, async (req, res) => {
  try {
    let kit = await BrandKit.findOne({ isDefault: true });
    if (!kit) kit = await BrandKit.create({ isDefault: true, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    res.json({ brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/brand-kit', auth, isAdmin, async (req, res) => {
  try {
    let kit = await BrandKit.findOne({ isDefault: true });
    if (!kit) kit = new BrandKit({ isDefault: true, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    const editable = ['name', 'primaryColor', 'secondaryColor', 'accentColor', 'fontPair', 'logoUrl', 'watermarkUrl', 'defaultCtaStyle', 'defaultBadgeStyle', 'defaultBannerLayout'];
    for (const f of editable) { if (req.body[f] !== undefined) kit[f] = req.body[f]; }
    await kit.save();
    res.json({ success: true, brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// TEMPLATES — organization-saved custom/cloned templates
// ══════════════════════════════════════════════════════════════════
router.get('/templates', auth, isAdmin, async (req, res) => {
  try {
    const { category, search, favorite, sort } = req.query;
    const filter = { isDeleted: false };
    if (category && category !== 'All') filter.category = category;
    if (favorite === 'true') filter.isFavorite = true;
    if (search) filter.name = { $regex: search, $options: 'i' };
    let templates = await BannerTemplate.find(filter).lean();
    if (sort === 'recent') templates = templates.sort((a, b) => new Date(b.lastUsedAt || 0) - new Date(a.lastUsedAt || 0));
    else if (sort === 'most_used') templates = templates.sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    else templates = templates.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ templates });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates', auth, isAdmin, async (req, res) => {
  try {
    const { name, category, config, clonedFromBuiltIn } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ error: 'Template name required' });
    if (!config) return res.status(400).json({ error: 'Template config required' });
    const tpl = await BannerTemplate.create({
      name: name.trim(), category: category || 'Custom', config,
      source: clonedFromBuiltIn ? 'cloned' : 'custom', clonedFromBuiltIn: clonedFromBuiltIn || '',
      createdBy: req.user.id, createdByName: req.user.name || 'Admin'
    });
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/templates/:id', auth, isAdmin, async (req, res) => {
  try {
    const tpl = await BannerTemplate.findOne({ _id: req.params.id, isDeleted: false });
    if (!tpl) return res.status(404).json({ error: 'Template not found' });
    const b = req.body;
    if (b.config !== undefined) {
      tpl.versions = tpl.versions || [];
      tpl.versions.push({ config: tpl.config, savedAt: new Date(), label: 'v' + (tpl.versions.length + 1) });
      tpl.config = b.config;
    }
    if (b.name !== undefined) tpl.name = b.name;
    if (b.category !== undefined) tpl.category = b.category;
    if (b.isFavorite !== undefined) tpl.isFavorite = !!b.isFavorite;
    await tpl.save();
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates/:id/clone', auth, isAdmin, async (req, res) => {
  try {
    const src = await BannerTemplate.findOne({ _id: req.params.id, isDeleted: false }).lean();
    if (!src) return res.status(404).json({ error: 'Template not found' });
    const clone = await BannerTemplate.create({
      name: src.name + ' (Copy)', category: src.category, config: src.config,
      source: 'cloned', clonedFromBuiltIn: src._id.toString(),
      createdBy: req.user.id, createdByName: req.user.name || 'Admin'
    });
    res.json({ success: true, template: clone });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/templates/:id', auth, isAdmin, async (req, res) => {
  try {
    const tpl = await BannerTemplate.findOne({ _id: req.params.id, isDeleted: false });
    if (!tpl) return res.status(404).json({ error: 'Template not found' });
    tpl.isDeleted = true;
    await tpl.save();
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates/:id/use', auth, isAdmin, async (req, res) => {
  try {
    await BannerTemplate.findByIdAndUpdate(req.params.id, { $inc: { usageCount: 1 }, $set: { lastUsedAt: new Date() } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/templates/:id/export', auth, isAdmin, async (req, res) => {
  try {
    const tpl = await BannerTemplate.findOne({ _id: req.params.id, isDeleted: false }).lean();
    if (!tpl) return res.status(404).json({ error: 'Template not found' });
    res.json({ exportData: { name: tpl.name, category: tpl.category, config: tpl.config, exportedAt: new Date() } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates/import', auth, isAdmin, async (req, res) => {
  try {
    const { name, category, config } = req.body;
    if (!name || !config) return res.status(400).json({ error: 'Invalid import data — name and config required' });
    const tpl = await BannerTemplate.create({ name, category: category || 'Custom', config, source: 'custom', createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/templates/:id/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const tpl = await BannerTemplate.findOne({ _id: req.params.id, isDeleted: false });
    if (!tpl) return res.status(404).json({ error: 'Template not found' });
    const v = tpl.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    tpl.config = v.config;
    await tpl.save();
    res.json({ success: true, template: tpl });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// ASSETS — shared library: stickers / decorative / subject graphics /
// typography presets / icons (illustrations already exist client-side
// from Part 2 — these are the ADDITIONAL categories from the spec)
// ══════════════════════════════════════════════════════════════════
router.get('/assets', auth, isAdmin, async (req, res) => {
  try {
    const { type, category, search, favorite, sort } = req.query;
    const filter = { isDeleted: false };
    if (type) filter.type = type;
    if (category) filter.category = category;
    if (favorite === 'true') filter.isFavorite = true;
    if (search) filter.name = { $regex: search, $options: 'i' };
    let assets = await SavedAsset.find(filter).lean();
    if (sort === 'recent') assets = assets.sort((a, b) => new Date(b.lastUsedAt || 0) - new Date(a.lastUsedAt || 0));
    else if (sort === 'most_used') assets = assets.sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
    res.json({ assets });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/assets', auth, isAdmin, async (req, res) => {
  try {
    const { name, type, category, content } = req.body;
    if (!name || !type) return res.status(400).json({ error: 'Name and type required' });
    const asset = await SavedAsset.create({ name, type, category: category || '', content: content || '', isBuiltIn: false, uploadedBy: req.user.id, uploadedByName: req.user.name || 'Admin' });
    res.json({ success: true, asset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/assets/:id', auth, isAdmin, async (req, res) => {
  try {
    const asset = await SavedAsset.findOne({ _id: req.params.id, isDeleted: false });
    if (!asset) return res.status(404).json({ error: 'Asset not found' });
    const b = req.body;
    if (b.name !== undefined) asset.name = b.name;
    if (b.category !== undefined) asset.category = b.category;
    if (b.isFavorite !== undefined) asset.isFavorite = !!b.isFavorite;
    await asset.save();
    res.json({ success: true, asset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/assets/:id', auth, isAdmin, async (req, res) => {
  try {
    const asset = await SavedAsset.findOne({ _id: req.params.id, isDeleted: false });
    if (!asset) return res.status(404).json({ error: 'Asset not found' });
    if (asset.isBuiltIn) return res.status(403).json({ error: 'Built-in assets cannot be deleted' });
    asset.isDeleted = true;
    await asset.save();
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/assets/:id/use', auth, isAdmin, async (req, res) => {
  try {
    await SavedAsset.findByIdAndUpdate(req.params.id, { $inc: { usageCount: 1 }, $set: { lastUsedAt: new Date() } });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// SEED — idempotent: populates built-in Stickers, Decorative
// Elements, Subject Graphics, Typography Presets, and Icons.
// Safe to call multiple times (checks name+type before inserting).
// ══════════════════════════════════════════════════════════════════
router.post('/assets/seed', auth, isAdmin, async (req, res) => {
  try {
    const seedList = [
      // ── Stickers (10) ──
      { name: 'Discount', type: 'sticker', category: 'Offer', content: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="#FF3B30"/><text x="50" y="58" font-size="22" fill="#fff" text-anchor="middle" font-weight="700">%</text></svg>' },
      { name: 'Flat ₹ Off', type: 'sticker', category: 'Offer', content: '<svg viewBox="0 0 100 100"><rect x="8" y="30" width="84" height="40" rx="8" fill="#FFD700"/><text x="50" y="56" font-size="16" fill="#1a1a2e" text-anchor="middle" font-weight="700">₹ OFF</text></svg>' },
      { name: 'Percentage Off', type: 'sticker', category: 'Offer', content: '<svg viewBox="0 0 100 100"><polygon points="50,5 95,50 50,95 5,50" fill="#F45C43"/><text x="50" y="58" font-size="18" fill="#fff" text-anchor="middle" font-weight="700">%OFF</text></svg>' },
      { name: 'Hurry Up', type: 'sticker', category: 'Urgency', content: '<svg viewBox="0 0 100 100"><rect x="5" y="35" width="90" height="30" rx="15" fill="#e65100"/><text x="50" y="55" font-size="13" fill="#fff" text-anchor="middle" font-weight="700">HURRY UP!</text></svg>' },
      { name: 'Offer Ends Soon', type: 'sticker', category: 'Urgency', content: '<svg viewBox="0 0 100 100"><rect x="2" y="38" width="96" height="24" rx="12" fill="#B71C1C"/><text x="50" y="54" font-size="10" fill="#fff" text-anchor="middle" font-weight="700">ENDS SOON</text></svg>' },
      { name: 'Limited Time', type: 'sticker', category: 'Urgency', content: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="none" stroke="#FFD700" stroke-width="4"/><text x="50" y="45" font-size="9" fill="#FFD700" text-anchor="middle" font-weight="700">LIMITED</text><text x="50" y="60" font-size="9" fill="#FFD700" text-anchor="middle" font-weight="700">TIME</text></svg>' },
      { name: 'Topper Choice', type: 'sticker', category: 'Achievement', content: '<svg viewBox="0 0 100 100"><polygon points="50,10 61,38 91,38 67,56 76,86 50,68 24,86 33,56 9,38 39,38" fill="#FFD700"/></svg>' },
      { name: 'Success', type: 'sticker', category: 'Achievement', content: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="#00E676"/><path d="M30 50 L45 65 L72 35" stroke="#fff" stroke-width="6" fill="none" stroke-linecap="round"/></svg>' },
      { name: 'Admission Open', type: 'sticker', category: 'Announcement', content: '<svg viewBox="0 0 100 100"><rect x="2" y="38" width="96" height="24" rx="4" fill="#1565C0"/><text x="50" y="54" font-size="9" fill="#fff" text-anchor="middle" font-weight="700">ADMISSION OPEN</text></svg>' },
      { name: 'New Launch', type: 'sticker', category: 'Announcement', content: '<svg viewBox="0 0 100 100"><polygon points="50,5 60,35 92,35 66,54 76,88 50,68 24,88 34,54 8,35 40,35" fill="#4D9FFF"/><text x="50" y="53" font-size="8" fill="#fff" text-anchor="middle" font-weight="700">NEW</text></svg>' },
      // ── Decorative Elements (8) ──
      { name: 'Ribbon', type: 'decorative', category: 'Ribbons', content: '<svg viewBox="0 0 100 40"><polygon points="0,10 70,10 85,20 70,30 0,30" fill="#FFD700"/></svg>' },
      { name: 'Corner Tag', type: 'decorative', category: 'Tags', content: '<svg viewBox="0 0 60 60"><polygon points="0,0 60,0 0,60" fill="#4D9FFF"/></svg>' },
      { name: 'Divider Line', type: 'decorative', category: 'Dividers', content: '<svg viewBox="0 0 100 10"><line x1="0" y1="5" x2="100" y2="5" stroke="#FFD700" stroke-width="2" stroke-dasharray="6,4"/></svg>' },
      { name: 'Frame', type: 'decorative', category: 'Frames', content: '<svg viewBox="0 0 100 100"><rect x="4" y="4" width="92" height="92" fill="none" stroke="#FFD700" stroke-width="3" rx="6"/></svg>' },
      { name: 'Border Accent', type: 'decorative', category: 'Borders', content: '<svg viewBox="0 0 100 20"><rect x="0" y="8" width="100" height="4" fill="#4D9FFF"/></svg>' },
      { name: 'Premium Accent Line', type: 'decorative', category: 'Lines', content: '<svg viewBox="0 0 100 10"><line x1="0" y1="5" x2="100" y2="5" stroke="#FFD700" stroke-width="3"/><circle cx="50" cy="5" r="4" fill="#FFD700"/></svg>' },
      { name: 'Floating Shape', type: 'decorative', category: 'Shapes', content: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="30" fill="#4D9FFF" opacity="0.25"/></svg>' },
      { name: 'Decorative Blob', type: 'decorative', category: 'Shapes', content: '<svg viewBox="0 0 100 100"><path d="M50 10 C80 10 90 40 85 60 C80 85 50 95 30 85 C10 75 5 45 20 25 C30 12 40 10 50 10Z" fill="#A78BFA" opacity="0.3"/></svg>' },
      // ── Subject Graphics (11, beyond the 3 already in Part 2) ──
      { name: 'Molecules', type: 'subject_graphic', category: 'Chemistry', content: '<svg viewBox="0 0 100 100"><circle cx="30" cy="40" r="8" fill="#00E5FF"/><circle cx="60" cy="30" r="8" fill="#FF6B35"/><circle cx="60" cy="60" r="8" fill="#00E676"/><line x1="30" y1="40" x2="60" y2="30" stroke="#fff" stroke-width="2"/><line x1="30" y1="40" x2="60" y2="60" stroke="#fff" stroke-width="2"/></svg>' },
      { name: 'Microscope', type: 'subject_graphic', category: 'Biology', content: '<svg viewBox="0 0 100 100"><rect x="45" y="20" width="10" height="35" fill="#4D9FFF"/><rect x="30" y="55" width="40" height="8" rx="4" fill="#4D9FFF"/><circle cx="50" cy="15" r="8" fill="#00E5FF"/></svg>' },
      { name: 'Stethoscope', type: 'subject_graphic', category: 'Medical', content: '<svg viewBox="0 0 100 100"><path d="M25 15 Q25 50 50 55 Q75 50 75 15" stroke="#FF6B6B" stroke-width="4" fill="none"/><circle cx="50" cy="70" r="10" fill="#FF6B6B"/></svg>' },
      { name: 'Brain', type: 'subject_graphic', category: 'Biology', content: '<svg viewBox="0 0 100 100"><ellipse cx="50" cy="50" rx="35" ry="28" fill="#F7931E" opacity="0.7"/><path d="M30 40 Q50 20 70 40" stroke="#fff" stroke-width="2" fill="none"/></svg>' },
      { name: 'Calculator', type: 'subject_graphic', category: 'Mathematics', content: '<svg viewBox="0 0 100 100"><rect x="25" y="10" width="50" height="80" rx="6" fill="#37474F"/><rect x="32" y="20" width="36" height="15" fill="#00E5FF"/><circle cx="38" cy="50" r="4" fill="#fff"/><circle cx="50" cy="50" r="4" fill="#fff"/><circle cx="62" cy="50" r="4" fill="#fff"/></svg>' },
      { name: 'Formula Graphics', type: 'subject_graphic', category: 'Physics', content: '<svg viewBox="0 0 100 40"><text x="50" y="26" font-size="16" fill="#FFD700" text-anchor="middle">F=ma</text></svg>' },
      { name: 'Laboratory Equipment', type: 'subject_graphic', category: 'Chemistry', content: '<svg viewBox="0 0 100 100"><path d="M40 10 L40 40 L20 85 L80 85 L60 40 L60 10 Z" fill="none" stroke="#00E676" stroke-width="3"/><rect x="35" y="5" width="30" height="8" fill="#00E676"/></svg>' },
      { name: 'Circuit Graphics', type: 'subject_graphic', category: 'Physics', content: '<svg viewBox="0 0 100 60"><path d="M10 30 H30 V10 H70 V30 H90 M30 30 V50 H70 V30" stroke="#00D4FF" stroke-width="2" fill="none"/><circle cx="30" cy="30" r="4" fill="#00D4FF"/><circle cx="70" cy="30" r="4" fill="#00D4FF"/></svg>' },
      { name: 'Engineering Graphics', type: 'subject_graphic', category: 'Engineering', content: '<svg viewBox="0 0 100 100"><rect x="20" y="20" width="60" height="60" fill="none" stroke="#4D9FFF" stroke-width="2"/><line x1="20" y1="20" x2="80" y2="80" stroke="#4D9FFF" stroke-width="1"/><line x1="80" y1="20" x2="20" y2="80" stroke="#4D9FFF" stroke-width="1"/></svg>' },
      { name: 'DNA Strand Alt', type: 'subject_graphic', category: 'Biology', content: '<svg viewBox="0 0 100 100"><path d="M20 10 Q50 25 20 40 Q50 55 20 70 Q50 85 20 100" stroke="#00E5FF" stroke-width="2" fill="none"/><path d="M80 10 Q50 25 80 40 Q50 55 80 70 Q50 85 80 100" stroke="#FF00E5" stroke-width="2" fill="none"/></svg>' },
      { name: 'Atom Alt', type: 'subject_graphic', category: 'Physics', content: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="5" fill="#FFD700"/><ellipse cx="50" cy="50" rx="45" ry="18" stroke="#00D4FF" stroke-width="1.5" fill="none" transform="rotate(30 50 50)"/><ellipse cx="50" cy="50" rx="45" ry="18" stroke="#00D4FF" stroke-width="1.5" fill="none" transform="rotate(90 50 50)"/><ellipse cx="50" cy="50" rx="45" ry="18" stroke="#00D4FF" stroke-width="1.5" fill="none" transform="rotate(150 50 50)"/></svg>' },
      // ── Icons (20, across education/subject/exam/achievement/calendar/notification) ──
      { name: 'Education Cap', type: 'icon', category: 'Education', content: '🎓' },
      { name: 'Book', type: 'icon', category: 'Education', content: '📖' },
      { name: 'Pencil', type: 'icon', category: 'Education', content: '✏️' },
      { name: 'Backpack', type: 'icon', category: 'Education', content: '🎒' },
      { name: 'Chemistry Flask', type: 'icon', category: 'Subject', content: '🧪' },
      { name: 'Dna Icon', type: 'icon', category: 'Subject', content: '🧬' },
      { name: 'Atom Icon', type: 'icon', category: 'Subject', content: '⚛️' },
      { name: 'Calculator Icon', type: 'icon', category: 'Subject', content: '🧮' },
      { name: 'Exam Sheet', type: 'icon', category: 'Exam', content: '📝' },
      { name: 'Clipboard', type: 'icon', category: 'Exam', content: '📋' },
      { name: 'Stopwatch', type: 'icon', category: 'Exam', content: '⏱️' },
      { name: 'Certificate', type: 'icon', category: 'Achievement', content: '📜' },
      { name: 'Trophy', type: 'icon', category: 'Achievement', content: '🏆' },
      { name: 'Medal', type: 'icon', category: 'Achievement', content: '🏅' },
      { name: 'Star', type: 'icon', category: 'Achievement', content: '⭐' },
      { name: 'Calendar', type: 'icon', category: 'Calendar', content: '📅' },
      { name: 'Alarm Clock', type: 'icon', category: 'Calendar', content: '⏰' },
      { name: 'Bell', type: 'icon', category: 'Notification', content: '🔔' },
      { name: 'Megaphone', type: 'icon', category: 'Notification', content: '📢' },
      { name: 'Fire Streak', type: 'icon', category: 'Notification', content: '🔥' },
      // ── Typography Presets (5) — stored as JSON style strings ──
      { name: 'Heading — Bold Impact', type: 'typography', category: 'Heading', content: JSON.stringify({ fontWeight: 800, fontSize: '1.4em', letterSpacing: '-0.02em' }) },
      { name: 'Subtitle — Soft Sans', type: 'typography', category: 'Subtitle', content: JSON.stringify({ fontWeight: 500, fontSize: '0.85em', opacity: 0.85 }) },
      { name: 'Number Highlight — Big Stat', type: 'typography', category: 'Number', content: JSON.stringify({ fontWeight: 900, fontSize: '2em', color: 'accent' }) },
      { name: 'Quote — Italic Elegant', type: 'typography', category: 'Quote', content: JSON.stringify({ fontStyle: 'italic', fontWeight: 400, fontSize: '0.9em' }) },
      { name: 'Heading — Serif Classic', type: 'typography', category: 'Heading', content: JSON.stringify({ fontWeight: 700, fontSize: '1.3em', fontFamily: "'Playfair Display',serif" }) },
      // ── Backgrounds (13) ──
      { name: 'Sunset Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#FF6B35,#F7931E)' },
      { name: 'Ocean Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#0077B6,#00B4D8)' },
      { name: 'Purple Dream Gradient', type: 'background', category: 'Gradients', content: 'linear-gradient(135deg,#8E2DE2,#4A00E0)' },
      { name: 'Abstract Blob Shape', type: 'background', category: 'Shapes', content: 'radial-gradient(ellipse at 30% 30%,#4D9FFF33,transparent 60%),radial-gradient(ellipse at 70% 70%,#A78BFA33,transparent 60%),#0a0a1a' },
      { name: 'Glassmorphism Frost', type: 'background', category: 'Glassmorphism', content: 'linear-gradient(135deg,rgba(255,255,255,0.15),rgba(255,255,255,0.05))' },
      { name: 'Diagonal Stripe Pattern', type: 'background', category: 'Patterns', content: 'repeating-linear-gradient(45deg,#1a1a3e,#1a1a3e 10px,#0a0a1a 10px,#0a0a1a 20px)' },
      { name: 'Dot Grid Pattern', type: 'background', category: 'Patterns', content: 'radial-gradient(circle,#4D9FFF22 1px,transparent 1px),#0a0a1a' },
      { name: 'Subtle Noise Texture', type: 'background', category: 'Textures', content: 'linear-gradient(135deg,#1a1a2e,#16213e,#0f3460)' },
      { name: 'Warm Light Effect', type: 'background', category: 'Light Effects', content: 'radial-gradient(circle at 50% 20%,#FFD70055,transparent 60%),#1a1200' },
      { name: 'Cool Glow Effect', type: 'background', category: 'Glow Effects', content: 'radial-gradient(circle at 50% 50%,#00E5FF44,transparent 70%),#020816' },
      { name: 'Bokeh Lights', type: 'background', category: 'Bokeh Effects', content: 'radial-gradient(circle at 20% 30%,#FFD70033,transparent 20%),radial-gradient(circle at 70% 60%,#4D9FFF33,transparent 20%),radial-gradient(circle at 40% 80%,#FF00E533,transparent 20%),#0a0a1a' },
      { name: 'Mesh Gradient Cool', type: 'background', category: 'Mesh Gradients', content: 'radial-gradient(at 0% 0%,#4D9FFF66,transparent 50%),radial-gradient(at 100% 0%,#A78BFA66,transparent 50%),radial-gradient(at 100% 100%,#00E5FF66,transparent 50%),radial-gradient(at 0% 100%,#00E67666,transparent 50%),#0a0a1a' },
      { name: 'Mesh Gradient Warm', type: 'background', category: 'Mesh Gradients', content: 'radial-gradient(at 0% 0%,#FF6B3566,transparent 50%),radial-gradient(at 100% 0%,#FFD70066,transparent 50%),radial-gradient(at 100% 100%,#F7931E66,transparent 50%),radial-gradient(at 0% 100%,#eb334966,transparent 50%),#1a0a00' },
      // ── CTA Elements (6 button-shape presets) ──
      { name: 'Pill Button', type: 'cta', category: 'Shape', content: 'pill' },
      { name: 'Rounded Button', type: 'cta', category: 'Shape', content: 'rounded' },
      { name: 'Square Button', type: 'cta', category: 'Shape', content: 'square' },
      { name: 'Outline Button', type: 'cta', category: 'Shape', content: 'outline' },
      { name: 'Pill with Arrow', type: 'cta', category: 'Shape', content: 'pill' },
      { name: 'Rounded with Arrow', type: 'cta', category: 'Shape', content: 'rounded' },
    ];

    let inserted = 0, skipped = 0;
    for (const item of seedList) {
      const exists = await SavedAsset.findOne({ name: item.name, type: item.type, isBuiltIn: true });
      if (exists) { skipped++; continue; }
      await SavedAsset.create({ ...item, isBuiltIn: true });
      inserted++;
    }
    res.json({ success: true, inserted, skipped, total: seedList.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
