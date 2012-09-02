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
		if [[ "$POSTGRES_SERVICE_NAME" == "" ]]; then
			POSTGRES_SERVICE_FILE=`find $INIT_D/ -name "postgresql*"`
			POSTGRES_SERVICE_NAME=${POSTGRES_SERVICE_FILE#*$INIT_D/}

			outputLog "POSTGRES_SERVICE_FILE is $POSTGRES_SERVICE_FILE"
			outputLog "POSTGRES_SERVICE_NAME is $POSTGRES_SERVICE_NAME"
			
			updateVariablesFile "POSTGRES_SERVICE_NAME=" "POSTGRES_SERVICE_NAME=${POSTGRES_SERVICE_NAME}"
			updateVariablesFile "POSTGRES_INSTALLED=" "POSTGRES_INSTALLED=y"
			
			VERSION=${POSTGRES_SERVICE_NAME#*-}
			outputLog "VERSION: $VERSION"
			MAJOR_VERSION=${VERSION:0:1}
			MINOR_VERSION=${VERSION:2:1}
			outputLog "MAJOR [$MAJOR_VERSION] -- MINOR [$MINOR_VERSION]"
			
			updateVariablesFile "POSTGRES_MAJOR_VERSION=" "POSTGRES_MAJOR_VERSION=${MAJOR_VERSION}"
			updateVariablesFile "POSTGRES_MINOR_VERSION=" "POSTGRES_MINOR_VERSION=${MINOR_VERSION}"
			loadVariables
		fi	
	fi
}

#function - checkPostgresInstall () - check if postgres is installed, running, etc
function checkPostgresInstall () {

	POSTGRES_INSTALLED="n"

	if [ -f $POSTGRES_SERVICE_FILE ]; then

		newLine
		status=`service $POSTGRES_SERVICE_NAME status`

		case "$status" in
		*inactive* | *stopped*)
			startPostgresService
			POSTGRES_INSTALLED="y"
			;;
		*active* | *running*)
			outputLog "PostgreSQL is installed, and running..." "2"
			POSTGRES_INSTALLED="y"
			;;
		*)
			outputLog "Somehow, none of the scenarios apply..." "3"
			;;
		esac
	else
		outputLog "PostgreSQL is not installed...\n" "2"
		POSTGRES_INSTALLED="n"
	fi
	
	updateVariablesFile "POSTGRES_INSTALLED=" "POSTGRES_INSTALLED=${POSTGRES_INSTALLED}"
	
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
	WGET_TMP_FILE="wget.tmp"
	wget http://yum.postgresql.org/${REPO_PACKAGES_FILE} -o $WGET_TMP_FILE
	choosePostgresVersion			#sets VERSION

	MAJOR_VERSION=${VERSION:0:1}
	MINOR_VERSION=${VERSION:1:2}
	
	updateVariablesFile "POSTGRES_MAJOR_VERSION=" "POSTGRES_MAJOR_VERSION=${MAJOR_VERSION}"
	updateVariablesFile "POSTGRES_MINOR_VERSION=" "POSTGRES_MINOR_VERSION=${MINOR_VERSION}"
	
	DOT_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}"
	
	newLine
	outputLog "POSTGRES VERSION is ${MAJOR_VERSION}.${MINOR_VERSION}" "2"

	REPO_BASE="http://yum.postgresql.org"
	RPM="pgdg-${DISTRO}${VERSION}-${DOT_VERSION}-"
	REPO_WO_RPM="/${DOT_VERSION}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/"
	
	outputLog "Link used to get build number: ${REPO_WO_RPM}${RPM}" "1"
	LINK=`grep ${REPO_WO_RPM}${RPM} $REPO_PACKAGES_FILE`
	outputLog "Link from file is $LINK" "1"
	INDEX=`awk -v a="$LINK" -v b=".noarch" 'BEGIN{print index(a,b)}'`
	outputLog "Index found at $INDEX" "1"
	INDEX=$((INDEX - 2))
	outputLog "Index corrected to $INDEX" "1"
	
	BUILD_VERSION=${LINK:INDEX:1}
	outputLog "Build number is: ${BUILD_VERSION}"
	
	RPM="${RPM}${BUILD_VERSION}.noarch.rpm"
	REPO="${REPO_BASE}${REPO_WO_RPM}${RPM}"	
}

