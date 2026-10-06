// version-label-check.mjs - the tablet shows the build's own version (MAINTENANCE row 236).
//
// WHY THIS BAR EXISTS. FT.VERSION was a hand-kept copy of modDesc.xml's <version> ("keep in sync"),
// and it drifted: testers on 2.6.0.11 read "FarmTablet v2.6.0.6" on the Settings page. Now
// Constants.lua takes the version the engine already read from modDesc.xml into its mod manager, and
// the hand-kept copy stays only as the fallback.
//
// THE ENTRY-POINT BAR. Each case loads the whole tablet the way the game loads it (tablet-harness.mjs:
// every file src/main.lua sources, in its order). Before the files run, the engine's own state at that
// moment is in place:
//   - the mod manager, holding the record the engine made from this repo's real modDesc.xml (mods.lua:430
//     reads modDesc.version, :961 addMod; ModManager.lua:16-27 stores it as `version`, keyed by the mod's
//     name, read back by getModByName, :89-91);
//   - g_currentModName, which loadMod sets before it sources the mod's scripts (mods.lua:992);
//   - src/main.lua's OWN latch lines (FarmTabletModDirectory, FarmTabletModName), run as written.
// Then the real Settings drawer and the real welcome header are drawn and read.
//
// Cases: A the record names this build (the header, the Version row and the welcome header show
// modDesc's version); B no record under this name; C no mod manager; D a record with an empty version;
// E a getModByName that throws; F a record with no version; G a live re-source (g_currentModName nil,
// the name already latched); H the mod installed under another name. B to F show the fallback, with no
// load error; G and H show modDesc's version.
//
// Usage:  node tools/test/version-label-check.mjs [--ref <git ref>]
// Exit:   0 = every case shows what it should, 1 = otherwise.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;
const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

// modDesc.xml's <version>, as mods.lua:430 reads it (modDesc.version).
const modDesc = readFile("modDesc.xml");
const vm = modDesc.match(/<modDesc\b[^>]*>[\s\S]*?<version>\s*([^<]*?)\s*<\/version>/);
if (!vm) { console.error("version-label: modDesc.xml has no <version>."); process.exit(1); }
const VERSION = vm[1];
// The fallback, as Constants.lua writes it.
const fm = readFile("src/core/Constants.lua").match(/^FT\.VERSION = "([^"]+)"/m);
if (!fm) { console.error("version-label: Constants.lua has no FT.VERSION literal."); process.exit(1); }
const FALLBACK = fm[1];
if (FALLBACK === VERSION) {
  console.error(`version-label: the fallback ${FALLBACK} equals modDesc's version, so no case could tell them apart.`);
  process.exit(1);
}

// src/main.lua's latch lines, exactly as written (from the FarmTabletModDirectory assignment to the
// FarmTabletModName one).
const main = readFile("src/main.lua");
const li = main.indexOf("FarmTabletModDirectory = ");
const le = main.indexOf("\n", main.indexOf("FarmTabletModName = ", li));
if (li < 0 || le < 0) { console.error("version-label: src/main.lua's latch lines were not found."); process.exit(1); }
const LATCH = main.slice(li, le);

const lua = (s) => JSON.stringify(s);
// The engine's ModManager (ModManager.lua:16-27, :89-91), the fields this reads.
const MOD_MANAGER = `
g_modManager = { nameToMod = {}, numMods = 0 }
function g_modManager:addMod(title, description, version, modDescVersion, author, iconFilename, modName)
  self.numMods = self.numMods + 1
  local mod = { id = self.numMods, title = title, description = description, version = version, modDescVersion = modDescVersion,
                author = author, iconFilename = iconFilename, modName = modName }
  self.nameToMod[modName] = mod
  return mod
end
function g_modManager:getModByName(modName) return self.nameToMod[modName] end
`;

