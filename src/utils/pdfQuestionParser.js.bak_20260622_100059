const fs = require('fs');
const pdfParse = require('pdf-parse');

// ══════════════════════════════════════════════════════════════
// Feature 21 / 21B — PDF Question Parsing Engine (NEW, self-contained)
// Does NOT touch any existing controller/route. Pure utility module.
// ══════════════════════════════════════════════════════════════

// F21.2.1 / F21B.2.1 — Extract text PAGE-BY-PAGE (needed to strip
// repeating headers/footers and to give page-level error references)
async function extractPagesText(filePath) {
  const buffer = fs.readFileSync(filePath);
  const pages = [];
  try {
    await pdfParse(buffer, {
      pagerender: function (pageData) {
        return pageData.getTextContent().then(function (textContent) {
          let text = '';
          let lastY = null;
          textContent.items.forEach(function (item) {
            if (lastY !== null && Math.abs(lastY - item.transform[5]) > 2) text += '\n';
            text += item.str;
            lastY = item.transform[5];
          });
          pages.push(text);
          return text;
        });
      }
    });
    if (pages.length > 0) return pages; // per-page granularity succeeded
  } catch (e) { /* fall through to plain-text fallback below */ }

  // F21.6 — Graceful fallback: some PDFs (unusual encoders/XRef layouts) fail the
  // per-page pagerender path. Fall back to a single combined-text extraction so the
  // feature still works (header-strip & page-number error refs are simply skipped).
  const data = await pdfParse(buffer);
  return [data.text || ''];
}

// F21.2.1 — Identify lines that repeat (institute name / running header / page no.)
// and strip them out so they don't pollute question text. Counts TOTAL occurrences
// across all pages combined (not just page-presence) so this also catches short
// PDFs where a header repeats more than once on the very same physical page —
// while carefully NOT stripping legitimate repeated option text (True/False/
// None of the above etc., which genuinely repeat across many questions).
function stripRepeatingLines(pages) {
  const optionLikePattern = /^\(?[A-Da-d][\)\.\:\-]/i;
  const commonOptionPhrase = /^(true|false|yes|no|none of (the )?above|all of (the )?above|cannot be determined|none of these|both \w+ and \w+)\.?$/i;
  const questionLikePattern = /^Q?\s*\d+[\.\)\:\-]/i;

  const lineTotalCounts = {};
  const linePageCounts = {};
  pages.forEach(p => {
    const lines = p.split('\n').map(l => l.trim()).filter(Boolean);
    lines.forEach(l => { lineTotalCounts[l] = (lineTotalCounts[l] || 0) + 1; });
    new Set(lines).forEach(l => { linePageCounts[l] = (linePageCounts[l] || 0) + 1; });
  });

  const pageThreshold = Math.max(2, Math.ceil(pages.length * 0.5));
  const repeating = new Set(
    Object.keys(lineTotalCounts).filter(l => {
      if (l.length >= 120 || questionLikePattern.test(l) || optionLikePattern.test(l) || commonOptionPhrase.test(l)) return false;
      const wordCount = l.split(/\s+/).length;
      const repeatsAcrossPages = linePageCounts[l] >= pageThreshold;
      const repeatsOnFewPages = pages.length <= 2 && lineTotalCounts[l] >= 2 && wordCount >= 2; // short-doc safety net
      return repeatsAcrossPages || repeatsOnFewPages;
    })
  );
  const cleanedPages = pages.map(p =>
    p.split('\n').filter(l => !repeating.has(l.trim())).join('\n')
  );
  return { cleanedPages, repeatingLines: [...repeating] };
}

// F21.3.8 — Language detection (Devanagari unicode block = Hindi)
function detectLanguage(text) {
  const hindiChars = (text.match(/[\u0900-\u097F]/g) || []).length;
  const engChars   = (text.match(/[A-Za-z]/g) || []).length;
  if (hindiChars > 20 && engChars > 20) return 'Bilingual';
  if (hindiChars > engChars) return 'Hindi';
  return 'English';
}

