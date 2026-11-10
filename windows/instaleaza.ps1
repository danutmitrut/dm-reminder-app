# instaleaza.ps1: copiază fișierele de Windows în %USERPROFILE%\Remindere,
# fără să suprascrie un remindere.json existent.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Src = $PSScriptRoot
if (-not $Src) { $Src = Split-Path -Parent $MyInvocation.MyCommand.Path }
$Dest = Join-Path $env:USERPROFILE 'Remindere'
$Root = Split-Path -Parent $Src

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Copy-Item -Force -LiteralPath (Join-Path $Src 'reminder.ps1') -Destination $Dest
Copy-Item -Force -LiteralPath (Join-Path $Src 'adauga-reminder.ps1') -Destination $Dest
Copy-Item -Force -LiteralPath (Join-Path $Src 'sterge-reminder.ps1') -Destination $Dest

$jsonDest = Join-Path $Dest 'remindere.json'
if (Test-Path -LiteralPath $jsonDest) {
    Write-Host "Păstrez remindere.json existent din $Dest."
} else {
    Copy-Item -Force -LiteralPath (Join-Path $Src 'remindere.json') -Destination $Dest
}

foreach ($doc in @('README.md', 'GHID-RAPID.md', 'INSTRUCTIUNI-PENTRU-CLAUDE.md')) {
    $from = Join-Path $Root $doc
    if (Test-Path -LiteralPath $from) {
        Copy-Item -Force -LiteralPath $from -Destination $Dest
    }
}

Write-Host "Gata. Fișierele sunt în $Dest"
Write-Host "Ca să adaugi un reminder, scrie titlul și textul în $Dest\remindere.json,"
Write-Host 'apoi rulează, de exemplu:'
Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Dest\adauga-reminder.ps1`" pauza-ceai --saptamanal luni 11 00"
Write-Host 'Ca să vezi fereastra acum:'
Write-Host "  powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File `"$Dest\reminder.ps1`" -Id pauza-ceai"
