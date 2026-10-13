# MAINTENANCE row 105, batch 8 (Organic Management): targeted mutation battery.
# The logic in this PR: every Organic text moved onto a named key (FT.l10n, FT.l10nFormat), the texts it
# built at run time from English (string.format) moved onto FT.l10nFormat, the compost batch's "day(s)"
# became a key per form, and the three certification states gained map entries so the renderer's
# FT.l10nAuto reaches them (drawnTables). Each mutation undoes one piece, or breaks one text row the
# translation leans on, and the bar tools/test/l10n-organic-check.mjs must FAIL on a named row. Each file
# is restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_organic.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-organic-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("O1-help-body-literal", "src/apps/OrganicApp.lua",
     one('body  = FT.l10n("ft_organic_help_later_body", ', 'body  = ('),
     "a help body drawn as a literal again: S2, S4"),
    ("O2-state-map-entry-gone", "src/core/Constants.lua",
     one('FT.AUTO_L10N["Certified"] = "ft_auto_certified"', '-- (no Certified entry)'),
     "a certification state without its map entry: S2 (drawnTables), S4"),
    ("O3-field-label-format", "src/apps/OrganicApp.lua",
     one('FT.l10nFormat("ft_organic_field_fmt", "Field #%s", tostring(field.id))', 'string.format("Field #%s", tostring(field.id))'),
     "a field label built by string.format again: S3"),
    ("O4-countdown-format", "src/apps/OrganicApp.lua",
     one('FT.l10nFormat("ft_organic_countdown_fmt", ', 'string.format('),
     "the transition countdown built by string.format again: S4"),
    ("O5-practice-line-literal", "src/apps/OrganicApp.lua",
     one('FT.l10n("ft_organic_practice_om_low", "OM low - plow in manure/compost or chop straw.")', '"OM low - plow in manure/compost or chop straw."'),
     "a practice advice line as an English literal: S4"),
    ("O6-batch-days-plural-back", "src/apps/OrganicApp.lua",
     one('FT.l10nFormat("ft_organic_batch_days_left_fmt", "%d days left", days)', 'string.format("%d day(s) left", days)'),
     "the compost days left built by string.format again: S4"),
    ("O7-opt-in-literal", "src/apps/OrganicApp.lua",
     one('FT.l10n("ft_organic_opt_in", "OPT IN")', '"OPT IN"'),
     "the OPT IN button drawn as a literal: S2, S4"),
    ("O8-barn-format", "src/apps/OrganicApp.lua",
     one('FT.l10nFormat("ft_organic_barn_fmt", "Barn %s", tostring(barn.barnId))', 'string.format("Barn %s", tostring(barn.barnId))'),
     "the barn label built by string.format again: S3, S4"),
    ("O9-market-literal", "src/apps/OrganicApp.lua",
     one('FT.l10n("ft_organic_market_na", "not available - waiting on organic premium / MDM contract")', '"not available - waiting on organic premium / MDM contract"'),
     "the market stub drawn as a literal: S2, S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_organic_countdown_fmt" text="%d / %d Tage  (noch %d)" />', '<text name="ft_organic_countdown_fmt" text="%d / %d Tage" />'),
     "a German value loses a placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_organic_herd_health" text="群れの健康" />', '<text name="ft_organic_herd_health" text="mure no kenkou" />'),
     "a Japanese value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_fr.xml",
     one('<text name="ft_organic_opt_out" text="SE RETIRER" />', '<text name="ft_organic_opt_out" text="OPT OUT" />'),
     "a French value reverted to the English text: the text rows"),
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
