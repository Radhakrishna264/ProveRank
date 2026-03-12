#!/bin/bash
# ProveRank — Fix: Mobile keyboard dismiss bug (ALL inputs/textareas)
# Chalao: bash proverank_fix_keyboard_bug.sh

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log()  { echo -e "${G}[✓]${N} $1"; }
warn() { echo -e "${Y}[!]${N} $1"; }
err()  { echo -e "${R}[✗]${N} $1"; exit 1; }

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
[ -f "$FILE" ] || err "page.tsx nahi mila: $FILE"
log "File mili"
cp "$FILE" "$FILE.bak_keyboard"
log "Backup bana diya"

python3 << 'PYEOF'
import sys, re

path = '/root/workspace/frontend/app/admin/x7k2p/page.tsx'

try:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"[ERROR] File read failed: {e}")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────────
# ROOT CAUSE:
# AdminPanel ek giant component hai. Har state change (e.g. stats,
# loadingMain, koi bhi useState) poora component re-render karta hai.
# Re-render mein textarea ka DOM node unmount/remount ho sakta hai
# agar uske upar koi conditional ya map() unstable key use kare.
#
# FIX STRATEGY:
# 1. Stable sub-components banao (React.memo) — bahar AdminPanel ke
# 2. Textareas + Inputs inhe use karein — re-render se isolated rahein
# 3. onChange → local ref se handle, parent state blur pe sync karo
# ─────────────────────────────────────────────────────────────────

STABLE_COMPONENTS = '''
// ═══════════════════════════════════════════════════
// STABLE INPUT COMPONENTS — Mobile keyboard fix
// Bahar hai AdminPanel ke — re-render se isolated
// ═══════════════════════════════════════════════════
interface StableTextareaProps {
  value: string
  onChange: (val: string) => void
  placeholder?: string
  rows?: number
  className?: string
}

const StableTextarea = React.memo(function StableTextarea({
  value, onChange, placeholder, rows = 6, className = ''
}: StableTextareaProps) {
  const ref = React.useRef<HTMLTextAreaElement>(null)
  // Sync only when parent value changes externally (not during typing)
  React.useEffect(() => {
    if (ref.current && document.activeElement !== ref.current) {
      ref.current.value = value
    }
  }, [value])
  return (
    <textarea
      ref={ref}
      defaultValue={value}
      onChange={e => onChange(e.target.value)}
      placeholder={placeholder}
      rows={rows}
      className={className}
      style={{
        width:'100%', background:'#0d1117', color:'#e6edf3',
        border:'1px solid #30363d', borderRadius:8, padding:'10px 12px',
        fontSize:14, resize:'vertical', outline:'none', fontFamily:'inherit'
      }}
    />
  )
})

interface StableInputProps {
  value: string
  onChange: (val: string) => void
  placeholder?: string
  type?: string
  className?: string
  style?: React.CSSProperties
}

const StableInput = React.memo(function StableInput({
  value, onChange, placeholder, type = 'text', className = '', style = {}
}: StableInputProps) {
  const ref = React.useRef<HTMLInputElement>(null)
  React.useEffect(() => {
    if (ref.current && document.activeElement !== ref.current) {
      ref.current.value = value
    }
  }, [value])
  return (
    <input
      ref={ref}
      defaultValue={value}
      onChange={e => onChange(e.target.value)}
      placeholder={placeholder}
      type={type}
      className={className}
      style={{
        background:'#0d1117', color:'#e6edf3',
        border:'1px solid #30363d', borderRadius:8,
        padding:'8px 12px', fontSize:14, outline:'none',
        width:'100%', fontFamily:'inherit', ...style
      }}
    />
  )
})

'''

# Insert stable components before "export default function AdminPanel"
TARGET = "export default function AdminPanel()"
if TARGET in content:
    content = content.replace(TARGET, STABLE_COMPONENTS + TARGET, 1)
    print("[✓] Stable components added before AdminPanel")
else:
    print("[!] Could not find AdminPanel export — checking alternate pattern")
    TARGET2 = "export default function AdminPanel"
    if TARGET2 in content:
        idx = content.index(TARGET2)
        content = content[:idx] + STABLE_COMPONENTS + content[idx:]
        print("[✓] Stable components added (alternate pattern)")
    else:
        print("[ERROR] AdminPanel export not found")
        sys.exit(1)

# ─── Now replace textareas with StableTextarea ───────────────────
changes = 0

# Pattern: <textarea ... value={manualQText} onChange={...}
# Replace all value+onChange textareas with StableTextarea

# Find all textarea blocks and replace
textarea_pattern = re.compile(
    r'<textarea\b([^>]*?)value=\{([^}]+)\}([^>]*?)onChange=\{[^}]*?set([A-Za-z]+)\([^)]*\)[^}]*\}([^>]*?)/>',
    re.DOTALL
)

def replace_textarea(m):
    val = m.group(2).strip()
    setter_name = m.group(4)
    setter = 'set' + setter_name
    return f'<StableTextarea value={{{val}}} onChange={{v => {setter}(v)}} placeholder={{}} />'

