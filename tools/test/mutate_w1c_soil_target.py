# SF-73 section 7, W1c and its last-pause follow-on: the Soil app's AUTO target block, targeted mutation battery (Tyson, 2026-09-25 and
# 2026-09-30: only the lines this PR adds). Each mutation undoes one piece of src/apps/SoilNutrientApp.lua, and a bar
# must FAIL on a named row: tools/test/soil-target-block-check.mjs (the block, drawn through the real registry over
# a recorder of Soil's reads) and tools/test/l10n-soil-nutrient-check.mjs (the text rows). Both bars run for every
# mutation. The file is restored byte-identical (sha256-checked) after each run. The bars must be green before any
# run. Usage: py tools/test/mutate_w1c_soil_target.py [id-prefix ...]
#
# NOT RUN, and why:
#   - _soilRead's method check: without it, pcall of nil fails and the read answers nil the same way;
#   - the nil-report return in _targetBlock: without it, indexing nil errors inside the call site's pcall, which
#     draws today's card the same way (rows L1 and L2 pin that card);
#   - the call site's pcall itself: no Soil shape the bar can build makes _targetBlock throw (X1 pins a read
#     that throws, which _soilRead's own pcall catches);
#   - _playerFarmland's id > 0 test: farmland 0 is no card's member, so it draws nothing either way;
#   - _firstReason's own fallbacks (one reason missing, the same reason twice, Soil naming neither): Soil names
#     one of two reasons it knows, and every reason the tablet words is one it knows;
#   - the local line's knowledgeState test: Soil sets a nutrient's grainMetres only when it is KNOWN;
#   - the block's height (tgtH): layout, not text (the in-game check names overlap);
#   - the colours: presentation (the in-game check);
#   - the pause read's method check: without it, _soilRead answers nil the same way (Q10 pins the older Soil);
#   - comments and the header.
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "soil-target-block-check.mjs"),
        os.path.join(ROOT, "tools", "test", "l10n-soil-nutrient-check.mjs")]
