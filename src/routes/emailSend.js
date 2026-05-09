const express = require('express')
const router = express.Router()
const https = require('https')
const { verifyToken, isAdmin } = require('../middleware/auth')

function sendViaBrevo(toArr, subject, htmlBody) {
  return new Promise((resolve, reject) => {
    const apiKey = process.env.BREVO_API_KEY || process.env.SENDINBLUE_API_KEY || ''
    if (!apiKey) return reject(new Error('BREVO_API_KEY missing in Render ENV'))
    const payload = JSON.stringify({
      sender: { name: 'ProveRank', email: process.env.BREVO_SENDER || 'radhakrishnan100806@gmail.com' },
      to: toArr,
      subject,
      htmlContent: htmlBody
    })
    const opts = {
      hostname: 'api.brevo.com', port: 443,
      path: '/v3/smtp/email', method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': apiKey,
        'Content-Length': Buffer.byteLength(payload)
      }
    }
    const req = https.request(opts, r => {
      let d = ''
      r.on('data', c => d += c)
      r.on('end', () => {
        if (r.statusCode >= 200 && r.statusCode < 300) resolve(JSON.parse(d))
        else reject(new Error(`Brevo ${r.statusCode}: ${d}`))
      })
    })
    req.on('error', reject)
    req.write(payload)
    req.end()
  })
}

// POST /api/admin/email/send
router.post('/send', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, body, testEmail } = req.body
    if (!subject || !body) return res.status(400).json({ error: 'Subject and body required' })
    const User = require('../models/User')
    let toArr = []
    if (testEmail) {
      toArr = [{ email: testEmail, name: 'Test' }]
    } else {
      const students = await User.find(
        { role: 'student', banned: { $ne: true } },
        { email: 1, name: 1 }
      ).lean()
      toArr = students.map(s => ({ email: s.email, name: s.name || 'Student' }))
    }
    if (!toArr.length) return res.status(400).json({ error: 'No recipients found' })
    let sent = 0, failed = 0, errs = []
    for (const r of toArr) {
      try {
        const html = body
          .replace(/{student_name}/g, r.name)
          .replace(/{date}/g, new Date().toLocaleDateString('en-IN'))
        await sendViaBrevo([{ email: r.email, name: r.name }], subject, html)
        sent++
      } catch(e) { failed++; errs.push(r.email + ': ' + e.message) }
    }
    res.json({ success: true, message: `Sent: ${sent}, Failed: ${failed}`, sent, failed, errors: errs.slice(0,3) })
  } catch(err) {
    console.error('emailSend error:', err)
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