// F21.1.7 / F21.1.7B / F21.1.7C — Subject range map parser. Supports:
//   "Q1. Physics" / "Q1 Physics" / "Q1) Physics"   (per-question)
//   "Q1-Q45 Physics; Q46-Q90 Chemistry"             (range list, ; or \n separated)
function parseSubjectRangeMap(mapText) {
  const perQuestion = {}; // qNum -> subject
  const ranges = [];      // [{from,to,subject}]
  if (!mapText || !mapText.trim()) return { perQuestion, ranges };

  const chunks = mapText.split(/[;\n]+/).map(s => s.trim()).filter(Boolean);
  chunks.forEach(chunk => {
    const rangeMatch = chunk.match(/Q?\s*(\d+)\s*-\s*Q?\s*(\d+)\s+([A-Za-z\s]+)/i);
    if (rangeMatch) {
      const from = parseInt(rangeMatch[1]), to = parseInt(rangeMatch[2]), subject = rangeMatch[3].trim();
      ranges.push({ from, to, subject });
      for (let i = from; i <= to; i++) perQuestion[i] = subject;
      return;
    }
    const singleMatch = chunk.match(/Q?\s*(\d+)[\.\)\:\-\s]+([A-Za-z\s]+)/i);
    if (singleMatch) {
      const qn = parseInt(singleMatch[1]), subject = singleMatch[2].trim();
      perQuestion[qn] = subject;
    }
  });
  return { perQuestion, ranges };
}

function subjectForQNum(qNum, subjectMap) {
  if (subjectMap.perQuestion[qNum]) return subjectMap.perQuestion[qNum];
  const r = subjectMap.ranges.find(r => qNum >= r.from && qNum <= r.to);
  return r ? r.subject : '';
}

// F21.3.6 — Answer key section detector
function extractAnswerKeySection(text) {
  const m = text.match(/(?:answer\s*key|answers?\s*:|solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

// F21.3.7 — Explanation/Solution section detector
function extractExplanationSection(text) {
  const m = text.match(/(?:explanations?\s*:|solutions?\s*:|detailed\s*solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

// F21.5.1-5.6 — Answer key parser (same multi-format logic family as Feature 19 paste engine)
function parseAnswerKey(text) {
  const map = {};
  if (!text || !text.trim()) return map;
  const cleaned = extractAnswerKeySection(text);
  const lines = cleaned.trim().split('\n').map(l => l.trim()).filter(Boolean);

  const matches = cleaned.matchAll(/Q?\s*(\d+)\s*[\-\.\)\:]\s*\(?([A-Da-d,\s]+|\-?\d+\.?\d*)\)?/g);
  let foundAny = false;
  for (const m of matches) {
    foundAny = true;
    const qNum = parseInt(m[1]);
    const raw = m[2].trim();
    if (/^[A-Da-d,\s]+$/.test(raw)) {
      const letters = [...new Set((raw.toUpperCase().match(/[A-D]/g) || []))];
      map[qNum] = { letters };
    } else {
      map[qNum] = { numeric: parseFloat(raw) };
    }
  }
  if (foundAny) return map;

  if (lines.length > 0 && lines.every(l => /^[A-Da-d]$/.test(l))) {
    lines.forEach((l, i) => { map[i + 1] = { letters: [l.toUpperCase()] }; });
    return map;
  }
  if (lines.length === 1 && /^[A-Da-d]+$/.test(lines[0])) {
    lines[0].split('').forEach((ch, i) => { map[i + 1] = { letters: [ch.toUpperCase()] }; });
  }
  return map;
}

// F21.5.7-5.9 — Explanation/Solution parser
function parseExplanations(text) {
  const map = {};
  if (!text || !text.trim()) return map;
  const cleaned = extractExplanationSection(text);
  const blocks = cleaned.split(/(?=(?:^|\n)\s*Q?\d+[\.\)\:\-\s])/im);
  blocks.forEach(block => {
    const m = block.trim().match(/^Q?\s*(\d+)[\.\)\:\-\s]+([\s\S]+)/);
    if (m) map[parseInt(m[1])] = m[2].trim();
  });
  return map;
}

// F21B.3.1-3.5 — Question block splitter: numbered / Q-number / Roman numerals
function splitIntoBlocks(text, customDelim) {
  if (customDelim && text.includes(customDelim)) {
    return text.split(customDelim).map(s => s.trim()).filter(Boolean);
  }
  const patterns = [
    { re: /(?=(?:^|\n)\s*Q\s*\.?\s*\d+[\s\.\)\:\-])/im, name: 'Q-number' },
    { re: /(?=(?:^|\n)\s*\d+[\.\)\:\-\s])/m,            name: 'numbered' },
    { re: /(?=(?:^|\n)\s*[IVXLC]+[\.\)\:\-\s])/m,       name: 'roman' },
  ];
  for (const p of patterns) {
    if (p.re.test(text)) {
      const blocks = text.split(p.re).map(s => s.trim()).filter(Boolean);
      if (blocks.length > 1) return blocks;
    }
  }
  return text.split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
}

