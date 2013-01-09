#function - startPostgresService () -  used to start postgreSQL service
function startPostgresService () {
	outputLog "Starting service..." "2"
	service $POSTGRES_SERVICE_NAME start
}

#function - stopPostgresService () -  used to start postgreSQL service
function stopPostgresService () {
	outputLog "Stopping service..." "2"
	service $POSTGRES_SERVICE_NAME stop
}

#function - checkForPostgresOnSystem () - Checks to see if a postgresql instance is installed locally
function checkForPostgresOnSystem () {
	
	if [[ "$POSTGRES_INSTALLED" != "y" ]]; then 
		#If postgresql exists in /etc/init.d, then the service exists
		POSTGRES_SERVICE_FILE=`find $INIT_D/ -name "postgresql*"`
		POSTGRES_SERVICE_NAME=${POSTGRES_SERVICE_FILE#*$INIT_D/}
		
		if [[ "$POSTGRES_SERVICE_FILE" == "" ]]; then
			outputLog "Postgres service file is not found on the file system." "1"
			
			SYSTEMCTL_AVAILABLE=`systemctl 2>&1`
			
			if [[ "$SYSTEMCTL_AVAILABLE" =~ "command not found" ]]; then
				outputLog "Working on RHEL with no systemctl, moving on" "1"
			else
				CHECK_SYSTEM=`systemctl | grep postgres`
				CHECK_SYSTEM=${CHECK_SYSTEM%% *}	##Remove anything after the space, if there's an error
	
				local CHECK_INSTALL=`find /etc/systemd/system/multi-user.target.wants -name "$POSTGRES_SERVICE_NAME"`
	
				if [[ "$CHECK_SYSTEM" != "" && "$CHECK_INSTALL" != "" ]]; then
					POSTGRES_SERVICE_NAME=${CHECK_SYSTEM%.service*}
					outputLog "Service name set to $POSTGRES_SERVICE_NAME"
									
					#Set the postgres service file 
					POSTGRES_SERVICE_FILE=$INIT_D/$POSTGRES_SERVICE_NAME
				else
					outputLog "Postgres is not found in the system check." "1"
					if [[ "$POSTGRES_INSTALLED" != "y" ]]; then 
						POSTGRES_INSTALLED="n"
						resetVariableInVariableFile "POSTGRES_INSTALLED" "$POSTGRES_INSTALLED"
						loadVariables
					fi
				fi
			fi
		fi
			
		if [[ "$POSTGRES_SERVICE_NAME" != "" ]]; then

			outputLog "POSTGRES_SERVICE_FILE is $POSTGRES_SERVICE_FILE"
			outputLog "POSTGRES_SERVICE_NAME is $POSTGRES_SERVICE_NAME"
			
			resetVariableInVariableFile "POSTGRES_SERVICE_NAME" "${POSTGRES_SERVICE_NAME}"
			resetVariableInVariableFile "POSTGRES_INSTALLED" "y"
			
			if [[ "$POSTGRES_SERVICE_NAME" != "postgresql" ]]; then 
				VERSION=${POSTGRES_SERVICE_NAME#*-}
				outputLog "VERSION: $VERSION"
				MAJOR_VERSION=${VERSION:0:1}
				MINOR_VERSION=${VERSION:2:1}
				outputLog "MAJOR [$MAJOR_VERSION] -- MINOR [$MINOR_VERSION]"
				
				resetVariableInVariableFile "POSTGRES_MAJOR_VERSION" "${MAJOR_VERSION}"
				resetVariableInVariableFile "POSTGRES_MINOR_VERSION" "${MINOR_VERSION}"
			else
				outputLog "Version of postgresql not found in service name, ignoring version numbers"
			fi
			loadVariables
		fi	
	else
		outputLog "POSTGRES_INSTALLED is set to 'y'"		
	fi
}

#function - checkPostgresInstall () - check if postgres is installed, running, etc
function checkPostgresInstall () {

	if [[ "$POSTGRES_INSTALLED" == "y" ]]; then

		newLine
		status=`service $POSTGRES_SERVICE_NAME status`

		case "$status" in
		*inactive* | *stopped*)
			startPostgresService
			;;
		*active* | *running*)
			outputLog "PostgreSQL is installed, and running..." "2"
			;;
		*)
			outputLog "Somehow, none of the scenarios apply..." "3"
			;;
		esac
	fi
	
}

