
# ============================================================
# SIXONE SETTINGV1
# MAX PERFORMANCE GAMING OPTIMIZER
# ============================================================

Set-ExecutionPolicy Unrestricted -Scope Process -Force

# ============================================================
# ADMINISTRATOR
# ============================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdmin = $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {

    try {

        $PowerShellPath = (Get-Command powershell.exe).Source

        $Arguments = @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            "`"$PSCommandPath`""
        )

        Start-Process `
            -FilePath $PowerShellPath `
            -ArgumentList $Arguments `
            -Verb RunAs

        exit
    }
    catch {

        Add-Type -AssemblyName System.Windows.Forms

        [System.Windows.Forms.MessageBox]::Show(
            "SIXONE ต้องการสิทธิ์ Administrator",
            "SIXONE MAX",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        exit
    }
}

# ============================================================
# ASSEMBLIES
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# COLORS
# ============================================================

$BG_MAIN = [System.Drawing.Color]::FromArgb(8, 7, 13)
$BG_CARD = [System.Drawing.Color]::FromArgb(17, 14, 26)
$BG_CONSOLE = [System.Drawing.Color]::FromArgb(10, 9, 16)

$PURPLE = [System.Drawing.Color]::FromArgb(168, 85, 247)
$PURPLE_DARK = [System.Drawing.Color]::FromArgb(126, 34, 206)

$GREEN = [System.Drawing.Color]::FromArgb(34, 197, 94)
$RED = [System.Drawing.Color]::FromArgb(239, 68, 68)

$WHITE = [System.Drawing.Color]::FromArgb(243, 244, 246)
$MUTED = [System.Drawing.Color]::FromArgb(156, 163, 175)

# ============================================================
# FORM
# ============================================================

$form = New-Object System.Windows.Forms.Form

$form.Text = "SIXONE SETTINGV1 // MAX PERFORMANCE"

$form.Size = New-Object System.Drawing.Size(
    1050,
    680
)

$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"

$form.MaximizeBox = $false
$form.BackColor = $BG_MAIN
$form.ForeColor = $WHITE

# ============================================================
# HEADER
# ============================================================

$lblTitle = New-Object System.Windows.Forms.Label

$lblTitle.Text = "SIXONE"

$lblTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    21,
    [System.Drawing.FontStyle]::Bold
)

$lblTitle.ForeColor = $PURPLE

$lblTitle.Location = New-Object System.Drawing.Point(
    22,
    15
)

$lblTitle.AutoSize = $true

$form.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label

$lblSubtitle.Text = "MAX PERFORMANCE // CPU + FPS OPTIMIZER"

$lblSubtitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9
)

$lblSubtitle.ForeColor = $MUTED

$lblSubtitle.Location = New-Object System.Drawing.Point(
    25,
    53
)

$lblSubtitle.AutoSize = $true

$form.Controls.Add($lblSubtitle)

# ============================================================
# LEFT STATUS PANEL
# ============================================================

$pnlStatus = New-Object System.Windows.Forms.Panel

$pnlStatus.Location = New-Object System.Drawing.Point(
    20,
    85
)

$pnlStatus.Size = New-Object System.Drawing.Size(
    330,
    485
)

$pnlStatus.BackColor = $BG_CARD

$form.Controls.Add($pnlStatus)

$lblStatusHeader = New-Object System.Windows.Forms.Label

$lblStatusHeader.Text = "OPTIMIZATION STATUS"

$lblStatusHeader.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    11,
    [System.Drawing.FontStyle]::Bold
)

$lblStatusHeader.ForeColor = $PURPLE

$lblStatusHeader.Location = New-Object System.Drawing.Point(
    18,
    15
)

$lblStatusHeader.AutoSize = $true

$pnlStatus.Controls.Add($lblStatusHeader)

# ============================================================
# STATUS ITEMS
# ============================================================

$StatusLabels = @{}

