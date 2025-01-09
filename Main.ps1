# Hat's MC Launcher - Main - Tyler Hatfield - v0.4
#CORENOTE- Pending Self Update Functionality

# Elevation function
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Add-Type -AssemblyName System.Windows.Forms
    try {
        [System.Windows.Forms.MessageBox]::Show("This script requires elevation. Please grant Administrator permissions.", "Elevation Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
        exit
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error during elevation request: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }
}

# Script setup
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
$LogPathName = 'HMCLInstallerLog.txt'
$LogPath = Join-Path -Path $DirLogs -ChildPath $logPathName
$FunctionsPath = Join-Path -Path $DirBin -ChildPath 'Functions.ps1'
. "$FunctionsPath"

# GUI Implementation
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Hat's MC Launcher"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Buttons
$btnInstallModpack = New-Object System.Windows.Forms.Button
$btnInstallModpack.Text = "Install ModPack"
$btnInstallModpack.Size = New-Object System.Drawing.Size(150, 40)
$btnInstallModpack.Location = New-Object System.Drawing.Point(125, 50)
$form.Controls.Add($btnInstallModpack)

$btnCreateCustomModpack = New-Object System.Windows.Forms.Button
$btnCreateCustomModpack.Text = "Create Custom ModPack"
$btnCreateCustomModpack.Size = New-Object System.Drawing.Size(150, 40)
$btnCreateCustomModpack.Location = New-Object System.Drawing.Point(125, 100)
$form.Controls.Add($btnCreateCustomModpack)

$btnTroubleshooting = New-Object System.Windows.Forms.Button
$btnTroubleshooting.Text = "Troubleshooting"
$btnTroubleshooting.Size = New-Object System.Drawing.Size(150, 40)
$btnTroubleshooting.Location = New-Object System.Drawing.Point(125, 150)
$form.Controls.Add($btnTroubleshooting)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = New-Object System.Drawing.Size(150, 40)
$btnExit.Location = New-Object System.Drawing.Point(125, 200)
$form.Controls.Add($btnExit)

# Progress Bar Style
function Create-ProgressBar {
    param (
        [int]$x,
        [int]$y
    )
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Style = "Continuous"
    $progressBar.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00008b")  # Dark blue
    $progressBar.Size = New-Object System.Drawing.Size(300, 20)
    $progressBar.Location = New-Object System.Drawing.Point($x, $y)
    return $progressBar
}

