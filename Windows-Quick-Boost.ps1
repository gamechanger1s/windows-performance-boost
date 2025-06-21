<#
  WinQuickBoost – v2.3  •  June 2025
  Deep-clean, tune, benchmark, and show a user-friendly report.
  ✨  Script forged by *Chinmay* to keep your system blazing-fast, always. 🚀
#>

# ── 0.  Setup & logging ───────────────────────────────────────────────────────
$Stamp   = (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
$WorkDir = Join-Path $Env:PUBLIC "WinQuickBoost-$Stamp"
New-Item $WorkDir -ItemType Directory -Force | Out-Null
$Log     = "$WorkDir\Action.log"
$Report  = "$WorkDir\Benchmark.json"

Function Write-Log { param([string]$Msg)
    "[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date),$Msg | Add-Content $Log
}

#  Admin-rights guard (robust, single line) ───────────────────────────────────
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) { Write-Error 'Run this script **as Administrator**!' ; exit 1 }

Write-Log '===== WinQuickBoost session started ====='

# ── 1.  Metric helpers ───────────────────────────────────────────────────────
Function Get-AvgCpu {
    $c = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 10
    [math]::Round(($c.CounterSamples | Measure CookedValue -Average).Average,2)
}
Function Get-Metrics {
    $os = Get-CimInstance Win32_OperatingSystem
    [pscustomobject]@{
        DiskGB  = [math]::Round((Get-PSDrive -PSProvider FileSystem | Measure Free -Sum).Sum/1GB,2)
        RAMGB   = [math]::Round($os.FreePhysicalMemory/1MB,2)
        CPU     = Get-AvgCpu
        Proc    = (Get-Process).Count
        Service = (Get-Service | Where Status -eq Running).Count
    }
}

