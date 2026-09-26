# MAINTENANCE row 105, batch 6 (Notes, Excavator): targeted mutation battery.
# The logic in this PR: the two apps' help bodies, Excavator's headings, subtitle and messages moved onto
# named keys (FT.l10n, and Notes' own helper N); texts Excavator built at run time from English
# (string.format, a concatenation) moved onto FT.l10nFormat; the implement fallback goes through
# FT.l10nAuto; and the bar learned keyTables, so Notes' task templates (a table of keys drawn through N)
# are checked and executed. Each mutation undoes one piece, or breaks one text row the translation leans
# on, and the bar tools/test/l10n-notes-excavator-check.mjs must FAIL on a named row. Each file is
# restored byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_notes_excavator.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-notes-excavator-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("N1-help-body-literal", "src/apps/NotesApp.lua",
     one('body  = N("ft_notes_help_todo_body", ', 'body  = ('),
     "a Notes help body drawn as a literal again: S2, S4"),
    ("N2-templates-not-drawn", "src/apps/NotesApp.lua",
     one('return N(t.key, t.fallback)', 'return tostring(t.fallback)'),
     "the task templates no longer drawn through N: S1 (keyTables)"),
    ("N3-template-key-renamed", "src/apps/NotesApp.lua",
     one('key = "ft_notes_template_mow"', 'key = "ft_notes_template_mowing"'),
     "a template names a key no file carries: S1, S4"),
    ("N4-pending-count-literal", "src/apps/NotesApp.lua",
     one('string.format(N("ft_notes_pending_fmt", "%d pending"), pending)', 'string.format("%d pending", pending)'),
     "the pending count built from an English literal: S3, S4"),
    ("E1-help-body-literal", "src/apps/ExcavatorApp.lua",
     one('body  = FT.l10n("ft_excavator_help_reset_body", ', 'body  = ('),
     "an Excavator help body drawn as a literal again: S2, S4"),
    ("E2-speed-back-to-format", "src/apps/ExcavatorApp.lua",
     one('FT.l10nFormat("ft_excavator_speed_fmt", "%.1f km/h", ', 'string.format("%.1f km/h", '),
     "the vehicle speed built by string.format again: S3, S4"),
    ("E3-history-heading-concat", "src/apps/ExcavatorApp.lua",
     one('FT.l10nFormat("ft_excavator_history_fmt", "LOAD HISTORY  (%d)", #bt.history)', '"LOAD HISTORY  (" .. #bt.history .. ")"'),
     "the load history heading built from English: S3, S4"),
    ("E4-kg-back-to-format", "src/apps/ExcavatorApp.lua",
     one('FT.l10nFormat("ft_excavator_kg_fmt", "%.0f kg", load.weight or 0)', 'string.format("%.0f kg", load.weight or 0)'),
     "the load weight built by string.format again: S3, S4"),
    ("E5-implement-fallback-raw", "src/apps/ExcavatorApp.lua",
     one('or FT.l10nAuto("Implement")', 'or "Implement"'),
     "the implement fallback no longer looked up: S4"),
    ("E6-subtitle-literal", "src/apps/ExcavatorApp.lua",
     one('FT.l10n("ft_excavator_subtitle", "Terrain + Bucket")', '"Terrain + Bucket"'),
     "the header subtitle drawn as a literal: S2, S4"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_excavator_history_fmt" text="LADEVERLAUF  (%d)" />', '<text name="ft_excavator_history_fmt" text="LADEVERLAUF" />'),
     "a German value loses its placeholder: the text rows"),
    ("T2-romanised-japanese", "translations/translation_jp.xml",
     one('<text name="ft_excavator_active_bucket" text="使用中のバケット" />', '<text name="ft_excavator_active_bucket" text="shiyouchuu no baketto" />'),
     "a Japanese value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_es.xml",
     one('<text name="ft_excavator_no_bucket" text="No se detecta ningún vehículo con cazo." />', '<text name="ft_excavator_no_bucket" text="No bucket vehicle detected." />'),
     "a Spanish value reverted to the English text: the text rows"),
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
