# link-skills.ps1 -- one junction per skill: .\Claude\<name> -> %USERPROFILE%\.claude\skills\<name>
# Junctions need no admin rights or Developer Mode.
# Re-run after creating or deleting a skill, and after `git pull` brings new ones.
#   powershell -ExecutionPolicy Bypass -File .\link-skills.ps1           # link, refresh, prune
#   powershell -ExecutionPolicy Bypass -File .\link-skills.ps1 -DryRun   # show only
param([switch]$DryRun)
$ErrorActionPreference = 'Stop'

$Source = (Resolve-Path (Join-Path $PSScriptRoot 'Claude')).Path
$Target = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $HOME '.claude\skills' }

function Do-It([string]$Msg, [scriptblock]$Act) { Write-Host $Msg; if (-not $DryRun) { & $Act } }

# Old layout: the whole dir was one link. Remove the link (never its contents).
$t = Get-Item $Target -ErrorAction SilentlyContinue
if ($t -and $t.LinkType) { Do-It "replace dir link: $Target" { $t.Delete() } }
if (-not (Test-Path $Target)) { Do-It "mkdir: $Target" { New-Item -ItemType Directory -Path $Target | Out-Null } }

# link every Claude\<name>\SKILL.md
Get-ChildItem $Source -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object {
  $name = $_.Name; $src = $_.FullName; $dest = Join-Path $Target $name
  $existing = Get-Item $dest -ErrorAction SilentlyContinue
  if ($existing -and -not $existing.LinkType) { Write-Host "skip (real dir, not a link): $dest"; return }
  Do-It "link:  $name" { if ($existing) { $existing.Delete() }; New-Item -ItemType Junction -Path $dest -Target $src | Out-Null }
}

# prune links into Source whose skill folder is gone
Get-ChildItem $Target -Directory -ErrorAction SilentlyContinue | Where-Object { $_.LinkType } | ForEach-Object {
  $item = $_; $tgt = @($_.Target)[0]
  if ($tgt -and $tgt.StartsWith($Source) -and -not (Test-Path $tgt)) { Do-It "prune: $($_.Name)" { $item.Delete() } }
}
