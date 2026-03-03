const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, 'src/index.js');
let content = fs.readFileSync(filePath, 'utf8');

// Remove existing declarations wherever they are
const imports = [
  `const examFeaturesRoutes   = require('./routes/examFeatures');`,
  `const adminSystemRoutes    = require('./routes/adminSystem');`,
  `const questionFeaturesRoutes = require('./routes/questionFeatures');`,
  `const adminManagementRoutes = require('./routes/adminManagement');`,
];

imports.forEach(imp => {
  // Remove all occurrences
  content = content.split(imp + '\n').join('');
  content = content.split(imp).join('');
});

// Add all imports together at the very top after first require
const firstRequire = content.indexOf("const express = require('express');");
const insertAfter = content.indexOf('\n', firstRequire) + 1;

const allImports = `const examFeaturesRoutes     = require('./routes/examFeatures');
const adminSystemRoutes      = require('./routes/adminSystem');
const questionFeaturesRoutes = require('./routes/questionFeatures');
const adminManagementRoutes  = require('./routes/adminManagement');
`;

content = content.slice(0, insertAfter) + allImports + content.slice(insertAfter);

fs.writeFileSync(filePath, content);
console.log('✅ Import order fixed!');

// Show first 40 lines
console.log('\nFirst 15 app lines:');
content.split('\n').slice(0,15).forEach((l,i) => console.log(`${i+1}: ${l}`));
