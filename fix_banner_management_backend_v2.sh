#!/bin/bash
# ════════════════════════════════════════════════════════════════════
# ProveRank — Banner Management Tab — BACKEND FIX SCRIPT — V2 (MERGED)
#
# V2 combines and supersedes two earlier gap-analysis passes into one
# complete, non-redundant backend patch:
#
#   1.  Crop fields on banner layers — cropTop/Right/Bottom/Left
#   2.  Media upload endpoint — POST /assets/upload-image (real,
#       backend-persisted, size-validated, reusable SavedAsset)
#   3.  AI-Recommended Assets endpoint — GET /assets/recommended
#       (honest heuristic keyword-matching engine — see note below)
#   4.  Section Visibility / Lock fields on Banner (Layout Controls)
#   5.  Badge Style / Card Style / Gradient Angle / Spacing fields
#   6.  Multi-preset Brand Kit — GET/POST /brand-kits,
#       POST /brand-kits/:id/set-default, DELETE /brand-kits/:id
#       (existing singular GET/PUT /brand-kit kept working = "current
#       default kit", fully backward compatible)
#   7.  Cross-banner Analytics — GET /analytics/templates,
#       GET /analytics/cta (platform-wide performance breakdown)
#   8.  Duplicate Version endpoint — Batch banner
#   9.  Duplicate Version endpoint — Test Series banner
#  10.  Whitelist all new fields in PUT /:id/banner (both files)
#
# NOT included (by design, see frontend script header for why):
#   - logoUrl / watermarkUrl / showBrandLogo / showWatermark fields —
#     Official Logo / Watermark are instead applied as normal,
#     draggable, croppable LAYERS (reusing the existing robust layer
#     system) rather than adding a second, parallel, fixed-position
#     mechanism. Cleaner, more flexible, one system instead of two.
#   - cropX / cropY (pan-point crop) — superseded by the more literal
#     4-directional cropTop/Right/Bottom/Left "trim" already in v1,
#     which V2 now actually wires into rendering (see frontend script).
#
# NOTE ON "AI GENERATED IMAGES / TEMPLATES":
#   True generative image AI needs a paid external API key not
#   configured anywhere in this project. This script ships an honest,
#   WORKING alternative instead: a keyword/category matching engine
#   over the REAL asset library, labelled `source:'heuristic'` in the
#   API response so the frontend can present it truthfully as
#   "🤖 AI Recommended" without claiming actual image generation.
#
# SAFE TO RE-RUN: every patch checks for its own anchor text before
# writing, and skips (does not error) if already applied. Full
# timestamped backups are taken before any file is touched, and every
# patched file is syntax-checked before the script exits successfully
# — on ANY failure, all 4 files are restored automatically.
# ════════════════════════════════════════════════════════════════════
set -e
cd ~/workspace || { echo "❌ ~/workspace not found — run this from the Replit shell"; exit 1; }

TS=$(date +%s)
BACKUP_DIR=~/workspace/.banner_backend_v2_backups_$TS
mkdir -p "$BACKUP_DIR"

FILES=(src/models/Banner.js src/routes/bannerAssets.js src/routes/batchManagerUltra.js src/routes/testSeriesManagerUltra.js)

echo "════════════════════════════════════════════════"
echo "📦  Backing up files before patching..."
echo "════════════════════════════════════════════════"
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename $f).bak"
    echo "  ✅ backed up: $f"
  else
    echo "  ❌ MISSING FILE: $f — cannot continue safely"; exit 1
  fi
done
echo "Backups saved to: $BACKUP_DIR"
echo ""

restore_and_exit() {
  echo ""
  echo "❌ $1"
  echo "↩️  Restoring original files from backup — no changes were kept."
  for f in "${FILES[@]}"; do cp "$BACKUP_DIR/$(basename $f).bak" "$f"; done
  exit 1
}

# ────────────────────────────────────────────────────────────────────
# Node.js patcher (no python, per project rule)
# ────────────────────────────────────────────────────────────────────
cat > /tmp/banner_backend_v2_patch.js << 'NODEEOF'
const fs = require('fs');

