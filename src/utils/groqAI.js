// ============================================================
// ProveRank — Gemini AI Question Generator Utility
// Supports: NEET / JEE Mains / JEE Advanced / CUET / Board / Other
// Formats: 12 Question Formats
// Types: SCQ / MSQ / Integer
// ============================================================

const callGroqAI = async (prompt) => {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error('GROQ_API_KEY not configured');
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions',{
    method:'POST',
    headers:{'Content-Type':'application/json','Authorization':'Bearer '+apiKey},
    body:JSON.stringify({
      model:'llama-3.3-70b-versatile',
      messages:[{role:'user',content:prompt}],
      temperature:0.9,max_tokens:8192
    })
  });
  if(!response.ok){const e=await response.text();throw new Error('Groq Error '+response.status+': '+e.slice(0,200));}
  const data=await response.json();
  const raw=data?.choices?.[0]?.message?.content||'';
  if(!raw) throw new Error('Empty response from Groq');
  let cleaned=raw.trim().replace(/^```json\s*/i,'').replace(/^```\s*/i,'').replace(/\s*```$/i,'').trim();
  const s=cleaned.indexOf('['),e=cleaned.lastIndexOf(']');
  if(s===-1||e===-1) throw new Error('No JSON array in response');
  return JSON.parse(cleaned.slice(s,e+1));
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

  // Build format instruction block
  const formatBlock = selectedFormats.map((f, idx) =>
    `FORMAT ${idx + 1} — ${f}:\n${fmtGuide[f] || fmtGuide.Random}`
  ).join('\n\n');

  const distributionNote = selectedFormats.length > 1
    ? `⚠️ DISTRIBUTION: Spread ${n} questions evenly across the ${selectedFormats.length} selected formats. No single format gets more than 60% of questions.`
    : `All ${n} questions use "${selectedFormats[0]}" format.`;

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

═══════════════ QUALITY RULES (MANDATORY) ═══════════════
1. ZERO TEMPLATE REPETITION — Every question must test a DIFFERENT aspect/sub-concept of "${topic}"
2. NEVER use generic placeholders like "primary mechanism", "unrelated process", "chemical property only", "fundamental law"
3. All distractors (wrong options) must be scientifically plausible — a student must actually think before rejecting them
4. For ${lvl}: match the EXACT cognitive demand, terminology, and style of actual ${lvl} papers
5. Numerical questions must provide ALL data needed (no missing values)
6. Explanations must include: concept name + formula/mechanism + why each wrong option is incorrect
7. Assertion-Reason: options must follow EXACTLY the 4-option format specified above
8. MSQ: correct array must have 2-3 indices — NEVER 1 or 4
9. Integer: options = [], correct = [integer_answer]
10. Match Column: all 8 items (4+4) must be specific, not generic
11. Each question must stand alone — no references to "the above" without context

═══════════════ MANDATORY JSON RESPONSE FORMAT ═══════════════
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
    "explanation": "Correct answer explanation. Name the concept. Give formula if applicable. Explain why each wrong option is wrong. Reference NCERT chapter/concept.",
    "format": "actual_format_name_used",
    "examLevel": "${lvl}",
    "imageUrl": "${img}"
  }
]

Generate all ${n} questions now. Maximum scientific accuracy. Zero compromise on quality.

━━━ LATEX MATH RULES (MANDATORY for numerical/physics/chemistry) ━━━
- All mathematical formulas MUST use LaTeX notation
- Inline math: wrap in single $...$ e.g. $\tau = r \times F$, $I = \frac{V}{R}$, $\alpha = \frac{\tau}{I}$
- Display math: wrap in $...$ for standalone equations e.g. $P/Q = R/S$
- Use proper LaTeX: \frac{a}{b} for fractions, \times for multiplication, \omega for omega, \alpha for alpha, ^2 for squared, _0 for subscript
- Example explanation format: "The torque is given by $\tau = r \times F = 0.5 \times 20 = 10$ Nm. Angular acceleration: $\alpha = \frac{\tau}{I} = \frac{10}{1.25} = 8 \text{ rad/s}^2$"
- For pure text questions (Biology/History), LaTeX is NOT needed`;
};

module.exports = { callGroqAI, buildPrompt };
