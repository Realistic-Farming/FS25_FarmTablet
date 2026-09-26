# MAINTENANCE row 154: targeted mutation battery for RSF-F166's literalText switch (Bob's five).
# Each mutation undoes one piece of the switch or its use, and the standing bar
# tools/test/renderer-literal-flag-check.mjs must FAIL on a named row. A mutation may touch more than one
# file. Every file is restored byte-identical (sha256-checked) after each run. The bar must be green first.
# Usage: py tools/test/mutate_renderer_literal_flag.py [id-prefix ...]
import hashlib, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BAR = os.path.join(ROOT, "tools", "test", "renderer-literal-flag-check.mjs")


def one(old, new):
    def f(t):
        assert t.count(old) == 1, (old[:60], t.count(old))
        return t.replace(old, new)
    return f


MUTATIONS = [
    ("M1-skip-labels-unflagged", [("src/apps/FarmAdminApp.lua",
        one('''            onClick = function() fa_dispatch(FarmAdminActions.SKIP, t.h) end
        }, true)''', '''            onClick = function() fa_dispatch(FarmAdminActions.SKIP, t.h) end
        })'''))],
     "the Farm Admin skip buttons drawn without the flag: F (FLAG), E (\"06: 00\")"),
    ("M2-flag-tested-truthy", [("src/utils/Renderer.lua",
        one('''function FT_Renderer:appText(x, y, size, txt, align, color, literalText)
    local literal = (literalText == true)''', '''function FT_Renderer:appText(x, y, size, txt, align, color, literalText)
    local literal = (literalText and true or false)'''))],
     "appText's switch tested truthy, so a colour table in the slot bypasses: T"),
    ("M3-ok-entry-back", [("src/core/Constants.lua",
        one('''    ["offline"] = "ft_auto_offline",
''', '''    ["offline"] = "ft_auto_offline",
    ["ok"] = "ft_auto_ok",
''')), ("translations/translation_en.xml",
        one('''        <text name="ft_auto_offline" text="offline" />
''', '''        <text name="ft_auto_offline" text="offline" />
        <text name="ft_auto_ok" text="ok" />
'''))],
     "the dead [\"ok\"] map entry and its key back: K"),
    ("M4-button-skips-one-pass", [("src/utils/Renderer.lua",
        one('''        RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT, literal)''', '''        RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)'''))],
     "a flagged button skips only its own pass, not appText's: T, E"),
    ("M5-help-title-flagged-with-body", [("src/FarmTabletUI.lua",
        one('''FT.C.TEXT_ACCENT, entry.literalTitle == true)''', '''FT.C.TEXT_ACCENT, entry.literalBody == true)'''))],
     "drawHelpPage flags an entry's title with its body, so a raw English title stops translating: H"),
    # Soil Nutrient (MAINTENANCE row 105, batch 9): the card draws F cannot reach, held by E's named case.
    ("M6-soil-treatment-line-unflagged", [("src/apps/SoilNutrientApp.lua",
        one('''                        self.r:appText(innerX + FT.px(12), y, FT.FONT.SMALL, part,
                            RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL, true)''', '''                        self.r:appText(innerX + FT.px(12), y, FT.FONT.SMALL, part,
                            RenderText.ALIGN_LEFT, FT.C.TEXT_NORMAL)'''))],
     "a Soil Nutrient treatment line drawn without the flag: E (the card's FLAG row)"),
    ("M7-soil-urgency-second-pass", [("src/apps/SoilNutrientApp.lua",
        one('''        _chip(self, cx, chipY, urgencyTxt, uCol)''', '''        _chip(self, cx, chipY, FT.l10nAuto(urgencyTxt), uCol)'''))],
     "the resolved urgency word handed to FT.l10nAuto again: E (the card's PASS row)"),
    ("M8-soil-crop-raw", [("src/apps/SoilNutrientApp.lua",
        one('''crop = (info and info.lastCrop and FT.l10nAuto(info.lastCrop)) or''', '''crop = (info and info.lastCrop) or'''))],
     "Soil Fertilizer's internal crop name drawn raw in the flagged title: E (the card title)"),
    ("M9-soil-help-body-unflagged", [("src/apps/SoilNutrientApp.lua",
        one('''"Left tick: green OK · yellow WATCH · red URGENT."), literalTitle = true, literalBody = true },''',
            '''"Left tick: green OK · yellow WATCH · red URGENT."), literalTitle = true },'''))],
     "a resolved Soil Nutrient help body drawn without the flag: F (FLAG)"),
    # Invoices (MAINTENANCE row 105, batch 11): the card and form draws F cannot reach, held by E's walks.
    ("M10-invoice-party-unflagged", [("src/apps/RoleplayPhoneApp.lua",
        one('''                FT.FONT.BODY, party, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT, true)''',
            '''                FT.FONT.BODY, party, RenderText.ALIGN_LEFT, FT.C.TEXT_BRIGHT)'''))],
     "an invoice's translated party drawn without the flag: E (the list's FLAG row)"),
    ("M11-invoice-due-unflagged", [("src/apps/RoleplayPhoneApp.lua",
        one('''                    FT.FONT.TINY, dueStr, RenderText.ALIGN_LEFT, dueColor, true)''',
            '''                    FT.FONT.TINY, dueStr, RenderText.ALIGN_LEFT, dueColor)'''))],
     "the resolved due line drawn without the flag: E (the list's FLAG row)"),
    ("M12-cycler-value-unflagged", [("src/apps/RoleplayPhoneApp.lua",
        one('''        FT.FONT.SMALL, valStr, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT, true)''',
            '''        FT.FONT.SMALL, valStr, RenderText.ALIGN_CENTER, FT.C.TEXT_BRIGHT)'''))],
     "the form's translated preset drawn without the flag: E (the form's FLAG row)"),
]


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def run_bar():
    r = subprocess.run(["node", BAR], capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()


only = sys.argv[1:]
rc, out = run_bar()
if rc != 0:
    print("BASELINE IS NOT GREEN; fix that before trusting any mutation result.")
    for l in out[-10:]:
        print("   " + l)
    sys.exit(2)
print("baseline green:", out[-1][:140])
killed = survived = bad = 0
for mid, edits, why in MUTATIONS:
    if only and not any(mid.startswith(o) for o in only):
        continue
    saved = []
    try:
        for rel, fn in edits:
            path = os.path.join(ROOT, rel)
            raw = open(path, "rb").read()
            saved.append((path, raw, sha(path)))
            crlf = b"\r\n" in raw
            t = raw.decode("utf-8").replace("\r\n", "\n")
            t2 = fn(t)
            open(path, "wb").write((t2.replace("\n", "\r\n") if crlf else t2).encode("utf-8"))
    except (AssertionError, ValueError) as e:
        for path, raw, h in saved:
            open(path, "wb").write(raw)
        print("  BAD EDIT %s (%s)" % (mid, e))
        bad += 1
        continue
    try:
        rc, out = run_bar()
    finally:
        for path, raw, h in saved:
            open(path, "wb").write(raw)
            assert sha(path) == h, "restore failed for " + path
    fails = [l.strip() for l in out if l.strip().startswith("FAIL ")]
    if rc != 0 and fails:
        killed += 1
        print("  KILLED   %s  (%s)" % (mid, why))
        for l in fails[:3]:
            print("        " + l[:170])
    elif rc != 0:
        bad += 1
        print("  CRASHED  %s: the bar failed without naming a row (not a kill)" % mid)
        for l in out[-4:]:
            print("        " + l)
    else:
        survived += 1
        print("  SURVIVED %s  (%s)" % (mid, why))
print("mutations: %d killed, %d survived, %d bad edit or crash" % (killed, survived, bad))
sys.exit(0 if survived == 0 and bad == 0 else 1)
