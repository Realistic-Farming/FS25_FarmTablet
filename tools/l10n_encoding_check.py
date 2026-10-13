#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Find, and optionally repair, double-encoded lines in this mod's translation files.

    py tools/l10n_encoding_check.py          report only; exit 1 on any finding
    py tools/l10n_encoding_check.py --fix    repair every double-encoded line in place

Run it from the repo root. A run that finds no translation file reports UNREAD and
exits 1, so a wrong working directory cannot pass as clean.

Ported from SeasonalCropStress's tools/l10n_encoding_check.py (#210, itself a port
of FertilizerDepot's, #74 and #76) for MAINTENANCE row 130, measured at bec2f267 and
again at 915f4f9: 658 lines in six files (da 125, en 92, id 92, it 104, nl 96,
tr 149); the other 20 files are clean.

WHAT DOUBLE-ENCODING IS HERE. The original UTF-8 bytes were read as a single-byte
codepage and re-encoded as UTF-8, so U+2014 became U+00E2 U+20AC U+201D. The repair
is the exact inverse: map each character back to its single byte and decode the
bytes as UTF-8. decode('utf-8') is the gate: it only succeeds on bytes that really
are UTF-8 sequences. Every damaged line here decodes in ONE pass, so --fix decodes
each line once; a line that would still decode after that is reported as a GAP.

ONE CODEC PER CHARACTER, NOT PER VALUE. cp1252 leaves five bytes undefined (0x81,
0x8D, 0x8F, 0x90, 0x9D); damage can leave those as C1 controls (U+0081 and so on)
beside cp1252's typographic characters in the same line, and a whole-value encode
in either codec then raises. Here each character takes its cp1252 byte when cp1252
defines one, else its latin-1 byte (only U+0080..U+009F reach that branch), else
the line is not single-byte text and is left alone.

LINES, NOT VALUES. The unit is the line, so a damaged comment is found as well as a
damaged value. The scan still asserts it REACHED every l10n element in every file,
since a clean report over a file it never read is a false clean.

INDEPENDENT OF THE REPAIR. Besides the per-character test, every line is also
tested against plain cp1252 and plain latin-1, and --fix counts lines ATTEMPTED
against lines WRITTEN and re-reads the files from disk before it reports.

EM DASHES. The office does not ship em dashes, so any em dash in any translation
file is a finding (MAINTENANCE row 131, Tyson's call 2026-09-25). #171 left the 20
files it did not repair holding 1322 as ordinary text and printed that count as
information; from row 131 on, the count fails the check again. --fix writes every
spaced em dash (U+2014 with a space on each side) as " - ", both in a line it
decodes and in an ordinary line, and a repaired line that would still hold one
counts as a GAP. An em dash that is not spaced (Chinese punctuation writes a doubled
dash with no spaces) is NOT rewritten: it needs a reader's choice of punctuation,
so it stays a finding until someone edits it by hand.
"""
import glob
import io
import re
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

EM = chr(0x2014)
SPACED_EM = " " + EM + " "
ELEMENT = re.compile(r'<text name="|<e k="')
VALUE = re.compile(r'<text name="[^"]+"\s*text="[^"]*"|<e k="[^"]+"\s*v="[^"]*"')

BYTE = {}
for _b in range(256):
    try:
        BYTE[bytes([_b]).decode("cp1252")] = _b
    except UnicodeDecodeError:
        pass


def single_bytes(s):
    """Each character's cp1252 byte, else its latin-1 byte; None if neither exists."""
    out = bytearray()
    for ch in s:
        b = BYTE.get(ch)
        if b is None:
            if ord(ch) > 0xFF:
                return None
            b = ord(ch)
        out.append(b)
    return bytes(out)


def redecode(s, codec=None):
    """The line's UTF-8 reading if it is double-encoded, else None."""
    try:
        raw = single_bytes(s) if codec is None else s.encode(codec)
        if raw is None:
            return None
        fixed = raw.decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None
    return fixed if fixed != s else None


def files():
    return sorted(glob.glob("translations/translation_*.xml"))


def lines_of(path):
    """Lines with their own endings kept, so a rewrite preserves every byte it does not repair.

    Split on LF only: str.splitlines also splits on U+0085, a C1 control that can sit
    inside a double-encoded line."""
    parts = io.open(path, "rb").read().decode("utf-8").split("\n")
    return [x + "\n" for x in parts[:-1]] + ([parts[-1]] if parts[-1] else [])


def report():
    bad = {"per-character": 0, "cp1252": 0, "latin-1": 0}
    em = elements = reached = 0
    unreached = []
    per_file = []
    em_per_file = []
    if not files():
        unreached.append(("translations/translation_*.xml", 0, 0))
    for p in files():
        text = "".join(lines_of(p))
        e, v = len(ELEMENT.findall(text)), len(VALUE.findall(text))
        elements += e
        reached += v
        if e != v or e == 0:
            unreached.append((p, e, v))
        n = file_em = 0
        for line in lines_of(p):
            hit = False
            for name, codec in (("per-character", None), ("cp1252", "cp1252"), ("latin-1", "latin-1")):
                if redecode(line, codec) is not None:
                    bad[name] += 1
                    hit = True
            n += hit
            file_em += line.count(EM)
        if n:
            per_file.append((p, n))
        if file_em:
            em_per_file.append((p, file_em))
        em += file_em
    total = sum(n for _, n in per_file)
    print("files scanned        : %d" % len(files()))
    print("l10n elements reached: %d of %d" % (reached, elements))
    for p, e, v in unreached:
        print("  UNREAD: %s holds %d element(s), the scan reached %d. NOT a clean bill." % (p, e, v))
    print("lines double-encoded : %d (per-character %d, plain cp1252 %d, plain latin-1 %d)"
          % (total, bad["per-character"], bad["cp1252"], bad["latin-1"]))
    for p, n in per_file:
        print("  %-3s %d" % (p.split("_")[-1][:-4], n))
    print("em dashes            : %d (a finding: the office does not ship em dashes)" % em)
    for p, n in em_per_file:
        print("  %-3s %d" % (p.split("_")[-1][:-4], n))
    return total + len(unreached) + em


def fix():
    attempted = written = dashes = plain = 0
    for p in files():
        lines = lines_of(p)
        out = []
        for line in lines:
            fixed = redecode(line)
            if fixed is None:
                # Not double-encoded: a spaced em dash here is ordinary text (row 131).
                plain += line.count(SPACED_EM)
                out.append(line.replace(SPACED_EM, " - "))
                continue
            attempted += 1
            dashes += fixed.count(SPACED_EM)
            fixed = fixed.replace(SPACED_EM, " - ")
            if redecode(fixed) is None and EM not in fixed:
                written += 1
            out.append(fixed)
        if out != lines:
            io.open(p, "wb").write("".join(out).encode("utf-8"))
    print("attempted %d, written %d, spaced em dashes written as a hyphen: %d in decoded lines, %d in ordinary lines"
          % (attempted, written, dashes, plain))
    if attempted != written:
        print("GAP: %d line(s) attempted but not written clean" % (attempted - written))
    return attempted - written


if __name__ == "__main__":
    gap = fix() if "--fix" in sys.argv[1:] else 0
    sys.exit(1 if (report() or gap) else 0)
