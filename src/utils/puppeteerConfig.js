// html-pdf-node wrapper — Replit compatible
const htmlPdf = require('html-pdf-node');

const generatePdfFromHtml = async (htmlContent, options = {}) => {
  const file = { content: htmlContent };
  const defaultOptions = {
    format: 'A4',
    printBackground: true,
    ...options
  };
  const pdfBuffer = await htmlPdf.generatePdf(file, defaultOptions);
  return pdfBuffer;
};

module.exports = { generatePdfFromHtml };
