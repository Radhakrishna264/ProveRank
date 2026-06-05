const fs = require('fs'), os = require('os');
const FILE = os.homedir() + '/workspace/src/utils/groqAI.js';
const BAK = FILE + '.bak_multilayer';

let current = fs.readFileSync(FILE, 'utf8');
fs.writeFileSync(BAK, current, 'utf8');
console.log('Backup created');

// Extract buildPrompt function (keep exactly as-is)
const bpStart = current.indexOf('\nconst buildPrompt');
const bpEnd = current.indexOf('\nmodule.exports');
if(bpStart===-1||bpEnd===-1){console.error('❌ buildPrompt or exports not found');process.exit(1);}
const buildPromptFn = current.slice(bpStart, bpEnd);

// New callGroqAI with 10-layer fallback
const newCallGroqAI = `
// ══════════════════════════════════════════════════════
// ProveRank — 10-Layer AI Fallback System
// L1: Groq | L2: Cerebras | L3: OpenRouter | L4: Fireworks
// L5: HuggingFace | L6: Cohere | L7: Mistral | L8: Cloudflare
// L9: Novita | L10: Groq Fallback Models
// ══════════════════════════════════════════════════════

const TIMEOUT_MS = 30000;

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), ms))
  ]);
}

// Parse OpenAI-compatible response
function parseOAIResponse(data) {
  if (data && data.choices && data.choices[0] && data.choices[0].message) {
    return data.choices[0].message.content;
  }
  return null;
}

// Parse JSON questions from text
function parseQuestions(text) {
  if (!text) return null;
  try {
    const clean = text.replace(/\`\`\`json/g,'').replace(/\`\`\`/g,'').trim();
    const arr = JSON.parse(clean);
    if (Array.isArray(arr) && arr.length > 0) return arr;
  } catch(e) {}
  try {
    const match = text.match(/\[[\s\S]*\]/);
    if (match) {
      const arr = JSON.parse(match[0]);
      if (Array.isArray(arr) && arr.length > 0) return arr;
    }
  } catch(e) {}
  return null;
}

// Layer 1: Groq
async function tryGroq(prompt, model) {
  const key = process.env.GROQ_API_KEY;
  if (!key) throw new Error('No GROQ_API_KEY');
  const m = model || 'llama-3.3-70b-versatile';
  const res = await withTimeout(fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: m, max_tokens: 4000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Groq ' + res.status + ': ' + (data.error && data.error.message || ''));
  return parseOAIResponse(data);
}

// Layer 2: Cerebras
async function tryCerebras(prompt) {
  const key = process.env.CEREBRAS_API_KEY;
  if (!key) throw new Error('No CEREBRAS_API_KEY');
  const res = await withTimeout(fetch('https://api.cerebras.ai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'llama-3.3-70b', max_tokens: 4000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Cerebras ' + res.status + ': ' + (data.error && data.error.message || ''));
  return parseOAIResponse(data);
}

// Layer 3: OpenRouter
async function tryOpenRouter(prompt) {
  const key = process.env.OPENROUTER_API_KEY;
  if (!key) throw new Error('No OPENROUTER_API_KEY');
  const res = await withTimeout(fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + key,
      'HTTP-Referer': 'https://proverank.onrender.com',
      'X-Title': 'ProveRank'
    },
    body: JSON.stringify({
      model: 'meta-llama/llama-3.3-70b-instruct:free',
      max_tokens: 4000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('OpenRouter ' + res.status + ': ' + (data.error && data.error.message || ''));
  return parseOAIResponse(data);
}

// Layer 4: Fireworks AI
async function tryFireworks(prompt) {
  const key = process.env.FIREWORKS_API_KEY;
  if (!key) throw new Error('No FIREWORKS_API_KEY');
  const res = await withTimeout(fetch('https://api.fireworks.ai/inference/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'accounts/fireworks/models/llama-v3p3-70b-instruct',
      max_tokens: 4000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Fireworks ' + res.status + ': ' + (data.error && data.error.message || ''));
  return parseOAIResponse(data);
}

// Layer 5: HuggingFace
async function tryHuggingFace(prompt) {
  const key = process.env.HF_API_KEY;
  if (!key) throw new Error('No HF_API_KEY');
  const res = await withTimeout(fetch('https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'Qwen/Qwen2.5-72B-Instruct',
      max_tokens: 3000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('HuggingFace ' + res.status + ': ' + (data.error || ''));
  return parseOAIResponse(data);
}

// Layer 6: Cohere
async function tryCohere(prompt) {
  const key = process.env.COHERE_API_KEY;
  if (!key) throw new Error('No COHERE_API_KEY');
  const res = await withTimeout(fetch('https://api.cohere.com/v2/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'command-r-plus',
      max_tokens: 3000, temperature: 0.7,
      messages: [{ role: 'user', content: prompt }]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Cohere ' + res.status + ': ' + (data.message || ''));
  if (data.message && data.message.content && data.message.content[0]) {
    return data.message.content[0].text;
  }
  return null;
}

// Layer 7: Mistral
async function tryMistral(prompt) {
  const key = process.env.MISTRAL_API_KEY;
  if (!key) throw new Error('No MISTRAL_API_KEY');
  const res = await withTimeout(fetch('https://api.mistral.ai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'mistral-small-latest',
      max_tokens: 3000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Mistral ' + res.status + ': ' + (data.message || ''));
  return parseOAIResponse(data);
}

// Layer 8: Cloudflare Workers AI
async function tryCloudflare(prompt) {
  const key = process.env.CLOUDFLARE_API_KEY;
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  if (!key || !accountId) throw new Error('No CLOUDFLARE keys');
  const model = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
  const res = await withTimeout(fetch('https://api.cloudflare.com/client/v4/accounts/' + accountId + '/ai/run/' + model, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      max_tokens: 3000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok || !data.success) throw new Error('Cloudflare ' + res.status);
  if (data.result && data.result.response) return data.result.response;
  return parseOAIResponse(data.result);
}

// Layer 9: Novita AI
async function tryNovita(prompt) {
  const key = process.env.NOVITA_API_KEY;
  if (!key) throw new Error('No NOVITA_API_KEY');
  const res = await withTimeout(fetch('https://api.novita.ai/v3/openai/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: 'meta-llama/llama-3.3-70b-instruct',
      max_tokens: 3000, temperature: 0.7,
      messages: [
        { role: 'system', content: 'You are a strict question formatter. Follow the specified FORMAT exactly.' },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  const data = await res.json();
  if (!res.ok) throw new Error('Novita ' + res.status + ': ' + (data.error && data.error.message || ''));
  return parseOAIResponse(data);
}

// Main callGroqAI with 10-layer fallback
const callGroqAI = async (prompt) => {
  const layers = [
    { name: 'L1-Groq-70B',           fn: () => tryGroq(prompt, 'llama-3.3-70b-versatile') },
    { name: 'L2-Cerebras-70B',        fn: () => tryCerebras(prompt) },
    { name: 'L3-OpenRouter',          fn: () => tryOpenRouter(prompt) },
    { name: 'L4-Fireworks',           fn: () => tryFireworks(prompt) },
    { name: 'L5-HuggingFace',         fn: () => tryHuggingFace(prompt) },
    { name: 'L6-Cohere',              fn: () => tryCohere(prompt) },
    { name: 'L7-Mistral',             fn: () => tryMistral(prompt) },
    { name: 'L8-Cloudflare',          fn: () => tryCloudflare(prompt) },
    { name: 'L9-Novita',              fn: () => tryNovita(prompt) },
    { name: 'L10-Groq-gemma2',        fn: () => tryGroq(prompt, 'gemma2-9b-it') },
    { name: 'L10-Groq-mixtral',       fn: () => tryGroq(prompt, 'mixtral-8x7b-32768') },
    { name: 'L10-Groq-llama-8b',      fn: () => tryGroq(prompt, 'llama-3.1-8b-instant') },
  ];

  for (const layer of layers) {
    try {
      console.log('[AI] Trying ' + layer.name + '...');
      const text = await layer.fn();
      const questions = parseQuestions(text);
      if (questions && questions.length > 0) {
        console.log('[AI] ✅ Success: ' + layer.name + ' — ' + questions.length + ' questions');
        return questions;
      }
      console.log('[AI] ' + layer.name + ' returned no valid questions, trying next...');
    } catch (err) {
      console.log('[AI] ' + layer.name + ' failed: ' + err.message);
    }
  }

  console.error('[AI] ❌ All 10 layers exhausted');
  return [];
};

`;

