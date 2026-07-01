# Right Key Holder for Windows
# Runs with built-in Windows PowerShell 5.1 or PowerShell 7.

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$nativeSource = @"
using System;
using System.Runtime.InteropServices;

public static class RightKeyHolderNative
{
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [StructLayout(LayoutKind.Sequential)]
    private struct INPUT
    {
        public uint type;
        public InputUnion U;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)]
        public MOUSEINPUT mi;

        [FieldOffset(0)]
        public KEYBDINPUT ki;

        [FieldOffset(0)]
        public HARDWAREINPUT hi;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct HARDWAREINPUT
    {
        public uint uMsg;
        public ushort wParamL;
        public ushort wParamH;
    }

    private const uint INPUT_KEYBOARD = 1;
    private const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    private const uint KEYEVENTF_KEYUP = 0x0002;

    public static uint GetProcessId(IntPtr hWnd)
    {
        uint processId;
        GetWindowThreadProcessId(hWnd, out processId);
        return processId;
    }

    public static void SendKey(ushort virtualKey, bool keyUp)
    {
        INPUT[] inputs = new INPUT[1];
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].U.ki.wVk = virtualKey;
        inputs[0].U.ki.wScan = 0;
        inputs[0].U.ki.dwFlags = (IsExtendedKey(virtualKey) ? KEYEVENTF_EXTENDEDKEY : 0) | (keyUp ? KEYEVENTF_KEYUP : 0);
        inputs[0].U.ki.time = 0;
        inputs[0].U.ki.dwExtraInfo = IntPtr.Zero;

        SendInput(1, inputs, Marshal.SizeOf(typeof(INPUT)));
    }

    private static bool IsExtendedKey(ushort virtualKey)
    {
        return virtualKey == 0x21 || virtualKey == 0x22 ||
               virtualKey == 0x23 || virtualKey == 0x24 ||
               virtualKey == 0x25 || virtualKey == 0x26 ||
               virtualKey == 0x27 || virtualKey == 0x28 ||
               virtualKey == 0x2D || virtualKey == 0x2E;
    }
}
"@

Add-Type -TypeDefinition $nativeSource -Language CSharp

$script:VK_RIGHT = [UInt16]0x27
$script:VK_SPACE = [UInt16]0x20
$script:AppVersionText = "made by Wenshuishi v1.1"
$script:OwnProcessId = [UInt32][System.Diagnostics.Process]::GetCurrentProcess().Id
$script:LastTargetHwnd = [IntPtr]::Zero
$script:IsHolding = $false

function U8([string]$Base64) {
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64))
}

$script:Strings = @{
    zh = @{
        appTitle = (U8 "5Y+z6ZSu6ZW/5oyJ5Yqp5omL")
        languageName = (U8 "5Lit5paH")
        holdKey = (U8 "5oyJ5L2PIOKGkg==")
        releaseKey = (U8 "5p2+5byAIOKGkg==")
        playPauseVideo = (U8 "5byA5aeLL+aaguWBnA==")
        testTap = (U8 "54K55oyJIOKGkiDmtYvor5U=")
        keyIdle = (U8 "5pyq5oyJ5L2P")
        keyHolding = (U8 "5Y+z5pa55ZCR6ZSu5oyJ5L2P5Lit")
        openVideoWindow = (U8 "6K+35YWI54K55Ye76KeG6aKR56qX5Y+j")
        playPauseKeySent = (U8 "5bey5Y+R6YCB5byA5aeLL+aaguWBnOmUrg==")
        testTapped = (U8 "5bey54K55oyJ5LiA5qyh5Y+z5pa55ZCR6ZSu")
        holdBehaviorNote = (U8 "6K+35YWI54K55Ye76KeG6aKR56qX5Y+j77yM5YaN54K55Ye75pys5bel5YW35oyJ6ZKu44CCDQpC56uZ5oyJ5L2P5pWI5p6c5Li66KeG6aKR5LiJ5YCN6YCf44CCDQpZb3VUdWJl5oyJ5L2P5pWI5p6c5Li66KeG6aKR5b+r6L+b44CC")
    }
    en = @{
        appTitle = "Right Key Holder"
        languageName = "English"
        holdKey = "Hold ->"
        releaseKey = "Release ->"
        playPauseVideo = "Play/Pause"
        testTap = "Tap -> Test"
        keyIdle = "Not holding"
        keyHolding = "Holding right arrow"
        openVideoWindow = "Click the video window first"
        playPauseKeySent = "Sent play/pause key"
        testTapped = "Tapped right arrow once"
        holdBehaviorNote = "Click the video window first, then click this tool.`r`nBilibili hold: 3x video speed.`r`nYouTube hold: video fast-forward."
    }
}

