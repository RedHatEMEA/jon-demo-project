//Usage: autoImport.js
//Description: Imports all auto-discovered inventory into JON
// autoImport.js
rhq.login('rhqadmin', 'rhqadmin');
println("Running autoImport.js");
 
var resources = findUncommittedResources();
var resourceIds = getIds(resources);

if (resourceIds.length > 0) {
	DiscoveryBoss.importResources(resourceIds);
}
 
rhq.logout();
 
// returns a java.util.List of Resource objects
// that have not yet been committed into inventory
function findUncommittedResources() {
    var criteria = ResourceCriteria();
    criteria.addFilterInventoryStatus(InventoryStatus.NEW);
     
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
