# MAINTENANCE row 105, the Settings PR: targeted mutation battery.
# Two changes in this PR are logic, so each gets a mutation the bar must kill:
#   - row 136's rule applied to SettingsApp.lua's own German table (the table and the language
#     check are gone; T1 must fail if either comes back);
#   - the bar's draw-site rows (S1 over SettingsApp.lua and the two FarmTabletUI frequency getters).
# The rest are text rows the translation leans on (English copied, a placeholder dropped, a label
# renamed while its hint still names the old text, a hint over its row's cut).
# Bob's findings on #181 add two more pieces of logic, each with its mutations:
#   - the palette rows (G1, G2): FT.BG_PALETTE's labels are read from the real Constants.lua, so a
#     palette name with no map entry, or with a key no file carries or still English, fails; and the
#     app must still draw the label through ftAuto;
#   - the helper row (R1): ftSafeText must reach the locale file through a lookup the loaded code
#     defines (FT.l10n), never through a global nothing sets (the old ftUiText);
#   - the executed lookup (X1): the helpers, run in fengari against the real locale files, must
#     return the file's text; X1-helper-asks-the-fallback is the case R1 cannot see (the helper calls
#     FT.l10n, so R1 passes, but asks it for the wrong key).
#
# Each mutation edits one file in place, runs tools/test/l10n-settings-check.mjs and expects it to
# FAIL on a named row; the file is restored byte-identical (sha256-checked) after each one. The bar
# must be green before any run.
# Usage: py tools/test/mutate_l10n_settings.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

def after(anchor, old, new):
    # replace the first `old` that follows the one `anchor`
    def f(t):
        assert t.count(anchor) == 1, (anchor[:60], t.count(anchor))
        i = t.index(anchor)
        j = t.index(old, i)
        return t[:j] + new + t[j + len(old):]
    return f

SAFE = "local function ftSafeText(key, fallback)\n    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(key, fallback) end\n"
SLATE = "    { label = \"Slate Grey\",      color = {0.08, 0.09, 0.12, 0.97} },\n"
NEWPAL = "    { label = \"Sunset Orange\",   color = {0.14, 0.06, 0.02, 0.97} },\n"

MUTATIONS = [
    ("T1-german-table-restored", "src/apps/SettingsApp.lua",
     one(SAFE, "local FT_SETTINGS_DE = { ft_settings_sounds = \"Töne\" }\n"
               "local function ftSafeText(key, fallback)\n"
               "    if FT_SETTINGS_DE[key] ~= nil then return FT_SETTINGS_DE[key] end\n"
               "    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(key, fallback) end\n"),
     "a runtime German table back in front of the locale file"),
    ("T2-language-branch-restored", "src/apps/SettingsApp.lua",
     one(SAFE, "local function ftSafeText(key, fallback)\n"
               "    if g_languageShort == \"de\" and key == \"ft_settings_sounds\" then return \"Töne\" end\n"
               "    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(key, fallback) end\n"),
     "a language branch with no table, answering German before the file"),
    ("S1-drawn-key-outside-the-bar", "src/apps/SettingsApp.lua",
     one("ftSafeText(\"ft_settings_general\", \"General\")", "ftSafeText(\"ft_settings_text_size\", \"General\")"),
     "the app draws a key en carries and this bar never checks (ft_settings_text_size)"),
    ("S1-getter-key-renamed", "src/FarmTabletUI.lua",
     after("function FarmTabletUI:_getSignalOutageFrequencyLabel", "ftUiText(\"ft_common_rare\", \"Rare\")", "ftUiText(\"ft_common_rarely\", \"Rare\")"),
     "the outage-frequency getter draws a key no locale file carries"),
    ("G1-palette-name-unmapped", "src/core/Constants.lua",
     one(SLATE, SLATE + NEWPAL),
     "a palette name added with no FT.AUTO_L10N entry: the Background colour row would read it in English"),
    ("G1-palette-key-missing", "src/core/Constants.lua",
     lambda t: one("    [\"Slate Grey\"] = \"ft_auto_slate_grey\",\n",
                   "    [\"Slate Grey\"] = \"ft_auto_slate_grey\",\n    [\"Sunset Orange\"] = \"ft_auto_sunset_orange\",\n")(one(SLATE, SLATE + NEWPAL)(t)),
     "a palette name added with its map entry, and a key no locale file carries"),
    ("G1-palette-name-english", "translations/translation_fr.xml",
     one("<text name=\"ft_auto_ocean_blue\" text=\"Bleu océan\" />", "<text name=\"ft_auto_ocean_blue\" text=\"Ocean Blue\" />"),
     "a palette name's translation replaced by the English text"),
    ("G2-palette-drawn-raw", "src/apps/SettingsApp.lua",
     one("ftAuto(tostring(bgEntry.label or ftSafeText(\"ft_common_default\", \"Default\")))",
         "tostring(bgEntry.label or ftSafeText(\"ft_common_default\", \"Default\"))"),
     "the Background colour row draws the palette label raw, not through ftAuto"),
    ("R1-helper-dead-global", "src/apps/SettingsApp.lua",
     one(SAFE, "local function ftSafeText(key, fallback)\n    if ftUiText ~= nil then return ftUiText(key, fallback) end\n"),
     "ftSafeText back on ftUiText, a local of FarmTabletUI.lua: every row reads its English fallback"),
    ("R1-format-helper-dead-global", "src/apps/SettingsApp.lua",
     one("    if FT ~= nil and FT.l10nFormat ~= nil then return FT.l10nFormat(key, fallback, ...) end\n",
         "    if ftUiFormat ~= nil then return ftUiFormat(key, fallback, ...) end\n"),
     "ftSafeFormat back on ftUiFormat, a local of FarmTabletUI.lua: every formatted row reads English"),
    ("X1-helper-asks-the-fallback", "src/apps/SettingsApp.lua",
     one(SAFE, "local function ftSafeText(key, fallback)\n    if FT ~= nil and FT.l10n ~= nil then return FT.l10n(fallback, fallback) end\n"),
     "ftSafeText calls FT.l10n (so R1 passes) but looks up its fallback, not its key"),
    ("E1-english-copied", "translations/translation_fr.xml",
     one("<text name=\"ft_settings_sounds\" text=\"Sons\" />", "<text name=\"ft_settings_sounds\" text=\"Sounds\" />"),
     "a translated label replaced by the English text"),
    ("P1-placeholder-dropped", "translations/translation_fr.xml",
     one("<text name=\"ft_price_per_day\" text=\"%d €/jour\" />", "<text name=\"ft_price_per_day\" text=\"€/jour\" />"),
     "the daily fee loses its %d, so string.format gets an argument it never prints"),
    ("C1-label-renamed", "translations/translation_fr.xml",
     one("<text name=\"ft_common_frequent\" text=\"Fréquent\" />", "<text name=\"ft_common_frequent\" text=\"Souvent\" />"),
     "the Frequent label renamed while the frequency hint still names Fréquent"),
    ("L1-hint-over-its-cut", "translations/translation_fr.xml",
     one("<text name=\"ft_settings_hint_reset_all\" text=\"Réinitialise tous les paramètres de la tablette.\" />",
         "<text name=\"ft_settings_hint_reset_all\" text=\"Réinitialise tous les paramètres de la tablette, position et taille comprises.\" />"),
     "a hint longer than its row's cut of 66 characters"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "l10n-settings-check.mjs")],
                       capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:120])
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
