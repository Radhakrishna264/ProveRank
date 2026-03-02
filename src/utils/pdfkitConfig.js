const PDFDocument = require('pdfkit');

const createSimplePDF = (options = {}) => {
  const doc = new PDFDocument({
    size: 'A4',
    margins: {
      top: 50,
      bottom: 50,
      left: 60,
      right: 60
    },
    ...options
  });
  return doc;
};

module.exports = { createSimplePDF };
