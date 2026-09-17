param(
    [string]$Mode,
    [string]$PowerToysPath
)

Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "PowerToys.KeyboardManagerEngine" -ErrorAction SilentlyContinue | Stop-Process -Force

if ($Mode -eq "Restart") {
    Start-Sleep -Milliseconds 1000
    if (Test-Path $PowerToysPath) {
        Start-Process -FilePath $PowerToysPath
    }
}
