#function - setupJonServer () - runs the basic setup for provision on the JON server, creates a group, imports resources, and adds them to the group.
function setupJonServer () {

	outputLog "Setting up JON server..." "2"
	newLine
	newLine
	##FYI can't have spaces in any of the params passed thru....

	#Create a Linux Platform group (no dependencies on anything, so create group first, then import)
	setGroupDetails
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/createGroup.js ${GROUP_NAME} ${PLUGIN_NAME} ${RESOURCE_TYPE_NAME}"
	newLine

	executeAgentCommand discovery
	waitFor "RuntimeDiscoveryExecutor)- Scanned platform and" "$AGENT_LOG_FOLDER" "20" "Awaiting server detection in JON..."
	
	newLine
	importResources

	#Add the agent machine (JON Server) into the Linux platform)
	HOST_NAME=`hostname`
	outputLog "hostname of current machine: $HOST_NAME"

	SEARCH_PATTERN=
	if [[ "$EMBEDDED_AGENT_ACTIVE" == "true" ]]; then
		SEARCH_PATTERN="${HOST_NAME}-embedded"
	else 
		SEARCH_PATTERN="${HOST_NAME}-agent"
	fi
	outputLog "will search for $SEARCH_PATTERN to add to group..."
	
	RESOURCE_TYPE_NAME="Linux"
	eval $CLI_COMMAND $RHQ_OPTS -f "${WORKSPACE_WD}/cli/CLI/addToGroup.js ${GROUP_NAME} ${SEARCH_PATTERN} ${RESOURCE_TYPE_NAME}"
	newLine

}