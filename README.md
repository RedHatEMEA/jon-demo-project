****************************************************************************************************************************************

Table of contents:
- [Description](#description)
- [Getting Started](#getting-started)
	- [First Steps](#first-steps)
- [More](#more)

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# DESCRIPTION: #
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

This set of scripts is meant to allow you to easily install a new JON demo consisting of a JON server (of your choice, depending on what you have provided in the ./data/jon folder), agent, and jboss servers.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# GETTING STARTED: #
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

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
	- LOCAL_USER:			Set to a local user account that you would like to own any new files or folders created by the script.  If it's left empty or invalid, root will be used by default.
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

Note: An internet connection is required for an initial install with no postgreSQL database installed locally.
Note: If you already installed an rhq database, it will prompt you to create a new database, just choose the name.
Note: For demo purposes, all the scan periods on the agent are set to occur every 30 seconds to ensure changes made during the demo are picked up quickly.
Note: JON 2.x required a license, it will need to be manually added and has not been tested with the latest version of the script.

*IT IS BEST NOT TO MODIFY ANY OF THE SCRIPT FILES OR INSTALLED DEMOS BY HAND AND TO USE THE SCRIPT WHERE NECESSARY TO MAKE CHANGES TO THE WHOLE ENVIRONMENT*

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# MORE INFO: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

For extra details about this project relating to any of the following, please read the README-MORE file: 

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