const fs = require('fs');
const filePath = require('path').join(process.env.HOME, 'workspace/src/routes/auth.js');
let c = fs.readFileSync(filePath, 'utf8');

const OLD = `    history.push({ at: new Date(), ip: req.ip,
      device: (req.headers['user-agent'] || 'Web').substring(0, 60) })
    await User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } })`;

const NEW = `    const rawUA = req.headers['user-agent'] || ''
    const realIp = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.ip || 'Unknown'
    let browser = 'Unknown'
    if (rawUA.includes('Edg/')) browser = 'Edge'
    else if (rawUA.includes('OPR/') || rawUA.includes('Opera')) browser = 'Opera'
    else if (rawUA.includes('Chrome') && !rawUA.includes('Chromium')) browser = 'Chrome'
    else if (rawUA.includes('Firefox')) browser = 'Firefox'
    else if (rawUA.includes('Safari') && !rawUA.includes('Chrome')) browser = 'Safari'
    let os = 'Unknown'
    if (rawUA.includes('Android')) os = 'Android'
    else if (rawUA.includes('iPhone') || rawUA.includes('iPad')) os = 'iOS'
    else if (rawUA.includes('Windows NT')) os = 'Windows'
    else if (rawUA.includes('Mac OS X')) os = 'macOS'
    else if (rawUA.includes('Linux')) os = 'Linux'
    let city = 'Unknown', country = 'Unknown'
    try {
      const geoRes = await fetch(\`http://ip-api.com/json/\${realIp}?fields=city,country,status\`)
      const geo = await geoRes.json()
      if (geo.status === 'success') { city = geo.city || 'Unknown'; country = geo.country || 'Unknown' }
    } catch(e) {}
    history.push({ at: new Date(), ip: realIp, browser, os, city, country, device: \`\${browser} on \${os}\` })
    await User.collection.updateOne({ _id: user._id },
      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } })`;

if (c.includes(OLD)) {
  fs.writeFileSync(filePath, c.replace(OLD, NEW));
  console.log('✅ loginHistory fix applied');
} else {
  console.log('❌ Pattern not found');
  const lines = c.split('\n');
  const i = lines.findIndex(l => l.includes('history.push'));
  console.log(lines.slice(i-1, i+4).join('\n'));
}
