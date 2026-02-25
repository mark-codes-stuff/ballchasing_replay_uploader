# For FAQ/help or to get the latest version of this script please check https://github.com/mark-codes-stuff/ballchasing_replay_uploader

# Grabbing current user/profile path to get location of Rocket League replay folder, creating vars to use later
$replaypath = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\Demos"
$token = ""
$visibilityPref = ""
$uploadURL = ""

# Function to easily write to the console with timestamps
function Write-Log
	{
		param($logContent)
		$timestamp = Get-Date -Format HH:mm
		Write-Host "[$timestamp]: $logContent"
	}

# Function for checking the replay folder exists
function Test-ReplayFolder
{
	if (-not (Test-Path -Path $replaypath))
	{
		Write-Log "There is something wrong with the replay folder path: $replaypath"
		Write-Log "The replay folder path is derived from `$env:USERPROFILE` ($env:USERPROFILE) and \Documents\My Games\Rocket League\TAGame\Demos"
		Write-Log "The script will now exit"
		pause
		exit
	}
}

# Function for checking the token file exists, creating it if not
function Test-Token
{
	if (-not (Test-Path -Path "$replaypath\token.txt"))
	{
		Write-Log "token.txt file not detected, the script will create the file now"
		Write-Log "Go to https://ballchasing.com/upload and copy your upload token to the clipboard"
		$tokenInput = Read-Host "Paste your token in here"
		New-Item -Path $replaypath -Name "token.txt" -ItemType File -Value $tokenInput
		$token = Get-Content -Path "$replaypath\token.txt"
		Write-Log "token file created with token: $token"			
	}
	else
	{
		$token = Get-Content -Path "$replaypath\token.txt"
	}
}

# Function for checking the visibility preference file exists, creating it if not
function Test-Visibility
{
	if (-not (Test-Path -Path "$replaypath\visibility.txt"))
	{
		Write-Log "visibility.txt file not detected, the script will create the file now"
		$visibilityPref = Read-Host "Please enter your replay visibility preference: enter 1 for public, 2 for unlisted, 3 for private"
			if ($visibilityPref -eq 1)
			{
				New-Item -Path $replaypath -Name "visibility.txt" -ItemType File -Value "public"
				$visibilityPref = Get-Content -Path "$replaypath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			elseif ($visibilityPref -eq 2)
			{
				New-Item -Path $replaypath -Name "visibility.txt" -ItemType File -Value "unlisted"
				$visibilityPref = Get-Content -Path "$replaypath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			elseif ($visibilityPref -eq 3)
			{
				New-Item -Path $replaypath -Name "visibility.txt" -ItemType File -Value "private"
				$visibilityPref = Get-Content -Path "$replaypath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			else
			{
				Write-Log "Invalid input detected"
				Test-Visibility
			}
	}
	else
	{
		$visibilityPref = Get-Content -Path "$replaypath\visibility.txt"
	}
}

Write-Log "For FAQ/help or to get the latest version of this script please check https://github.com/mark-codes-stuff/ballchasing_replay_uploader"

try
{

	# Test to make sure the folder, token & visibility files all exist before proceeding, grab values
	Test-ReplayFolder
	Test-Token
	Test-Visibility
	$token = Get-Content -Path "$replaypath\token.txt"
	$visibilityPref = Get-Content -Path "$replaypath\visibility.txt"

	# Create a new FileSystemWatcher, including specifying path and file types to monitor
	$fileWatcher = New-Object System.IO.FileSystemWatcher
	$fileWatcher.Path = $replaypath
	$fileWatcher.Filter = "*.replay"
	$fileWatcher.IncludeSubDirectories = $false
	$fileWatcher.EnableRaisingEvents = $true

	# Some more debug writes
	Write-Log "Watcher is watching $replaypath"
	Write-Log "Replay visibility is set to $visibilityPref"
	# Write-Log "Token: $token"
	Write-Log "Replay uploader is running.."
	Write-Log "Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota"
	Write-Log "To see your current quota, see the upload page here: https://ballchasing.com/upload"
	$uploadURL = "https://ballchasing.com/api/v2/upload?visibility=" + $visibilityPref

	# Action newly created files
	$actionHandle =
	{
		# Declaring a few variables inside the block
		# Write-Log "File $($Event.SourceEventArgs.ChangeType)"
		$replayFile = $Event.SourceEventArgs.FullPath
		$replayName = $Event.SourceEventArgs.Name
		Write-Log "New file detected $replayFile"
	
		# Also need to encode the file as Invoke-RestMethod/WebRequest in PS 5.1 won't do this
		Write-Log "Encoding file for upload.."
		$encObject = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
		$rawFile = [System.IO.File]::ReadAllBytes($replayFile)
		$encodedFile = $encObject.GetString($rawFile)
	
		# We need a random ID for the request boundary
		$boundary = [System.Guid]::NewGuid().ToString()
	
		# Creating the body of the request
		$newLine = "`r`n"
		$bodyInfo =
		(
			"--$boundary",
			"Content-Disposition: form-data; name=`"file`"; filename=`"$replayName`"",
			"Content-Type: application/octet-stream$newLine",
			$encodedFile,
			"--$boundary--$newLine"
		)
		$body = $bodyInfo -join $newLine
		
		# Make the request using the info above
		try
		{
			Start-Sleep -Seconds 1
			$headers = 
			@{
				"Authorization" = $token
			}
			# If anything breaks in future these can be uncommented for checks
			# Write-Log "The value of $headers is: '$headers'"
			# Write-Log "Token in header: '$($headers['Authorization'])'"
			# Write-Log "Upload URL is: '$uploadURL'"
			Write-Log "Attempting to upload file.."
			$request = Invoke-WebRequest -Uri $uploadURL -Method Post -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $body -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
			switch ($request.StatusCode)
				{
					201 {Write-Log "Upload successful!"}
   					default {Write-Log "Unexpected response: $($request.StatusCode)"}
				}
		}
		catch
		{
   			switch ([int]$_.Exception.Response.StatusCode.value__)
				{
					401 {Write-Log "The upload failed due to an authorisation failure. Check the token provided is correct ($token). If in doubt, delete the token file from $replayPath and rerun the script "}
					409 {Write-Log "The upload was rejected as the replay is a duplicate and has already been uploaded before" }
					429
					{
						Write-Log "The upload was rejected as you have hit an upload limit"
						Write-Log "Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota"
						Write-Log "To see your current quota, see the upload page here: https://ballchasing.com/upload"
					}
					default
					{
						Write-Log "Something else has gone wrong, more detail will be provided below:"
						Write-Log "Status code value: '$($_.Exception.Response.StatusCode.value__)'"
						Write-Log "Status code: '$($_.Exception.Response.StatusCode)'"
						Write-Log "Full exception: '$($_.Exception.Message)'"
						Write-Log "Check the ballchasing.com status here: https://ballchasingstatus.com/ as it might be down"
					}
				}
		}
	}

# Error handling if the system file watcher crashes (probably won't ever happen but you never know)
$errorHandle =
{
	Write-Log "As unlikely as it might be, the system file watcher has encountered an overflow error, the script will now exit"
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
$fileWatcher.EnableRaisingEvents = $false ; #Write-Log "Disabling watcher events"
$fileWatcher.Dispose() ; #Write-Log "Killing watcher"
$actionableEvent | Unregister-Event ; #Write-Log "Unregistering file create event subscription"
$errorEvent | Unregister-Event ; #Write-Log "Unregistering error event subscription"
}
