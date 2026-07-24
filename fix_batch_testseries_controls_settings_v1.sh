#!/bin/bash
set -e
cd ~/workspace

echo "=========================================="
echo "STEP 1: Locating target files"
echo "=========================================="
F1=$(find . -iname "BatchManagerUltra.tsx" 2>/dev/null | grep -v node_modules | head -1)
F2=$(find . -iname "TestSeriesManagerUltra.tsx" 2>/dev/null | grep -v node_modules | head -1)
F3=$(find . -iname "batchManagerUltra.js" 2>/dev/null | grep -v node_modules | head -1)
F4=$(find . -iname "testSeriesManagerUltra.js" 2>/dev/null | grep -v node_modules | head -1)

echo "BatchManagerUltra.tsx      -> $F1"
echo "TestSeriesManagerUltra.tsx -> $F2"
echo "batchManagerUltra.js       -> $F3"
echo "testSeriesManagerUltra.js  -> $F4"

if [ -z "$F1" ] || [ -z "$F2" ] || [ -z "$F3" ] || [ -z "$F4" ]; then
  echo "❌ ERROR: Ek ya zyada file nahi mili. Upar output check karo aur confirm karo files workspace me maujood hain."
  exit 1
fi

echo ""
echo "=========================================="
echo "STEP 2: Taking backups (.bak_TIMESTAMP)"
echo "=========================================="
TS=$(date +%Y%m%d_%H%M%S)
cp "$F1" "$F1.bak_$TS"
cp "$F2" "$F2.bak_$TS"
cp "$F3" "$F3.bak_$TS"
cp "$F4" "$F4.bak_$TS"
echo "Backups created with suffix .bak_$TS"

echo ""
echo "=========================================="
echo "STEP 3: Writing fix script"
echo "=========================================="
cat > /tmp/fix_batch_testseries_v1.js << 'ENDOFNODESCRIPT'
const fs = require('fs');

function replaceBetween(content, startMarker, endMarker, newBlock) {
  const s = content.indexOf(startMarker);
  if (s === -1) throw new Error('START marker not found: ' + startMarker.slice(0, 60));
  const e = content.indexOf(endMarker, s);
  if (e === -1) throw new Error('END marker not found: ' + endMarker.slice(0, 60));
  return content.slice(0, s) + newBlock + content.slice(e);
}

function mustReplace(content, oldStr, newStr, label) {
  if (content.indexOf(oldStr) === -1) throw new Error('mustReplace not found: ' + label);
  return content.split(oldStr).join(newStr);
}

function buildSettingsTabBatch() {
  return `// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const locked = !!s.isLocked
  const saveAndLock = async () => {
    await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) })
    await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders })
    showToast('✅ Saved & Locked')
    load(); loadParent && loadParent()
  }
  const unlock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); showToast('🔓 Unlocked'); load(); loadParent && loadParent() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Batch Name</label><input style={inp} disabled={locked} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} disabled={locked} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} disabled={locked} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} disabled={locked} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
      </div>
      <div style={{ marginTop: 10 }}>
        <label style={lbl}>Description</label>
        <textarea style={{ ...inp, minHeight: 60 }} disabled={locked} value={s.description || ''} onChange={e => setS({ ...s, description: e.target.value })} />
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => !locked && setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        {locked ? <button style={bs} onClick={unlock}>🔓 Unlock Batch</button> : <button style={bp} onClick={saveAndLock}>💾🔒 Save & Lock Batch</button>}
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

`;
}

function buildSettingsTabSeries() {
  return `// ── 14) SETTINGS TAB ──
function SettingsTab({ base, authHeaders, id, showToast, load: loadParent }: any) {
  const [s, setS] = useState<any>(null)
  const load = useCallback(() => fetch(base + '/' + id + '/settings', { headers: authHeaders }).then(r => r.json()).then(d => setS(d.settings)).catch(() => {}), [])
  useEffect(() => { load() }, [load])
  if (!s) return <EmptyMsg text="⟳ Loading settings…" />
  const locked = !!s.isLocked
  const saveAndLock = async () => {
    await fetch(base + '/' + id, { method: 'PUT', headers: authHeaders, body: JSON.stringify(s) })
    await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders })
    showToast('✅ Saved & Locked')
    load(); loadParent && loadParent()
  }
  const unlock = async () => { await fetch(base + '/' + id + '/settings/lock', { method: 'PUT', headers: authHeaders }); showToast('🔓 Unlocked'); load(); loadParent && loadParent() }
  return (
    <div>
      <div style={{ ...cs, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 10 }}>
        <div><label style={lbl}>Series Name</label><input style={inp} disabled={locked} value={s.name} onChange={e => setS({ ...s, name: e.target.value })} /></div>
        <div><label style={lbl}>Start Date</label><input style={inp} disabled={locked} type="date" value={s.startDate ? s.startDate.slice(0, 10) : ''} onChange={e => setS({ ...s, startDate: e.target.value })} /></div>
        <div><label style={lbl}>End Date</label><input style={inp} disabled={locked} type="date" value={s.endDate ? s.endDate.slice(0, 10) : ''} onChange={e => setS({ ...s, endDate: e.target.value })} /></div>
        <div><label style={lbl}>Seat Limit</label><input style={inp} disabled={locked} type="number" value={s.seatLimit} onChange={e => setS({ ...s, seatLimit: e.target.value })} /></div>
      </div>
      <div style={{ marginTop: 10 }}>
        <label style={lbl}>Description</label>
        <textarea style={{ ...inp, minHeight: 60 }} disabled={locked} value={s.description || ''} onChange={e => setS({ ...s, description: e.target.value })} />
      </div>
      <div style={{ margin: '10px 0' }}><Toggle on={s.autoArchiveAfterEnd} onChange={v => !locked && setS({ ...s, autoArchiveAfterEnd: v })} label="Auto-Archive After End Date" /></div>
      <div style={{ display: 'flex', gap: 8 }}>
        {locked ? <button style={bs} onClick={unlock}>🔓 Unlock Series</button> : <button style={bp} onClick={saveAndLock}>💾🔒 Save & Lock Series</button>}
      </div>
      {s.renameHistory?.length > 0 && (
        <div style={{ ...cs, marginTop: 14 }}>
          <div style={{ fontWeight: 700, marginBottom: 6, color: TS }}>Rename History</div>
          {s.renameHistory.map((r: any, i: number) => <div key={i} style={{ fontSize: 11, color: DIM }}>{r.oldName} → {r.newName} ({new Date(r.changedAt).toLocaleDateString()})</div>)}
        </div>
      )}
    </div>
  )
}

`;
}

