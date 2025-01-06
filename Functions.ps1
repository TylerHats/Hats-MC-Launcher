# Hat's MC Launcher - Functions - Tyler Hatfield - v0.2

# Log-Message takes a string or command output and sends it both to the registered $logPath and the PS consol
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