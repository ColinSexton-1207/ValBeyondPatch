# Scripts

Helper scripts for working on the patch. The mod is built in the BG3 Toolkit, which keeps its own copy of the project inside the game's `Data` folder. These scripts move the project between that copy and this repo's `src/` folder.

Each script comes in a PowerShell version and a bash version (for Git Bash), and both do the same thing. Run them from the repo folder. Every script has a preview mode that changes nothing, so use it whenever you're unsure.

## Which script do I need?

| You want to… | Run |
|---|---|
| Bring Toolkit changes (and a fresh build) into the repo | **Sync-FromToolkit** |
| Push repo changes into the Toolkit, so you can build them | **Sync-ToToolkit** |
| Ship a new version | **Sync-FromToolkit** with a version, then push (see [Releasing](#releasing)) |

## Sync-FromToolkit (Toolkit → repo)

Mirrors the Toolkit project into `src/`: files deleted in the Toolkit are deleted in `src/` too. With a version, it also copies the built `.pak` into `releases/vX.Y.Z/` and creates a release notes template there.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Sync-FromToolkit.ps1 -WhatIf          # preview
powershell -ExecutionPolicy Bypass -File scripts\Sync-FromToolkit.ps1                  # sync src\
powershell -ExecutionPolicy Bypass -File scripts\Sync-FromToolkit.ps1 -Version 1.0.1   # sync + pak + notes template
```
```bash
bash scripts/sync-from-toolkit.sh --dry-run
bash scripts/sync-from-toolkit.sh
bash scripts/sync-from-toolkit.sh --version 1.0.1
```

It stops before copying anything if it can't find the Toolkit project, because a mirror from a missing folder would empty `src/`.

## Sync-ToToolkit (repo → Toolkit)

Copies `src/` into the Toolkit project. **Close the Toolkit first**, or it may overwrite the files.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1 -WhatIf   # preview
powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1           # copy
```
```bash
bash scripts/sync-to-toolkit.sh --dry-run
bash scripts/sync-to-toolkit.sh
```

Safety rules:
- **Copy only.** Files that exist only in the Toolkit are kept. Add `-Prune` / `--prune` to delete Toolkit files you removed from the repo. It deletes files only and leaves folders alone, so the Toolkit's empty `Content` and `RootTemplates` folders survive.
- **Newer Toolkit edits block the copy.** If a Toolkit file is newer than the repo's copy and different from it, you probably edited it in the Toolkit and haven't synced it back. The script stops and lists those files. Run Sync-FromToolkit to keep them, or add `-Force` / `--force` to overwrite them.

## Game in a different location

Both scripts assume the default Steam install. If yours is elsewhere, set an environment variable once:

| Variable | What it points to | Default |
|---|---|---|
| `BG3_DATA` | The game's `Data` folder, where the Toolkit keeps projects | `C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Data` |
| `BG3_PAKS` | Where the Toolkit puts the built `.pak` (Sync-FromToolkit only) | `%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods` |

To set one permanently in PowerShell: `[Environment]::SetEnvironmentVariable('BG3_DATA', 'D:\SteamLibrary\steamapps\common\Baldurs Gate 3\Data', 'User')`, then open a new terminal. The PowerShell scripts also accept `-GameData` and `-PakFolder` for a one-off.

## Releasing

1. Build the pak in the Toolkit.
2. Run `Sync-FromToolkit` with the new version (for example `-Version 1.0.1`). This syncs `src/`, copies the pak to `releases/v1.0.1/`, and creates `releases/v1.0.1/v1.0.1.md`.
3. Fill in the release notes.
4. Commit and push to `main`.

GitHub takes it from there:
- **`.github/workflows/release.yml`** sees the newly added pak. It creates the `v1.0.1` tag and GitHub release, using the notes file as the description and attaching the pak.
- **`.github/workflows/nexus-release.yml`** then uploads the pak to Nexus Mods as a new version of the main file, and archives the old one.

The release workflow stops with an error if:
- one push adds more than one pak
- the folder isn't named like a version (`v1.0.1`, `v1.0.0.3`)
- the tag already exists
- the notes file is missing

Check the repo's **Actions** tab after pushing. Creating a release by hand on GitHub (tag `vX.Y.Z`, with `releases/vX.Y.Z/` committed) also uploads to Nexus.

## Adding a script

Put it in this folder, start it with a comment block covering what it does and how to run it (see the existing scripts), and add a section here.
