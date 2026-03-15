// ProveRank emailService — Brevo API (confirmed working)
const nodeFetch = typeof fetch !== 'undefined' ? fetch
  : (...args) => import('node-fetch').then(({default:f})=>f(...args))

const BREVO_API    = 'https://api.brevo.com/v3/smtp/email'
const SENDER_EMAIL = 'radhakrishnan100806@gmail.com'
const SENDER_NAME  = 'ProveRank'

async function sendVerificationEmail(toEmail, toName, linkToken=null, otp=null, type='verify') {
  const cfg = {
    verify: { subject:'✅ ProveRank — Email Verification OTP',
              heading:'Verify Your Email',
              msg:'Enter this OTP to verify your email and activate your ProveRank account.' },
    login : { subject:'🔐 ProveRank — Your Login OTP',
              heading:'Login OTP',
              msg:'Enter this OTP to log in to your ProveRank account.' },
    reset : { subject:'🔑 ProveRank — Password Reset OTP',
              heading:'Reset Password OTP',
              msg:'Enter this OTP to reset your ProveRank password.' }
  }
  const c = cfg[type] || cfg.verify

  const html = `
<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
body{margin:0;padding:0;font-family:Arial,sans-serif;background:#f0f4ff}
.wrap{max-width:520px;margin:32px auto;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.10)}
.hdr{background:linear-gradient(135deg,#001628,#0055CC);padding:30px 28px;text-align:center}
.logo{font-size:26px;font-weight:900;color:#4D9FFF}.logo span{color:#fff}
.bdy{padding:30px 28px}
h2{color:#1F3864;margin:0 0 10px;font-size:19px}
p{color:#444;font-size:15px;line-height:1.6;margin:0 0 14px}
.obox{background:linear-gradient(135deg,#001628,#003366);border-radius:12px;padding:22px;text-align:center;margin:20px 0}
.otp{font-size:42px;font-weight:900;color:#4D9FFF;letter-spacing:12px;font-family:monospace}
.exp{color:#aaa;font-size:13px;margin-top:8px}
.note{background:#FFF9E6;border-left:4px solid #FFB300;padding:11px 14px;border-radius:6px;font-size:13px;color:#7B4F00;margin-top:14px}
.ftr{background:#f5f7ff;padding:16px 28px;text-align:center;font-size:12px;color:#888}
.ftr a{color:#4D9FFF;text-decoration:none}
</style></head><body>
<div class="wrap">
<div class="hdr"><div class="logo">Prove<span>Rank</span></div>
<div style="color:#B8C8D8;font-size:12px;margin-top:5px">NEET 2026 Preparation</div></div>
<div class="bdy">
<h2>Hi ${toName||'Student'}! 👋</h2>
<p>${c.msg}</p>
<div class="obox"><div class="otp">${otp}</div><div class="exp">⏱️ Valid for 10 minutes</div></div>
<p>Enter this OTP on ProveRank to continue.</p>
<div class="note">⚠️ <strong>Do not share this OTP</strong> with anyone. ProveRank never asks for OTP via call or message.</div>
</div>
<div class="ftr">
<p>ProveRank · <a href="https://prove-rank.vercel.app">prove-rank.vercel.app</a></p>
<p><a href="mailto:ProveRank.support@gmail.com">ProveRank.support@gmail.com</a></p>
</div></div></body></html>`

  try {
    const res = await nodeFetch(BREVO_API, {
      method:'POST',
      headers:{ 'Content-Type':'application/json', 'api-key': process.env.BREVO_API_KEY },
      body: JSON.stringify({
        sender: { name: SENDER_NAME, email: SENDER_EMAIL },
        to: [{ email: toEmail, name: toName||'Student' }],
        subject: c.subject,
        htmlContent: html
      })
    })
    if (res.ok) { console.log(`✅ OTP email [${type}] sent to ${toEmail}`) }
    else { const e=await res.text(); console.error(`❌ Brevo error ${res.status}:`, e) }
  } catch(err) {
    console.error('❌ Email failed:', err.message)
  }
}

module.exports = { sendVerificationEmail }
