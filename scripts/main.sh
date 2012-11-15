#function - findAbsoluteFromRelativePath () - A method used to strip out the ../ from the path to create an absolute one
#TODO could be made to be recursive instead of using the loop
function findAbsoluteFromRelativePath () {
	
	PART_PATH_LEN=${#PART_PATH}
	PART_PATH=${PART_PATH:3:PART_PATH_LEN}

	CURRENT=${CURRENT%/*}	
}

#function - setWorkingDirectory () - sets the Working directory using the way the script is called and pwd
function setWorkingDirectory () {
#How the bash script is called, aka ./main.sh or ./scrips/main.sh, etc...
	WD=$0

	#Check if we are running from outside the scripts folder
	if [[ "$WD" =~ "scripts" ]]; then
		CURRENT=`pwd`

		#If it's called from one level above  (./scripts/main.sh)
		if [[ "${WD:0:9}" == "./scripts" ]]; then
			WORKSPACE_WD=${CURRENT}
			
		#If it's called from the absolute path from root (/opt/project/scripts/main.sh)
		elif [[ "${WD:0:1}" == "/" ]]; then
			WORKSPACE_WD=${WD%/scripts*}
		
		#If it's called from a different relative branch path  (../project/scripts/main.sh)
		elif [[ "${WD:0:3}" == "../" ]]; then
			PART_PATH=${WD%/scripts*}
			while [[ "${PART_PATH:0:3}" == "../" ]]; do
				findAbsoluteFromRelativePath
			done
			WORKSPACE_WD=${CURRENT}/${PART_PATH}

		#If it's called from a direct relative path from our project  (./project/scripts/main.sh)
		else	
			PART_PATH=${WD%/scripts*}
			PART_PATH_LEN=${#PART_PATH}

			#If it's called without the ./ in the start
			if [[ "${PART_PATH:0:1}" != "." ]]; then
				WORKSPACE_WD=${CURRENT}/${PART_PATH}
			else
				WORKSPACE_WD=${CURRENT}${PART_PATH:1:PART_PATH_LEN}
			fi
		fi

	else
		#If we are running from within the scripts folder  (./main.sh)
		#Get the current directory
		WD=`pwd`

		#Ensure the pwd contains scripts in it (no reason why it wouldn't)
		if [[ "$WD" =~ "scripts" ]]; then
			#Cut off the scripts directory from the pwd
			WORKSPACE_WD=${WD%/*}
		else
			outputLog "The project structure has been modified or running from an unidentifable location." "4"
			exit
		fi
	fi
}

function loadScripts () {
	
	#Include necessary shell scripts
	. ${WORKSPACE_WD}/scripts/debug.sh

	. ${WORKSPACE_WD}/scripts/utils.sh
	. ${WORKSPACE_WD}/scripts/variables.sh
	. ${WORKSPACE_WD}/scripts/ecUtils.sh
	. ${WORKSPACE_WD}/scripts/postgresql.sh
	. ${WORKSPACE_WD}/scripts/jon.sh
	. ${WORKSPACE_WD}/scripts/setupServerBundles.sh
	. ${WORKSPACE_WD}/scripts/provision.sh
	. ${WORKSPACE_WD}/scripts/unprovision.sh
	. ${WORKSPACE_WD}/scripts/jd-demo.sh
	. ${WORKSPACE_WD}/scripts/menuFunctions.sh
	. ${WORKSPACE_WD}/scripts/menuManageServers.sh
	. ${WORKSPACE_WD}/scripts/manageBundles.sh
	
	. ${WORKSPACE_WD}/cli/cli-commands.sh

}

function loadVariables () {
	
	if [[ -f "${WORKSPACE_WD}/data/script_variables.sh" ]]; then
		. ${WORKSPACE_WD}/data/script_variables.sh
	fi
	
	if [[ -f "${WORKSPACE_WD}/data/demo-config.properties" ]]; then
		. ${WORKSPACE_WD}/data/demo-config.properties
	fi 
	
	. ${WORKSPACE_WD}/scripts/variables.sh
	getAgentFolder
	getRHQCLIDetails
	
	if [[ "${JON_MAJOR_VERSION}" != "" && "${JON_MINOR_VERSION}" != "" && "${JON_REVISION_VERSION}" != "" ]]; then
		JON_PRODUCT="jon-server-${JON_MAJOR_VERSION}.${JON_MINOR_VERSION}.${JON_REVISION_VERSION}"
	fi
}

#function - repeatChar(width, character) - Output a character for as many times as defined by the width
function repeatChar() {
	W=$1
	CHAR=$2 
	
	CHAR_OUTPUT=""
	for (( A = 0; A < $W; A++ ))
	do
		CHAR_OUTPUT="${CHAR_OUTPUT}${CHAR}"
	done
	echo -n "$CHAR_OUTPUT"
}

#function - breakTextLine (width, text) - Takes text, and breaks it according to the width available in the terminal
function breakTextLine () {
	W=$1
	TEXT=$2

	O=""
	NUM_SPACES=0
	TEXT_LEN=${#TEXT}
	CHAR_OUTPUT=""
	INDENT_LINE=false

	#Check if we trim any whitespace from the start, is the variable still the same
	TEXT_NO_SPACES=`echo "$TEXT" | sed 's/^ *//g'`
	if [[ "$TEXT_NO_SPACES" != "$TEXT" ]]; then
		#If it does have whitespace, calculate the length of the whitespace
		TEXT_NS_LEN=${#TEXT_NO_SPACES}
		NUM_SPACES=$(( TEXT_LEN - TEXT_NS_LEN ))
		#And create a string of whitespace with the right length
		CHAR_OUTPUT=`repeatChar "$(( NUM_SPACES ))" " "`
		#And remove the original whitespace to add it to all new lines
		TEXT="$TEXT_NO_SPACES"
	fi

	#Decrease the available width according to the space taken up by the text and it's spaces
	if [ $NUM_SPACES -eq "0" ]; then
		BEFORE_END_LINE=$(( W - 1 ))
	else
		BEFORE_END_LINE=$(( W - 1 - $NUM_SPACES ))
	fi
	
	#If the text starts with *-- *, for example 1-- or a-- 
	if [[ "$TEXT_NO_SPACES" =~ "-- " ]]; then
		INDENT_LINE=true
		#Then add an indent of 4 characters, to align the front of the line with the start of the text on the line above
		INDENT="    "
	fi

	COUNT=0
	#If the text is longer then the width
	while [[ "$TEXT_LEN" -gt "$BEFORE_END_LINE" ]]; do

		#Only indent after the first line with the 1--
		if [[ "$INDENT_LINE" == "true" && "$COUNT" -eq "1" ]]; then
			CHAR_OUTPUT="${CHAR_OUTPUT}${INDENT}"
			BEFORE_END_LINE=$(( BEFORE_END_LINE - 4 ))
		fi
		
		#Check what the last character is
		LAST_CHAR=${TEXT:BEFORE_END_LINE - 1:1}
		BEFORE_LAST_CHAR=${TEXT:BEFORE_END_LINE - 2:1}
		NEXT_CHAR=${TEXT:BEFORE_END_LINE:1}
		#echo "b[$BEFORE_LAST_CHAR] l[$LAST_CHAR] n[$NEXT_CHAR]"
		#If it's a white space, 
		L_IS_LETTER=`echo "$LAST_CHAR" | grep '^[a-zA-Z]'`
		B_IS_LETTER=`echo "$BEFORE_LAST_CHAR" | grep '^[a-zA-Z]'`
		N_IS_LETTER=`echo "$NEXT_CHAR" | grep '^[a-zA-Z]'`
		if [[ "$L_IS_LETTER" == "" ]]; then
			O="${O}${CHAR_OUTPUT}${TEXT:0:BEFORE_END_LINE - 1}\n"
			TEXT="${TEXT:BEFORE_END_LINE - 1:TEXT_LEN}"
			#echo "chose L"
		elif [[ "$B_IS_LETTER" == "" ]]; then
			O="${O}${CHAR_OUTPUT}${TEXT:0:BEFORE_END_LINE - 1}\n"
			TEXT="${TEXT:BEFORE_END_LINE - 1:TEXT_LEN}"
			#echo "chose B"
		elif [[ "$N_IS_LETTER" == "" ]]; then
			O="${O}${CHAR_OUTPUT}${TEXT:0:BEFORE_END_LINE + 1}\n"
			TEXT="${TEXT:BEFORE_END_LINE + 1:TEXT_LEN}"
			#echo "chose N"			
		else
			O="${O}${CHAR_OUTPUT}${TEXT:0:BEFORE_END_LINE}-\n"
			TEXT="${TEXT:BEFORE_END_LINE:TEXT_LEN}"
			#echo "chose to break"
		fi
		NUM_OF_LINES=$(( NUM_OF_LINES + 1 ))
		COUNT=$(( COUNT + 1 ))
		TEXT_LEN=${#TEXT}
	done
	
	#If we only break just once and we are indenting, then we set the indent for the second line 
	if [[ "$INDENT_LINE" == "true" && "$COUNT" -eq "1" ]]; then
			CHAR_OUTPUT="${CHAR_OUTPUT}${INDENT}"
	fi
	
	O="${O}${CHAR_OUTPUT}${TEXT}\n"
	TEXT_OUTPUT="${TEXT_OUTPUT}${O}"
	NUM_OF_LINES=$(( NUM_OF_LINES + 1 ))
}

#function - splashScreen () - shows the initial splash screen on first start up with instructions.
function splashScreen () {
	clear
	WIDTH=`tput cols`
	HEIGHT=`tput lines`

	OUTPUT=""
	TEXT_OUTPUT=""
	NUM_OF_LINES=0
			
	#Do breakTextLine first to count how many lines come out of it
	TEXT_OUTPUT=""
	breakTextLine $WIDTH "  STEPS TO SET UP:"
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  0-- Read the readme, it provides elaborate details of the information below"
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  1-- Update the configurable variables in the \"data\demo-config.properties\" file:"
	breakTextLine $WIDTH "      a-- INSTALL_LOCATION: If you have a preference, you can modify the default base install location. This location will have the JD_FOLDER variable (configurable via the script) appended to it."
	breakTextLine $WIDTH "      b-- JAVA_HOME: Update to the appropriate value on your system."
	breakTextLine $WIDTH "      c-- MVN_HOME: Update to the appropriate value on your system."
	breakTextLine $WIDTH "      d-- ANT_HOME: Update to the appropriate value on your system."
	breakTextLine $WIDTH "      e-- LOCAL_USER: Set to a local user account that you would like to own any new files or folders, if left empty or invalid, root will be used by default."
	breakTextLine $WIDTH "      f-- LATEST_JON_VERSION: The latest version of JON for the creation of the default data FS.  Currently set to jon-server-3.1.0."
	breakTextLine $WIDTH "      g-- DEMO_LOG_LEVEL: The log level to be used across the demo script project"	
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  2-- Add the JON server zip and plugin packages into the appropriate location"
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  3-- Add the JBoss server zip (only 5.1.x currently supported) for bundle creation into the appropriate location"
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  4-- (Optional) Install Ant and Maven to your system - allowing access by root - to enable bundle creation and deployment."
	TEXT_OUTPUT="${TEXT_OUTPUT}\n"
	breakTextLine $WIDTH "  *Note: On a first install, if PostgreSQL is not installed, an internet connection will be required"
	
	#Then figure out the lines to output
	#echo "height $HEIGHT bla"
	#echo "num lines: $NUM_OF_LINES"
	#height - (total lines broken up) - 2 (lines for the **** output) - 6 (for the extra spaces between text) - 2 (for last \n and pause line)
	REST_OF_LINES=$(( HEIGHT - NUM_OF_LINES - 10))
	#echo "rest of lines $REST_OF_LINES"
	HALF_OF_LINES=$(( REST_OF_LINES / 2 ))
	#echo "half of lines $HALF_OF_LINES"

	CHAR_OUTPUT=`repeatChar "$(( WIDTH - 2))" " "`
	for (( A = 1; A < HALF_OF_LINES; A++ ))
	do
		OUTPUT="${OUTPUT}.${CHAR_OUTPUT}.\n"
	done
	
	CHAR_OUTPUT=`repeatChar "$(( WIDTH - 1))" "*"`
	OUTPUT="${OUTPUT}\n${CHAR_OUTPUT}\n${TEXT_OUTPUT}${CHAR_OUTPUT}\n"
	
	CHAR_OUTPUT=`repeatChar "$(( WIDTH - 2))" " "`

		for (( A = 1; A < HALF_OF_LINES; A++ ))
		do
			OUTPUT="${OUTPUT}.${CHAR_OUTPUT}.\n"
	done
	
	echo -e "$OUTPUT"

	echo -n " "
	read -p "Press any key to continue..."
}

function mainMenu () {

	while true;
	do
		menuHeader "Main Menu"

		FOLDER=`getDemoInstallFolder`
		echo ***Config options***
		if [[ "$JON_DEMO_INSTALLED" != "y" ]]; then
			echo "CD. Change demo directory [Currently: $FOLDER]"
		else
			echo "Note: Change directory not available when a demo is installed."
		fi
		newLine
		
		echo ***JON Demo options***
		jonDemoMenu $INSTALL_LOCATION
		
		checkBundlesEnabled
		
		manageServersMenu
		
		echo -------------------------------------------------------
		newLine
		
		echo ***Other options***
		echo I. Install menu
		echo D. Delete menu

		if [ -f $POSTGRES_SERVICE_FILE ]; then
			echo UP. Uninstall Postgres Service
		else
			newLine			
			echo IP. Install Postgres Service
		fi
		newLine
		
		if [[ "$LOG_LEVEL" == "1" ]]; then
			echo ***Debug options***
			echo "R. Reload scripts"
			echo "T. Run test function"
			echo "L. List all functions"
			echo "F. Invoke function"
			newLine
			echo "C.  CLI commands"
		fi
		
		echo "CL. Change Log Level [Currently: $LOG_LEVEL]"
		
		menuFooter true
		option=`takeInputOption`
		newLine

		case $option in
			"i")
				installMenu
				;;

			"t")
				testFunction
				;;

			"cd")
				changeDemoDirectory
				;;

			"cb")
				SUB_PROJECT_CALL=true
				createBundles
				SUB_PROJECT_CALL=false
				;;

			"db")
				deleteBundles
				;;

			"d")
				deleteMenu
				;;

			"r")	
				initialise
				;;
				
			"cl")
				changeLogLevel
				;;

			"l") 
				displayFunctions
				newLine
				;;

			"f") 
				takeInput "Input function to run"
				read option

				$option
				;;

			"ip") 
				checkPostgresInstall	
				if [[ "$POSTGRES_INSTALLED" == "n" ]]; then 
					getPostgresRepo
					installPostgres
					deletePostgresTmpFiles
				fi
				;;

			"up")
				if [[ "$POSTGRES_INSTALLED" == "y" ]]; then 
					uninstallPostgres
				fi
				;;

			"dd" | "id" | "srd" | "sod" | "c" | "dj" | "uj" ) 
				jonDemoOptions $option $JD_INSTALL_LOCATION
				;;
				
			"sp" | "rp" | "sj" | "pj" | "pa" | "sa" | "ra" | "sajb" | "pajb"  ) 
				manageServersOptions $option
				;;
				
			*) 
				if [[ "$option" =~ "sjb" || "$option" =~ "pjb" ]]; then
					manageServersOptions $option
				else
					basicMenuOptions $option
				fi
				;;
		esac
		
		#Pause to show output of selected action
		newLine
		pause
	done

}

