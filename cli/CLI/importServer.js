//Params Required: serverName
//Params Optional: 
//Usage: importServer.js
//Description: Imports the specified server into the JON server

rhq.login('rhqadmin', 'rhqadmin');
println("Running importServer.js");

var serverName;

function checkArgs() {
	if (args.length < 1) {
		println("You need to provide the server name that you want to import.");
		return true;
	} else {
		serverName = args[0];
		return false;
	}
}

var error = checkArgs();
if (!error) {
	 
	var resources = findUncommittedResources();
	var resourceIds = getIds(resources);
	DiscoveryBoss.importResources(resourceIds);
	
}
 
rhq.logout();
 
// returns a java.util.List of Resource objects
// that have not yet been committed into inventory
function findUncommittedResources() {
    var criteria = ResourceCriteria();
    criteria.addFilterInventoryStatus(InventoryStatus.NEW);
    criteria.addFilterName(serverName);
     
    return ResourceManager.findResourcesByCriteria(criteria);
}
 
// returns an array of ids for a given list
// of Resource objects. Note the resources argument
// can actually be any Collection that contains
// elements having an id property.
function getIds(resources) {
	var ids = [];

	if (resources.size() > 0) {
		println("Found resources to import: ");
		for (i = 0; i < resources.size(); i++) {
			resource = resources.get(i);
			ids[i] =  resource.id;
			println("  " + resource.name);
		}
	} else {
		println("No resources found awaiting import...");
	}

    return ids;
}
