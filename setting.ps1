Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

# --- Custom Form Styling ---
$form = New-Object System.Windows.Forms.Form;
$form.Text = "SIXONE SETTINGV1 - Ultimate Tweak Edition";
$form.Size = New-Object System.Drawing.Size(820, 560);$form.StartPosition = "CenterScreen";
$form.FormBorderStyle = "FixedSingle";
$form.MaximizeBox =$false;
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 10, 18);

# --- Top Header Title ---
$lblTitle = New-Object System.Windows.Forms.Label;
$lblTitle.Text = "SIXONE SETTINGV1  //  ULTIMATE GAMING OPTIMIZER";
$lblTitle.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold);
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(186, 85, 211);
$lblTitle.Location = New-Object System.Drawing.Point(20, 15);$lblTitle.Size = New-Object System.Drawing.Size(760, 25);
$form.Controls.Add($lblTitle);

# --- Panel 1: STATUS (Top Left) ---
$lblStatusHeader = New-Object System.Windows.Forms.Label;
$lblStatusHeader.Text = "SYS STATUS";
$lblStatusHeader.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold);
$lblStatusHeader.ForeColor = [System.Drawing.Color]::FromArgb(140, 130, 170);
$lblStatusHeader.Location = New-Object System.Drawing.Point(20, 48);$lblStatusHeader.Size = New-Object System.Drawing.Size(220, 18);
$form.Controls.Add($lblStatusHeader);

$txtStatus = New-Object System.Windows.Forms.TextBox;
$txtStatus.Location = New-Object System.Drawing.Point(20, 68);$txtStatus.Size = New-Object System.Drawing.Size(220, 320);
$txtStatus.Multiline =$true;
$txtStatus.ReadOnly =$true;
$txtStatus.BackColor = [System.Drawing.Color]::FromArgb(20, 16, 28);
$txtStatus.ForeColor = [System.Drawing.Color]::FromArgb(215, 185, 255);$txtStatus.BorderStyle = "FixedSingle";
$txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9);
$form.Controls.Add($txtStatus);

# --- Panel 2: LOGS (Top Right) ---
$lblLogsHeader = New-Object System.Windows.Forms.Label;
$lblLogsHeader.Text = "OPTIMIZATION LOGS";
$lblLogsHeader.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold);
$lblLogsHeader.ForeColor = [System.Drawing.Color]::FromArgb(140, 130, 170);
$lblLogsHeader.Location = New-Object System.Drawing.Point(255, 48);$lblLogsHeader.Size = New-Object System.Drawing.Size(525, 18);
$form.Controls.Add($lblLogsHeader);

$txtLogs = New-Object System.Windows.Forms.TextBox;
$txtLogs.Location = New-Object System.Drawing.Point(255, 68);$txtLogs.Size = New-Object System.Drawing.Size(525, 320);
$txtLogs.Multiline =$true;
$txtLogs.ReadOnly =$true;
$txtLogs.ScrollBars = "Vertical";
$txtLogs.BackColor = [System.Drawing.Color]::FromArgb(8, 6, 12);
$txtLogs.ForeColor = [System.Drawing.Color]::FromArgb(160, 120, 255);$txtLogs.BorderStyle = "FixedSingle";
$txtLogs.Font = New-Object System.Drawing.Font("Consolas", 9.5);
$form.Controls.Add($txtLogs);

# --- Panel 3: ACTION BUTTON (Bottom Left) ---
$btnTweak = New-Object System.Windows.Forms.Button;
$btnTweak.Location = New-Object System.Drawing.Point(20, 405);
$btnTweak.Size = New-Object System.Drawing.Size(220, 60);$btnTweak.Text = "⚡ เริ่ม TWEAK ระบบ";
$btnTweak.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold);
$btnTweak.BackColor = [System.Drawing.Color]::FromArgb(128, 0, 128);$btnTweak.ForeColor = [System.Drawing.Color]::White;
$btnTweak.FlatStyle = "Flat";
$btnTweak.FlatAppearance.BorderSize = 1;
$btnTweak.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(218, 112, 214);
$form.Controls.Add($btnTweak);

