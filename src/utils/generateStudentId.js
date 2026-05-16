
const User = require('../models/User');

async function generateStudentId() {
  const year = new Date().getFullYear().toString().slice(-2); // "25" or "26"
  const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let id, exists, attempts = 0;
  do {
    const rand = Array.from({length:4}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join('');
    id = 'PR' + year + rand; // e.g. PR25A4B9
    exists = await User.findOne({ studentId: id }).lean();
    attempts++;
    if(attempts > 100) { id = 'PR' + year + Date.now().toString(36).toUpperCase().slice(-4); break; }
  } while(exists);
  return id;
}

module.exports = generateStudentId;
