# MAINTENANCE row 105, batch 7 (Farm Admin, Personnel): targeted mutation battery.
# The logic in this PR: the two apps' help bodies, headings, notices, buttons and status messages moved
# onto named keys (FT.l10n); texts they built at run time from English (string.format, concatenations,
# the AM / PM skip buttons) moved onto FT.l10nFormat or their own keys; Personnel's addBtn now draws its
# label through FT.l10nAuto, so the bar can pin it (drawnArgs, S5); its sort and filter words are
# drawnTables, and the bar reads an and/or choice inside a drawnArgs call. Each mutation undoes one piece, or breaks one text row the translation leans on, and the
# bar tools/test/l10n-farmadmin-personnel-check.mjs must FAIL on a named row. Each file is restored
# byte-identical (sha256-checked) after each run. The bar must be green before any run.
# Usage: py tools/test/mutate_l10n_farmadmin_personnel.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "l10n-farmadmin-personnel-check.mjs")

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

MUTATIONS = [
    ("A1-help-body-literal", "src/apps/FarmAdminApp.lua",
     one('body  = FT.l10n("ft_farmadmin_help_skip_body", ', 'body  = ('),
     "a Farm Admin help body drawn as a literal again: S2, S4"),
    ("A2-time-scale-concat", "src/apps/FarmAdminApp.lua",
     one('FT.l10nFormat("ft_farmadmin_time_scale_fmt", "TIME SCALE  ·  now: %s", fa_getTimeStr())', '"TIME SCALE  ·  now: " .. fa_getTimeStr()'),
     "the time-scale heading built from English again: S3, S4"),
    ("A3-skip-label-literal", "src/apps/FarmAdminApp.lua",
     one('label = FT.l10n("ft_farmadmin_skip_6am", "6 AM")', 'label = "6 AM"'),
     "a skip button's English clock label drawn raw: S2, S4"),
    ("A4-vehicles-back-to-format", "src/apps/FarmAdminApp.lua",
     one('FT.l10nFormat("ft_farmadmin_vehicles_fmt", ', 'string.format('),
     "the vehicles heading built by string.format again: S3, S4"),
    ("A5-admin-only-literal", "src/apps/FarmAdminApp.lua",
     one('FT.l10n("ft_farmadmin_admin_only", "Admin only")', '"Admin only"'),
     "the admin-only subtitle drawn as a literal: S2, S4"),
    ("P1-addbtn-label-raw", "src/apps/PersonnelApp.lua",
     one('FT.l10nAuto(label), color, { onClick = onClick })', 'label, color, { onClick = onClick })'),
     "addBtn draws its label raw again: S5"),
    ("P2-sort-label-concat", "src/apps/PersonnelApp.lua",
     one('FT.l10nFormat("ft_personnel_sort_fmt", "SORT: %s", FT.l10nAuto(SORT_LABEL[self._psSort] or "Level"))', '"SORT: " .. (SORT_LABEL[self._psSort] or "Level")'),
     "the sort button built from English again: S4"),
    ("P3-stats-back-to-format", "src/apps/PersonnelApp.lua",
     one('FT.l10nFormat("ft_personnel_worker_stats_fmt", ', 'string.format('),
     "a worker's stats line built by string.format again: S3, S4"),
    ("P4-signing-cost-concat", "src/apps/PersonnelApp.lua",
     one('FT.l10nFormat("ft_personnel_signing_cost_fmt", "Signing cost  %s", money(r.hireCost))', '"Signing cost  " .. money(r.hireCost)'),
     "the signing cost built from English again: S3, S4"),
    ("P5-per-worker-concat", "src/apps/PersonnelApp.lua",
     one('FT.l10nFormat("ft_personnel_per_worker_fmt", "PER WORKER  (base %s)", money(math.floor(fin.baseRate or 0)) .. rateUnit)', '"PER WORKER  (base " .. money(math.floor(fin.baseRate or 0)) .. rateUnit .. ")"'),
     "the per-worker heading built from English again: S3, S4"),
    ("P6-sort-word-unmapped", "src/apps/PersonnelApp.lua",
     one('hours = "Hours"', 'hours = "Hourz"'),
     "a sort word with no map entry: S2 (drawnTables)"),
    ("P7-fire-label-unmapped", "src/apps/PersonnelApp.lua",
     one('confirming and "SURE?" or "FIRE"', 'confirming and "SURE?" or "FIRES"'),
     "a label chosen by and/or inside addBtn with no map entry: S2 (drawnArgs)"),
    ("T1-placeholder-dropped", "translations/translation_de.xml",
     one('<text name="ft_personnel_msg_fired" text="%s entlassen (Abfindung %s)" />', '<text name="ft_personnel_msg_fired" text="%s entlassen" />'),
     "a German value loses a placeholder: the text rows"),
    ("T2-romanised-korean", "translations/translation_kr.xml",
     one('<text name="ft_personnel_msg_rerolled" text="채용 후보를 새로 뽑았습니다" />', '<text name="ft_personnel_msg_rerolled" text="chaeyong hubo" />'),
     "a Korean value written in Latin letters: the script row"),
    ("T3-english-copy", "translations/translation_es.xml",
     one('<text name="ft_farmadmin_host_only" text="Solo anfitrión o admin del servidor" />', '<text name="ft_farmadmin_host_only" text="Host or server admin only" />'),
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
