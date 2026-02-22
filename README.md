# ballchasing.com replay uploader

## What is this?

This tool will monitor the Rocket League replay folder and upload new replay files to ballchasing.com when they're detected, using the ballchasing.com API token provided. The popular replay uploader plugin for bakkesmod won't work in the near future due to an anti-cheat being added to Rocket League.

I've tried to make this as easy as possible to use, if you run into any issues make you've read the below info.

## How to use

For this tool to function, create a file in the same folder as the .ps1 file named 'token.txt' and in the txt file you paste in your ballchasing.com API token. If you don't have a token, get one from here: https://ballchasing.com/upload

In the same folder, create a txt file named "visibility.txt" and enter into the file your preference for replay visibility (public, unlisted, private).

When first running the script it'll check you have these files - if you're missing the visibility.txt file you'll be asked to make one.

To run the script, you can right-click on the file and choose Run with PowerShell. Hit Ctrl + C in the PowerShell window once you're finished playing Rocket league to close it.

This has been tested on Windows 11 / PowerShell 5.1 and should not require any additional downloads.

## Diagnosing errors with the script

To stop PS from just closing the window if the script errors out, run PowerShell from the script directory (shift + right-click > Open PowerShell window here), or open PowerShell and cd to wherever you have the script saved e.g.:

cd ""C:\Users\xxxxxxxxxx\Downloads\"

Then you can just type .\ and hit tab to pick the script and hit enter to run it.

This will keep the window open so you can scroll up to read any errors.

This was made with PowerShell 5.1 in mind, I think this should work in PS7 too but haven't tested it.

## Errors with the upload

If the upload errors out then it'll probably be one of the following errors:

- 401 - check you have the correct API token inside the token.txt file, and that the txt file is in the same folder as the .ps1 script file. Also ensure the token is all on one line and that there are no extra line breaks in the txt file.

- 409 - this means the replay is a duplicate and has already been uploaded before

- 429 - you have hit an upload limit

  - Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota

  - To see your current quota, see the upload page here: https://ballchasing.com/upload

- 50x - something is wrong with ballchasing.com and you can check the website status here: https://ballchasingstatus.com/

## Credits / references

- Ballchasing.com API info - https://ballchasing.com/doc/api

- Help with formatting the request - https://curlconverter.com/powershell-restmethod/ (although I realised later PS 5.1 doesn't use the Form parameter but the rest was helpful!)

- Help with making a random ID, encoding the file and creating the request body - https://gist.github.com/weipah/19bfdb14aab253e3f109
