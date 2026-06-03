#!/bin/bash
set -e
echo "🔧 ProveRank — Groq AI Complete Fix"

# Read current buildPrompt from file (preserve it)
node << 'REWRITE_EOF'
const fs = require('fs');
const f = '/home/runner/workspace/src/utils/groqAI.js';
let current = fs.readFileSync(f, 'utf8');

// Extract buildPrompt function (keep it, just update LaTeX rule)
const bpStart = current.indexOf('const buildPrompt');
if(bpStart === -1){ console.error('buildPrompt not found'); process.exit(1); }
let buildPromptSection = current.slice(bpStart);

// Fix LaTeX rule in buildPrompt - replace backslash LaTeX with Unicode math
if(buildPromptSection.includes('LATEX MATH RULES') || buildPromptSection.includes('MATH NOTATION RULES')){
  // Find and replace the LaTeX/math rules section
  const rulePatterns = ['LATEX MATH RULES', 'MATH NOTATION RULES'];
  for(const rp of rulePatterns){
    if(buildPromptSection.includes(rp)){
      const rStart = buildPromptSection.indexOf(rp);
      // Find end of this rule section (next empty line or next section marker)
      const rEnd = buildPromptSection.indexOf('\n\n', rStart + rp.length);
      const endPos = rEnd !== -1 ? rEnd : rStart + 300;
      const newRule = `MATH NOTATION RULES:
- Use Unicode symbols for Greek letters: α β γ δ ε θ λ μ π ρ σ τ φ ω Δ
- Powers: v², r², m³ or v^2, r^2  
- Fractions: a/b notation (e.g. P/Q = R/S, τ/I = α)
- Standard notation: U = -GMm/R, F = ma, E = hν, ΔU = mgh
- Units: m/s, m/s², J, W, N, kg, mol, K
- DO NOT use LaTeX backslash commands (no \\frac, \\alpha, \\omega etc.)
- Write naturally readable math that works as plain text`;
      buildPromptSection = buildPromptSection.slice(0, rStart) + newRule + buildPromptSection.slice(endPos);
      console.log('✅ LaTeX rules replaced with Unicode math notation');
      break;
    }
  }
}

// New callGroqAI function - clean version
const newCallFn = `// ProveRank — Groq AI Question Generator
// Model: llama-3.3-70b-versatile | Free: 14,400 req/day

const callGroqAI = async (prompt, retries) => {
  if (retries === undefined) retries = 2;
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY not configured');

  // Timeout controller
  const controller = new AbortController();
  const timer = setTimeout(function() { controller.abort(); }, 28000);

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.85,
        max_tokens: 4096
      })
    });

    clearTimeout(timer);

    // Rate limit or server error — retry
    if (!response.ok) {
      const errText = await response.text();
      if ((response.status === 429 || response.status >= 500) && retries > 0) {
        const wait = response.status === 429 ? 4000 : 2000;
        console.log('Groq retry after ' + wait + 'ms (status ' + response.status + ')');
        await new Promise(function(r) { setTimeout(r, wait); });
        return callGroqAI(prompt, retries - 1);
      }
      throw new Error('Groq API Error ' + response.status + ': ' + errText.slice(0, 200));
    }

    const data = await response.json();
    const raw = (data && data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) ? data.choices[0].message.content : '';
    if (!raw) throw new Error('Empty response from Groq');

    // Find JSON array bounds
    const arrStart = raw.indexOf('[');
    const arrEnd = raw.lastIndexOf(']');
    if (arrStart === -1 || arrEnd === -1) {
      throw new Error('No JSON array in response. Got: ' + raw.slice(0, 200));
    }
    let jsonStr = raw.slice(arrStart, arrEnd + 1);

    // Try direct parse first
    try {
      return JSON.parse(jsonStr);
    } catch (parseErr) {
      // Fix 1: Escape lone backslashes before letters (LaTeX commands like \\alpha, \\omega)
      // Valid JSON escapes after backslash: " \\ / b f n r t u
      // Everything else needs to be doubled
      let fixed = jsonStr.replace(/\\([^"\\\/bfnrtu\d\s])/g, function(match, ch) {
        return '\\\\' + ch;
      });
      try {
        return JSON.parse(fixed);
      } catch (parseErr2) {
        // Fix 2: More aggressive - remove all problematic escape sequences
        let aggressive = fixed.replace(/[\x00-\x1f\x7f]/g, ' ');
        try {
          return JSON.parse(aggressive);
        } catch (parseErr3) {
          throw new Error('JSON parse failed after all fixes: ' + parseErr.message);
        }
      }
    }

  } catch (err) {
    clearTimeout(timer);
    if (err.name === 'AbortError') {
      if (retries > 0) {
        console.log('Groq timeout — retrying...');
        await new Promise(function(r) { setTimeout(r, 2000); });
        return callGroqAI(prompt, retries - 1);
      }
      throw new Error('Request timed out. Please try again.');
    }
    // Retry on network errors (not API key or JSON errors)
    if (retries > 0 && err.message && 
        !err.message.includes('GROQ_API_KEY') && 
        !err.message.includes('JSON parse failed')) {
      await new Promise(function(r) { setTimeout(r, 2000); });
      return callGroqAI(prompt, retries - 1);
    }
    throw err;
  }
};

`;

// Write the new file
const newContent = newCallFn + buildPromptSection;
fs.writeFileSync(f, newContent, 'utf8');
console.log('✅ groqAI.js completely rewritten');
console.log('File size:', newContent.length, 'chars');
REWRITE_EOF

echo ""
echo "▶ Testing Groq..."
cd ~/workspace
node -e "
require('dotenv').config({path:'.env'});
const {callGroqAI,buildPrompt}=require('./src/utils/groqAI');
const start=Date.now();
console.log('Calling Groq API...');
callGroqAI(buildPrompt({
  subject:'Physics',
  chapter:'Laws of Motion',
  topic:'Newton Third Law',
  count:2,
  difficulty:'medium',
  type:'SCQ',
  examLevel:'NEET',
  formats:['Numerical'],
  imageUrl:''
})).then(function(r){
  console.log('✅ SUCCESS in '+(Date.now()-start)+'ms');
  console.log('Questions:', r.length);
  console.log('Q1:', r[0].text.slice(0,100));
  console.log('Explanation words:', r[0].explanation.split(' ').length);
  console.log('ExamLevel:', r[0].examLevel);
}).catch(function(e){
  console.error('❌ ERROR:', e.message);
});
"

echo ""
echo "▶ Git push..."
cd ~/workspace
git add -A
git commit -m "fix: complete groqAI rewrite - Unicode math, retry, safe JSON parser, 28s timeout"
git push origin main
echo "✅ Done!"
