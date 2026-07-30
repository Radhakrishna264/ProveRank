#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# FIX: Exam Instructions page — "Terms & Conditions" modal's "I Agree"
# button stays permanently disabled when the T&C text is short enough
# to already fit inside the modal (no actual scrollable overflow).
#
# Root cause: scrolledToBottom is only ever set via the onScroll event
# handler. If content fits without overflow, the browser NEVER fires
# a 'scroll' event, so scrolledToBottom stays stuck at its initial
# `false` forever — user has nothing to scroll, so the gate can never
# open. This blocks starting the exam entirely.
#
# Fix: run the same "already at bottom" check once, right after the
# modal opens (content is a fixed static string, not fetched, so a
# short setTimeout after render is enough to let it paint first).
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

cat > /tmp/patch_tc_scroll.js << 'NODEEOF'
const fs = require('fs');

// Update this path if it differs from what was shared with us.
const path = process.argv[2] || 'frontend/app/exam/[examId]/instructions/page.tsx';

if (!fs.existsSync(path)) {
  console.error('❌ File not found at: ' + path);
  console.error('   Re-run with the correct path as an argument:');
  console.error('   node /tmp/patch_tc_scroll.js <real/path/to/page.tsx>');
  process.exit(1);
}

let src = fs.readFileSync(path, 'utf8');

const oldStr = `  const onTcScroll = () => {
    const el = tcBodyRef.current
    if (!el) return
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 20) setScrolledToBottom(true)
  }`;

const newStr = `  const onTcScroll = () => {
    const el = tcBodyRef.current
    if (!el) return
    if (el.scrollHeight - el.scrollTop - el.clientHeight < 20) setScrolledToBottom(true)
  }

  // F53-d FIX: if T&C text already fits without overflow, no 'scroll'
  // event ever fires, so scrolledToBottom stayed stuck at false forever
  // and "I Agree" was permanently disabled. Check once when modal opens.
  useEffect(() => {
    if (!tcModal) return
    setScrolledToBottom(false)
    const tId = setTimeout(() => onTcScroll(), 50)
    return () => clearTimeout(tId)
  }, [tcModal])`;

if (!src.includes(oldStr)) {
  console.error('❌ FAILED — anchor not found in ' + path + '. ABORTING (no changes written).');
  process.exit(1);
}
const count = src.split(oldStr).length - 1;
if (count > 1) {
  console.error('❌ FAILED — anchor not unique (' + count + ' matches). ABORTING.');
  process.exit(1);
}
src = src.replace(oldStr, newStr);
fs.writeFileSync(path, src, 'utf8');
console.log('✅ Patched: ' + path);
NODEEOF

echo "Run with the REAL path of this Instructions/T&C page, e.g.:"
echo "  node /tmp/patch_tc_scroll.js frontend/app/exam/[examId]/instructions/page.tsx"
echo ""
echo "(Find it first if unsure: find ~/workspace/frontend -iname '*.tsx' -exec grep -l 'Scroll to the bottom to continue' {} \\;)"
