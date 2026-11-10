﻿﻿# reminder.ps1: arată un reminder din remindere.json (WPF).
# Folosire: powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File reminder.ps1 -Id <id>
# Salvat UTF-8 cu BOM, pentru diacritice în Windows PowerShell 5.1.
# „Am înțeles” sau Enter închid fereastra. „Repetă în” o ascunde și o readuce după N minute.
# Culorile stau în stânga sus, ceasul analogic în dreapta sus, data în stânga ceasului. design.json lângă script.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Alias('Id')]
    [string]$Identificator
)

$ErrorActionPreference = 'Stop'

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $psi = @(
        '-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', $MyInvocation.MyCommand.Path,
        '-Identificator', $Identificator
    )
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $psi -Wait -PassThru
    exit $p.ExitCode
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Media
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$dir = $PSScriptRoot
if (-not $dir) { $dir = Join-Path $env:USERPROFILE 'Remindere' }
$jsonPath = Join-Path $dir 'remindere.json'
$designPath = Join-Path $dir 'design.json'

if (-not (Test-Path -LiteralPath $jsonPath)) {
    [System.Windows.MessageBox]::Show("Nu găsesc fișierul remindere.json în:`n$dir", 'Reminder') | Out-Null
    exit 1
}

$raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
try {
    $lista = $raw | ConvertFrom-Json
} catch {
    [System.Windows.MessageBox]::Show('remindere.json nu este un JSON valid.', 'Reminder') | Out-Null
    exit 1
}

$r = $lista.PSObject.Properties[$Identificator]
if ($null -eq $r -or $null -eq $r.Value) {
    [System.Windows.MessageBox]::Show("Reminder necunoscut: $Identificator", 'Reminder') | Out-Null
    exit 1
}
$item = $r.Value
$titlu = [string]$item.titlu
if ([string]::IsNullOrWhiteSpace($titlu)) { $titlu = 'Reminder' }
$text = [string]$item.text
$titluMare = $titlu.ToUpper()

function Write-Jurnal([string]$Linie) {
    try {
        $jurnal = Join-Path $dir 'jurnal.log'
        $lin = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Linie
        $enc = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::AppendAllText($jurnal, $lin + [Environment]::NewLine, $enc)
    } catch {}
}

function Play-SunetReminder {
    try {
        $wav = Join-Path $env:WINDIR 'Media\Windows Notify.wav'
        if (-not (Test-Path -LiteralPath $wav)) {
            $wav = Join-Path $env:WINDIR 'Media\Windows Notify System Generic.wav'
        }
        if (Test-Path -LiteralPath $wav) {
            $player = New-Object System.Media.SoundPlayer $wav
            $player.Play()
        } else {
            [System.Media.SystemSounds]::Exclamation.Play()
        }
    } catch {
        try { [System.Media.SystemSounds]::Exclamation.Play() } catch {}
    }
}

function Get-RgbValid($val) {
    if ($null -eq $val) { return $null }
    $arr = @($val)
    if ($arr.Count -lt 3) { return $null }
    try {
        $r = [double]$arr[0]; $g = [double]$arr[1]; $b = [double]$arr[2]
    } catch { return $null }
    function Clip([double]$x) { if ($x -lt 0) { 0 } elseif ($x -gt 1) { 1 } else { $x } }
    return @((Clip $r), (Clip $g), (Clip $b))
}

function Get-DesignImplicit {
    return [pscustomobject]@{
        mod = 'degrade'
        solid = @(0.88, 0.80, 0.97)
        degrade_inceput = @(0.88, 0.80, 0.97)
        degrade_sfarsit = @(0.45, 0.76, 0.84)
        degrade_personalizat = $false
    }
}

