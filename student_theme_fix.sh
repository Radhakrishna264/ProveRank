#!/bin/bash
# ═══════════════════════════════════════════════════
#  ProveRank — Student Theme System (FIXED VERSION)
#  Backtick issue fixed using heredoc format
# ═══════════════════════════════════════════════════
set -e

echo "🎨 Theme System — Fixed Script"

# ── Locate files ──────────────────────────────────
SHELL_F=$(find . -path "*/src/components/StudentShell.tsx" | grep -v node_modules | head -1)
LOGIN_F=$(find . -path "*/app/login/page.tsx"              | grep -v node_modules | head -1)
REG_F=$(  find . -path "*/app/register/page.tsx"           | grep -v node_modules | head -1)
TERMS_F=$(find . -path "*/app/terms/page.tsx"              | grep -v node_modules | head -1)
PROF_F=$( find . -path "*/dashboard/profile/page.tsx"      | grep -v node_modules | head -1)
CSS_F=$(  find . -name "globals.css"                       | grep -v node_modules | head -1)

echo "StudentShell : $SHELL_F"
echo "Login        : $LOGIN_F"
echo "Register     : $REG_F"
echo "Terms        : $TERMS_F"
echo "Profile      : $PROF_F"
echo "globals.css  : $CSS_F"

# ── Restore backups (from failed previous run) ────
for f in "$SHELL_F" "$LOGIN_F" "$REG_F" "$TERMS_F" "$PROF_F" "$CSS_F"; do
  if [ -f "${f}.bak_theme" ]; then
    cp "${f}.bak_theme" "$f"
    echo "♻️  Restored: $f"
  elif [ -f "$f" ]; then
    cp "$f" "${f}.bak_theme"
    echo "📦 Backed up: $f"
  fi
done

# ════════════════════════════════════════════════════
# 1. PATCH — StudentShell.tsx
# ════════════════════════════════════════════════════
export SHELL_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.SHELL_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  StudentShell not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');

// 1. ColorTheme type + ShellCtx interface
c = c.replace(
  "export interface ShellCtx{lang:'en'|'hi';darkMode:boolean;user:any;toast:(m:string,t?:'s'|'e'|'w')=>void;token:string;role:string}",
  "export type ColorTheme='white'|'dark'|'teal'\nexport interface ShellCtx{lang:'en'|'hi';darkMode:boolean;colorTheme:ColorTheme;theme:any;setColorTheme:(t:ColorTheme)=>void;user:any;toast:(m:string,t?:'s'|'e'|'w')=>void;token:string;role:string}"
);

// 2. createContext default
c = c.replace(
  "createContext<ShellCtx>({lang:'en',darkMode:true,user:null,toast:()=>{},token:'',role:'student'})",
  "createContext<ShellCtx>({lang:'en',darkMode:true,colorTheme:'dark',theme:{primary:'#4D9FFF'},setColorTheme:()=>{},user:null,toast:()=>{},token:'',role:'student'})"
);

// 3. Replace hardcoded dm=true
c = c.replace(
  "  const dm=true",
  "  const [colorTheme,setColorThemeState]=useState<ColorTheme>('dark')"
);

// 4. Read pr_color_theme in useEffect
c = c.replace(
  "try{const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null;if(sl)setLang(sl);}catch{}",
  "try{const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null;if(sl)setLang(sl);const ct=localStorage.getItem('pr_color_theme') as ColorTheme|null;if(ct&&['white','dark','teal'].includes(ct))setColorThemeState(ct);}catch{}\n    const _onTh=(e:StorageEvent)=>{if(e.key==='pr_color_theme'&&e.newValue&&['white','dark','teal'].includes(e.newValue))setColorThemeState(e.newValue as ColorTheme)};window.addEventListener('storage',_onTh)"
);

