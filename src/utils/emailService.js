const nodemailer = require('nodemailer')

const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_EMAIL,
    pass: process.env.SMTP_PASS
  }
})

async function sendVerificationEmail(toEmail, toName, token) {
  const verifyUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`
  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: toEmail,
    subject: 'Verify Your ProveRank Account',
    html: `<div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;background:#000A18;color:#E8F4FF;padding:32px;border-radius:12px;"><h2 style="color:#4D9FFF;">Welcome to ProveRank, ${toName}! ⚡</h2><p>Please verify your email to activate your account.</p><a href="${verifyUrl}" style="display:inline-block;background:#4D9FFF;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">Verify Email</a><p style="color:#aaa;font-size:12px;">Link expires in 24 hours.</p></div>`
  })
}

module.exports = { sendVerificationEmail }
