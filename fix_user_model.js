const fs = require('fs');
const p = './src/models/User.js';
let c = fs.readFileSync(p, 'utf8');

if (!c.includes("collection: 'students'")) {
  c = c.replace(
    "mongoose.model('User', userSchema)",
    "mongoose.model('User', userSchema, 'students')"
  );
  fs.writeFileSync(p, c);
  console.log('✅ User model ab students collection use karega!');
} else {
  console.log('Already fixed');
}
