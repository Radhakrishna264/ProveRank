#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# BANNER MANAGEMENT — REMOVE GLOBAL PAGE, REBUILD AS SCOPED TAB
#
# REMOVES (old global "Creative Studio / Banner Management" feature):
#   • Sidebar nav entry (page.tsx NAV array)
#   • Sidebar redirect handler (_setTab override → banner-generator page)
#   • Dead "🎨 Generate Banner" button inside legacy BatchDetailOverlay
#   • Standalone page: frontend/app/admin/x7k2p/banner-generator/
#   • Backend route file: src/routes/bannerGenerator.js
#   • index.js: route mount + the separate cron auto-publish job
#
# KEEPS & REUSES (per spec: "upgrade, don't replace"):
#   • src/models/Banner.js (already has linkedBatchId/linkedType — a
#     perfect scoping field, reused as-is, no schema change needed)
#   • src/models/BannerAuditLog.js (reused as-is)
#   • Template list, color presets, fonts, badges, SVG illustration
#     library, live preview engine, html2canvas PNG export — all
#     ported over and expanded into the new tab
#
# ADDS (new scoped tab, right after Coupon Management, on both Batch
# Detail and Test Series Detail pages):
#   Backend  /:id/banner routes added directly into batchManagerUltra.js
#            and testSeriesManagerUltra.js (same pattern as Coupons):
#            GET (overview+current+syncPreview), auto-generate, edit,
#            sync-from-product, duplicate, remove, restore-removed,
#            replace, restore-version, analytics, track, audit.
#   Frontend BannerManagementTab in both admin tsx files: Overview
#            strip, Current Banner panel, Banner Builder (content +
#            design + live validation), Preview & Variants (4 sizes +
#            PNG export), Templates & Assets (31 templates across 8
#            categories + search/filter, 18 badges, 6 color presets,
#            3 fonts, 8 SVG illustrations + safe-zone guide), Version
#            History, Analytics, Audit Trail, Integration Summary.
#
# NOTE: Publish/Launch is intentionally NOT in this tab — the spec
# reserves that for a future separate "Publish Center" feature.
#
# DEFERRED (spec explicitly marks these "(Future)"/"(Future Ready)",
# or they require infrastructure beyond this task's scope — not built
# now, flagged honestly rather than silently skipped): AI-generated
# templates/suggestions, background videos, 3D objects/particle/mesh
# effects, organization-wide asset library & brand-kit storage, bulk
# banner manager, drag-and-drop layout editor, campaign auto-publish
# scheduling (all tied to the future Publish Center).
# ══════════════════════════════════════════════════════════════════

set -e
cd ~/workspace

B_ROUTE="src/routes/batchManagerUltra.js"
S_ROUTE="src/routes/testSeriesManagerUltra.js"
B_TSX="frontend/app/admin/x7k2p/BatchManagerUltra.tsx"
S_TSX="frontend/app/admin/x7k2p/TestSeriesManagerUltra.tsx"
ADMIN_PAGE="frontend/app/admin/x7k2p/page.tsx"
INDEX_JS="src/index.js"
OLD_BANNER_ROUTE="src/routes/bannerGenerator.js"
OLD_BANNER_PAGE_DIR="frontend/app/admin/x7k2p/banner-generator"

for f in "$B_ROUTE" "$S_ROUTE" "$B_TSX" "$S_TSX" "$ADMIN_PAGE" "$INDEX_JS"; do
  if [ ! -f "$f" ]; then echo "❌ Not found: $f"; exit 1; fi
  cp "$f" "${f}.bak_$(date +%s)"
done

# ══════════════════════════════════════════════════════════════════
# STEP 1 — Node.js precise patch: removals + additions across 6 files
# ══════════════════════════════════════════════════════════════════
cat > /tmp/fix_banner_tab.js << 'NODEEOF'
const fs = require('fs');

function replaceExact(path, replacements) {
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error(`❌ [${path}] anchor not found: ${label}`);
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src);
  console.log(`✅ ${path} updated`);
}

