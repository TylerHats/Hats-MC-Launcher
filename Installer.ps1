# Hat's MC Launcher - Installer - Tyler Hatfield - v0.1

# Elevation function
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

#System compatibility check
if (-not ([System.Environment]::Is64BitOperatingSystem)) {
    $IgnoreCompat = Read-Host "This setup is intended for 64bit machines and may not work correctly on your system, continue? (y/N)"
	if (-not ($IgnoreCompat.ToLower() -in @("yes", "y")) {
		Read-Host "Press any key to exit"
		Exit
	}
}
if ($PSVersionTable.PSVersion.Major -lt 5) {
	$FullVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
	Write-Host "The Hat's MC Launcher requries PowerShell version 5 or newer, version $FullVersion is currently installed."
	Read-Host "Please run Windows Update and attempt installation again. Press any key to exit"
}

# Script setup
Clear-Host
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$AppDataPath = $Env:APPDATA
$HMCPath = Join-Path -Path $AppDataPath -ChildPath '.HatsMC'
$DirLogs = Join-Path -Path $HMCPath -ChildPath 'Logs'
$DirBin = Join-Path -Path $HMCPath -ChildPath 'Bin'
$DirProfiles = Join-Path -Path $HMCPath -ChildPath 'Profiles'
$DirEtc = Join-Path -Path $HMCPath -ChildPath 'Etc'
$DirJava = Join-Path -Path $DirBin -ChildPath 'Java'
$DirTemp = Join-Path -Path $DirEtc -ChildPath 'Temp'
$LogPathName = 'HMCLInstallerLog.txt'
$LogPath = Join-Path -Path $PSScriptRoot -ChildPath $logPathName
function Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    Write-Host $logMessage  # Output to console
    $logMessage | Out-File -FilePath $LogPath -Append  # Write to log
}
if (Test-Path -Path "$DirEtc") {
	if (Test-Path -Path "$DirBin\Uninstaller.ps1") {
		$UninstallNow = Read-Host "It appears the Hat's MC Launcher is already installed, would you like to uninstall now? (y/N)"
		if ($UninstallNow.ToLower() -in @("yes", "y")) {
			#LaunchUninstaller
		} else {
			Read-Host "The Hat's MC Launcher is already installed. Press any key to exit"
			Exit
		}
	} else {
		Write-Host "The Hat's MC Launcher seems to have been previously installed but files are missing or corrupt."
		Write-Host "Would you like to cleanup any files from previous installations and reinstall?"
		$WipeInstall = Read-Host "Any previous files such as world data and game files will be moved to a folder called `".HatsMC-OLD`" (y/N)"
		if ($WipeInstall.ToLower() -in @("yes", "y")) {
			#RenameCurrentInstall,proceed
		} else {
			Read-Host "Setup cannot continue due to a previous corrupt installation. Press any key to exit"
		}
	}
}
Log-Message "Script setup and system checks complete, begining installation..."

# Directory setup
Log-Message "Setting up directory structure..."
$Directories = @(
    "$HMCPath",
	"$DirLogs",
	"$DirBin",
	"$DirProfiles",
	"$DirEtc",
	"$DirJava",
	"$DirTemp"
)
foreach ($DirectoryPath in $Directories) {
    if (-not (Test-Path -Path $DirectoryPath)) {
        # If the directory does not exist, create it and log the output
        New-Item -ItemType Directory -Path $DirectoryPath >> $LogPath
    } else {
        # Log that the directory already exists
        Write-Output "Directory already exists: $DirectoryPath" | Out-File -FilePath $LogPath -Append
    }
}

# Download required files for setup
Log-Message "Downloading files for setup..."
Start-BitsTransfer -Source 'https://mc.hatsthings.com/wp-content/uploads/2025/01/PortableGit.zip' -Destination "$DirTemp\PGit.zip" >> $LogPath

# Extract files
Log-Message "Extracting downloaded files..."
Expand-Archive -Path "$DirTemp\PGit.zip" -DestinationPath "$DirEtc" >> $LogPath

# Clone GitHub files with PortableGit
