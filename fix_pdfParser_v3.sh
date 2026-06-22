#!/bin/bash
set -e

POSSIBLE_PATHS=(
  "$HOME/workspace/src/utils/pdfQuestionParser.js"
  "$HOME/workspace/utils/pdfQuestionParser.js"
  "$HOME/workspace/backend/src/utils/pdfQuestionParser.js"
  "$HOME/workspace/backend/utils/pdfQuestionParser.js"
)
TARGET=""
for P in "${POSSIBLE_PATHS[@]}"; do
  if [ -f "$P" ]; then TARGET="$P"; break; fi
done
[ -z "$TARGET" ] && { echo "❌ pdfQuestionParser.js not found. Run: find ~/workspace -name 'pdfQuestionParser.js'"; exit 1; }
TARGET="${TARGET_OVERRIDE:-$TARGET}"
echo "✅ Found: $TARGET"
cp "$TARGET" "${TARGET}.bak_v2_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup created"

cat > "$TARGET" << 'ENDOFFILE'
const fs = require('fs');
const pdfParse = require('pdf-parse');

// ══════════════════════════════════════════════════════════════
// Feature 21 / 21B — PDF Question Parsing Engine v3
// Supports: ALLEN, CLC, AAKASH, Standard ABCD formats
// ══════════════════════════════════════════════════════════════

const NUM_TO_LETTER = { '1': 'A', '2': 'B', '3': 'C', '4': 'D' };
function numOptToLetter(n) { return NUM_TO_LETTER[String(n)] || null; }

// ── Page-by-page text extraction ──────────────────────────────
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
    if (pages.length > 0) return pages;
  } catch (e) { /* fallback */ }
  const data = await pdfParse(buffer);
  return [data.text || ''];
}

// ── Strip repeating headers/footers ───────────────────────────
// FIX: optionLikePattern includes 1-4 so numeric options never stripped
function stripRepeatingLines(pages) {
  const optionLikePattern  = /^[\(\[]?[A-Da-d1-4][\)\]\.:\-]/i;
  const commonOptionPhrase = /^(true|false|yes|no|none of (the )?above|all of (the )?above|cannot be determined|none of these|both \w+ and \w+)\.?$/i;
  const questionLikePattern = /^Q?\s*\d+[\.)\:\-]/i;

  const lineTotalCounts = {};
  const linePageCounts  = {};
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
      return linePageCounts[l] >= pageThreshold ||
             (pages.length <= 2 && lineTotalCounts[l] >= 2 && wordCount >= 2);
    })
  );
  return {
    cleanedPages: pages.map(p => p.split('\n').filter(l => !repeating.has(l.trim())).join('\n')),
    repeatingLines: [...repeating],
  };
}

function detectLanguage(text) {
  const hindiChars = (text.match(/[\u0900-\u097F]/g) || []).length;
  const engChars   = (text.match(/[A-Za-z]/g) || []).length;
  if (hindiChars > 20 && engChars > 20) return 'Bilingual';
  if (hindiChars > engChars) return 'Hindi';
  return 'English';
}

function parseSubjectRangeMap(mapText) {
  const perQuestion = {};
  const ranges = [];
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
    const singleMatch = chunk.match(/Q?\s*(\d+)[\.)\:\-\s]+([A-Za-z\s]+)/i);
    if (singleMatch) perQuestion[parseInt(singleMatch[1])] = singleMatch[2].trim();
  });
  return { perQuestion, ranges };
}

function subjectForQNum(qNum, subjectMap) {
  if (subjectMap.perQuestion[qNum]) return subjectMap.perQuestion[qNum];
  const r = subjectMap.ranges.find(r => qNum >= r.from && qNum <= r.to);
  return r ? r.subject : '';
}

