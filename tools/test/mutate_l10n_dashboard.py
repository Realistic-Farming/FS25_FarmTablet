# MAINTENANCE row 105, the dashboard PR: targeted mutation battery for its draw-site change
# (Desk's rule for the wave: a literal the app draws and its FT.AUTO_L10N key change together, so a
# mutation that changes one side only must be killed by a row showing the lookup miss).
#
# Each mutation edits one file in place, runs tools/test/l10n-dashboard-check.mjs and expects it to
# FAIL on a named row; the file is restored byte-identical (sha256-checked) after each one. The bar
# must be green before any run.
# Usage: py tools/test/mutate_l10n_dashboard.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EM = chr(0x2014)
BS = chr(92)

def T(s):
    return s.replace("{EM}", EM).replace("{NL}", BS + "n")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("D1-help-line-literal-only", "src/apps/DashboardApp.lua",
     one(T("\"Season requires the Seasons mod - blank in base game.{NL}\""), T("\"Season requires the Seasons mod {EM} blank in base game.{NL}\"")),
     "the help line's draw site goes back to the em dash, its map key does not: the line never resolves"),
    ("D2-help-line-map-key-only", "src/core/Constants.lua",
     one(T("[\"Season requires the Seasons mod - blank in base game.{NL}\"]"), T("[\"Season requires the Seasons mod {EM} blank in base game.{NL}\"]")),
     "the map key goes back to the em dash, the draw site does not: the retry finds nothing"),
    ("D3-label-english-copied", "translations/translation_fr.xml",
     one(T("<text name=\"ft_auto_nothing_pinned\" text=\"Rien d'épinglé.\" />"), T("<text name=\"ft_auto_nothing_pinned\" text=\"Nothing pinned.\" />")),
     "a translated label replaced by the English text"),
    ("D4-toggle-renamed", "translations/translation_fr.xml",
     one(T("<text name=\"ft_auto_on\" text=\"OUI\" />"), T("<text name=\"ft_auto_on\" text=\"ACTIF\" />")),
     "the ON toggle renamed while the hint still names OUI"),
    ("D5-drawn-key-outside-the-bar", "src/apps/DashboardApp.lua",
     one("drawRow(y, \"Weather\",", "drawRow(y, \"Balance\","),
     "the app draws a mapped literal whose key the bar never checks (ft_auto_balance): S3 names it"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "l10n-dashboard-check.mjs")],
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
    except AssertionError as e:
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