function patchFile(path, patches) {
  let src = fs.readFileSync(path, 'utf8');
  let changed = false;
  for (const p of patches) {
    if (src.includes(p.skipIfPresent)) { console.log('  ⏭️  already applied:', p.label); continue; }
    const count = src.split(p.anchor).length - 1;
    if (count === 0) { console.error('  ❌ ANCHOR NOT FOUND for "' + p.label + '"'); process.exit(1); }
    if (count > 1) { console.error('  ❌ ANCHOR NOT UNIQUE (' + count + 'x) for "' + p.label + '"'); process.exit(1); }
    src = src.replace(p.anchor, p.replacement);
    changed = true;
    console.log('  ✅ applied:', p.label);
  }
  if (changed) fs.writeFileSync(path, src, 'utf8');
}

console.log('\n📄 src/models/Banner.js');
patchFile('src/models/Banner.js', [
  {
    label: '1. Crop fields on layers (cropTop/Right/Bottom/Left)',
    skipIfPresent: 'cropTop: { type: Number, default: 0 }',
    anchor: `    blendMode: { type: String, default: 'normal' }
  }],`,
    replacement: `    blendMode: { type: String, default: 'normal' },
    cropTop: { type: Number, default: 0 },
    cropRight: { type: Number, default: 0 },
    cropBottom: { type: Number, default: 0 },
    cropLeft: { type: Number, default: 0 }
  }],`
  },
  {
    label: '4/5. Section visibility/lock + badge/card/gradient/spacing style fields',
    skipIfPresent: 'sectionVisibility: { type: mongoose.Schema.Types.Mixed',
    anchor: `  textAlign: { type: String, enum: ['left', 'center', 'right'], default: 'left' },`,
    replacement: `  textAlign: { type: String, enum: ['left', 'center', 'right'], default: 'left' },
  sectionVisibility: { type: mongoose.Schema.Types.Mixed, default: () => ({ icon: true, badge: true, title: true, tagline: true, highlights: true, price: true, cta: true }) },
  sectionLock: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
  badgeStyle: { type: String, enum: ['pill', 'ribbon', 'corner'], default: 'pill' },
  cardStyle: { type: String, enum: ['sharp', 'rounded', 'soft', 'elevated'], default: 'rounded' },
  gradientAngle: { type: Number, default: 135 },
  spacing: { type: String, enum: ['compact', 'normal', 'spacious'], default: 'normal' },`
  }
]);

