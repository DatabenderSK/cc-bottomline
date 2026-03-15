# CC Bottomline — Windows PowerShell installer
# Usage: irm https://raw.githubusercontent.com/DatabenderSK/cc-bottomline/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$repo = "https://raw.githubusercontent.com/DatabenderSK/cc-bottomline/main"
$dest = "$env:USERPROFILE\.claude"

Write-Host "Installing CC Bottomline..." -ForegroundColor Cyan

# Check prerequisites
$missing = @()
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) { $missing += "bash (Git for Windows)" }
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { $missing += "jq" }
if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing prerequisites:" -ForegroundColor Yellow
    foreach ($m in $missing) { Write-Host "  - $m" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Install with:" -ForegroundColor Gray
    Write-Host "  winget install Git.Git" -ForegroundColor Gray
    Write-Host "  winget install jqlang.jq" -ForegroundColor Gray
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') { exit 1 }
}

# Create directory
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Download scripts
$files = @(
    "scripts/statusline-command.sh",
    "scripts/fetch-usage.sh",
    "scripts/track-tool.sh",
    "scripts/get-credentials.ps1"
)
foreach ($file in $files) {
    $name = Split-Path $file -Leaf
    Write-Host "  Downloading $name..."
    Invoke-WebRequest -Uri "$repo/$file" -OutFile "$dest\$name" -UseBasicParsing
}

# Config — only if not exists
$confPath = "$dest\statusline.conf"
if (-not (Test-Path $confPath)) {
    Invoke-WebRequest -Uri "$repo/scripts/statusline.conf" -OutFile $confPath -UseBasicParsing
    Write-Host "  Created default config: ~/.claude/statusline.conf"
} else {
    Write-Host "  Config already exists, skipping"
}

# Wire settings.json
$settingsPath = "$dest\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

# Add statusLine
$statusLine = [PSCustomObject]@{
    type = "command"
    command = "bash ~/.claude/statusline-command.sh"
}
if ($settings.PSObject.Properties['statusLine']) {
    $settings.statusLine = $statusLine
} else {
    $settings | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLine
}

# Add hooks
if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{})
}

if (-not $settings.hooks.PSObject.Properties['PreToolUse']) {
    $preToolUse = @(
        [PSCustomObject]@{
            matcher = ""
            hooks = @(
                [PSCustomObject]@{
                    type = "command"
                    command = "bash ~/.claude/track-tool.sh; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &"
                }
            )
        }
    )
    $settings.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue $preToolUse
}

if (-not $settings.hooks.PSObject.Properties['Stop']) {
    $stop = @(
        [PSCustomObject]@{
            matcher = ""
            hooks = @(
                [PSCustomObject]@{
                    type = "command"
                    command = "bash ~/.claude/track-tool.sh clean; bash ~/.claude/fetch-usage.sh > /dev/null 2>&1 &"
                }
            )
        }
    )
    $settings.hooks | Add-Member -NotePropertyName 'Stop' -NotePropertyValue $stop
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "  Updated ~/.claude/settings.json"

Write-Host ""
Write-Host "Done! Restart Claude Code to see your new bottomline." -ForegroundColor Green
Write-Host ""
Write-Host "Change theme:  edit ~/.claude/statusline.conf -> THEME=hybrid" -ForegroundColor Gray
Write-Host "Available:     hybrid, default, minimal, nerd, compact, tokyo" -ForegroundColor Gray
Write-Host "Preview:       https://github.com/DatabenderSK/cc-bottomline#themes" -ForegroundColor Gray
