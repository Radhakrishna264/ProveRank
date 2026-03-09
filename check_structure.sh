#!/bin/bash
# Phase 7.4 ke liye structure check
echo "📁 Frontend app structure:"
find ~/workspace/frontend/app -type d | head -30
echo ""
echo "📋 Results folder exists?"
ls ~/workspace/frontend/app/dashboard/results 2>/dev/null || echo "results folder nahi hai"
echo ""
echo "📋 Dashboard structure:"
ls ~/workspace/frontend/app/dashboard/
