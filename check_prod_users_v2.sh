#!/bin/bash
node << 'EOF'
const https = require('https')

function req(opts, body) {
  return new Promise((res, rej) => {
    const r = https.request(opts, resp => {
      let d = ''
      resp.on('data', c => d += c)
      resp.on('end', () => res(d))
    })
    r.on('error', rej)
    if (body) r.write(body)
    r.end()
  })
}

async function main() {
  // Step 1: Login
  const loginBody = JSON.stringify({ email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' })
  const loginResp = await req({
    hostname: 'proverank.onrender.com',
    path: '/api/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Content-Length': loginBody.length }
  }, loginBody)

  const token = JSON.parse(loginResp).token
  if (!token) { console.log('Login failed:', loginResp); return }
  console.log('Login OK')

  // Step 2: Fetch students
  const stuResp = await req({
    hostname: 'proverank.onrender.com',
    path: '/api/admin/students',
    headers: { Authorization: 'Bearer ' + token }
  })

  try {
    const data = JSON.parse(stuResp)
    const list = Array.isArray(data) ? data : (data.students || data.data || [])
    console.log('\n=== PRODUCTION DB STUDENTS:', list.length, '===')
    list.forEach((u, i) => console.log('[' + (i+1) + '] ' + u.email + ' | ' + (u.name||'?') + ' | verified: ' + (u.emailVerified||u.verified||false)))
  } catch(e) {
    console.log('Response:', stuResp.substring(0, 500))
  }
}

main().catch(console.error)
EOF
