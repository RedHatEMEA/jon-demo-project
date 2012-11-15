function getJONPluginDirectory () {

	if [[ "$JON_PRODUCT_FULL_PATH" != "" ]]; then
	
		#Directory for selected product (ex: ./data/jon/jon-server-3.1.0.GA.zip)
		JON_DIRECTORY=${JON_PRODUCT_FULL_PATH%/*}
		#outputLog "JON_DIRECTORY: $JON_DIRECTORY"	
	
		#Directory for plugins for selected JON product (from above - ex: ./data/jon/plugins)
		JON_PLUGINS_DIRECTORY=$JON_DIRECTORY/$JON_PLUGINS	
		
		outputLog "JON_PLUGINS_DIRECTORY: $JON_PLUGINS_DIRECTORY"	
	else
		outputLog "The JON_PRODUCT_FULL_PATH hasn't been defined, as such no JON_PLUGIN_DIRECTORY can be defined." "3"
	fi
}

#function - extractJONPlugins () - extracts all the found plugins into the installed jon server
function extractJONPlugins () {

	newLine
	outputLog "JON product selected, extracting plugins..." "2"
		
	#Get the JON Plugin directory...
	getJONPluginDirectory

	JON_PRODUCT=`extractProductName $JON_PRODUCT_FULL_PATH`
	outputLog "JON_PRODUCT: $JON_PRODUCT"

	#Remove any existing jon extracted plugins in the tmp directory
	deleteFolder $TMP_LOCATION/$JON_PRODUCT

	#Find all plugin ZIPs and extract to tmp into selected JON version folder
	FOUND_PLUGIN_ZIPS=`ls -A $JON_PLUGINS_DIRECTORY`
	if [[ -d $JON_PLUGINS_DIRECTORY && "$FOUND_PLUGIN_ZIPS" != "" ]]; then 
		for f in `find $JON_PLUGINS_DIRECTORY -name "*.zip"`
		do
			extractPackage $f $TMP_LOCATION/$JON_PRODUCT
		done
		
		newLine
		#Copy all the JARs from the plugins into the JON server plugins folder
		outputLog "Copying all plugin JARs to $JD_INSTALL_LOCATION/$JON_PRODUCT/$JON_PLUGINS" "2"
		for f in `find $TMP_LOCATION/$JON_PRODUCT -name "*.jar"`
		do
			cp $f $JD_INSTALL_LOCATION/$JON_PRODUCT/$JON_PLUGINS
		done
	else
		outputLog "No plugins found, skipping plugin install.  You will have limited platforms supported." "3"
	fi

	newLine
}

#function - silentlyInstallJon () - silently install JON using defined configuration properties
function silentlyInstallJon () {
	outputLog "Using properties file: $JON_SILENT_CONFIG_FILE to install $JON_PRODUCT" "2"
	outputLog "You can change the server end point, http and https ports, amongst other properties if need be..." "2"

	newLine

	JON_CONFIG_FILE=$JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_SILENT_CONFIG_FILE
	
	outputLog "Backing up $JON_SILENT_CONFIG_FILE to ${JON_CONFIG_FILE}_bak" "2"
	cp $JON_CONFIG_FILE ${JON_CONFIG_FILE}_bak
	
	outputLog "Updating $JON_SILENT_CONFIG_FILE with postgres database name [$POSTGRES_JON_DB]" "2"
	replaceStringInFile "rhq.server.database.db-name=rhq" "rhq.server.database.db-name=${POSTGRES_JON_DB}" "$JON_CONFIG_FILE"
	replaceStringInFile "rhq.server.database.connection-url=jdbc:postgresql://127.0.0.1:5432/rhq" "rhq.server.database.connection-url=jdbc:postgresql://127.0.0.1:5432/${POSTGRES_JON_DB}" "$JON_CONFIG_FILE"
	replaceStringInFile "rhq.autoinstall.enabled=false" "rhq.autoinstall.enabled=true" "$JON_CONFIG_FILE"
	
	outputLog "Backing up $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT to $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/${JON_STARTUP_SCRIPT}_bak" "2"
	cp $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/${JON_STARTUP_SCRIPT}_bak

	replaceStringInFile "# RHQ_SERVER_HOME=/path/to/server/home" "RHQ_SERVER_HOME=${JD_INSTALL_LOCATION}/${JON_PRODUCT}" "$JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT"
	replaceStringInFile "# JAVA_HOME=/path/to/java/installation" "RHQ_SERVER_JAVA_HOME=${JAVA_HOME}" "$JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT"

	if [ -f /etc/init.d/postgresql ]; then
		PGVERSION=`grep "PGVERSION=" /etc/init.d/postgresql`
		if [[ "$PGVERSION" =~ "9" ]]; then
			newLine
			
			if [[ "$JON_MAJOR_VERSION" != "3" ]]; then
				outputLog "Using postgres 9 drivers $POSTGRESQL_DRIVER - functionality will not be 100% unless using JON 3.x+" "2"
			else
				outputLog "Using postgres 9 drivers $POSTGRESQL_DRIVER with JON 3" "2"
			fi
			
			#copy the latest postgresql driver into jon
			cp =$JON_CONF_DIR/$JON_PRODUCT/$POSTGRESQL_DRIVER ${JD_INSTALL_LOCATION}/$JON_PRODUCT/jbossas/server/default/lib
			deleteFile ${JD_INSTALL_LOCATION}/$JON_PRODUCT/jbossas/server/default/lib/postgresql-8.4*.jar
		fi
	fi

	newLine
	#Start the jon server
	${JD_INSTALL_LOCATION}/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT start

	newLine

	#We need to wait cause on initial start up, the server unpacks stuff...
	waitFor "Started in" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "180" "Awaiting JON server start up"
	if [[ "$WAIT_FOR_RESULT" == "completed" ]]; then
		handleJonFirstStartup
	else
		outputLog "Server start up did not complete after a long wait, please check rhq-server.log and boot.log, aborting JON demo install." "4"
		mainMenu
	fi
	
	#Install the jon tools: agent, cli
	handleJonAccessoriesSetup
	
	#Wait for the JON server to be ready, to display the run firefox line
	waitFor "Starting the master server plugin container" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "300" "Processing JON plugin deployment..."
	waitFor "Started J2EE application" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "300" "Finalizing JON server setup"
	
	newLine
	outputLog "-----------  Run: firefox http://localhost:7080  -----------" "2"
	newLine
	
	#Check which agent is used and wait for it to connect to the server, necessary to use the CLI to deploy, etc...
	checkEmbeddedAgent
	
	if [[ "$EMBEDDED_AGENT_ACTIVE" == "true" ]]; then
		waitFor "Embedded RHQ Agent has been started!" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "180" "Waiting for embedded agent to start"
	else
		outputLog "Embedded agent not enabled, not waiting for it..."
		waitFor "has connected to this server at" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "180" "Waiting for stand-alone agent to connect to server"
		
		waitFor "Discovered new platform with" "$AGENT_LOG_FOLDER" "45" "Waiting for availability report to be sent to server from agent"
	fi

	runCLIScripts
		
	#Set the entire jon demo directory to be owned by the LOCAL_USER
	chown $LOCAL_USER:$LOCAL_USER -R "$JD_INSTALL_LOCATION"
	
}

#function - handleJonAccessoriesSetup () - handles the installation of all the JON accessories after JON setup itself is complete
function handleJonAccessoriesSetup () {

	newLine
	outputLog "Setting up JON accessories..." "2"
	newLine
	
	deployAgent "$JD_INSTALL_LOCATION/$JON_PRODUCT"

	deployCLI "$JD_INSTALL_LOCATION/$JON_PRODUCT"
	deployCLIAntTestTool "$JD_INSTALL_LOCATION/$JON_PRODUCT"
}

#function - handleJonFirstStartup () - handles the tasks to undertake on first start up of JON, license, postgres driver, patches, etc...
function handleJonFirstStartup () {

	newLine

	if [[ "$PGVERSION" =~ "9" ]]; then
		newLine
	
		if [[ "$JON_MAJOR_VERSION" != "3" ]]; then
			outputLog "Using postgres 9 drivers $POSTGRESQL_DRIVER - functionality will not be 100% unless using JON 3.x+" "2"
		else
			outputLog "Using postgres 9 drivers $POSTGRESQL_DRIVER with JON 3" "2"
		fi
	
		#copy the latest postgresql driver into jon
		cp $JON_PRODUCTS_DIR/$CONF/$POSTGRESQL_DRIVER ${JD_INSTALL_LOCATION}/$JON_PRODUCT/$JON_RHQ_EAR/lib/
		if [[ -f ${JD_INSTALL_LOCATION}/$JON_PRODUCT/$JON_RHQ_EAR/lib/postgresql-8.4*.jar ]]; then
			deleteFile ${JD_INSTALL_LOCATION}/$JON_PRODUCT/$JON_RHQ_EAR/lib/postgresql-8.4*.jar
		fi
	fi		
	
	outputLog "prod dir: $JON_PRODUCTS_DIR" "1"

	deployJONPatches "$JON_PRODUCTS_DIR/$JON_PRODUCT/patches" "${JD_INSTALL_LOCATION}/$JON_PRODUCT/"
	newLine
	
}

#function - deleteJONServer - delete the jon server installed
function deleteJONServer () {
		
	outputLog "Existing JON instances:" "1" "y" "n"
	
	#TODO modify the reading of this variable to take a number versus the full url
	find $JD_INSTALL_LOCATION -name "jon-server*"

	newLine
	takeInput "Choose JON server to delete"
	read TO_DELETE

	if [[ -n "$TO_DELETE" ]]; then

		newLine
		SERVICE_STATUS=`$JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT status`
		if [[ "$SERVICE_STATUS" =~ "is running" ]]; then
			$JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_STARTUP_SCRIPT stop
			newLine
		#else the server is already stopped
		fi
		deleteFolder $TO_DELETE
		deleteFile $INIT_D/rhq-server
		outputLog "Deleted JON server from $TO_DELETE" "1" "y" "n"
		newLine

		#DB_TO_DELETE=`grep "rhq.server.database.db-name=" $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_SILENT_CONFIG_FILE`
		#DB_TO_DELETE=${DB_TO_DELETE#*=}
		deletePostgresDB $POSTGRES_JON_DB #$DB_TO_DELETE
		resetVariableInVariableFile "POSTGRES_JON_DB"
		loadVariables
	fi
	newLine

}

#function - deployJONPatches (from, to) - patches the JON server using the expanded versions of the patches
function deployJONPatches () {
	FROM=$1
	TO=$2

	newLine
	if [[ -d $FROM ]]; then
	
		#check if JON patches are found in the folder before attempting to deploy
		TOTAL=`ls -l $FROM`
		
		if [[ "$TOTAL" != "total 0" ]]; then
			outputLog "Deploying extracted JON patches from ${FROM} to ${TO}..." "2"
			alias cp='cp'
			cp -Rf ${FROM}/* ${TO}
		else
			outputLog "The patches folder exists but is empty, skipping JON patch deployment" "3"
		fi
	else
		outputLog "No patches to deploy, skipping JON patch deployment" "2"
	fi

}

#function - manageJBossDemoServers (command, jbossPortArray) - start/shutdown the servers installed with the demo
function manageJBossDemoServers () {
	
	COMMAND=$1
	local PORT_ARRAY=$2
	
	if [[ "$PORT_ARRAY" == "" ]]; then
		PORT_ARRAY=($( echo $JBOSS_SERVER_PORTS_PROVISIONED ))
	else
		PORT_ARRAY=($( echo $PORT_ARRAY ))
	fi
	
	outputLog "Managing the JBoss servers: ${PORT_ARRAY[@]}" "1"
	
	if [[ "$NUM_JBOSS_TO_INSTALL" != 0 ]]; then
		for PORT in ${PORT_ARRAY[@]}
		#for (( A=1; A <= NUM_JBOSS_TO_INSTALL ; A++ ))
		do 
			#PORT=$(( $A * 100 ))
			outputLog "working on port $PORT -- currently deployed [$JBOSS_SERVER_PORTS_PROVISIONED]"
			
			findServer $PORT
			if [[ "${SERVER_ID}x" != "x" ]]; then
				manageServerProfile $SERVER_ID "$COMMAND"
			else
				outputLog "Server with port ${PORT} not found in JON, moving on..." "3"
			fi
		done
	else
		outputLog "No JBoss demo servers installed to be $COMMAND." "2"
	fi
}

function runCLIScripts () {

	##FIXME can't have spaces in any of the params passed thru....
	getRHQCLIDetails
	setupJonServer

	if [[ "$BUNDLES_ENABLED" == "true" ]]; then
		#setup the bundles and the destinations
		if [[ "$INSTALL_BUNDLES" == "yes" ]]; then
			outputLog "Installing the bundles into the JON server..." "2"
			
			if [[ -f ${BUNDLE_COMMON_FILE} && -f ${BUNDLE_DEFAULT_FILE} && -f ${BUNDLE_APP_FILE} ]]; then
				setupBundleAndDestination ${BUNDLE_COMMON_FILE} $DEST_COMMON_SUFFIX
				setupBundle ${BUNDLE_DEFAULT_FILE}
				setupBundle ${BUNDLE_APP_FILE}
				
				setupBundle ${BUNDLE_HW_APP_FILE}
				
				if [[ "$NUM_JBOSS_TO_INSTALL" != 0 ]]; then
					#Passing in expression to find the creation of the last bundle
					waitFor "Creating bundle.*name=seam-dvdstore" "$JD_INSTALL_LOCATION/$JON_PRODUCT/logs/rhq-server-log4j.log" "45" "Waiting 45s, giving ant bundle time to be available for deployment."
			
					for (( A=1; A <= NUM_JBOSS_TO_INSTALL ; A++ ))
					do 
						PORT=$(( $A * 100 ))
						outputLog "working on port $PORT in iteration $A -- currently deployed [$JBOSS_SERVER_PORTS_PROVISIONED]"
						if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" =~ "$PORT" ]]; then
							outputLog "JBoss instance with port $PORT already provisioned, skipping..." "3"
						else
							installJBossServer $PORT
							
							#This may be modifying by the provisioning script, if we find that port is already installed
							CURRENT_PORT_BEING_INSTALLED=$PORT
							if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" == "" ]]; then
								outputLog "JBOSS_SERVER_PORTS_PROVISIONED is currently empty, adding first port"
								JBOSS_SERVER_PORTS_PROVISIONED=$CURRENT_PORT_BEING_INSTALLED
							else
								outputLog "JBOSS_SERVER_PORTS_PROVISIONED is currently $JBOSS_SERVER_PORTS_PROVISIONED"
								insertUniquePortInIncreasingOrder "$CURRENT_PORT_BEING_INSTALLED" "$JBOSS_SERVER_PORTS_PROVISIONED"
								JBOSS_SERVER_PORTS_PROVISIONED="\"$JBOSS_SERVER_PORTS_PROVISIONED $CURRENT_PORT_BEING_INSTALLED\""
							fi
							#TODO this line is confusing, is it meant to be here? doesn't it always reset this to empty?
							#TODO should it be update instead?
							resetVariableInVariableFile "JBOSS_SERVER_PORTS_PROVISIONED" "$JBOSS_SERVER_PORTS_PROVISIONED"
						fi
					done
				else
					outputLog "No JBoss servers will be installed from the bundles." "2"
				fi
			else
				outputLog "The bundle files do not exist, bundle upload and deployment failed." "4"
			fi
		fi
	fi
}

function installJBossServer () {
	
	PORT_SET=$1
	outputLog "Provisioning server with port $PORT_SET..." "2"
	newLine
	provision $PORT_SET	
}

#function - deployCLI (jonDirectory) - deploy the command line interface for JON
function deployCLI () {

	newLine
	outputLog "Deploying CLI tool" "2"
	newLine

	JON_DIRECTORY=$1

	CLI_ZIP_ARRAY=(`find $JON_DIRECTORY/$JON_RHQ_EAR/rhq-downloads/rhq-client/ -name "rhq*cli*.zip"`)
	CLI_ZIP=${CLI_ZIP_ARRAY[0]}
	
	CLI_TOP_FOLDER=`getZipTopFolder ${CLI_ZIP}`
	unzip -qo ${CLI_ZIP} -d $JON_TOOLS

	CLI_FOLDER=$JON_TOOLS/$CLI_TOP_FOLDER
	CLI_COMMAND=$CLI_FOLDER/$BIN/rhq-cli.sh

	#Modify the Java Home in the CLI tool
	replaceStringInFile "#RHQ_CLI_JAVA_HOME=\"/opt/java\"" "RHQ_CLI_JAVA_HOME=\"${JAVA_HOME}\"" "$CLI_FOLDER/$BIN/rhq-cli-env.sh"
}

#function - deployAgent (jonDirectory) - deploy the JON agent
function deployAgent () {

	JON_DIRECTORY=$1
	
	newLine
	mkdir -p $JON_TOOLS
	
	outputLog "Creating JON Agent in $JON_TOOLS" "2"
	newLine
	cp $JON_DIRECTORY/$JON_RHQ_EAR/rhq-downloads/rhq-agent/rhq*agent*.jar $JON_TOOLS
		
	AGENT_JAR_NAME=`find $JON_TOOLS/ -name "rhq*agent*.jar"`
	java -jar $AGENT_JAR_NAME --install=$JON_TOOLS/
	
	initialSetup
	
	deleteFile $JON_TOOLS/rhq*agent*.jar
	mv rhq-agent-update.log $JON_TOOLS/rhq-agent
}

#function - getAgentFolder () - creates variables for AGENT_FOLDER and AGENT_LOG_FOLDER
function getAgentFolder () {
	AGENT_FOLDER=$JON_TOOLS/$JON_AGENT_FOLDER
	AGENT_LOG_FOLDER=${AGENT_FOLDER}/logs/agent.log
}

function initialSetup () {
	
	newLine
	outputLog "Setting up JON agent" "2"
	newLine
	
	AGENT_JD_LOG=
	AGENT_CONF_FILE=$AGENT_FOLDER/$CONF/$AGENT_SILENT_CONFIG_FILE

	HOST_NAME=`hostname`
	#TODO: What is required to modify here?
	#Set auto configured to true
	uncommentAndReplaceInFile "rhq.agent.configuration-setup-flag\" value=\"false\"" "rhq.agent.configuration-setup-flag\" value=\"true\"" "$AGENT_CONF_FILE"
	
	#Replace all reference to 127.0.0.1 with `hostname` given that agent and server run on the same machine
	#FUTURE: if this were to deploy to multiple servers, we would need the jon server hostname to be used for some of the variables to replace
	replaceStringInFile "127.0.0.1" "${HOST_NAME}" "$AGENT_CONF_FILE"
		
	#Set the agent name to be `hostname`-agent
	uncommentAndReplaceInFile "my.hostname.com" "${HOST_NAME}-agent" "$AGENT_CONF_FILE"
	
	#Set the bind-address to be `hostname` to avoid the loopback message
	uncommentLineInFile "<entry key=\"rhq.communications.connector.bind-address" "$AGENT_CONF_FILE"
	uncommentLineInFile "<entry key=\"rhq.agent.server.bind-address" "$AGENT_CONF_FILE"
	uncommentLineInFile "<entry key=\"rhq.agent.agent-update.version-url" "$AGENT_CONF_FILE"
	uncommentLineInFile "<entry key=\"rhq.agent.agent-update.download-url" "$AGENT_CONF_FILE"
	uncommentLineInFile "<entry key=\"rhq.agent.plugins.availability-scan.period-secs" "$AGENT_CONF_FILE"
	
	#Set the different discovery periods to be faster in demo mode
	uncommentAndReplaceInFile "rhq.agent.plugins.server-discovery.period-secs\" value=\"900\"" "rhq.agent.plugins.server-discovery.period-secs\" value=\"30\"" "$AGENT_CONF_FILE"
	uncommentAndReplaceInFile "rhq.agent.plugins.drift-detection.period-secs\" value=\"60\"" "rhq.agent.plugins.drift-detection.period-secs\" value=\"30\"" "$AGENT_CONF_FILE"
	uncommentAndReplaceInFile "rhq.agent.plugins.configuration-discovery.period-secs\" value=\"3600\"" "rhq.agent.plugins.configuration-discovery.period-secs\" value=\"30\"" "$AGENT_CONF_FILE"
	
	if [[ -d "$AGENT_FOLDER/logs" ]]; then
		mkdir $AGENT_FOLDER/logs
		AGENT_JD_LOG=$AGENT_FOLDER/logs/jd-agent-setup.log
		touch $AGENT_JD_LOG
	fi

	chown -R ${JBOSS_OS_USER}:${JBOSS_OS_USER} $AGENT_FOLDER
	
	manageJonAgent $AGENT_FOLDER start
	newLine
	
	sleep 10

}

#function - manageJonAgent (agentFolder, command) - start the agent using the wrapper script
function manageJonAgent () {
	
	AGENT_FOLDER=$1
	COMMAND=$2
	
	CHECK_AGENT=`$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh status`
	
	#If the agent is running but we are just starting up the demo, restart it (as when the PC goes into suspend, the agent isn't happy)
	if [[ "$CHECK_AGENT" =~ "is running" && "$COMMAND" == "start" ]]; then
		outputLog "Even though the agent was started, we will restart it to ensure it's running properly." "2" 
		$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh restart
	else
		$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh $COMMAND
	fi 
	
}

function deployCLIAntTestTool () {
	JON_DIRECTORY=$1
	mkdir -p $JON_TOOLS
	
	CLI_TOP_FOLDER=`getZipTopFolder $JON_DIRECTORY/$JON_RHQ_EAR/rhq-downloads/bundle-deployer/rhq*bundle*deployer*.zip`
	unzip -qo $JON_DIRECTORY/$JON_RHQ_EAR/rhq-downloads/bundle-deployer/rhq*bundle*deployer*.zip -d $JON_TOOLS
	
}
#function - checkEmbeddedAgent () - checks if the embedded agent is set to true or false 
function checkEmbeddedAgent () {
		EMBEDDED_AGENT_ACTIVE=`grep "embedded-agent.enabled" $JD_INSTALL_LOCATION/$JON_PRODUCT/$BIN/$JON_SILENT_CONFIG_FILE`
		EMBEDDED_AGENT_ACTIVE=${EMBEDDED_AGENT_ACTIVE#*=}
}