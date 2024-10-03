#!/bin/bash
echo "---------------------"
echo ""
echo "Fallout London installation script for Steam Deck by krupar"
echo ""
echo "---------------------"
sleep 1
echo "---------------------"
echo ""
echo "Published by Overkill.wtf"
echo ""
echo "---------------------"
sleep 1

# Global Paths
DOWNGRADE_LIST_PATH="$HOME/Downloads/folon_downgrade.txt"
F4LONDON_INI_URL="https://raw.githubusercontent.com/krupar101/f4london_steam_deck_ini/main/Fallout4.INI"
PROGRESS_FILE="$HOME/.folon_patch_progress"
F4_VERSION_SELECTION_FILE="$HOME/.folon_f4_version_selected"
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
HEROIC_CONFIG_FILE="$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic/gog_store/installed.json"
HEROIC_PREFIX_FILE="$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic/GamesConfig/1998527297.json"
PROTON_DIR_SSD="$HOME/.steam/steam/steamapps/common/Proton - Experimental"

# Define paths to find installation directory.
F4_LAUNCHER_NAME="Fallout4Launcher.exe"
SSD_F4_LAUNCHER_FILE="$HOME/.steam/steam/steamapps/common/Fallout 4/$F4_LAUNCHER_NAME"

check_if_sd_card_is_mounted_and_set_proton_f4_paths() {
	#Function to automatically detect the SD card mount location and set Proton Directory and Fallout 4 launcher Directory for installation detection
	SD_MOUNT=$(findmnt -rn -o TARGET | grep '/run/media')

	if [ -n "$SD_MOUNT" ]; then
		echo "SD Card is mounted at: $SD_MOUNT"
		PROTON_DIR_SD="$SD_MOUNT/steamapps/common/Proton - Experimental"
		SD_CARD_F4_LAUNCHER_FILE="$SD_MOUNT/steamapps/common/Fallout 4/$F4_LAUNCHER_NAME"
	else
		echo "SD Card is not mounted."
	fi

}

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
		echo "$FALLOUT_LONDON_DIR"
	else
		echo "Fallout London not recognized to be installed in Heroic Launcher."
		FALLOUT_LONDON_DIR="$HOME/Games/Heroic/Fallout London"
	fi
	GAME_EXE_PATH="$FALLOUT_LONDON_DIR/installer.exe"
}

find_fallout4_heroic_install_path() {
	# Check if the file exists
	if [[ ! -f "$HEROIC_CONFIG_FILE" ]]; then
		echo "Fallout 4 not recognized to be installed in Heroic Launcher."
	fi

	# Search for the install_path for the game "Fallout London"
	install_path=$(jq -r '.installed[] | select(.install_path | contains("Fallout 4")) | .install_path' "$HEROIC_CONFIG_FILE")

	# Check if the install_path was found
	if [[ -n "$install_path" ]]; then
		echo "Fallout 4 installation path found."
		FALLOUT_4_DIR="$install_path"
	else
		echo "Fallout 4 not recognized to be installed in Heroic Launcher. Install it and try again."
		exit
	fi
}

