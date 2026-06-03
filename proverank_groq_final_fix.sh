#!/bin/bash
set -e
echo "Fixing groqAI.js..."

# Write new callGroqAI via base64 (avoids all escaping issues)
echo "Ly8gUHJvdmVSYW5rIOKAlCBHcm9xIEFJIFF1ZXN0aW9uIEdlbmVyYXRvcgovLyBNb2RlbDogbGxhbWEtMy4zLTcwYi12ZXJzYXRpbGUgfCBGcmVlOiAxNCw0MDAgcmVxL2RheQoKY29uc3QgY2FsbEdyb3FBSSA9IGFzeW5jIChwcm9tcHQsIHJldHJpZXMpID0+IHsKICBpZiAocmV0cmllcyA9PT0gdW5kZWZpbmVkKSByZXRyaWVzID0gMjsKICBjb25zdCBhcGlLZXkgPSBwcm9jZXNzLmVudi5HUk9RX0FQSV9LRVk7CiAgaWYgKCFhcGlLZXkpIHRocm93IG5ldyBFcnJvcignR1JPUV9BUElfS0VZIG5vdCBjb25maWd1cmVkJyk7CgogIGNvbnN0IGNvbnRyb2xsZXIgPSBuZXcgQWJvcnRDb250cm9sbGVyKCk7CiAgY29uc3QgdGltZXIgPSBzZXRUaW1lb3V0KGZ1bmN0aW9uKCkgeyBjb250cm9sbGVyLmFib3J0KCk7IH0sIDI4MDAwKTsKCiAgdHJ5IHsKICAgIGNvbnN0IHJlc3BvbnNlID0gYXdhaXQgZmV0Y2goJ2h0dHBzOi8vYXBpLmdyb3EuY29tL29wZW5haS92MS9jaGF0L2NvbXBsZXRpb25zJywgewogICAgICBtZXRob2Q6ICdQT1NUJywKICAgICAgaGVhZGVyczogewogICAgICAgICdDb250ZW50LVR5cGUnOiAnYXBwbGljYXRpb24vanNvbicsCiAgICAgICAgJ0F1dGhvcml6YXRpb24nOiAnQmVhcmVyICcgKyBhcGlLZXkKICAgICAgfSwKICAgICAgc2lnbmFsOiBjb250cm9sbGVyLnNpZ25hbCwKICAgICAgYm9keTogSlNPTi5zdHJpbmdpZnkoewogICAgICAgIG1vZGVsOiAnbGxhbWEtMy4zLTcwYi12ZXJzYXRpbGUnLAogICAgICAgIG1lc3NhZ2VzOiBbeyByb2xlOiAndXNlcicsIGNvbnRlbnQ6IHByb21wdCB9XSwKICAgICAgICB0ZW1wZXJhdHVyZTogMC44NSwKICAgICAgICBtYXhfdG9rZW5zOiA0MDk2CiAgICAgIH0pCiAgICB9KTsKCiAgICBjbGVhclRpbWVvdXQodGltZXIpOwoKICAgIGlmICghcmVzcG9uc2Uub2spIHsKICAgICAgY29uc3QgZXJyVGV4dCA9IGF3YWl0IHJlc3BvbnNlLnRleHQoKTsKICAgICAgaWYgKChyZXNwb25zZS5zdGF0dXMgPT09IDQyOSB8fCByZXNwb25zZS5zdGF0dXMgPj0gNTAwKSAmJiByZXRyaWVzID4gMCkgewogICAgICAgIGNvbnN0IHdhaXQgPSByZXNwb25zZS5zdGF0dXMgPT09IDQyOSA/IDQwMDAgOiAyMDAwOwogICAgICAgIGNvbnNvbGUubG9nKCdHcm9xIHJldHJ5IGFmdGVyICcgKyB3YWl0ICsgJ21zIChzdGF0dXMgJyArIHJlc3BvbnNlLnN0YXR1cyArICcpJyk7CiAgICAgICAgYXdhaXQgbmV3IFByb21pc2UoZnVuY3Rpb24ocikgeyBzZXRUaW1lb3V0KHIsIHdhaXQpOyB9KTsKICAgICAgICByZXR1cm4gY2FsbEdyb3FBSShwcm9tcHQsIHJldHJpZXMgLSAxKTsKICAgICAgfQogICAgICB0aHJvdyBuZXcgRXJyb3IoJ0dyb3EgQVBJIEVycm9yICcgKyByZXNwb25zZS5zdGF0dXMgKyAnOiAnICsgZXJyVGV4dC5zbGljZSgwLCAyMDApKTsKICAgIH0KCiAgICBjb25zdCBkYXRhID0gYXdhaXQgcmVzcG9uc2UuanNvbigpOwogICAgY29uc3QgcmF3ID0gKGRhdGEgJiYgZGF0YS5jaG9pY2VzICYmIGRhdGEuY2hvaWNlc1swXSAmJiBkYXRhLmNob2ljZXNbMF0ubWVzc2FnZSAmJiBkYXRhLmNob2ljZXNbMF0ubWVzc2FnZS5jb250ZW50KSA/IGRhdGEuY2hvaWNlc1swXS5tZXNzYWdlLmNvbnRlbnQgOiAnJzsKICAgIGlmICghcmF3KSB0aHJvdyBuZXcgRXJyb3IoJ0VtcHR5IHJlc3BvbnNlIGZyb20gR3JvcScpOwoKICAgIGNvbnN0IGFyclN0YXJ0ID0gcmF3LmluZGV4T2YoJ1snKTsKICAgIGNvbnN0IGFyckVuZCA9IHJhdy5sYXN0SW5kZXhPZignXScpOwogICAgaWYgKGFyclN0YXJ0ID09PSAtMSB8fCBhcnJFbmQgPT09IC0xKSB7CiAgICAgIHRocm93IG5ldyBFcnJvcignTm8gSlNPTiBhcnJheSBpbiByZXNwb25zZS4gR290OiAnICsgcmF3LnNsaWNlKDAsIDIwMCkpOwogICAgfQogICAgY29uc3QganNvblN0ciA9IHJhdy5zbGljZShhcnJTdGFydCwgYXJyRW5kICsgMSk7CgogICAgdHJ5IHsKICAgICAgcmV0dXJuIEpTT04ucGFyc2UoanNvblN0cik7CiAgICB9IGNhdGNoIChlMSkgewogICAgICAvLyBSZW1vdmUgcHJvYmxlbWF0aWMgYmFja3NsYXNoIHNlcXVlbmNlcyBjaGFyIGJ5IGNoYXIKICAgICAgbGV0IGZpeGVkID0gJyc7CiAgICAgIGZvciAobGV0IGkgPSAwOyBpIDwganNvblN0ci5sZW5ndGg7IGkrKykgewogICAgICAgIGNvbnN0IGNoID0ganNvblN0cltpXTsKICAgICAgICBjb25zdCBueCA9IGpzb25TdHJbaSArIDFdOwogICAgICAgIGlmIChjaCA9PT0gJ1xcJyAmJiBueCAhPT0gdW5kZWZpbmVkKSB7CiAgICAgICAgICBpZiAobnggPT09ICciJyB8fCBueCA9PT0gJ1xcJyB8fCBueCA9PT0gJy8nIHx8IG54ID09PSAnYicgfHwgbnggPT09ICdmJyB8fCBueCA9PT0gJ24nIHx8IG54ID09PSAncicgfHwgbnggPT09ICd0JyB8fCBueCA9PT0gJ3UnKSB7CiAgICAgICAgICAgIGZpeGVkICs9IGNoOwogICAgICAgICAgfSBlbHNlIHsKICAgICAgICAgICAgZml4ZWQgKz0gJ1xcXFwnOwogICAgICAgICAgfQogICAgICAgIH0gZWxzZSB7CiAgICAgICAgICBmaXhlZCArPSBjaDsKICAgICAgICB9CiAgICAgIH0KICAgICAgdHJ5IHsKICAgICAgICByZXR1cm4gSlNPTi5wYXJzZShmaXhlZCk7CiAgICAgIH0gY2F0Y2ggKGUyKSB7CiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdKU09OIHBhcnNlIGZhaWxlZDogJyArIGUxLm1lc3NhZ2UpOwogICAgICB9CiAgICB9CgogIH0gY2F0Y2ggKGVycikgewogICAgY2xlYXJUaW1lb3V0KHRpbWVyKTsKICAgIGlmIChlcnIubmFtZSA9PT0gJ0Fib3J0RXJyb3InKSB7CiAgICAgIGlmIChyZXRyaWVzID4gMCkgewogICAgICAgIGF3YWl0IG5ldyBQcm9taXNlKGZ1bmN0aW9uKHIpIHsgc2V0VGltZW91dChyLCAyMDAwKTsgfSk7CiAgICAgICAgcmV0dXJuIGNhbGxHcm9xQUkocHJvbXB0LCByZXRyaWVzIC0gMSk7CiAgICAgIH0KICAgICAgdGhyb3cgbmV3IEVycm9yKCdSZXF1ZXN0IHRpbWVkIG91dC4gUGxlYXNlIHRyeSBhZ2Fpbi4nKTsKICAgIH0KICAgIGlmIChyZXRyaWVzID4gMCAmJiBlcnIubWVzc2FnZSAmJgogICAgICAgICFlcnIubWVzc2FnZS5pbmNsdWRlcygnR1JPUV9BUElfS0VZJykgJiYKICAgICAgICAhZXJyLm1lc3NhZ2UuaW5jbHVkZXMoJ0pTT04gcGFyc2UgZmFpbGVkJykpIHsKICAgICAgYXdhaXQgbmV3IFByb21pc2UoZnVuY3Rpb24ocikgeyBzZXRUaW1lb3V0KHIsIDIwMDApOyB9KTsKICAgICAgcmV0dXJuIGNhbGxHcm9xQUkocHJvbXB0LCByZXRyaWVzIC0gMSk7CiAgICB9CiAgICB0aHJvdyBlcnI7CiAgfQp9OwoK" | base64 -d > /tmp/groq_new_fn.js

