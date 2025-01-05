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
$LogPath = Join-Path -Path $ExeDir -ChildPath $logPathName
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
	"$DirTemp",
	"$DirDependencies"
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

# Clone GitHub files with PortableGit and only keep needed files
Log-Message "Cloning GitHub files and cleaning up..."
& "$DirEtc\PortableGit\Bin\Git.exe" clone --branch main --single-branch https://github.com/TylerHats/Hats-MC-Launcher $DirBin >> $LogPath
$KeepFiles = @(
	"Main.ps1",
	"Functions.ps1",
	"Uninstaller.ps1",
	"HMCLIcon.ico"
)
$BinFiles = Get-ChildItem -Path $DirBin -File
foreach ($File in $BinFiles) {
	if ($File.Name -notin $KeepFiles) {
		Remove-Item -Path $File.FullName -Force >> $LogPath
	}
}

# Make main script executable
Install-PackageProvider -Name NuGet -Force >> $LogPath
Install-Module -Name PS2EXE -Scope CurrentUser -Force >> $LogPath
Invoke-PS2EXE -InputFile "$DirBin\Main.ps1" -OutputFile "$DirBin\HatsMCLauncher.exe" -NoConsole -IconFile "$DirBin\HMCLIcon.ico" >> $LogPath

# Make uninstall script executable and register program with Windows
Invoke-PS2EXE -InputFile "$DirBin\Uninstaller.ps1" -OutputFile "$DirBin\Uninstall.exe" >> $LogPath
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Hats MC Launcher"
New-Item -Path $RegPath -Force >> $LogPath
Set-ItemProperty -Path $RegPath -Name "DisplayName" -Value "Hat's MC Launcher" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "DisplayIcon" -Value "$DirBin\HatsMCLauncher.exe" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "UninstallString" -Value "`"$DirBin\Uninstall.exe`"" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value "0.1" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "Publisher" -Value "Hat's Things" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "InstallLocation" -Value "$HMCPath" >> $LogPath
Set-ItemProperty -Path $RegPath -Name "NoModify" -Value 1 -Type DWORD >> $LogPath
Set-ItemProperty -Path $RegPath -Name "NoRepair" -Value 1 -Type DWORD >> $LogPath
$CurrentDate = (Get-Date).ToString("yyyyMMdd")
Set-ItemProperty -Path $RegPath -Name "InstallDate" -Value "$CurrentDate" >> $LogPath
$FolderSize = (Get-ChildItem -Path "$HMCPath" -Recurse | Measure-Object -Property Length -Sum).Sum
Set-ItemProperty -Path $RegPath -Name "EstimatedSize" -Value $FolderSize -Type DWORD >> $LogPath

# Create shortcuts if desired
$DShort = Read-Host "Create program shortcut on the desktop? (y/N)"
$SMShort = Read-Host"Create program shortcut in the start menu? (y/N)"
$WshShell = New-Object -ComObject WScript.Shell >> $LogPath
$shortcut = $WshShell.CreateShortcut("$DirBin\Hats MC Launcher.lnk") >> $LogPath
$shortcut.TargetPath = "$DirBin\HatsMCLauncher.exe" >> $LogPath
$shortcut.Save() >> $LogPath
if ($DShort.ToLower() -in @("yes", "y")) {
	Copy-Item -Path "$DirBin\Hats MC Launcher.lnk" -Destination "$DesktopPath\Hats MC Launcher.lnk" -Force >> $LogPath
}
if ($SMShort.ToLower() -in @("yes", "y")) {
	$startMenuPath = [System.Environment]::GetFolderPath('StartMenu')
	Copy-Item -Path "$DirBin\Hats MC Launcher.lnk" -Destination "$startMenuPath\Hats MC Launcher.lnk" -Force >> $LogPath
}
Read-Host "Installation complete, press any key to exit"