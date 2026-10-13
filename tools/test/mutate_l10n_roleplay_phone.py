# MAINTENANCE row 105, batch 11 (Invoices / Roleplay Phone): targeted mutation battery.
# The logic in this PR: the help bodies and the due line (built from English at run time: "Due: " .. date,
# "Overdue by %d day%s", "Due in %d day%s") moved onto keys, one per plural form; the status words and the
# custom label sit in drawn tables; the cycler, the party and the description are translated before their
# cut. Each mutation undoes one piece, or breaks one text row the translation leans on, and the bar
# tools/test/l10n-roleplay-phone-check.mjs must FAIL on a named row. Each file is restored byte-identical
# (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_roleplay_phone.py [id-prefix ...]
import hashlib, os, subprocess, sys

# Failure lines quote locale text (Korean, Cyrillic); a piped Windows console is cp1252.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-roleplay-phone-check.mjs")
APP = "src/apps/RoleplayPhoneApp.lua"
EN = "translations/translation_en.xml"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("R1-help-body-literal", APP,
     one('body  = FT.l10n("ft_rpphone_help_summary_body", ', 'body  = ('),
     "a help body drawn as a literal again: S2, S4"),
    ("R2-due-in-format", APP,
     one('FT.l10nFormat("ft_rpphone_due_in_fmt", "Due in %d days", daysLeft)', 'string.format("Due in %d days", daysLeft)'),
     "the due line built by string.format again: S4"),
    ("R3-due-date-concat", APP,
     one('FT.l10nFormat("ft_rpphone_due_date_fmt", "Due: %s", inv.dueDateStr)', '"Due: " .. inv.dueDateStr'),
     "the phone's due date glued to English again: S4"),
    ("R4-status-word-unmapped", APP,
     one('paid = "PAID",', 'paid = "SETTLED",'),
     "a status word with no map entry: S2 (drawnTables)"),
    ("R5-cycler-stops-translating", APP,
     one('local valStr = FT.l10nAuto(value)', 'local valStr = tostring(value)'),
     "the cycler draws its value untranslated: S5"),
    ("R6-preset-unmapped", APP,
     one('"Contractor", "Supplier", "Farm Supply",', '"Contractor", "Supplier", "Farm Supplies",'),
     "a party preset with no map entry: S2 (drawnTables)"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_rpphone_due_in_fmt" text="Fällig in %d Tagen" />', '<text name="ft_rpphone_due_in_fmt" text="Fällig in Tagen" />'),
     "a German value loses its placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_auto_paid" text="支払済み" />', '<text name="ft_auto_paid" text="shiharaizumi" />'),
     "a Japanese value written in Latin letters: the script row, the CONTAINS row"),
    ("T3-help-misnames-status", "translations/translation_fr.xml",
     one('Statuts : EN ATTENTE, PAYÉE', 'Statuts : EN COURS, PAYÉE'),
     "a French help line naming a status the screen does not draw: the CONTAINS row"),
    ("T4-new-button-mismatch", "translations/translation_kr.xml",
     one('<text name="ft_auto_new" text="+ 신규" />', '<text name="ft_auto_new" text="+ 새로" />'),
     "a Korean + NEW that the help and the empty state no longer name: the CONTAINS row"),
    ("T5-line-break-lost", "translations/translation_es.xml",
     one('Arriba se muestra el total por cobrar (verde)&#10;y el total', 'Arriba se muestra el total por cobrar (verde) y el total'),
     "a Spanish help body one line short: the text rows"),
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
