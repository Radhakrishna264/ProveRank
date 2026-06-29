#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  ProveRank — Student Color Theme System
#  3 Themes: Pure White / Pure Dark / Neon Teal
#  Auth pages: Neon Teal hardcoded
#  Student pages: controlled from Profile > Preferences
#  Test Series page: EXCLUDED (keeps current Galaxy BG)
# ═══════════════════════════════════════════════════════════════════
set -e

echo "🎨 ProveRank Student Theme System — Starting..."

# ── Locate files ────────────────────────────────────────────────
SHELL_F=$(find . -path "*/src/components/StudentShell.tsx"  | grep -v node_modules | head -1)
LOGIN_F=$(find . -path "*/app/login/page.tsx"               | grep -v node_modules | head -1)
REG_F=$(  find . -path "*/app/register/page.tsx"            | grep -v node_modules | head -1)
TERMS_F=$(find . -path "*/app/terms/page.tsx"               | grep -v node_modules | head -1)
PROF_F=$( find . -path "*/dashboard/profile/page.tsx"       | grep -v node_modules | head -1)
CSS_F=$(  find . -name "globals.css"                        | grep -v node_modules | head -1)

echo "StudentShell : $SHELL_F"
echo "Login        : $LOGIN_F"
echo "Register     : $REG_F"
echo "Terms        : $TERMS_F"
echo "Profile      : $PROF_F"
echo "globals.css  : $CSS_F"
echo ""

# ── Backup all ──────────────────────────────────────────────────
for f in "$SHELL_F" "$LOGIN_F" "$REG_F" "$TERMS_F" "$PROF_F" "$CSS_F"; do
  [ -f "$f" ] && cp "$f" "${f}.bak_theme"
done
echo "✅ Backups created"

# ════════════════════════════════════════════════════════════════
# 1. PATCH — StudentShell.tsx (Theme System Core)
# ════════════════════════════════════════════════════════════════
export SHELL_F
node -e "
const fs = require('fs');
const f  = process.env.SHELL_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  StudentShell not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');