$script:ConfigDir = Join-Path $env:APPDATA "RightKeyHolder"
$script:ConfigPath = Join-Path $script:ConfigDir "settings.json"

function Load-Language {
    try {
        if (Test-Path $script:ConfigPath) {
            $config = Get-Content -Raw -Path $script:ConfigPath | ConvertFrom-Json
            if ($config.language -eq "en") {
                return "en"
            }
        }
    } catch {
    }

    return "zh"
}

function Save-Language {
    try {
        if (-not (Test-Path $script:ConfigDir)) {
            New-Item -ItemType Directory -Path $script:ConfigDir | Out-Null
        }

        @{ language = $script:Language } | ConvertTo-Json | Set-Content -Path $script:ConfigPath -Encoding UTF8
    } catch {
    }
}

$script:Language = Load-Language

function T([string]$Key) {
    $table = $script:Strings[$script:Language]
    if ($table.ContainsKey($Key)) {
        return $table[$Key]
    }

    return $Key
}

function Has-TargetWindow {
    if ($script:LastTargetHwnd -eq [IntPtr]::Zero) {
        return $false
    }

    return [RightKeyHolderNative]::IsWindow($script:LastTargetHwnd)
}

function Focus-TargetWindow {
    if (-not (Has-TargetWindow)) {
        $script:StatusLabel.Text = T "openVideoWindow"
        return $false
    }

    [RightKeyHolderNative]::SetForegroundWindow($script:LastTargetHwnd) | Out-Null
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 90
    return $true
}

function Send-KeyTap([UInt16]$VirtualKey) {
    [RightKeyHolderNative]::SendKey($VirtualKey, $false)
    Start-Sleep -Milliseconds 45
    [RightKeyHolderNative]::SendKey($VirtualKey, $true)
}

function Update-IdleUI {
    $script:HoldButton.Text = T "holdKey"
    $script:HoldButton.BackColor = [System.Drawing.Color]::FromArgb(42, 109, 237)
    $script:StatusLabel.Text = T "keyIdle"
}

function Update-RunningUI {
    $script:HoldButton.Text = T "releaseKey"
    $script:HoldButton.BackColor = [System.Drawing.Color]::FromArgb(219, 51, 41)
    $script:StatusLabel.Text = T "keyHolding"
}

function Start-Hold {
    if (-not (Has-TargetWindow)) {
        $script:StatusLabel.Text = T "openVideoWindow"
        return
    }

    $script:IsHolding = $true
    Update-RunningUI

    if (Focus-TargetWindow) {
        [RightKeyHolderNative]::SendKey($script:VK_RIGHT, $false)
        $script:HoldTimer.Start()
    }
}

function Stop-Hold {
    if (-not $script:IsHolding) {
        return
    }

    $script:HoldTimer.Stop()
    $script:IsHolding = $false
    Update-IdleUI

    if (Focus-TargetWindow) {
        [RightKeyHolderNative]::SendKey($script:VK_RIGHT, $true)
    } else {
        [RightKeyHolderNative]::SendKey($script:VK_RIGHT, $true)
    }
}

function Play-Pause {
    if ($script:IsHolding) {
        Stop-Hold
        Start-Sleep -Milliseconds 120
    }

    if (Focus-TargetWindow) {
        Send-KeyTap $script:VK_SPACE
        $script:StatusLabel.Text = T "playPauseKeySent"
    }
}

function Test-RightArrow {
    if (Focus-TargetWindow) {
        Send-KeyTap $script:VK_RIGHT
        $script:StatusLabel.Text = T "testTapped"
    }
}

function Apply-Language {
    $script:Form.Text = T "appTitle"
    $script:TitleLabel.Text = T "appTitle"
    $script:PauseButton.Text = T "playPauseVideo"
    $script:TestButton.Text = T "testTap"
    $script:NoteLabel.Text = T "holdBehaviorNote"

    if ($script:IsHolding) {
        Update-RunningUI
    } else {
        Update-IdleUI
    }
}

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.ClientSize = New-Object System.Drawing.Size(340, 360)
$script:Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$script:Form.MaximizeBox = $false
$script:Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$script:Form.TopMost = $true
$script:Form.BackColor = [System.Drawing.Color]::FromArgb(247, 249, 252)

$script:TitleLabel = New-Object System.Windows.Forms.Label
$script:TitleLabel.Location = New-Object System.Drawing.Point(0, 16)
$script:TitleLabel.Size = New-Object System.Drawing.Size(340, 24)
$script:TitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:TitleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)