// 5. Add THEMES + compute th (replace bg/bdr/txt/sub lines)
c = c.replace(
  "  const bg='radial-gradient(ellipse at 15% 55%,#001020 0%,#000A18 50%,#000308 100%)'\n  const bdr=dm?C.border:C.borderL,txt=dm?C.text:C.textL,sub=dm?C.sub:C.subL",
  [
    "  // Color Theme System",
    "  const _TH:Record<string,any>={",
    "    white:{shellBg:'#FFFFFF',headerBg:'rgba(240,247,255,0.97)',sidebarBg:'rgba(240,247,255,0.97)',primary:'#2563EB',text:'#0F172A',sub:'#64748B',border:'rgba(37,99,235,0.15)',navActive:'rgba(37,99,235,0.1)',isDark:false,showGalaxy:false,hexC:'rgba(37,99,235,0.03)'},",
    "    dark:{shellBg:'#0A0A0A',headerBg:'rgba(17,17,17,0.97)',sidebarBg:'rgba(17,17,17,0.97)',primary:'#4D9FFF',text:'#FFFFFF',sub:'#9CA3AF',border:'rgba(77,159,255,0.12)',navActive:'rgba(77,159,255,0.12)',isDark:true,showGalaxy:false,hexC:'rgba(77,159,255,0.022)'},",
    "    teal:{shellBg:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)',headerBg:'rgba(0,26,26,0.96)',sidebarBg:'rgba(0,40,35,0.97)',primary:'#2DD4BF',text:'#CCFBF1',sub:'#5EEAD4',border:'rgba(45,212,191,0.18)',navActive:'rgba(45,212,191,0.14)',isDark:true,showGalaxy:true,hexC:'rgba(45,212,191,0.022)'},",
    "  }",
    "  const _isTS=['test-series','batches'].includes(pageKey)",
    "  const _tsDef={shellBg:'#020816',headerBg:'rgba(0,5,18,.95)',sidebarBg:'rgba(0,5,18,.97)',primary:'#4D9FFF',text:'#E8F4FF',sub:'#6B8FAF',border:C.border,navActive:'rgba(77,159,255,.16)',isDark:true,showGalaxy:true,hexC:'rgba(77,159,255,.022)'}",
    "  const th=_isTS?_tsDef:(_TH[colorTheme]||_TH.dark)",
    "  const dm=th.isDark",
    "  const setColorTheme=(t:ColorTheme)=>{setColorThemeState(t);try{localStorage.setItem('pr_color_theme',t);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:t}))}catch{}}",
    "  const bdr=th.border,txt=th.text,sub=th.sub",
  ].join('\n')
);

// 6. ShellCtx.Provider value
c = c.replace(
  "<ShellCtx.Provider value={{lang,darkMode:dm,user,toast,token,role}}>",
  "<ShellCtx.Provider value={{lang,darkMode:dm,colorTheme:_isTS?'dark':colorTheme,theme:th,setColorTheme,user,toast,token,role}}>"
);

// 7. Container div background
c = c.replace(
  "<div style={{minHeight:'100vh',background:'#020816',color:txt,",
  "<div data-color-theme={_isTS?'dark':colorTheme} style={{minHeight:'100vh',background:th.shellBg,color:txt,"
);

// 8. Conditional GalaxyBg
c = c.replace(
  '        <GalaxyBg/>',
  '        {th.showGalaxy&&<GalaxyBg/>}'
);

// 9. Hexagon decorations color
c = c.replace(
  "style={{position:'fixed',top:-70,left:-70,fontSize:320,color:'rgba(77,159,255,.022)'",
  "style={{position:'fixed',top:-70,left:-70,fontSize:320,color:th.hexC"
);
c = c.replace(
  "style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:'rgba(77,159,255,.022)'",
  "style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:th.hexC"
);

// 10. Sidebar background
c = c.replace(
  "background:'rgba(0,5,18,.97)',borderRight:",
  "background:th.sidebarBg,borderRight:"
);

// 11. Sidebar sticky header
c = c.replace(
  "background:'rgba(0,5,18,.97)',flexShrink:0",
  "background:th.sidebarBg,flexShrink:0"
);

// 12. Header background
c = c.replace(
  "background:dm?'rgba(0,5,18,.95)':'rgba(224,239,255,.96)'",
  "background:th.headerBg"
);

// 13. Nav link colors — use string concat (NOT template literal, avoids backtick issue)
c = c.replace(
  "color:pageKey===n.id?'#4D9FFF':sub",
  "color:pageKey===n.id?th.primary:sub"
);
c = c.replace(
  "background:pageKey===n.id?'rgba(77,159,255,.16)':'transparent'",
  "background:pageKey===n.id?th.navActive:'transparent'"
);
// Nav border — use string concat instead of template literal
c = c.replace(
  "borderLeft:pageKey===n.id?'3px solid #4D9FFF':'3px solid transparent'",
  "borderLeft:pageKey===n.id?('3px solid '+th.primary):'3px solid transparent'"
);
// Nav active dot
c = c.replace(
  "background:'#4D9FFF',flexShrink:0",
  "background:th.primary,flexShrink:0"
);

