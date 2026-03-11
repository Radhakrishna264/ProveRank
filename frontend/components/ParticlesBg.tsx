'use client'
import { useRef, useEffect } from 'react'

function ParticlesBg() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = canvasRef.current; if (!canvas) return;
    const ctx = canvas.getContext('2d'); if (!ctx) return;
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;
    const particles: {x:number;y:number;vx:number;vy:number;r:number;opacity:number}[] = [];
    for (let i=0; i<80; i++) {
      particles.push({
        x: Math.random()*canvas.width,
        y: Math.random()*canvas.height,
        vx: (Math.random()-.5)*.4,
        vy: (Math.random()-.5)*.4,
        r:  Math.random()*2+1,
        opacity: Math.random()*.5+.1
      });
    }
    let animId: number;
    const draw = () => {
      ctx.clearRect(0,0,canvas.width,canvas.height);
      particles.forEach(p=>{
        p.x+=p.vx; p.y+=p.vy;
        if(p.x<0)p.x=canvas.width;
        if(p.x>canvas.width)p.x=0;
        if(p.y<0)p.y=canvas.height;
        if(p.y>canvas.height)p.y=0;
        ctx.beginPath();
        ctx.arc(p.x,p.y,p.r,0,Math.PI*2);
        ctx.fillStyle=`rgba(77,159,255,${p.opacity})`;
        ctx.fill();
      });
      for(let i=0;i<particles.length;i++)
        for(let j=i+1;j<particles.length;j++){
          const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y;
          const dist=Math.sqrt(dx*dx+dy*dy);
          if(dist<120){
            ctx.beginPath();
            ctx.moveTo(particles[i].x,particles[i].y);
            ctx.lineTo(particles[j].x,particles[j].y);
            ctx.strokeStyle=`rgba(77,159,255,${.12*(1-dist/120)})`;
            ctx.lineWidth=.5; ctx.stroke();
          }
        }
      animId=requestAnimationFrame(draw);
    };
    draw();
    const resize=()=>{canvas.width=window.innerWidth;canvas.height=window.innerHeight;};
    window.addEventListener('resize',resize);
    return ()=>{ cancelAnimationFrame(animId); window.removeEventListener('resize',resize); };
  },[]);
  return <canvas ref={canvasRef} style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:0}}/>;
}

export default ParticlesBg;
