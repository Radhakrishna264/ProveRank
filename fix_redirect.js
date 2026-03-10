const fs = require('fs');
const path = '/home/runner/workspace/frontend/app/login/page.tsx';
let code = fs.readFileSync(path, 'utf8');

// router.push ki jagah window.location.href — force full reload
code = code.replace(
  "if (data.role === 'superadmin') router.push('/superadmin');",
  "if (data.role === 'superadmin') window.location.href = '/superadmin';"
);
code = code.replace(
  "else if (data.role === 'admin') router.push('/admin');",
  "else if (data.role === 'admin') window.location.href = '/admin';"
);
code = code.replace(
  "else router.push('/dashboard');",
  "else window.location.href = '/dashboard';"
);

fs.writeFileSync(path, code);
console.log('✅ Redirect fix done!');