function installMenu () {
	
	while true;
	do
		menuHeader "Install Menu"

		echo I. Install Product
		
		menuFooter
		option=`takeInputOption`

		case $option in

			"i" | "I" ) 
				chooseProduct
				extractPackage "$PRODUCT_SELECTED" "$INSTALL_LOCATION" 
				pause
				;;
			
			*) 
				basicMenuOptions $option
				;;
		esac
	done

}

function deleteMenu () {
	
	while true;
	do
		menuHeader "Delete Menu"

		echo "J. Delete JON server and database"
		echo "P. Delete Postgres DB"
		echo "D. Delete JON Demo basic data"
		echo "A. Delete all JON Demo data"
		
		menuFooter
		option=`takeInputOption`

		case $option in
			"j" | "J" ) 
				deleteJONServer
				pause
				;;

			"p" )
				choosePostgresDB
				if [[ "$DB" != "" ]]; then
					deletePostgresDB $DB
				fi
				pause
				;;
				
			"a" )
				takeYesNoInput "Are you sure you want to delete all the associated data, bundles, and demo? (yes/no):"
				if [[ "$ANSWER" == "yes" ]]; then
					if [[ "$JON_DEMO_INSTALLED" == "y" ]]; then
						jdDeleteDemo $JD_INSTALL_LOCATION
					else
						outputLog "Only deleting the data, as the demo is not installed..."
					fi
					
					deleteFolder ${WORKSPACE_WD}/data
					initialise
				fi
				newLine
				pause
				;;
				
			"d" )
				takeYesNoInput "Are you sure you want to delete the bundle files and script specific data? (yes/no):"
				if [[ "$ANSWER" == "yes" ]]; then	
					if [[ "$JON_DEMO_INSTALLED" == "y" ]]; then
						jdDeleteDemo $JD_INSTALL_LOCATION
					else
						outputLog "Only deleting the data, as the demo is not installed..."
					fi
					
					#Delete the bundles
					deleteFolder "${WORKSPACE_WD}/data/bundles"
					
					#Delete any expanded JBoss ZIP directories
					JBOSS_DIR=`ls -d ${WORKSPACE_WD}/data/jboss/*/ 2>&1`
					
					if [[ "$JBOSS_DIR" =~ "cannot access" ]]; then
						outputLog "No JBoss was provided, so nothing to delete."
					else
						for d in `ls -d ${WORKSPACE_WD}/data/jboss/*/`
						do
							deleteFolder $d
						done
					fi
					
					#Delete the script_variables
					deleteFile ${WORKSPACE_WD}/data/$SCRIPT_VARIABLES
					outputLog "All script data files deleted, re-initialsing..." "2"
					initialise
				fi
				newLine
				pause
				;;
				
			*)
				basicMenuOptions $option
				;;	
		esac
	done

}

