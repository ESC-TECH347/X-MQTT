param(
    [string]$ProcessName,
    [string]$Key
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
"@

$proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1

if ($proc) {
    $targetHwnd = $proc.MainWindowHandle
    $foregroundHwnd = [Win32]::GetForegroundWindow()
    $currentThreadId = [Win32]::GetCurrentThreadId()

    $targetThreadId = 0
    [Win32]::GetWindowThreadProcessId($targetHwnd, [ref]$targetThreadId) | Out-Null
    $foregroundThreadId = 0
    [Win32]::GetWindowThreadProcessId($foregroundHwnd, [ref]$foregroundThreadId) | Out-Null

    [Win32]::AttachThreadInput($currentThreadId, $foregroundThreadId, $true) | Out-Null
    [Win32]::AttachThreadInput($targetThreadId, $foregroundThreadId, $true) | Out-Null

    [Win32]::ShowWindow($targetHwnd, 9) | Out-Null
    [Win32]::BringWindowToTop($targetHwnd) | Out-Null
    [Win32]::SetForegroundWindow($targetHwnd) | Out-Null

    [Win32]::AttachThreadInput($currentThreadId, $foregroundThreadId, $false) | Out-Null
    [Win32]::AttachThreadInput($targetThreadId, $foregroundThreadId, $false) | Out-Null

    Start-Sleep -Milliseconds 300
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{$Key}")
}
