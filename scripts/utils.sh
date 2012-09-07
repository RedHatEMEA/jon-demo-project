#Answer used for input functions
ANSWER=""

#function - quit () - to quit
function quit () {
	clear;
	exit;
}

#function - displayFunctions () - display the list of all functions 
function displayFunctions () {
	for f in `find ${WORKSPACE_WD} -name "*.sh"`
	do
		outputLog "From $f" "1" "y" "n"
		grep "#function" $f  | grep -v 'find'
		newLine
		newLine
	done
}

#function - newLine (whenToOutput) - to output an empty line
function newLine () {
	WHEN=$1
	if [[ "$LOG_LEVEL" == "$WHEN" || "$WHEN" == "" ]]; then
		echo -e "\t"
	fi
}

#function - takeInput(message) - to output a message before taking input
function takeInput () {
	MESSAGE=$1
	SHOW_INPUT=$2
	
	TEXT=""
	
	if [[ "$SHOW_INPUT" != "0" ]]; then
		TEXT="INPUT: "
	fi
	
	echo -en "\t${TEXT}$MESSAGE\n\t"
}

#function - takeYesNoInput(message, [default], [allowBack]) - to output a message before taking input
function takeYesNoInput () {
	MESSAGE=$1
	DEFAULT=$2
	ALLOW_BACK=$3
	ANSWER=""
	
	while [[ "$ANSWER" == "" ]];
	do
		takeInput "$MESSAGE"
		read ANSWER
		ANSWER=`lowercase $ANSWER`
		newLine
		
		if [[ "$ANSWER" == "" && "$DEFAULT" != "" ]]; then
			outputLog "Taking the default $DEFAULT as the answer..." "1"
			ANSWER=$DEFAULT
			break
		elif [[ "$ANSWER" == "" && "$DEFAULT" == "" ]]; then
			outputLog "No default provided, so please answer yes or no." "4"
			ANSWER=""
			newLine
		elif [[ "$ANSWER" == "b" && "$ALLOW_BACK" == "1" ]]; then
			mainMenu
		elif [[ "$ANSWER" != "yes" && "$ANSWER" != "no" && "$ANSWER" != "y" && "$ANSWER" != "n" ]]; then
			outputLog "Invalid input, must be yes or no." "4"
			ANSWER=""
			newLine
		else
			if [[ "$ANSWER" == "y" ]]; then
				ANSWER="yes"
			elif [[ "$ANSWER" == "n" ]]; then
				ANSWER="no"
			fi
			break
		fi
		
	done
	outputLog "The answer selected is [$ANSWER]" "1"
}

#function - pause () - to pause command line
function pause () {
	echo -en "\t"
	read -p "Press any key to continue..."
}

#function - checkScriptUser () - used to check if user running script is root/sudo-ed
function checkScriptUser () {
	if [[ $EUID -ne 0 ]]; then
	   	outputLog "This script must be run as root" "4" "y" "n"
	   	exit 1
	fi
	
	#TODO, figure if this is possible
	#when is this necessary, only during postgres install? anything else?
	#Where is root used?
	# -if postgres isn't there, yum
	# - start/stop/status on postgres service
	# access to etc/init.d 
	#chown user:user for /data, and then run as local user always
}

#function - extractPackage (package, installLocation) - extract the selected package
function extractPackage () {
	PACKAGE=$1
	LOCATION=$2
	
	outputLog "Extracting package - $PACKAGE - to $LOCATION " "2"

	mkdir -p $LOCATION
	unzip -qo $PACKAGE -d $LOCATION

	newLine
	
}

