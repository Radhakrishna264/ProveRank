const fs = require('fs');
const path = '/home/runner/workspace/src/index.js';
let code = fs.readFileSync(path, 'utf8');

code = code.replace(
  'app.use(cors());',
  `app.use(cors({
  origin: [
    'https://prove-rank.vercel.app',
    'http://localhost:3000',
    'http://localhost:3001'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));`
);

fs.writeFileSync(path, code);
console.log('✅ CORS fix done!');
