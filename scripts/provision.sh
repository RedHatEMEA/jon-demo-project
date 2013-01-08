#Global Variables
CHECKING_PREVIOUS="n"
BASE_NEEDED="y"
SERVER_PORT=0

STARTING_PORT=0

#function - provisionServer () - provisions the server common bits using a previously created destination
function provisionServer () {

	BUNDLE_NAME=""
	getBundleDetails ${BUNDLE_COMMON_FILE}
	
	DESTINATION_NAME="${DEST_NAME_TEXT}${DEST_COMMON_SUFFIX}"
	#Deploy bundle
	#BUNDLE_NAME taken from above
	DEPLOYMENT_DESC="Deployment_via_CLI_script--${DEST_COMMON_SUFFIX}"
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/deployBundle.js ${BUNDLE_NAME} ${DESTINATION_NAME} ${DEPLOYMENT_DESC}"
	newLine
}

#function - provisionServerProfile (PORT_SET) - provisions the server profile taking in the port set to deploy using a previously created destination
function provisionServerProfile () {

	PORT_SET=$1

	BUNDLE_NAME=""
	getBundleDetails ${BUNDLE_DEFAULT_FILE}
	
	DESTINATION_NAME="${DEST_NAME_TEXT}${NODE_TEXT}${PORT_SET}"
	#Deploy bundle
	#BUNDLE_NAME taken from above
	DEPLOYMENT_DESC="Deployment_via_CLI_script--${NODE_TEXT}${PORT_SET}"

	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/deployBundle.js ${BUNDLE_NAME} ${DESTINATION_NAME} ${DEPLOYMENT_DESC} JAVA_HOME=${JAVA_HOME} JBOSS_HOME=${JD_INSTALL_LOCATION}/${DEST_COMMON_SUFFIX} JBOSS_USER=${JBOSS_OS_USER} JBOSS_CONF_BASE=${JBOSS_BASE_CONF} JBOSS_PORTS_OFFSET=${PORT_SET}"
	newLine
}

#function - provisionApp (PORT_SET, DESTINATION_NAME) - provisions the app taking in the port set and destination name to deploy to the appropriate destination
function provisionApp () {
	
	PORT_SET=$1
	DESTINATION_NAME=$2
	APP_FILE=$3

	outputLog "DESTINATION_NAME $DESTINATION_NAME"
	BUNDLE_NAME=""
	getBundleDetails $APP_FILE
	 
	#Deploy bundle
	#BUNDLE_NAME taken from above
	DEPLOYMENT_DESC="Deployment_via_CLI_script--${DEST_COMMON_SUFFIX}"
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/deployBundle.js ${BUNDLE_NAME} ${DESTINATION_NAME} ${DEPLOYMENT_DESC} JBOSS_HOME=${JD_INSTALL_LOCATION}/${DEST_COMMON_SUFFIX} JBOSS_CONF=${JBOSS_BASE_CONF}${PORT_SET}"
	newLine
}

#function - executeAgentCommand (command) - executes the provided agent command
function executeAgentCommand () {
	COMMAND=$1
	
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/agentsOperations.js $COMMAND"
}

#function - checkForServerWithPort (portSet) - Check the JON server for a JBoss server with the port pattern specified
function checkForServerWithPort () {
	CHECK_PORT=$1
	SERVER_ID=""
	
	outputLog "Searching to see if server ${NODE_TEXT}${CHECK_PORT} is already installed and inventoried in JON..." "2"
	findServer $CHECK_PORT
	
	#We check a previous install (with port - 100), if it's not found, we need the base 
	if [[ "${SERVER_ID}x" == "x" && "$CHECKING_PREVIOUS" == "y" ]]; then
		outputLog "Base server bundle has not been provisioned previously." "2"
		BASE_NEEDED="y"
		echo "in function portset is: [$PORT_SET]"
		echo "in function checkport is: [$CHECK_PORT]"
		
	#We check a previous install (with port - 100), if it is found, then we don't need the base
	elif [[ "${SERVER_ID}x" != "x" && "$CHECKING_PREVIOUS" == "y" ]]; then
		outputLog "Server $CHECK_PORT has been provisioned with base server previously." "3"
		BASE_NEEDED="n"
		
	#We check the current install, if it's not found, we will install it (base will be dependent on default vs previous conditions)
	elif [[ "${SERVER_ID}x" == "x" && "$CHECKING_PREVIOUS" == "n" ]]; then
		if [[ "$BASE_NEEDED" == "y" ]]; then
			outputLog "Server $CHECK_PORT will be provisioned fully." "2"
		else
			outputLog "Server $CHECK_PORT will be provisioned only with the port-specific components." "2"
		fi
		SERVER_PORT=$CHECK_PORT
		
	#We check the current install, if it's found, we will install it (base will be dependent on default vs previous conditions)
	elif [[ "${SERVER_ID}x" != "x" && "$CHECKING_PREVIOUS" == "n" ]]; then
		BASE_NEEDED="n"
		CHECK_PORT=$(( CHECK_PORT + 100 ))
		
		PORT_DIFF=$(( CHECK_PORT - STARTING_PORT )) 
		if [ $PORT_DIFF -le 500 ]; then
			checkForServerWithPort $CHECK_PORT
	
			if [ $CHECK_PORT -le $SERVER_PORT ]; then
				outputLog "Ignoring $CHECK_PORT, as it was found and is less then or equal to $SERVER_PORT" "1"
			fi
		else
			outputLog "Servers $STARTING_PORT thru $CHECK_PORT are already installed, call provision with a higher port to start with..." "3"
			SERVER_PORT=9999 
		fi

	fi
}

