async function sendVerificationEmail(toEmail, toName, token) {
  const verifyUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'api-key': process.env.BREVO_API_KEY
    },
    body: JSON.stringify({
      sender: { name: 'ProveRank', email: 'radhakrishnan100806@gmail.com' },
      to: [{ email: toEmail, name: toName }],
      subject: 'Verify Your ProveRank Account',
      htmlContent: `<div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;background:#000A18;color:#E8F4FF;padding:36px;border-radius:14px;border:1px solid #1A3A5C"><h2 style="color:#4D9FFF;">Welcome to ProveRank, ${toName}! ⚡</h2><p style="color:#aaa;">Please verify your email to activate your account.</p><a href="${verifyUrl}" style="display:inline-block;background:#4D9FFF;color:#fff;padding:13px 32px;border-radius:8px;text-decoration:none;font-weight:bold;">Verify Email</a><p style="color:#666;font-size:12px;margin-top:24px;">Link expires in 24 hours.</p></div>`
    })
  })
  const data = await res.json()
  if (!res.ok) throw new Error(`Brevo API error: ${JSON.stringify(data)}`)
  console.log('Email sent to', toEmail)
}

module.exports = { sendVerificationEmail }
