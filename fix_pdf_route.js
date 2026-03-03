const fs = require('fs');
const file = '/home/runner/workspace/src/routes/upload.js';
let code = fs.readFileSync(file, 'utf8');

// Remove the wrong appended route (authMiddleware wala)
const wrongRoute = `
// Phase 2.3 Step 8 - Error Logging for unparseable PDF
router.post('/pdf', authMiddleware, upload.single('pdf'), async (req, res) => {
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
});`;

if (code.includes('authMiddleware')) {
  code = code.replace(wrongRoute, '');
  // Also remove any duplicate
  code = code.replace(/\/\/ Phase 2\.3 Step 8[\s\S]*?authMiddleware[\s\S]*?\}\);/g, '');
  fs.writeFileSync(file, code);
  console.log('✅ Wrong route removed');
} else {
  console.log('⚠️ authMiddleware not found');
}

// Now add correct route at end
const correctRoute = `
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
});`;

let fresh = fs.readFileSync(file, 'utf8');
if (!fresh.includes("router.post('/pdf'")) {
  fresh += correctRoute;
  fs.writeFileSync(file, fresh);
  console.log('✅ Correct PDF route added with verifyToken');
} else {
  console.log('✅ PDF route already exists');
}
