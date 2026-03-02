const { createSimplePDF } = require('./pdfkitConfig');
const path = require('path');
const fs = require('fs');

const PDF_DIR = path.join(__dirname, '../../pdfs');
if (!fs.existsSync(PDF_DIR)) {
  fs.mkdirSync(PDF_DIR, { recursive: true });
}

// ─── 1. CERTIFICATE PDF (PDFKit) ────────────────────────────
const generateCertificate = ({ studentName, score, date, uniqueId }) => {
  return new Promise((resolve, reject) => {
    const doc = createSimplePDF({ size: [841.89, 595.28] }); // A4 Landscape
    const filePath = path.join(PDF_DIR, `certificate_${uniqueId}.pdf`);
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);

    const W = 841.89;
    const H = 595.28;

    // Gold border
    doc.rect(20, 20, W - 40, H - 40).lineWidth(3).strokeColor('#b8860b').stroke();
    doc.rect(26, 26, W - 52, H - 52).lineWidth(1).strokeColor('#b8860b').stroke();

    // Title
    doc.fontSize(36).fillColor('#b8860b').font('Helvetica-Bold')
       .text('ProveRank', 0, 80, { align: 'center', width: W });

    doc.fontSize(14).fillColor('#555555').font('Helvetica')
       .text('Certificate of Achievement', 0, 128, { align: 'center', width: W });

    // Divider
    doc.moveTo(200, 155).lineTo(W - 200, 155).strokeColor('#b8860b').lineWidth(1).stroke();

    doc.fontSize(13).fillColor('#333333')
       .text('This is to certify that', 0, 168, { align: 'center', width: W });

    // Student name
    doc.fontSize(28).fillColor('#1a1a2e').font('Helvetica-Bold')
       .text(studentName, 0, 195, { align: 'center', width: W });

    doc.moveTo(220, 235).lineTo(W - 220, 235).strokeColor('#b8860b').lineWidth(1).stroke();

    doc.fontSize(13).fillColor('#333333').font('Helvetica')
       .text('has successfully completed the NEET Mock Exam', 0, 248, { align: 'center', width: W });

    // Score box
    doc.rect(W/2 - 100, 278, 200, 70).fillColor('#f0f8ff').fill();
    doc.rect(W/2 - 100, 278, 200, 70).lineWidth(1).strokeColor('#4169e1').stroke();
    doc.fontSize(11).fillColor('#666666').text('Score Achieved', W/2 - 100, 288, { width: 200, align: 'center' });
    doc.fontSize(24).fillColor('#4169e1').font('Helvetica-Bold')
       .text(`${score} / 720`, W/2 - 100, 308, { width: 200, align: 'center' });

    // Date and ID
    doc.fontSize(11).fillColor('#777777').font('Helvetica')
       .text(`Date: ${date}`, 0, 368, { align: 'center', width: W });
    doc.text(`Certificate ID: ${uniqueId}`, 0, 384, { align: 'center', width: W });

    // Footer
    doc.moveTo(200, 410).lineTo(W - 200, 410).strokeColor('#b8860b').lineWidth(1).stroke();
    doc.fontSize(12).fillColor('#b8860b').font('Helvetica-Bold')
       .text('ProveRank — Prove Yourself · Rise to the Top', 0, 422, { align: 'center', width: W });

    doc.end();
    stream.on('finish', () => resolve(filePath));
    stream.on('error', reject);
  });
};

