//Params Required: serverId serverOperation
//Params Optional: 
//Usage: manageServer.js
//Description: Finds a server with the defined searchPattern (default server type is JBoss, unless the optional resourceType is provided)

rhq.login('rhqadmin', 'rhqadmin');
println("Running findServer.js");
var serverId;
var serverOperation;
var resource;

var availabilityScanPeriod = 30;

function checkArgs() {
	if( args.length < 2 ) {
		println("ERROR: Call this script with <serverId> and <serverOperation>");
		return true;
	} else {
		serverId = args[0];
		serverOperation = args[1];
		println("Using parameters: serverId [" + serverId + "] - serverOperation[" + serverOperation + "].\n");
	}
}

function getResource () {
	
	//Search for EAP resources based on criteria
	var criteria = new ResourceCriteria();
	criteria.addFilterId(parseInt(serverId));
	
	var resources = ResourceManager.findResourcesByCriteria(criteria);
	
	if( resources != null ) {
		if( resources.size() > 1 ) {
			println("Found more than one server. Check configuration of provisioned servers.");
			for( i = 0; i < resources.size(); ++i) {
				resource = resources.get(i);
				println("  found " + resource.name );
			}
			return true;
		}
		else if( resources.size() == 1 ) {
			resource = resources.get(0);
		}
		else {
			println("Did not find any servers with the provided serverId. Try again with a new <serverId>.");
			return true;
		}
	}
}

function applyOperation (operation) {
	
	var availability = getAvailability();
	//println("DEBUG: Current status is: " + availability);
	if (availability == "DOWN" && operation == "shutdown") {
		println("Server is already down, nothing to do.");
		return true;
	} else if (availability == "DOWN" && (operation == "start" || operation == "restart")) {
		println("Server is down, invoking " + operation + " operation.");
	} else if (availability == "UP" && (operation == "shutdown" || operation == "restart")) {
		println("Server is running, invoking " + operation + " operation.");
	} else if (availability == "UP" && operation == "start") {
		println("Server is already running, no need to start it up...");
		return true;
	} else if (availability == "undefined") {
		println("Server is not recognised, check logs and process...");
		return true;
	}else {
		println("Server status [" + availability + "] is not recognised, attempting operation");
	}
	OperationManager.scheduleResourceOperation(serverId, operation, 0, 0, 0, 5000, new Configuration(), "CLI Operation");
	return false;	
}

function checkServerStatus() {
	var expectedAvailability;
	var currentAvailability;
	
	var currentAvailability = getAvailability();
	if (currentAvailability == "DOWN") {
		expectedAvailability = "UP";
	} else if (currentAvailability == "UP") {
		expectedAvailability = "DOWN";
	}
	
	print("Waiting for server to have status: " + expectedAvailability);
	
	var count = 0;
	while (expectedAvailability != currentAvailability) {
		
		if (count % 5 == 0) {
			print(".");
		}
		
	    java.lang.Thread.sleep(1000);  // sleep for 1 seconds
	    currentAvailability = getAvailability();
	    count++;
	    if (count > (availabilityScanPeriod * 2.5)) {
	    	println("\nServer availability not confirmed to be: " + expectedAvailability);
	    	break;
	    }
	}
	
	if ( expectedAvailability == currentAvailability ) {
		println("\nServer availability now confirmed to be: " + currentAvailability + "\n");
	}
}

function run (command) {
	if (!error) error = applyOperation(command);
	if (!error) error = checkServerStatus();
}

function getAvailability() {
	var availabilty = AvailabilityManager.getCurrentAvailabilityForResource(serverId);
	var availabiltyType = availabilty.getAvailabilityType();
	var availabiltyText = availabiltyType.toString();
	
	return availabiltyText;
}

var error = checkArgs();
if (!error) error = getResource();

if (serverOperation == "restart") {
	println("Restarting the server...");
	
	var currentAvailability = getAvailability();
	if (currentAvailability == "UP") {
		run("shutdown");
	}
	run("start");
} else {
	run(serverOperation);
}

println("Done!");

rhq.logout();