// F21B.3.5 — Option format detect & block parse
function parseOneBlock(block, idx, pageHint) {
  const lines = block.split('\n').map(l => l.trim()).filter(Boolean);
  const numMatch = lines[0] && lines[0].match(/^Q?\s*(\d+)[\s\.\)\:\-]/i);
  const qNum = numMatch ? parseInt(numMatch[1]) : idx + 1;

  let qText = lines[0] ? lines[0].replace(/^Q?\s*\d+[\s\.\)\:\-]\s*/i, '').trim() : '';
  let i = 1;
  const optionLineRe = /^(?:Option\s*)?[\(\[]?\s*([A-Da-d])\s*[\)\]\.\:\-\s]+(.+)/i;
  while (i < lines.length && !optionLineRe.test(lines[i])) {
    qText += ' ' + lines[i];
    i++;
  }
  const options = [];
  while (i < lines.length) {
    const m = lines[i].match(optionLineRe);
    if (m) options.push(m[2].trim());
    i++;
  }

  const errors = [];
  if (!qText) errors.push('Question text empty');
  if (options.length < 2) errors.push('Options not detected (<2) — Page ' + (pageHint || '?'));

  return { num: qNum, text: qText.trim(), options, hasParseError: errors.length > 0, parseError: errors.join('; ') };
}

/**
 * F21B Main orchestrator — extract + parse + sync answer key + explanation.
 */
