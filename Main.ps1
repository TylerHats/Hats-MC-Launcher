# Hat's MC Launcher - Main - Tyler Hatfield - v0.2

# Elevation function
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
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
$LogPathName = 'HMCLInstallerLog.txt'
$LogPath = Join-Path -Path $DirLogs -ChildPath $logPathName
$FunctionsPath = Join-Path -Path $DirBin -ChildPath 'Functions.ps1'
. "$FunctionsPath"

# Prepare Windows form 
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Hat''s MC Launcher'
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = 'CenterScreen'

