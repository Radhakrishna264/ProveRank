const fs = require('fs');
const FILE = require('path').join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx');
let c = fs.readFileSync(FILE, 'utf8');

// ══ FIX 1: Galaxy BG ══
// Find exact old function boundary
const A = '// PARTICLES BACKGROUND \u2014 Same as Login page';
const B = "  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>\n}";
const ai = c.indexOf(A);
const bi = c.indexOf(B, ai) + B.length;
if(ai===-1){console.error('ParticlesBg start not found');process.exit(1);}
if(bi===B.length-1){console.error('ParticlesBg end not found');process.exit(1);}

// New Galaxy function — backticks totally fine here inside Node JS strings
const GALAXY = `// GALAXY BACKGROUND \u2014 Stars + Nebula + Shooting Stars + Particles
// \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
function ParticlesBg() {
  const canvasRef=useRef<HTMLCanvasElement>(null)
  useEffect(()=>{
    const canvas=canvasRef.current;if(!canvas)return
    const ctx=canvas.getContext('2d');if(!ctx)return
    let W=window.innerWidth,H=window.innerHeight
    canvas.width=W;canvas.height=H
    const stars:{x:number;y:number;r:number;op:number;ts:number;tp:number}[]=[]
    for(let i=0;i<200;i++)stars.push({x:Math.random()*W,y:Math.random()*H,r:Math.random()*1.5+0.2,op:Math.random()*0.65+0.15,ts:Math.random()*0.025+0.005,tp:Math.random()*Math.PI*2})
    const gStars:{x:number;y:number;r:number;op:number}[]=[]
    const cx=W*0.74,cy=H*0.25
    for(let i=0;i<160;i++){const arm=Math.floor(Math.random()*3);const t=Math.random()*Math.PI*3;const sp=Math.random()*50+8;const gx=cx+Math.cos(t+arm*2.09)*sp*(1+t*0.18)+(Math.random()-0.5)*20;const gy=cy+Math.sin(t+arm*2.09)*sp*0.55*(1+t*0.12)+(Math.random()-0.5)*18;gStars.push({x:gx,y:gy,r:Math.random()*1.3+0.2,op:Math.random()*0.5+0.15})}
    const particles:{x:number;y:number;vx:number;vy:number;r:number;opacity:number}[]=[]
    for(let i=0;i<50;i++)particles.push({x:Math.random()*W,y:Math.random()*H,vx:(Math.random()-.5)*.25,vy:(Math.random()-.5)*.25,r:Math.random()*1.2+0.3,opacity:Math.random()*.22+.04})
    const shoots:{x:number;y:number;len:number;life:number;maxL:number;active:boolean}[]=[]
    for(let i=0;i<4;i++)shoots.push({x:Math.random()*W,y:Math.random()*H*0.45,len:Math.random()*85+55,life:0,maxL:Math.random()*55+35,active:Math.random()>0.5})
    let frame=0,animId:number
    const ANG=Math.PI/5
    const draw=()=>{
      ctx.clearRect(0,0,W,H)
      const bg=ctx.createRadialGradient(W*.5,H*.35,0,W*.5,H*.5,W*.8)
      bg.addColorStop(0,'rgba(4,8,32,1)');bg.addColorStop(.5,'rgba(1,5,18,1)');bg.addColorStop(1,'rgba(0,2,10,1)')
      ctx.fillStyle=bg;ctx.fillRect(0,0,W,H)
      const n1=ctx.createRadialGradient(W*.18,H*.62,0,W*.18,H*.62,W*.35)
      n1.addColorStop(0,'rgba(75,35,155,0.13)');n1.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n1;ctx.fillRect(0,0,W,H)
      const n2=ctx.createRadialGradient(W*.78,H*.18,0,W*.78,H*.18,W*.3)
      n2.addColorStop(0,'rgba(25,75,175,0.14)');n2.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n2;ctx.fillRect(0,0,W,H)
      const n3=ctx.createRadialGradient(W*.88,H*.78,0,W*.88,H*.78,W*.22)
      n3.addColorStop(0,'rgba(0,155,175,0.08)');n3.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n3;ctx.fillRect(0,0,W,H)
      const gc=ctx.createRadialGradient(cx,cy,0,cx,cy,120)
      gc.addColorStop(0,'rgba(110,155,255,0.18)');gc.addColorStop(.45,'rgba(55,95,195,0.08)');gc.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=gc;ctx.fillRect(0,0,W,H)
      gStars.forEach(s=>{ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=\`rgba(155,195,255,\${s.op})\`;ctx.fill()})
      frame++
      stars.forEach(s=>{
        const tw=s.op*(0.45+0.55*Math.sin(frame*s.ts+s.tp))
        ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);ctx.fillStyle=\`rgba(215,232,255,\${tw})\`;ctx.fill()
        if(s.r>1.1){ctx.beginPath();ctx.arc(s.x,s.y,s.r*2.5,0,Math.PI*2);ctx.fillStyle=\`rgba(175,210,255,\${tw*.07})\`;ctx.fill()}
      })
      shoots.forEach(s=>{
        if(!s.active){s.life++;if(s.life>s.maxL*2.5){s.life=0;s.active=true;s.x=Math.random()*W;s.y=Math.random()*H*.4;s.maxL=Math.random()*55+35}return}
        s.life++;const prog=s.life/s.maxL
        if(prog>=1){s.active=false;s.life=0;return}
        const op=prog<.2?prog/.2:prog>.8?(1-prog)/.2:1
        const ex=s.x+Math.cos(ANG)*s.len*prog,ey=s.y+Math.sin(ANG)*s.len*prog
        const sg=ctx.createLinearGradient(s.x,s.y,ex,ey)
        sg.addColorStop(0,'rgba(255,255,255,0)');sg.addColorStop(.5,\`rgba(175,215,255,\${op*.55})\`);sg.addColorStop(1,\`rgba(255,255,255,\${op})\`)
        ctx.beginPath();ctx.moveTo(s.x,s.y);ctx.lineTo(ex,ey);ctx.strokeStyle=sg;ctx.lineWidth=1.5;ctx.stroke()
      })
      particles.forEach(p=>{p.x+=p.vx;p.y+=p.vy;if(p.x<0)p.x=W;if(p.x>W)p.x=0;if(p.y<0)p.y=H;if(p.y>H)p.y=0;ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2);ctx.fillStyle=\`rgba(77,159,255,\${p.opacity})\`;ctx.fill()})
      for(let i=0;i<particles.length;i++)for(let j=i+1;j<particles.length;j++){const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy);if(dist<110){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=\`rgba(77,159,255,\${.07*(1-dist/110)})\`;ctx.lineWidth=.4;ctx.stroke()}}
      animId=requestAnimationFrame(draw)
    }
    draw()
    const resize=()=>{W=window.innerWidth;H=window.innerHeight;canvas.width=W;canvas.height=H}
    window.addEventListener('resize',resize)
    return()=>{cancelAnimationFrame(animId);window.removeEventListener('resize',resize)}
  },[])
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>
}`;

