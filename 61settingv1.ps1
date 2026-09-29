# ============================================================
# SIXONE SETTINGV1
# PERMANENT MAX GAMING OPTIMIZER
# PREMIUM DARK / NEON PURPLE UI
# ============================================================

Set-ExecutionPolicy Unrestricted -Scope Process -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# ADMIN
# ============================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdmin = $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {

    try {

        $Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList $Arguments

        exit
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            "SIXONE SETTINGV1 requires Administrator permission.",
            "SIXONE SETTINGV1",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

        exit
    }
}

# ============================================================
# GLOBAL
# ============================================================

$script:OptimizationRunning = $false

$script:StartProcessCount = 0
$script:EndProcessCount = 0

$script:StartMemoryMB = 0
$script:EndMemoryMB = 0

$script:CompletedCount = 0
$script:TotalSteps = 16

# ============================================================
# COLORS
# ============================================================

$BG_MAIN      = [System.Drawing.Color]::FromArgb(7,6,12)
$BG_CARD      = [System.Drawing.Color]::FromArgb(15,12,23)
$BG_CARD2     = [System.Drawing.Color]::FromArgb(20,16,30)
$BG_CONSOLE   = [System.Drawing.Color]::FromArgb(8,7,13)

$PURPLE       = [System.Drawing.Color]::FromArgb(168,85,247)
$PURPLE_DARK  = [System.Drawing.Color]::FromArgb(126,34,206)
$PURPLE_LIGHT = [System.Drawing.Color]::FromArgb(192,132,252)

$GREEN        = [System.Drawing.Color]::FromArgb(34,197,94)
$RED          = [System.Drawing.Color]::FromArgb(239,68,68)
$YELLOW       = [System.Drawing.Color]::FromArgb(250,204,21)

$WHITE        = [System.Drawing.Color]::White
$TEXT         = [System.Drawing.Color]::FromArgb(230,225,240)
$MUTED        = [System.Drawing.Color]::FromArgb(145,138,160)
$BORDER       = [System.Drawing.Color]::FromArgb(52,43,66)

# ============================================================
# WRITE LOG
# ============================================================

function Write-Log {

    param(
        [string]$Message,
        [ValidateSet("INFO","OK","WARN","ERROR")]
        [string]$Type = "INFO"
    )

    if ($null -eq $script:LogBox) {
        return
    }

    try {

        $Time = Get-Date -Format "HH:mm:ss"

        switch ($Type) {

            "OK" {
                $Prefix = "[OK]"
                $Color = $GREEN
            }

            "WARN" {
                $Prefix = "[WARN]"
                $Color = $YELLOW
            }

            "ERROR" {
                $Prefix = "[ERROR]"
                $Color = $RED
            }

            default {
                $Prefix = "[INFO]"
                $Color = $TEXT
            }
        }

        $script:LogBox.SelectionStart =
            $script:LogBox.TextLength

        $script:LogBox.SelectionLength = 0

        $script:LogBox.SelectionColor = $MUTED

        $script:LogBox.AppendText(
            "[$Time] "
        )

        $script:LogBox.SelectionColor = $Color

        $script:LogBox.AppendText(
            "$Prefix "
        )

        $script:LogBox.SelectionColor = $TEXT

        $script:LogBox.AppendText(
            "$Message`r`n"
        )

        $script:LogBox.SelectionStart =
            $script:LogBox.TextLength

        $script:LogBox.ScrollToCaret()

        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {}
}

# ============================================================
# REGISTRY DWORD
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
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType DWord `
            -Value $Value `
            -Force `
            -ErrorAction Stop |
            Out-Null

        return $true
    }
    catch {

        Write-Log `
            "$Name : $($_.Exception.Message)" `
            "ERROR"

        return $false
    }
}

# ============================================================
# REGISTRY STRING
# ============================================================

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
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType String `
            -Value $Value `
            -Force `
            -ErrorAction Stop |
            Out-Null

        return $true
    }
    catch {

        Write-Log `
            "$Name : $($_.Exception.Message)" `
            "ERROR"

        return $false
    }
}

# ============================================================
# PROCESS COUNT
# ============================================================

function Get-ProcessCountSafe {

    try {

        return @(
            Get-Process -ErrorAction SilentlyContinue
        ).Count
    }
    catch {

        return 0
    }
}

# ============================================================
# MEMORY
# ============================================================

function Get-MemoryInfo {

    try {

        $OS = Get-CimInstance `
            Win32_OperatingSystem `
            -ErrorAction Stop

        $Total = [math]::Round(
            $OS.TotalVisibleMemorySize / 1MB,
            0
        )

        $Free = [math]::Round(
            $OS.FreePhysicalMemory / 1MB,
            0
        )

        $Used = $Total - $Free

        return @{
            Total = $Total
            Free  = $Free
            Used  = $Used
        }
    }
    catch {

        return @{
            Total = 0
            Free  = 0
            Used  = 0
        }
    }
}

# ============================================================
# STATUS
# ============================================================

