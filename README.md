****************************************************************************************************************************************

Table of contents:
- [Description](#description)
- [Getting Started](#getting-started)
	- [Pre-requisites](#pre-requisites)
	- [Supported Environments](#supported-environments)
	- [First Steps](#first-steps)
	- [Manual Steps](#manual-steps)
- [Known Issues](#known-issues)
- [More Info](#more-info)

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# DESCRIPTION: #
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

This set of scripts is meant to allow you to easily install a new JON demo consisting of a JON server (of your choice, depending on what you have provided in the ./data/jon folder), agent, and jboss servers.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# GETTING STARTED: #
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

## PRE-REQUISITES ##

- Ensure the installation of the demo/jdk into a location that the "jboss" user can access (/opt should be a functional location)
- You can have Postgres installed before hand, but it may be better to let the script handle it as it doesn't cover every scenario of Postgres deployments...
- Ensure you do not have any JON servers/agents running on the server you are deploying to
- Ensure that if you do not have any JBoss servers running, but if necessary, 8080 will not be used by this demo.
- For bundle creation to be enabled, ensure you have ant and maven installed locally
- Package requirements:
	wget (installed from the internet if possible and necessary)
	
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	# Supported Environments: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Testing at the moment is more of a manual process.  As such, there are no guarantees regarding the full functionality of all the aspects of the script on different environments.  

The following environments have been tried and partly tested with the following results:
SUCCESS:	Fedora 15 64-bit (original code development environment)
SUCCESS:	Fedora 16 64-bit
CONFIRMED on 2013.04.13:	RHEL 6.1  64-bit (current code development environment)
CONFIRMED on 2013.04.13:	Fedora 17 64-bit 

FAILURE:   on 2013.04.13: Fedora 18 64-bit [Not yet supported because only RPMs available are for PostgreSQL 9.2, unless you manually install 9.1]
FAILURE:	MAC OSX 10.8 [Non-transferable linux commands such as useradd, wget, etc...]   

Components, there's no way to guarantee functioning with all versions of the required components, but the following work:
Maven 		3.0.3, 3.0.4
Ant   		1.8.2, 1.8.4
JDK   		1.6.0_29 [1.7 JDK does NOT work for EAP 5.x]
PostgreSQL	8.4, 9.1-4, 9.1-6 [9.2 is not yet supported in JON]

Note: I'd be interested in hearing how this runs on OSX or any other setups people might have.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	

*********************************************************************************

## FIRST STEPS ##

To get started:

Run the following script:  
		./scripts/main.sh
	
This will display a splash screen with the requirements and create the necessary data file/structure in the background.  
It will also inform you of all the pre-requisites that are required before the script will run fully.

One of the necessary modifications is to the user-defined variables file (./data/demo-config.properties) which is created at the first run of the script:

+ REQUIRED  
	- JAVA_HOME:			Update to the appropriate value on your system  
	
+ OPTIONAL
	- INSTALL_LOCATION:		If you have a preference, you can modify the base install location (default: /opt/).  This location will have the JD_FOLDER variable (configurable via the script) appended to it.
	- MVN_HOME:				If you want bundle creation to be enabled, provide the mvn home location
	- ANT_HOME:				If you want bundle creation to be enabled, provide the ant home location
	- LOCAL_USER:			Set to a local user account that you would like to own any new files or folders created by the script.  If it's left empty or invalid, root will be used by default.
	- UD_ID:				Set the id to be used for the local jboss user account to be created.
	- LATEST_JON_VERSION: 	The latest version of JON for the creation of the default data FS.  Currently set to jon-server-3.1.0.
	- DEMO_LOG_LEVEL:		The log level to be used across the project, set to INFO (2) by default. (See more about the different log levels at the top of debug.sh)
	
Running the script the first time will create the initial directory structure required in the data directory, or it can be done manually as follows:
- data
	- jboss
	- jon
		- jon-server-x.x.x.GA (where x.x.x represents the version you want to you, you can have multiple versions in the demo at the same time)
			- patches
			- plugins
			
Then, add the necessary product ZIPs into the appropriate locations (please use the provided naming convention):
+ REQUIRED
	- jon-server-x.x.x.zip into ./data/jon/jon-server-x.x.x.GA/
	
+ OPTIONAL
	- jboss-eap-x.x.x.zip into ./data/jboss
	- jon-plugin-pack-*.zip into ./data/jon/jon-server-x.x.x.GA/plugins
	- unpack any JON  patch ZIPs into ./data/jon/jon-server-x.x.x.GA/patches
	
At the top of the Main Menu, you can see where the demo will currently be installed (demo directory is ${INSTALL_LOCATION}/jon-demo by default).  You can change that by using the "cd" option.

To manage the JON demo, use the JON demo options, (ID) to Install and (DD) to Delete the JON Demo.
Follow the prompts.  

- Note: An internet connection is required for an initial install with no postgreSQL database installed locally.
- Note: If you already installed an rhq database, it will prompt you to create a new database, just choose the name.
- Note: For demo purposes, all the scan periods on the agent are set to occur every 30 seconds to ensure changes made during the demo are picked up quickly.
- Note: JON 2.x required a license, it will need to be manually added and has not been tested with the latest version of the script.

*IT IS BEST NOT TO MODIFY ANY OF THE SCRIPT FILES OR INSTALLED DEMOS BY HAND AND TO USE THE SCRIPT WHERE NECESSARY TO MAKE CHANGES TO THE WHOLE ENVIRONMENT*

*********************************************************************************

## MANUAL STEPS ##
At the time of writing, the CLI (in JON v3.1.1) does not support the creation of Alert Definitions, as such, you will need to create one manually through the GUI.
For demo purposes, we will create one that will get invoked so that it shows up during the demo:

- Go to the local JBoss server that was installed with your demo (otherwise, you can set an alert on another resource)
- Under the Summary tab, get a view of what the JVM Free/Total Memory numbers are looking like (let's say 350/750 MB)
- Click the Alerts tab -> Definitions -> New
- Name it "JBoss Memory Alert"
- Click the Conditions tab -> Add
- Set the Condition Type to "Measurement Absolute Value Threshold"
- Set the Metric to "JVM Free Memory"
- Set the Comparator to "< (Less than)
- Input a Metric value which is larger then the JVM Free Memory you'd seen (eg 400 MB, from the above number), click OK
- Add a notification to the rhq system user
- Save the alert 

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Known Issues: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- Using PostgreSQL version 9.1-6 will break the demo
	Currently, provided a mechanism to choose the last known working version and providing it as default option.

WON'T FIX:
- If a server is deployed (with port 200), only server's with higher increments should be installed.  Installing (port 300) is fine whereas installing (port 100), will re-deploy the base and has varying behaviour - it either breaks the (port 200) build by removing the symbolic link from ../common/server or leaves it intact.
	- Recommendation is to always install servers with incrementally higher ports

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# MORE INFO: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

For extra details about this project relating to any of the following, please read the [README-MORE](README-MORE.md) file: 

- Getting Started
	- New JON Versions
	- Bundles
	- Other Options
	- Debug
- Demo Details
	- Features
		- JON
		- JBOSS
		- PostgreSQL
		- Gotchas to be aware of
- Known Issues
- Tested Environments
- Contributing
- Future Planning
- Contact