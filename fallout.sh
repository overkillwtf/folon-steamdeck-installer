#!/bin/bash

echo "Fallout London Patcher by Timo Schmidt and Overkill.wtf"
sleep 1

# Set appmanifest_377160.acf to read-only
echo "Setting appmanifest_377160.acf to read-only to stop Steam from updating the game..."
chmod 444 "$HOME/.local/share/Steam/steamapps/appmanifest_377160.acf"

# Check if NonSteamLaunchers is already installed
NONSTEAM_LAUNCHERS_DIR="$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/"
if [ -e "$NONSTEAM_LAUNCHERS_DIR" ]; then
    echo "NonSteamLaunchers is already installed."
else
    echo "Setting up NonSteamLaunchers..."
    /bin/bash -c 'curl -Ls https://raw.githubusercontent.com/moraroy/NonSteamLaunchers-On-Steam-Deck/main/NonSteamLaunchers.sh | nohup /bin/bash -s -- "GOG Galaxy"'
fi

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p "$HOME/Downloads/Depots"

# Setting up downgrade-list
echo "Setting up downgrade-list..."
cat <<EOL > "$HOME/Downloads/folon_downgrade.txt"
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
download_depot 377160 540810 1558929737289295473
quit
EOL

sleep 1

# Setting up SteamCMD
echo "Setting up SteamCMD..."
mkdir -p "$HOME/Downloads/SteamCMD"
cd "$HOME/Downloads/SteamCMD"
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

sleep 1

# Prompt user for Steam login credentials
echo "Please enter your Steam login credentials."
echo "Note: Your login details are secure and will NOT be stored."

username=$(zenity --entry --title="Steam Username" --text="Enter name of your Steam user:")
password=$(zenity --password --title="Steam Password" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

# Run SteamCMD with the provided credentials and script
echo "Running SteamCMD with provided credentials..."
chmod +x "$HOME/Downloads/SteamCMD/steamcmd.sh"
"$HOME/Downloads/SteamCMD/steamcmd.sh" +login "$username" "$password" +runscript "$HOME/Downloads/folon_downgrade.txt"

# Move downloaded content and clean up
echo "Moving downloaded content and cleaning up..."
rsync -a "$HOME/Downloads/SteamCMD/linux32/steamapps/content/app_377160/"* "$HOME/Downloads/Depots/"
rm -rf "$HOME/Downloads/SteamCMD"
rm "$HOME/Downloads/folon_downgrade.txt"

echo "Patch process completed successfully!"

# Check for Fallout: London installation
if [ ! -d "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London" ]; then
  text="`printf "<b>Please download Fallout: London from GOG and install it!</b>\n\nThen click OK to continue. (You can find GOG in your Steam Library.)"`"
   zenity --info \
           --title="Overkill" \
           --width="450" \
           --text="${text}" 2>/dev/null
fi

# Step 1: Move main game files
echo "Step 1: Moving main game files..."
if [ -d "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London" ]; then
    rsync -a "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London/"* "$HOME/.steam/steam/steamapps/common/Fallout 4/"
else
    echo "Directory for main game files not found."
fi

# Step 2: Move _config files
echo "Step 2: Moving _config files..."
mkdir -p "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4"
if [ -d "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London/__Config" ]; then
    rsync -a "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London/__Config/"* "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4/"
else
    echo "__Config directory not found."
fi

# Step 3: Move _appdata files
echo "Step 3: Moving _appdata files..."
mkdir -p "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/AppData/Local/Fallout4"
if [ -d "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London/__AppData" ]; then
    rsync -a "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London/__AppData/"* "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/AppData/Local/Fallout4/"
else
    echo "__AppData directory not found."
fi

# Step 4: Download and place Fallout4.INI
echo "Step 4: Downloading and placing Fallout4.INI..."
curl -L -o "$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4/Fallout4.INI" https://github.com/krupar101/f4london_steam_deck_ini/blob/main/Fallout4.INI

# Step 5: Renaming executables
echo "Step 5: Renaming executables..."
if [ -e "$HOME/.steam/steam/steamapps/common/Fallout 4/f4se_loader.exe" ]; then
    mv -f "$HOME/.steam/steam/steamapps/common/Fallout 4/Fallout4Launcher.exe" "$HOME/.steam/steam/steamapps/common/Fallout 4/F04LauncherBackup.exe"
    mv -f "$HOME/.steam/steam/steamapps/common/Fallout 4/f4se_loader.exe" "$HOME/.steam/steam/steamapps/common/Fallout 4/Fallout4Launcher.exe"
else
    echo "f4se_loader.exe not found."
fi

# Cleanup: Remove Fallout London directory
echo "Cleaning up..."
rm -rf "$HOME/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/Program Files (x86)/GOG Galaxy/Games/Fallout London"

text="`printf "<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole."`"
zenity --info \
       --title="Overkill" \
       --width="450" \
       --text="${text}" 2>/dev/null
exit
