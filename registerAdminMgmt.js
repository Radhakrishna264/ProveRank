const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

if (content.includes('adminManagementRoutes')) {
  console.log('⚠️  Already registered'); process.exit(0);
}

content = content.replace(
  /const customFieldsRoutes/,
  `const adminManagementRoutes = require('./routes/adminManagement');\nconst customFieldsRoutes`
);
content = content.replace(
  /app\.use\('\/api\/auth', customFieldsRoutes\)/,
  `app.use('/api/admin', adminManagementRoutes);\napp.use('/api/auth', customFieldsRoutes)`
);

fs.writeFileSync(filePath, content);
console.log('✅ adminManagement route registered!');
