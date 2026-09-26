// renderer-parity-check.mjs - MAINTENANCE row 154's parity bar.
//
// The whole tablet drawn on the base tree and on this one: every drawer, main page and help page, and the
// chrome (home, lock, status bar, repair, battery, provider, toast, offline banner, edit overlay), in all 26
// locales, through tools/test/tablet-harness.mjs (the real files, the real registry, the real FT_Renderer).
// The base is read from git; the head is the working tree. The harness marks every text a caller queued
// with the literal flag (RSF-F166's literalText, exactly true).
//
//   - A text drawn WITHOUT the flag must be byte-identical to the base: absent/false keeps today's
//     behaviour (F166: "Absent/false retains existing behavior for all other callers"). One exception,
//     named: the dead ["ok"] map entry is gone, so a drawn "OK" no longer turns into "ok" (map data, not
//     flag behaviour).
//   - A text drawn WITH the flag may differ only as a removed second translation: it is a resolver's output
//     in that draw (FT.l10n, FT.l10nFormat, g_i18n:getText, a format or gsub of one), or made only of such
//     outputs and letterless glue ("Ottimo (4/4)"), and the old renderer
//     made the old text from it with FT.l10nAuto once (appText, text, appHeaderText) or twice (button).
//     A text with no letters (a clock, a count) the old pass reshaped is allowed and counted apart.
//   - Listed and allowed too: a name the old code cut while still English and translated afterwards, now
//     translated first and cut to the width it was sized for.
// Anything else fails: a flagged text that is no resolver's output (an English value flagged by mistake
// draws English), an unflagged text that changed, or a page that changed shape.
//
// Usage:  node tools/test/renderer-parity-check.mjs [base-ref]
//         (default base: the merge-base of HEAD and origin/development; on development itself there is
//         nothing to compare and the bar says so.)
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";
import { readdirSync } from "node:fs";
import { join } from "node:path";

const git = (...a) => execFileSync("git", a, { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 }).trim();
let base = process.argv[2];
if (!base) {
  try { base = git("merge-base", "HEAD", "origin/development"); } catch { console.log("renderer-parity: no base ref (pass one)"); process.exit(1); }
}
const head = git("rev-parse", "HEAD");
const baseSha = git("rev-parse", base);
const dirty = git("status", "--porcelain", "--", "src", "translations") !== "";
if (baseSha === head && !dirty) {
  console.log(`renderer-parity: PASS - HEAD is the base (${baseSha.slice(0, 7)}); nothing to compare`);
  process.exit(0);
}
const cache = new Map();
const readBase = (rel) => { if (!cache.has(rel)) cache.set(rel, git("show", `${baseSha}:${rel}`) + "\n"); return cache.get(rel); };

const before = makeTablet(readBase);
const after = makeTablet(workingTree, { instrument: true });
for (const [n, t] of [["base", before], ["head", after]]) if (t.loadErrors.length) { console.log(`renderer-parity: the ${n} tree did not load: ${t.loadErrors.join("; ")}`); process.exit(1); }
const CHROME = ["_drawHome", "_drawLock", "_drawStatusBar", "_drawRepairScreen", "_drawBatteryEmpty", "_drawProviderSelect", "_drawSignalToast", "_drawOfflineDataBanner", "_drawEditOverlay"];
const locales = readdirSync(join(ROOT, "translations")).map((f) => f.match(/^translation_([a-z]{2})\.xml$/)).filter(Boolean).map((m) => m[1]).sort();
const ids = [...new Set([...before.appIds(), ...after.appIds()])].sort();
const failures = [], cutAfter = [], letterless = [], okMap = [];
let draws = 0, texts = 0, flagged = 0, removed = 0;
for (const loc of locales) {
  before.setLocale(loc);
  after.setLocale(loc);
  const jobs = [];
  for (const id of ids) for (const help of [false, true]) jobs.push({ name: `${id}${help ? " (help)" : ""}`, b: () => before.draw(id, help), a: () => after.draw(id, help) });
  for (const c of CHROME) jobs.push({ name: `chrome ${c}`, b: () => before.chrome(c), a: () => after.chrome(c) });
  for (const j of jobs) {
    const b = j.b(), a = j.a();
    draws++;
    if ((b.error || "") !== (a.error || "")) { failures.push(`${loc} ${j.name}: the drawer stopped differently (before: ${b.error || "no error"}; after: ${a.error || "no error"})`); continue; }
    if (b.texts.length !== a.texts.length) {
      let i = 0; while (i < b.texts.length && b.texts[i] === a.texts[i]) i++;
      failures.push(`${loc} ${j.name}: ${b.texts.length} texts before, ${a.texts.length} after; first difference at ${i}: ${JSON.stringify(b.texts[i])} -> ${JSON.stringify(a.texts[i])}`);
      continue;
    }
    for (let i = 0; i < a.texts.length; i++) {
      texts++;
      if (a.flagged[i]) flagged++;
      const bt = b.texts[i], at = a.texts[i];
      if (bt === at) continue;
      const tag = `${loc} ${j.name}: ${JSON.stringify(bt)} -> ${JSON.stringify(at)}`;
      if (!a.flagged[i]) {
        if (bt.replace(/\bok\b/g, "OK") === at) { okMap.push(tag); continue; }
        failures.push(`${loc} ${j.name} #${i}: ${JSON.stringify(bt)} -> ${JSON.stringify(at)} (drawn without the flag, and changed)`);
        continue;
      }
      const once = before.auto(at);
      if (!/\p{L}/u.test(at) && (once === bt || before.auto(once) === bt)) { letterless.push(tag); continue; }
      const resolved = after.recHas(at) || after.recCovers(at);
      if (resolved && (once === bt || before.auto(once) === bt)) { removed++; continue; }
      if (at.endsWith("…") && bt.startsWith(at.slice(0, -1)) && at.length < bt.length) { cutAfter.push(tag); continue; }
      failures.push(`${loc} ${j.name} #${i}: ${JSON.stringify(bt)} -> ${JSON.stringify(at)} (flagged, ${resolved ? "but not the old text's source" : "and no resolver's output: English drawn as it is"})`);
    }
  }
}
console.log(`  base ${baseSha.slice(0, 7)} vs head ${head.slice(0, 7)}${dirty ? " + working tree" : ""}: ${draws} draws (${ids.length} drawers x main/help + ${CHROME.length} chrome x ${locales.length} locales), ${texts} texts, ${flagged} drawn with the flag`);
if (failures.length) {
  for (const f of failures.slice(0, 80)) console.log("  FAIL " + f);
  if (failures.length > 80) console.log(`  ... and ${failures.length - 80} more`);
  console.log(`renderer-parity: ${failures.length} failure(s)`);
  process.exit(1);
}
for (const c of okMap.slice(0, 20)) console.log("  OK-MAP " + c);
for (const c of cutAfter.slice(0, 40)) console.log("  CUT    " + c);
const shapes = [...new Set(letterless.map((l) => l.slice(l.indexOf(": ") + 2)))];
if (letterless.length) console.log(`  LETTERLESS ${letterless.length}: ${shapes.join(", ")}`);
console.log(`renderer-parity: PASS - every text drawn without the flag is as before (${okMap.length} "ok" -> "OK" from the removed map entry); every flagged change is a removed second translation (${removed}), a letterless text the old pass reshaped (${letterless.length}), or a name translated before its cut (${cutAfter.length})`);