#function - changeDemoDirectory () - change the directory into which to install
function changeDemoDirectory () {
	
	if [[ "$JON_DEMO_INSTALLED" != "y" ]]; then
		DEMO_DIR=
		while [[ "$DEMO_DIR" == "" ]];
		do
			takeInput "Select one of the options below or enter a new directory name to use as the install location for the demo:\n\t(base is set to [$INSTALL_LOCATION] in demo-config.properties):\n\tB. Back to Main Menu"
			newLine 
			
			for f in `ls ${INSTALL_LOCATION}`
			do
				echo -e "\t\t $f"
			done
	
			echo -en "\n\t"
			read DEMO_DIR
	
			if [[ "$DEMO_DIR" == "" ]]; then
				outputLog "The directory name cannot be empty, please input it again" "4"
			elif [[ "$DEMO_DIR" == "b" || "$DEMO_DIR" == "B" ]]; then
				mainMenu
			fi
		done
	
		FOLDER=`getDemoInstallFolder`
		
		resetVariableInFile "JD_FOLDER" "$DEMO_DIR"
		loadScripts
		
		outputLog "\nUpdated $SCRIPT_VARIABLES to use JD_FOLDER=$DEMO_DIR"
		newLine
	else
		outputLog "Cannot modify the demo install directory as you have a demo installed already." "3"	
	fi
}

