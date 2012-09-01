#!/bin/sh
#
# JBoss Control Script
#
# chkconfig: 3 80 20
# description: JBoss EJB Container
# 
# To use this script
# run it as root - it will switch to the specified user
# It loses all console output - use the log.
#
# Here is a little (and extremely primitive) 
# startup/shutdown script for RedHat systems. It assumes 
# that JBoss lives in /usr/local/jboss/jboss-as, it's run by user 
# 'jboss' and JDK binaries are in /usr/local/jdk/bin. All 
# this can be changed in the script itself. 
# Bojan 
#
# Either amend this script for your requirements
# or just ensure that the following variables are set correctly 
# before calling the script

# [ #420297 ] JBoss startup/shutdown for RedHat

#define where jboss is - this is the directory containing directories log, bin, conf etc
JBOSS_HOME=${JBOSS_HOME:-"/usr/local/jboss"}

#make java is on your path
JAVAPTH=${JAVAPTH:-"/usr/local/jdk/bin"}

#define which server instance to start up - by default use "all" or take the second input to this script
INSTANCE=$2
JBOSS_INSTANCE=all
if [[ "$INSTANCE" != "" ]]; then
	JBOSS_INSTANCE=$INSTANCE
fi

#get the admin line from the jmx console user file
JMX_ADMIN_LINE=`grep -v "# " ${JBOSS_HOME}/server/${INSTANCE}/conf/props/jmx-console-users.properties | grep "admin="`

