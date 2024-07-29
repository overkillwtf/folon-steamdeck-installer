# Fallout London Steam Deck Installer

![](https://github.com/overkillwtf/folon-steamdeck-installer/blob/main/folondeck.gif)

## Context

This automates as much as possible to set up [Fallout London](https://fallout4london.com) on your Steam Deck.

The only prerequisite is having Fallout 4 GOTY in **English** installed on your __**internal SSD**__.

Note: Right now, this script applies [the optimized .ini](https://github.com/krupar101/f4london_steam_deck_ini) by @krupar101

## Steps

1. **Open a Terminal on your Steam Deck.**
2. **Download, Make Executable, and Run the Script:**

Run the following command in the terminal:
```
curl -O https://raw.githubusercontent.com/overkillwtf/folon-steamdeck-installer/main/fallout.sh && chmod +x fallout.sh && ./fallout.sh
```

3. Before the downgrade starts, SteamCMD (a tool developed by Valve) will authenticate with the previously provided credentials, and might possibly need a 2FA / Steam Guard confirmation. 

None of your credentials will be stored in any form.

## About the Script

This script performs the following actions:

-	Downgrades the Steam version of Fallout 4 to a working version.
-	Installs GOG, so that you can install Fallout: London
-	Automatically moves the necessary files to the correct path.

## Passwords

While this tool asks for your password, it does not keep them locally. Instead, it uses [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD), a command-line version of Steam provided by Valve.