function Add-StatusItem {

    param(
        [string]$Key,
        [string]$Text,
        [int]$Y
    )

    $label = New-Object System.Windows.Forms.Label

    $label.Text = "○  $Text"

    $label.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        8.5
    )

    $label.ForeColor = $MUTED

    $label.Location = New-Object System.Drawing.Point(
        18,
        $Y
    )

    $label.Size = New-Object System.Drawing.Size(
        295,
        26
    )

    $pnlStatus.Controls.Add($label)

    $StatusLabels[$Key] = $label
}

Add-StatusItem "GameMode"     "Game Mode"                       52
Add-StatusItem "GPU"          "Hardware GPU Scheduling"        78
Add-StatusItem "Power"        "High Performance Power"         104
Add-StatusItem "Visual"       "Visual Effects Reduced"         130
Add-StatusItem "Background"   "Background Apps Reduced"        156
Add-StatusItem "Capture"      "Game DVR Disabled"              182
Add-StatusItem "Startup"      "Startup Apps Reduced"            208
Add-StatusItem "Input"        "Mouse / Keyboard Optimized"      234
Add-StatusItem "Network"      "Network Tweaks"                  260
Add-StatusItem "MMCSS"        "Game Process Priority"            286
Add-StatusItem "Temp"         "Temporary Files Cleaned"         312
Add-StatusItem "Shader"       "Shader Cache Cleaned"            338
Add-StatusItem "Explorer"     "Explorer Effects Reduced"        364
Add-StatusItem "Tasks"        "Background Tasks Reduced"        390
Add-StatusItem "CPU"          "CPU Process Cleanup"              416
Add-StatusItem "Memory"       "Memory Working Set Cleanup"       442

# ============================================================
# STATUS UPDATE
# ============================================================

function Set-Status {

    param(
        [string]$Key,
        [bool]$Success
    )

    if (-not $StatusLabels.ContainsKey($Key)) {
        return
    }

    $text =
        $StatusLabels[$Key].Text -replace "^[○✓]\s+", ""

    if ($Success) {

        $StatusLabels[$Key].Text =
            "✓  $text"

        $StatusLabels[$Key].ForeColor = $GREEN
    }
    else {

        $StatusLabels[$Key].Text =
            "○  $text"

        $StatusLabels[$Key].ForeColor = $MUTED
    }

    [System.Windows.Forms.Application]::DoEvents()
}

# ============================================================
# LOG PANEL
# ============================================================

$pnlLogs = New-Object System.Windows.Forms.Panel

$pnlLogs.Location = New-Object System.Drawing.Point(
    370,
    85
)

$pnlLogs.Size = New-Object System.Drawing.Size(
    655,
    485
)

$pnlLogs.BackColor = $BG_CONSOLE

$form.Controls.Add($pnlLogs)

$lblLogHeader = New-Object System.Windows.Forms.Label

$lblLogHeader.Text = "MAX OPTIMIZATION CONSOLE"

$lblLogHeader.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

$lblLogHeader.ForeColor = $PURPLE

$lblLogHeader.Location = New-Object System.Drawing.Point(
    15,
    12
)

$lblLogHeader.AutoSize = $true

$pnlLogs.Controls.Add($lblLogHeader)

$txtLogs = New-Object System.Windows.Forms.TextBox

$txtLogs.Location = New-Object System.Drawing.Point(
    15,
    42
)

$txtLogs.Size = New-Object System.Drawing.Size(
    625,
    425
)

$txtLogs.Multiline = $true
$txtLogs.ReadOnly = $true
$txtLogs.ScrollBars = "Vertical"

$txtLogs.BackColor = $BG_CONSOLE

$txtLogs.ForeColor =
    [System.Drawing.Color]::FromArgb(
        216,
        180,
        254
    )

$txtLogs.BorderStyle = "None"

$txtLogs.Font = New-Object System.Drawing.Font(
    "Consolas",
    9
)

$pnlLogs.Controls.Add($txtLogs)