// ══════════════════════════════════════════
// A) REMOVE from src/index.js
// ══════════════════════════════════════════
replaceExact('src/index.js', [
[
'index.js — remove banner auto-publish cron block',
`// ── Scheduled Banner Auto-Publish Cron (runs every minute) ──
const cron = require('node-cron');
cron.schedule('* * * * *', async () => {
  try {
    const mongoose = require('mongoose');
    if (mongoose.connection.readyState !== 1) return;
    let BannerModel;
    try { BannerModel = mongoose.model('Banner'); } catch(e) { return; }
    const now = new Date();
    const toPublish = await BannerModel.find({
      published: false,
      scheduledAt: { $lte: now, $exists: true, $ne: null }
    });
    for (const b of toPublish) {
      b.published = true;
      await b.save();
      console.log('Auto-published banner:', b.title, 'at', now.toISOString());
    }
  } catch(e) { /* silent — cron errors should not crash server */ }
});

`,
``
],
[
'index.js — remove bannerGeneratorRoutes require',
`const bannerGeneratorRoutes = require('./routes/bannerGenerator');
`,
``
],
[
'index.js — remove bannerGeneratorRoutes mount',
`app.use('/api/admin/banners', bannerGeneratorRoutes);
`,
``
]
]);

// ══════════════════════════════════════════
// B) REMOVE from frontend/app/admin/x7k2p/page.tsx
// ══════════════════════════════════════════
replaceExact('frontend/app/admin/x7k2p/page.tsx', [
[
'page.tsx — remove sidebar NAV entry',
`  {id:'store',ico:'🛒',lbl:'Store Management',grp:'Tools'},
    {id:'creative_studio',ico:'🖼️',lbl:'Banner Management',grp:'Settings',alwaysShow:true},
  ]`,
`  {id:'store',ico:'🛒',lbl:'Store Management',grp:'Tools'},
  ]`
],
[
'page.tsx — remove _setTab redirect override, use direct setter',
`const _setTab=(id:string)=>{if(id==='creative_studio'){window.location.href='/admin/x7k2p/banner-generator';return;}_setTab_orig(id);}`,
`const _setTab=(id:string)=>{_setTab_orig(id);}`
],
[
'page.tsx — remove dead Generate Banner button in legacy BatchDetailOverlay',
` <button onClick={()=>{const url='/admin/x7k2p/banner-generator?batchId='+batch._id+'&batchName='+encodeURIComponent(batch.name);window.location.href=url;}} style={{padding:'6px 12px',background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(0,212,255,0.1))',border:'1px solid rgba(77,159,255,0.3)',borderRadius:8,color:'#4D9FFF',cursor:'pointer',fontSize:10,fontWeight:700,whiteSpace:'nowrap'}}>🎨 Generate Banner</button>`,
``
],
[
'page.tsx — remove dead banner-generator TABS entry in legacy overlay',
`    {id:'banner-generator',label:'🖼️ Banner Management',href:'/admin/x7k2p/banner-generator'},
`,
``
]
]);