function Read-Design {
    $d = Get-DesignImplicit
    if (-not (Test-Path -LiteralPath $designPath)) { return $d }
    try {
        $o = [System.IO.File]::ReadAllText($designPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($o.mod -eq 'solid' -or $o.mod -eq 'degrade') { $d.mod = [string]$o.mod }
        $s = Get-RgbValid $o.solid; if ($s) { $d.solid = $s }
        $a = Get-RgbValid $o.degrade_inceput; if ($a) { $d.degrade_inceput = $a }
        $b = Get-RgbValid $o.degrade_sfarsit; if ($b) { $d.degrade_sfarsit = $b }
        $d.degrade_personalizat = ($o.degrade_personalizat -eq $true)
    } catch {}
    return $d
}

function Save-Design($design) {
    function RoundRgb($rgb) {
        return @(
            [Math]::Round([double]$rgb[0], 4),
            [Math]::Round([double]$rgb[1], 4),
            [Math]::Round([double]$rgb[2], 4)
        )
    }
    $o = [ordered]@{
        mod = $design.mod
        solid = RoundRgb $design.solid
        degrade_inceput = RoundRgb $design.degrade_inceput
        degrade_sfarsit = RoundRgb $design.degrade_sfarsit
        degrade_personalizat = [bool]$design.degrade_personalizat
    }
    $json = ($o | ConvertTo-Json -Depth 5) + [Environment]::NewLine
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($designPath, $json, $enc)
}

function Get-MediaColor([double[]]$rgb) {
    $r = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[0] * 255)))
    $g = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[1] * 255)))
    $b = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[2] * 255)))
    return [Windows.Media.Color]::FromRgb($r, $g, $b)
}

function Get-DrawingColor([double[]]$rgb) {
    $r = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[0] * 255)))
    $g = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[1] * 255)))
    $b = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($rgb[2] * 255)))
    return [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
}

function Get-RgbFromDrawing($c) {
    return @(
        [Math]::Round($c.R / 255.0, 4),
        [Math]::Round($c.G / 255.0, 4),
        [Math]::Round($c.B / 255.0, 4)
    )
}

function Get-Luminanta($liste) {
    $s = 0.0
    $n = 0
    foreach ($rgb in $liste) {
        $s += 0.2126 * $rgb[0] + 0.7152 * $rgb[1] + 0.0722 * $rgb[2]
        $n++
    }
    if ($n -eq 0) { return 1 }
    return $s / $n
}

function Get-PartiData {
    $zile = @('duminică', 'luni', 'marți', 'miercuri', 'joi', 'vineri', 'sâmbătă')
    $luni = @('ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie')
    $d = Get-Date
    return [pscustomobject]@{
        zi = $zile[[int]$d.DayOfWeek]
        data = '{0} {1}' -f $d.Day, $luni[$d.Month - 1]
        an = [string]$d.Year
    }
}

function Set-TextData($window) {
    $p = Get-PartiData
    $window.FindName('DataZi').Text = $p.zi
    $window.FindName('DataLuna').Text = $p.data
    $window.FindName('DataAn').Text = $p.an
}

function Add-LinieCeas($canvas, $x1, $y1, $x2, $y2, $grosime, $brush) {
    $linie = New-Object Windows.Shapes.Line
    $linie.X1 = $x1; $linie.Y1 = $y1; $linie.X2 = $x2; $linie.Y2 = $y2
    $linie.Stroke = $brush
    $linie.StrokeThickness = $grosime
    $linie.StrokeStartLineCap = [Windows.Media.PenLineCap]::Round
    $linie.StrokeEndLineCap = [Windows.Media.PenLineCap]::Round
    [void]$canvas.Children.Add($linie)
}

