# MAINTENANCE row 153 (Farm Admin money buttons): targeted mutation battery.
# The logic in this PR: the four money labels and the MONEY help line take the currency symbol from the
# player's money setting (g_i18n:getCurrencySymbol(true)) through one key per amount, "$" only without
# g_i18n, and the four "+$" map entries and their keys are gone. Each mutation undoes one piece, or
# breaks one text row the translation leans on, and a bar must FAIL on a named row: the entry-point bar
# tools/test/farmadmin-currency-check.mjs, or the app's text bar l10n-farmadmin-personnel-check.mjs.
# Each file is restored byte-identical (sha256-checked) after each run. Both bars must be green first.
# Usage: py tools/test/mutate_farmadmin_currency.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", b) for b in ("farmadmin-currency-check.mjs", "l10n-farmadmin-personnel-check.mjs")]
APP = "src/apps/FarmAdminApp.lua"
BS = chr(92)   # a backslash, spelled so no transport can collapse it

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("C1-hardcoded-label", APP,
     one('label = FT.l10nFormat("ft_farmadmin_money_1k_fmt",   "+%s1K",   sym)', 'label = "+$1K"'),
     "the first button's old hardcoded label: U1, U2, U3, U4, S2, S4"),
    ("C2-literal-symbol", APP,
     one('"+%s10K",  sym)', '"+%s10K",  "$")'),
     "a literal symbol handed to the format: U1 to U4"),
    ("C3-language-symbol", APP,
     one('return g_i18n:getCurrencySymbol(true) end', 'return g_i18n:getText("unit_dollarShort") end'),
     "the symbol read from a text, not the money setting: U1 to U4"),
    ("C4-long-name", APP,
     one('return g_i18n:getCurrencySymbol(true) end', 'return g_i18n:getCurrencySymbol(false) end'),
     "the unit's long name (Euro) in place of its symbol: U1 to U4"),
    ("C5-dollar-fallback", APP,
     one('"+%s100K", sym)', '"+$100K", sym)'),
     "a fallback with the dollar written in: U4"),
    ("C6-help-without-list", APP,
     one('FT.l10nFormat("ft_farmadmin_help_money_fmt", "Adds funds to your farm account.' + BS + 'nAmounts: %s",' + chr(10)
         + '              table.concat(amountLabels, " · "))',
         'FT.l10n("ft_farmadmin_help_money_fmt", "Adds funds to your farm account.' + BS + 'nAmounts: %s")'),
     "the MONEY help without the buttons' labels: U2, U3, U4"),
    ("C7-converted-amount", APP,
     one('{val = 1000,    label', '{val = 1340,    label'),
     "the first amount converted to dollars: R2, U6"),
    ("T1-symbol-written-in", "translations/translation_de.xml",
     one('<text name="ft_farmadmin_money_1k_fmt" text="+1.000 %s" />', '<text name="ft_farmadmin_money_1k_fmt" text="+1.000 €" />'),
     "a German value with the euro written in: T1, U1, U3, the placeholder row"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_farmadmin_money_10k_fmt" text="+%s1万" />', '<text name="ft_farmadmin_money_10k_fmt" text="+%s10K" />'),
     "a Japanese value in Latin letters, the English text: the script and English-copy rows"),
    ("T3-help-list-written-in", "translations/translation_fr.xml",
     one('Montants : %s"', 'Montants : +1 k$ · +10 k$ · +100 k$ · +1 M$"'),
     "a French help line with the amounts written in: T1, the placeholder row"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bars():
    rc, out = 0, []
    for b in BARS:
        r = subprocess.run(["node", b], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
        rc = rc or r.returncode
        out += (r.stdout + r.stderr).strip().splitlines()
    return rc, out

only = sys.argv[1:]
rc, out = run_bars()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]: print("   " + l)
    sys.exit(2)
print("baseline green:", " / ".join(l[:70] for l in out if "PASS" in l))
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
