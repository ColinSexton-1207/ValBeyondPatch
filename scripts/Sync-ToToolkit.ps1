<#
.SYNOPSIS
    Copies the mod's project files from the repo's src\ folder into the BG3
    Toolkit data folder, ready to build. The opposite of Sync-FromToolkit.ps1.

.DESCRIPTION
    Copies Mods, Public, Editor\Mods and Projects for this mod from src\ into the
    Toolkit's Data folder. Close the Toolkit first, so it doesn't overwrite the
    files or keep stale copies open.

    Safety:
      - Copy only by default. Toolkit files that aren't in src\ are kept, unless
        -Prune is given.
      - If a Toolkit file is newer than the repo's copy and different from it,
        it's probably an unsynced Toolkit edit. The script stops and lists those
        files, unless -Force is given. Run Sync-FromToolkit.ps1 first to keep them.

.PARAMETER WhatIf
    Show what would be copied or deleted without changing anything.

.PARAMETER Prune
    Also delete Toolkit files that aren't in src\ (a full mirror).

.PARAMETER Force
    Overwrite Toolkit files even when they're newer than the repo's copy.

.PARAMETER GameData
    The game's Data folder. Defaults to the BG3_DATA environment variable, then
    the standard Steam install path.

.NOTES
    HOW TO RUN
    Close the BG3 Toolkit. Open PowerShell (or the VS Code terminal) in the
    repo folder, then:

        powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1 -WhatIf
            Preview: lists what would change, changes nothing.

        powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1
            Copy src\ into the Toolkit project. Then open the Toolkit and build.

        powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1 -Prune
            Also delete Toolkit files you removed from the repo.

        powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1 -Force
            Overwrite Toolkit files that are newer than the repo's copy.
            Only after checking they're edits you don't need.

        powershell -ExecutionPolicy Bypass -File scripts\Sync-ToToolkit.ps1 -GameData "D:\SteamLibrary\steamapps\common\Baldurs Gate 3\Data"
            Game installed somewhere else (or set BG3_DATA once instead).

    "-ExecutionPolicy Bypass" lets Windows run the script for that one command;
    it doesn't change any system setting. Run from another folder by giving the
    full path to the script; it always finds the repo from its own location.

    See scripts\README.md for when to use which script.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Prune,
    [switch]$Force,
    [string]$GameData
)

$ErrorActionPreference = 'Stop'

if (-not $GameData) {
    $GameData = if ($env:BG3_DATA) { $env:BG3_DATA } else { 'C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Data' }
}

$ModFolder = 'ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $RepoRoot 'src'
$Folders = @('Mods', 'Public', 'Editor\Mods', 'Projects')

# Guards: a mirror from an empty src\ would wipe the Toolkit project, and a
# wrong game path would scatter files somewhere useless.
if (-not (Test-Path (Join-Path $Src "Mods\$ModFolder\meta.lsx"))) {
    throw "src\Mods\$ModFolder\meta.lsx not found. Is this the right repo?"
}
if (-not (Test-Path ([IO.Path]::Combine($GameData, 'Mods')))) {
    throw "Game Data folder not found: $GameData. Pass -GameData or set BG3_DATA."
}
if (Get-Process -Name 'BG3Toolkit*', 'LSToolFramework*' -ErrorAction SilentlyContinue) {
    Write-Warning 'The BG3 Toolkit looks like it is running. Close it before syncing, or it may overwrite these files.'
}

# Find Toolkit files that are newer than the repo's copy and differ from it.
$conflicts = @()
foreach ($folder in $Folders) {
    $from = Join-Path $Src "$folder\$ModFolder"
    $to = [IO.Path]::Combine($GameData, $folder, $ModFolder)
    if (-not (Test-Path $from) -or -not (Test-Path $to)) { continue }
    foreach ($file in Get-ChildItem $from -Recurse -File) {
        $target = Join-Path $to $file.FullName.Substring($from.Length + 1)
        if (-not (Test-Path $target)) { continue }
        $existing = Get-Item $target
        if ($existing.LastWriteTime -gt $file.LastWriteTime -and
            (Get-FileHash $existing.FullName).Hash -ne (Get-FileHash $file.FullName).Hash) {
            $conflicts += "$folder\$ModFolder\$($file.FullName.Substring($from.Length + 1))"
        }
    }
}
if ($conflicts -and -not $Force) {
    Write-Host 'These Toolkit files are newer than the repo and differ from it:' -ForegroundColor Yellow
    $conflicts | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    throw 'Stopped so they are not overwritten. Run Sync-FromToolkit.ps1 to keep them, or pass -Force to overwrite them.'
}

$mode = if ($WhatIf) { 'DRY RUN - nothing will change' } elseif ($Prune) { 'syncing, deleting extra Toolkit files' } else { 'syncing' }
Write-Host "repo -> Toolkit ($mode)" -ForegroundColor Cyan

foreach ($folder in $Folders) {
    $from = Join-Path $Src "$folder\$ModFolder"
    $to = [IO.Path]::Combine($GameData, $folder, $ModFolder)

    if (-not (Test-Path $from)) {
        Write-Host "  skip  $folder (not in repo)" -ForegroundColor DarkGray
        continue
    }

    # /E copy subfolders, /XX don't list Toolkit-only files (prune handles those);
    # /NJH /NJS /NP /NDL quiet output, /FP full paths.
    # Not /MIR: it would also delete the Toolkit's empty folders (Content, RootTemplates).
    $flags = @('/E', '/XX', '/NJH', '/NJS', '/NP', '/NDL', '/FP', '/R:1', '/W:1')
    if ($WhatIf) { $flags += '/L' }

    Write-Host "  sync  $folder"
    robocopy $from $to @flags | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "        $($_.Trim())" }

    # robocopy: 0-7 = success (with or without changes), 8+ = failure
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed for $folder (exit code $LASTEXITCODE)."
    }

    # Prune deletes extra files only; folders are left alone.
    if ($Prune -and (Test-Path $to)) {
        foreach ($file in Get-ChildItem $to -Recurse -File) {
            $rel = $file.FullName.Substring($to.Length + 1)
            if (-not (Test-Path (Join-Path $from $rel))) {
                Write-Host "        delete   $rel"
                if (-not $WhatIf) { Remove-Item $file.FullName -Force }
            }
        }
    }
}

Write-Host ''
Write-Host 'Done. Open the Toolkit and build.' -ForegroundColor Green
