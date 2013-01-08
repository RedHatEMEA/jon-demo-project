//Params Required: serverId
//Params Optional: 
//Usage: uninventoryServer.js
//Description: Remove server from JON inventory

rhq.login('rhqadmin', 'rhqadmin');
println("Running uninventoryServer.js");
var serverId;

function checkArgs() {
	if( args.length < 1 ) {
		println("ERROR: Call this script with <serverId>");
		return true;
	} else {
		serverId = args[0];
		
		if (!isNaN(parseFloat(serverId)) && isFinite(serverId)) {
			//is numeric
		} else {
			println("The provided <serverId> is not numeric, please try again.");
			return true;
		}
			
		println("Using parameters: serverId [" + serverId + "]");
	}
}

function uninventory() {
	var ids = new Array(serverId);
	ResourceManager.uninventoryResources(ids);
}

var error = checkArgs();
if (!error) error = uninventory();

println("Done!");

rhq.logout();
