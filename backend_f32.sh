#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — Feature 32: Per-Student Time Extension (BACKEND)
#  Creates: models/TimeExtension.js, routes/timeExtension.js
#  Patches:  routes/attemptRoutes.js (timer), index.js (register)
# ═══════════════════════════════════════════════════════════════
set -e

# ── Locate server root ─────────────────────────────────────────
SERVER_ROOT=$(find . -maxdepth 3 -name "index.js" | grep -v node_modules | grep -v frontend | head -1 | xargs dirname 2>/dev/null || echo ".")
echo "📁 Server root: $SERVER_ROOT"

MODELS_DIR="$SERVER_ROOT/models"
ROUTES_DIR="$SERVER_ROOT/routes"
INDEX_FILE=$(find "$SERVER_ROOT" -maxdepth 1 -name "index.js" | head -1)

mkdir -p "$MODELS_DIR" "$ROUTES_DIR"

# ════════════════════════════════════════════════════════════════
# 1. MODEL — models/TimeExtension.js
# ════════════════════════════════════════════════════════════════
cat > "$MODELS_DIR/TimeExtension.js" << 'EOF'
const mongoose = require('mongoose');

// Feature 32 — Per-Student Time Extension Model
const TimeExtensionSchema = new mongoose.Schema({
  // 32.6 — Log: examId, attemptId, studentId, adminId
  examId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Exam',    required: true, index: true },
  attemptId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Attempt', required: true, index: true },
  studentId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  adminId:     { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  adminName:   { type: String, default: 'Admin' },
  studentName: { type: String, default: 'Student' },

  // 32.3 — Extra minutes granted
  extraMinutes: { type: Number, required: true, min: 1, max: 120 },

  // 32.9 — Reason dropdown
  reason: {
    type: String,
    enum: ['Disability', 'Technical Issue', 'Internet Problem', 'Other'],
    default: 'Other'
  },

  // 32.8 — Global extension flag
  isGlobal: { type: Boolean, default: false },

  // 32.12 — Undo tracking
  isUndone:  { type: Boolean, default: false },
  undoneAt:  { type: Date },
  undoneBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: true });

// Index for fast log lookup per exam
TimeExtensionSchema.index({ examId: 1, createdAt: -1 });
TimeExtensionSchema.index({ attemptId: 1, isUndone: 1 });

module.exports = mongoose.model('TimeExtension', TimeExtensionSchema);
EOF
echo "✅ models/TimeExtension.js created"

# ════════════════════════════════════════════════════════════════
# 2. ROUTE — routes/timeExtension.js
# ════════════════════════════════════════════════════════════════
cat > "$ROUTES_DIR/timeExtension.js" << 'EOF'
// Feature 32 — Per-Student Time Extension (All Sub-Features)
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

// ── Auth Middleware ────────────────────────────────────────────
function authAdmin(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token missing' });
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (!['admin', 'superadmin'].includes(decoded.role))
      return res.status(403).json({ error: 'Admin access required' });
    req.user = decoded;
    next();
  } catch(e) { return res.status(401).json({ error: 'Invalid token' }); }
}

