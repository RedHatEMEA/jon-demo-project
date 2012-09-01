****************************************************************************************************************************************
*AN INTERNET CONNECTION IS REQUIRED FOR AN INITIAL INSTALL WITH NO POSTGRESQL DB INSTALLED LOCALLY*

*IT IS BEST NOT TO MODIFY ANY OF THE SCRIPT FILES BY HAND AND TO USE THE SCRIPT WHERE NECESSARY TO MAKE CHANGES TO THE DEMO ENVIRONMENT*
****************************************************************************************************************************************


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
	
If you have the intention of using bundles, then you must ensure that Ant (v.1.7.x+) is installed on your system.  If not, then bundle creation and deployment will not be available.  You also need to ensure to provide a jboss-eap-*.zip.  Currently, only version 5.x is supported (v.5.1.1 and 5.1.2 confirmed).

At the top of the Main Menu, you can see where the demo will currently be installed (demo directory is ${INSTALL_LOCATION}/jon-demo by default).  You can change that by using the "cd" option.

To manage the JON demo, use the JON demo options, (ID) to Install and (DD) to Delete the JON Demo.
Follow the prompts.  

Note: If you already installed an rhq database, it will prompt you to create a new database, just choose the name.
Note: For demo purposes, all the scan periods on the agent are set to occur every 30 seconds to ensure changes made during the demo are picked up quickly.
Note: JON 2.x required a license, it will need to be manually added and has not been tested with the latest version of the script.

******************************************************************************

## NEW JON VERSIONS ##

As is to be expected, there will be new versions of JON that will come along and it will be desirable to be able to just drop them into the demo script builder and have it work...  

Even though, I wouldn't go as far as saying this is verified and supported as a solution in this script, but throughout the process of writing the script, I've gone through having JON 2.3.0 - 3.1.0.  And all have worked seamlessly (with a minor tweak between 2.x and 3.x).

To add a new version of JON, the suggested steps would be as follows:
- Go into the ./data/jon folder
- Copy the auto-generated jon-server-x.x.x.GA folder with all the sub-folders (or create a new folder structure as described above)
- Rename it to the appropriate jon server version name
- Copy the jon-server-xxx.GA.zip file into that location
- If there are any patches, add them into the "patches" and extract all the patches into that folder, removing the ZIPs
- Delete the older version's plug-in ZIPs from the sub-directory called "plug-ins" and drop in the new files for the new version (**Do NOT leave old plug-ins with newer versions of JON, they are incompatible)
- Voila!  Start up the script, and it should offer up the new version as an option to install

*********************************************************************************

## OTHER OPTIONS ##

There are other menus provided, some for managing the JON environment, and others that were mostly used for debugging or some repeated tasks that were required during development but may prove beneficial.

### Create/Delete bundles menu: ###
  Allows for the creations and deletion of bundles depending on the availability of a jboss-eap-5.x ZIP file and the presence of ANT on the system.  The bundles can be used as part of the JON demo or can be used separately from the JON demo script.
	
### (Coming soon) Server/Service management menu: ###
  A menu that will provide management capabilities to all the different services and servers deployed by the demo.   

### Install menu: ###
#### Install Product ####
  This allows for the script to extract the zips available in the "products" section of the project to the demo location
		
### Delete menu: ###
#### Delete JON server and database ####
  Will delete the JON server and the database, but this can be better achieved by using the Delete Jon Demo (JD) option
#### Delete Postgres DB ####
  This allows for the deletion of any Postgres databases... in case of the creation of an incorrect DB or the failure of the install/deletion, you can remove the unused DB.
#### Delete JON Demo data ####
  Will prompt the user regarding the deletion of all the bundles, demo environment and all the contents of the data folder. Otherwise, will prompt for the deletion of just the script specific data.
		
### Start/Stop Jon Server menu: ###
  Depending on the status of the server, it'll allow you to start/stop it via the script.  It will only show when a JON demo environment is installed.
	
### Start/Stop Postres service menu: ###
  Depending on the status of the service, it'll allow you to start/stop it via the script
  
### Install/Uninstall Postres service menu: ###
  Depending on if the service is installed, it'll allow you to install/un-install it via the script
		
*Note: None of these extra options will be elaborated in the future as the aim is to generate a more user friendly GUI.*

*********************************************************************************************************************************************

## DEBUG ##

There is a file ../script/debug.sh that is provided for debugging and logging purposes.  It allows for changing the amount of log to be displayed.  If you are having any issues with the script, set:  
		LOG_LEVEL=1

This will output more debug information that would help in troubleshooting the issues.
All debug menus (as defined below) on the main menu will only be visible when LOG_LEVEL is set to 1 except for the "Change Log Level option"

