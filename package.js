Package.describe({
  name: 'cosmos:navigator-location',
  version: '0.1.0',
  summary: 'Reactive browser location',
  git: 'http://github.com/elidoran/cosmos-navigator-location',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2');

  api.use([
    'tracker',              // onLocation uses Tracker
    'reactive-var',         // Nav._location is a ReactiveVar
    'coffeescript@1.0.11'
  ], ['client']);

  // Optionally use Running.onChange() instead of Meteor.startup()
  api.use('cosmos:running', 'client', {weak:true});

  api.addFiles([
    'client/export.js', // export must be first
    'client/navigator-location.coffee'
  ], 'client');

  // export so we can use Nav from the console
  api.export('Nav', 'client');
});

Package.onTest(function(api) {
  api.use(['tinytest', 'coffeescript@1.0.11']);

  api.use('cosmos:navigator-location');

  api.addFiles([
    'test/tests.coffee'
  ], 'client');

  api.export('Nav', 'client');
});