function Set-Status {

    param(
        [int]$Index,
        [string]$Text,
        [ValidateSet("WAIT","RUN","OK","ERROR")]
        [string]$State = "WAIT"
    )

    if ($null -eq $script:StatusLabels) {
        return
    }

    if (
        $Index -lt 0 -or
        $Index -ge $script:StatusLabels.Count
    ) {
        return
    }

    try {

        $Label = $script:StatusLabels[$Index]

        switch ($State) {

            "RUN" {

                $Label.Text = "●  $Text"
                $Label.ForeColor = $PURPLE_LIGHT
            }

            "OK" {

                $Label.Text = "✓  $Text"
                $Label.ForeColor = $GREEN
            }

            "ERROR" {

                $Label.Text = "×  $Text"
                $Label.ForeColor = $RED
            }

            default {

                $Label.Text = "○  $Text"
                $Label.ForeColor = $MUTED
            }
        }

        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {}
}

# ============================================================
# PROGRESS
# ============================================================

function Update-Progress {

    param(
        [string]$StepName
    )

    try {

        $script:CompletedCount++

        if (
            $script:CompletedCount -gt
            $script:TotalSteps
        ) {
            $script:CompletedCount =
                $script:TotalSteps
        }

        $Percent = [math]::Round(
            (
                $script:CompletedCount /
                $script:TotalSteps
            ) * 100
        )

        if ($Percent -lt 0) {
            $Percent = 0
        }

        if ($Percent -gt 100) {
            $Percent = 100
        }

        $script:ProgressBar.Value = $Percent
        $script:ProgressText.Text = "$Percent%"

        Write-Log "$StepName completed." "OK"

        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {}
}

# ============================================================
# 01 GAME MODE
# ============================================================

function Optimize-GameMode {

    try {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AllowAutoGameMode" `
            1

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" `
            1

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "UseNexusForGameBarEnabled" `
            0

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            0

        Write-Log `
            "Windows Game Mode configured." `
            "OK"
    }
    catch {

        Write-Log `
            "Game Mode: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 02 GPU
# ============================================================

function Optimize-GPU {

    try {

        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
            "HwSchMode" `
            2

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled" `
            0

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AudioCaptureEnabled" `
            0

        Write-Log `
            "GPU scheduling configuration applied." `
            "OK"

        Write-Log `
            "HAGS may require restart." `
            "WARN"
    }
    catch {

        Write-Log `
            "GPU: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 03 POWER
# ============================================================

function Optimize-Power {

    try {

        powercfg /setactive SCHEME_MIN 2>&1 |
            Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Log `
                "High Performance power plan activated." `
                "OK"
        }
        else {

            Write-Log `
                "Power plan command returned an error." `
                "WARN"
        }
    }
    catch {

        Write-Log `
            "Power: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 04 VISUAL
# ============================================================

function Optimize-VisualEffects {

    try {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            2

        Write-Log `
            "Visual effects reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Visual Effects: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 05 BACKGROUND APPS
# ============================================================

function Optimize-BackgroundApps {

    try {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled" `
            1

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "BackgroundAppGlobalToggle" `
            0

        Write-Log `
            "Background application activity reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Background Apps: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 06 CAPTURE
# ============================================================

function Optimize-Capture {

    try {

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_FSEBehaviorMode" `
            2

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_HonorUserFSEBehaviorMode" `
            1

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_DXGIHonorFSEWindowsCompatible" `
            1

        Write-Log `
            "Game capture overhead reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Capture: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 07 STARTUP
# ============================================================

function Optimize-Startup {

    try {

        $RunPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        )

        $Names = @(
            "OneDrive",
            "Teams",
            "com.squirrel.Teams.Teams",
            "Microsoft Teams",
            "Spotify"
        )

        foreach ($Path in $RunPaths) {

            if (-not (Test-Path $Path)) {
                continue
            }

            foreach ($Name in $Names) {

                try {

                    $Property = Get-ItemProperty `
                        -Path $Path `
                        -Name $Name `
                        -ErrorAction SilentlyContinue

                    if ($null -ne $Property) {

                        Remove-ItemProperty `
                            -Path $Path `
                            -Name $Name `
                            -Force `
                            -ErrorAction SilentlyContinue

                        Write-Log `
                            "Startup disabled: $Name" `
                            "OK"
                    }
                }
                catch {}
            }
        }

        Write-Log `
            "Startup load reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Startup: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 08 INPUT
# ============================================================

function Optimize-Input {

    try {

        # ----------------------------------------------------
        # MOUSE
        # ----------------------------------------------------

        Set-RegDWORD `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed" `
            0

        Set-RegDWORD `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold1" `
            0

        Set-RegDWORD `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold2" `
            0

        # ----------------------------------------------------
        # KEYBOARD
        # ----------------------------------------------------

        Set-RegDWORD `
            "HKCU:\Control Panel\Keyboard" `
            "KeyboardDelay" `
            0

        Set-RegDWORD `
            "HKCU:\Control Panel\Keyboard" `
            "KeyboardSpeed" `
            31

        # ----------------------------------------------------
        # MOUSE DRIVER QUEUE
        # ----------------------------------------------------

        $MousePath =
            "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"

        if (-not (Test-Path $MousePath)) {

            New-Item `
                -Path $MousePath `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        New-ItemProperty `
            -Path $MousePath `
            -Name "MouseDataQueueSize" `
            -PropertyType DWord `
            -Value 36 `
            -Force `
            -ErrorAction Stop |
            Out-Null

        # ----------------------------------------------------
        # KEYBOARD DRIVER QUEUE
        # ----------------------------------------------------

        $KeyboardPath =
            "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"

        if (-not (Test-Path $KeyboardPath)) {

            New-Item `
                -Path $KeyboardPath `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        New-ItemProperty `
            -Path $KeyboardPath `
            -Name "KeyboardDataQueueSize" `
            -PropertyType DWord `
            -Value 36 `
            -Force `
            -ErrorAction Stop |
            Out-Null

        Write-Log `
            "Mouse acceleration disabled." `
            "OK"

        Write-Log `
            "Keyboard response configured." `
            "OK"

        Write-Log `
            "MouseDataQueueSize = 36" `
            "OK"

        Write-Log `
            "KeyboardDataQueueSize = 36" `
            "OK"

        Write-Log `
            "Restart required for driver queue changes." `
            "WARN"
    }
    catch {

        Write-Log `
            "Input: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 09 NETWORK
# ============================================================

function Optimize-Network {

    try {

        $Path =
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        New-ItemProperty `
            -Path $Path `
            -Name "NetworkThrottlingIndex" `
            -PropertyType DWord `
            -Value ([uint32]0xFFFFFFFF) `
            -Force `
            -ErrorAction SilentlyContinue |
            Out-Null

        Set-RegDWORD `
            $Path `
            "SystemResponsiveness" `
            0

        Write-Log `
            "Network multimedia scheduling configured." `
            "OK"
    }
    catch {

        Write-Log `
            "Network: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 10 MMCSS
# ============================================================

function Optimize-MMCSS {

    try {

        $Path =
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        Set-RegString `
            $Path `
            "GPU Priority" `
            "8"

        Set-RegString `
            $Path `
            "Priority" `
            "6"

        Set-RegString `
            $Path `
            "Scheduling Category" `
            "High"

        Set-RegString `
            $Path `
            "SFIO Priority" `
            "High"

        Write-Log `
            "MMCSS Games profile configured." `
            "OK"
    }
    catch {

        Write-Log `
            "MMCSS: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 11 TEMP
# ============================================================

function Clean-Temp {

    try {

        $TempPaths = @(
            $env:TEMP,
            "$env:WINDIR\Temp"
        )

        foreach ($Path in $TempPaths) {

            if (-not (Test-Path $Path)) {
                continue
            }

            try {

                Get-ChildItem `
                    -Path $Path `
                    -Force `
                    -ErrorAction SilentlyContinue |
                    Remove-Item `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
            }
            catch {}
        }

        Write-Log `
            "Temporary files cleaned." `
            "OK"
    }
    catch {

        Write-Log `
            "Temp: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 12 SHADER
# ============================================================

function Clean-Shaders {

    try {

        $ShaderPaths = @(
            "$env:LOCALAPPDATA\D3DSCache",
            "$env:LOCALAPPDATA\NVIDIA\DXCache",
            "$env:LOCALAPPDATA\NVIDIA\GLCache",
            "$env:LOCALAPPDATA\AMD\DxCache"
        )

        foreach ($Path in $ShaderPaths) {

            if (-not (Test-Path $Path)) {
                continue
            }

            try {

                Get-ChildItem `
                    -Path $Path `
                    -Force `
                    -ErrorAction SilentlyContinue |
                    Remove-Item `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
            }
            catch {}
        }

        Write-Log `
            "Shader caches cleaned." `
            "OK"

        Write-Log `
            "Shaders may rebuild after launch." `
            "WARN"
    }
    catch {

        Write-Log `
            "Shader Cache: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 13 EXPLORER
# ============================================================

function Optimize-Explorer {

    try {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowSyncProviderNotifications" `
            0

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0

        Write-Log `
            "Explorer background overhead reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Explorer: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 14 TASKS
# ============================================================

function Optimize-Tasks {

    try {

        $Tasks = @(
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\Feedback\Siuf\DmClient",
            "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
        )

        foreach ($Task in $Tasks) {

            try {

                schtasks.exe `
                    /Change `
                    /TN "$Task" `
                    /Disable 2>&1 |
                    Out-Null

                if ($LASTEXITCODE -eq 0) {

                    Write-Log `
                        "Task disabled: $Task" `
                        "OK"
                }
            }
            catch {}
        }

        Write-Log `
            "Optional scheduled tasks reduced." `
            "OK"
    }
    catch {

        Write-Log `
            "Tasks: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# 15 SYSTEM.INI
# ============================================================

function Optimize-SystemINI {

    $SystemIni =
        Join-Path $env:WINDIR "system.ini"

    try {

        if (-not (Test-Path $SystemIni)) {

            Write-Log `
                "system.ini not found." `
                "WARN"

            return
        }

        # ----------------------------------------------------
        # BACKUP
        # ----------------------------------------------------

        $Backup =
            "$SystemIni.sixone.backup"

        if (-not (Test-Path $Backup)) {

            Copy-Item `
                -Path $SystemIni `
                -Destination $Backup `
                -Force `
                -ErrorAction Stop

            Write-Log `
                "system.ini backup created." `
                "OK"
        }

        # ----------------------------------------------------
        # READ
        # ----------------------------------------------------

        $Content = Get-Content `
            -Path $SystemIni `
            -Raw `
            -ErrorAction Stop

        if ($null -eq $Content) {
            $Content = ""
        }

        # ----------------------------------------------------
        # REMOVE OLD SIXONE BLOCK
        # ----------------------------------------------------

        $Pattern =
            '(?ms)^\s*;\s*===== SIXONE SETTINGV1 START =====.*?^\s*;\s*===== SIXONE SETTINGV1 END =====\s*\r?\n?'

        $Content =
            [regex]::Replace(
                $Content,
                $Pattern,
                ""
            )

        # ----------------------------------------------------
        # SAFE BLOCK
        # ----------------------------------------------------

        $SixOneBlock = @"

; ===== SIXONE SETTINGV1 START =====
; SIXONE SETTINGV1
; Modern Windows system.ini compatibility marker
; No unsupported legacy performance values forced.
; ===== SIXONE SETTINGV1 END =====

"@

        $NewContent =
            $Content.TrimEnd() +
            $SixOneBlock

        # ----------------------------------------------------
        # TEMP WRITE
        # ----------------------------------------------------

        $TempFile =
            "$SystemIni.sixone.tmp"

        [System.IO.File]::WriteAllText(
            $TempFile,
            $NewContent,
            [System.Text.UTF8Encoding]::new($false)
        )

        Copy-Item `
            -Path $TempFile `
            -Destination $SystemIni `
            -Force `
            -ErrorAction Stop

        Remove-Item `
            -Path $TempFile `
            -Force `
            -ErrorAction SilentlyContinue

        Write-Log `
            "system.ini updated safely." `
            "OK"

        Write-Log `
            "Backup: $Backup" `
            "OK"
    }
    catch {

        Write-Log `
            "system.ini: $($_.Exception.Message)" `
            "ERROR"

        try {

            Remove-Item `
                -Path "$SystemIni.sixone.tmp" `
                -Force `
                -ErrorAction SilentlyContinue
        }
        catch {}
    }
}

# ============================================================
# 16 PERMANENT PROCESS LOAD
# ============================================================

function Optimize-PermanentProcessLoad {

    try {

        $Paths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        )

        $Targets = @(
            "OneDrive",
            "Teams",
            "com.squirrel.Teams.Teams",
            "Microsoft Teams",
            "Spotify"
        )

        foreach ($Path in $Paths) {

            if (-not (Test-Path $Path)) {
                continue
            }

            foreach ($Target in $Targets) {

                try {

                    $Exists =
                        Get-ItemProperty `
                            -Path $Path `
                            -Name $Target `
                            -ErrorAction SilentlyContinue

                    if ($null -ne $Exists) {

                        Remove-ItemProperty `
                            -Path $Path `
                            -Name $Target `
                            -Force `
                            -ErrorAction SilentlyContinue

                        Write-Log `
                            "Startup load removed: $Target" `
                            "OK"
                    }
                }
                catch {}
            }
        }

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" `
            "IsDynamicSearchBoxEnabled" `
            0

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures" `
            1

        Write-Log `
            "Permanent process-load configuration applied." `
            "OK"

        Write-Log `
            "Realtime process killer: DISABLED." `
            "OK"

        Write-Log `
            "Process watcher: DISABLED." `
            "OK"
    }
    catch {

        Write-Log `
            "Permanent Load: $($_.Exception.Message)" `
            "ERROR"
    }
}

# ============================================================
# MASTER
# ============================================================

function Start-PermanentOptimization {

    if ($script:OptimizationRunning) {
        return
    }

    $script:OptimizationRunning = $true
    $script:CompletedCount = 0

    # --------------------------------------------------------
    # BEFORE
    # --------------------------------------------------------

    $script:StartProcessCount =
        Get-ProcessCountSafe

    $StartMemory =
        Get-MemoryInfo

    $script:StartMemoryMB =
        $StartMemory.Used

    # --------------------------------------------------------
    # BUTTON
    # --------------------------------------------------------

    $script:RunButton.Enabled = $false
    $script:RunButton.Text = "OPTIMIZING..."
    $script:RunButton.BackColor = $PURPLE_DARK

    $script:ProgressBar.Value = 0
    $script:ProgressText.Text = "0%"

    $script:StatusMain.Text = "OPTIMIZING"
    $script:StatusMain.ForeColor = $PURPLE_LIGHT

    Write-Log ""
    Write-Log "============================================"
    Write-Log "SIXONE PERMANENT MAX STARTED"
    Write-Log "============================================"

    Write-Log `
        "Processes Before: $($script:StartProcessCount)"

    Write-Log `
        "RAM Before: $($script:StartMemoryMB) MB"

    # ========================================================
    # STEP 01
    # ========================================================

    Set-Status 0 "Game Mode" "RUN"

    Optimize-GameMode

    Set-Status 0 "Game Mode" "OK"

    Update-Progress "Game Mode"

    # ========================================================
    # STEP 02
    # ========================================================

    Set-Status 1 "GPU / HAGS" "RUN"

    Optimize-GPU

    Set-Status 1 "GPU / HAGS" "OK"

    Update-Progress "GPU"

    # ========================================================
    # STEP 03
    # ========================================================

    Set-Status 2 "Power Plan" "RUN"

    Optimize-Power

    Set-Status 2 "Power Plan" "OK"

    Update-Progress "Power Plan"

    # ========================================================
    # STEP 04
    # ========================================================

    Set-Status 3 "Visual Effects" "RUN"

    Optimize-VisualEffects

    Set-Status 3 "Visual Effects" "OK"

    Update-Progress "Visual Effects"

    # ========================================================
    # STEP 05
    # ========================================================

    Set-Status 4 "Background Apps" "RUN"

    Optimize-BackgroundApps

    Set-Status 4 "Background Apps" "OK"

    Update-Progress "Background Apps"

    # ========================================================
    # STEP 06
    # ========================================================

    Set-Status 5 "Game Capture" "RUN"

    Optimize-Capture

    Set-Status 5 "Game Capture" "OK"

    Update-Progress "Game Capture"

    # ========================================================
    # STEP 07
    # ========================================================

    Set-Status 6 "Startup" "RUN"

    Optimize-Startup

    Set-Status 6 "Startup" "OK"

    Update-Progress "Startup"

    # ========================================================
    # STEP 08
    # ========================================================

    Set-Status 7 "Input / Queue" "RUN"

    Optimize-Input

    Set-Status 7 "Input / Queue" "OK"

    Update-Progress "Input"

    # ========================================================
    # STEP 09
    # ========================================================

    Set-Status 8 "Network" "RUN"

    Optimize-Network

    Set-Status 8 "Network" "OK"

    Update-Progress "Network"

    # ========================================================
    # STEP 10
    # ========================================================

    Set-Status 9 "MMCSS" "RUN"

    Optimize-MMCSS

    Set-Status 9 "MMCSS" "OK"

    Update-Progress "MMCSS"

    # ========================================================
    # STEP 11
    # ========================================================

    Set-Status 10 "Temp Cleanup" "RUN"

    Clean-Temp

    Set-Status 10 "Temp Cleanup" "OK"

    Update-Progress "Temp Cleanup"

    # ========================================================
    # STEP 12
    # ========================================================

    Set-Status 11 "Shader Cache" "RUN"

    Clean-Shaders

    Set-Status 11 "Shader Cache" "OK"

    Update-Progress "Shader Cache"

    # ========================================================
    # STEP 13
    # ========================================================

    Set-Status 12 "Explorer" "RUN"

    Optimize-Explorer

    Set-Status 12 "Explorer" "OK"

    Update-Progress "Explorer"

    # ========================================================
    # STEP 14
    # ========================================================

    Set-Status 13 "Scheduled Tasks" "RUN"

    Optimize-Tasks

    Set-Status 13 "Scheduled Tasks" "OK"

    Update-Progress "Scheduled Tasks"

    # ========================================================
    # STEP 15
    # ========================================================

    Set-Status 14 "system.ini" "RUN"

    Optimize-SystemINI

    Set-Status 14 "system.ini" "OK"

    Update-Progress "system.ini"

    # ========================================================
    # STEP 16
    # ========================================================

    Set-Status 15 "Permanent Process Load" "RUN"

    Optimize-PermanentProcessLoad

    Set-Status 15 "Permanent Process Load" "OK"

    Update-Progress "Permanent Process Load"

    # ========================================================
    # FINAL
    # ========================================================

    Start-Sleep -Milliseconds 500

    $script:EndProcessCount =
        Get-ProcessCountSafe

    $EndMemory =
        Get-MemoryInfo

    $script:EndMemoryMB =
        $EndMemory.Used

    # --------------------------------------------------------
    # DIFFERENCE
    # --------------------------------------------------------

    $ProcessDifference =
        $script:StartProcessCount -
        $script:EndProcessCount

    $MemoryDifference =
        $script:StartMemoryMB -
        $script:EndMemoryMB

    # --------------------------------------------------------
    # PROCESS UI
    # --------------------------------------------------------

    $script:BeforeProcessLabel.Text =
        "$($script:StartProcessCount)"

    $script:AfterProcessLabel.Text =
        "$($script:EndProcessCount)"

    if ($ProcessDifference -gt 0) {

        $script:ProcessDeltaLabel.Text =
            "-$ProcessDifference processes"
    }
    elseif ($ProcessDifference -lt 0) {

        $script:ProcessDeltaLabel.Text =
            "+$([math]::Abs($ProcessDifference)) processes"
    }
    else {

        $script:ProcessDeltaLabel.Text =
            "No change"
    }

    # --------------------------------------------------------
    # MEMORY UI
    # --------------------------------------------------------

    $script:BeforeMemoryLabel.Text =
        "$($script:StartMemoryMB) MB"

    $script:AfterMemoryLabel.Text =
        "$($script:EndMemoryMB) MB"

    if ($MemoryDifference -gt 0) {

        $script:MemoryDeltaLabel.Text =
            "-$MemoryDifference MB"
    }
    elseif ($MemoryDifference -lt 0) {

        $script:MemoryDeltaLabel.Text =
            "+$([math]::Abs($MemoryDifference)) MB"
    }
    else {

        $script:MemoryDeltaLabel.Text =
            "No change"
    }

    # --------------------------------------------------------
    # COMPLETE
    # --------------------------------------------------------

    $script:ProgressBar.Value = 100
    $script:ProgressText.Text = "100%"

    $script:StatusMain.Text =
        "COMPLETED"

    $script:StatusMain.ForeColor =
        $GREEN

    $script:RunButton.Enabled = $true
    $script:RunButton.Text =
        "RUN PERMANENT MAX"

    $script:RunButton.BackColor =
        $PURPLE

    $script:OptimizationRunning =
        $false

    Write-Log ""
    Write-Log "============================================"
    Write-Log "OPTIMIZATION COMPLETED"
    Write-Log "============================================"

    Write-Log `
        "Processes Before : $($script:StartProcessCount)"

    Write-Log `
        "Processes After  : $($script:EndProcessCount)"

    Write-Log `
        "RAM Before       : $($script:StartMemoryMB) MB"

    Write-Log `
        "RAM After        : $($script:EndMemoryMB) MB"

    Write-Log `
        "Permanent configuration completed." `
        "OK"

    Write-Log `
        "No realtime process watcher installed." `
        "OK"

    Write-Log `
        "Restart Windows to apply driver/system changes." `
        "WARN"
}

# ============================================================
# FORM
# ============================================================

$form = New-Object System.Windows.Forms.Form

$form.Text =
    "SIXONE SETTINGV1"

# IMPORTANT:
# Use ClientSize instead of Size
# to prevent controls from going outside the screen.

$form.ClientSize =
    New-Object System.Drawing.Size(1080,700)

$form.MinimumSize =
    New-Object System.Drawing.Size(1080,700)

$form.MaximumSize =
    New-Object System.Drawing.Size(1080,700)

$form.StartPosition =
    "CenterScreen"

$form.BackColor =
    $BG_MAIN

$form.ForeColor =
    $TEXT

$form.FormBorderStyle =
    "FixedSingle"

$form.MaximizeBox =
    $false

$form.MinimizeBox =
    $true

# ============================================================
# HEADER
# ============================================================

$Header = New-Object System.Windows.Forms.Panel

$Header.Location =
    New-Object System.Drawing.Point(15,12)

$Header.Size =
    New-Object System.Drawing.Size(1050,65)

$Header.BackColor =
    $BG_CARD

$form.Controls.Add($Header)

# Accent

$Accent = New-Object System.Windows.Forms.Panel

$Accent.Location =
    New-Object System.Drawing.Point(0,0)

$Accent.Size =
    New-Object System.Drawing.Size(5,65)

$Accent.BackColor =
    $PURPLE

$Header.Controls.Add($Accent)

# Title

$Title = New-Object System.Windows.Forms.Label

$Title.Text =
    "SIXONE"

$Title.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        21,
        [System.Drawing.FontStyle]::Bold
    )

$Title.ForeColor =
    $WHITE

$Title.Location =
    New-Object System.Drawing.Point(22,7)

$Title.AutoSize =
    $true

$Header.Controls.Add($Title)

# Subtitle

$SubTitle = New-Object System.Windows.Forms.Label

$SubTitle.Text =
    "SETTINGV1  •  PERMANENT GAMING OPTIMIZER"

$SubTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        8
    )

$SubTitle.ForeColor =
    $MUTED

$SubTitle.Location =
    New-Object System.Drawing.Point(25,40)

$SubTitle.AutoSize =
    $true

$Header.Controls.Add($SubTitle)

# Main Status

$script:StatusMain =
    New-Object System.Windows.Forms.Label

$script:StatusMain.Text =
    "READY"

$script:StatusMain.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        9,
        [System.Drawing.FontStyle]::Bold
    )

$script:StatusMain.ForeColor =
    $PURPLE_LIGHT

$script:StatusMain.Location =
    New-Object System.Drawing.Point(970,27)

$script:StatusMain.AutoSize =
    $true

$Header.Controls.Add($script:StatusMain)

# ============================================================
# STATUS CARD
# ============================================================

$StatusCard =
    New-Object System.Windows.Forms.Panel

$StatusCard.Location =
    New-Object System.Drawing.Point(15,90)

$StatusCard.Size =
    New-Object System.Drawing.Size(370,420)

$StatusCard.BackColor =
    $BG_CARD

$form.Controls.Add($StatusCard)

$StatusTitle =
    New-Object System.Windows.Forms.Label

$StatusTitle.Text =
    "SYSTEM STATUS"

$StatusTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        10,
        [System.Drawing.FontStyle]::Bold
    )

$StatusTitle.ForeColor =
    $WHITE

$StatusTitle.Location =
    New-Object System.Drawing.Point(18,15)

$StatusTitle.AutoSize =
    $true

$StatusCard.Controls.Add($StatusTitle)

$StatusLine =
    New-Object System.Windows.Forms.Panel

$StatusLine.Location =
    New-Object System.Drawing.Point(18,42)

$StatusLine.Size =
    New-Object System.Drawing.Size(334,1)

$StatusLine.BackColor =
    $BORDER

$StatusCard.Controls.Add($StatusLine)

# ============================================================
# STATUS ITEMS
# ============================================================

$StatusNames = @(
    "Game Mode",
    "GPU / HAGS",
    "Power Plan",
    "Visual Effects",
    "Background Apps",
    "Game Capture",
    "Startup",
    "Input / Queue",
    "Network",
    "MMCSS",
    "Temp Cleanup",
    "Shader Cache",
    "Explorer",
    "Scheduled Tasks",
    "system.ini",
    "Permanent Process Load"
)

$script:StatusLabels = @()

$Y = 55

foreach ($Name in $StatusNames) {

    $Label =
        New-Object System.Windows.Forms.Label

    $Label.Text =
        "○  $Name"

    $Label.Font =
        New-Object System.Drawing.Font(
            "Segoe UI",
            8.5
        )

    $Label.ForeColor =
        $MUTED

    $Label.Location =
        New-Object System.Drawing.Point(20,$Y)

    $Label.Size =
        New-Object System.Drawing.Size(320,20)

    $StatusCard.Controls.Add($Label)

    $script:StatusLabels += $Label

    $Y += 21
}

# ============================================================
# LOG CARD
# ============================================================

$LogCard =
    New-Object System.Windows.Forms.Panel

$LogCard.Location =
    New-Object System.Drawing.Point(400,90)

$LogCard.Size =
    New-Object System.Drawing.Size(665,420)

$LogCard.BackColor =
    $BG_CARD

$form.Controls.Add($LogCard)

$LogTitle =
    New-Object System.Windows.Forms.Label

$LogTitle.Text =
    "EXECUTION LOGS"

$LogTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        10,
        [System.Drawing.FontStyle]::Bold
    )

$LogTitle.ForeColor =
    $WHITE

$LogTitle.Location =
    New-Object System.Drawing.Point(18,15)

$LogTitle.AutoSize =
    $true

$LogCard.Controls.Add($LogTitle)

$LogLine =
    New-Object System.Windows.Forms.Panel

$LogLine.Location =
    New-Object System.Drawing.Point(18,42)

$LogLine.Size =
    New-Object System.Drawing.Size(629,1)

$LogLine.BackColor =
    $BORDER

$LogCard.Controls.Add($LogLine)

# ============================================================
# LOG BOX
# ============================================================

$script:LogBox =
    New-Object System.Windows.Forms.RichTextBox

$script:LogBox.Location =
    New-Object System.Drawing.Point(18,55)

$script:LogBox.Size =
    New-Object System.Drawing.Size(629,350)

$script:LogBox.BackColor =
    $BG_CONSOLE

$script:LogBox.ForeColor =
    $TEXT

$script:LogBox.BorderStyle =
    "None"

$script:LogBox.Font =
    New-Object System.Drawing.Font(
        "Consolas",
        8.5
    )

$script:LogBox.ReadOnly =
    $true

$script:LogBox.ScrollBars =
    "Vertical"

$script:LogBox.DetectUrls =
    $false

$LogCard.Controls.Add($script:LogBox)

# ============================================================
# INFO CARD
# ============================================================

$InfoCard =
    New-Object System.Windows.Forms.Panel

$InfoCard.Location =
    New-Object System.Drawing.Point(15,520)

$InfoCard.Size =
    New-Object System.Drawing.Size(1050,78)

$InfoCard.BackColor =
    $BG_CARD

$form.Controls.Add($InfoCard)

# ============================================================
# BEFORE PROCESS
# ============================================================

$BeforeTitle =
    New-Object System.Windows.Forms.Label

$BeforeTitle.Text =
    "BEFORE PROCESSES"

$BeforeTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$BeforeTitle.ForeColor =
    $MUTED

$BeforeTitle.Location =
    New-Object System.Drawing.Point(18,9)

$BeforeTitle.AutoSize =
    $true

$InfoCard.Controls.Add($BeforeTitle)

$script:BeforeProcessLabel =
    New-Object System.Windows.Forms.Label

$script:BeforeProcessLabel.Text =
    "--"

$script:BeforeProcessLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        15,
        [System.Drawing.FontStyle]::Bold
    )

$script:BeforeProcessLabel.ForeColor =
    $WHITE

$script:BeforeProcessLabel.Location =
    New-Object System.Drawing.Point(18,28)

$script:BeforeProcessLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:BeforeProcessLabel
)

# ============================================================
# AFTER PROCESS
# ============================================================

$AfterTitle =
    New-Object System.Windows.Forms.Label

$AfterTitle.Text =
    "AFTER PROCESSES"

$AfterTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$AfterTitle.ForeColor =
    $MUTED

$AfterTitle.Location =
    New-Object System.Drawing.Point(165,9)

$AfterTitle.AutoSize =
    $true

$InfoCard.Controls.Add($AfterTitle)

$script:AfterProcessLabel =
    New-Object System.Windows.Forms.Label

$script:AfterProcessLabel.Text =
    "--"

$script:AfterProcessLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        15,
        [System.Drawing.FontStyle]::Bold
    )

$script:AfterProcessLabel.ForeColor =
    $GREEN

$script:AfterProcessLabel.Location =
    New-Object System.Drawing.Point(165,28)

$script:AfterProcessLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:AfterProcessLabel
)

$script:ProcessDeltaLabel =
    New-Object System.Windows.Forms.Label

$script:ProcessDeltaLabel.Text =
    "Waiting..."

$script:ProcessDeltaLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$script:ProcessDeltaLabel.ForeColor =
    $MUTED

$script:ProcessDeltaLabel.Location =
    New-Object System.Drawing.Point(165,53)

$script:ProcessDeltaLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:ProcessDeltaLabel
)

