#!/bin/bash
echo "=================================================="
echo "VERIFICATION — Feature 21B : Create Exam via PDF Parsing"
echo "Checks 21B.1 through 21B.33"
echo "=================================================="
cd ~/workspace || { echo "ERROR: ~/workspace not found"; exit 1; }
PASS=0
FAIL=0

if grep -qF "PDFUploadZone" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.1 — PDF upload zone for Create-Exam flow (Q+Answer+Explanation)"; PASS=$((PASS+1)); else echo "  [❌] 21B.1 — PDF upload zone for Create-Exam flow (Q+Answer+Explanation) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Subject Allotment" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.1.7 — Subject allotment per question-range input"; PASS=$((PASS+1)); else echo "  [❌] 21B.1.7 — Subject allotment per question-range input — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "F21.1.7B" src/utils/pdfQuestionParser.js 2>/dev/null || grep -qF "parseSubjectRangeMap" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.1.7B — Range format Q1-Q45 Physics support"; PASS=$((PASS+1)); else echo "  [❌] 21B.1.7B — Range format Q1-Q45 Physics support — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "F21.1.7C" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.1.7C — Per-question format Q1. Physics support"; PASS=$((PASS+1)); else echo "  [❌] 21B.1.7C — Per-question format Q1. Physics support — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "extractPagesText" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.2 — Text extraction page-by-page"; PASS=$((PASS+1)); else echo "  [❌] 21B.2 — Text extraction page-by-page — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "stripRepeatingLines" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.2.1 — Repeating header/footer auto-strip"; PASS=$((PASS+1)); else echo "  [❌] 21B.2.1 — Repeating header/footer auto-strip — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "splitIntoBlocks" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.3 — Question block splitter (numbered/Q-no/roman)"; PASS=$((PASS+1)); else echo "  [❌] 21B.3 — Question block splitter (numbered/Q-no/roman) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Q-number" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.3.1 — Q-number format detection"; PASS=$((PASS+1)); else echo "  [❌] 21B.3.1 — Q-number format detection — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "optionLineRe" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.3.5 — Option format detect (A)/A./a)"; PASS=$((PASS+1)); else echo "  [❌] 21B.3.5 — Option format detect (A)/A./a) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "previewMode" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.4 — Preview parsed Qs / Exam preview toggle"; PASS=$((PASS+1)); else echo "  [❌] 21B.4 — Preview parsed Qs / Exam preview toggle — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "parseAnswerKey" src/utils/pdfQuestionParser.js 2>/dev/null; then echo "  [✅] 21B.5 — Answer key PDF sync SCQ/MSQ/Integer"; PASS=$((PASS+1)); else echo "  [❌] 21B.5 — Answer key PDF sync SCQ/MSQ/Integer — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Could not parse PDF" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21B.6 — Graceful error handling for bad PDFs"; PASS=$((PASS+1)); else echo "  [❌] 21B.6 — Graceful error handling for bad PDFs — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "editingQ && editDraft" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.7 — Edit individual question modal"; PASS=$((PASS+1)); else echo "  [❌] 21B.7 — Edit individual question modal — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "editDraft.subject" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.7.3 — Edit modal: text/options/answer/subject/chapter"; PASS=$((PASS+1)); else echo "  [❌] 21B.7.3 — Edit modal: text/options/answer/subject/chapter — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "moveQuestion" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.7.5 — Re-order questions up/down arrows"; PASS=$((PASS+1)); else echo "  [❌] 21B.7.5 — Re-order questions up/down arrows — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "DuplicateCheckPanel" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.7.6 — Duplicate-in-exam/batch check wired in UI"; PASS=$((PASS+1)); else echo "  [❌] 21B.7.6 — Duplicate-in-exam/batch check wired in UI — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "ExamDetailsForm" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.8 — Exam Details form (shared step)"; PASS=$((PASS+1)); else echo "  [❌] 21B.8 — Exam Details form (shared step) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "totalQuestionsRequested" frontend/app/admin/x7k2p/ContentForge.tsx src/utils/examBuilder.js 2>/dev/null; then echo "  [✅] 21B.8.4 — Total Questions input (auto-select N of M)"; PASS=$((PASS+1)); else echo "  [❌] 21B.8.4 — Total Questions input (auto-select N of M) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "subjectWiseCount" frontend/app/admin/x7k2p/ContentForge.tsx src/utils/examBuilder.js 2>/dev/null; then echo "  [✅] 21B.8.5 — Subject-wise Qs count distribution"; PASS=$((PASS+1)); else echo "  [❌] 21B.8.5 — Subject-wise Qs count distribution — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "unlimitedAttempts" frontend/app/admin/x7k2p/ContentForge.tsx src/models/Exam.js 2>/dev/null; then echo "  [✅] 21B.8.16 — Unlimited attempts option"; PASS=$((PASS+1)); else echo "  [❌] 21B.8.16 — Unlimited attempts option — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "fromQNo" src/models/Exam.js src/utils/examBuilder.js 2>/dev/null || grep -qF "toQNo" src/models/Exam.js src/utils/examBuilder.js 2>/dev/null; then echo "  [✅] 21B.8.21 — Subject Q-No range mapping for live exam"; PASS=$((PASS+1)); else echo "  [❌] 21B.8.21 — Subject Q-No range mapping for live exam — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "AssignmentSelector" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.9 — Assignment selector (Batch/Series/Mini/Individual)"; PASS=$((PASS+1)); else echo "  [❌] 21B.9 — Assignment selector (Batch/Series/Mini/Individual) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Test Series" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.9.2 — Test Series dropdown"; PASS=$((PASS+1)); else echo "  [❌] 21B.9.2 — Test Series dropdown — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "multiBatchEnabled" frontend/app/admin/x7k2p/ContentForge.tsx src/models/Exam.js 2>/dev/null; then echo "  [✅] 21B.9.7 — Multi-batch assign toggle"; PASS=$((PASS+1)); else echo "  [❌] 21B.9.7 — Multi-batch assign toggle — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pdf/create-exam" frontend/app/admin/x7k2p/ContentForge.tsx src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 21B.10 — Create Exam submit → backend builder"; PASS=$((PASS+1)); else echo "  [❌] 21B.10 — Create Exam submit → backend builder — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "sourceMeta" frontend/app/admin/x7k2p/ContentForge.tsx src/models/Exam.js 2>/dev/null; then echo "  [✅] 21B.10.3 — Source meta tracking (pageCount/parsed/errors)"; PASS=$((PASS+1)); else echo "  [❌] 21B.10.3 — Source meta tracking (pageCount/parsed/errors) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "PostCreateActions" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.11 — Post-create actions step"; PASS=$((PASS+1)); else echo "  [❌] 21B.11 — Post-create actions step — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "scheduledPublishEnabled" frontend/app/admin/x7k2p/ContentForge.tsx src/models/Exam.js 2>/dev/null; then echo "  [✅] 21B.11.1 — Scheduled auto-publish toggle"; PASS=$((PASS+1)); else echo "  [❌] 21B.11.1 — Scheduled auto-publish toggle — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "isTemplate" frontend/app/admin/x7k2p/ContentForge.tsx src/models/Exam.js 2>/dev/null; then echo "  [✅] 21B.11.4 — Save as Template"; PASS=$((PASS+1)); else echo "  [❌] 21B.11.4 — Save as Template — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "will be notified" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.11.6 — Notify Students toggle + count preview"; PASS=$((PASS+1)); else echo "  [❌] 21B.11.6 — Notify Students toggle + count preview — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pageFrom" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "pageTo" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.12 — Page range selector (from-to)"; PASS=$((PASS+1)); else echo "  [❌] 21B.12 — Page range selector (from-to) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "PreSubmitChecklist" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.13 — Pre-submit checklist before create"; PASS=$((PASS+1)); else echo "  [❌] 21B.13 — Pre-submit checklist before create — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "MathText" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "renderMath" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.31 — LaTeX/KaTeX rendering in preview"; PASS=$((PASS+1)); else echo "  [❌] 21B.31 — LaTeX/KaTeX rendering in preview — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "qbView=\"pdf_qs\" examView=\"pdf_exam\"" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.32 — PDFHome 2-card structure (QB upload / Create Exam)"; PASS=$((PASS+1)); else echo "  [❌] 21B.32 — PDFHome 2-card structure (QB upload / Create Exam) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "backdropFilter:'blur" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 21B.33 — Premium Ultra SaaS design upgrade"; PASS=$((PASS+1)); else echo "  [❌] 21B.33 — Premium Ultra SaaS design upgrade — NOT FOUND"; FAIL=$((FAIL+1)); fi

echo ""
echo "=================================================="
echo "Feature 21B: $PASS passed / $FAIL missing (of $((PASS+FAIL)) checked)"
if [ $FAIL -eq 0 ]; then
  echo "✅✅✅ FEATURE 21B — ALL SUB-FEATURES VERIFIED PRESENT ✅✅✅"
else
  echo "⚠️  FEATURE 21B — $FAIL item(s) need attention (see ❌ above)"
fi
echo "=================================================="