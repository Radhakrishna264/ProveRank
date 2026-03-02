const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

if (content.includes('customFieldsRoutes')) {
  console.log('⚠️  Routes already registered');
  process.exit(0);
}

content = content.replace(
  /const pdfRoutes/,
  `const customFieldsRoutes = require('./routes/customFields');\nconst twoFactorRoutes    = require('./routes/twoFactor');\nconst pdfRoutes`
);

content = content.replace(
  /app\.use\('\/api\/pdf'/,
  `app.use('/api/auth', customFieldsRoutes);\napp.use('/api/auth', twoFactorRoutes);\napp.use('/api/pdf'`
);

fs.writeFileSync(filePath, content);
console.log('✅ Routes registered in index.js!');
