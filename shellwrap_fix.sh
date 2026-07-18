#!/bin/bash
# ============================================================================
# ProveRank — StudentShell Wrap Fix
# Wraps My Batches & Test Series pages in <StudentShell> so they get the
# same sidebar/topbar/theme/language toggle as every other dashboard page.
# No other logic/styling changed — page content is 100% preserved.
# Run from your frontend project ROOT on Replit.
# ============================================================================
set -e
echo "🚀 StudentShell Wrap Fix — Starting..."

MB_PAGE=$(grep -rl "MyBatchesPage" --include="page.tsx" . 2>/dev/null | head -1)
TS_PAGE=$(grep -rl "TestSeriesPage" --include="page.tsx" . 2>/dev/null | head -1)
SHELL_FILE=$(find . -type f -name "StudentShell.tsx" -not -path "*/node_modules/*" 2>/dev/null | head -1)

if [ -z "$MB_PAGE" ]; then echo "❌ My Batches page.tsx not found."; exit 1; fi
if [ -z "$TS_PAGE" ]; then echo "❌ Test Series page.tsx not found."; exit 1; fi
if [ -z "$SHELL_FILE" ]; then echo "❌ StudentShell.tsx not found."; exit 1; fi
echo "📍 My Batches:   $MB_PAGE"
echo "📍 Test Series:  $TS_PAGE"
echo "📍 StudentShell: $SHELL_FILE"

if grep -q "MyBatchesPage" <<< "$(cat "$MB_PAGE")" && grep -q "<StudentShell" "$MB_PAGE"; then
  echo "ℹ️  My Batches page already wrapped in StudentShell — skipping"
else
  cp "$MB_PAGE" "$MB_PAGE.pre-shellwrap-bak"
  node -e "
    const fs = require('fs');
    const path = '$MB_PAGE';
    let c = fs.readFileSync(path, 'utf8');

    const importAnchor = \"import { useRouter } from 'next/navigation'\";
    const importLine = \"\nimport StudentShell from '@/src/components/StudentShell'\";
    if (!c.includes(importLine.trim())) {
      c = c.replace(importAnchor, importAnchor + importLine);
    }

    const openOld = \"return (\n    <div style={{minHeight:'100vh',color:TEXT,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:BG, ...(vars as any)}}>\";
    const openNew = \"return (\n    <StudentShell pageKey=\\\"my-batches\\\">\n    <div style={{minHeight:'100vh',color:TEXT,fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:BG, ...(vars as any)}}>\";
    if (!c.includes(openNew)) {
      if (!c.includes(openOld)) { console.error('❌ My Batches: opening anchor not found — aborting, no changes made'); process.exit(1); }
      c = c.replace(openOld, openNew);
    }

    const closeOld = \"        </div>\n\n      </div>\n    </div>\n  )\n}\";
    const closeNew = \"        </div>\n\n      </div>\n    </div>\n    </StudentShell>\n  )\n}\";
    if (!c.includes(closeNew)) {
      if (!c.includes(closeOld)) { console.error('❌ My Batches: closing anchor not found — aborting, no changes made'); process.exit(1); }
      c = c.replace(closeOld, closeNew);
    }

    fs.writeFileSync(path, c);
    console.log('✅ My Batches page wrapped in StudentShell');
  "
fi

if grep -q "<StudentShell" "$TS_PAGE"; then
  echo "ℹ️  Test Series page already wrapped in StudentShell — skipping"
else
  cp "$TS_PAGE" "$TS_PAGE.pre-shellwrap-bak"
  node -e "
    const fs = require('fs');
    const path = '$TS_PAGE';
    let c = fs.readFileSync(path, 'utf8');

    const importAnchor = \"import { useRouter } from 'next/navigation'\";
    const importLine = \"\nimport StudentShell from '@/src/components/StudentShell'\";
    if (!c.includes(importLine.trim())) {
      c = c.replace(importAnchor, importAnchor + importLine);
    }

    const openOld = \"return (\n    <div style={{ minHeight:'100vh',color:'var(--pr-text)',fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:'var(--pr-bg)', ...(vars as any) }}>\";
    const openNew = \"return (\n    <StudentShell pageKey=\\\"test-series\\\">\n    <div style={{ minHeight:'100vh',color:'var(--pr-text)',fontFamily:'Inter,sans-serif',position:'relative',overflowX:'hidden',background:'var(--pr-bg)', ...(vars as any) }}>\";
    if (!c.includes(openNew)) {
      if (!c.includes(openOld)) { console.error('❌ Test Series: opening anchor not found — aborting, no changes made'); process.exit(1); }
      c = c.replace(openOld, openNew);
    }

    const closeOld = \"    </div>\n  )\n}\";
    const closeNew = \"    </div>\n    </StudentShell>\n  )\n}\";
    const trimmed = c.replace(/\s+$/, '');
    const idx = trimmed.lastIndexOf(closeOld);
    if (idx === -1 || idx !== trimmed.length - closeOld.length) {
      console.error('❌ Test Series: closing anchor not found at end of file — aborting, no changes made');
      process.exit(1);
    }
    if (!trimmed.endsWith(closeNew)) {
      c = trimmed.slice(0, idx) + closeNew + '\n';
    }

    fs.writeFileSync(path, c);
    console.log('✅ Test Series page wrapped in StudentShell');
  "
fi

# ----------------------------------------------------------------------------
# SYNTAX VALIDATION
# ----------------------------------------------------------------------------
echo ""
echo "🔍 Validating syntax..."
if command -v tsc >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
  TSC_CMD="npx --yes typescript@latest tsc"
  command -v tsc >/dev/null 2>&1 && TSC_CMD="tsc"
  $TSC_CMD --noEmit --jsx preserve --target es2020 --module esnext --moduleResolution bundler --allowJs --skipLibCheck --esModuleInterop "$MB_PAGE" "$TS_PAGE" "$SHELL_FILE" > /tmp/shellwrap_tsc.txt 2>&1 || true
  ERRS=$(grep -E "error TS1[0-9]{3}:" /tmp/shellwrap_tsc.txt || true)
  if [ -n "$ERRS" ]; then
    echo "❌ SYNTAX ERRORS — restoring backups:"
    echo "$ERRS"
    [ -f "$MB_PAGE.pre-shellwrap-bak" ] && cp "$MB_PAGE.pre-shellwrap-bak" "$MB_PAGE"
    [ -f "$TS_PAGE.pre-shellwrap-bak" ] && cp "$TS_PAGE.pre-shellwrap-bak" "$TS_PAGE"
    exit 1
  else
    echo "  ✅ No parser/syntax errors"
  fi
else
  echo "  ⚠️  tsc not available — skipping automated check"
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "✅ DONE — both pages now render inside StudentShell"
echo "   (same sidebar, topbar, theme toggle, hi/en toggle as every other page)"
echo "═══════════════════════════════════════════════"
echo "⚠️  Restart your Next.js dev server to see changes."
echo "📦 Rollback: cp \"\$MB_PAGE.pre-shellwrap-bak\" \"\$MB_PAGE\" && cp \"\$TS_PAGE.pre-shellwrap-bak\" \"\$TS_PAGE\""
