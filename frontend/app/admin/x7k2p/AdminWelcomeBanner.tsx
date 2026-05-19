'use client';
import { useEffect, useState } from 'react';

const PERM_LABELS: Record<string, string> = {
  manageExams: '📋 Exam Management',
  createExam: '📝 Create Exams',
  editExam: '✏️ Edit Exams',
  deleteExam: '🗑️ Delete Exams',
  manageQuestions: '❓ Question Bank',
  bulkUpload: '📤 Bulk Upload',
  manageStudents: '👥 Student Mgmt',
  banStudents: '🚫 Ban Students',
  viewResults: '📊 View Results',
  exportReports: '📁 Export Reports',
  sendAnnouncements: '📢 Announcements',
  sendEmails: '📧 Email Templates',
  manageSettings: '⚙️ Settings',
  maintenance: '🔧 Maintenance',
  viewAnalytics: '📈 Analytics',
  manageAdmins: '👤 Manage Admins',
  viewAuditLogs: '🔍 Audit Logs',
  manageGrievances: '📋 Grievances',
  manageBackup: '💾 Backup',
  manageBranding: '🎨 Branding',
  manageFeatureFlags: '🚩 Feature Flags',
  manageBatches: '🎓 Batch Mgmt',
  viewLiveMonitor: '🔴 Live Monitor',
  managePermissions: '🔒 Permissions',
  manageTemplates: '📄 Templates',
  viewProctoringReports: '🛡️ Proctoring',
};

