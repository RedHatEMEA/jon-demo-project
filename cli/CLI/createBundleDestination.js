//Params Required: bundleName groupName destinationName destinationLocation
//Params Optional: destinationDesc destinationBaseDir
//Usage: createBundleDestination.js
//Description: Creates a bundle destination using the specified bundleName, groupName, providing a destination name and location and optionally a destination description. destinationBaseDir used in JON 3.x
rhq.login('rhqadmin', 'rhqadmin');
println("Running createBundleDestination.js");

var bundleName = args[0];
var groupName = args[1];
var destinationName = args[2];
var destinationLocation = args[3];
var destinationDesc = args[4];
var destinationBaseDir = args[5];

if (args.length < 4 || destinationName == "" || bundleName == "" || groupName == "" || destinationLocation == "") {
	println("You need to provide all the required params to create the bundle destination...");
} else {
	if (destinationDesc == "") {
		destinationDesc = "Destination genererated via CLI script.";
	}

	//Find the bundle created
	var criteria = new BundleCriteria();
	criteria.addFilterName(bundleName);
	var bundleArray = BundleManager.findBundlesByCriteria(criteria);
	if (bundleArray.totalSize == 0) {
		println("Bundle with name " + bundleName + " is not found...");
	} else {
		var bundle = bundleArray.get(bundleArray.totalSize - 1);
	
		var destinationExists = false;

		var bdc = new BundleDestinationCriteria(); 
		var dests = BundleManager.findBundleDestinationsByCriteria(bdc);

		if (!dests.isEmpty()) {
			//println("in check destination");
			for (var i = 0; i < dests.size(); i++) {
				var dest = dests.get(i);
				var name = dest.name;
				//println("dest name is: " + name + " -- comparing to: " + destinationName + " value: " + (name.equalsIgnoreCase(destinationName)));
				if (name.equalsIgnoreCase(destinationName)) {
					destinationExists = true;
					println("A destination with name \"" + destinationName + "\" already exists...");
				}
			
				//println("dest deployDir is: " + dest.deployDir + " -- comparing to: " + destinationLocation + " value: " + (dest.deployDir == destinationLocation));
				var dir = dest.deployDir;
				if (dir.equalsIgnoreCase(destinationLocation)) {
					destinationExists = true;
					println("A destination with deploy directory \"" + destinationLocation + "\" already exists...");
				}
			
			}
		}

		if (!destinationExists) {
			if (!destinationExists) { 
				//Get the bundle id to be used
				var bundleId = bundle.id;
				println("Found bundle " + bundleName + " with id: " + bundleId);
	
				//Find the group to be used
				var criteria = new ResourceGroupCriteria();
				criteria.addFilterName(groupName);
				var groupArray = ResourceGroupManager.findResourceGroupsByCriteria(criteria);
				
				if (groupArray.totalSize == 0) {
					println("No groups were found, aborting destination creation...");
				} else { 
					var group = groupArray.get(groupArray.totalSize - 1);
					var groupId = group.id;
					println("Found group " + groupName + " with id: " + groupId);
		
					var destination;
					if (destinationBaseDir && !destinationBaseDir.isEmpty()) {
						if (destinationBaseDir.equals("Root")) {
							destinationBaseDir = "Root File System";
						}
						destination = BundleManager.createBundleDestination(bundleId, destinationName, destinationDesc, destinationBaseDir, destinationLocation, groupId);					
					} else {
						destination = BundleManager.createBundleDestination(bundleId, destinationName, destinationDesc, destinationLocation, groupId);
					}
					println("Destination " + destinationName + " created with id: " + destination.id);
				}
			}

		}
	}
}

rhq.logout();
