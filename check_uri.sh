#!/bin/bash
WS=~/workspace

echo "=== .env file MONGO_URI ==="
grep MONGO_URI $WS/.env

echo ""
echo "=== src/config/db.js ==="
cat $WS/src/config/db.js

echo ""
echo "=== src/index.js MONGO connection lines ==="
grep -n "MONGO\|mongoose.connect\|dotenv\|config" $WS/src/index.js | head -20

echo ""
echo "=== .env file full ==="
cat $WS/.env | grep -v "SECRET\|KEY\|PASS" 
