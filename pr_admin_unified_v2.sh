#!/bin/bash
# ════════════════════════════════════════════════════════════
# ProveRank — Admin Unified Fix v2
# Fix 1: /admin/panel → hard redirect to /admin/x7k2p
# Fix 2: /admin/x7k2p → admin sees ALL tabs except SuperAdmin-only
# ════════════════════════════════════════════════════════════
set -e
SAF="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
APF="$HOME/workspace/frontend/app/admin/panel/page.tsx"

[ ! -f "$SAF" ] && echo "❌ $SAF not found" && exit 1
[ ! -f "$APF" ] && echo "❌ $APF not found" && exit 1

cp "$SAF" "${SAF}.bak8.$(date +%s)"
cp "$APF" "${APF}.bak8.$(date +%s)"
echo "✅ Backups created"

# ════════════════════════════════════════════════════════════
# FIX 1 — /admin/panel: just a 5-line redirect file
# ════════════════════════════════════════════════════════════
node -e "
const fs=require('fs');
fs.writeFileSync(process.env.APF,\`'use client'
import{useEffect}from'react'
import{useRouter}from'next/navigation'
export default function AdminPanel(){
  const router=useRouter()
  useEffect(()=>{router.replace('/admin/x7k2p')},[router])
  return null
}
\");
console.log('✅ Fix 1: /admin/panel → redirect to /admin/x7k2p');
" APF="$APF"

# ════════════════════════════════════════════════════════════
# FIX 2 — /admin/x7k2p: show all tabs for admin
# Remove old adminOwnPerms fetch & filteredNAV, replace with simple logic
# ════════════════════════════════════════════════════════════
node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.SAF;
let c=fs.readFileSync(FILE,'utf8');

// ── REMOVE old broken permission fetch (A2) ──
const FETCH_OLD=`setToken(t);setRole(r);setMounted(true);
    // If admin (not superadmin), fetch own permissions for nav filtering
    if(r==='admin'){
      fetch((process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com')+'/api/admin/manage/profile/me',{headers:{Authorization:'Bearer '+t}})
        .then(res=>res.json())
        .then(d=>{
          if(d.success&&d.admin&&d.admin.permissions){
            const p=d.admin.permissions;
            const obj=typeof p.forEach==='function'?Object.fromEntries(p):p;
            setAdminOwnPerms(obj||{});
          }
        })
        .catch(()=>{
          // fallback: try profile with own ID from token
        });
    }
  },[router])`;
const FETCH_NEW=`setToken(t);setRole(r);setMounted(true)
  },[router])`;
if(c.includes(FETCH_OLD)){
  c=c.replace(FETCH_OLD,FETCH_NEW);
  console.log('\u2705 Removed broken /profile/me fetch');
}else{
  // Maybe already clean
  console.log('\u2139\uFE0F  Fetch block not found — may already be clean');
}

// ── REMOVE old PERM_TO_NAV + filteredNAV (A3) if present ──
// Find from "const PERM_TO_NAV" to end of filteredNavGroups line
const ptnIdx=c.indexOf('const PERM_TO_NAV:');
const fngIdx=c.indexOf('const filteredNavGroups=');
if(ptnIdx!==-1&&fngIdx!==-1){
  const fngEnd=c.indexOf('\n',fngIdx)+1;
  c=c.slice(0,ptnIdx)+c.slice(fngEnd);
  console.log('\u2705 Removed old PERM_TO_NAV + filteredNAV block');
}

// ── ADD adminOwnPerms state if not present (needed by JSX) ──
if(!c.includes('adminOwnPerms')){
  c=c.replace(
    'const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);',
    'const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);\nconst [adminOwnPerms,setAdminOwnPerms]=useState({});'
  );
}

// ── REPLACE filteredNAV logic: admin sees all except SA-only ──
const navGroupsLine='const navGroups=[...new Set(NAV.map(n=>n.grp))]';
if(c.includes(navGroupsLine)){
  c=c.replace(navGroupsLine,
    `const navGroups=[...new Set(NAV.map(n=>n.grp))]
  // Admin sees all tabs except SuperAdmin-only management tabs
  const SA_ONLY=['admins','permissions','maintenance','transparency','omr_view','retention','institute_report','re_eval','whatsapp_sms','changelog','tasks','parent_portal']
  const filteredNAV=role==='superadmin'?NAV:NAV.filter(n=>!SA_ONLY.includes(n.id))
  const filteredNavGroups=[...new Set(filteredNAV.map(n=>n.grp))]`
  );
  console.log('\u2705 filteredNAV: admin sees all tabs except SA-only');
}else{
  console.warn('\u26A0\uFE0F navGroups line not found');
}

// ── Fix sidebar: use filteredNavGroups + filteredNAV ──
// Replace navGroups.map → filteredNavGroups.map (if not already done)
if(c.includes('navGroups.map(')){
  c=c.replaceAll('navGroups.map(','filteredNavGroups.map(');
  console.log('\u2705 navGroups.map \u2192 filteredNavGroups.map');
}
// Replace NAV.filter(n=>n.grp===grp) → filteredNAV.filter
if(c.includes('NAV.filter(n=>n.grp===grp)')){
  c=c.replaceAll('NAV.filter(n=>n.grp===grp)','filteredNAV.filter(n=>n.grp===grp)');
  console.log('\u2705 NAV.filter \u2192 filteredNAV.filter in sidebar');
}

// ── Role label: SUPERADMIN in gold, ADMIN in blue ──
// This is already handled by: {role==='superadmin'?GOLD:ACC}
// Just make sure the text says SUPERADMIN or ADMIN correctly
if(c.includes('⚡ SUPERADMIN')){
  c=c.replace(
    '⚡ SUPERADMIN',
    `{role==='superadmin'?'\u26A1 SUPERADMIN':'\u26A1 ADMIN'}`
  );
  console.log('\u2705 Role badge: SUPERADMIN/ADMIN dynamic');
}else if(c.includes('⚡ {role.toUpperCase()}')){
  console.log('\u2139\uFE0F  Role badge already dynamic');
}

fs.writeFileSync(FILE,c,'utf8');
console.log('\n\u2705 All x7k2p fixes applied!');
NODEEOF

echo ""
echo "══════════════════════════════════════════════════════════"
echo "✅ Done! Run: git add -A && git commit -m 'Admin: unified panel v2 — sees SuperAdmin UI' && git push"
echo "══════════════════════════════════════════════════════════"