#extract the password portion
JMX_PASSWORD=${JMX_ADMIN_LINE#*=}

#extract the user portion
JMX_USER=${JMX_ADMIN_LINE%=*}

#if not found, use default value of "admin" for password
if [[ "$JMX_PASSWORD" == "" ]]; then
        JMX_PASSWORD="admin"
fi

#if not found, use default value of "admin" for user
if [[ "$JMX_USER" == "" ]]; then
        JMX_USER="admin"
fi


JBOSS_JNP_PORT=1099

PARAMETER=`grep "jboss.service.binding.set:" $JBOSS_HOME/server/$JBOSS_INSTANCE/conf/bindingservice.beans/META-INF/bindings-jboss-beans.xml `

#ex: <parameter>${jboss.service.binding.set:ports-01}</parameter>
PARAMETER=${PARAMETER#*:ports-}	#Remove everything before the colon
PORTS=${PARAMETER%\}*}	#Remove everything from the curly brace

if [[ "$PORTS" != "default" ]]; then
	INCREMENT=${PORTS}00		#Add "hundred" to the port number

	#If the ports is 0100, adding will be messed up, and so, we remove the leading 0
	FIRST_NUM=${INCREMENT:0:1}
	if [[ "$FIRST_NUM" == "0" ]]; then
		INCREMENT=${INCREMENT:1}
	fi

	NEW_PORT=$(($JBOSS_JNP_PORT + $INCREMENT))
	JBOSS_JNP_PORT=$NEW_PORT
fi

#if JBOSS_HOST specified, use -b to bind jboss services to that address
JBOSS_BIND_ADDR=${JBOSS_BIND_ADDR:-"127.0.0.1"}

#define the classpath for the shutdown class
JBOSSCP=${JBOSSCP:-"$JBOSS_HOME/bin/shutdown.jar:$JBOSS_HOME/client/jnet.jar"}

#define the script to use to start jboss
JBOSSSH=${JBOSSSH:-"$JBOSS_HOME/bin/run.sh -c $JBOSS_INSTANCE -b $JBOSS_BIND_ADDR"}

#define the log location for the current instance
JBOSS_LOG_DIR=${JBOSS_HOME}/server/$JBOSS_INSTANCE/log
JBOSS_LOG=${JBOSS_LOG_DIR}/server.log

#define users to run script as
if [ "$JBOSSUS" = "RUNASIS" ]; then
  SUBIT=""
else
  SUBIT="su - $JBOSSUS -c "
fi

#define the console to user - by default when using this script send to /dev/null
if [ -z "$JBOSS_CONSOLE" -a ! -d "$JBOSS_CONSOLE" ]; then
  JBOSS_CONSOLE=$JBOSS_LOG
  # ensure the file exists
	if [ -z "$SUBIT" ]; then
		mkdir -p ${JBOSS_LOG_DIR}
		touch $JBOSS_CONSOLE	
	else
		$SUBIT "mkdir -p ${JBOSS_LOG_DIR}"
		$SUBIT "touch $JBOSS_CONSOLE"	  
	fi
fi

if [ -n "$JBOSS_CONSOLE" -a ! -f "$JBOSS_CONSOLE" ]; then
  echo "WARNING: location for saving console log invalid: $JBOSS_CONSOLE"
  echo "WARNING: ignoring it and using /dev/null"
  JBOSS_CONSOLE="/dev/null"
fi

#define what will be done with the console log
JBOSS_CONSOLE=${JBOSS_CONSOLE:-"/dev/null"}

#define the user under which jboss will run, or use RUNASIS to run as the current user
JBOSSUS=${JBOSSUS:-"jboss"}

#function to check the log file for the final shutdown log line, returns 0 (as in off) if found
function checkShutdown () {
	END_OF_LOG=`tail -1 ${JBOSS_LOG}`
	if [[ "$END_OF_LOG" =~ "(JBoss Shutdown Hook) Shutdown complete" ]]; then
		echo 0
	else
		echo 1
	fi
}

#function to check if JMX is available to figure out if server is starting/started up
function checkServerStartupStatus () {

	#call wget and store result in wget.tmp file
	wget -o wget.tmp http://${JBOSS_BIND_ADDR}:${JBOSS_JNP_PORT} >${JBOSS_CONSOLE}
	if [[ -f index.html ]]; then
		rm index.html
	fi

	#check wget.tmp file for text - "refused", not started up yet, "connected", server started up
	SERVER_DOWN=`grep "Connection refused." wget.tmp`
	SERVER_UP=`grep "connected." wget.tmp`

	#set server status to 0 for server down, 1 for server started
	if [[ "$SERVER_DOWN" != "" ]]; then
		SERVER_STATUS=0
	elif [[ "$SERVER_UP" != "" ]]; then
		SERVER_STATUS=1
	fi

	#remove temp wget output log file
	if [[ -f wget.tmp ]]; then
		rm wget.tmp
	fi
}

#function - checkServerShutdown (max_wait) - checks server log for final shutdown log
function checkServerShutdown () {
	COUNT=0
	MAX_WAIT=$1
	#check for server shutdown, with up to a (COUNT*2) second wait
	while true;
	do
		#if log file exists, check shutdown
		if [[ -f ${JBOSS_LOG} ]]; then

			#if shutdown, complete stop process
			SHUTDOWN_STATUS=`checkShutdown`
			if [[ "$SHUTDOWN_STATUS" == "0" ]]; then
				STATUS=0
				echo -e
				break

			#stop waiting if max_wait time surpassed
			elif [[ "$COUNT" > "$MAX_WAIT" ]]; then
				STATUS=1
				echo -e
				break

			#if not shutdown, wait and try again
			else
				echo -ne "."

				sleep 2
				COUNT=$(( $COUNT + 1 ))
			fi

		#if log file doesn't exist, can't check shutdown, try to kill process if it exists
		else
			COUNT=$MAX_WAIT
			STATUS=2
			echo -e
			break
		fi
	done
}

#define the start/stop commands to use in the terminal
CMD_START="cd $JBOSS_HOME/bin; $JBOSSSH" 
CMD_STOP="java -classpath $JBOSSCP org.jboss.Shutdown --shutdown -s jnp://$JBOSS_BIND_ADDR:$JBOSS_JNP_PORT -u $JMX_USER -p $JMX_PASSWORD"

#check for java in path
if [ -z "`echo $PATH | grep $JAVAPTH`" ]; then
  export PATH=$PATH:$JAVAPTH
fi

#check jboss_home is a proper directory
if [ ! -d "$JBOSS_HOME" ]; then
  echo JBOSS_HOME does not exist as a valid directory : $JBOSS_HOME
  exit 1
fi

checkServerStartupStatus

case "$1" in
start)
	#if server is shutdown, then try starting it up
	if [[ "$SERVER_STATUS" == "0" ]]; then

		echo Starting with command: "$CMD_START >${JBOSS_CONSOLE} 2>&1 &"
		cd $JBOSS_HOME/bin

		if [ -z "$SUBIT" ]; then
			eval ${CMD_START} > ${JBOSS_LOG} 2>&1 &
		else
			$SUBIT "${CMD_START} > ${JBOSS_LOG} 2>&1 &"  
		fi

		#Wait a little to confirm JMX is up before allowing use of the script to have accurate server status checking
		sleep 7

		echo The server is starting up, check the logs to confirm when start up is complete:
		echo "tail -f ${JBOSS_LOG}"

	#the server is already started
	else
		echo Server instance $JBOSS_INSTANCE is already started...
	fi
	;;

