//Params Required: bundleName destinationName deploymentDesc
//Params Optional: configParam1 configParam2 configParam3 configParam4 configParam5 configParam6
//Usage: deployBundle.js 		
//Description: Deploys a bundle using the specified bundleName using the destinationName and a deployment description to be used.  Along with optionally adding in config name/value params to be used by the bundle recipe.
rhq.login('rhqadmin', 'rhqadmin');
println("Running deployBundle.js");

var bundleName = args[0];
var destinationName = args[1];
var deploymentDesc = args[2]

var bundleId;
var bundleVersion; 
var destination;

var error = checkArgs();
if (!error) error = findBundle();
if (!error) error = findDestination();
if (!error) error = checkGroup();
if (!error)	deployBundle();

rhq.logout();

function checkArgs() {
	if (args.length < 2 || bundleName == "" || destinationName == "" || deploymentDesc == "") {
		println("You need to provide the bundle name, destinationName and deploymentDesc to deploy the bundle");
		return true;
	} else {
		if (deploymentDesc.isEmpty()) {
			deploymentDesc = "Deployment triggered by CLI script";
		}
	}

	if (args.length > 3) {
		for (var i = 3; i < args.length; i++) {
			var param = args[i];
			if (!param.contains("=") || param.startsWith("=") || param.endsWith("=")) {
				println("The format of your config params needs to be \"name=value\".");
			}
		}
	} else {
		println("No config params passed in for deployment.");
	}
	
}

function findBundle() {
	//Find the bundle
	var criteria = new BundleCriteria();
	criteria.addFilterName(bundleName);
	criteria.fetchBundleVersions(true);
	var bundleArray = BundleManager.findBundlesByCriteria(criteria);

	if (!bundleArray.isEmpty()) {
		var bundle = bundleArray.get(bundleArray.totalSize - 1);

		//Get the bundle id to be used
		bundleId = bundle.id;
		println("Found the bundle " + bundleName + " with id: " + bundleId);
		var bundleVersions = bundle.getBundleVersions();
		bundleVersion = bundleVersions.get(bundleVersions.size() - 1);
		println("Using version [" + bundleVersion.version + "] of the bundle");
	} else {
		println("The bundle with name " + bundleName
				+ " does not exist in the system.");
		return true;
	}

}

function findDestination () {
	//Find the destination
	var bdc = new BundleDestinationCriteria();
	bdc.addFilterBundleId(bundleId);
	
	if (!destinationName.isEmpty()) {
		bdc.addFilterName(destinationName);		
	}
	var destinations = BundleManager.findBundleDestinationsByCriteria(bdc);

	if (destinations.totalSize > 0) {
		//Always get the first destination.  If we put in the name, it will be unique,
		//if not, we will default to the first destination
		destination = destinations.get(0);
		println("Found the destination " + destination.name);
	} else {
		println("The bundle does not have a destination and cannot be deployed.");
		return true;
	}
}

function checkGroup() {

	var group = destination.group;
	var groupId = group.id;

	var rgc = new ResourceGroupCriteria();
	rgc.addFilterId(groupId);
	rgc.fetchExplicitResources(true);
	var groupList = ResourceGroupManager
			.findResourceGroupsByCriteria(rgc);

	if (groupList == null || groupList.size() == 0) {
		println("Can't find a resource group named " + groupName);
		return true;
	} else {
		println("Found group: " + group.name);
		var group = groupList.get(0);

		if (group.explicitResources == null	|| group.explicitResources.size() == 0) {
			println("Group does not contain explicit resources, cannot deploy to this group");
			return true;
		}
	}
}

function deployBundle() {

	// create a config for the deployment
	// setting the required properties for recipe in distro
	var config = new Configuration();
	var property;
	
	if (args.length > 3) {
		println("Adding configuration params for deployment:");
		for (var i = 3; i < args.length; i++) {
			var configParam = args[i];
			var indexOfEqual = configParam.indexOf("=");
			var propertyName = configParam.substring(0, indexOfEqual);
			var propertyValue = configParam.substring(indexOfEqual + 1);

			println("  " + propertyName + " --> " + propertyValue);
			property = new PropertySimple(propertyName, propertyValue);
			config.put(property);
		}
	}

	var deployment = BundleManager.createBundleDeployment(
			bundleVersion.getId(), destination.getId(),
			deploymentDesc, config);
	deployment = BundleManager.scheduleBundleDeployment(deployment
			.getId(), true);
	println("Deployment scheduled.");

}
