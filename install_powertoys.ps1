$defaultPath = "C:\Program Files\PowerToys\PowerToys.exe"
$alreadyInstalled = Test-Path $defaultPath

Write-Host "Checking whether PowerToys is already installed..."

if ($alreadyInstalled) {
    Write-Host "PowerToys is already installed at $defaultPath - skipping the installer, but still checking for a saved settings file to apply."
}
else {
    try {
        # Bundled by the installer into this same folder (C:\Scripts), not downloaded -
        # see m3_setup.iss for why.
        $installerPath = Join-Path $PSScriptRoot "PowerToysSetup-x64.exe"

        if (-not (Test-Path $installerPath)) {
            throw "Could not find $installerPath. Re-run M3PCControlSetup.exe on this PC so it gets copied into C:\Scripts, then try again."
        }

        Write-Host "Installing PowerToys silently to C:\Program Files\PowerToys - this can take a minute or two, please wait..."
        # NOTE: current PowerToys installers (WiX Burn-based, 0.53.0+) use /install
        # /quiet /norestart, NOT the old --silent --install_dir syntax from older
        # Squirrel-based installers. The new installer has no documented switch for
        # a custom install directory at all - --install_dir was silently ignored,
        # which is why this used to "succeed" (exit code 0) without actually
        # landing PowerToys.exe anywhere. There's no workaround needed for this
        # though: the current installer's own per-machine default IS
        # C:\Program Files\PowerToys, which already matches what config.bat expects.
        $logPath = Join-Path $env:TEMP "PowerToys-Install.log"
        $proc = Start-Process -FilePath $installerPath -ArgumentList @("/install", "/quiet", "/norestart", "/log", "`"$logPath`"") -Wait -PassThru

        if ($proc.ExitCode -ne 0) {
            throw "The PowerToys installer exited with code $($proc.ExitCode). Log: $logPath"
        }

        if (-not (Test-Path $defaultPath)) {
            throw "The installer reported success but PowerToys.exe still isn't at $defaultPath. Check the log at $logPath for details."
        }

        Write-Host "PowerToys installed successfully."
    }
    catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Could not automatically install PowerToys.`n`nError: $($_.Exception.Message)`n`nYou can install it manually from https://aka.ms/installpowertoys and then just re-run the M3 PC Setup icon to save this PC's settings again.", "PowerToys Install Failed", "OK", "Error")
        exit 1
    }
}

# --- Apply the saved Crime Scene settings file -----------------------------
# This runs EVERY time this script runs, whether PowerToys was just installed
# above or was already present from an earlier run - that's the fix for the
# bug where an already-installed PC silently skipped this whole section
# because the script used to exit at the top before ever getting here.
# Re-running this on a PC that already has the settings applied is harmless -
# it just overwrites with the same values.
$backupFile = Get-ChildItem -Path $PSScriptRoot -Filter "settings_*.ptb" -File | Select-Object -First 1

if ($backupFile) {
    Write-Host "Applying saved PowerToys settings ($($backupFile.Name))..."
    try {
        # Part 1: drop a copy where PowerToys' own Settings > General > Restore
        # button looks by default, so it's available there too - as an
        # official fallback / a way to re-apply it later by hand if ever
        # needed. This alone does NOT apply anything automatically - that
        # requires opening PowerToys Settings and clicking Restore, since
        # there's no documented silent/command-line restore.
        $restoreFolder = Join-Path $env:USERPROFILE "Documents\PowerToys\Backup"
        if (-not (Test-Path $restoreFolder)) {
            New-Item -ItemType Directory -Path $restoreFolder -Force | Out-Null
        }
        Copy-Item -Path $backupFile.FullName -Destination $restoreFolder -Force

        # Part 2: actually apply the settings with no manual step needed, by
        # extracting the same file (it's just a .zip) directly into
        # %LocalAppData%\Microsoft\PowerToys\ - the exact folder PowerToys
        # itself reads per-module settings.json/default.json from. This is
        # the same well-known location people already edit by hand to
        # customize Keyboard Manager remaps, so writing the files there
        # directly is safe. manifest.json is skipped since that's bookkeeping
        # for the official Restore feature, not a real per-module settings
        # file PowerToys would look for in this folder.
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $settingsRoot = Join-Path $env:LOCALAPPDATA "Microsoft\PowerToys"
        if (-not (Test-Path $settingsRoot)) {
            New-Item -ItemType Directory -Path $settingsRoot -Force | Out-Null
        }
        $zip = [System.IO.Compression.ZipFile]::OpenRead($backupFile.FullName)
        try {
            foreach ($entry in $zip.Entries) {
                if ($entry.Name -eq "" -or $entry.FullName -eq "manifest.json") { continue }
                $destPath = Join-Path $settingsRoot $entry.FullName
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
            }
        }
        finally {
            $zip.Dispose()
        }
        Write-Host "Saved settings applied."
    }
    catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Could not automatically apply the saved settings file.`n`nError: $($_.Exception.Message)`n`nA copy was placed in $restoreFolder - you can try applying it manually from PowerToys Settings > General > Restore.", "Settings Restore Failed", "OK", "Warning")
    }
}
else {
    Write-Host "No settings_*.ptb file found in $PSScriptRoot - PowerToys will keep its default settings."
}

# --- Make sure PowerToys is actually running with the (possibly just-updated)
# settings, restarting it if it was already running so it picks up the files
# we just wrote instead of keeping whatever was already loaded in memory.
$running = Get-Process -Name "PowerToys.Runner" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Restarting PowerToys so it picks up the applied settings..."
    Get-Process -Name "PowerToys.Runner" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 1000
}
Start-Process -FilePath $defaultPath

Start-Sleep -Seconds 2
exit 0

