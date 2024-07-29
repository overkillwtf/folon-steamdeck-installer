# Fallout London Steam Deck Installer

![](https://github.com/overkillwtf/folon-steamdeck-installer/blob/main/folondeck.gif)

## About the Script

This automates as much as possible to set up [Fallout London](https://fallout4london.com) on your Steam Deck.

The only prerequisite is having Fallout 4 GOTY in **English** installed on your __**internal SSD**__.

This script performs the following actions:

-	Downgrades the Steam version of Fallout 4 to the right version (pre-NextGen).
-	Installs GOG, so that you can then download Fallout: London
-	Automatically moves the necessary files to the correct paths.

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

## Password Disclaimer:

While this tool asks for your Steam credentials, it does not keep them locally, nor does it send them to any third party outside of Valve. Instead, it uses [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD), a command-line version of Steam provided by Valve.
