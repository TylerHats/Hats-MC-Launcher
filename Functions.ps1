# Hat's MC Launcher - Functions - Tyler Hatfield - v0.3

# Available Functions:
# Log-Message (Adds time and level information and logs a message to the consol and to $LogPath)
# GetRAMGB (Stores the system's installed RAM amount to $SystemRAM rounded to the nearest GB)

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