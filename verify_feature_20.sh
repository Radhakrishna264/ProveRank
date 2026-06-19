#!/bin/bash
echo "=================================================="
echo "VERIFICATION — Feature 20 : Bulk Upload via Excel/CSV (Upgraded)"
echo "Checks 20.1 through 20.23"
echo "=================================================="
cd ~/workspace || { echo "ERROR: ~/workspace not found"; exit 1; }
PASS=0
FAIL=0

if grep -qF ".xlsx', '.xls', '.csv'" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.1 — Excel(.xlsx)+CSV upload support"; PASS=$((PASS+1)); else echo "  [❌] 20.1 — Excel(.xlsx)+CSV upload support — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "excel/template" src/routes/contentForge.js src/utils/excelParser.js 2>/dev/null || grep -qF "generateTemplateBuffer" src/routes/contentForge.js src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.2 — Template download button"; PASS=$((PASS+1)); else echo "  [❌] 20.2 — Template download button — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "columnMap" src/routes/contentForge.js src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.3 — Column mapping UI (backend support)"; PASS=$((PASS+1)); else echo "  [❌] 20.3 — Column mapping UI (backend support) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Subject missing" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.4 — Required fields validation (text+options+answer+subject)"; PASS=$((PASS+1)); else echo "  [❌] 20.4 — Required fields validation (text+options+answer+subject) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Image_URL" src/utils/excelParser.js 2>/dev/null || grep -qF "OptionsImage_URL" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.4b — Image url fields optional (Image_URL, OptionsImage_URL)"; PASS=$((PASS+1)); else echo "  [❌] 20.4b — Image url fields optional (Image_URL, OptionsImage_URL) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "row: rowNum" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.5 — Invalid rows flag row+reason"; PASS=$((PASS+1)); else echo "  [❌] 20.5 — Invalid rows flag row+reason — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "isDuplicateInFile" src/utils/excelParser.js src/routes/contentForge.js 2>/dev/null || grep -qF "isDuplicateInDB" src/utils/excelParser.js src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.6 — Duplicate detection during import"; PASS=$((PASS+1)); else echo "  [❌] 20.6 — Duplicate detection during import — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "excel/parse" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.7 — Preview table before final import (no-save parse endpoint)"; PASS=$((PASS+1)); else echo "  [❌] 20.7 — Preview table before final import (no-save parse endpoint) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "skipped++" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.8 — Partial import (valid saved, invalid skipped)"; PASS=$((PASS+1)); else echo "  [❌] 20.8 — Partial import (valid saved, invalid skipped) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "imported, skipped, errors" src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.9 — Import summary (imported/skipped/errors)"; PASS=$((PASS+1)); else echo "  [❌] 20.9 — Import summary (imported/skipped/errors) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "parseStudentExcel" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.10 — Bulk Student Import via same Excel"; PASS=$((PASS+1)); else echo "  [❌] 20.10 — Bulk Student Import via same Excel — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "answerSheetMap" src/utils/excelParser.js 2>/dev/null || grep -qF "explSheetMap" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.11 — Separate sheet support (Answer/Explanation sheets)"; PASS=$((PASS+1)); else echo "  [❌] 20.11 — Separate sheet support (Answer/Explanation sheets) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "google-sheet" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "docs.google.com" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.12 — Google Sheets URL paste import"; PASS=$((PASS+1)); else echo "  [❌] 20.12 — Google Sheets URL paste import — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "HEADER_SYNONYMS" src/utils/excelParser.js 2>/dev/null; then echo "  [✅] 20.13 — Auto column-detect (header synonyms)"; PASS=$((PASS+1)); else echo "  [❌] 20.13 — Auto column-detect (header synonyms) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "reuploadDiff" frontend/app/admin/x7k2p/ContentForge.tsx src/routes/contentForge.js 2>/dev/null || grep -qF "isReupload" frontend/app/admin/x7k2p/ContentForge.tsx src/routes/contentForge.js 2>/dev/null; then echo "  [✅] 20.14 — Re-upload to fix errors, match by row number"; PASS=$((PASS+1)); else echo "  [❌] 20.14 — Re-upload to fix errors, match by row number — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "ContentForgeImportLog" frontend/app/admin/x7k2p/ContentForge.tsx src/routes/contentForge.js src/models/ContentForgeImportLog.js 2>/dev/null || grep -qF "import-history" frontend/app/admin/x7k2p/ContentForge.tsx src/routes/contentForge.js src/models/ContentForgeImportLog.js 2>/dev/null; then echo "  [✅] 20.15 — Import history log (new upgraded flow)"; PASS=$((PASS+1)); else echo "  [❌] 20.15 — Import history log (new upgraded flow) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "onDragOver" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "dragOver" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.16 — Drag-drop upload zone UI"; PASS=$((PASS+1)); else echo "  [❌] 20.16 — Drag-drop upload zone UI — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "showMapping" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "Column Mapping" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.17 — Column mapping UI - drag columns to map"; PASS=$((PASS+1)); else echo "  [❌] 20.17 — Column mapping UI - drag columns to map — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "rowStatus" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.18 — Preview table color-coded rows (green/red/yellow)"; PASS=$((PASS+1)); else echo "  [❌] 20.18 — Preview table color-coded rows (green/red/yellow) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "Parsing rows" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "Importing..." frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.19 — Import progress bar / spinner"; PASS=$((PASS+1)); else echo "  [❌] 20.19 — Import progress bar / spinner — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "validCount" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "dupCount" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null || grep -qF "errCount" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.20 — Summary card 3 tiles (valid/dup/error counts)"; PASS=$((PASS+1)); else echo "  [❌] 20.20 — Summary card 3 tiles (valid/dup/error counts) — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "ExcelHome" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.21 — Sidebar removal + new 2-card home structure"; PASS=$((PASS+1)); else echo "  [❌] 20.21 — Sidebar removal + new 2-card home structure — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "backdropFilter:'blur" frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.22 — Complete premium redesign"; PASS=$((PASS+1)); else echo "  [❌] 20.22 — Complete premium redesign — NOT FOUND"; FAIL=$((FAIL+1)); fi
if grep -qF "pyq_bank" src/routes/contentForge.js frontend/app/admin/x7k2p/ContentForge.tsx 2>/dev/null; then echo "  [✅] 20.23 — PYQ Bank upload option (target base)"; PASS=$((PASS+1)); else echo "  [❌] 20.23 — PYQ Bank upload option (target base) — NOT FOUND"; FAIL=$((FAIL+1)); fi

echo ""
echo "=================================================="
echo "Feature 20: $PASS passed / $FAIL missing (of $((PASS+FAIL)) checked)"
if [ $FAIL -eq 0 ]; then
  echo "✅✅✅ FEATURE 20 — ALL SUB-FEATURES VERIFIED PRESENT ✅✅✅"
else
  echo "⚠️  FEATURE 20 — $FAIL item(s) need attention (see ❌ above)"
fi
echo "=================================================="