# Read existing buildPrompt from current file
node << 'NODE_EOF'
const fs = require('fs');
const newFn = fs.readFileSync('/tmp/groq_new_fn.js', 'utf8');
const current = fs.readFileSync('/home/runner/workspace/src/utils/groqAI.js', 'utf8');

// Get buildPrompt section
const bpIdx = current.indexOf('const buildPrompt');
if (bpIdx === -1) { console.error('buildPrompt not found'); process.exit(1); }
let buildPart = current.slice(bpIdx);

// Update math notation in buildPrompt - replace LaTeX rule
const mathRulePatterns = ['LATEX MATH RULES', 'MATH NOTATION RULES'];
for (const rp of mathRulePatterns) {
  if (buildPart.includes(rp)) {
    const rStart = buildPart.indexOf(rp);
    const rEnd = buildPart.indexOf('\n\n', rStart);
    const endPos = rEnd !== -1 ? rEnd : rStart + 400;
    const newRule = 'MATH NOTATION RULES:\n- Use Unicode: alpha beta gamma omega tau sigma delta pi\n- Powers: v^2, r^2\n- Fractions: a/b (P/Q = R/S)\n- NO backslash commands of any kind';
    buildPart = buildPart.slice(0, rStart) + newRule + buildPart.slice(endPos);
    console.log('Math rule updated');
    break;
  }
}

const finalContent = newFn + '\n' + buildPart;
fs.writeFileSync('/home/runner/workspace/src/utils/groqAI.js', finalContent, 'utf8');
console.log('groqAI.js written, size:', finalContent.length);
NODE_EOF

echo "Testing..."
cd ~/workspace
node -e "
require('dotenv').config({path:'.env'});
const {callGroqAI,buildPrompt}=require('./src/utils/groqAI');
const start=Date.now();
callGroqAI(buildPrompt({subject:'Physics',chapter:'Laws of Motion',topic:'Friction',count:2,difficulty:'medium',type:'SCQ',examLevel:'NEET',formats:['Numerical'],imageUrl:''})).then(function(r){
  console.log('SUCCESS in '+(Date.now()-start)+'ms, q:'+r.length);
  console.log('Q1:',r[0].text.slice(0,80));
}).catch(function(e){ console.error('ERROR:',e.message); });
"

cd ~/workspace && git add -A && git commit -m "fix: groqAI complete rewrite via base64 - char-by-char JSON parser" && git push origin main
echo "Done!"
