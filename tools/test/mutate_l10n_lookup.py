# MAINTENANCE row 136: targeted mutation battery for the one-lookup rewrite of src/core/Constants.lua,
# run against the lookup bar tools/test/l10n-lookup-check.mjs.
#
# Each mutation edits src/core/Constants.lua in place (it puts back one piece of what row 136
# removed, or removes one piece row 136 added), runs the bar, and expects it to FAIL on a named
# row. The file is restored byte-identical (sha256-checked) after each one. The bar must be green
# before any run.
#
# KILLED means the bar failed and names the row that caught it; SURVIVED means it stayed green.
# Usage: py tools/test/mutate_l10n_lookup.py [id-prefix ...]
import hashlib, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONST = os.path.join(ROOT, "src", "core", "Constants.lua")

# M1: the ft36 layer as it stood before row 136 (Constants.lua :5160-:5289 at 1bbcb14), cut to its
# logic and the short keys that did the damage; its smart translate substitutes every key of the
# language's final table anywhere in the fallback, before the file is asked.
FT36 = r'''
local function ft36LanguageShort()
    local lang = string.lower(tostring(g_languageShort or ""))
    if lang:find("de", 1, true) == 1 then return "de" end
    if lang:find("ru", 1, true) == 1 then return "ru" end
    return lang
end
local function ft36EscapePattern(s)
    return tostring(s or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end
FT.FINAL_DE_TEXT = { ["Open"] = "Öffnen", ["Off"] = "Aus", ["On"] = "An", ["Day"] = "Tag", ["New"] = "Neu" }
FT.FINAL_RU_TEXT = { ["Open"] = "Открыть", ["Off"] = "Выкл.", ["On"] = "Вкл.", ["Day"] = "День", ["New"] = "Новое" }
local function ft36SmartTranslate(raw, lang)
    raw = tostring(raw or "")
    local map = (lang == "de" and FT.FINAL_DE_TEXT) or (lang == "ru" and FT.FINAL_RU_TEXT) or nil
    if map == nil or raw == "" then return raw end
    if map[raw] ~= nil then return map[raw] end
    local out = raw
    local keys = {}
    for k, _ in pairs(map) do if string.len(k) > 1 then table.insert(keys, k) end end
    table.sort(keys, function(a, b) return string.len(a) > string.len(b) end)
    for _, k in ipairs(keys) do out = out:gsub(ft36EscapePattern(k), map[k]) end
    return out
end
local _ft36PrevL10n = FT.l10n
function FT.l10n(key, fallback)
    local lang = ft36LanguageShort()
    if (lang == "de" or lang == "ru") and fallback ~= nil then
        local tr = ft36SmartTranslate(fallback, lang)
        if tr ~= tostring(fallback) then return tr end
    end
    return _ft36PrevL10n(key, fallback)
end
local _ft36PrevAuto = FT.l10nAuto
function FT.l10nAuto(text)
    local raw = tostring(text or "")
    local prev = _ft36PrevAuto(raw)
    local lang = ft36LanguageShort()
    if lang == "de" or lang == "ru" then
        local direct = ft36SmartTranslate(raw, lang)
        if direct ~= raw then return direct end
    end
    return prev
end
'''

# M2: one blind gsub of the old German layer (:4525-:4540 at 1bbcb14) put back in front of the lookup.
ONE_GSUB = r'''
local _mPrevAuto = FT.l10nAuto
function FT.l10nAuto(text)
    local raw = tostring(text or "")
    if string.lower(tostring(g_languageShort or "")) == "de" then raw = raw:gsub("now", "jetzt") end
    return _mPrevAuto(raw)
end
'''

