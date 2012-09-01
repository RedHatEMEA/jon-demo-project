#Set these variables to connect to your JON server
JON_HOST=127.0.0.1
JON_USER=rhqadmin
JON_PWD=rhqadmin
JON_PORT=7080

#Set this variable to point to the directory of your CLI client
#Ensure that the user calling this script has access to the directory below
#CLI_CLIENT=/opt/${JD_FOLDER}/jon-tools/
CLI_CLIENT=/opt/jon-demo/jon-tools/


#function - cliCommandsMenu (cliScriptFolder) - menu to show all CLI scripts
function cliCommandsMenu () {

	CLI_SCRIPT_FOLDER=$1
	PARAMS_REQ=
	PARAMS_OPT=

	t=`pwd`
	outputLog $t "2" "y" "n"

	while true;
	do
		menuHeader "CLI Scripts"
		COUNT=1

		CURRENT_DIR=`pwd`
		CURRENT_DIR=${CURRENT_DIR%/*}
		CLI_DIR=${CURRENT_DIR}/cli
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

			outputLog "$COUNT. $f" "2" "y" "n"
			USAGE=`grep "//Usage: " $f`
			DESC=`grep "//Description: " $f`
			outputLog "${USAGE#*\/\/} ${PARAMS_STRING}" "2" "y" "n"
			outputLog "${DESC#*\/\/}" "2" "y" "n"
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
				outputLog "Invalid input, please enter a value between 1 and $COUNT" "4" "y" "n"
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
					takeInput "Input required $PARAM:"
					read INPUT_PARAM
					PARAMS_STRING="${PARAMS_STRING} ${INPUT_PARAM}"
				done

				#Read the optional parameters
				for PARAM in $PARAMS_OPT
				do
					takeInput "Input optional $PARAM:"
					read INPUT_PARAM
					PARAMS_STRING="${PARAMS_STRING} ${INPUT_PARAM}"
				done
				newLine
			
				#Call the JS script with the appropiate params
				getRHQCLIDetails
 				$CLI_COMMAND -f ${CLI_CMD_ARRAY[$option]} ${PARAMS_STRING}
			fi
		fi

		pause
	done
}