// ─── 2. OMR SHEET PDF (PDFKit) ──────────────────────────────
const generateOMRSheet = ({ studentName, examTitle, totalQuestions = 180, uniqueId }) => {
  return new Promise((resolve, reject) => {
    const doc = createSimplePDF();
    const filePath = path.join(PDF_DIR, `omr_${uniqueId}.pdf`);
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);

    // Header
    doc.fontSize(18).fillColor('#1a1a2e').font('Helvetica-Bold')
       .text('ProveRank — OMR Answer Sheet', { align: 'center' });
    doc.fontSize(12).fillColor('#555555').font('Helvetica')
       .text(examTitle, { align: 'center' });
    doc.moveDown(0.5);

    doc.fontSize(11).fillColor('#333333')
       .text(`Student Name: ${studentName}`, { continued: true })
       .text(`    Sheet ID: ${uniqueId}`, { align: 'right' });
    doc.moveDown(0.5);

    // Table header
    const startX = 60;
    const colW = [40, 80, 80, 80, 80];
    const headers = ['Q#', 'A', 'B', 'C', 'D'];
    let y = doc.y;

    doc.rect(startX, y, 360, 20).fillColor('#1a1a2e').fill();
    headers.forEach((h, i) => {
      const x = startX + colW.slice(0, i).reduce((a, b) => a + b, 0);
      doc.fontSize(10).fillColor('#ffffff').font('Helvetica-Bold')
         .text(h, x, y + 5, { width: colW[i], align: 'center' });
    });
    y += 20;

    // Rows
    for (let q = 1; q <= totalQuestions; q++) {
      if (y > 750) {
        doc.addPage();
        y = 50;
      }

      const bg = q % 2 === 0 ? '#f5f5f5' : '#ffffff';
      doc.rect(startX, y, 360, 18).fillColor(bg).fill();
      doc.rect(startX, y, 360, 18).lineWidth(0.3).strokeColor('#cccccc').stroke();

      // Q number
      doc.fontSize(9).fillColor('#333333').font('Helvetica-Bold')
         .text(`${q}`, startX, y + 4, { width: colW[0], align: 'center' });

      // Bubbles
      const opts = ['A', 'B', 'C', 'D'];
      opts.forEach((opt, i) => {
        const cx = startX + colW[0] + colW.slice(1, i + 1).reduce((a, b) => a + b, 0) + 40;
        const cy = y + 9;
        doc.circle(cx, cy, 7).lineWidth(1).strokeColor('#333333').stroke();
        doc.fontSize(7).fillColor('#333333').font('Helvetica')
           .text(opt, cx - 7, cy - 4, { width: 14, align: 'center' });
      });

      y += 18;
    }

    // Footer
    doc.moveDown(1);
    doc.fontSize(9).fillColor('#999999')
       .text('ProveRank | Prove Yourself · Rise to the Top', { align: 'center' });

    doc.end();
    stream.on('finish', () => resolve(filePath));
    stream.on('error', reject);
  });
};

// ─── 3. RESULT REPORT PDF (PDFKit) ──────────────────────────
const generateResultReport = ({ studentName, examTitle, score, totalMarks, correct, wrong, skipped, subject_scores, rank, uniqueId }) => {
  return new Promise((resolve, reject) => {
    const doc = createSimplePDF();
    const filePath = path.join(PDF_DIR, `result_${uniqueId}.pdf`);
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);

    doc.fontSize(22).fillColor('#1a1a2e').font('Helvetica-Bold').text('ProveRank', { align: 'center' });
    doc.fontSize(13).fillColor('#b8860b').font('Helvetica').text('Result Report', { align: 'center' });
    doc.moveDown(0.5);
    doc.moveTo(60, doc.y).lineTo(535, doc.y).strokeColor('#b8860b').lineWidth(1.5).stroke();
    doc.moveDown(0.8);

    doc.fontSize(12).fillColor('#333333');
    doc.text(`Student Name : ${studentName}`);
    doc.text(`Exam Title   : ${examTitle}`);
    doc.text(`Report ID    : ${uniqueId}`);
    doc.moveDown(0.8);

    const boxY = doc.y;
    doc.rect(60, boxY, 475, 80).fillColor('#f0f8ff').fill();
    doc.fontSize(13).fillColor('#1a1a2e').font('Helvetica-Bold')
      .text(`Total Score: ${score} / ${totalMarks}`, 80, boxY + 10)
      .text(`Rank: ${rank}`, 80, boxY + 30)
      .text(`Correct: ${correct}  |  Wrong: ${wrong}  |  Skipped: ${skipped}`, 80, boxY + 50);
    doc.moveDown(5.5);

    doc.fontSize(13).fillColor('#1a1a2e').font('Helvetica-Bold').text('Subject-wise Scores:');
    doc.moveDown(0.4);
    doc.fontSize(12).fillColor('#333333').font('Helvetica');
    if (subject_scores && subject_scores.length > 0) {
      subject_scores.forEach(s => {
        doc.text(`  ${s.subject}: ${s.score} / ${s.total}   (Correct: ${s.correct}, Wrong: ${s.wrong})`);
      });
    }

    doc.moveDown(2);
    doc.moveTo(60, doc.y).lineTo(535, doc.y).strokeColor('#dddddd').lineWidth(1).stroke();
    doc.moveDown(0.5);
    doc.fontSize(10).fillColor('#999999').text('ProveRank — Prove Yourself · Rise to the Top', { align: 'center' });

    doc.end();
    stream.on('finish', () => resolve(filePath));
    stream.on('error', reject);
  });
};

module.exports = { generateCertificate, generateOMRSheet, generateResultReport };