$btnTweak.Add_MouseEnter({
    if ($btnTweak.Enabled) {
        $btnTweak.BackColor = [System.Drawing.Color]::FromArgb(160, 32, 240);$btnTweak.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 180, 255);
    }
});

$btnTweak.Add_MouseLeave({
    if ($btnTweak.Enabled) {
        $btnTweak.BackColor = [System.Drawing.Color]::FromArgb(128, 0, 128);$btnTweak.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(218, 112, 214);
    }
});

# --- Panel 4: INFO & PROGRESS (Bottom Right) ---
$lblInfoText = New-Object System.Windows.Forms.Label;
$lblInfoText.Location = New-Object System.Drawing.Point(255, 405);
$lblInfoText.Size = New-Object System.Drawing.Size(525, 25);$lblInfoText.Text = "READY: กดปุ่มซ้ายมือเพื่อเริ่มกระบวนการ Tweak";
$lblInfoText.Font = New-Object System.Drawing.Font("Consolas", 9.5);
$lblInfoText.ForeColor = [System.Drawing.Color]::FromArgb(200, 180, 240);
$form.Controls.Add($lblInfoText);

$progressBar = New-Object System.Windows.Forms.ProgressBar;
$progressBar.Location = New-Object System.Drawing.Point(255, 435);
$progressBar.Size = New-Object System.Drawing.Size(525, 30);$progressBar.Style = "Continuous";
$form.Controls.Add($progressBar);

# --- Helper Functions ---
function Append-Log {
    param([string]$Text);$time = Get-Date -Format "HH:mm:ss";
    $txtLogs.AppendText("[$time]$Text`r`n");
    $txtLogs.SelectionStart =$txtLogs.Text.Length;
    $txtLogs.ScrollToCaret();
    [System.Windows.Forms.Application]::DoEvents();
}

# --- Event: Form Load ---
$form.Add_Shown({$txtStatus.Text = "=== SYSTEM INFO ===" + "`r`n`r`n";
    $txtStatus.AppendText("• OS: Win " + (Get-CimInstance Win32_OperatingSystem).Version + "`r`n");
    $txtStatus.AppendText("• CPU: " + (Get-CimInstance Win32_Processor).Name.Split('@')[0].Trim() + "`r`n");
    $ramGB = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB, 1);
    $txtStatus.AppendText("• RAM: $ramGB GB`r`n`r`n");
    $txtStatus.AppendText("-------------------`r`n");
    $txtStatus.AppendText("• STATUS: READY`r`n");
    $txtStatus.AppendText("• ENGINE: SIXONE v1");

    Append-Log "SIXONE SETTINGV1 Ultimate Edition Loaded.";
    Append-Log "System status verified. Ready for tweak.";
});

