Package.describe({
  name: "ccorcos:react-transitioner",
  version: "0.0.1",
  summary: "Page transitions for React and Meteor",
  git: "https://github.com/ccorcos/meteor-react-transitioner",
});


Package.onUse(function(api) {
  api.use([
    "coffeescript@1.0.5",
    "meteorhacks:flow-router@1.1.3"
  ]);
  api.imply([
    "grove:react",
    "meteorhacks:flow-router"
  ], 'client');

  api.addFiles([
    "src/transitioner.coffee",
  ], 'client');

  api.export('Transitioner')
});