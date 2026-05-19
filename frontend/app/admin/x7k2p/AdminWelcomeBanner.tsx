'use client';
import { useEffect, useState } from 'react';

const PERM_LABELS: Record<string, string> = {
  manageExams: '📝 Exam Management',
  createExam: '📝 Create Exams',
  editExam: '✏️ Edit Exams',
  deleteExam: '🗑️ Delete Exams',
  manageQuestions: '❓ Question Bank',
  bulkUpload: '📤 Bulk Upload',
  manageStudents: '👥 Student Mgmt',
  banStudents: '🚫 Ban Students',
  viewResults: '📊 View Results',
  exportReports: '📄 Export Reports',
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
  manageBatches: '📦 Batch Mgmt',
  viewLiveMonitor: '👁️ Live Monitor',
  managePermissions: '🔐 Permissions',
  manageTemplates: '📋 Templates',
  viewProctoringReports: '🎥 Proctoring',
};

export default function AdminWelcomeBanner() {
  const [visible, setVisible] = useState(false);
  const [adminName, setAdminName] = useState('Admin');
  const [adminId, setAdminId] = useState('');
  const [loginNum, setLoginNum] = useState(1);
  const [perms, setPerms] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(function () {
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

      const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com';
      fetch(API + '/api/admin/manage/profile/me', {
        headers: { Authorization: 'Bearer ' + token },
      })
        .then(function (r) { return r.json(); })
        .then(function (data) {
          const a = data.admin || data.user || data;
          setAdminName(a.name || 'Admin');
          setAdminId(a.adminId || '');
          const p: Record<string, boolean> = a.permissions || {};
          const granted = Object.entries(p)
            .filter(function (e) { return e[1] === true; })
            .map(function (e) {
              return PERM_LABELS[e[0]] || e[0].replace(/([A-Z])/g, ' $1').trim();
            });
          setPerms(granted);
          setLoading(false);
          setVisible(true);
        })
        .catch(function () {
          setLoading(false);
          setVisible(true);
        });
    } catch (_e) {
      // Silent fail — admin panel must not break
    }
  }, []);

  const handleCopy = function () {
    if (typeof navigator !== 'undefined' && navigator.clipboard && adminId) {
      navigator.clipboard.writeText(adminId).then(function () {
        setCopied(true);
        setTimeout(function () { setCopied(false); }, 2000);
      });
    }
  };

  if (!visible) return null;

  const hasPerms = perms.length > 0;
  const isFirst = loginNum === 1;

  return (
    <>
      <style>{`
        @keyframes prwb_fi {
          from { opacity: 0; transform: scale(0.88) translateY(24px); }
          to   { opacity: 1; transform: scale(1)    translateY(0);    }
        }
        @keyframes prwb_sh {
          0%,100% { background-position: 0%   50%; }
          50%      { background-position: 100% 50%; }
        }
        @keyframes prwb_fl {
          0%,100% { transform: translateY(0px);   }
          50%      { transform: translateY(-10px); }
        }
        @keyframes prwb_gl {
          0%,100% { box-shadow: 0 0 25px #d9770688, 0 0 50px #f59e0b33; }
          50%      { box-shadow: 0 0 50px #f59e0baa, 0 0 100px #fbbf2444; }
        }
      `}</style>

      <div style={{
        position: 'fixed', inset: 0, zIndex: 99999,
        background: 'rgba(0,0,0,0.88)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        backdropFilter: 'blur(10px)',
        animation: 'prwb_fi 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards',
      }}>
        <div style={{
          width: '92%', maxWidth: '490px',
          maxHeight: '90vh', overflowY: 'auto',
          background: 'linear-gradient(145deg,#0f0800 0%,#1c1100 45%,#0a0500 100%)',
          border: '1.5px solid #d97706',
          borderRadius: '22px',
          padding: '30px 24px 24px',
          position: 'relative',
          animation: 'prwb_gl 2.5s ease-in-out infinite',
        }}>

          {/* Shimmer top bar */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: '3px',
            background: 'linear-gradient(90deg,#92400e,#f59e0b,#fbbf24,#f59e0b,#92400e)',
            backgroundSize: '300% 100%',
            animation: 'prwb_sh 2s linear infinite',
            borderRadius: '22px 22px 0 0',
          }} />

          {/* Close */}
          <button
            onClick={function () { setVisible(false); }}
            style={{
              position: 'absolute', top: '14px', right: '16px',
              background: 'rgba(245,158,11,0.1)',
              border: '1px solid rgba(245,158,11,0.35)',
              color: '#f59e0b', borderRadius: '8px',
              padding: '4px 12px', cursor: 'pointer',
              fontSize: '12px', fontWeight: 700,
            }}
          >✕ Close</button>

          {/* Crown */}
          <div style={{
            textAlign: 'center', fontSize: '46px', marginBottom: '8px',
            animation: 'prwb_fl 3s ease-in-out infinite',
          }}>👑</div>

          {/* Login badge */}
          <div style={{ textAlign: 'center', marginBottom: '6px' }}>
            <span style={{
              background: 'linear-gradient(90deg,#92400e,#d97706,#92400e)',
              backgroundSize: '200% auto',
              animation: 'prwb_sh 2s linear infinite',
              color: '#fef3c7', fontSize: '10px', fontWeight: 800,
              letterSpacing: '3px', textTransform: 'uppercase',
              padding: '3px 16px', borderRadius: '20px', display: 'inline-block',
            }}>
              {isFirst ? '✦ First Login ✦' : '✦ Second Login ✦'}
            </span>
          </div>

          {/* Welcome name */}
          <div style={{
            textAlign: 'center', fontSize: '20px', fontWeight: 800,
            color: '#fbbf24',
            textShadow: '0 0 24px rgba(251,191,36,0.55)',
            margin: '8px 0 3px',
          }}>
            {loading ? 'Loading...' : ('Welcome, ' + adminName + '!')}
          </div>
          <p style={{
            textAlign: 'center', color: '#78716c',
            fontSize: '12px', margin: '0 0 22px',
          }}>
            ProveRank Admin Center — You are now in command
          </p>

          {/* Admin ID card */}
          <div style={{
            background: 'rgba(217,119,6,0.1)',
            border: '1px solid rgba(217,119,6,0.3)',
            borderRadius: '12px', padding: '12px 16px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: '20px',
          }}>
            <div>
              <div style={{
                color: '#78716c', fontSize: '9px', fontWeight: 700,
                letterSpacing: '2px', textTransform: 'uppercase', marginBottom: '4px',
              }}>Admin ID</div>
              <div style={{
                color: '#fbbf24', fontSize: '18px', fontWeight: 800,
                fontFamily: 'monospace', letterSpacing: '2px',
              }}>
                {loading ? '· · ·' : (adminId || '—')}
              </div>
            </div>
            <button
              onClick={handleCopy}
              style={{
                background: copied ? 'rgba(34,197,94,0.18)' : 'rgba(217,119,6,0.15)',
                border: copied ? '1px solid #22c55e' : '1px solid rgba(217,119,6,0.45)',
                color: copied ? '#22c55e' : '#f59e0b',
                borderRadius: '8px', padding: '6px 14px', cursor: 'pointer',
                fontSize: '11px', fontWeight: 700, whiteSpace: 'nowrap',
              }}
            >
              {copied ? '✓ Copied' : '📋 Copy'}
            </button>
          </div>

          {/* Permissions */}
          <div>
            <div style={{
              color: '#d97706', fontSize: '10px', fontWeight: 700,
              letterSpacing: '2px', textTransform: 'uppercase', marginBottom: '10px',
            }}>
              ⚡ Your Granted Permissions
            </div>

            {loading ? (
              <div style={{
                textAlign: 'center', color: '#57534e',
                padding: '18px', fontSize: '13px',
              }}>Loading permissions...</div>
            ) : hasPerms ? (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                {perms.map(function (p, i) {
                  return (
                    <div key={i} style={{
                      background: 'rgba(217,119,6,0.07)',
                      border: '1px solid rgba(217,119,6,0.18)',
                      borderRadius: '8px', padding: '8px 10px',
                      color: '#d4a017', fontSize: '10px', fontWeight: 600,
                      lineHeight: '1.4',
                    }}>{p}</div>
                  );
                })}
              </div>
            ) : (
              <div style={{
                background: 'rgba(217,119,6,0.07)',
                border: '1px solid rgba(217,119,6,0.2)',
                borderRadius: '10px', padding: '14px', textAlign: 'center',
                color: '#f59e0b', fontSize: '12px', fontWeight: 600,
              }}>
                🔑 Permissions configured by SuperAdmin
              </div>
            )}
          </div>

          {/* Footer */}
          <div style={{
            marginTop: '22px',
            borderTop: '1px solid rgba(217,119,6,0.12)',
            paddingTop: '14px', textAlign: 'center',
            color: '#44403c', fontSize: '10px', letterSpacing: '1.5px',
          }}>
            PROVERANK · PROVE YOURSELF · RISE TO THE TOP
          </div>

        </div>
      </div>
    </>
  );
}
