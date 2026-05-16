#!/bin/bash
# ProveRank — Feature 2: Welcome Banner + Student ID in Student Profile/Dashboard
# Run: bash feature2_welcome_profile.sh

echo "=== FEATURE 2: Welcome Banner + Student Profile ID ==="

node << 'EOF'
const fs=require('fs'),path=require('path');
const WS=process.env.HOME+'/workspace';
const FE=WS+'/frontend';

// ── Find student dashboard/home page ──
function findFile(dir,depth=0){
  if(depth>6||!fs.existsSync(dir))return null;
  for(const item of fs.readdirSync(dir)){
    if(item==='node_modules'||item.startsWith('.'))continue;
    const fp=path.join(dir,item);
    const stat=fs.statSync(fp);
    if(stat.isDirectory()){const f=findFile(fp,depth+1);if(f)return f;}
    else if(/\.(jsx?|tsx?)$/.test(item)){
      try{
        const c=fs.readFileSync(fp,'utf8');
        if((c.includes('dashboard')||c.includes('Dashboard'))&&c.includes('student')&&c.length>5000)return fp;
      }catch(e){}
    }
  }
  return null;
}

// Find profile page
function findProfilePage(dir,depth=0){
  if(depth>6||!fs.existsSync(dir))return null;
  for(const item of fs.readdirSync(dir)){
    if(item==='node_modules'||item.startsWith('.'))continue;
    const fp=path.join(dir,item);
    const stat=fs.statSync(fp);
    if(stat.isDirectory()){const f=findProfilePage(fp,depth+1);if(f)return f;}
    else if(/\.(jsx?|tsx?)$/.test(item)&&(item.includes('profile')||item.includes('Profile'))){
      try{
        const c=fs.readFileSync(fp,'utf8');
        if(c.includes('name')||c.includes('email'))return fp;
      }catch(e){}
    }
  }
  return null;
}

// ── Create Welcome Banner Component ──
const compDir=FE+'/components';
if(!fs.existsSync(compDir))fs.mkdirSync(compDir,{recursive:true});