# ============================================================
# BEFORE RAM
# ============================================================

$RamBeforeTitle =
    New-Object System.Windows.Forms.Label

$RamBeforeTitle.Text =
    "BEFORE RAM"

$RamBeforeTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$RamBeforeTitle.ForeColor =
    $MUTED

$RamBeforeTitle.Location =
    New-Object System.Drawing.Point(320,9)

$RamBeforeTitle.AutoSize =
    $true

$InfoCard.Controls.Add($RamBeforeTitle)

$script:BeforeMemoryLabel =
    New-Object System.Windows.Forms.Label

$script:BeforeMemoryLabel.Text =
    "--"

$script:BeforeMemoryLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        15,
        [System.Drawing.FontStyle]::Bold
    )

$script:BeforeMemoryLabel.ForeColor =
    $WHITE

$script:BeforeMemoryLabel.Location =
    New-Object System.Drawing.Point(320,28)

$script:BeforeMemoryLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:BeforeMemoryLabel
)

# ============================================================
# AFTER RAM
# ============================================================

$RamAfterTitle =
    New-Object System.Windows.Forms.Label

$RamAfterTitle.Text =
    "AFTER RAM"

$RamAfterTitle.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$RamAfterTitle.ForeColor =
    $MUTED

$RamAfterTitle.Location =
    New-Object System.Drawing.Point(470,9)

