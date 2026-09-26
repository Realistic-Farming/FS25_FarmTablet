# MAINTENANCE row 105, the final fc sweep: targeted mutation battery.
# The work in this PR: French Canadian's remaining Chinese values in French (61, Irrigation Suite's among them) and
# its modDesc input text, the 50 "[EN]"-stamped Irrigation Suite lock lines translated again (Wizard's English, the
# Pro Staff Co-Op), Latin American Spanish's "financiación", and RSF-F166's flag on row 158's six named sites (the
# Organic fallback only, and FactoryWeekSchedule's day and time only when a time comes with it). Each mutation undoes
# one piece, and a bar must FAIL on a named row: tools/test/l10n-tree-check.mjs for the text rows,
# tools/test/renderer-literal-flag-check.mjs for the drawers (its row 158 E case walks each site's real route). Both
# bars run for every mutation. Each file is restored byte-identical (sha256-checked) after each run. Both bars must be
# green before any run.
# Usage: py tools/test/mutate_l10n_fc_sweep.py [id-prefix ...]
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "l10n-tree-check.mjs"),
        os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs")]

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("C1-animals-header-flag-dropped", "src/apps/AnimalHusbandryApp.lua",
     one("pen.numAnimals > 0 and FT.C.TEXT_BRIGHT or FT.C.TEXT_DIM, true)", "pen.numAnimals > 0 and FT.C.TEXT_BRIGHT or FT.C.TEXT_DIM)"),
     "the pen header (a type name DataProvider resolved) handed to the second pass: E (FLAG, pen header)"),
    ("C2-field-label-flag-dropped", "src/apps/FieldJobsApp.lua",
     one("FT.FONT.SMALL, label, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT, true)", "FT.FONT.SMALL, label, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)"),
     "Field Jobs' field label handed to the second pass: E (FLAG, field label)"),
    ("C3-hotspot-status-flag-dropped", "src/apps/HotspotManagerApp.lua",
     one("RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT, true)\n        y = y - FT.py(14)", "RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)\n        y = y - FT.py(14)"),
     "Hotspot Manager's held status message handed to the second pass: E (status message)"),
    ("C4-organic-fallback-flag-dropped", "src/apps/OrganicApp.lua",
     one("FT.C.NEGATIVE, barn.feedDiseaseCropName == nil)", "FT.C.NEGATIVE)"),
     "Organic's feed-disease fallback handed to the second pass: E (FLAG, fallback)"),
    ("C5-organic-mod-text-flagged", "src/apps/OrganicApp.lua",
     one("FT.C.NEGATIVE, barn.feedDiseaseCropName == nil)", "FT.C.NEGATIVE, true)"),
     "DairyCore's disease id drawn with the flag, losing the pass the ruling keeps for mod text: E (DairyCore's id)"),
    ("C6-personnel-message-flag-dropped", "src/apps/PersonnelApp.lua",
     one("self._psMsg, RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT, true)", "self._psMsg, RenderText.ALIGN_LEFT, FT.C.TEXT_ACCENT)"),
     "Personnel's held message handed to the second pass: E (reroll message)"),
    ("C7-fws-time-flag-dropped", "src/apps/AkitaTabletIntegrationsApp.lua",
     one("nil, nil, true, fwsView.hudTimeText ~= nil)", "nil, nil, true)"),
     "FactoryWeekSchedule's day and time through the second pass, 06:00 split: E (day and time)"),
    ("C8-fws-day-always-flagged", "src/apps/AkitaTabletIntegrationsApp.lua",
     one("nil, nil, true, fwsView.hudTimeText ~= nil)", "nil, nil, true, true)"),
     "FactoryWeekSchedule's day with no time drawn with the flag, losing the mod text's pass: E (day with no time)"),
    ("T1-fc-network-back-to-chinese", "translations/translation_fc.xml",
     one('<text name="ft_network_recovered" text="%s : signal rétabli." />', '<text name="ft_network_recovered" text="%s：信号已恢复。" />'),
     "a French Canadian value no batch owns back in Chinese: SCRIPT-OUT"),
    ("T2-fc-irrigation-back-to-chinese", "translations/translation_fc.xml",
     one('<text name="ft_water_dry" text="À sec" />', '<text name="ft_water_dry" text="干涸" />'),
     "one of Irrigation Suite's French Canadian values back in Chinese: SCRIPT-OUT"),
    ("T3-moddesc-fc-back-to-chinese", "modDesc.xml",
     one("<fc>Afficher/Masquer la Tablette</fc>", "<fc>打开/关闭农场平板</fc>"),
     "modDesc's French Canadian input text back in Chinese: SCRIPT-OUT (modDesc)"),
    ("T4-en-marker-back", "translations/translation_de.xml",
     one('<text name="ft_irr_advisory_locked_l7" text="Freigeschaltet mit der Pro Staff Co-Op ab Level 7" />',
         '<text name="ft_irr_advisory_locked_l7" text="[EN] Unlocks with Pro Staff Co-Op at level 7" />'),
     "a lock line stamped \"[EN]\" again: MARKER"),
    ("T5-lock-line-loses-the-name", "translations/translation_fr.xml",
     one('<text name="ft_irr_advisory_locked_l18" text="Débloqué avec la coopérative Pro Staff au niveau 18" />',
         '<text name="ft_irr_advisory_locked_l18" text="Débloqué au niveau de coopérative 18" />'),
     "a lock line back to the old wording without the Pro Staff Co-Op: LOCK"),
    ("T6-ea-accent-stripped", "translations/translation_ea.xml",
     one("RealisticDealer: financiación,", "RealisticDealer: financiacion,"),
     "Latin American Spanish's RealisticDealer description stripped again: ACCENT"),
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
