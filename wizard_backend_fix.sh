#!/bin/bash
# ============================================================================
# ProveRank — Create Batch / Create Test Series Wizard Overhaul (BACKEND)
# - Updates examType enum (new exam list, backward-compatible with old data)
# - Removes discount/trial/bundle/spotlight/auto-archive from CREATE route only
#   (Pricing/Controls tabs on the detail page are untouched — still work as before)
# Run from backend project ROOT on Replit.
# ============================================================================
set -e
echo "🚀 Create Wizard Overhaul — Backend Install Starting..."

BATCH_MODEL=$(find . -type f -iname "Batch.js" -path "*/models/*" -not -path "*/node_modules/*" | head -1)
SERIES_MODEL=$(find . -type f -iname "TestSeries.js" -path "*/models/*" -not -path "*/node_modules/*" | head -1)
BATCH_ROUTE=$(find . -type f -iname "batchManagerUltra.js" -path "*/routes/*" -not -path "*/node_modules/*" | head -1)
SERIES_ROUTE=$(find . -type f -iname "testSeriesManagerUltra.js" -path "*/routes/*" -not -path "*/node_modules/*" | head -1)

for f in "$BATCH_MODEL" "$SERIES_MODEL" "$BATCH_ROUTE" "$SERIES_ROUTE"; do
  if [ -z "$f" ]; then echo "❌ Could not locate one of the required files. Run from backend root."; exit 1; fi
done
echo "📍 $BATCH_MODEL"
echo "📍 $SERIES_MODEL"
echo "📍 $BATCH_ROUTE"
echo "📍 $SERIES_ROUTE"

for f in "$BATCH_MODEL" "$SERIES_MODEL" "$BATCH_ROUTE" "$SERIES_ROUTE"; do
  cp "$f" "$f.pre-wizardfix-bak"
done
echo "📦 Backups created (.pre-wizardfix-bak)"

