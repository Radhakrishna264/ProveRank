#!/bin/bash
G='\033[0;32m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }

# Step 1: Check current email import in adminSystem.js
echo "=== Current email import ==="
grep -n "emailService\|nodemailer\|require.*email\|require.*otp" ~/workspace/src/routes/adminSystem.js | head -10

# Step 2: Check otp.js transporter pattern
echo "=== otp.js transporter ==="
grep -n "createTransport\|EMAIL_USER\|transporter" ~/workspace/src/routes/otp.js | head -10
