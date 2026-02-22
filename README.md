# ballchasing.com replay uploader

## What is this?

This tool will monitor the Rocket League replay folder and upload new replay files to ballchasing.com when they're detected, using the ballchasing.com API token provided. Replays will be uploaded with your specified visibility preference. The popular replay uploader plugin for bakkesmod won't work in the near future due to an anti-cheat being added to Rocket League. I want to learn PowerShell and figured this would be a handy way to get started with it and it might help a few people too.

I've tried to make this as easy as possible to use, if you run into any issues make you've read the below info.

## How to use

On first run, the script will help you create 2 files needed for the script to run, these files contain your upload token and your replay visibility preference. If you don't have a token, get one from here: https://ballchasing.com/upload

The next time it runs, it will check these files still exist in case you accidentally delete them or something. The files should stay in the same folder as the script in order for it to be able to read them.

To run the script, you can right-click on the file and choose Run with PowerShell. Hit Ctrl + C in the PowerShell window once you're finished playing Rocket league to close it down.

This has been tested on Windows 11 / PowerShell 5.1 and should not require any additional downloads.

## Diagnosing errors with the script

To stop PS from just closing the window if the script errors out, run PowerShell from the script directory (shift + right-click > Open PowerShell window here), or open PowerShell and cd to wherever you have the script saved e.g.:

cd ""C:\Users\xxxxxxxxxx\Downloads\"

Then you can just type .\ and hit tab to pick the script and hit enter to run it. This will keep the window open so you can scroll up to read any errors.

This was made with PowerShell 5.1 in mind, I think this should work in PS7 too but haven't tested it.

## Errors with the upload

If the upload errors out then it'll probably be one of the following errors:

- 401 - check you have the correct API token inside the token.txt file, and that the txt file is in the same folder as the script file. Or just delete it and let the script help you remake the file.

- 409 - this means the replay is a duplicate and has already been uploaded before

- 429 - you have hit an upload limit

  - Bear in mind that ballchasing.com has a daily and weekly upload limit which you might hit while playing the game. For more info read this page here: https://ballchasing.com/doc/faq#upload-quota

  - To see your current quota, see the upload page here: https://ballchasing.com/upload

- 50x - something is wrong with ballchasing.com and you can check the website status here: https://ballchasingstatus.com/

## Credits / references / things that helped

- Ballchasing.com API info - https://ballchasing.com/doc/api

- Help with formatting the request - https://curlconverter.com/powershell-restmethod/ (although I realised later PS 5.1 doesn't use the Form parameter but the rest was helpful!)

- Help with making a random ID, encoding the file and creating the request body - https://gist.github.com/weipah/19bfdb14aab253e3f109

- File watcher - https://learn.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher?view=net-10.0
