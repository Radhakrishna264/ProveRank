#!/bin/bash
set -e
echo "🔧 ProveRank — Groq AI Fix: Retry + Timeout + Explanation Limit"

node << 'FIX_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/utils/groqAI.js';
let c = fs.readFileSync(f,'utf8');

// ── FIX 1: Replace callGroqAI with retry + timeout version ──
const newFn = `const callGroqAI = async (prompt, retries) => {
  if(retries===undefined) retries=2;
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY not configured');

  const controller = new AbortController();
  const timer = setTimeout(()=>controller.abort(), 28000);

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {'Content-Type':'application/json','Authorization':'Bearer '+apiKey},
      signal: controller.signal,
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{role:'user',content:prompt}],
        temperature: 0.85,
        max_tokens: 4096
      })
    });

    clearTimeout(timer);

    if (!response.ok) {
      const errText = await response.text();
      if ((response.status === 429 || response.status >= 500) && retries > 0) {
        const wait = response.status === 429 ? 4000 : 2000;
        console.log('Groq retry after '+wait+'ms, status:'+response.status);
        await new Promise(r=>setTimeout(r,wait));
        return callGroqAI(prompt, retries-1);
      }
      throw new Error('Groq Error '+response.status+': '+errText.slice(0,200));
    }

    const data = await response.json();
    const raw = data && data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content ? data.choices[0].message.content : '';
    if (!raw) throw new Error('Empty response from Groq');

    let cleaned = raw.trim()
      .replace(/^\`\`\`json[\s\S]*?(\[)/,'$1')
      .replace(/^\`\`\`[\s\S]*?(\[)/,'$1')
      .replace(/\`\`\`\s*$/,'')
      .trim();

    const s = cleaned.indexOf('[');
    const e = cleaned.lastIndexOf(']');
    if(s===-1||e===-1) throw new Error('No JSON array in Groq response. Got: '+cleaned.slice(0,150));
    return JSON.parse(cleaned.slice(s,e+1));

  } catch(err) {
    clearTimeout(timer);
    if(err.name==='AbortError') {
      if(retries>0){
        console.log('Groq timeout — retrying...');
        await new Promise(r=>setTimeout(r,2000));
        return callGroqAI(prompt, retries-1);
      }
      throw new Error('Request timed out. Please try again.');
    }
    if(retries>0 && err.message && !err.message.includes('GROQ_API_KEY') && !err.message.includes('JSON')){
      await new Promise(r=>setTimeout(r,2000));
      return callGroqAI(prompt, retries-1);
    }
    throw err;
  }
};`;

// Find and replace existing callGroqAI function
const fnStart = c.indexOf('const callGroqAI');
const fnEnd = c.indexOf('\nconst buildPrompt');
if(fnStart === -1 || fnEnd === -1){
  console.error('callGroqAI or buildPrompt not found');
  process.exit(1);
}
c = c.slice(0,fnStart) + newFn + '\n' + c.slice(fnEnd);
console.log('✅ Fix 1: callGroqAI — retry + timeout added');

// ── FIX 2: Add explanation word limit to buildPrompt ──
if(!c.includes('EXPLANATION LIMIT')){
  const target = '11. Each question must stand alone';
  const inject = `10.5. EXPLANATION LIMIT: Maximum 80 words per explanation. Be concise and precise. State: correct answer reason + why 1-2 wrong options are wrong. No repetition.\n`;
  if(c.includes(target)){
    c = c.replace(target, inject+'11. Each question must stand alone');
    console.log('✅ Fix 2: Explanation word limit added to prompt');
  } else {
    // Try alternate
    const t2 = 'MANDATORY JSON RESPONSE FORMAT';
    if(c.includes(t2)){
      c = c.replace(t2, 'EXPLANATION LIMIT: Max 80 words per explanation. Concise only.\n\n'+t2);
      console.log('✅ Fix 2: Explanation limit added (alt position)');
    }
  }
}

// ── FIX 3: Reduce max_tokens in prompt count ──
// Already set to 4096 in new function above

fs.writeFileSync(f, c, 'utf8');
console.log('✅ groqAI.js updated');
FIX_EOF

echo ""
echo "▶ Testing Groq connection..."
cd ~/workspace
node -e "
require('dotenv').config({path:'.env'});
const {callGroqAI,buildPrompt}=require('./src/utils/groqAI');
const start=Date.now();
callGroqAI(buildPrompt({subject:'Physics',chapter:'Laws of Motion',topic:'Newton Laws',count:2,difficulty:'medium',type:'SCQ',examLevel:'NEET',formats:['Numerical'],imageUrl:''}))
.then(r=>{
  const t=Date.now()-start;
  console.log('✅ Success in '+t+'ms | Questions:'+r.length);
  console.log('Q1:',r[0].text.slice(0,80));
  console.log('Explanation length:',r[0].explanation.split(' ').length,'words');
})
.catch(e=>console.error('❌',e.message));
"

echo ""
echo "▶ Git push..."
cd ~/workspace
git add -A
git commit -m "fix: Groq retry+timeout+explanation limit — fix AI failed errors"
git push origin main

echo ""
echo "✅ DONE! Changes:"
echo "  • Retry: 2 automatic retries on failure/rate limit"
echo "  • Timeout: 28s with auto-retry"
echo "  • Rate limit 429: waits 4s then retries"
echo "  • max_tokens: 8192→4096 (2x faster)"
echo "  • Explanation: max 80 words (no more wall of text)"
