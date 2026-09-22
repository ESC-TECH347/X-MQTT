$defaultPath = "C:\Program Files\PowerToys\PowerToys.exe"

Write-Host "Checking whether PowerToys is already installed..."
if (Test-Path $defaultPath) {
    Write-Host "PowerToys is already installed at $defaultPath - nothing to do."
    Start-Sleep -Seconds 2
    exit 0
}

try {
    # Bundled by the installer into this same folder (C:\Scripts), not downloaded -
    # see m3_setup.iss for why.
    $installerPath = Join-Path $PSScriptRoot "PowerToysSetup-x64.exe"

    if (-not (Test-Path $installerPath)) {
        throw "Could not find $installerPath. Re-run M3PCControlSetup.exe on this PC so it gets copied into C:\Scripts, then try again."
    }

    Write-Host "Installing PowerToys silently to C:\Program Files\PowerToys - this can take a minute or two, please wait..."
    # --install_dir is passed explicitly so this always lands exactly where
    # POWERTOYS_PATH in config.bat expects it, instead of trusting whatever the
    # installer's own default happens to be.
    $proc = Start-Process -FilePath $installerPath -ArgumentList @("--silent", "--install_dir", "`"C:\Program Files\PowerToys`"") -Wait -PassThru

    if ($proc.ExitCode -ne 0) {
        throw "The PowerToys installer exited with code $($proc.ExitCode)."
    }

    if (-not (Test-Path $defaultPath)) {
        throw "The installer reported success but PowerToys.exe still isn't at $defaultPath."
    }

    Write-Host "PowerToys installed successfully."

    # Load the Crime Scene desk PC's saved config (Keyboard Manager remaps, etc.).
    # This file must be named settings_<numbers>.ptb - that's PowerToys' own
    # required naming pattern for its Settings > General > Restore feature to
    # recognize a backup at all.
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
            [System.Windows.Forms.MessageBox]::Show("PowerToys installed, but could not automatically apply the saved settings file.`n`nError: $($_.Exception.Message)`n`nA copy was placed in $restoreFolder - you can try applying it manually from PowerToys Settings > General > Restore.", "Settings Restore Failed", "OK", "Warning")
        }
    }
    else {
        Write-Host "No settings_*.ptb file found in $PSScriptRoot - PowerToys will keep its default settings."
    }

    # Launch it once so it's actually running (and registers its own startup
    # task) instead of sitting installed-but-not-running until next logon.
    Start-Process -FilePath $defaultPath

    Start-Sleep -Seconds 2
    exit 0
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Could not automatically install PowerToys.`n`nError: $($_.Exception.Message)`n`nYou can install it manually from https://aka.ms/installpowertoys and then just re-run the M3 PC Setup icon to save this PC's settings again.", "PowerToys Install Failed", "OK", "Error")
    exit 1
}
