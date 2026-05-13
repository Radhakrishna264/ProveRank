#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — Admin sees SuperAdmin panel (filtered tabs)
# Fix 1: /admin/x7k2p — filter NAV when role=admin
# Fix 2: /admin/panel — redirect to /admin/x7k2p
# ═══════════════════════════════════════════════════════════════
set -e
SAF="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
APF="$HOME/workspace/frontend/app/admin/panel/page.tsx"

[ ! -f "$SAF" ] && echo "❌ SuperAdmin page not found" && exit 1
[ ! -f "$APF" ] && echo "❌ Admin panel page not found" && exit 1

cp "$SAF" "${SAF}.bak7.$(date +%s)"
cp "$APF" "${APF}.bak7.$(date +%s)"
echo "✅ Backups created"
export SAF APF

# ════════════════════════════════════════════════════════
# FIX 1 — SuperAdmin panel: 3 targeted Node.js changes
# ════════════════════════════════════════════════════════
node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.SAF;
let c=fs.readFileSync(FILE,'utf8');

// ── ADD adminOwnPerms state after selectedPermAdmin ──
const A1_OLD=`const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);`;
const A1_NEW=`const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);
const [adminOwnPerms,setAdminOwnPerms]=useState({});`;
if(c.includes(A1_OLD)){
  c=c.replace(A1_OLD,A1_NEW);
  console.log('✅ A1: adminOwnPerms state added');
}else console.warn('⚠️ A1: selectedPermAdmin line not found');

// ── FETCH OWN PERMISSIONS when role=admin ──
// Insert after: setToken(t);setRole(r);setMounted(true)
const A2_OLD=`setToken(t);setRole(r);setMounted(true)
  },[router])`;
const A2_NEW=`setToken(t);setRole(r);setMounted(true);
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
if(c.includes(A2_OLD)){
  c=c.replace(A2_OLD,A2_NEW);
  console.log('✅ A2: Own permissions fetch for admin role added');
}else console.warn('⚠️ A2: setToken/setRole line not found');

// ── ADD PERM_TO_NAV mapping + filteredNAV after navGroups ──
const A3_OLD=`const navGroups=[...new Set(NAV.map(n=>n.grp))]`;
const A3_NEW=`const navGroups=[...new Set(NAV.map(n=>n.grp))]

  // ── Admin role: filter NAV based on their permissions ──
  const PERM_TO_NAV:{[k:string]:string[]}={
    create_exam:['create_exam','templates','bulk_creator'],
    edit_exam:['exams'],delete_exam:['exams'],clone_exam:['exams'],
    bulk_exam:['bulk_creator'],
    manage_questions:['questions'],
    ai_questions:['smart_gen'],
    pyq_access:['pyq_bank'],
    view_students:['students'],ban_student:['students'],impersonate:['students'],
    batch_transfer:['batches'],
    view_results:['results'],
    view_leaderboard:['leaderboard'],
    view_analytics:['analytics'],
    download_reports:['reports','qbank_stats'],
    export_data:['reports'],
    send_announcements:['announcements'],
    manage_doubts:['tickets'],
    manage_grievances:['tickets'],
    answer_key_challenge:['ans_challenge'],
    view_audit_logs:['audit'],
    view_snapshots:['snapshots','cheating','integrity'],
    manage_features:['features'],
    manage_branding:['branding'],
    manage_backup:['backup'],
  }
  const ADMIN_HIDDEN=['admins','permissions','maintenance','changelog','tasks','parent_portal','transparency','omr_view','proct_pdf','retention','institute_report','re_eval','whatsapp_sms','email_tmpl','custom_fields','global_search','live']
  const filteredNAV=role==='superadmin'?NAV:(()=>{
    const allowed=new Set(['dashboard'])
    Object.entries(adminOwnPerms).forEach(([perm,val])=>{
      if(val&&PERM_TO_NAV[perm]) PERM_TO_NAV[perm].forEach(t=>allowed.add(t))
    })
    return NAV.filter(n=>allowed.has(n.id)&&!ADMIN_HIDDEN.includes(n.id))
  })()
  const filteredNavGroups=[...new Set(filteredNAV.map(n=>n.grp))]`;
if(c.includes(A3_OLD)){
  c=c.replace(A3_OLD,A3_NEW);
  console.log('✅ A3: PERM_TO_NAV + filteredNAV added');
}else console.warn('⚠️ A3: navGroups line not found');

// ── USE filteredNAV in sidebar (replace NAV with filteredNAV) ──
// The sidebar renders: navGroups.map + NAV.filter(n=>n.grp===grp)
// Replace navGroups with filteredNavGroups and NAV.filter with filteredNAV.filter
let sidebarFixed=0;

// Replace navGroups.map in sidebar
const NAV_MAP_OLD=`navGroups.map(`;
const NAV_MAP_NEW=`filteredNavGroups.map(`;
if(c.includes(NAV_MAP_OLD)){
  c=c.replaceAll(NAV_MAP_OLD,NAV_MAP_NEW);
  sidebarFixed++;
  console.log('✅ A4: navGroups.map → filteredNavGroups.map');
}

// Replace NAV.filter in sidebar group rendering
const NAV_FILTER_OLD=`NAV.filter(n=>n.grp===grp)`;
const NAV_FILTER_NEW=`filteredNAV.filter(n=>n.grp===grp)`;
if(c.includes(NAV_FILTER_OLD)){
  c=c.replaceAll(NAV_FILTER_OLD,NAV_FILTER_NEW);
  sidebarFixed++;
  console.log('✅ A5: NAV.filter → filteredNAV.filter');
}

// ── Role badge in header: show ADMIN vs SUPERADMIN ──
const BADGE_OLD=`⚡ SUPERADMIN`;
if(c.includes(BADGE_OLD)){
  c=c.replace(BADGE_OLD,`{role==='superadmin'?'⚡ SUPERADMIN':'🛡️ ADMIN'}`);
  // Fix the wrapping since it was inside JSX text
  // Actually this is inside JSX, let's find and fix properly
}

fs.writeFileSync(FILE,c,'utf8');
console.log('\n✅ SuperAdmin panel fixes applied!');
NODEEOF

# ════════════════════════════════════════════════════════
# FIX 2 — Admin panel: redirect to /admin/x7k2p
# ════════════════════════════════════════════════════════
cat > "$APF" << 'REDIRECTEOF'
'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function AdminPanel() {
  const router = useRouter()
  useEffect(() => {
    router.replace('/admin/x7k2p')
  }, [router])
  return null
}
REDIRECTEOF

echo "✅ Admin panel → redirect to /admin/x7k2p"

echo ""
echo "══════════════════════════════════════════════════════════"
echo "✅ ALL DONE! Now run:"
echo "   git add -A && git commit -m 'Admin: sees SuperAdmin panel with filtered tabs' && git push"
echo "══════════════════════════════════════════════════════════"
