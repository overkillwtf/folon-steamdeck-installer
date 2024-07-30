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
F4LONDON_INI_URL="https://raw.githubusercontent.com/krupar101/f4london_steam_deck_ini/main/Fallout4.INI"
PROGRESS_FILE="$HOME/.folon_patch_progress"

# Function to update progress
update_progress() {
    echo "$1" > "$PROGRESS_FILE"
}

# Read last completed step
if [ -f "$PROGRESS_FILE" ]; then
    LAST_STEP=$(cat "$PROGRESS_FILE")
else
    LAST_STEP=0
fi

# Step 0: Set appmanifest_377160.acf to read-only
if [ "$LAST_STEP" -lt 1 ]; then
    echo "Setting appmanifest_377160.acf to read-only to stop Steam from updating the game..."
    chmod 444 "$STEAM_APPMANIFEST_PATH"
    update_progress 1
fi

# Step 1: Check if NonSteamLaunchers is already installed
if [ "$LAST_STEP" -lt 2 ]; then
    if [ -e "$NONSTEAM_LAUNCHERS_DIR" ]; then
        echo "NonSteamLaunchers is already installed."
    else
        echo "Setting up NonSteamLaunchers..."
        /bin/bash -c 'curl -Ls https://raw.githubusercontent.com/moraroy/NonSteamLaunchers-On-Steam-Deck/main/NonSteamLaunchers.sh | nohup /bin/bash -s -- "GOG Galaxy"'
    fi
    update_progress 2
fi

# Step 2: Setting up downgrade-list
if [ "$LAST_STEP" -lt 3 ]; then
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
download_depot 480630 5527412439359349504
download_depot 480631 6588493486198824788
download_depot 393885 5000262035721758737
download_depot 490650 4873048792354485093
download_depot 393895 7677765994120765493
quit
EOL
    update_progress 3
fi

sleep 1

# Step 3: Setting up SteamCMD
if [ "$LAST_STEP" -lt 4 ]; then
    echo "Setting up SteamCMD..."
    mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR" || { echo "Failed to change directory to $STEAMCMD_DIR"; exit 1; }
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    update_progress 4
fi

sleep 1

