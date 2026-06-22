#!/bin/bash
set -e

# ── Locate the file ──────────────────────────────────────────
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

if [ -z "$TARGET" ]; then
  echo "❌  pdfQuestionParser.js not found in expected locations."
  echo "    Common paths checked:"
  for P in "${POSSIBLE_PATHS[@]}"; do echo "      $P"; done
  echo ""
  echo "    Run:  find ~/workspace -name 'pdfQuestionParser.js' 2>/dev/null"
  echo "    Then re-run this script with:"
  echo "      TARGET=/your/actual/path bash fix_pdfQuestionParser.sh"
  exit 1
fi

# Allow override via env
TARGET="${TARGET_OVERRIDE:-$TARGET}"
echo "✅  Found: $TARGET"

# ── Backup ───────────────────────────────────────────────────
cp "$TARGET" "${TARGET}.bak_$(date +%Y%m%d_%H%M%S)"
echo "✅  Backup created"

# ── Write fixed file ─────────────────────────────────────────
cat > "$TARGET" << 'ENDOFFILE'
const fs = require('fs');
const pdfParse = require('pdf-parse');

// ══════════════════════════════════════════════════════════════
// Feature 21 / 21B — PDF Question Parsing Engine
// Supports: ALLEN (N) opts), CLC (N. opts), AAKASH (Question:N),
//           Standard (Q. N / A-D opts)
// ══════════════════════════════════════════════════════════════

// ── Numeric option helper ──────────────────────────────────
// Maps option number 1-4 → letter A-D
const NUM_TO_LETTER = { '1': 'A', '2': 'B', '3': 'C', '4': 'D' };
function numOptToLetter(n) { return NUM_TO_LETTER[String(n)] || null; }

// F21.2.1 — Extract text page-by-page
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
  } catch (e) { /* fall through */ }
  const data = await pdfParse(buffer);
  return [data.text || ''];
}

// F21.2.1 — Strip repeating headers/footers
// FIX: optionLikePattern now includes (1)/(2)/(3)/(4) so numeric options
//      are never mistaken for repeating lines.
function stripRepeatingLines(pages) {
  const optionLikePattern = /^[\(\[]?[A-Da-d1-4][\)\]\.:\-]/i;
  const commonOptionPhrase = /^(true|false|yes|no|none of (the )?above|all of (the )?above|cannot be determined|none of these|both \w+ and \w+)\.?$/i;
  const questionLikePattern = /^Q?\s*\d+[\.)\:\-]/i;

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
      return linePageCounts[l] >= pageThreshold ||
             (pages.length <= 2 && lineTotalCounts[l] >= 2 && wordCount >= 2);
    })
  );
  return {
    cleanedPages: pages.map(p => p.split('\n').filter(l => !repeating.has(l.trim())).join('\n')),
    repeatingLines: [...repeating],
  };
}

// F21.3.8 — Language detection
function detectLanguage(text) {
  const hindiChars = (text.match(/[\u0900-\u097F]/g) || []).length;
  const engChars   = (text.match(/[A-Za-z]/g) || []).length;
  if (hindiChars > 20 && engChars > 20) return 'Bilingual';
  if (hindiChars > engChars) return 'Hindi';
  return 'English';
}

// F21.1.7 — Subject range map parser
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

