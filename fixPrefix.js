const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

content = content.replace(
  "app.use('/api/admin', adminManagementRoutes); // S37/S72/S38/S93/M4",
  "app.use('/api/admin/manage', adminManagementRoutes); // S37/S72/S38/S93/M4"
);

fs.writeFileSync(filePath, content);
console.log('✅ Prefix fixed!');