#function - changeLogLevel () - change the log level to display
function changeLogLevel () {
	LOG_CHANGE=
	while [[ "$LOG_CHANGE" == "" ]];
	do
		echo "Current Log level is: $LOG_LEVEL"
		newLine
		echo "Possible options:"
		newLine
		echo "1 == DEBUG"
		echo "2 == INFO"
		echo "3 == WARNING"
		echo "4 == ERROR"

		newLine
		echo "Please enter the log level you would like to set:"
		echo "B. Back to Main Menu"
		echo -en "\t"
		read LOG_CHANGE

		if [[ "$LOG_CHANGE" == "" ]]; then
			outputLog "The log level cannot be empty, please input it again." "4"
		elif [[ "$LOG_CHANGE" == "b" || "$LOG_CHANGE" == "B" ]]; then
			mainMenu
		elif [[ "$LOG_CHANGE" != +([1-4]) ]]; then
			outputLog "The chosen log level [$LOG_CHANGE] is not an appropriate option, select a number between 1 and 4 relating to the appropriate log level." "4"
			LOG_CHANGE=""
		else
			replaceStringInFile "DEMO_LOG_LEVEL=$LOG_LEVEL" "DEMO_LOG_LEVEL=$LOG_CHANGE" "${WORKSPACE_WD}/data/demo-config.properties"
			loadVariables
			loadScripts
			outputLog "Updated LOG_LEVEL to use $LOG_CHANGE"
			newLine
		fi
	done
}

