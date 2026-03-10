const crypto = require('crypto');
const ALGORITHM = 'aes-256-cbc';
const getKey = () => Buffer.from((process.env.EXAM_ENCRYPTION_KEY || 'proverank_exam_key_32chars_secure').padEnd(32,'0').slice(0,32));
const encryptData = (text) => {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, getKey(), iv);
  let enc = cipher.update(JSON.stringify(text), 'utf8', 'hex');
  enc += cipher.final('hex');
  return iv.toString('hex') + ':' + enc;
};
const decryptData = (encText) => {
  const [ivHex, enc] = encText.split(':');
  const decipher = crypto.createDecipheriv(ALGORITHM, getKey(), Buffer.from(ivHex,'hex'));
  let dec = decipher.update(enc,'hex','utf8');
  dec += decipher.final('utf8');
  return JSON.parse(dec);
};
module.exports = { encryptData, decryptData };
