$wtPath = (Get-ChildItem "$env:LOCALAPPDATA\Packages" | Where-Object { $_.Name -like "Microsoft.WindowsTerminal*" }).FullName
New-Item -ItemType SymbolicLink -Path "$wtPath\LocalState\settings.json" -Target "$PSScriptRoot\settings.json" -Force
