# MAINTENANCE row 105, batch 15 (Akita: FactoryWeekSchedule and RealisticDealer): targeted mutation battery.
# The logic in this PR: the tablet's own words on the factory and contract cards (a fallback name, "No event", a
# contract's status, the installments line) are drawn as the file has them, and the mod's own texts keep the
# renderer's pass; a factory's Open is its own key (ft_common_open is the Settings button's verb, German "Öffnen").
# The data: 232 values the Akita83 import wrote with their accents stripped are restored (ACCENT), and the section
# headers stay capitals (CASE). Each mutation undoes one piece, and a bar must FAIL on a named row:
# tools/test/l10n-akita-factory-dealer-check.mjs for the text rows, tools/test/renderer-literal-flag-check.mjs for the
# drawers (its E case drives the real drawers through the real renderer). Both bars run for every mutation. Each file
# is restored byte-identical (sha256-checked) after each run. Both bars must be green before any run.
# Usage: py tools/test/mutate_l10n_akita_factory_dealer.py [id-prefix ...]
import hashlib, os, subprocess, sys

# Failure lines quote locale text (Vietnamese, Cyrillic); a piped Windows console is cp1252.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "l10n-akita-factory-dealer-check.mjs"),
        os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs")]
APP = "src/apps/AkitaTabletIntegrationsApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("C1-state-is-the-settings-verb", APP,
     one('fac.isOpen == true and ftAkitaText("ft_fws_state_open", "Open")', 'fac.isOpen == true and ftAkitaText("ft_common_open", "Open")'),
     "a factory's Open drawn from the Settings button's verb again (German Öffnen): E (open state), S1, S4"),
    ("C2-factory-name-flag-dropped", APP,
     one('FT_Renderer.truncate(name, 20), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, modName == nil)',
         'FT_Renderer.truncate(name, 20), RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)'),
     "a factory's fallback name handed to the renderer's second pass: E (FLAG)"),
    ("C3-no-event-flag-dropped", APP,
     one('event ~= "" and FT.C.WARNING or FT.C.TEXT_NORMAL, noLine)', 'event ~= "" and FT.C.WARNING or FT.C.TEXT_NORMAL)'),
     "a factory's \"No event\" handed to the renderer's second pass: E (FLAG)"),
    ("C4-vehicle-name-flag-dropped", APP,
     one('FT.FONT.BODY, name, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, modName == nil)', 'FT.FONT.BODY, name, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)'),
     "a contract's fallback name handed to the renderer's second pass: E (FLAG)"),
    ("C5-status-flag-dropped", APP,
     one('status, RenderText.ALIGN_RIGHT, statusColor, statusLiteral)', 'status, RenderText.ALIGN_RIGHT, statusColor)'),
     "a contract's status handed to the renderer's second pass: E (FLAG)"),
    ("C6-installments-flag-dropped", APP,
     one('inst, RenderText.ALIGN_LEFT, missed > 0 and FT.C.WARNING or FT.C.TEXT_DIM, true)', 'inst, RenderText.ALIGN_LEFT, missed > 0 and FT.C.WARNING or FT.C.TEXT_DIM)'),
     "the installments line handed to the renderer's second pass: E (FLAG)"),
    ("C7-paid-status-lost", APP,
     one('    if st == "paid" then return ftAkitaText("ft_rd_status_paid", "Paid"), true end\n', ''),
     "a paid contract drawn with the mod's raw \"paid\": E (paid status), S4"),
    ("T1-french-accents-stripped", "translations/translation_fr.xml",
     one('<text name="ft_fws_fire_system" text="Système incendie" />', '<text name="ft_fws_fire_system" text="Systeme incendie" />'),
     "a French value back to the import's stripped text: ACCENT"),
    ("T2-czech-accents-stripped", "translations/translation_cz.xml",
     one('<text name="ft_rd_status_repossession" text="Probíhá zabavení" />', '<text name="ft_rd_status_repossession" text="Probiha zabaveni" />'),
     "a Czech value back to the import's stripped text: ACCENT"),
    ("T3-german-state-is-the-verb", "translations/translation_de.xml",
     one('<text name="ft_fws_state_open" text="Geöffnet" />', '<text name="ft_fws_state_open" text="Öffnen" />'),
     "German's factory state written as the Settings verb: STATE, E"),
    ("T4-polish-header-lower-case", "translations/translation_pl.xml",
     one('<text name="ft_rd_contracts" text="UMOWY" />', '<text name="ft_rd_contracts" text="Umowy" />'),
     "Polish CONTRACTS header in lower case: CASE"),
    ("T6-french-canadian-chinese-again", "translations/translation_fc.xml",
     one('<text name="ft_rd_contracts" text="CONTRATS" />', '<text name="ft_rd_contracts" text="合同" />'),
     "a French Canadian value back in Simplified Chinese (Bob's #202 BLOCKER): SCRIPT-OUT"),
    ("T5-new-key-missing", "translations/translation_sv.xml",
     one('        <text name="ft_fws_state_open" text="Öppen" />\n', ''),
     "a locale file without the new state key: the text rows"),
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