### Reload scripts menu: ###
  If you were to make any changes to any of the scripts while you have the process running, you can invoke the "r" option to "Reload scripts" so as not to have to quit and restart the process.  This does not tend to work for changes in the "main.sh" script as it does not reload itself.
### Run test function menu: ###
  There is a "function testFunction ()" available in the debug.sh file.  You can call any function from it's body passing in the appropriate parameters and be able to invoke that function repeatedly from the Main Menu by using the "t" option to run the test function.
### List all functions menu: ###
  This will list all the functions defined in all the "*.sh" files in this project providing the description of the functions as defined in each file.
### Invoke function menu: ###
  Allows you to invoke one of the functions from the list above.  This is an alternative to the test function menu above, although you'll have more flexibility with the test function menu.
### CLI Commands menu: ###
#### CLI Scripts menu: ####
  All the CLI scripts used in this demo are available to be tested out separately.  A description of the script and the parameters that need to be passed will be displayed (these are pulled in from the first two lines of the JS script, where a very specific pattern is required).  Then you can invoke the script and you will be asked for each parameter.

### Change Log Level: ###
  Changes the log level in the debug.sh file allowing for more or less outputs from functions.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Demo Details: #
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

For more information regarding how to use the installed demo and what features come with it, please refer to the attached recording:
	./documentation/intro_video.avi
	
## FEATURES ##

### JON ###

- Auto installs the JON server with all the necessary configuration
- Auto installs the JON agent with all the necessary configuration and faster scan periods for demo purposes
- Auto imports the local resources into JON
- Creates a group with the local server
- Allows for creations of bundles via the script and in JON
- Allows for deployment of any number of JBoss servers via bundles from JON

### JBOSS ###

- Option to create/delete the bundles
- Currently ONLY supports JBoss EAP v5.x
- Creates a dvd-store bundle as well and deploys it to each JBoss instance
- Can deploy multiple instances of EAP from JON
- Can un-deploy multiple instances of EAP from JON 
- Sets the JBoss instance up as a service

### POSTGRESQL ###

- Option to install/delete
- Option to delete specific databases
- Creates an "rhqadmin" postgres user and "rhq" database
- Asks for new database to create if one called "rhq" already exists

### Gotchas to be aware of: ###
- If you plan to manually deploy a JBoss server via the bundles uploaded into the JON demo, please ensure that you set up the destination for the ec-default instance correctly; otherwise, you're deployment will fail.
- If you accidentally set the destination to be something like "/opt/jon-demo/", ensure NOT to click the "Clean deployment" check-box; otherwise, it will wipe you're entire jon-demo folder.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Known Issues: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- If a server is deployed (with port 200), only server's with higher increments should be installed.  Installing (port 300) is fine whereas installing (port 100), will re-deploy the base and has varying behaviour - it either breaks the (port 200) build by removing the symbolic link from ../common/server or leaves it intact.
	- Recommendation is to always install servers with incrementally higher ports
- If you use "Start JON Demo" menu option, all the components start up fine, but the text displayed suggests it timed out waiting for "server and agent to be ready..."
- jon cli warnings on delete when looking for servers to remove, fix log level and info displayed

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# CONTRIBUTING: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Following the spirit at Red Hat, this project is Open Source, so please feel free to contribute using pull requests.

One comment on contributing code, it's probably best that after confirming your changes work local, revert your project to a vanilla state (deleting any JON demos and bundles) and ensure *not* to commit "build" files or local customisations to configuration or variables... 

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# FUTURE PLANNING: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

This project is done on my own time, as such any changes are restricted by my ability to spend extra time on it.

I have some thoughts as to what I would like to be able to do with this project.  Below are some examples of what I'd like to get to, in some order of priority as I see it:

- Automatically (via CLI scripts) configure demo-able parts of JON:
	- alerts
	- drift
	- events
	- users/roles
	- snmp traps to an snmp listener
	- mail server to show emails being delivered 
- Provide a slick Web interface to allow for the choosing of the demo components to install 
- Deploy EAP 6 with the application modified for it.
- Provide some form of load that will show some usage in the JON metrics:
	- by providing a self calling basic app
	- by deploying a load generator via JON and activating it when necessary
- Provide the ability to build other products and demos using bundles from the base JON demo
- Provide capability to have the JON demo build onto a slew of VM guests (maybe integrated with RHEV) 
	- Also allowing for importing new VMs, adding them into a separate group, deploying the bundles, and then moving them to the standard group
- Allow for bundle deployments to have different environment property capabilities

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# CONTACT: #

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

If you need help with any of the following:
- setting this project up and getting the JON demo functional
- a run through of the configured environment (please check the provided slides/video)
- new features
- comments/suggestions
- bugs

You can contact the originator of this project at: 

Nabeel Saad  
nabeel@redhat.com  
07525611473  
Based in London, UK   