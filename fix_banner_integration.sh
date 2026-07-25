#!/bin/bash
set -e
cd ~/workspace

cp src/routes/studentBatches.js src/routes/studentBatches.js.bak_banner_fix
cp frontend/app/dashboard/test-series/page.tsx frontend/app/dashboard/test-series/page.tsx.bak_banner_fix

# ── Backend patch pieces ──
cat > /tmp/p1_old.txt << 'EOF'
const TestSeries=require('../models/TestSeries');
EOF

cat > /tmp/p1_new.txt << 'EOF'
const TestSeries=require('../models/TestSeries');
const Banner=require('../models/Banner');
EOF

cat > /tmp/p2_old.txt << 'EOF'
    let batches=await Batch.find(filter).sort(sortObj).lean();
    let series=await TestSeries.find(seriesFilter).sort(sortObj).lean();
    series=series.map(normalizeSeries);
    batches=batches.concat(series);
EOF

cat > /tmp/p2_new.txt << 'EOF'
    let batches=await Batch.find(filter).sort(sortObj).lean();
    let series=await TestSeries.find(seriesFilter).sort(sortObj).lean();
    series=series.map(normalizeSeries);
    batches=batches.concat(series);

    // ── Attach latest linked Banner (Creative Studio design) to each card ──
    const bannerIds=batches.map(x=>x._id);
    const banners=await Banner.find({ linkedBatchId:{ $in:bannerIds }, status:{ $nin:['removed','replaced'] } }).sort({ createdAt:-1 }).lean();
    const bannerMap={};
    banners.forEach(bn=>{ const key=String(bn.linkedBatchId); if(!bannerMap[key])bannerMap[key]=bn; });
EOF

cat > /tmp/p3_old.txt << 'EOF'
    const result=batches.map(b=>{
      const eff=effectivePrice(b);
      const watched=priceWatchMap[b._id.toString()];
      return{
        ...b,
        isEnrolled:enrolledIds.includes(b._id.toString()),
        isWishlisted:wishlistIds.includes(b._id.toString()),
        effectivePrice:eff,
        discountPct:discountPct(b),
        fitScore:computeFitScore(b,user),
        isPriceWatched:watched!==undefined,
        priceDropped:watched!==undefined&&eff<watched
      };
    });
EOF

cat > /tmp/p3_new.txt << 'EOF'
    const result=batches.map(b=>{
      const eff=effectivePrice(b);
      const watched=priceWatchMap[b._id.toString()];
      return{
        ...b,
        banner:bannerMap[b._id.toString()]||null,
        isEnrolled:enrolledIds.includes(b._id.toString()),
        isWishlisted:wishlistIds.includes(b._id.toString()),
        effectivePrice:eff,
        discountPct:discountPct(b),
        fitScore:computeFitScore(b,user),
        isPriceWatched:watched!==undefined,
        priceDropped:watched!==undefined&&eff<watched
      };
    });
EOF