#function - getDemoInstallFolder() - gets the folder used to install the demo into, from SCRIPT_VARIABLES, outputs/returns the name
function getDemoInstallFolder() {

	GET_FOLDER=`grep "JD_FOLDER=" ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}`
	FOLDER=${GET_FOLDER#*JD_FOLDER=}
	echo $FOLDER
}

#function - checkScriptPrereqs () - Checks that all script pre-requisites are met
function checkScriptPrereqs () {
	
	#Run checks on the system for the pre-reqs
	JON_PROVIDED=`find ${WORKSPACE_WD}/data/jon/ -name "jon-server-*.zip"`
	checkForPostgresOnSystem
	
	ERROR=false
	#If any of the pre-reqs are not met - or it's the first start up - then process them
	if [[ ! -f ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES} || "$JON_PROVIDED" == "" || "$POSTGRES_INSTALLED" != "y" || "$POSTGRES_SERVICE_FILE" == "" || "$JAVA_HOME" == "" ]]; then
		splashScreen
		newLine
		
		#If JON zip is not provided, error with message
		if [[ "$JON_PROVIDED" == "" ]]; then
			outputLog "No JON zip was provided in [${WORKSPACE_WD}/data/jon]" "4"
			ERROR="true"
		fi
		
		#If postgres is not installed and not found on the system
		if [[ "$POSTGRES_INSTALLED" != "y" && "$POSTGRES_SERVICE_FILE" == "" ]]; then
			
			#Can we get index.html from google - i.e we have internet
			wget www.google.com -o output.txt

			#If we don't have internet connectivity, error with message
			if [[ ! -f index.html ]]; then 
				outputLog "PostgreSQL is not installed, and no internet connectivity found" "4"
				ERROR=true
			else
				outputLog "PostgreSQL is not installed or on the system, but internet connectivity available."
			fi
			
			#Clean wget files
			deleteFile index.html
			deleteFile output.txt
		
		#If postgres is not installed by the script but found on the system
		elif [[ "$POSTGRES_INSTALLED" != "y" && "$POSTGRES_SERVICE_FILE" != "" ]]; then
			outputLog "PostgreSQL is not installed, but found on the system. Internet is not required"
		fi 
		
		if [[ "$JAVA_HOME" == "" || ! -d $JAVA_HOME ]]; then
			outputLog "JAVA_HOME has not been set or is set to a non-existent folder [$JAVA_HOME] in [${WORKSPACE_WD}/data/demo-config.properties], please set it first" "4"
			ERROR=true
		fi
		
		if [[ "$ANT_HOME" == "" || ! -d $ANT_HOME ]]; then
			outputLog "ANT_HOME has not been set or is set to a non-existent folder [$ANT_HOME] in [${WORKSPACE_WD}/data/demo-config.properties], please set it appropriately.  In the meantime, bundles will not be available" "3"
		fi	
		
		if [[ "$MVN_HOME" == "" || ! -d $MVN_HOME ]]; then
			outputLog "MVN_HOME has not been set or is set to a non-existent folder [$MVN_HOME] in [${WORKSPACE_WD}/data/demo-config.properties], please set it first.  In the meantime, bundles will not be available" "3"
		fi
		
		if [[ "$INSTALL_LOCATION" == "" || ! -d $INSTALL_LOCATION ]]; then
			outputLog "INSTALL_LOCATION has not been set or is set to a non-existent folder [$INSTALL_LOCATION] in [${WORKSPACE_WD}/data/demo-config.properties], please set it first" "4"
			ERROR=true
		fi
		
		if [[ "$LOCAL_USER" == "" ]]; then
			outputLog "Root will be used as the default owner of any new files and folders" "1"
		else
			LOCAL_USER_EXISTS=`id $LOCAL_USER`		
			if [[ "$LOCAL_USER_EXISTS" =~ "No such user" ]]; then
				outputLog "LOCAL_USER has not been set or is set to a non-existent user [$LOCAL_USER] in [${WORKSPACE_WD}/data/demo-config.properties], root will be used as default" "3"
				LOCAL_USER="root"
			fi
		fi
		
		#If any pre-req errored, then exit
		if [[ "$ERROR" == "true" ]]; then
			newLine
			outputLog "Please fix the above error messages and run the script again." "4"
			exit
		fi
	fi

}

