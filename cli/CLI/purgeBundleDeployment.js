//Params Required: bundleName
//Params Optional: pattern
//Usage: purgeBundleDeployment.js 		
//Description: Purges a deployment of a bundle using the specified bundleName and destinationName
rhq.login('rhqadmin', 'rhqadmin');
println("Running purgeBundleDeployment.js");

var bundleName = args[0];
var pattern = args[1];

var bundleId;
var bundle;
var destination;
var destinationId = 0;

var error = checkArgs();
if (!error) error = findBundle();
if (!error) error = findDestination();
if (!error) purgeBundle();

rhq.logout();

function checkArgs() {
	if (args.length < 1 || bundleName == "") {
		println("You need to provide the bundle name to purge the bundle deployment and optionally a pattern, if you are purging a bundle with multiple destinations.");
		return true;
	}	
}

function findBundle() {
	//Find the bundle
	var criteria = new BundleCriteria();
	criteria.addFilterName(bundleName);
	criteria.fetchDestinations(true);
	var bundleArray = BundleManager.findBundlesByCriteria(criteria);

	if (!bundleArray.isEmpty()) {
		bundle = bundleArray.get(bundleArray.totalSize - 1);

		//Get the bundle id to be used
		bundleId = bundle.id;
		println("Found the bundle " + bundleName + " with id: " + bundleId);
	} else {
		println("The bundle with name " + bundleName
				+ " does not exist in the system.");
		return true;
	}

}

function findDestination () {
	//Find the destination
	var destinations = bundle.destinations

	if (destinations.size() == 1) {
		//Always get the first destination.  If we put in the name, it will be unique,
		//if not, we will default to the first destination
		destination = destinations.get(0);
		destinationId = destination.id;
		println("Found the destination " + destination.name);
	} else if (destinations.size() > 1) {
		if (pattern && pattern != "") {
			println("Looking through multiple destinations:");
			for (var i = 0; i < destinations.size(); i++) {
				var dest = destinations.get(i);
				print("  " + dest.name)
				var deployDir = dest.deployDir;
				if (deployDir.contains(pattern)) {
					destinationId = dest.id
					println(" <-- choosen destination");
					break;
				} else {
					println("");
				}
			}
			if (destinationId == 0) {
				println("Destination with pattern [" + pattern + " not found, aborting purge bundle deployment.");
				return true;
			}
		} else {
			println("You have not provided a pattern to identify the destination, aborting purge bundle deployment.");
			return true;
		}
	} else {
		println("The bundle does not have a destination and cannot be deployed.");
		return true;
	}
}

function purgeBundle() {

	var purge = BundleManager.purgeBundleDestination(destinationId);
	println("Purge scheduled.");

}