# ============================================================
# BOTTOM PANEL
# ============================================================

$pnlBottom = New-Object System.Windows.Forms.Panel

$pnlBottom.Location = New-Object System.Drawing.Point(
    20,
    585
)

$pnlBottom.Size = New-Object System.Drawing.Size(
    1005,
    55
)

$pnlBottom.BackColor = $BG_CARD

$form.Controls.Add($pnlBottom)

# ============================================================
# STATUS
# ============================================================

$lblStatus = New-Object System.Windows.Forms.Label

$lblStatus.Text = "READY FOR MAX PERFORMANCE"

$lblStatus.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    9,
    [System.Drawing.FontStyle]::Bold
)

$lblStatus.ForeColor = $WHITE

$lblStatus.Location = New-Object System.Drawing.Point(
    15,
    16
)

$lblStatus.Size = New-Object System.Drawing.Size(
    370,
    25
)

$pnlBottom.Controls.Add($lblStatus)

# ============================================================
# PROGRESS
# ============================================================

$progress = New-Object System.Windows.Forms.ProgressBar

$progress.Location = New-Object System.Drawing.Point(
    390,
    20
)

$progress.Size = New-Object System.Drawing.Size(
    300,
    18
)

$progress.Minimum = 0
$progress.Maximum = 100

$pnlBottom.Controls.Add($progress)

# ============================================================
# MAX BUTTON
# ============================================================

$btnOptimize = New-Object System.Windows.Forms.Button

$btnOptimize.Text = "⚡  MAX OPTIMIZE"

$btnOptimize.Location = New-Object System.Drawing.Point(
    710,
    8
)

$btnOptimize.Size = New-Object System.Drawing.Size(
    280,
    40
)

$btnOptimize.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

$btnOptimize.BackColor = $PURPLE_DARK
$btnOptimize.ForeColor = $WHITE

$btnOptimize.FlatStyle = "Flat"

$btnOptimize.FlatAppearance.BorderSize = 1
$btnOptimize.FlatAppearance.BorderColor = $PURPLE

$btnOptimize.Cursor =
    [System.Windows.Forms.Cursors]::Hand

$pnlBottom.Controls.Add($btnOptimize)

# ============================================================
# LOG
# ============================================================

function Append-Log {

    param(
        [string]$Text
    )

    $time = Get-Date -Format "HH:mm:ss"

    $txtLogs.AppendText(
        "[$time] > $Text`r`n"
    )

    $txtLogs.SelectionStart =
        $txtLogs.Text.Length

    $txtLogs.ScrollToCaret()

    [System.Windows.Forms.Application]::DoEvents()
}

# ============================================================
# REGISTRY HELPERS
# ============================================================

function Set-RegDWORD {

    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    try {

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        Set-ItemProperty `
            -Path $Path `
            -Name $Name `
            -Value $Value `
            -Type DWord `
            -Force `
            -ErrorAction Stop

        return $true
    }
    catch {

        Append-Log "[WARN] Registry: $Name"

        return $false
    }
}

function Set-RegString {

    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    try {

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        Set-ItemProperty `
            -Path $Path `
            -Name $Name `
            -Value $Value `
            -Type String `
            -Force `
            -ErrorAction Stop

        return $true
    }
    catch {

        return $false
    }
}

# ============================================================
# 1. GAME MODE
# ============================================================

function Optimize-GameMode {

    $path =
        "HKCU:\Software\Microsoft\GameBar"

    $a = Set-RegDWORD `
        $path `
        "AllowAutoGameMode" `
        1

    $b = Set-RegDWORD `
        $path `
        "AutoGameModeEnabled" `
        1

    return ($a -and $b)
}

# ============================================================
# 2. GPU SCHEDULING
# ============================================================

