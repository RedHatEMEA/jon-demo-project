function getBundleDetails () {

	BUNDLE_FILE=$1
	
	#Get bundle details - name, version
	unzip $BUNDLE_FILE deploy.xml 2>&1 > /dev/null
	BUNDLE_TEXT=`grep "bundle name" deploy.xml`
	#Text after the rhq:bundle name=...
	BUNDLE_TEXT=${BUNDLE_TEXT#*name=\"}
	#Text before the rest of the line, after the first double quote
	BUNDLE_NAME=${BUNDLE_TEXT%%\"*}
	outputLog Dealing with bundle named $BUNDLE_NAME "2"
	BUNDLE_TEXT=${BUNDLE_TEXT#*version=\"}
	BUNDLE_VERSION=${BUNDLE_TEXT%%\"*}
	outputLog Dealing with bundle with version $BUNDLE_VERSION "2"
	newLine
	deleteFile deploy.xml

}

#function - importResources () - imports resources into the JON server
function importResources () {

	#Import all resources into JON
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/autoImport.js"
	newLine
}

#function - findServer (portSet) - checks for a server containing the provided port set and sets the resource ID for that server if found
function findServer () {
	SERVER_PORT_TO_FIND=$1
	
	SERVER_ID=
	SERVER_SEARCH=`eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/findServer.js ${JBOSS_BASE_CONF}${SERVER_PORT_TO_FIND}" 2>&1`
	#Check for OUTPUT text, i.e the server is found
	if [[ "$SERVER_SEARCH" =~ "OUTPUT" ]]; then
		outputLog "Found server with pattern: ${JBOSS_BASE_CONF}${SERVER_PORT_TO_FIND}, continuing to operation..." "2"
		SERVER_ID=${SERVER_SEARCH#*OUTPUT=}
		SERVER_ID=${SERVER_ID% *}
	else
		outputLog "Server with pattern: ${JBOSS_BASE_CONF}${SERVER_PORT_TO_FIND} not found..." "2"
	fi
	newLine
}

function setupBundleAndDestination () {
	
	BUNDLE_FILE=$1
	DEST_SUFFIX=$2

	setupBundle $BUNDLE_FILE
	setupDestination $BUNDLE_FILE $DEST_SUFFIX
}

function setupBundle () {

	BUNDLE_FILE=$1

	getBundleDetails $BUNDLE_FILE
	
	#Create bundle
	outputLog "Invoking bundle creation..." "2"
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/createBundle.js ${BUNDLE_FILE} ${BUNDLE_NAME} ${BUNDLE_VERSION}"
	newLine

}

function setupDestination () {

	BUNDLE_FILE=$1
	DEST_SUFFIX=$2

	getBundleDetails $BUNDLE_FILE

	#Create bundle destination
	#GROUP_NAME taken from above
	DESTINATION_NAME="${DEST_NAME_TEXT}${DEST_SUFFIX}"
	DESTINATION_LOCATION="${JD_INSTALL_LOCATION}/${DEST_SUFFIX}"
	DESTINATION_BASE_DIR="Root"

	#Ensure that the location does NOT contain a trailing / at the end
	LAST_CHAR=`echo $DESTINATION_LOCATION | tail -c 2`
	if [[ "$LAST_CHAR" == "/" ]]; then
		DESTINATION_LOCATION=${DESTINATION_LOCATION%*/}
	fi
	DESTINATION_DESC="Generated_via_CLI--${DEST_SUFFIX}"

	if [[ "$JON_MAJOR_VERSION" == "3" ]]; then
		outputLog "Invoking bundle destination creation..." "2"
		DESTINATION_BASE_DIR="Root"
		eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/createBundleDestination.js ${BUNDLE_NAME} ${GROUP_NAME} ${DESTINATION_NAME} ${DESTINATION_LOCATION} ${DESTINATION_DESC} ${DESTINATION_BASE_DIR}"
	elif [[ "$JON_MAJOR_VERSION" == "2" ]]; then
		outputLog "Invoking bundle destination creation..." "2"
		eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/createBundleDestination.js ${BUNDLE_NAME} ${GROUP_NAME} ${DESTINATION_NAME} ${DESTINATION_LOCATION} ${DESTINATION_DESC}"
	else
		outputLog "Unsupported JON version [${JON_MAJOR_VERSION}], not creating destination..." "3"
	fi

	newLine
}

function deployBundle () {
	
	BUNDLE_FILE=$1

	getBundleDetails $BUNDLE_FILE
	
	#Deploy bundle
	#BUNDLE_NAME taken from above
	DEPLOYMENT_DESC="Deployment_via_CLI_script"
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/deployBundle.js ${BUNDLE_NAME} "01" "JON_Demo_JBoss_Bundle_Destination1" ${DEPLOYMENT_DESC}"
	newLine
}

function setGroupDetails () {
	GROUP_NAME="Linux-Platform"
	PLUGIN_NAME="Platforms"
	RESOURCE_TYPE_NAME="Linux"
}