fs.writeFileSync(f, c);
console.log('✅ StudentShell.tsx patched');

// Quick verify
const v = fs.readFileSync(f,'utf8');
console.log('  ColorTheme type:', v.includes("export type ColorTheme='white'|'dark'|'teal'") ? '✅':'❌');
console.log('  THEMES (_TH):', v.includes('const _TH') ? '✅':'❌');
console.log('  showGalaxy cond:', v.includes('th.showGalaxy&&<GalaxyBg') ? '✅':'❌');
console.log('  th.shellBg bg:', v.includes('background:th.shellBg') ? '✅':'❌');
console.log('  th.headerBg:', v.includes('background:th.headerBg') ? '✅':'❌');
JSEOF

# ════════════════════════════════════════════════════
# 2. PATCH — globals.css
# ════════════════════════════════════════════════════
export CSS_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.CSS_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  globals.css not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');
if(c.includes('teal-color-theme')){console.log('ℹ️  Already patched');process.exit(0);}

c += `
/* ═══════════════════════════════════════════════════
   PROVERANK 3-THEME SYSTEM (student pages)
   Controlled via [data-color-theme] on container
   ═══════════════════════════════════════════════════ */

[data-color-theme='teal'] { --teal-color-theme: 1; }
[data-color-theme='teal'] ::-webkit-scrollbar-thumb { background: rgba(45,212,191,0.4) !important; }
[data-color-theme='teal'] input,
[data-color-theme='teal'] select,
[data-color-theme='teal'] textarea { color-scheme: dark; accent-color: #2DD4BF; }
[data-color-theme='teal'] .nav-lnk:hover  { background: rgba(45,212,191,0.14) !important; color: #2DD4BF !important; }
[data-color-theme='teal'] .btn-p { background: linear-gradient(135deg,#2DD4BF,#0D9488) !important; }
[data-color-theme='teal'] .tbtn  { border-color: rgba(45,212,191,0.35) !important; color: #CCFBF1 !important; }
[data-color-theme='teal'] .tbtn:hover { border-color: #2DD4BF !important; background: rgba(45,212,191,0.14) !important; }

[data-color-theme='dark'] ::-webkit-scrollbar-thumb { background: rgba(77,159,255,0.35) !important; }
[data-color-theme='dark'] input,
[data-color-theme='dark'] select,
[data-color-theme='dark'] textarea { color-scheme: dark; accent-color: #4D9FFF; }

[data-color-theme='white'] ::-webkit-scrollbar-thumb { background: rgba(37,99,235,0.3) !important; }
[data-color-theme='white'] input,
[data-color-theme='white'] select,
[data-color-theme='white'] textarea { color-scheme: light; accent-color: #2563EB; }
[data-color-theme='white'] .nav-lnk:hover  { background: rgba(37,99,235,0.1) !important; color: #2563EB !important; }
[data-color-theme='white'] .btn-p { background: linear-gradient(135deg,#2563EB,#1D4ED8) !important; }
[data-color-theme='white'] .tbtn  { border-color: rgba(37,99,235,0.35) !important; color: #0F172A !important; }
[data-color-theme='white'] .tbtn:hover { border-color: #2563EB !important; background: rgba(37,99,235,0.1) !important; }
[data-color-theme='white'] .pr-card,
[data-color-theme='white'] .stat-card { background: rgba(255,255,255,0.97) !important; border-color: rgba(0,0,0,0.06) !important; box-shadow: 0 4px 24px rgba(0,0,0,0.07) !important; }
`;

fs.writeFileSync(f, c);
console.log('✅ globals.css — 3-theme CSS added');
JSEOF

# ════════════════════════════════════════════════════
# 3. PATCH — Auth Pages → Neon Teal
# ════════════════════════════════════════════════════
export LOGIN_F REG_F TERMS_F
node << 'JSEOF'
const fs = require('fs');

