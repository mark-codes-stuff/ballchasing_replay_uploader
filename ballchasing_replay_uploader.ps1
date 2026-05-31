# For FAQ/help or to get the latest version of this script please check https://github.com/mark-codes-stuff/ballchasing_replay_uploader

$ErrorActionPreference = "Continue"

try {

	# Function to easily write to the console with timestamps
	function Write-Log {
		param($logContent)
		$timestamp = Get-Date -Format HH:mm
		Write-Host "[$timestamp]: $logContent"
	}

	# Just a quick check to see if you're running the latest version, nothing too fancy
	$scriptVersion = "2026-05-31"
	$response = Invoke-RestMethod -Uri "https://api.github.com/repos/mark-codes-stuff/ballchasing_replay_uploader/commits?path=ballchasing_replay_uploader.ps1&per_page=1"
	$lastUpdated = $response[0].commit.committer.date.Substring(0, 10)
	if ($lastUpdated -gt $scriptVersion) {
		Write-Log "A newer version of the script is available on GitHub"
	}

	# Grabbing current user/profile path to get location of Rocket League folders, creating vars to use later
	$replayPathSteam = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\Demos"
	$replayPathEpic = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\DemosEpic"
	$settingsPath = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame"
	$script:uploadCount = 0

	# Function for checking the Rocket League folders exist
	function Test-Folders {
		$testvar = 0
		if (-not (Test-Path -Path $settingsPath)) {
			Write-Log "There is something wrong with the Rocket League config folder path: $settingsPath"
			Write-Log "The folder path is derived from `$env:USERPROFILE` ($env:USERPROFILE) and \Documents\My Games\Rocket League\TAGame"
			Write-Log "The script will now exit"
			Pause
			exit
		}
		if (-not (Test-Path -Path $replayPathSteam)) {
			Write-Log "There is something wrong with the Steam replay folder path: $replayPathSteam"
			Write-Log "The Steam replay folder path is derived from `$env:USERPROFILE` ($env:USERPROFILE) and \Documents\My Games\Rocket League\TAGame\Demos"
			Write-Log "If you're not using the Steam client then this can be ignored"
			$testvar += 1
		}
		if (-not (Test-Path -Path $replayPathEpic)) {
			Write-Log "There is something wrong with the Epic replay folder path: $replayPathEpic"
			Write-Log "The Epic replay folder path is derived from `$env:USERPROFILE` ($env:USERPROFILE) and \Documents\My Games\Rocket League\TAGame\DemosEpic"
			Write-Log "If you're not using the Epic client then this can be ignored"
			$testvar += 1
		}
		if ($testvar -eq 2) {
			Write-Log "Since neither the Steam replay nor Epic replay folders exist, the script will now exit. Please check the folders exist."
			Pause
			exit
		}
	}

	# Function for checking the token file exists, creating it if not
	function Test-Token {
		if (-not (Test-Path -Path "$settingsPath\token.txt")) {
			Write-Log "token.txt file not detected, the script will create the file now"
			Write-Log "Go to https://ballchasing.com/upload and copy your upload token to the clipboard"
			$tokenInput = Read-Host "Paste your token in here"
			New-Item -Path $settingsPath -Name "token.txt" -ItemType File -Value $tokenInput
			$token = Get-Content -Path "$settingsPath\token.txt"
			Write-Log "token file created with token: $token"			
		}
		else {
			$token = Get-Content -Path "$settingsPath\token.txt"
		}
	}

	# Function for checking the visibility preference file exists, creating it if not
	function Test-Visibility {
		if (-not (Test-Path -Path "$settingsPath\visibility.txt")) {
			Write-Log "visibility.txt file not detected, the script will create the file now"
			$visibilityPref = Read-Host "Please enter your replay visibility preference: enter 1 for public, 2 for unlisted, 3 for private"
			if ($visibilityPref -eq 1) {
				New-Item -Path $settingsPath -Name "visibility.txt" -ItemType File -Value "public"
				$visibilityPref = Get-Content -Path "$settingsPath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			elseif ($visibilityPref -eq 2) {
				New-Item -Path $settingsPath -Name "visibility.txt" -ItemType File -Value "unlisted"
				$visibilityPref = Get-Content -Path "$settingsPath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			elseif ($visibilityPref -eq 3) {
				New-Item -Path $settingsPath -Name "visibility.txt" -ItemType File -Value "private"
				$visibilityPref = Get-Content -Path "$settingsPath\visibility.txt"
				Write-Log "File created, replay visibility set to: $visibilityPref"
			}
			else {
				Write-Log "Invalid input detected"
				Test-Visibility
			}
		}
		else {
			$visibilityPref = Get-Content -Path "$settingsPath\visibility.txt"
		}
	}

	# Function for counting successful uploads in the session. Will also just output the total amount without counting if needed. Useful as grabbing $script:uploadCount in the upload block was causing an issue
	function Count-Uploads {
		param($increment = $false)
		if ($increment) {
			$script:uploadCount++
		}
		Write-Log "You have uploaded $script:uploadCount replays in this session"
	}

	Write-Log "For FAQ/help or to get the latest version of this script please check https://github.com/mark-codes-stuff/ballchasing_replay_uploader"

	try {

		# Test to make sure the folder, token & visibility files all exist before proceeding, grab values
		Test-Folders
		Test-Token
		Test-Visibility
		$token = Get-Content -Path "$settingsPath\token.txt"
		$visibilityPref = Get-Content -Path "$settingsPath\visibility.txt"

		if (Test-Path -Path $replayPathSteam) {
			# Create a new FileSystemWatcher for Steam demos, including specifying path and file types to monitor
			$fileWatcher = New-Object System.IO.FileSystemWatcher
			$fileWatcher.Path = $replayPathSteam
			$fileWatcher.Filter = "*.replay"
			$fileWatcher.IncludeSubDirectories = $false
			$fileWatcher.EnableRaisingEvents = $true
			Write-Log "Watcher is watching $replayPathSteam"
		}

		if (Test-Path -Path $replayPathEpic) {
			# Create a new FileSystemWatcher for Epic demos, including specifying path and file types to monitor
			$fileWatcher2 = New-Object System.IO.FileSystemWatcher
			$fileWatcher2.Path = $replayPathEpic
			$fileWatcher2.Filter = "*.replay"
			$fileWatcher2.IncludeSubDirectories = $false
			$fileWatcher2.EnableRaisingEvents = $true
			Write-Log "Watcher is watching $replayPathEpic"
		}

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

			# If downloading the replay file from the match history menu rather than saving it immediately after the game has finished, RL downloads the file but then renames it or seems to remove and re-create it
			# This causes the upload to fail because the referenced file doesn't exist any more so it gets stuck forever
			# A pause is needed, then we need to check if the file name has changed since $actionHandle was called, to be generous let's say 5s
			Start-Sleep -Seconds 5
			if (-not (Test-Path -Path $replayFile)) {
				Write-Log "It looks like the file doesn't exist any more - Rocket League has renamed it. Aborting upload attempt."
				return
			}
	
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
			try {
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
				switch ($request.StatusCode) {
					201 {
						Write-Log "Upload successful!" ;
						Count-Uploads -increment $true
					}
					default { Write-Log "Unexpected response: $($request.StatusCode)" }
				}
			}
			catch {
				switch ([int]$_.Exception.Response.StatusCode.value__) {
					401 { Write-Log "The upload failed due to an authorisation failure. Check the token provided is correct. If in doubt, delete the token file from $settingsPath and then close & rerun the script " }
					409 { Write-Log "The upload was rejected as the replay is a duplicate and has already been uploaded before" }
					429 {
						Write-Log "The upload was rejected as you have hit an upload limit"
						Write-Log "Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota"
						Write-Log "To see your current quota, see the upload page here: https://ballchasing.com/upload"
						Count-Uploads
					}
					default {
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
			Pause
			exit
		}

		# Subscribe to events for newly created files, and also error events in case there's an issue
		# The subscriber doesn't work if created in the same block as the watcher so setting up outside
		if (Test-Path -Path $replayPathSteam) {
			$actionableEventSteam = Register-ObjectEvent -InputObject $fileWatcher -EventName "Created" -Action $actionHandle
			$errorEvent = Register-ObjectEvent -InputObject $fileWatcher -EventName "Error" -Action $errorHandle
		}
		if (Test-Path -Path $replayPathEpic) {
			$actionableEventEpic = Register-ObjectEvent -InputObject $fileWatcher2 -EventName "Created" -Action $actionHandle
			$errorEvent2 = Register-ObjectEvent -InputObject $fileWatcher2 -EventName "Error" -Action $errorHandle
		}	

		# Keep alive
		while ($true) {
			Start-Sleep -Seconds 1
		}

	}

	# Cleanly remove the watcher & event handlers on exit
	# When adding a second watcher that isn't always in use, the commands to clean it up started to cause more issues than they solved so have commented them out for now
	# In theory ending the PS process and closing the terminal window should kill all the objects in the script anyway, the below can be left for debugging out of curiosity
	finally {
		#$fileWatcher.EnableRaisingEvents = $false ; #Write-Log "Disabling watcher events"
		#$fileWatcher.Dispose() ; #Write-Log "Killing watcher"
		#$actionableEventSteam | Unregister-Event ; #Write-Log "Unregistering file create event subscription"
		#$fileWatcher2.EnableRaisingEvents = $false ; #Write-Log "Disabling watcher2 events"
		#$fileWatcher2.Dispose() ; #Write-Log "Killing watcher2"
		#$actionableEventEpic | Unregister-Event ; #Write-Log "Unregistering file create event subscription"
		#$errorEvent | Unregister-Event ; #Write-Log "Unregistering error event subscription"
		Get-EventSubscriber -Force | Unregister-Event -Force # All event subscriber objects can be deleted in one go with this line
	}
}
catch {
	Write-Log "Error: $($_.Exception.Message)"
	Write-Log "Line $($_.InvocationInfo.ScriptLineNumber)"
	Read-Host "Press enter to exit"
}