function extractAnswerKeySection(text) {
  const m = text.match(/(?:answer\s*key|answers?\s*:|solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

function extractExplanationSection(text) {
  const m = text.match(/(?:explanations?\s*:|solutions?\s*:|detailed\s*solutions?\s*:)([\s\S]*)/i);
  return m ? m[1] : text;
}

// ══════════════════════════════════════════════════════════════
// CRITICAL FIX: ALLEN Inline Question Number Preprocessor
// ALLEN PDFs have format: "...PHYSICS 1) question text..."
// Question number is MID-LINE after subject name.
// This function moves each "N)" to its own line so
// splitIntoBlocks can correctly identify question boundaries.
// ══════════════════════════════════════════════════════════════
function preprocessAllenFormat(text) {
  // Pattern: subject keyword followed by question number mid-line
  // e.g. "PHYSICS 1)" or "CHEMISTRY 23)" or "MD PHYSICS 1)"
  const subjectInlineRe = /\b(PHYSICS|CHEMISTRY|BIOLOGY|BOTANY|ZOOLOGY|MATHEMATICS?|MATH|ENGLISH|HINDI|MD)\s+(\d{1,3})\)/gi;
  let processed = text.replace(subjectInlineRe, (match, subj, num) => {
    return '\n' + num + ')';
  });

  // Also handle lines like "0999DMD... 22-06-2025 MD PHYSICS 1) text"
  // where the whole header line contains a question number mid-line
  // Split such lines at the question number
  processed = processed.replace(/^(.{10,}?)\s+(\d{1,3})\)\s+(.{10,})/gm, (match, pre, num, qtext) => {
    // Only split if pre-part looks like a header code (has digits/dates, no option markers)
    if (/\d{4,}|\d{2}-\d{2}-\d{4}/.test(pre) && !/^[\(\[]?[A-Da-d1-4]/.test(pre.trim())) {
      return '\n' + num + ') ' + qtext;
    }
    return match;
  });

  return processed;
}

// ── Answer Key Parser ──────────────────────────────────────
// Pass 1: AAKASH "Question : N ... Answer (M)"
// Pass 2: Standalone sequential "Answer (N)"
// Pass 3: Standard + numeric option "1. (3)"
function parseAnswerKey(text) {
  const map = {};
  if (!text || !text.trim()) return map;

  // Pass 1: AAKASH style
  if (/Question\s*[:\s]+\d+/im.test(text)) {
    const re = /Question\s*[:\s]+(\d+)[\s\S]{0,2000}?Answer\s*\(\s*([1-4A-Da-d])\s*\)/gim;
    let found = false;
    for (const m of text.matchAll(re)) {
      const qNum = parseInt(m[1]);
      const raw  = m[2].trim().toUpperCase();
      const letter = /^[1-4]$/.test(raw) ? numOptToLetter(raw) : raw;
      if (letter && /^[A-D]$/.test(letter)) { map[qNum] = { letters: [letter] }; found = true; }
    }
    if (found) return map;
  }

  // Pass 2: Standalone "Answer (N)"
  const standaloneList = [...text.matchAll(/(?:^|\n)\s*Answer\s*\(\s*([1-4A-Da-d])\s*\)/gim)];
  if (standaloneList.length > 0) {
    standaloneList.forEach((m, idx) => {
      const pre = text.slice(Math.max(0, m.index - 500), m.index);
      const qMatch = pre.match(/(?:^|\n)\s*Q?\s*(\d+)\s*[.)\-:\s]/im);
      const qNum = qMatch ? parseInt(qMatch[1]) : idx + 1;
      const raw  = m[1].trim().toUpperCase();
      const letter = /^[1-4]$/.test(raw) ? numOptToLetter(raw) : raw;
      if (letter && /^[A-D]$/.test(letter)) map[qNum] = { letters: [letter] };
    });
    if (Object.keys(map).length > 0) return map;
  }

  // Pass 3: Standard formats
  const cleaned = extractAnswerKeySection(text);
  const lines   = cleaned.trim().split('\n').map(l => l.trim()).filter(Boolean);
  let foundAny  = false;

  for (const m of cleaned.matchAll(/Q?\s*(\d+)\s*[\-\.)\:]\s*\(?([A-Da-d,\s]+|\-?\d+\.?\d*)\)?/g)) {
    foundAny = true;
    const qNum = parseInt(m[1]);
    const raw  = m[2].trim();
    if (/^[A-Da-d,\s]+$/.test(raw)) {
      const letters = [...new Set((raw.toUpperCase().match(/[A-D]/g) || []))];
      if (letters.length > 0) map[qNum] = { letters };
    } else if (/^[1-4]$/.test(raw)) {
      const letter = numOptToLetter(raw);
      if (letter) map[qNum] = { letters: [letter] };
    } else {
      const num = parseFloat(raw);
      if (!isNaN(num)) map[qNum] = { numeric: num };
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

// ── Explanation Parser ─────────────────────────────────────
function parseExplanations(text) {
  const map = {};
  if (!text || !text.trim()) return map;

  // AAKASH: "Question : N ... Solution : ... Answer (M) ..."
  if (/Question\s*[:\s]+\d+/im.test(text)) {
    const blocks = text.split(/(?=(?:^|\n)\s*Question\s*[:\s]+\d+)/im);
    blocks.forEach(block => {
      const qMatch  = block.match(/Question\s*[:\s]+(\d+)/i);
      if (!qMatch) return;
      const solMatch = block.match(/Solution\s*:?\s*([\s\S]+)/i);
      if (solMatch) {
        const raw = solMatch[1].replace(/^\s*Answer\s*\([1-4A-Da-d]\)\s*/i, '').trim();
        if (raw) map[parseInt(qMatch[1])] = raw;
      }
    });
    if (Object.keys(map).length > 0) return map;
  }

  // Standard / CLC
  const cleaned = extractExplanationSection(text);
  const blocks  = cleaned.split(/(?=(?:^|\n)\s*Q?\d+[\.)\:\-\s])/im);
  blocks.forEach(block => {
    const m = block.trim().match(/^Q?\s*(\d+)[\.)\:\-\s]+([\s\S]+)/);
    if (m) map[parseInt(m[1])] = m[2].trim();
  });
  return map;
}

// ── Block Splitter ─────────────────────────────────────────
// NOTE: preprocessAllenFormat() is called BEFORE this
//       so ALLEN "N)" always appears at line start by now.
function splitIntoBlocks(text, customDelim) {
  if (customDelim && text.includes(customDelim)) {
    return text.split(customDelim).map(s => s.trim()).filter(Boolean);
  }
  const patterns = [
    { re: /(?=(?:^|\n)\s*Question\s*[:\s]+\s*\d+)/im, name: 'question-label' },
    { re: /(?=(?:^|\n)\s*Q\s*\.?\s*\d+[\s\.)\:\-])/im, name: 'Q-number' },
    { re: /(?=(?:^|\n)\s*\d+[\.)\:\-\s])/m,            name: 'numbered' },
    { re: /(?=(?:^|\n)\s*[IVXLC]+[\.)\:\-\s])/m,       name: 'roman' },
  ];
  for (const p of patterns) {
    if (p.re.test(text)) {
      const blocks = text.split(p.re).map(s => s.trim()).filter(Boolean);
      if (blocks.length > 1) return blocks;
    }
  }
  return text.split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
}

