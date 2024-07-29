# Fallout London Steam Deck Installer
## Context

This script is meant to automate as much as possible to set up [Fallout London](https://fallout4london.com) on your Steam Deck.

The only prerequisite is having Fallout 4 GOTY in **English** installed on your __**internal SSD**__.

## Steps

1. **Open a Terminal on your Steam Deck.**
2. **Download, Make Executable, and Run the Script:**

Run the following command in the terminal:
```
curl -O https://raw.githubusercontent.com/overkillwtf/folon-steamdeck-installer/main/fallout.sh && chmod +x fallout.sh && ./fallout.sh
```

## About the Script

This script performs the following actions:

-	Downgrades the Steam version of Fallout 4 to a working version.
-	Installs GOG, so that you can install Fallout: London
-	Automatically moves the necessary files to the correct path.

## Passwords

While this tool asks for your password, it does not keep them locally. Instead, it uses [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD), a command-line version of Steam provided by Valve.
