//Params Required: groupName pluginName resourceType
//Params Optional: 
//Usage: createGroup.js
//Description: Create a group for the specified resource type
/*
 * createGroup.js
 * --------------
 * The purpose of this script is to show how to create a new compatible group within JON
 * with the CLI.
 *
 * This script was not tested very well and should not be used in productive 
 * environments without further testing. 
 *
 * Version 1.0: Initial version.
 * 
 *  
 * As always: No warrenties and use it on your own risk
 *
 * @author: Wanja Pernath
 */

// name of the group
rhq.login('rhqadmin', 'rhqadmin');
println("Running createGroup.js");
var groupName = "GroupName";

// Name of the plugin which should handle this compatible group (JBossAS or JBossAS5)
var pluginName = "JBossAS";
var resName = "Linux";

if( args.length >= 1) groupName = args[0];
if( args.length >= 2) pluginName = args[1];
if( args.length >= 3) resName = args[2];

println("About to create a new Compatible Group with name " + groupName + " and resource type " + pluginName + " and resource name " + resName + "...");

// First find resourceType specified by pluginName
var resType = ResourceTypeManager.getResourceTypeByNameAndPlugin(resName, pluginName);
println("resType:" + resType)
// Secondly, test to see if the specified group name already exists
var criteria = ResourceGroupCriteria();
criteria.addFilterName(groupName);
criteria.fetchExplicitResources(false);
var resourceGroups = ResourceGroupManager.findResourceGroupsByCriteria(criteria);

if( resourceGroups != null && resourceGroups.size() > 0 ) {
	println("\nA group with name " + groupName + " already exists: ID = " + resourceGroups.get(0).getId());
	println("Group not created.  Call script with a new group name or delete existing group.");
} else {

	// Now just create the group
	var rg = new ResourceGroup(groupName, resType);
	rg.setRecursive(true);
	rg.setDescription("Created via JON demo auto-scripts on " + new java.util.Date().toString());

	ResourceGroupManager.createResourceGroup(rg);
	println("Group created");
}

rhq.logout();
