#Set DEBUG=1 if you want extra output to try to figure out any problems.
#DEBUG=1
##Definitions for LOG_LEVEL##
##1 == DEBUG
##2 == INFO
##3 == WARNING
##4 == ERROR
##*/0 == ALL

#Pick up the log level from the demo-config.properties file or else set it to 2 by default
if [[ "$DEMO_LOG_LEVEL" == "" ]]; then 
	LOG_LEVEL=2
else
	LOG_LEVEL=$DEMO_LOG_LEVEL
fi

#function - outputLog (message, logLevelToDisplay, newLine, displayInfo) - that outputs debug information when DEBUG variable is set to 1
function outputLog () {
	
	MESSAGE=$1
	LOG_TO_DISPLAY=$2
	NEW_LINE=$3
	DISPLAY_INFO=$4
	
	DEFAULT_COLOR="\033[39m"
	ERROR_COLOR="\033[31m"
	WARNING_COLOR="\033[33m"
	
	START_COLOR=""
	END_COLOR=""
	
	if [[ "$LOG_TO_DISPLAY" == "" || "$LOG_TO_DISPLAY" -gt 4 ]]; then
		LOG_TO_DISPLAY=1
	fi
	
	if [[ $LOG_LEVEL -le $LOG_TO_DISPLAY ]]; then
		
		case "$LOG_TO_DISPLAY" in
		"1")
			LOG_TEXT="DEBUG"
			;;
		"2")
			LOG_TEXT="INFO"
			;;	
		"3")	
			LOG_TEXT="WARNING" 
			START_COLOR=$WARNING_COLOR
			END_COLOR=$DEFAULT_COLOR
			;;
		"4")
			LOG_TEXT="ERROR"
			START_COLOR=$ERROR_COLOR 
			END_COLOR=$DEFAULT_COLOR
			;;
		*)
			#By default, if no log level is passed or an incorrect value, it'll be set to debug by default
			LOG_TEXT="DEBUG"
			;;
			
		esac
			
		TEXT=""
		NOW=`date +"%F - %T" 2>&1`
		
		##Sometimes, date is not found as a command for some reason, so avoiding it's error
		if [[ "$NOW" =~ "command not found" ]]; then
			NOW=""
		fi
		
		if [[ "$DISPLAY_INFO" == "y" || "$DISPLAY_INFO" == "" ]]; then
			TEXT="${NOW} [${LOG_TEXT}] "
		fi
		
		TEXT="${START_COLOR}${TEXT}${MESSAGE}${END_COLOR}"
			
		if [[ "$NEW_LINE" == "y" || "$NEW_LINE" == "" ]]; then
			TEXT="${TEXT}\n"
		fi
							
		echo -ne "$TEXT"
	fi
}

function testFunction () {

	outputLog "in testFunction"
	
	#findServer 100
	#echo $SERVER_ID
	#manageServerProfile 10531 start

	#t=`hostname`
	#setupJonServer

	manageJBossDemoServers "start" "100 300"
	
	#try with  server start, shutdown, and try start/stop.. 4 combination i believe
		
	#getAgentFolder
	#getRHQCLIDetails
	#setGroupDetails
	
	#installJBossServer 100
	#unprovision 100
	
	#runCLIScripts
	
}