# Step 4: Prompt user for Steam login credentials
if [ "$LAST_STEP" -lt 5 ]; then
    echo "Please enter your Steam login credentials."
    echo "Note: Your login details are secure and will NOT be stored."

    username=$(zenity --entry --title="Steam Username" --text="Enter name of your Steam user:")
    password=$(zenity --password --title="Steam Password" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

    # Run SteamCMD with the provided credentials and script
    echo "Running SteamCMD with provided credentials..."
    chmod +x "$STEAMCMD_DIR/steamcmd.sh"
    "$STEAMCMD_DIR/steamcmd.sh" +login "$username" "$password" +runscript "$DOWNGRADE_LIST_PATH"
    update_progress 5
fi

# Step 5: Move downloaded content and clean up
if [ "$LAST_STEP" -lt 6 ]; then
    echo "Moving downloaded content and cleaning up..."
    rsync -av --remove-source-files "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/"*/ "$FALLOUT_4_DIR/"

    # Check if there are any files left in the subfolders
    if find "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/" -type f | read; then
        echo "Error: One or more files need to be moved manually."
        echo "File(s) still present:"
        find "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/" -type f
        exit 1
    else
        rm -rf "$STEAMCMD_DIR"
        rm "$DOWNGRADE_LIST_PATH"
    fi
    update_progress 6
fi

echo "Patch process completed successfully!"

# Step 6: Check for Fallout: London installation
if [ "$LAST_STEP" -lt 7 ]; then
    if [ ! -d "$FALLOUT_LONDON_DIR" ]; then
      text="<b>Please download Fallout: London from GOG and install it!</b>\n\nThen click OK to continue. (You can find GOG in your Steam Library.)"
      zenity --info \
             --title="Overkill" \
             --width="450" \
             --text="$text" 2>/dev/null
    fi
    update_progress 7
fi

# Step 7: Move main game files
if [ "$LAST_STEP" -lt 8 ]; then
    echo "Step 7: Moving main game files..."
    if [ -d "$FALLOUT_LONDON_DIR" ]; then
        rsync -av --remove-source-files "$FALLOUT_LONDON_DIR/" "$FALLOUT_4_DIR/"
        
        # Check if there are any files left in the subfolders
        if find "$FALLOUT_LONDON_DIR/" -type f | read; then
            echo "Error: One or more files need to be moved manually."
            echo "File(s) still present:"
            find "$FALLOUT_LONDON_DIR/" -type f
            zenity --info --title="Manual Intervention Required" --width="450" --text="Please move the remaining files manually from '$FALLOUT_LONDON_DIR' to '$FALLOUT_4_DIR'.\n\nClick OK when you have finished moving the files to continue." 2>/dev/null
            update_progress 8
        else
            update_progress 8
        fi
    else
        echo "Directory for main game files not found."
        update_progress 8
    fi
fi

# Step 8: Move _config files
if [ "$LAST_STEP" -lt 9 ]; then
    echo "Step 8: Moving _config files..."
    mkdir -p "$FALLOUT4_CONFIG_DIR"
    if [ -d "$FALLOUT_LONDON_DIR/__Config" ]; then
        rsync -av --remove-source-files "$FALLOUT_LONDON_DIR/__Config/"* "$FALLOUT4_CONFIG_DIR/"
        
        # Check if there are any files left in the subfolders
        if find "$FALLOUT_LONDON_DIR/__Config" -type f | read; then
            echo "Error: One or more files need to be moved manually."
            echo "File(s) still present:"
            find "$FALLOUT_LONDON_DIR/__Config" -type f
            zenity --info --title="Manual Intervention Required" --width="450" --text="Please move the remaining files manually from '$FALLOUT_LONDON_DIR/__Config' to '$FALLOUT4_CONFIG_DIR'.\n\nClick OK when you have finished moving the files to continue." 2>/dev/null
            update_progress 9
        else
            update_progress 9
        fi
    else
        echo "__Config directory not found."
        update_progress 9
    fi
fi

# Step 9: Move _appdata files
if [ "$LAST_STEP" -lt 10 ]; then
    echo "Step 9: Moving _appdata files..."
    mkdir -p "$FALLOUT4_APPDATA_DIR"
    if [ -d "$FALLOUT_LONDON_DIR/__AppData" ]; then
        rsync -av --remove-source-files "$FALLOUT_LONDON_DIR/__AppData/"* "$FALLOUT4_APPDATA_DIR/"
        
        # Check if there are any files left in the subfolders
        if find "$FALLOUT_LONDON_DIR/__AppData" -type f | read; then
            echo "Error: One or more files need to be moved manually."
            echo "File(s) still present:"
            find "$FALLOUT_LONDON_DIR/__AppData" -type f
            zenity --info --title="Manual Intervention Required" --width="450" --text="Please move the remaining files manually from '$FALLOUT_LONDON_DIR/__AppData' to '$FALLOUT4_APPDATA_DIR'.\n\nClick OK when you have finished moving the files to continue." 2>/dev/null
            update_progress 10
        else
            update_progress 10
        fi
    else
        echo "__AppData directory not found."
        update_progress 10
    fi
fi

# Step 10: Download and place Fallout4.INI
if [ "$LAST_STEP" -lt 11 ]; then
    echo "Step 10: Downloading and placing Fallout4.INI..."
    curl -L -o "$FALLOUT4_CONFIG_DIR/Fallout4.ini" "$F4LONDON_INI_URL"
    update_progress 11
fi

# Step 11: Renaming executables
if [ "$LAST_STEP" -lt 12 ]; then
    echo "Step 11: Renaming executables..."
    if [ -f "$FALLOUT_4_DIR/f4se_loader.exe" ]; then
        mv -f "$FALLOUT_4_DIR/Fallout4Launcher.exe" "$FALLOUT_4_DIR/F04LauncherBackup.exe"
        mv -f "$FALLOUT_4_DIR/f4se_loader.exe" "$FALLOUT_4_DIR/Fallout4Launcher.exe"
    else
        echo "f4se_loader.exe not found."
    fi
    update_progress 12
fi

# Step 12: Cleanup: Remove Fallout London directory
if [ "$LAST_STEP" -lt 13 ]; then
    echo "Cleaning up..."
    rm -rf "$FALLOUT_LONDON_DIR"
    update_progress 13
fi

# Step 13: Cleanup: Remove all files starting with cc in the Data folder
if [ "$LAST_STEP" -lt 14 ]; then
    echo "Removing files starting with 'cc' in the Data folder..."
    rm -f "$FALLOUT_4_DIR/Data/cc*"
    update_progress 14
fi

text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole."
zenity --info \
       --title="Overkill" \
       --width="450" \
       --text="$text" 2>/dev/null

# Cleanup progress file
rm -f "$PROGRESS_FILE"

exit
