#!/bin/bash

# Global Paths
DOWNGRADE_LIST_PATH="$HOME/Downloads/folon_downgrade.txt"
STEAMCMD_DIR="$HOME/Downloads/SteamCMD"
F4LONDON_INI_URL="https://raw.githubusercontent.com/krupar101/f4london_steam_deck_ini/main/Fallout4.INI"
PROGRESS_FILE="$HOME/.folon_patch_progress"
PROTON_DIR="$HOME/.steam/steam/steamapps/common/Proton - Experimental"
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
HEROIC_CONFIG_FILE="$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic/gog_store/installed.json"
STEAM_COMPAT_DATA_PATH="$HOME/.steam/steam/steamapps/compatdata/377160"
WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx"
FALLOUT_4_STEAMUSER_DIR="$WINEPREFIX/drive_c/users/steamuser"

# Define paths to find installation directory.
F4_LAUNCHER_NAME="Fallout4Launcher.exe"
SSD_F4_LAUNCHER_FILE="$HOME/.steam/steam/steamapps/common/Fallout 4/$F4_LAUNCHER_NAME"
SD_CARD_F4_LAUNCHER_FILE="/run/media/mmcblk0p1/steamapps/common/Fallout 4/$F4_LAUNCHER_NAME"

# Check where Steam Version of Fallout 4 is installed.
if [ -e "$SSD_F4_LAUNCHER_FILE" ]; then
    echo "Fallout 4 recognized to be installed on Internal SSD"

        STEAM_APPMANIFEST_PATH="$HOME/.local/share/Steam/steamapps/appmanifest_377160.acf"
        FALLOUT_4_DIR="$HOME/.steam/steam/steamapps/common/Fallout 4"

elif [ -e "$SD_CARD_F4_LAUNCHER_FILE" ]; then
    echo "Fallout 4 recognized to be installed on SD Card"

        STEAM_APPMANIFEST_PATH="/run/media/mmcblk0p1/steamapps/appmanifest_377160.acf"
        FALLOUT_4_DIR="/run/media/mmcblk0p1/steamapps/common/Fallout 4"

else
    echo "ERROR: Steam version of Fallout 4 is not installed on this device."
fi


find_f4london_install_path() {
# Check if the file exists
if [[ ! -f "$HEROIC_CONFIG_FILE" ]]; then
    echo "Fallout London not recognized to be installed in Heroic Launcher."
fi

# Search for the install_path for the game "Fallout London"
install_path=$(jq -r '.installed[] | select(.install_path | contains("Fallout London")) | .install_path' "$HEROIC_CONFIG_FILE")

# Check if the install_path was found
if [[ -n "$install_path" ]]; then
    echo "Fallout London installation path found."
    FALLOUT_LONDON_DIR="$install_path"
else
    echo "Fallout London not recognized to be installed in Heroic Launcher."
    FALLOUT_LONDON_DIR="$HOME/Games/Heroic/Fallout London"
fi
GAME_EXE_PATH="$FALLOUT_LONDON_DIR/installer.exe"
}

# Function to handle script interruption
cleanup() {
    echo "Script interrupted. Rolling back one step..."
    if [ -f "$PROGRESS_FILE" ]; then
        LAST_STEP=$(cat "$PROGRESS_FILE")
        PREV_STEP=$((LAST_STEP - 1))
        if [ "$PREV_STEP" -lt 0 ]; then
            PREV_STEP=0
        fi
        echo "$PREV_STEP" > "$PROGRESS_FILE"
    fi
    pkill -f zenity
    exit 1
}


trap cleanup SIGINT SIGTERM

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

# Step 1: Check if Heroic Launcher is already installed
if [ "$LAST_STEP" -lt 1 ]; then
    if flatpak list --app | grep -q "com.heroicgameslauncher.hgl"; then
        echo "Heroic Launcher is installed."
    else
        echo "Setting up Heroic Launcher."
        flatpak install flathub com.heroicgameslauncher.hgl
    fi
    update_progress 1
fi

sleep 1

# Step 2: Setting up downgrade-list
if [ "$LAST_STEP" -lt 2 ]; then
    echo "Setting up downgrade-list..."
    cat <<EOL > "$DOWNGRADE_LIST_PATH"
