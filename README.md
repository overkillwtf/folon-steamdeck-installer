# Fallout London Steam Deck Installer

![](https://github.com/overkillwtf/folon-steamdeck-installer/blob/main/folondeck.gif)

## About the Script

This automates as many steps as possible to set up [Fallout London](https://fallout4london.com) on your Steam Deck.

The only prerequisite is installing Fallout 4 GOTY in **English** on your __**internal SSD**__.

This script performs the following actions:

- Downgrades the Steam version of Fallout 4 to the right version (pre-NextGen).
- Installs GOG through Heroic Launcher.
- Automatically moves the necessary files to the correct paths.

Note: Right now, this script applies [the optimized .ini](https://github.com/krupar101/f4london_steam_deck_ini) by @krupar101.

---

## Installation

To run the script, run the command below.

```
bash <(curl -s https://raw.githubusercontent.com/overkillwtf/folon-steamdeck-installer/main/fallout.sh)
```

or

```
curl -O https://raw.githubusercontent.com/overkillwtf/folon-steamdeck-installer/main/fallout.sh && \
chmod +x fallout.sh && \
./fallout.sh
```

You can find the full written guide on overkill.wtf.

## Password Disclaimer:

While this tool asks for your Steam credentials, it does not keep them locally, nor does it send them to any third party outside of Valve. Instead, it uses [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD), a command-line version of Steam provided by Valve.
