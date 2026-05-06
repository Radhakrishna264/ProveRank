#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  ProveRank — Remove "NEET 2026" from Auth Pages     ║
# ║  Rule C1: cat > EOF | Rule C2: NO sed              ║
# ╚══════════════════════════════════════════════════════╝
G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[✓]${N} $1"; }
FE=~/workspace/frontend

# Python se safe text replace — no sed
python3 - << 'PYEOF'
import os

files = [
    os.path.expanduser('~/workspace/frontend/app/login/page.tsx'),
    os.path.expanduser('~/workspace/frontend/app/register/page.tsx'),
]

replacements = [
    ('NEET 2026 Preparation Platform', 'NEET Preparation Platform'),
    ('NEET 2026', 'NEET'),
    ('neet 2026', 'neet'),
    ('· 2026 ·', '·'),
    ('2026', ''),
]

for fpath in files:
    if not os.path.exists(fpath):
        print(f'[SKIP] Not found: {fpath}')
        continue
    with open(fpath, 'r') as f:
        content = f.read()
    original = content
    for old, new in replacements:
        content = content.replace(old, new)
    if content != original:
        with open(fpath, 'w') as f:
            f.write(content)
        name = fpath.split('/')[-2]
        print(f'[✓] Fixed: {name}/page.tsx')
    else:
        print(f'[–] No changes needed: {fpath}')
PYEOF

echo -e "\n${Y}╔════════════════════════════════════════╗${N}"
echo -e "${Y}║  ✅ Done! "2026" removed from both      ║${N}"
echo -e "${Y}║  login/page.tsx & register/page.tsx    ║${N}"
echo -e "${Y}╠════════════════════════════════════════╣${N}"
echo -e "${Y}║  NOW run:                              ║${N}"
echo -e "${Y}║  cd ~/workspace/frontend               ║${N}"
echo -e "${Y}║  git add -A                            ║${N}"
echo -e "${Y}║  git commit -m 'fix: remove 2026'     ║${N}"
echo -e "${Y}║  git push                              ║${N}"
echo -e "${Y}╚════════════════════════════════════════╝${N}"
