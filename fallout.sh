#!/bin/bash

echo "Fallout London Patcher by Timo Schmidt and Kevin Wammer for overkill.wtf"
sleep 1

# Paths
STEAM_APPMANIFEST_PATH="$HOME/.local/share/Steam/steamapps/appmanifest_377160.acf"
NONSTEAM_LAUNCHERS_DIR="$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/"
DOWNGRADE_LIST_PATH="$HOME/Downloads/folon_downgrade.txt"
STEAMCMD_DIR="$HOME/Downloads/SteamCMD"
FALLOUT_LONDON_DIR="$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London"
FALLOUT_4_DIR="$HOME/.steam/steam/steamapps/common/Fallout 4"
FALLOUT4_CONFIG_DIR="$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4"
FALLOUT4_APPDATA_DIR="$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/AppData/Local/Fallout4"
F4LONDON_INI_URL="https://github.com/krupar101/f4london_steam_deck_ini/blob/main/Fallout4.INI"

# Set appmanifest_377160.acf to read-only
echo "Setting appmanifest_377160.acf to read-only to stop Steam from updating the game..."
chmod 444 "$STEAM_APPMANIFEST_PATH"

# Check if NonSteamLaunchers is already installed
if [ -e "$NONSTEAM_LAUNCHERS_DIR" ]; then
    echo "NonSteamLaunchers is already installed."
else
    echo "Setting up NonSteamLaunchers..."
    /bin/bash -c 'curl -Ls https://raw.githubusercontent.com/moraroy/NonSteamLaunchers-On-Steam-Deck/main/NonSteamLaunchers.sh | nohup /bin/bash -s -- "GOG Galaxy"'
fi

# Setting up downgrade-list
echo "Setting up downgrade-list..."
cat <<EOL > "$DOWNGRADE_LIST_PATH"
download_depot 377160 377161 7497069378349273908
download_depot 377160 377163 5819088023757897745
download_depot 377160 377162 5847529232406005096
download_depot 377160 377164 2178106366609958945
download_depot 377160 435870 1691678129192680960
download_depot 377160 435871 5106118861901111234
download_depot 377160 435880 1255562923187931216
download_depot 377160 435881 1207717296920736193
download_depot 377160 435882 8482181819175811242
download_depot 377160 480630 5527412439359349504
download_depot 377160 480631 6588493486198824788
download_depot 377160 393885 5000262035721758737
download_depot 377160 490650 4873048792354485093
download_depot 377160 393895 7677765994120765493
quit
EOL

sleep 1

# Setting up SteamCMD
echo "Setting up SteamCMD..."
mkdir -p "$STEAMCMD_DIR"
cd "$STEAMCMD_DIR" || { echo "Failed to change directory to $STEAMCMD_DIR"; exit 1; }
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

sleep 1

# Prompt user for Steam login credentials
echo "Please enter your Steam login credentials."
echo "Note: Your login details are secure and will NOT be stored."

username=$(zenity --entry --title="Steam Username" --text="Enter name of your Steam user:")
password=$(zenity --password --title="Steam Password" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

# Run SteamCMD with the provided credentials and script
echo "Running SteamCMD with provided credentials..."
chmod +x "$STEAMCMD_DIR/steamcmd.sh"
"$STEAMCMD_DIR/steamcmd.sh" +login "$username" "$password" +runscript "$DOWNGRADE_LIST_PATH"

# Move downloaded content and clean up
echo "Moving downloaded content and cleaning up..."
rsync -av --remove-source-files "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/"*/ "$FALLOUT_4_DIR/"
rm -rf "$STEAMCMD_DIR"
rm "$DOWNGRADE_LIST_PATH"

echo "Patch process completed successfully!"

# Check for Fallout: London installation
if [ ! -d "$FALLOUT_LONDON_DIR" ]; then
  text="<b>Please download Fallout: London from GOG and install it!</b>\n\nThen click OK to continue. (You can find GOG in your Steam Library.)"
  zenity --info \
         --title="Overkill" \
         --width="450" \
         --text="$text" 2>/dev/null
fi

# Step 1: Move main game files
echo "Step 1: Moving main game files..."
if [ -d "$FALLOUT_LONDON_DIR" ]; then
    rsync -av "$FALLOUT_LONDON_DIR/"* "$FALLOUT_4_DIR/"
else
    echo "Directory for main game files not found."
fi

# Step 2: Move _config files
echo "Step 2: Moving _config files..."
mkdir -p "$FALLOUT4_CONFIG_DIR"
if [ -d "$FALLOUT_LONDON_DIR/__Config" ]; then
    rsync -av "$FALLOUT_LONDON_DIR/__Config/"* "$FALLOUT4_CONFIG_DIR/"
else
    echo "__Config directory not found."
fi

# Step 3: Move _appdata files
echo "Step 3: Moving _appdata files..."
mkdir -p "$FALLOUT4_APPDATA_DIR"
if [ -d "$FALLOUT_LONDON_DIR/__AppData" ]; then
    rsync -av "$FALLOUT_LONDON_DIR/__AppData/"* "$FALLOUT4_APPDATA_DIR/"
else
    echo "__AppData directory not found."
fi

# Step 4: Download and place Fallout4.INI
echo "Step 4: Downloading and placing Fallout4.INI..."
curl -L -o "$FALLOUT4_CONFIG_DIR/Fallout4.ini" "$F4LONDON_INI_URL"

# Step 5: Renaming executables
echo "Step 5: Renaming executables..."
if [ -f "$FALLOUT_4_DIR/f4se_loader.exe" ]; then
    mv -f "$FALLOUT_4_DIR/Fallout4Launcher.exe" "$FALLOUT_4_DIR/F04LauncherBackup.exe"
    mv -f "$FALLOUT_4_DIR/f4se_loader.exe" "$FALLOUT_4_DIR/Fallout4Launcher.exe"
else
    echo "f4se_loader.exe not found."
fi

# Cleanup: Remove Fallout London directory
echo "Cleaning up..."
rm -rf "$FALLOUT_LONDON_DIR"

text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole."
zenity --info \
       --title="Overkill" \
       --width="450" \
       --text="$text" 2>/dev/null
exit
