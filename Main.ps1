# Hat's MC Launcher - Main - Tyler Hatfield - v0.1

# Elevation function
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Script setup
Clear-Host
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$AppDataPath = $Env:APPDATA
$HMCPath = Join-Path -Path $AppDataPath -ChildPath '.HatsMC'
$LogPathName = "HatsMCLauncherLog.txt"
$LogFolder = Join-Path -Path $HMCPath -ChildPath 'Logs'
$LogPath = Join-Path -Path $logFolder -ChildPath $logPathName
$FunctionPath = Join-Path -Path $PSScriptRoot -ChildPath 'Functions.ps1'
. "$FunctionPath"

# Directory setup
if (-not (Test-Path -Path $DirectoryPath)) {
    # If it doesn't exist, create the directory
    New-Item -ItemType Directory -Path $DirectoryPath >> $LogPath
}