# Hat's MC Launcher - Installer - Tyler Hatfield - v0.4

# Elevation function
$IsElevated = ([System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsElevated) {
	Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
	Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

#System compatibility check
if (-not ([System.Environment]::Is64BitOperatingSystem)) {
	$IgnoreCompat = Read-Host "This setup is intended for 64bit machines and may not work correctly on your system, continue? (y/N)"
	if (-not ($IgnoreCompat.ToLower() -in @("yes", "y"))) {
		Read-Host "Press any key to exit"
		Exit
	}
}
if ($PSVersionTable.PSVersion.Major -lt 5) {
	$FullVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
	Write-Host "The Hat's MC Launcher requires PowerShell version 5 or newer, version $FullVersion is currently installed."
	Read-Host "Please run Windows Update and attempt installation again. Press any key to exit"
	Exit
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
$DirModpacks = Join-Path -Path $DirEtc -ChildPath 'Modpacks'
$CurrentDate = Get-Date -Format "yyyyMMdd"
$CurrentTime = Get-Date -Format "HHmmss"
$LogPathName = "HMCLInstallerLog-$CurrentDate-$CurrentTime.txt"
$LogPath = Join-Path -Path $ExeDir -ChildPath $logPathName
$StartMenuInt = [System.Environment]::GetFolderPath('StartMenu')
$StartMenuPrograms = Join-Path -Path $StartMenuInt -ChildPath "Programs"
$StartMenuApp = Join-Path -Path $StartMenuPrograms -ChildPath "Hats MC Launcher"
New-Item -Path "$LogPath" -ItemType File -Force
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
	if (Test-Path -Path "$DirBin\Uninstall.exe") {
		$UninstallNow = Read-Host "It appears the Hat's MC Launcher is already installed, would you like to uninstall now? (y/N)"
		if ($UninstallNow.ToLower() -in @("yes", "y")) {
			Start-Process -FilePath "$DirBin\Uninstall.exe" -WindowStyle Normal
			Exit
		} else {
			Read-Host "The Hat's MC Launcher is already installed. Press any key to exit"
			Exit
		}
	} else {
		Write-Host "The Hat's MC Launcher seems to have been previously installed but files are missing or corrupt."
		Write-Host "Would you like to cleanup any files from previous installations and reinstall?"
		$WipeInstall = Read-Host "Any previous files such as world data and game files will be moved to a folder called `".HatsMC-OLD-DATE-TIME`" (y/N)"
		if ($WipeInstall.ToLower() -in @("yes", "y")) {
			Rename-Item -Path "$HMCPath" -NewName ".HatsMC-OLD-$CurrentDate-$CurrentTime"
		} else {
			Read-Host "Setup cannot continue due to a previous corrupt installation. Press any key to exit"
		}
	}
}
Log-Message "Script setup and system checks complete, beginning installation..."

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
	"$DirModpacks",
	"$DirDependencies",
	"$StartMenuPrograms",
	"$StartMenuApp"
)
Foreach ($DirectoryPath in $Directories) {
	If (-not (Test-Path -Path $DirectoryPath)) {
		# If the directory does not exist, create it and log the output
		New-Item -ItemType Directory -Path $DirectoryPath | Out-File -Append -FilePath $logPath
	} Else {
		# Log that the directory already exists
		Log-Message "Directory already exists: $DirectoryPath"
	}
}

# Download required files for setup
Log-Message "Downloading files for setup..."
Try {
	Start-BitsTransfer -Source 'https://mc.hatsthings.com/wp-content/uploads/2025/01/PortableGit.zip' -Destination "$DirTemp\PGit.zip" | Out-File -Append -FilePath $logPath
} Catch {
	Log-Message "File download failed, retrying..." -level "Error"
	Try {
		Start-BitsTransfer -Source 'https://mc.hatsthings.com/wp-content/uploads/2025/01/PortableGit.zip' -Destination "$DirTemp\PGit.zip" | Out-File -Append -FilePath $logPath
	} Catch {
		Log-Message "File download failed again, please retry setup later."
		Read-Host "Press any key to exit"
		Exit
	}
}

# Extract files
Log-Message "Extracting downloaded files..."
Expand-Archive -Path "$DirTemp\PGit.zip" -DestinationPath "$DirEtc" -Force | Out-File -Append -FilePath $logPath

# Clone GitHub files with PortableGit and only keep needed files
Log-Message "Cloning GitHub files and cleaning up..."
Try {
	& "$DirEtc\PortableGit\Bin\Git.exe" clone --branch main --single-branch https://github.com/TylerHats/Hats-MC-Launcher $DirBin | Out-File -Append -FilePath $logPath
} Catch {
	Log-Message "Git clone failed, retrying..." -level "Error"
	Try {
		& "$DirEtc\PortableGit\Bin\Git.exe" clone --branch main --single-branch https://github.com/TylerHats/Hats-MC-Launcher $DirBin | Out-File -Append -FilePath $logPath
	} Catch {
		Log-Message "Git clone failed again, please retry setup later."
		Read-Host "Press any key to exit"
		Exit
	}
}
$KeepFiles = @(
	"Main.ps1",
	"Functions.ps1",
	"Uninstaller.ps1",
	"HMCLIcon.ico"
)
$BinFiles = Get-ChildItem -Path $DirBin -File
foreach ($File in $BinFiles) {
	if ($File.Name -notin $KeepFiles) {
		Try {
			Remove-Item -Path $File.FullName -Force | Out-File -Append -FilePath $logPath
		} Catch {
			Log-Message "Failed to remove file: $($File.FullName)" -level "Error"
		}
	}
}

# Make main script executable
Install-PackageProvider -Name NuGet -Force | Out-File -Append -FilePath $logPath
Try {
	Install-Module -Name PS2EXE -Scope CurrentUser -Force | Out-File -Append -FilePath $logPath
} Catch {
	Log-Message "PS2EXE Failed to install, retrying..."
	Try {
		Install-Module -Name PS2EXE -Scope CurrentUser -Force | Out-File -Append -FilePath $logPath
	} Catch {
		Log-Message "PS2EXE Failed to install again, please retry setup later."
		Read-Host "Press any key to exit"
		Exit
	}
}
Invoke-PS2EXE -InputFile "$DirBin\Main.ps1" -OutputFile "$DirBin\HatsMCLauncher.exe" -NoConsole -IconFile "$DirBin\HMCLIcon.ico" | Out-File -Append -FilePath $logPath

# Make uninstall script executable and register program with Windows
Invoke-PS2EXE -InputFile "$DirBin\Uninstaller.ps1" -OutputFile "$DirBin\Uninstall.exe" | Out-File -Append -FilePath $logPath
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Hats MC Launcher"
New-Item -Path $RegPath -Force | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "DisplayName" -Value "Hat's MC Launcher" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "DisplayIcon" -Value "$DirBin\HatsMCLauncher.exe" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "UninstallString" -Value "`"$DirBin\Uninstall.exe`"" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value "0.1" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "Publisher" -Value "Hat's Things" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "InstallLocation" -Value "$HMCPath" | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "NoModify" -Value 1 -Type DWORD | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "NoRepair" -Value 1 -Type DWORD | Out-File -Append -FilePath $logPath
Set-ItemProperty -Path $RegPath -Name "InstallDate" -Value "$CurrentDate" | Out-File -Append -FilePath $logPath
$FolderSize = [math]::Floor((Get-ChildItem -Path "$HMCPath" -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB)
Set-ItemProperty -Path $RegPath -Name "EstimatedSize" -Value $FolderSize -Type DWORD | Out-File -Append -FilePath $logPath

# Create shortcuts if desired
$DShort = Read-Host "Create program shortcut on the desktop? (y/N)"
$SMShort = Read-Host"Create program shortcut in the start menu? (y/N)"
$WshShell = New-Object -ComObject WScript.Shell | Out-File -Append -FilePath $logPath
$shortcut = $WshShell.CreateShortcut("$DirBin\Hats MC Launcher.lnk") | Out-File -Append -FilePath $logPath
$shortcut.TargetPath = "$DirBin\HatsMCLauncher.exe" | Out-File -Append -FilePath $logPath
$shortcut.Save()
if ($DShort.ToLower() -in @("yes", "y")) {
	Copy-Item -Path "$DirBin\Hats MC Launcher.lnk" -Destination "$DesktopPath\Hats MC Launcher.lnk" -Force | Out-File -Append -FilePath $logPath
}
if ($SMShort.ToLower() -in @("yes", "y")) {
	Copy-Item -Path "$DirBin\Hats MC Launcher.lnk" -Destination "$StartMenuApp\Hats MC Launcher.lnk" -Force | Out-File -Append -FilePath $logPath
}

# Cleanup and closing notes
Remove-Item -Path "$DirTemp\PGit.zip" -Force -ErrorAction SilentlyContinue | Out-File -Append -FilePath $logPath
Read-Host "Installation complete, press any key to exit"