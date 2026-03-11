#!/bin/bash
# ProveRank — Global Mobile Responsive Fix (globals.css only)
set -e
G='\033[0;32m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'
log()  { echo -e "${G}[✓]${N} $1"; }
step() { echo -e "\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n${C}  $1${N}\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"; }

FE=~/workspace/frontend

step "Global Mobile CSS"
cat >> $FE/app/globals.css << 'CSSEOF'

/* ═══════════════════════════════════════════════════════════════
   PROVERANK — GLOBAL MOBILE RESPONSIVE FIXES
   Applies to ALL pages. Desktop untouched.
   ═══════════════════════════════════════════════════════════════ */

/* ── Base mobile resets ──────────────────────────────────────── */
@media (max-width: 768px) {

  /* Prevent horizontal scroll on all pages */
  html, body {
    overflow-x: hidden !important;
    max-width: 100vw !important;
  }

  /* All containers — full width, safe padding */
  main, section, div[style*="max-width"] {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }

  /* ── DASHBOARD: stat cards — 2 per row on mobile ── */
  /* Target the 4 big stat cards grid */
  div[style*="repeat(auto-fit, minmax(200px"] ,
  div[style*="repeat(auto-fit,minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 10px !important;
  }

  /* Mini 6-card info row — 2 per row */
  div[style*="repeat(auto-fit, minmax(180px"] ,
  div[style*="repeat(auto-fit,minmax(180px"] {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 10px !important;
  }

  /* Upcoming + Recent side-by-side — stack on mobile */
  div[style*="repeat(auto-fit, minmax(340px"] ,
  div[style*="repeat(auto-fit,minmax(340px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* Quick access — 3 per row on mobile */
  div[style*="repeat(auto-fit, minmax(110px"] ,
  div[style*="repeat(auto-fit,minmax(110px"] {
    grid-template-columns: repeat(3, 1fr) !important;
    gap: 8px !important;
  }

  /* ── DASHBOARD: header clock — shrink ── */
  /* Topbar padding reduce */
  header[style*="height:60"] ,
  header[style*="height: 60"] {
    padding: 0 12px !important;
  }

  /* ── LANDING PAGE ── */

  /* Hero section */
  section[style*="min-height:'100vh'"] ,
  section[style*="min-height: 100vh"] {
    padding: 80px 16px 40px !important;
    text-align: center !important;
  }

  /* Hero illustrations row — hide on very small, show smaller */
  div[style*="gap:48px"][style*="justify-content:'center'"] ,
  div[style*="gap: 48px"] svg {
    display: none !important;
  }

  /* Stats banner — 2 columns */
  div[style*="repeat(auto-fit, minmax(180px"] ,
  div[style*="repeat(auto-fit,minmax(180px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  /* Feature cards — 1 column */
  div[style*="repeat(auto-fit, minmax(300px"] ,
  div[style*="repeat(auto-fit,minmax(300px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* About section grid */
  div[style*="repeat(auto-fit, minmax(300px"] ,
  div[style*="repeat(auto-fit,minmax(300px"] {
    grid-template-columns: 1fr !important;
  }

  /* Footer grid */
  div[style*="repeat(auto-fit, minmax(220px"] ,
  div[style*="repeat(auto-fit,minmax(220px"] {
    grid-template-columns: 1fr !important;
    gap: 24px !important;
  }

  /* Nav links — hide text links on mobile (keep logo + buttons) */
  nav a.nav-link {
    display: none !important;
  }

  /* ── ALL PAGES: general table overflow ── */
  table {
    display: block !important;
    overflow-x: auto !important;
    white-space: nowrap !important;
    -webkit-overflow-scrolling: touch !important;
  }

  /* ── ANALYTICS PAGE ── */
  /* Subject performance grid */
  div[style*="repeat(auto-fit, minmax(260px"] ,
  div[style*="repeat(auto-fit,minmax(260px"] {
    grid-template-columns: 1fr !important;
  }

  /* Weak/Strong chapter cards — stack */
  div[style*="repeat(auto-fit, minmax(280px"] ,
  div[style*="repeat(auto-fit,minmax(280px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* ── CERTIFICATE PAGE ── */
  div[style*="repeat(auto-fit, minmax(280px"] ,
  div[style*="repeat(auto-fit,minmax(280px"] {
    grid-template-columns: 1fr !important;
  }

  /* Certificate preview body — stack QR + info */
  div[style*="gap:28px"][style*="flex-wrap:'wrap'"] ,
  div[style*="gap: 28px"] {
    flex-direction: column !important;
  }

  /* ── PROFILE PAGE ── */
  /* Profile header — stack on mobile */
  div[style*="repeat(auto-fit, minmax(260px"] ,
  div[style*="repeat(auto-fit,minmax(260px"] {
    grid-template-columns: 1fr !important;
    gap: 14px !important;
  }

  /* Profile header flex — column on mobile */
  div[style*="gap:24px"][style*="flexWrap:'wrap'"] {
    flex-direction: column !important;
    gap: 16px !important;
  }

  /* ── RESULTS PAGE ── */
  div[style*="repeat(auto-fit, minmax(180px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  /* Results row — wrap on mobile */
  div[style*="gap:16px"][style*="flexWrap:'wrap'"][style*="alignItems:'center'"] {
    flex-direction: column !important;
    align-items: flex-start !important;
    gap: 10px !important;
  }

  /* ── SUPPORT PAGE ── */
  /* Contact cards grid */
  div[style*="repeat(auto-fit, minmax(260px"] {
    grid-template-columns: 1fr !important;
  }

  /* Feedback type buttons — wrap */
  div[style*="gap:8px"][style*="flexWrap:'wrap'"] {
    gap: 6px !important;
  }

  /* ── ADMIN PAGE ── */
  /* Admin stat cards */
  div[style*="repeat(auto-fit, minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 10px !important;
  }

  /* Admin tables */
  div[style*="overflowX:'auto'"] {
    overflow-x: auto !important;
    -webkit-overflow-scrolling: touch !important;
  }

  /* ── LEADERBOARD: Podium — shrink on mobile ── */
  div[style*="gap:16px"][style*="alignItems:'flex-end'"] {
    gap: 8px !important;
  }

  /* ── 404 PAGE ── */
  div[style*="fontSize:300"] {
    font-size: 120px !important;
  }

  /* ── MAINTENANCE PAGE ── */
  div[style*="fontSize:80"] {
    font-size: 50px !important;
  }

  /* ── EXAM PAGE ── */
  /* Q palette — smaller on mobile */
  div[style*="repeat(auto-fill, minmax(36px"] ,
  div[style*="repeat(auto-fill,minmax(36px"] {
    grid-template-columns: repeat(auto-fill, minmax(30px, 1fr)) !important;
  }

}

/* ── Small phone (< 420px) extras ──────────────────────────── */
@media (max-width: 420px) {

  /* 4 stat cards — still 2 col but smaller padding */
  div[style*="repeat(auto-fit, minmax(200px"] ,
  div[style*="repeat(auto-fit,minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  /* Reduce main padding */
  main {
    padding: 16px 12px !important;
  }

  /* Font sizes */
  h1 { font-size: clamp(1.3rem, 6vw, 2rem) !important; }
  h2 { font-size: clamp(1.1rem, 5vw, 1.6rem) !important; }

  /* Quick access — 3 col */
  div[style*="repeat(auto-fit, minmax(110px"] ,
  div[style*="repeat(auto-fit,minmax(110px"] {
    grid-template-columns: repeat(3, 1fr) !important;
    gap: 6px !important;
  }

  /* Footer bottom row — column */
  div[style*="justifyContent:'space-between'"][style*="flexWrap:'wrap'"] {
    flex-direction: column !important;
    gap: 8px !important;
    align-items: flex-start !important;
  }

  /* Certificate preview padding */
  div[style*="padding:48px"] {
    padding: 24px 16px !important;
  }

  /* Admit card body padding */
  div[style*="padding:'28px'"] {
    padding: 16px !important;
  }

  /* Leaderboard table — hide some cols */
  td:last-child, th:last-child {
    display: none !important;
  }

}

/* ── Touch improvements ─────────────────────────────────────── */
@media (hover: none) and (pointer: coarse) {
  /* Make all buttons/links easier to tap */
  button, a {
    min-height: 40px !important;
    min-width: 40px !important;
  }

  /* Remove hover transforms that don't work on touch */
  .dash-card:hover,
  .feat-card:hover,
  .quick-btn:hover {
    transform: none !important;
  }

  /* Smooth scrolling */
  * {
    -webkit-tap-highlight-color: rgba(77,159,255,0.15) !important;
    scroll-behavior: smooth !important;
  }
}

/* ── Tablet (768px – 1024px) ────────────────────────────────── */
@media (min-width: 769px) and (max-width: 1024px) {

  /* 4 stat cards — 2x2 on tablet */
  div[style*="repeat(auto-fit, minmax(200px"] ,
  div[style*="repeat(auto-fit,minmax(200px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  /* Feature cards — 2 col on tablet */
  div[style*="repeat(auto-fit, minmax(300px"] ,
  div[style*="repeat(auto-fit,minmax(300px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  /* Footer — 2 col on tablet */
  div[style*="repeat(auto-fit, minmax(220px"] ,
  div[style*="repeat(auto-fit,minmax(220px"] {
    grid-template-columns: repeat(2, 1fr) !important;
  }

  main {
    padding: 20px 16px !important;
  }
}

/* ── Dashboard header: clock hide on very small ─────────────── */
@media (max-width: 480px) {
  /* Hide clock in center of topbar */
  header > div:nth-child(2) {
    display: none !important;
  }

  /* Reduce topbar height */
  header {
    height: 52px !important;
  }
}
CSSEOF
log "Global mobile CSS appended ✓"

step "GIT PUSH"
cd $FE
git add -A
git commit -m "Fix: Global mobile responsive CSS for all pages"
git push origin main

echo ""
echo -e "${G}╔══════════════════════════════════════════════════════╗"
echo -e "║  ✅ MOBILE RESPONSIVE FIX PUSHED!                    ║"
echo -e "║                                                      ║"
echo -e "║  ✓ Dashboard — 2-col stat cards on mobile            ║"
echo -e "║  ✓ Landing page — stacked layout on mobile           ║"
echo -e "║  ✓ Analytics — weak/strong cards stacked             ║"
echo -e "║  ✓ Certificate — preview stacked                     ║"
echo -e "║  ✓ Profile — header stacked                          ║"
echo -e "║  ✓ Results — cards wrap properly                     ║"
echo -e "║  ✓ Support — contact grid stacked                    ║"
echo -e "║  ✓ Admin — 2-col stat cards                          ║"
echo -e "║  ✓ Leaderboard — podium shrinks                      ║"
echo -e "║  ✓ Tables — horizontal scroll on mobile              ║"
echo -e "║  ✓ Touch — 40px min tap targets                      ║"
echo -e "║  ✓ Tablet (768-1024px) — medium layout               ║"
echo -e "║  ✓ Desktop — completely unchanged                    ║"
echo -e "╚══════════════════════════════════════════════════════╝${N}"
