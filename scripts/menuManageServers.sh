#function - manageServersMenu () - display menu to show the manage servers options
function manageServersMenu () {
	
	newLine
	echo "***Manage Servers***"
	newLine

	JON_DIRECTORY=`find /opt -name "jon-server*"`
	if [[ "$JON_DEMO_INSTALLED" == "y" ]]; then
		
		echo "*JON Server"
		
		JON_SCRIPT=$JON_DIRECTORY/$BIN/$JON_STARTUP_SCRIPT
		SERVER_STATUS=`checkServerStatus $JON_SCRIPT`
		newLine
		case "$SERVER_STATUS" in
			0)
				echo "  SJ. Start Jon Server"
				;;
			1)
				echo "  PJ. Stop Jon Server"
				;;
		esac
		newLine
		
		CHECK_AGENT=`$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh status`
		echo "*JON Agent"
		
		#If the agent is running, offer shutdown and restart
		if [[ "$CHECK_AGENT" =~ "is running" ]]; then
			echo "  RA. Restart Jon Agent"
			echo "  PA. Stop Jon Agent"
		else
			echo "  SA. Start Jon Agent"
			$AGENT_FOLDER/$BIN/rhq-agent-wrapper.sh $COMMAND
		fi
		
		newLine
		echo "*Postgres Server"
		
		if [ -f $POSTGRES_SERVICE_FILE ]; then
			SERVICE_STATUS=`service $POSTGRES_SERVICE_NAME status 2>/dev/null`
			case "$SERVICE_STATUS" in
			*inactive*)
				echo "  SP. Start Postgres Service"
				;;
			*active*)
				echo "  PP. Stop Postgres Service"
				;;
			esac
		fi
		
		if [[ "$NUM_JBOSS_TO_INSTALL" -gt "0" && "$JBOSS_SERVER_PORTS_PROVISIONED" != "" ]]; then
			newLine
			echo "*JBoss Servers"
			
			for (( A=1; A <= NUM_JBOSS_TO_INSTALL ; A++ ))
			do 
				local PORT=$(( $A * 100 + 8080 ))
				JB_SERVER_STATUS=`curl http://localhost:${PORT} 2>/dev/null`
				
				if [[ "$JB_SERVER_STATUS" == "" ]]; then
					echo "  sjb${A}. Start JBoss Server (port: $PORT)"
				elif [[ "$JB_SERVER_STATUS" =~ "Welcome to JBoss EAP" ]]; then
					echo "  pjb${A}. Stop JBoss Server (port: $PORT)"
				else
					outputLog "JBoss status is not recognised, check server logs." "4"
				fi
			done
			
			echo "  sajb. Start All JBoss Servers"
			echo "  pajb. Stop All JBoss Servers"
		fi
	fi
}

#Handles the options for the manageServers menu
function manageServersOptions () {
	option=$1
		
	case $option in				
			"pp") 
				stopPostgresService
				;;

			"sp") 
				startPostgresService
				;;
			
			"sj")
				manageServer jon-server start $JD_INSTALL_LOCATION
				;;

			"pj")
				manageServer jon-server stop $JD_INSTALL_LOCATION
				;;
							
			"sa") 
				manageJonAgent $AGENT_FOLDER start
				;;

			"ra") 
				manageJonAgent $AGENT_FOLDER restart
				;;
			
			"pa")
				manageJonAgent $AGENT_FOLDER stop
				;;
				
			"sajb" )
				manageJBossDemoServers "start" 
				;;
				
			"pajb" )
				manageJBossDemoServers "shutdown" 
				;;
		esac
		
		if [[ "$option" =~ "pjb" ]]; then
			local PORT_NUM=${option:3:1}
			local PORT=$(( $PORT_NUM * 100 ))
		
			findServer $PORT
			if [[ "${SERVER_ID}x" != "x" ]]; then
				manageServerProfile $SERVER_ID "shutdown"
			fi
			
		elif [[ "$option" =~ "sjb" ]]; then
			local PORT_NUM=${option:3:1}
			local PORT=$(( $PORT_NUM * 100 ))
		
			findServer $PORT
			if [[ "${SERVER_ID}x" != "x" ]]; then
				manageServerProfile $SERVER_ID "start"
			fi
			
		fi
}