// ── Answer Key Parser ──────────────────────────────────────
// FIX: Now handles 4 formats:
//  1) AAKASH style  — "Question : N ... Answer (M)" where M = option 1-4
//  2) Standalone    — sequential "Answer (N)" blocks in solution PDFs
//  3) Numeric opt   — "1. (3)" or "1) 3" where 3 = 1-based option index
//  4) Standard      — "Q1 - B", "1. A", "1) D"  (original logic, kept intact)
function parseAnswerKey(text) {
  const map = {};
  if (!text || !text.trim()) return map;

  // ── Pass 1: AAKASH style "Question : N ... Answer (M)" ──────
  // Each question block ends at next "Question :" or end of string.
  if (/Question\s*[:\s]+\d+/im.test(text)) {
    const aakashRe = /Question\s*[:\s]+(\d+)[\s\S]{0,2000}?Answer\s*\(\s*([1-4A-Da-d])\s*\)/gim;
    let found = false;
    for (const m of text.matchAll(aakashRe)) {
      const qNum = parseInt(m[1]);
      const raw  = m[2].trim().toUpperCase();
      const letter = /^[1-4]$/.test(raw) ? numOptToLetter(raw) : raw;
      if (letter && /^[A-D]$/.test(letter)) { map[qNum] = { letters: [letter] }; found = true; }
    }
    if (found) return map;
  }

  // ── Pass 2: Standalone sequential "Answer (N)" in solution PDFs ──
  const standaloneList = [...text.matchAll(/(?:^|\n)\s*Answer\s*\(\s*([1-4A-Da-d])\s*\)/gim)];
  if (standaloneList.length > 0) {
    standaloneList.forEach((m, idx) => {
      // Try to find question number in preceding 500 chars
      const pre = text.slice(Math.max(0, m.index - 500), m.index);
      const qMatch = pre.match(/(?:^|\n)\s*Q?\s*(\d+)\s*[.)\-:\s]/im);
      const qNum = qMatch ? parseInt(qMatch[1]) : idx + 1;
      const raw  = m[1].trim().toUpperCase();
      const letter = /^[1-4]$/.test(raw) ? numOptToLetter(raw) : raw;
      if (letter && /^[A-D]$/.test(letter)) { map[qNum] = { letters: [letter] }; }
    });
    if (Object.keys(map).length > 0) return map;
  }

  // ── Pass 3: Standard & numeric-option formats ────────────────
  const cleaned = extractAnswerKeySection(text);
  const lines   = cleaned.trim().split('\n').map(l => l.trim()).filter(Boolean);
  let foundAny  = false;

  // "Q?N - X"  where X = letter(s), numeric answer, or option number 1-4
  const matches = cleaned.matchAll(/Q?\s*(\d+)\s*[\-\.)\:]\s*\(?([A-Da-d,\s]+|\-?\d+\.?\d*)\)?/g);
  for (const m of matches) {
    foundAny = true;
    const qNum = parseInt(m[1]);
    const raw  = m[2].trim();
    if (/^[A-Da-d,\s]+$/.test(raw)) {
      const letters = [...new Set((raw.toUpperCase().match(/[A-D]/g) || []))];
      if (letters.length > 0) map[qNum] = { letters };
    } else if (/^[1-4]$/.test(raw)) {
      // FIX: single digit 1-4 = numeric option index → convert to letter
      const letter = numOptToLetter(raw);
      if (letter) map[qNum] = { letters: [letter] };
    } else {
      const num = parseFloat(raw);
      if (!isNaN(num)) map[qNum] = { numeric: num };
    }
  }
  if (foundAny) return map;

  // Single-char-per-line  A / B / C / D
  if (lines.length > 0 && lines.every(l => /^[A-Da-d]$/.test(l))) {
    lines.forEach((l, i) => { map[i + 1] = { letters: [l.toUpperCase()] }; });
    return map;
  }
  // All on one line  "ADBC..."
  if (lines.length === 1 && /^[A-Da-d]+$/.test(lines[0])) {
    lines[0].split('').forEach((ch, i) => { map[i + 1] = { letters: [ch.toUpperCase()] }; });
  }
  return map;
}

// ── Explanation Parser ─────────────────────────────────────
// FIX: Now handles AAKASH "Question : N" blocks with "Solution :" section,
//      CLC "N." blocks, and original standard format.
function parseExplanations(text) {
  const map = {};
  if (!text || !text.trim()) return map;

  // AAKASH format: "Question : N ... Solution : ... Answer (M) ... explanation"
  if (/Question\s*[:\s]+\d+/im.test(text)) {
    const blocks = text.split(/(?=(?:^|\n)\s*Question\s*[:\s]+\d+)/im);
    blocks.forEach(block => {
      const qMatch = block.match(/Question\s*[:\s]+(\d+)/i);
      if (!qMatch) return;
      const qNum = parseInt(qMatch[1]);
      const solMatch = block.match(/Solution\s*:?\s*([\s\S]+)/i);
      if (solMatch) {
        // Remove the "Answer (N)" line from explanation, keep the rest
        const raw = solMatch[1].replace(/^\s*Answer\s*\([1-4A-Da-d]\)\s*/i, '').trim();
        if (raw) map[qNum] = raw;
      }
    });
    if (Object.keys(map).length > 0) return map;
  }

  // Standard / CLC: split on "Q?N." or "N)" at line start
  const cleaned = extractExplanationSection(text);
  const blocks  = cleaned.split(/(?=(?:^|\n)\s*Q?\d+[\.)\:\-\s])/im);
  blocks.forEach(block => {
    const m = block.trim().match(/^Q?\s*(\d+)[\.)\:\-\s]+([\s\S]+)/);
    if (m) map[parseInt(m[1])] = m[2].trim();
  });
  return map;
}