#function - chooseProduct (productNamePattern) - allows the choosing of a product to extract - current name options jon/eap
function chooseProduct () {
	
	NAME_PATTERN=$1

	PRODUCT_ARRAY=(`find ${WORKSPACE_WD}/data -name "*${NAME_PATTERN}*.zip" | grep -v plugins`)
	PRODUCT_ARRAY_LENGTH=$((${#PRODUCT_ARRAY[@]}))
	takeInput "Select the version of $NAME_PATTERN you would like to install/extract:\n\tB. Back to Main Menu."
	#takeInput "\tExisting packages with '$NAME_PATTERN': " "0"
	
	newLine
	echo -en "\t"
	COUNT=0
	for p in ${PRODUCT_ARRAY[@]}
	do
		takeInput "$((++COUNT)). ${p}" "0"
	done
	
	while true;
	do
		read PRODUCT_SELECTED
		newLine
		
		if [[ "$PRODUCT_SELECTED" == "b" || "$PRODUCT_SELECTED" == "B" ]]; then
				deletePostgresDB "$POSTGRES_JON_DB"
				resetVariableInFile "POSTGRES_JON_DB"
				resetVariableInFile "NUM_JBOSS_TO_INSTALL"
				INSTALL_BUNDLES=""
				loadVariables
				mainMenu
		elif [[ "$PRODUCT_SELECTED" != +([0-9]) || "$PRODUCT_SELECTED" -lt "1" || "$PRODUCT_SELECTED" -gt "$PRODUCT_ARRAY_LENGTH" ]]; then
			outputLog "Invalid input, must be between 1 and $PRODUCT_ARRAY_LENGTH" "4"
			echo -en "\n\t"
		else
			#Decrement PRODUCT_SELECTED by one to match the array indices
			PRODUCT_SELECTED=$((PRODUCT_SELECTED - 1))
			
			#Get the correct PRODUCT_SELECTED from the array
			PRODUCT_SELECTED=${PRODUCT_ARRAY[$PRODUCT_SELECTED]}
			outputLog "The selected product is [$PRODUCT_SELECTED]" "1"
			break
		fi
		
	done
	
	if [[ "$NAME_PATTERN" == "jon" ]]; then
		updateVariablesFile "JON_PRODUCT_FULL_PATH=" "JON_PRODUCT_FULL_PATH=$PRODUCT_SELECTED"
		outputLog "updated the JON_PRODUCT_FULL_PATH variable in the script variables file" "1"
	fi

}

#function - checkOrCreateJBossUser () - checks for jboss user existence, if it exists, do nothing, otherwise create it with passwd jboss
function checkOrCreateJBossUser () {
	USERADD_STATUS=`grep "${JBOSS_OS_USER}:" /etc/passwd`  
	if [[ "$USERADD_STATUS" == "" ]]; then
		useradd ${JBOSS_OS_USER}
		echo ${JBOSS_OS_USER} | passwd ${JBOSS_OS_USER} --stdin 2>&1
		outputLog "Created ${JBOSS_OS_USER} user" "2"
	else
		outputLog "A user called '${JBOSS_OS_USER}' already exists and will be used if needed" "1"
	fi
}

function getProductVersionDetails () {
	
		PN=`extractProductName ${JON_PRODUCT_FULL_PATH}`
		outputLog "Product Name is: [$PN]" "1"
		PV=`extractProductVersion ${PN}`
		outputLog "Product Version is: [$PV]" "1"
		
		PMJV=`extractProductMajorVersion $PV`
		outputLog "Product Major Version is: [$PMJV]" "1"
		PMNV=`extractProductMinorVersion $PV`
		outputLog "Product Minor Version is: [$PMNV]" "1"
		PRV=`extractProductRevisionVersion $PV`
		outputLog "Product Revision Version is: [$PRV]" "1"
		
		updateVariablesFile "JON_MAJOR_VERSION=" "JON_MAJOR_VERSION=$PMJV"
		updateVariablesFile "JON_MINOR_VERSION=" "JON_MINOR_VERSION=$PMNV"
		updateVariablesFile "JON_REVISION_VERSION=" "JON_REVISION_VERSION=$PRV"
		updateVariablesFile "JON_DEMO_INSTALLED=" "JON_DEMO_INSTALLED=y"
		
		
}

#function - extractProductName (path) - extracts product/file name from a full path provided
function extractProductName () {
	PATH=$1
#
	#Filename of zip file for selected JON product (ex:jon-server-2.4.0.GA.zip)
	ZIP=${PATH##*/}
#	outputLog "extractProductName: zip filename is: $ZIP"
#
	#The name/version of the selected JON product (ex: jon-server-2.4.0.GA)
	PRODUCT=${ZIP%.zip}
#	outputLog "extractProductName: productname is: $PRODUCT"
#
	echo $PRODUCT
}

#function - extractProductVersion (productName) - extract the version from the product name
function extractProductVersion () {
	#Example jon-server-2.4.0.GA
	PRODUCT_NAME=$1

	if [[ "$PRODUCT_NAME" =~ ".GA" ]]; then
		TMP=${PRODUCT_NAME%.GA*} #jon-server-2.4.0
	elif [[ "$PRODUCT_NAME" =~ ".CR" ]]; then
		TMP=${PRODUCT_NAME%.CR*} #jon-server-2.4.0
	elif [[ "$PRODUCT_NAME" =~ ".RC" ]]; then
		TMP=${PRODUCT_NAME%.RC*} #jon-server-2.4.0
	fi
	TMP=${TMP##*-}		 #2.4.0

	echo $TMP
}

#function - extractProductMajorVersion (productVersion) - extract the major version from the product version
function extractProductMajorVersion () {
	PRODUCT_VERSION=$1
	
	echo ${PRODUCT_VERSION%%.*}		#2
}

#function - extractProductMinorVersion (productVersion) - extract the minor version from the product version
function extractProductMinorVersion () {
	PRODUCT_VERSION=$1
	
	TEMP=${PRODUCT_VERSION#*.}		#4.0
	echo ${TEMP%.*}		#4
}

#function - extractProductRevisionVersion (productVersion) - extract the revision version from the product version
function extractProductRevisionVersion () {
	PRODUCT_VERSION=$1
	
	echo ${PRODUCT_VERSION##*.}		#0
}

#function - getZipTopFolder (zipFile) - outputs the top level folder for the provided zip file
function getZipTopFolder () {
	COUNT=0
	for i in `zipinfo -1 $1`
	do
		COUNT=1
		if [[ "$COUNT" == 1 ]]; then	
			echo $i
			break
		fi
	done
}

#function - uncommentLineInFile (stringToUncomment, fileInWhichToReplace)  - find a line and uncomment it.
function uncommentLineInFile () {
	local STRING_TO_FIND=$1
	local FILE=$2
	
	LINE_NUMBER=`grep -nr "$STRING_TO_FIND" $FILE`
	LINE_NUMBER=${LINE_NUMBER%%:*}

	if [[ "$LINE_NUMBER" == "" ]]; then
		outputLog "The text $STRING_TO_FIND was not found in $FILE in UncommentLineInFile, skipping uncomment" "3"
	else
		outputLog "Found the text [$STRING_TO_FIND] at line $LINE_NUMBER"
		AFTER=$(( LINE_NUMBER + 1))
		BEFORE=$(( LINE_NUMBER - 1))
		
		CHECK_AFTER=`head -$AFTER $FILE | tail -1`
		CHECK_BEFORE=`head -$BEFORE $FILE | tail -1`
		if [[ "$CHECK_AFTER" =~ "-->" && "$CHECK_BEFORE" =~ "<!--"  ]]; then
			sed -i ${AFTER}d $FILE
			sed -i ${BEFORE}d $FILE
			
		#If a comment starts before this line but ends later on, just shift the start comment to below
		elif [[ "$CHECK_BEFORE" =~ "<!--" && "$CHECK_AFTER" != "*-->*" ]]; then
			outputLog "Text BEFORE at $BEFORE [$CHECK_BEFORE] -- Text AFTER at $AFTER [$CHECK_AFTER]"
	
			#Add a new line after the current that contains the line before (which is <!--)
			touch tmp.txt
			awk -v "n=${AFTER}" -v "s=${CHECK_BEFORE}" '(NR==n) {print s} 1' $FILE > tmp.txt 2>&1
			mv tmp.txt $FILE
			
			#Remove the start comment on the line before, as it's shifted to the line below
			sed -i ${BEFORE}d $FILE

		else
			outputLog "The lines before and after the text being replaced are not comment only lines, not processing them..."
		fi	
	fi
	
}

#function - UncommentAndReplaceInFile (stringToUncomment, stringReplacing, fileInWhichToReplace) - Takes a line with text, uncomments it, and replaces it with the new text
function uncommentAndReplaceInFile () {

	local STRING_TO_REPLACE=$1
	local STRING_REPLACING=$2	
	local FILE=$3
	
	LINE_NUMBER=`grep -nr "$STRING_TO_REPLACE" $FILE`
	LINE_NUMBER=${LINE_NUMBER%%:*}

	if [[ "$LINE_NUMBER" == "" ]]; then
		outputLog "The text $STRING_TO_REPLACE was not found in $FILE in UncommentAndReplaceInFile, skipping replace" "3"
	else
		replaceStringInFile "$STRING_TO_REPLACE" "$STRING_REPLACING" "$FILE"
		uncommentLineInFile "$STRING_REPLACING" "$FILE"	
	fi
		
}

#function - replaceStringInFile (stringToReplace, stringReplacing, fileInWhichToReplace) - replace string1 with string2 in specified file
function replaceStringInFile () {
	
	local STRING_TO_REPLACE=$1
	local STRING_REPLACING=$2	
	local FILE=$3
	
	if [[ -f "$FILE" ]]; then
		
		local STRING_FOUND=`grep "$STRING_TO_REPLACE" "$FILE"`
		if [[ "$STRING_FOUND" != "" ]]; then
			
			TMP_FILE=$TMP_LOCATION/replacing
			
			sed -e "s|$STRING_TO_REPLACE|$STRING_REPLACING|g" $FILE > $TMP_FILE
			
			cp $TMP_FILE $FILE
			deleteFile $TMP_FILE
		else
			outputLog "The string [$STRING_TO_REPLACE] is not found in $FILE, so no replace will take place." "3"
		fi
	
	else
		echo "file not found"
		outputLog "File $FILE does not exist in replaceStringInFile, so skipping replace..." "3"
	fi
}

#function - createScriptVariablesFile () - will create the dynamic variables file used by the script - not to be checked in
function createScriptVariablesFile () {
	
	if [[ -f ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES} ]]; then
		outputLog "Script variables file already exists, using set values" "1"
	else
		touch ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JON_MAJOR_VERSION=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JON_MINOR_VERSION=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JON_REVISION_VERSION=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JON_PRODUCT_FULL_PATH=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JBOSS_SERVER_PORTS_PROVISIONED=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "NUM_JBOSS_TO_INSTALL=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JON_DEMO_INSTALLED=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "POSTGRES_INSTALLED=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "POSTGRES_MAJOR_VERSION=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "POSTGRES_MINOR_VERSION=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "POSTGRES_SERVICE_NAME=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "POSTGRES_JON_DB=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "TIME_TAKEN_PREVIOUSLY=" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "JD_FOLDER=jon-demo" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		echo -e "BUNDLES_ENABLED=false" >> ${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
		outputLog "Script variables file created..." "1"
		
		chown $LOCAL_USER:$LOCAL_USER "${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}"
		
		loadVariables
	fi 
	
}
#function - createDemoConfFile () - Create the conf variable file in the data folder 
function createDemoConfFile () {

	#Create the demo-config.properties file
	if [[ -f ${WORKSPACE_WD}/data/demo-config.properties ]]; then
		outputLog "demo-config.properties file already exists, using set values" "1"
	else
		touch ${WORKSPACE_WD}/data/demo-config.properties
		echo "#USER DEFINABLE VARIABLES" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#########################" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#The location where any/all installs will be placed using this menu" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "INSTALL_LOCATION=/opt" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo -e "\n" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#The location of the system's JAVA install" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "JAVA_HOME=" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo -e "\n" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#The local user account to use for new files and folders, root if left empty" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "LOCAL_USER=" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo -e "\n" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#The details of the latest version of JON, for the creation of the default file structure for the demo" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "LATEST_JON_VERSION=jon-server-3.1.0.GA" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo -e "\n" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#The demo log level to be used across the project" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "DEMO_LOG_LEVEL=2" >> ${WORKSPACE_WD}/data/demo-config.properties
		echo "#########################" >> ${WORKSPACE_WD}/data/demo-config.properties
		outputLog "demo-config.properties file created..." "1"
		
		chown $LOCAL_USER:$LOCAL_USER "${WORKSPACE_WD}/data/demo-config.properties"
		
		loadScripts
		loadVariables
	fi	
}

#function - createDemoDataDir () - create the data directory to prep for all the other file/folder creations
function createDemoDataDir () {
	#Create the data folder only	
	if [[ ! -d ${WORKSPACE_WD}/data ]]; then
		mkdir ${WORKSPACE_WD}/data
	fi
}

#function - createDemoFsStructure (jonVersion) - Creates the data file structure to be used by the demo
function createDemoFsStructure () {
	JON_VERSION=$1
	
	#or if it's not in the right format jon-server-x.x.x
	if [[ "$JON_VERSION" == "" ]]; then
		JON_VERSION=$LATEST_JON_VERSION
	fi		
	
	outputLog "JON VERSION is set to $JON_VERSION"

	#Create the data folder and it's subdirectory	
	if [[ ! -d ${WORKSPACE_WD}/data/jon/$JON_VERSION ]]; then
		mkdir -p ${WORKSPACE_WD}/data/jon/$JON_VERSION
		
		#Currently conf is not used for anything, could add it back if necessary
		#mkdir ${WORKSPACE_WD}/data/jon/$JON_VERSION/conf

		mkdir ${WORKSPACE_WD}/data/jon/$JON_VERSION/patches
		mkdir ${WORKSPACE_WD}/data/jon/$JON_VERSION/plugins
		
	fi	
	
	if [[ ! -d ${WORKSPACE_WD}/data/jboss ]]; then
		mkdir ${WORKSPACE_WD}/data/jboss
	fi
	
	chown $LOCAL_USER:$LOCAL_USER -R ${WORKSPACE_WD}/data
}

#function - updateVariablesFile (stringToReplace, stringReplacing) - calls replaceStringInFile but always in SCRIPT_VARIABLES, allowing for simplified use of the function
function updateVariablesFile () {
	STRING_TO_REPLACE=$1
	STRING_REPLACING=$2	
	
	VARIABLE_FILE=${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}

	TMP_REPLACE=`grep $STRING_TO_REPLACE $VARIABLE_FILE`
	replaceStringInFile "$TMP_REPLACE" "$STRING_REPLACING" "$VARIABLE_FILE"
	
	loadVariables
}

#function - resetVariableInFile (variableName, [variableValue]) - calls replaceStringInFile but always in SCRIPT_VARIABLES, allowing for simplified use of the function
function resetVariableInFile () {
	VARIABLE_NAME=$1
	VARIABLE_VALUE=$2
	outputLog "resetting variable $VARIABLE_NAME to [$VARIABLE_VALUE]"
	
	VARIABLE_FILE=${WORKSPACE_WD}/data/${SCRIPT_VARIABLES}
	#outputLog "looking in file $VARIABLE_FILE"

	TMP_FILE=$TMP_LOCATION/replacing
	#outputLog "temp location $TMP_FILE"
	
	SED_ARG="'/${VARIABLE_NAME}/ c\ ${VARIABLE_NAME}=${VARIABLE_VALUE}'"
	
	SED_EXEC="sed -e $SED_ARG $VARIABLE_FILE > $TMP_FILE"
	#outputLog "sed_exec is $SED_EXEC"
	eval $SED_EXEC
	
	#outputLog "completed sed replacement"
	
	cp $TMP_FILE $VARIABLE_FILE
	deleteFile $TMP_FILE
	
	loadVariables
}

#function - findProductDir () - find the product $1 in location $2
function findProductDir () {
	
	PRODUCT=$1
	LOCATION=$2
	echo `find $LOCATION -name "${PRODUCT}*" -type d`
}

#function - checkServerStatus (serverScript, [nodeInstance]) - This function checks the status of a server with optional node instance returning 0 for stopped, 1 for started, 99 for anything else
function checkServerStatus () {
	SCRIPT=$1
	NODE=$2
	
	if [[ -f $SCRIPT ]]; then
		STATUS=`$SCRIPT status $NODE`
		if [[ "$STATUS" =~ "NOT running" || "$STATUS" =~ "is stopped" ]]; then
			echo 0
		elif [[ "$STATUS" =~ "is running" || "$STATUS" =~ "is started" ]]; then
			echo 1
		else 
			echo 99
		fi
	else
		echo 99
	fi
}

#function - manageServer (product, command, location, instance) - manage product $1, using command $2, in location $3, using instance $4 if passed in 
function manageServer () {
	
	PRODUCT=$1
	COMMAND=$2
	LOCATION=$3
	INSTANCE=$4
	
	PRODUCT_SCRIPT=
	SERVER_STATUS=
	outputLog "\nTrying to ($COMMAND) ($PRODUCT) server in ($LOCATION) using instance ($INSTANCE)"
	
	PRODUCT_DIR=`findProductDir "$PRODUCT" "$LOCATION"`
	case $PRODUCT in
		jon-server) 
			PRODUCT_SCRIPT=$PRODUCT_DIR/$BIN/$JON_STARTUP_SCRIPT;;
		
		jboss-eap)
			PRODUCT_SCRIPT=$PRODUCT_DIR/$JBOSS_BIN/$JBOSS_RH_SCRIPT;;
		
		*)
			outputLog "$PRODUCT start script needs to be defined in utils.sh:manageServer" "4" "y" "n"
			return;;		
	esac
	
	outputLog "script set to $PRODUCT_SCRIPT"
	
	#Check server status and apply correct command
	if [[ "$PRODUCT_DIR" != "" ]]; then
		SERVER_STATUS=`checkServerStatus $PRODUCT_SCRIPT $INSTANCE`
		outputLog "server status ($SERVER_STATUS)"
		newLine
	
		case $COMMAND in
			"start") 		
				if [[ "$SERVER_STATUS" == "0" ]]; then
					$PRODUCT_SCRIPT start $INSTANCE
				fi
				;;
			"stop") 			
				if [[ "$SERVER_STATUS" =~ "1" ]]; then
					$PRODUCT_SCRIPT stop $INSTANCE
				fi
				;;
			"restart") 			
				if [[ "$SERVER_STATUS" =~ "1" ]]; then
					$PRODUCT_SCRIPT stop $INSTANCE
				fi
				$PRODUCT_SCRIPT start $INSTANCE
				;;
			*)			
				outputLog "Valid options for $0 are start | stop | restart" "1" "y" "n"
				;;
		esac	
				
	else
		outputLog "manageServer: server of type $PRODUCT not found in [$LOCATION] to $COMMAND" "4"
	fi
}

