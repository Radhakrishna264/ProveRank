#!/bin/bash
set -e

cd ~/workspace/frontend

echo "--- Step 1: Create local .npmrc with real npm registry ---"
cat > .npmrc << 'NPMRC'
registry=https://registry.npmjs.org/
NPMRC

echo "--- Step 2: Remove old lock file + node_modules (they reference replit.local) ---"
rm -rf node_modules
rm -f package-lock.json

echo "--- Step 3: Reinstall using real registry (regenerates clean lock file) ---"
npm install --registry=https://registry.npmjs.org/

echo "--- Step 4: Verify no replit.local references remain ---"
if grep -q "replit.local" package-lock.json; then
  echo "❌ STILL FOUND replit.local in package-lock.json — manual check needed"
else
  echo "✅ package-lock.json is clean — no replit.local references"
fi

echo "--- Step 5: Git add, commit, push ---"
cd ~/workspace
git add frontend/.npmrc frontend/package-lock.json
git commit -m "Fix: regenerate frontend package-lock.json with public npm registry (fixes Vercel ENOTFOUND build failure)"
git push origin main

echo "--- DONE: Push complete. Trigger Vercel redeploy now. ---"
