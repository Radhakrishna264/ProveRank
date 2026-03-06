const fs = require('fs');
const filePath = './src/controllers/uploadController.js';
const lines = fs.readFileSync(filePath, 'utf8').split('\n');
let fixed = false;
for (let i = 324; i <= 334; i++) {
  if (lines[i] && lines[i].includes('res.status(500)') && lines[i].includes('err.message')) {
    const oldLine = lines[i];
    lines[i] = '    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);\n    const isPdfErr = err.message && (err.message.toLowerCase().includes("pdf") || err.message.toLowerCase().includes("xref") || err.message.toLowerCase().includes("invalid") || err.message.toLowerCase().includes("parse"));\n    return res.status(isPdfErr ? 422 : 500).json({ success: false, message: err.message, flagged: isPdfErr });';
    console.log("Fixed line", i+1);
    console.log("Old:", oldLine.trim().substring(0,80));
    fixed = true;
    break;
  }
}
if (fixed) { fs.writeFileSync(filePath, lines.join('\n')); console.log('Controller fix DONE!'); }
else { console.log('Line not found!'); }
