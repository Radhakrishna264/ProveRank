const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const {
  uploadExcelQuestions,
  uploadExcelStudents,
  uploadPDFQuestions,
  copyPasteQuestions
} = require('../controllers/uploadController');

// Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/';
    if (!require('fs').existsSync(dir)) require('fs').mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  const allowed = ['.xlsx', '.xls', '.pdf'];
  if (allowed.includes(ext)) cb(null, true);
  else cb(new Error('Only .xlsx, .xls, .pdf files allowed'), false);
};

const upload = multer({ storage, fileFilter, limits: { fileSize: 10 * 1024 * 1024 } });

// STEP 1+2+3+4+5: Excel Questions Upload
router.post('/excel/questions', verifyToken, isSuperAdmin, upload.single('file'), uploadExcelQuestions);

// STEP 6: Excel Students Bulk Import (S8)
router.post('/excel/students', verifyToken, isSuperAdmin, upload.single('file'), uploadExcelStudents);

// STEP 7+8+9+10: PDF Question Parser
router.post('/pdf/questions', verifyToken, isSuperAdmin, upload.single('file'), uploadPDFQuestions);

// STEP 11+12+13+14: Copy-Paste System
router.post('/copypaste/questions', verifyToken, isSuperAdmin, copyPasteQuestions);

module.exports = router;
// Phase 2.4 - Step 5+6: Validate + Result Link
const { validateAndLink } = require('../controllers/uploadController');
router.post('/copypaste/validate', verifyToken, isSuperAdmin, validateAndLink);


// Phase 2.3 Step 8 - Error Logging for unparseable PDF
router.post('/pdf', verifyToken, isSuperAdmin, upload.single('pdf'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'PDF file required', error: 'No file uploaded' });
    }
    const pdfParse = require('pdf-parse');
    let parseError = null, parsed = null;
    try { parsed = await pdfParse(req.file.buffer); } catch(e) { parseError = e.message; }
    if (parseError || !parsed?.text?.trim()) {
      console.error('[PDF_PARSE_ERROR]', parseError || 'Empty content');
      return res.status(422).json({ success: false, message: 'PDF content unparseable - flagged for review', error: parseError || 'Empty content', flagged: true });
    }
    return res.status(200).json({ success: true, message: 'PDF parsed successfully', text: parsed.text.substring(0, 500) });
  } catch(e) { return res.status(500).json({ success: false, message: e.message }); }
});