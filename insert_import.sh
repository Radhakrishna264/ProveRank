#!/bin/bash
set -e
cd ~/workspace
FILE=frontend/app/admin/x7k2p/page.tsx

echo "── File first line ──"
head -1 $FILE

echo ""
echo "── Adding import at line 2 ──"
# Use sed to insert import after line 1 ('use client')
# First check if already there
if grep -q "StoreAdminTab" $FILE; then
  echo "StoreAdminTab already in file at:"
  grep -n "StoreAdminTab" $FILE | head -5
else
  # Insert import at line 2 using sed
  sed -i "2i import StoreAdminTab from './StoreAdminTab';" $FILE
  echo "✅ Import inserted at line 2"
fi

echo ""
echo "── Verify (first 6 lines) ──"
head -6 $FILE

echo ""
echo "── Git add + commit + push ──"
git add $FILE
git diff --staged --stat
git commit -m "fix: insert StoreAdminTab import at line 2 of admin page.tsx"
git push origin main
echo "✅ Done!"
