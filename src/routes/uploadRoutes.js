
// Phase 2.3 Step 8 - Error Logging for unparseable PDF
router.post('/pdf', authMiddleware, upload.single('pdf'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'PDF file required', error: 'No file uploaded' });
    }
    const pdfParse = require('pdf-parse');
    let parseError = null;
    let parsed = null;
    try {
      parsed = await pdfParse(req.file.buffer);
    } catch (e) {
      parseError = e.message;
    }
    if (parseError || !parsed?.text?.trim()) {
      // Log the error
      console.error('[PDF_PARSE_ERROR]', parseError || 'Empty content', 'File:', req.file.originalname);
      return res.status(422).json({
        success: false,
        message: 'PDF content unparseable - flagged for review',
        error: parseError || 'Empty or unreadable content',
        flagged: true,
        filename: req.file.originalname
      });
    }
    return res.status(200).json({ success: true, message: 'PDF parsed successfully', text: parsed.text.substring(0, 500) });
  } catch (e) {
    console.error('[PDF_ROUTE_ERROR]', e.message);
    return res.status(500).json({ success: false, message: e.message });
  }
});