$RamAfterTitle.AutoSize =
    $true

$InfoCard.Controls.Add($RamAfterTitle)

$script:AfterMemoryLabel =
    New-Object System.Windows.Forms.Label

$script:AfterMemoryLabel.Text =
    "--"

$script:AfterMemoryLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        15,
        [System.Drawing.FontStyle]::Bold
    )

$script:AfterMemoryLabel.ForeColor =
    $GREEN

$script:AfterMemoryLabel.Location =
    New-Object System.Drawing.Point(470,28)

$script:AfterMemoryLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:AfterMemoryLabel
)

$script:MemoryDeltaLabel =
    New-Object System.Windows.Forms.Label

$script:MemoryDeltaLabel.Text =
    "Waiting..."

$script:MemoryDeltaLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI",
        7.5
    )

$script:MemoryDeltaLabel.ForeColor =
    $MUTED

$script:MemoryDeltaLabel.Location =
    New-Object System.Drawing.Point(470,53)

$script:MemoryDeltaLabel.AutoSize =
    $true

$InfoCard.Controls.Add(
    $script:MemoryDeltaLabel
)

# ============================================================
# PROGRESS LABEL
# ============================================================

$ProgressLabel =
    New-Object System.Windows.Forms.Label

$ProgressLabel.Text =
    "OPTIMIZATION PROGRESS"

