#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank — UPLOAD FRONTEND FIX                           ║
# ║  Sirf page.tsx update hoga — Backend TOUCH NAHI HOGA       ║
# ║  Chalao: bash proverank_upload_frontend_fix.sh             ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log()  { echo -e "${G}[✓]${N} $1"; }
step() { echo -e "\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n  $1\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }
warn() { echo -e "${Y}[!]${N} $1"; }

PAGE=~/workspace/frontend/app/admin/x7k2p/page.tsx

step "Verify: page.tsx exists?"
if [ ! -f "$PAGE" ]; then
  echo -e "${R}[✗]${N} page.tsx nahi mila at: $PAGE"
  exit 1
fi
log "page.tsx found ✓"

# ──────────────────────────────────────────────────────────────
step "BUG 1 FIX — createExamStep1: fake local_ ID block karo"
# ──────────────────────────────────────────────────────────────
# Problem: Jab /api/exams call fail hoti hai, code silently
# fakeId = "local_TIMESTAMP" set karta hai aur step 2 pe aa jaata hai.
# Phir upload mein yahi fake ID backend ko jaati hai →
# MongoDB CastError → 500 → "Upload failed"
#
# Fix: Fake fallback HATAO — agar exam creation fail ho toh
# user ko clearly batao aur step 2 pe NAHI jaane do.

python3 << 'PYEOF'
with open('/root/workspace/frontend/app/admin/x7k2p/page.tsx', 'r') as f:
    code = f.read()

OLD = '''    }catch{
      const fakeId=`local_${Date.now()}`
      setCreatedExamId(fakeId)
      setExams(p=>[{_id:fakeId,attempts:0,...payload} as any,...p])
      setExamStep(2)
      showToast('Exam saved (pending sync)')
    }
  }'''

NEW = '''    }catch(e:any){
      // FIX: fake local_ ID se upload fail hota tha — ab retry karo
      const msg = e?.message||'Server error'
      showToast(`❌ Exam create failed: ${msg} — Retry karo`,'error')
      // Step 1 pe hi raho — fake ID se upload nahi hone denge
    }
  }'''

if OLD in code:
    code = code.replace(OLD, NEW)
    with open('/root/workspace/frontend/app/admin/x7k2p/page.tsx', 'w') as f:
        f.write(code)
    print('BUG 1 FIXED: fake local_ ID fallback removed')
else:
    print('WARNING: OLD pattern not found — already fixed or code different')
PYEOF

# ──────────────────────────────────────────────────────────────
step "BUG 2 FIX — Excel route: /api/excel/upload → /api/excel/questions"
# ──────────────────────────────────────────────────────────────
# Problem: Frontend POST /api/excel/upload karta hai
# Lekin backend excelUpload.js mein route hai: router.post('/questions', ...)
# Matlab actual endpoint hai: POST /api/excel/questions
# /api/excel/upload = 404 → "Upload failed"

python3 << 'PYEOF'
with open('/root/workspace/frontend/app/admin/x7k2p/page.tsx', 'r') as f:
    code = f.read()

OLD = "res = await fetch(`${API}/api/excel/upload`,{method:'POST', headers:{Authorization:`Bearer ${token}`}, body:fd})"
NEW = "res = await fetch(`${API}/api/excel/questions`,{method:'POST', headers:{Authorization:`Bearer ${token}`}, body:fd})"

if OLD in code:
    code = code.replace(OLD, NEW)
    with open('/root/workspace/frontend/app/admin/x7k2p/page.tsx', 'w') as f:
        f.write(code)
    print('BUG 2 FIXED: /api/excel/upload → /api/excel/questions')
else:
    print('WARNING: Excel route pattern not found — check manually')
PYEOF

# ──────────────────────────────────────────────────────────────
step "Verify both fixes applied"
# ──────────────────────────────────────────────────────────────
echo ""
echo "--- Checking Bug 1 fix (no more local_ fakeId) ---"
if grep -q "local_\${Date.now()}" "$PAGE"; then
  echo -e "${R}[✗]${N} Bug 1 still present!"
else
  log "Bug 1 fixed — no fake local_ ID ✓"
fi

echo ""
echo "--- Checking Bug 2 fix (correct Excel route) ---"
if grep -q "/api/excel/questions" "$PAGE"; then
  log "Bug 2 fixed — /api/excel/questions ✓"
elif grep -q "/api/excel/upload" "$PAGE"; then
  echo -e "${R}[✗]${N} Bug 2 still present — /api/excel/upload still there"
else
  warn "Excel route not found — check page.tsx manually"
fi

# ──────────────────────────────────────────────────────────────
step "Deploy — git push karo"
# ──────────────────────────────────────────────────────────────
echo ""
log "Fixes done! Ab ye commands chalao:"
echo ""
echo -e "  ${G}cd ~/workspace/frontend${N}"
echo -e "  ${G}git add app/admin/x7k2p/page.tsx${N}"
echo -e "  ${G}git commit -m 'fix: upload bug — remove fake examId + fix excel route'${N}"
echo -e "  ${G}git push${N}"
echo ""
warn "Vercel auto-deploy hoga — 1-2 min mein live"
echo ""
echo -e "${G}╔══════════════════════════════════════════════╗${N}"
echo -e "${G}║  ✅ FRONTEND FIX COMPLETE                   ║${N}"
echo -e "${G}╠══════════════════════════════════════════════╣${N}"
echo -e "${G}║  Fixed:                                      ║${N}"
echo -e "${G}║  1. Fake examId (local_TIMESTAMP) block kiya ║${N}"
echo -e "${G}║  2. Excel: /excel/upload→/excel/questions    ║${N}"
echo -e "${G}╠══════════════════════════════════════════════╣${N}"
echo -e "${G}║  Backend: ZERO changes — sab theek tha ✅    ║${N}"
echo -e "${G}╚══════════════════════════════════════════════╝${N}"