function Optimize-GPU {

    $path =
        "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

    return Set-RegDWORD `
        $path `
        "HwSchMode" `
        2
}

# ============================================================
# 3. POWER
# ============================================================

function Optimize-Power {

    try {

        powercfg /SETACTIVE SCHEME_MIN 2>$null

        if ($LASTEXITCODE -eq 0) {
            return $true
        }

        $guid = (powercfg -getactivescheme |
            Select-String `
                -Pattern "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
        ).Matches.Value

        if ($guid) {

            powercfg /S $guid | Out-Null
            return $true
        }

        return $false
    }
    catch {

        return $false
    }
}

# ============================================================
# 4. VISUAL EFFECTS
# ============================================================

function Optimize-VisualEffects {

    $ok = $true

    $path =
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"

    if (-not (Set-RegDWORD `
        $path `
        "VisualFXSetting" `
        2)) {

        $ok = $false
    }

    $desktop =
        "HKCU:\Control Panel\Desktop"

    Set-RegString `
        $desktop `
        "MenuShowDelay" `
        "0" | Out-Null

    Set-RegString `
        $desktop `
        "DragFullWindows" `
        "0" | Out-Null

    return $ok
}

# ============================================================
# 5. BACKGROUND APPS
# ============================================================

function Optimize-BackgroundApps {

    $path =
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"

    return Set-RegDWORD `
        $path `
        "GlobalUserDisabled" `
        1
}

# ============================================================
# 6. GAME DVR
# ============================================================

function Optimize-Capture {

    $ok = $true

    $gameDVR =
        "HKCU:\System\GameConfigStore"

    $gameBar =
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"

    if (-not (Set-RegDWORD `
        $gameDVR `
        "GameDVR_Enabled" `
        0)) {

        $ok = $false
    }

    if (-not (Set-RegDWORD `
        $gameDVR `
        "AppCaptureEnabled" `
        0)) {

        $ok = $false
    }

    Set-RegDWORD `
        $gameBar `
        "AppCaptureEnabled" `
        0 | Out-Null

    Set-RegDWORD `
        $gameBar `
        "HistoricalCaptureEnabled" `
        0 | Out-Null

    return $ok
}

# ============================================================
# 7. STARTUP
# ============================================================

function Optimize-Startup {

    $path =
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

    $targets = @(
        "OneDrive",
        "MicrosoftEdgeAutoLaunch",
        "Teams",
        "com.squirrel.Teams.Teams"
    )

    foreach ($target in $targets) {

        try {

            Remove-ItemProperty `
                -Path $path `
                -Name $target `
                -ErrorAction SilentlyContinue
        }
        catch {
        }
    }

    return $true
}

# ============================================================
# 8. INPUT
# ============================================================

function Optimize-Input {

    $mouse =
        "HKCU:\Control Panel\Mouse"

    $keyboard =
        "HKCU:\Control Panel\Keyboard"

    $ok = $true

    if (-not (Set-RegString `
        $mouse `
        "MouseSpeed" `
        "0")) {

        $ok = $false
    }

    Set-RegString `
        $mouse `
        "MouseThreshold1" `
        "0" | Out-Null

    Set-RegString `
        $mouse `
        "MouseThreshold2" `
        "0" | Out-Null

    Set-RegString `
        $keyboard `
        "KeyboardDelay" `
        "0" | Out-Null

    Set-RegString `
        $keyboard `
        "KeyboardSpeed" `
        "31" | Out-Null

    return $ok
}

# ============================================================
# 9. NETWORK
# ============================================================

function Optimize-Network {

    $profile =
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

    $ok = $true

    if (-not (Set-RegDWORD `
        $profile `
        "SystemResponsiveness" `
        0)) {

        $ok = $false
    }

    try {

        Set-ItemProperty `
            -Path $profile `
            -Name "NetworkThrottlingIndex" `
            -Value ([uint32]0xFFFFFFFF) `
            -Type DWord `
            -Force `
            -ErrorAction Stop
    }
    catch {

        $ok = $false
    }

    try {

        $interfaces =
            Get-ChildItem `
                "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" `
                -ErrorAction Stop

        foreach ($interface in $interfaces) {

            Set-RegDWORD `
                $interface.PSPath `
                "TcpAckFrequency" `
                1 | Out-Null

            Set-RegDWORD `
                $interface.PSPath `
                "TCPNoDelay" `
                1 | Out-Null
        }
    }
    catch {
    }

    return $ok
}

# ============================================================
# 10. GAME PRIORITY
# ============================================================

function Optimize-MMCSS {

    $path =
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"

    $ok = $true

    if (-not (Set-RegDWORD `
        $path `
        "GPU Priority" `
        8)) {

        $ok = $false
    }

    if (-not (Set-RegDWORD `
        $path `
        "Priority" `
        6)) {

        $ok = $false
    }

    Set-RegString `
        $path `
        "Scheduling Category" `
        "High" | Out-Null

    Set-RegString `
        $path `
        "SFIO Priority" `
        "High" | Out-Null

    return $ok
}

# ============================================================
# 11. TEMP CLEAN
# ============================================================

function Clean-Temp {

    try {

        Get-ChildItem `
            -LiteralPath $env:TEMP `
            -Force `
            -ErrorAction SilentlyContinue |
            Remove-Item `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue

        Get-ChildItem `
            -LiteralPath "$env:WINDIR\Temp" `
            -Force `
            -ErrorAction SilentlyContinue |
            Remove-Item `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue

        Clear-DnsClientCache `
            -ErrorAction SilentlyContinue

        return $true
    }
    catch {

        return $false
    }
}

# ============================================================
# 12. SHADER CACHE
# ============================================================

function Clean-Shaders {

    $paths = @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\NVIDIA\GLCache",
        "$env:LOCALAPPDATA\AMD\DxCache"
    )

    foreach ($path in $paths) {

        if (Test-Path $path) {

            try {

                Get-ChildItem `
                    -Path $path `
                    -Force `
                    -ErrorAction SilentlyContinue |
                    Remove-Item `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
            }
            catch {
            }
        }
    }

    return $true
}

# ============================================================
# 13. EXPLORER
# ============================================================

function Optimize-Explorer {

    $path =
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    Set-RegDWORD `
        $path `
        "TaskbarAnimations" `
        0 | Out-Null

    Set-RegDWORD `
        $path `
        "ListviewAlphaSelect" `
        0 | Out-Null

    Set-RegDWORD `
        $path `
        "ListviewShadow" `
        0 | Out-Null

    return $true
}

# ============================================================
# 14. BACKGROUND TASKS
# ============================================================

function Optimize-Tasks {

    $tasks = @(
        @(
            "\Microsoft\Windows\Customer Experience Improvement Program",
            "Consolidator"
        ),
        @(
            "\Microsoft\Windows\Customer Experience Improvement Program",
            "UsbCeip"
        ),
        @(
            "\Microsoft\Windows\Feedback\Siuf",
            "DmClient"
        ),
        @(
            "\Microsoft\Windows\Feedback\Siuf",
            "DmClientOnScenarioDownload"
        )
    )

    foreach ($task in $tasks) {

        try {

            Disable-ScheduledTask `
                -TaskPath $task[0] `
                -TaskName $task[1] `
                -ErrorAction SilentlyContinue |
                Out-Null
        }
        catch {
        }
    }

    return $true
}

