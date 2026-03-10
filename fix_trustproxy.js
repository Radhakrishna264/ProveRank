const fs = require('fs');
const path = '/home/runner/workspace/src/index.js';
let code = fs.readFileSync(path, 'utf8');

// Add trust proxy before app.use(helmet())
code = code.replace(
  'app.use(helmet());',
  `app.set('trust proxy', 1);
app.use(helmet());`
);

fs.writeFileSync(path, code);
console.log('✅ Trust proxy fix done!');
