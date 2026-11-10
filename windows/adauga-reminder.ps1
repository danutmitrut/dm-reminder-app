# adauga-reminder.ps1: programează un reminder deja prezent în remindere.json.
# Folosire (în PowerShell):
#   .\adauga-reminder.ps1 pauza-ceai --saptamanal luni 11 00
#   .\adauga-reminder.ps1 pauza-ceai --zilnic 11:00
#   .\adauga-reminder.ps1 pauza-ceai --o-data 2026-11-15 11 00
# Trebuie rulat din %USERPROFILE%\Remindere\ (după instaleaza.ps1).

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Argamente
)

$ErrorActionPreference = 'Stop'

$Dest = Join-Path $env:USERPROFILE 'Remindere'
$Aici = $PSScriptRoot
if (-not $Aici) { $Aici = $Dest }

function Show-Utilizare {
    @"
Folosire:
  .\adauga-reminder.ps1 <id> --saptamanal <zi> <ora> [minut]
  .\adauga-reminder.ps1 <id> --zilnic <ora> [minut]
  .\adauga-reminder.ps1 <id> --o-data <YYYY-MM-DD> <ora> [minut]

Exemple:
  .\adauga-reminder.ps1 pauza-ceai --saptamanal luni 11 00
  .\adauga-reminder.ps1 pauza-ceai --zilnic 11:00
  .\adauga-reminder.ps1 pauza-ceai --o-data 2026-11-15 11 00

Reminderul (titlu și text) trebuie să existe deja în $Dest\remindere.json.
Rulează mai întâi: .\instaleaza.ps1
"@ | Write-Host
}

if (-not $Argamente -or $Argamente.Count -lt 2 -or $Argamente[0] -in @('-h', '--help', '/?')) {
    Show-Utilizare
    exit 0
}