#function - getPostgresRepo () - get the postgres repo url using the distro details and the user's choice of postgres version
function getPostgresRepo () {

	newLine
	DISTRO_VERSION=
	DISTRO_NICK=
	DISTRO=
	ARCH=`arch`
	VERSION=

	getDistroDetails			#sets DISTRO_VERSION & DISTRO & ARCH & DISTRO_NICK
	outputLog "DISTRO_VERSION is $DISTRO_VERSION --  DISTRO is $DISTRO -- ARCH is $ARCH -- DISTRO_NICK is $DISTRO_NICK" "1"

	REPO_PACKAGES_FILE="repopackages.php"
	BASE_URL="http://yum.postgresql.org/"
	WGET_TMP_FILE="${WORKSPACE_WD}/data/wget.tmp"
	
	wget --quiet ${BASE_URL}${REPO_PACKAGES_FILE} -O "${WORKSPACE_WD}/data/$REPO_PACKAGES_FILE" > $WGET_TMP_FILE
	
	if [[ -f "${WORKSPACE_WD}/data/$REPO_PACKAGES_FILE" ]]; then
		choosePostgresVersion			#sets VERSION
	
		MAJOR_VERSION=${VERSION:0:1}
		MINOR_VERSION=${VERSION:1:2}
		
		resetVariableInVariableFile "POSTGRES_MAJOR_VERSION" "${MAJOR_VERSION}"
		resetVariableInVariableFile "POSTGRES_MINOR_VERSION" "${MINOR_VERSION}"
		
		DOT_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}"
		
		newLine
		outputLog "POSTGRES VERSION is ${MAJOR_VERSION}.${MINOR_VERSION}" "2"
	
		REPO_BASE="http://yum.postgresql.org"
		RPM="pgdg-${DISTRO}${VERSION}-${DOT_VERSION}-"
		REPO_WO_RPM="/${DOT_VERSION}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/"
		
		outputLog "Link used to get build number: ${REPO_WO_RPM}${RPM}" "1"
		LINK=`grep ${REPO_WO_RPM}${RPM} "${WORKSPACE_WD}/data/$REPO_PACKAGES_FILE"`
		outputLog "Link from file is $LINK" "1"
		INDEX=`awk -v a="$LINK" -v b=".noarch" 'BEGIN{print index(a,b)}'`
		outputLog "Index found at $INDEX" "1"
		INDEX=$((INDEX - 2))
		outputLog "Index corrected to $INDEX" "1"
		
		BUILD_VERSION=${LINK:INDEX:1}
		outputLog "Build number is: ${BUILD_VERSION}"
		
		RPM="${RPM}${BUILD_VERSION}.noarch.rpm"
		REPO="${REPO_BASE}${REPO_WO_RPM}${RPM}"	
	else
		CONNECTION_REFUSED=`grep "Connection refused" $WGET_TMP_FILE` 
		if [[ "$CONNECTION_REFUSED" != "" ]]; then
			outputLog "Could not reach http://yum.postgresql.org/..." "4"
			outputLog "Is your internet connection available? Stopping install." "3"
		else
			outputLog "Some error occurred in acquiring Postgres list from http://yum.postgresql.org/" "4"
			outputLog "Is your internet connection available? Stopping install." "3"
			cat $WGET_TMP_FILE
		fi
		
		deletePostgresTmpFiles
		
		newLine
		pause
		
		mainMenu
	fi
}