fs.writeFileSync(compDir+'/WelcomeBanner.tsx',`'use client'
import{useState,useEffect}from 'react'

interface WelcomeBannerProps{
  studentName:string
  studentId:string
  onClose:()=>void
}

export default function WelcomeBanner({studentName,studentId,onClose}:WelcomeBannerProps){
  const[visible,setVisible]=useState(false)
  const[copied,setCopied]=useState(false)
  
  useEffect(()=>{setTimeout(()=>setVisible(true),100)},[])

  const copyId=()=>{
    navigator.clipboard.writeText(studentId).then(()=>{setCopied(true);setTimeout(()=>setCopied(false),2000)})
  }

  const handleClose=async()=>{
    setVisible(false)
    setTimeout(onClose,400)
    try{
      const token=localStorage.getItem('pr_token')
      if(token)await fetch((process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com')+'/api/welcome-seen',{
        method:'POST',headers:{Authorization:'Bearer '+token}
      })
    }catch(e){}
  }

  return(
    <div style={{
      position:'fixed',inset:0,zIndex:9999,
      background:'rgba(0,0,0,0.85)',backdropFilter:'blur(8px)',
      display:'flex',alignItems:'center',justifyContent:'center',padding:16,
      opacity:visible?1:0,transition:'opacity 0.4s ease'
    }}>
      <div style={{
        background:'linear-gradient(135deg,#001628 0%,#000D20 50%,#001028 100%)',
        border:'1px solid rgba(77,159,255,0.4)',borderRadius:24,
        padding:'40px 28px',maxWidth:420,width:'100%',
        boxShadow:'0 0 80px rgba(77,159,255,0.15),0 0 200px rgba(77,159,255,0.05)',
        transform:visible?'scale(1) translateY(0)':'scale(0.9) translateY(20px)',
        transition:'all 0.4s cubic-bezier(0.34,1.56,0.64,1)',
        fontFamily:'Inter,sans-serif',textAlign:'center',position:'relative',overflow:'hidden'
      }}>
        {/* Glow effects */}
        <div style={{position:'absolute',top:-60,left:'50%',transform:'translateX(-50%)',width:200,height:200,background:'radial-gradient(circle,rgba(77,159,255,0.15),transparent 70%)',pointerEvents:'none'}}/>
        <div style={{position:'absolute',bottom:-40,right:-40,width:150,height:150,background:'radial-gradient(circle,rgba(99,102,241,0.1),transparent 70%)',pointerEvents:'none'}}/>
        
        {/* Stars animation */}
        <style>{\`
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&family=Playfair+Display:wght@700;800&display=swap');
          @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
          @keyframes pulse{0%,100%{opacity:0.6}50%{opacity:1}}
          @keyframes shimmer{0%{background-position:-200% center}100%{background-position:200% center}}
          .welcome-badge:hover{transform:scale(1.02)}
        \`}</style>
        
        {/* Rocket / Welcome Icon */}
        <div style={{fontSize:56,marginBottom:16,animation:'float 3s ease-in-out infinite',display:'block'}}>🎉</div>
        
        {/* Welcome text */}
        <div style={{fontSize:13,fontWeight:600,color:'#4D9FFF',letterSpacing:2,textTransform:'uppercase',marginBottom:8}}>Welcome to ProveRank</div>
        <div style={{fontSize:24,fontWeight:800,fontFamily:'Playfair Display,serif',color:'#E8F4FF',marginBottom:6,lineHeight:1.2}}>
          Namaste, {studentName?.split(' ')[0] || 'Student'}! 🙏
        </div>
        <div style={{fontSize:13,color:'#6B8FAF',marginBottom:28,lineHeight:1.6}}>
          Your journey to NEET success starts here.<br/>Your unique Student ID is ready!
        </div>
        
        {/* Student ID Card */}
        <div className="welcome-badge" style={{
          background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(99,102,241,0.08))',
          border:'1.5px solid rgba(77,159,255,0.35)',
          borderRadius:16,padding:'20px 24px',marginBottom:24,
          cursor:'pointer',transition:'all 0.2s',position:'relative',overflow:'hidden'
        }} onClick={copyId}>
          <div style={{position:'absolute',inset:0,background:'linear-gradient(135deg,transparent 30%,rgba(77,159,255,0.05) 100%)',pointerEvents:'none'}}/>
          <div style={{fontSize:10,fontWeight:700,color:'#6B8FAF',letterSpacing:2,textTransform:'uppercase',marginBottom:10}}>Your Student ID</div>
          <div style={{
            fontSize:28,fontWeight:800,
            background:'linear-gradient(90deg,#4D9FFF,#818CF8,#A78BFA)',
            WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',
            backgroundSize:'200% auto',animation:'shimmer 3s linear infinite',
            letterSpacing:4,fontFamily:'monospace',marginBottom:10
          }}>{studentId}</div>
          <div style={{fontSize:11,color:copied?'#00C48C':'#6B8FAF',transition:'color 0.2s',display:'flex',alignItems:'center',justifyContent:'center',gap:4}}>
            {copied?'✅ Copied to clipboard!':'📋 Tap to copy ID'}
          </div>
        </div>
        
        {/* Info points */}
        <div style={{display:'flex',flexDirection:'column',gap:8,marginBottom:28,textAlign:'left'}}>
          {[
            {i:'🔐',t:'Save your Student ID',d:'Use it to login and for admin reference'},
            {i:'📊',t:'Track your Progress',d:'View ranks, scores & analytics'},
            {i:'📚',t:'Access Study Material',d:'Batches, exams & notes await you'},
          ].map(x=>(
            <div key={x.i} style={{display:'flex',gap:10,alignItems:'flex-start',padding:'8px 10px',borderRadius:10,background:'rgba(77,159,255,0.04)',border:'1px solid rgba(77,159,255,0.08)'}}>
              <span style={{fontSize:16,flexShrink:0}}>{x.i}</span>
              <div>
                <div style={{fontSize:12,fontWeight:700,color:'#E8F4FF'}}>{x.t}</div>
                <div style={{fontSize:11,color:'#6B8FAF'}}>{x.d}</div>
              </div>
            </div>
          ))}
        </div>
        
        {/* CTA Button */}
        <button onClick={handleClose} style={{
          width:'100%',padding:'14px',
          background:'linear-gradient(135deg,#4D9FFF,#6366F1)',
          color:'#fff',border:'none',borderRadius:12,
          fontSize:14,fontWeight:700,cursor:'pointer',
          boxShadow:'0 8px 32px rgba(77,159,255,0.35)',
          transition:'all 0.2s',letterSpacing:0.5
        }}>
          🚀 Start My NEET Journey!
        </button>
        
        <div style={{fontSize:10,color:'rgba(107,143,175,0.5)',marginTop:12}}>
          ProveRank · India's Most Advanced NEET Platform
        </div>
      </div>
    </div>
  )
}
`);
console.log('WelcomeBanner component created');

