const TRANSLATE_SYS_MSG = 'You are a professional Hindi translator for NCERT/NEET science exam content. Translate English to Hindi (Devanagari script). Keep all scientific terms, units, numbers, chemical formulas and symbols unchanged - translate only surrounding language. Return ONLY a valid JSON object, no markdown, no extra text.';

async function chatComplete(url, key, model, userPrompt) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: TRANSLATE_SYS_MSG },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.3
    })
  });
  if (!res.ok) throw new Error('HTTP ' + res.status);
  const data = await res.json();
  const content = data && data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
  if (!content) throw new Error('Empty AI response');
  return content;
}

function extractJSON(text) {
  if (!text) return null;
  let cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) return null;
  try { return JSON.parse(cleaned.substring(start, end + 1)); } catch (e) { return null; }
}

async function translateQuestionToHindi(text, options, explanation) {
  const optList = (options || []).map(function(o, i) { return String.fromCharCode(65 + i) + '. ' + o; }).join('\n');
  const prompt = 'Translate the following NEET question, options and explanation to Hindi.\n' +
    'Return JSON exactly as: {"hindiText":"...","hindiOptions":["...","...","...","..."],"hindiExplanation":"..."}\n\n' +
    'Question: ' + text + '\nOptions:\n' + optList + '\nExplanation: ' + (explanation || 'N/A');

  const mistralKeys = [process.env.MISTRAL_API_KEY, process.env.MISTRAL_API_KEY_1, process.env.MISTRAL_API_KEY_2, process.env.MISTRAL_API_KEY_3].filter(Boolean);

  const layers = [];
  if (process.env.GROQ_API_KEY) layers.push(function() { return chatComplete('https://api.groq.com/openai/v1/chat/completions', process.env.GROQ_API_KEY, 'llama-3.3-70b-versatile', prompt); });
  mistralKeys.forEach(function(key) { layers.push(function() { return chatComplete('https://api.mistral.ai/v1/chat/completions', key, 'mistral-small-latest', prompt); }); });
  if (process.env.NVIDIA_API_KEY) layers.push(function() { return chatComplete('https://integrate.api.nvidia.com/v1/chat/completions', process.env.NVIDIA_API_KEY, 'meta/llama-3.3-70b-instruct', prompt); });

  let lastErr;
  for (const layerFn of layers) {
    try {
      const raw = await layerFn();
      const parsed = extractJSON(raw);
      if (parsed && parsed.hindiText) {
        return {
          hindiText: parsed.hindiText || '',
          hindiOptions: Array.isArray(parsed.hindiOptions) ? parsed.hindiOptions : [],
          hindiExplanation: parsed.hindiExplanation || ''
        };
      }
    } catch (e) { lastErr = e; }
  }
  throw new Error('AI Hindi translation failed: ' + (lastErr ? lastErr.message : 'no layer succeeded'));
}

module.exports = { translateQuestionToHindi };
