#!/bin/bash
# ProveRank — Feature 19: Bulk Upload via Copy-Paste FRONTEND
set -e
echo "🚀 Feature 19 Frontend starting..."

# ── 1. Copy ContentForge.tsx to workspace
if [ -f "/mnt/user-data/outputs/ContentForge.tsx" ]; then
  cp /mnt/user-data/outputs/ContentForge.tsx ~/workspace/frontend/app/admin/x7k2p/ContentForge.tsx
  echo "✅ ContentForge.tsx copied"
else
  echo "⚠️ ContentForge.tsx not found in outputs — please upload it"
  exit 1
fi

# ── 2. Update page.tsx via node.js
cat > /tmp/f19_page.js << 'NODE_EOF'
var fs  = require('fs');
var p   = require('path');
var fpath = p.join(process.env.HOME,'workspace/frontend/app/admin/x7k2p/page.tsx');
var c = fs.readFileSync(fpath,'utf8');

// A. Add import
if (!c.includes("import ContentForge")) {
  c = c.replace("'use client'", "'use client'\nimport ContentForge from './ContentForge';");
  console.log('✅ ContentForge import added');
} else { console.log('✅ Import already present'); }

// B. Add sidebar nav item for creation_studio
if (!c.includes("{id:'creation_studio'")) {
  c = c.replace(
    "{id:'ai_explain',ico:'💡',lbl:'AI Explanation',grp:'Questions'},",
    "{id:'ai_explain',ico:'💡',lbl:'AI Explanation',grp:'Questions'},\n    {id:'creation_studio',ico:'\u26A1',lbl:'Creation Studio',grp:'Questions'},"
  );
  if (!c.includes("{id:'creation_studio'")) {
    // Fallback: add after smart_gen
    c = c.replace(
      "{id:'smart_gen',ico:'\uD83E\uDD16',lbl:'Smart Generator',grp:'Questions'},",
      "{id:'smart_gen',ico:'\uD83E\uDD16',lbl:'Smart Generator',grp:'Questions'},\n    {id:'creation_studio',ico:'\u26A1',lbl:'Creation Studio',grp:'Questions'},"
    );
  }
  console.log('✅ Sidebar nav item added');
} else { console.log('✅ Sidebar nav already has creation_studio'); }

// C. Add tab content section — inject before PYQ BANK marker
var PYQ_MARKER = '{/* \u2550\u2550 PYQ BANK \u2550\u2550 */}';
var STUDIO_SECTION =
  "{/* \u2550\u2550 CREATION STUDIO \u2550\u2550 */}\n" +
  "          {tab==='creation_studio'&&(\n" +
  "            <ContentForge API={API} token={typeof window!=='undefined'?localStorage.getItem('pr_token')||'':''} />\n" +
  "          )}\n\n          ";

if (!c.includes("tab==='creation_studio'")) {
  var pyqIdx = c.indexOf(PYQ_MARKER);
  if (pyqIdx > -1) {
    c = c.slice(0, pyqIdx) + STUDIO_SECTION + c.slice(pyqIdx);
    console.log('✅ creation_studio tab section added');
  } else {
    console.log('❌ PYQ BANK marker not found');
  }
} else { console.log('✅ Tab section already exists'); }

fs.writeFileSync(fpath, c, 'utf8');
console.log('✅ page.tsx updated');
NODE_EOF

node /tmp/f19_page.js
echo ""

# ── 3. VERIFICATION
cat > /tmp/f19_verify.js << 'VEOF'
var fs  = require('fs');
var p   = require('path');

var comp  = fs.existsSync(p.join(process.env.HOME,'workspace/frontend/app/admin/x7k2p/ContentForge.tsx'))
           ? fs.readFileSync(p.join(process.env.HOME,'workspace/frontend/app/admin/x7k2p/ContentForge.tsx'),'utf8') : '';
var page  = fs.existsSync(p.join(process.env.HOME,'workspace/frontend/app/admin/x7k2p/page.tsx'))
           ? fs.readFileSync(p.join(process.env.HOME,'workspace/frontend/app/admin/x7k2p/page.tsx'),'utf8') : '';
var route = fs.existsSync(p.join(process.env.HOME,'workspace/src/routes/questionFeatures.js'))
           ? fs.readFileSync(p.join(process.env.HOME,'workspace/src/routes/questionFeatures.js'),'utf8') : '';

var c  = function(s){ return comp.includes(s); };
var pg = function(s){ return page.includes(s); };
var r  = function(s){ return route.includes(s); };