// ── 1. Add ColorTheme type + update ShellCtx interface ──────
c = c.replace(
  \"export interface ShellCtx{lang:'en'|'hi';darkMode:boolean;user:any;toast:(m:string,t?:'s'|'e'|'w')=>void;token:string;role:string}\",
  \`export type ColorTheme='white'|'dark'|'teal'
export interface ShellCtx{lang:'en'|'hi';darkMode:boolean;colorTheme:ColorTheme;theme:any;setColorTheme:(t:ColorTheme)=>void;user:any;toast:(m:string,t?:'s'|'e'|'w')=>void;token:string;role:string}\`
);

// ── 2. Update createContext default ────────────────────────
c = c.replace(
  \"createContext<ShellCtx>({lang:'en',darkMode:true,user:null,toast:()=>{},token:'',role:'student'})\",
  \"createContext<ShellCtx>({lang:'en',darkMode:true,colorTheme:'dark',theme:{primary:'#4D9FFF'},setColorTheme:()=>{},user:null,toast:()=>{},token:'',role:'student'})\"
);

// ── 3. Replace hardcoded dm=true with colorTheme state ─────
c = c.replace(
  '  const dm=true',
  \"  const [colorTheme,setColorThemeState]=useState<ColorTheme>('dark')\"
);

// ── 4. Read pr_color_theme in useEffect ───────────────────
c = c.replace(
  \"try{const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null;if(sl)setLang(sl);}catch{}\",
  \`try{
      const sl=localStorage.getItem('pr_lang') as 'en'|'hi'|null;
      if(sl)setLang(sl);
      const ct=localStorage.getItem('pr_color_theme') as ColorTheme|null;
      if(ct&&['white','dark','teal'].includes(ct))setColorThemeState(ct);
    }catch{}
    const _onTheme=(e:StorageEvent)=>{
      if(e.key==='pr_color_theme'&&e.newValue&&['white','dark','teal'].includes(e.newValue))
        setColorThemeState(e.newValue as ColorTheme);
    };
    window.addEventListener('storage',_onTheme);\`
);

// ── 5. Add THEMES + compute th before render ───────────────
c = c.replace(
  \"  const bg='radial-gradient(ellipse at 15% 55%,#001020 0%,#000A18 50%,#000308 100%)'\n  const bdr=dm?C.border:C.borderL,txt=dm?C.text:C.textL,sub=dm?C.sub:C.subL\",
  \`  // ── Color Theme System ────────────────────────────────
  const _TH:Record<string,any>={
    white:{
      shellBg:'#FFFFFF',headerBg:'rgba(240,247,255,0.97)',
      sidebarBg:'rgba(240,247,255,0.97)',sidebarBg2:'rgba(240,247,255,0.97)',
      primary:'#2563EB',text:'#0F172A',sub:'#64748B',
      border:'rgba(37,99,235,0.15)',navActive:'rgba(37,99,235,0.1)',
      isDark:false,showGalaxy:false,hexColor:'rgba(37,99,235,0.04)',
    },
    dark:{
      shellBg:'#0A0A0A',headerBg:'rgba(17,17,17,0.97)',
      sidebarBg:'rgba(17,17,17,0.97)',sidebarBg2:'rgba(17,17,17,0.97)',
      primary:'#4D9FFF',text:'#FFFFFF',sub:'#9CA3AF',
      border:'rgba(77,159,255,0.12)',navActive:'rgba(77,159,255,0.12)',
      isDark:true,showGalaxy:false,hexColor:'rgba(77,159,255,0.022)',
    },
    teal:{
      shellBg:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)',
      headerBg:'rgba(0,26,26,0.96)',
      sidebarBg:'rgba(0,40,35,0.97)',sidebarBg2:'rgba(0,40,35,0.97)',
      primary:'#2DD4BF',text:'#CCFBF1',sub:'#5EEAD4',
      border:'rgba(45,212,191,0.18)',navActive:'rgba(45,212,191,0.14)',
      isDark:true,showGalaxy:true,hexColor:'rgba(45,212,191,0.022)',
    },
  }
  const _isTS=['test-series','batches'].includes(pageKey)
  const th=_isTS?{
    shellBg:'#020816',headerBg:'rgba(0,5,18,.95)',sidebarBg:'rgba(0,5,18,.97)',sidebarBg2:'rgba(0,5,18,.97)',
    primary:'#4D9FFF',text:'#E8F4FF',sub:'#6B8FAF',border:C.border,
    navActive:'rgba(77,159,255,.16)',isDark:true,showGalaxy:true,hexColor:'rgba(77,159,255,.022)',
  }:(_TH[colorTheme]||_TH.dark)
  const dm=th.isDark
  const setColorTheme=(t:ColorTheme)=>{setColorThemeState(t);try{localStorage.setItem('pr_color_theme',t);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:t}))}catch{}}
  const bdr=th.border,txt=th.text,sub=th.sub\`
);

// ── 6. Update ShellCtx.Provider value ─────────────────────
c = c.replace(
  \"<ShellCtx.Provider value={{lang,darkMode:dm,user,toast,token,role}}>\",
  \"<ShellCtx.Provider value={{lang,darkMode:dm,colorTheme:_isTS?'dark':colorTheme,theme:th,setColorTheme,user,toast,token,role}}>\"
);

// ── 7. Container div background ───────────────────────────
c = c.replace(
  \"<div style={{minHeight:'100vh',background:'#020816',color:txt,\",
  \"<div data-color-theme={_isTS?'dark':colorTheme} style={{minHeight:'100vh',background:th.shellBg,color:txt,\"
);

// ── 8. Conditional GalaxyBg ───────────────────────────────
c = c.replace(
  '        <GalaxyBg/>',
  '        {th.showGalaxy&&<GalaxyBg/>}'
);

// ── 9. Hexagon decorations: use theme color ────────────────
c = c.replace(
  \"style={{position:'fixed',top:-70,left:-70,fontSize:320,color:'rgba(77,159,255,.022)'\",
  \"style={{position:'fixed',top:-70,left:-70,fontSize:320,color:th.hexColor\"
);
c = c.replace(
  \"style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:'rgba(77,159,255,.022)'\",
  \"style={{position:'fixed',bottom:-70,right:-70,fontSize:320,color:th.hexColor\"
);

// ── 10. Sidebar background ────────────────────────────────
c = c.replace(
  \"background:'rgba(0,5,18,.97)',borderRight:\",
  'background:th.sidebarBg,borderRight:'
);

// ── 11. Sidebar sticky header bg ─────────────────────────
c = c.replace(
  \"background:'rgba(0,5,18,.97)',flexShrink:0\",
  'background:th.sidebarBg2,flexShrink:0'
);

// ── 12. Header background ─────────────────────────────────
c = c.replace(
  \"background:dm?'rgba(0,5,18,.95)':'rgba(224,239,255,.96)'\",
  'background:th.headerBg'
);

// ── 13. Nav link active colors ────────────────────────────
c = c.replace(
  \"color:pageKey===n.id?'#4D9FFF':sub\",
  'color:pageKey===n.id?th.primary:sub'
);
c = c.replace(
  \"background:pageKey===n.id?'rgba(77,159,255,.16)':'transparent'\",
  \"background:pageKey===n.id?th.navActive:'transparent'\"
);
c = c.replace(
  \"borderLeft:pageKey===n.id?'3px solid #4D9FFF':'3px solid transparent'\",
  \`borderLeft:pageKey===n.id?\`3px solid \${th.primary}\`:'3px solid transparent'\`
);
// Nav active dot
c = c.replace(
  \"background:'#4D9FFF',flexShrink:0\",
  'background:th.primary,flexShrink:0'
);

fs.writeFileSync(f, c);
console.log('✅ StudentShell.tsx patched — theme system added');
" 2>&1

# ════════════════════════════════════════════════════════════════
# 2. PATCH — globals.css (add teal + white + dark-pure scrollbars)
# ════════════════════════════════════════════════════════════════
export CSS_F
node -e "
const fs = require('fs');
const f  = process.env.CSS_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  globals.css not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');

if(c.includes('teal-color-theme')){
  console.log('ℹ️  globals.css already has teal theme');process.exit(0);
}

const APPEND = \`
/* ═══════════════════════════════════════════════════════════════
   PROVERANK — 3-COLOR THEME SYSTEM (student pages)
   Controlled via [data-color-theme] on container div
   ═══════════════════════════════════════════════════════════════ */

/* ── Neon Teal Theme ────────────────────────────────────────── */
[data-color-theme='teal'] ::-webkit-scrollbar-thumb { background: rgba(45,212,191,0.4) !important; }
[data-color-theme='teal'] input,
[data-color-theme='teal'] select,
[data-color-theme='teal'] textarea { color-scheme: dark; accent-color: #2DD4BF; }
[data-color-theme='teal'] .nav-lnk:hover { background: rgba(45,212,191,0.14) !important; color: #2DD4BF !important; }
[data-color-theme='teal'] .btn-p { background: linear-gradient(135deg,#2DD4BF,#0D9488) !important; }
[data-color-theme='teal'] .tbtn { border-color: rgba(45,212,191,0.35); color: #CCFBF1; background: rgba(0,35,30,0.6); }
[data-color-theme='teal'] .tbtn:hover { border-color: #2DD4BF; background: rgba(45,212,191,0.16); }

/* ── Pure Dark Theme ────────────────────────────────────────── */
[data-color-theme='dark'] ::-webkit-scrollbar-thumb { background: rgba(77,159,255,0.35) !important; }
[data-color-theme='dark'] input,
[data-color-theme='dark'] select,
[data-color-theme='dark'] textarea { color-scheme: dark; accent-color: #4D9FFF; }

/* ── Pure White Theme ───────────────────────────────────────── */
[data-color-theme='white'] ::-webkit-scrollbar-thumb { background: rgba(37,99,235,0.3) !important; }
[data-color-theme='white'] input,
[data-color-theme='white'] select,
[data-color-theme='white'] textarea { color-scheme: light; accent-color: #2563EB; }
[data-color-theme='white'] .nav-lnk:hover { background: rgba(37,99,235,0.1) !important; color: #2563EB !important; }
[data-color-theme='white'] .btn-p { background: linear-gradient(135deg,#2563EB,#1D4ED8) !important; }
[data-color-theme='white'] .tbtn { border-color: rgba(37,99,235,0.35); color: #0F172A; background: rgba(240,247,255,0.8); }
[data-color-theme='white'] .tbtn:hover { border-color: #2563EB; background: rgba(37,99,235,0.1); }
[data-color-theme='white'] .pr-card,
[data-color-theme='white'] .stat-card { background: rgba(255,255,255,0.97) !important; border-color: rgba(0,0,0,0.06) !important; box-shadow: 0 4px 24px rgba(0,0,0,0.07) !important; }
\`;

c = c + APPEND;
fs.writeFileSync(f, c);
console.log('✅ globals.css — 3-theme CSS added');
" 2>&1

# ════════════════════════════════════════════════════════════════
# 3. PATCH — Auth Pages → Neon Teal Theme
# ════════════════════════════════════════════════════════════════
export LOGIN_F REG_F TERMS_F

node -e "
const fs = require('fs');

// ── Teal color replacements for auth pages ──────────────────
function applyTeal(filePath, pageName) {
  if(!filePath || !fs.existsSync(filePath)){
    console.log('⚠️  Not found: ' + pageName); return;
  }
  let c = fs.readFileSync(filePath, 'utf8');

  // 1. Color constants
  c = c.replace(
    \"const PRI='#4D9FFF',SUC='#00C48C',DNG='#FF4D4D',SUB='#6B8FAF',TXT='#E8F4FF'\",
    \"const PRI='#2DD4BF',SUC='#00C48C',DNG='#FF4D4D',SUB='#5EEAD4',TXT='#CCFBF1'  // Neon Teal\"
  );

  // 2. Input style (bg + border)
  c = c.replace(
    \"background:'rgba(0,22,40,.85)',border:'1.5px solid rgba(77,159,255,.3)'\",
    \"background:'rgba(0,20,18,.85)',border:'1.5px solid rgba(0,200,160,.3)'\"
  );

  // 3. Outer container background → teal gradient
  c = c.replace(
    \"background:'radial-gradient(ellipse at 20% 50%,#000D1A,#000308 60%,#00010A)'\",
    \"background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'\"
  );
  c = c.replace(
    \"background:'radial-gradient(ellipse at 80% 40%,#000D1A,#000510 55%,#000108)'\",
    \"background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'\"
  );
  c = c.replace(
    \"background:'radial-gradient(ellipse at 20% 50%,#000D1A 0%,#000510 60%,#000108 100%)'\",
    \"background:'linear-gradient(145deg,#001A1A 0%,#002E2E 50%,#000D0D 100%)'\"
  );

  // 4. Card background + border
  c = c.replace(/background:'rgba\(0,22,40,\.88\)',border:'1px solid rgba\(77,159,255,\.28\)'/g,
    \"background:'rgba(0,35,30,.88)',border:'1px solid rgba(0,200,160,.28)'\"
  );
  c = c.replace(/background:'rgba\(0,22,40,\.78\)',border:'1px solid rgba\(77,159,255,\.22\)'/g,
    \"background:'rgba(0,35,30,.78)',border:'1px solid rgba(0,200,160,.22)'\"
  );

  // 5. ProveRank logo gradient text
  c = c.replace(
    \"background:'linear-gradient(90deg,#4D9FFF,#00D4FF)'\",
    \"background:'linear-gradient(90deg,#2DD4BF,#00F0D4)'\"
  );

  // 6. Primary button color (already handled via PRI var, but catch direct uses)
  c = c.replace(/linear-gradient\(135deg,#4D9FFF,#0055CC\)/g, 'linear-gradient(135deg,#2DD4BF,#0D9488)');

  fs.writeFileSync(filePath, c);
  console.log('✅ ' + pageName + ' — Neon Teal applied');
}

applyTeal(process.env.LOGIN_F, 'Login page');
applyTeal(process.env.REG_F,   'Register page');
applyTeal(process.env.TERMS_F, 'Terms page');
" 2>&1

# ════════════════════════════════════════════════════════════════
# 4. PATCH — Profile Page → Add Theme Picker in Preferences tab
# ════════════════════════════════════════════════════════════════
export PROF_F
node -e "
const fs = require('fs');
const f  = process.env.PROF_F;
if(!f||!fs.existsSync(f)){console.log('⚠️  Profile page not found');process.exit(0);}
let c = fs.readFileSync(f,'utf8');

if(c.includes('pr_color_theme')||c.includes('ThemePicker')){
  console.log('ℹ️  Theme picker already present in Profile');process.exit(0);
}

// ── A. Add activeTheme state in ProfileContent ────────────
// Find the first useState inside the function ProfileContent
const firstState = 'const [tab,setTab]=useState';
if(c.includes(firstState)){
  c = c.replace(firstState,
    \`const [activeTheme,setActiveTheme]=useState<'white'|'dark'|'teal'>('dark')
  // Load saved theme on mount
  useEffect(()=>{try{const t=localStorage.getItem('pr_color_theme') as any;if(t)setActiveTheme(t)}catch{}},[])
  const applyTheme=(t:'white'|'dark'|'teal')=>{setActiveTheme(t);try{localStorage.setItem('pr_color_theme',t);window.dispatchEvent(new StorageEvent('storage',{key:'pr_color_theme',newValue:t}))}catch{}}
  \` + firstState
  );
}

// ── B. Inject theme picker into Preferences tab ───────────
const THEME_PICKER = \`
          {/* ── 🎨 Theme Picker ── */}
          <div style={{borderTop:\`1px solid \${C.border}\`,paddingTop:18,marginTop:6}}>
            <div style={{fontSize:13,fontWeight:700,color:C.primary,marginBottom:14}}>🎨 {t('App Color Theme','ऐप कलर थीम')}</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10}}>
              {([
                {id:'white' as const,label:t('Pure White','शुद्ध सफेद'),sub:'Bright & Clean',bg:'#FFFFFF',acc:'#2563EB',ico:'☀️',tcl:'#0F172A'},
                {id:'dark'  as const,label:t('Pure Dark', 'शुद्ध काला'),sub:'Bold & Dark',   bg:'#0A0A0A',acc:'#4D9FFF',ico:'🌑',tcl:'#FFFFFF'},
                {id:'teal'  as const,label:t('Neon Teal', 'नियॉन टील'), sub:'Deep & Vibrant',bg:'linear-gradient(135deg,#001A1A,#002E2E)',acc:'#2DD4BF',ico:'🌊',tcl:'#CCFBF1'},
              ]).map(th=>{
                const active=activeTheme===th.id
                return(
                  <button key={th.id} onClick={()=>applyTheme(th.id)}
                    style={{background:th.bg,border:\`2px solid \${active?th.acc:'rgba(255,255,255,0.08)'}\`,borderRadius:14,padding:'14px 8px',cursor:'pointer',textAlign:'center',boxShadow:active?\`0 0 20px \${th.acc}55\`:'none',transition:'all .25s',position:'relative',minHeight:90}}>
                    {active&&<span style={{position:'absolute',top:6,right:8,fontSize:10,color:th.acc,fontWeight:800}}>✓</span>}
                    <div style={{fontSize:22,marginBottom:6}}>{th.ico}</div>
                    <div style={{fontSize:11,fontWeight:700,color:th.acc,lineHeight:1.2}}>{th.label}</div>
                    <div style={{fontSize:9,marginTop:3,color:th.tcl==='#FFFFFF'?'rgba(255,255,255,0.4)':'rgba(0,0,0,0.3)'}}>{th.sub}</div>
                  </button>
                )
              })}
            </div>
            <div style={{fontSize:10,color:C.sub,textAlign:'center',marginTop:10,lineHeight:1.5}}>
              {t('Applies to all student pages. Test Series keeps default.','सभी स्टूडेंट पेज पर लागू होती है।')}
            </div>
          </div>\`;

// Inject just before the closing </div> of the prefs tab
const PREFS_END = \"          ))}\\n        </div>\\n      )}\";
const PREFS_REPLACE = \"          ))}\" + THEME_PICKER + \"\\n        </div>\\n      )}\";

if(c.includes(PREFS_END)){
  c = c.replace(PREFS_END, PREFS_REPLACE);
  fs.writeFileSync(f, c);
  console.log('✅ Profile page — Theme picker added in Preferences tab');
} else {
  // Fallback: inject before Login History section
  const fallback = '{/* ── Login History ── */}';
  if(c.includes(fallback)){
    const insert = \`      {/* ── Theme Picker ── */}
      {tab==='prefs'&&(
        <div style={{background:'rgba(0,35,30,0.08)',border:'1px solid rgba(45,212,191,0.15)',borderRadius:14,padding:18,marginTop:12}}>
\` + THEME_PICKER + \`
        </div>
      )}
      \`;
    c = c.replace(fallback, insert + fallback);
    fs.writeFileSync(f, c);
    console.log('✅ Profile page — Theme picker added (fallback position)');
  } else {
    console.log('⚠️  Could not find injection point in profile page');
  }
}
" 2>&1

# ════════════════════════════════════════════════════════════════
# 5. VERIFICATION
# ════════════════════════════════════════════════════════════════
echo ""
echo "══════════════════════════════════════════════════"
echo "  🔍 Verification"
echo "══════════════════════════════════════════════════"
export SHELL_F LOGIN_F REG_F TERMS_F PROF_F CSS_F

node -e "
const fs = require('fs');
const read = (f) => (f && fs.existsSync(f)) ? fs.readFileSync(f,'utf8') : '';

const sh   = read(process.env.SHELL_F);
const lo   = read(process.env.LOGIN_F);
const re   = read(process.env.REG_F);
const te   = read(process.env.TERMS_F);
const pr   = read(process.env.PROF_F);
const css  = read(process.env.CSS_F);

const checks = [
  // StudentShell
  ['StudentShell: ColorTheme type exported',        sh.includes(\"export type ColorTheme='white'|'dark'|'teal'\")],
  ['StudentShell: colorTheme state added',          sh.includes('setColorThemeState')],
  ['StudentShell: THEMES object (_TH) defined',     sh.includes('const _TH')],
  ['StudentShell: Test Series excluded',            sh.includes(\"_isTS=['test-series']\") || sh.includes(\"_isTS=['\") ],
  ['StudentShell: GalaxyBg conditional',            sh.includes('th.showGalaxy&&<GalaxyBg')],
  ['StudentShell: Container bg uses th.shellBg',    sh.includes('background:th.shellBg')],
  ['StudentShell: Header uses th.headerBg',         sh.includes('background:th.headerBg')],
  ['StudentShell: Sidebar uses th.sidebarBg',       sh.includes('background:th.sidebarBg')],
  ['StudentShell: Nav uses th.primary',             sh.includes('th.primary')],
  ['StudentShell: setColorTheme in ShellCtx',       sh.includes('setColorTheme,user')],
  ['StudentShell: reads pr_color_theme on mount',   sh.includes(\"localStorage.getItem('pr_color_theme')\")],
  ['StudentShell: cross-tab storage listener',      sh.includes('_onTheme')],
  // Auth pages — Neon Teal
  ['Login page: Teal primary color',                lo.includes(\"PRI='#2DD4BF'\")],
  ['Login page: Teal background gradient',          lo.includes('#001A1A')],
  ['Register page: Teal primary color',             re.includes(\"PRI='#2DD4BF'\")],
  ['Register page: Teal background',               re.includes('#001A1A')],
  // Profile — theme picker
  ['Profile: activeTheme state added',              pr.includes('activeTheme')],
  ['Profile: applyTheme function',                  pr.includes('applyTheme')],
  ['Profile: Theme picker UI (3 buttons)',          pr.includes('Pure White') || pr.includes('Neon Teal')],
  ['Profile: saves to pr_color_theme',             pr.includes(\"localStorage.setItem('pr_color_theme'\")],
  // globals.css
  ['globals.css: teal-color-theme class',           css.includes(\"data-color-theme='teal'\")],
  ['globals.css: white-color-theme class',          css.includes(\"data-color-theme='white'\")],
];

let pass=0, fail=0;
checks.forEach(([l,v])=>{
  console.log((v?'✅':'❌')+' '+l);
  v?pass++:fail++;
});

console.log('');
console.log(\`Result: \${pass}/\${checks.length} checks passed\`);
if(fail===0){
  console.log('');
  console.log('🎉 Theme System Fully Implemented!');
  console.log('');
  console.log('HOW IT WORKS:');
  console.log('  Student → Profile → Preferences → 🎨 App Color Theme');
  console.log('  3 options: ☀️ Pure White | 🌑 Pure Dark | 🌊 Neon Teal');
  console.log('  Saved in localStorage pr_color_theme');
  console.log('  Auth pages: Neon Teal hardcoded');
  console.log('  Test Series: keeps current Galaxy BG (excluded)');
}else{
  console.log(\`⚠️  \${fail} check(s) need attention\`);
}
"

echo ""
echo "Git push karo:"
echo "  git add . && git commit -m 'feat: Student 3-color theme system (White/Dark/Teal)' && git push"