function installPostgres () {

	outputLog "Installing PostgreSQL now...\n" "2"

	outputLog "Getting postgreSQL pgdg RPM from $REPO\n" "2"
		
	curl -0 $REPO -o "${WORKSPACE_WD}/data/$RPM" 2>/dev/null
	
	rpm -ivh "${WORKSPACE_WD}/data/$RPM"
	newLine
	
	BUILD_VERSION=
	MAINTENANCE_VERSION=
	
	IFS=$'\n'
	#Find all the minor/maintanence build numbers, excluding the beta and rc versions
	POSTGRESQL_RPM_ARRAY=( $(yum provides postgresql${VERSION} | grep "postgresql${VERSION}" | grep -v "beta" | grep -v "rc") )
	findLatestPgRpmVersion "${POSTGRESQL_RPM_ARRAY[@]}"
	newLine
	
	POSTGRESQL_RPM=`yum provides postgresql${VERSION} | grep "postgresql${VERSION}-${MAJOR_VERSION}.${MINOR_VERSION}.${BUILD_VERSION}-${MAINTENANCE_VERSION}"` 
	POSTGRESQL_RPM=${POSTGRESQL_RPM% : *}
	outputLog "POSTGRESQL_RPM $POSTGRESQL_RPM" "1" 
	
	POSTGRESQL_SERVER_RPM=`yum provides postgresql${VERSION}-server | grep "postgresql${VERSION}-server-${MAJOR_VERSION}.${MINOR_VERSION}.${BUILD_VERSION}-${MAINTENANCE_VERSION}"` 				
	POSTGRESQL_SERVER_RPM=${POSTGRESQL_SERVER_RPM% : *}	#removing description of rpm
	outputLog "POSTGRESQL_SERVER_RPM $POSTGRESQL_SERVER_RPM" "1" 

	POSTGRESQL_LIB_RPM=`yum provides postgresql${VERSION}-libs | grep "postgresql${VERSION}-libs-${MAJOR_VERSION}.${MINOR_VERSION}.${BUILD_VERSION}-${MAINTENANCE_VERSION}"` 				
	POSTGRESQL_LIB_RPM=${POSTGRESQL_LIB_RPM% : *}	#removing description of rpm
	outputLog "POSTGRESQL_LIB_RPM $POSTGRESQL_LIB_RPM"
	
	newLine
	outputLog "Going to install all the necessary RPMs for your selected postgreSQL version..." "2"
	
	yum -y install $POSTGRESQL_LIB_RPM
	yum -y install $POSTGRESQL_RPM $POSTGRESQL_SERVER_RPM
	
	resetVariableInVariableFile "POSTGRES_SERVICE_NAME" "postgresql-${MAJOR_VERSION}.${MINOR_VERSION}"
	loadVariables
	newLine

	#Big switch in postgres install from version 9.1-4
	if [[ "${MAJOR_VERSION}" -le "9" && "${MINOR_VERSION}" -le "1" && "$BUILD_VERSION" -le "4" ]]; then
		
		outputLog "Looking for $POSTGRES_SERVICE_FILE" "1"
		if [ -f $POSTGRES_SERVICE_FILE ]; then
	
			newLine
			service $POSTGRES_SERVICE_NAME initdb
			
			outputLog "Copying postgres config file to $POSTGRES_INSTALL_LOCATION/${MAJOR_VERSION}.${MINOR_VERSION}/data/pg_hba.conf" "2"
			cp "${WORKSPACE_WD}/conf/postgres/pg_hba.conf" $POSTGRES_INSTALL_LOCATION/${MAJOR_VERSION}.${MINOR_VERSION}/data/pg_hba.conf
	
			outputLog "Setting $POSTGRES_SERVICE_NAME to default to on after a machine restart..." "2"
			chkconfig $POSTGRES_SERVICE_NAME on
			
			newLine
			startPostgresService
			resetVariableInVariableFile "POSTGRES_INSTALLED" "y"
			
		else
			outputLog "Postgres has not been installed, yum installation failed, check output above." "4"
		fi	
	else
		#Handling install of versions of postgres newer then 9.1-4
		eval su - postgres -c "/usr/pgsql-${MAJOR_VERSION}.${MINOR_VERSION}/bin/initdb"
		
		SYSTEMCTL_AVAILABLE=`systemctl 2>&1`
		
		if [[ "$SYSTEMCTL_AVAILABLE" =~ "command not found" ]]; then
			chkconfig ${POSTGRES_SERVICE_NAME} on
		else
			systemctl enable ${POSTGRES_SERVICE_NAME}.service
		fi
			
		newLine
		startPostgresService
		resetVariableInVariableFile "POSTGRES_INSTALLED" "y"
	fi
}

