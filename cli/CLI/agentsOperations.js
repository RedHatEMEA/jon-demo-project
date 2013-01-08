//Params Required: operation
//Params Optional: 
//Usage: agentsRescan.js
//Description: Invokes the agents operation action

rhq.login('rhqadmin', 'rhqadmin');
println("Running agentsOperations.js");

var operation;

function checkArgs() {
	if( args.length < 1 ) {
		println("ERROR: Call this script with <operation>, availability or discovery");
		return true;
	} else {
		operation = args[0];
		println("Using parameters: operation [" + operation + "]");
	}
}

function executeDiscoveryScan(agent) {
	
	println("  executing discovery scan on agent" );
    println("    -> " + agent.name + " / " + agent.id);
    
    var config = new Configuration();
    config.put(new PropertySimple("command", "discovery -f") );
				
    var ros = OperationManager.scheduleResourceOperation(
	  agent.id, 
	  "executePromptCommand", 
	  0,   // delay
	  1,   // repeatInterval
	  0,   // repeat Count
	  10,  // timeOut in seconds
	  config,    // config
	  "Availability Scan from CLI" // description
    );
}

function executeAvailabilityScan(agent) {
	
	println("  executing availability scan on agent" );
    println("    -> " + agent.name + " / " + agent.id);
    
    var config = new Configuration();
    config.put(new PropertySimple("changesOnly", "false") );
				
    var ros = OperationManager.scheduleResourceOperation(
	  agent.id, 
	  "executeAvailabilityScan", 
	  0,   // delay
	  1,   // repeatInterval
	  0,   // repeat Count
	  10,  // timeOut in seconds
	  config,    // config
	  "Availability Scan from CLI" // description
    );
}

function agentsOperations() {
	var criteria = new ResourceCriteria();
	
	var resType = ResourceTypeManager.getResourceTypeByNameAndPlugin("RHQ Agent", "RHQAgent");
	criteria.addFilterResourceTypeName(resType.name);          
	
	var agents = ResourceManager.findResourcesByCriteria(criteria).toArray();
	if( agents != null ) {
		for (var i = 0; i < agents.length; i++) {
			var agent = agents[i];
			if( agent.resourceType.id == resType.id ) {
				if (operation == ("availability")) {
					executeAvailabilityScan(agent);			
				} else if (operation == ("discovery")) {
					executeDiscoveryScan(agent);			
				}
			}
		}
	}
}

var error = checkArgs();
if (!error) error = agentsOperations();

println("Done!");

rhq.logout();