# ============================================================
# 15. CPU PROCESS CLEANUP
# ============================================================

function Optimize-CPUProcesses {

    # --------------------------------------------------------
    # IMPORTANT
    #
    # These are user applications / optional background apps.
    # Core Windows processes are intentionally NOT touched.
    # --------------------------------------------------------

    $targets = @(
        "OneDrive",
        "Teams",
        "ms-teams",
        "MicrosoftTeams",
        "Widgets",
        "WidgetService",
        "PhoneExperienceHost",
        "YourPhone",
        "GameBar",
        "XboxPcApp",
        "XboxApp",
        "Spotify",
        "Discord",
        "AdobeCollabSync",
        "AdobeIPCBroker",
        "steamwebhelper"
    )

    $stopped = 0

    foreach ($name in $targets) {

        try {

            $processes =
                Get-Process `
                    -Name $name `
                    -ErrorAction SilentlyContinue

            foreach ($process in $processes) {

                # Never stop this script itself.
                if ($process.Id -eq $PID) {
                    continue
                }

                try {

                    Stop-Process `
                        -Id $process.Id `
                        -Force `
                        -ErrorAction SilentlyContinue

                    $stopped++
                }
                catch {
                }
            }
        }
        catch {
        }
    }

    Append-Log "[CPU] Closed $stopped optional background processes"

    return $true
}

# ============================================================
# 16. MEMORY WORKING SET
# ============================================================

function Optimize-Memory {

    try {

        $targets = @(
            "OneDrive",
            "Teams",
            "ms-teams",
            "MicrosoftTeams",
            "Widgets",
            "PhoneExperienceHost",
            "YourPhone",
            "Spotify",
            "Discord"
        )

        foreach ($name in $targets) {

            $processes =
                Get-Process `
                    -Name $name `
                    -ErrorAction SilentlyContinue

            foreach ($process in $processes) {

                try {

                    $process.Refresh()

                    # Trim only non-critical user applications.
                    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class WorkingSetCleaner
{
    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@ -ErrorAction SilentlyContinue

                    [WorkingSetCleaner]::EmptyWorkingSet(
                        $process.Handle
                    ) | Out-Null
                }
                catch {
                }
            }
        }

        return $true
    }
    catch {

        return $false
    }
}

# ============================================================
# MAX OPTIMIZATION
# ============================================================

$btnOptimize.Add_Click({

    $btnOptimize.Enabled = $false

    $progress.Value = 0

    $lblStatus.Text =
        "MAX PERFORMANCE OPTIMIZATION..."

    $lblStatus.ForeColor = $PURPLE

    Append-Log ""
    Append-Log "============================================================"
    Append-Log "SIXONE MAX PERFORMANCE ENGINE"
    Append-Log "============================================================"
    Append-Log "Starting maximum safe gaming optimization..."
    Append-Log ""

    # ========================================================
    # 1
    # ========================================================

    Append-Log "[01/16] Enabling Game Mode..."

    if (Optimize-GameMode) {

        Set-Status "GameMode" $true
        Append-Log "[OK] Game Mode enabled"
    }

    $progress.Value = 6

    # ========================================================
    # 2
    # ========================================================

    Append-Log "[02/16] Configuring Hardware GPU Scheduling..."

    if (Optimize-GPU) {

        Set-Status "GPU" $true
        Append-Log "[OK] GPU scheduling configured"
    }

    $progress.Value = 12

    # ========================================================
    # 3
    # ========================================================

    Append-Log "[03/16] Activating High Performance power profile..."

    if (Optimize-Power) {

        Set-Status "Power" $true
        Append-Log "[OK] Performance power profile"
    }

    $progress.Value = 18

    # ========================================================
    # 4
    # ========================================================

    Append-Log "[04/16] Reducing Windows visual overhead..."

    if (Optimize-VisualEffects) {

        Set-Status "Visual" $true
        Append-Log "[OK] Visual effects reduced"
    }

    $progress.Value = 24

    # ========================================================
    # 5
    # ========================================================

    Append-Log "[05/16] Disabling unnecessary background app activity..."

    if (Optimize-BackgroundApps) {

        Set-Status "Background" $true
        Append-Log "[OK] Background apps reduced"
    }

    $progress.Value = 30

    # ========================================================
    # 6
    # ========================================================

    Append-Log "[06/16] Disabling Game DVR / background capture..."

    if (Optimize-Capture) {

        Set-Status "Capture" $true
        Append-Log "[OK] Game DVR disabled"
    }

    $progress.Value = 36

    # ========================================================
    # 7
    # ========================================================

    Append-Log "[07/16] Reducing startup applications..."

    if (Optimize-Startup) {

        Set-Status "Startup" $true
        Append-Log "[OK] Startup reduced"
    }

    $progress.Value = 42

    # ========================================================
    # 8
    # ========================================================

    Append-Log "[08/16] Optimizing mouse and keyboard response..."

    if (Optimize-Input) {

        Set-Status "Input" $true
        Append-Log "[OK] Input optimized"
    }

    $progress.Value = 48

    # ========================================================
    # 9
    # ========================================================

    Append-Log "[09/16] Optimizing network stack..."

    if (Optimize-Network) {

        Set-Status "Network" $true
        Append-Log "[OK] Network optimized"
    }

    $progress.Value = 54

    # ========================================================
    # 10
    # ========================================================

    Append-Log "[10/16] Configuring game process priority..."

    if (Optimize-MMCSS) {

        Set-Status "MMCSS" $true
        Append-Log "[OK] Game priority configured"
    }

    $progress.Value = 60

    # ========================================================
    # 11
    # ========================================================

    Append-Log "[11/16] Cleaning temporary files..."

    if (Clean-Temp) {

        Set-Status "Temp" $true
        Append-Log "[OK] Temporary files cleaned"
    }

    $progress.Value = 66

    # ========================================================
    # 12
    # ========================================================

    Append-Log "[12/16] Cleaning old graphics shader cache..."

    if (Clean-Shaders) {

        Set-Status "Shader" $true
        Append-Log "[OK] Shader cache cleaned"
    }

    $progress.Value = 72

    # ========================================================
    # 13
    # ========================================================

    Append-Log "[13/16] Reducing Explorer overhead..."

    if (Optimize-Explorer) {

        Set-Status "Explorer" $true
        Append-Log "[OK] Explorer effects reduced"
    }

    $progress.Value = 78

    # ========================================================
    # 14
    # ========================================================

    Append-Log "[14/16] Reducing consumer background tasks..."

    if (Optimize-Tasks) {

        Set-Status "Tasks" $true
        Append-Log "[OK] Background tasks reduced"
    }

    $progress.Value = 84

    # ========================================================
    # 15
    # ========================================================

    Append-Log "[15/16] Closing optional CPU background processes..."

    if (Optimize-CPUProcesses) {

        Set-Status "CPU" $true
        Append-Log "[OK] Optional CPU processes cleaned"
    }

    $progress.Value = 92

    # ========================================================
    # 16
    # ========================================================

    Append-Log "[16/16] Cleaning unused working memory..."

    if (Optimize-Memory) {

        Set-Status "Memory" $true
        Append-Log "[OK] User application working sets cleaned"
    }

    $progress.Value = 100

    # ========================================================
    # COMPLETE
    # ========================================================

    $lblStatus.Text =
        "✓ MAX PERFORMANCE ACTIVE"

    $lblStatus.ForeColor = $GREEN

    Append-Log ""
    Append-Log "============================================================"
    Append-Log "MAX PERFORMANCE OPTIMIZATION COMPLETED"
    Append-Log "============================================================"
    Append-Log "CPU background workload reduced."
    Append-Log "Non-essential user applications cleaned."
    Append-Log "Gaming profile configured."
    Append-Log "Restart Windows for changes requiring reboot."
    Append-Log "============================================================"

    $btnOptimize.Enabled = $true
})

# ============================================================
# INITIAL MESSAGE
# ============================================================

$form.Add_Shown({

    Append-Log "SIXONE MAX ENGINE INITIALIZED."
    Append-Log "Administrator: ACTIVE"
    Append-Log "Mode: MAX PERFORMANCE"
    Append-Log ""
    Append-Log "Ready to optimize CPU / RAM / GPU / Network."
})

# ============================================================
# SHOW
# ============================================================

[void]$form.ShowDialog()