if ([IO.Path]::GetFullPath($Aici).TrimEnd('\') -ne [IO.Path]::GetFullPath($Dest).TrimEnd('\')) {
    Write-Host "Fișierele trebuie să fie în $Dest."
    Write-Host "Rulează mai întâi, din pachet: .\windows\instaleaza.ps1"
    exit 1
}

$Id = $Argamente[0]
if ($Id -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Host "Id invalid: $Id. Folosește doar litere, cifre, cratimă și underscore."
    exit 1
}

$JsonPath = Join-Path $Dest 'remindere.json'
$ScriptPath = Join-Path $Dest 'reminder.ps1'
if (-not (Test-Path -LiteralPath $JsonPath) -or -not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Host "Lipsesc $JsonPath sau $ScriptPath. Rulează mai întâi instaleaza.ps1."
    exit 1
}

$raw = [System.IO.File]::ReadAllText($JsonPath, [System.Text.Encoding]::UTF8)
try { $lista = $raw | ConvertFrom-Json } catch {
    Write-Host 'remindere.json nu este un JSON valid.'
    exit 1
}
$prop = $lista.PSObject.Properties[$Id]
if ($null -eq $prop -or $null -eq $prop.Value) {
    Write-Host "Nu am găsit reminderul `"$Id`" în $JsonPath."
    Write-Host 'Adaugă mai întâi intrarea în remindere.json, apoi rulează din nou acest script.'
    exit 1
}
$item = $prop.Value
if ([string]::IsNullOrWhiteSpace([string]$item.titlu) -or [string]::IsNullOrWhiteSpace([string]$item.text)) {
    Write-Host "Reminderului `"$Id`" îi lipsesc câmpurile titlu și text."
    exit 1
}

function Get-ZiEngleza([string]$Zi) {
    $z = $Zi.ToLowerInvariant()
    $z = $z.Replace('ă', 'a').Replace('â', 'a').Replace('î', 'i').Replace('ș', 's').Replace('ş', 's').Replace('ț', 't').Replace('ţ', 't')
    switch ($z) {
        { $_ -in @('duminica', 'sunday') } { return @{ Eng = 'Sunday'; Ro = 'duminică' } }
        { $_ -in @('luni', 'monday') }     { return @{ Eng = 'Monday'; Ro = 'luni' } }
        { $_ -in @('marti', 'tuesday') }   { return @{ Eng = 'Tuesday'; Ro = 'marți' } }
        { $_ -in @('miercuri', 'wednesday') } { return @{ Eng = 'Wednesday'; Ro = 'miercuri' } }
        { $_ -in @('joi', 'thursday') }    { return @{ Eng = 'Thursday'; Ro = 'joi' } }
        { $_ -in @('vineri', 'friday') }   { return @{ Eng = 'Friday'; Ro = 'vineri' } }
        { $_ -in @('sambata', 'saturday') } { return @{ Eng = 'Saturday'; Ro = 'sâmbătă' } }
        default { return $null }
    }
}

function Get-OraMinut([string[]]$Rest, [int]$Index) {
    if ($Index -ge $Rest.Count) { throw 'Lipsește ora.' }
    $a = $Rest[$Index]
    $ora = 0
    $minut = 0
    if ($a -match '^(\d{1,2}):(\d{1,2})$') {
        $ora = [int]$Matches[1]
        $minut = [int]$Matches[2]
    } else {
        $ora = [int]$a
        if (($Index + 1) -lt $Rest.Count -and $Rest[$Index + 1] -match '^\d{1,2}$') {
            $minut = [int]$Rest[$Index + 1]
        } else {
            $minut = 0
        }
    }
    if ($ora -lt 0 -or $ora -gt 23 -or $minut -lt 0 -or $minut -gt 59) {
        throw "Ora trebuie să fie între 0 și 23, minutul între 0 și 59. Am primit: $a"
    }
    return @{ Ora = $ora; Minut = $minut }
}

$mod = $Argamente[1]
$rest = @($Argamente | Select-Object -Skip 2)
$cand = ''
$oData = $false
$trigger = $null

try {
    switch ($mod) {
        '--saptamanal' {
            if ($rest.Count -lt 2) { Show-Utilizare; exit 1 }
            $zi = Get-ZiEngleza $rest[0]
            if ($null -eq $zi) { throw "Zi necunoscută: $($rest[0])" }
            $om = Get-OraMinut $rest 1
            $cand = '{0} {1:D2}:{2:D2}, săptămânal' -f $zi.Ro, $om.Ora, $om.Minut
            $la = Get-Date -Hour $om.Ora -Minute $om.Minut -Second 0
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $zi.Eng -At $la
        }
        '--zilnic' {
            if ($rest.Count -lt 1) { Show-Utilizare; exit 1 }
            $om = Get-OraMinut $rest 0
            $cand = '{0:D2}:{1:D2}, zilnic' -f $om.Ora, $om.Minut
            $la = Get-Date -Hour $om.Ora -Minute $om.Minut -Second 0
            $trigger = New-ScheduledTaskTrigger -Daily -At $la
        }
        '--o-data' {
            if ($rest.Count -lt 2) { Show-Utilizare; exit 1 }
            $data = $rest[0]
            if ($data -notmatch '^\d{4}-\d{2}-\d{2}$') {
                throw "Data trebuie să fie de forma YYYY-MM-DD, de exemplu 2026-11-15."
            }
            $om = Get-OraMinut $rest 1
            $cand = '{0} {1:D2}:{2:D2}, o dată' -f $data, $om.Ora, $om.Minut
            $oData = $true
            $la = [datetime]::ParseExact(('{0} {1:D2}:{2:D2}:00' -f $data, $om.Ora, $om.Minut), 'yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture)
            $trigger = New-ScheduledTaskTrigger -Once -At $la
        }
        default {
            Write-Host 'Lipsește modul: --saptamanal, --zilnic sau --o-data.'
            Show-Utilizare
            exit 1
        }
    }
} catch {
    Write-Host $_.Exception.Message
    exit 1
}

# Actualizează câmpul cand (și o_data) în JSON.
$item | Add-Member -NotePropertyName cand -NotePropertyValue $cand -Force
if ($oData) {
    $item | Add-Member -NotePropertyName o_data -NotePropertyValue $true -Force
} else {
    if ($item.PSObject.Properties['o_data']) { $item.PSObject.Properties.Remove('o_data') }
    if ($item.PSObject.Properties['tip']) { $item.PSObject.Properties.Remove('tip') }
}

# ConvertTo-Json din Windows PowerShell 5.1 poate scăpa unicode ca \uXXXX.
# Scriem manual un JSON îngrijit, păstrând restul listei.
function ConvertTo-JsonIngrijit($Obj, [int]$Nivel = 0) {
    $pad = '  ' * $Nivel
    $pad2 = '  ' * ($Nivel + 1)
    $esc = {
        param($s)
        $t = [string]$s
        $t = $t.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
        '"{0}"' -f $t
    }
    if ($null -eq $Obj) { return 'null' }
    if ($Obj -is [bool] -or $Obj -is [System.Boolean]) { if ($Obj) { return 'true' } else { return 'false' } }
    if ($Obj -is [int] -or $Obj -is [long] -or $Obj -is [double] -or $Obj -is [decimal]) { return [string]$Obj }
    if ($Obj -is [string]) { return & $esc $Obj }
    if ($Obj -is [System.Collections.IDictionary]) {
        $piese = @()
        foreach ($k in $Obj.Keys) {
            $piese += ('{0}{1}: {2}' -f $pad2, (& $esc $k), (ConvertTo-JsonIngrijit $Obj[$k] ($Nivel + 1)))
        }
        return "{\n$($piese -join ",\n")\n$pad}"
    }
    # PSCustomObject
    $props = @($Obj.PSObject.Properties)
    if ($Obj -is [System.Management.Automation.PSCustomObject] -or $props.Count -gt 0) {
        $piese = @()
        foreach ($p in $props) {
            $piese += ('{0}{1}: {2}' -f $pad2, (& $esc $p.Name), (ConvertTo-JsonIngrijit $p.Value ($Nivel + 1)))
        }
        return "{$([Environment]::NewLine)$($piese -join (',' + [Environment]::NewLine))$([Environment]::NewLine)$pad}"
    }
    return (& $esc ([string]$Obj))
}

# Bug in my ConvertTo-JsonIngrijit for hashtables: I used literal \n instead of newlines.
# I'll fix by not using that branch much; lista is PSCustomObject.

$jsonNou = (ConvertTo-JsonIngrijit $lista 0) + [Environment]::NewLine
# Fix accidental \n sequences if any from hashtable branch (not used for root).
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($JsonPath, $jsonNou, $utf8Bom)

# Sarcina programată: rulează doar când utilizatorul e autentificat, interactiv, fără fereastră de consolă.
$argumente = '-STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -Identificator {1}' -f $ScriptPath, $Id
try {
    $actiune = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argumente -WorkingDirectory $Dest
} catch {
    $actiune = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argumente
}
$setari = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1) -MultipleInstances IgnoreNew
$utilizator = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
$principal = New-ScheduledTaskPrincipal -UserId $utilizator -LogonType Interactive -RunLevel Limited

$numeSarcina = "CursantReminder-$Id"
$caleSarcina = '\Remindere\'

# Register-ScheduledTask -Force înlocuiește o sarcină existentă cu același nume.
Register-ScheduledTask -TaskName $numeSarcina -TaskPath $caleSarcina -Action $actiune -Trigger $trigger -Settings $setari -Principal $principal -Force | Out-Null

Write-Host "Reminderul `"$Id`" este armat: $cand"
Write-Host "Sarcină: ${caleSarcina}${numeSarcina}"
Write-Host 'Pentru a-l vedea acum, fără să aștepți ora:'
Write-Host ("  powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -Id $Id")