// ── Single Block Parser ────────────────────────────────────
// Supports: ALLEN (1)/(2)/(3)/(4), AAKASH Options: header,
//           CLC (1)/(2)/(3)/(4), Standard (A)/(B)/(C)/(D)
function parseOneBlock(block, idx, pageHint) {
  const lines = block.split('\n').map(l => l.trim()).filter(Boolean);
  if (lines.length === 0) return { num: idx + 1, text: '', options: [], hasParseError: true, parseError: 'Empty block' };

  let qNum = idx + 1;
  const aakashNumMatch  = lines[0].match(/^Question\s*[:\s]+(\d+)/i);
  const standardNumMatch = lines[0].match(/^Q?\s*(\d+)[\s\.)\:\-]/i);
  if (aakashNumMatch)    qNum = parseInt(aakashNumMatch[1]);
  else if (standardNumMatch) qNum = parseInt(standardNumMatch[1]);

  let qText = '';
  let i = 0;
  if (aakashNumMatch) {
    qText = lines[0].replace(/^Question\s*[:\s]+\d+\s*/i, '').trim();
    i = 1;
    while (i < lines.length && /^(You scored|Score:|Time\s*:|Marks?\s*:)/i.test(lines[i])) i++;
  } else {
    qText = lines[0].replace(/^Q?\s*\d+[\s\.)\:\-]\s*/i, '').trim();
    i = 1;
  }

  const optAlpha   = /^(?:Option\s*)?[\(\[]?\s*([A-Da-d])\s*[\)\]\.:\-\s]+(.+)/i;
  const optNumeric = /^[\(\[]\s*([1-4])\s*[\)\]\.:\-]\s*(.+)/;
  const optHeader  = /^Options?\s*:?\s*$/i;
  const solMarker  = /^Solution\s*:?\s*$/i;
  const secHeader  = /^(PHYSICS|CHEMISTRY|BIOLOGY|MATHEMATICS|MATH|SECTION[\s\-]\w)/i;

  while (i < lines.length) {
    const l = lines[i];
    if (optAlpha.test(l) || optNumeric.test(l) || optHeader.test(l)) break;
    if (solMarker.test(l)) break;
    if (secHeader.test(l) && l.length < 30) break;
    qText += (qText ? ' ' : '') + l;
    i++;
  }

  let afterOptionsHeader = false;
  if (i < lines.length && optHeader.test(lines[i])) { i++; afterOptionsHeader = true; }

  const options = [];
  let isNumericOptions = false;

  while (i < lines.length) {
    const l = lines[i];
    if (solMarker.test(l)) break;
    const mAlpha   = l.match(optAlpha);
    const mNumeric = l.match(optNumeric);

    if (mAlpha) {
      options.push(mAlpha[2].trim());
      afterOptionsHeader = false;
      i++;
    } else if (mNumeric) {
      options.push(mNumeric[2].trim());
      isNumericOptions = true;
      afterOptionsHeader = false;
      i++;
    } else if (afterOptionsHeader && options.length < 4 && l.length > 0) {
      options.push(l);
      i++;
    } else {
      break;
    }
  }

  const errors = [];
  if (!qText.trim()) errors.push('Question text empty');
  if (options.length < 2) errors.push('Options not detected (<2) — Page ' + (pageHint || '?'));

  return { num: qNum, text: qText.trim(), options, isNumericOptions, hasParseError: errors.length > 0, parseError: errors.join('; ') };
}