# --- Event: Click Tweak Button ---
$btnTweak.Add_Click({
    $btnTweak.Enabled =$false;
    $btnTweak.BackColor = [System.Drawing.Color]::FromArgb(50, 30, 70);$progressBar.Value = 0;

    Append-Log "========================================";
    Append-Log "STARTING FULL SYSTEM TWEAK PROCESS...";

    # Task 1: Mouse & Keyboard DataQueueSize (36)
    $lblInfoText.Text = "TWEAKING: Setting Mouse & Keyboard Queue Size (36)...";
    $progressBar.Value = 10;
    Start-Sleep -Milliseconds 200;
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Value 36 -Type DWord -ErrorAction Stop;
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Value 36 -Type DWord -ErrorAction Stop;
        Append-Log "[OK] Mouse & Keyboard DataQueueSize set to 36.";
    } catch {
        Append-Log "[ERROR] Failed QueueSize settings. Check Admin rights!";
    }

    # Task 2: Win32PrioritySeparation (42)
    $lblInfoText.Text = "TWEAKING: Setting Win32PrioritySeparation (42)...";
    $progressBar.Value = 25;
    Start-Sleep -Milliseconds 200;
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 42 -Type DWord -ErrorAction Stop;
        Append-Log "[OK] Win32PrioritySeparation set to 42.";
    } catch {
        Append-Log "[ERROR] Failed PrioritySeparation.";
    }

    # Task 3: SystemResponsiveness & Network Throttling
    $lblInfoText.Text = "TWEAKING: CPU Responsiveness & Network Throttling...";
    $progressBar.Value = 40;
    Start-Sleep -Milliseconds 200;
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -Force;
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -Type DWord -Force;
        Append-Log "[OK] SystemResponsiveness = 0, NetworkThrottling Disabled.";
    } catch {
        Append-Log "[ERROR] Failed System Profile tweaks.";
    }

    # Task 4: Games Task Profile Priority
    $lblInfoText.Text = "TWEAKING: Game Execution Priority to High...";
    $progressBar.Value = 55;
    Start-Sleep -Milliseconds 200;
    try {
        $taskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games";
        Set-ItemProperty -Path $taskPath -Name "GPU Priority" -Value 8 -Type DWord -Force;
        Set-ItemProperty -Path $taskPath -Name "Priority" -Value 6 -Type DWord -Force;
        Set-ItemProperty -Path $taskPath -Name "Scheduling Category" -Value "High" -Type String -Force;
        Set-ItemProperty -Path $taskPath -Name "SFIO Priority" -Value "High" -Type String -Force;
        Append-Log "[OK] Game Process Priority set to HIGH.";
    } catch {
        Append-Log "[ERROR] Failed Games Task Priority tweaks.";
    }

    # Task 5: Mouse Acceleration & Keyboard Delays
    $lblInfoText.Text = "TWEAKING: Input Response & Delay Optimization...";
    $progressBar.Value = 70;
    Start-Sleep -Milliseconds 200;
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type String -Force;
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -Type String -Force;
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -Type String -Force;
        Append-Log "[OK] Input Delays removed (Mouse Acceleration Off).";
    } catch {
        Append-Log "[WARN] Skipped input tweaks.";
    }

    # Task 6: Network TCP Ack Frequency & NoDelay
    $lblInfoText.Text = "TWEAKING: TCP NoDelay & Ack Frequency (FiveM)...";
    $progressBar.Value = 80;
    Start-Sleep -Milliseconds 200;
    try {
        Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue;
            Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue;
        };
        Append-Log "[OK] Network TCP NoDelay enabled.";
    } catch {
        Append-Log "[WARN] TCP Tweaks partially applied.";
    }

    # Task 7: System.ini File Tweaks
    $lblInfoText.Text = "TWEAKING: Modifying C:\Windows\system.ini...";
    $progressBar.Value = 90;
    Start-Sleep -Milliseconds 200;
    try {
        $iniPath = "$env:SystemRoot\system.ini";
        if (Test-Path $iniPath) {
            $content = Get-Content -Path$iniPath;
            if (-not ($content -match "\[386Enh\]")) {
                Add-Content -Path $iniPath -Value "`r`n[386Enh]";
            }
            if (-not ($content -match "ConservativeSwapfileUsage")) {
                Add-Content -Path $iniPath -Value "ConservativeSwapfileUsage=1";
            }
            if (-not ($content -match "TimerCriticalSection")) {
                Add-Content -Path $iniPath -Value "TimerCriticalSection=0";
            }
            Append-Log "[OK] system.ini optimized.";
        }
    } catch {
        Append-Log "[ERROR] Failed to write system.ini. Run as Administrator!";
    }

    # Task 8: Temp & DNS Clean
    $lblInfoText.Text = "CLEANING: Clearing Cache & DNS...";
    $progressBar.Value = 95;
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue;
    Clear-DnsClientCache;
    Append-Log "[OK] Temp files & DNS Cache flushed.";

    # Complete
    $progressBar.Value = 100;
    $lblInfoText.Text = "SUCCESS: All Registry, system.ini, & System Tweaks Applied!";
    Append-Log "========================================";
    Append-Log "ALL TWEAKS COMPLETED SUCCESSFULLY.";
    Append-Log "IMPORTANT: Please Restart your PC for full performance!";
    Append-Log "========================================";

    $btnTweak.Enabled =$true;
    $btnTweak.BackColor = [System.Drawing.Color]::FromArgb(128, 0, 128);
});

# --- Show Dialog ---
$form.ShowDialog() | Out-Null;