function Update-CeasAnalog($canvas, $brush) {
    if ($null -eq $canvas) { return }
    $canvas.Children.Clear()
    $w = [double]$canvas.Width
    $h = [double]$canvas.Height
    $cx = $w / 2
    $cy = $h / 2
    $r = [Math]::Min($w, $h) / 2 - 3
    $cerc = New-Object Windows.Shapes.Ellipse
    $cerc.Width = $r * 2
    $cerc.Height = $r * 2
    $cerc.Stroke = $brush
    $cerc.StrokeThickness = 1.6
    $fundal = $brush.Clone()
    $fundal.Opacity = 0.08
    $cerc.Fill = $fundal
    [Windows.Controls.Canvas]::SetLeft($cerc, $cx - $r)
    [Windows.Controls.Canvas]::SetTop($cerc, $cy - $r)
    [void]$canvas.Children.Add($cerc)
    for ($i = 0; $i -lt 60; $i++) {
        $theta = $i * [Math]::PI / 30
        if (($i % 15) -eq 0) { $inner = $r - 13; $outer = $r - 2.5; $lw = 2.3 }
        elseif (($i % 5) -eq 0) { $inner = $r - 9; $outer = $r - 2.5; $lw = 1.6 }
        else { $inner = $r - 5; $outer = $r - 2.5; $lw = 1.0 }
        $x1 = $cx + [Math]::Sin($theta) * $inner
        $y1 = $cy - [Math]::Cos($theta) * $inner
        $x2 = $cx + [Math]::Sin($theta) * $outer
        $y2 = $cy - [Math]::Cos($theta) * $outer
        $tick = $brush.Clone(); $tick.Opacity = 0.72
        Add-LinieCeas $canvas $x1 $y1 $x2 $y2 $lw $tick
    }
    $now = Get-Date
    $sec = $now.Second
    $min = $now.Minute + $sec / 60.0
    $hr = ($now.Hour % 12) + $min / 60.0
    $aH = $hr * [Math]::PI / 6
    $aM = $min * [Math]::PI / 30
    $aS = $sec * [Math]::PI / 30
    function Mana($angle, $lung, $gros, $b) {
        $x1 = $cx - [Math]::Sin($angle) * ($r * 0.12)
        $y1 = $cy + [Math]::Cos($angle) * ($r * 0.12)
        $x2 = $cx + [Math]::Sin($angle) * $lung
        $y2 = $cy - [Math]::Cos($angle) * $lung
        Add-LinieCeas $canvas $x1 $y1 $x2 $y2 $gros $b
    }
    Mana $aH ($r * 0.52) 3.6 $brush
    Mana $aM ($r * 0.72) 2.4 $brush
    $secBrush = $brush.Clone(); $secBrush.Opacity = 0.9
    Mana $aS ($r * 0.80) 1.2 $secBrush
    $cap = New-Object Windows.Shapes.Ellipse
    $cap.Width = 7.2; $cap.Height = 7.2
    $cap.Fill = $brush
    [Windows.Controls.Canvas]::SetLeft($cap, $cx - 3.6)
    [Windows.Controls.Canvas]::SetTop($cap, $cy - 3.6)
    [void]$canvas.Children.Add($cap)
}

function Set-FundalDesign($window, $design, [switch]$Salveaza) {
    $border = $window.FindName('Rama')
    $c1 = @(0.88, 0.80, 0.97)
    $c2 = @(0.72, 0.50, 0.97)
    $c3 = @(0.45, 0.76, 0.84)
    if ($design.mod -eq 'solid') {
        $border.Background = New-Object Windows.Media.SolidColorBrush (Get-MediaColor $design.solid)
        $lista = @($design.solid)
        $bordRgb = $design.solid
        $implicit = $false
    } elseif ($design.degrade_personalizat) {
        $brush = New-Object Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object Windows.Point 0, 0.68
        $brush.EndPoint = New-Object Windows.Point 1, 0.32
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop (Get-MediaColor $design.degrade_inceput), 0))
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop (Get-MediaColor $design.degrade_sfarsit), 1))
        $border.Background = $brush
        $lista = @($design.degrade_inceput, $design.degrade_sfarsit)
        $bordRgb = $design.degrade_inceput
        $implicit = $false
    } else {
        $brush = New-Object Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object Windows.Point 0, 0.68
        $brush.EndPoint = New-Object Windows.Point 1, 0.32
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop (Get-MediaColor $c1), 0))
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop (Get-MediaColor $c2), 0.5))
        [void]$brush.GradientStops.Add((New-Object Windows.Media.GradientStop (Get-MediaColor $c3), 1))
        $border.Background = $brush
        $lista = @($c1, $c2, $c3)
        $bordRgb = $null
        $implicit = $true
    }
    if ($implicit) {
        $border.BorderBrush = New-Object Windows.Media.SolidColorBrush (Get-MediaColor @(0.62, 0.50, 0.92))
    } else {
        $inchis = @($bordRgb[0] * 0.72, $bordRgb[1] * 0.72, $bordRgb[2] * 0.72)
        $border.BorderBrush = New-Object Windows.Media.SolidColorBrush (Get-MediaColor $inchis)
    }
    $intunecat = (Get-Luminanta $lista) -lt 0.45
    if ($intunecat) {
        $tc = [Windows.Media.Colors]::White
    } else {
        $tc = Get-MediaColor @(0.05, 0.04, 0.09)
    }
    $brushText = New-Object Windows.Media.SolidColorBrush $tc
    $script:culoareAce = $brushText
    $window.FindName('Titlu').Foreground = $brushText
    $window.FindName('Mesaj').Foreground = $brushText
    $window.FindName('EtichetaFundal').Foreground = $brushText
    $window.FindName('RadioSolid').Foreground = $brushText
    $window.FindName('RadioDegrade').Foreground = $brushText
    $window.FindName('DataZi').Foreground = $brushText
    $window.FindName('DataLuna').Foreground = $brushText
    $window.FindName('DataAn').Foreground = $brushText
    Update-CeasAnalog $window.FindName('CeasAnalog') $brushText
    if ($intunecat) {
        $bordSelectat = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Colors]::White)
        $bordSelectat.Opacity = 0.92
    } else {
        $bordSelectat = New-Object Windows.Media.SolidColorBrush (Get-MediaColor @(0.05, 0.04, 0.09))
        $bordSelectat.Opacity = 0.92
    }
    $script:liniste = $true
    $window.FindName('RadioSolid').IsChecked = ($design.mod -eq 'solid')
    $window.FindName('RadioDegrade').IsChecked = ($design.mod -ne 'solid')
    $eSolid = ($design.mod -eq 'solid')
    $esSolid = $window.FindName('EsantionSolid')
    $esInceput = $window.FindName('EsantionInceput')
    $esSfarsit = $window.FindName('EsantionSfarsit')
    $esSolid.Background = New-Object Windows.Media.SolidColorBrush (Get-MediaColor $design.solid)
    $esInceput.Background = New-Object Windows.Media.SolidColorBrush (Get-MediaColor $design.degrade_inceput)
    $esSfarsit.Background = New-Object Windows.Media.SolidColorBrush (Get-MediaColor $design.degrade_sfarsit)
    $esSolid.BorderBrush = $bordSelectat
    $esInceput.BorderBrush = $bordSelectat
    $esSfarsit.BorderBrush = $bordSelectat
    $esSolid.BorderThickness = if ($eSolid) { 2 } else { 0 }
    $esInceput.BorderThickness = if ($eSolid) { 0 } else { 2 }
    $esSfarsit.BorderThickness = if ($eSolid) { 0 } else { 2 }
    $esSolid.Opacity = if ($eSolid) { 1 } else { 0.5 }
    $window.FindName('RandDegradeEsantioane').Opacity = if ($eSolid) { 0.5 } else { 1 }
    $script:liniste = $false
    if ($Salveaza) { Save-Design $design }
}

