#!/bin/bash
echo "====== BACKUP ALL STUDENT PAGES ======"
PAGES=(
  ~/workspace/frontend/app/dashboard/page.tsx
  ~/workspace/frontend/app/results/page.tsx
  ~/workspace/frontend/app/profile/page.tsx
  ~/workspace/frontend/app/pyq-bank/page.tsx
  ~/workspace/frontend/app/my-exams/page.tsx
  ~/workspace/frontend/app/certificate/page.tsx
  ~/workspace/frontend/app/attempt-history/page.tsx
  ~/workspace/frontend/app/analytics/page.tsx
  ~/workspace/frontend/app/leaderboard/page.tsx
  ~/workspace/frontend/app/announcements/page.tsx
  ~/workspace/frontend/app/revision/page.tsx
  ~/workspace/frontend/app/goals/page.tsx
  ~/workspace/frontend/app/compare/page.tsx
  ~/workspace/frontend/app/doubt/page.tsx
  ~/workspace/frontend/app/parent-portal/page.tsx
  ~/workspace/frontend/app/admit-card/page.tsx
  ~/workspace/frontend/app/mini-tests/page.tsx
  ~/workspace/frontend/app/support/page.tsx
  ~/workspace/frontend/app/omr-view/page.tsx
  ~/workspace/frontend/src/components/StudentShell.tsx
)

for f in "${PAGES[@]}"; do
  [ -f "$f" ] && cp "$f" "${f}.bak_padding2" && echo "Backed up: $f"
done

echo ""
echo "====== FIXING STUDENTSHELL — CHILDREN WRAPPER ======"
SHELL=~/workspace/frontend/src/components/StudentShell.tsx

# Fix 1: Children content wrapper — remove any side padding, ensure full width
sed -i "s/padding:'0 0 56px',maxWidth:1100,margin:'0 auto'/padding:'0 0 56px',width:'100%'/g" "$SHELL"
echo "StudentShell children wrapper fixed"

echo ""
echo "====== FIXING EACH PAGE — OUTER CONTAINER HORIZONTAL PADDING ======"

# Fix common padding patterns in outer containers — reduce horizontal padding to 4px
# Pattern: padding:'Xpx Ypx' where Y is 12px or more → reduce Y to 4px
# Pattern: padding:'Xpx' (all sides equal, 16px+) → keep vertical, reduce horizontal

for f in "${PAGES[@]}"; do
  [ ! -f "$f" ] && continue
  
  # Fix: padding:'24px 20px' → padding:'24px 4px'
  sed -i "s/padding:'24px 20px'/padding:'24px 4px'/g" "$f"
  # Fix: padding:'24px 22px' → padding:'24px 4px'
  sed -i "s/padding:'24px 22px'/padding:'24px 4px'/g" "$f"
  # Fix: padding:'20px 16px' → padding:'20px 4px'
  sed -i "s/padding:'20px 16px'/padding:'20px 4px'/g" "$f"
  # Fix: padding:'18px 16px' → padding:'18px 4px'
  sed -i "s/padding:'18px 16px'/padding:'18px 4px'/g" "$f"
  # Fix: padding:'16px 16px' → padding:'16px 4px'
  sed -i "s/padding:'16px 16px'/padding:'16px 4px'/g" "$f"
  # Fix: padding:'20px 18px' → padding:'20px 4px'
  sed -i "s/padding:'20px 18px'/padding:'20px 4px'/g" "$f"
  # Fix: padding:'16px 14px' → padding:'16px 4px'
  sed -i "s/padding:'16px 14px'/padding:'16px 4px'/g" "$f"

  echo "Fixed: $f"
done

echo ""
echo "====== FIXING DASHLAYOUT — ZERO HORIZONTAL PADDING ======"
LAYOUT=~/workspace/frontend/components/DashLayout.tsx
sed -i "s/padding:'20px 6px',animation:'fadeIn/padding:'20px 0px',animation:'fadeIn/g" "$LAYOUT"
echo "DashLayout fixed: padding → 20px 0px"

echo ""
echo "====== VERIFY CHANGES ======"
grep -rn "padding:'24px 4px'\|padding:'20px 4px'\|padding:'18px 4px'\|padding:'0 0 56px',width:'100%'" ~/workspace/frontend/app/ ~/workspace/frontend/src/components/StudentShell.tsx 2>/dev/null | head -20

echo ""
echo "====== BUILD ======"
cd ~/workspace/frontend && npm run build

if [ $? -eq 0 ]; then
  cd ~/workspace
  git add -A
  git commit -m "fix: remove horizontal padding from all student pages for full-width mobile cards"
  git push origin main
  echo "====== DEPLOYED ======"
else
  echo "====== BUILD FAILED ======"
fi