async function buildQuestionsFromPDFs(args) {
  const { questionsPdfPath, answerKeyPdfPath, explanationPdfPath, subjectMapText, pageFrom, pageTo, customDelimiter } = args;

  if (!questionsPdfPath) throw new Error('Question paper PDF is required');
  if (!answerKeyPdfPath) throw new Error('Answer key PDF is required');

  const qPagesRaw = await extractPagesText(questionsPdfPath);
  const { cleanedPages: qPagesClean, repeatingLines } = stripRepeatingLines(qPagesRaw); // F21.2.1

  const from = pageFrom && pageFrom > 0 ? pageFrom - 1 : 0;
  const to   = pageTo && pageTo <= qPagesClean.length ? pageTo : qPagesClean.length;
  const selectedPages = qPagesClean.slice(from, to);

  let pageBoundaries = [];
  let cum = 0;
  selectedPages.forEach(p => { cum += p.length + 1; pageBoundaries.push(cum); });
  const fullQuestionText = selectedPages.join('\n');

  const language = detectLanguage(fullQuestionText); // F21.3.8

  const ansPages = await extractPagesText(answerKeyPdfPath);
  const fullAnswerText = ansPages.join('\n');
  const answerMap = parseAnswerKey(fullAnswerText); // F21.5

  let explanationMap = {};
  if (explanationPdfPath) {
    const explPages = await extractPagesText(explanationPdfPath);
    explanationMap = parseExplanations(explPages.join('\n')); // F21.5.7-5.9
  }

  const subjectMap = parseSubjectRangeMap(subjectMapText); // F21.1.7

  const blocks = splitIntoBlocks(fullQuestionText, customDelimiter); // F21B.3/3.4
  let runningOffset = 0;
  const questions = [];
  const errors = [];
  const seenText = new Set(); // F21.7.6 duplicate-in-this-paper detection

  blocks.forEach((block, idx) => {
    const blockStartOffset = fullQuestionText.indexOf(block, runningOffset);
    const pageNum = pageBoundaries.findIndex(b => blockStartOffset < b) + 1;
    runningOffset = blockStartOffset >= 0 ? blockStartOffset + block.length : runningOffset;

    const parsed = parseOneBlock(block, idx, pageNum || '?');
    const ans = answerMap[parsed.num];
    const correct = ans ? (ans.letters ? ans.letters.map(l => ['A','B','C','D'].indexOf(l)).filter(i => i >= 0) : (ans.numeric !== undefined ? [ans.numeric] : [])) : [];
    const type = ans && ans.numeric !== undefined ? 'Integer' : (ans && ans.letters && ans.letters.length > 1 ? 'MSQ' : 'SCQ');

    const dedupKey = parsed.text.toLowerCase().slice(0, 80);
    const isDuplicate = !!(parsed.text && seenText.has(dedupKey));
    if (parsed.text) seenText.add(dedupKey);

    const rowErrors = [];
    if (parsed.hasParseError) rowErrors.push(parsed.parseError);
    if (correct.length === 0) rowErrors.push('Answer not found for Q' + parsed.num + ' — Page ' + (pageNum || '?'));

    const subject = subjectForQNum(parsed.num, subjectMap);
    const looksLikeDiagram = /diagram|figure|graph shown|image shown/i.test(block); // F21.15

    questions.push({
      num: parsed.num,
      text: parsed.text,
      options: parsed.options,
      correct,
      type,
      subject: subject || '',
      explanation: explanationMap[parsed.num] || '',
      hasError: rowErrors.length > 0,
      error: rowErrors.join('; '),
      needsReview: rowErrors.length > 0 || looksLikeDiagram,        // F21.7.7
      confidencePct: rowErrors.length === 0 ? (looksLikeDiagram ? 60 : 90) : 40, // F21.20
      isDuplicate,
      page: pageNum || null,
      imageFlag: looksLikeDiagram,                                  // F21.15
    });

    if (rowErrors.length > 0) errors.push({ qNum: parsed.num, page: pageNum || null, message: rowErrors.join('; ') });
  });

  return {
    questions,
    errors,
    pageCount: qPagesRaw.length,
    selectedPageRange: { from: from + 1, to },
    language,
    repeatingLinesRemoved: repeatingLines,
    rawTextPreview: fullQuestionText.slice(0, 2000), // F21.2.3
  };
}

// F21.16 OCR fallback scaffold — only attempted if explicitly requested; fails gracefully
// if tesseract.js / system deps are unavailable in the deploy environment (kept optional & safe).
async function ocrFallback(filePath) {
  try {
    const Tesseract = require('tesseract.js');
    const result = await Tesseract.recognize(filePath, 'eng');
    return { success: true, text: result.data.text };
  } catch (e) {
    return { success: false, message: 'OCR not available in this environment: ' + e.message };
  }
}

module.exports = {
  extractPagesText,
  stripRepeatingLines,
  detectLanguage,
  parseSubjectRangeMap,
  subjectForQNum,
  parseAnswerKey,
  parseExplanations,
  splitIntoBlocks,
  parseOneBlock,
  buildQuestionsFromPDFs,
  ocrFallback,
};