// ── Create CopyButton universal component ──
fs.writeFileSync(compDir+'/CopyBtn.tsx',`'use client'
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
`);
console.log('CopyBtn universal component created');

// ── Find and patch student-facing pages ──
// Find registration/onboarding page
function findByContent(dir,keywords,depth=0){
  if(depth>6||!fs.existsSync(dir))return[];
  const results=[];
  for(const item of fs.readdirSync(dir)){
    if(item==='node_modules'||item.startsWith('.'))continue;
    const fp=path.join(dir,item);
    const stat=fs.statSync(fp);
    if(stat.isDirectory()){results.push(...findByContent(fp,keywords,depth+1));}
    else if(/\.(jsx?|tsx?)$/.test(item)){
      try{
        const c=fs.readFileSync(fp,'utf8');
        if(keywords.every(k=>c.includes(k)))results.push(fp);
      }catch(e){}
    }
  }
  return results;
}

const profilePages=findByContent(FE,['profile','name','email'],0).filter(f=>f.includes('profile')||f.includes('Profile'));
const dashboardPages=findByContent(FE,['dashboard','student'],0).filter(f=>f.includes('dashboard')||f.includes('home'));
const registerPages=findByContent(FE,['register','signup','password','Register'],0).filter(f=>!f.includes('node_modules'));

console.log('Profile pages found:',profilePages.slice(0,3));
console.log('Dashboard pages:',dashboardPages.slice(0,3));
console.log('Register pages:',registerPages.slice(0,3));

// Patch profile page to show studentId
for(const pf of profilePages.slice(0,2)){
  let c=fs.readFileSync(pf,'utf8');
  if(c.includes('studentId')){console.log('Profile already has studentId:',pf);continue;}
  
  // Add studentId display near email/name display
  // Look for where email is displayed and add studentId after
  const emailPatterns=[
    ['{user?.email}','<div style={{marginTop:8,display:"flex",alignItems:"center",gap:6}}><span style={{fontSize:11,color:"#6B8FAF",fontWeight:600}}>Student ID:</span><span style={{fontSize:13,fontWeight:700,color:"#4D9FFF",fontFamily:"monospace",letterSpacing:1}}>{user?.studentId||"—"}</span>{user?.studentId&&<button onClick={()=>{navigator.clipboard.writeText(user.studentId);}} style={{fontSize:10,background:"rgba(77,159,255,0.1)",color:"#4D9FFF",border:"1px solid rgba(77,159,255,0.3)",borderRadius:5,padding:"2px 7px",cursor:"pointer"}}>📋</button>}</div>\n{user?.email}'],
    ['student.email','student.studentId&&<div style={{display:"flex",alignItems:"center",gap:6,marginTop:6}}><span style={{fontSize:11,fontWeight:600,color:"#6B8FAF"}}>ID: </span><span style={{color:"#4D9FFF",fontFamily:"monospace",fontWeight:700}}>{student.studentId}</span></div>'],
  ];
  for(const[old,rep] of emailPatterns){
    if(c.includes(old)){c=c.replace(old,rep);console.log('Profile patched:',pf);break;}
  }
  fs.writeFileSync(pf,c);
}

