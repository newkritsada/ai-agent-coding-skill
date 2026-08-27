<#
.SYNOPSIS
  Mirror .\Claude into the global skills directory.

.DESCRIPTION
  .\Claude is the single source of truth. The target is REBUILT from it, so any
  skill that exists only in the target is DELETED.

.EXAMPLE
  .\sync-skills.ps1 -DryRun   # show what would change
  .\sync-skills.ps1           # do it
#>
[CmdletBinding()]
param(
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$Source = Join-Path $PSScriptRoot 'Claude'
$Target = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR }
          else { Join-Path $env:USERPROFILE '.claude\skills' }

# Never copied into the target.
$Excludes = @(
  'sync-skills.sh'
  'sync-skills.cmd'
  'sync-skills.ps1'
  '.gitignore'
  '.DS_Store'
  'Thumbs.db'
  '.git'
)

function Resolve-Full([string]$p) {
  try { (Resolve-Path -LiteralPath $p -ErrorAction Stop).ProviderPath.TrimEnd('\') }
  catch { $p.TrimEnd('\') }
}

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
  Write-Host "source skills dir not found: $Source" -ForegroundColor Red
  exit 1
}
$SourceFull = Resolve-Full $Source

$parent = Split-Path -Parent $Target
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
  Write-Host "ABORT: parent directory does not exist ($parent)" -ForegroundColor Red
  exit 1
}

# Refuse to rebuild a target that is (or contains) the source.
if (Test-Path -LiteralPath $Target) {
  $TargetFull = Resolve-Full $Target
  if ($TargetFull -eq $SourceFull) {
    Write-Host "ABORT: target resolves to the source ($TargetFull)" -ForegroundColor Red
    exit 1
  }
  if ($SourceFull.StartsWith($TargetFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "ABORT: source lives inside the target" -ForegroundColor Red
    exit 1
  }
}

# Top-level entries of the source that should be copied.
$payload = Get-ChildItem -LiteralPath $Source -Force |
  Where-Object { $Excludes -notcontains $_.Name }

Write-Host "Source of truth: $SourceFull" -ForegroundColor Green
Write-Host "->              $Target"      -ForegroundColor Cyan

if ($DryRun) {
  Write-Host 'DRY RUN' -ForegroundColor Yellow
  if (Test-Path -LiteralPath $Target) {
    Get-ChildItem -LiteralPath $Target -Force |
      ForEach-Object { Write-Host "   delete $($_.Name)" -ForegroundColor Red }
  }
  $payload | ForEach-Object { Write-Host "   copy   $($_.Name)" -ForegroundColor Green }
  Write-Host 'dry run -- nothing written' -ForegroundColor DarkGray
  exit 0
}

# A symlink/junction at the target is removed as a link, not followed.
if (Test-Path -LiteralPath $Target) {
  $item = Get-Item -LiteralPath $Target -Force
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    $item.Delete()
  } else {
    Remove-Item -LiteralPath $Target -Recurse -Force
  }
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null
foreach ($entry in $payload) {
  Copy-Item -LiteralPath $entry.FullName -Destination $Target -Recurse -Force
}

Write-Host "synced ($($payload.Count) entries)" -ForegroundColor Green