#function - deletePostgresTmpFiles () - will delete all temp files created in the process of install postgresql
function deletePostgresTmpFiles () {	
	deleteFile $WGET_TMP_FILE
	deleteFile "${WORKSPACE_WD}/data/$REPO_PACKAGES_FILE"
	deleteFile "${WORKSPACE_WD}/data/$RPM"
	deleteFile "${WORKSPACE_WD}/data/list.txt"
}

#function - findLatestPgRpmVersion (rpmArray) - find the version with the highest minor/build numbers and choose that
function findLatestPgRpmVersion () {
	
	RPM_ARRAY=( "$@" )
	
	TOP_BUILD_NUMBER=0
	TOP_MAINTENANCE_NUMBER=0
	local COUNT=0
	
	outputLog "Available build-maintenance version numbers are:" "2" "y" "n" 
	for V in "${RPM_ARRAY[@]}"
	do
		COUNT=$(( COUNT + 1 ))
		outputLog "Processing $V" "1"
		if [[ "$V" =~ "Provides-match" ]]; then
			outputLog "Ignoring last line in array..." "1"
		else

			BUILD_VERSION=${V:17:1}
			MAINTENANCE_VERSION=${V:19:1}
			outputLog "BUILD_VERSION [$BUILD_VERSION] -- MAINTENANCE_VERSION [$MAINTENANCE_VERSION]" "1"
			
			if [[ $TOP_BUILD_NUMBER -eq 0 ]]; then
				TOP_BUILD_NUMBER=$BUILD_VERSION
				TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
				TOP_CHOICE=$COUNT
				outputLog "TOP numbers at 0, set them both to TOP_BUILD_NUMBER[$TOP_BUILD_NUMBER] -- TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
			elif [[ $TOP_BUILD_NUMBER -lt $BUILD_VERSION ]]; then
				TOP_BUILD_NUMBER=$BUILD_VERSION
				TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
				TOP_CHOICE=$COUNT
				outputLog "Current build greater then $TOP_BUILD_NUMBER, set them both to TOP_BUILD_NUMBER[$TOP_BUILD_NUMBER] -- TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
			elif [[ $TOP_BUILD_NUMBER -eq $BUILD_VERSION && $TOP_MAINTENANCE_NUMBER -lt $MAINTENANCE_VERSION ]]; then
				TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
				TOP_CHOICE=$COUNT
								
				outputLog "Build numbers are the same [$BUILD_VERSION], but current maintence greater then $TOP_MAINTENANCE_NUMBER, set TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
			fi
		fi
		
		outputLog "\t${COUNT}. postgresql${VERSION}.${BUILD_VERSION}-${MAINTENANCE_VERSION}" "2" "y" "n"
	done
	
	while true;
	do
		takeInput "Choose the build/maintenance version you desire, it's recommended to use the default for 9.1: (${TOP_BUILD_NUMBER}-${TOP_MAINTENANCE_NUMBER})"
		read DETAIL_VERSION_TO_INSTALL
		
		#If non-numeric or not in the correct number range, then invalid else extract version to add to repo base
		if [[ "$DETAIL_VERSION_TO_INSTALL" == "b" || "$DETAIL_VERSION_TO_INSTALL" == "B" ]]; then
			deletePostgresDB "$POSTGRES_JON_DB"
			deletePostgresTmpFiles
			resetVariableInVariableFile "POSTGRES_JON_DB"
			INSTALL_BUNDLES=""
			loadVariables
			mainMenu
		elif [[ "$DETAIL_VERSION_TO_INSTALL" == "" ]]; then
			DETAIL_VERSION_TO_INSTALL=$TOP_CHOICE
			break
		elif [[ ! "$DETAIL_VERSION_TO_INSTALL" =~ ^[[:digit:]] || "$DETAIL_VERSION_TO_INSTALL" -le "0" || "$DETAIL_VERSION_TO_INSTALL" -gt "$COUNT" ]]; then
			outputLog "Invalid input, must be between 1 and $COUNT" "4"
			newLine
		else
			break
		fi
	done
	
	#Take into account the zero/one start index of list/array
	DETAIL_VERSION_TO_INSTALL=$(( DETAIL_VERSION_TO_INSTALL - 1 ))
	
	CHOSEN_CHOICE=${RPM_ARRAY[DETAIL_VERSION_TO_INSTALL]}
	TOP_BUILD_NUMBER=${CHOSEN_CHOICE:17:1}
	TOP_MAINTENANCE_NUMBER=${CHOSEN_CHOICE:19:1}
	
	outputLog "TOP_BUILD_NUMBER: [$TOP_BUILD_NUMBER] -- TOP_MAINTENANCE_NUMBER: [$TOP_MAINTENANCE_NUMBER]"
	
	
}