// ── Block Splitter ─────────────────────────────────────────
// FIX: Added "Question : N" pattern (AAKASH) as highest priority.
function splitIntoBlocks(text, customDelim) {
  if (customDelim && text.includes(customDelim)) {
    return text.split(customDelim).map(s => s.trim()).filter(Boolean);
  }
  const patterns = [
    { re: /(?=(?:^|\n)\s*Question\s*[:\s]+\s*\d+)/im, name: 'question-label' }, // AAKASH
    { re: /(?=(?:^|\n)\s*Q\s*\.?\s*\d+[\s\.)\:\-])/im, name: 'Q-number' },       // Q1. / Q1)
    { re: /(?=(?:^|\n)\s*\d+[\.)\:\-\s])/m,            name: 'numbered' },        // 1. / 1) ALLEN
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
// FIX: Now supports three option formats:
//   A) ALLEN / CLC  — (1) opt1 / (2) opt2 / (3) opt3 / (4) opt4
//   B) AAKASH       — "Options:\n" header then plain-text lines
//   C) Standard     — (A) opt1 / (B) opt2  [original logic, kept]
// Also handles "Question : N" prefix and skips AAKASH metadata lines.
function parseOneBlock(block, idx, pageHint) {
  const lines = block.split('\n').map(l => l.trim()).filter(Boolean);
  if (lines.length === 0) return { num: idx + 1, text: '', options: [], hasParseError: true, parseError: 'Empty block' };

  // ── Detect question number ──
  let qNum = idx + 1;
  const aakashNumMatch = lines[0].match(/^Question\s*[:\s]+(\d+)/i);
  const standardNumMatch = lines[0].match(/^Q?\s*(\d+)[\s\.)\:\-]/i);
  if (aakashNumMatch)  qNum = parseInt(aakashNumMatch[1]);
  else if (standardNumMatch) qNum = parseInt(standardNumMatch[1]);

  // ── Strip question number prefix, start collecting question text ──
  let qText = '';
  let i = 0;
  if (aakashNumMatch) {
    qText = lines[0].replace(/^Question\s*[:\s]+\d+\s*/i, '').trim();
    i = 1;
    // Skip AAKASH metadata: "You scored 4 of 4", "Time:", etc.
    while (i < lines.length && /^(You scored|Score:|Time\s*:|Marks?\s*:)/i.test(lines[i])) i++;
  } else {
    qText = lines[0].replace(/^Q?\s*\d+[\s\.)\:\-]\s*/i, '').trim();
    i = 1;
  }

  // Option line regexes — all three formats
  const optAlpha   = /^(?:Option\s*)?[\(\[]?\s*([A-Da-d])\s*[\)\]\.:\-\s]+(.+)/i; // (A) / A) / A.
  const optNumeric = /^[\(\[]\s*([1-4])\s*[\)\]\.:\-]\s*(.+)/;                     // (1) / [1] / (1).
  const optHeader  = /^Options?\s*:?\s*$/i;                                          // "Options:" header
  const solMarker  = /^Solution\s*:?\s*$/i;
  const secHeader  = /^(PHYSICS|CHEMISTRY|BIOLOGY|MATHEMATICS|MATH|SECTION[\s\-]\w)/i;

  // ── Accumulate question text lines until options start ──
  while (i < lines.length) {
    const l = lines[i];
    if (optAlpha.test(l) || optNumeric.test(l) || optHeader.test(l)) break;
    if (solMarker.test(l)) break;
    if (secHeader.test(l) && l.length < 30) break;
    qText += (qText ? ' ' : '') + l;
    i++;
  }

  // ── Skip "Options:" header if present (AAKASH) ──
  let afterOptionsHeader = false;
  if (i < lines.length && optHeader.test(lines[i])) { i++; afterOptionsHeader = true; }

  // ── Parse options ──
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
      // AAKASH plain-text options after "Options:" header
      options.push(l);
      i++;
    } else {
      break;
    }
  }

  const errors = [];
  if (!qText.trim()) errors.push('Question text empty');
  if (options.length < 2) errors.push('Options not detected (<2) — Page ' + (pageHint || '?'));

  return {
    num: qNum,
    text: qText.trim(),
    options,
    isNumericOptions,
    hasParseError: errors.length > 0,
    parseError: errors.join('; '),
  };
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
  const fullQuestionText = selectedPages.join('\n');

  const language = detectLanguage(fullQuestionText);

  const ansPages       = await extractPagesText(answerKeyPdfPath);
  const fullAnswerText = ansPages.join('\n');
  const answerMap      = parseAnswerKey(fullAnswerText);

  let explanationMap = {};
  if (explanationPdfPath) {
    const explPages = await extractPagesText(explanationPdfPath);
    explanationMap = parseExplanations(explPages.join('\n'));
  }
  // If answer key PDF is AAKASH solution style, also extract explanations from it
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

// F21.16 — OCR fallback (optional, graceful fail)
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
  buildQuestionsFromPDFs,
  ocrFallback,
};
ENDOFFILE

echo "✅  pdfQuestionParser.js updated at: $TARGET"
echo ""
echo "━━ Changes applied ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Fix 1 — stripRepeatingLines: (1)/(2)/(3)/(4) options"
echo "           no longer stripped as repeating lines"
echo "  Fix 2 — splitIntoBlocks: 'Question : N' AAKASH pattern added"
echo "  Fix 3 — parseOneBlock: (1)/(2)/(3)/(4) numeric options detected"
echo "           + 'Options:' header support (AAKASH)"
echo "           + 'You scored N of N' metadata lines skipped"
echo "  Fix 4 — parseAnswerKey: 'Answer (2)' AAKASH format supported"
echo "           + '1. (3)' numeric option answer supported"
echo "  Fix 5 — parseExplanations: 'Question : N / Solution :' blocks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄  Restart your server after applying:"
echo "    cd ~/workspace && pm2 restart all"
echo "    OR: npm run dev"
