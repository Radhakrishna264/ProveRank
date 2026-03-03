const fs = require('fs');
const path = './src/models/Question.js';

let content = fs.readFileSync(path, 'utf8');

if (!content.includes("runAIPipeline")) {

  const hook = `
const { runAIPipeline } = require('../services/ai');

questionSchema.pre('save', async function () {
  if (this.isModified('text') || this.isNew) {
    await runAIPipeline(this);
  }
});
`;

  content = content.replace(
    /module\.exports\s*=\s*mongoose\.model\([^\n]+\);/,
    hook + "\nmodule.exports = mongoose.model('Question', questionSchema);"
  );

  fs.writeFileSync(path, content);
  console.log("✔ Clean AI hook added");
} else {
  console.log("AI hook already exists");
}