c = c.slice(0, ai-64) + GALAXY + c.slice(bi);
console.log('Fix 1 DONE: GalaxyBg installed');

// ══ FIX 2: Add SVG cards + extra content INSIDE dashboard, before closing </div> ══
// Find the exact closing of dashboard section
const DASH_CLOSE = '            </div>\n          )}\n\n          {/* \u2550\u2550 GLOBAL SEARCH \u2550\u2550 */}';
const dci = c.indexOf(DASH_CLOSE);
if(dci===-1){console.error('Dashboard close not found');process.exit(1);}

const EXTRA = `
              {/* SVG Illustration Cards */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginTop:16,marginBottom:16}}>
                <div style={{...cs,textAlign:'center',padding:'16px 8px'}}>
                  <svg viewBox="0 0 100 90" width="80" style={{display:'block',margin:'0 auto 8px'}} xmlns="http://www.w3.org/2000/svg">
                    <circle cx="50" cy="28" r="14" fill="rgba(77,159,255,0.15)" stroke="rgba(77,159,255,0.6)" strokeWidth="1.5"/>
                    <circle cx="50" cy="24" r="6" fill="rgba(77,159,255,0.7)"/>
                    <path d="M34 46 Q50 40 66 46 L68 66 Q50 72 32 66 Z" fill="rgba(0,22,40,0.85)" stroke="rgba(77,159,255,0.5)" strokeWidth="1"/>
                    <rect x="38" y="50" width="24" height="2.5" rx="1.2" fill="rgba(77,159,255,0.6)"/>
                    <rect x="38" y="56" width="18" height="2" rx="1" fill="rgba(77,159,255,0.4)"/>
                    <rect x="38" y="61" width="14" height="2" rx="1" fill="rgba(77,159,255,0.3)"/>
                    <circle cx="50" cy="28" r="22" fill="none" stroke="rgba(77,159,255,0.08)" strokeWidth="1" strokeDasharray="3,5"/>
                  </svg>
                  <div style={{fontSize:10,fontWeight:700,color:ACC,marginBottom:2}}>Students</div>
                  <div style={{fontSize:20,fontWeight:900,color:TS}}>{(students||[]).length}</div>
                  <div style={{fontSize:9,color:DIM}}>Registered</div>
                </div>
                <div style={{...cs,textAlign:'center',padding:'16px 8px'}}>
                  <svg viewBox="0 0 100 90" width="80" style={{display:'block',margin:'0 auto 8px'}} xmlns="http://www.w3.org/2000/svg">
                    <rect x="18" y="12" width="64" height="70" rx="5" fill="rgba(0,22,40,0.85)" stroke="rgba(255,215,0,0.4)" strokeWidth="1.5"/>
                    <rect x="28" y="22" width="44" height="4.5" rx="2" fill="rgba(255,215,0,0.75)"/>
                    <rect x="28" y="30" width="30" height="2.5" rx="1.2" fill="rgba(77,159,255,0.5)"/>
                    <rect x="28" y="38" width="18" height="2.5" rx="1.2" fill="rgba(200,220,255,0.3)"/>
                    <circle cx="52" cy="39.2" r="3" fill="rgba(0,196,140,0.75)"/>
                    <rect x="28" y="46" width="18" height="2.5" rx="1.2" fill="rgba(200,220,255,0.3)"/>
                    <circle cx="52" cy="47.2" r="3" fill="rgba(0,196,140,0.75)"/>
                    <rect x="28" y="54" width="18" height="2.5" rx="1.2" fill="rgba(200,220,255,0.3)"/>
                    <circle cx="52" cy="55.2" r="3" fill="rgba(77,159,255,0.6)"/>
                    <path d="M70 65 L76 58 L78 60 L72 68 Z" fill="rgba(255,215,0,0.85)"/>
                  </svg>
                  <div style={{fontSize:10,fontWeight:700,color:GOLD,marginBottom:2}}>Exams</div>
                  <div style={{fontSize:20,fontWeight:900,color:TS}}>{(exams||[]).length}</div>
                  <div style={{fontSize:9,color:DIM}}>Created</div>
                </div>
                <div style={{...cs,textAlign:'center',padding:'16px 8px'}}>
                  <svg viewBox="0 0 100 90" width="80" style={{display:'block',margin:'0 auto 8px'}} xmlns="http://www.w3.org/2000/svg">
                    <rect x="10" y="60" width="80" height="24" rx="4" fill="rgba(0,22,40,0.85)" stroke="rgba(0,196,140,0.4)" strokeWidth="1"/>
                    <rect x="24" y="47" width="52" height="14" rx="3" fill="rgba(0,22,40,0.8)" stroke="rgba(0,196,140,0.3)" strokeWidth="1"/>
                    <rect x="40" y="34" width="20" height="14" rx="2" fill="rgba(0,22,40,0.8)" stroke="rgba(0,196,140,0.3)" strokeWidth="1"/>
                    <polygon points="46,16 50,8 54,16" fill="rgba(0,196,140,0.85)"/>
                    <circle cx="50" cy="4" r="2.5" fill="rgba(0,196,140,0.95)"/>
                    <rect x="17" y="66" width="8" height="11" rx="1.5" fill="rgba(77,159,255,0.3)"/>
                    <rect x="46" y="66" width="8" height="11" rx="1.5" fill="rgba(77,159,255,0.3)"/>
                    <rect x="75" y="66" width="8" height="11" rx="1.5" fill="rgba(77,159,255,0.3)"/>
                  </svg>
                  <div style={{fontSize:10,fontWeight:700,color:SUC,marginBottom:2}}>Features</div>
                  <div style={{fontSize:20,fontWeight:900,color:TS}}>{features.filter((f:any)=>f.enabled).length}/{features.length}</div>
                  <div style={{fontSize:9,color:DIM}}>Enabled</div>
                </div>
              </div>

              {/* Admin Guide + Platform Summary */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16}}>
                <div style={{...cs,background:'linear-gradient(135deg,rgba(0,85,204,0.18),rgba(0,22,40,0.75))'}}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:12,color:ACC}}>🚀 Quick-Start Guide</div>
                  {([['1','Create Batch','Students → Batches','students'],['2','Add Questions','Question Bank → Add','questions'],['3','Create Exam','Exams → Create','create_exam'],['4','Go Live','Live Monitor','live']] as [string,string,string,string][]).map(([n,t,d,tab_])=>(
                    <div key={n} onClick={()=>setTab(tab_)} style={{display:'flex',gap:8,padding:'6px 0',borderBottom:\`1px solid \${BOR}\`,cursor:'pointer'}}>
                      <div style={{width:20,height:20,borderRadius:'50%',background:ACC+'22',border:'1px solid '+ACC+'55',display:'flex',alignItems:'center',justifyContent:'center',fontSize:9,fontWeight:700,color:ACC,flexShrink:0}}>{n}</div>
                      <div><div style={{fontSize:11,fontWeight:600,color:TS}}>{t}</div><div style={{fontSize:9,color:DIM}}>{d}</div></div>
                    </div>
                  ))}
                </div>
                <div style={{...cs,background:'linear-gradient(135deg,rgba(0,100,80,0.15),rgba(0,22,40,0.75))'}}>
                  <div style={{fontWeight:700,marginBottom:10,fontSize:12,color:SUC}}>📋 Platform Summary</div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:6}}>
                    {([['👥',(students||[]).length+' Students',ACC],['📝',(exams||[]).length+' Exams',GOLD],['❓',(questions||[]).length+' Questions','#FF6B9D'],['📦',(batches||[]).length+' Batches','#00E5FF'],['🛡️',(adminUsers||[]).length+' Admins',SUC],['🚩',(flags||[]).length+' Flags',(flags||[]).length>0?DNG:SUC]] as [string,string,string][]).map(([ico,val,col])=>(
                      <div key={val} style={{background:'rgba(0,0,0,0.2)',borderRadius:8,padding:'8px',border:'1px solid '+BOR,textAlign:'center'}}>
                        <div style={{fontSize:16}}>{ico}</div>
                        <div style={{fontSize:10,fontWeight:700,color:col,marginTop:2}}>{val}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Student Journey */}
              <div style={{...cs,background:'linear-gradient(135deg,rgba(77,159,255,0.07),rgba(0,22,40,0.75))'}}>
                <div style={{fontWeight:700,marginBottom:12,fontSize:12,color:TS}}>🎓 Student Journey on ProveRank</div>
                <div style={{display:'flex',alignItems:'flex-start',justifyContent:'space-around',flexWrap:'wrap',gap:4}}>
                  {['📝|Register|Sign up','📚|Practice|PYQ Bank','🎯|Attempt|Live exam','📊|Analyse|AIR Rank','🏆|Achieve|Certificate'].map((item,i,arr)=>{const[ico,t,d]=item.split('|');return(
                    <div key={t} style={{display:'flex',alignItems:'center',gap:3}}>
                      <div style={{textAlign:'center',minWidth:50}}>
                        <div style={{fontSize:18,marginBottom:2}}>{ico}</div>
                        <div style={{fontSize:10,fontWeight:700,color:ACC}}>{t}</div>
                        <div style={{fontSize:8,color:DIM}}>{d}</div>
                      </div>
                      {i<arr.length-1&&<div style={{fontSize:12,color:'rgba(77,159,255,0.3)',marginBottom:10}}>›</div>}
                    </div>
                  )})}
                </div>
              </div>
`;

c = c.slice(0, dci) + EXTRA + c.slice(dci);
console.log('Fix 2 DONE: SVG cards + rich content added');

fs.writeFileSync(FILE, c, 'utf8');
console.log('File saved successfully.');
