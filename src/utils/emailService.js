const nodemailer = require('nodemailer')

const transporter = nodemailer.createTransport({
  service: 'gmail',
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
    html: `
      <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;background:#000A18;color:#E8F4FF;padding:32px;border-radius:12px;">
        <h2 style="color:#4D9FFF;">Welcome to ProveRank, ${toName}! ⚡</h2>
        <p>Please verify your email to activate your account.</p>
        <a href="${verifyUrl}" style="display:inline-block;background:#4D9FFF;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">Verify Email</a>
        <p style="color:#aaa;font-size:12px;">Link expires in 24 hours. If you did not register, ignore this email.</p>
      </div>
    `
  })
}

async function sendPasswordResetEmail(toEmail, toName, token) {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`
  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: toEmail,
    subject: 'Reset Your ProveRank Password',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:500px;margin:auto;background:#000A18;color:#E8F4FF;padding:32px;border-radius:12px;">
        <h2 style="color:#4D9FFF;">Password Reset Request ⚡</h2>
        <p>Hi ${toName}, click below to reset your password.</p>
        <a href="${resetUrl}" style="display:inline-block;background:#4D9FFF;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">Reset Password</a>
        <p style="color:#aaa;font-size:12px;">Link expires in 1 hour. If you did not request this, ignore this email.</p>
      </div>
    `
  })
}

module.exports = { sendVerificationEmail, sendPasswordResetEmail }
