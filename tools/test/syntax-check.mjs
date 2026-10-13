// Lua 5.1 syntax checker for FS25_FarmTablet, driven by build.py.
//
// FS25 runs Lua 5.1. A parse error (or a 5.2+-only construct like `goto`/`::label::`)
// makes the whole mod fail to load in-game with no useful message: the file is
// silently dropped, so one feature is simply absent. This parses every Lua file the
// build ships with luaparse pinned to luaVersion "5.1", so those errors surface here
// in <1s instead of after a deploy + game restart.
//
// Usage:  node syntax-check.mjs <abs-path>...
// Exit:   0 = all files parse, 1 = at least one parse error.
import { readFileSync } from "node:fs";
import luaparse from "luaparse";

const files = process.argv.slice(2);
let bad = 0;

for (const f of files) {
  let code;
  try {
    code = readFileSync(f, "utf8");
  } catch {
    continue; // deleted or moved between collection and now; nothing to parse
  }

  // A UTF-8 BOM is caught by the parse below, but only as
  // "Cannot read properties of undefined (reading 'range')", which tells you
  // nothing. Name it explicitly instead. Lua does not skip a byte order mark
  // the way it skips a shebang, so U+FEFF is read as part of the first token.
  if (code.charCodeAt(0) === 0xfeff) {
    bad++;
    console.error(`  \u2717 ${f}`);
    console.error("      Starts with a UTF-8 BOM (EF BB BF). Lua 5.1 cannot parse it.");
    console.error("      Fix: re-save as UTF-8 WITHOUT BOM, or strip the 3 leading bytes.");
    continue;
  }

  try {
    luaparse.parse(code, { luaVersion: "5.1", comments: false, locations: true });
  } catch (e) {
    bad++;
    console.error(`  \u2717 ${f}\n      ${e.message}`);
  }
}

if (bad > 0) {
  console.error(`\n  ${bad} Lua file(s) will NOT compile in FS25. Build blocked.`);
  console.error("  FS25 drops the whole file at load with no useful message, so this");
  console.error("  would ship as a silently missing feature. Fix before building.");
  process.exit(1);
}
console.log(`  \u2713 Lua 5.1 syntax OK - ${files.length} file(s)`);
