# MAINTENANCE row 105, batch 13 (NPC Favor, RSF-F357's drawer): targeted mutation battery.
# The logic in this PR: the help bodies moved onto keys; the town reputation line, the favor progress line and the
# relationships heading no longer build English at run time; the band and relationship words are resolved where
# they are read. Each mutation undoes one piece, or breaks one text row the translation leans on, and the bar
# tools/test/l10n-npc-favor-check.mjs must FAIL on a named row. Each file is restored byte-identical
# (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_npc_favor.py [id-prefix ...]
import hashlib, os, subprocess, sys

# Failure lines quote locale text (Korean, Cyrillic); a piped Windows console is cp1252.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-npc-favor-check.mjs")
APP = "src/apps/IncomeApp.lua"
EN = "translations/translation_en.xml"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("P1-help-body-literal", APP,
     one('body  = FT.l10n("ft_npc_help_building_body", ', 'body  = ('),
     "a help body drawn as a literal again: S2, S4"),
    ("P2-town-rep-concat", APP,
     one('FT.l10nFormat("ft_npc_town_rep_fmt", "Town Reputation: %s", repLabel)', '"Town Reputation: " .. repLabel'),
     "the town reputation line glued to English again: S3, S4"),
    ("P3-relationships-heading-concat", APP,
     one('FT.l10nFormat("ft_npc_relationships_fmt", "RELATIONSHIPS  (%d)", #live)', '"RELATIONSHIPS  (" .. #live .. ")"'),
     "the roster view's relationships heading glued to English again: S3"),
    ("P4-progress-line-format", APP,
     one('FT.l10nFormat("ft_npc_progress_left_fmt", "%d%%  %dh left", progress, ', 'string.format("%d%%  %dh left", progress, '),
     "the favor progress line built by string.format again: S3"),
    ("P5-role-word-dropped", APP,
     one('    agronomist = function() return FT.l10n("ft_npc_role_agronomist", "agronomist") end,\n', ''),
     "a role id without its key (the consultant's agronomist drawn English): S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_npc_progress_left_fmt" text="%d%%  noch %d Std." />', '<text name="ft_npc_progress_left_fmt" text="%d%%  noch Std." />'),
     "a German progress line loses a placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_auto_friend" text="友人" />', '<text name="ft_auto_friend" text="yuujin" />'),
     "a Japanese relationship word written in Latin letters: the script row, the CONTAINS row"),
    ("T3-help-misnames-band", "translations/translation_fr.xml",
     one('Respectée &gt;= 70', 'Respecté &gt;= 70'),
     "a French reputation help naming a band word the line does not draw: the CONTAINS row"),
    ("T4-line-break-lost", "translations/translation_ru.xml",
     one('Число услуг, которые сейчас выполняются.&#10;Для', 'Число услуг, которые сейчас выполняются. Для'),
     "a Russian help body one line short: the text rows"),
    ("R1-mechanic-back", "translations/translation_en.xml",
     one('(Agronomist, Shopkeeper, etc.)', '(Agronomist, Mechanic, etc.)'),
     "the relationships help names a Mechanic role NPCFavor does not have (row 155): ROLE"),
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
