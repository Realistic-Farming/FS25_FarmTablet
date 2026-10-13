# MAINTENANCE row 105, batch 9 (Soil Nutrient): targeted mutation battery.
# The logic in this PR: every Soil Nutrient text moved onto a named key (FT.l10n, FT.l10nFormat), the texts it
# built at run time from English (string.format) moved onto FT.l10nFormat, the chips measure the drawn word,
# and the drawn em dashes went. Each mutation undoes one piece, or breaks one text row the translation leans
# on, and the bar tools/test/l10n-soil-nutrient-check.mjs must FAIL on a named row. Each file is restored
# byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_soil_nutrient.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-soil-nutrient-check.mjs")
APP = "src/apps/SoilNutrientApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("N1-help-body-literal", APP,
     one('body  = FT.l10n("ft_soilnut_help_colours_body", ', 'body  = ('),
     "a help body drawn as a literal again: S2, S4"),
    ("N2-fields-heading-format", APP,
     one('FT.l10nFormat("ft_soilnut_fields_fmt", ', 'string.format('),
     "the FIELDS heading built by string.format again: S3, S4"),
    ("N3-field-title-format", APP,
     one('FT.l10nFormat("ft_soilnut_field_title_fmt", ', 'string.format('),
     "the card title built by string.format again: S4"),
    ("N4-urgent-chip-literal", APP,
     one('return FT.l10n("ft_soilnut_urgent", "URGENT")', 'return "URGENT"'),
     "the URGENT chip as an English literal: S4"),
    ("N5-treatment-line-literal", APP,
     one('FT.l10n("ft_soilnut_tr_lime", "Apply LIME or LIQUID LIME to raise pH.")', '"Apply LIME or LIQUID LIME to raise pH."'),
     "a treatment line as an English literal: S4"),
    ("N6-area-format", APP,
     one('FT.l10nFormat("ft_auto_1f_ha", "%.1f ha", card.area)', 'string.format("%.1f ha", card.area)'),
     "the area line built by string.format again (Bob's :492): S4"),
    ("N7-fert-chip-literal", APP,
     one('local fertTxt = FT.l10n("ft_soilnut_fert", "FERT")', 'local fertTxt = "FERT"'),
     "the FERT chip as an English literal: S4"),
    ("N8-unscouted-literal", APP,
     one('FT.l10n("ft_soilnut_unscouted", "Unscouted")', '"Unscouted"'),
     "the Unscouted disease value as an English literal: S4"),
    ("N9-no-data-line-literal", APP,
     one('FT.l10n("ft_soilnut_no_soil_data_field", "No soil data for this field.")', '"No soil data for this field."'),
     "the no-data line drawn as a literal: S2, S4"),
    ("N10-em-dash-back", APP,
     one('return { { label = "-", text = FT.l10n("ft_soilnut_tr_no_data"', 'return { { label = "' + chr(0x2014) + '", text = FT.l10n("ft_soilnut_tr_no_data"'),
     "an em dash drawn again as a row label: S2"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_soilnut_field_title_fmt" text="Feld #%s  ·  %s" />', '<text name="ft_soilnut_field_title_fmt" text="Feld #%s" />'),
     "a German value loses a placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_soilnut_weed" text="雑草" />', '<text name="ft_soilnut_weed" text="zassou" />'),
     "a Japanese value written in Latin letters: the script row, the CONTAINS row"),
    ("T3-english-copy", "translations/translation_fr.xml",
     one('<text name="ft_soilnut_treatment_plan" text="PLAN DE TRAITEMENT" />', '<text name="ft_soilnut_treatment_plan" text="TREATMENT PLAN" />'),
     "a French value reverted to the English text: the text rows, the CONTAINS row"),
    ("T4-help-misnames-chip", "translations/translation_es.xml",
     one('amarillo VIGILAR', 'amarillo ATENCIÓN'),
     "a Spanish help line naming a chip word the screen does not draw: the CONTAINS row"),
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