function installServer () {
	PROVISION_BASE=$1
	
	setupDestination ${BUNDLE_DEFAULT_FILE} "${NODE_TEXT}${SERVER_PORT}"
		
	if [[ "$PROVISION_BASE" == "y" ]]; then
		provisionServer
	fi
	
	provisionServerProfile $SERVER_PORT
		
	#Deploy and provision the dvd-store app
	APPLICATION_DESTINATION_NAME="applications/${NODE_TEXT}${SERVER_PORT}/seam-dvdstore"
	setupDestination ${BUNDLE_APP_FILE} $APPLICATION_DESTINATION_NAME
	provisionApp $SERVER_PORT $APPLICATION_DESTINATION_NAME ${BUNDLE_APP_FILE}
	
	#Deploy and provision the hello-world app
	APPLICATION_DESTINATION_NAME="applications/${NODE_TEXT}${SERVER_PORT}/hello-world"
	setupDestination ${BUNDLE_HW_APP_FILE} $APPLICATION_DESTINATION_NAME
	provisionApp $SERVER_PORT $APPLICATION_DESTINATION_NAME ${BUNDLE_HW_APP_FILE}
}

#function - handleJBossServerImport () - Invokes the CLI scripts when importing the JBoss server, only if the EAP plugin is provided
function handleJBossServerImport () {
	
#If the jon plugin directory hasn't been defined due to no installation, then update it
	if [[ "$JON_PLUGINS_DIRECTORY" == "" ]]; then
		getJONPluginDirectory
	fi
	
	#Check if the plug in exists and that the JBoss server has started up
	EAP_PLUGIN_FOUND=`find $JON_PLUGINS_DIRECTORY -name "*eap*"`

	if [[ "$EAP_PLUGIN_FOUND" != "" ]]; then 
		
		#wait for the server to start up fully before attempting to import to JON - as we have more servers, assume a longer startup
		ASSUMED_SERVER_NUM=$(( SERVER_PORT / 100 ))
		SERVER_STARTUP_TIMEOUT=$(( ASSUMED_SERVER_NUM * 50 * 3 / 2 ))  #3/2 because bash doesn't 1.5 as an arithmetic operator 
		waitFor "Started in" "$JD_INSTALL_LOCATION/${NODE_TEXT}${PORT_SET}/${JBOSS_BASE_CONF}${PORT_SET}/log/server.log" "$SERVER_STARTUP_TIMEOUT" "Waiting for the JBoss server start up"
		newLine
	
		executeAgentCommand discovery
		waitFor "Discovered [^0] new server" "$AGENT_LOG_FOLDER" "20" "Awaiting server discovery by JON..."

		executeAgentCommand availability
		newLine
		
		importResources
		#Wait for the import to take effect to ensure new server is seen in JON
		waitFor "Scanned platform and [^0] server(s)" "$AGENT_LOG_FOLDER" "30" "Awaiting server import into JON..."
		#waitFor "Detected new Server" "$AGENT_LOG_FOLDER" "20" "Awaiting server import into JON..."
		#sleep 5
		
		findServer $PORT_SET
		if [[ "$SERVER_ID" != "" ]]; then
			JNP_PORT=$(( $PORT_SET + 1099 ))
			eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/configureServer.js ${SERVER_ID} true namingURL=jnp://127.0.0.1:${JNP_PORT} javaHome=${JAVA_HOME} bindAddress=0.0.0.0 startWaitMax=2 stopWaitMax=1"
			eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/toggleEventLogging.js ${SERVER_ID} on"
			sleep 7
			
			#TODO enable events in the configuration... either new cli script, or the above one..
			
			#Once the configuration is update, wait to ensure it takes effect
			waitFor "RuntimeDiscoveryExecutor)- Scanned platform and" "$AGENT_LOG_FOLDER" "20" "Platform and server being scanned..."
				newLine

				eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/agentsOperations.js availability"
		else
			outputLog "Server with portSet: $PORT_SET not found in JON, not updating config". "3"
		fi
	else
		outputLog "Looked in '$EAP_PLUGIN_FOUND' for a plugin with name *eap*" "1"
		outputLog "The EAP plugin has not been provided.  The JBoss server was deployed but cannot be imported and properly configured." "3"
	fi
			
}

#function - provision (portSet) - the start function to provision a new server with the passed in portSet
function provision () {
	#This is the main part of the script - gets called at startup of the script
	PORT_SET=$1
	#FUTURE pass in platform to deploy to be used to check against the plugin.
	
	if [[ "${PORT_SET}x" == "x" ]]; then
		outputLog "Usage: $0 <${NODE_TEXT}-PORT_SET> (ex. 100, 200, etc...)" "4"
		outputLog "This script will provision extra servers using the provided port set" "4"
	else
		
		STARTING_PORT=$PORT_SET
		setGroupDetails
		
		#checkForServerWithPort 100
		#if [[ "$PORT_SET" != "100" ]]; then
		#	checkForServerWithPort $PORT_SET
		#fi
			
		if [[ "$PORT_SET" != "100" ]]; then
			CHECKING_PREVIOUS="y"
			PREVIOUS_PORT=$(( PORT_SET - 100 ))
			checkForServerWithPort $PREVIOUS_PORT
			CHECKING_PREVIOUS="n"
		fi

		checkForServerWithPort $PORT_SET
			
		if [[ "$SERVER_PORT" != "9999" ]]; then
			CURRENT_PORT_BEING_INSTALLED=$SERVER_PORT
			installServer "$BASE_NEEDED"
					
			waitFor "Bundle \[seam-dvdstore" "$AGENT_LOG_FOLDER" "15" "Awaiting bundle deployment..."
			
			handleJBossServerImport
		else
			#Not installing a server, so change the current port being installed to empty
			CURRENT_PORT_BEING_INSTALLED=""
		fi
	fi
}
