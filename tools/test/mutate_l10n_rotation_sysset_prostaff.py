# MAINTENANCE row 105, batch 1 (Rotation Planner, System Settings, Pro-Staff Co-Op): targeted mutation battery.
# The logic in this PR: map entries for drawn literals (Constants.lua), and texts the apps build at run time moved
# onto named keys (FT.l10n / FT.l10nFormat). Each mutation undoes one piece, or breaks one text row the
# translation leans on, and the bar tools/test/l10n-rotation-sysset-prostaff-check.mjs must FAIL on a named row.
# Each file is restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# MAINTENANCE row 142 part 3 adds P3a to P3d: the Pro-Staff level name through ProStaff's own getter, the
# bar's X2 row.
# Usage: py tools/test/mutate_l10n_rotation_sysset_prostaff.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-rotation-sysset-prostaff-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("R1-count-back-to-format", "src/apps/RotationPlannerApp.lua",
     one('FT.l10nFormat("ft_rotation_field_count", "%d fields · same engine as soil foresight", #fields)',
         'string.format("%d fields · same engine as soil foresight", #fields)'),
     "the field count line built by string.format again: S3 (and S4, its key no longer drawn)"),
    ("R2-map-entry-dropped", "src/core/Constants.lua",
     one('FT.AUTO_L10N["WHERE DO I STAND"] = "ft_rotation_help_stand_title"\n', ""),
     "a help title loses its map entry: S2"),
    ("R3-fallback-text-literal", "src/apps/RotationPlannerApp.lua",
     one('FT.l10n("ft_rotation_no_change", "no change")', '"no change"'),
     "the no-change text drawn as a bare literal: S4 (its key no longer drawn)"),
    ("P1-modifier-label-literal", "src/apps/ProStaffApp.lua",
     one('try(FT.l10n("ft_prostaff_mod_wage_cost", "Wage cost"), ', 'try("Wage cost", '),
     "a modifier label back to an English literal: S4"),
    ("P2-on-line-concatenated", "src/apps/ProStaffApp.lua",
     one('FT.l10nFormat("ft_prostaff_mod_on", "%s: on", label)', 'label .. ": on"'),
     "the 'label: on' line concatenated in English again: S4"),
    ("P3-level-none-literal", "src/apps/ProStaffApp.lua",
     one('FT.l10n("ft_prostaff_level_none", "None")', '"None"'),
     "the level name None back to a literal: S4"),
    ("C1-button-renamed", "translations/translation_fr.xml",
     one('<text name="ft_prostaff_buy_next_level" text="ACHETER LE NIVEAU SUIVANT" />',
         '<text name="ft_prostaff_buy_next_level" text="PASSER AU NIVEAU SUIVANT" />'),
     "the BUY NEXT LEVEL button renamed while the help still names the old text: CONTAINS"),
    ("C2-switch-renamed", "translations/translation_fr.xml",
     one('<text name="ft_auto_on_2" text="Activé" />', '<text name="ft_auto_on_2" text="Allumé" />'),
     "the On switch renamed while the help still names the old text: CONTAINS"),
    ("E1-english-copied", "translations/translation_fr.xml",
     one('<text name="ft_prostaff_membership" text="ADHÉSION" />', '<text name="ft_prostaff_membership" text="MEMBERSHIP" />'),
     "a translated label replaced by the English text: the text row"),
    ("K1-romanised", "translations/translation_jp.xml",
     one('<text name="ft_prostaff_invested" text="投資額" />', '<text name="ft_prostaff_invested" text="Toushigaku" />'),
     "a Japanese value written in Latin letters: the script row"),
    ("F1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_prostaff_level_n" text="Stufe %d" />', '<text name="ft_prostaff_level_n" text="Stufe" />'),
     "the level name loses its %d: the placeholder row"),
    ("X1-lookup-never-reaches-file", "src/core/Constants.lua",
     one("    if g_i18n ~= nil and key ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText(key) then\n        local text = g_i18n:getText(key)",
         "    if false and g_i18n ~= nil and key ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText(key) then\n        local text = g_i18n:getText(key)"),
     "FT.l10n stops reading the locale file: every lookup returns its English fallback: X1"),
    # MAINTENANCE row 142 part 3: _levelName asks ProStaff's getLevelDisplayName (X2). Run with the prefix P3.
    ("P3a-getter-skipped", "src/apps/ProStaffApp.lua",
     one("    local mgr = _ps()\n    if type(mgr) == \"table\" and type(mgr.getLevelDisplayName) == \"function\" then",
         "    local mgr = nil\n    if type(mgr) == \"table\" and type(mgr.getLevelDisplayName) == \"function\" then"),
     "the level name never asks ProStaff: English in every language: X2"),
    ("P3b-dot-call", "src/apps/ProStaffApp.lua",
     one("pcall(mgr.getLevelDisplayName, mgr, level)", "pcall(mgr.getLevelDisplayName, level)"),
     "the getter is called with the level as self: X2"),
    ("P3c-no-pcall", "src/apps/ProStaffApp.lua",
     one("        local ok, name = pcall(mgr.getLevelDisplayName, mgr, level)\n",
         "        local ok, name = true, mgr:getLevelDisplayName(level)\n"),
     "a getter that raises takes the tablet page down: X2"),
    ("P3d-empty-answer-kept", "src/apps/ProStaffApp.lua",
     one("        if ok and type(name) == \"string\" and name ~= \"\" then return name end\n",
         "        if ok and type(name) == \"string\" then return name end\n"),
     "an empty answer is drawn as the level name: X2"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", BAR], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:140])
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
    open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
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
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