depot_download_location_choice() {
	# Check if STEAMCMD_DIR is set
	check_if_sd_card_is_mounted_and_set_proton_f4_paths
	if [ -z "$STEAMCMD_DIR" ]; then
		if [ -d "$SD_MOUNT" ]; then
			echo "SD Card available"
			response=$(zenity --forms --title="Choose file download location" --width="450" --text="To downgrade Fallout 4 the script needs to download ~35GB of files.\nPlease ensure you have that much space available on the preferred device (SSD/microSD Card).\n\nWhere would you like to download the files?\n" --ok-label="Internal SSD" --cancel-label="microSD Card")
			# Check the response
			if [ $? -eq 0 ]; then
				echo "Internal SSD Selected"
				STEAMCMD_DIR="$HOME/Downloads/SteamCMD"
			else
				set_sd_card_paths_4_steamcmddir
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

check_if_proton_experimental_is_installed() {
	check_if_sd_card_is_mounted_and_set_proton_f4_paths
	if [ -e "$PROTON_DIR_SSD/proton" ]; then
		echo "Proton Experimental is installed on Internal SSD. Continue..."
		PROTON_DIR="$PROTON_DIR_SSD"
	elif [ -e "$PROTON_DIR_SD/proton" ]; then
		echo "Proton Experimental is installed on SD card. Continue..."
		PROTON_DIR="$PROTON_DIR_SD"
	else
		echo "Proton Experimental is not installed."
		echo ""
		echo "Go to your STEAM LIBRARY and install 'Proton Experimental'"
		echo "After that run the script one more time and select 'Continue from last known step'"
		exit
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
		echo "$PREV_STEP" >"$PROGRESS_FILE"
	fi
	pkill -f zenity
	exit 1
}
trap cleanup SIGINT SIGTERM

ask_user_if_he_wants_to_update() {

	if [ "$F4_VERSION" == "STEAM" ]; then

		#Ask what to do if the progress file does not exist.
		response=$(zenity --question --text="The script allows you to perform 2 actions.\n\n1. Install Fallout London\n2. Update Fallout London to a new version\n\nWhich one do you want to perform?" --width="450" --ok-label="Install" --cancel-label="Update" --title="Choose action")

		# Check the response
		if [ $? -eq 0 ]; then
			echo "Install selected."
		else
			echo "Update selected."

			response=$(zenity --question --text="Heroic Launcher will now start.\nMake sure to update Fallout London to the newest version.\n\nIf you don't have it installed make sure you are logged in to GoG and install Fallout London.\n\nOnce completed close Heroic Launcher.\n\nPress 'Continue' to start the process." --width="450" --ok-label="Continue" --cancel-label="Cancel" --title="Check if updates are applied")
			printf "\n\nHeroic Launcher will now start.\nMake sure to update Fallout London to the newest version.\n\nIf you don't have it installed make sure you are logged in to GoG and install Fallout London.\n\nOnce completed close Heroic Launcher.\n\n"
			# Check the response
			if [ $? -eq 0 ]; then
				echo "Ok pressed"
				check_if_heroic_is_installed_else_install
				flatpak run com.heroicgameslauncher.hgl >/dev/null 2>&1
				LAST_STEP=5
			else
				echo "Cancel pressed"
				exit
			fi
		fi

	elif
		[ "$F4_VERSION" == "GOG" ]
	then
		check_if_heroic_is_installed_else_install
		LAST_STEP=5
		#Ask what to do if the progress file does not exist.
		response=$(zenity --question --text="The script allows you to perform 2 actions.\n\n1. Install Fallout London\n2. Update Fallout London to a new version\n\nWhich one do you want to perform?" --width="450" --ok-label="Install" --cancel-label="Update" --title="Choose action")
		# Check the response
		if [ $? -eq 0 ]; then
			echo "Install selected."
		else
			echo "Update selected."

			response=$(zenity --question --text="Heroic Launcher will now start.\nMake sure to update Fallout London to the newest version.\n\nIf you don't have it installed make sure you are logged in to GoG and install Fallout London.\n\nOnce completed close Heroic Launcher.\n\nPress 'Continue' to start the process." --width="450" --ok-label="Continue" --cancel-label="Cancel" --title="Check if updates are applied")
			printf "\n\nHeroic Launcher will now start.\nMake sure to update Fallout London to the newest version.\n\nIf you don't have it installed make sure you are logged in to GoG and install Fallout London.\n\nOnce completed close Heroic Launcher.\n\n"
			# Check the response
			if [ $? -eq 0 ]; then
				echo "Ok pressed"

				flatpak run com.heroicgameslauncher.hgl >/dev/null 2>&1
			else
				echo "Cancel pressed"
				exit
			fi
		fi

	fi
}

check_if_heroic_is_installed_else_install() {
	if flatpak list --app | grep -q "com.heroicgameslauncher.hgl"; then
		echo "Heroic Launcher is installed."
	else
		echo "Setting up Heroic Launcher."
		flatpak -y install flathub com.heroicgameslauncher.hgl
	fi
}

set_sd_card_paths_4_steamcmddir() {
	echo "microSD Card Selected"
	if [ -d "$SD_MOUNT" ]; then
		echo "set the path to the default sd card location"
		STEAMCMD_DIR="$SD_MOUNT/Downloads/SteamCMD"
	else
		echo "ERROR: This error should never be shown. If it is it means that microsd card was wrongly detected in depot_download_location_choice function."
	fi
}

# Function to update progress
update_progress() {
	echo "$1" >"$PROGRESS_FILE"
}

update_selected_version() {
	echo "$1" >"$F4_VERSION_SELECTION_FILE"
}

select_gog_or_steam_to_update_or_install() {
	response=$(zenity --question --text="Which Version of Fallout 4 do you own?" --width="450" --ok-label="GoG" --cancel-label="Steam" --title="Fallout 4 version selection")

	# Check the response
	if [ $? -eq 0 ]; then
		echo "GoG Selected"
		update_selected_version "GOG"
	else
		echo "Steam selected"
		update_selected_version "STEAM"
	fi
}

read_selected_version() {
	if [ ! -f "$F4_VERSION_SELECTION_FILE" ]; then
		echo "Fallout 4 version was not selected"
	else
		echo "Reading selected version from file."
		F4_VERSION=$(cat "$F4_VERSION_SELECTION_FILE")
	fi
}

find_f4_heroic_prefix_location() {
	if [[ ! -f "$HEROIC_PREFIX_FILE" ]]; then
		echo "Fallout 4 is not installed in Heroic."
		check_if_heroic_is_installed_else_install

		response=$(zenity --question --text="Heroic Launcher will now start.\nMake sure to install Fallout 4.\n\nOnce completed close Heroic Launcher.\n\nPress 'Continue' to start the process." --width="450" --ok-label="Continue" --cancel-label="Cancel" --title="Check if updates are applied")
		printf "\n\nHeroic Launcher will now start.\nMake sure to install Fallout 4.\n\nOnce completed close Heroic Launcher.\n\nPress 'Continue' to start the process.\n\n"
		# Check the response
		if [ $? -eq 0 ]; then
			echo "Ok pressed"
			flatpak run com.heroicgameslauncher.hgl >/dev/null 2>&1
		else
			echo "Cancel pressed"
			exit
		fi
	fi

	# Extract the winePrefix using jq
	echo "Fallout 4 recognized to be installed in Heroic Launcher."
	COMPAT_DATA_PATH="$(jq -r '."1998527297".winePrefix' "$HEROIC_PREFIX_FILE")"
	WINEPREFIX="$COMPAT_DATA_PATH/pfx"
	FALLOUT_4_STEAMUSER_DIR="$WINEPREFIX/drive_c/users/steamuser"
}

check_if_fallout_4_is_installed() {
	check_if_sd_card_is_mounted_and_set_proton_f4_paths
	if [ "$F4_VERSION" == "STEAM" ]; then
		echo "F4_VERSION is STEAM"

		COMPAT_DATA_PATH="$HOME/.steam/steam/steamapps/compatdata/377160"
		WINEPREFIX="$COMPAT_DATA_PATH/pfx"
		FALLOUT_4_STEAMUSER_DIR="$WINEPREFIX/drive_c/users/steamuser"

		# Check where Steam Version of Fallout 4 is installed.
		if [ -e "$SSD_F4_LAUNCHER_FILE" ]; then
			echo "Fallout 4 recognized to be installed on Internal SSD"

			STEAM_APPMANIFEST_PATH="$HOME/.steam/steam/steamapps/appmanifest_377160.acf"
			FALLOUT_4_DIR="$HOME/.steam/steam/steamapps/common/Fallout 4"

		elif [ -e "$SD_CARD_F4_LAUNCHER_FILE" ]; then
			echo "Fallout 4 recognized to be installed on SD Card"

			STEAM_APPMANIFEST_PATH="$SD_MOUNT/steamapps/appmanifest_377160.acf"
			FALLOUT_4_DIR="$SD_MOUNT/steamapps/common/Fallout 4"
		else
			echo "ERROR: Steam version of Fallout 4 is not installed on this device."
			exit
		fi
	elif [ "$F4_VERSION" == "GOG" ]; then
		echo "F4_VERSION is GOG"
		find_f4_heroic_prefix_location
		find_fallout4_heroic_install_path
	else
		echo "Unknown F4_VERSION: $F4_VERSION"
		rm -f "$PROGRESS_FILE"
		rm -f "$F4_VERSION_SELECTION_FILE"
		echo "Please run the script again."
		exit
	fi

}

# Function to compare checksums and replace files if needed
compare_and_replace_appdata() {
	local target_file="$1" # Target file path
	local source_file="$2" # Source file path

	# Calculate SHA256 checksums for both files and extract only the hash values
	local target_checksum source_checksum
	target_checksum=$(sha256sum "$target_file" 2>/dev/null | awk '{print $1}')
	source_checksum=$(sha256sum "$source_file" 2>/dev/null | awk '{print $1}')

	# Compare checksums and decide what to do
	if [[ -n "$target_checksum" && -n "$source_checksum" ]]; then
		if [[ "$target_checksum" == "$source_checksum" ]]; then
			echo "Files $target_file and $source_file are identical. No backup or replacement needed."
		else
			echo "Files $target_file and $source_file differ. Backing up and replacing $target_file with $source_file."
			# Back up the existing file in the target directory if it differs from the source file
			cp "$target_file" "$BACKUP_DIR/"
			echo "Backup of $target_file created at $BACKUP_DIR."
			# Replace the target file with the source file
			cp "$source_file" "$target_file"
			echo "$target_file has been replaced with $source_file."
		fi
	elif [[ -z "$target_checksum" && -f "$source_file" ]]; then
		echo "$target_file does not exist in the target directory. Copying $source_file to target directory."
		cp "$source_file" "$target_file"
		echo "$source_file has been copied to $target_file."
	else
		echo "One or both files do not exist: $target_file or $source_file. Skipping replacement."
	fi
}

# Read last completed step

if [ -f "$PROGRESS_FILE" ] && [ -f "$F4_VERSION_SELECTION_FILE" ]; then

	response=$(zenity --question --text="Looks like the script was interrupted.\n\nDo you want to continue the process from last known step or restart again from the beginning?" --width="450" --ok-label="Restart from the beginning" --cancel-label="Continue from last known step" --title="Script interrupted")

	# Check the response
	if [ $? -eq 0 ]; then
		echo "Restart the script from beginning"
		rm -f "$PROGRESS_FILE"
		rm -f "$F4_VERSION_SELECTION_FILE"
		LAST_STEP=0
		select_gog_or_steam_to_update_or_install
		read_selected_version
		check_if_fallout_4_is_installed
		ask_user_if_he_wants_to_update
	else
		echo "Continue from last known step."
		LAST_STEP=$(cat "$PROGRESS_FILE")
		read_selected_version
		check_if_fallout_4_is_installed
	fi

else
	LAST_STEP=0
	select_gog_or_steam_to_update_or_install
	read_selected_version
	check_if_fallout_4_is_installed
	ask_user_if_he_wants_to_update
fi

# Step 1: Check if Heroic Launcher is already installed
if [ "$LAST_STEP" -lt 1 ]; then
	check_if_heroic_is_installed_else_install
	update_progress 1
fi

# Step 2: Setting up downgrade-list
if [ "$LAST_STEP" -lt 2 ]; then
	echo "Setting up downgrade-list..."
	cat <<EOL >"$DOWNGRADE_LIST_PATH"
download_depot 377160 377162 5847529232406005096
download_depot 377160 435870 1691678129192680960
download_depot 377160 435871 5106118861901111234
download_depot 377160 435880 1255562923187931216
download_depot 377160 435882 8482181819175811242
download_depot 377160 480630 5527412439359349504
download_depot 377160 480631 6588493486198824788
download_depot 377160 393885 5000262035721758737
download_depot 377160 393895 7677765994120765493
download_depot 377160 435881 1207717296920736193
download_depot 377160 377164 2178106366609958945
download_depot 377160 490650 4873048792354485093
download_depot 377160 377161 7497069378349273908
download_depot 377160 377163 5819088023757897745
quit
EOL
	update_progress 2
fi

# Step 3: Setting up SteamCMD
if [ "$LAST_STEP" -lt 3 ]; then

	depot_download_location_choice

	echo "Setting up SteamCMD..."
	mkdir -p "$STEAMCMD_DIR"
	cd "$STEAMCMD_DIR" || {
		echo "Failed to change directory to $STEAMCMD_DIR"
		exit 1
	}
	curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
	update_progress 3
fi

# Step 4: Prompt user for Steam login credentials
if [ "$LAST_STEP" -lt 4 ]; then

	depot_download_location_choice

	echo "Please enter your Steam login credentials."
	echo "Note: Your login details are secure and will NOT be stored."

	# Loop until a non-empty username is entered
	while true; do
		username=$(zenity --entry --title="Steam Username" --width="450" --text="Enter name of your Steam user:")

		if [ -n "$username" ]; then
			break
		else
			zenity --error --title="Input Error" --text="Username cannot be empty. Please enter your Steam username." --width="450"
		fi
	done

	# Loop until a non-empty password is entered
	while true; do
		password=$(zenity --password --title="Steam Password" --width="450" --text="Enter your Steam user password to install required dependencies" 2>/dev/null)

		if [ -n "$password" ]; then
			break
		else
			zenity --error --title="Input Error" --text="Password cannot be empty. Please enter your Steam user password." --width="450"
		fi
	done

	# Run SteamCMD with the provided credentials and script
	echo "Running SteamCMD with provided credentials..."
	chmod +x "$STEAMCMD_DIR/steamcmd.sh"
	"$STEAMCMD_DIR/steamcmd.sh" +login "$username" "$password" +runscript "$DOWNGRADE_LIST_PATH"

	expected_files=(
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480631/Data/DLCworkshop03 - Main.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480631/Data/DLCworkshop03.cdx"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480631/Data/DLCworkshop03 - Geometry.csg"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480631/Data/DLCworkshop03 - Textures.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480630/Data/DLCworkshop02.esm"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480630/Data/DLCworkshop02 - Textures.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_480630/Data/DLCworkshop02 - Main.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Geometry.csg"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Textures.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast - Main.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_435881/Data/DLCCoast.cdx"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_490650/Data/DLCNukaWorld - Main.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_490650/Data/DLCNukaWorld - Geometry.csg"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_490650/Data/DLCNukaWorld - Textures.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_490650/Data/DLCNukaWorld.cdx"
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
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_393895/Data/DLCNukaWorld.esm"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_393895/Data/DLCNukaWorld - Voices_en.ba2"
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
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_393885/Data/DLCworkshop03 - Voices_en.ba2"
		"$STEAMCMD_DIR/linux32/steamapps/content/app_377160/depot_393885/Data/DLCworkshop03.esm"
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
		text="<b>Please install Fallout London from Heroic Launcher</b>\n\n1. Go to 'Log in' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n4. Once Fallout London is installed - Close Heroic Launcher to continue.\n\nPress 'OK' to start Heroic Launcher and close this message."
		zenity --info \
			--title="Overkill" \
			--width="450" \
			--text="$text" 2>/dev/null
		echo ""
		printf "Please install Fallout London from Heroic Launcher\n\n1. Go to 'Log in' in the left Heroic Launcher pane.\n2. Login to GoG\n3. Go to your library and install Fallout London.\n4. Once Fallout London is installed - Close Heroic Launcher to continue.\n"
		echo ""
		flatpak run com.heroicgameslauncher.hgl >/dev/null 2>&1
	fi
	update_progress 6
fi

# Step 7: Move main game files
if [ "$LAST_STEP" -lt 7 ]; then
	echo "Step 7: Manual Installation of Fallout London"
	check_if_proton_experimental_is_installed
	find_f4london_install_path
	if [ -d "$FALLOUT_LONDON_DIR" ]; then

		zenity --info --title="Manual Installation" --width="450" --text="GoG installer for Fallout London will now launch.\n\n1. Click 'Install' or 'Update' if you have both options\n2. Select Drive H:\n3. Click Install Here\n4. Close the installer after it's done to continue the setup process.\n\nMake sure to disconnect all external drives other than Internal SSD and microSD card before you proceed.\n\nClick 'OK' in this window to start the process." 2>/dev/null

		printf "\n\nGoG installer for Fallout London will now launch.\n\n1. Click 'Install' or 'Update' if you have both options\n2. Select Drive H:\n3. Click Install Here\n4. Close the installer after it's done to continue the setup process.\n\nMake sure to disconnect all external drives other than Internal SSD and microSD card before you proceed.\n\n"

		# Export the variables
		export STEAM_COMPAT_DATA_PATH="$COMPAT_DATA_PATH"
		export WINEPREFIX
		export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/deck/.steam"

		echo "COMPAT_DATA_PATH is $COMPAT_DATA_PATH"
		echo "WINEPREFIX is $WINEPREFIX"

		# Create the dosdevices directory if it doesn't exist
		mkdir -p "$WINEPREFIX/dosdevices"

		# Remove existing symlink if it exists
		if [ -L "$WINEPREFIX/dosdevices/h:" ]; then
			rm "$WINEPREFIX/dosdevices/h:"
		fi

		# Create the new symlink
		ln -s "$FALLOUT_4_DIR" "$WINEPREFIX/dosdevices/h:"

		# Verify the symlink
		if [ -L "$WINEPREFIX/dosdevices/h:" ]; then
			echo "Drive H: successfully created pointing to $FALLOUT_4_DIR"
		else
			echo "Failed to create Drive H:"
			exit
		fi

		# Run the game using Proton with the specified Wine prefix and compatibility data path
		killall wineserver

		echo "$PROTON_DIR/proton"
		echo "$GAME_EXE_PATH"
		echo "$COMPAT_DATA_PATH"
		echo "$WINEPREFIX"
		echo "$STEAM_COMPAT_CLIENT_INSTALL_PATH"

		"$PROTON_DIR/proton" run "$GAME_EXE_PATH"

		update_progress 7
	else
		echo "Fallout London is not recognized to be installed in Heroic Launcher.\nStart the Installation process from the beginning or install Heroic Launcher and Fallout London manually."
		exit
	fi
fi

# Step 8: Check if Fallout 4 is properly downgraded
if [ "$LAST_STEP" -lt 8 ]; then
	fallout4defaultlauncher_default_sha256sum="75065f52666b9a2f3a76d9e85a66c182394bfbaa8e85e407b1a936adec3654cc"
	fallout4defaultlauncher_actual_sha256sum=$(sha256sum "$FALLOUT_4_DIR/Fallout4Launcher.exe" | awk '{print $1}')

	if [ "$fallout4defaultlauncher_default_sha256sum" == "$fallout4defaultlauncher_actual_sha256sum" ]; then
		echo "You are using standard Fallout 4 launcher exe. Your Game is not downgraded."
		echo "Please start the script again from the beginning."
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
			update_progress 6
			echo "ERROR: Fallout London is not installed or installation was not successful."
			echo "ERROR: Please run the script again and select 'Continue from last known step'"
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
	SOURCE_DIR="$FALLOUT_LONDON_DIR/__AppData"

	# Ensure the TARGET_DIR exists
	if [ ! -d "$TARGET_DIR" ]; then
		echo "AppData Directory does not exist. Creating directory."
		mkdir -p "$TARGET_DIR"
		echo "AppData Directory created."
	else
		echo "AppData Directory exists."
	fi

	# Create a backup directory if it doesn't exist
	if [ ! -d "$BACKUP_DIR" ]; then
		echo "Creating backup directory at $BACKUP_DIR"
		mkdir -p "$BACKUP_DIR"
	else
		echo "Backup directory exists."
	fi

	# Loop through all files in the source directory and process them
	echo "Processing files in $SOURCE_DIR..."
	for source_file in "$SOURCE_DIR"/*; do
		# Check if it's a regular file (not a directory)
		if [[ -f "$source_file" ]]; then
			# Extract the file name from the full path
			file_name=$(basename "$source_file")

			# Define the target file path
			target_file="$TARGET_DIR/$file_name"

			echo "Processing file: $file_name"

			# Compare and replace if necessary, with conditional backup
			compare_and_replace_appdata "$target_file" "$source_file"
		else
			echo "Skipping non-regular file: $source_file"
		fi
	done

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

		xdg-open "https://www.nexusmods.com/fallout4/mods/47359?tab=files" >/dev/null 2>&1 &

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

	if [ "$F4_VERSION" = "STEAM" ]; then
		# Your commands go here
		echo "F4_VERSION is STEAM, executing command..."
		# Example command

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

				response=$(zenity --question --width="450" --text="(Optional Step) Automatic updates for Steam version of Fallout 4 are enabled. \nDo you want to disable Steam automatic updates for Fallout 4? \n\n- THIS ACTION IS PERMANENT AND WILL REQUIRE YOU TO RUN A COMMAND IN CONSOLE TO REVERT IT BACK!\n- THIS COMMAND REQUIRES SUPER USER (SUDO) PRIVILEGES.\n- YOU WILL NEED TO PROVIDE SUDO PASSWORD TO PERFORM THIS STEP." --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

				if [ $? -eq 0 ]; then

					response=$(zenity --question --width="450" --text="If you don't know what you're doing it's recommended not to perform this action. \n\nAre you sure you want to continue?" --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

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

							response=$(zenity --question --width="450" --text="It looks like you don't have a SUDO password set for $USER user. Do you want to set it right now?\n\n<b>You will need to type it into the Konsole window</b>" --ok-label="Yes" --cancel-label="No" --title="Disable Steam Updates")

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
						zenity --info --width="450" --text="You will need to switch your focus on the Konsole window!\n\nPress 'OK' to proceed" --title="Disable Steam Updates"
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

	fi
	update_progress 18
fi

if [ "$LAST_STEP" -lt 19 ]; then
	read_selected_version
	check_if_fallout_4_is_installed

	FAUDIO_DIR="$HOME/Downloads/faudio"
	FAudio_Target="$WINEPREFIX/drive_c/windows/system32"
	# Step 1: Check if the F4_VERSION variable is set to "GOG"
	if [ "$F4_VERSION" = "GOG" ]; then
		# Define the path to the Proton prefix

		# Define the path to the FAudio.dll file
		FAudio_FILE="$FAudio_Target/FAudio.dll"

		# Check if the FAudio.dll file exists
		if [ -f "$FAudio_FILE" ]; then
			printf "FAudio.dll is installed.\n"
			echo "$FAudio_Target"
		else
			echo "FAudio.dll is not installed. Proceeding with installation."

			# Add local bin directory to PATH
			export WINEPREFIX
			echo "$WINEPREFIX"
			# Step 3: Install FAudio using winetricks
			echo "Installing FAudio"

			#!/bin/bash# Variables
			# WINEPREFIX_PATH="$WINEPREFIX"
			# Ensure the Wine prefix path is provided

			#sorta working
			mkdir -p $FAUDIO_DIR
			wget -P "$FAUDIO_DIR" -O "$FAUDIO_DIR/faudio-20.07.tar.xz" https://github.com/Kron4ek/FAudio-Builds/releases/download/20.07/faudio-20.07.tar.xz
			tar xvf "$FAUDIO_DIR/faudio-20.07.tar.xz" -C "$HOME/Downloads/faudio"

			for dll in "$FAUDIO_DIR/faudio-20.07/x64/"*.dll; do
				cp -f "$dll" "$FAudio_Target/"
				echo "$dll copied correctly"
			done

			# chmod +x "$HOME/Downloads/faudio/faudio-20.07"
			# cd "$HOME/Downloads/faudio/faudio-20.07"
			# WINE="$HOME/.local/share/flatpak/app/org.winehq.Wine/current/active/export/bin/org.winehq.Wine" WINEPREFIX="$WINEPREFIX" ./wine_setup_faudio.sh
			# cd ..
			# cd ..
			# cd ..
			# Verify if FAudio.dll was installed
			if [ -f "$FAudio_FILE" ]; then
				echo "FAudio.dll installed successfully."
			else
				echo "Failed to install FAudio.dll. Please refer to step 11 of the instructions on https://www.reddit.com/r/fallout4london/comments/1ebrc74/steam_deck_instructions/ for GoG Fallout London installation."
				exit 1
			fi
		fi
	fi

	update_progress 19
fi

# Cleanup progress file
rm -f "$PROGRESS_FILE"
rm -f "$F4_VERSION_SELECTION_FILE"
rm -rf "$FAUDIO_DIR"

if [ "$F4_VERSION" == "STEAM" ]; then
	text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole.\nFallout London can be launched from Fallout 4 Steam page."
	zenity --info \
		--title="Overkill" \
		--width="450" \
		--text="$text" 2>/dev/null
elif [ "$F4_VERSION" == "GOG" ]; then
	text="<b>All steps completed successfully!</b>\n\nYou can now close the terminal / Konsole.\nFallout London can be launched from Fallout 4 Heroic Launcher page."
	zenity --info \
		--title="Overkill" \
		--width="450" \
		--text="$text" 2>/dev/null
fi

exit
