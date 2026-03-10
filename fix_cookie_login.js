const fs = require('fs');
const path = '/home/runner/workspace/frontend/app/login/page.tsx';
let code = fs.readFileSync(path, 'utf8');

// localStorage ke saath cookies bhi set karo
code = code.replace(
  "localStorage.setItem('pr_token', data.token);",
  `localStorage.setItem('pr_token', data.token);
        document.cookie = \`pr_token=\${data.token};path=/;max-age=604800;SameSite=Lax\`;`
);

code = code.replace(
  "localStorage.setItem('pr_role', data.role || 'student');",
  `localStorage.setItem('pr_role', data.role || 'student');
        document.cookie = \`pr_role=\${data.role || 'student'};path=/;max-age=604800;SameSite=Lax\`;`
);

fs.writeFileSync(path, code);
console.log('✅ Cookie fix done!');