// ══════════════════════════════════════════
// C) src/routes/batchManagerUltra.js — add Banner routes
// ══════════════════════════════════════════
const batchBannerRoutes = `
// ══════════════════════════════════════════════════════════════════
// BANNER MANAGEMENT TAB — batch-scoped banner only (no global list).
// Publish/Launch is intentionally NOT done here — reserved for a
// future Publish Center. This tab only manages the ONE banner linked
// to this batch: create/auto-generate/edit/sync/version/analyze.
// ══════════════════════════════════════════════════════════════════
function computeBannerQualityScore(b) {
  let score = 0;
  if (b.title && b.title.trim()) score += 20;
  if (b.ctaText && b.ctaText.trim()) score += 15;
  if (b.price && String(b.price).trim()) score += 15;
  if (b.tagline && b.tagline.trim()) score += 10;
  if (b.highlights && b.highlights.filter(Boolean).length >= 2) score += 15;
  if (b.bgImage && b.bgImage.trim()) score += 10;
  if (b.template) score += 10;
  if (b.primaryColor && b.accentColor) score += 5;
  return Math.min(100, score);
}
function buildBannerSyncFields(batch) {
  let validity, duration;
  if (batch.startDate && batch.endDate) {
    const days = Math.max(1, Math.round((new Date(batch.endDate) - new Date(batch.startDate)) / 86400000));
    validity = new Date(batch.startDate).toLocaleDateString() + ' → ' + new Date(batch.endDate).toLocaleDateString();
    duration = days + ' days';
  } else {
    const days = batch.validity || 365;
    validity = days + ' days';
    duration = days + ' days';
  }
  const eff = (batch.discountPrice && (!batch.discountValidTill || new Date(batch.discountValidTill) >= new Date())) ? batch.discountPrice : (batch.price || 0);
  return {
    batchName: batch.name || '',
    title: batch.name || '',
    examType: batch.examType || 'NEET',
    price: String(eff || 0),
    totalTests: String(batch.totalTests || 0),
    validity, duration,
    highlights: [
      (batch.totalTests || 0) + ' Practice Tests',
      duration + ' Validity',
      batch.language || 'Hindi + English'
    ],
    badge: batch.isSpotlight ? 'trending' : 'none'
  };
}
function checkBannerSyncState(banner, batch) {
  if (banner.syncState === 'manual_override') return 'manual_override';
  const live = buildBannerSyncFields(batch);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  return mismatch ? 'pending_sync' : 'synced';
}
async function logBannerAudit({ bannerId, action, oldValue, newValue, performedBy, performedByName, linkedType, linkedBatchId, reason }) {
  try {
    await BannerAuditLog.create({ bannerId, action, oldValue, newValue, performedBy, performedByName: performedByName || 'Admin', linkedType, linkedBatchId, reason: reason || '', timestamp: new Date() });
  } catch (e) { /* audit must never break main flow */ }
}

router.get('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    const syncPreview = buildBannerSyncFields(batch);
    if (!banner) return res.json({ banner: null, overview: { status: 'none', readiness: 'banner_required' }, syncPreview, batchName: batch.name });
    const liveSyncState = checkBannerSyncState(banner, batch);
    const qualityScore = banner.qualityScore || computeBannerQualityScore(banner);
    res.json({
      banner: { ...banner, syncState: liveSyncState, qualityScore },
      overview: {
        status: banner.status, lastUpdated: banner.updatedAt,
        draftState: banner.status === 'draft' ? 'Draft' : banner.status === 'ready' ? 'Ready' : banner.status,
        qualityScore, syncState: liveSyncState,
        recentVersion: banner.versions && banner.versions.length ? banner.versions[banner.versions.length - 1] : null,
        readiness: qualityScore >= 60 && banner.status !== 'draft' ? 'ready' : 'incomplete'
      },
      syncPreview, batchName: batch.name
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/auto-generate', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const existing = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } });
    if (existing) return res.status(409).json({ error: 'A banner already exists for this batch. Edit or replace it instead.' });
    const fields = buildBannerSyncFields(batch);
    const banner = await Banner.create({
      ...fields, batchId: String(req.params.id),
      tagline: '', ctaText: 'Enroll Now', template: 'classic',
      primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
      fontStyle: 'modern', bgImage: '', published: false,
      linkedType: 'batch', linkedBatchId: req.params.id, status: 'draft', syncState: 'synced',
      createdBy: req.user.id
    });
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'created', newValue: { title: banner.title }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    if (banner.status === 'published' && !req.body.forceUnlock) {
      const lockedFields = ['title', 'price', 'examType'];
      const touchingLocked = lockedFields.some(f => req.body[f] !== undefined && req.body[f] !== banner[f]);
      if (touchingLocked) return res.status(423).json({ error: 'Banner is published — critical fields are locked. Use forceUnlock to override.' });
    }
    const versionSnap = banner.toObject();
    delete versionSnap._id; delete versionSnap.versions; delete versionSnap.__v;
    banner.versions = banner.versions || [];
    banner.versions.push({ data: versionSnap, savedAt: new Date(), label: 'v' + (banner.versions.length + 1) });
    const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage'];
    for (const f of editable) { if (req.body[f] !== undefined) banner[f] = req.body[f]; }
    if (req.body.markReady) banner.status = 'ready';
    else if (req.body.saveAsDraft) banner.status = 'draft';
    banner.syncState = 'manual_override';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'edited', linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/sync', auth, isAdmin, async (req, res) => {
  try {
    const batch = await Batch.findById(req.params.id).lean();
    if (!batch) return res.status(404).json({ error: 'Batch not found' });
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    const oldVal = { title: banner.title, price: banner.price };
    const fields = buildBannerSyncFields(batch);
    Object.assign(banner, fields);
    banner.syncState = 'synced';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'synced', oldValue: oldVal, newValue: { title: banner.title, price: banner.price }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const orig = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!orig) return res.status(404).json({ error: 'No banner found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false; orig.status = 'draft'; orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    orig.linkedType = 'none'; orig.linkedBatchId = null;
    const dup = await Banner.create(orig);
    await logBannerAudit({ bannerId: dup._id, action: 'duplicated', oldValue: { from: req.params.id }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/remove', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    banner.status = 'removed';
    banner.removedAt = new Date();
    banner.published = false;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'removed', reason: req.body.reason, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-removed', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: 'removed' }).sort({ removedAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No removed banner found' });
    banner.status = 'draft';
    banner.removedAt = null;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'restored_from_removed', linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/replace', auth, isAdmin, async (req, res) => {
  try {
    const old = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!old) return res.status(404).json({ error: 'No banner found to replace' });
    const oldObj = old.toObject();
    delete oldObj._id; delete oldObj.createdAt; delete oldObj.updatedAt; delete oldObj.versions; delete oldObj.__v;
    const replacement = await Banner.create({
      ...oldObj, ...req.body, status: 'draft', published: false, replacedFrom: old._id,
      linkedType: 'batch', linkedBatchId: req.params.id,
      versions: [], analytics: { views: 0, clicks: 0, enrolls: 0 }
    });
    old.status = 'replaced';
    old.replacedBy = replacement._id;
    old.published = false;
    await old.save();
    await logBannerAudit({ bannerId: replacement._id, action: 'replaced', oldValue: { replacedFrom: old._id }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: replacement });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: 'batch', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/analytics', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return res.json({ analytics: null });
    const a = banner.analytics || { views: 0, clicks: 0, enrolls: 0 };
    res.json({ analytics: { views: a.views || 0, clicks: a.clicks || 0, enrolls: a.enrolls || 0, clickRate: a.views ? +((a.clicks / a.views) * 100).toFixed(1) : 0, conversionRate: a.views ? +((a.enrolls / a.views) * 100).toFixed(1) : 0, template: banner.template, ctaText: banner.ctaText } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/track', async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'batch', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.json({ success: false });
    const { type } = req.body;
    const inc = {};
    if (type === 'view') inc['analytics.views'] = 1;
    if (type === 'click') inc['analytics.clicks'] = 1;
    if (type === 'enroll') inc['analytics.enrolls'] = 1;
    if (Object.keys(inc).length) await Banner.findByIdAndUpdate(banner._id, { $inc: inc });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/audit', auth, isAdmin, async (req, res) => {
  try {
    const audit = await BannerAuditLog.find({ linkedType: 'batch', linkedBatchId: req.params.id }).sort({ timestamp: -1 }).limit(100).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`;

