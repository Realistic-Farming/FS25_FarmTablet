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
// The Field Jobs screens' labels (RSF-141's "exact control names" clause, the follow-up to #166):
// the ft_auto_* words the screens draw through FT.l10nAuto (src/core/Constants.lua), the same
// checks; units ("h ", " ha") are the same in every language and are allowed as such.
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
  // The screens' auto labels (50): the words the Field Jobs screens draw, so the help's control
  // names match what the player sees.
  "ft_auto_1_active_job", "ft_auto_active_3", "ft_auto_area_2", "ft_auto_at", "ft_auto_back", "ft_auto_baling",
  "ft_auto_clear", "ft_auto_day", "ft_auto_day_3", "ft_auto_dur", "ft_auto_elapsed", "ft_auto_empty_3",
  "ft_auto_fertilizing", "ft_auto_field_2", "ft_auto_field_4", "ft_auto_field_5", "ft_auto_field_jobs",
  "ft_auto_finish_current_first", "ft_auto_finish_job", "ft_auto_finishing_a_job", "ft_auto_general_work",
  "ft_auto_h_3", "ft_auto_ha", "ft_auto_harvesting", "ft_auto_history_2", "ft_auto_history_3", "ft_auto_home",
  "ft_auto_job", "ft_auto_mowing_cutting", "ft_auto_new_job", "ft_auto_no_active_job", "ft_auto_no_completed_jobs_yet",
  "ft_auto_no_job_running", "ft_auto_no_vehicle", "ft_auto_plowing_cultivating", "ft_auto_rolling",
  "ft_auto_sowing_planting", "ft_auto_spraying", "ft_auto_start", "ft_auto_start_job_2", "ft_auto_start_new",
  "ft_auto_started_day", "ft_auto_starting_a_job", "ft_auto_state", "ft_auto_stone_picking", "ft_auto_task",
  "ft_auto_unknown", "ft_auto_vehicle", "ft_auto_vehicle_3", "ft_auto_you_don_t_own_any_fields",
];
// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  "ft_auto_h_3": "unit: h is the hour symbol everywhere",
  "ft_auto_ha": "unit: ha is the hectare symbol everywhere",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "da:ft_fieldjobs_start_job": "cognate: Danish says Start job",
  "da:ft_auto_start_job_2": "cognate: Danish says start job",
  "da:ft_auto_start": "cognate: Danish says start",
  "no:ft_auto_start": "cognate: Norwegian says start",
  "pl:ft_auto_start": "cognate: Polish says start",
  "cz:ft_auto_start": "cognate: Czech says start",
  "nl:ft_auto_home": "cognate: Dutch names the home screen start",
  "it:ft_auto_area_2": "cognate: Italian says Area",
  "da:ft_auto_job": "cognate: Danish says job",
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
    if (v === e[0] && !ALLOW[`${loc}:${key}`] && !ALLOW_ALL[key]) failures.push(`${loc}: ${key} is the English text`);
  }
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-fieldjobs: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-fieldjobs: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} unit keys`);
