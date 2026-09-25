// l10n-shell-check.mjs - MAINTENANCE row 105's text bar for the tablet shell (FarmTabletUI.lua): the battery, repair and network notices and screens, the help chrome, the welcome and error screens and the offline banner
// (a PR of the tablet translation wave; the pattern of l10n-fieldjobs-check.mjs).
//
// Every key below is drawn by FarmTabletUI.lua: through ftUiText / ftUiFormat for the notices
// (_notifyBattery, _notifyTabletRepair, _notifySignal), the network-provider, repair and battery
// screens, the status bar's network word, the help page's title and BACK button and the scroll
// hint; through the renderer's FT.l10nAuto for the welcome and error screens and for the offline
// banner, which draws the literal "KEIN NETZ" in every language (ft_auto_kein_netz).
// For each key, in all 26 files:
//   - the key sits inside <texts> exactly once, and nowhere outside it (FS25 reads only
//     l10n.texts.text, mods.lua:798: a key after </texts> is a key the game does not have);
//   - its format placeholders (%s, %d, %02d, %.1f) are English's, in English's order;
//   - its line breaks are as many as English's;
//   - its text is not the English text, unless the (locale, key) pair is allowed below with a
//     reason (an own name, a word the language shares with English; never a copy passed off
//     as a translation: Tyson's ruling, MAINTENANCE row 80).
//
// Usage:  node tools/test/l10n-shell-check.mjs        Exit: 0 clean, 1 any failure.
import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const DIR = join(ROOT, "translations");

const KEYS = [
  // battery
  "ft_battery_service_title", "ft_battery_empty_auto_charge", "ft_battery_charging_locked",
  "ft_battery_charged_usable", "ft_battery_charged_full", "ft_battery_charging", "ft_battery_empty",
  "ft_battery_charge_hint", "ft_battery_charge",
  // repair
  "ft_repair_open_blocked_msg", "ft_repair_remaining_day_format", "ft_repair_service_title",
  "ft_repair_started_msg", "ft_repair_done_msg", "ft_repair_force_done_msg", "ft_repair_title",
  "ft_repair_subtitle", "ft_repair_in_progress", "ft_repair_notify_done", "ft_repair_stock_available",
  "ft_repair_stock_ordered", "ft_repair_remaining", "ft_common_close",
  // network
  "ft_network_outage_short", "ft_network_no_signal_short", "ft_network_weak_short",
  "ft_network_default_provider", "ft_network_data_frozen", "ft_network_choose_provider",
  "ft_network_choose_hint", "ft_network_fee_format", "ft_network_activate", "ft_network_provider_active",
  "ft_network_fee_deducted", "ft_network_title", "ft_network_outage_recovered", "ft_network_outage_detected",
  "ft_network_outage_label", "ft_network_no_signal_label", "ft_network_weak_signal_label",
  "ft_network_no_reception_here", "ft_network_weak_reception",
  // help chrome, welcome and error screens, offline banner
  "ft_help_common_title", "ft_help_back", "ft_scroll_label", "ft_auto_welcome_tap_an_app_to_begin",
  "ft_auto_tap_home_to_return_to_the_app_grid", "ft_auto_app_error", "ft_auto_farm_tablet",
  "ft_auto_kein_netz",
];

// Keys whose text is the same in every language, with the reason.
const ALLOW_ALL = {
  "ft_network_default_provider": "a network provider's own name: Realistic Farming Mobile",
  "ft_auto_farm_tablet": "the mod's own name: Farm Tablet",
};
// (locale, key) pairs whose text legitimately equals English, each with its reason.
const ALLOW = {
};
const CONTAINS = [];

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
const placeholders = (s) => (s.match(/%[-+ #0]*\d*(?:\.\d+)?[sdif]/g) || []).join(",");
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
  for (const [outer, inner, ci] of CONTAINS) {
    const o = (L.inside.get(outer) || [])[0], i = (L.inside.get(inner) || [])[0];
    if (o && i && !(ci ? o.toLowerCase().includes(i.toLowerCase()) : o.includes(i))) failures.push(`${loc}: ${outer} does not name ${inner}'s text ${JSON.stringify(i)}`);
  }
}
const checked = KEYS.length * locales.length;
if (failures.length > 0) {
  for (const f of failures) console.log("  FAIL " + f);
  console.log(`l10n-shell: ${failures.length} failure(s) over ${checked} entries (${KEYS.length} keys x ${locales.length} locales)`);
  process.exit(1);
}
console.log(`l10n-shell: PASS - ${checked} entries checked (${KEYS.length} keys x ${locales.length} locales), ${Object.keys(ALLOW).length} allowed identical pairs, ${Object.keys(ALLOW_ALL).length} own names`);