# ── 2.  Progress helper ──────────────────────────────────────────────────────
$TotalSteps = 10; $Step = 0
Function Tick($Msg){
    $Global:Step++
    Write-Progress -Activity 'WinQuickBoost working…' -Status $Msg `
        -PercentComplete ([int](($Step-1)/$TotalSteps*100))
    Write-Log $Msg
}

# ── 3.  Baseline ─────────────────────────────────────────────────────────────
Tick 'Benchmarking (before)'
$Before = Get-Metrics
Write-Log "Before:`n$($Before | ConvertTo-Json)"

# ── 4.  Optimisations ────────────────────────────────────────────────────────
Try {
    Tick 'Deep-clean temp'
    @("$env:TEMP\*","$env:WINDIR\Temp\*","$env:SystemRoot\Prefetch\*") |
        ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }

    Tick 'Purge Windows-Update cache'
    Stop-Service wuauserv,bits -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -EA SilentlyContinue
    Start-Service wuauserv,bits -EA SilentlyContinue

    Tick 'Tune services & flush DNS'
    If (Get-PhysicalDisk | Where MediaType -eq SSD) {
        Stop-Service SysMain -Force -EA SilentlyContinue
        Set-Service  SysMain -StartupType Disabled
    }
    'bthserv','Spooler','TabletInputService' | ForEach-Object {
        Try { Set-Service $_ -StartupType Manual } Catch{}
    }
    ipconfig /flushdns | Out-Null

    Tick 'Disable hibernation & tweak timeouts'
    powercfg /h off | Out-Null
    $desk = 'HKCU:\Control Panel\Desktop'
    @{HungAppTimeout='2000';WaitToKillAppTimeout='2000';AutoEndTasks='1'}.GetEnumerator() |
        ForEach-Object { New-ItemProperty $desk -Name $_.Key -Value $_.Value -Type String -Force | Out-Null }

    Tick 'Set Best-Performance visuals'
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
        /v VisualFXSetting /t REG_DWORD /d 2 /f >$null

    Tick 'Silent Disk Cleanup'
    cleanmgr /sagerun:1 | Out-Null

    Tick 'Filesystem scan'
    If ((chkdsk $env:SystemDrive | Select-String 'no problems').Count -eq 0) {
        schtasks /Create /TN WinQuickBoost-Chkdsk /TR "chkdsk $env:SystemDrive /F /R" `
            /SC ONSTART /RL HIGHEST /F >$null
    }

    Tick 'Activate High-Perf power plan'
    $HP = (powercfg -L | Select-String 'High performance' | ForEach-Object {($_ -split '\s+')[3]})
    If (-not $HP) { $HP = powercfg -duplicatescheme SCHEME_MIN }
    powercfg -setactive $HP
}
Catch { Write-Log "ERROR: $_" }

# ── 5.  Post metrics ─────────────────────────────────────────────────────────
Tick 'Benchmarking (after)'
$After = Get-Metrics
Write-Log "After:`n$($After | ConvertTo-Json)"
[pscustomobject]@{Before=$Before;After=$After} | ConvertTo-Json -Depth 3 | Out-File $Report -Encoding UTF8
Write-Progress -Activity WinQuickBoost -Completed
Start-Sleep 1
Clear-Host

# ── 6.  Friendly report ──────────────────────────────────────────────────────
$Info = @(
    @{Key='DiskGB';  Name='Free Disk Space (GB)';   Desc='How much storage is free';   Up=$true },
    @{Key='RAMGB';   Name='Free RAM (GB)';          Desc='Idle physical memory';       Up=$true },
    @{Key='CPU';     Name='Average CPU Load (%)';   Desc='10-sec CPU usage';           Up=$false},
    @{Key='Proc';    Name='Running Processes';      Desc='Apps & background tasks';    Up=$false},
    @{Key='Service'; Name='Running Services';       Desc='Windows services alive';     Up=$false}
)
Function Verdict($Up,$Δ){
    If     ($Δ -eq 0) { '⚪','No change' }
    ElseIf (($Up -and $Δ -gt 0) -or (-not $Up -and $Δ -lt 0)){ '✅','Improved' }
    Else               { '⚠️','Slightly worse' }
}

$Bullets = @()
$Rows    = foreach($row in $Info){
    $B=[double]$Before.$($row.Key); $A=[double]$After.$($row.Key); $Δ=[math]::Round($A-$B,2)
    $Sym,$Txt = Verdict $row.Up $Δ
    If ($row.Key -eq 'DiskGB' -and $Δ -gt 0){ $Bullets += "gained $Δ GB disk" }
    If ($row.Key -eq 'CPU'    -and $Δ -lt 0){ $Bullets += "lowered CPU load"  }
    [pscustomobject]@{Win=$Sym;Metric=$row.Name;Measure=$row.Desc;Change=("{0:+0.##;-0.##;0}" -f $Δ);Result=$Txt}
}

$Line = '='*98
Write-Host ''
Write-Host $Line -Foreground Cyan
Write-Host '📊  WINQUICKBOOST PERFORMANCE REPORT  📊' -Foreground Cyan
Write-Host $Line -Foreground Cyan
Write-Host ('{0,-3} {1,-25} {2,-38} {3,10} {4}' -f '','Metric','What it measures','Change','Result') -Foreground Cyan
Write-Host ('-'*98) -Foreground Cyan
$Rows | ForEach-Object {
    '{0,-3} {1,-25} {2,-38} {3,10} {4}' -f $_.Win,$_.Metric,$_.Measure,$_.Change,$_.Result | Write-Host
}
Write-Host $Line -Foreground Cyan
If ($Bullets) { Write-Host ('TL;DR  →  ' + ($Bullets -join ', ') + '.') -Foreground Green }
Else          { Write-Host 'TL;DR  →  Nothing major changed.' -Foreground Yellow }

Write-Host ''
Write-Host '✨  Script forged by *Chinmay* to keep your system blazing-fast, always.🚀' -Foreground Yellow