//Params Required: searchPattern
//Params Optional: resourceType
//Usage: findServer.js
//Description: Finds a server with the defined searchPattern (default server type is JBoss, unless the optional resourceType is provided)

rhq.login('rhqadmin', 'rhqadmin');
println("Running findServer.js");
var searchPattern;
var resourceType;


function checkArgs() {
	if( args.length < 1 ) {
		println("ERROR: Call this script with <searchPattern> and optional <resourceType>");
		return true;
	} else {
		searchPattern = args[0];
		if (args[1] && !args[1].isEmpty()) {
			resourceType = args[1];
			
			if (resourceType.equals("linux")) {
				resourceType = "Linux";
			} else {			
				resourceType = "JBossAS Server";
			}
		} else {		
			resourceType = "JBossAS Server";
		}
		println("Using parameters: searchPattern[" + searchPattern + "] - resourceType[" + resourceType + "].\n");
	}
}

var error = checkArgs();
if (!error) {
	
	//Search for EAP resources based on criteria
	var criteria = new ResourceCriteria();
	criteria.addFilterName(searchPattern);
	criteria.addFilterResourceTypeName(resourceType);
	
	var resources = ResourceManager.findResourcesByCriteria(criteria);
	
	if( resources != null ) {
		if( resources.size() > 1 ) {
			println("Found more than one " + resourceType + " item. Check configuration of provisioned servers.");
			for( i = 0; i < resources.size(); ++i) {
				var resource = resources.get(i);
				println("  found " + resource.name );
			}
		}
		else if( resources.size() == 1 ) {
			resource = resources.get(0);
			println("Found one " + resourceType + " item.");
			println("  " + resource.name );
			println("  OUTPUT=" + resource.id );
		}
		else {
			println("Did not find any " + resourceType + " item(s) matching your pattern. Try again with a new <searchPattern>.");
		}
	}
}
//Removed this to ensure no extra lines in server id
//println("Done!");

rhq.logout();