# Install ModPack Submenu
$btnInstallModpack.Add_Click({
	if (-not (Test-Path -Path $DirModpacks)) {
		New-Item -ItemType Directory -Path $DirModpacks | Out-Null
	}
	
    $form.Hide()

    $installForm = New-Object System.Windows.Forms.Form
    $installForm.Text = "Install ModPack"
    $installForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $installForm.Size = New-Object System.Drawing.Size(400, 400)
    $installForm.StartPosition = "CenterScreen"

    $btnDownloadDefault = New-Object System.Windows.Forms.Button
    $btnDownloadDefault.Text = "Download Default ModPacks"
    $btnDownloadDefault.Size = New-Object System.Drawing.Size(200, 40)
    $btnDownloadDefault.Location = New-Object System.Drawing.Point(100, 50)
    $installForm.Controls.Add($btnDownloadDefault)

    $btnRegisterCustom = New-Object System.Windows.Forms.Button
    $btnRegisterCustom.Text = "Register Custom ModPack"
    $btnRegisterCustom.Size = New-Object System.Drawing.Size(200, 40)
    $btnRegisterCustom.Location = New-Object System.Drawing.Point(100, 100)
    $installForm.Controls.Add($btnRegisterCustom)

    $btnInstallSelected = New-Object System.Windows.Forms.Button
    $btnInstallSelected.Text = "Install Selected ModPacks"
    $btnInstallSelected.Size = New-Object System.Drawing.Size(200, 40)
    $btnInstallSelected.Location = New-Object System.Drawing.Point(100, 150)
    $installForm.Controls.Add($btnInstallSelected)

    $btnReturn = New-Object System.Windows.Forms.Button
    $btnReturn.Text = "Return to Main Menu"
    $btnReturn.Size = New-Object System.Drawing.Size(200, 40)
    $btnReturn.Location = New-Object System.Drawing.Point(100, 350)
    $installForm.Controls.Add($btnReturn)

    # Create checkboxes for ZIP files in $DirModpacks
    $zipFiles = Get-ChildItem -Path $DirModpacks -Filter "*.zip"
    $yOffset = 200
    $checkboxes = @()

    $btnInstallSelected.Enabled = $false
	$btnInstallSelected.ForeColor = [System.Drawing.Color]::Gray

	$lblNoModPacks = New-Object System.Windows.Forms.Label
	$lblNoModPacks.Text = "No mod packs available to install."
	$lblNoModPacks.Size = New-Object System.Drawing.Size(300, 20)
	$lblNoModPacks.Location = New-Object System.Drawing.Point(50, 200)
	$lblNoModPacks.ForeColor = [System.Drawing.Color]::Gray
	$lblNoModPacks.Visible = $false
	$installForm.Controls.Add($lblNoModPacks)

	if ($zipFiles.Count -eq 0) {
		$lblNoModPacks.Visible = $true
	} else {
		foreach ($file in $zipFiles) {
			$checkbox = New-Object System.Windows.Forms.CheckBox
			$checkbox.Text = ([System.IO.Path]::GetFileNameWithoutExtension($file.Name))
			$checkbox.Location = New-Object System.Drawing.Point(100, $yOffset)
			$checkbox.Size = New-Object System.Drawing.Size(200, 20)
			$installForm.Controls.Add($checkbox)
			$checkboxes += $checkbox
			$yOffset += 30
		}
		$btnInstallSelected.Enabled = $true
		$btnInstallSelected.ForeColor = [System.Drawing.Color]::Black
	}


    # Button Actions
    $btnDownloadDefault.Add_Click({
		# Create and show the progress bar
		$progressBar = Create-ProgressBar -x 50 -y 350
		$progressBar.Style = "Marquee"
		$installForm.Controls.Add($progressBar)
		$progressBar.Visible = $true
		$installForm.Refresh()  # Force UI update
		
        Log-Message "Downloading Default ModPacks..." "Info"
        $tempZipPath = Join-Path -Path $DirTemp -ChildPath "DefaultModpacks.zip"

        if (-not (Test-Path -Path $DirTemp)) {
            New-Item -ItemType Directory -Path $DirTemp | Out-Null
        }

        $maxRetries = 3
		$attempt = 0
		$success = $false
		
        try {
			while (-not $success -and $attempt -lt $maxRetries) {
				try {
					Invoke-WebRequest -Uri "https://mc.hatsthings.com/wp-content/uploads/2025/01/DefaultModpacks.zip" -OutFile $tempZipPath -ErrorAction Stop
					$success = $true
				} catch {
					$attempt++
					Log-Message "Attempt $attempt of $maxRetries failed: $_" "Error"
					Start-Sleep -Seconds 5
				}
			}

			if (-not $success) {
				Log-Message "Failed to download Default ModPacks after $maxRetries attempts." "Error"
				[System.Windows.Forms.MessageBox]::Show("Failed to download Default ModPacks after multiple attempts. Please check your internet connection and try again.", "Error")
				return
			}
            Expand-Archive -Path $tempZipPath -DestinationPath $DirModpacks -Force
            Remove-Item -Path $tempZipPath -Force
            Log-Message "Default ModPacks downloaded and extracted successfully." "Success"
            [System.Windows.Forms.MessageBox]::Show("Default ModPacks downloaded and extracted successfully!", "Success")
        } catch {
            Log-Message "Failed to download or extract Default ModPacks: $_" "Error"
            [System.Windows.Forms.MessageBox]::Show("Failed to download or extract Default ModPacks. Please try again later.", "Error")
        } finally {
			# Remove or hide the progress bar once the operation is complete
			$progressBar.Visible = $false
			$installForm.Controls.Remove($progressBar)
			$installForm.Refresh()
		}

        # Refresh checkboxes
        foreach ($checkbox in $checkboxes) {
            $installForm.Controls.Remove($checkbox)
        }

        $zipFiles = Get-ChildItem -Path $DirModpacks -Filter "*.zip"
        $yOffset = 200
        $checkboxes = @()

        if ($zipFiles.Count -eq 0) {
			$lblNoModPacks.Visible = $true
			$btnInstallSelected.Enabled = $false
			$btnInstallSelected.ForeColor = [System.Drawing.Color]::Gray
		} else {
			$lblNoModPacks.Visible = $false
			foreach ($file in $zipFiles) {
				$checkbox = New-Object System.Windows.Forms.CheckBox
				$checkbox.Text = ([System.IO.Path]::GetFileNameWithoutExtension($file.Name))
				$checkbox.Location = New-Object System.Drawing.Point(100, $yOffset)
				$checkbox.Size = New-Object System.Drawing.Size(200, 20)
				$installForm.Controls.Add($checkbox)
				$checkboxes += $checkbox
				$yOffset += 30
			}
			$btnInstallSelected.Enabled = $true
			$btnInstallSelected.ForeColor = [System.Drawing.Color]::Black
		}
    })

    $btnInstallSelected.Add_Click({
        foreach ($checkbox in $checkboxes) {
            if ($checkbox.Checked) {
                $zipFilePath = Join-Path -Path $DirModpacks -ChildPath "$($checkbox.Text).zip"
                try {
					Log-Message "Installing ModPack from: $zipFilePath" "Info"
					InstallModpack -zipPath $zipFilePath
				} catch {
					Log-Message "Failed to install ModPack from $zipFilePath: $_" "Error"
					[System.Windows.Forms.MessageBox]::Show("Failed to install ModPack: $($checkbox.Text). Please check the file and try again.", "Error")
				}
            }
        }
        [System.Windows.Forms.MessageBox]::Show("Selected ModPacks installed successfully!", "Success")
    })

    $btnRegisterCustom.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.InitialDirectory = $DesktopPath
        $openFileDialog.Filter = "ZIP files (*.zip)|*.zip"
        $openFileDialog.ShowDialog() | Out-Null

        if ($openFileDialog.FileName -ne "") {
            $destination = Join-Path -Path $DirModpacks -ChildPath (Split-Path $openFileDialog.FileName -Leaf)
            Copy-Item -Path $openFileDialog.FileName -Destination $destination -Force
            Log-Message "Registered custom ModPack: $destination" "Success"
            [System.Windows.Forms.MessageBox]::Show("Custom ModPack registered successfully!", "Success")

            # Refresh checkboxes
            foreach ($checkbox in $checkboxes) {
                $installForm.Controls.Remove($checkbox)
            }

            $zipFiles = Get-ChildItem -Path $DirModpacks -Filter "*.zip"
            $yOffset = 200
            $checkboxes = @()

            if ($zipFiles.Count -eq 0) {
				$lblNoModPacks.Visible = $true
				$btnInstallSelected.Enabled = $false
				$btnInstallSelected.ForeColor = [System.Drawing.Color]::Gray
			} else {
				$lblNoModPacks.Visible = $false
				foreach ($file in $zipFiles) {
					$checkbox = New-Object System.Windows.Forms.CheckBox
					$checkbox.Text = ([System.IO.Path]::GetFileNameWithoutExtension($file.Name))
					$checkbox.Location = New-Object System.Drawing.Point(100, $yOffset)
					$checkbox.Size = New-Object System.Drawing.Size(200, 20)
					$installForm.Controls.Add($checkbox)
					$checkboxes += $checkbox
					$yOffset += 30
				}
				$btnInstallSelected.Enabled = $true
				$btnInstallSelected.ForeColor = [System.Drawing.Color]::Black
			}
        }
    })

    $btnReturn.Add_Click({
        $installForm.Close()
        Log-Message "Returned to Main Menu" "Info"
        $form.Show()
    })

    $installForm.Add_Shown({ $installForm.Activate() })
    [System.Windows.Forms.Application]::Run($installForm)
})