$languageBox = New-Object System.Windows.Forms.ComboBox
$languageBox.Location = New-Object System.Drawing.Point(83, 52)
$languageBox.Size = New-Object System.Drawing.Size(174, 28)
$languageBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$languageBox.Items.Add((U8 "5Lit5paH"))
[void]$languageBox.Items.Add("English")
$languageBox.SelectedIndex = if ($script:Language -eq "en") { 1 } else { 0 }
$languageBox.Add_SelectedIndexChanged({
    $script:Language = if ($languageBox.SelectedIndex -eq 1) { "en" } else { "zh" }
    Save-Language
    Apply-Language
})

$script:HoldButton = New-Object System.Windows.Forms.Button
$script:HoldButton.Location = New-Object System.Drawing.Point(85, 96)
$script:HoldButton.Size = New-Object System.Drawing.Size(170, 40)
$script:HoldButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:HoldButton.FlatAppearance.BorderSize = 0
$script:HoldButton.ForeColor = [System.Drawing.Color]::White
$script:HoldButton.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
$script:HoldButton.UseVisualStyleBackColor = $false
$script:HoldButton.Add_Click({
    if ($script:IsHolding) {
        Stop-Hold
    } else {
        Start-Hold
    }
})

$script:PauseButton = New-Object System.Windows.Forms.Button
$script:PauseButton.Location = New-Object System.Drawing.Point(85, 146)
$script:PauseButton.Size = New-Object System.Drawing.Size(170, 32)
$script:PauseButton.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Regular)
$script:PauseButton.Add_Click({ Play-Pause })

$script:StatusLabel = New-Object System.Windows.Forms.Label
$script:StatusLabel.Location = New-Object System.Drawing.Point(20, 190)
$script:StatusLabel.Size = New-Object System.Drawing.Size(300, 22)
$script:StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:StatusLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Regular)
$script:StatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(79, 88, 105)

$script:TestButton = New-Object System.Windows.Forms.Button
$script:TestButton.Location = New-Object System.Drawing.Point(110, 220)
$script:TestButton.Size = New-Object System.Drawing.Size(120, 28)
$script:TestButton.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 8.5, [System.Drawing.FontStyle]::Regular)
$script:TestButton.Add_Click({ Test-RightArrow })

$script:NoteLabel = New-Object System.Windows.Forms.Label
$script:NoteLabel.Location = New-Object System.Drawing.Point(18, 266)
$script:NoteLabel.Size = New-Object System.Drawing.Size(304, 54)
$script:NoteLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:NoteLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 8.5, [System.Drawing.FontStyle]::Regular)
$script:NoteLabel.ForeColor = [System.Drawing.Color]::FromArgb(88, 99, 118)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Location = New-Object System.Drawing.Point(110, 332)
$versionLabel.Size = New-Object System.Drawing.Size(218, 18)
$versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Regular)
$versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(130, 138, 152)
$versionLabel.Text = $script:AppVersionText

$script:Form.Controls.Add($script:TitleLabel)
$script:Form.Controls.Add($languageBox)
$script:Form.Controls.Add($script:HoldButton)
$script:Form.Controls.Add($script:PauseButton)
$script:Form.Controls.Add($script:StatusLabel)
$script:Form.Controls.Add($script:TestButton)
$script:Form.Controls.Add($script:NoteLabel)
$script:Form.Controls.Add($versionLabel)

$script:TrackTimer = New-Object System.Windows.Forms.Timer
$script:TrackTimer.Interval = 250
$script:TrackTimer.Add_Tick({
    $hwnd = [RightKeyHolderNative]::GetForegroundWindow()
    if ($hwnd -ne [IntPtr]::Zero -and [RightKeyHolderNative]::IsWindow($hwnd)) {
        $processId = [RightKeyHolderNative]::GetProcessId($hwnd)
        if ($processId -ne $script:OwnProcessId) {
            $script:LastTargetHwnd = $hwnd
        }
    }
})

$script:HoldTimer = New-Object System.Windows.Forms.Timer
$script:HoldTimer.Interval = 80
$script:HoldTimer.Add_Tick({
    if ($script:IsHolding) {
        [RightKeyHolderNative]::SendKey($script:VK_RIGHT, $false)
    }
})

$script:Form.Add_FormClosing({
    if ($script:IsHolding) {
        $script:HoldTimer.Stop()
        [RightKeyHolderNative]::SendKey($script:VK_RIGHT, $true)
    }
    $script:TrackTimer.Stop()
})

Apply-Language
$script:TrackTimer.Start()
[System.Windows.Forms.Application]::Run($script:Form)
