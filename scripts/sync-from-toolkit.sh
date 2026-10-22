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
# HOW TO RUN
# Open Git Bash (or the VS Code terminal set to Git Bash) in the repo folder, then:
#
#   bash scripts/sync-from-toolkit.sh --dry-run
#       Preview: lists what would change, changes nothing.
#
#   bash scripts/sync-from-toolkit.sh
#       Pull the Toolkit project into src/.
#
#   bash scripts/sync-from-toolkit.sh --version 1.0.1
#       Same, plus copy the built pak to releases/v1.0.1/ and create
#       releases/v1.0.1/v1.0.1.md (notes template) if it doesn't exist.
#
#   BG3_DATA="/d/SteamLibrary/steamapps/common/Baldurs Gate 3/Data" bash scripts/sync-from-toolkit.sh
#       Game installed somewhere else.
#
#   bash scripts/sync-from-toolkit.sh --help
#       Show this text.
#
# Paths (override when the game isn't in the default Steam location):
#   BG3_DATA  the game's Data folder (where the Toolkit keeps projects)
#   BG3_PAKS  where the Toolkit puts the built .pak
#
# Run from another folder by giving the full path to the script; it always finds
# the repo from its own location. See scripts/README.md for when to use which script.

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
        -h|--help) sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
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

    # The release workflow requires notes; start a template if there are none.
    notes="$release_dir/v$VERSION.md"
    if [[ ! -f "$notes" ]]; then
        echo "  notes releases/v$VERSION/v$VERSION.md (template - fill it in before pushing)"
        if (( ! DRY_RUN )); then
            printf '%s\n' "# Val's DnD AIO Beyond Patch v$VERSION" '' '## Changes' '- ' '' '## Known Issues' '- ' > "$notes"
        fi
    fi
fi

echo
echo "Done. Review with: git status"