# Create Custom ModPack Submenu
$btnCreateCustomModpack.Add_Click({
    Log-Message "Creating Custom ModPack..." "Info"
    $tempModPackDir = Join-Path -Path $DirTemp -ChildPath "CustomModPack"
    if (Test-Path $tempModPackDir) { Remove-Item -Recurse -Force -Path $tempModPackDir }
    New-Item -ItemType Directory -Path $tempModPackDir | Out-Null

    explorer.exe $tempModPackDir

    $helpButton = New-Object System.Windows.Forms.Button
    $helpButton.Text = "Help"
    $helpButton.Size = New-Object System.Drawing.Size(80, 30)
    $helpButton.Location = New-Object System.Drawing.Point(10, 10)
    $helpButton.Add_Click({ Start-Process "https://github.com/TylerHats/Hats-MC-Launcher/wiki/Custom-Mod-Packs" })
    
    [System.Windows.Forms.MessageBox]::Show("Add your files to the directory. Click OK to continue.", "Custom ModPack")

    $zipFilePath = Join-Path -Path $DirModpacks -ChildPath "CustomModPack.zip"
    if (Test-Path $zipFilePath) { Remove-Item -Path $zipFilePath -Force }

	try {
		Compress-Archive -Path "$tempModPackDir\*" -DestinationPath $zipFilePath -ErrorAction Stop
	} catch {
		Log-Message "Failed to compress files: $_" "Error"
		[System.Windows.Forms.MessageBox]::Show("Failed to compress files. Ensure no files are open or locked and that you have write permissions to the destination directory.", "Error")
		Remove-Item -Recurse -Force -Path $tempModPackDir
		return
	}
    Log-Message "Custom ModPack created and saved to $zipFilePath" "Success"

    Remove-Item -Recurse -Force -Path $tempModPackDir
    [System.Windows.Forms.MessageBox]::Show("Custom ModPack created successfully!", "Success")
})

# Troubleshooting Button Action
$btnTroubleshooting.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("This function is still under development.", "Troubleshooting")
})

# Exit Button Action
$btnExit.Add_Click({
    Log-Message "Exiting Hat's MC Launcher." "Info"
    $form.Close()
})

# Show the Main Form
$form.Add_Shown({ $form.Activate() })
Log-Message "Main GUI loaded." "Info"
[System.Windows.Forms.Application]::Run($form)