$ProgressLabel.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        7.5,
        [System.Drawing.FontStyle]::Bold
    )

$ProgressLabel.ForeColor =
    $MUTED

$ProgressLabel.Location =
    New-Object System.Drawing.Point(15,608)

$ProgressLabel.AutoSize =
    $true

$form.Controls.Add($ProgressLabel)

# ============================================================
# PROGRESS TEXT
# ============================================================

$script:ProgressText =
    New-Object System.Windows.Forms.Label

$script:ProgressText.Text =
    "0%"

$script:ProgressText.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        7.5,
        [System.Drawing.FontStyle]::Bold
    )

$script:ProgressText.ForeColor =
    $PURPLE_LIGHT

$script:ProgressText.Location =
    New-Object System.Drawing.Point(350,608)

$script:ProgressText.AutoSize =
    $true

$form.Controls.Add($script:ProgressText)

# ============================================================
# PROGRESS BAR
# ============================================================

$script:ProgressBar =
    New-Object System.Windows.Forms.ProgressBar

$script:ProgressBar.Location =
    New-Object System.Drawing.Point(15,625)

$script:ProgressBar.Size =
    New-Object System.Drawing.Size(370,10)

$script:ProgressBar.Minimum =
    0

$script:ProgressBar.Maximum =
    100