replaceExact('src/routes/batchManagerUltra.js', [
[
'batchManagerUltra — import Banner models',
`const Coupon   = require('../models/Coupon');`,
`const Coupon   = require('../models/Coupon');
const Banner   = require('../models/Banner');
const BannerAuditLog = require('../models/BannerAuditLog');`
],
[
'batchManagerUltra — insert banner routes before CONTROLS TAB',
`
// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`,
batchBannerRoutes + `// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`
]
]);

// ══════════════════════════════════════════
// D) src/routes/testSeriesManagerUltra.js — add Banner routes (mirror)
// ══════════════════════════════════════════
const seriesBannerRoutes = `
// ══════════════════════════════════════════════════════════════════
// BANNER MANAGEMENT TAB — series-scoped banner only (no global list).
// Publish/Launch is intentionally NOT done here — reserved for a
// future Publish Center. This tab only manages the ONE banner linked
// to this series: create/auto-generate/edit/sync/version/analyze.
// ══════════════════════════════════════════════════════════════════
function computeBannerQualityScore(b) {
  let score = 0;
  if (b.title && b.title.trim()) score += 20;
  if (b.ctaText && b.ctaText.trim()) score += 15;
  if (b.price && String(b.price).trim()) score += 15;
  if (b.tagline && b.tagline.trim()) score += 10;
  if (b.highlights && b.highlights.filter(Boolean).length >= 2) score += 15;
  if (b.bgImage && b.bgImage.trim()) score += 10;
  if (b.template) score += 10;
  if (b.primaryColor && b.accentColor) score += 5;
  return Math.min(100, score);
}
function buildBannerSyncFields(series) {
  let validity, duration;
  if (series.startDate && series.endDate) {
    const days = Math.max(1, Math.round((new Date(series.endDate) - new Date(series.startDate)) / 86400000));
    validity = new Date(series.startDate).toLocaleDateString() + ' → ' + new Date(series.endDate).toLocaleDateString();
    duration = days + ' days';
  } else {
    const days = series.validity || 365;
    validity = days + ' days';
    duration = days + ' days';
  }
  const eff = (series.discountPrice && (!series.discountValidTill || new Date(series.discountValidTill) >= new Date())) ? series.discountPrice : (series.price || 0);
  return {
    batchName: series.name || '',
    title: series.name || '',
    examType: series.examType || 'NEET',
    price: String(eff || 0),
    totalTests: String(series.totalTests || 0),
    validity, duration,
    highlights: [
      (series.totalTests || 0) + ' Practice Tests',
      duration + ' Validity',
      series.language || 'Hindi + English'
    ],
    badge: series.isSpotlight ? 'trending' : 'none'
  };
}
function checkBannerSyncState(banner, series) {
  if (banner.syncState === 'manual_override') return 'manual_override';
  const live = buildBannerSyncFields(series);
  const mismatch = banner.title !== live.title || banner.price !== live.price || banner.examType !== live.examType || banner.totalTests !== live.totalTests;
  return mismatch ? 'pending_sync' : 'synced';
}
async function logBannerAudit({ bannerId, action, oldValue, newValue, performedBy, performedByName, linkedType, linkedBatchId, reason }) {
  try {
    await BannerAuditLog.create({ bannerId, action, oldValue, newValue, performedBy, performedByName: performedByName || 'Admin', linkedType, linkedBatchId, reason: reason || '', timestamp: new Date() });
  } catch (e) { /* audit must never break main flow */ }
}

router.get('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    const syncPreview = buildBannerSyncFields(series);
    if (!banner) return res.json({ banner: null, overview: { status: 'none', readiness: 'banner_required' }, syncPreview, batchName: series.name });
    const liveSyncState = checkBannerSyncState(banner, series);
    const qualityScore = banner.qualityScore || computeBannerQualityScore(banner);
    res.json({
      banner: { ...banner, syncState: liveSyncState, qualityScore },
      overview: {
        status: banner.status, lastUpdated: banner.updatedAt,
        draftState: banner.status === 'draft' ? 'Draft' : banner.status === 'ready' ? 'Ready' : banner.status,
        qualityScore, syncState: liveSyncState,
        recentVersion: banner.versions && banner.versions.length ? banner.versions[banner.versions.length - 1] : null,
        readiness: qualityScore >= 60 && banner.status !== 'draft' ? 'ready' : 'incomplete'
      },
      syncPreview, batchName: series.name
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/auto-generate', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const existing = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } });
    if (existing) return res.status(409).json({ error: 'A banner already exists for this test series. Edit or replace it instead.' });
    const fields = buildBannerSyncFields(series);
    const banner = await Banner.create({
      ...fields, batchId: String(req.params.id),
      tagline: '', ctaText: 'Enroll Now', template: 'classic',
      primaryColor: '#4D9FFF', secondaryColor: '#00D4FF', textColor: '#FFFFFF', accentColor: '#FFD700',
      fontStyle: 'modern', bgImage: '', published: false,
      linkedType: 'series', linkedBatchId: req.params.id, status: 'draft', syncState: 'synced',
      createdBy: req.user.id
    });
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'created', newValue: { title: banner.title }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put('/:id/banner', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    if (banner.status === 'published' && !req.body.forceUnlock) {
      const lockedFields = ['title', 'price', 'examType'];
      const touchingLocked = lockedFields.some(f => req.body[f] !== undefined && req.body[f] !== banner[f]);
      if (touchingLocked) return res.status(423).json({ error: 'Banner is published — critical fields are locked. Use forceUnlock to override.' });
    }
    const versionSnap = banner.toObject();
    delete versionSnap._id; delete versionSnap.versions; delete versionSnap.__v;
    banner.versions = banner.versions || [];
    banner.versions.push({ data: versionSnap, savedAt: new Date(), label: 'v' + (banner.versions.length + 1) });
    const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage'];
    for (const f of editable) { if (req.body[f] !== undefined) banner[f] = req.body[f]; }
    if (req.body.markReady) banner.status = 'ready';
    else if (req.body.saveAsDraft) banner.status = 'draft';
    banner.syncState = 'manual_override';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'edited', linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/sync', auth, isAdmin, async (req, res) => {
  try {
    const series = await TestSeries.findById(req.params.id).lean();
    if (!series) return res.status(404).json({ error: 'Test series not found' });
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found. Auto-generate a draft first.' });
    const oldVal = { title: banner.title, price: banner.price };
    const fields = buildBannerSyncFields(series);
    Object.assign(banner, fields);
    banner.syncState = 'synced';
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'synced', oldValue: oldVal, newValue: { title: banner.title, price: banner.price }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/duplicate', auth, isAdmin, async (req, res) => {
  try {
    const orig = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!orig) return res.status(404).json({ error: 'No banner found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    orig.title = orig.title + ' (Copy)';
    orig.published = false; orig.status = 'draft'; orig.versions = [];
    orig.analytics = { views: 0, clicks: 0, enrolls: 0 };
    orig.linkedType = 'none'; orig.linkedBatchId = null;
    const dup = await Banner.create(orig);
    await logBannerAudit({ bannerId: dup._id, action: 'duplicated', oldValue: { from: req.params.id }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/remove', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    banner.status = 'removed';
    banner.removedAt = new Date();
    banner.published = false;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'removed', reason: req.body.reason, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-removed', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: 'removed' }).sort({ removedAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No removed banner found' });
    banner.status = 'draft';
    banner.removedAt = null;
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'restored_from_removed', linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/replace', auth, isAdmin, async (req, res) => {
  try {
    const old = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!old) return res.status(404).json({ error: 'No banner found to replace' });
    const oldObj = old.toObject();
    delete oldObj._id; delete oldObj.createdAt; delete oldObj.updatedAt; delete oldObj.versions; delete oldObj.__v;
    const replacement = await Banner.create({
      ...oldObj, ...req.body, status: 'draft', published: false, replacedFrom: old._id,
      linkedType: 'series', linkedBatchId: req.params.id,
      versions: [], analytics: { views: 0, clicks: 0, enrolls: 0 }
    });
    old.status = 'replaced';
    old.replacedBy = replacement._id;
    old.published = false;
    await old.save();
    await logBannerAudit({ bannerId: replacement._id, action: 'replaced', oldValue: { replacedFrom: old._id }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner: replacement });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: 'series', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/analytics', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 }).lean();
    if (!banner) return res.json({ analytics: null });
    const a = banner.analytics || { views: 0, clicks: 0, enrolls: 0 };
    res.json({ analytics: { views: a.views || 0, clicks: a.clicks || 0, enrolls: a.enrolls || 0, clickRate: a.views ? +((a.clicks / a.views) * 100).toFixed(1) : 0, conversionRate: a.views ? +((a.enrolls / a.views) * 100).toFixed(1) : 0, template: banner.template, ctaText: banner.ctaText } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/track', async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: 'series', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.json({ success: false });
    const { type } = req.body;
    const inc = {};
    if (type === 'view') inc['analytics.views'] = 1;
    if (type === 'click') inc['analytics.clicks'] = 1;
    if (type === 'enroll') inc['analytics.enrolls'] = 1;
    if (Object.keys(inc).length) await Banner.findByIdAndUpdate(banner._id, { $inc: inc });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/:id/banner/audit', auth, isAdmin, async (req, res) => {
  try {
    const audit = await BannerAuditLog.find({ linkedType: 'series', linkedBatchId: req.params.id }).sort({ timestamp: -1 }).limit(100).lean();
    res.json({ audit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

`;