APP = "src/apps/SoilNutrientApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("M01-another-farms-machine", APP,
     one("        if okO and owner == farmId then\n", "        if okO then\n"),
     "another farm's machine drawn on this farm's card (R4)"),
    ("M02-parked-machine", APP,
     one('if type(r) == "table" and r.active == true and type(r.fieldId) == "number" then',
         'if type(r) == "table" and type(r.fieldId) == "number" then'),
     "a parked machine's last result drawn as a current pause (R3)"),
    ("M03-later-reason-wins", APP,
     one("    if pick == a or pick == b then return pick end\n",
         "    if pick == a or pick == b then return (pick == a) and b or a end\n"),
     "two machines: the reason Soil puts second (R5, P12)"),
    ("M04-list-order-decides", APP,
     one("                    out[r.fieldId] = _firstReason(soilSys, out[r.fieldId], reason)\n",
         "                    out[r.fieldId] = reason\n"),
     "two machines: whichever the list walks last (R5)"),
    ("M05-window-always", APP,
     one('    if rel.cropKey ~= nil and type(rel.nutrients) == "table" then\n',
         '    if type(rel.nutrients) == "table" then\n'),
     "no crop window drawn as a window of question marks (W1)"),
    ("M06-near-reads-ok", APP,
     one('    APPROACHING  = { key = "ft_soiltgt_rel_near",  fallback = "near" },',
         '    APPROACHING  = { key = "ft_soiltgt_rel_ok",  fallback = "ok" },'),
     "a relationship word drawn as another (E1)"),
    ("M07-local-on-every-card", APP,
     one("    if here ~= nil and isMember[here.id] then\n", "    if here ~= nil then\n"),
     "the local line on a card the player is not on (E4, H2)"),
    ("M08-another-crops-pass", APP,
     one(" and p.cropKey ~= nil and p.cropKey == rel.cropKey\n", "\n"),
     "another crop's pass shown as this crop's (P6)"),
    ("M09-oldest-pass", APP,
     one("(tonumber(p.notedAt) or 0) > (tonumber(pass.notedAt) or 0)", "(tonumber(p.notedAt) or 0) < (tonumber(pass.notedAt) or 0)"),
     "a merged field shows its oldest pass (P8)"),
    ("M10-lead-only-pass", APP,
     one('    if passRead then\n        for _, id in ipairs(members) do\n',
         '    if passRead then\n        for _, id in ipairs({ card.id }) do\n'),
     "a member's pass never reaches the lead's card (P8)"),
    ("M11-none-without-the-read", APP,
     one('    local passRead = type(soilSys.getLastTargetPassForField) == "function"\n', "    local passRead = true\n"),
     "a Soil without the pass read draws 'none' (P10)"),
    ("M12-no-estimate-label", APP,
     one("            hasPass = true\n", ""),
     "a confirmed dose beside an unlabelled plan (E2)"),
    ("M13-estimate-without-dose", APP,
     one("local planTitle = (tgt ~= nil and tgt.hasPass)", "local planTitle = (tgt ~= nil)"),
     "the plan labelled an estimate where no dose was confirmed (E5, P7)"),
    ("M14-binding-note-is-scope", APP,
     one('            if pass.doseState == "SHORT_BINDING" then\n', '            if false then\n'),
     "a blend-limited pass loses the nutrient it would overshoot (P1)"),
    ("M15-failed-note-is-scope", APP,
     one('            elseif pass.doseState == "APPLICATION_FAILED" then\n', '            elseif false then\n'),
     "a failed write loses 'not confirmed' (P5)"),
    ("M16-lead-only-pause", APP,
     one("    for _, id in ipairs(members) do reason = _firstReason(soilSys, reason, live[id]) end\n",
         "    for _, id in ipairs({ card.id }) do reason = _firstReason(soilSys, reason, live[id]) end\n"),
     "a machine paused on a member never reaches the lead's card (P9, P12)"),
    ("M17-block-unflagged", APP,
     one("RenderText.ALIGN_LEFT, line.color or FT.C.TEXT_NORMAL, true)", "RenderText.ALIGN_LEFT, line.color or FT.C.TEXT_NORMAL)"),
     "resolved block text handed to the renderer without the literal flag (F1)"),
    ("M18-litres-format", APP,
     one('return string.format(math.abs(x) < 10 and "%.2f" or "%.1f", x)', 'return string.format(math.abs(x) < 100 and "%.2f" or "%.1f", x)'),
     "litres drawn unlike the host's (P1)"),
    ("M19-pass-read-unguarded", APP,
     one('            local p = _soilRead(soilSys, "getLastTargetPassForField", id)\n',
         '            local p = soilSys:getLastTargetPassForField(id)\n'),
     "a Soil read that throws takes the block down (X1)"),
    ("M20-local-needs-a-crop", APP,
     one("        if grain ~= nil then\n", "        if grain ~= nil and loc.cropKey ~= nil then\n"),
     "a map reading where nothing grows said as no reading (H5)"),
    # the Tablet's last pause (Soil #1090's read, the PDA card's rules)
    ("M21-denied-access-pause", APP,
     one('                if x == "FARM_ACCESS" then denied = true end\n', '                if false then denied = true end\n'),
     "a pause naming denied access drawn as this farm's (Q7)"),
    ("M22-pause-any-crop", APP,
     one(" and not denied and q.fieldCrop ~= nil and q.fieldCrop == rel.cropKey\n", " and not denied\n"),
     "a pause noted under another crop drawn on the resown field (Q6)"),
    ("M23-pause-always-wins", APP,
     one("        if pause ~= nil and pass ~= nil and not ((tonumber(pause.notedAt) or 0) > (tonumber(pass.notedAt) or 0)) then\n"
         "            pause = nil\n        end\n", ""),
     "an older pause hides a newer pass (Q4, Q5)"),
    ("M24-tie-to-the-pause", APP,
     one("not ((tonumber(pause.notedAt) or 0) > (tonumber(pass.notedAt) or 0))", "not ((tonumber(pause.notedAt) or 0) >= (tonumber(pass.notedAt) or 0))"),
     "a tie goes to the pause (Q5)"),
    ("M25-oldest-pause", APP,
     one("(pause == nil or (tonumber(q.notedAt) or 0) > (tonumber(pause.notedAt) or 0))", "(pause == nil or (tonumber(q.notedAt) or 0) < (tonumber(pause.notedAt) or 0))"),
     "a merged field shows its oldest pause (Q13)"),
    ("M26-pause-reads-as-none", APP,
     one('    line = { key = "ft_soiltgt_state_paused", fallback = "Last pause: no growing crop" },',
         '    line = { key = "ft_soiltgt_state_none", fallback = "Last pass: none on this crop" },'),
     "the pause line reads as no pass (Q1, Q3)"),
    ("M27-pause-is-a-dose", APP,
     one("        add(_tgtText(TGT_PAUSE.note.key, TGT_PAUSE.note.fallback), FT.C.TEXT_DIM)\n",
         "        add(_tgtText(TGT_PAUSE.note.key, TGT_PAUSE.note.fallback), FT.C.TEXT_DIM)\n        hasPass = true\n"),
     "a pause labels the plan an estimate as if a dose were confirmed (Q2)"),
    ("M28-pause-unflagged-note", APP,
     one("        add(_tgtText(TGT_PAUSE.note.key, TGT_PAUSE.note.fallback), FT.C.TEXT_DIM)\n", ""),
     "the pause loses its manual hint (Q1)"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bars():
    rc, out = 0, []
    for bar in BARS:
        r = subprocess.run(["node", bar], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
        rc = rc or r.returncode
        out += (r.stdout + r.stderr).strip().splitlines()
    return rc, out

only = sys.argv[1:]
rc, out = run_bars()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", " / ".join(l[:70] for l in out if ": PASS" in l))
killed = survived = bad = 0
for mid, rel, fn, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only): continue
    path = os.path.join(ROOT, rel)
    before = sha(path)
    raw = open(path, "rb").read()
    crlf = b"\r\n" in raw
    t = raw.decode("utf-8").replace("\r\n", "\n")
    try:
        t2 = fn(t)
    except (AssertionError, ValueError) as e:
        print("  BAD EDIT %s (%s)" % (mid, e)); bad += 1; continue
    if t2 == t:
        print("  BAD EDIT %s (the edit changed nothing)" % mid); bad += 1; continue
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bars()
    finally:
        open(path, "wb").write(raw)
        assert sha(path) == before, "restore failed for " + rel
    fails = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and fails:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in fails[:3]: print("        " + l[:170])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: a bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