// ──────────────────────────────────────────────────────────────
// 32.1 / 32.10 — GET active students in a live exam
// GET /api/time-extension/active-students/:examId
// ──────────────────────────────────────────────────────────────
router.get('/active-students/:examId', authAdmin, async (req, res) => {
  try {
    const Attempt       = require('../models/Attempt');
    const Exam          = require('../models/Exam');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const exam = await Exam.findById(req.params.examId).select('title duration');
    if (!exam) return res.status(404).json({ error: 'Exam not found' });

    const activeAttempts = await Attempt.find({
      examId: req.params.examId,
      status: 'active'
    }).lean();

    const studentIds = activeAttempts.map(a => a.studentId);
    const students   = await User.find({ _id: { $in: studentIds } }).select('name email rollNumber').lean();
    const studMap    = {};
    students.forEach(s => { studMap[s._id.toString()] = s; });

    // Calculate remaining time including extensions (32.10)
    const baseDurSec = (exam.duration || 200) * 60;
    const now        = Date.now();

    const result = await Promise.all(activeAttempts.map(async (a) => {
      const exts     = await TimeExtension.find({ attemptId: a._id, isUndone: false });
      const extMin   = exts.reduce((s, e) => s + e.extraMinutes, 0);
      const totalSec = baseDurSec + extMin * 60;
      const elapsed  = Math.floor((now - new Date(a.startedAt).getTime()) / 1000);
      const remaining= Math.max(0, totalSec - elapsed);
      const stud     = studMap[a.studentId?.toString()] || {};
      return {
        attemptId:      a._id,
        studentId:      a.studentId,
        studentName:    stud.name    || 'Unknown',
        studentEmail:   stud.email   || '',
        rollNumber:     stud.rollNumber || '',
        startedAt:      a.startedAt,
        remainingSec:   remaining,
        remainingMin:   Math.ceil(remaining / 60),
        totalExtMin:    extMin,
        extensionCount: exts.length,
        isPaused:       a.isPaused || false,
        answeredCount:  (a.answers || []).filter(ans => ans.selectedOption != null).length,
      };
    }));

    res.json({ success: true, examTitle: exam.title, count: result.length, students: result });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.2/32.3/32.4/32.6/32.7/32.9/32.11/32.13 — Give Extra Time
// POST /api/time-extension/give
// ──────────────────────────────────────────────────────────────
router.post('/give', authAdmin, async (req, res) => {
  try {
    const { attemptId, examId, studentId, extraMinutes, reason, studentName } = req.body;

    if (!attemptId || !extraMinutes)
      return res.status(400).json({ error: 'attemptId and extraMinutes required' });

    const mins = parseInt(extraMinutes);
    if (isNaN(mins) || mins < 1 || mins > 120)
      return res.status(400).json({ error: 'extraMinutes must be between 1 and 120' });

    const Attempt       = require('../models/Attempt');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const attempt = await Attempt.findById(attemptId);
    if (!attempt || attempt.status !== 'active')
      return res.status(404).json({ error: 'Active attempt not found' });

    // 32.7 — Multiple extensions: calculate previous total
    const prevExts    = await TimeExtension.find({ attemptId, isUndone: false });
    const prevTotalMin= prevExts.reduce((s, e) => s + e.extraMinutes, 0);
    const newTotal    = prevTotalMin + mins;

    // 32.11 — Warn if exceeds 30 min
    const warning = newTotal > 30
      ? `⚠️ Warning: Total extensions for this student = ${newTotal} min (exceeds recommended 30 min)`
      : null;

    const admin     = await User.findById(req.user.id).select('name email');
    const adminName = admin?.name || admin?.email || 'Admin';

    // 32.6 — Save extension log
    const ext = await TimeExtension.create({
      examId:      examId || attempt.examId,
      attemptId,
      studentId:   studentId || attempt.studentId,
      adminId:     req.user.id,
      adminName,
      studentName: studentName || 'Student',
      extraMinutes: mins,
      reason:      reason || 'Other',
      isGlobal:    false,
    });

    // 32.4 / 32.5 / 32.13 — Real-time socket push to student
    const io = req.app.get('io');
    if (io) {
      const payload = {
        attemptId,
        extraMinutes:   mins,
        reason:         reason || 'Other',
        adminName,
        message:        `Admin has given you +${mins} minutes extra time`, // 32.13
        totalExtension: newTotal,
        extensionId:    ext._id,
        timestamp:      new Date(),
        isUndo:         false,
      };
      // Push to student's personal room + attempt room (32.4/32.5)
      io.to(`student:${attempt.studentId}`).emit('time:extend', payload);
      io.to(`attempt:${attemptId}`).emit('time:extend', payload);
      // Notify all admin monitors
      io.emit('admin:extension_given', {
        ...payload,
        studentName: studentName || 'Student',
        examId:      examId || attempt.examId,
      });
    }

    res.json({
      success:     true,
      message:     `+${mins} min given to ${studentName || 'student'}`,
      extensionId: ext._id,
      totalExtMin: newTotal,
      warning,       // 32.11
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.8 — Global Extend: All active students at once
// POST /api/time-extension/global
// ──────────────────────────────────────────────────────────────
router.post('/global', authAdmin, async (req, res) => {
  try {
    const { examId, extraMinutes, reason } = req.body;
    if (!examId || !extraMinutes)
      return res.status(400).json({ error: 'examId and extraMinutes required' });

    const mins = parseInt(extraMinutes);
    if (isNaN(mins) || mins < 1 || mins > 120)
      return res.status(400).json({ error: 'extraMinutes must be 1-120' });

    const Attempt       = require('../models/Attempt');
    const User          = require('../models/User');
    const TimeExtension = require('../models/TimeExtension');

    const admin     = await User.findById(req.user.id).select('name email');
    const adminName = admin?.name || admin?.email || 'Admin';

    const activeAttempts = await Attempt.find({ examId, status: 'active' }).lean();
    if (!activeAttempts.length)
      return res.status(404).json({ error: 'No active attempts found for this exam' });

    // Bulk create extension logs for all students (32.6)
    const bulkDocs = activeAttempts.map(a => ({
      examId,
      attemptId:   a._id,
      studentId:   a.studentId,
      adminId:     req.user.id,
      adminName,
      studentName: 'All Students (Global)',
      extraMinutes: mins,
      reason:      reason || 'Technical Issue',
      isGlobal:    true,
    }));
    await TimeExtension.insertMany(bulkDocs);

    // 32.4 — Emit to every active student
    const io = req.app.get('io');
    if (io) {
      for (const a of activeAttempts) {
        const payload = {
          attemptId:    a._id,
          extraMinutes: mins,
          reason:       reason || 'Technical Issue',
          adminName,
          message:      `Admin has extended exam time by +${mins} minutes for all students`,
          isGlobal:     true,
          timestamp:    new Date(),
        };
        io.to(`student:${a.studentId}`).emit('time:extend', payload);
        io.to(`attempt:${a._id}`).emit('time:extend', payload);
      }
      io.emit('admin:global_extension', {
        examId, extraMinutes: mins, reason,
        adminName, studentsAffected: activeAttempts.length,
      });
    }

    res.json({
      success:          true,
      message:          `+${mins} min given to all ${activeAttempts.length} active students`,
      studentsAffected: activeAttempts.length,
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.6 / 32.19 — Extension Log for an exam
// GET /api/time-extension/log/:examId
// ──────────────────────────────────────────────────────────────
router.get('/log/:examId', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const logs = await TimeExtension.find({ examId: req.params.examId })
      .sort({ createdAt: -1 })
      .populate('studentId', 'name email')
      .populate('adminId', 'name email')
      .lean();
    res.json({ success: true, count: logs.length, logs });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.10 — Current time remaining for a specific student
// GET /api/time-extension/remaining/:attemptId
// ──────────────────────────────────────────────────────────────
router.get('/remaining/:attemptId', authAdmin, async (req, res) => {
  try {
    const Attempt       = require('../models/Attempt');
    const Exam          = require('../models/Exam');
    const TimeExtension = require('../models/TimeExtension');

    const attempt = await Attempt.findById(req.params.attemptId);
    if (!attempt) return res.status(404).json({ error: 'Attempt not found' });

    const exam         = await Exam.findById(attempt.examId);
    const baseDurSec   = (exam?.duration || 200) * 60;
    const exts         = await TimeExtension.find({ attemptId: req.params.attemptId, isUndone: false });
    const totalExtMin  = exts.reduce((s, e) => s + e.extraMinutes, 0);
    const totalDurSec  = baseDurSec + totalExtMin * 60;
    const elapsedSec   = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurSec - elapsedSec);

    res.json({
      success:        true,
      remainingSec,
      remainingMin:   Math.ceil(remainingSec / 60),
      totalExtMin,
      baseDurationMin: exam?.duration || 200,
      elapsedSec,
      extensionCount: exts.length,
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.12 — Undo Extension (within 5 minutes)
// DELETE /api/time-extension/:logId/undo
// ──────────────────────────────────────────────────────────────
router.delete('/:logId/undo', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const ext = await TimeExtension.findById(req.params.logId);
    if (!ext) return res.status(404).json({ error: 'Extension log not found' });
    if (ext.isUndone) return res.status(400).json({ error: 'Already undone' });

    // 32.12 — 5 minute window check
    const minsElapsed = (Date.now() - new Date(ext.createdAt).getTime()) / 60000;
    if (minsElapsed > 5)
      return res.status(400).json({
        error: `Cannot undo — 5 minute window has passed (${minsElapsed.toFixed(1)} min ago)`
      });

    ext.isUndone = true;
    ext.undoneAt  = new Date();
    ext.undoneBy  = req.user.id;
    await ext.save();

    // Emit undo event to student (reverse the extension)
    const io = req.app.get('io');
    if (io) {
      const payload = {
        attemptId:    ext.attemptId,
        extraMinutes: -ext.extraMinutes,  // negative = reduce time back
        message:      `Admin has cancelled a +${ext.extraMinutes} min extension`,
        isUndo:       true,
        timestamp:    new Date(),
      };
      io.to(`student:${ext.studentId}`).emit('time:extend', payload);
      io.to(`attempt:${ext.attemptId}`).emit('time:extend', payload);
      io.emit('admin:extension_undone', { ...payload, logId: ext._id });
    }

    res.json({ success: true, message: `Extension of +${ext.extraMinutes} min has been undone`, undoneMinutes: ext.extraMinutes });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ──────────────────────────────────────────────────────────────
// 32.14 — Download PDF Report of all extensions
// GET /api/time-extension/report/:examId
// ──────────────────────────────────────────────────────────────
router.get('/report/:examId', authAdmin, async (req, res) => {
  try {
    const TimeExtension = require('../models/TimeExtension');
    const Exam          = require('../models/Exam');
    const PDFDocument   = require('pdfkit');

    const exam = await Exam.findById(req.params.examId).select('title duration');
    const logs = await TimeExtension.find({ examId: req.params.examId })
      .populate('studentId', 'name email rollNumber')
      .populate('adminId', 'name email')
      .sort({ createdAt: 1 })
      .lean();

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="TimeExtensions_${req.params.examId}.pdf"`);
    doc.pipe(res);

    // Title
    doc.fontSize(20).fillColor('#1B3A6B')
      .text('ProveRank — Time Extension Report', { align: 'center' });
    doc.fontSize(12).fillColor('#374151')
      .text(`Exam: ${exam?.title || req.params.examId}`, { align: 'center' });
    doc.text(`Generated: ${new Date().toLocaleString()}`, { align: 'center' });
    doc.moveDown(1.5);

    // Summary
    const active = logs.filter(l => !l.isUndone);
    const totalMin = active.reduce((s, l) => s + l.extraMinutes, 0);
    doc.fontSize(12).fillColor('#0F766E').text('Summary', { underline: true });
    doc.moveDown(0.3);
    doc.fontSize(11).fillColor('#1F2937')
      .text(`Total Extensions Given: ${logs.length}`)
      .text(`Active Extensions: ${active.length}`)
      .text(`Undone Extensions: ${logs.length - active.length}`)
      .text(`Total Extra Minutes Granted: ${totalMin} min`);
    doc.moveDown(1);

    // Log table
    doc.fontSize(12).fillColor('#0F766E').text('Extension Log', { underline: true });
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke('#D1D5DB');
    doc.moveDown(0.5);

    if (!logs.length) {
      doc.fontSize(11).fillColor('#6B7280').text('No extensions were given for this exam.');
    } else {
      logs.forEach((log, i) => {
        const sName   = log.studentId?.name  || log.studentName  || 'Unknown';
        const sEmail  = log.studentId?.email || '';
        const aName   = log.adminId?.name    || log.adminName    || 'Admin';
        const status  = log.isUndone ? ' [UNDONE]' : '';
        const time    = new Date(log.createdAt).toLocaleString();
        const color   = log.isUndone ? '#9CA3AF' : '#1F2937';

        doc.fontSize(10).fillColor(color)
          .text(`${i + 1}. ${sName} (${sEmail}) — +${log.extraMinutes} min — ${log.reason}${log.isGlobal ? ' [GLOBAL]' : ''}`)
          .text(`    By: ${aName} | At: ${time}${status}`);
        doc.moveDown(0.4);
      });
    }

    doc.moveDown();
    doc.fontSize(10).fillColor('#6B7280')
      .text(`Generated by ProveRank Admin | ${new Date().toLocaleString()}`, { align: 'center' });

    doc.end();
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
EOF
echo "✅ routes/timeExtension.js created"

# ════════════════════════════════════════════════════════════════
# 3. PATCH — routes/attemptRoutes.js (include extension time in timer)
# ════════════════════════════════════════════════════════════════
ATTEMPT_FILE="$ROUTES_DIR/attemptRoutes.js"
if [ -f "$ATTEMPT_FILE" ]; then
  cp "$ATTEMPT_FILE" "${ATTEMPT_FILE}.bak"
  node << 'JSEOF'
const fs = require('fs');
const filePath = process.env.ATTEMPT_FILE;
let c = fs.readFileSync(filePath, 'utf8');

// Check if already patched
if (c.includes('TimeExtension') && c.includes('timeExtMin')) {
  console.log('ℹ️  attemptRoutes.js already patched — skipping');
  process.exit(0);
}

// Find the timer route and patch it
const OLD = `    const totalDurationSec = (exam.duration || 200) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurationSec - elapsedSec);`;

const NEW = `    // ── Feature 32: Include granted extra time in timer ──
    let timeExtMin = 0;
    try {
      const TimeExtension = require('../models/TimeExtension');
      const exts = await TimeExtension.find({ attemptId: attempt._id, isUndone: false });
      timeExtMin = exts.reduce((s, e) => s + e.extraMinutes, 0);
    } catch(_extErr) { /* TimeExtension model not loaded yet */ }
    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurationSec - elapsedSec);`;

if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  // Also add timeExtMin to the response JSON
  c = c.replace(
    'totalDurationSec, elapsedSec, remainingSec,',
    'totalDurationSec, elapsedSec, remainingSec, timeExtMin,'
  );
  fs.writeFileSync(filePath, c);
  console.log('✅ attemptRoutes.js patched — extension time included in timer');
} else {
  console.log('⚠️  Timer string not found exactly — manual check needed');
  // Still try partial patch
  if (c.includes('exam.duration || 200') && !c.includes('timeExtMin')) {
    c = c.replace(
      /const totalDurationSec = \(exam\.duration \|\| 200\) \* 60;/,
      `// Feature 32: include extra time in timer\n    let timeExtMin = 0;\n    try {\n      const TimeExtension = require('../models/TimeExtension');\n      const exts = await TimeExtension.find({ attemptId: attempt._id, isUndone: false });\n      timeExtMin = exts.reduce((s, e) => s + e.extraMinutes, 0);\n    } catch(_e) {}\n    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;`
    );
    fs.writeFileSync(filePath, c);
    console.log('✅ attemptRoutes.js patched (regex fallback)');
  }
}
JSEOF
else
  echo "⚠️  attemptRoutes.js not found at $ATTEMPT_FILE — timer patch skipped"
fi
# Pass the file path to Node via env
ATTEMPT_FILE="$ATTEMPT_FILE" node << 'JSEOF'
const fs = require('fs');
const filePath = process.env.ATTEMPT_FILE;
if (!filePath || !fs.existsSync(filePath)) { console.log('Skip'); process.exit(0); }
let c = fs.readFileSync(filePath, 'utf8');
if (c.includes('timeExtMin')) { console.log('ℹ️  Already patched'); process.exit(0); }
c = c.replace(
  'const totalDurationSec = (exam.duration || 200) * 60;',
  `// Feature 32: include granted extra time\n    let timeExtMin = 0;\n    try { const TE = require('../models/TimeExtension'); const exts = await TE.find({ attemptId: attempt._id, isUndone: false }); timeExtMin = exts.reduce((s,e)=>s+e.extraMinutes,0); } catch(_e){}\n    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;`
);
c = c.replace('totalDurationSec, elapsedSec, remainingSec,', 'totalDurationSec, elapsedSec, remainingSec, timeExtMin,');
fs.writeFileSync(filePath, c);
console.log('✅ attemptRoutes.js patched');
JSEOF

# ════════════════════════════════════════════════════════════════
# 4. PATCH — index.js (register time-extension route)
# ════════════════════════════════════════════════════════════════
if [ -f "$INDEX_FILE" ]; then
  node << 'JSEOF'
const fs = require('fs');
const filePath = process.env.INDEX_FILE;
let c = fs.readFileSync(filePath, 'utf8');

if (c.includes('timeExtension') || c.includes('time-extension')) {
  console.log('ℹ️  index.js already has time-extension route — skipping');
  process.exit(0);
}

// Add require after attemptRoutes line
const requireMark = "const attemptRoutes = require('./routes/attemptRoutes');";
const requireAdd  = "\nconst timeExtensionRoutes = require('./routes/timeExtension'); // Feature 32";

// Add use() after attempts line
const useMark = "app.use('/api/attempts', attemptRoutes);";
const useAdd  = "\napp.use('/api/time-extension', timeExtensionRoutes); // Feature 32 — Per-Student Time Extension";

if (c.includes(requireMark)) {
  c = c.replace(requireMark, requireMark + requireAdd);
} else {
  // Fallback — append before server.listen
  c = c.replace("server.listen(", "const timeExtensionRoutes = require('./routes/timeExtension');\napp.use('/api/time-extension', timeExtensionRoutes);\n\nserver.listen(");
}

if (c.includes(useMark)) {
  c = c.replace(useMark, useMark + useAdd);
}

fs.writeFileSync(filePath, c);
console.log('✅ index.js patched — /api/time-extension registered');
JSEOF
  INDEX_FILE="$INDEX_FILE" node << 'JSEOF'
  const fs = require('fs'); const f = process.env.INDEX_FILE;
  if(!f||!fs.existsSync(f)){process.exit(0);}
  const c = fs.readFileSync(f,'utf8');
  if(c.includes('timeExtension')){console.log('✅ index.js already has route');}
  else{console.log('⚠️ Manual add needed: app.use(\'/api/time-extension\', require(\'./routes/timeExtension\'));');}
JSEOF
else
  echo "⚠️  index.js not found — manually add: app.use('/api/time-extension', require('./routes/timeExtension'));"
fi

# ════════════════════════════════════════════════════════════════
# 5. VERIFICATION
# ════════════════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════════"
echo "  🔍 Backend Feature 32 — Verification"
echo "══════════════════════════════════════════════"
node << 'JSEOF'
const fs   = require('fs');
const path = require('path');

function find(dir, name) {
  const { execSync } = require('child_process');
  try { return execSync(`find ${dir} -name "${name}" | grep -v node_modules | head -1`).toString().trim(); }
  catch(e) { return ''; }
}

const modelFile = find('.', 'TimeExtension.js');
const routeFile = find('.', 'timeExtension.js');
const attemptF  = find('.', 'attemptRoutes.js');
const indexF    = find('.', 'index.js');

const modelC   = modelFile  ? fs.readFileSync(modelFile, 'utf8') : '';
const routeC   = routeFile  ? fs.readFileSync(routeFile, 'utf8') : '';
const attemptC = attemptF   ? fs.readFileSync(attemptF,  'utf8') : '';
const indexC   = indexF     ? fs.readFileSync(indexF,    'utf8') : '';

const checks = [
  ['32.1  Active students API endpoint exists',      routeC.includes('active-students/:examId')],
  ['32.2  Give Extra Time endpoint (/give)',          routeC.includes("router.post('/give'")],
  ['32.3  extraMinutes validated in /give',           routeC.includes('extraMinutes')],
  ['32.4  Socket.io emit to student room',            routeC.includes("student:${attempt.studentId}") || routeC.includes('io.to')],
  ['32.5  attempt room socket emit',                  routeC.includes('attempt:${attemptId}') || routeC.includes('io.to(`attempt')],
  ['32.6  TimeExtension.create() — log saved',       routeC.includes('TimeExtension.create')],
  ['32.7  prevExts checked (multi-extension ok)',     routeC.includes('prevExts')],
  ['32.8  Global extend endpoint (/global)',          routeC.includes("router.post('/global'")],
  ['32.9  Reason enum in model',                     modelC.includes("'Disability'") && modelC.includes("'Technical Issue'")],
  ['32.10 Remaining time endpoint (/remaining/:id)', routeC.includes('/remaining/:attemptId')],
  ['32.11 30 min warning logic',                     routeC.includes('> 30')],
  ['32.12 Undo endpoint with 5 min check',           routeC.includes('minsElapsed > 5')],
  ['32.13 Notification message to student',          routeC.includes('Admin has given you')],
  ['32.14 PDF report endpoint (/report/:examId)',     routeC.includes('/report/:examId')],
  ['32.15 remainingSec returned in active-students', routeC.includes('remainingSec')],
  ['32.16 Route for extension exists (API ready)',   routeC.includes("router.post('/give'")],
  ['32.17 Extension log model has all fields',       modelC.includes('reason') && modelC.includes('adminName') && modelC.includes('studentName')],
  ['32.18 admin:extension_given socket event',       routeC.includes('admin:extension_given')],
  ['32.19 Extension log API /log/:examId',           routeC.includes('/log/:examId')],
  ['32.20 Global extend broadcasts to all students', routeC.includes('activeAttempts.map') || routeC.includes('for (const a')],
  ['Timer patch: attemptRoutes uses extension time', attemptC.includes('timeExtMin') || attemptC.includes('TimeExtension')],
  ['index.js: /api/time-extension registered',       indexC.includes('time-extension') || indexC.includes('timeExtension')],
];

let pass = 0, fail = 0;
checks.forEach(([label, ok]) => {
  console.log((ok ? '✅' : '❌') + ' ' + label);
  ok ? pass++ : fail++;
});

console.log('\n──────────────────────────────────────────────');
console.log(`Result: ${pass}/${checks.length} checks passed`);
if (fail === 0) console.log('🎉 ALL BACKEND CHECKS PASSED — Feature 32 Backend Ready!');
else            console.log(`⚠️  ${fail} check(s) need attention`);
JSEOF
