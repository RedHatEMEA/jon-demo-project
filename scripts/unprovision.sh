#function - unprovisionServer () - the function to unprovision the common server components
#function - unprovisionServer () - the function to unprovision the common server components
function unprovisionServer () {

	BUNDLE_NAME=""
	getBundleDetails ${BUNDLE_COMMON_FILE}
	
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/purgeBundleDeployment.js ${BUNDLE_NAME}"
	newLine
}

#function - unprovisionServerProfile (portSet) - the function to unprovision the server profile using the specified portSet found in the name of the profile
function unprovisionServerProfile () {

	PORT_SET=$1

	BUNDLE_NAME=""
	getBundleDetails ${BUNDLE_DEFAULT_FILE}

	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/purgeBundleDeployment.js ${BUNDLE_NAME} $PORT_SET"
	newLine
}

#function - uninventoryServer (portSet) - removes the server with the portSet in the name from the JON server inventory
function uninventoryServer () {
	PORT_SET=$1
	
	findServer $PORT_SET
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/uninventoryServer.js ${SERVER_ID}"
}

#function - unprovisionApp (portSet) - the function to unprovision the app using the specified portSet
function unprovisionApp () {
	
	PORT_SET=$1
	APP_BUNDLE=$2
	
	BUNDLE_NAME=""
	getBundleDetails $APP_BUNDLE
	
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/purgeBundleDeployment.js ${BUNDLE_NAME} $PORT_SET"
	newLine
}

#function - shutDownServerProfile () - uses the previously set SERVER_ID to run an operation on the provided server to shut it down.
function manageServerProfile () {
	SERVER_ID=$1
	OPERATION=$2
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/manageServer.js ${SERVER_ID} ${OPERATION}"
}

#function - unprovision (portSet) - the start function to unprovision an existing server with the passed in portSet
function unprovision () {
	PORT_SET=$1
	if [[ "${PORT_SET}x" == "x" ]]; then
		outputLog "Usage: $0 <${NODE_TEXT}-PORT_SET> (ex. 100, 200, etc...)" "4"
		outputLog "This script will unprovision extra servers using the provided port set" "4"
	else
	
		getRHQCLIDetails
		
		findServer $PORT_SET
		if [[ "${SERVER_ID}x" != "x" ]]; then
			
			#Shutdown the server if it is running
			manageServerProfile $SERVER_ID "shutdown"
		
			unprovisionApp $PORT_SET ${BUNDLE_APP_FILE}
			unprovisionApp $PORT_SET ${BUNDLE_HW_APP_FILE}
			unprovisionServerProfile $PORT_SET
			uninventoryServer $PORT_SET
			
			#Maintain the original port set pass thru the command line arguements given that findServer sets PORT_SET
			CMD_ARG_PORT_SET=$PORT_SET
			
			SERVER_ID=
			
			#Look for the first server that was provisioned...
			FIRST_SERVER=${JBOSS_SERVER_PORTS_PROVISIONED%% *}
			findServer $FIRST_SERVER
			PORT_SET=$CMD_ARG_PORT_SET
			
			#Hardcoding the fact that if we are unprovision portSet 100, we remove the base
			if [[ "${SERVER_ID}x" == "x" || "$PORT_SET" == "100" ]]; then
				unprovisionServer
			else
				outputLog "Unprovisioning a server other then 100 or the first [$FIRST_SERVER], so keeping the server base..." "2"
			fi
		else
			outputLog "The server with port $PORT_SET, was not set and cannot be unprovisioned." "3"
		fi
	fi
}
