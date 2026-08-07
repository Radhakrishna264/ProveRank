'use client'

function PRLogo({size=36}:{size?:number}) {
  const blockSize = size * 0.94
  const pSize = Math.round(blockSize * 0.63)
  const rSize = Math.round(blockSize * 0.63)
  const fontSize = Math.round(pSize * 0.52)
  const radius = Math.round(pSize * 0.28)
  return (
    <div style={{position:'relative',width:blockSize,height:blockSize,flexShrink:0,display:'inline-flex'}}>
      <div style={{
        position:'absolute',top:0,left:0,
        width:pSize,height:pSize,
        borderRadius:radius,
        background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#030810',
        boxShadow:'0 4px 16px rgba(77,159,255,0.4)'
      }}>P</div>
      <div style={{
        position:'absolute',bottom:0,right:0,
        width:rSize,height:rSize,
        borderRadius:radius,
        background:'rgba(0,212,255,0.1)',
        border:'1.5px solid rgba(0,212,255,0.45)',
        display:'flex',alignItems:'center',justifyContent:'center',
        fontSize:fontSize,fontWeight:900,fontFamily:'Inter,sans-serif',
        color:'#00D4FF',
        backdropFilter:'blur(8px)'
      }}>R</div>
    </div>
  )
}

export default PRLogo;