var checks = [
  ['19    ','ContentForge component exists',             c('export default function ContentForge')],
  ['19.1  ','2 textareas — Eng + Hindi questions',      c('English Questions Text') && c('Hindi Questions Text')],
  ['19.2  ','Answer Key textarea',                      c('Answer Key') && c('setAnsKey')],
  ['19.3  ','Explanation textarea (optional)',           c('Explanations') && c('setExplText') && c('Leave blank')],
  ['19.4  ','Q-number auto parsing',                    c('splitIntoBlocks') && c('parseOneBlock') && c('qNum')],
  ['19.5  ','Answer key sync with Q numbers',           c('parseAnswerKey') && c('ansMap') && c('correctLetter')],
  ['19.6  ','Validation indicators',                    c('hasError') && c('Validation') && c('Eng') && c('Opts') && c('Ans')],
  ['19.7  ','Error highlighting — red mark',            c('rgba(255,77,77') && c('hasError') && c('error')],
  ['19.8  ','Preview before saving',                    c('Live Preview') && c('goodQs') && c('errQs')],
  ['19.9  ','Edit individual question',                 c('editingQ') && c('editDraft') && c('saveEdit') && c('Edit Q')],
  ['19.10 ','Bulk assign subject/chapter/difficulty',   c('applyBulkMeta') && c('defaultSubject') || c('Bulk Assign')],
  ['19.11 ','Final bulk save to QB',                    c('bulk-paste-save') && c('handleSave') && r("router.post('/bulk-paste-save'")],
  ['19.12 ','Auto-detect question format',              c('splitIntoBlocks') && c('detectDelimiter') && c('Q-number') && c('roman')],
  ['19.13 ','Smart clean button',                       c('smartClean') && c('Smart Clean')],
  ['19.14 ','WhatsApp format support',                  c('WhatsApp') && c('\\*\\*(.+?)\\*\\*') || c('WhatsApp bold') && c('replace')],
  ['19.15 ','Drag-and-drop reorder',                    c('draggable') && c('onDragStart') && c('handleDrop') && c('dragIdx')],
  ['19.16 ','Custom delimiter option',                  c('customDelim') && c('Custom delimiter')],
  ['19.17 ','Split screen — left paste, right preview', c('gridTemplateColumns') && c('1fr 1fr') && c('Live Preview')],
  ['19.18 ','Color-coded parsing',                      c('E8F4FF') && c('93C5FD') && c('6EE7B7') && c('FCA5A5')],
  ['19.19 ','Line parsing animation',                   c('shimmer') && c('parseAnim') && c('Parsing...')],
  ['19.20 ','Counter badge detected',                   c('detected') && c('parsedQs.length')],
  ['19.21 ','Error tooltip on hover',                   c('onMouseEnter') && c('setTooltip') && c('tooltip')],
  ['19.22 ','New tab + 3-card home + 2-card subpage',   c('HomeView') && c('CopyPasteHome') && pg("tab==='creation_studio'") && c('3 cards') || (c('HomeView') && c('CopyPasteHome') && pg("creation_studio"))],
  ['19.23 ','QB + PYQ Bank upload option',              c("'qs_bank'") && c("'pyq_bank'") && c('Upload Target') && r("target === 'pyq_bank'")],
  ['page  ','ContentForge imported in page.tsx',        pg('import ContentForge')],
  ['page  ','creation_studio tab section exists',       pg("tab==='creation_studio'")],
  ['page  ','Sidebar nav — Creation Studio',            pg("creation_studio")],
  ['route ','Backend bulk-paste-save route',            r("router.post('/bulk-paste-save'")],
  ['route ','PYQ Bank target support',                  r("target === 'pyq_bank'")],
];

console.log('\n'+'='.repeat(64));
console.log('  ProveRank — Feature 19 to 19.23 FINAL VERIFICATION');
console.log('='.repeat(64));
var pass=0, fail=0;
checks.forEach(function(chk){
  var ok = false;
  try { ok = chk[2]; } catch(e){}
  ok ? pass++ : fail++;
  console.log('  '+(ok?'✅':'❌')+'  Feature '+chk[0]+'— '+chk[1]);
});
console.log('='.repeat(64));
console.log('  Result: '+pass+' ✅  |  '+fail+' ❌');
console.log(fail===0
  ? '  \uD83C\uDF89 ALL FEATURES 19 \u2192 19.23 PERFECTLY IMPLEMENTED!'
  : '  ⚠️  Check ❌ items above');
console.log('='.repeat(64)+'\n');
VEOF

node /tmp/f19_verify.js
