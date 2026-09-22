@echo off
REM Placeholder until the setup icon is run for the first time.
set BROKER_HOST=
set BROKER_PORT=1883
set TOPIC=
set SECRET=SHUTDOWN_NOW_9x7q
set RESTART_SECRET=RESTART_NOW_9x7q
set REFRESH_SECRET=REFRESH_NOW_9x7q
set CLEARCACHE_SECRET=CLEARCACHE_NOW_9x7q
set STOPKM_SECRET=STOPKM_NOW_9x7q
set RESTARTKM_SECRET=RESTARTKM_NOW_9x7q
set BROWSER_PROCESS=MythricClient
set POWERTOYS_PATH=%LocalAppData%\PowerToys\PowerToys.exe
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

