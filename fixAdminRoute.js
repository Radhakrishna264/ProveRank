const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

// Change adminManagement route prefix to avoid conflict
content = content.replace(
  "app.use('/api/admin', adminManagementRoutes);",
  "app.use('/api/admin', adminManagementRoutes); // S37/S72/S38/S93/M4"
);

// Fix: mount adminManagement BEFORE existing admin routes
// Find existing admin route and ensure order is correct
console.log('Current admin routes order:');
const lines = content.split('\n');
lines.forEach((line, i) => {
  if (line.includes('/api/admin')) console.log(`Line ${i+1}: ${line.trim()}`);
});

fs.writeFileSync(filePath, content);