# ── Frontend patch pieces ──
cat > /tmp/p4_old.txt << 'EOF'
// ── BATCH CARD ──
function BatchCard({ b, tok, onUpdate, compareList, toggleCompare, onBuy, onReview, onPreview, showPriceWatch }: {
EOF

cat > /tmp/p4_new.txt << 'EOF'
// ── Banner Live Design constants (mirrors admin Creative Studio) ──
const BN_TEMPLATES = [
  { id: 'classic', label: 'Classic Premium', category: 'Featured', bg: 'linear-gradient(135deg,#0a0a1a,#1a1a3e)', accent: '#FFD700' },
  { id: 'glass', label: 'Glassmorphism', category: 'Premium', bg: 'linear-gradient(135deg,rgba(77,159,255,0.25),rgba(155,89,182,0.25))', accent: '#4D9FFF' },
  { id: 'minimal', label: 'Minimal Clean', category: 'Featured', bg: 'linear-gradient(135deg,#f8f9fa,#e9ecef)', accent: '#1a237e' },
  { id: 'moderngrad', label: 'Modern Gradient', category: 'Premium', bg: 'linear-gradient(135deg,#4568DC,#B06AB3)', accent: '#FFD700' },
  { id: 'premiumdark', label: 'Premium Dark', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#302b63)', accent: '#00D4FF' },
  { id: 'lightpro', label: 'Light Professional', category: 'Professional', bg: 'linear-gradient(135deg,#e0eafc,#cfdef3)', accent: '#1a237e' },
  { id: 'aurora', label: 'Aurora', category: 'Premium', bg: 'linear-gradient(135deg,#1a0533,#003333)', accent: '#00FFD1' },
  { id: 'cosmic', label: 'Cosmic Dark', category: 'Premium', bg: 'linear-gradient(135deg,#020816,#0d1b2a)', accent: '#4D9FFF' },
  { id: 'gold', label: 'Gold Elite', category: 'Premium', bg: 'linear-gradient(135deg,#1a1200,#3d2e00)', accent: '#FFD700' },
  { id: 'platinum', label: 'Platinum Elite', category: 'Premium', bg: 'linear-gradient(135deg,#232526,#414345)', accent: '#E5E4E2' },
  { id: 'luxuryblack', label: 'Luxury Black', category: 'Premium', bg: 'linear-gradient(135deg,#000000,#1a1a1a)', accent: '#FFD700' },
  { id: 'royalblue', label: 'Royal Blue', category: 'Premium', bg: 'linear-gradient(135deg,#1e3c72,#2a5298)', accent: '#FFD700' },
  { id: 'emerald', label: 'Emerald Premium', category: 'Premium', bg: 'linear-gradient(135deg,#0f3d3e,#1b5e20)', accent: '#00E676' },
  { id: 'crimson', label: 'Crimson Pro', category: 'Professional', bg: 'linear-gradient(135deg,#870000,#190A05)', accent: '#FFD700' },
  { id: 'neontech', label: 'Neon Tech', category: 'Premium', bg: 'linear-gradient(135deg,#0f0c29,#24243e)', accent: '#00FFF0' },
  { id: 'cyber', label: 'Cyber Future', category: 'Premium', bg: 'linear-gradient(135deg,#12121e,#1e1e3a)', accent: '#FF00E5' },
  { id: 'academic', label: 'Academic Professional', category: 'Academic', bg: 'linear-gradient(135deg,#1a2980,#26d0ce)', accent: '#FFD700' },
  { id: 'university', label: 'University Style', category: 'Academic', bg: 'linear-gradient(135deg,#232526,#0f2027)', accent: '#4D9FFF' },
  { id: 'coaching', label: 'Coaching Institute', category: 'Academic', bg: 'linear-gradient(135deg,#134E5E,#71B280)', accent: '#FFD700' },
  { id: 'studyplan', label: 'Study Planner', category: 'Academic', bg: 'linear-gradient(135deg,#3a1c71,#d76d77)', accent: '#FFD700' },
  { id: 'warrior', label: 'Exam Warrior', category: 'Motivation', bg: 'linear-gradient(135deg,#bf360c,#e65100)', accent: '#FFD700' },
  { id: 'topper', label: 'Topper Edition', category: 'Motivation', bg: 'linear-gradient(135deg,#f7971e,#ffd200)', accent: '#1a1a2e' },
  { id: 'rankbooster', label: 'Rank Booster', category: 'Motivation', bg: 'linear-gradient(135deg,#DA22FF,#9733EE)', accent: '#FFD700' },
  { id: 'launch', label: 'New Batch Launch', category: 'Offer', bg: 'linear-gradient(135deg,#11998e,#38ef7d)', accent: '#1a1a2e' },
  { id: 'earlybird', label: 'Early Bird Offer', category: 'Offer', bg: 'linear-gradient(135deg,#f857a6,#ff5858)', accent: '#FFD700' },
  { id: 'megasale', label: 'Mega Sale', category: 'Offer', bg: 'linear-gradient(135deg,#eb3349,#f45c43)', accent: '#FFD700' },
  { id: 'limitedseats', label: 'Limited Seats', category: 'Offer', bg: 'linear-gradient(135deg,#7f0000,#3d0000)', accent: '#FFD700' },
  { id: 'diwali', label: 'Diwali Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#8E2DE2,#FF6B00)', accent: '#FFD700' },
  { id: 'newyear', label: 'New Year Special', category: 'Seasonal', bg: 'linear-gradient(135deg,#000046,#1CB5E0)', accent: '#FFD700' },
  { id: 'neetv', label: 'Medical (NEET)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#004d40,#006064)', accent: '#00E5FF' },
  { id: 'jeev', label: 'Engineering (JEE)', category: 'Exam-Specific', bg: 'linear-gradient(135deg,#1a237e,#283593)', accent: '#FFD700' },
]
const BN_FONTS = [
  { id: 'modern', label: 'Bold Modern', family: "'Inter',sans-serif" },
  { id: 'serif', label: 'Elegant Serif', family: "'Playfair Display',serif" },
  { id: 'clean', label: 'Clean Sans', family: "'Poppins',sans-serif" },
]
const BN_BADGES = [
  { id: 'none', label: 'None' }, { id: 'new', label: '✨ New' }, { id: 'trending', label: '📈 Trending' },
  { id: 'popular', label: '⭐ Popular' }, { id: 'bestseller', label: '🏆 Best Seller' }, { id: 'premium', label: '💎 Premium' },
  { id: 'limitedseats', label: '🔥 Limited Seats' }, { id: 'scholarship', label: '🎓 Scholarship' }, { id: 'earlybird', label: '🐦 Early Bird' },
  { id: 'flashsale', label: '⚡ Flash Sale' }, { id: 'live', label: '🔴 Live' }, { id: 'upcoming', label: '🕐 Upcoming' },
  { id: 'regopen', label: '📝 Registration Open' }, { id: 'closingsoon', label: '⏳ Closing Soon' }, { id: 'freedemo', label: '🆓 Free Demo' },
  { id: 'recommended', label: '👍 Recommended' }, { id: 'topRated', label: '🌟 Top Rated' }, { id: 'verified', label: '✅ Verified' },
]
const BN_EXAM_ICON: any = { NEET: '🧬', 'NEET UG': '🧬', 'NEET PG': '🩺', JEE: '⚛️', 'JEE Main': '⚛️', 'JEE Advanced': '⚛️', CUET: '📘', 'CUET UG': '📘', 'CUET PG': '📗', SSC: '📋', 'SSC CGL': '📋', 'SSC CHSL': '📋', UPSC: '🏛️', 'UPSC CSE': '🏛️', NDA: '🎖️', CDS: '🎖️', CAT: '📊', CLAT: '⚖️', GATE: '🔧', 'IIT JAM': '🔬', 'CSIR NET': '🔬', 'UGC NET': '📖', 'Railway (RRB)': '🚆', 'Banking (IBPS / SBI)': '🏦', 'State PSC': '🏛️' }

// ── STUDENT BANNER CARD (renders the admin-designed Creative Studio banner) ──
function StudentBannerCard({ banner: b }: any) {
  const tpl = BN_TEMPLATES.find(t => t.id === b.template) || BN_TEMPLATES[0]
  let bg = b.bgImage ? (/^(linear|radial)-gradient|^#|^rgba?\(/.test(b.bgImage) ? b.bgImage : `url(${b.bgImage}) center/cover`) : (tpl.bg)
  if (b.gradientAngle && b.gradientAngle !== 135 && typeof bg === 'string' && bg.indexOf('135deg') >= 0) bg = bg.replace('135deg', b.gradientAngle + 'deg')
  const badgeObj = BN_BADGES.find((x: any) => x.id === b.badge)
  const sv = b.sectionVisibility || { icon: true, badge: true, title: true, tagline: true }
  const badgeRadius = b.badgeStyle === 'corner' ? 0 : b.badgeStyle === 'ribbon' ? 3 : 20
  const pad = b.spacing === 'compact' ? 8 : b.spacing === 'spacious' ? 16 : 12
  const renderLayerContent = (l: any) => {
    if (l.type === 'icon') return <span style={{ fontSize: 18 }}>{l.content}</span>
    if (!l.content) return null
    if (l.content.startsWith('<svg')) return <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: l.content }} />
    if (l.content.startsWith('data:image') || /^https?:\/\//.test(l.content)) return <img src={l.content} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
    return null
  }
  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', background: bg, color: b.textColor || '#fff', fontFamily: (BN_FONTS.find((f: any) => f.id === b.fontStyle) || BN_FONTS[0]).family, padding: pad, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', zIndex: 1 }}>
      {(b.layers || []).slice().sort((a: any, b2: any) => a.zIndex - b2.zIndex).map((l: any) => (
        <div key={l.id} style={{ position: 'absolute', left: l.x + '%', top: l.y + '%', transform: `translate(-50%,-50%) scale(${l.scale * 0.6}) rotate(${l.rotation}deg)`, opacity: l.opacity, zIndex: 10 + l.zIndex, width: 34, height: 34, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
          {renderLayerContent(l)}
        </div>
      ))}
      {(sv.icon !== false || sv.badge !== false) && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          {sv.icon !== false ? <span style={{ fontSize: 16 }}>{BN_EXAM_ICON[b.examType] || '📚'}</span> : <span />}
          {sv.badge !== false && badgeObj && badgeObj.id !== 'none' && <span style={{ fontSize: 8, fontWeight: 700, padding: '2px 7px', borderRadius: badgeRadius, background: b.accentColor || tpl.accent, color: '#1a1a2e' }}>{badgeObj.label}</span>}
        </div>
      )}
      {(sv.title !== false || sv.tagline !== false) && (
        <div style={{ textAlign: (b.textAlign || 'left') as any }}>
          {sv.title !== false && <div style={{ fontSize: 14, fontWeight: 800, lineHeight: 1.2, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{b.title}</div>}
          {sv.tagline !== false && b.tagline && <div style={{ fontSize: 9.5, opacity: 0.85, marginTop: 2 }}>{b.tagline}</div>}
        </div>
      )}
    </div>
  )
}

// ── BATCH CARD ──
function BatchCard({ b, tok, onUpdate, compareList, toggleCompare, onBuy, onReview, onPreview, showPriceWatch }: {
EOF

cat > /tmp/p5_old.txt << 'EOF'
      <div style={{ height:140,background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden' }}>
        <div style={{ position:'absolute',inset:0,background:'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))',zIndex:1 }} />
        {!b.thumbnail&&<span style={{ fontSize:46,filter:`drop-shadow(0 0 16px ${ec})`,zIndex:2,opacity:0.88 }}>{CICONS[b.examType]||'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{ position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.92)',padding:'4px 0',textAlign:'center',fontSize:10,fontWeight:700,color:'#fff',zIndex:3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled&&<div style={{ position:'absolute',inset:0,background:'rgba(39,174,96,0.16)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2 }}><span style={{ background:'rgba(39,174,96,0.9)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:11,fontWeight:800 }}>✅ Enrolled</span></div>}
      </div>
EOF

cat > /tmp/p5_new.txt << 'EOF'
      <div style={{ height:140,position:'relative',display:'flex',alignItems:'center',justifyContent:'center',overflow:'hidden',...(b.banner?{}:{background:b.thumbnail?`url(${b.thumbnail}) center/cover`:`linear-gradient(135deg,${ec}12,${ec}05,rgba(2,8,22,0.9))`}) }}>
        {b.banner&&<StudentBannerCard banner={b.banner} />}
        {!b.banner&&<div style={{ position:'absolute',inset:0,background:'linear-gradient(180deg,transparent 30%,rgba(4,12,30,0.95))',zIndex:1 }} />}
        {!b.banner&&!b.thumbnail&&<span style={{ fontSize:46,filter:`drop-shadow(0 0 16px ${ec})`,zIndex:2,opacity:0.88 }}>{CICONS[b.examType]||'📚'}</span>}
        {isFlash&&b.flashSaleEndTime&&<div style={{ position:'absolute',bottom:0,left:0,right:0,background:'rgba(200,40,40,0.92)',padding:'4px 0',textAlign:'center',fontSize:10,fontWeight:700,color:'#fff',zIndex:3 }}>⚡ Flash: <FlashTimer end={b.flashSaleEndTime} /></div>}
        {b.isEnrolled&&<div style={{ position:'absolute',inset:0,background:'rgba(39,174,96,0.16)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:2 }}><span style={{ background:'rgba(39,174,96,0.9)',color:'#fff',padding:'5px 14px',borderRadius:20,fontSize:11,fontWeight:800 }}>✅ Enrolled</span></div>}
      </div>
EOF

# ── Apply patches via Node ──
cat > /tmp/apply_banner_integration.js << 'NODEEOF'
const fs = require('fs');
function readTrim(p) { let c = fs.readFileSync(p, 'utf8'); return c.endsWith('\n') ? c.slice(0, -1) : c; }
function patch(targetPath, oldFile, newFile, label) {
  let content = fs.readFileSync(targetPath, 'utf8');
  const oldStr = readTrim(oldFile), newStr = readTrim(newFile);
  if (!content.includes(oldStr)) { console.log('❌ [' + label + '] NOT FOUND — skipped.'); return; }
  content = content.replace(oldStr, newStr);
  fs.writeFileSync(targetPath, content, 'utf8');
  console.log('✅ [' + label + '] patched.');
}
patch('src/routes/studentBatches.js', '/tmp/p1_old.txt', '/tmp/p1_new.txt', 'backend: Banner require');
patch('src/routes/studentBatches.js', '/tmp/p2_old.txt', '/tmp/p2_new.txt', 'backend: banner fetch+map');
patch('src/routes/studentBatches.js', '/tmp/p3_old.txt', '/tmp/p3_new.txt', 'backend: attach banner to result');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/p4_old.txt', '/tmp/p4_new.txt', 'frontend: BN constants + StudentBannerCard');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/p5_old.txt', '/tmp/p5_new.txt', 'frontend: card thumbnail → banner render');
NODEEOF

node /tmp/apply_banner_integration.js

echo ""
echo "=== Restarting backend ==="
pkill -9 -f "node src/index.js" 2>/dev/null
sleep 1
cd ~/workspace && node src/index.js &
sleep 3
echo "=== Done. Student page reload karke check karo ==="