stop)
	#if server status is 0, server is already stopped
	if [[ "$SERVER_STATUS" == "0" ]]; then
		echo Server instance $JBOSS_INSTANCE is already stopped...
	else
		echo -ne "Stopping the server now."
		#echo Stopping with command: "$CMD_STOP"

		#try to shutdown the server with the shutdown command
		#if [ -z "$SUBIT" ]; then
		#	eval ${CMD_STOP} >>${JBOSS_CONSOLE} 2>&1 &
		#else
		#	$SUBIT "${CMD_STOP} >>${JBOSS_CONSOLE} 2>&1 &"
		#fi 

		#MAX_WAIT=7
		#checkServerShutdown $MAX_WAIT
		#if [[ "$STATUS" == "0" ]]; then
		#	echo "The server is now stopped"
		
		#if max wait time was exceed, try killing process
		#elif [[ "$STATUS" == "1" || "$STATUS" == "2" ]]; then

		#	echo "The server is taking a while to shut down, trying to kill it gently..."

			#look for all process ids that are running for the current instance
			for pid in `ps -ef | grep "[run.sh|Main] -c $JBOSS_INSTANCE [-b $JBOSS_BIND_ADDR]" | awk '{print $2}'`
			do
				#if pid is found
				if [[ "$pid" != "" ]]; then
					#then kill it gently
					if [ -z "$SUBIT" ]; then
						kill -15 $pid 2>&1
					else
						$SUBIT "kill -15 $pid" 2>&1
					fi
				fi
			done

			checkServerShutdown 5
			if [[ "$STATUS" == "0" ]]; then
				echo Server shutdown initiated and completed.
			else 
				echo Server shutdown initiated, please check the logs:
				echo "tail -f ${JBOSS_LOG}"
			fi
		#fi
	fi
	;;
restart)
	if [[ "$SERVER_STATUS" == "0" ]]; then
		echo Server instance $JBOSS_INSTANCE is already stopped... restarting
	else
		$0 stop $JBOSS_INSTANCE
	fi
	
	$0 start $JBOSS_INSTANCE
	;;

status)
	if [[ "$SERVER_STATUS" == "0" ]]; then
		echo Server instance $JBOSS_INSTANCE is stopped.
	elif [[ "$SERVER_STATUS" == "1" ]]; then
		echo Server instance $JBOSS_INSTANCE is started.
	fi
	;;

#COMPLETE ME - how to figure out the port to check the status
statusall)
	for instance in `ls ${JBOSS_HOME}/server`
	do
		ACTIVE=`ps -elf | grep "*run.sh*-c $instance"`
		echo $ACTIVE
		if [[ "$ACTIVE" != "" ]]; then
			echo Server instance $instance is started...
		else 
			echo Server instance $instance is stopped...
		fi
	done
	;;

*)
    echo "usage: $0 (start|stop|restart|status|help) (instance_name|default:all)"
esac
