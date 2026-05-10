const fs = require('fs');
const fp = 'page.tsx';
let lines = fs.readFileSync(fp, 'utf8').split('\n');

let mapIdx = -1;
for(let i = 0; i < lines.length; i++){
  if(lines[i].includes('(adminUsers||[]).map(a=>(')){
    mapIdx = i;
    lines[i] = lines[i].replace('(adminUsers||[]).map(a=>(','(adminUsers||[]).map(au=>(');
    console.log('Fixed map param at L'+(i+1));
    break;
  }
}
if(mapIdx === -1){
  for(let i = 0; i < lines.length; i++){
    if(lines[i].includes('adminUsers') && lines[i].includes('.map(au=>')){
      mapIdx = i;
      console.log('Map already au at L'+(i+1));
      break;
    }
  }
}
if(mapIdx >= 0){
  for(let i = mapIdx; i < Math.min(mapIdx+40, lines.length); i++){
    const l = lines[i];
    if(!l.includes('p.map') && !l.includes('p.filter')){
      if(l.includes('key={a._id}')){ lines[i]=lines[i].replace('key={a._id}','key={au._id}'); console.log('key L'+(i+1)); }
      if(l.includes('>{a.name}<')){ lines[i]=lines[i].replace('>{a.name}<','>{au.name}<'); console.log('name L'+(i+1)); }
      if(l.includes('>{a.email}<')){ lines[i]=lines[i].replace('>{a.email}<','>{au.email}<'); console.log('email L'+(i+1)); }
      if(l.includes('label={a.role}')){ lines[i]=lines[i].replace('label={a.role}','label={au.role}').replace("a.role==='superadmin'","au.role==='superadmin'"); console.log('role L'+(i+1)); }
    }
  }
}
fs.writeFileSync(fp, lines.join('\n'));
console.log('DONE. Verifying...');
[506,535,2242,2244,2246,2248,2250].forEach(n=>{ if(lines[n-1]) console.log('L'+n+': '+lines[n-1].trim().substring(0,90)); });