function fixFrontend(file, settingsBuilder) {
  let c = fs.readFileSync(file, 'utf8');
  const before = c.length;

  c = mustReplace(c, "['controls', '⚙️ Controls'], ", "", "tabs-array-controls-entry (" + file + ")");
  c = c.replace(/^[ \t]*\{tab === 'controls' && <ControlsTab[^\n]*\n/m, "");
  c = replaceBetween(c, "// ── 10) CONTROLS TAB ──\n", "// ── 11) MATERIALS TAB ──", "");
  c = replaceBetween(c, "// ── 14) SETTINGS TAB ──\n", "// ── 15) AUDIT HISTORY TAB ──", settingsBuilder());

  fs.writeFileSync(file, c, 'utf8');
  console.log(file, '=> OK, size', before, '->', c.length);
}

function fixBackend(file, entityVar, codeField) {
  let c = fs.readFileSync(file, 'utf8');
  const before = c.length;

  c = replaceBetween(
    c,
    "// ══════════════════════════════════════════════════════════════════\n// CONTROLS TAB — system control center\n",
    "// ══════════════════════════════════════════════════════════════════\n// MATERIALS / NOTES TAB",
    ""
  );

  const oldSettingsGet =
`      settings: {
        name: ${entityVar}.name, ${codeField}: ${entityVar}.${codeField}, colorIcon: ${entityVar}.colorIcon,
        startDate: ${entityVar}.startDate, endDate: ${entityVar}.endDate, visibility: ${entityVar}.visibility,
        seatLimit: ${entityVar}.seatLimit, enrollmentRule: ${entityVar}.enrollmentRule,
        autoArchiveAfterEnd: !!${entityVar}.autoArchiveAfterEnd, teacherAssigned: ${entityVar}.teacherAssigned,
        renameHistory: ${entityVar}.renameHistory || [], isLocked: !!${entityVar}.settingsLocked
      }`;
  const newSettingsGet =
`      settings: {
        name: ${entityVar}.name, ${codeField}: ${entityVar}.${codeField}, description: ${entityVar}.description,
        startDate: ${entityVar}.startDate, endDate: ${entityVar}.endDate, visibility: ${entityVar}.visibility,
        seatLimit: ${entityVar}.seatLimit, enrollmentRule: ${entityVar}.enrollmentRule,
        autoArchiveAfterEnd: !!${entityVar}.autoArchiveAfterEnd,
        renameHistory: ${entityVar}.renameHistory || [], isLocked: !!${entityVar}.settingsLocked
      }`;
  c = mustReplace(c, oldSettingsGet, newSettingsGet, "settings-GET-response (" + file + ")");

  fs.writeFileSync(file, c, 'utf8');
  console.log(file, '=> OK, size', before, '->', c.length);
}

const [F1, F2, F3, F4] = process.argv.slice(2);
fixFrontend(F1, buildSettingsTabBatch);
fixFrontend(F2, buildSettingsTabSeries);
fixBackend(F3, 'batch', 'batchCode');
fixBackend(F4, 'series', 'seriesCode');

console.log('ALL DONE');
ENDOFNODESCRIPT

echo ""
echo "=========================================="
echo "STEP 4: Applying fix"
echo "=========================================="
node /tmp/fix_batch_testseries_v1.js "$F1" "$F2" "$F3" "$F4"

echo ""
echo "=========================================="
echo "STEP 5: Verification"
echo "=========================================="
echo "-- Controls tab / route residue (should all be 0) --"
grep -c "ControlsTab" "$F1" "$F2" || true
grep -c "/:id/controls" "$F3" "$F4" || true
echo "-- colorIcon / teacherAssigned in settings GET response (should be 0) --"
grep -c "colorIcon: batch.colorIcon\|teacherAssigned: batch.teacherAssigned" "$F3" || true
grep -c "colorIcon: series.colorIcon\|teacherAssigned: series.teacherAssigned" "$F4" || true
echo "-- New Save & Lock button present (should be >=1 each) --"
grep -c "Save & Lock" "$F1" "$F2" || true

echo ""
echo "✅ DONE. Backend server restart karo aur dev server dubara start karo taaki changes reflect ho."
echo "Agar kuch galat lage to backups se restore kar sakte ho:"
echo "cp $F1.bak_$TS $F1"
echo "cp $F2.bak_$TS $F2"
echo "cp $F3.bak_$TS $F3"
echo "cp $F4.bak_$TS $F4"