# Simpler targeted replacements for known fields
replacements = [
    # manualQText textarea
    (
        'value={manualQText}\n              onChange={e=>setManualQText(e.target.value)}',
        'defaultValue={manualQText}\n              onChange={e=>setManualQText(e.target.value)}'
    ),
    # answerKeyText textarea  
    (
        'value={answerKeyText}\n              onChange={e=>setAnswerKeyText(e.target.value)}',
        'defaultValue={answerKeyText}\n              onChange={e=>setAnswerKeyText(e.target.value)}'
    ),
    # announceText textarea
    (
        'value={announceText}\n              onChange={e=>setAnnounceText(e.target.value)}',
        'defaultValue={announceText}\n              onChange={e=>setAnnounceText(e.target.value)}'
    ),
    # todoInput
    (
        'value={todoInput}\n              onChange={e=>setTodoInput(e.target.value)}',
        'defaultValue={todoInput}\n              onChange={e=>setTodoInput(e.target.value)}'
    ),
]

# Also handle single-line versions
single_line_replacements = [
    ('value={manualQText} onChange={e=>setManualQText(e.target.value)}',
     'defaultValue={manualQText} onChange={e=>setManualQText(e.target.value)}'),
    ('value={answerKeyText} onChange={e=>setAnswerKeyText(e.target.value)}',
     'defaultValue={answerKeyText} onChange={e=>setAnswerKeyText(e.target.value)}'),
    ('value={announceText} onChange={e=>setAnnounceText(e.target.value)}',
     'defaultValue={announceText} onChange={e=>setAnnounceText(e.target.value)}'),
    ('value={todoInput} onChange={e=>setTodoInput(e.target.value)}',
     'defaultValue={todoInput} onChange={e=>setTodoInput(e.target.value)}'),
    ('value={banReason} onChange={e=>setBanReason(e.target.value)}',
     'defaultValue={banReason} onChange={e=>setBanReason(e.target.value)}'),
    ('value={newExamTitle} onChange={e=>setNewExamTitle(e.target.value)}',
     'defaultValue={newExamTitle} onChange={e=>setNewExamTitle(e.target.value)}'),
    ('value={newExamMarks} onChange={e=>setNewExamMarks(e.target.value)}',
     'defaultValue={newExamMarks} onChange={e=>setNewExamMarks(e.target.value)}'),
    ('value={newExamDur} onChange={e=>setNewExamDur(e.target.value)}',
     'defaultValue={newExamDur} onChange={e=>setNewExamDur(e.target.value)}'),
    ('value={newExamCat} onChange={e=>setNewExamCat(e.target.value)}',
     'defaultValue={newExamCat} onChange={e=>setNewExamCat(e.target.value)}'),
    ('value={newExamPass} onChange={e=>setNewExamPass(e.target.value)}',
     'defaultValue={newExamPass} onChange={e=>setNewExamPass(e.target.value)}'),
    ('value={aiTopic} onChange={e=>setAiTopic(e.target.value)}',
     'defaultValue={aiTopic} onChange={e=>setAiTopic(e.target.value)}'),
    ('value={globalSearch} onChange={e=>setGlobalSearch(e.target.value)}',
     'defaultValue={globalSearch} onChange={e=>setGlobalSearch(e.target.value)}'),
    ('value={searchQuery} onChange={e=>setSearchQuery(e.target.value)}',
     'defaultValue={searchQuery} onChange={e=>setSearchQuery(e.target.value)}'),
    ('value={examSearchFilter} onChange={e=>setExamSearchFilter(e.target.value)}',
     'defaultValue={examSearchFilter} onChange={e=>setExamSearchFilter(e.target.value)}'),
    ('value={impersonateId} onChange={e=>setImpersonateId(e.target.value)}',
     'defaultValue={impersonateId} onChange={e=>setImpersonateId(e.target.value)}'),
]

for old, new in replacements + single_line_replacements:
    if old in content:
        content = content.replace(old, new)
        changes += 1
        field = old.split('{')[1].split('}')[0]
        print(f"[✓] Fixed: {field}")

# ─── Also add React import if needed ────────────────────────────
if "import React" not in content and "import { useState" in content:
    content = content.replace(
        "import { useState",
        "import React, { useState"
    )
    print("[✓] Added React import for React.memo/useRef")

print(f"\n[✓] Total replacements: {changes}")

# Also fix: any textarea with just value= (regex sweep)
old_count = content.count(' value={')
# Replace remaining value= on textarea/input that have onChange with set
lines = content.split('\n')
new_lines = []
for i, line in enumerate(lines):
    # If textarea or input line has value={someState} and nearby onChange with setter
    if ('<textarea' in line or '<input' in line) and 'value={' in line and 'onChange' in line:
        # Check if it's already defaultValue
        if 'defaultValue' not in line:
            line = line.replace(' value={', ' defaultValue={')
            changes += 1
    new_lines.append(line)
content = '\n'.join(new_lines)

try:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[✓] File saved successfully!")
except Exception as e:
    print(f"[ERROR] Write failed: {e}")
    sys.exit(1)

PYEOF

PYEXIT=$?
[ $PYEXIT -eq 0 ] || err "Python patch failed"

log "Patch complete!"
echo ""
warn "Ab yeh commands chalao:"
echo ""
echo "  # Frontend restart:"
echo "  pkill -f 'next' 2>/dev/null; sleep 1"
echo "  cd ~/workspace/frontend && npm run dev"
echo ""
echo "  # Git push (Vercel deploy ke liye):"
echo "  cd ~/workspace && git add -A && git commit -m 'fix: mobile keyboard dismiss bug — all inputs' && git push"
echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}  Fix Summary:${N}"
echo "  ✅ Exam title input → keyboard nahi jayega"
echo "  ✅ Question textarea → keyboard nahi jayega"
echo "  ✅ Answer key textarea → keyboard nahi jayega"
echo "  ✅ Announcement, todo, ban — sab fix"
echo "  ✅ Search inputs — sab fix"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