function installPostgres () {

	outputLog "Installing PostgreSQL now...\n" "2"

	outputLog "Getting postgreSQL pgdg RPM from $REPO\n" "2"
		
	curl -O $REPO
	
	rpm -ivh $RPM
	newLine
	
	BUILD_VERSION=
	MAINTENANCE_VERSION=
	
	IFS=$'\n'
	POSTGRESQL_RPM_ARRAY=( $(yum provides postgresql${VERSION} | grep "postgresql${VERSION}") )
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
	
	updateVariablesFile "POSTGRES_SERVICE_NAME=" "POSTGRES_SERVICE_NAME=postgresql-${MAJOR_VERSION}.${MINOR_VERSION}"
	loadVariables
	newLine

	outputLog "Looking for $POSTGRES_SERVICE_FILE" "1"
	if [ -f $POSTGRES_SERVICE_FILE ]; then

		newLine
		service $POSTGRES_SERVICE_NAME initdb
		
		outputLog "Copying postgres config file to $POSTGRES_INSTALL_LOCATION/${MAJOR_VERSION}.${MINOR_VERSION}/data/pg_hba.conf" "2"
		cp ${WORKSPACE_WD}/conf/postgres/pg_hba.conf $POSTGRES_INSTALL_LOCATION/${MAJOR_VERSION}.${MINOR_VERSION}/data/pg_hba.conf

		outputLog "Setting $POSTGRES_SERVICE_NAME to default to on after a machine restart..." "2"
		chkconfig $POSTGRES_SERVICE_NAME on
		
		newLine
		startPostgresService
		updateVariablesFile "POSTGRES_INSTALLED=" "POSTGRES_INSTALLED=y"
	else
		outputLog "Postgres has not been installed, yum installation failed, check output above." "4"
	fi	

}

#function - deletePostgresTmpFiles () - will delete all temp files created in the process of install postgresql
function deletePostgresTmpFiles () {	
	deleteFile $WGET_TMP_FILE
	deleteFile $REPO_PACKAGES_FILE
	deleteFile $RPM	
	deleteFile list.txt
}

#function - findLatestPgRpmVersion (rpmArray) - find the version with the highest minor/build numbers and choose that
function findLatestPgRpmVersion () {
	
	RPM_ARRAY=( "$@" )
	
	TOP_BUILD_NUMBER=0
	TOP_MAINTENANCE_NUMBER=0
	
	for V in "${RPM_ARRAY[@]}"
	do
		BUILD_VERSION=${V:17:1}
		MAINTENANCE_VERSION=${V:19:1}
		outputLog "BUILD_VERSION [$BUILD_VERSION] -- MAINTENANCE_VERSION [$MAINTENANCE_VERSION]" "1"
		
		if [[ $TOP_BUILD_NUMBER -eq 0 ]]; then
			TOP_BUILD_NUMBER=$BUILD_VERSION
			TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
			outputLog "TOP numbers at 0, set them both to TOP_BUILD_NUMBER[$TOP_BUILD_NUMBER] -- TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
		elif [[ $TOP_BUILD_NUMBER -lt $BUILD_VERSION ]]; then
			TOP_BUILD_NUMBER=$BUILD_VERSION
			TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
			outputLog "Current build greater then $TOP_BUILD_NUMBER, set them both to TOP_BUILD_NUMBER[$TOP_BUILD_NUMBER] -- TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
		elif [[ $TOP_BUILD_NUMBER -eq $BUILD_VERSION && $TOP_MAINTENANCE_NUMBER -lt $MAINTENANCE_VERSION ]]; then
			TOP_MAINTENANCE_NUMBER=$MAINTENANCE_VERSION
			outputLog "Build numbers are the same [$BUILD_VERSION], but current maintence greater then $TOP_MAINTENANCE_NUMBER, set TOP_MAINTENANCE_NUMBER[$TOP_MAINTENANCE_NUMBER]" "1"
		fi
		
	done
	
}

