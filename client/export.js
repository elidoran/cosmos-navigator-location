
// create object we're exporting. We'll actually define it in a CoffeeScript file
Nav = {}

// use Running instead of Meteor.startup() if available
if (Package['cosmos:running'] && Package['cosmos:running'].Running) {
  // function to call Nav.start() and Nav.stop()
  function runNav(running) {
    if (running)
      if (Nav.running !== true) Nav.start();
    else
      Nav.stop()
  }

  // set its id. no before/after because others will order in relation to this one
  runNav.options = {id:'CosmosRunNav'};

  Package['cosmos:running'].Running.onChange(runNav);
}

else // use startup()
  Meteor.startup(function startupNav() {
    Nav.start();
  });