#function - updateLocalUser () - updates the owner of the data and jon demo install location to the local user
function updateLocalUser () {
	if [[ "$LOCAL_USER" != "" ]]; then
		if [[ -d ${WORKSPACE_WD}/data ]]; then
			DATA_OWNER=`stat -c %U ${WORKSPACE_WD}/data`
			
			if [[ "$DATA_OWNER" != "$LOCAL_USER" ]]; then
				chown $LOCAL_USER:$LOCAL_USER -R ${WORKSPACE_WD}/data
			fi
		fi
		
		if [[ -d ${JD_INSTALL_LOCATION} ]]; then
			DATA_OWNER=`stat -c %U ${JD_INSTALL_LOCATION}`
			
			if [[ "$DATA_OWNER" != "$LOCAL_USER" ]]; then
				chown $LOCAL_USER:$LOCAL_USER -R ${JD_INSTALL_LOCATION}
			fi
		fi
	fi
}

function initialise () {
	loadScripts
	loadVariables
	createDemoDataDir
	createScriptVariablesFile
	createDemoConfFile
	createDemoFsStructure
	checkScriptPrereqs
	checkScriptUser
	checkOrCreateJBossUser	
	updateLocalUser
	loadScripts
	loadVariables
}

setWorkingDirectory
initialise
mainMenu