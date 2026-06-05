const fs = require('fs');
const os = require('os');
const FILE = os.homedir() + '/workspace/src/utils/groqAI.js';

// Backup
fs.copyFileSync(FILE, FILE + '.bak_v2layers');

// Read current file to extract buildPrompt
const current = fs.readFileSync(FILE, 'utf8');
const bpStart = current.indexOf('\nconst buildPrompt');
const bpEnd = current.indexOf('\nmodule.exports');
if(bpStart===-1||bpEnd===-1){console.error('❌ buildPrompt not found');process.exit(1);}
const buildPromptFn = current.slice(bpStart, bpEnd);

const newContent = `
// ══════════════════════════════════════════════════════════════════
// ProveRank — 20-Layer AI Fallback System v2
// L1: Groq | L2: Mistral(orig) | L3: NVIDIA NIM
// L4-L16: Mistral Keys 1-13 | L17: SambaNova | L18: DeepInfra
// L19: Cerebras | L20: Cloudflare
// ══════════════════════════════════════════════════════════════════

const TIMEOUT_MS = 30000;

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise(function(_, reject) {
      setTimeout(function() { reject(new Error('Timeout')); }, ms);
    })
  ]);
}

function parseOAIResponse(data) {
  if (data && data.choices && data.choices[0] && data.choices[0].message) {
    return data.choices[0].message.content;
  }
  return null;
}

function parseQuestions(text) {
  if (!text) return null;
  try {
    var clean = text.replace(/\`\`\`json/g,'').replace(/\`\`\`/g,'').trim();
    var arr = JSON.parse(clean);
    if (Array.isArray(arr) && arr.length > 0) return arr;
  } catch(e) {}
  try {
    var match = text.match(/\[[\s\S]*\]/);
    if (match) {
      var arr2 = JSON.parse(match[0]);
      if (Array.isArray(arr2) && arr2.length > 0) return arr2;
    }
  } catch(e2) {}
  return null;
}

var SYS_MSG = 'You are a strict NCERT question formatter. Return ONLY a valid JSON array. No markdown, no explanation, no text outside the array. Follow the specified FORMAT exactly for every question.';

// ── OpenAI-compatible helper ──
async function callOAI(url, key, model, prompt, extraHeaders) {
  var headers = { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key };
  if (extraHeaders) Object.assign(headers, extraHeaders);
  var res = await withTimeout(fetch(url, {
    method: 'POST',
    headers: headers,
    body: JSON.stringify({
      model: model, max_tokens: 4000, temperature: 0.7,
      messages: [
        { role: 'system', content: SYS_MSG },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  var data = await res.json();
  if (!res.ok) throw new Error(url.split('/')[2] + ' ' + res.status + ': ' + JSON.stringify(data).slice(0,100));
  return parseOAIResponse(data);
}

// L1: Groq
async function tryGroq(prompt, model) {
  var key = process.env.GROQ_API_KEY;
  if (!key) throw new Error('No GROQ_API_KEY');
  return callOAI('https://api.groq.com/openai/v1/chat/completions', key, model || 'llama-3.3-70b-versatile', prompt);
}

// L2 & L4-L16: Mistral (any key)
async function tryMistral(prompt, key) {
  var k = key || process.env.MISTRAL_API_KEY;
  if (!k) throw new Error('No MISTRAL key');
  return callOAI('https://api.mistral.ai/v1/chat/completions', k, 'mistral-small-latest', prompt);
}

// L3: NVIDIA NIM
async function tryNvidia(prompt) {
  var key = process.env.NVIDIA_API_KEY;
  if (!key) throw new Error('No NVIDIA_API_KEY');
  return callOAI(
    'https://integrate.api.nvidia.com/v1/chat/completions',
    key, 'meta/llama-3.3-70b-instruct', prompt,
    { 'Accept': 'application/json' }
  );
}

// L17: SambaNova
async function trySambaNova(prompt) {
  var key = process.env.SAMBANOVA_API_KEY;
  if (!key) throw new Error('No SAMBANOVA_API_KEY');
  return callOAI('https://api.sambanova.ai/v1/chat/completions', key, 'Meta-Llama-3.3-70B-Instruct', prompt);
}

// L18: DeepInfra
async function tryDeepInfra(prompt) {
  var key = process.env.DEEPINFRA_API_KEY;
  if (!key) throw new Error('No DEEPINFRA_API_KEY');
  return callOAI('https://api.deepinfra.com/v1/openai/chat/completions', key, 'meta-llama/Llama-3.3-70B-Instruct', prompt);
}

// L19: Cerebras
async function tryCerebras(prompt) {
  var key = process.env.CEREBRAS_API_KEY;
  if (!key) throw new Error('No CEREBRAS_API_KEY');
  return callOAI('https://api.cerebras.ai/v1/chat/completions', key, 'llama3.1-70b', prompt);
}

// L20: Cloudflare Workers AI
async function tryCloudflare(prompt) {
  var key = process.env.CLOUDFLARE_API_KEY;
  var accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  if (!key || !accountId) throw new Error('No CLOUDFLARE keys');
  var model = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
  var res = await withTimeout(fetch('https://api.cloudflare.com/client/v4/accounts/' + accountId + '/ai/run/' + model, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      max_tokens: 3000, temperature: 0.7,
      messages: [
        { role: 'system', content: SYS_MSG },
        { role: 'user', content: prompt }
      ]
    })
  }), TIMEOUT_MS);
  var data = await res.json();
  if (!res.ok || !data.success) throw new Error('Cloudflare ' + res.status);
  if (data.result && data.result.response) return data.result.response;
  return parseOAIResponse(data.result);
}

// ── Main 20-Layer callGroqAI ──
const callGroqAI = async function(prompt) {
  var mistralKeys = [
    process.env.MISTRAL_API_KEY,
    process.env.MISTRAL_API_KEY_1,
    process.env.MISTRAL_API_KEY_2,
    process.env.MISTRAL_API_KEY_3,
    process.env.MISTRAL_API_KEY_4,
    process.env.MISTRAL_API_KEY_5,
    process.env.MISTRAL_API_KEY_6,
    process.env.MISTRAL_API_KEY_7,
    process.env.MISTRAL_API_KEY_8,
    process.env.MISTRAL_API_KEY_9,
    process.env.MISTRAL_API_KEY_10,
    process.env.MISTRAL_API_KEY_11,
    process.env.MISTRAL_API_KEY_12,
    process.env.MISTRAL_API_KEY_13,
  ].filter(Boolean);

  var layers = [
    { name: 'L1-Groq-70B',           fn: function() { return tryGroq(prompt); } },
    { name: 'L2-Mistral-orig',        fn: function() { return tryMistral(prompt, null); } },
    { name: 'L3-NVIDIA-LLaMA70B',     fn: function() { return tryNvidia(prompt); } },
  ];

  // L4-L16: Mistral keys 1-13
  mistralKeys.slice(1).forEach(function(key, idx) {
    layers.push({
      name: 'L' + (idx + 4) + '-Mistral-key' + (idx + 1),
      fn: (function(k) { return function() { return tryMistral(prompt, k); }; })(key)
    });
  });

  // L17-L20
  layers.push({ name: 'L17-SambaNova',   fn: function() { return trySambaNova(prompt); } });
  layers.push({ name: 'L18-DeepInfra',   fn: function() { return tryDeepInfra(prompt); } });
  layers.push({ name: 'L19-Cerebras',    fn: function() { return tryCerebras(prompt); } });
  layers.push({ name: 'L20-Cloudflare',  fn: function() { return tryCloudflare(prompt); } });

  // Groq fallback models at the end
  layers.push({ name: 'LX-Groq-llama70b',  fn: function() { return tryGroq(prompt, 'llama-3.1-70b-versatile'); } });
  layers.push({ name: 'LX-Groq-llama3',    fn: function() { return tryGroq(prompt, 'llama3-70b-8192'); } });

  for (var i = 0; i < layers.length; i++) {
    var layer = layers[i];
    try {
      console.log('[AI] Trying ' + layer.name + '...');
      var text = await layer.fn();
      var questions = parseQuestions(text);
      if (questions && questions.length > 0) {
        console.log('[AI] ✅ Success: ' + layer.name + ' — ' + questions.length + ' questions');
        return questions;
      }
      console.log('[AI] ' + layer.name + ' returned no valid questions, trying next...');
    } catch (err) {
      console.log('[AI] ' + layer.name + ' failed: ' + err.message.slice(0, 100));
    }
  }

  console.error('[AI] ❌ All layers exhausted');
  return [];
};

`;

const exportsLine = '\nmodule.exports = { callGroqAI, buildPrompt };\n';
fs.writeFileSync(FILE, newContent + buildPromptFn + exportsLine, 'utf8');

// Verify
const written = fs.readFileSync(FILE, 'utf8');
const checks = [
  ['callGroqAI', 'const callGroqAI'],
  ['buildPrompt', 'const buildPrompt'],
  ['L1 Groq', 'tryGroq'],
  ['L2 Mistral', 'tryMistral'],
  ['L3 NVIDIA', 'tryNvidia'],
  ['L17 SambaNova', 'trySambaNova'],
  ['L18 DeepInfra', 'tryDeepInfra'],
  ['L19 Cerebras', 'tryCerebras'],
  ['L20 Cloudflare', 'tryCloudflare'],
  ['Mistral keys loop', 'MISTRAL_API_KEY_13'],
  ['module.exports', 'module.exports = { callGroqAI, buildPrompt }'],
];
var allOk = true;
checks.forEach(function(c) {
  var ok = written.includes(c[1]);
  if (!ok) allOk = false;
  console.log((ok ? '✅' : '❌') + ' ' + c[0]);
});
console.log(allOk ? '\n✅ ALL CHECKS PASSED' : '\n❌ SOME FAILED');
