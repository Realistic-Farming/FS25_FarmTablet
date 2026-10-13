// l10n-irrigation-suite-check.mjs - MAINTENANCE row 105's text bar for the Irrigation Suite (batch 17, the last app
// batch of the tablet translation wave; the pattern of l10n-financial-cockpit-check.mjs, #204).
//
// IrrigationSuiteApp.lua (the suite's Wizard UI brief of 2026-07-24; SCS-046's rain key; SCS-009's advisory; SCS-023's
// Operations strings; RSF-F245's trend): the three views, the coverage outline, the advisory and the help page.
// Drawn literals reach their keys through the renderer's FT.l10nAuto; built texts through FT.l10n,
// FT.l10nFormat and an app's own helper. A SOURCES entry's drawnTables names a local table whose string
// values the app draws through FT.l10nAuto, and drawnArgs a local function whose argument at an index it
// draws that way: each such value is checked as a drawn literal (S2) and executed (X1). keyTables names a
// local table of { key = "...", fallback = "..." } entries and the helper that draws them: each entry's
// key is a key site of that helper (S1, S4, X1), and the file must call the helper with an entry's .key
// (S1), so a table nobody draws fails.
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80);
//   - script row (Bob's MAJOR on #177): in a locale written in its own script, the text carries at
//     least one letter of that script (CJK ideographs for cs and ct, kana or CJK for jp, Hangul for
//     kr, Cyrillic for ru and uk), unless the key is an own name (ALLOW_ALL), the pair is allowed
//     below, or English's own text holds no letter. A romanised or other-language value differs
//     from English, so the rows above pass it; this row fails it. FarmTablet ships no
//     translation_cs.xml, so the row covers ct, jp, kr, ru and uk until one is added.
//
// CASE row: a text English writes in capitals (no lowercase letter) holds no lowercase letter in any file: the
// section headers, badges, buttons and help titles. German's were title case where every other German header on the
// tablet is capitals. (No lowercase letter, not v === v.toUpperCase(): German's ß upper-cases to SS.)
// SCRIPT-OUT row: a file written in Latin letters holds no Han, kana, Hangul or Cyrillic letter (fc is French Canadian).
// ACCENT row: every existing value the import had stripped of its accents (278 in 17 files, German's ae/oe/ue/ss
// digraphs and partial strips included) keeps as many letters outside ASCII as its restored text has.
// FALLBACK row (#204's rule): every key's English equals the fallback the code passes with it (a ".." chain of
// literals joined). The file wins at run time, so an English value the code has moved on from is never seen: the lock
// lines' fallback takes Wizard's English (the Pro Staff Co-Op, 0cf4aeb), Bob's batch 17 intake, ruling 1.
//
// Draw-site rows (below the text rows), over the real source files in SOURCES:
//   S1  every key a SOURCES file passes as a literal to one of its text functions (KEYFN) is one of
//       KEYS or named in OTHER_PR, and translation_en.xml carries it;
//   S2  every literal a SOURCES file hands straight to a drawing call (DRAWFN) or holds in a drawn
//       table field resolves through the real FT.AUTO_L10N (Constants.lua run in fengari) to one of
//       KEYS or OTHER_PR, unless NO_KEY names it with its reason; none holds an em dash;
//   S3  no drawing call (and no FT_Renderer.truncate, whose result is drawn) gets text built from an
//       English literal at run time: a string.format of a worded literal, or a concatenation holding
//       one. FT.l10nAuto looks the whole text up, so such text reads English in every language.
//   S4  every key in KEYS is drawn by a SOURCES file: a key call, or a drawn literal the real map sends to it,
//       unless UNDRAWN names it with its reason. A text moved back to a bare literal leaves its key
//       checked and never drawn; S4 fails that.
//   X1  the lookup, executed (Bob's ask on #181): every key call site runs the app's OWN text helper
//       (cut from the real source, with the top-level definitions it needs, the globals other src
//       files set included, such as FarmTabletUI.lua's FT_UI_TEXT) in fengari beside the real
//       Constants.lua, with g_i18n answering from the real locale file, in all 26 files; each drawn
//       literal runs the real FT.l10nAuto. The result must be the file's text (formatted, when the
//       site passes arguments), never the fallback. S1 and S2 read the code; X1 runs it. A helper the
//       bar cannot run fails X1 until X1_SKIP names it with a reason.
//   S5  a drawnArgs function draws that parameter through FT.l10nAuto (none in this batch).
// keyTables here: MODE_LABEL and the three rain-key lookup tables (RAIN_KEY_STATE_TEXT, PAUSE_REASON_TEXT,
// ACTIVITY_TEXT), each entry drawn through _T by its .key.
//
// Usage:  node tools/test/l10n-irrigation-suite-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  "ft_irr_mode_operations", "ft_irr_mode_forecast", "ft_irr_mode_usage", "ft_rainKey_unknown", "ft_rainKey_mm",
  "ft_irr_mins", "ft_irr_hours", "ft_rainKey_unfitted", "ft_rainKey_armed", "ft_rainKey_collecting",
  "ft_rainKey_tripped", "ft_rainKey_inputUnavail", "ft_rainKey_whyTripped", "ft_rainKey_whyNoInput",
  "ft_rainKey_whyNoSource", "ft_rainKey_whyNoPress", "ft_rainKey_whySchedule", "ft_rainKey_whyMaster",
  "ft_rainKey_running", "ft_rainKey_rainPaused", "ft_rainKey_off", "ft_water_na", "ft_water_unlimited",
  "ft_water_dry", "ft_water_hours", "ft_water_stop_dry", "ft_water_stop_nosource", "ft_rainKey_dryResetIn",
  "ft_rainKey_dryResetPending", "ft_rainKey_nextCheckIn", "ft_rainKey_nextCheck", "ft_rainKey_playerAction",
  "ft_irr_na", "ft_irr_schedule_na", "ft_irr_day_mon", "ft_irr_day_tue", "ft_irr_day_wed", "ft_irr_day_thu",
  "ft_irr_day_fri", "ft_irr_day_sat", "ft_irr_day_sun", "ft_irr_no_active_days", "ft_irr_every_day",
  "ft_irr_no_coverage", "ft_irr_trend_watering", "ft_irr_trend_drying", "ft_irr_trend_wet", "ft_irr_trend_steady",
  "ft_irr_help_what_title", "ft_irr_help_what_body", "ft_irr_help_ops_title", "ft_irr_help_ops_body",
  "ft_irr_help_forecast_title", "ft_irr_help_forecast_body", "ft_irr_help_usage_title", "ft_irr_help_usage_body",
  "ft_irr_scs_not_detected", "ft_irr_scs_install", "ft_water_header", "ft_water_none", "ft_water_source",
  "ft_water_connected", "ft_irr_systems", "ft_irr_no_systems", "ft_irr_idle", "ft_irr_no_schedule",
  "ft_irr_system_line", "ft_rainKey_unknownState", "ft_rainKey_collected", "ft_rainKey_trip",
  "ft_rainKey_whyUnknown", "ft_irr_coverage_outline", "ft_irr_moisture_split", "ft_irr_more_fields",
  "ft_irr_watering", "ft_irr_field_tag", "ft_irr_split_line", "ft_irr_moisture_na", "ft_irr_no_moisture_reads",
  "ft_irr_farm_advisory", "ft_irr_trend_header", "ft_irr_air_line", "ft_irr_field", "ft_irr_moist_line",
  "ft_irr_alerts_capped", "ft_irr_advisory_water_need", "ft_irr_advisory_locked_l7", "ft_irr_call_water_today",
  "ft_irr_call_watch", "ft_irr_call_can_hold", "ft_irr_advisory_no_reads", "ft_irr_advisory_forward_call",
  "ft_irr_advisory_locked_l18", "ft_irr_advisory_schedule_covers", "ft_irr_advisory_schedule_gap",
  "ft_irr_covered_gap", "ft_irr_usage_header", "ft_irr_costs_off", "ft_irr_no_systems_price", "ft_irr_usage_line",
  "ft_irr_soil_risk_header", "ft_irr_soil_na", "ft_irr_unscouted", "ft_irr_soil_line", "ft_irr_no_risk_reads",
  "ft_irr_private_unavailable", "ft_irr_fitted_path",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {

};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
  "br:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "cz:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "da:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "ea:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "es:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "fc:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "fi:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "fr:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "it:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "nl:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "no:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "pl:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "pt:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "ro:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "sv:ft_irr_mins": "the language writes minutes as min, the unit symbol",
  "br:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "br:ft_water_hours": "the language writes hours as h, the unit symbol",
  "cz:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "cz:ft_water_hours": "the language writes hours as h, the unit symbol",
  "ea:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "ea:ft_water_hours": "the language writes hours as h, the unit symbol",
  "es:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "es:ft_water_hours": "the language writes hours as h, the unit symbol",
  "fc:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "fc:ft_water_hours": "the language writes hours as h, the unit symbol",
  "fi:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "fi:ft_water_hours": "the language writes hours as h, the unit symbol",
  "fr:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "fr:ft_water_hours": "the language writes hours as h, the unit symbol",
  "it:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "it:ft_water_hours": "the language writes hours as h, the unit symbol",
  "pl:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "pl:ft_water_hours": "the language writes hours as h, the unit symbol",
  "pt:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "pt:ft_water_hours": "the language writes hours as h, the unit symbol",
  "ro:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "ro:ft_water_hours": "the language writes hours as h, the unit symbol",
  "sv:ft_irr_hours": "the language writes hours as h, the unit symbol",
  "sv:ft_water_hours": "the language writes hours as h, the unit symbol",
};
// (locale, key) pairs in a script locale whose text is written in Latin letters and differs from
// English, each with its reason (a unit symbol the language writes that way, such as jp "ha").
const SCRIPT_ALLOW = {

};
// Keys this app draws that another PR of the wave checks, with the PR.
const OTHER_PR = {
  "ft_ui_app_irrigation_suite": "the app's name, carried by row 105's app-names batch",
};
// Drawn literals with no key, each with its reason.
const NO_KEY = {

};
// Keys this bar checks that no SOURCES file draws, each with its reason.
const UNDRAWN = {
  "ft_rainKey_unknownState": "_lookup's fallback key (IrrigationSuiteApp.lua:569), drawn through _T inside _lookup (:74) when SCS reports a rain-key state RAIN_KEY_STATE_TEXT does not name",
  "ft_rainKey_whyUnknown": "_lookup's fallback key (:599), drawn through _T inside _lookup (:74) when SCS reports a pause reason PAUSE_REASON_TEXT does not name",
  "ft_irr_call_water_today": "returned by _waterCall (:345) and drawn through _T(callKey, ...) at :841 and _T(callK, ...) at :886",
  "ft_irr_call_watch": "returned by _waterCall (:345) and drawn through _T(callKey, ...) at :841 and _T(callK, ...) at :886",
  "ft_irr_call_can_hold": "returned by _waterCall (:345) and drawn through _T(callKey, ...) at :841 and _T(callK, ...) at :886",
  "ft_irr_advisory_schedule_covers": "chosen into fwdKey (:880) and drawn through _T(fwdKey, fwdTxt) at :889",
  "ft_irr_advisory_schedule_gap": "chosen into fwdKey (:880) and drawn through _T(fwdKey, fwdTxt) at :889",
};
// Key helpers X1 does not run, each with its reason (e.g. a helper returning a table of lines).
const X1_SKIP = {

};
// [outer, inner]: the outer text names the inner key's text (case-insensitive).
const CONTAINS = [
];
// The source files the draw-site rows read, and in each the text functions whose first argument is
// a key. keyPrefix limits a shared file to this app's keys.
const SOURCES = [
  {"file": "src/apps/IrrigationSuiteApp.lua", "keyFns": ["_T", "l10n", "l10nFormat"], "literals": true, "keyTables": {"MODE_LABEL": "_T", "RAIN_KEY_STATE_TEXT": "_T", "PAUSE_REASON_TEXT": "_T", "ACTIVITY_TEXT": "_T"}},
];
const DRAWFN = new Set(["appText", "text", "drawRow", "drawSection", "button", "drawButton", "drawButtonPair",
  "drawAppHeader", "appHeaderText", "sectionHeader", "row", "badge", "l10nAuto", "infoRow", "actionRow", "section"]);
