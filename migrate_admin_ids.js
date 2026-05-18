require('dotenv').config()
const mongoose = require('mongoose')

const MONGO_URI = process.env.MONGO_URI
if(!MONGO_URI){ console.error('MONGO_URI not found'); process.exit(1) }

function generateAdminId(year){
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let xyz = ''
  for(let i=0;i<3;i++) xyz += chars[Math.floor(Math.random()*chars.length)]
  return 'PRA' + String(year).slice(-2) + xyz
}

async function migrate(){
  await mongoose.connect(MONGO_URI)
  console.log('✅ MongoDB connected — DB:', mongoose.connection.db.databaseName)
  const col = mongoose.connection.db.collection('students')

  const admins = await col.find({
    role: { $in: ['admin','superadmin'] },
    $or: [{ adminId: { $exists: false } }, { adminId: null }, { adminId: '' }]
  }).toArray()

  console.log(`Found ${admins.length} admins without adminId`)

  let updated = 0
  for(const a of admins){
    const year = a.createdAt ? new Date(a.createdAt).getFullYear() : 2025
    let adminId, isUnique = false, tries = 0
    while(!isUnique && tries < 30){
      adminId = generateAdminId(year)
      const exists = await col.findOne({ adminId })
      if(!exists) isUnique = true
      tries++
    }
    await col.updateOne({ _id: a._id }, { $set: { adminId } })
    console.log(`✅ ${a.email} (${a.role}) → ${adminId}`)
    updated++
  }
  console.log(`\nMigration done! ${updated} admins updated.`)
  await mongoose.disconnect()
}
migrate().catch(e => { console.error('Error:', e.message); process.exit(1) })