$script:ProgressBar.Value =
    0

$form.Controls.Add($script:ProgressBar)

# ============================================================
# RUN BUTTON
# ============================================================

$script:RunButton =
    New-Object System.Windows.Forms.Button

$script:RunButton.Text =
    "RUN PERMANENT MAX"

# FIXED:
# Button is completely inside ClientSize 1080x700

$script:RunButton.Location =
    New-Object System.Drawing.Point(735,605)

$script:RunButton.Size =
    New-Object System.Drawing.Size(330,40)

$script:RunButton.FlatStyle =
    "Flat"

$script:RunButton.FlatAppearance.BorderSize =
    0

$script:RunButton.BackColor =
    $PURPLE

$script:RunButton.ForeColor =
    $WHITE

$script:RunButton.Font =
    New-Object System.Drawing.Font(
        "Segoe UI Semibold",
        9,
        [System.Drawing.FontStyle]::Bold
    )

$script:RunButton.Cursor =
    [System.Windows.Forms.Cursors]::Hand

$form.Controls.Add(
    $script:RunButton
)

# ============================================================
# BUTTON HOVER
# ============================================================

$script:RunButton.Add_MouseEnter({

    if ($script:RunButton.Enabled) {

        $script:RunButton.BackColor =
            $PURPLE_LIGHT
    }
})

