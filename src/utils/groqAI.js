
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
    const clean = text.replace(/```json/g,'').replace(/```/g,'').trim();
    const arr = JSON.parse(clean);
    if (Array.isArray(arr) && arr.length > 0) return arr;
  } catch(e) {}
  try {
    const match = text.match(/[[sS]*]/);
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
      model: 'llama3.1-70b', max_tokens: 4000, temperature: 0.7,
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
      model: 'accounts/fireworks/models/deepseek-v4-pro',
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
      model: 'c4ai-aya-expanse-32b',
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


const buildPrompt = ({ subject, chapter, topic, count, difficulty, type, examLevel, formats, imageUrl }) => {
  const seed = `${Date.now()}-${Math.floor(Math.random() * 999999)}`;
  const n = Math.min(parseInt(count) || 5, 30);
  const lvl = examLevel || 'NEET';
  const diff = (difficulty || 'medium').toLowerCase();
  const qtype = type || 'SCQ';
  const img = imageUrl || '';
  const selectedFormats = (Array.isArray(formats) && formats.length > 0) ? formats : ['Random'];

  // ── Exam Level Guidelines ──────────────────────────
  const examGuide = {
    NEET: 'NEET UG standard. NCERT Biology/Physics/Chemistry based. Concept recall + application. Match exact difficulty and terminology of NEET papers 2018-2024. Use NCERT phrasing.',
    JEE_MAINS: 'JEE Main standard. NTA pattern. Moderate-high difficulty. Mix of theory + calculation. Physics/Chemistry/Math. Direct formula application + multi-step problems.',
    JEE_ADVANCED: 'JEE Advanced standard — highest difficulty in India. Multi-concept integration required. Deceptive distractors. Paragraph/linked questions possible. Requires deep NCERT + beyond understanding.',
    CUET: 'CUET UG standard. 12th board level. NCERT verbatim concepts. Straightforward MCQ. Moderate difficulty. Suitable for Class 12 students.',
    BOARD: 'CBSE/State Board standard. Direct NCERT concept questions. Definition recall, basic application. Easy to moderate. Class 11-12 level.',
    OTHER: 'General competitive exam standard. Balanced difficulty. Conceptual + application mix.'
  };

  // ── Question Type Instructions ──────────────────────
  const typeInstr = {
    SCQ: 'SINGLE CORRECT TYPE: Exactly ONE option (A/B/C/D) is correct. The other 3 must be scientifically plausible but definitively wrong. "correct" array has exactly 1 index [0-3].',
    MSQ: 'MULTIPLE SELECT TYPE (JEE Advanced style): 2 or 3 options are correct (NEVER all 4, NEVER only 1). Student must identify ALL correct options. "correct" array has 2 or 3 indices. Partial marking applies.',
    Integer: 'INTEGER/NUMERICAL TYPE: No options needed. Answer is a specific non-negative integer. "options" MUST be empty array []. "correct" MUST be [answer_as_number]. Provide all data needed to calculate.'
  };

  // ── Format Instructions ──────────────────────────────
  const fmtGuide = {
    Random: `Choose the MOST VARIED and APPROPRIATE format per question. Rotate across different styles — avoid repeating same structure. Prefer analytical/application/multi-step over simple recall.`,

    Statement_Based: `STATEMENT-BASED: Write exactly 2 or 3 numbered statements about ${topic}. Each statement is either correct or incorrect scientifically.
Question: "Which of the following statement(s) is/are correct?"
Options MUST follow pattern: A) Only Statement I, B) Only Statement II, C) Both I and II, D) Neither I nor II (adjust for 3 statements if needed).`,

    Assertion_Reason: `ASSERTION-REASON FORMAT:
Assertion (A): [Write a factual statement about ${topic}]
Reason (R): [Write related mechanism/explanation]
Options MUST be EXACTLY these 4 (do not modify):
A) Both A and R are true, and R is the correct explanation of A
B) Both A and R are true, but R is NOT the correct explanation of A
C) A is true but R is false
D) A is false but R is true
Vary which option letter is correct across questions.`,

    True_False: `TRUE/FALSE FORMAT: Write 4 distinct statements about ${topic}. Question: "Which of the following are TRUE (T) and FALSE (F) in the given order?"
Options are 4 different T/F combinations e.g.:
A) T, T, F, F  B) T, F, T, F  C) F, T, T, F  D) T, F, F, T`,

    Numerical: `NUMERICAL/CALCULATION BASED: Provide specific numerical data, measurements, or values. Student must calculate/derive the answer.
All required data MUST be given in the question. For SCQ: options are 4 different numerical values with units. For Integer: exact integer result.
Use realistic values relevant to ${subject} (e.g., actual atomic weights, standard g=9.8 m/s², etc.)`,

    Fill_Blanks: `FILL IN THE BLANK: Write a meaningful, important scientific sentence about ${topic} with ONE key term/value replaced by "___________".
The blank must be a specific concept, term, formula component, or value — not a generic word.
Options are 4 different possible fill-ins (only 1 scientifically correct).`,

    Match_Column: `MATCH THE COLUMN: Create Column I (items A, B, C, D) and Column II (items P, Q, R, S) — all related to ${topic}.
Both columns should have meaningful, specific scientific items.
Options are 4 different matching combinations e.g.:
A) A-P, B-Q, C-R, D-S  B) A-Q, B-P, C-R, D-S  etc.`,

    Passage_Based: `PASSAGE/COMPREHENSION BASED: Write a 3-4 sentence scientific paragraph about ${topic} containing specific data/observations.
Question must be answerable from the passage content (not general knowledge).
The passage should contain enough information to derive the answer analytically.`,

    Sequence_Based: `SEQUENCE/PROCESS ORDER: Give 4-5 steps, events, or stages of a process related to ${topic} in SCRAMBLED order (label as P, Q, R, S or 1, 2, 3, 4).
Question: "The correct sequence is:"
Options show different arrangements. The correct sequence must be scientifically/logically verifiable.`,

    Graph_Data_Based: `GRAPH/DATA ANALYSIS: Present experimental data as a table, graph description, or observation series related to ${topic}.
Example: "The following data was recorded: [specific values]..." or "A graph shows [describe axes, trend, key points]..."
Question requires analyzing/interpreting this data to draw a conclusion.
Data must be realistic and calculable.`,

    Diagram_Based: img
      ? `DIAGRAM-BASED (with provided image): An image/diagram is provided at: ${img}
Describe what this diagram shows in the question text (start with "Refer to the diagram shown:" or similar).
Create a question that requires reading, identifying, or calculating from this diagram.
Set imageUrl field to: "${img}"`
      : `DIAGRAM-BASED (text description): Create a detailed text-described diagram scenario for ${topic}.
For Physics: Describe circuit/system with labeled components and specific numerical values (e.g., "A series circuit has R₁=10Ω, R₂=20Ω, connected to V=15V battery. Find current through R₁...")
For Chemistry: Describe a reaction scheme with reactants/conditions/products (e.g., "Compound A (C₃H₆O) undergoes reaction with...")
For Biology: Describe a labeled diagram with specific numbered/lettered parts (e.g., "In the diagram of [structure], part X represents...")
Leave imageUrl empty — admin can attach diagram image to the question later.`
  };

  // Format-specific concrete examples for AI to mimic
  const fmtExample = {
    Assertion_Reason: `
CONCRETE EXAMPLE — How Assertion_Reason question text MUST look:
{
  "text": "Assertion (A): Water molecules have a bent shape.\nReason (R): The two lone pairs on the oxygen atom repel the bonding pairs, reducing the bond angle below 109.5°.",
  "options": ["A. Both A and R are true, and R is the correct explanation of A", "B. Both A and R are true, but R is NOT the correct explanation of A", "C. A is true but R is false", "D. A is false but R is true"],
  "correct": [0]
}
Your questions MUST follow this EXACT structure. Question text MUST start with "Assertion (A):" on line 1 and "Reason (R):" on line 2.`,

    True_False: `
CONCRETE EXAMPLE — How True_False question text MUST look:
{
  "text": "Consider the following statements about photosynthesis:\n1. Light reaction occurs in stroma\n2. Calvin cycle occurs in thylakoid\n3. ATP is produced in light reaction\n4. CO2 is fixed in Calvin cycle\nWhich of the following shows the correct TRUE (T) / FALSE (F) order?",
  "options": ["A. F, F, T, T", "B. T, T, F, F", "C. F, T, T, F", "D. T, F, T, T"],
  "correct": [0]
}`,

    Statement_Based: `
CONCRETE EXAMPLE — How Statement_Based question text MUST look:
{
  "text": "Consider the following statements about ionic bonding:\nStatement I: Ionic compounds have high melting points\nStatement II: Ionic compounds conduct electricity in solid state\nWhich of the following statement(s) is/are correct?",
  "options": ["A. Only Statement I", "B. Only Statement II", "C. Both I and II", "D. Neither I nor II"],
  "correct": [0]
}`
  };

  // Build format instruction block with examples
  const formatBlock = selectedFormats.map((f, idx) => {
    const example = fmtExample[f] ? `\n${fmtExample[f]}` : '';
    return `FORMAT ${idx + 1} — ${f}:\n${fmtGuide[f] || fmtGuide.Random}${example}`;
  }).join('\n\n');

  // Per-question explicit format assignment
  const perQFormat = [];
  if (selectedFormats.length === 1 && selectedFormats[0] !== 'Random') {
    for (let i = 0; i < n; i++) perQFormat.push(selectedFormats[0]);
  } else if (selectedFormats.length > 1) {
    for (let i = 0; i < n; i++) perQFormat.push(selectedFormats[i % selectedFormats.length]);
  }

  const perQAssignment = perQFormat.length > 0
    ? perQFormat.map((f, i) => `Q${i+1}: MUST use "${f}" format — ${
        f === 'Assertion_Reason' ? 'text MUST start with Assertion (A): and include Reason (R):' :
        f === 'True_False' ? 'text MUST list 4 numbered statements with T/F options' :
        f === 'Statement_Based' ? 'text MUST list numbered statements and ask which is correct' :
        f === 'Numerical' ? 'text MUST provide numerical data for calculation' :
        f === 'Fill_Blanks' ? 'text MUST have a blank (___________) to fill' :
        f === 'Match_Column' ? 'text MUST have Column I and Column II to match' :
        f === 'Passage_Based' ? 'text MUST start with a scientific paragraph/passage' :
        f === 'Sequence_Based' ? 'text MUST list scrambled steps to arrange in order' :
        f === 'Graph_Data_Based' ? 'text MUST present data/graph description to interpret' :
        'follow format instructions above'
      }`).join('\n')
    : '';

  const distributionNote = selectedFormats.length > 1
    ? `⚠️ DISTRIBUTION: Spread ${n} questions evenly across the ${selectedFormats.length} selected formats. No single format gets more than 60% of questions.`
    : `ALL ${n} questions MUST use ONLY "${selectedFormats[0]}" format. Every single question. No exceptions. Any question not in this format is INVALID.`;

  // Build per-format enforcement reminder
  const formatEnforcement = selectedFormats.map(f => {
    const enfMap = {
      Assertion_Reason: `✅ Assertion_Reason: question text MUST start with "Assertion (A):" followed by "Reason (R):". Options MUST be the exact 4 assertion-reason options. NO numerical/calculation structure allowed.`,
      True_False: `✅ True_False: question MUST list exactly 4 numbered statements. Ask "Which of the following are TRUE (T) and FALSE (F) in the given order?". Options are 4 T/F combinations.`,
      Statement_Based: `✅ Statement_Based: question MUST list 2-3 numbered statements. Ask "Which statement(s) is/are correct?". Options are combinations of statements.`,
      Numerical: `✅ Numerical: provide specific numerical data. Student calculates the answer. Options are 4 different numerical values with units.`,
      Fill_Blanks: `✅ Fill_Blanks: question is a sentence with ONE blank (___________). Options are 4 possible fill-ins.`,
      Match_Column: `✅ Match_Column: Column I (A,B,C,D) vs Column II (P,Q,R,S). Options are 4 different matching combinations.`,
      Passage_Based: `✅ Passage_Based: 3-4 sentence scientific paragraph FIRST, then question answerable from passage.`,
      Sequence_Based: `✅ Sequence_Based: list scrambled steps/stages (P,Q,R,S). Ask for correct sequence order.`,
      Graph_Data_Based: `✅ Graph_Data_Based: table/graph/data description FIRST, then question requiring data interpretation.`,
      Diagram_Based: `✅ Diagram_Based: diagram description in question text. Question requires identifying/calculating from diagram.`,
      Random: `✅ Random: choose MOST VARIED format — mix assertion-reason, statement-based, numerical, fill-blanks across questions.`
    };
    return enfMap[f] || `✅ ${f}: follow the format instructions above strictly.`;
  }).join('\n');

  const diffGuide = {
    easy: 'Easy: Direct NCERT recall, single-step, definition based. First-time student should get it right.',
    medium: 'Medium: Requires concept understanding + moderate application. 1-2 steps of reasoning.',
    hard: 'Hard: Multi-step reasoning, tricky distractors, concept integration, advanced application. Only prepared students crack it.'
  };

  return `You are a senior question setter for Indian competitive exams with 25+ years of experience setting ${lvl} papers. You have set questions for actual NEET/JEE papers.

═══════════════ TASK ═══════════════
Generate EXACTLY ${n} unique, high-quality questions.
UNIQUENESS SEED: ${seed} — This ensures different questions each generation. Never repeat patterns.

═══════════════ PARAMETERS ═══════════════
• Exam Level : ${lvl}
• Guidelines : ${examGuide[lvl] || examGuide.OTHER}
• Subject    : ${subject}
• Chapter    : ${chapter}
• Topic      : ${topic}
• Difficulty : ${diff.toUpperCase()} → ${diffGuide[diff] || diffGuide.medium}
• Type       : ${qtype} → ${typeInstr[qtype] || typeInstr.SCQ}

═══════════════ SELECTED FORMATS ═══════════════
${formatBlock}

${distributionNote}

${perQAssignment ? '📋 QUESTION-BY-QUESTION FORMAT ASSIGNMENT (MANDATORY):\n' + perQAssignment + '\n\nEach question listed above MUST strictly follow its assigned format. A question in wrong format = INVALID.' : ''}

⚠️⚠️ FORMAT ENFORCEMENT — NON-NEGOTIABLE ⚠️⚠️
The FORMAT selected OVERRIDES any topic-specific tendencies of the AI.
Even if the topic is numerical/calculation-heavy, you MUST follow the selected FORMAT.
DO NOT generate generic calculation MCQs unless "Numerical" or "Random" is the selected format.

${formatEnforcement}

These FORMAT rules apply to EVERY SINGLE question in this batch. No exceptions.

═══════════════ QUALITY RULES (MANDATORY) ═══════════════
1. FORMAT FIRST — Every question MUST strictly follow the FORMAT specified above. This is the #1 rule. A wrong format means the question is completely rejected.
1.5. ZERO TEMPLATE REPETITION — Every question must test a DIFFERENT aspect/sub-concept of "${topic}"
2. NEVER use generic placeholders like "primary mechanism", "unrelated process", "chemical property only", "fundamental law"
3. All distractors (wrong options) must be scientifically plausible — a student must actually think before rejecting them
4. For ${lvl}: match the EXACT cognitive demand, terminology, and style of actual ${lvl} papers
5. Numerical questions must provide ALL data needed (no missing values)
6. Explanations must include: concept name + formula/mechanism + why each wrong option is incorrect
7. Assertion-Reason: options must follow EXACTLY the 4-option format specified above
8. MSQ: correct array must have 2-3 indices — NEVER 1 or 4
9. Integer: options = [], correct = [integer_answer]
10. Match Column: all 8 items (4+4) must be specific, not generic
10.5. EXPLANATION FORMAT RULES (follow based on question type):
- NUMERICAL: Show complete step-by-step solution on SEPARATE LINES using \n between each step. Format: "Given: [values]\nFormula: [formula]\nStep 1: [substitution]\nStep 2: [calculation]\nStep 3: [result]\nAnswer: [final answer with units]. Option X is correct."
- ASSERTION-REASON: Use \n between each part. Format: "Assertion (A): [True/False] — [reason why]\nReason (R): [True/False] — [reason why]\nR explains A: [Yes/No] — [why R is/isn't the correct explanation]\nCorrect option: [A/B/C/D]"
- TRUE/FALSE: Use \n between each statement. Format: "Statement 1: [T/F] — [reason]\nStatement 2: [T/F] — [reason]\nStatement 3: [T/F] — [reason]\nStatement 4: [T/F] — [reason]\nCorrect order: [T,F,T,F etc]. Option X is correct."
- STATEMENT-BASED: For each statement, state correct/incorrect with reason. Then explain which combination is correct.
- MATCH COLUMN: Use \n between each pair. Format: "A → P: [reason]\nB → Q: [reason]\nC → R: [reason]\nD → S: [reason]\nCorrect matching: [A-P, B-Q, C-R, D-S]. Option X is correct."
- PASSAGE/GRAPH/DATA: Show calculation or reasoning from the given data. Reference specific values from the passage.
- FILL IN BLANK: State the correct word/value and explain the concept behind it.
- SEQUENCE: Explain the correct order with reason for each step's position.
- GENERAL SCQ: State correct answer + concept/formula used + why other options are wrong (briefly).
No word limit — write as much as needed to fully explain. No repetition of question text. ALWAYS use \n to separate each step, part, or statement — never write everything in one paragraph.
11. Each question must stand alone — no references to "the above" without context

═══════════════ MANDATORY JSON RESPONSE FORMAT ═══════════════
⚠️ FINAL REMINDER: Format selected = "${selectedFormats.join(', ')}". Every question structure MUST match this format.
Return ONLY a valid JSON array. NO markdown. NO explanation. NO text before or after the array.

[
  {
    "text": "Full question text here. For diagram: include complete description.",
    "hindiText": "",
    "options": ["A. option text", "B. option text", "C. option text", "D. option text"],
    "correct": [0],
    "type": "${qtype}",
    "difficulty": "${diff}",
    "subject": "${subject}",
    "chapter": "${chapter}",
    "topic": "${topic}",
    "explanation": "FORMAT-SPECIFIC EXPLANATION: For Numerical→show full step-by-step calculation with formula+substitution+steps+answer. For Assertion-Reason→explain A true/false why, R true/false why, R explains A why/why not. For True-False→each statement T/F with reason. For Match Column→each pair match reason. For others→complete concept explanation with formula and reasoning.",
    "format": "actual_format_name_used",
    "examLevel": "${lvl}",
    "imageUrl": "${img}"
  }
]

Generate all ${n} questions now. Maximum scientific accuracy. Zero compromise on quality.

━━━ MATH NOTATION RULES:
- Powers/Superscripts: use Unicode superscripts — m² not m^2, r² not r^2, 10⁻¹¹ not 10^-11, 10²⁴ not 10^24
- For negative powers: 10⁻¹¹ 10⁻³ 10⁻⁶ 10⁻⁹ (use ⁻ Unicode)
- Multiplication: use × not * (e.g. 5 × 10⁻¹¹ not 5*10^-11)
- Fractions: a/b format (P/Q = R/S)
- Greek letters: α β γ ω τ σ δ π θ μ
- Units: m² kg⁻² N·m² m/s² rad/s²
- NO ^ symbol, NO * for multiplication, NO backslash commands

`;
};

module.exports = { callGroqAI, buildPrompt };
