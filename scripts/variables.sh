export JAVA_HOME=$JAVA_HOME
export MVN_HOME=$MVN_HOME
export ANT_HOME=$ANT_HOME

#GLOBAL VARIABLES THAT MAY CHANGE AS THINGS PROGRESS
POSTGRESQL_DRIVER=postgresql-9.0-801.jdbc3.jar

#GLOBAL VARIABLES
PRODUCT=
BIN=bin
CONF=conf
SERVER_STATUS=

#OS locations:
INIT_D=/etc/init.d
TMP_LOCATION=/tmp
YUM_REPOS=/etc/yum.repos.d
JBOSS_OS_USER=jboss

#JON_DEMO script variables file
SCRIPT_VARIABLES=script_variables.sh

#JON_DEMO specific variables
JD_INSTALL_LOCATION=$INSTALL_LOCATION/$JD_FOLDER
JD_BUNDLE_LOCATION="${WORKSPACE_WD}/data/bundles"
CURRENT_PORT_BEING_INSTALLED=

#JON specific variables
JON_PLUGINS=plugins
JON_PRODUCTS_DIR="${WORKSPACE_WD}/data/jon"
JON_CONF_DIR="${WORKSPACE_WD}/conf/jon"
JON_TOOLS=$JD_INSTALL_LOCATION/jon-tools
JON_SILENT_CONFIG_FILE=rhq-server.properties
JON_STARTUP_SCRIPT=rhq-server.sh
JON_RHQ_EAR=jbossas/server/default/deploy/rhq.ear
JON_PRODUCT=
JON_DIRECTORY=
AGENT_SILENT_CONFIG_FILE=agent-configuration.xml
JON_AGENT_FOLDER=rhq-agent

#JBoss specific variables
JBOSS_AS=jboss-as
JBOSS_CONF=conf
JBOSS_SERVER=$JBOSS_AS/server
JBOSS_BIN=$JBOSS_AS/$BIN
JBOSS_RH_SCRIPT=jboss_init_redhat.sh
JBOSS_BINDING_SERVICE_XML=$JBOSS_CONF/bindingservice.beans/META-INF/bindings-jboss-beans.xml
JBOSS_JMX_USERS=$JBOSS_CONF/props/jmx-console-users.properties
JBOSS_JMX_ADMIN_PASSWORD=jd_admin

#Postgres specific variables
POSTGRES_INSTALL_LOCATION=/var/lib/pgsql
POSTGRES_USER=rhqadmin
POSTGRES_DB_DEFAULT=rhq

#Bundle specific variables
BUNDLE_COMMON_FILE="$JD_BUNDLE_LOCATION/EAP-common.zip"
BUNDLE_DEFAULT_FILE="$JD_BUNDLE_LOCATION/EAP-default.zip"
BUNDLE_APP_FILE="$JD_BUNDLE_LOCATION/seam-dvdstore.zip"
BUNDLE_HW_APP_FILE="$JD_BUNDLE_LOCATION/hello-world.zip"

DEST_COMMON_SUFFIX="common"
DEST_DEFAULT_SUFFIX="default"
DEST_APP_SUFFIX="app"
DEST_NAME_TEXT="Bundle_Destination--"

NODE_TEXT=node
JBOSS_BASE_CONF="ec-default"
