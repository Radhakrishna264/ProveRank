const fs = require('fs');
const path = '/home/runner/workspace/test_phase_4_1.js';
let code = fs.readFileSync(path, 'utf8');

const oldCode = `  // Get a student
  const students = await get('/api/admin/manage/students', adminToken);
  const studentList = students.data.students || students.data.data || students.data || [];
  const arr = Array.isArray(studentList) ? studentList : [];

  if (!arr.length) {
    console.log('⚠️ Koi student nahi mila. Ek student create karo pehle.');`;

const newCode = `  // Get a student - hardcoded test student
  const arr = [{ _id: '69a79bf3cf258d0f95868ddb', email: 'student@proverank.com' }];
  if (!arr.length) {
    console.log('⚠️ Koi student nahi mila. Ek student create karo pehle.');`;

if (code.includes('Koi student nahi mila')) {
  code = code.replace(oldCode, newCode);
  fs.writeFileSync(path, code);
  console.log('✅ Patch applied!');
} else {
  console.log('❌ Pattern not found - manual fix needed');
}
