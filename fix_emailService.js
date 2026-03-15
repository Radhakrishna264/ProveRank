/**
 * ProveRank — emailService.js (Brevo API — WORKING config)
 * Run: node fix_emailService.js  (from /home/runner/workspace)
 */
const fs = require('fs')
const filePath = '/home/runner/workspace/src/utils/emailService.js'

const code = `const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args))

// Brevo API — WORKING (confirmed)
const BREVO_API  = 'https://api.brevo.com/v3/smtp/email'
const SENDER_EMAIL = 'radhakrishnan100806@gmail.com'
const SENDER_NAME  = 'ProveRank'

/**
 * sendVerificationEmail
 * type: 'verify' | 'login' | 'reset'
 * otp:  6-digit string (null for old link-based)
 */
async function sendVerificationEmail(toEmail, toName, linkToken = null, otp = null, type = 'verify') {

  const subjects = {
    verify : '✅ ProveRank — Email Verification OTP',
    login  : '🔐 ProveRank — Your Login OTP',
    reset  : '🔑 ProveRank — Password Reset OTP'
  }
  const headings = {
    verify : 'Verify Your Email',
    login  : 'Login OTP',
    reset  : 'Reset Your Password'
  }
  const messages = {
    verify : 'Enter this OTP to verify your email and activate your ProveRank account.',
    login  : 'Enter this OTP to log in to your ProveRank account.',
    reset  : 'Enter this OTP to reset your ProveRank password.'
  }

  const subject = subjects[type] || subjects.verify
  const heading = headings[type] || headings.verify
  const message = messages[type] || messages.verify

  // OTP email HTML
  const htmlContent = \`
<!DOCTYPE html>
<html>
<head><meta charset="utf-8">
<style>
  body{margin:0;padding:0;font-family:Arial,sans-serif;background:#f0f4ff}
  .wrap{max-width:520px;margin:32px auto;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.10)}
  .header{background:linear-gradient(135deg,#001628,#0055CC);padding:32px 28px;text-align:center}
  .logo{font-size:28px;font-weight:900;color:#4D9FFF;letter-spacing:1px}
  .logo span{color:#fff}
  .body{padding:32px 28px}
  h2{color:#1F3864;margin:0 0 12px;font-size:20px}
  p{color:#444;font-size:15px;line-height:1.6;margin:0 0 16px}
  .otp-box{background:linear-gradient(135deg,#001628,#003366);border-radius:12px;padding:22px;text-align:center;margin:22px 0}
  .otp{font-size:44px;font-weight:900;color:#4D9FFF;letter-spacing:12px;font-family:monospace}
  .expires{color:#aaa;font-size:13px;margin-top:8px}
  .note{background:#FFF9E6;border-left:4px solid #FFB300;padding:12px 16px;border-radius:6px;font-size:13px;color:#7B4F00;margin-top:16px}
  .footer{background:#f5f7ff;padding:18px 28px;text-align:center;font-size:12px;color:#888}
  .footer a{color:#4D9FFF;text-decoration:none}
</style>
</head>
<body>
<div class="wrap">
  <div class="header">
    <div class="logo">Prove<span>Rank</span></div>
    <div style="color:#B8C8D8;font-size:13px;margin-top:6px">NEET 2026 Preparation Platform</div>
  </div>
  <div class="body">
    <h2>Hi \${toName || 'Student'}! 👋</h2>
    <p>\${message}</p>
    <div class="otp-box">
      <div class="otp">\${otp}</div>
      <div class="expires">⏱️ Valid for 10 minutes only</div>
    </div>
    <p>Enter this OTP on the ProveRank platform to continue.</p>
    <div class="note">
      ⚠️ <strong>Do not share this OTP</strong> with anyone.<br>
      ProveRank will never ask for your OTP via call or chat.
    </div>
  </div>
  <div class="footer">
    <p>ProveRank · NEET 2026 Preparation</p>
    <p><a href="https://prove-rank.vercel.app">prove-rank.vercel.app</a> · <a href="mailto:ProveRank.support@gmail.com">ProveRank.support@gmail.com</a></p>
  </div>
</div>
</body>
</html>
\`

  try {
    const res = await fetch(BREVO_API, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': process.env.BREVO_API_KEY
      },
      body: JSON.stringify({
        sender  : { name: SENDER_NAME, email: SENDER_EMAIL },
        to      : [{ email: toEmail, name: toName || 'Student' }],
        subject,
        htmlContent
      })
    })

    if (res.ok) {
      console.log('✅ Email sent via Brevo:', toEmail, '| type:', type)
    } else {
      const err = await res.text()
      console.error('❌ Brevo error:', res.status, err)
    }
  } catch (err) {
    console.error('❌ Email send failed:', err.message)
    // Don't throw — never block registration/login flow
  }
}

module.exports = { sendVerificationEmail }
`

fs.writeFileSync(filePath, code, 'utf8')
console.log('✅ emailService.js updated with Brevo API!')
console.log('')
console.log('📋 Uses: https://api.brevo.com/v3/smtp/email')
console.log('📋 Sender: radhakrishnan100806@gmail.com')
console.log('📋 Env var needed: BREVO_API_KEY (already set on Render)')
console.log('')
console.log('✅ Supports types: verify | login | reset')
