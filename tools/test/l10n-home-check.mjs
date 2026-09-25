// l10n-home-check.mjs - MAINTENANCE row 105's text bar for the home screen, the lock screen and
// the app names (the first app PR of the translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn: the app names by the home grid (HomeScreen.lua appLabel), the app
// headers and the App Store (AppRegistry.lua names); the home screen's labels by HomeScreen.lua;
// the grid's short names by HomeScreen.lua:45 ("ft_ui_short_" .. app.id); the lock screen's by
// LockScreen.lua (the date line, the slide hint, the farm-name fallback, the season through
// FT.l10nAuto). For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its %s / %d placeholders are English's, in English's order;
//   - its "\n" line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (a mod's own name, a word the language shares with English; never a copy passed
//     off as a translation: Tyson's ruling, MAINTENANCE row 80).
// And one control-name row: the favourites hint names the EDIT button by the button's own
// text in that language (ft_auto_tap_edit_then_pick_your_apps contains ft_auto_edit).
//
// Usage:  node tools/test/l10n-home-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const APP_NAMES = [
  "ft_ui_app_dashboard", "ft_ui_app_store", "ft_ui_app_updates", "ft_ui_app_settings", "ft_ui_app_system_settings",
  "ft_ui_app_workshop", "ft_ui_app_field_status", "ft_ui_app_field_sentry", "ft_ui_app_rotation_planner",
  "ft_ui_app_organic", "ft_ui_app_irrigation_suite", "ft_ui_app_financial_cockpit", "ft_ui_app_animals",
  "ft_ui_app_dairy", "ft_ui_app_weather", "ft_ui_app_excavator", "ft_ui_app_income_mod", "ft_ui_app_tax_mod",
  "ft_ui_app_npc_favor", "ft_ui_app_soil_fertilizer", "ft_ui_app_market_dynamics", "ft_ui_app_worker_costs",
  "ft_ui_app_personnel", "ft_ui_app_prostaff", "ft_ui_app_random_world_events", "ft_ui_app_used_plus",
  "ft_ui_app_roleplay_phone", "ft_ui_app_storage", "ft_ui_app_hotspot_manager", "ft_ui_app_notes",
  "ft_ui_app_farm_admin", "ft_ui_app_field_jobs", "ft_ui_app_contracts", "ft_ui_app_fleet_manager",
  "ft_ui_app_production_buildings", "ft_ui_app_farm_stats", "ft_ui_app_animal_auto_care",
  "ft_ui_app_animal_vet_system", "ft_ui_app_factory_week_schedule", "ft_ui_app_realistic_dealer",
];
const HOME = [
  "ft_auto_favourites", "ft_auto_done", "ft_auto_edit", "ft_auto_no_favourites_yet",
  "ft_auto_tap_edit_then_pick_your_apps", "ft_auto_tap_an_app_to_add_or_remove_it_from_favourites", "ft_auto_fields_3",
  "ft_ui_short_financial_cockpit", "ft_ui_short_hotspot_manager", "ft_ui_short_fleet_manager",
  "ft_ui_short_irrigation_suite", "ft_ui_short_soil_fertilizer", "ft_ui_short_field_sentry",
];
const LOCK = [
  "ft_lockscreen_date_day", "ft_lockscreen_slide_to_unlock", "ft_auto_my_farm",
  "ft_auto_spring", "ft_auto_summer", "ft_auto_autumn", "ft_auto_winter",
];
const KEYS = [...APP_NAMES, ...HOME, ...LOCK];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  "ft_ui_app_prostaff": "a mod's own name: ProStaff Co-Op",
  "ft_ui_app_used_plus": "a mod's own name: UsedPlus",
  "ft_ui_app_animal_auto_care": "a mod's own name: AnimalAutoCare",
  "ft_ui_app_realistic_dealer": "a mod's own name: RealisticDealer",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "nl:ft_ui_app_updates": "loanword: Dutch says Updates",
  "ro:ft_ui_app_excavator": "cognate: Romanian says Excavator",
  "fr:ft_ui_app_personnel": "cognate: French says Personnel",
  "fc:ft_ui_app_personnel": "cognate: French says Personnel",
  "fr:ft_ui_app_notes": "cognate: French says Notes",
  "fc:ft_ui_app_notes": "cognate: French says Notes",
  "fr:ft_ui_app_production_buildings": "cognate: French says Production",
  "fc:ft_ui_app_production_buildings": "cognate: French says Production",
  "fr:ft_ui_short_financial_cockpit": "cognate: French says Finances",
  "fc:ft_ui_short_financial_cockpit": "cognate: French says Finances",
  "de:ft_auto_winter": "cognate: German says Winter",
  "nl:ft_auto_winter": "cognate: Dutch says Winter",
};

function entries(file) {
  const whole = readFileSync(file, "utf8");
  const s = whole.indexOf("<texts>"), e = whole.indexOf("</texts>");
  const re = /<text\s+name="([^"]+)"\s+text="([^"]*)"\s*\/>/g;
  const inside = new Map(), outside = new Map();
  let m;
  while ((m = re.exec(whole)) !== null) {
    const map = m.index > s && m.index < e ? inside : outside;
    if (!map.has(m[1])) map.set(m[1], []);
    map.get(m[1]).push(m[2]);
  }
  return { inside, outside };
}
const placeholders = (s) => (s.match(/%[sd]/g) || []).join(",");
const breaks = (s) => (s.match(/&#10;|\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const EN = entries(join(DIR, "translation_en.xml"));
const failures = [];
for (const key of KEYS) {
  const e = EN.inside.get(key);
  if (!e || e.length !== 1) { failures.push(`en: ${key} present ${e ? e.length : 0} times inside <texts>`); continue; }
  if (EN.outside.has(key)) failures.push(`en: ${key} also sits outside <texts>`);
}
for (const loc of locales) {
  const L = entries(join(DIR, `translation_${loc}.xml`));
  for (const key of KEYS) {
    const e = EN.inside.get(key);
    if (!e || e.length !== 1) continue;
    if (L.outside.has(key)) failures.push(`${loc}: ${key} sits outside <texts>, where FS25 does not read it`);
    const got = L.inside.get(key) || [];
    if (got.length !== 1) { failures.push(`${loc}: ${key} present ${got.length} times inside <texts>`); continue; }
    const v = got[0];
    if (placeholders(v) !== placeholders(e[0])) failures.push(`${loc}: ${key} placeholders [${placeholders(v)}] differ from English [${placeholders(e[0])}]`);
    if (breaks(v) !== breaks(e[0])) failures.push(`${loc}: ${key} has ${breaks(v)} line breaks, English ${breaks(e[0])}`);
    if (v === e[0] && !ALLOW[`${loc}:${key}`] && !ALLOW_ALL[key]) failures.push(`${loc}: ${key} is the English text`);
  }
  const edit = (L.inside.get("ft_auto_edit") || [])[0];
  const hint = (L.inside.get("ft_auto_tap_edit_then_pick_your_apps") || [])[0];
  if (edit && hint && !hint.includes(edit)) failures.push(`${loc}: the favourites hint does not name the EDIT button's text ${JSON.stringify(edit)}`);
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-home: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-home: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} mod names`);
