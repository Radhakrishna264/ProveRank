const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

// Step 1: Remove new routes from current positions
content = content.replace(/app\.use\('\/api\/exams', examFeaturesRoutes\);\n?/g, '');
content = content.replace(/app\.use\('\/api\/admin', adminSystemRoutes\);\n?/g, '');
content = content.replace(/app\.use\('\/api\/questions', questionFeaturesRoutes\);\n?/g, '');
content = content.replace(/app\.use\('\/api\/admin\/manage', adminManagementRoutes\);[^\n]*\n?/g, '');

// Step 2: Mount them BEFORE existing conflicting routes
// Before existing exam route
content = content.replace(
  /app\.use\('\/api\/exams', require\('\.\/routes\/exam'\)\);/,
  `app.use('/api/exams', examFeaturesRoutes);       // S5/S75/S85/S26/S62/S31/S96\napp.use('/api/exams', require('./routes/exam'));`
);

// Before existing questions route
content = content.replace(
  /app\.use\('\/api\/questions', questionRoutes\);/,
  `app.use('/api/questions', questionFeaturesRoutes); // AI-1/AI-2/S33/S35/MCQ/MSQ\napp.use('/api/questions', questionRoutes);`
);

// Before existing admin route
content = content.replace(
  /app\.use\('\/api\/admin', require\('\.\/routes\/admin'\)\);/,
  `app.use('/api/admin/manage', adminManagementRoutes); // S37/S72/S38/S93/M4\napp.use('/api/admin', adminSystemRoutes);        // S66/N21\napp.use('/api/admin', require('./routes/admin'));`
);

fs.writeFileSync(filePath, content);
console.log('✅ Route order fixed!');
console.log('\nNew order:');
content.split('\n').forEach((l,i) => {
  if(l.includes('app.use(')) console.log(`${i+1}: ${l.trim()}`);
});
