#Load user set variables
. $WORKSPACE_WD/cli/cli-user-settings.sh

#function - cliCommandsMenu (cliScriptFolder) - menu to show all CLI scripts
function cliCommandsMenu () {

	CLI_SCRIPT_FOLDER=$1
	PARAMS_REQ=
	PARAMS_OPT=

	while true;
	do
		menuHeader "CLI Scripts"
		COUNT=1
		
		if [[ "$WORKSPACE_WD" != "" ]]; then
			CLI_DIR=${WORKSPACE_WD}/cli	
		else
			CURRENT_DIR=`pwd`
			CLI_DIR=${WORKSPACE_WD}/cli
		fi
		
		for f in `find ${CLI_DIR} -name "*.js"`
		do
			PARAMS_STRING=
			#Read the required parameters
			PARAMS_REQ=`grep "//Params Required: " $f`
			PARAMS_REQ=${PARAMS_REQ#*\/\/Params Required: }
			for PARAM in $PARAMS_REQ
			do
				PARAMS_STRING="${PARAMS_STRING} ${PARAM}"
			done

			#Read the optional parameters
			PARAMS_OPT=`grep "//Params Optional: " $f`
			PARAMS_OPT=${PARAMS_OPT#*\/\/Params Optional: }
			for PARAM in $PARAMS_OPT
			do
				PARAMS_STRING="${PARAMS_STRING} [${PARAM}]"
			done

			echo "$COUNT. $f"
			USAGE=`grep "//Usage: " $f`
			DESC=`grep "//Description: " $f`
			echo "${USAGE#*\/\/} ${PARAMS_STRING}"
			echo "${DESC#*\/\/}"
			CLI_CMD_ARRAY[$COUNT]=$f
			COUNT=$(( $COUNT + 1 ))
			newLine
		done

		menuFooter
		option=`takeInputOption`
		newLine

		if [[ "$option" == "b" || "$option" == "q" ]]; then
			basicMenuOptions $option
		else
			if [[ "$option" != +([0-9]) || "$option" -lt "1" || "$option" -gt "$COUNT" ]]; then
				echo "Invalid input, please enter a value between 1 and $COUNT"
			else
				PARAMS_STRING=

				#Check for required params
				PARAMS_REQ=`grep "//Params Required: " ${CLI_CMD_ARRAY[$option]}`
				PARAMS_REQ=${PARAMS_REQ#*\/\/Params Required: }

				#Check for optional params				
				PARAMS_OPT=`grep "//Params Optional: " ${CLI_CMD_ARRAY[$option]}`
				PARAMS_OPT=${PARAMS_OPT#*\/\/Params Optional: }
			
				#Read the required parameters
				for PARAM in $PARAMS_REQ
				do
					echo "Input required $PARAM:"
					read INPUT_PARAM
					PARAMS_STRING="${PARAMS_STRING} ${INPUT_PARAM}"
				done

				#Read the optional parameters
				for PARAM in $PARAMS_OPT
				do
					echo "Input optional $PARAM:"
					read INPUT_PARAM
					PARAMS_STRING="${PARAMS_STRING} ${INPUT_PARAM}"
				done
				newLine
			
				#Call the JS script with the appropiate params
				if [[ "$CLI_COMMAND" == "" ]]; then
					getRHQCLIDetails
				fi
 				$CLI_COMMAND -f ${CLI_CMD_ARRAY[$option]} ${PARAMS_STRING}
			fi
		fi

		pause
	done
}

#function - getRHQCLIDetails () - sets up the CLI required variables
function getRHQCLIDetails () {

	export RHQ_CLI_JAVA_HOME=$JAVA_HOME
	RHQ_OPTS="-s $JON_HOST -u $JON_USER -t $JON_PORT -p $JON_PWD"

	if [[ "$CLI_CLIENT" == "" ]]; then
		CLI_CLIENT=$JON_TOOLS
	fi

	if [[ -d $CLI_CLIENT ]]; then
		CLI_COMMAND=`find $CLI_CLIENT -name "rhq*cli.sh"`
	fi
}