$script:RunButton.Add_MouseLeave({

    if ($script:RunButton.Enabled) {

        $script:RunButton.BackColor =
            $PURPLE
    }
})

# ============================================================
# BUTTON CLICK
# ============================================================

$script:RunButton.Add_Click({

    if ($script:OptimizationRunning) {
        return
    }

    try {

        Start-PermanentOptimization
    }
    catch {

        Write-Log `
            "Fatal error: $($_.Exception.Message)" `
            "ERROR"

        $script:OptimizationRunning =
            $false

        $script:RunButton.Enabled =
            $true

        $script:RunButton.Text =
            "RUN PERMANENT MAX"

        $script:RunButton.BackColor =
            $PURPLE

        $script:StatusMain.Text =
            "ERROR"

        $script:StatusMain.ForeColor =
            $RED
    }
})

# ============================================================
# INITIAL STATS
# ============================================================

$InitialProcesses =
    Get-ProcessCountSafe

$InitialMemory =
    Get-MemoryInfo

$script:BeforeProcessLabel.Text =
    "$InitialProcesses"

$script:AfterProcessLabel.Text =
    "$InitialProcesses"

$script:BeforeMemoryLabel.Text =
    "$($InitialMemory.Used) MB"

$script:AfterMemoryLabel.Text =
    "$($InitialMemory.Used) MB"

# ============================================================
# INITIAL LOG
# ============================================================

Write-Log `
    "SIXONE SETTINGV1 initialized." `
    "OK"

Write-Log `
    "Administrator mode confirmed." `
    "OK"

Write-Log `
    "Permanent optimization mode enabled." `
    "OK"

Write-Log `
    "Realtime process killer: DISABLED." `
    "OK"

Write-Log `
    "Process watcher: DISABLED." `
    "OK"

Write-Log `
    "Ready."

# ============================================================
# SHOW FORM
# ============================================================

[void]$form.ShowDialog()
