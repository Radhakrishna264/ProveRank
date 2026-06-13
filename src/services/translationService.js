// ProveRank — MyMemory Free Translation Service
// No API key needed | Free 5000 chars/day | Accurate Hindi

const https = require('https');

/**
 * Translate text EN → HI using MyMemory API (free, no key)
 */
async function translateText(text) {
  if (!text || !text.trim()) return '';
  
  return new Promise((resolve) => {
    const encoded = encodeURIComponent(text.slice(0, 500)); // 500 char limit per call
    const url = `https://api.mymemory.translated.net/get?q=${encoded}&langpair=en|hi`;
    
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          const translated = json?.responseData?.translatedText || text;
          // MyMemory sometimes returns ALL CAPS on error — fallback to original
          if (translated === translated.toUpperCase() && translated.length > 10) {
            resolve(text);
          } else {
            resolve(translated);
          }
        } catch(e) {
          resolve(text); // fallback to original on error
        }
      });
    }).on('error', () => resolve(text));
  });
}

/**
 * Split long text into chunks and translate
 */
async function translateLongText(text) {
  if (!text) return '';
  if (text.length <= 500) return translateText(text);
  
  // Split on sentence boundaries
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  const results = [];
  
  for (const sentence of sentences) {
    const t = await translateText(sentence.trim());
    results.push(t);
    // Small delay to avoid rate limit
    await new Promise(r => setTimeout(r, 200));
  }
  
  return results.join(' ');
}

/**
 * Translate full question (text + options + explanation)
 */
async function translateQuestion(text, options = [], explanation = '') {
  try {
    const [hindiText, hindiExplanation, ...hindiOpts] = await Promise.all([
      translateLongText(text || ''),
      translateLongText(explanation || ''),
      ...options.map(opt => translateText(String(opt || ''))),
    ]);

    return {
      hindiText:        hindiText        || '',
      hindiOptions:     hindiOpts        || [],
      hindiExplanation: hindiExplanation || '',
    };
  } catch(e) {
    console.log('[Translation] Error:', e.message);
    return { hindiText: text, hindiOptions: options, hindiExplanation: explanation };
  }
}

module.exports = { translateText, translateLongText, translateQuestion };
