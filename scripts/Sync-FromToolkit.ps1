<#
.SYNOPSIS
    Copies the mod's project files from the BG3 Toolkit data folder into src/,
    and optionally copies the built .pak into releases/vX.Y.Z/.

.DESCRIPTION
    Mirrors Mods, Public, Editor\Mods and Projects for this mod from the Toolkit's
    Data folder into the repo's src\ folder. Mirroring means files deleted in the
    Toolkit are deleted in src\ too, so src\ always matches what was built.

    Nothing is committed. Review the changes with `git status` afterwards.

.PARAMETER Version
    Release version (e.g. 1.0.1). When given, the built .pak is copied from the
    game's Mods folder into releases\v<Version>\.

.PARAMETER WhatIf
    Show what would be copied or deleted without changing anything.

.PARAMETER GameData
    The game's Data folder (where the Toolkit keeps projects). Defaults to the
    BG3_DATA environment variable, then the standard Steam install path.

.PARAMETER PakFolder
    Where the Toolkit puts the built .pak. Defaults to the BG3_PAKS environment
    variable, then %LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods.

.EXAMPLE
    .\scripts\Sync-FromToolkit.ps1 -WhatIf
    .\scripts\Sync-FromToolkit.ps1
    .\scripts\Sync-FromToolkit.ps1 -Version 1.0.1
#>
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$WhatIf,
    [string]$GameData,
    [string]$PakFolder
)

$ErrorActionPreference = 'Stop'

if (-not $GameData) {
    $GameData = if ($env:BG3_DATA) { $env:BG3_DATA } else { 'C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Data' }
}
if (-not $PakFolder) {
    $PakFolder = if ($env:BG3_PAKS) { $env:BG3_PAKS } else { "$env:LOCALAPPDATA\Larian Studios\Baldur's Gate 3\Mods" }
}

$ModFolder = 'ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $RepoRoot 'src'

# Toolkit sub-folder -> repo sub-folder (both relative)
$Folders = [ordered]@{
    'Mods'        = 'Mods'
    'Public'      = 'Public'
    'Editor\Mods' = 'Editor\Mods'
    'Projects'    = 'Projects'
}

# Guard: a mirror from a missing or wrong folder would wipe src\.
# [IO.Path] rather than Join-Path, which throws on a drive that doesn't exist.
$Meta = [IO.Path]::Combine($GameData, 'Mods', $ModFolder, 'meta.lsx')
if (-not (Test-Path $Meta)) {
    throw "Toolkit project not found: $Meta. Pass -GameData or set BG3_DATA to your game's Data folder."
}

$mode = if ($WhatIf) { 'DRY RUN - nothing will change' } else { 'syncing' }
Write-Host "Toolkit -> repo ($mode)" -ForegroundColor Cyan

foreach ($entry in $Folders.GetEnumerator()) {
    $from = Join-Path $GameData "$($entry.Key)\$ModFolder"
    $to = Join-Path $Src "$($entry.Value)\$ModFolder"

    if (-not (Test-Path $from)) {
        Write-Host "  skip  $($entry.Key) (not in Toolkit)" -ForegroundColor DarkGray
        continue
    }

    # /MIR mirror (copies and deletes), /NJH /NJS /NP /NDL quiet output, /FP full paths
    $flags = @('/MIR', '/NJH', '/NJS', '/NP', '/NDL', '/FP', '/R:1', '/W:1')
    if ($WhatIf) { $flags += '/L' }

    Write-Host "  sync  $($entry.Key)"
    robocopy $from $to @flags | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "        $($_.Trim())" }

    # robocopy: 0-7 = success (with or without changes), 8+ = failure
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed for $($entry.Key) (exit code $LASTEXITCODE)."
    }
}

if ($Version) {
    $Version = $Version.TrimStart('v')
    $pak = Join-Path $PakFolder "$ModFolder.pak"
    if (-not (Test-Path $pak)) {
        throw "Built pak not found: $pak. Build it in the Toolkit first."
    }
    $releaseDir = Join-Path $RepoRoot "releases\v$Version"
    $built = (Get-Item $pak).LastWriteTime
    Write-Host "  pak   $ModFolder.pak (built $built) -> releases\v$Version\"
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
        Copy-Item $pak $releaseDir -Force
    }
}

Write-Host ''
Write-Host 'Done. Review with: git status' -ForegroundColor Green
