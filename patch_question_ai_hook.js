const fs = require('fs');
const path = './src/models/Question.js';

let content = fs.readFileSync(path, 'utf8');

if (!content.includes("runAIPipeline")) {

  const hookCode = `
const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function(next) {
  if (this.isModified('text') || this.isNew) {
    await runAIPipeline(this);
  }
  next();
});
`;

  // Insert before module.exports
  content = content.replace(
    /module\.exports\s*=\s*mongoose\.model\([^\n]+\);/,
    hookCode + "\nmodule.exports = mongoose.model('Question', questionSchema);"
  );

  fs.writeFileSync(path, content);
  console.log("✔ AI hook added to Question model");
} else {
  console.log("AI hook already exists");
}
