const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');
let changed = false;

const toAdd = [
  {
    check: 'examFeaturesRoutes',
    imp: `const examFeaturesRoutes   = require('./routes/examFeatures');`,
    use: `app.use('/api/exams', examFeaturesRoutes);`
  },
  {
    check: 'adminSystemRoutes',
    imp: `const adminSystemRoutes    = require('./routes/adminSystem');`,
    use: `app.use('/api/admin', adminSystemRoutes);`
  },
  {
    check: 'questionFeaturesRoutes',
    imp: `const questionFeaturesRoutes = require('./routes/questionFeatures');`,
    use: `app.use('/api/questions', questionFeaturesRoutes);`
  }
];

toAdd.forEach(r => {
  if (!content.includes(r.check)) {
    content = content.replace(
      /const adminManagementRoutes/,
      `${r.imp}\nconst adminManagementRoutes`
    );
    content = content.replace(
      /app\.use\('\/api\/admin\/manage'/,
      `${r.use}\napp.use('/api/admin/manage'`
    );
    console.log(`✅ ${r.check} registered`);
    changed = true;
  } else {
    console.log(`⚠️  ${r.check} already registered`);
  }
});

if (changed) fs.writeFileSync(filePath, content);
console.log('\nCurrent routes:');
content.split('\n').forEach((l,i) => { if(l.includes('app.use(')) console.log(`${i+1}: ${l.trim()}`); });