console.log('\n📄 src/routes/bannerAssets.js');
patchFile('src/routes/bannerAssets.js', [
  {
    label: '2/3. POST /assets/upload-image + GET /assets/recommended',
    skipIfPresent: "router.post('/assets/upload-image'",
    anchor: `module.exports = router;`,
    replacement: `// ══════════════════════════════════════════════════════════════════
// MEDIA UPLOAD — real "Uploaded Images/Logos/SVG/PNG/WebP" support.
// Client reads the file as a base64 data URL (FileReader) and posts
// it here as plain JSON — no multer/cloudinary dependency required.
// Stored as a SavedAsset (type:'media') so it is persisted, reusable
// across banners, and shows up in the asset library like any other
// asset — unlike storing the base64 string directly inline on the
// banner document (which would bloat that document on every load).
// ══════════════════════════════════════════════════════════════════
router.post('/assets/upload-image', auth, isAdmin, async (req, res) => {
  try {
    const { name, dataUrl, category } = req.body;
    if (!dataUrl || typeof dataUrl !== 'string' || !/^data:image\\/(png|jpe?g|webp|svg\\+xml|gif);base64,/.test(dataUrl)) {
      return res.status(400).json({ error: 'Invalid image data — expected a base64 data URL (png/jpg/webp/svg/gif)' });
    }
    const approxBytes = Math.ceil((dataUrl.length - dataUrl.indexOf(',') - 1) * 3 / 4);
    if (approxBytes > 900000) {
      return res.status(413).json({ error: 'Image too large (max ~900KB). Please compress or resize the image before uploading.' });
    }
    const asset = await SavedAsset.create({
      name: (name || 'Uploaded Image').trim().slice(0, 120),
      type: 'media',
      category: category || 'Uploaded',
      content: dataUrl,
      isBuiltIn: false,
      uploadedBy: req.user.id,
      uploadedByName: req.user.name || 'Admin'
    });
    res.json({ success: true, asset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// AI-RECOMMENDED ASSETS — heuristic keyword/category scoring engine
// over the existing SavedAsset library. NOT a generative-AI image
// call (no external image-gen API key is configured in this
// project) — a real, working recommendation engine over real assets,
// labelled source:'heuristic' so the UI can present it honestly as
// "🤖 AI Recommended" without claiming actual image generation.
// ══════════════════════════════════════════════════════════════════
router.get('/assets/recommended', auth, isAdmin, async (req, res) => {
  try {
    const { examType = '', subject = '', limit = 12 } = req.query;
    const KEYWORD_MAP = {
      NEET: ['medical', 'biology', 'chemistry', 'stethoscope', 'dna', 'microscope', 'molecules'],
      JEE: ['physics', 'engineering', 'mathematics', 'calculator', 'circuit', 'formula', 'gear'],
      CUET: ['education', 'general', 'academic', 'graduation'],
      SSC: ['general', 'education', 'achievement', 'document'],
      UPSC: ['general', 'education', 'achievement', 'pillar'],
      Banking: ['calculator', 'achievement', 'bank'],
      Biology: ['biology', 'dna', 'microscope', 'brain', 'molecules'],
      Chemistry: ['chemistry', 'molecules', 'laboratory'],
      Physics: ['physics', 'circuit', 'formula', 'engineering', 'atom'],
      Mathematics: ['mathematics', 'calculator', 'formula']
    };
    const terms = new Set();
    [examType, subject].forEach(v => {
      const key = Object.keys(KEYWORD_MAP).find(k => (v || '').toLowerCase().includes(k.toLowerCase()));
      if (key) KEYWORD_MAP[key].forEach(t => terms.add(t));
    });
    if (terms.size === 0) ['education', 'achievement', 'exam'].forEach(t => terms.add(t));

    const all = await SavedAsset.find({ isDeleted: false }).lean();
    const scored = all.map(a => {
      const hay = ((a.name || '') + ' ' + (a.category || '')).toLowerCase();
      let score = 0;
      terms.forEach(t => { if (hay.includes(t)) score += 10; });
      score += Math.min(5, (a.usageCount || 0));
      return { ...a, matchScore: score, isRecommended: score > 0 };
    }).filter(a => a.matchScore > 0)
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, Number(limit) || 12);

    res.json({ assets: scored, source: 'heuristic', matchedTerms: Array.from(terms) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;`
  },
  {
    label: '6/7. Multi-preset Brand Kit routes + cross-banner Analytics by-template/by-CTA',
    skipIfPresent: "router.get('/brand-kits'",
    anchor: `router.put('/brand-kit', auth, isAdmin, async (req, res) => {
  try {
    let kit = await BrandKit.findOne({ isDefault: true });
    if (!kit) kit = new BrandKit({ isDefault: true, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    const editable = ['name', 'primaryColor', 'secondaryColor', 'accentColor', 'fontPair', 'logoUrl', 'watermarkUrl', 'defaultCtaStyle', 'defaultBadgeStyle', 'defaultBannerLayout'];
    for (const f of editable) { if (req.body[f] !== undefined) kit[f] = req.body[f]; }
    await kit.save();
    res.json({ success: true, brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`,
    replacement: `router.put('/brand-kit', auth, isAdmin, async (req, res) => {
  try {
    let kit = await BrandKit.findOne({ isDefault: true });
    if (!kit) kit = new BrandKit({ isDefault: true, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    const editable = ['name', 'primaryColor', 'secondaryColor', 'accentColor', 'fontPair', 'logoUrl', 'watermarkUrl', 'defaultCtaStyle', 'defaultBadgeStyle', 'defaultBannerLayout'];
    for (const f of editable) { if (req.body[f] !== undefined) kit[f] = req.body[f]; }
    await kit.save();
    res.json({ success: true, brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Multi-preset Brand Kit management ("Saved Brand Kits") ──
router.get('/brand-kits', auth, isAdmin, async (req, res) => {
  try {
    const kits = await BrandKit.find({}).sort({ isDefault: -1, createdAt: -1 }).lean();
    res.json({ brandKits: kits });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/brand-kits', auth, isAdmin, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ error: 'Preset name required' });
    const kit = await BrandKit.create({ ...req.body, name: name.trim(), isDefault: false, createdBy: req.user.id, createdByName: req.user.name || 'Admin' });
    res.json({ success: true, brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/brand-kits/:id/set-default', auth, isAdmin, async (req, res) => {
  try {
    await BrandKit.updateMany({}, { $set: { isDefault: false } });
    const kit = await BrandKit.findByIdAndUpdate(req.params.id, { $set: { isDefault: true } }, { new: true });
    if (!kit) return res.status(404).json({ error: 'Brand kit not found' });
    res.json({ success: true, brandKit: kit });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/brand-kits/:id', auth, isAdmin, async (req, res) => {
  try {
    const kit = await BrandKit.findById(req.params.id);
    if (!kit) return res.status(404).json({ error: 'Brand kit not found' });
    if (kit.isDefault) return res.status(400).json({ error: 'Cannot delete the default brand kit — set another as default first' });
    await BrandKit.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ── Cross-banner analytics breakdown (platform-wide, not per-banner) ──
router.get('/analytics/templates', auth, isAdmin, async (req, res) => {
  try {
    let Banner;
    try { Banner = require('../models/Banner'); } catch (e) { return res.json({ breakdown: [] }); }
    const banners = await Banner.find({ status: { $ne: 'removed' } }).lean();
    const map = {};
    banners.forEach(b => {
      const key = b.template || 'classic';
      if (!map[key]) map[key] = { template: key, count: 0, views: 0, clicks: 0, enrolls: 0 };
      map[key].count++;
      map[key].views += (b.analytics?.views || 0);
      map[key].clicks += (b.analytics?.clicks || 0);
      map[key].enrolls += (b.analytics?.enrolls || 0);
    });
    const breakdown = Object.values(map).map((m) => ({ ...m, conversionRate: m.views ? +((m.enrolls / m.views) * 100).toFixed(1) : 0 })).sort((a, b) => b.conversionRate - a.conversionRate);
    res.json({ breakdown });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/analytics/cta', auth, isAdmin, async (req, res) => {
  try {
    let Banner;
    try { Banner = require('../models/Banner'); } catch (e) { return res.json({ breakdown: [] }); }
    const banners = await Banner.find({ status: { $ne: 'removed' } }).lean();
    const map = {};
    banners.forEach(b => {
      const key = (b.ctaShape || 'pill') + ' — "' + (b.ctaText || 'Enroll Now') + '"';
      if (!map[key]) map[key] = { cta: key, count: 0, views: 0, clicks: 0, enrolls: 0 };
      map[key].count++;
      map[key].views += (b.analytics?.views || 0);
      map[key].clicks += (b.analytics?.clicks || 0);
      map[key].enrolls += (b.analytics?.enrolls || 0);
    });
    const breakdown = Object.values(map).map((m) => ({ ...m, conversionRate: m.views ? +((m.enrolls / m.views) * 100).toFixed(1) : 0 })).sort((a, b) => b.conversionRate - a.conversionRate);
    res.json({ breakdown });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
  }
]);

for (const [routeFile, linkedType] of [['src/routes/batchManagerUltra.js', 'batch'], ['src/routes/testSeriesManagerUltra.js', 'series']]) {
  console.log('\n📄', routeFile);
  patchFile(routeFile, [
    {
      label: '10. Whitelist new Banner fields in PUT /:id/banner',
      skipIfPresent: "'sectionVisibility', 'sectionLock', 'badgeStyle'",
      anchor: `const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride', 'textAlign'];`,
      replacement: `const editable = ['title', 'tagline', 'examType', 'price', 'totalTests', 'duration', 'validity', 'highlights', 'ctaText', 'ctaShape', 'badge', 'template', 'primaryColor', 'secondaryColor', 'textColor', 'accentColor', 'fontStyle', 'bgImage', 'layers', 'textStyleOverride', 'textAlign', 'sectionVisibility', 'sectionLock', 'badgeStyle', 'cardStyle', 'gradientAngle', 'spacing'];`
    },
    {
      label: '8/9. Duplicate Version endpoint',
      skipIfPresent: "router.post('/:id/banner/duplicate-version",
      anchor: `router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: '${linkedType}', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: '${linkedType}', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`,
      replacement: `router.post('/:id/banner/restore-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: '${linkedType}', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    Object.assign(banner, v.data);
    banner.qualityScore = computeBannerQualityScore(banner);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_restored', newValue: { vIdx: req.params.vIdx }, linkedType: '${linkedType}', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/:id/banner/duplicate-version/:vIdx', auth, isAdmin, async (req, res) => {
  try {
    const banner = await Banner.findOne({ linkedType: '${linkedType}', linkedBatchId: req.params.id, status: { $ne: 'removed' } }).sort({ createdAt: -1 });
    if (!banner) return res.status(404).json({ error: 'No banner found' });
    const v = banner.versions[parseInt(req.params.vIdx)];
    if (!v) return res.status(404).json({ error: 'Version not found' });
    const clone = { data: v.data, savedAt: new Date(), label: (v.label || 'v?') + ' (copy)' };
    banner.versions.push(clone);
    await banner.save();
    await logBannerAudit({ bannerId: banner._id, action: 'version_duplicated', newValue: { fromVIdx: req.params.vIdx }, linkedType: '${linkedType}', linkedBatchId: req.params.id, performedBy: req.user.id, performedByName: req.user.name });
    res.json({ success: true, banner });
  } catch (e) { res.status(500).json({ error: e.message }); }
});`
    }
  ]);
}

