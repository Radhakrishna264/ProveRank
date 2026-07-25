#!/bin/bash
set -e
cd ~/workspace

cp frontend/app/dashboard/test-series/page.tsx frontend/app/dashboard/test-series/page.tsx.bak_card_click_preview

mkdir -p /tmp/cardpatch

# 1. Root card div: add onClick to open preview + pointer cursor
cat > /tmp/cardpatch/1_old.txt << 'EOF'
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)' }}>
EOF
cat > /tmp/cardpatch/1_new.txt << 'EOF'
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)} onClick={()=>onPreview&&onPreview(b)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)',cursor:onPreview?'pointer':'default' }}>
EOF

# 2. Remove the eye preview button entirely
cat > /tmp/cardpatch/2_old.txt << 'EOF'
      {onPreview&&<button onClick={e=>{e.stopPropagation();onPreview(b)}} style={{ position:'absolute',top:52,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:32,height:32,cursor:'pointer',fontSize:13,display:'flex',alignItems:'center',justifyContent:'center',color:'#fff' }}>👁️</button>}
EOF
cat > /tmp/cardpatch/2_new.txt << 'EOF'
EOF

# 3. Wishlist heart button: stop propagation so it doesn't also trigger preview
cat > /tmp/cardpatch/3_old.txt << 'EOF'
      <button onClick={toggleWish} style={{ position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:15,display:'flex',alignItems:'center',justifyContent:'center' }}>{b.isWishlisted?'❤️':'🤍'}</button>
EOF
cat > /tmp/cardpatch/3_new.txt << 'EOF'
      <button onClick={e=>{e.stopPropagation();toggleWish()}} style={{ position:'absolute',top:10,right:10,zIndex:5,background:'rgba(0,0,20,0.6)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:'50%',width:36,height:36,cursor:'pointer',fontSize:15,display:'flex',alignItems:'center',justifyContent:'center' }}>{b.isWishlisted?'❤️':'🤍'}</button>
EOF

# 4. Price watch button
cat > /tmp/cardpatch/4_old.txt << 'EOF'
          <button onClick={togglePriceWatch} style={{ width:'100%',padding:'6px',marginBottom:8,background:b.isPriceWatched?'rgba(0,212,255,0.12)':'rgba(77,159,255,0.05)',border:`1px solid ${b.isPriceWatched?'rgba(0,212,255,0.35)':'rgba(77,159,255,0.12)'}`,borderRadius:10,color:b.isPriceWatched?'#00D4FF':'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:10,fontWeight:700 }}>
EOF
cat > /tmp/cardpatch/4_new.txt << 'EOF'
          <button onClick={e=>{e.stopPropagation();togglePriceWatch()}} style={{ width:'100%',padding:'6px',marginBottom:8,background:b.isPriceWatched?'rgba(0,212,255,0.12)':'rgba(77,159,255,0.05)',border:`1px solid ${b.isPriceWatched?'rgba(0,212,255,0.35)':'rgba(77,159,255,0.12)'}`,borderRadius:10,color:b.isPriceWatched?'#00D4FF':'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:10,fontWeight:700 }}>
EOF

# 5. Enrolled state (Go to Batch + review) wrapper: stop propagation on the whole row
cat > /tmp/cardpatch/5_old.txt << 'EOF'
          <div style={{ display:'flex',gap:6 }}>
            <button style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to Batch →</button>
            {onReview&&<button onClick={()=>onReview(b)} style={{ padding:'10px 10px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:11 }}>⭐</button>}
          </div>
EOF
cat > /tmp/cardpatch/5_new.txt << 'EOF'
          <div style={{ display:'flex',gap:6 }} onClick={e=>e.stopPropagation()}>
            <button style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to Batch →</button>
            {onReview&&<button onClick={()=>onReview(b)} style={{ padding:'10px 10px',background:'rgba(255,215,0,0.08)',border:'1px solid rgba(255,215,0,0.2)',borderRadius:11,color:'#FFD700',cursor:'pointer',fontSize:11 }}>⭐</button>}
          </div>
EOF

# 6. Enroll Free button
cat > /tmp/cardpatch/6_old.txt << 'EOF'
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
EOF
cat > /tmp/cardpatch/6_new.txt << 'EOF'
          <button onClick={e=>{e.stopPropagation();enroll()}} disabled={loading} style={{ width:'100%',padding:'10px',background:'linear-gradient(135deg,#27AE60,#1E8449)',border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Enrolling...':'🚀 Enroll Free'}</button>
EOF

# 7. Free Trial button
cat > /tmp/cardpatch/7_old.txt << 'EOF'
          <button onClick={enroll} disabled={loading} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Starting...':'🎯 Free Trial'}</button>
EOF
cat > /tmp/cardpatch/7_new.txt << 'EOF'
          <button onClick={e=>{e.stopPropagation();enroll()}} disabled={loading} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>{loading?'Starting...':'🎯 Free Trial'}</button>
EOF

# 8. Buy button
cat > /tmp/cardpatch/8_old.txt << 'EOF'
          <button onClick={()=>onBuy&&onBuy(b)} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>
            🛒 Buy ₹{finalPrice}
          </button>
EOF
cat > /tmp/cardpatch/8_new.txt << 'EOF'
          <button onClick={e=>{e.stopPropagation();onBuy&&onBuy(b)}} style={{ width:'100%',padding:'10px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11 }}>
            🛒 Buy ₹{finalPrice}
          </button>
EOF

cat > /tmp/cardpatch/apply.js << 'NODEEOF'
const fs = require('fs');
function readTrim(p) { let c = fs.readFileSync(p, 'utf8'); return c.endsWith('\n') ? c.slice(0, -1) : c; }
const targetPath = 'frontend/app/dashboard/test-series/page.tsx';
let content = fs.readFileSync(targetPath, 'utf8');
for (let i = 1; i <= 8; i++) {
  const oldStr = readTrim(`/tmp/cardpatch/${i}_old.txt`);
  const newStr = readTrim(`/tmp/cardpatch/${i}_new.txt`);
  if (!content.includes(oldStr)) {
    console.log('❌ [' + i + '] Pattern NOT FOUND — skipped.');
    continue;
  }
  content = content.replace(oldStr, newStr);
  console.log('✅ [' + i + '] patched.');
}
fs.writeFileSync(targetPath, content, 'utf8');
NODEEOF

node /tmp/cardpatch/apply.js
