const fs = require('fs');
const path = './src/models/Question.js';

let content = fs.readFileSync(path, 'utf8');

// Remove all runAIPipeline imports
content = content.replace(/const\s+\{\s*runAIPipeline\s*\}\s*=\s*require\([^\n]+\);\n?/g, '');

// Remove all pre save hooks
content = content.replace(/questionSchema\.pre\('save'[\s\S]*?\}\);/g, '');

// Remove duplicate exports if broken
content = content.replace(/module\.exports\s*=\s*mongoose\.model\('Question',\s*questionSchema\);\s*module\.exports\s*=\s*mongoose\.model\('Question',\s*questionSchema\);/g, 
"module.exports = mongoose.model('Question', questionSchema);"
);

fs.writeFileSync(path, content);

console.log("✔ Question.js cleaned");