#function - choosePostgresVersion () - choose the version of postgres to download
function choosePostgresVersion () {
	
	#Truncate the file to only the available repos
	sed '/Available Repository RPMs/, /EOL/ !d' repopackages.php > list.txt
	
	#Get the list of a tags containing the postgres version numbers
	TEMP=`grep "<a name=" list.txt`
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
		
		T1=${LINE#*\"}
		T1=${T1%\"*}
		#outputLog "T1 is: $T1" "1"
		
		T1_LENGTH=${#T1}
		outputLog "T1 length is: $T1_LENGTH" "1"
		if [[ "$T1_LENGTH" -ne "2" ]]; then
			outputLog "T1 ($T1) will be cut to substring ${T1:2:2}" "1"
			T1=${T1:2:2}
		fi
		
		outputLog "Checking for \"/${T1:0:1}.${T1:1:1}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/\" in list.txt"
		DISTRO_PG_OK=`grep "/${T1:0:1}.${T1:1:1}/${DISTRO}/${DISTRO_NICK}-${DISTRO_VERSION}-${ARCH}/" list.txt`
		
		if [[ "$DISTRO_PG_OK" == "" ]]; then
			outputLog "Skipping PostgreSQL v.${T1} as it's not available for the current distro" "1"
		else 
		
			#outputLog "T1 is: $T1" "1"
			#outputLog "v array is: ${VERSION_ARRAY[@]}" "1"
			
			MATCH=$(echo "${VERSION_ARRAY[@]}" | grep -o $T1)  
			if [[ "$MATCH" == "" ]]; then
			  outputLog "Adding $T1 to the array of PostgreSQL versions" "1"
			  VERSION_ARRAY+=($T1)
			  COUNT=$((COUNT + 1))
			else
			  outputLog "Ignoring $T1 as it already exists in the array" "1"
			fi
		fi
		
	done <<< "$TEMP"
	outputLog "\n" "1"

	VERSION_ARRAY_LENGTH=$((${#VERSION_ARRAY[@]}))
	outputLog "Array length is: $VERSION_ARRAY_LENGTH" "1"

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

		#echo -en "\t"
		read VERSION

		#If non-numeric or not in the correct number range, then invalid else extract version to add to repo base
		if [[ "$VERSION" == "b" || "$VERSION" == "B" ]]; then
			deletePostgresTmpFiles
			mainMenu
		elif [[ "$VERSION" != +([0-9]) || "$VERSION" -lt "1" || "$VERSION" -gt "$VERSION_ARRAY_LENGTH" ]]; then
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

	createdb -h 127.0.0.1 -p 5432 -U postgres -O $POSTGRES_USER $POSTGRES_DB_DEFAULT 2>&1
	
	POSTGRES_DB=""
	while [[ "$?" == "1" ]]; do
		while [[ "$POSTGRES_DB" == "" ]]; do
	
			outputLog "createdb errored, the following dbs already exist:" "3"
	
			psql -U postgres -c "\l"
	
			takeInput "Please enter a new database name to use:\n\tB. Back to Main Menu."
			read POSTGRES_DB
			
			if [[ "$POSTGRES_DB" == "b" || "$POSTGRES_DB" == "B" ]]; then
				deletePostgresDB "$POSTGRES_JON_DB"
				resetVariableInFile "POSTGRES_JON_DB"
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
	
	updateVariablesFile "POSTGRES_JON_DB=" "POSTGRES_JON_DB=$POSTGRES_DB"
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
		
		resetVariableInFile "POSTGRES_INSTALLED"
		resetVariableInFile "POSTGRES_SERVICE_NAME"
		resetVariableInFile "POSTGRES_MAJOR_VERSION"
		resetVariableInFile "POSTGRES_MINOR_VERSION"
		resetVariableInFile "POSTGRES_JON_DB"
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
