# sterge-reminder.ps1: dezarmează un reminder (șterge sarcina programată).
# Folosire:
#   .\sterge-reminder.ps1 <id>
#   .\sterge-reminder.ps1 <id> --si-din-lista

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
  .\sterge-reminder.ps1 <id>
  .\sterge-reminder.ps1 <id> --si-din-lista

Prima formă oprește programarea, dar lasă textul în remindere.json.
A doua scoate și intrarea din listă.
"@ | Write-Host
}

if (-not $Argamente -or $Argamente.Count -lt 1 -or $Argamente[0] -in @('-h', '--help', '/?')) {
    Show-Utilizare
    exit 0
}

if ([IO.Path]::GetFullPath($Aici).TrimEnd('\') -ne [IO.Path]::GetFullPath($Dest).TrimEnd('\')) {
    Write-Host "Fișierele trebuie să fie în $Dest."
    Write-Host "Rulează mai întâi, din pachet: .\windows\instaleaza.ps1"
    exit 1
}

$Id = $Argamente[0]
$siDinLista = $false
if ($Argamente.Count -ge 2 -and $Argamente[1] -eq '--si-din-lista') { $siDinLista = $true }

if ($Id -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Host "Id invalid: $Id."
    exit 1
}

$numeSarcina = "CursantReminder-$Id"
$caleSarcina = '\Remindere\'

$existent = Get-ScheduledTask -TaskName $numeSarcina -TaskPath $caleSarcina -ErrorAction SilentlyContinue
if ($existent) {
    Unregister-ScheduledTask -TaskName $numeSarcina -TaskPath $caleSarcina -Confirm:$false
    Write-Host "Am scos programarea: ${caleSarcina}${numeSarcina}"
} else {
    Write-Host "Nu am găsit sarcina ${caleSarcina}${numeSarcina} (poate era deja ștearsă)."
}

if ($siDinLista) {
    $jsonPath = Join-Path $Dest 'remindere.json'
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        Write-Host "Nu am găsit $jsonPath, deci n-am ce scoate din listă."
        exit 0
    }
    $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
    $lista = $raw | ConvertFrom-Json
    if (-not $lista.PSObject.Properties[$Id]) {
        Write-Host "Nu am găsit `"$Id`" în remindere.json."
        exit 0
    }
    $lista.PSObject.Properties.Remove($Id)

    function ConvertTo-JsonIngrijit($Obj, [int]$Nivel = 0) {
        $pad = '  ' * $Nivel
        $pad2 = '  ' * ($Nivel + 1)
        $nl = [Environment]::NewLine
        if ($null -eq $Obj) { return 'null' }
        if ($Obj -is [bool] -or $Obj -is [System.Boolean]) { if ($Obj) { return 'true' } else { return 'false' } }
        if ($Obj -is [int] -or $Obj -is [long] -or $Obj -is [double] -or $Obj -is [decimal]) { return [string]$Obj }
        if ($Obj -is [string]) {
            $t = $Obj.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
            return '"{0}"' -f $t
        }
        $props = @($Obj.PSObject.Properties)
        $piese = @()
        foreach ($p in $props) {
            $piese += ('{0}{1}: {2}' -f $pad2, ('"{0}"' -f $p.Name), (ConvertTo-JsonIngrijit $p.Value ($Nivel + 1)))
        }
        return ('{{{0}{1}{0}{2}}}' -f $nl, ($piese -join (',' + $nl)), $pad)
    }

    $jsonNou = (ConvertTo-JsonIngrijit $lista 0) + [Environment]::NewLine
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($jsonPath, $jsonNou, $utf8Bom)
    Write-Host "Am scos `"$Id`" și din remindere.json."
}

Write-Host 'Gata. Dacă vrei să te asiguri că nu mai e armat:'
Write-Host "  Get-ScheduledTask -TaskName $numeSarcina -TaskPath $caleSarcina"
Write-Host '(comanda trebuie să nu mai găsească sarcina.)'
