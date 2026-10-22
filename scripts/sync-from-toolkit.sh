#!/usr/bin/env bash
# Copies the mod's project files from the BG3 Toolkit data folder into src/,
# and optionally copies the built .pak into releases/vX.Y.Z/.
# Bash version of Sync-FromToolkit.ps1 (for Git Bash on Windows).
#
# Mirrors Mods, Public, Editor/Mods and Projects for this mod from the Toolkit's
# Data folder into the repo's src/ folder. Mirroring means files deleted in the
# Toolkit are deleted in src/ too, so src/ always matches what was built.
# Nothing is committed. Review the changes with `git status` afterwards.
#
# Usage:
#   scripts/sync-from-toolkit.sh [--dry-run] [--version X.Y.Z]
#
# Paths (override when the game isn't in the default Steam location):
#   BG3_DATA  the game's Data folder (where the Toolkit keeps projects)
#   BG3_PAKS  where the Toolkit puts the built .pak

set -euo pipefail

MOD_FOLDER='ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/src"

# Converts a Windows path (C:\...) to a Git Bash path (/c/...) when cygpath exists.
to_unix() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi
}

GAME_DATA="${BG3_DATA:-/c/Program Files (x86)/Steam/steamapps/common/Baldurs Gate 3/Data}"
GAME_DATA="$(to_unix "$GAME_DATA")"
if [[ -n "${BG3_PAKS:-}" ]]; then
    PAK_FOLDER="$(to_unix "$BG3_PAKS")"
else
    PAK_FOLDER="$(to_unix "${LOCALAPPDATA:-}")/Larian Studios/Baldur's Gate 3/Mods"
fi

DRY_RUN=0
VERSION=''
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -v|--version) VERSION="${2:?--version needs a value, e.g. 1.0.1}"; shift 2 ;;
        -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1 (try --help)" >&2; exit 1 ;;
    esac
done

# Guard: a mirror from a missing or wrong folder would wipe src/.
if [[ ! -f "$GAME_DATA/Mods/$MOD_FOLDER/meta.lsx" ]]; then
    echo "Toolkit project not found: $GAME_DATA/Mods/$MOD_FOLDER/meta.lsx" >&2
    echo "Set BG3_DATA to your game's Data folder." >&2
    exit 1
fi

if (( DRY_RUN )); then
    echo "Toolkit -> repo (DRY RUN - nothing will change)"
else
    echo "Toolkit -> repo (syncing)"
fi

for folder in 'Mods' 'Public' 'Editor/Mods' 'Projects'; do
    from="$GAME_DATA/$folder/$MOD_FOLDER"
    to="$SRC/$folder/$MOD_FOLDER"

    if [[ ! -d "$from" ]]; then
        echo "  skip  $folder (not in Toolkit)"
        continue
    fi

    echo "  sync  $folder"
    if [[ -d "$to" ]]; then
        # diff exits 1 when folders differ; that's expected here.
        diff -rq "$from" "$to" | sed "s|$from|toolkit|g; s|$to|repo|g; s|^|        |" || true
    else
        echo "        new folder: $folder/$MOD_FOLDER"
    fi

    if (( ! DRY_RUN )); then
        rm -rf "$to"
        mkdir -p "$to"
        cp -r "$from/." "$to/"
    fi
done

if [[ -n "$VERSION" ]]; then
    VERSION="${VERSION#v}"
    pak="$PAK_FOLDER/$MOD_FOLDER.pak"
    if [[ ! -f "$pak" ]]; then
        echo "Built pak not found: $pak. Build it in the Toolkit first." >&2
        exit 1
    fi
    release_dir="$REPO_ROOT/releases/v$VERSION"
    echo "  pak   $MOD_FOLDER.pak (built $(date -r "$pak" '+%Y-%m-%d %H:%M')) -> releases/v$VERSION/"
    if (( ! DRY_RUN )); then
        mkdir -p "$release_dir"
        cp "$pak" "$release_dir/"
    fi
fi

echo
echo "Done. Review with: git status"
