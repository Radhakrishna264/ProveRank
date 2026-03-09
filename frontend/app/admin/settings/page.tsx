'use client';
import { useState } from 'react';

export default function SettingsPage() {
  const [settings, setSettings] = useState({
    platformName: 'ProveRank',
    examDuration: 180,
    negativeMarking: true,
    negativeFactor: 0.25,
    allowLateJoin: false,
    autoSubmit: true,
    maxWarnings: 3,
    registrationOpen: true,
    maintenanceMode: false,
  });

  const toggle = (key: keyof typeof settings) => setSettings(s=>({...s,[key]:!s[key]}));

  const ToggleSwitch = ({ enabled, onToggle }: { enabled: boolean; onToggle: ()=>void }) => (
    <div onClick={onToggle} style={{width:44,height:24,borderRadius:12,background:enabled?'#4D9FFF':'#1E3A5F',position:'relative',cursor:'pointer',transition:'background 0.2s',flexShrink:0}}>
      <div style={{position:'absolute',top:2,left:enabled?20:2,width:20,height:20,borderRadius:10,background:'white',transition:'left 0.2s',boxShadow:'0 1px 4px rgba(0,0,0,0.3)'}}/>
    </div>
  );

  return (
    <div style={{padding:'20px 16px',color:'#E8F4FF'}}>
      <h1 style={{fontFamily:'Playfair Display,serif',fontSize:20,fontWeight:700,color:'#E8F4FF',margin:'0 0 20px'}}>⚙️ Settings</h1>

      {/* Platform Settings */}
      <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:14,padding:'16px',marginBottom:16}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:'#4D9FFF',marginBottom:14}}>🏢 Platform</div>
        <div style={{marginBottom:12}}>
          <label style={{fontSize:11,color:'#6B8FAF',display:'block',marginBottom:4}}>PLATFORM NAME</label>
          <input value={settings.platformName} onChange={e=>setSettings(s=>({...s,platformName:e.target.value}))}
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#E8F4FF',fontSize:13,outline:'none',fontFamily:'Inter,sans-serif',boxSizing:'border-box'}}/>
        </div>
        {[
          {l:'Registration Open',k:'registrationOpen' as const},
          {l:'Maintenance Mode',k:'maintenanceMode' as const},
        ].map(({l,k})=>(
          <div key={k} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderTop:'1px solid #002D55'}}>
            <span style={{fontSize:13,color:'#E8F4FF'}}>{l}</span>
            <ToggleSwitch enabled={settings[k] as boolean} onToggle={()=>toggle(k)}/>
          </div>
        ))}
      </div>

      {/* Exam Settings */}
      <div style={{background:'#001628',border:'1px solid #002D55',borderRadius:14,padding:'16px',marginBottom:16}}>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:14,fontWeight:700,color:'#4D9FFF',marginBottom:14}}>📝 Exam Settings</div>
        <div style={{marginBottom:12}}>
          <label style={{fontSize:11,color:'#6B8FAF',display:'block',marginBottom:4}}>DEFAULT DURATION (minutes)</label>
          <input type="number" value={settings.examDuration} onChange={e=>setSettings(s=>({...s,examDuration:+e.target.value}))}
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#E8F4FF',fontSize:13,outline:'none',fontFamily:'Inter,sans-serif',boxSizing:'border-box'}}/>
        </div>
        <div style={{marginBottom:12}}>
          <label style={{fontSize:11,color:'#6B8FAF',display:'block',marginBottom:4}}>MAX WARNINGS BEFORE AUTO-SUBMIT</label>
          <input type="number" value={settings.maxWarnings} onChange={e=>setSettings(s=>({...s,maxWarnings:+e.target.value}))}
            style={{width:'100%',padding:'10px 12px',background:'rgba(0,22,40,0.8)',border:'1px solid #002D55',borderRadius:8,color:'#E8F4FF',fontSize:13,outline:'none',fontFamily:'Inter,sans-serif',boxSizing:'border-box'}}/>
        </div>
        {[
          {l:'Negative Marking',k:'negativeMarking' as const},
          {l:'Allow Late Join',k:'allowLateJoin' as const},
          {l:'Auto Submit on Time Up',k:'autoSubmit' as const},
        ].map(({l,k})=>(
          <div key={k} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderTop:'1px solid #002D55'}}>
            <span style={{fontSize:13,color:'#E8F4FF'}}>{l}</span>
            <ToggleSwitch enabled={settings[k] as boolean} onToggle={()=>toggle(k)}/>
          </div>
        ))}
      </div>

      {/* Save Button */}
      <button style={{width:'100%',padding:14,background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:12,color:'white',fontSize:15,fontWeight:700,cursor:'pointer',fontFamily:'Inter,sans-serif'}}>
        💾 Save Settings
      </button>
    </div>
  );
}