replaceExact('src/routes/testSeriesManagerUltra.js', [
[
'testSeriesManagerUltra — import Banner models',
`const Coupon   = require('../models/Coupon');`,
`const Coupon   = require('../models/Coupon');
const Banner   = require('../models/Banner');
const BannerAuditLog = require('../models/BannerAuditLog');`
],
[
'testSeriesManagerUltra — insert banner routes before CONTROLS TAB',
`
// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`,
seriesBannerRoutes + `// ══════════════════════════════════════════════════════════════════
// CONTROLS TAB — system control center
// ══════════════════════════════════════════════════════════════════
router.get('/:id/controls', auth, isAdmin, async (req, res) => {`
]
]);

console.log('✅ Backend + admin page.tsx patched');
NODEEOF

node /tmp/fix_banner_tab.js

# ══════════════════════════════════════════════════════════════════
# STEP 2 — Delete old global banner files
# ══════════════════════════════════════════════════════════════════
if [ -d "$OLD_BANNER_PAGE_DIR" ]; then
  rm -rf "$OLD_BANNER_PAGE_DIR"
  echo "✅ Deleted $OLD_BANNER_PAGE_DIR"
fi
if [ -f "$OLD_BANNER_ROUTE" ]; then
  rm -f "$OLD_BANNER_ROUTE"
  echo "✅ Deleted $OLD_BANNER_ROUTE"
fi

echo ""
echo "=== STEP 1-2 verification ==="
grep -n "banner-generator\|creative_studio\|bannerGeneratorRoutes" "$ADMIN_PAGE" "$INDEX_JS" && echo "⚠️ Some references still remain — check above" || echo "✅ Clean — no old global banner references left"

echo ""
echo "✅ Backend + removal steps DONE. Frontend BannerManagementTab (Batch + TestSeries) script part 2 follows separately due to size — run that next."
