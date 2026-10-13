# MAINTENANCE row 156 (F27, the Akita drawers that reported the opposite of their own data): targeted mutation battery.
# The logic in this PR: the vet counts the cases it draws (a table entry of sickStables; the method is not read); the
# dealer with a handle but no financeManager says its finance data is not available; Open Notices is the sum of the
# cards' missed installments (data.overdue is not read). Each mutation undoes one piece (Bob's intake list), and a bar
# must FAIL on a named row: tools/test/akita-f27-check.mjs for the drawers, tools/test/l10n-akita-factory-dealer-check.mjs
# for the new key's text rows. Both bars run for every mutation. Each file is restored byte-identical (sha256-checked)
# after each run. Both bars must be green before any run.
# Usage: py tools/test/mutate_akita_f27.py [id-prefix ...]
import hashlib, os, subprocess, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "akita-f27-check.mjs"),
        os.path.join(ROOT, "tools", "test", "l10n-akita-factory-dealer-check.mjs")]
APP = "src/apps/AkitaTabletIntegrationsApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("M1-clamp-restored", APP,
     one("            overdue = overdue + missedHere\n", "            overdue = math.max(overdue, 1)\n"),
     "Open Notices clamps to 1 again: N1"),
    ("M2-data-overdue-preferred", APP,
     one("    local overdue = 0\n", "    local overdue = tonumber(data.overdue) or 0\n"),
     "Open Notices starts from the mod's data.overdue again: N1, N2"),
    ("M3-gate-on-the-method", APP,
     one("    if count <= 0 then\n", '    if (ftAkitaSafeCall(avs, "getActiveIllnessCount") or 0) <= 0 then\n'),
     "the \"No sick\" gate reads the method again: V1, V3"),
    ("M4-header-on-the-method", APP,
     one('string.format(ftAkitaText("ft_vet_active_cases", "%d active cases"), count)',
         'string.format(ftAkitaText("ft_vet_active_cases", "%d active cases"), ftAkitaSafeCall(avs, "getActiveIllnessCount") or 0)'),
     "the header count reads the method again: V1, V3"),
    ("M5-no-finance-is-not-detected", APP,
     one('ftAkitaText("ft_rd_no_finance", "RealisticDealer\'s finance data is not available.")',
         'ftAkitaText("ft_rd_not_detected", "RealisticDealer was not detected.")'),
     "a dealer without finance data says not detected again: D1"),
    ("M6-walk-table-check-dropped", APP,
     one('            if type(d) == "table" then\n                local name', '            if true then\n                local name'),
     "the case walk takes a non-table entry: V3 (the drawer stops)"),
    ("M7-count-table-check-dropped", APP,
     one('        if type(d) == "table" then count = count + 1 end\n', '        count = count + 1\n'),
     "the count takes a non-table entry: V3"),
    ("T1-french-canadian-chinese", "translations/translation_fc.xml",
     one('text="Données de financement RealisticDealer indisponibles." />', 'text="RealisticDealer 融资数据不可用。" />'),
     "the new key's French Canadian value in Chinese: SCRIPT-OUT"),
    ("T2-new-key-missing", "translations/translation_de.xml",
     one('        <text name="ft_rd_no_finance" text="RealisticDealer-Finanzdaten sind nicht verfügbar." />\n', ''),
     "a locale file without the new key: the text rows, D1"),
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
