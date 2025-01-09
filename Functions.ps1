# Hat's MC Launcher - Functions - Tyler Hatfield - v0.4

# Available Functions:
# Log-Message (Adds time and level information and logs a message to the consol and to $LogPath)
# GetRAMGB (Stores the system's installed RAM amount to $SystemRAM rounded to the nearest GB)
# MakeMCProfile (Creates a new MC launcher profile with the specified information passed to the function in this order: "Name" "Game Version" "Install Location" "Java Args")
# InstallModpack (Installs a modpack from the provided path as a parameter if the modpack ZIP archive is properly formatted)

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

function GetRAMGB {
	$totalRAMGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
	$SystemRAM = [math]::Round($totalRAMGB)
}

function MakeMCProfile {
	param(
		[string]$profileNameFUNC,
		[string]$gameVersionFUNC,
		[string]$installLocationFUNC,
		[string]$javaArgsFUNC
	)
	$launcherProfilesPath = "$env:APPDATA\.minecraft\launcher_profiles.json"
	
	if (-not (Test-Path -Path $installLocationFUNC)) {
		New-Item -ItemType Directory -Path $installLocationFUNC -Force | Out-Null
	}
	
	if (-not (Test-Path -Path $launcherProfilesPath)) {
		Log-Message "launcher_profiles.json file not found. Ensure the Minecraft launcher has been run at least once." "Error"
		$MakeMCProfileFailedNoJSON = 1
		Return
	}
	
	$launcherProfiles = Get-Content -Path $launcherProfilesPath -Raw | ConvertFrom-Json
	
	if (-not $launcherProfiles.profiles) {
		$launcherProfiles.profiles = @{}
	}
	
	$newProfile = [PSCustomObject]@{
		created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffz")
		lastUsed = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffz")
		lastVersionID = $gameVersionFUNC
		javaArgs = $javaArgsFUNC
		name = $profileNameFUNC
		type = "custom"
		gameDir = $installLocationFUNC
	}
	
	$launcherProfiles.profiles[$profileNameFUNC] = $newProfile
	
	$launcherProfiles | ConvertTo-Json -Depth 10 | Set-Content -Path $launcherProfilesPath -Force
	
	Log-Message "MC profile '$profileNameFUNC' added successfully!" "Success"
}

function InstallModpack {
	#Needs setup to receive path to modpack zip file and setup based on the modpack zip file
}