// ── Main Orchestrator ──────────────────────────────────────
async function buildQuestionsFromPDFs(args) {
  const { questionsPdfPath, answerKeyPdfPath, explanationPdfPath, subjectMapText, pageFrom, pageTo, customDelimiter } = args;

  if (!questionsPdfPath) throw new Error('Question paper PDF is required');
  if (!answerKeyPdfPath)  throw new Error('Answer key PDF is required');

  const qPagesRaw = await extractPagesText(questionsPdfPath);
  const { cleanedPages: qPagesClean, repeatingLines } = stripRepeatingLines(qPagesRaw);

  const from = pageFrom && pageFrom > 0 ? pageFrom - 1 : 0;
  const to   = pageTo && pageTo <= qPagesClean.length ? pageTo : qPagesClean.length;
  const selectedPages = qPagesClean.slice(from, to);

  let pageBoundaries = [];
  let cum = 0;
  selectedPages.forEach(p => { cum += p.length + 1; pageBoundaries.push(cum); });

  // CRITICAL FIX: preprocess ALLEN inline question number format
  const rawJoined = selectedPages.join('\n');
  const fullQuestionText = preprocessAllenFormat(rawJoined);

  const language = detectLanguage(fullQuestionText);

  const ansPages       = await extractPagesText(answerKeyPdfPath);
  const fullAnswerText = ansPages.join('\n');
  const answerMap      = parseAnswerKey(fullAnswerText);

  let explanationMap = {};
  if (explanationPdfPath) {
    const explPages = await extractPagesText(explanationPdfPath);
    explanationMap = parseExplanations(explPages.join('\n'));
  }
  if (Object.keys(explanationMap).length === 0) {
    explanationMap = parseExplanations(fullAnswerText);
  }

  const subjectMap = parseSubjectRangeMap(subjectMapText);
  const blocks     = splitIntoBlocks(fullQuestionText, customDelimiter);

  let runningOffset = 0;
  const questions = [];
  const errors    = [];
  const seenText  = new Set();

  blocks.forEach((block, idx) => {
    const blockStartOffset = fullQuestionText.indexOf(block, runningOffset);
    const pageNum = pageBoundaries.findIndex(b => blockStartOffset < b) + 1;
    runningOffset = blockStartOffset >= 0 ? blockStartOffset + block.length : runningOffset;

    const parsed  = parseOneBlock(block, idx, pageNum || '?');
    const ans     = answerMap[parsed.num];
    const correct = ans
      ? (ans.letters ? ans.letters.map(l => ['A','B','C','D'].indexOf(l)).filter(i => i >= 0)
                     : (ans.numeric !== undefined ? [ans.numeric] : []))
      : [];
    const type = ans && ans.numeric !== undefined ? 'Integer'
               : (ans && ans.letters && ans.letters.length > 1 ? 'MSQ' : 'SCQ');

    const dedupKey    = parsed.text.toLowerCase().slice(0, 80);
    const isDuplicate = !!(parsed.text && seenText.has(dedupKey));
    if (parsed.text) seenText.add(dedupKey);

    const rowErrors = [];
    if (parsed.hasParseError) rowErrors.push(parsed.parseError);
    if (correct.length === 0) rowErrors.push('Answer not found for Q' + parsed.num + ' — Page ' + (pageNum || '?'));

    const subject          = subjectForQNum(parsed.num, subjectMap);
    const looksLikeDiagram = /diagram|figure|graph shown|image shown/i.test(block);

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
      needsReview: rowErrors.length > 0 || looksLikeDiagram,
      confidencePct: rowErrors.length === 0 ? (looksLikeDiagram ? 60 : 90) : 40,
      isDuplicate,
      page: pageNum || null,
      imageFlag: looksLikeDiagram,
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
    rawTextPreview: fullQuestionText.slice(0, 2000),
  };
}

async function ocrFallback(filePath) {
  try {
    const Tesseract = require('tesseract.js');
    const result = await Tesseract.recognize(filePath, 'eng');
    return { success: true, text: result.data.text };
  } catch (e) {
    return { success: false, message: 'OCR not available: ' + e.message };
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
  preprocessAllenFormat,
  buildQuestionsFromPDFs,
  ocrFallback,
};
ENDOFFILE

echo "✅  pdfQuestionParser.js (v3) updated at: $TARGET"
echo ""
echo "━━ New Fix in v3 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  preprocessAllenFormat() — ALLEN/CLC PDFs mein question"
echo "  number mid-line hota hai (e.g. 'PHYSICS 1) text')"
echo "  ye function use N) ko line-start pe le aata hai"
echo "  taaki splitIntoBlocks sahi se kaam kare"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄  Restart: pm2 restart all  OR  npm run dev"
