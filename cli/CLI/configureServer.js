//Params Required: serverId homeDirsAsBase
//Params Optional: portSet hostName jbossHomeDir serverProfile javaHome startScript stopScript jbossUser jbossPassword
//Usage: configureServer.js
//Description: Finds a server with the defined serverId and sets up the configuration as appropriate by passing in name=value properties for any of the optional params

rhq.login('rhqadmin', 'rhqadmin');
println("Running configureServer.js");
var serverId;
var homeDirsAsBase = false;

var requiredParams = 2;

//Properties gathered from the CLI by doing the following command:
//	var c = ConfigurationManager.getPluginConfiguration(<jbossServerId>);
var validPropertyNames = new Array("namingURL", "principal", "credentials", "homeDir", "serverHomeDir", 
		"serverName", "startWaitMax", "stopWaitMax", "javaHome", "childJmxServerName", "shutdownMethod", 
		"shutdownScript", "startScript", "shutdownMBeanName", "scriptPrefix", "clientUrl", "libUrl",
		"shutdownMBeanOperation", "availabilityCheckPeriod", "bindAddress", "commonLibUrl");

function checkArgs() {
	if( args.length < requiredParams ) {
		println("ERROR: Call this script with <serverId> and any other optional params as name=value pairs...");
		return true;
	} else {
		serverId = args[0];
		if (args[1].equals("true")) {
			homeDirsAsBase = true;
		}
		
		var numOfParams = args.length - requiredParams;
		println("Using parameters: serverId[" + serverId + "] homeDirsAsBase[" + homeDirsAsBase + "] - num of params passed in[" + numOfParams + "].\n");
		
		if (args.length > requiredParams) {
			for (var i = requiredParams; i < args.length; i++) {
				var param = args[i];
				if (!param.contains("=") || param.startsWith("=") || param.endsWith("=")) {
					println("The format of your config params needs to be \"name=value\".");
					return true;
				}
			}
		} else {
			println("No config params passed in for updating, thus not going to progress with update...");
			return true;
		}
	}
}

function getResource() {
	
	//Search for EAP resources based on criteria
	var criteria = new ResourceCriteria();
	if (!isNaN(parseFloat(serverId)) && isFinite(serverId)) {
		criteria.addFilterId(parseInt(serverId));
	} else {
		println("The serverId passed in is not a valid numeric id, please try again.")
		return true;
	}
	
	
	var resources = ResourceManager.findResourcesByCriteria(criteria);
	
	if( resources != null ) {
		if( resources.size() > 1 ) {
			println("Found more than one server item. Check configuration of provisioned servers.");
			for( i = 0; i < resources.size(); ++i) {
				var resource = resources.get(i);
				println("  found " + resource.name );
			}
			return true;
		}
		else if( resources.size() == 1 ) {
			resource = resources.get(0);
			println("Found server, setting up configuration properly.");
		}
		else {
			println("Did not find any servers matching the serverId. Try again with a new <serverId>.");
			return true;
		}
	}
}

function configServer() {
	
	var config = ConfigurationManager.getPluginConfiguration(serverId);
	//println("Initial config: " + config.allProperties)
	
	var serverHomeDir;
	println("homeDirsAsBase: " + homeDirsAsBase);
	if (homeDirsAsBase) {
		serverHomeDir = config.getSimple("serverHomeDir").stringValue;
		homeDir = config.getSimple("homeDir").stringValue;
		println("serverHomeDir: " + serverHomeDir + " -- homeDir: " + homeDir);
	}
	
	var configUpdated = false;
	if (args.length > requiredParams) {
		println("Dealing with configuration params:");
		for (var i = requiredParams; i < args.length; i++) {
			var configParam = args[i];
			var indexOfEqual = configParam.indexOf("=");
			var propertyName = configParam.substring(0, indexOfEqual);
			var propertyValue = configParam.substring(indexOfEqual + 1);
			if (checkPropertyName(propertyName)) {
				println("  " + propertyName + " --> " + propertyValue);
				
				var ps = config.getSimple(propertyName);
				var stringValue = ps.stringValue;

				if (stringValue == null || !stringValue.equals(propertyValue)) {		
					println("propertyName: " + propertyName);
					
					if (propertyName.equals("shutdownMethod")) {
						if (propertyValue.equalsIgnoreCase("jmx")) {
							propertyValue = "JMX";
						} else if (propertyValue.equalsIgnoreCase("script")) {
							propertyValue = "SCRIPT";
						} else {
							println("  Invalid selection for shutdownMethod property...");
							return true;
						}
					}
					
					if (propertyName.equals("shutdownScript")) {
						if (homeDirsAsBase) {
							propertyValue = serverHomeDir + "/" + propertyValue;
						}
					}
					
					if (propertyName.equals("startScript")) {
						if (homeDirsAsBase) {
							propertyValue = serverHomeDir + "/" + propertyValue;
						}
					}
					
					if (propertyName.equals("libUrl") || propertyName.equals("clientUrl") || propertyName.equals("commonLibUrl")) {
						if (homeDirsAsBase) {
							propertyValue = homeDir + "/" + propertyValue;
						}
					}
				
					var property = new PropertySimple(propertyName, propertyValue);
					config.put(property);
					configUpdated = true;
				} else {
					println("  Value provided for " + propertyName + "[" + propertyValue + "] is the same as in the config, ignoring...");
				}
			}
		}
	}
		
	//Update the plugin configuration
	if (configUpdated) {
		//println("Using updated config: " + config.allProperties);
		ConfigurationManager.updatePluginConfiguration(serverId, config)
	} else {
		println("No params were modified, so configuration update was not invoked.");
	}
}

function checkPropertyName(propertyName) {
	
	if (contains(validPropertyNames, propertyName)){
		return true;
	} else {
		return false;
	}
	
}

function contains(array, object) {
    for (var i = 0; i < array.length; i++) {
        if (array[i] == object) {
            return true;
        }
    }
    return false;
}

var error = checkArgs();
if (!error) error = getResource();
if (!error) error = configServer();

println("Done!");

rhq.logout();