function load(before) {
  const t = makeTablet(readFile, { before });
  const settings = t.draw("settings", false);
  const welcome = t.chrome("_drawWelcome");
  return { loadErrors: t.loadErrors, settings, welcome };
}
const shows = (r, v) => r.settings.texts.includes(`FarmTablet v${v}`) && r.settings.texts.includes(`v${v}`)
  && r.welcome.texts.includes(`v${v}`);

const CASES = [
  { id: "A", what: "the record names this build", want: VERSION,
    before: `${MOD_MANAGER} g_modManager:addMod("Farm Tablet", "", ${lua(VERSION)}, "106", "TisonK", "icon.dds", "FS25_FarmTablet")
             g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "B", what: "no record under this name", want: FALLBACK,
    before: `${MOD_MANAGER} g_modManager:addMod("Other", "", "9.9.9.9", "106", "x", "icon.dds", "FS25_Other")
             g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "C", what: "no mod manager", want: FALLBACK,
    before: `g_modManager = nil g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "D", what: "a record with an empty version", want: FALLBACK,
    before: `${MOD_MANAGER} g_modManager:addMod("Farm Tablet", "", "", "106", "TisonK", "icon.dds", "FS25_FarmTablet")
             g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "E", what: "a getModByName that throws", want: FALLBACK,
    before: `${MOD_MANAGER} function g_modManager:getModByName() error("lookup failed") end
             g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "F", what: "a record with no version", want: FALLBACK,
    before: `${MOD_MANAGER} g_modManager:addMod("Farm Tablet", "", nil, "106", "TisonK", "icon.dds", "FS25_FarmTablet")
             g_currentModName = "FS25_FarmTablet" g_currentModDirectory = "mods/FS25_FarmTablet/" ${LATCH}` },
  { id: "G", what: "a live re-source: g_currentModName nil, the name already latched", want: VERSION,
    before: `${MOD_MANAGER} g_modManager:addMod("Farm Tablet", "", ${lua(VERSION)}, "106", "TisonK", "icon.dds", "FS25_FarmTablet")
             FarmTabletModDirectory = "mods/FS25_FarmTablet/" FarmTabletModName = "FS25_FarmTablet"
             g_currentModName = nil g_currentModDirectory = nil ${LATCH}` },
  { id: "H", what: "the mod installed under another name", want: VERSION,
    before: `${MOD_MANAGER} g_modManager:addMod("Farm Tablet", "", ${lua(VERSION)}, "106", "TisonK", "icon.dds", "FS25_FarmTablet_beta")
             g_currentModName = "FS25_FarmTablet_beta" g_currentModDirectory = "mods/FS25_FarmTablet_beta/" ${LATCH}` },
];

const failures = [];
let pass = 0;
for (const c of CASES) {
  let r;
  try { r = load(c.before); } catch (e) { failures.push(`${c.id} (${c.what}): the tablet did not load: ${e.message}`); continue; }
  const problems = [];
  if (r.loadErrors.length > 0) problems.push(`load errors: ${r.loadErrors.join("; ")}`);
  if (r.settings.error) problems.push(`the Settings page stopped: ${r.settings.error}`);
  if (r.welcome.error) problems.push(`the welcome header stopped: ${r.welcome.error}`);
  if (!shows(r, c.want)) {
    const got = r.settings.texts.filter((s) => s.startsWith("FarmTablet v")).join(", ") || "no version header";
    problems.push(`expected "FarmTablet v${c.want}" in the header, "v${c.want}" in the Version row and the welcome header; got ${got}`);
  }
  if (problems.length > 0) failures.push(`${c.id} (${c.what}): ${problems.join(" | ")}`);
  else pass++;
}

const label = REF ? ` at ${REF}` : "";
if (failures.length > 0) {
  console.error(`version-label${label}: ${pass} of ${CASES.length} cases pass (modDesc ${VERSION}, fallback ${FALLBACK}).`);
  for (const f of failures) console.error("  FAIL " + f);
  process.exit(1);
}
console.log(`version-label${label}: ${pass} of ${CASES.length} cases pass (modDesc ${VERSION}, fallback ${FALLBACK}).`);
