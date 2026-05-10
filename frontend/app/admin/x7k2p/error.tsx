'use client'
export default function AdminError({error,reset}:{error:Error&{digest?:string};reset:()=>void}){
  return(
    <div style={{background:'#0a0e1a',color:'#fff',minHeight:'100vh',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:20,fontFamily:'monospace'}}>
      <div style={{fontSize:22,marginBottom:16}}>🔴 ProveRank — Admin Panel Error</div>
      <div style={{background:'#1a1f2e',border:'2px solid #FF6B9D',borderRadius:10,padding:16,maxWidth:'95%',width:600,wordBreak:'break-word'}}>
        <div style={{color:'#FF6B9D',fontWeight:'bold',fontSize:13,marginBottom:6}}>⚡ Error Message:</div>
        <div style={{color:'#fff',fontSize:15,marginBottom:14,padding:8,background:'#0d1117',borderRadius:6}}>{error.message||'Unknown error'}</div>
        <div style={{color:'#FF6B9D',fontWeight:'bold',fontSize:13,marginBottom:6}}>📍 Stack (top lines):</div>
        <div style={{color:'#aaa',fontSize:11,whiteSpace:'pre-wrap',padding:8,background:'#0d1117',borderRadius:6}}>{error.stack?.split('\n').slice(0,6).join('\n')||'No stack'}</div>
      </div>
      <button onClick={reset} style={{marginTop:20,background:'#00B4FF',color:'#000',border:'none',borderRadius:8,padding:'12px 28px',cursor:'pointer',fontWeight:'bold',fontSize:15}}>🔄 Reload Panel</button>
      <div style={{marginTop:10,color:'#555',fontSize:11}}>📸 Screenshot karo aur developer ko bhejo</div>
    </div>
  )
}
