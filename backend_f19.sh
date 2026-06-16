#!/bin/bash
# ProveRank — Feature 19: Bulk Upload via Copy-Paste BACKEND
set -e
echo "🚀 Feature 19 Backend starting..."

cat > /tmp/f19_routes.js << 'ROUTES_EOF'

// ══ Feature 19 — Bulk Paste Save ════════════════════════════════
// POST /api/questions/bulk-paste-save
router.post('/bulk-paste-save', verifyToken, isAdmin, async function(req, res) {
  try {
    var questions = req.body.questions;
    var target    = req.body.target || 'qs_bank'; // 'qs_bank' | 'pyq_bank'
    var defaultSubject    = req.body.subject    || 'General';
    var defaultChapter    = req.body.chapter    || '';
    var defaultDifficulty = req.body.difficulty || 'Medium';
    var defaultType       = req.body.type       || 'SCQ';

    if (!questions || !questions.length)
      return res.status(400).json({ success:false, message:'No questions provided' });

    var saved = [], errors = [];

    for (var i=0; i<questions.length; i++) {
      try {
        var q = questions[i];
        var doc = new Question({
          text:             q.text             || '',
          hindiText:        q.hindiText        || '',
          options:          q.options          || [],
          hindiOptions:     q.hindiOptions     || [],
          correct:          q.correct          || [0],
          explanation:      q.explanation      || '',
          hindiExplanation: q.hindiExplanation || '',
          subject:          q.subject          || defaultSubject,
          chapter:          q.chapter          || defaultChapter,
          difficulty:       q.difficulty       || defaultDifficulty,
          type:             q.type             || defaultType,
          format:           q.format           || '',
          isPYQ:            target === 'pyq_bank',
          source:           'paste',
          usageCount:       0
        });
        await doc.save();
        saved.push(doc._id);
      } catch(e) {
        errors.push({ index:i, message:e.message });
      }
    }

    return res.json({
      success: true,
      message: saved.length+' questions saved to '+(target==='pyq_bank'?'PYQ Bank':'Question Bank'),
      saved:   saved.length,
      errors:  errors,
      target:  target
    });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

// ── Feature 19 — Parse Preview (server-side validation only)
router.post('/bulk-paste-validate', verifyToken, isAdmin, async function(req, res) {
  try {
    var questions = req.body.questions || [];
    var valid   = questions.filter(function(q){return q.text&&q.options&&q.options.length>=2&&q.correct&&q.correct.length>0;}).length;
    var invalid = questions.length - valid;
    return res.json({ success:true, total:questions.length, valid:valid, invalid:invalid });
  } catch(err) { return res.status(500).json({ success:false, message:err.message }); }
});

ROUTES_EOF

echo "✅ Routes written to temp file"

cat > /tmp/f19_patch.js << 'NODE_EOF'
var fs = require('fs'), p = require('path');
var fpath = p.join(process.env.HOME,'workspace/src/routes/questionFeatures.js');
var c = fs.readFileSync(fpath,'utf8');
var newRoutes = fs.readFileSync('/tmp/f19_routes.js','utf8');

if (!c.includes('bulk-paste-save')) {
  // Insert before last router usage or append
  var insertAt = c.lastIndexOf('\nmodule.exports');
  if (insertAt > -1) {
    c = c.slice(0, insertAt) + '\n' + newRoutes + c.slice(insertAt);
  } else {
    c += '\n' + newRoutes;
  }
  fs.writeFileSync(fpath, c, 'utf8');
  console.log('✅ bulk-paste-save route added');
} else {
  console.log('✅ Route already exists');
}

var final = fs.readFileSync(fpath,'utf8');
var checks = [
  ['19.11 bulk-paste-save route',   final.includes("router.post('/bulk-paste-save'")],
  ['19.23 target qs_bank/pyq_bank', final.includes("target === 'pyq_bank'")],
  ['19.10 defaultSubject/Chapter',  final.includes('defaultSubject')],
  ['      validate route',          final.includes("router.post('/bulk-paste-validate'")],
];
console.log('\n── Backend Verification ──');
checks.forEach(function(c){ console.log('  '+(c[1]?'✅':'❌')+' '+c[0]); });
NODE_EOF

node /tmp/f19_patch.js
echo ""
echo "✅ Feature 19 Backend done!"
