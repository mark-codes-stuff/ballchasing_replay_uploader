Write-Host "For FAQ/help or to get the latest version of this script please check https://github.com/mark-codes-stuff/ballchasing_replay_uploader"

try
{
# Grabbing current username and getting RL replay path
$currentUser = $env:username
$replayPath = "C:\Users\$currentUser\Documents\My Games\Rocket League\TAGame\Demos"

# Testing to make sure the path is actually valid and the prerequisite files exist too & make the visibility pref file if it's not detected
	if (-not (Test-Path -Path $replayPath))
	{
		Write-Host "There is something wrong with the replay folder path: $replayPath"
		exit
	}
	
	if (-not (Test-Path -Path "./token.txt"))
	{
		Write-Host "token.txt file not detected, please ensure token.txt is saved in the same folder as the script .ps1 file"
		exit
	}

	function Test-Visibility
	{
		if (-not (Test-Path -Path "./visibility.txt"))
		{
			Write-Host "visibility.txt file not detected, the script will create the file now"
			$visibilityPref = Read-Host "Please enter your replay visibility preference: enter 1 for public, 2 for unlisted, 3 for private"
				if ($visibilityPref -eq 1)
				{
					New-Item -Path . -Name "visibility.txt" -ItemType File -Value "public"
				}
				elseif ($visibilityPref -eq 2)
				{
					New-Item -Path . -Name "visibility.txt" -ItemType File -Value "unlisted"
				}
				elseif ($visibilityPref -eq 3)
				{
					New-Item -Path . -Name "visibility.txt" -ItemType File -Value "private"
				}
				else
				{
					Write-Host "Invalid input detected"
					Test-Visibility
				}

		}
	}
	
	Test-Visibility

# Create a new FileSystemWatcher, including specifying path and file types to monitor
$fileWatcher = New-Object System.IO.FileSystemWatcher
$fileWatcher.Path = $replayPath
$fileWatcher.Filter = "*.replay"
$fileWatcher.IncludeSubDirectories = $false
$fileWatcher.EnableRaisingEvents = $true

# Some more debug writes
Write-Host "Watcher is watching $replayPath"
$visibilityPref = Get-Content -Path .\visibility.txt
Write-Host "Replay visibility is set to $visibilityPref"
Write-Host "Replay uploader is running.."
Write-Host "Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota"
Write-Host "To see your current quota, see the upload page here: https://ballchasing.com/upload"

# Action newly created files
$actionHandle =
	{
		# Declaring a few variables inside the block
		$token = Get-Content -Path .\token.txt
		$uploadURL = "https://ballchasing.com/api/v2/upload?visibility=" + $visibilityPref
		#Write-Host "File $($Event.SourceEventArgs.ChangeType)"
		$replayFile = $Event.SourceEventArgs.FullPath
		$replayName = $Event.SourceEventArgs.Name
		Write-Host "New file detected $replayFile"
		
		# Also need to encode the file as Invoke-RestMethod in PS 5.1 won't do this easily
		Write-Host "Encoding file for upload"
		$encObject = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
		$rawFile = [System.IO.File]::ReadAllBytes($replayFile)
		$encodedFile = $encObject.GetString($rawFile)
		
		# We need a random ID for the request boundary
		$boundary = [System.Guid]::NewGuid().ToString()
		
		# Creating the body of the request
		$newLine = "`r`n"
		$bodyInfo = (
			"--$boundary",
			"Content-Disposition: form-data; name=`"file`"; filename=`"$replayName`"",
			"Content-Type: application/octet-stream$newLine",
			$encodedFile,
			"--$boundary--$newLine"
		)
		$body = $bodyInfo -join $newLine
			try
			{
				Start-Sleep -Seconds 1
				$headers = 
				@{
					"Authorization" = $token
				}
				# If anything breaks in future these can be uncommented for checks
				# Write-Host "The value of $headers is: '$headers'"
				# Write-Host "Token in header: '$($headers['Authorization'])'"
				# Write-Host "Upload URL is: '$uploadURL'"
				Invoke-RestMethod -Uri $uploadURL -Method Post -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $body -UseBasicParsing
				Write-Host "Upload successful"
			}
			catch
			{
				Write-Host "Upload failed: $($_.Exception.Message)"
			}
	}

# Error handling if the system file watcher crashes (probably won't ever happen but you never know)
$errorHandle =
	{
		Write-Host "As unlikely as it might be, the system file watcher has encountered an overflow error, the script will now exit"
		exit
	}

# Subscribe to events for newly created files, and also error events in case there's an issue
$actionableEvent = Register-ObjectEvent -InputObject $fileWatcher -EventName "Created" -Action $actionHandle
$errorEvent = Register-ObjectEvent -InputObject $fileWatcher -EventName "Error" -Action $errorHandle

# Keep alive
while($true)
	{
		Start-Sleep -Seconds 1
	}

}

# Cleanly remove the watcher & event handlers on exit
finally
{
$fileWatcher.EnableRaisingEvents = $false ; #Write-Host "Disabling watcher events"
$fileWatcher.Dispose() ; #Write-Host "Killing watcher"
$actionableEvent | Unregister-Event ; #Write-Host "Unregistering file create event subscription"
$errorEvent | Unregister-Event ; #Write-Host "Unregistering error event subscription"
}