// Build final file
const exportsLine = `\nmodule.exports = { callGroqAI, buildPrompt };\n`;
const newContent = newCallGroqAI + buildPromptFn + exportsLine;

fs.writeFileSync(FILE, newContent, 'utf8');
console.log('✅ groqAI.js written with 10-layer fallback');

// Verify
const checks = [
  ['callGroqAI function', 'const callGroqAI = async'],
  ['buildPrompt function', 'const buildPrompt'],
  ['Layer 1 Groq', 'tryGroq'],
  ['Layer 2 Cerebras', 'tryCerebras'],
  ['Layer 3 OpenRouter', 'tryOpenRouter'],
  ['Layer 4 Fireworks', 'tryFireworks'],
  ['Layer 5 HuggingFace', 'tryHuggingFace'],
  ['Layer 6 Cohere', 'tryCohere'],
  ['Layer 7 Mistral', 'tryMistral'],
  ['Layer 8 Cloudflare', 'tryCloudflare'],
  ['Layer 9 Novita', 'tryNovita'],
  ['Layer 10 fallback', 'L10-Groq-gemma2'],
  ['module.exports', 'module.exports = { callGroqAI, buildPrompt }'],
];
const content = fs.readFileSync(FILE, 'utf8');
let allOk = true;
checks.forEach(([name, needle]) => {
  const ok = content.includes(needle);
  if (!ok) allOk = false;
  console.log((ok ? '✅' : '❌') + ' ' + name);
});
console.log(allOk ? '\n✅ ALL CHECKS PASSED' : '\n❌ SOME CHECKS FAILED');
