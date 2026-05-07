const fs = require('fs');
const FILE = require('path').join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx');
let c = fs.readFileSync(FILE, 'utf8');

// Find draw() start and end dynamically — no hardcoded match
const DRAW_START = '    const draw=()=>{';
const DRAW_END   = '      animId=requestAnimationFrame(draw)\n    }';

const si = c.indexOf(DRAW_START);
const ei = c.indexOf(DRAW_END, si);

if(si === -1){ console.error('ERROR: draw() start not found'); process.exit(1); }
if(ei === -1){ console.error('ERROR: draw() end not found'); process.exit(1); }

console.log('Found draw() at char', si, 'to', ei + DRAW_END.length);
console.log('Current draw() preview:');
console.log(c.slice(si, si+120) + '...');

// Replace entire draw() body with galaxy version
const NEW_DRAW = `    const draw=()=>{
      ctx.clearRect(0,0,canvas.width,canvas.height)
      const W=canvas.width,H=canvas.height
      const bg=ctx.createRadialGradient(W*.5,H*.3,0,W*.5,H*.5,W*.85)
      bg.addColorStop(0,'rgba(4,8,32,1)');bg.addColorStop(.5,'rgba(1,5,18,1)');bg.addColorStop(1,'rgba(0,2,10,1)')
      ctx.fillStyle=bg;ctx.fillRect(0,0,W,H)
      const n1=ctx.createRadialGradient(W*.18,H*.6,0,W*.18,H*.6,W*.35)
      n1.addColorStop(0,'rgba(75,35,155,0.13)');n1.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n1;ctx.fillRect(0,0,W,H)
      const n2=ctx.createRadialGradient(W*.78,H*.18,0,W*.78,H*.18,W*.3)
      n2.addColorStop(0,'rgba(25,75,175,0.14)');n2.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n2;ctx.fillRect(0,0,W,H)
      const n3=ctx.createRadialGradient(W*.85,H*.75,0,W*.85,H*.75,W*.22)
      n3.addColorStop(0,'rgba(0,155,175,0.08)');n3.addColorStop(1,'rgba(0,0,0,0)')
      ctx.fillStyle=n3;ctx.fillRect(0,0,W,H)
      particles.forEach(p=>{
        p.x+=p.vx;p.y+=p.vy
        if(p.x<0)p.x=W;if(p.x>W)p.x=0
        if(p.y<0)p.y=H;if(p.y>H)p.y=0
        ctx.beginPath();ctx.arc(p.x,p.y,p.r,0,Math.PI*2)
        ctx.fillStyle=\`rgba(77,159,255,\${p.opacity})\`;ctx.fill()
      })
      for(let i=0;i<particles.length;i++)for(let j=i+1;j<particles.length;j++){
        const dx=particles[i].x-particles[j].x,dy=particles[i].y-particles[j].y,dist=Math.sqrt(dx*dx+dy*dy)
        if(dist<100){ctx.beginPath();ctx.moveTo(particles[i].x,particles[i].y);ctx.lineTo(particles[j].x,particles[j].y);ctx.strokeStyle=\`rgba(77,159,255,\${.08*(1-dist/100)})\`;ctx.lineWidth=.5;ctx.stroke()}
      }
      animId=requestAnimationFrame(draw)
    }`;

c = c.slice(0, si) + NEW_DRAW + c.slice(ei + DRAW_END.length);
fs.writeFileSync(FILE, c, 'utf8');
console.log('DONE: Galaxy nebula BG applied successfully!');