# M4: FT.DE_L10N back in front of the file (the :4514 layer at 1bbcb14), with three of its real
# values, English and half-English as they were.
DE_FIRST = r'''
FT.DE_L10N = {
    ["ft_auto_breakdowns_repair_before_reaching_80"] = "breakdowns - reparieren before reaching 80%.",
    ["ft_auto_sorted_by_fuel_level_emptiest_machines_appear_first"] = "Sortierened by Kraftstoff Stufe - emptiest machines appear first\n",
    ["ft_auto_done_collect_reward"] = "DONE - COLLECT REWARD",
}
local _mDePrevAuto = FT.l10nAuto
function FT.l10nAuto(text)
    local raw = tostring(text or "")
    if string.lower(tostring(g_languageShort or "")) == "de" and FT.AUTO_L10N ~= nil then
        local key = FT.AUTO_L10N[raw]
        if key ~= nil and FT.DE_L10N[key] ~= nil then return FT.DE_L10N[key] end
    end
    return _mDePrevAuto(raw)
end
'''

# M5: the Russian final layer's "table by fallback before the file" (:5100-:5108 at 1bbcb14).
RU_FIRST = r'''
FT.RU_FINAL_TEXT = { ["Show text below app icons"] = "Показывать текст под иконками" }
local _mRuPrevL10n = FT.l10n
function FT.l10n(key, fallback)
    if string.lower(tostring(g_languageShort or "")) == "ru" and fallback ~= nil and FT.RU_FINAL_TEXT[tostring(fallback)] ~= nil then
        return FT.RU_FINAL_TEXT[tostring(fallback)]
    end
    return _mRuPrevL10n(key, fallback)
end
'''

RETRY_RE = re.compile(r"\n[ \t]*-- 1b\).*?\n[ \t]*key = FT\.AUTO_L10N\[raw \.\. \"\\n\"\]\n.*?\n[ \t]*end\n", re.S)

def drop_retry(t):
    return RETRY_RE.sub("\n", t, count=1)

def keep_trailing_newline(t):
    return t.replace("            if string.sub(line, -1) == \"\\n\" then line = string.sub(line, 1, -2) end\n", "", 1)

MUTATIONS = [
    ("M1-ft36-restored", lambda t: t + FT36,
     "the outermost ft36 layer and its substring smart translate, as before row 136"),
    ("M2-one-gsub-restored", lambda t: t + ONE_GSUB,
     "one blind gsub of the old German layer (now -> jetzt) in front of the lookup"),
    ("M3-newline-retry-dropped", drop_retry,
     "the help-line retry with \"\\n\" removed: drawHelpPage's lines never match again"),
    ("M4-de-table-before-file", lambda t: t + DE_FIRST,
     "FT.DE_L10N answered before the locale file, as the :4514 layer did"),
    ("M5-ru-table-by-fallback", lambda t: t + RU_FIRST,
     "the Russian final table answered by fallback before the locale file, as the v31 layer did"),
    ("M6-retry-keeps-newline", keep_trailing_newline,
     "the retry returns the file's text with its trailing \"\\n\": every help line gains an empty line"),
    ("M7-second-l10n-layer", lambda t: t + "\nlocal _mPrev = FT.l10n\nfunction FT.l10n(key, fallback) return _mPrev(key, fallback) end\n",
     "a second FT.l10n definition, harmless in behaviour: the source rule must still refuse it"),
]

def sha(path):
    with open(path, "rb") as f: return hashlib.sha256(f.read()).hexdigest()

def run_bar():
    r = subprocess.run(["node", os.path.join(ROOT, "tools", "test", "l10n-lookup-check.mjs")],
                       capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()

only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[:10]: print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:120])
killed = survived = bad = 0
for mid, fn, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only): continue
    before = sha(CONST)
    raw = open(CONST, "rb").read()
    crlf = b"\r\n" in raw
    t = raw.decode("utf-8").replace("\r\n", "\n")
    t2 = fn(t)
    if t2 == t:
        print("  BAD EDIT %s (no change)" % mid); bad += 1; continue
    open(CONST, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    try:
        rc, out = run_bar()
    finally:
        open(CONST, "wb").write(raw)
        assert sha(CONST) == before, "restore failed"
    rows = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and rows:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in rows: print("        " + l)
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-5:]: print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