#function - lowercase (input) - convert input to lowercase
function lowercase () {
	INPUT=$1
	
	OUTPUT=`tr '[:upper:]' '[:lower:]' <<<"$INPUT"`
	echo $OUTPUT
}

#function - deleteFile (location) - checks if the file exists, and then deletes it
function deleteFile () {

	FILE=$1
	if [[ -f $FILE ]]; then
		rm -f $FILE
	else
		outputLog "File [${FILE}] does not exist, skipping delete..."
	fi
}

#function - deleteFolder (location) - checks if the folder exists, and then deletes it
function deleteFolder () {

	DIR=$1
	if [[ -d $DIR ]]; then
		rm -rf $DIR
	else
		outputLog "Folder [${DIR}] does not exist, skipping delete..."
	fi
}

#function - getInstalledJonVersion () - Gets the version of the JON server installed and currently in use by the script
function getInstalledJonVersion () {
	FOLDER=`find $JD_INSTALL_LOCATION/$JD_FOLDER -name "jon-server*"`
	if [[ "FOLDER" !=  "" ]]; then
		FULL_VERSION=${FOLDER#jon-server*}
		MAJOR_VERSION=${FULL_VERSION%%.*}
	fi
}

#function - waitFor (textToFind, FileToLookIn, timeOutInSeconds, messageToDisplay) - a function that will wait for a maximum of TIMEOUT looking for specific text in a file
function waitFor () {

	TEXT_TO_FIND=$1
	FILE_TO_LOOK=$2
	TIMEOUT=$3
	MESSAGE_TO_DISPLAY=$4
	
	outputLog "Waiting to find \"${TEXT_TO_FIND}\" in $FILE_TO_LOOK with a max timeout of $TIMEOUT"
	outputLog "$MESSAGE_TO_DISPLAY" "2" "n" "y"
	
	#Doubling because the sleep time is halved to ensure reading the log fast enough
	TIMEOUT=$(( TIMEOUT * 2 ))	
	WAIT_FOR_RESULT=""

	COUNT=0
	FOUND=
	while [[ "$FOUND" == "" ]]; do		
		if [[ $((COUNT % 10)) == 0 ]]; then
			outputLog "." "2" "n" "n"
		fi

		if [[ -f "$FILE_TO_LOOK" ]]; then
			FOUND=`tail -15 $FILE_TO_LOOK | grep "${TEXT_TO_FIND}"`
		else
			FOUND=
		fi
		
		if [[ "$FOUND" == "" ]]; then
			sleep 0.5
		else
			outputLog ".   Done waiting after $(( COUNT / 2 ))s"  "2" "n" "n"
			WAIT_FOR_RESULT="completed"
			break
		fi
		 
		if [ $COUNT -lt $TIMEOUT ]; then
			COUNT=$(( $COUNT + 1 ))
		else 
			FOUND=".   Timeout of $(( TIMEOUT / 2 )) seconds reached"
			WAIT_FOR_RESULT="timedout"
			outputLog "$FOUND" "2" "n" "n"
			break
		fi
		
	done
	
	outputLog "." "2" "y" "n"
}

#function - checkBundlesEnabled () - check if bundles are enabled by checking jboss and ant being provided
function checkBundlesEnabled () {
	JBOSS_PROVIDED=`find ${WORKSPACE_WD}/data/jboss -name "jboss-eap-*.zip"`
	ANT_PROVIDED=`ant -version 2>&1`
	if [[ "$JBOSS_PROVIDED" == "" ]]; then
		BUNDLES_ENABLED=false
		echo "*Note: Bundle creation is not enabled. Add JBoss to the data folder if desired."
	elif [[ "$ANT_PROVIDED" =~ "command not found" ]]; then
		BUNDLES_ENABLED=false
		echo "*Note: Bundle creation is not enabled. Install ant on your system if desired."
	else
		setAnt
		
		echo ***Bundle options***
		echo "CB. Create bundles"
		BUNDLES_CREATED=`find ${WORKSPACE_WD}/data -name "bundles"`
		if [[ "$BUNDLES_CREATED" != "" ]]; then
			echo "DB. Delete bundles"
		fi
		BUNDLES_ENABLED=true
	fi
	updateVariablesFile "BUNDLES_ENABLED=" "BUNDLES_ENABLED=$BUNDLES_ENABLED"
	
}

#function - contains () - checks if an array contains a value
function contains () {
	local N=$#
	local VALUE=${!N}
	for (( I = 1; i < $#; i++ )) {
		if [ "${!I}" == "${VALUE}" ]; then
			echo "y"
			return 0
		fi
	}	
	echo "n"
	return 1
}