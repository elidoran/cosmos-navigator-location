Package.describe({
  name: 'cosmos:navigator-location',
  version: '0.1.0',
  summary: 'Reactive browser location',
  git: 'http://github.com/elidoran/cosmos-navigator-location',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1');

  api.use([
    'tracker',              // onLocation uses Tracker
    'reactive-var',         // Nav._location is a ReactiveVar
    'cosmos:running@0.1.0', // for Running.onChange with 'RunNav'
    'coffeescript@1.0.6'
  ], ['client']);

    api.addFiles([
      'client/export.js', // export must be first
      'client/navigator-location.coffee'
    ], 'client');

    api.export('Nav', 'client');
});

Package.onTest(function(api) {
  api.use(['tinytest', 'coffeescript@1.0.6']);

  api.use('cosmos:navigator-location');

  api.addFiles([
    'test/navigator-location-tests.coffee'
  ], 'client');

  api.export('Nav', 'client');
});
