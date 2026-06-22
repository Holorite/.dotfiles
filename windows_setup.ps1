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
$taskName = "lemonade-server"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $action  = New-ScheduledTaskAction -Execute $lemonadeExe -Argument "server --allow 127.0.0.1"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Limited -Force | Out-Null
}
# Start it now so it's up without needing to log out/in.
if ((Get-ScheduledTask -TaskName $taskName).State -ne "Running") {
    Start-ScheduledTask -TaskName $taskName
}

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

