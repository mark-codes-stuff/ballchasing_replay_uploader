# For the latest version of this script please check xxxxxxxxxxxxxx

try
{
# Grabbing info and declaring variables
$currentUser = $env:username
$replayPath = "C:\Users\$currentUser\Documents\My Games\Rocket League\TAGame\Demos"

# Some debug writes which can be uncommented if you find something isn't working
#Write-Host "Current user name is: $currentUser"
#Write-Host "Replay folder path is: $replayPath"
#Write-Host "Ballchasing token is: $token"

# Create a new FileSystemWatcher, including specifying path and file types to monitor
$fileWatcher = New-Object System.IO.FileSystemWatcher
$fileWatcher.Path = $replayPath
$fileWatcher.Filter = "*.replay"
$fileWatcher.IncludeSubDirectories = $false
$fileWatcher.EnableRaisingEvents = $true

# Some more debug writes
#Write-Host "Watcher is watching $replayPath ready"

Write-Host "Replay uploader is running.."
Write-Host "Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota"
Write-Host "To see your current quota, see the upload page here: https://ballchasing.com/upload"

# Action newly created files
$actionHandle =
	{
		# Declaring a few variables inside the block
		$token = Get-Content -Path .\token.txt
		$uploadURL = "https://ballchasing.com/api/v2/upload?visibility=public"
		#Write-Host "File $($Event.SourceEventArgs.ChangeType)"
		$replayFile = $Event.SourceEventArgs.FullPath
		$replayName = $Event.SourceEventArgs.Name
		Write-Host "New file detected $replayFile"
		
		# Also need to encode the file as PS 5.1 won't do this easily.
		Write-Host "Encoding file for upload"
		$encObject = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
		$rawFile = [System.IO.File]::ReadAllBytes($replayFile)
		$encodedFile = $encObject.GetString($rawFile)
		
		# We need a random ID for the boundary
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
				# Write-Host "The value of $headers is: '$headers'"
				# Write-Host "Token in header: '$($headers['Authorization'])'"
				# Write-Host "Upload URL is: '$uploadURL'"
				$response = Invoke-RestMethod -Uri $uploadURL -Method Post -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $body -UseBasicParsing
				Write-Host "Upload successful"
			}
			catch
			{
				Write-Host "Upload failed: $($_.Exception.Message)"
			}
	}

# Error handling
$errorHandle =
	{
		Write-Host "As unlikely as it might be, the system file watcher has encountered an overflow error, please quit the script and rerun"
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