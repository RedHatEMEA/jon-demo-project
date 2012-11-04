#function - setAnt () - sets the variable ANT to the result of which ant
function setAnt () {
	ANT=`which ant 2>/dev/null`	
}

#function - setMaven () - sets the variable MAVEN to the result of which mvn
function setMaven () {
	MAVEN=`which mvn 2>/dev/null`	
}

#function - deleteBundles () - Function that deletes the created bundles and bits of EAP moved into the sub project
function deleteBundles () {

	CURRENT_WD=`pwd`
	cd ${WORKSPACE_WD}/sub-projects/bundle-creation
	
	$ANT clean -Ddist.dir=${WORKSPACE_WD}/data/bundles
	
	cd $CURRENT_WD
	
	#Use the provided zip file if available (checked in main.sh).
	JBOSS_PRODUCT=`getZipTopFolder $JBOSS_PROVIDED`		#jboss-eap-5.1/
	JBOSS_PRODUCT=${JBOSS_PRODUCT%\/*}					#jboss-eap-5.1

	#Remove the expanded JBoss folder
	rm -rf $( ls -d ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/*/)
	rm -rf ${WORKSPACE_WD}/data/bundles
	
	outputLog "Bundles deleted." "2"
}

#function - createBundles () - Function that creates the bundles
function createBundles () {
	
	#Use the provided zip file if available (checked in main.sh).
	JBOSS_PRODUCT=`getZipTopFolder $JBOSS_PROVIDED`		#jboss-eap-5.1/
	JBOSS_PRODUCT=${JBOSS_PRODUCT%\/*}					#jboss-eap-5.1
	JBOSS_VERSION_NO_REVISION=${JBOSS_PRODUCT##*-}		#5.1
	JBOSS_VERSION=${JBOSS_PROVIDED##*-}					#5.1.2.zip
	JBOSS_VERSION=${JBOSS_VERSION%.*}					#5.1.2

	outputLog "JBoss product provided is: $JBOSS_PRODUCT, and version is: $JBOSS_VERSION_NO_REVISION"
	
	if [[ "$BUNDLES_CREATED" != "" ]]; then
		deleteBundles
	fi
	
	if [[ "$JBOSS_VERSION_NO_REVISION" =~ "5.1" ]]; then
		
		extractPackage "$JBOSS_PROVIDED" "${WORKSPACE_WD}/data/jboss/"
		
		#Remove the components not used
		rm -rf ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/mod_cluster/ ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/seam/
		rm -rf ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/picketlink/ ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/resteasy/
		
		#Create the folders to use for the bundles
		mkdir ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common
		mkdir ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default
		
		#Copy the jboss-as server to common dir
		mv ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/jboss-as/* ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common
		
		#Copy the default instance to default dir
		mv ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common/server/default/* ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default
		
		#Remove all the other profiles and extraneous folders
		rm -rf $( find ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common/server/* -type d )
		rm -rf ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/jboss-as
		
		#Copy the necessary files
		cp ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common/bin/run.conf ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/
		mv ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/conf/bindingservice.beans/META-INF/bindings-jboss-beans.xml ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/

		#Make the in-place changes for:
			#run.conf
		replaceStringInFile "#JAVA_HOME=\"\/usr\/java\/jdk1.6.0\"" "JAVA_HOME=\"\@\@JAVA_HOME\@\@\"" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/run.conf"
		replaceStringInFile "JAVA_OPTS=\"-Xms1303m -Xmx1303m" "JAVA_OPTS=\"-Xms\@\@JAVA_XMS\@\@m -Xmx\@\@JAVA_XMX\@\@m" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/run.conf"
		
		echo -e "\nJAVA_OPTS=\"-Djboss.bind.address=\`0.0.0.0\` \$JAVA_OPTS\"" >> ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/run.conf
		echo "JAVA_OPTS=\"-Djboss.service.binding.set=ports-@PORTS_OFFSET@ \$JAVA_OPTS\"" >> ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/run.conf
		echo "JAVA_OPTS=\"-Dconf.jvmRoute=\`hostname\`-@JBOSS_CONF@  \$JAVA_OPTS\"" >> ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/run.conf
			
			#bindings-jboss-beans.xml
		replaceStringInFile "Ports01Bindings" "Ports\@PORTS_OFFSET\@Bindings" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/bindings-jboss-beans.xml"
		replaceStringInFile "<parameter>ports-01</parameter>" "<parameter>ports-\@PORTS_OFFSET\@</parameter>" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/bindings-jboss-beans.xml"
		replaceStringInFile "<parameter>100</parameter>" "<parameter>\@PORTS_OFFSET\@</parameter>" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/bindings-jboss-beans.xml"
		
		#Copy the additional files into the appropriate dir
		cp ${WORKSPACE_WD}/sub-projects/bundle-creation/src/EAP/default/files/$JBOSS_VERSION_NO_REVISION/* ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/
		cp -R ${WORKSPACE_WD}/sub-projects/bundle-creation/src/EAP/common/files/$JBOSS_VERSION_NO_REVISION/* ${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common/
		
		#Uncomment the admin user credentials for the jmx-console
		replaceStringInFile "# admin=admin" "admin=admin" "${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default/conf/props/jmx-console-users.properties"
		
		#Create the bundles folder to drop the newly created bundles in.
		mkdir -p ${WORKSPACE_WD}/data/bundles

		CURRENT_WD=`pwd`
		cd ${WORKSPACE_WD}/sub-projects/bundle-creation

		#Call ant (forking process) passing in the directory to find the data (under the data folder) required for the bundles
		if [[ "$SUB_PROJECT_CALL" == "true" ]]; then				
			$ANT -Ddata.dir=${WORKSPACE_WD}/data -Ddist.dir=${WORKSPACE_WD}/data/bundles -Dcommon.dir=${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common -Ddefault.dir=${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default -Ddvdstore.dir=${WORKSPACE_WD}/sub-projects/bundle-creation/src/seam/seam-dvdstore
		else
			$ANT -Ddata.dir=${WORKSPACE_WD}/data -Ddist.dir=${WORKSPACE_WD}/data/bundles -Dcommon.dir=${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/common -Ddefault.dir=${WORKSPACE_WD}/data/jboss/$JBOSS_PRODUCT/default -Ddvdstore.dir=${WORKSPACE_WD}/sub-projects/bundle-creation/src/seam/seam-dvdstore &
		fi
		
		#Go to the application hello world, and build it using maven
		cd ${WORKSPACE_WD}/sub-projects/applications/hello_world_servlet
		outputLog "Building the hello world application bundle..." "2"
		$MAVEN clean package
		
		#Copy the bundle zip to the bundles folder
		outputLog "Copying the hello world application bundle..." "1"
		cp target/hello.world.servlet-0.0.1-SNAPSHOT-bundle.zip $BUNDLE_HW_APP_FILE
		
		cd $CURRENT_WD
			
		#Change the owner ship from root to default script user
		chown $LOCAL_USER:$LOCAL_USER -R ${WORKSPACE_WD}/data/bundles
		
		outputLog "Bundles are being built..." "2"
	else
		outputLog "At the moment, only EAP v5.1.x is supported for the creation of bundles, more versions will be supported at a later time. Bundle creation will be skipped." "3"
	fi 	
}