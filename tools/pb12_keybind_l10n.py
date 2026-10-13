#!/usr/bin/env python3
"""BUILD 15:39 / PB-12 - retire the stale T-only keybind guidance from the
bundled l10n.

Two separate problems, handled differently on purpose.

1. `ft_battery_charged_usable` is LIVE (FarmTabletUI:_updateBatteryCharging
   renders it). It hardcoded the key name, so it would go stale again the moment
   anybody rebinds. The literal key token becomes a `%s` and the Lua fills it
   from InputHandler:getKeybindString(), which reads the live binding. That keeps
   every language's own sentence and cannot rot.

2. `ft_help_p1_open_text`, `ft_help_p2_key_text` and `ft_help_s2_console_text`
   are DEAD - nothing in src/ reads them - and all three describe a rebindable
   single letter changed through a console command, which is not what the tablet
   has been for two builds. Patching the key token would leave 26 languages of
   sentences that are still wrong about the mechanism. They are removed instead,
   so a future help page has to add correct copy through the normal l10n route
   rather than inherit wrong copy.

Files are decoded utf-8-sig and written back as plain UTF-8 with no BOM.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS = ROOT / "translations"
CONSTANTS = ROOT / "src" / "core" / "Constants.lua"

DEAD_KEYS = (
    "ft_help_p1_open_text",
    "ft_help_p2_key_text",
    "ft_help_s2_console_text",
)

# Per-language key token replacements for the live battery string. Every entry
# swaps the literal key name for the %s the Lua now fills in.
BATTERY_SUBS = (
    ("Press T to turn it on.", "Press %s to turn it on."),
    ("Mit T wieder einschalten.", "Mit %s wieder einschalten."),
    ("Нажмите T.", "Нажмите %s."),
)


def read(path):
    return path.read_bytes().decode("utf-8-sig")


def write(path, text):
    path.write_bytes(text.encode("utf-8"))


def patch_translation(path):
    text = read(path)
    original = text

    # 1. battery string: key token -> %s
    m = re.search(r'(name="ft_battery_charged_usable"\s+text=")([^"]*)(")', text)
    if m:
        value = m.group(2)
        for old, new in BATTERY_SUBS:
            if old in value:
                value = value.replace(old, new)
                break
        text = text[: m.start(2)] + value + text[m.end(2) :]

    # 2. drop the dead stale-guidance keys, whole line including its newline
    for key in DEAD_KEYS:
        text = re.sub(
            r'[ \t]*<text name="%s"[^>]*/>[ \t]*\r?\n' % re.escape(key), "", text
        )

    if text != original:
        write(path, text)
        return True
    return False


def patch_constants(path):
    text = read(path)
    original = text

    m = re.search(r'(\["ft_battery_charged_usable"\]\s*=\s*")([^"]*)(")', text)
    if m:
        value = m.group(2)
        for old, new in BATTERY_SUBS:
            if old in value:
                value = value.replace(old, new)
                break
        text = text[: m.start(2)] + value + text[m.end(2) :]

    for key in DEAD_KEYS:
        text = re.sub(r'[ \t]*\["%s"\]\s*=\s*"(?:[^"\\]|\\.)*",[ \t]*\r?\n' % re.escape(key), "", text)

    if text != original:
        write(path, text)
        return True
    return False


def main():
    changed = []
    for path in sorted(TRANSLATIONS.glob("translation_*.xml")):
        if patch_translation(path):
            changed.append(path.name)
    if patch_constants(CONSTANTS):
        changed.append(CONSTANTS.name)

    print("patched %d file(s)" % len(changed))
    for name in changed:
        print("  " + name)

    # Verify nothing still ships the stale guidance.
    stale = []
    for path in list(TRANSLATIONS.glob("translation_*.xml")) + [CONSTANTS]:
        body = read(path)
        for key in DEAD_KEYS:
            if key in body:
                stale.append("%s: %s" % (path.name, key))
        if re.search(r"Press T to turn it on|Mit T wieder|Right Shift \+ T", body):
            stale.append("%s: stale key token" % path.name)
    if stale:
        print("STALE GUIDANCE REMAINS:")
        for s in stale:
            print("  " + s)
        return 1
    print("no stale T-only or Right Shift + T guidance remains")
    return 0


if __name__ == "__main__":
    sys.exit(main())