// Patch registration success to show welcome banner
for(const rf of registerPages.slice(0,3)){
  let c=fs.readFileSync(rf,'utf8');
  if(c.includes('WelcomeBanner')||c.includes('welcomeSeen')){continue;}
  if(!c.includes('register')&&!c.includes('Register'))continue;
  
  // Check if this is the registration page (has form + submit)
  if(!c.includes('password')&&!c.includes('Password'))continue;
  
  console.log('Patching registration page:',rf);
  
  // Add WelcomeBanner import at top
  const importLine=`import WelcomeBanner from '@/components/WelcomeBanner';\n`;
  c=importLine+c;
  
  // Add state for showing welcome banner
  const statePatterns=['useState(',`useState(`];
  const firstUseState=c.indexOf('useState(');
  if(firstUseState>-1){
    const lineStart=c.lastIndexOf('\n',firstUseState)+1;
    c=c.slice(0,lineStart)+'  const [showWelcome,setShowWelcome]=useState(false);\n  const [welcomeData,setWelcomeData]=useState<{name:string,studentId:string}|null>(null);\n'+c.slice(lineStart);
  }
  
  // Find successful registration handler and add welcome data
  const successPatterns=[
    ['setToken(data.token','setToken(data.token);\n      if(data.user&&data.user.studentId&&!data.user.welcomeSeen){setWelcomeData({name:data.user.name||"Student",studentId:data.user.studentId});setShowWelcome(true);}'],
    ['localStorage.setItem(\'pr_token\'','setWelcomeData({name:data.user?.name||"Student",studentId:data.user?.studentId||""});\n      if(!data.user?.welcomeSeen)setShowWelcome(true);\n      localStorage.setItem(\'pr_token\''],
  ];
  for(const[old,rep] of successPatterns){
    if(c.includes(old)){c=c.replace(old,rep);console.log('Registration success patched');break;}
  }
  
  // Add WelcomeBanner to JSX - find return and add at top
  const retIdx=c.lastIndexOf('return (');
  if(retIdx>-1){
    const insertAt=c.indexOf('\n',retIdx)+1;
    c=c.slice(0,insertAt)+`{showWelcome&&welcomeData&&<WelcomeBanner studentName={welcomeData.name} studentId={welcomeData.studentId} onClose={()=>{setShowWelcome(false);}}/>}\n`+c.slice(insertAt);
    console.log('WelcomeBanner added to registration JSX');
  }
  
  fs.writeFileSync(rf,c);
}

// ── Check if student panel page.tsx has login/init and add welcome check ──
const studentPanelFiles=findByContent(FE,['getToken','student','useEffect'],0).filter(f=>f.includes('student')&&!f.includes('admin')&&!f.includes('node_modules'));
console.log('Student panel files:',studentPanelFiles.slice(0,3));

// Add WelcomeBanner to student dashboard/main page
for(const sf of studentPanelFiles.slice(0,2)){
  let c=fs.readFileSync(sf,'utf8');
  if(c.includes('WelcomeBanner')||c.includes('showWelcome'))continue;
  if(c.length<5000)continue;
  
  console.log('Adding welcome check to student page:',sf);
  
  // Add import
  c=`import WelcomeBanner from '@/components/WelcomeBanner';\n`+c;
  
  // Add states
  const firstState=c.indexOf('useState(');
  if(firstState>-1){
    const lineStart=c.lastIndexOf('\n',firstState)+1;
    c=c.slice(0,lineStart)+'  const [showWelcome,setShowWelcome]=useState(false);\n  const [welcomeData,setWelcomeData]=useState<{name:string,studentId:string}|null>(null);\n'+c.slice(lineStart);
  }
  
  // Find where user data is loaded (getProfile/fetchUser) and check welcomeSeen
  const checkCode=`
  // Welcome banner check
  useEffect(()=>{
    const checkWelcome=async()=>{
      const token=localStorage.getItem('pr_token');
      if(!token)return;
      try{
        const r=await fetch((process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com')+'/api/profile',{headers:{Authorization:'Bearer '+token}});
        if(r.ok){
          const d=await r.json();
          const user=d.user||d;
          if(user&&user.studentId&&!user.welcomeSeen){
            setWelcomeData({name:user.name||'Student',studentId:user.studentId});
            setShowWelcome(true);
          }
        }
      }catch(e){}
    };
    checkWelcome();
  },[]);
`;
  
  // Add after first useEffect
  const firstEffectEnd=c.indexOf('},[])');
  if(firstEffectEnd>-1){
    c=c.slice(0,firstEffectEnd+5)+checkCode+c.slice(firstEffectEnd+5);
    console.log('Welcome check useEffect added');
  }
  
  // Add to JSX
  const retIdx=c.lastIndexOf('return (');
  if(retIdx>-1){
    const insertAt=c.indexOf('\n',retIdx)+1;
    c=c.slice(0,insertAt)+`    {showWelcome&&welcomeData&&<WelcomeBanner studentName={welcomeData.name} studentId={welcomeData.studentId} onClose={()=>setShowWelcome(false)}/>}\n`+c.slice(insertAt);
  }
  
  fs.writeFileSync(sf,c);
  break; // Only patch first matching file
}

console.log('\nAll patches applied!');
EOF

cd ~/workspace && git add . && git commit -m "feat: WelcomeBanner + CopyBtn components + Student ID in profile" && git push
echo "Feature 2 done!"