#function - choosePostgresVersion () - choose the version of postgres to download
function choosePostgresVersion () {
	
	#Truncate the file to only the available repos
	local LIST_FILE="${WORKSPACE_WD}/data/list.txt"
	sed '/Available Repository RPMs/, /d releases/ !d' "${WORKSPACE_WD}/data/repopackages.php" > $LIST_FILE
	
	#Get the list of a tags containing the postgres version numbers
	TEMP=`grep "<a name=" $LIST_FILE`
	#outputLog "TEMP list is: $TEMP" "1"
	
	VERSION_ARRAY=()
	BETA_VERSION=""
	COUNT=0
	
	while read -r LINE; 
	do 
		if [[ "$LINE" =~ "font color=red" || "$LINE" =~ "BETA" ]]; then 
			BETA_VERSION=$COUNT
		fi

		#outputLog "Beta version matches with index $BETA_VERSION of postgreSQL versions"
		
		T1=${LINE#*\"} ###pg90fedora"></a>
		T1=${T1%\"*}   ###pg90fedora
		#outputLog "T1 is: $T1" "1"
		
		T1_LENGTH=${#T1}
		outputLog "T1 length is: $T1_LENGTH" "1"
		if [[ "$T1_LENGTH" -ne "2" ]]; then
			outputLog "T1 ($T1) will be cut to substring ${T1:2:2}" "1"
			T1=${T1:2:2}
		fi
		
		outputLog "Checking for \"/${T1:0:1}.${T1:1:1}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/\" in $LIST_FILE"
		DISTRO_PG_OK=`grep "/${T1:0:1}.${T1:1:1}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/" $LIST_FILE | grep "pgdg-${DISTRO}"`
		
		outputLog "distro <-- $DISTRO_PG_OK"
		if [[ "$DISTRO_PG_OK" == "" ]]; then
			outputLog "Skipping PostgreSQL v.${T1} as it's not available for the current distro" "1"
		else 
			#Check if the URL is valid before adding it
			local LINK=""
			LINK=${DISTRO_PG_OK#*\"}   #Text after first double quote
			LINK=${LINK%%\"*}   #Text after first double quote, full relative link
			outputLog "LINK is [${BASE_URL}${LINK}]" "1"
			
			#Check if the URL is valid
			local RESULT=`curl -0 ${BASE_URL}${LINK} 2>/dev/null`
			if [[ "$RESULT" =~ "404 - Not found" ]]; then
				outputLog "This version [${T1}] - supposedly available for your architecture - throws a 404 on the PostgreSQL website, ignoring..." "3"
			else	
		
				#outputLog "T1 is: $T1" "1"
				#outputLog "v array is: ${VERSION_ARRAY[@]}" "1"

				if [[ "$T1" -le "$LATEST_SUPPORTED_POSTGREQ" ]]; then
				
					MATCH=$(echo "${VERSION_ARRAY[@]}" | grep -o $T1)  
					if [[ "$MATCH" == "" ]]; then
					  outputLog "Adding $T1 to the array of PostgreSQL versions" "1"
					  VERSION_ARRAY+=($T1)
					  COUNT=$((COUNT + 1))
					else
					  outputLog "Ignoring $T1 as it already exists in the array" "1"
					fi
				else
					outputLog "Ignoring PostgreSQL v${T1} as it is not supported by JON" "3"
				fi
			fi
		fi
		
	done <<< "$TEMP"
	outputLog "\n" "1"

	VERSION_ARRAY_LENGTH=$((${#VERSION_ARRAY[@]}))
	outputLog "Array length is: $VERSION_ARRAY_LENGTH" "1"
	
	#If there are no versions add in the array, then we have not found a compatible PostgreSQL version
	#And cannot install the JON demo in this environment
	if [[ "$VERSION_ARRAY_LENGTH" == "0" ]]; then
		outputLog "Sorry, there are no supported PostgreSQL versions for your architecture, try with one of the verified configurations found in the README-MORE file" "4"
		deletePostgresTmpFiles
		exit
	else

		newLine "1"
		takeInput "Select the version of postgres you would like to install: [1 ... x]\n\tB. Back to Main Menu.\n"
	
		while true;
		do
			VERSION=
	
			for (( i = 1 ; i <= $VERSION_ARRAY_LENGTH ; i++ ))
			#i in $(seq $COUNT $VERSION_ARRAY_LENGTH)
			do			
				INDEX_FOR_ARRAY=$((i - 1))
				
				if [[ "$BETA_VERSION" == "$INDEX_FOR_ARRAY" ]]; then
					BETA_TEXT=" BETA version"
				else 
					BETA_TEXT=""
				fi
				takeInput "$i. -- PostgreSQL v.${VERSION_ARRAY[$INDEX_FOR_ARRAY]}${BETA_TEXT}" "0"
			done
	
			read VERSION
	
			#If non-numeric or not in the correct number range, then invalid else extract version to add to repo base
			if [[ "$VERSION" == "b" || "$VERSION" == "B" ]]; then
				deletePostgresTmpFiles
				mainMenu
			elif [[ ! "$VERSION" =~ ^[[:digit:]] || "$VERSION" -lt "1" || "$VERSION" -gt "$VERSION_ARRAY_LENGTH" ]]; then
				outputLog "Invalid input, must be between 1 and $VERSION_ARRAY_LENGTH" "4"
				newLine
			else
				#Decrement version by one to match the array indices
				VERSION=$((VERSION - 1))
				
				#Get the correct PG version from the array
				VERSION=${VERSION_ARRAY[$VERSION]}
				break
			fi
	
		done
	fi
}

function getDistroDetails () {
	if [[ -f "/etc/fedora-release" ]]; then
		temp=`cat /etc/fedora-release`	#Fedora release 15 (Lovelock)
		temp=${temp% \(*}			#Fedora release 15
		DISTRO_VERSION=${temp#*release }	#15

		DISTRO="fedora"
	fi

	if [[ -f "/etc/redhat-release" && "$DISTRO" == "" ]]; then
		temp=`cat /etc/redhat-release`	#Red Hat Enterprise Linux Server release 5 (xxx)
		temp=${temp% \(*}			#Red Hat Enterprise Linux Server release 5
		DISTRO_VERSION=${temp#*release }			#5

		DISTRO="redhat"
	fi
			
	if [[ "$DISTRO" == "redhat" ]]; then
		DISTRO_NICK="rhel"
		DISTRO_VERSION=${DISTRO_VERSION:0:1}
	else
		DISTRO_NICK=$DISTRO
	fi
	
}

#function - createPostgresUser ()- create a user for postgres, by default using rhqadmin, otherwise request input displaying current users
function createPostgresUser () {

	createuser -h 127.0.0.1 -p 5432 -U postgres -S -D -R $POSTGRES_USER 2>&1
	if [[ "$?" == "1" ]]; then
		outputLog "postgres user [$POSTGRES_USER] already exists, progressing using this user." "2" 
		newLine
	else
		outputLog "Created postgres user $POSTGRES_USER" "2"
	fi

	createPostgresDb
}

#function - createPostgresDb () - to create a database, by default using rhq, otherwise request user input display all the current dbs
function createPostgresDb () {

	DB_CREATION=`createdb -h 127.0.0.1 -p 5432 -U postgres -O $POSTGRES_USER $POSTGRES_DB_DEFAULT 2>&1`
	
	POSTGRES_DB=""
	while [[ "$DB_CREATION" =~ "database creation failed" ]]; do
		while [[ "$POSTGRES_DB" == "" ]]; do
	
			outputLog "createdb errored, the following dbs already exist:" "3"
	
			psql -U postgres -c "\l"
	
			takeInput "Please enter a new database name to use:\n\tB. Back to Main Menu."
			read POSTGRES_DB
			
			if [[ "$POSTGRES_DB" == "b" || "$POSTGRES_DB" == "B" ]]; then
				deletePostgresDB "$POSTGRES_JON_DB"
				resetVariableInVariableFile "POSTGRES_JON_DB"
				loadVariables
				mainMenu
			elif [[ "$POSTGRES_DB" == "" ]]; then
				outputLog "Invalid input, must be a non-empty string" "4"
				newLine
			fi
			
			createdb -h 127.0.0.1 -p 5432 -U postgres -O $POSTGRES_USER $POSTGRES_DB
			
		done
	done
	
	if [[ "$POSTGRES_DB" == "" ]]; then
		POSTGRES_DB=$POSTGRES_DB_DEFAULT
	fi
	
	resetVariableInVariableFile "POSTGRES_JON_DB" "$POSTGRES_DB"
	loadVariables
	
	outputLog "Created postgres db $POSTGRES_DB" "2"
}

#function - deletePostgresDB (dbToDelete) - delete JON postgres db
function deletePostgresDB () {
	
	DB_TO_DELETE=$1
	if [[ "$DB_TO_DELETE" == "" && "$POSTGRES_JON_DB" == "" ]]; then
		outputLog "The name of database to be deleted is empty and must be deleted manually." "3"
	else		
		dropdb -h 127.0.0.1 -p 5432 -U postgres $DB_TO_DELETE
		if [[ "$?" == "0" ]]; then
			outputLog "Dropped postgres DB $DB_TO_DELETE" "2"
		fi
	
		dropuser -h 127.0.0.1 -p 5432 -U postgres $POSTGRES_USER
		if [[ "$?" == "0" ]]; then
			outputLog "Dropped postgres user $POSTGRES_USER" "2"
		fi
	fi

}

#function - uninstallPostgres () - uninstall postgres
function uninstallPostgres () {
	takeYesNoInput "All postgresql data will be deleted, are you certain? (yes/no): [default no]\n\tB. Back to Main Menu." "no" "1"

	newLine

	if [[ "$ANSWER" == "yes" ]]; then
		stopPostgresService

		chkconfig --level 345 $POSTGRES_SERVICE_NAME off
		yum -y remove postgresql${POSTGRES_MAJOR_VERSION}${POSTGRES_MINOR_VERSION}-libs postgresql${POSTGRES_MAJOR_VERSION}${POSTGRES_MINOR_VERSION}
		yum -y remove pgdg-*${POSTGRES_MAJOR_VERSION}${POSTGRES_MINOR_VERSION}-${POSTGRES_MAJOR_VERSION}.${POSTGRES_MINOR_VERSION}-*.noarch
	
		deleteFolder $POSTGRES_INSTALL_LOCATION
		
		resetVariableInVariableFile "POSTGRES_INSTALLED"
		resetVariableInVariableFile "POSTGRES_SERVICE_NAME"
		resetVariableInVariableFile "POSTGRES_MAJOR_VERSION"
		resetVariableInVariableFile "POSTGRES_MINOR_VERSION"
		resetVariableInVariableFile "POSTGRES_JON_DB"
	else
		outputLog "Uninstall stopped." "2"
	fi
}

function choosePostgresDB () {

	DB=
	while [[ "$DB" == "" ]];
	do
		outputLog "Possible options:" "1" "y" "n"
		newLine
		psql -U postgres -c "\l"

		newLine
		takeInput "Please enter the database name you would like to delete:\n\tB. Back to Main Menu"
		read DB

		if [[ "$DB" == "" ]]; then
			outputLog "The database name cannot be empty, please input it again" "4"
		elif [[ "$DB" == "b" || "$DB" == "B" ]]; then
			#Try deleting a DB with name "b" if it exists
			deletePostgresDB $DB
			mainMenu
			break
		fi
	done
}
