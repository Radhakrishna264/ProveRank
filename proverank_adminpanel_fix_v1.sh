#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ProveRank — Admin Panel Complete Fix                              ║
# ║  SuperAdmin panel ka poora code Admin Panel mein copy karo        ║
# ║  Sirf redirect line hatao — baaki sab same                        ║
# ║  Rule C1: grep/pipe only | Rule C2: NO sed -i | NO Python         ║
# ╚══════════════════════════════════════════════════════════════════════╝
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
step(){ echo -e "\n${B}══════ $1 ══════${N}"; }
warn(){ echo -e "${Y}[NOTE]${N} $1"; }
err(){ echo -e "${R}[ERR]${N} $1"; exit 1; }

FE=~/workspace/frontend
SUPERADMIN_FILE="$FE/app/admin/x7k2p/page.tsx"
ADMIN_DIR="$FE/app/admin/x7k2p/admin-panel"
ADMIN_FILE="$ADMIN_DIR/page.tsx"

step "Step 1 — Verify SuperAdmin panel file exists"
if [ ! -f "$SUPERADMIN_FILE" ]; then
  err "SuperAdmin panel file not found at: $SUPERADMIN_FILE"
fi
LINES=$(wc -l < "$SUPERADMIN_FILE")
log "SuperAdmin panel found — $LINES lines"

step "Step 2 — Create admin-panel directory"
mkdir -p "$ADMIN_DIR"
log "Directory created: $ADMIN_DIR"

step "Step 3 — Copy SuperAdmin panel → Admin Panel (minus redirect line)"
# SuperAdmin mein ek redirect line hai jo admin users ko kick karta tha:
# useEffect(()=>{const r=localStorage...if(r&&r!=='superadmin'){window.location.href='/admin/x7k2p/admin-panel'
# Ye line grep -v se remove karke naya file banao

grep -v "window.location.href='/admin/x7k2p/admin-panel'" \
  "$SUPERADMIN_FILE" \
  > "$ADMIN_FILE"

NEW_LINES=$(wc -l < "$ADMIN_FILE")
log "Admin panel file written — $NEW_LINES lines"

# Verify the redirect line is gone
if grep -q "window.location.href='/admin/x7k2p/admin-panel'" "$ADMIN_FILE"; then
  err "Redirect line still present! Check manually."
else
  log "Redirect line successfully removed"
fi

step "Step 4 — Verify key features present in new Admin Panel"

# Check filteredNAV logic present (permission-based nav)
if grep -q "filteredNAV" "$ADMIN_FILE"; then
  log "filteredNAV (permission-based nav) — Present ✅"
else
  warn "filteredNAV not found — check file"
fi

# Check adminOwnPerms present
if grep -q "adminOwnPerms" "$ADMIN_FILE"; then
  log "adminOwnPerms (admin permission fetch) — Present ✅"
else
  warn "adminOwnPerms not found — check file"
fi

# Check ADMIN_HIDDEN list
if grep -q "ADMIN_HIDDEN" "$ADMIN_FILE"; then
  log "ADMIN_HIDDEN (superadmin-only tabs hidden from admin) — Present ✅"
else
  warn "ADMIN_HIDDEN not found — check file"
fi

# Check StatBox component
if grep -q "function StatBox" "$ADMIN_FILE"; then
  log "StatBox component — Present ✅"
else
  warn "StatBox not found — check file"
fi

# Check PageHero component
if grep -q "function PageHero" "$ADMIN_FILE"; then
  log "PageHero component — Present ✅"
else
  warn "PageHero not found — check file"
fi

# Check Galaxy BG
if grep -q "function GalaxyBg" "$ADMIN_FILE"; then
  log "GalaxyBg (Live Galaxy Background) — Present ✅"
else
  warn "GalaxyBg not found — check file"
fi

# Check science SVGs
if grep -q "DNA Structure" "$ADMIN_FILE"; then
  log "Science SVG Illustrations — Present ✅"
else
  warn "Science SVGs not found — check file"
fi

# Check both roles allowed
if grep -q "'admin','superadmin'" "$ADMIN_FILE"; then
  log "Both admin + superadmin roles allowed — Present ✅"
else
  warn "Role check not found — check file"
fi

# Check role-based nav display
if grep -q "role==='superadmin'?NAV" "$ADMIN_FILE"; then
  log "Role-based nav filtering — Present ✅"
else
  warn "Role-based nav not found — check file"
fi

step "Step 5 — Show file size comparison"
echo ""
echo -e "  ${B}SuperAdmin panel:${N} $LINES lines"
echo -e "  ${G}Admin panel (new):${N} $NEW_LINES lines"
echo -e "  ${Y}Difference:${N} $((LINES - NEW_LINES)) lines removed (just the redirect)"
echo ""

step "Step 6 — Summary: What Admin Panel now has"
echo ""
echo "  ✅ SAME as SuperAdmin:"
echo "     → N6 Neon Blue Arctic Theme (exact match)"
echo "     → Live Galaxy + Particles Background"
echo "     → PR4 Split Block Logo (Blue+Cyan)"
echo "     → StatBox, PageHero, GlobalSearch, Badge components"
echo "     → Science SVG Illustrations (DNA, Atom, Cell, etc.)"
echo "     → All tab content: Exams, Questions, Students, Results, etc."
echo "     → 3-Step Exam Create Wizard"
echo "     → AI Smart Generator, PYQ Bank"
echo "     → Branding, Feature Flags"
echo "     → Audit Logs, Reports & Export"
echo "     → Announcements, Email Templates"
echo ""
echo "  ✅ DIFFERENT from SuperAdmin (permission-based):"
echo "     → Admin sees only permitted tabs (based on SuperAdmin permissions)"
echo "     → ADMIN_HIDDEN tabs not shown: admins, permissions, maintenance, etc."
echo "     → Header shows: ProveRank ⚡ ADMIN (not SUPERADMIN)"
echo "     → No access to Admin Management, Permissions Control"
echo ""
echo "  ✅ PERMISSION MAPPING:"
echo "     → create_exam → Exams, Create Exam, Templates, Bulk Creator"
echo "     → manage_questions → Question Bank, Smart Gen, PYQ Bank"
echo "     → ban_student → Students, Batches"
echo "     → view_results → Results, Leaderboard, Analytics"
echo "     → export_data → Reports, QB Stats"
echo "     → send_announcements → Announcements, Email Templates"
echo "     → view_audit_logs → Audit Logs"
echo "     → view_snapshots → Cheating Logs, Snapshots, AI Integrity"
echo ""

step "Step 7 — Git push karo (optional, manual)"
echo ""
echo -e "  ${Y}Agar git push karna ho:${N}"
echo "  cd ~/workspace"
echo "  git add frontend/app/admin/x7k2p/admin-panel/page.tsx"
echo "  git commit -m 'fix: Admin panel - full SuperAdmin theme & content copied, permission-based nav'"
echo "  git push"
echo ""

echo -e "${G}════════════════════════════════════════════${N}"
echo -e "${G}  Admin Panel Fix COMPLETE! ✅              ${N}"
echo -e "${G}  Test: prove-rank.vercel.app/admin/x7k2p   ${N}"
echo -e "${G}  Login as sub-admin to verify permissions  ${N}"
echo -e "${G}════════════════════════════════════════════${N}"
