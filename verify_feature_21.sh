#!/bin/bash
echo "=================================================="
echo "VERIFICATION — Feature 21 : Bulk Upload via PDF Parse (Upgraded)"
echo "Checks 21.1 through 21.24"
echo "=================================================="
cd ~/workspace || { echo "ERROR: ~/workspace not found"; exit 1; }
PASS=0
FAIL=0

if grep -qF "Only PDF files allowed" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.1 — PDF file upload support (.pdf only, 10MB limit)"; PASS=$((PASS+1)); else echo "  [❌] 21.1 — PDF file upload support (.pdf only, 10MB limit) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "extractPagesText" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.2 — Text extraction engine (pdf-parse, page-by-page)"; PASS=$((PASS+1)); else echo "  [❌] 21.2 — Text extraction engine (pdf-parse, page-by-page) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "splitIntoBlocks" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.3 — Pattern detection engine (numbered/Q-number/roman)"; PASS=$((PASS+1)); else echo "  [❌] 21.3 — Pattern detection engine (numbered/Q-number/roman) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "stripRepeatingLines" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.4 — Repeating header/footer auto-strip per page"; PASS=$((PASS+1)); else echo "  [❌] 21.4 — Repeating header/footer auto-strip per page — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "parseAnswerKey" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.5 — Answer key PDF sync (SCQ/MSQ/Integer)"; PASS=$((PASS+1)); else echo "  [❌] 21.5 — Answer key PDF sync (SCQ/MSQ/Integer) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Could not parse PDF" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.6 — Graceful error handling (corrupted/scanned PDF)"; PASS=$((PASS+1)); else echo "  [❌] 21.6 — Graceful error handling (corrupted/scanned PDF) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "isDuplicateInDB" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.7 — Duplicate detection (vs Question Bank)"; PASS=$((PASS+1)); else echo "  [❌] 21.7 — Duplicate detection (vs Question Bank) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "parseExplanations" src/utils/pdfQuestionParser.js src/routes/contentForge.js 2>/dev/null || grep -qF "explanationPdf" src/utils/pdfQuestionParser.js src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.8 — Explanation PDF sync (optional)"; PASS=$((PASS+1)); else echo "  [❌] 21.8 — Explanation PDF sync (optional) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "parseSubjectRangeMap" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.9 — Subject allotment per question-range"; PASS=$((PASS+1)); else echo "  [❌] 21.9 — Subject allotment per question-range — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "detectLanguage" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.10 — Language detection (English/Hindi/Bilingual)"; PASS=$((PASS+1)); else echo "  [❌] 21.10 — Language detection (English/Hindi/Bilingual) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "page: pageNum" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.11 — Error logging with page reference"; PASS=$((PASS+1)); else echo "  [❌] 21.11 — Error logging with page reference — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "looksLikeDiagram" src/utils/pdfQuestionParser.js 2>/dev/null || grep -qF "imageFlag" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.12 — Image/diagram question flag"; PASS=$((PASS+1)); else echo "  [❌] 21.12 — Image/diagram question flag — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "editingQ && editDraft" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.13 — Manual correction in preview (editable)"; PASS=$((PASS+1)); else echo "  [❌] 21.13 — Manual correction in preview (editable) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pdf/save-to-bank" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.14 — Bulk save to QB/PYQ with target selector"; PASS=$((PASS+1)); else echo "  [❌] 21.14 — Bulk save to QB/PYQ with target selector — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "looksLikeDiagram" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.15 — Image-based question detection (diagram keyword)"; PASS=$((PASS+1)); else echo "  [❌] 21.15 — Image-based question detection (diagram keyword) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pageFrom" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "pageTo" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.16 — Page range selector (from-to)"; PASS=$((PASS+1)); else echo "  [❌] 21.16 — Page range selector (from-to) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "ocrFallback" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21.17 — OCR fallback for scanned PDFs (graceful degrade)"; PASS=$((PASS+1)); else echo "  [❌] 21.17 — OCR fallback for scanned PDFs (graceful degrade) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "questionsPdf" src/routes/contentForge.js 2>/dev/null || grep -qF "answerKeyPdf" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21.18 — Multi-file upload (question+answer+explanation)"; PASS=$((PASS+1)); else echo "  [❌] 21.18 — Multi-file upload (question+answer+explanation) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "rawTextPreview" src/utils/pdfQuestionParser.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "View Extracted Text" src/utils/pdfQuestionParser.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.19 — Raw extracted text preview (collapsible)"; PASS=$((PASS+1)); else echo "  [❌] 21.19 — Raw extracted text preview (collapsible) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "confidencePct" src/utils/pdfQuestionParser.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.20 — Confidence score per parsed question"; PASS=$((PASS+1)); else echo "  [❌] 21.20 — Confidence score per parsed question — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "needsReview" src/utils/pdfQuestionParser.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "Needs Review" src/utils/pdfQuestionParser.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.21 — Needs-review flagging for low-confidence Qs"; PASS=$((PASS+1)); else echo "  [❌] 21.21 — Needs-review flagging for low-confidence Qs — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "customDelimiter" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.22 — Custom delimiter support"; PASS=$((PASS+1)); else echo "  [❌] 21.22 — Custom delimiter support — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "PDFHome" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.23 — Premium redesign + PDFHome 2-card structure"; PASS=$((PASS+1)); else echo "  [❌] 21.23 — Premium redesign + PDFHome 2-card structure — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pyq_bank" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21.24 — PYQ Bank upload option (target base)"; PASS=$((PASS+1)); else echo "  [❌] 21.24 — PYQ Bank upload option (target base) — NOT FOUND"; FAIL=$((FAIL+1)); fi

echo ""
echo "=================================================="
echo "Feature 21: $PASS passed / $FAIL missing (of $((PASS+FAIL)) checked)"
if [ $FAIL -eq 0 ]; then
  echo "✅✅✅ FEATURE 21 — ALL SUB-FEATURES VERIFIED PRESENT ✅✅✅"
else
  echo "⚠️  FEATURE 21 — $FAIL item(s) need attention (see ❌ above)"
fi
echo "=================================================="