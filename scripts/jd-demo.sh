#function - jonDemoMenu (installLocation) - the menu options for the Jon Demo
function jonDemoMenu () {
	INSTALL_LOCATION=$1
	
	JD_BASE=`find $INSTALL_LOCATION -name "$JD_FOLDER" 2>&1`
	if [[ -d $JD_BASE && "$JON_DEMO_INSTALLED" == "y" ]]; then
		JD_JON_DIRECTORY=`find $JD_INSTALL_LOCATION -name "jon-server*"`
		#outputLog JD_JON_DIRECTORY $JD_JON_DIRECTORY -- INSTALL_LOCATION $JD_INSTALL_LOCATION -- JD_FOLDER $JD_FOLDER
		JON_SCRIPT=$JD_JON_DIRECTORY/$BIN/$JON_STARTUP_SCRIPT
		
		SERVER_STATUS=`checkServerStatus $JON_SCRIPT`
		
		case "$SERVER_STATUS" in
			0)
				echo SRD. Start Jon Demo
				DEMO_STATUS="0"
				;;
			1)
				echo SOD. Stop Jon Demo
				DEMO_STATUS="1"
				;;
		esac	
		
		newLine
		
		#TODO move into separate functions
		NEXT_SERVER="100"
		if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" != "" ]]; then
			if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" =~ " " ]]; then
				LAST_SERVER=${JBOSS_SERVER_PORTS_PROVISIONED##* }
			else
				LAST_SERVER=$JBOSS_SERVER_PORTS_PROVISIONED
			fi
			outputLog "The last server found is: [$LAST_SERVER]" "1"
			NEXT_SERVER=$(( LAST_SERVER + 100 ))
		fi		
		echo "DJ. Deploy next JBoss server [Port: $(( 8080 + NEXT_SERVER ))]"
				
		LAST_SERVER=""
		if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" != "" ]]; then
			if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" =~ " " ]]; then
				LAST_SERVER=${JBOSS_SERVER_PORTS_PROVISIONED##* }
			else
				LAST_SERVER=$JBOSS_SERVER_PORTS_PROVISIONED
			fi
			outputLog "The last server found is: [$LAST_SERVER]" "1"
			echo "UJ. Undeploy last JBoss server [Port: $(( 8080 + LAST_SERVER ))]"
		else
			outputLog "No JBoss servers to unprovision..." "1" "y" "n"
		fi
		
		newLine
		echo DD. Delete Jon Demo
	else
		echo ID. Install Jon Demo
		if [[ -d $JD_BASE && ( "$JON_DEMO_INSTALLED" == "n" || "$JON_DEMO_INSTALLED" == "" ) ]]; then
			outputLog "[$JD_BASE] already exists, you might want to check it's contents..." "3"
		fi
	fi
	newLine
}

#function - jonDemoOptions (option) - handles the menu options from the jon demo menu
function jonDemoOptions () {
	option=$1
	JD_INSTALL_LOCATION=$2
	
	case $option in	
			"dd") 
				jdDeleteDemo $JD_INSTALL_LOCATION
				;;

			"id") 	
				jdInstallDemo $JD_INSTALL_LOCATION
				;;

			"srd")  
				if [[ "$DEMO_STATUS" == "0" ]]; then
					jdStartDemo $JD_INSTALL_LOCATION
				else
					outputLog "The JON demo is already started, ignoring start command." "2"
				fi
				;;

			"sod") 
				if [[ "$DEMO_STATUS" == "1" ]]; then
					jdStopDemo $JD_INSTALL_LOCATION
				else
					outputLog "The JON demo is already stopped, ignoring stop command." "2"
				fi
				;;

			"dj")
				deployJBoss $NEXT_SERVER
				;;

			"uj")
				undeployJBoss $LAST_SERVER
				;;

			"c")
				cliCommandsMenu "${WORKSPACE_WD}/cli/"
				;;
	esac
}

 #function - jdDeleteDemo (installLocation) - delete everything relating to the jon demo