function tealify(filePath, name) {
  if(!filePath||!fs.existsSync(filePath)){console.log('⚠️  Not found: '+name);return;}
  let c = fs.readFileSync(filePath,'utf8');

  // Color constants
  c = c.replace(
    "const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',SUB='#6B8FAF',TXT='#E8F4FF'",
    "const PRI='#2DD4BF',SUC='#00C48C',DNG='#FF4D4D',SUB='#5EEAD4',TXT='#CCFBF1' // Neon Teal"
  );
  // Input style
  c = c.replace(
    "background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)'",
    "background:'rgba(0,20,18,.85)',border:'1.5px solid rgba(0,200,160,.3)'"
  );
  // Outer div backgrounds
  c = c.replace(
    "background:'radial-gradient(ellipse at 20% 50%,#000D1A,#000308 60%,#00010A)'",
    "background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'"
  );
  c = c.replace(
    "background:'radial-gradient(ellipse at 80% 40%,#000D1A,#000510 55%,#000108)'",
    "background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'"
  );
  c = c.replace(
    "background:'radial-gradient(ellipse at 20% 50%,#000D1A 0%,#000510 60%,#000108 100%)'",
    "background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'"
  );
  // Card bg + border
  c = c.replace(/background:'rgba\(0,22,40,\.88\)',border:'1px solid rgba\(77,159,255,\.28\)'/g,
    "background:'rgba(0,35,30,.88)',border:'1px solid rgba(0,200,160,.28)'"
  );
  // Logo gradient text
  c = c.replace(
    "background:'linear-gradient(90deg,#4D9FFF,#00D4FF)'",
    "background:'linear-gradient(90deg,#2DD4BF,#00F0D4)'"
  );
  // Button gradients
  c = c.replace(/linear-gradient\(135deg,#4D9FFF,#0055CC\)/g,'linear-gradient(135deg,#2DD4BF,#0D9488)');

  fs.writeFileSync(filePath, c);
  console.log('✅ '+name+' — Neon Teal applied');
}

tealify(process.env.LOGIN_F, 'Login');
tealify(process.env.REG_F,   'Register');
tealify(process.env.TERMS_F, 'Terms');
JSEOF

# ════════════════════════════════════════════════════
# 4. PATCH — Profile Page → Theme Picker
# ════════════════════════════════════════════════════
export PROF_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.PROF_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  Profile not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');
if(c.includes('pr_color_theme')){console.log('ℹ️  Theme picker already present');process.exit(0);}

// A. Add activeTheme state after first useState in ProfileContent
const ST = 'const [tab,setTab]=useState';
if(c.includes(ST)){
  c = c.replace(ST,
    "const [activeTheme,setActiveTheme]=useState<'white'|'dark'|'teal'>('dark')\n" +
    "  useEffect(()=>{try{const t=localStorage.getItem('pr_color_theme') as any;if(t)setActiveTheme(t)}catch{}}",[])+
    "\n  const applyTheme=(t:'white'|'dark'|'teal')=>{setActiveTheme(t);try{localStorage.setItem('pr_color_theme',t);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:t}))}catch{}}\n  "+ST
  );
}

// B. Theme picker UI block
const PICKER = `
          {/* 🎨 Theme Picker */}
          <div style={{borderTop:'1px solid '+C.border,paddingTop:18,marginTop:6}}>
            <div style={{fontSize:13,fontWeight:700,color:C.primary,marginBottom:14}}>🎨 {t('App Color Theme','ऐप कलर थीम')}</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10}}>
              {([
                {id:'white',lbl:t('Pure White','शुद्ध सफेद'),sub:'Bright & Clean',bg:'#FFFFFF',acc:'#2563EB',ico:'☀️'},
                {id:'dark', lbl:t('Pure Dark','शुद्ध काला'), sub:'Bold & Dark',  bg:'#0A0A0A',acc:'#4D9FFF',ico:'🌑'},
                {id:'teal', lbl:t('Neon Teal','नियॉन टील'),  sub:'Deep & Vibrant',bg:'linear-gradient(135deg,#001A1A,#002E2E)',acc:'#2DD4BF',ico:'🌊'},
              ]).map((th)=>{
                const act=activeTheme===th.id
                return(
                  <button key={th.id} onClick={()=>applyTheme(th.id as any)}
                    style={{background:th.bg,border:'2px solid '+(act?th.acc:'rgba(255,255,255,0.08)'),borderRadius:14,padding:'14px 8px',cursor:'pointer',textAlign:'center',boxShadow:act?'0 0 20px '+th.acc+'55':'none',transition:'all .25s',position:'relative',minHeight:90}}>
                    {act&&<span style={{position:'absolute',top:6,right:8,fontSize:10,color:th.acc,fontWeight:800}}>✓</span>}
                    <div style={{fontSize:22,marginBottom:6}}>{th.ico}</div>
                    <div style={{fontSize:11,fontWeight:700,color:th.acc}}>{th.lbl}</div>
                    <div style={{fontSize:9,marginTop:3,color:'rgba(255,255,255,0.4)'}}>{th.sub}</div>
                  </button>
                )
              })}
            </div>
            <div style={{fontSize:10,color:C.sub,textAlign:'center',marginTop:10}}>
              {t('Applies to all pages. Test Series uses default theme.','सभी पेजों पर लागू। टेस्ट सीरीज डिफ़ॉल्ट थीम रखता है।')}
            </div>
          </div>`;

// Inject before closing of prefs tab
const END_PREFS = "          ))}\n        </div>\n      )}";
if(c.includes(END_PREFS)){
  c = c.replace(END_PREFS, "          ))}" + PICKER + "\n        </div>\n      )}");
  fs.writeFileSync(f, c);
  console.log('✅ Profile page — Theme picker added');
} else {
  // Fallback injection before Login History
  const FB = '{/* ── Login History ── */}';
  if(c.includes(FB)){
    const block = "      {tab==='prefs'&&(\n        <div style={{marginTop:16,background:'rgba(0,35,30,0.08)',border:'1px solid rgba(45,212,191,0.15)',borderRadius:14,padding:18}}>\n" + PICKER + "\n        </div>\n      )}\n\n      ";
    c = c.replace(FB, block + FB);
    fs.writeFileSync(f, c);
    console.log('✅ Profile page — Theme picker added (fallback)');
  } else {
    console.log('⚠️  Could not inject in profile page');
  }
}
JSEOF

# ════════════════════════════════════════════════════
# VERIFY
# ════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════════"
echo "  🔍 Final Verification"
echo "══════════════════════════════════════════════"
export SHELL_F LOGIN_F REG_F TERMS_F PROF_F CSS_F
node << 'JSEOF'
const fs = require('fs');
const rd = (f) => (f&&fs.existsSync(f))?fs.readFileSync(f,'utf8'):'';
const sh=rd(process.env.SHELL_F), lo=rd(process.env.LOGIN_F),
      re=rd(process.env.REG_F),   pr=rd(process.env.PROF_F),
      css=rd(process.env.CSS_F);

const checks=[
  ['StudentShell: ColorTheme type',          sh.includes("export type ColorTheme='white'|'dark'|'teal'")],
  ['StudentShell: colorTheme state',         sh.includes('setColorThemeState')],
  ['StudentShell: _TH themes defined',       sh.includes('const _TH')],
  ['StudentShell: Test Series excluded',     sh.includes('_isTS')],
  ['StudentShell: GalaxyBg conditional',     sh.includes('th.showGalaxy&&<GalaxyBg')],
  ['StudentShell: shellBg applied',          sh.includes('background:th.shellBg')],
  ['StudentShell: headerBg applied',         sh.includes('background:th.headerBg')],
  ['StudentShell: sidebarBg applied',        sh.includes('background:th.sidebarBg')],
  ['StudentShell: nav uses th.primary',      sh.includes('th.primary')],
  ['StudentShell: ShellCtx has colorTheme',  sh.includes('setColorTheme,user')],
  ['Login: Teal PRI color',                  lo.includes("PRI='#2DD4BF'")],
  ['Login: Teal background',                 lo.includes('#001A1A')],
  ['Register: Teal PRI color',               re.includes("PRI='#2DD4BF'")],
  ['Profile: activeTheme state',             pr.includes('activeTheme')],
  ['Profile: applyTheme function',           pr.includes('applyTheme')],
  ['Profile: theme picker UI',               pr.includes('Neon Teal')||pr.includes('Pure White')],
  ['Profile: saves pr_color_theme',          pr.includes("'pr_color_theme'")],
  ['globals.css: teal theme CSS',            css.includes("teal-color-theme")||css.includes("data-color-theme='teal'")],
  ['globals.css: white theme CSS',           css.includes("data-color-theme='white'")],
];

let pass=0,fail=0;
checks.forEach(([l,v])=>{console.log((v?'✅':'❌')+' '+l);v?pass++:fail++;});
console.log('\n'+pass+'/'+checks.length+' passed');
if(fail===0){
  console.log('\n🎉 ALL DONE! Now run:');
  console.log("git add . && git commit -m 'feat: Student 3-color theme system' && git push");
}else{
  console.log('⚠️  '+fail+' issue(s) — screenshot bhejo');
}
JSEOF
