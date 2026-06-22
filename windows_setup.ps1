$wtPath = (Get-ChildItem "$env:LOCALAPPDATA\Packages" | Where-Object { $_.Name -like "Microsoft.WindowsTerminal*" }).FullName
New-Item -ItemType SymbolicLink -Path "$wtPath\LocalState\settings.json" -Target "$PSScriptRoot\windows\terminal\settings.json" -Force

# ── lemonade ────────────────────────────────────────────────────────────────
# Laptop half of the $BROWSER setup: `lemonade server` listens locally; the
# work host's browser-open wrapper relays `gh browse` URLs to it over an
# ssh -R 2489 tunnel, so the tab opens here. The remote half is installed by
# install/lemonade/install.sh; see notes/improvements.md.
$lemonadeDir = "$env:LOCALAPPDATA\lemonade"
$lemonadeExe = "$lemonadeDir\lemonade.exe"
$lemonadeUrl = "https://github.com/lemonade-command/lemonade/releases/latest/download/lemonade_windows_amd64.zip"

if (-not (Test-Path $lemonadeExe)) {
    New-Item -ItemType Directory -Path $lemonadeDir -Force | Out-Null
    $zip = "$env:TEMP\lemonade.zip"
    Invoke-WebRequest -Uri $lemonadeUrl -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $lemonadeDir -Force
    Remove-Item $zip
}

# Put lemonade.exe on the user PATH (idempotent).
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$lemonadeDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$lemonadeDir", "User")
}

# Run `lemonade server` at logon, bound to loopback only (the connection always
# arrives via the SSH RemoteForward as 127.0.0.1, so no need to expose it).
#
# Launch it *detached and hidden* through a Start-Process wrapper rather than
# invoking lemonade.exe directly: a console app run directly by Task Scheduler
# is attached to a console and gets killed with STATUS_CONTROL_C_EXIT
# (0xC000013A) when that console closes. The wrapper exits immediately, leaving
# lemonade running windowless in the interactive session (required so it can pop
# the browser). ExecutionTimeLimit 0 disables the 3-day auto-stop; restart-on-
# failure revives it if it ever dies.
$taskName = "lemonade-server"
$psArgs = "Start-Process -WindowStyle Hidden -FilePath '$lemonadeExe' -ArgumentList 'server','--allow','127.0.0.1'"
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -NonInteractive -Command `"$psArgs`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3
# -Force re-registers so re-running this script applies fixes to an existing task.
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Limited -Force | Out-Null

# Start it now so it's up without needing to log out/in.
Start-ScheduledTask -TaskName $taskName

# ── ssh RemoteForward (laptop = chain root) ──────────────────────────────────
# The Linux hosts get this block via the stowed ssh/ package; the laptop isn't
# stowed, so append it to %USERPROFILE%\.ssh\config (idempotent, marker-guarded).
# Same port on every hop chains the tunnel back here. Excludes github (it denies
# forwarding). Built-in Windows OpenSSH reads this file.
$sshDir = "$env:USERPROFILE\.ssh"
$sshConfig = "$sshDir\config"
$marker = "# >>> lemonade RemoteForward (managed by windows_setup.ps1) >>>"
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
if (-not ((Test-Path $sshConfig) -and (Select-String -Path $sshConfig -SimpleMatch $marker -Quiet))) {
    $block = @"

$marker
Host * !github.com !github.qualcomm.com !github.com-qcom-eng-650
    RemoteForward 2489 127.0.0.1:2489
    ExitOnForwardFailure no
    ServerAliveInterval 30
    ServerAliveCountMax 3
# <<< lemonade RemoteForward <<<
"@
    Add-Content -Path $sshConfig -Value $block
}

