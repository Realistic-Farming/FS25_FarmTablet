# MAINTENANCE row 105, batch 14 (Akita: AnimalAutoCare and AnimalVetSystem): targeted mutation battery.
# The logic in this PR: AnimalAutoCare's German log lines reach the reader's language through FT_AKITA_LINE_WORDS
# (every other language used to get English); the log lines and the vet's case status tag are drawn as the file has
# them; the vet header and case line take their one-case forms. The data: 173 values the Akita83 import wrote with
# their accents stripped are restored (ACCENT), a section header regains its capitals (CASE), the count lines of
# cz, pl and ro follow a label (LABEL), and br and pt stop using their On word for Connected (DISTINCT). Each
# mutation undoes one piece, and a bar must FAIL on a named row: tools/test/l10n-akita-animals-check.mjs for the
# text rows, tools/test/renderer-literal-flag-check.mjs for the drawers (its E case drives the real drawers through
# the real renderer). Both bars run for every mutation. Each file is restored byte-identical (sha256-checked) after
# each run. Both bars must be green before any run.
# Usage: py tools/test/mutate_l10n_akita_animals.py [id-prefix ...]
import hashlib, os, subprocess, sys

# Failure lines quote locale text (Vietnamese, Cyrillic); a piped Windows console is cp1252.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BARS = [os.path.join(ROOT, "tools", "test", "l10n-akita-animals-check.mjs"),
        os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs")]
APP = "src/apps/AkitaTabletIntegrationsApp.lua"

def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f

# The helper as it stood before this PR: every language but German got the English word.
OLD_LINE_TEXT = '''local function ftAkitaLineText(line)
    local t = tostring(line or "")
    local lang = string.lower(tostring(g_languageShort or ""))
    if lang:sub(1,2) ~= "de" then
        t = t:gsub("Gesamt", "Overall")
        t = t:gsub("Futter", "Food")
        t = t:gsub("Wasser", "Water")
        t = t:gsub("Stroh", "Straw")
        t = t:gsub("Auffüllen ab", "Refill below")
        t = t:gsub("Zielfüllung", "Target fill")
        t = t:gsub("Priorität", "Priority")
        t = t:gsub("Letzte Aktion", "Last action")
        t = t:gsub(": An", ": On")
        t = t:gsub(": Aus", ": Off")
    end
    return t
end'''

def old_line_text(t):
    i = t.index("local function ftAkitaLineText(line)")
    j = t.index("\nend\n", i) + len("\nend")
    return t[:i] + OLD_LINE_TEXT + t[j:]

MUTATIONS = [
    ("C1-english-words-back", APP, old_line_text,
     "the log lines read English in every language but German again: E (the French and Polish lines)"),
    ("C2-word-to-wrong-key", APP,
     one('{ de = "Priorität",     key = "ft_aac_priority",', '{ de = "Priorität",     key = "ft_aac_last_action",'),
     "Priorität sent to the LAST ACTION section header's key: E (the straw line)"),
    ("C3-straw-entry-gone", APP,
     one('    { de = "Stroh",         key = "ft_aac_straw",            fallback = "Straw" },\n', ''),
     "a German word without its table entry (Stroh stays German): E"),
    ("C4-on-hardcoded", APP,
     one('local on, off = ftAkitaText("ft_common_on", "On"), ftAkitaText("ft_common_off", "Off")', 'local on, off = "On", ftAkitaText("ft_common_off", "Off")'),
     "a log line's On written in English: E (the overall line)"),
    ("C5-line-flag-dropped", APP,
     one('ftAkitaLineText(line), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)', 'ftAkitaLineText(line), RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)'),
     "a translated log line handed to the renderer's second pass: E (FLAG)"),
    ("C6-status-flag-dropped", APP,
     one('RenderText.ALIGN_RIGHT, FT.C.TEXT_ACCENT, statusLiteral)', 'RenderText.ALIGN_RIGHT, FT.C.TEXT_ACCENT)'),
     "the vet's case status tag handed to the renderer's second pass: E (FLAG)"),
    ("C7-one-case-header-gone", APP,
     one('avs and (count == 1 and ftAkitaText("ft_vet_active_cases_one", "1 active case")\n            or string.format(',
         'avs and (string.format('),
     "the vet header reads \"1 active cases\" again: E (one case)"),
    ("C8-one-animal-line-gone", APP,
     one('animals == 1 and string.format(ftAkitaText("ft_vet_case_line_one", "%s - 1 animal - about %d min"), illness, rem)\n                        or ', ''),
     "the case line reads \"1 animals\" again: E (one animal)"),
    ("C9-an-not-a-whole-word", APP,
     one('t = t:gsub(": An([^%a\\128-\\255])", function(c) return ": " .. on .. c end)', 't = t:gsub(": An", function() return ": " .. on end)'),
     "\": An\" replaced inside a longer word (\": Anzahl\"), Bob's #201 MINOR: E (the Anzahl line)"),
    ("C10-lead-byte-not-a-letter", APP,
     one('t = t:gsub(": An([^%a\\128-\\255])", function(c) return ": " .. on .. c end)', 't = t:gsub(": An([^%a])", function(c) return ": " .. on .. c end)'),
     "a UTF-8 lead byte after \": An\" counted as a non-letter (\": Anästhesie\"), Bob's #202 MINOR: E (the Anästhesie line)"),
    ("T1-french-accents-stripped", "translations/translation_fr.xml",
     one('text="AnimalAutoCare n\'a pas été détecté."', 'text="AnimalAutoCare n\'a pas ete detecte."'),
     "a French value back to the import's stripped text: ACCENT"),
    ("T2-vietnamese-accents-stripped", "translations/translation_vi.xml",
     one('<text name="ft_common_connected" text="Đã kết nối" />', '<text name="ft_common_connected" text="Da ket noi" />'),
     "a Vietnamese value back to the import's stripped text: ACCENT"),
    ("T3-german-word-not-the-mods", "translations/translation_de.xml",
     one('<text name="ft_aac_refill_below" text="Auffüllen ab" />', '<text name="ft_aac_refill_below" text="Nachfüllen unter" />'),
     "German's refill word is not AnimalAutoCare's own, so a German log line changes: E"),
    ("T4-russian-header-lower-case", "translations/translation_ru.xml",
     one('<text name="ft_aac_last_action" text="ПОСЛЕДНЕЕ ДЕЙСТВИЕ" />', '<text name="ft_aac_last_action" text="Последнее действие" />'),
     "Russian's LAST ACTION header in lower case again: CASE"),
    ("T5-czech-count-before-noun", "translations/translation_cz.xml",
     one('<text name="ft_vet_active_cases" text="Aktivní případy: %d" />', '<text name="ft_vet_active_cases" text="%d aktivních případů" />'),
     "a Czech count before a noun whose form changes with it: LABEL"),
    ("T6-connected-reads-on", "translations/translation_br.xml",
     one('<text name="ft_common_connected" text="Conectado" />', '<text name="ft_common_connected" text="Ligado" />'),
     "Brazilian Connected reads the file's On word again: DISTINCT"),
    ("T8-french-canadian-chinese-again", "translations/translation_fc.xml",
     one('<text name="ft_aac_care_now" text="Soigner" />', '<text name="ft_aac_care_now" text="立即照护" />'),
     "a French Canadian value back in Simplified Chinese (Bob's #202 BLOCKER): SCRIPT-OUT"),
    ("T7-new-key-missing", "translations/translation_pl.xml",
     one('        <text name="ft_aac_priority" text="Priorytet" />\n', ''),
     "a locale file without one of the new line words: the text rows"),
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
