#!/bin/bash

# Global Paths
DOWNGRADE_LIST_PATH="$HOME/Downloads/folon_downgrade.txt"
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

        STEAM_APPMANIFEST_PATH="$HOME/.steam/steam/steamapps/appmanifest_377160.acf"
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

depot_download_location_choice () {
# Check if STEAMCMD_DIR is set
    if [ -z "$STEAMCMD_DIR" ]; then
    	if [ -d "/run/media/mmcblk0p1" ]; then
    	    echo "SD Card detected"
    	response=$(zenity --forms --title="Choose file download location" --text="To downgrade Fallout 4 the script needs to download ~35GB of files.\nPlease ensure you have that much space available on the preferred device (SSD/microSD Card).\n\nWhere would you like to download the files?\n" --ok-label="Internal SSD" --cancel-label="microSD Card")
    		# Check the response
    		if [ $? -eq 0 ]; then
    		    echo "Internal SSD Selected"
                    STEAMCMD_DIR="$HOME/Downloads/SteamCMD"
    		else
    		    echo "microSD Card Selected"
    		    STEAMCMD_DIR="/run/media/mmcblk0p1/Downloads/SteamCMD"
    		fi
    	else
    	    echo "SD Card not detected - Default to Internal SSD"
    		zenity --info --title="Download process message" --width="450" --text="To downgrade Fallout 4 the script needs to download ~35GB of files.\nPlease ensure you have that much space available on your SSD.\n\nConfirm this window only after you make sure you have enough memory." 2>/dev/null
        	STEAMCMD_DIR="$HOME/Downloads/SteamCMD"
        fi
    else
        echo "STEAMCMD_DIR is set to $STEAMCMD_DIR"
    fi
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
	response=$(zenity --question --text="Looks like the script was interrupted.\n\nDo you want to continue the process from last known step or restart again from the beginning?" --ok-label="Restart from the beginning" --cancel-label="Continue from last known step" --title="Script interrupted")

	# Check the response
	if [ $? -eq 0 ]; then
	    echo "Restart the script from beginning"
	    rm -f "$PROGRESS_FILE"
	    LAST_STEP=0
	else
	    echo "Continue from last known step."
	    LAST_STEP=$(cat "$PROGRESS_FILE")
	fi
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

    depot_download_location_choice

    echo "Setting up SteamCMD..."
    mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR" || { echo "Failed to change directory to $STEAMCMD_DIR"; exit 1; }
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    update_progress 3
fi

sleep 1

# Step 4: Prompt user for Steam login credentials
if [ "$LAST_STEP" -lt 4 ]; then

    depot_download_location_choice

    echo "Please enter your Steam login credentials."
    echo "Note: Your login details are secure and will NOT be stored."

	# Loop until a non-empty username is entered
	while true; do
	    username=$(zenity --entry --title="Steam Username" --text="Enter name of your Steam user:")

	    if [ -n "$username" ]; then
		break
	    else
		zenity --error --title="Input Error" --text="Username cannot be empty. Please enter your Steam username."
	    fi
	done

	# Loop until a non-empty password is entered
	while true; do
	    password=$(zenity --password --title="Steam Password" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

	    if [ -n "$password" ]; then
		break
	    else
		zenity --error --title="Input Error" --text="Password cannot be empty. Please enter your Steam user password."
	    fi
	done

    # Run SteamCMD with the provided credentials and script
    echo "Running SteamCMD with provided credentials..."
    chmod +x "$STEAMCMD_DIR/steamcmd.sh"
    "$STEAMCMD_DIR/steamcmd.sh" +login "$username" "$password" +runscript "$DOWNGRADE_LIST_PATH"

	expected_files=(
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Geometry.csg"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast.cdx"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435871/Data/DLCRobot - Voices_en.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435871/Data/DLCRobot.esm"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377162/Fallout4.exe"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435870/Data/DLCRobot - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435870/Data/DLCRobot - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435870/Data/DLCRobot - Geometry.csg"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435870/Data/DLCRobot.cdx"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435880/Data/DLCworkshop01.esm"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435880/Data/DLCworkshop01 - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435880/Data/DLCworkshop01 - Geometry.csg"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435880/Data/DLCworkshop01 - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435880/Data/DLCworkshop01.cdx"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Fallout4_Default.ini"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Video/Intro.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Video/Endgame_MALE_A.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Video/Endgame_FEMALE_A.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Video/Endgame_FEMALE_B.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Video/Endgame_MALE_B.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377164/Data/Fallout4 - Voices.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Fallout4 - Sounds.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Fallout4 - Meshes.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/INTELLIGENCE.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/ENDURANCE.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/MainMenuLoop.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/STRENGTH.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/LUCK.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/PERCEPTION.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/CHARISMA.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/GameIntro_V3_B.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/Data/Video/AGILITY.bk2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377161/installscript.vdf"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435882/Data/DLCCoast - Voices_en.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435882/Data/DLCCoast.esm"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/bink2w64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/GFSDK_SSAO_D3D11.win64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/flexExtRelease_x64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/nvToolsExt64_1.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Fallout4/Fallout4Prefs.ini"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Low.ini"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/steam_api64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Fallout4Launcher.exe"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/flexRelease_x64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Ultra.ini"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/nvdebris.txt"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures9.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4038-HorseArmor - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Shaders.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures2.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFSVFO4002-MidCenturyModern - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures5.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4003-PipBoy(Camo01) - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - MeshesExtra.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures4.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4003-PipBoy(Camo01) - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Animations.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4006-PipBoy(Chrome) - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFRSFO4001-HandmadeShotgun - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4004-PipBoy(Camo02) - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4016-Prey - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Startup.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4020-PowerArmorSkin(Black) - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Meshes.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures1.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Nvflex.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4019-ChineseStealthArmor - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFSVFO4001-ModularMilitaryBackpack - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4006-PipBoy(Chrome) - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFSVFO4002-MidCenturyModern - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4020-PowerArmorSkin(Black) - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Materials.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures6.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Interface.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4019-ChineseStealthArmor - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Geometry.csg"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFRSFO4001-HandmadeShotgun - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4004-PipBoy(Camo02) - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4018-GaussRiflePrototype - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccFSVFO4001-ModularMilitaryBackpack - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4001-PipBoy(Black) - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Misc.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4001-PipBoy(Black) - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4044-HellfirePowerArmor - Main.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4.cdx"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4038-HorseArmor - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures3.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4016-Prey - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4.esm"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4018-GaussRiflePrototype - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures8.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/Fallout4 - Textures7.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Data/ccBGSFO4044-HellfirePowerArmor - Textures.ba2"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/GFSDK_GodraysLib.x64.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Medium.ini"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/msvcr110.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/Fallout4.ccc"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/msvcp110.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/cudart64_75.dll"
	"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_377163/High.ini"
	)

	# Check if all expected files exist
	for file in "${expected_files[@]}"; do
	    if [ ! -f "$file" ]; then
		echo "ERROR: Download progress was not successful. Please run the script again."
		exit 1
	    fi
	done
    	echo "All files downloaded successfully."
    
    update_progress 4
fi

# Step 5: Move downloaded content and clean up
if [ "$LAST_STEP" -lt 5 ]; then
    
    depot_download_location_choice

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
      text="<b>Please install Fallout London from Heroic Launcher</b>\n\n1. Go to 'Log in' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n\nOnce Fallout London is installed - Close Heroic Launcher to continue.\n\nPress 'OK' to start Heroic Launcher and close this message."
      zenity --info \
             --title="Overkill" \
             --width="450" \
             --text="$text" 2>/dev/null
      echo ""
      printf "Please install Fallout London from Heroic Launcher\n\n1. Go to 'Log in' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n\nOnce Fallout London is installed - Close Heroic Launcher to continue.\n"
      echo "" 
      flatpak run com.heroicgameslauncher.hgl > /dev/null 2>&1
    fi
    update_progress 6
fi

# Step 7: Move main game files
if [ "$LAST_STEP" -lt 7 ]; then

	if [ -d "$PROTON_DIR" ]; then
	    echo "Proton Experimental is installed. Continue..."
	else
	    echo "Proton Experimental is not installed."
	    exit
	fi

    echo "Step 7: Manual Installation of Fallout London"
    find_f4london_install_path
    if [ -d "$FALLOUT_LONDON_DIR" ]; then


	echo "$FALLOUT_4_DIR"
	echo "$WINEPREFIX/dosdevices"
     
	# Check if Fallout 4 directory exists
	if [ ! -d "$FALLOUT_4_DIR" ]; then
	    echo "Fallout 4 directory not found: $FALLOUT_4_DIR"
	    exit 1
	fi
	
	# Ensure Wine prefix directory exists
	if [ ! -d "$WINEPREFIX/dosdevices" ]; then
	    echo "Wine prefix dosdevices directory not found: $WINEPREFIX/dosdevices"
	    exit 1
	fi
	
	# Remove any existing symlink or directory
	if [ -e "$WINEPREFIX/dosdevices/d:" ]; then
	    rm -f "$WINEPREFIX/dosdevices/d:"
	fi

        zenity --info --title="Manual Installation" --width="450" --text="GoG installer for Fallout London will now launch.\n1. Click Install\n2. Select Drive D:\n3. Click Install Here\n\nClose the installer after it's done to continue the setup process.\n\nClick 'OK' in this window to start the process." 2>/dev/null

	# Create the symbolic link
	ln -s "$FALLOUT_4_DIR" "$WINEPREFIX/dosdevices/d:"
	
	# Verify if the link was created successfully
	if [ -L "$WINEPREFIX/dosdevices/d:" ]; then
	    echo "Symbolic link created successfully."
	else
	    echo "Failed to create symbolic link."
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
		
		while true; do
		    # Prompt the user to drop a file and read the input
		    echo ""
		    echo "Drop the 'Buffout 4' zip file here:"
		    read -r dropped_file
		
		    # Remove single quotes from the file path if they exist
		    dropped_file="${dropped_file//\'/}"
		
		    # Check if the input is empty
		    if [[ -z "$dropped_file" ]]; then
		        echo "Error: No file provided. Please drop a file."
		        continue
		    fi
		
		    # Check if the file exists
		    if [[ ! -e "$dropped_file" ]]; then
		        echo "Error: File does not exist. Please drop a valid file."
		        continue
		    fi
		
		    # Check if the file is a .zip file
		    if [[ ! "$dropped_file" =~ \.zip$ ]]; then
		        echo "Error: The file is not a .zip file. Please drop a .zip file."
		        continue
		    fi
		
		    # If all checks pass, break out of the loop
		    echo "The file '$dropped_file' is a valid .zip file."
		    break
		done

  
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

# Step 18: Disable Steam Updates for Fallout 4 (Optional Step)
if [ "$LAST_STEP" -lt 18 ]; then

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FILE="$STEAM_APPMANIFEST_PATH"

disable_steam_updates_escape_message() {
echo ""
echo "You decided not to disable automatic updates for Fallout 4. The game may still be automatically updated through Steam which can break the Fallout London installation."
echo ""
}

# Check if the file exists first
if [ -e "$FILE" ]; then
	# Get the attributes of the file
	attributes=$(lsattr "$FILE" 2>/dev/null | awk '{print $1}')

	# Check if the immutable attribute 'i' is set
	if [[ $attributes == *i* ]]; then
		printf "${GREEN}Automatic updates for Steam version of Fallout 4 are disabled. \n\n${RED}If you ever want to re-enable automatic updates for Fallout 4, run this command in konsole:\nsudo chattr -i \"$FILE\"${NC}\n\n"
	else

        response=$(zenity --question --text="(Optional Step) Automatic updates for Steam version of Fallout 4 are enabled. \nDo you want to disable Steam automatic updates for Fallout 4? \n\n- THIS ACTION IS PERMANENT AND WILL REQUIRE YOU TO RUN A COMMAND IN CONSOLE TO REVERT IT BACK!\n- THIS COMMAND REQUIRES SUPER USER (SUDO) PRIVILEGES.\n- YOU WILL NEED TO PROVIDE SUDO PASSWORD TO PERFORM THIS STEP." --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

		if [ $? -eq 0 ]; then

            response=$(zenity --question --text="If you don't know what you're doing it's recommended not to perform this action. \n\nAre you sure you want to continue?" --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

			# Evaluate the response
			if [ $? -eq 0 ]; then

				# Get the password status for the current user
				PASS_STATUS=$(passwd -S $USER 2>/dev/null)

				# Extract the status field from the output
				STATUS=${PASS_STATUS:${#USER}+1:2}

				password_set="N"

				if [ "$STATUS" = "NP" ]; then
                    echo ""
					echo "SUDO PASSWORD NOT SET"
                    echo ""

                    response=$(zenity --question --text="It looks like you don't have a SUDO password set for $USER user. Do you want to set it right now?\n\n<b>You will need to type it into the Konsole window</b>" --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

					# Evaluate the response
					if [ $? -eq 0 ]; then
						passwd
						password_set="Y"
						echo "SUDO Password is set for the user $USER"
					else
						disable_steam_updates_escape_message
					fi

				else
					echo "SUDO Password is set for the user $USER."
					password_set="Y"
				fi
			else
				disable_steam_updates_escape_message
			fi

			if [ "$password_set" = "Y" ]; then
                zenity --info --text="You will need to switch your focus on the Konsole window!\n\nPress 'OK' to proceed" --title="Disable Steam Updates"
				echo "Please provide your password to disable Steam Automatic Updates for Fallout 4."
				sudo chattr +i "$FILE"
				printf "${GREEN}Automatic updates for Steam version of Fallout 4 are disabled. \n\n${RED}If you ever want to re-enable automatic updates for Fallout 4, run this command in Konsole:\nsudo chattr -i \"$FILE\"${NC}\n\n"
			fi
		else
            disable_steam_updates_escape_message
		fi
	fi

else
	echo "file $file does not exist."
fi


    update_progress 18
fi

# Cleanup progress file
rm -f "$PROGRESS_FILE"

text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole.\nFallout London can be launched from Fallout 4 Steam page."
zenity --info \
       --title="Overkill" \
       --width="450" \
       --text="$text" 2>/dev/null
exit
