#!/bin/bash
echo "=== start-attempt handler exact code ==="
grep -n "" ~/workspace/src/routes/exam.js | sed -n '60,90p'
echo ""
echo "=== Server log errors ==="
cat /tmp/server.log | grep -iE "error|crash|cannot|undefined" | tail -20
