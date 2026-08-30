import zipfile
import os
import subprocess
import sys
import shutil
from pathlib import Path

# ============================================================
# build.py — Build & deploy FS25_FarmTablet
# Usage:
#   python build.py            — builds zip only
#   python build.py --deploy   — builds zip AND copies to mods folder
# ============================================================

MOD_NAME = "FS25_FarmTablet"
MOD_DIR = Path(__file__).parent.resolve()
ZIP_PATH = MOD_DIR / f"{MOD_NAME}.zip"

# Windows default mods path
MODS_DIR = Path.home() / "Documents" / "My Games" / "FarmingSimulator2025" / "mods"

EXCLUDE_DIRS = {".git", ".claude", ".github", "__MACOSX", "tools", ".vscode"}
EXCLUDE_EXTS = {".sh", ".py", ".md", ".DS_Store", ".zip"}
EXCLUDE_FILES = {".gitignore", "icon_source.png"}

def lua_files():
    """Yield every .lua file that will ship in the zip, using the same exclusions
    as build_zip(). The entry point main.lua lives at the repo root, not under
    src/, so this walks the whole mod tree rather than a single source dir."""
    for root, dirs, files in os.walk(MOD_DIR):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for fname in files:
            if fname in EXCLUDE_FILES:
                continue
            if any(fname.endswith(ext) for ext in EXCLUDE_EXTS):
                continue
            if fname.endswith(".lua"):
                yield Path(root) / fname

def check_lua_syntax():
    """Fail the build if any shipping .lua file will not parse under Lua 5.1.

    FS25 runs Lua 5.1. A parse error silently drops the whole file at load, so a
    bad file would ship as a missing feature with nothing but a compiler line
    nobody reads. This surfaces the error here, before the zip is built."""
    files = list(lua_files())
    if not files:
        return
    checker = MOD_DIR / "tools" / "test" / "syntax-check.mjs"
    if not checker.exists():
        print("  WARNING: tools/test/syntax-check.mjs not found; skipping Lua 5.1 gate")
        return
    node_modules = MOD_DIR / "tools" / "test" / "node_modules"
    if not node_modules.exists():
        print("  Installing tools/test dependencies (luaparse)...")
        subprocess.run(["npm", "install", "--silent"], cwd=checker.parent, check=True)
    print("  Checking Lua 5.1 syntax...")
    subprocess.run(["node", str(checker), *[str(p) for p in files]], check=True)

def build_zip():
    print(f"============================================")
    print(f"  Building {MOD_NAME}")
    print(f"============================================")

    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
        print("  Removed old zip")

    with zipfile.ZipFile(ZIP_PATH, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(MOD_DIR):
            # Filter directories
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            
            for fname in files:
                if fname in EXCLUDE_FILES:
                    continue
                if any(fname.endswith(ext) for ext in EXCLUDE_EXTS):
                    continue
                
                full_path = Path(root) / fname
                arc_name = full_path.relative_to(MOD_DIR).as_posix()
                zf.write(full_path, arc_name)
                print(f"  + {arc_name}")

    print(f"\n  ZIP created: {ZIP_PATH}")

def deploy():
    print(f"\n  Deploying to mods folder...")
    if not MODS_DIR.exists():
        print(f"  WARNING: Mods folder not found at: {MODS_DIR}")
        sys.exit(1)

    dest = MODS_DIR / f"{MOD_NAME}.zip"
    if dest.exists():
        dest.unlink()
    shutil.copy2(ZIP_PATH, dest)
    print(f"  Deployed: {dest}")

if __name__ == "__main__":
    check_lua_syntax()
    build_zip()
    if "--deploy" in sys.argv:
        deploy()
    print(f"\n  Done. Check log.txt for [FarmTablet] entries after launching.")
    print(f"============================================")
