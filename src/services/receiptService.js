const PDFDocument = require('pdfkit');

async function generateReceiptPDF(attemptData, res) {
  const doc = new PDFDocument({ margin: 50 });

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename=receipt_${attemptData.attemptId}.pdf`
  );
  doc.pipe(res);

  doc.fontSize(22).font('Helvetica-Bold')
    .text('ProveRank — Exam Attempt Receipt', { align: 'center' });
  doc.moveDown();

  doc.fontSize(12).font('Helvetica')
    .text(`Student: ${attemptData.studentName}`)
    .text(`Exam: ${attemptData.examTitle}`)
    .text(`Attempt ID: ${attemptData.attemptId}`)
    .text(`Date: ${new Date(attemptData.submittedAt).toLocaleString()}`)
    .moveDown();

  doc.fontSize(14).font('Helvetica-Bold').text('Result Summary');
  doc.fontSize(12).font('Helvetica')
    .text(`Score: ${attemptData.score} / ${attemptData.totalMarks}`)
    .text(`Rank: ${attemptData.rank}`)
    .text(`Percentile: ${attemptData.percentile}%`)
    .text(`Correct: ${attemptData.totalCorrect}`)
    .text(`Incorrect: ${attemptData.totalIncorrect}`)
    .text(`Unattempted: ${attemptData.totalUnattempted}`)
    .moveDown();

  if (attemptData.subjectStats) {
    doc.fontSize(14).font('Helvetica-Bold').text('Subject Wise');
    for (const [subject, stats] of Object.entries(attemptData.subjectStats)) {
      doc.fontSize(12).font('Helvetica')
        .text(`${subject}: Score ${stats.score} | C:${stats.correct} W:${stats.incorrect} U:${stats.unattempted}`);
    }
  }

  doc.moveDown(2);
  doc.fontSize(10).fillColor('gray')
    .text('ProveRank — Prove Yourself · Rise to the Top', { align: 'center' });

  doc.end();
}

module.exports = { generateReceiptPDF };
