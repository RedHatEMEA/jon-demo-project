//Params Required: serverId 
//Params Optional: toggleOnOrOff
//Usage: toggleEventLogging.js
//Description: Finds a server with the defined serverId and toggles the event logging to be on or off depending on the optional param

rhq.login('rhqadmin', 'rhqadmin');
println("Running toggleEventLogging.js");

var serverId;
var toggleTo = "";

//How many parameters are required?
var requiredParams = 1;

//Check for the required parameters
function checkArgs() {
	if( args.length < requiredParams ) {
		println("ERROR: Call this script with <serverId> and an optional [on/off]...");
		return true;
	} else {
		serverId = args[0];
		
		if (args[1] != null && args[1] != "") {
			toggleValue = args[1];
			if (toggleValue != "on" && toggleValue != "off") {
				println("ERROR: The optional parameter should only be on/off, otherwise don't pass it in.");
				return true;
			} 
			toggleTo = toggleValue;
		}
	}
}

function updateConfiguration() {
	
	//Get the config for the server
	var jbossConfig = ConfigurationManager.getPluginConfiguration(serverId);
	
	//Get the server home directory
	var homeDir = jbossConfig.getSimple('serverHomeDir').getStringValue();
	
	var logDir = "";
	if (homeDir != "" && homeDir != null) {
		logDir = homeDir + "/log/server.log";	
		
		//Get the list for the log events
		var jbossConfigPropList = jbossConfig.getList("logEventSources");     
		
		//If the list is empty, create a new event listener
		var eventList = jbossConfigPropList.list;
		if (eventList.size() == 0 ) {
			
			println("Server does not have an event log defined, creating a new one.");
		
			//Create a new map for the properties
			var jbossConfigLogEventSourcesMap = new PropertyMap();
			jbossConfigLogEventSourcesMap.name="logEventSource"
			
			//Set the enabled to the appropriate toggleTo option, if not provided, set to true
			if (toggleTo == "" || toggleTo == "on") {
				toggleTo = true;
			} else if (toggleTo == "off") {
				toggleTo = false;
			}
				
			var sp = new PropertySimple();
			sp.booleanValue = toggleTo;
			sp.stringValue = toggleTo;
			sp.override = null;
			sp.name = "enabled";
			
			jbossConfigLogEventSourcesMap.put(sp)
			
			//Specify the log path property
			sp = new PropertySimple();
			sp.booleanValue = false;
			sp.name = "logFilePath";
			sp.stringValue = logDir;
			sp.override = null;
			
			jbossConfigLogEventSourcesMap.put(sp)                                
			
			//Add the property map to the config property list
			jbossConfigPropList.list.add(jbossConfigLogEventSourcesMap);
			println("   Set the log event [" + (toggleTo ? "on" : "off") + "] to monitor " + logDir);
		
		} else {
			
			var it = eventList.listIterator();
			while (it.hasNext()) {
				
				var eventPropertyMap  = it.next();
				
				var enabledProperty = eventPropertyMap.getSimple("enabled");
				var enabledValue = enabledProperty.getBooleanValue();
				
				var toggleToPerEvent = "";
				
				if (toggleTo != ""){
					toggleToPerEvent = toggleTo;
					if (toggleTo == "on") {
						enabledProperty.setBooleanValue(true);
					} else if (toggleTo == "off") {
						enabledProperty.setBooleanValue(false);
					}
				} else {
					if (enabledValue == true) {
						toggleToPerEvent = false;
					} else {
						toggleToPerEvent = true;
					}
					enabledProperty.setBooleanValue(toggleToPerEvent);
				}
									
				//Get the log file path to inform which logPath is being changed and to what  
				var logEventPath = eventPropertyMap.getSimple("logFilePath");
				println("   Toggling [" + logEventPath.getStringValue() + "] to " + (toggleToPerEvent ? "on" : "off"));               
				
			}
		}
		
		//Update the configuration with the new updates
		ConfigurationManager.updatePluginConfiguration(serverId, jbossConfig)

	} else {
		println("The homeDir for the server could not be identified, so cannot set it to listen to the logs");
		error=true;
	}
}

//Run the script calling the correct functions in the correct order watching for errors
var error = checkArgs();
if (!error) error = updateConfiguration();

println("Done!");

rhq.logout();

//TESTS TO DO:
/*
 * Run basic, on a server with no log
 * 	 check that it gets added
 *   that the port is correct
 *   that it's enabled
 *   
 * Run on a server with 1 enabled log
 * 	 check that it gets the right toggleTo variable
 *   ignore the port portion
 *   apply the toggle via the configuration
 *   
 * Run on a server with 2 enabled log
 * 
 * Run on a server with 1 enabled and 1 disabled logs
 * 
 * Run on a server with 2 disabled logs
 */
