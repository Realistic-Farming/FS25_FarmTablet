// l10n-fieldjobs-check.mjs - RSF-141's text bar over the 26 translation files.
//
// For each of the Field Jobs keys below, in every locale file:
//   - the key is present exactly once;
//   - its %s / %d placeholders are the same, in the same order, as English's
//     (FieldJobsApp's format helper falls back to English on an arity mismatch, so a
//     wrong count shows English rather than crashing, but it is still wrong);
//   - its literal "\n" breaks are as many as English's (the help panel's layout
//     depends on them; FieldJobsApp.lua converts the two characters to a newline);
//   - its text is not the English text, unless the (locale, key) pair is allowed below
//     with a reason (a legitimately identical word, never a copy passed off as a
//     translation: Tyson's ruling, MAINTENANCE row 80).
//
// Usage:  node tools/test/l10n-fieldjobs-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

// 13 keys #162 left English-only, then the 6 keys every locale carried as an English copy.
const KEYS = [
  "ft_fieldjobs_confirm_start", "ft_fieldjobs_purpose", "ft_fieldjobs_finish_job", "ft_fieldjobs_history_more",
  "ft_fieldjobs_field_label", "ft_fieldjobs_no_field", "ft_fieldjobs_help_start_title", "ft_fieldjobs_help_start_body",
  "ft_fieldjobs_help_finish_title", "ft_fieldjobs_help_finish_body", "ft_fieldjobs_help_history_body",
  "ft_fieldjobs_help_nav_title", "ft_fieldjobs_help_nav_body",
  "ft_fieldjobs_no_job", "ft_fieldjobs_start_job", "ft_fieldjobs_recent_jobs", "ft_fieldjobs_no_completed",
  "ft_fieldjobs_no_job_short", "ft_common_history",
];
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "da:ft_fieldjobs_start_job": "cognate: Danish says Start job",
};

function entries(file) {
  const text = readFileSync(file, "utf8");
  const out = new Map();
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (!out.has(m[1])) out.set(m[1], []);
    out.get(m[1]).push(m[2]);
  }
  return out;
}
const placeholders = (s) => (s.match(/%[sd]/g) || []).join(",");
const breaks = (s) => (s.match(/\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const en = entries(join(DIR, "translation_en.xml"));
const failures = [];
for (const key of KEYS) {
  const e = en.get(key);
  if (!e || e.length !== 1) { failures.push(`en: ${key} present ${e ? e.length : 0} times`); continue; }
  for (const loc of locales) {
    const got = entries(join(DIR, `translation_${loc}.xml`)).get(key) || [];
    if (got.length !== 1) { failures.push(`${loc}: ${key} present ${got.length} times`); continue; }
    const v = got[0];
    if (placeholders(v) !== placeholders(e[0])) failures.push(`${loc}: ${key} placeholders [${placeholders(v)}] differ from English [${placeholders(e[0])}]`);
    if (breaks(v) !== breaks(e[0])) failures.push(`${loc}: ${key} has ${breaks(v)} line breaks, English ${breaks(e[0])}`);
    if (v === e[0] && !ALLOW[`${loc}:${key}`]) failures.push(`${loc}: ${key} is the English text`);
  }
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-fieldjobs: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-fieldjobs: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical`);
