#!/usr/bin/env bash
# Copies the mod's project files from the repo's src/ folder into the BG3
# Toolkit data folder, ready to build. The opposite of sync-from-toolkit.sh.
# Bash version of Sync-ToToolkit.ps1 (for Git Bash on Windows).
#
# Close the Toolkit first, so it doesn't overwrite the files.
#
# Safety:
#   - Copy only by default. Toolkit files that aren't in src/ are kept, unless
#     --prune is given.
#   - If a Toolkit file is newer than the repo's copy and different from it,
#     it's probably an unsynced Toolkit edit. The script stops and lists those
#     files, unless --force is given. Run sync-from-toolkit.sh first to keep them.
#
# HOW TO RUN
# Close the BG3 Toolkit. Open Git Bash (or the VS Code terminal set to Git Bash)
# in the repo folder, then:
#
#   bash scripts/sync-to-toolkit.sh --dry-run
#       Preview: lists what would change, changes nothing.
#
#   bash scripts/sync-to-toolkit.sh
#       Copy src/ into the Toolkit project. Then open the Toolkit and build.
#
#   bash scripts/sync-to-toolkit.sh --prune
#       Also delete Toolkit files you removed from the repo.
#
#   bash scripts/sync-to-toolkit.sh --force
#       Overwrite Toolkit files that are newer than the repo's copy.
#       Only after checking they're edits you don't need.
#
#   BG3_DATA="/d/SteamLibrary/steamapps/common/Baldurs Gate 3/Data" bash scripts/sync-to-toolkit.sh
#       Game installed somewhere else.
#
#   bash scripts/sync-to-toolkit.sh --help
#       Show this text.
#
# Paths (override when the game isn't in the default Steam location):
#   BG3_DATA  the game's Data folder (where the Toolkit keeps projects)
#
# Run from another folder by giving the full path to the script; it always finds
# the repo from its own location. See scripts/README.md for when to use which script.

set -euo pipefail

MOD_FOLDER='ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/src"
FOLDERS=('Mods' 'Public' 'Editor/Mods' 'Projects')

# Converts a Windows path (C:\...) to a Git Bash path (/c/...) when cygpath exists.
to_unix() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi
}

GAME_DATA="$(to_unix "${BG3_DATA:-/c/Program Files (x86)/Steam/steamapps/common/Baldurs Gate 3/Data}")"

DRY_RUN=0
PRUNE=0
FORCE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        --prune) PRUNE=1; shift ;;
        --force) FORCE=1; shift ;;
        -h|--help) sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1 (try --help)" >&2; exit 1 ;;
    esac
done

# Guards: a mirror from an empty src/ would wipe the Toolkit project, and a
# wrong game path would scatter files somewhere useless.
if [[ ! -f "$SRC/Mods/$MOD_FOLDER/meta.lsx" ]]; then
    echo "src/Mods/$MOD_FOLDER/meta.lsx not found. Is this the right repo?" >&2
    exit 1
fi
if [[ ! -d "$GAME_DATA/Mods" ]]; then
    echo "Game Data folder not found: $GAME_DATA. Set BG3_DATA to your game's Data folder." >&2
    exit 1
fi
if command -v tasklist >/dev/null 2>&1 && tasklist 2>/dev/null | grep -qi -e 'BG3Toolkit' -e 'LSToolFramework'; then
    echo "Warning: the BG3 Toolkit looks like it is running. Close it before syncing, or it may overwrite these files." >&2
fi

# Find Toolkit files that are newer than the repo's copy and differ from it.
conflicts=()
for folder in "${FOLDERS[@]}"; do
    from="$SRC/$folder/$MOD_FOLDER"
    to="$GAME_DATA/$folder/$MOD_FOLDER"
    [[ -d "$from" && -d "$to" ]] || continue
    while IFS= read -r -d '' file; do
        rel="${file#"$from"/}"
        target="$to/$rel"
        if [[ -f "$target" && "$target" -nt "$file" ]] && ! cmp -s "$target" "$file"; then
            conflicts+=("$folder/$MOD_FOLDER/$rel")
        fi
    done < <(find "$from" -type f -print0)
done
if (( ${#conflicts[@]} )) && (( ! FORCE )); then
    echo "These Toolkit files are newer than the repo and differ from it:" >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    echo "Stopped so they are not overwritten. Run sync-from-toolkit.sh to keep them, or pass --force to overwrite them." >&2
    exit 1
fi

if (( DRY_RUN )); then
    echo "repo -> Toolkit (DRY RUN - nothing will change)"
elif (( PRUNE )); then
    echo "repo -> Toolkit (syncing, deleting extra Toolkit files)"
else
    echo "repo -> Toolkit (syncing)"
fi

for folder in "${FOLDERS[@]}"; do
    from="$SRC/$folder/$MOD_FOLDER"
    to="$GAME_DATA/$folder/$MOD_FOLDER"

    if [[ ! -d "$from" ]]; then
        echo "  skip  $folder (not in repo)"
        continue
    fi

    echo "  sync  $folder"
    while IFS= read -r -d '' file; do
        rel="${file#"$from"/}"
        target="$to/$rel"
        if [[ ! -f "$target" ]]; then
            echo "        new      $rel"
        elif ! cmp -s "$file" "$target"; then
            echo "        changed  $rel"
        else
            continue
        fi
        if (( ! DRY_RUN )); then
            mkdir -p "$(dirname "$target")"
            cp "$file" "$target"
        fi
    done < <(find "$from" -type f -print0)

    if (( PRUNE )) && [[ -d "$to" ]]; then
        while IFS= read -r -d '' file; do
            rel="${file#"$to"/}"
            if [[ ! -f "$from/$rel" ]]; then
                echo "        delete   $rel"
                (( DRY_RUN )) || rm -f "$file"
            fi
        done < <(find "$to" -type f -print0)
    fi
done

echo
echo "Done. Open the Toolkit and build."
