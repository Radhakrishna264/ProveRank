'use client'
import{useState}from 'react'

interface CopyBtnProps{
  text:string
  size?:'sm'|'md'
  label?:string
}

export default function CopyBtn({text,size='sm',label}:CopyBtnProps){
  const[copied,setCopied]=useState(false)
  const copy=(e:any)=>{
    e.stopPropagation()
    navigator.clipboard.writeText(text).then(()=>{setCopied(true);setTimeout(()=>setCopied(false),2000)}).catch(()=>{
      // Fallback for older browsers
      const el=document.createElement('textarea');el.value=text;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);
      setCopied(true);setTimeout(()=>setCopied(false),2000)
    })
  }
  const sz=size==='md'?{fontSize:12,padding:'4px 10px'}:{fontSize:10,padding:'2px 7px'}
  return(
    <button onClick={copy} title={'Copy: '+text} style={{
      background:copied?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.08)',
      color:copied?'#00C48C':'#6B8FAF',
      border:'1px solid '+(copied?'rgba(0,196,140,0.3)':'rgba(77,159,255,0.2)'),
      borderRadius:6,cursor:'pointer',
      display:'inline-flex',alignItems:'center',gap:3,
      transition:'all 0.2s',flexShrink:0,whiteSpace:'nowrap',
      fontFamily:'Inter,sans-serif',fontWeight:600,
      ...sz
    }}>
      {copied?'✅':'📋'}{label||''}{copied?' Copied!':''}
    </button>
  )
}