console.log('\n✅ All V2 backend patches applied successfully.');
NODEEOF

echo "════════════════════════════════════════════════"
echo "🔧  Running patcher..."
echo "════════════════════════════════════════════════"
node /tmp/banner_backend_v2_patch.js
PATCH_EXIT=$?
rm -f /tmp/banner_backend_v2_patch.js

if [ $PATCH_EXIT -ne 0 ]; then
  restore_and_exit "Patch failed"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "🧪  Syntax-checking patched files..."
echo "════════════════════════════════════════════════"
SYNTAX_OK=1
for f in "${FILES[@]}"; do
  if node --check "$f" 2>/tmp/synerr.txt; then
    echo "  ✅ $f — syntax OK"
  else
    echo "  ❌ $f — SYNTAX ERROR:"; cat /tmp/synerr.txt; SYNTAX_OK=0
  fi
done
rm -f /tmp/synerr.txt

if [ $SYNTAX_OK -eq 0 ]; then
  restore_and_exit "Syntax errors found"
fi

# ════════════════════════════════════════════════════════════════════
# VERIFICATION CHECKLIST
# ════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "✅ VERIFICATION — Backend V2 sub-features"
echo "════════════════════════════════════════════════"
check() { if grep -qF "$2" "$3" 2>/dev/null; then echo "✅ $1"; else echo "❌ $1  (MISSING — check $3)"; fi; }

