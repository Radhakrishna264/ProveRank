const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

// Fix: /api/admin/manage prefix ensure karo
if (content.includes("app.use('/api/admin', adminManagementRoutes)")) {
  content = content.replace(
    "app.use('/api/admin', adminManagementRoutes);",
    "app.use('/api/admin/manage', adminManagementRoutes);"
  );
  console.log('✅ Route prefix fixed to /api/admin/manage');
} else if (content.includes("app.use('/api/admin/manage', adminManagementRoutes)")) {
  console.log('⚠️  Already correct prefix');
} else {
  console.log('❌ adminManagementRoutes line nahi mili — check karo');
}

fs.writeFileSync(filePath, content);
console.log('Current admin routes:');
content.split('\n').forEach((l,i) => { if(l.includes('admin')) console.log(`${i+1}: ${l.trim()}`); });