const FIELDS = new Set(["title", "label", "section"]);

const ALL = {};
const unesc = (s) => s.replace(/&#10;/g, "\n").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&apos;/g, "'").replace(/&amp;/g, "&");
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
const SCRIPT = {
  cs: { name: "CJK ideograph", re: /\p{Script=Han}/u },
  ct: { name: "CJK ideograph", re: /\p{Script=Han}/u },
  jp: { name: "kana or CJK ideograph", re: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/u },
  kr: { name: "Hangul letter", re: /\p{Script=Hangul}/u },
  ru: { name: "Cyrillic letter", re: /\p{Script=Cyrillic}/u },
  uk: { name: "Cyrillic letter", re: /\p{Script=Cyrillic}/u },
};
const hasLetter = (s) => /\p{L}/u.test(s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, "").replace(/&[a-z]+;|&#\d+;/g, ""));
let scriptChecked = 0;
const placeholders = (s) => (s.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).join(",");
const breaks = (s) => (s.match(/&#10;|\\n/g) || []).length;

const files = readdirSync(DIR).filter((f) => /^translation_[a-z]{2}\.xml$/.test(f)).sort();
const locales = files.map((f) => f.slice("translation_".length, -".xml".length)).filter((l) => l !== "en");
if (locales.length !== 25) { console.log(`expected 25 non-English locale files, found ${locales.length}`); process.exit(1); }
const EN = entries(join(DIR, "translation_en.xml"));
ALL.en = EN;
const failures = [];
for (const key of KEYS) {
  const e = EN.inside.get(key);
  if (!e || e.length !== 1) { failures.push(`en: ${key} present ${e ? e.length : 0} times inside <texts>`); continue; }
  if (EN.outside.has(key)) failures.push(`en: ${key} also sits outside <texts>`);
}
for (const loc of locales) {
  const L = entries(join(DIR, `translation_${loc}.xml`));
  ALL[loc] = L;
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
    if (SCRIPT[loc] && !ALLOW_ALL[key] && !ALLOW[`${loc}:${key}`] && !SCRIPT_ALLOW[`${loc}:${key}`] && hasLetter(e[0])) {
      scriptChecked++;
      if (!SCRIPT[loc].re.test(v)) failures.push(`${loc}: ${key} ${JSON.stringify(v)} holds no ${SCRIPT[loc].name}: it is another language, or romanised`);
    }
  }
  for (const [outer, inner] of CONTAINS) {
    const o = (L.inside.get(outer) || [])[0], i = (L.inside.get(inner) || [])[0];
    if (o && i && !unesc(o).toLowerCase().includes(unesc(i).toLowerCase())) failures.push(`${loc}: ${outer} does not name ${inner}'s text ${JSON.stringify(unesc(i))}`);
  }
}

// ---- CASE, SCRIPT-OUT and ACCENT (batch 16's rows).
{
  const lower = (s) => [...s.replace(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g, "")].some((c) => c !== c.toUpperCase() && c === c.toLowerCase());
  const CAPS = KEYS.filter((k) => !lower(unesc((EN.inside.get(k) || [""])[0])));
  const FOREIGN = /[\u3040-\u30ff\u3400-\u9fff\uf900-\ufaff\uac00-\ud7af\u0400-\u04ff]/;
  const FOLD = { "\u00e6": "ae", "\u00c6": "AE", "\u00f8": "o", "\u00d8": "O", "\u0142": "l", "\u0141": "L", "\u0111": "d", "\u0110": "D", "\u0131": "i" };
  const fold = (s) => [...s].map((c) => FOLD[c] ?? c).join("").normalize("NFKD").replace(/\p{M}/gu, "");
  const ACCENT = {
    br: { "ft_irr_advisory_forward_call": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyNoInput": 3, "ft_rainKey_whyNoSource": 1, "ft_rainKey_whyNoPress": 1, "ft_rainKey_whySchedule": 1, "ft_rainKey_whyMaster": 2, "ft_rainKey_whyUnknown": 1, "ft_rainKey_running": 2, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 1, "ft_rainKey_nextCheckIn": 3, "ft_rainKey_nextCheck": 5, "ft_rainKey_playerAction": 3, "ft_water_header": 1, "ft_water_na": 1, "ft_water_none": 1, "ft_water_source": 1 },
    cz: { "ft_rainKey_unknown": 1, "ft_rainKey_mm": 1, "ft_rainKey_unfitted": 3, "ft_rainKey_armed": 2, "ft_rainKey_collecting": 5, "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 2, "ft_rainKey_whyTripped": 4, "ft_rainKey_whyNoInput": 5, "ft_rainKey_whyNoSource": 3, "ft_rainKey_whyNoPress": 3, "ft_rainKey_whyMaster": 5, "ft_rainKey_whyUnknown": 2, "ft_rainKey_running": 3, "ft_rainKey_rainPaused": 2, "ft_rainKey_unknownState": 3, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 4, "ft_rainKey_nextCheckIn": 2, "ft_rainKey_nextCheck": 4, "ft_rainKey_playerAction": 2, "ft_rainKey_collected": 2, "ft_rainKey_trip": 1, "ft_water_unlimited": 1, "ft_water_na": 1, "ft_water_none": 2, "ft_water_connected": 1, "ft_water_stop_nosource": 3 },
    da: { "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoInput": 1, "ft_rainKey_whyUnknown": 2, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 1, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 1, "ft_rainKey_trip": 1, "ft_water_unlimited": 1, "ft_water_dry": 1, "ft_water_na": 1, "ft_water_none": 2, "ft_water_stop_dry": 1 },
    de: { "ft_irr_advisory_water_need": 1, "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 1, "ft_rainKey_whySchedule": 1, "ft_rainKey_whyMaster": 1, "ft_rainKey_whyUnknown": 1, "ft_rainKey_running": 1, "ft_rainKey_dryResetPending": 1, "ft_rainKey_nextCheckIn": 2, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 2, "ft_water_na": 1 },
    ea: { "ft_irr_advisory_forward_call": 2, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoPress": 1, "ft_rainKey_nextCheckIn": 2, "ft_rainKey_nextCheck": 2, "ft_rainKey_playerAction": 1 },
    es: { "ft_irr_advisory_forward_call": 2, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoPress": 1, "ft_rainKey_nextCheckIn": 2, "ft_rainKey_nextCheck": 2, "ft_rainKey_playerAction": 1 },
    fi: { "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoInput": 2, "ft_rainKey_whyNoSource": 2, "ft_rainKey_whyMaster": 2, "ft_rainKey_running": 1, "ft_rainKey_playerAction": 1, "ft_water_header": 1, "ft_water_none": 4, "ft_water_source": 1, "ft_water_stop_dry": 1, "ft_water_stop_nosource": 2 },
    fr: { "ft_irr_advisory_forward_call": 1, "ft_rainKey_mm": 2, "ft_rainKey_armed": 1, "ft_rainKey_tripped": 2, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 4, "ft_rainKey_whyNoInput": 2, "ft_rainKey_whyMaster": 3, "ft_rainKey_off": 1, "ft_rainKey_unknownState": 1, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 3, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 2, "ft_rainKey_playerAction": 1, "ft_rainKey_collected": 1, "ft_water_unlimited": 1, "ft_water_dry": 1, "ft_water_connected": 1, "ft_water_stop_dry": 1 },
    hu: { "ft_rainKey_unfitted": 4, "ft_rainKey_armed": 5, "ft_rainKey_collecting": 2, "ft_rainKey_tripped": 3, "ft_rainKey_inputUnavail": 5, "ft_rainKey_whyTripped": 5, "ft_rainKey_whyNoInput": 4, "ft_rainKey_whyNoSource": 2, "ft_rainKey_whyNoPress": 1, "ft_rainKey_whySchedule": 2, "ft_rainKey_whyMaster": 5, "ft_rainKey_whyUnknown": 2, "ft_rainKey_running": 2, "ft_rainKey_rainPaused": 2, "ft_rainKey_unknownState": 4, "ft_rainKey_dryResetIn": 4, "ft_rainKey_dryResetPending": 4, "ft_rainKey_nextCheckIn": 4, "ft_rainKey_nextCheck": 4, "ft_rainKey_playerAction": 4, "ft_rainKey_collected": 2, "ft_rainKey_trip": 2, "ft_water_header": 2, "ft_water_unlimited": 1, "ft_water_hours": 1, "ft_water_dry": 1, "ft_water_na": 2, "ft_water_none": 2, "ft_water_source": 2, "ft_water_stop_dry": 2, "ft_water_stop_nosource": 1 },
    it: { "ft_rainKey_whyTripped": 2 },
    no: { "ft_rainKey_tripped": 1, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoInput": 1, "ft_rainKey_whyUnknown": 1, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 1, "ft_water_dry": 1, "ft_water_none": 2, "ft_water_stop_dry": 1 },
    pl: { "ft_rainKey_tripped": 2, "ft_rainKey_whyTripped": 2, "ft_rainKey_whyNoInput": 2, "ft_rainKey_whyNoSource": 3, "ft_rainKey_whyNoPress": 1, "ft_rainKey_whyMaster": 6, "ft_rainKey_whyUnknown": 2, "ft_rainKey_off": 2, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 5, "ft_rainKey_trip": 1, "ft_water_header": 3, "ft_water_na": 1, "ft_water_none": 3, "ft_water_source": 3, "ft_water_connected": 2, "ft_water_stop_dry": 3, "ft_water_stop_nosource": 3 },
    pt: { "ft_irr_advisory_forward_call": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyNoInput": 3, "ft_rainKey_whyNoSource": 1, "ft_rainKey_whyNoPress": 1, "ft_rainKey_whySchedule": 1, "ft_rainKey_whyUnknown": 1, "ft_rainKey_dryResetIn": 1, "ft_rainKey_dryResetPending": 1, "ft_rainKey_nextCheckIn": 3, "ft_rainKey_nextCheck": 5, "ft_rainKey_playerAction": 3, "ft_water_header": 1, "ft_water_na": 1, "ft_water_none": 1, "ft_water_source": 1 },
    ro: { "ft_rainKey_mm": 1, "ft_rainKey_unfitted": 2, "ft_rainKey_collecting": 1, "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoInput": 1, "ft_rainKey_whyNoSource": 4, "ft_rainKey_whyNoPress": 2, "ft_rainKey_whySchedule": 1, "ft_rainKey_whyMaster": 2, "ft_rainKey_running": 2, "ft_rainKey_rainPaused": 1, "ft_rainKey_unknownState": 1, "ft_rainKey_dryResetIn": 2, "ft_rainKey_dryResetPending": 2, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 4, "ft_water_header": 1, "ft_water_dry": 1, "ft_water_none": 4, "ft_water_source": 2, "ft_water_stop_dry": 2, "ft_water_stop_nosource": 3 },
    sv: { "ft_rainKey_unknown": 1, "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 1, "ft_rainKey_whyNoInput": 2, "ft_rainKey_whyNoSource": 1, "ft_rainKey_whySchedule": 1, "ft_rainKey_whyMaster": 1, "ft_rainKey_whyUnknown": 1, "ft_rainKey_unknownState": 1, "ft_rainKey_dryResetIn": 2, "ft_rainKey_dryResetPending": 3, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 4, "ft_rainKey_trip": 1, "ft_water_header": 1, "ft_water_unlimited": 1, "ft_water_na": 1, "ft_water_none": 3, "ft_water_source": 1, "ft_water_stop_dry": 2, "ft_water_stop_nosource": 1 },
    tr: { "ft_rainKey_unfitted": 6, "ft_rainKey_armed": 2, "ft_rainKey_collecting": 1, "ft_rainKey_tripped": 1, "ft_rainKey_inputUnavail": 1, "ft_rainKey_whyTripped": 5, "ft_rainKey_whyNoInput": 1, "ft_rainKey_whyNoSource": 2, "ft_rainKey_whyNoPress": 2, "ft_rainKey_whySchedule": 3, "ft_rainKey_whyMaster": 2, "ft_rainKey_running": 2, "ft_rainKey_rainPaused": 1, "ft_rainKey_off": 1, "ft_rainKey_unknownState": 1, "ft_rainKey_dryResetIn": 2, "ft_rainKey_dryResetPending": 4, "ft_rainKey_nextCheckIn": 1, "ft_rainKey_nextCheck": 1, "ft_rainKey_playerAction": 4, "ft_rainKey_trip": 1, "ft_water_unlimited": 3, "ft_water_na": 2, "ft_water_none": 3, "ft_water_source": 2, "ft_water_connected": 2 },
    vi: { "ft_water_header": 3, "ft_water_unlimited": 3, "ft_water_hours": 1, "ft_water_dry": 1, "ft_water_na": 3, "ft_water_none": 8, "ft_water_source": 3, "ft_water_connected": 2, "ft_water_stop_dry": 2, "ft_water_stop_nosource": 3 },
  };
  let caps = 0, latin = 0, acc = 0;
  for (const loc of ["en", ...locales]) {
    const L = ALL[loc];
    const val = (k) => unesc((L.inside.get(k) || [""])[0]);
    for (const k of CAPS) { caps++; if (lower(val(k))) failures.push(`CASE ${loc}: ${k} ${JSON.stringify(val(k))} holds a lowercase letter where English writes capitals`); }
    if (!SCRIPT[loc]) for (const k of KEYS) { latin++; if (FOREIGN.test(val(k))) failures.push(`SCRIPT-OUT ${loc}: ${k} ${JSON.stringify(val(k))} holds another script's letters in a Latin-script file`); }
  }
  for (const [loc, keys] of Object.entries(ACCENT)) for (const [k, n] of Object.entries(keys)) { acc++; const v = unesc((ALL[loc].inside.get(k) || [""])[0]); const have = [...v].filter((c) => c.codePointAt(0) > 127).length; if (have < n) failures.push(`ACCENT ${loc}: ${k} ${JSON.stringify(v)} carries ${have} of its ${n} letters outside ASCII: the import's stripped text is back`); }
  console.log(`  CASE: ${CAPS.length} capitals keys (${caps} values); SCRIPT-OUT: ${latin} Latin-script values; ACCENT: ${acc} restored pairs`);
  // FALLBACK: the code's own English, read from the source.
  const src = readFileSync(join(ROOT, "src/apps/IrrigationSuiteApp.lua"), "utf8").replace(/\r\n/g, "\n");
  const LIT = String.raw`"((?:[^"\\]|\\.)*)"`;
  const CALL = new RegExp(String.raw`(?:_T|FT\.l10n(?:Format)?)\(\s*"(ft_[a-z0-9_]+)",\s*((?:` + LIT + String.raw`\s*(?:\.\.\s*)?)+)`, "g");
  let fb = 0;
  for (const m of src.matchAll(CALL)) {
    const code = [...m[2].matchAll(new RegExp(LIT, "g"))].map((x) => x[1]).join("").replace(/\\n/g, "\n").replace(/\\"/g, '"');
    if (!KEYS.includes(m[1])) continue;
    fb++;
    const en = unesc((EN.inside.get(m[1]) || [""])[0]);
    if (en !== code) failures.push(`FALLBACK en: ${m[1]} reads ${JSON.stringify(en)}; the code's fallback is ${JSON.stringify(code)}`);
  }
  console.log(`  FALLBACK: ${fb} key calls' English equals their code fallback`);
}

// ---- Draw-site rows, over the real source.
{
  const { createRequire } = await import("node:module");
  const req = createRequire(join(ROOT, "tools", "test", "package.json"));
  const luaparse = req("luaparse");
  const fengari = req("fengari");
  const { lua, lauxlib, lualib, to_luastring } = fengari;
  const KEYSET = new Set(KEYS);
  const EMD = String.fromCharCode(0x2014);
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const cbuf = readFileSync(join(ROOT, "src", "core", "Constants.lua"));
  if (lauxlib.luaL_loadbuffer(L, cbuf, null, to_luastring("@Constants.lua")) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
    failures.push(`S0: Constants.lua did not load: ${lua.lua_tojsstring(L, -1)}`);
  }
  const AUTO = new Map();
  lua.lua_getglobal(L, to_luastring("FT"));
  lua.lua_getfield(L, -1, to_luastring("AUTO_L10N"));
  lua.lua_pushnil(L);
  while (lua.lua_next(L, -2) !== 0) { AUTO.set(lua.lua_tojsstring(L, -2), lua.lua_tojsstring(L, -1)); lua.lua_pop(L, 1); }
  const dec = (s) => Buffer.from(s, "latin1").toString("utf8");
  const fold = (n) => {
    if (!n) return null;
    if (n.type === "StringLiteral") return dec(n.value);
    if (n.type === "BinaryExpression" && n.operator === "..") { const a = fold(n.left), b = fold(n.right); return a !== null && b !== null ? a + b : null; }
    return null;
  };
  const callName = (n) => (n.base.type === "Identifier" ? n.base.name : n.base.type === "MemberExpression" ? n.base.identifier.name : null);
  let keySites = 0, litSites = 0;
  const PARSED = new Map(), X1KEYS = [], X1LITS = [];
  const seen = new Set();
  for (const src of SOURCES) {
    const text = readFileSync(join(ROOT, src.file), "latin1");
    const ast = luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true, ranges: true });
    PARSED.set(src.file, { text, ast });
    const keyFn = new Set(src.keyFns);
    const hasWord = (s) => /[A-Za-z]{2,}/.test(s);
    const dyn = (a, line) => {
      if (!a) return;
      if (a.type === "CallExpression" && a.base.type === "MemberExpression" && a.base.base && a.base.base.name === "string" && a.base.identifier.name === "format") {
        const f = fold(a.arguments[0]);
        if (f !== null && hasWord(f)) failures.push(`S3 ${src.file}:${line}: string.format(${JSON.stringify(f)}, ...) is drawn: the formatted text never matches a map key, so it reads English in every language`);
        return;
      }
      if (a.type === "BinaryExpression" && a.operator === ".." && fold(a) === null) {
        const lits = [];
        (function c(x) { if (!x) return; if (x.type === "StringLiteral") lits.push(dec(x.value)); else if (x.type === "BinaryExpression" && x.operator === "..") { c(x.left); c(x.right); } })(a);
        for (const s of lits) if (hasWord(s)) failures.push(`S3 ${src.file}:${line}: a drawn concatenation holds the English literal ${JSON.stringify(s)}, which no map can hold`);
        return;
      }
      if (a.type === "LogicalExpression") { dyn(a.left, line); dyn(a.right, line); }
    };
    const lit = (line, v, helpLine) => {
      if (v === "" || /^ft_[a-z0-9_]+$/.test(v) || /^[\s\d%.:,+\-/()'x*#]*$/.test(v)) return;
      const id = `${src.file}|${v}`;
      if (seen.has(id)) return;
      seen.add(id);
      litSites++;
      if (v.includes(EMD)) failures.push(`S2 ${src.file}:${line}: the drawn literal ${JSON.stringify(v)} holds an em dash`);
      if (NO_KEY[v]) return;
      const key = AUTO.get(v) || (helpLine ? AUTO.get(v + "\n") : undefined);
      if (key) X1LITS.push({ v, key, file: src.file, line });
      if (!key) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} has no FT.AUTO_L10N entry: the lookup misses and every language reads English`);
      else if (!KEYSET.has(key) && !OTHER_PR[key]) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} maps to ${key}, which this bar does not check`);
      else if (!EN.inside.has(key)) failures.push(`S2 ${src.file}:${line}: ${JSON.stringify(v)} maps to ${key}, which translation_en.xml does not carry`);
    };
    (function walk(n) {
      if (!n || typeof n !== "object") return;
      if (Array.isArray(n)) { n.forEach(walk); return; }
      // Another batch's drawer or helper in the same file: not this bar's.
      if (src.skipDrawers && n.type === "CallExpression" && callName(n) === "registerDrawer" && n.arguments[0]
          && n.arguments[0].type === "MemberExpression" && src.skipDrawers.includes(n.arguments[0].identifier.name)) return;
      if (src.skipFunctions && n.type === "FunctionDeclaration" && n.identifier
          && src.skipFunctions.includes(n.identifier.type === "Identifier" ? n.identifier.name : n.identifier.identifier.name)) return;
      if (src.skipLocals && n.type === "LocalStatement" && n.variables.some((v) => src.skipLocals.includes(v.name))) return;
      if (src.skipLocals && n.type === "LocalStatement" && n.variables.some((v) => src.skipLocals.includes(v.name))) return;
      if (n.type === "CallExpression") {
        const name = callName(n);
        if (keyFn.has(name)) {
          const k = fold(n.arguments[0]);
          if (k !== null && (!src.keyPrefix || k.startsWith(src.keyPrefix))) {
            keySites++;
            X1KEYS.push({ file: src.file, fn: name, key: k, nargs: n.arguments.length, line: n.loc.start.line, method: n.base.type === "MemberExpression" && n.base.indexer === ":" });
            if (!KEYSET.has(k) && !OTHER_PR[k]) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and this bar does not check it: it can read English in every language`);
            if (!EN.inside.has(k)) failures.push(`S1 ${src.file}:${n.loc.start.line}: ${k} is drawn, and translation_en.xml does not carry it`);
          }
        } else if (src.literals && DRAWFN.has(name)) {
          // A literal argument, or every literal inside an `a and "X" or "Y"` choice.
          const pick = (a) => {
            if (!a) return;
            const v = fold(a);
            if (v !== null) { lit(n.loc.start.line, v, false); return; }
            if (a.type === "LogicalExpression") { pick(a.left); pick(a.right); }
          };
          for (const a of n.arguments) pick(a);
          for (const a of n.arguments) dyn(a, n.loc.start.line);
        }
        // drawnArgs: a local draw function whose argument at the given index is drawn through
        // FT.l10nAuto, called directly or through pcall.
        if (src.drawnArgs) {
          let fn = name, args = n.arguments;
          if (name === "pcall" && args[0] && args[0].type === "Identifier") { fn = args[0].name; args = args.slice(1); }
          if (Object.prototype.hasOwnProperty.call(src.drawnArgs, fn)) {
            // A literal argument, or every literal inside an `a and "X" or "Y"` choice.
            const pickArg = (a) => {
              if (!a) return;
              const v = fold(a);
              if (v !== null) { lit(n.loc.start.line, v, false); return; }
              if (a.type === "LogicalExpression") { pickArg(a.left); pickArg(a.right); }
            };
            pickArg(args[src.drawnArgs[fn]]);
          }
        }
        if (src.literals && name === "truncate") dyn(n.arguments[0], n.loc.start.line);
        if (src.literals && name === "drawHelpPage") { const v = fold(n.arguments[2]); if (v !== null) lit(n.loc.start.line, v, false); }
      }
      // A local table of { key = "...", fallback = "..." } entries drawn through a helper (keyTables):
      // each entry's key is a key site of that helper, as if the file called helper(key, fallback).
      if (src.keyTables && n.type === "LocalStatement" && n.variables.length === 1
          && Object.prototype.hasOwnProperty.call(src.keyTables, n.variables[0].name)
          && n.init && n.init[0] && n.init[0].type === "TableConstructorExpression") {
        const helper = src.keyTables[n.variables[0].name];
        for (const f of n.init[0].fields) {
          if (!f.value || f.value.type !== "TableConstructorExpression") continue;
          const kf = f.value.fields.find((g) => g.type === "TableKeyString" && g.key.name === "key");
          const k = kf ? fold(kf.value) : null;
          if (k === null) continue;
          keySites++;
          X1KEYS.push({ file: src.file, fn: helper, key: k, nargs: 2, line: f.loc.start.line, method: false });
          if (!KEYSET.has(k) && !OTHER_PR[k]) failures.push(`S1 ${src.file}:${f.loc.start.line}: ${k} is drawn, and this bar does not check it: it can read English in every language`);
          if (!EN.inside.has(k)) failures.push(`S1 ${src.file}:${f.loc.start.line}: ${k} is drawn, and translation_en.xml does not carry it`);
        }
      }
      // A local table whose values the app draws through FT.l10nAuto (drawnTables): every string value
      // is a drawn literal, as if handed to the renderer.
      if (src.drawnTables && n.type === "LocalStatement" && n.variables.length === 1 && src.drawnTables.includes(n.variables[0].name)
          && n.init && n.init[0] && n.init[0].type === "TableConstructorExpression") {
        for (const f of n.init[0].fields) { const v = fold(f.value); if (v !== null) lit(f.loc.start.line, v, false); }
      }
      if (src.literals && n.type === "TableKeyString" && FIELDS.has(n.key.name)) { const v = fold(n.value); if (v !== null) lit(n.loc.start.line, v, false); }
      if (src.literals && n.type === "TableKeyString" && n.key.name === "body") { const v = fold(n.value); if (v !== null) for (const line of v.split("\n")) lit(n.loc.start.line, line, true); }
      for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") walk(n[k]);
    })(ast.body);
  }

  // ---- S1 (keyTables): the file calls the helper with an entry's .key, so the table is really drawn.
  for (const src of SOURCES) {
    if (!src.keyTables) continue;
    const ast = luaparse.parse(readFileSync(join(ROOT, src.file), "latin1"), { luaVersion: "5.1", encodingMode: "pseudo-latin1" });
    for (const [tbl, helper] of Object.entries(src.keyTables)) {
      let drawn = false;
      (function w(n) {
        if (!n || typeof n !== "object" || drawn) return;
        if (Array.isArray(n)) { n.forEach(w); return; }
        if (n.type === "CallExpression" && n.base.type === "Identifier" && n.base.name === helper && n.arguments[0]
            && n.arguments[0].type === "MemberExpression" && n.arguments[0].identifier.name === "key") drawn = true;
        for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
      })(ast.body);
      if (!drawn) failures.push(`S1 ${src.file}: ${tbl}'s keys are checked as ${helper} sites, and no ${helper}(<entry>.key, ...) call draws them`);
    }
  }

  // ---- S5: a drawnArgs function draws that parameter through FT.l10nAuto (a label drawn raw would read
  // English in every language while S2 still finds its map entry).
  for (const src of SOURCES) {
    if (!src.drawnArgs) continue;
    const { ast } = PARSED.get(src.file);
    for (const [fn, idx] of Object.entries(src.drawnArgs)) {
      let decl = null;
      (function w(n) {
        if (!n || typeof n !== "object" || decl) return;
        if (Array.isArray(n)) { n.forEach(w); return; }
        if (n.type === "FunctionDeclaration" && n.identifier && n.identifier.name === fn) { decl = n; return; }
        for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
      })(ast.body);
      const param = decl && decl.parameters[idx] ? decl.parameters[idx].name : null;
      let flows = false;
      if (param) (function w(n) {
        if (!n || typeof n !== "object" || flows) return;
        if (Array.isArray(n)) { n.forEach(w); return; }
        if (n.type === "CallExpression" && callName(n) === "l10nAuto" && n.arguments[0] && n.arguments[0].type === "Identifier" && n.arguments[0].name === param) { flows = true; return; }
        for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]);
      })(decl.body);
      if (!flows) failures.push(`S5 ${src.file}: ${fn}'s parameter ${idx + 1} (${param || "not found"}) is not drawn through FT.l10nAuto: its label reads English in every language`);
    }
  }

  // ---- S4: every checked key is drawn.
  {
    const reached = new Set([...X1KEYS.map((s) => s.key), ...X1LITS.map((s) => s.key)]);
    for (const k of KEYS) if (!reached.has(k) && !UNDRAWN[k]) failures.push(`S4 ${k} is checked here, and no SOURCES file draws it (a key call, or a drawn literal the map sends to it)`);
  }
  // ---- X1: the lookup, executed against the real locale files.
  let x1Calls = 0;
  {
    const { readdirSync: rd, statSync: st } = await import("node:fs");
    const tree = (dir) => rd(join(ROOT, dir)).flatMap((f) => { const rel = dir + "/" + f; return st(join(ROOT, rel)).isDirectory() ? tree(rel) : rel.endsWith(".lua") ? [rel] : []; });
    const parsedOf = (rel) => {
      if (!PARSED.has(rel)) { const text = readFileSync(join(ROOT, rel), "latin1"); PARSED.set(rel, { text, ast: luaparse.parse(text, { luaVersion: "5.1", encodingMode: "pseudo-latin1", locations: true, ranges: true }) }); }
      return PARSED.get(rel);
    };
    const topDefs = (rel) => {
      const { ast } = parsedOf(rel); const locals = new Map(), globals = new Map();
      for (const s of ast.body) {
        if (s.type === "FunctionDeclaration" && s.identifier && s.identifier.type === "Identifier") (s.isLocal ? locals : globals).set(s.identifier.name, s);
        if (s.type === "LocalStatement") for (const v of s.variables) locals.set(v.name, s);
        if (s.type === "AssignmentStatement") for (const v of s.variables) if (v.type === "Identifier" && !locals.has(v.name)) globals.set(v.name, s);
      }
      return { locals, globals };
    };
    const GLOBAL_DEFS = new Map();
    for (const rel of tree("src")) { try { for (const [g, s] of topDefs(rel).globals) if (!GLOBAL_DEFS.has(g)) GLOBAL_DEFS.set(g, { rel, s }); } catch (e) { failures.push(`X1 ${rel}: luaparse cannot read it (${e.message})`); } }
    // The statements a definition needs: top-level locals of its own file it names, and globals other
    // src files set (with theirs), each file's pieces in source order.
    const need = new Map();
    const addStmt = (rel, s) => {
      if (!need.has(rel)) need.set(rel, new Set());
      if (need.get(rel).has(s)) return;
      need.get(rel).add(s);
      const { locals } = topDefs(rel);
      const names = new Set();
      (function w(n) { if (!n || typeof n !== "object") return; if (Array.isArray(n)) { n.forEach(w); return; } if (n.type === "Identifier") names.add(n.name); for (const k of Object.keys(n)) if (k !== "loc" && k !== "range") w(n[k]); })(s.type === "FunctionDeclaration" ? s.body : s);
      for (const nm of names) {
        if (locals.has(nm) && locals.get(nm) !== s) addStmt(rel, locals.get(nm));
        else if (!locals.has(nm) && GLOBAL_DEFS.has(nm) && nm !== "FT") { const g = GLOBAL_DEFS.get(nm); addStmt(g.rel, g.s); }
      }
    };
    const helperOf = new Map();
    for (const site of X1KEYS) {
      const id = `${site.file}|${site.fn}`;
      if (helperOf.has(id) || X1_SKIP[site.fn]) continue;
      const { locals } = topDefs(site.file);
      const d = locals.get(site.fn);
      if (!site.method && d && d.type === "FunctionDeclaration") { addStmt(site.file, d); helperOf.set(id, `X1_H[${JSON.stringify(id)}] = ${site.fn}`); continue; }
      lua.lua_getglobal(L, to_luastring("FT"));
      lua.lua_getfield(L, -1, to_luastring(site.fn));
      const isFT = lua.lua_type(L, -1) === lua.LUA_TFUNCTION;
      lua.lua_pop(L, 2);
      if (isFT) { helperOf.set(id, `X1_H[${JSON.stringify(id)}] = FT.${site.fn}`); continue; }
      helperOf.set(id, null);
      failures.push(`X1 ${site.file}:${site.line}: the bar cannot run ${site.fn} (not a top-level local function of the file, not an FT function); name it in X1_SKIP with a reason, or teach the bar`);
    }
    const run = (buf, name) => {
      if (lauxlib.luaL_loadbuffer(L, buf, null, to_luastring(name)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
      return null;
    };
    let err = run(to_luastring(`
      X1_H = {}
      g_i18n = { texts = {} }
      function g_i18n:hasText(k) return self.texts[k] ~= nil end
      function g_i18n:getText(k) return self.texts[k] end
      local SENT = "\\1fallback"
      function X1_text(id, key, want) return X1_H[id](key, SENT) == want end
      function X1_fmt(id, key, want, a, b, c)
        local ok, w = pcall(string.format, want, a, b, c)
        if not ok then w = want end
        return X1_H[id](key, SENT .. " %s %s %s", a, b, c) == w
      end
      function X1_auto(text, want) return FT.l10nAuto(text) == want end
    `), "@X1");
    for (const [rel, set] of need) {
      if (err) break;
      const { text } = parsedOf(rel);
      const pieces = [...set].sort((a, b) => a.range[0] - b.range[0]).map((s) => text.slice(s.range[0], s.range[1]));
      const tail = [...helperOf.entries()].filter(([id, v]) => v && id.startsWith(rel + "|")).map(([, v]) => v);
      err = run(Buffer.from(pieces.join("\n") + "\n" + tail.join("\n") + "\n", "latin1"), "@" + rel + " (X1 cut)");
    }
    for (const [id, v] of helperOf) if (!err && v && v.includes("= FT.")) err = run(to_luastring(v), "@X1");
    if (err) failures.push(`X1: the helpers did not run in fengari: ${err}`);
    else {
      const argsFor = (fmt) => (fmt.replace(/%%/g, "").match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).map((q) => (q.endsWith("s") ? "x" : q.endsWith("d") || q.endsWith("i") ? 7 : 1.5));
      const call = (fn, args) => {
        lua.lua_getglobal(L, to_luastring(fn));
        for (const a of args) { if (typeof a === "number") lua.lua_pushnumber(L, a); else lua.lua_pushstring(L, to_luastring(a)); }
        if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) { const e = lua.lua_tojsstring(L, -1); lua.lua_pop(L, 1); return e; }
        const ok = lua.lua_toboolean(L, -1); lua.lua_pop(L, 1); return ok;
      };
      for (const loc of ["en", ...locales]) {
        const map = ALL[loc].inside;
        lua.lua_getglobal(L, to_luastring("g_i18n"));
        lua.lua_createtable(L, 0, map.size);
        for (const [k, v] of map) { lua.lua_pushstring(L, to_luastring(unesc(v[0]))); lua.lua_setfield(L, -2, to_luastring(k)); }
        lua.lua_setfield(L, -2, to_luastring("texts"));
        lua.lua_pop(L, 1);
        const bad = [];
        const seenSite = new Set();
        for (const s of X1KEYS) {
          const id = `${s.file}|${s.fn}`;
          if (!helperOf.get(id) || !map.has(s.key) || seenSite.has(id + "|" + s.key + "|" + (s.nargs > 2))) continue;
          seenSite.add(id + "|" + s.key + "|" + (s.nargs > 2));
          const want = unesc(map.get(s.key)[0]);
          x1Calls++;
          let r;
          if (s.nargs > 2) { const a = argsFor(want).slice(0, 3); while (a.length < 3) a.push("x"); r = call("X1_fmt", [id, s.key, want, ...a]); }
          else r = call("X1_text", [id, s.key, want]);
          if (r !== true) bad.push(`${s.key} (${s.fn})`);
        }
        const seenLit = new Set();
        for (const s of X1LITS) {
          if (!map.has(s.key) || seenLit.has(s.v)) continue;
          seenLit.add(s.v);
          x1Calls++;
          const want = unesc(map.get(s.key)[0]).replace(/\n$/, "");
          const r = call("X1_auto", [s.v, want]);
          if (r !== true) bad.push(`${JSON.stringify(s.v).slice(0, 30)} (l10nAuto)`);
        }
        if (bad.length) failures.push(`X1 ${loc}: ${bad.length} lookups return something other than the file's text (the fallback, for a helper that never reaches the file): ${bad.slice(0, 4).join(", ")}${bad.length > 4 ? ", ..." : ""}`);
      }
    }
  }
  console.log(`  draw sites checked: ${keySites} key calls, ${litSites} drawn literals in ${SOURCES.map((s) => s.file).join(", ")}; X1: ${x1Calls} lookups executed against the files`);
}

const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures.slice(0, 60)) console.log("  FAIL " + f);
  if (failures.length > 60) console.log(`  ... and ${failures.length - 60} more`);
  console.log(`l10n-irrigation-suite: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-irrigation-suite: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names; script rule: ${scriptChecked} values in ${locales.filter((l) => SCRIPT[l]).join(", ")}`);
