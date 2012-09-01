//Params Required: groupName searchPattern
//Params Optional: resourceType
//Usage: addToGroup.js
//Description: Adds the resource (if found) into the specified group
/*
 * addToGroup.js
 * ----------------
 * The purpose of this script is to show how to add new EAP instances to a compatible group
 * with JON 2.3 scripting engine. 
 
 * This script was not tested very well and should not be used in productive 
 * environments without further testing. 
 *
 * Version 1.0: Initial version
 *  
 * As always: No warrenties and use it on your own risk
 *
 * @author: Wanja Pernath 
 */

// name of the group
rhq.login('rhqadmin', 'rhqadmin');
println("Running addToGroup.js");
var groupName = "GroupName";
var searchPattern;
var resourceType = "JBossAS Server";

if( args.length < 2 ) {
	println("ERROR: Call this script with <groupName> and <searchPattern> and optional <resourceType>");
	throw("Invalid args!");
} else {
	groupName = args[0];
	searchPattern = args[1];
	resourceType = args[2];
	println("Using parameters: groupName[" + groupName + "] - searchPattern[" + searchPattern + "] - resourceType[" + resourceType + "].\n");
}

// Secondly, test to see if the specified group name already exists
var criteria = ResourceGroupCriteria();
criteria.addFilterName(groupName);
//criteria.addFilterResourceTypeName(resourceType);
criteria.fetchExplicitResources(false);
var resourceGroups = ResourceGroupManager.findResourceGroupsByCriteria(criteria);

if( resourceGroups == null || resourceGroups.size() == 0 ) {
	throw("A group with name " + groupName + " does not exists");
}
var group = resourceGroups.get(0);
println("[DEBUG] found group " + group);

// now, search for EAP resources based on criteria
criteria = new ResourceCriteria();
criteria.addFilterName(searchPattern);
criteria.addFilterResourceTypeName(resourceType);

var resources = ResourceManager.findResourcesByCriteria(criteria);

if( resources != null ) {
	println("[DEBUG] found " + resources.size() + " resource(s) with searchPattern[" + searchPattern + "]");
	if( resources.size() > 1 ) {
		println("Found more than one " + resourceType + " item. Adding them all into the group...");
		for( i =0; i < resources.size(); ++i) {
			var resource = resources.get(i);
			println("  found " + resource.name );
			ResourceGroupManager.addResourcesToGroup(group.id, [resource.id]);
		}
		println("\nAdded to Group!");
	}
	else if( resources.size() == 1 ) {
		resource = resources.get(0);
		println("Found one " + resourceType + " item. Trying to add it.");
		println("  " + resource.name );
	    ResourceGroupManager.addResourcesToGroup(group.id, [resource.id]);
		println("\nAdded to Group!");
	}
	else {
		println("Did not find any " + resourceType + " item(s) matching your pattern. Try again.");
	}
}

println("Done!");

rhq.logout();
