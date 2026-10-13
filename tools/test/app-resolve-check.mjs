// app-resolve-check.mjs - AppRegistry.resolve must redirect the ids it claims to, and nothing else.
//
// WHY THIS BAR EXISTS. `AppRegistry.resolve` redirects retired app ids so a saved startupApp, a
// favourite, or a tile still on the rail in a running session keeps opening something. Each redirect
// is written as `if id == FT.APP.<NAME>`, which reads as a named constant and silently becomes
// `if id == nil` the moment that constant is removed from FT.APP. When that happens the redirect
// stops working AND every nil id starts resolving to the redirect target, which is worse than the
// bug it was meant to fix: switchApp(nil) would open an app.
//
// That is exactly what happened with CROP_STRESS: 2c1d30a removed the id under Tyson's 2026-09-08
// ruling, and the redirect added later compared against nil.
//
// WHAT IT ASSERTS, through the real FT.APP and the real AppRegistry:
//   1. every id FT.APP declares is a non-empty string, so no comparison in resolve is against nil;
//   2. each declared legacy redirect maps its id to its target;
//   3. resolve(nil) is nil. A nil id must never resolve to an app.
//
// Usage:  node tools/test/app-resolve-check.mjs [--ref <git ref>]
// Exit:   0 = every redirect resolves and nil resolves to nothing, 1 = otherwise.
import { execFileSync } from "node:child_process";
import { makeTablet, workingTree, ROOT } from "./tablet-harness.mjs";

const argv = process.argv.slice(2);
const ri = argv.indexOf("--ref");
const REF = ri >= 0 ? argv[ri + 1] : null;
const readFile = REF
  ? (rel) => execFileSync("git", ["-c", "core.autocrlf=false", "show", `${REF}:${rel}`],
                          { cwd: ROOT, encoding: "utf8", maxBuffer: 64 << 20 })
  : workingTree;

// The redirects this bar pins, as id -> target. Each is a retired app whose id must still open its
// replacement. Add a row when a redirect is added; the bar then fails until the id exists.
const REDIRECTS = [
  ["DIGGING", "EXCAVATOR"],
  ["BUCKET", "EXCAVATOR"],
  ["TIME_CONTROLS", "FARM_ADMIN"],
  ["CROP_STRESS", "IRRIGATION_SUITE"],
];

const t = makeTablet(readFile);

const lua = `
local out = {}
local function add(s) out[#out + 1] = s end

-- 1. no id in FT.APP is nil or empty.
local bad = {}
for k, v in pairs(FT.APP or {}) do
  if type(v) ~= "string" or v == "" then bad[#bad + 1] = tostring(k) end
end
table.sort(bad)
add("NILIDS " .. table.concat(bad, ","))

-- 2. each declared redirect, by NAME, so a missing constant is reported as missing rather than
--    quietly comparing against nil.
${REDIRECTS.map(([from, to]) => `
do
  local fromId, toId = FT.APP.${from}, FT.APP.${to}
  if fromId == nil then
    add("MISSING ${from}")
  elseif toId == nil then
    add("MISSINGTARGET ${to}")
  else
    local got = AppRegistry.resolve(fromId)
    add(string.format("REDIRECT ${from} %s %s", tostring(got), tostring(toId)))
  end
end`).join("")}

-- 3. a nil id must resolve to nothing at all.
local okNil, gotNil = pcall(AppRegistry.resolve, nil)
add("NIL " .. tostring(okNil) .. " " .. tostring(gotNil))

error(table.concat(out, "|"), 0)
`;

const msg = t.run(lua, "@app-resolve");
if (msg === null) { console.error("app-resolve: the chunk returned without signalling."); process.exit(1); }

const parts = String(msg).trim().split("|");
const failures = [];
let redirects = 0;

for (const p of parts) {
  const w = p.split(" ");
  if (w[0] === "NILIDS") {
    if (w[1]) failures.push(`FT.APP has nil or empty ids: ${w[1]}. A resolve comparing against one of these compares against nil.`);
  } else if (w[0] === "MISSING") {
    failures.push(`FT.APP.${w[1]} does not exist, so a redirect written as "id == FT.APP.${w[1]}" compares against nil: that id is never redirected, and every nil id resolves to the target instead.`);
  } else if (w[0] === "MISSINGTARGET") {
    failures.push(`FT.APP.${w[1]} does not exist, so a redirect has no target.`);
  } else if (w[0] === "REDIRECT") {
    redirects++;
    if (w[2] !== w[3]) failures.push(`FT.APP.${w[1]} resolves to ${JSON.stringify(w[2])}, expected ${JSON.stringify(w[3])}.`);
  } else if (w[0] === "NIL") {
    if (w[1] !== "true") failures.push("AppRegistry.resolve(nil) raised.");
    else if (w[2] !== "nil") failures.push(`AppRegistry.resolve(nil) returned ${JSON.stringify(w[2])}. A nil id must never open an app.`);
  }
}

for (const f of failures) console.error("  ✗ " + f);
if (failures.length > 0) {
  console.error(`\napp-resolve: ${failures.length} failure(s) over ${REDIRECTS.length} declared redirect(s).`);
  process.exit(1);
}
console.log(`app-resolve: PASS - ${redirects} redirects resolve to their targets, every FT.APP id is a ` +
            `real string, and resolve(nil) is nil.`);