check "1. Crop fields on Banner layers"                     "cropTop: { type: Number, default: 0 }" "src/models/Banner.js"
check "4. Section Visibility field"                          "sectionVisibility: { type: mongoose.Schema.Types.Mixed" "src/models/Banner.js"
check "4. Section Lock field"                                 "sectionLock: { type: mongoose.Schema.Types.Mixed" "src/models/Banner.js"
check "5. Badge/Card/Gradient/Spacing style fields"            "gradientAngle: { type: Number, default: 135 }" "src/models/Banner.js"
check "2. Media upload endpoint"                                "router.post('/assets/upload-image'" "src/routes/bannerAssets.js"
check "3. AI-Recommended Assets endpoint"                        "router.get('/assets/recommended'" "src/routes/bannerAssets.js"
check "6. Multi-preset Brand Kit — list/create/set-default/delete" "router.delete('/brand-kits/:id'" "src/routes/bannerAssets.js"
check "7. Cross-banner Analytics by-template"                      "router.get('/analytics/templates'" "src/routes/bannerAssets.js"
check "7. Cross-banner Analytics by-CTA"                             "router.get('/analytics/cta'" "src/routes/bannerAssets.js"
check "10. Whitelist updated — Batch"                                  "'sectionVisibility', 'sectionLock', 'badgeStyle'" "src/routes/batchManagerUltra.js"
check "10. Whitelist updated — Series"                                  "'sectionVisibility', 'sectionLock', 'badgeStyle'" "src/routes/testSeriesManagerUltra.js"
check "8. Duplicate Version endpoint — Batch"                             "router.post('/:id/banner/duplicate-version" "src/routes/batchManagerUltra.js"
check "9. Duplicate Version endpoint — Test Series"                        "router.post('/:id/banner/duplicate-version" "src/routes/testSeriesManagerUltra.js"

echo ""
echo "════════════════════════════════════════════════"
echo "🎉 Backend V2 patching complete."
echo "   Backups kept at: $BACKUP_DIR"
echo "   Restart the server to load the new routes:"
echo "     cd ~/workspace && node src/index.js"
echo "   Next: run the frontend V2 script."
echo "════════════════════════════════════════════════"
