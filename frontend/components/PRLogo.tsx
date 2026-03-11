'use client'

function PRLogo() {
  const size = 64; const r = 32; const cx = 32; const cy = 32;
  const outer = Array.from({length:6},(_,i)=>{
    const a=(Math.PI/180)*(60*i-30);
    return `${cx+r*0.88*Math.cos(a)},${cy+r*0.88*Math.sin(a)}`;
  }).join(' ');
  const inner = Array.from({length:6},(_,i)=>{
    const a=(Math.PI/180)*(60*i-30);
    return `${cx+r*0.72*Math.cos(a)},${cy+r*0.72*Math.sin(a)}`;
  }).join(' ');

  return (
    <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:10}}>
      <svg width={size} height={size} viewBox="0 0 64 64">
        <defs>
          <filter id="gl">
            <feGaussianBlur stdDeviation="2.5" result="b"/>
            <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
          </filter>
        </defs>
        {/* Outer glow ring */}
        <polygon points={outer} fill="none"
          stroke="rgba(77,159,255,0.35)" strokeWidth="1" filter="url(#gl)"/>
        {/* Inner ring */}
        <polygon points={inner} fill="none"
          stroke="#4D9FFF" strokeWidth="2" filter="url(#gl)"/>
        {/* Honeycomb dots */}
        {Array.from({length:6},(_,i)=>{
          const a=(Math.PI/180)*(60*i-30);
          return <circle key={i}
            cx={cx+r*0.88*Math.cos(a)} cy={cy+r*0.88*Math.sin(a)}
            r={3} fill="#4D9FFF" filter="url(#gl)"/>;
        })}
        {/* PR text */}
        <text x={cx} y={cy+6}
          textAnchor="middle"
          fontFamily="Playfair Display,serif"
          fontSize="20" fontWeight="700"
          fill="#4D9FFF" filter="url(#gl)">PR</text>
      </svg>
      {/* ProveRank gradient text — exact from login page */}
      <div style={{
        fontFamily:'Playfair Display,serif',
        fontSize:30, fontWeight:700,
        background:'linear-gradient(90deg,#4D9FFF 0%,#FFFFFF 50%,#4D9FFF 100%)',
        WebkitBackgroundClip:'text',
        WebkitTextFillColor:'transparent',
        letterSpacing:1, lineHeight:1
      }}>ProveRank</div>
      <div style={{
        fontSize:11, color:'#6B8BAF',
        letterSpacing:4, textTransform:'uppercase'
      }}>Online Test Platform</div>
    </div>
  );
}

export default PRLogo;
