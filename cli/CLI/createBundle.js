//Params Required: bundleZipFile
//Params Optional: bundleName bundleVersion
//Usage: createBundle.js
//Description: Creates a bundle version using the specified file
rhq.login('rhqadmin', 'rhqadmin');
println("Running createBundle.js");

var fileName = args[0];
var bundleName = args[1];
var bundleVersion = args[2];

if (args.length < 1 || fileName == "") {
	println("You need to provide the bundle file name to create generate your bundle...");
} else {
	doCreateBundle();
}

rhq.logout();

function doCreateBundle() {

//TODO do look for bundle and then use
//	criteria.fetchBundleVersions(true);
//	but how to figure out the version of the bundle being uploaded.. read what's in file??
//	currently have the user pass it in...
//	try out JS file handling to read deploy.xml
	var bundleArray;
	var newVersion = false;

	if (bundleVersion > 0) {
		var criteria = new BundleCriteria();
		criteria.addFilterName(bundleName);
		criteria.fetchBundleVersions(true);
		bundleArray = BundleManager.findBundlesByCriteria(criteria);
		
		var bundleSize = bundleArray.totalSize;
		if (bundleSize >= 1) {
			println("Bundle with name " + bundleName + " found in system, checking version");
			var bundle = bundleArray.get(bundleSize - 1);
			var versions = bundle.bundleVersions;
			var versionSize = versions.size()
			var latestVersion = versions.get(versionSize - 1);
			var bundleVersionInSystem = latestVersion.version;

			if (parseInt(bundleVersionInSystem) == parseInt(bundleVersion)) {
				println("You already have a bundle with name [" + bundleName + "] and version [" + bundleVersion + "], not going to upload this bundle.");
				return;
			} else {
				println("Current version is " + bundleVersionInSystem + ", uploading new bundle.");
				newVersion = true;
			}
		} else {
			println("Bundle not found in system, uploading new version...");
		}
			
	} else {
		println("Bundle version not provided, attempting to upload new version...");
	}
	
	if (!bundleArray || bundleArray.isEmpty() || newVersion) {

		//Create bundle version
		var file = new java.io.File(fileName);

		var bundle = BundleManager.createBundleVersionViaFile(file);
		println("Bundle " + bundle.name + " has been created.");
	}
}