function jdDeleteDemo () {
	
	JD_INSTALL_LOCATION=$1
	
	if [[ "$JON_DEMO_INSTALLED" == "" ]]; then
		outputLog "JON demo not installed, deleting is not an option..." "3"
	else
		
		getStartTime
	
		#Delete provisioned JBoss servers
		if [[ "${JBOSS_SERVER_PORTS_PROVISIONED}" != "" ]]; then
			outputLog "Need to shut down and unprovision the JBoss servers with ports $JBOSS_SERVER_PORTS_PROVISIONED" "2"
			JBOSS_SERVER_PORTS_ARRAY=($( echo $JBOSS_SERVER_PORTS_PROVISIONED ))
			#declare -a JBOSS_SERVER_PORTS_ARRAY=$JBOSS_SERVER_PORTS_PROVISIONED
			
			ARRAY_LENGTH=${#JBOSS_SERVER_PORTS_ARRAY[@]}
	
			#Unprovision the servers in reverse order to leave serverPort 100 till the end
			for (( A=$((ARRAY_LENGTH - 1)); A >= 0 ; A-- ));
			do 
				SERVER_PORT=${JBOSS_SERVER_PORTS_ARRAY[A]}
				outputLog "Unprovisioning JBoss server with port $SERVER_PORT" "2"
				unprovision $SERVER_PORT
				rm -f $INIT_D/jboss-${JBOSS_BASE_CONF}${SERVER_PORT}
			done
		else
			outputLog "No JBoss servers to shutdown, moving on..." "2"
		fi
		
		newLine
		#Stop all Jon demo components
		jdStopDemo $JD_INSTALL_LOCATION
	
		#Delete the postgres db used by JON
		deletePostgresDB $POSTGRES_JON_DB  #$DB_TO_DELETE
		deleteFolder $JD_INSTALL_LOCATION
		
		##Empty out script set variables
		SERVER_PORT=""
		resetVariableInFile "JON_DEMO_INSTALLED"
		resetVariableInFile "JON_MAJOR_VERSION"
		resetVariableInFile "JON_MINOR_VERSION"
		resetVariableInFile "JON_REVISION_VERSION"
		resetVariableInFile "JON_PRODUCT_FULL_PATH"
		resetVariableInFile "JBOSS_SERVER_PORTS_PROVISIONED"
		resetVariableInFile "NUM_JBOSS_TO_INSTALL"
		resetVariableInFile "POSTGRES_JON_DB"
		
			
		newLine
		outputLog "Deleted JON demo from $JD_INSTALL_LOCATION" "2"
		newLine
		
		getEndTime
		getTimeTaken
		
	fi
	
}

#function - getStartTime () - gets the start time, stores it and outputs it
function getStartTime () {	
	START_DATE=`date`
	outputLog "Started at $START_DATE" "2"
	START_DATE_MS=`date -d "$START_DATE" +"%s"`
	newLine
}

#function - getEndTime () - gets the end time, stores it and outputs it
function getEndTime () {
	END_DATE=`date`
	END_DATE_MS=`date -d "$END_DATE" +"%s"`
	outputLog "Completed at $END_DATE" "2"
}

#function - getTimeTaken (updateVariable) - figures out the time taken from the start/end time
function getTimeTaken () {
	UPDATE_VARIABLE=$1
	
	TIME_DIFF=`expr ${END_DATE_MS} - ${START_DATE_MS}`
	
	MINS_SECS_TEXT=`getTimeInMinsSecs $TIME_DIFF`
	
	outputLog "Total time taken was ${TIME_DIFF} seconds or $MINS_SECS_TEXT" "2"
	
	if [[ "$UPDATE_VARIABLE" != "" ]]; then
		updateVariablesFile "TIME_TAKEN_PREVIOUSLY=" "TIME_TAKEN_PREVIOUSLY=${TIME_DIFF}"
	fi
}

function getTimeInMinsSecs () {
	TIME_DIFF=$1
	
	MINS=`expr ${TIME_DIFF} / 60`
	SECS=`expr ${TIME_DIFF} % 60`
	
	if [ $SECS -lt 10 ]; then
		SECS="0${SECS}"
	fi
	 
	if [ $MINS -lt 10 ]; then
		MINS="0${MINS}"
	elif [[ $MINS == 0 ]]; then
		MINS="00"
	fi
	
	echo "${MINS}:${SECS} mins"
}

#function - jdInstallDemo (installLocation) - install the entire jon demo
function jdInstallDemo () {
	
	if [[ "$JON_DEMO_INSTALLED" == "y" ]]; then
		outputLog "JON demo is already installed, installing is not an option..." "3"
	else
				
		JD_INSTALL_LOCATION=$1
	
		newLine
		outputLog "Installing jon server demo..." "2"
		
		if [[ "${TIME_TAKEN_PREVIOUSLY}" != "" ]]; then
			MINS_SECS_TEXT=`getTimeInMinsSecs $TIME_TAKEN_PREVIOUSLY`
			outputLog "Installing has previously taken ${TIME_TAKEN_PREVIOUSLY} second(s) or $MINS_SECS_TEXT" "2"
		fi
		
		getStartTime
		
		checkForPostgresOnSystem
		checkPostgresInstall	
		if [[ "$POSTGRES_INSTALLED" == "n" ]]; then 
			getPostgresRepo
		fi
		
		newLine
				
		if [[ "$BUNDLES_ENABLED" == "true" ]]; then
			takeYesNoInput "Would you like to install the bundles (yes/no): [default yes]\n\tB. Back to Main Menu." "yes" "1"
			INSTALL_BUNDLES=$ANSWER
			outputLog "Install bundles set to $INSTALL_BUNDLES"
			
			#If non-numeric or not in the correct number range, then invalid else extract version to add to repo base
			if [[ "$INSTALL_BUNDLES" == "b" || "$INSTALL_BUNDLES" == "B" ]]; then
				deletePostgresDB "$POSTGRES_JON_DB"
				resetVariableInFile "POSTGRES_JON_DB"
				INSTALL_BUNDLES=""
				loadVariables
				mainMenu
			fi
			
			if [[ "$INSTALL_BUNDLES" == "yes" ]]; then	
				
				if [[ "$BUNDLES_CREATED" != "" ]]; then
					takeYesNoInput "The bundles already exist, do you want to re-build them? (yes/no): [default no]\n\tB. Back to Main Menu." "no" "1"
					REBUILD_BUNDLES=$ANSWER
					outputLog "Re-building of bundles set to $REBUILD_BUNDLES"
				fi
				
				while true;
				do
					takeInput "If you want to install any JBoss servers - via the bundles - specify how many: [default 0]\n\tB. Back to Main Menu."
					read NUM_JBOSS_TO_INSTALL
					
					#If non-numeric or not in the correct number range, then invalid else extract version to add to repo base
					if [[ "$NUM_JBOSS_TO_INSTALL" == "b" || "$NUM_JBOSS_TO_INSTALL" == "B" ]]; then
						deletePostgresDB "$POSTGRES_JON_DB"
						resetVariableInFile "POSTGRES_JON_DB"
						INSTALL_BUNDLES=""
						loadVariables
						mainMenu
					elif [[ "$NUM_JBOSS_TO_INSTALL" == "" ]]; then
						NUM_JBOSS_TO_INSTALL=0
						break
					elif [[ "$NUM_JBOSS_TO_INSTALL" != +([0-9]) || "$NUM_JBOSS_TO_INSTALL" -lt "0" ]]; then
						outputLog "Invalid input, must be between 0 and 10" "4"
						newLine
					elif [[ "$NUM_JBOSS_TO_INSTALL" -gt "10" ]]; then
						outputLog "Why are you trying to install more then 10 servers locally? It'll slow performance of the demo... Setting the value to 9, you can always install more via the menus if you insist." "3"
						break
					else
						break
					fi
				done			
				
				updateVariablesFile "NUM_JBOSS_TO_INSTALL=" "NUM_JBOSS_TO_INSTALL=$NUM_JBOSS_TO_INSTALL"

			fi
		fi
	
		newLine
		chooseProduct "jon"
	
		if [[ "$POSTGRES_INSTALLED" == "n" ]]; then 
			installPostgres
			deletePostgresTmpFiles
		fi
		
		newLine
				
		createPostgresUser
		
		#Create the bundles if enabled
		if [[ "$INSTALL_BUNDLES" == "yes" ]]; then
			
			#If they dont already exist 
			if [[ "$BUNDLES_CREATED" == "" || "$REBUILD_BUNDLES" == "yes" ]]; then
				#then create the bundles
				createBundles
			else
				#others, inform user they already exist
				outputLog "The bundles already existing, not rebuilding them..." "2"
			fi
		fi
		extractPackage $JON_PRODUCT_FULL_PATH $JD_INSTALL_LOCATION
		
		getProductVersionDetails
	
		extractJONPlugins
		silentlyInstallJon
		
		newLine
		
		getEndTime
		getTimeTaken "y"
		
		newLine
		
	fi
	
}

#function - jdStartDemo (installLocation) - start up all the components of the jon demo
function jdStartDemo () {
	
	if [[ "$JON_DEMO_INSTALLED" == "" ]]; then
		outputLog "JON demo not installed, starting the demo is not an option..." "3"
	else
		
		JD_INSTALL_LOCATION=$1
			
		newLine
		outputLog "Starting up jon server demo..." "2"
		
		newLine
		manageJonAgent $AGENT_FOLDER start
		manageServer jon-server start $JD_INSTALL_LOCATION
		newLine
		
		outputLog "Going to start JBoss servers, once the JON server and agent are ready..." "2"
		
		manageJBossDemoServers start
		
		newLine
	
	fi

}

#function - jdStopDemo (installLocation) - stop all the components of the jon demo
function jdStopDemo () {
	
	if [[ "$JON_DEMO_INSTALLED" == "" ]]; then
		outputLog "JON demo not installed, stopping is not an option..." "3"
	else
			
		JD_INSTALL_LOCATION=$1
	
		newLine
		outputLog "Stopping jon server demo..." "2"
				
		if [[ "${JBOSS_SERVER_PORTS_PROVISIONED}" != "" ]]; then
			#If the agent is stopped, start it up to be able to manage any deployed JBoss servers
			getAgentFolder
			
			if [ -f "$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh" ]; then
				AGENT_STATUS=`$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh status`
				if [[ "$AGENT_STATUS" =~ "NOT running" ]]; then
					manageJonAgent "$AGENT_FOLDER" "start"
				fi
			fi
			
			getRHQCLIDetails
			executeAgentCommand discovery
			executeAgentCommand availability
			manageJBossDemoServers shutdown
		fi
		
		manageServer "jon-server" "stop" "$JD_INSTALL_LOCATION"
		newLine
	
		manageJonAgent $AGENT_FOLDER stop
		
		newLine
		
	fi
}

#function - deployJBoss () - will deploy a JBoss server with the next port number 
function deployJBoss () {
	
	NEXT_SERVER=$1
	
	outputLog "The next server to be installed will have port set [$NEXT_SERVER]" "2"
	#TODO this is copied from jon.sh runCliscripts, should split it out to a separate function
	installJBossServer $NEXT_SERVER
								
	#This may be modifying by the provisioning script, if we find that port is already installed otherwise just set it to the original calculated value
	if [[ "$CURRENT_PORT_BEING_INSTALLED" == "" ]]; then
		 CURRENT_PORT_BEING_INSTALLED=$NEXT_SERVER
	fi
		
	if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" == "" ]]; then
		outputLog "JBOSS_SERVER_PORTS_PROVISIONED is currently empty, adding first port"
		JBOSS_SERVER_PORTS_PROVISIONED=$CURRENT_PORT_BEING_INSTALLED
	else
		outputLog "JBOSS_SERVER_PORTS_PROVISIONED is currently $JBOSS_SERVER_PORTS_PROVISIONED"
		JBOSS_SERVER_PORTS_PROVISIONED="\"$JBOSS_SERVER_PORTS_PROVISIONED $CURRENT_PORT_BEING_INSTALLED\""
	fi

	updateVariablesFile "JBOSS_SERVER_PORTS_PROVISIONED" "JBOSS_SERVER_PORTS_PROVISIONED=$JBOSS_SERVER_PORTS_PROVISIONED"
}

#function - undeployJBoss () - will undeploy the last deployed JBoss server 
function undeployJBoss () {
	
	LAST_SERVER=$1
	
	#Avoid attempting to undeploy if no servers are available 
	if [[ "$LAST_SERVER" != "" ]]; then
	
		outputLog "The last server to be installed had port set [$LAST_SERVER]" "2"
		#TODO this is copied from jon.sh runCliscripts, should split it out to a separate function
		unprovision $LAST_SERVER
									
		#This may be modifying by the provisioning script, if we find that port is already installed
		CURRENT_PORT_BEING_UNPROVISIONED=$LAST_SERVER
		if [[ "$JBOSS_SERVER_PORTS_PROVISIONED" == "$CURRENT_PORT_BEING_UNPROVISIONED" ]]; then
			outputLog "JBOSS_SERVER_PORTS_PROVISIONED only has $CURRENT_PORT_BEING_UNPROVISIONED, empty after this..."
			JBOSS_SERVER_PORTS_PROVISIONED=""
		elif [[ "$JBOSS_SERVER_PORTS_PROVISIONED" != "" ]]; then
			outputLog "JBOSS_SERVER_PORTS_PROVISIONED is $JBOSS_SERVER_PORTS_PROVISIONED, removing $CURRENT_PORT_BEING_UNPROVISIONED"
			JBOSS_SERVER_PORTS_PROVISIONED="\"${JBOSS_SERVER_PORTS_PROVISIONED%* $CURRENT_PORT_BEING_UNPROVISIONED}\""
		else
			outputLog "We shouldn't be trying to unprovision is JBOSS_SERVER_PORTS_PROVISIONED is already empty... ignoring."
		fi
	
		updateVariablesFile "JBOSS_SERVER_PORTS_PROVISIONED" "JBOSS_SERVER_PORTS_PROVISIONED=$JBOSS_SERVER_PORTS_PROVISIONED"
	fi
}