function Show-AlegeCuloare($window, [double[]]$curent) {
    $window.Topmost = $false
    $dlg = New-Object System.Windows.Forms.ColorDialog
    $dlg.FullOpen = $true
    $dlg.AnyColor = $true
    $dlg.SolidColorOnly = $false
    $dlg.Color = Get-DrawingColor $curent
    $rez = $dlg.ShowDialog()
    $window.Topmost = $true
    [void]$window.Activate()
    if ($rez -eq [System.Windows.Forms.DialogResult]::OK) {
        return (Get-RgbFromDrawing $dlg.Color)
    }
    return $null
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Reminder"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Width="920" Height="660"
        WindowStartupLocation="CenterScreen"
        Topmost="True"
        ShowInTaskbar="True"
        ResizeMode="NoResize"
        ShowActivated="True">
  <Border x:Name="Rama" Margin="20" CornerRadius="28" BorderThickness="2" BorderBrush="#9E80EB">
    <Border.Effect>
      <DropShadowEffect BlurRadius="24" ShadowDepth="0" Opacity="0.45" Color="#000000"/>
    </Border.Effect>
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0.68" EndPoint="1,0.32">
        <GradientStop Color="#E0CCF7" Offset="0"/>
        <GradientStop Color="#B880F7" Offset="0.5"/>
        <GradientStop Color="#73C2D6" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Grid Margin="28,16,28,24">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <Grid Grid.Row="0" Margin="0,0,0,8" MinHeight="148">
        <Border HorizontalAlignment="Left" VerticalAlignment="Top"
                BorderThickness="2" BorderBrush="#9E80EB" CornerRadius="12" Padding="10">
          <StackPanel>
            <TextBlock x:Name="EtichetaFundal" Text="Alege fundalul" FontSize="14.67"
                       Foreground="#0D0A17" Margin="0,0,0,6"/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
              </Grid.RowDefinitions>
              <RadioButton Grid.Row="0" Grid.Column="0" x:Name="RadioSolid" Content="Culoare solidă"
                           FontSize="16" VerticalAlignment="Center" Margin="0,0,10,8" Foreground="#0D0A17"/>
              <Button Grid.Row="0" Grid.Column="1" x:Name="EsantionSolid" Width="28" Height="18"
                      Cursor="Hand" BorderThickness="2" VerticalAlignment="Center" Margin="0,0,0,8"
                      ToolTip="Culoare">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4"/>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <RadioButton Grid.Row="1" Grid.Column="0" x:Name="RadioDegrade" Content="Degrade"
                           FontSize="16" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#0D0A17"/>
              <StackPanel Grid.Row="1" Grid.Column="1" x:Name="RandDegradeEsantioane"
                          Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="EsantionInceput" Width="28" Height="18" Cursor="Hand"
                        BorderThickness="0" Margin="0,0,8,0" ToolTip="Început">
                  <Button.Template>
                    <ControlTemplate TargetType="Button">
                      <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                              BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4"/>
                    </ControlTemplate>
                  </Button.Template>
                </Button>
                <Button x:Name="EsantionSfarsit" Width="28" Height="18" Cursor="Hand"
                        BorderThickness="0" ToolTip="Sfârșit">
                  <Button.Template>
                    <ControlTemplate TargetType="Button">
                      <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                              BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4"/>
                    </ControlTemplate>
                  </Button.Template>
                </Button>
              </StackPanel>
            </Grid>
          </StackPanel>
        </Border>
        <StackPanel HorizontalAlignment="Right" VerticalAlignment="Center" Orientation="Horizontal">
          <StackPanel VerticalAlignment="Center" Width="250" Margin="0,0,16,0">
            <TextBlock x:Name="DataZi" FontFamily="Segoe UI, Helvetica Neue, Arial"
                       FontSize="34.67" FontWeight="Medium" TextAlignment="Right" Foreground="#0D0A17"/>
            <TextBlock x:Name="DataLuna" FontFamily="Segoe UI, Helvetica Neue, Arial"
                       FontSize="45.33" FontWeight="SemiBold" TextAlignment="Right" Foreground="#0D0A17" Margin="0,2,0,2"/>
            <TextBlock x:Name="DataAn" FontFamily="Segoe UI, Helvetica Neue, Arial"
                       FontSize="34.67" FontWeight="Medium" TextAlignment="Right" Foreground="#0D0A17"/>
          </StackPanel>
          <Canvas x:Name="CeasAnalog" Width="132" Height="132" VerticalAlignment="Center"/>
        </StackPanel>
      </Grid>
      <StackPanel Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Stretch" Margin="8,0,8,0">
        <TextBlock x:Name="Titlu" FontSize="26.67" FontWeight="Bold"
                   TextAlignment="Center" TextWrapping="Wrap" Foreground="#0A0A0F"
                   HorizontalAlignment="Stretch" Margin="0,0,0,14"/>
        <TextBlock x:Name="Mesaj" FontSize="40" TextWrapping="Wrap"
                   TextAlignment="Center" Foreground="#0D0A17" HorizontalAlignment="Stretch"/>
      </StackPanel>
      <DockPanel Grid.Row="2" Margin="0,8,0,4" LastChildFill="False">
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
          <ComboBox x:Name="Interval" Width="150" Height="36" FontSize="21.33"
                    VerticalContentAlignment="Center" Margin="0,0,12,0"
                    Background="#E8D4F7" Foreground="#0D0A17" BorderBrush="#6B3DD1"/>
          <Button x:Name="ButonAmana" Content="Repetă în" Width="180" Height="56"
                  FontSize="26.67" FontWeight="Bold" Foreground="#331A66" Cursor="Hand">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="fundAmana" Background="#D1B8F7" CornerRadius="28"
                        BorderBrush="#6B3DD1" BorderThickness="1.5">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="fundAmana" Property="Background" Value="#C3A3F2"/>
                  </Trigger>
                  <Trigger Property="IsPressed" Value="True">
                    <Setter TargetName="fundAmana" Property="Background" Value="#B38EE8"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
        </StackPanel>
        <Button x:Name="Buton" Content="Am înțeles" Width="240" Height="56"
                FontSize="29.33" FontWeight="Bold" Foreground="White" Cursor="Hand"
                DockPanel.Dock="Right" HorizontalAlignment="Right" IsDefault="True">
          <Button.Template>
            <ControlTemplate TargetType="Button">
              <Border x:Name="fund" Background="#6B3DD1" CornerRadius="28">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter TargetName="fund" Property="Background" Value="#5720B8"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                  <Setter TargetName="fund" Property="Background" Value="#4A1C9A"/>
                </Trigger>
              </ControlTemplate.Triggers>
            </ControlTemplate>
          </Button.Template>
        </Button>
      </DockPanel>
    </Grid>
  </Border>
</Window>
"@

$script:design = Read-Design
$script:culoareAce = New-Object Windows.Media.SolidColorBrush (Get-MediaColor @(0.05, 0.04, 0.09))

try {
    do {
        Play-SunetReminder
        $script:design = Read-Design
        $window = [Windows.Markup.XamlReader]::Parse($xaml)
        $window.FindName('Titlu').Text = $titluMare
        $window.FindName('Mesaj').Text = $text
        Set-TextData $window
        $combo = $window.FindName('Interval')
        foreach ($m in 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60) {
            [void]$combo.Items.Add("$m min")
        }
        $combo.SelectedIndex = 1
        $script:actiune = 'ok'
        $script:minute = 0
        $script:liniste = $false
        Set-FundalDesign $window $script:design
        $timer = New-Object Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(1)
        $timer.Add_Tick({
            Update-CeasAnalog $window.FindName('CeasAnalog') $script:culoareAce
            Set-TextData $window
        })
        $window.Add_Closed({ $timer.Stop() })
        $timer.Start()
        $window.FindName('RadioSolid').Add_Checked({
            if ($script:liniste) { return }
            $script:design.mod = 'solid'
            Set-FundalDesign $window $script:design -Salveaza
        })
        $window.FindName('RadioDegrade').Add_Checked({
            if ($script:liniste) { return }
            $script:design.mod = 'degrade'
            Set-FundalDesign $window $script:design -Salveaza
        })
        $window.FindName('EsantionSolid').Add_Click({
            if ($script:design.mod -ne 'solid') {
                $script:design.mod = 'solid'
                Set-FundalDesign $window $script:design -Salveaza
            }
            $nou = Show-AlegeCuloare $window $script:design.solid
            if ($nou) {
                $script:design.solid = $nou
                Set-FundalDesign $window $script:design -Salveaza
            }
        })
        $window.FindName('EsantionInceput').Add_Click({
            if ($script:design.mod -ne 'degrade') {
                $script:design.mod = 'degrade'
                Set-FundalDesign $window $script:design -Salveaza
            }
            $nou = Show-AlegeCuloare $window $script:design.degrade_inceput
            if ($nou) {
                $script:design.degrade_inceput = $nou
                $script:design.degrade_personalizat = $true
                Set-FundalDesign $window $script:design -Salveaza
            }
        })
        $window.FindName('EsantionSfarsit').Add_Click({
            if ($script:design.mod -ne 'degrade') {
                $script:design.mod = 'degrade'
                Set-FundalDesign $window $script:design -Salveaza
            }
            $nou = Show-AlegeCuloare $window $script:design.degrade_sfarsit
            if ($nou) {
                $script:design.degrade_sfarsit = $nou
                $script:design.degrade_personalizat = $true
                Set-FundalDesign $window $script:design -Salveaza
            }
        })
        $window.FindName('ButonAmana').Add_Click({
            param($sender, $e)
            $idx = $window.FindName('Interval').SelectedIndex
            if ($idx -lt 0) { $idx = 0 }
            $n = ($idx + 1) * 5
            if ($n -lt 5 -or $n -gt 60) { $n = 5 }
            $script:actiune = 'amana'
            $script:minute = $n
            $window.Close()
        })
        $window.FindName('Buton').Add_Click({
            param($sender, $e)
            $script:actiune = 'ok'
            $window.Close()
        })
        $window.Add_KeyDown({
            param($sender, $e)
            if ($e.Key -eq 'Return' -or $e.Key -eq 'Enter') {
                $script:actiune = 'ok'
                $window.Close()
            }
        })
        [void]$window.Dispatcher.Invoke({ $window.Activate() })
        [void]$window.ShowDialog()
        $timer.Stop()
        if ($script:actiune -eq 'amana' -and $script:minute -ge 5) {
            Write-Jurnal "$Identificator amana $($script:minute) min"
            Start-Sleep -Seconds ($script:minute * 60)
        } else {
            Write-Jurnal "$Identificator ok"
            break
        }
    } while ($true)
} catch {
    Write-Jurnal "$Identificator eroare=$($_.Exception.Message)"
    if ($_.Exception.Message -match 'xaml') {
        [System.Windows.MessageBox]::Show("Nu am putut deschide fereastra: $($_.Exception.Message)", 'Reminder') | Out-Null
        exit 1
    }
    throw
}