download_depot 377160 377161 7497069378349273908
download_depot 377160 377162 5847529232406005096
download_depot 377160 377163 5819088023757897745
download_depot 377160 377164 2178106366609958945
download_depot 377160 435880 1255562923187931216
download_depot 377160 435870 1691678129192680960
download_depot 377160 435871 5106118861901111234
download_depot 377160 435881 1207717296920736193
download_depot 377160 435882 8482181819175811242
download_depot 480630 5527412439359349504
download_depot 480631 6588493486198824788
download_depot 393885 5000262035721758737
download_depot 490650 4873048792354485093
download_depot 393895 7677765994120765493
quit
EOL
    update_progress 2
fi

sleep 1

# Step 3: Setting up SteamCMD
if [ "$LAST_STEP" -lt 3 ]; then
    echo "Setting up SteamCMD..."
    mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR" || { echo "Failed to change directory to $STEAMCMD_DIR"; exit 1; }
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    update_progress 3
fi

sleep 1

# Step 4: Prompt user for Steam login credentials
if [ "$LAST_STEP" -lt 4 ]; then
    echo "Please enter your Steam login credentials."
    echo "Note: Your login details are secure and will NOT be stored."

    username=$(zenity --entry --title="Steam Username" --text="Enter name of your Steam user:")
    password=$(zenity --password --title="Steam Password" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

    # Run SteamCMD with the provided credentials and script
    echo "Running SteamCMD with provided credentials..."
    chmod +x "$STEAMCMD_DIR/steamcmd.sh"
    "$STEAMCMD_DIR/steamcmd.sh" +login "$username" "$password" +runscript "$DOWNGRADE_LIST_PATH"
    update_progress 4
fi

# Step 5: Move downloaded content and clean up
if [ "$LAST_STEP" -lt 5 ]; then
    echo "Moving downloaded content and cleaning up..."
    rsync -av --remove-source-files "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/"*/ "$FALLOUT_4_DIR/"

    # Manually move and overwrite the Fallout4 - Meshes.ba2 file
    if [ -f "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Meshes.ba2" ]; then
        mv -f "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Meshes.ba2" "$FALLOUT_4_DIR/Data/"
    fi

    # Remove empty directories
    find "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/" -type d -empty -delete

    # Check if there are any files left in the subfolders
    if find "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/" -type f | read; then
        echo "Error: One or more files need to be moved manually."
        echo "File(s) still present:"
        find "$STEAMCMD_DIR/linux32/steamapps/content/app_377160/" -type f
        zenity --info --title="Manual Intervention Required" --width="450" --text="Some files could not be moved. Please move the remaining files manually from '$STEAMCMD_DIR/linux32/steamapps/content/app_377160/' to '$FALLOUT_4_DIR'. However, do not move folders starting with 'depot_'. Move their content. Normally it should only be one file, called Fallout4 - Meshes.ba2 that has to go into /Data/.\n\nClick OK when you have finished moving the files to continue." 2>/dev/null
    else
        rm -rf "$STEAMCMD_DIR"
        rm "$DOWNGRADE_LIST_PATH"
    fi
    update_progress 5
fi

# Step 6: Check for Fallout: London installation
if [ "$LAST_STEP" -lt 6 ]; then
    find_f4london_install_path
    if [ ! -d "$FALLOUT_LONDON_DIR" ]; then
      text="<b>Please install Fallout London from Heroic Launcher</b>\n\n1. Go to 'Manage Accounts' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n\nOnce Fallout London is installed - Close Heroic Launcher to continue.\n\nPress 'OK' to start Heroic Launcher and close this message."
      zenity --info \
             --title="Overkill" \
             --width="450" \
             --text="$text" 2>/dev/null
      echo ""
      printf "Please install Fallout London from Heroic Launcher\n\n1. Go to 'Manage Accounts' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n\nOnce Fallout London is installed - Close Heroic Launcher to continue.\n"
      echo "" 
      flatpak run com.heroicgameslauncher.hgl > /dev/null 2>&1
    fi
    update_progress 6
fi

# Step 7: Move main game files
if [ "$LAST_STEP" -lt 7 ]; then
    echo "Step 9: Manual Installation of Fallout London"
    find_f4london_install_path
    if [ -d "$FALLOUT_LONDON_DIR" ]; then
    
        # Export the variables
        export STEAM_COMPAT_DATA_PATH
        export WINEPREFIX

        # Create the dosdevices directory if it doesn't exist
        mkdir -p "$WINEPREFIX/dosdevices"

        # Remove existing symlink if it exists
        if [ -L "$WINEPREFIX/dosdevices/d:" ]; then
            rm "$WINEPREFIX/dosdevices/d:"
        fi

        # Create the new symlink
        ln -s "$FALLOUT_4_DIR" "$WINEPREFIX/dosdevices/d:"

        zenity --info --title="Manual Installation" --width="450" --text="GoG installer for Fallout London will now launch.\n1. Click Install\n2. Select Drive D:\n3. Click Install Here\n\nClose the installer after it's done to continue the setup process.\n\nClick 'OK' in this window to start the process." 2>/dev/null

        
        # Verify the symlink
        if [ -L "$WINEPREFIX/dosdevices/d:" ]; then
            echo "Drive D: successfully created pointing to $FALLOUT_4_DIR"
        else
            echo "Failed to create Drive D:"
            exit
        fi

	printf "\n\nGoG installer for Fallout London will now launch.\n\n1. Click Install\n2. Select Drive D:\n3. Click Install Here\n\nClose the installer after it's done to continue the setup process.\n\n"
	
	# Run the game using Proton with the specified Wine prefix and compatibility data path
	STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" \
	STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
	WINEPREFIX="$WINEPREFIX" \
	"$PROTON_DIR/proton" run "$GAME_EXE_PATH"

        update_progress 7
    fi
fi

# Step 8: Check if Fallout 4 is properly downgraded
if [ "$LAST_STEP" -lt 8 ]; then
    	fallout4defaultlauncher_default_sha256sum="75065f52666b9a2f3a76d9e85a66c182394bfbaa8e85e407b1a936adec3654cc"
    	fallout4defaultlauncher_actual_sha256sum=$(sha256sum "$FALLOUT_4_DIR/Fallout4Launcher.exe" | awk '{print $1}')
    	
    	if [ "$fallout4defaultlauncher_default_sha256sum" == "$fallout4defaultlauncher_actual_sha256sum" ]; then
    		    echo "You are using standard Fallout 4 launcher exe. Your Game is not downgraded."
    		    exit 1
    	else
    		echo "Correct. Game does not launch with standard launcher"
    	fi
    update_progress 8
fi


# Step 9: Check if the launcher is set to f4se_loader.exe and rename Fallout4Launcher.exe to Fallout4Launcher.exe.old and f4se_loader.exe to Fallout4Launcher.exe if needed.
if [ "$LAST_STEP" -lt 9 ]; then

fallout4defaultlauncher_downgraded_sha256sum="5e457259dca72c8d1217e2f08a981b630ffd5fe0d30bf28269c8b7898491c6ae"
correct_launcher_sha="f41d4065a1da80d4490be0baeee91985d2b10b3746ec708b91dc82a64ec1e2a6"
fallout4defaultlauncher_actual_sha256sum=$(sha256sum "$FALLOUT_4_DIR/Fallout4Launcher.exe" | awk '{print $1}')

if [ "$fallout4defaultlauncher_downgraded_sha256sum" == "$fallout4defaultlauncher_actual_sha256sum" ]; then
    echo "You are using a downgraded standard Fallout 4 launcher exe."
    launcher_dir="$FALLOUT_4_DIR"
    launcher_file="$launcher_dir/Fallout4Launcher.exe"
    f4se_loader_file="$launcher_dir/f4se_loader.exe"
    launcher_old_file="$launcher_dir/Fallout4Launcher.exe.old"

    # Check if Fallout4Launcher.exe and Fallout4Launcher.exe.old exist
    if [ -f "$launcher_file" ] && [ -f "$launcher_old_file" ]; then
        launcher_check=$(sha256sum "$launcher_file" | awk '{print $1}')
        if [ "$launcher_check" == "$correct_launcher_sha" ]; then
            echo "Launcher correctly renamed."
        fi
    fi

    # Check if f4se_loader.exe and downgraded Fallout4Launcher.exe exist
    if [ -f "$f4se_loader_file" ] && [ "$fallout4defaultlauncher_actual_sha256sum" == "$fallout4defaultlauncher_downgraded_sha256sum" ]; then
        echo "Both f4se_loader.exe and downgraded Fallout4Launcher.exe found. Renaming the files."
        mv "$launcher_file" "$launcher_old_file"
        mv "$f4se_loader_file" "$launcher_file"
        echo "Files have been renamed."
    else
        echo "ERROR: Fallout London is not installed or installation was not successful."
        exit 1
    fi

else
    echo "Correct. Game does not launch with standard downgraded launcher"
fi

    update_progress 9
fi





# Step 10: Check if the sha256sum for f4se_loader.exe is correct.
if [ "$LAST_STEP" -lt 10 ]; then

    launcher_dir="$FALLOUT_4_DIR"
    launcher_file="$launcher_dir/Fallout4Launcher.exe"
    launcher_check=$(sha256sum "$launcher_file" | awk '{print $1}')
    correct_launcher_sha="f41d4065a1da80d4490be0baeee91985d2b10b3746ec708b91dc82a64ec1e2a6"

    # Check if the launcher sha is correct
    if [ "$launcher_check" == "$correct_launcher_sha" ]; then
        echo "f4se_loader.exe is correctly selected to run the game."
        
    else
        echo "ERROR: f4se_loader.exe was not properly renamed to Fallout4Launcher.exe or a new version of F4SE was added to GoG Installer."
    fi

    update_progress 10
fi



# Step 11: Ensure that the proper Fallout4.INI is placed correctly.
if [ "$LAST_STEP" -lt 11 ]; then

    ini_file_desired_checksum="82cfb36d003551ee5db7fb3321e830e1bceed53aa74aa30bb49bf0278612a9d7"
    fallout4_mygames_dir="$FALLOUT_4_STEAMUSER_DIR/Documents/My Games/Fallout4"
    file_path="$fallout4_mygames_dir/Fallout4.INI"
    computed_checksum=$(sha256sum "$file_path" | awk '{ print $1 }')

    if [ "$computed_checksum" == "$ini_file_desired_checksum" ]; then
        echo "Fallout4.INI correctly placed"
    else
        echo "Fallout4.INI checksum does not match."

        if [ -d "$fallout4_mygames_dir" ]; then
            echo "'My Games' Fallout 4 directory exists."
        else
            mkdir -p "$fallout4_mygames_dir"
            echo "Directory $fallout4_mygames_dir created."
        fi
    
            if [ -e "$fallout4_mygames_dir/Fallout4.INI" ]; then
                rm "$fallout4_mygames_dir/Fallout4.INI"
            fi

            if [ -e "$fallout4_mygames_dir/Fallout4.ini" ]; then
                rm "$fallout4_mygames_dir/Fallout4.ini"
            fi

                wget -O "$file_path" "$F4LONDON_INI_URL"
                
                if [ $? -eq 0 ]; then
                    echo "File downloaded successfully to $file_path."

                else
                    echo "ERROR: Failed to download Fallout4.INI file."
                    exit 1
                fi
    fi
    update_progress 11
fi



# Step 12: Move AppData files to steam directory. Backup existing files if there are any.
if [ "$LAST_STEP" -lt 12 ]; then
        find_f4london_install_path

		# Define the directories and files
		TARGET_DIR="$FALLOUT_4_STEAMUSER_DIR/AppData/Local/Fallout4"
		BACKUP_DIR="$TARGET_DIR/backup"
		FILES=("DLCList.txt" "Plugins.fo4viewsettings" "Plugins.txt" "UserDownloadedContent.txt")
		# Check if the target directory exists
		if [ -d "$TARGET_DIR" ]; then
		    echo "AppData Directory Exists."
		else
		    echo "AppData Directory does not exist. Creating directory."
			mkdir -p "$TARGET_DIR"
			echo "AppData Directory created."
		fi

		# Check for the existence of the files
		missing_files=0
		for file in "${FILES[@]}"; do
		    if [ ! -f "$TARGET_DIR/$file" ]; then
			missing_files=1
			break
		    fi
		done

		if [ $missing_files -eq 1 ]; then
		    if [ ! -d "$BACKUP_DIR" ]; then
                mkdir "$BACKUP_DIR"
                for file in "${FILES[@]}"; do
                    if [ -f "$TARGET_DIR/$file" ]; then
                    cp "$TARGET_DIR/$file" "$BACKUP_DIR/"
                    fi
                done
		    fi

            # Check if no leftover files are left after backup 
                files_exist=1
                for file in "${FILES[@]}"; do
                    if [ ! -f "$FALLOUT_LONDON_DIR/__AppData/$file" ]; then
                    files_exist=0
                    break
                    fi
                done

		        echo "The AppData files are not correctly placed. Moving AppData files."

                if [ $files_exist -eq 1 ]; then
                    for file in "${FILES[@]}"; do
                        cp "$FALLOUT_LONDON_DIR/__AppData/$file" "$TARGET_DIR/"
                    done
                    echo "AppData files copied."
                fi

		else
		    echo "All files are present in the AppData directory."
		fi

    update_progress 12
fi


# Step 13: Verify if 'plugins' folder is renamed to 'Plugins'. If not - rename it. 
if [ "$LAST_STEP" -lt 13 ]; then

                    # Define folder paths
                    FOLDER1="$FALLOUT_4_DIR/Data/F4SE/plugins"
                    FOLDER2="$FALLOUT_4_DIR/Data/F4SE/Plugins"

                    # Check if the "plugins" folder exists
                    if [ -d "$FOLDER1" ]; then
                            mv "$FOLDER1" "$FOLDER2"
                            echo "Folder 'plugins' renamed to 'Plugins'."
                    else
                        if [ ! -d "$FOLDER1" ] && [ ! -d "$FOLDER2" ]; then
		                    echo "Plugins folder does not exist under $FOLDER1. Fallout London files were not moved correctly."
		                	exit 1
                        else
                         echo "Plugins folder exists and is named correctly."
                    	fi
                    fi

    update_progress 13
fi



# Step 14: Remove Fallout4Custom.ini & Fallout4Prefs.ini from My Games directory. Files proven to cause trouble for some users.
if [ "$LAST_STEP" -lt 14 ]; then

                    # Define file paths
                    file1="$FALLOUT_4_STEAMUSER_DIR/Documents/My Games/Fallout4/Fallout4Custom.ini"
                    file2="$FALLOUT_4_STEAMUSER_DIR/Documents/My Games/Fallout4/Fallout4Prefs.ini"

                    # Check if the first file exists
                    if [ -e "$file1" ]; then
                            rm "$file1"
                            echo "File removed: ${file1}"
                    else
                        echo "File does not exist which is correct: ${file1}"
                    fi

                    # Check if the second file exists
                    if [ -e "$file2" ]; then
                            rm "$file2"
                            echo "File removed: ${file2}"
                    else
                        echo "File does not exist which is correct: ${file2}"
                    fi

    update_progress 14
fi



# Step 15: Remove cc* (Creation Club) files from Fallot 4 Data directory.
if [ "$LAST_STEP" -lt 15 ]; then

			FOLDER_LOCATION="$FALLOUT_4_DIR/Data"

			# Check for files starting with cc in the folder
			FILES=$(find "$FOLDER_LOCATION" -name 'cc*' 2>/dev/null)

			if [ -n "$FILES" ]; then
				rm -f "${FOLDER_LOCATION}/cc"*
				echo "Creation Club files have been removed."
			else
			    # No files found
			    echo "No Creation Club items are installed."
			fi

    update_progress 15
fi



# Step 16: Ensure Buffout 4 mod is installed. If not help install it. 
if [ "$LAST_STEP" -lt 16 ]; then

        # Define the path for Buffout Mod files
        BUFFOUT_FOLDER="$FALLOUT_4_DIR/Data/F4SE/Plugins/Buffout4"
        BUFFOUT_DLL="$FALLOUT_4_DIR/Data/F4SE/Plugins/Buffout4.dll"
        BUFFOUT_PRELOAD="$FALLOUT_4_DIR/Data/F4SE/Plugins/Buffout4_preload.txt"

        # Check if the Buffout Mod folder and files exist
        if [ -d "$BUFFOUT_FOLDER" ] && [ -f "$BUFFOUT_DLL" ] && [ -f "$BUFFOUT_PRELOAD" ]; then
            all_prerequisites_met=true
            echo "'Buffout 4' Mod is recognized to be installed."
        else
            echo "'Buffout Mod' is not installed. If it's not installed you may experience crashes during the gameplay of Fallout London."

        zenity --info --title="Manual Installation" --width="450" --text="<b>'Buffout 4' mod needs to be installed.</b> \nAs soon as you Accept this message the Nexus page with 'Buffout 4' mod will be opened.\n\n1. Download the mod from nexus.\n2. After downloading switch your focus to the Konsole window.\n3. Drag and drop the downloaded .zip file with the mod onto the konsole window.\n4. Press enter." 2>/dev/null
                
                xdg-open "https://www.nexusmods.com/fallout4/mods/47359?tab=files" > /dev/null 2>&1 &
                

                echo ""
                echo "1. Please download 'Buffout 4' mod from nexus (https://www.nexusmods.com/fallout4/mods/47359?tab=files)"
                echo "2. Drag and drop the downloaded zip file on this window"
                echo "3. Click on this window and press enter."
                echo ""
                echo "If you don't have a keyboard connected you can press 'STEAM' + 'X' buttons to launch the software keyboard."
                echo ""
                echo "Drop the zip file here:"

                # Read the full path of the dropped file
                read -r dropped_file
                
                # Remove single quotes and replace with double quotes
                dropped_file="${dropped_file//\'/}"
                # Check if the file exists
                if [ -f "$dropped_file" ]; then
                echo "File dropped: ${dropped_file}"
                
                # Define the target directory
                    target_dir="$FALLOUT_4_DIR/Data"

                    # Unzip the file to the target directory
                    unzip -o "$dropped_file" -d "$target_dir"

                        # Check if the unzip command was successful
                        if [ $? -eq 0 ]; then
                            echo "Successfully unzipped '$dropped_file' to '$target_dir'."

                                if [ -d "$BUFFOUT_FOLDER" ] && [ -f "$BUFFOUT_DLL" ] && [ -f "$BUFFOUT_PRELOAD" ]; then
                                all_prerequisites_met=true
                                echo "'Buffout 4' Mod is recognized to be installed."
                                else
                                echo "Error: Failed to install 'Buffout 4' from file '$dropped_file'. Please install it manually or re-run the script and try again."
                                exit 1
                                fi
                        else
                            echo "Error: Failed to install 'Buffout 4' from file '$dropped_file'. Please install it manually or re-run the script and try again."
                            exit 1
                        fi
                else
                    echo "The dropped file does not exist. Please run the script again."
                    exit 1
                fi
        fi


    update_progress 16
fi


# Step 17: Disable MemoryManager in 'Buffout 4'. Fallout London has it's own memory manager and the two sometimes cause conflicts and crash the game.
if [ "$LAST_STEP" -lt 17 ]; then

			# Path to the config file
			config_file="$FALLOUT_4_DIR/Data/F4SE/Plugins/Buffout4/config.toml"

			# Check if the config file exists
			if [[ -f "$config_file" ]]; then
			    # Read the current value of MemoryManager
			    memory_manager_value=$(grep -E '^MemoryManager = (true|false)' "$config_file" | awk '{print $3}')

			    if [[ "$memory_manager_value" == "true" ]]; then

                # Change the line to MemoryManager = false
                sed -i 's/^MemoryManager = true/MemoryManager = false/' "$config_file"
                echo "MemoryManager has been disabled in the 'Buffout 4' config."

			    elif [[ "$memory_manager_value" == "false" ]]; then
				echo "MemoryManager has been disabled in the 'Buffout 4' config."
			    else
				echo "The MemoryManager setting was not found or is not set to true/false. Please reinstall 'Buffout 4' Mod and run the script again."
				exit
			    fi
			else
				echo "The MemoryManager setting was not found or is not set to true/false. Please reinstall 'Buffout 4' Mod and run the script again."
				exit
			fi

    update_progress 17
fi

# Step 18: Cleanup: Remove Fallout London directory
# if [ "$LAST_STEP" -lt 18 ]; then
#     find_f4london_install_path
#     echo "Cleaning up..."
#     rm -rf "$FALLOUT_LONDON_DIR"
#     update_progress 18
# fi

text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole.\nFallout London can be launched from Fallout 4 Steam page."
zenity --info \
       --title="Overkill" \
       --width="450" \
       --text="$text" 2>/dev/null

# Cleanup progress file
rm -f "$PROGRESS_FILE"

exit
