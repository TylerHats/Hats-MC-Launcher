# Hat's MC Launcher - Uninstaller - Tyler Hatfield - v0.3

# Elevation function
$IsElevated = ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsElevated) {
	Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
	Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

# Script setup
Clear-Host
$ExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$ExeDir = Split-Path -Path $ExePath
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$AppDataPath = $Env:APPDATA
$HMCPath = Join-Path -Path $AppDataPath -ChildPath '.HatsMC'
$DirLogs = Join-Path -Path $HMCPath -ChildPath 'Logs'
$DirBin = Join-Path -Path $HMCPath -ChildPath 'Bin'
$DirDependencies = Join-Path -Path $DirBin -ChildPath 'Dependencies'
$DirProfiles = Join-Path -Path $HMCPath -ChildPath 'Profiles'
$DirEtc = Join-Path -Path $HMCPath -ChildPath 'Etc'
$DirJava = Join-Path -Path $DirBin -ChildPath 'Java'
$DirTemp = Join-Path -Path $DirEtc -ChildPath 'Temp'
$CurrentDate = Get-Date -Format "yyyyMMdd"
$CurrentTime = Get-Date -Format "HHmmss"
$StartMenuInt = [System.Environment]::GetFolderPath('StartMenu')
$StartMenuPrograms = Join-Path -Path $StartMenuInt -ChildPath "Programs"
$StartMenuApp = Join-Path -Path $StartMenuPrograms -ChildPath "Hats MC Launcher"

# Script start
$Uninstall = Read-Host "This script will uninstall the Hat's MC Launcher and remove related data.`nYou will be given an option to backup data like word saves. Continue? (y/N)"
If (-not ($Uninstall.ToLower() -in @("yes", "y"))) { exit }
$Backup = Read-Host ""