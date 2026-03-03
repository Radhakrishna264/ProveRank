const fs = require('fs');
const path = './src/models/Question.js';

let content = fs.readFileSync(path, 'utf8');

// Remove old hook block
content = content.replace(
  /questionSchema\.pre\('save'[\s\S]*?\}\);/g,
  ''
);

// Insert correct async-only hook
const hook = `
const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function() {
  if (this.isModified('text') || this.isNew) {
    await runAIPipeline(this);
  }
});
`;

// Insert before module.exports
content = content.replace(
  /module\.exports\s*=\s*mongoose\.model\([^\n]+\);/,
  hook + "\nmodule.exports = mongoose.model('Question', questionSchema);"
);

fs.writeFileSync(path, content);

console.log("✔ Question AI hook fixed properly");
