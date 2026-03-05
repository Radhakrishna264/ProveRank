require('dotenv').config();
const express    = require('express');
const http       = require('http');
const cors       = require('cors');
const helmet     = require('helmet');
const mongoose   = require('mongoose');
const { initSocket } = require('./config/socket');

// ── Route Imports ─────────────────────────────────────────────
const authRoutes             = require('./routes/auth');
const adminRoutes            = require('./routes/admin');
const examPatchRoutes = require('./routes/exam_patch');
const examRoutes             = require('./routes/exam');
const examExtraRoutes        = require('./routes/examExtra');
const questionRoutes         = require('./routes/question');
const uploadRoutes           = require('./routes/upload');
const excelUploadRoutes      = require('./routes/excelUpload');
const paperGeneratorRoutes   = require('./routes/paperGenerator');
const pdfRoutes              = require('./routes/pdfRoutes');

// ── New Feature Routes (load BEFORE conflicting base routes) ──
const examFeaturesRoutes     = require('./routes/examFeatures');
const examPaperRoutes = require('./routes/examPaper');
const adminSystemRoutes      = require('./routes/adminSystem');
const adminManagementRoutes  = require('./routes/adminManagement');
const questionFeaturesRoutes = require('./routes/questionFeatures');
const customFieldsRoutes     = require('./routes/customFields');
const twoFactorRoutes        = require('./routes/twoFactor');

// ── Optional Routes (load if file exists) ────────────────────
let questionAIRoutes, questionAdvancedRoutes, questionExtraRoutes;
let examSubmissionRoutes, permissionTestRoutes;
try { questionAIRoutes       = require('./routes/questionAI'); } catch(e) {}
try { questionAdvancedRoutes = require('./routes/questionAdvanced'); } catch(e) {}
try { questionExtraRoutes    = require('./routes/questionExtra'); } catch(e) {}
try { examSubmissionRoutes   = require('./routes/examSubmission'); } catch(e) {}
try { permissionTestRoutes   = require('./routes/permissionTest'); } catch(e) {}

// ── App Setup ─────────────────────────────────────────────────
const app    = express();
const server = http.createServer(app);
initSocket(server);

app.use(helmet());
app.use(cors());
app.use(express.json());

// ── MongoDB ───────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB Connected:', mongoose.connection.host))
  .catch(err => console.log('MongoDB Error:', err));

// ── Health Check ──────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// ── Auth Routes ───────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/auth', customFieldsRoutes);
app.use('/api/auth', twoFactorRoutes);

// ── Admin Routes ──────────────────────────────────────────────
app.use('/api/admin/manage', adminManagementRoutes);  // S37/S72/S38/S93/M4
app.use('/api/admin', adminSystemRoutes);              // S66/N21
app.use('/api/admin', adminRoutes);

// ── Question Routes ───────────────────────────────────────────
app.use('/api/questions', questionFeaturesRoutes);     // AI-1/AI-2/S33/S35/MCQ/MSQ
app.use('/api/questions', questionRoutes);
if (questionAIRoutes)       app.use('/api/questions-advanced', questionAIRoutes);
if (questionAdvancedRoutes) app.use('/api/questions-advanced', questionAdvancedRoutes);
if (questionExtraRoutes)    app.use('/api/questions', questionExtraRoutes);

// ── Exam Routes ───────────────────────────────────────────────
app.use('/api/exams', examRoutes);
app.use('/api/exams', examFeaturesRoutes);
app.use('/api/exams', examPatchRoutes);
             // S5/S75/S85/S26/S62/S31/S96
app.use('/api/exam-paper', examPaperRoutes);
app.use('/api/exams', examExtraRoutes);
if (examSubmissionRoutes) app.use('/api/exams', examSubmissionRoutes);

// ── Other Routes ─────────────────────────────────────────────
app.use('/api/upload', uploadRoutes);
app.use('/api/excel', excelUploadRoutes);
app.use('/api/paper', paperGeneratorRoutes);
app.use('/api/pdf', pdfRoutes);
app.use('/api/exam-instances', require('./routes/examInstance'));
const attemptRoutes = require('./routes/attemptRoutes');
app.use('/api/attempts', attemptRoutes);
if (permissionTestRoutes) app.use('/api/permission', permissionTestRoutes);

// ── Start Server ──────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`ProveRank server running at http://0.0.0.0:${PORT}`);
});
