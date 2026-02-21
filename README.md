# ballchasing.com replay uploader
This tool will monitor the Rocket League replay folder and upload new replay files to ballchasing.com when they're detected, using the ballchasing.com API token provided.

For this tool to function, create a file in the same folder as the .ps1 file named 'token.txt' and in the txt file you should place your ballchasing.com API token.

If you don't have a token, get it from here: https://ballchasing.com/upload

Then just run this before you open Rocket League and it will detect new replay files and upload them for you. They will be uploaded with public visibility by default.

Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota

To see your current quota, see the upload page here: https://ballchasing.com/upload

To run the script, you can right-click on the file and choose Run with PowerShell. Hit Ctrl + C in the PowerShell window once you're finished playing Rocket league to close it.

This has been tested on Windows 11 / PowerShell 5.1 and does not require any additional downloads.

If it errors out then it'll probably be one of the following errors:

  401 - check you have the correct API token inside the token.txt file and that the txt file is in the same folder as the .ps1 script file. Also ensure the token is all on one line and that there are no extra line breaks in the txt file.

  409 - this means the replay is a duplicate and has already been uploaded before

  429 - you have hit the upload limit

  50x - something is wrong with ballchasing.com and you can check the website status here: https://ballchasingstatus.com/