node -e "
  const fs = require('fs');

  // ---- 1) Batch model: examType enum ----
  let bm = fs.readFileSync('$BATCH_MODEL', 'utf8');
  const bmOld = \"examType:{type:String,default:'NEET',enum:['NEET','NEET UG','JEE','JEE MAINS','JEE ADVANCE','CUET','CUET UG','CUET PG','SSC CGL','IIT JAM','Class 11','Class 12','Foundation','Crash Course','Other']},\";
  const bmNew = \"examType:{type:String,default:'NEET UG',enum:['NEET','NEET UG','NEET PG','JEE','JEE MAINS','JEE ADVANCE','JEE Main','JEE Advanced','CUET','CUET UG','CUET PG','SSC CGL','SSC CHSL','UPSC CSE','NDA','CDS','CAT','CLAT','GATE','IIT JAM','CSIR NET','UGC NET','Railway (RRB)','Banking (IBPS / SBI)','State PSC','Nursing Entrance','Paramedical Entrance','Defence Exams','Class 11','Class 12','Foundation','Crash Course','Other','Other (Custom)']},\";
  if (bm.includes(bmNew)) { console.log('ℹ️  Batch model already updated — skipping'); }
  else if (bm.includes(bmOld)) { bm = bm.replace(bmOld, bmNew); fs.writeFileSync('$BATCH_MODEL', bm); console.log('✅ Batch.js examType enum updated'); }
  else { console.error('❌ Batch.js: examType anchor not found — no changes made. Please check manually.'); process.exit(1); }

  // ---- 2) TestSeries model: examType enum ----
  let sm = fs.readFileSync('$SERIES_MODEL', 'utf8');
  const smOld = \"examType: { type: String, default: 'NEET', enum: ['NEET', 'JEE', 'CUET', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other'] },\";
  const smNew = \"examType: { type: String, default: 'NEET UG', enum: ['NEET', 'NEET UG', 'NEET PG', 'JEE', 'JEE Main', 'JEE Advanced', 'CUET', 'CUET UG', 'CUET PG', 'SSC CGL', 'SSC CHSL', 'UPSC CSE', 'NDA', 'CDS', 'CAT', 'CLAT', 'GATE', 'IIT JAM', 'CSIR NET', 'UGC NET', 'Railway (RRB)', 'Banking (IBPS / SBI)', 'State PSC', 'Nursing Entrance', 'Paramedical Entrance', 'Defence Exams', 'Class 11', 'Class 12', 'Foundation', 'Crash Course', 'Other', 'Other (Custom)'] },\";
  if (sm.includes(smNew)) { console.log('ℹ️  TestSeries model already updated — skipping'); }
  else if (sm.includes(smOld)) { sm = sm.replace(smOld, smNew); fs.writeFileSync('$SERIES_MODEL', sm); console.log('✅ TestSeries.js examType enum updated'); }
  else { console.error('❌ TestSeries.js: examType anchor not found — no changes made. Please check manually.'); process.exit(1); }

  // ---- 3) Batch create route: strip pricing-extras + default-controls ----
  let br = fs.readFileSync('$BATCH_ROUTE', 'utf8');
  const brOld = \"      price: Number(body.price) || 0,\n      discountPrice: body.discountPrice ? Number(body.discountPrice) : undefined,\n      isBundle: !!body.isBundle,\n      bundlePrice: body.bundlePrice ? Number(body.bundlePrice) : undefined,\n      allowFreeTrial: !!body.allowFreeTrial,\n      trialDays: Number(body.trialDays) || 0,\n      isSpotlight: !!body.isSpotlight,\n      autoArchiveAfterEnd: !!body.autoArchiveAfterEnd,\n      lastActivityAt: new Date(),\n      isTemplate: false\n    });\";
  const brNew = \"      price: Number(body.price) || 0,\n      lastActivityAt: new Date(),\n      isTemplate: false\n    });\";
  if (br.includes(brNew) && !br.includes(brOld)) { console.log('ℹ️  batchManagerUltra.js create route already updated — skipping'); }
  else if (br.includes(brOld)) { br = br.replace(brOld, brNew); fs.writeFileSync('$BATCH_ROUTE', br); console.log('✅ batchManagerUltra.js create route cleaned'); }
  else { console.error('❌ batchManagerUltra.js: create-route anchor not found — no changes made. Please check manually.'); process.exit(1); }

  // ---- 4) TestSeries create route: strip pricing-extras + default-controls ----
  let sr = fs.readFileSync('$SERIES_ROUTE', 'utf8');
  const srOld = \"      price: Number(body.price) || 0,\n      discountPrice: body.discountPrice ? Number(body.discountPrice) : undefined,\n      isBundle: !!body.isBundle,\n      bundlePrice: body.bundlePrice ? Number(body.bundlePrice) : undefined,\n      allowFreeTrial: !!body.allowFreeTrial,\n      trialDays: Number(body.trialDays) || 0,\n      isSpotlight: !!body.isSpotlight,\n      autoArchiveAfterEnd: !!body.autoArchiveAfterEnd,\n      lastActivityAt: new Date(),\n      isTemplate: false\n    });\";
  const srNew = \"      price: Number(body.price) || 0,\n      lastActivityAt: new Date(),\n      isTemplate: false\n    });\";
  if (sr.includes(srNew) && !sr.includes(srOld)) { console.log('ℹ️  testSeriesManagerUltra.js create route already updated — skipping'); }
  else if (sr.includes(srOld)) { sr = sr.replace(srOld, srNew); fs.writeFileSync('$SERIES_ROUTE', sr); console.log('✅ testSeriesManagerUltra.js create route cleaned'); }
  else { console.error('❌ testSeriesManagerUltra.js: create-route anchor not found — no changes made. Please check manually.'); process.exit(1); }
"

echo ""
echo "🔍 Validating syntax..."
FAIL=0
for f in "$BATCH_MODEL" "$SERIES_MODEL" "$BATCH_ROUTE" "$SERIES_ROUTE"; do
  if node --check "$f" 2>/tmp/err_$$; then
    echo "  ✅ $f — syntax OK"
  else
    echo "  ❌ $f — SYNTAX ERROR:"; cat /tmp/err_$$
    FAIL=1
  fi
  rm -f /tmp/err_$$
done
if [ "$FAIL" -eq 1 ]; then
  echo "❌ Syntax errors found — restoring backups..."
  for f in "$BATCH_MODEL" "$SERIES_MODEL" "$BATCH_ROUTE" "$SERIES_ROUTE"; do
    cp "$f.pre-wizardfix-bak" "$f"
  done
  exit 1
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "✅ DONE — Backend create-flow updated:"
echo "   • New exam list accepted (both models, backward-compatible)"
echo "   • Discount/Trial/Bundle/Spotlight/Auto-Archive no longer set at creation"
echo "     (still fully usable later via Pricing/Controls tabs — untouched)"
echo "   • New batches/series default to lifecycleStatus:'draft' (hidden from students"
echo "     until you manually Launch/Activate from the batch/series card)"
echo "═══════════════════════════════════════════════"
echo "⚠️  Restart your backend server."
echo "➡️  Next: run the matching FRONTEND wizard-overhaul script."
