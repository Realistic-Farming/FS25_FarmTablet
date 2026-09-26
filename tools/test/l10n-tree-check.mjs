// l10n-tree-check.mjs - MAINTENANCE row 105's tree-wide text bar (the final fc sweep). Each per-batch bar checks its
// own keys; this one reads every key of every file, so a value no batch owns cannot carry the two defects the wave
// kept finding:
//   SCRIPT-OUT  a file written in Latin letters, and modDesc.xml's element for a Latin-script language, holds no
//               Han, kana, Hangul or Cyrillic letter. French Canadian (fc) is French: the sweep found 61 Chinese
//               values in it, and its modDesc input text in Chinese.
//   MARKER      no value in any file, English included, nor in modDesc.xml, carries the "[EN]" marker: 0cf4aeb
//               stamped 50 values "[EN] <English>" (Bob's row), and no per-batch bar owned their keys.
// And two named rows for this sweep's restorations:
//   LOCK        every other file's two Irrigation Suite lock lines name the Pro Staff Co-Op and carry the level (7,
//               18), as Wizard's English does, and are not English.
//   ACCENT      the Latin American Spanish RealisticDealer description reads "financiación".
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const failures = [];
const unesc = (s) => s.replace(/&#10;/g, "\n").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&apos;/g, "'").replace(/&amp;/g, "&");
const locales = readdirSync(join(ROOT, "translations")).map((f) => f.match(/^translation_([a-z]{2})\.xml$/)).filter(Boolean).map((m) => m[1]).sort();
// Languages written in their own script (cn: modDesc.xml's title carries a Chinese <cn> element); every other file
// is written in Latin letters.
const OWN_SCRIPT = new Set(["cn", "cs", "ct", "jp", "kr", "ru", "uk"]);
const FOREIGN = /[\u3040-\u30ff\u3400-\u9fff\uf900-\ufaff\uac00-\ud7af\u0400-\u04ff]/;
const MARK = /\[EN\]/;

const files = {};
for (const loc of locales) {
  const whole = readFileSync(join(ROOT, "translations", `translation_${loc}.xml`), "utf8");
  const map = new Map();
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  let m;
  while ((m = re.exec(whole)) !== null) map.set(m[1], unesc(m[2]));
  files[loc] = map;
}
if (locales.length < 26) failures.push(`[reached] only ${locales.length} translation files`);

// ---- SCRIPT-OUT and MARKER over every value of every file.
let latin = 0, marked = 0;
for (const loc of locales) {
  for (const [k, v] of files[loc]) {
    marked++;
    if (MARK.test(v)) failures.push(`MARKER ${loc}: ${k} ${JSON.stringify(v).slice(0, 90)} carries the "[EN]" marker`);
    if (OWN_SCRIPT.has(loc)) continue;
    latin++;
    if (FOREIGN.test(v)) failures.push(`SCRIPT-OUT ${loc}: ${k} ${JSON.stringify(v).slice(0, 90)} holds another script's letters in a Latin-script file`);
  }
}
if (latin < 20000) failures.push(`SCRIPT-OUT [reached] only ${latin} Latin-script values`);

// ---- modDesc.xml: every element named for a language (<de>, <fc>, ...) under its l10n blocks.
let md = 0;
{
  const whole = readFileSync(join(ROOT, "modDesc.xml"), "utf8");
  const re = /<([a-z]{2})>([\s\S]*?)<\/\1>/g;
  let m;
  while ((m = re.exec(whole)) !== null) {
    const [, loc, raw] = m;
    const v = raw.replace(/^<!\[CDATA\[|\]\]>$/g, "");
    md++;
    if (MARK.test(v)) failures.push(`MARKER modDesc <${loc}>: ${JSON.stringify(v.trim()).slice(0, 90)} carries the "[EN]" marker`);
    if (!OWN_SCRIPT.has(loc) && FOREIGN.test(v)) failures.push(`SCRIPT-OUT modDesc <${loc}>: ${JSON.stringify(v.trim()).slice(0, 90)} holds another script's letters`);
  }
  if (md < 26) failures.push(`modDesc [reached] only ${md} language elements`);
}

// ---- LOCK: the two lock lines in every other file.
let lock = 0;
for (const [key, level] of [["ft_irr_advisory_locked_l7", "7"], ["ft_irr_advisory_locked_l18", "18"]]) {
  const en = files.en.get(key);
  if (!en || !en.includes("Pro Staff Co-Op") || !en.includes(level)) failures.push(`LOCK en: ${key} ${JSON.stringify(en)} is not Wizard's wording`);
  for (const loc of locales) {
    if (loc === "en") continue;
    lock++;
    const v = files[loc].get(key);
    if (v == null) { failures.push(`LOCK ${loc}: ${key} is missing`); continue; }
    if (!v.includes("Pro Staff")) failures.push(`LOCK ${loc}: ${key} ${JSON.stringify(v)} does not name the Pro Staff Co-Op`);
    if (!new RegExp(`(^|\\D)${level}(\\D|$)`).test(v)) failures.push(`LOCK ${loc}: ${key} ${JSON.stringify(v)} does not carry level ${level}`);
    if (v === en) failures.push(`LOCK ${loc}: ${key} is English`);
  }
}

// ---- ACCENT: the one accent this sweep restores outside a batch.
{
  const v = files.ea.get("ft_desc_app_realistic_dealer") || "";
  if (!v.includes("financiación")) failures.push(`ACCENT ea: ft_desc_app_realistic_dealer ${JSON.stringify(v)} does not read "financiación"`);
}

console.log(`  SCRIPT-OUT: ${latin} values in ${locales.length - [...OWN_SCRIPT].filter((l) => files[l]).length} Latin-script files, ${md} modDesc language elements; MARKER: ${marked} values in ${locales.length} files; LOCK: ${lock} lines; ACCENT: 1`);
if (failures.length) {
  for (const f of failures.slice(0, 60)) console.log("  FAIL " + f);
  if (failures.length > 60) console.log(`  ... and ${failures.length - 60} more`);
  console.log(`l10n-tree: ${failures.length} failure(s)`);
  process.exit(1);
}
console.log("l10n-tree: PASS - no Latin-script file holds another script's letters, no value carries the \"[EN]\" marker, the lock lines name the Pro Staff Co-Op");
