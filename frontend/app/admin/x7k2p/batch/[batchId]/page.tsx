'use client'
import{useState,useEffect}from 'react'
export default function P(){
const[id,setId]=useState('')
useEffect(()=>{
const p=window.location.pathname.split('/')
setId(p[p.length-1]||'none')
},[])
return <div style={{background:'#001628',minHeight:'100vh',color:'white',padding:40,fontFamily:'sans-serif'}}>
<h2>Batch Detail Page ✅</h2>
<p>Batch ID: {id||'loading...'}</p>
<button onClick={()=>{window.location.href='/admin/x7k2p'}} style={{background:'blue',color:'white',padding:'10px 20px',border:'none',borderRadius:8,cursor:'pointer',marginTop:20}}>Back to Admin</button>
</div>
}