export default function AdminWelcomeBanner() {
  const [visible, setVisible] = useState(false);
  const [adminName, setAdminName] = useState('Admin');
  const [adminId, setAdminId] = useState('');
  const [loginNum, setLoginNum] = useState(1);
  const [perms, setPerms] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    try {
      const token = localStorage.getItem('pr_token');
      const role = localStorage.getItem('pr_role');
      if (!token || role !== 'admin') return;

      const parts = token.split('.');
      if (parts.length < 2) return;
      const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const payload = JSON.parse(atob(b64));
      const uid: string = payload.id || 'u';

      const justLogged = sessionStorage.getItem('pr_just_logged_in');
      const countKey = 'pr_admin_wc_' + uid;
      let count = parseInt(localStorage.getItem(countKey) || '0', 10);

      if (justLogged) {
        count = count + 1;
        localStorage.setItem(countKey, String(count));
        sessionStorage.removeItem('pr_just_logged_in');
      }

      if (count < 1 || count > 2) return;

      setLoginNum(count);

      const apiBase = (process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com');
      fetch(apiBase + '/api/admin/manage/profile/me', {
        headers: { Authorization: 'Bearer ' + token },
      })
        .then(function(r) { return r.json(); })
        .then(function(d) {
          if (d && d.success && d.admin) {
            setAdminName(d.admin.name || 'Admin');
            setAdminId(d.admin.adminId || '');
            const p = d.admin.permissions;
            if (p && typeof p === 'object') {
              const granted = Object.entries(p as Record<string,boolean>)
                .filter(function(entry) { return entry[1] === true; })
                .map(function(entry) { return PERM_LABELS[entry[0]] || entry[0]; });
              setPerms(granted);
            }
          }
          setLoading(false);
          setVisible(true);
        })
        .catch(function() {
          setLoading(false);
          setVisible(true);
        });
    } catch (err) {
      console.error('AdminWelcomeBanner error:', err);
    }
  }, []);

  const handleCopy = function() {
    if (adminId) {
      navigator.clipboard.writeText(adminId).then(function() {
        setCopied(true);
        setTimeout(function() { setCopied(false); }, 2000);
      }).catch(function() {});
    }
  };

  if (!visible) return null;

  return (
    <div style={{
      position: 'fixed',
      inset: 0,
      zIndex: 99999,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'rgba(0,0,0,0.78)',
      backdropFilter: 'blur(10px)',
      padding: '16px',
    }}>
      <style>{`
        @keyframes bannerIn {
          from { opacity:0; transform:scale(0.82) translateY(32px); }
          to { opacity:1; transform:scale(1) translateY(0); }
        }
        @keyframes goldShimmer {
          0% { background-position:-200% center; }
          100% { background-position:200% center; }
        }
        @keyframes goldenGlow {
          0%,100% { box-shadow:0 0 60px rgba(255,180,0,0.22),0 0 120px rgba(255,140,0,0.1); }
          50% { box-shadow:0 0 80px rgba(255,200,0,0.35),0 0 160px rgba(255,160,0,0.16); }
        }
      `}</style>

      <div style={{
        maxWidth: '520px',
        width: '100%',
        maxHeight: '92vh',
        overflowY: 'auto',
        borderRadius: '22px',
        background: 'linear-gradient(145deg,rgba(18,10,2,0.98) 0%,rgba(28,18,4,0.98) 50%,rgba(22,12,2,0.98) 100%)',
        border: '1.5px solid rgba(255,200,50,0.32)',
        animation: 'bannerIn 0.45s cubic-bezier(0.34,1.56,0.64,1) forwards, goldenGlow 3s ease-in-out infinite',
        position: 'relative',
      }}>

        <div style={{
          background: 'linear-gradient(90deg,#7c5200,#ffd700,#daa520,#ffc200,#b8860b,#ffd700,#7c5200)',
          backgroundSize: '300% auto',
          animation: 'goldShimmer 4s linear infinite',
          borderRadius: '22px 22px 0 0',
          height: '4px',
        }} />

        <div style={{ padding: '26px 22px 22px' }}>

          <div style={{ textAlign: 'center', marginBottom: '22px' }}>
            <div style={{ fontSize: '40px', marginBottom: '6px' }}>
              {loginNum === 1 ? '🎊' : '👋'}
            </div>
            <div style={{
              fontSize: '10px',
              fontWeight: 700,
              letterSpacing: '3.5px',
              color: '#b8860b',
              textTransform: 'uppercase',
              marginBottom: '8px',
            }}>
              {loginNum === 1 ? '✦ Welcome to ProveRank Admin ✦' : '✦ Welcome Back, Admin ✦'}
            </div>
            <div style={{
              fontSize: '24px',
              fontWeight: 800,
              background: 'linear-gradient(135deg,#ffd700 0%,#ffb300 40%,#ffe066 70%,#ffd700 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
              fontFamily: "'Georgia', 'Times New Roman', serif",
              lineHeight: 1.2,
              marginBottom: '6px',
            }}>
              {loginNum === 1 ? 'Hello, ' + adminName + '!' : 'Great to see you, ' + adminName + '!'}
            </div>
            <div style={{ fontSize: '12px', color: '#78716c', lineHeight: 1.6, maxWidth: '340px', margin: '0 auto' }}>
              {loginNum === 1
                ? 'Your Admin account is active. Review your assigned permissions and Admin ID below.'
                : 'This is your last welcome banner. You are fully set up — let\'s build something great!'}
            </div>
          </div>

          <div style={{
            background: 'linear-gradient(135deg,rgba(217,119,6,0.12) 0%,rgba(180,90,0,0.08) 100%)',
            border: '1px solid rgba(217,119,6,0.3)',
            borderRadius: '14px',
            padding: '16px 18px',
            marginBottom: '16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '12px',
          }}>
            <div>
              <div style={{
                fontSize: '9px',
                fontWeight: 700,
                color: '#78716c',
                letterSpacing: '2.5px',
                textTransform: 'uppercase',
                marginBottom: '4px',
              }}>Your Admin ID</div>
              <div style={{
                fontSize: '20px',
                fontWeight: 800,
                color: '#fbbf24',
                letterSpacing: '2px',
                fontFamily: "'Courier New', monospace",
              }}>
                {loading ? '· · ·' : (adminId || '—')}
              </div>
            </div>
            <button
              onClick={handleCopy}
              style={{
                background: copied ? 'rgba(34,197,94,0.18)' : 'rgba(217,119,6,0.16)',
                border: copied ? '1px solid #22c55e' : '1px solid rgba(217,119,6,0.5)',
                color: copied ? '#22c55e' : '#f59e0b',
                borderRadius: '9px',
                padding: '8px 16px',
                cursor: 'pointer',
                fontSize: '11px',
                fontWeight: 700,
                whiteSpace: 'nowrap',
                transition: 'all 0.2s',
              }}
            >
              {copied ? '✓ Copied!' : '📋 Copy ID'}
            </button>
          </div>

          <div style={{ marginBottom: '18px' }}>
            <div style={{
              fontSize: '9px',
              fontWeight: 700,
              color: '#d97706',
              letterSpacing: '2.5px',
              textTransform: 'uppercase',
              marginBottom: '10px',
            }}>⚡ Your Granted Permissions</div>

            {loading ? (
              <div style={{ textAlign: 'center', color: '#57534e', padding: '20px', fontSize: '13px' }}>
                Loading permissions...
              </div>
            ) : perms.length > 0 ? (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '7px' }}>
                {perms.map(function(p, i) {
                  return (
                    <div key={i} style={{
                      background: 'rgba(217,119,6,0.08)',
                      border: '1px solid rgba(217,119,6,0.2)',
                      borderRadius: '8px',
                      padding: '7px 10px',
                      fontSize: '10px',
                      fontWeight: 600,
                      color: '#d4a017',
                      lineHeight: 1.4,
                    }}>{p}</div>
                  );
                })}
              </div>
            ) : (
              <div style={{
                background: 'rgba(217,119,6,0.07)',
                border: '1px solid rgba(217,119,6,0.2)',
                borderRadius: '10px',
                padding: '14px',
                textAlign: 'center',
                color: '#f59e0b',
                fontSize: '12px',
                fontWeight: 600,
              }}>🔑 Permissions assigned by SuperAdmin</div>
            )}
          </div>

          <div style={{
            background: loginNum === 1
              ? 'rgba(217,119,6,0.1)'
              : 'rgba(139,92,246,0.1)',
            border: loginNum === 1
              ? '1px solid rgba(217,119,6,0.3)'
              : '1px solid rgba(139,92,246,0.3)',
            borderRadius: '9px',
            padding: '9px 14px',
            textAlign: 'center',
            fontSize: '11px',
            color: loginNum === 1 ? '#f59e0b' : '#a78bfa',
            fontWeight: 600,
            marginBottom: '18px',
          }}>
            {loginNum === 1 ? '🌟 First Login — Welcome to the ProveRank Team!' : '✨ Second Login — Last welcome message. You\'re all set!'}
          </div>

          <button
            onClick={function() { setVisible(false); }}
            style={{
              width: '100%',
              background: 'linear-gradient(90deg,#7c5200,#ffd700,#daa520,#ffc200,#ffd700,#7c5200)',
              backgroundSize: '200% auto',
              animation: 'goldShimmer 4s linear infinite',
              border: 'none',
              borderRadius: '13px',
              padding: '15px',
              color: '#1a0a00',
              fontSize: '13px',
              fontWeight: 800,
              cursor: 'pointer',
              letterSpacing: '1.5px',
              textTransform: 'uppercase',
            }}
          >
            🚀 Enter Admin Panel
          </button>

          <div style={{
            marginTop: '16px',
            borderTop: '1px solid rgba(217,119,6,0.12)',
            paddingTop: '12px',
            textAlign: 'center',
            color: '#44403c',
            fontSize: '9px',
            letterSpacing: '2px',
          }}>
            PROVERANK · PROVE YOURSELF · RISE TO THE TOP
          </div>
        </div>

        <div style={{
          background: 'linear-gradient(90deg,#7c5200,#ffd700,#daa520,#ffc200,#b8860b,#ffd700,#7c5200)',
          backgroundSize: '300% auto',
          animation: 'goldShimmer 4s linear infinite',
          borderRadius: '0 0 22px 22px',
          height: '4px',
        }} />
      </div>
    </div>
  );
}
