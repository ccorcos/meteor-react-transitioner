Package.describe({
  name: "ccorcos:react-transitioner",
  version: "0.0.2",
  summary: "Page transitions for React and Meteor",
  git: "https://github.com/ccorcos/meteor-react-transitioner",
});


Package.onUse(function(api) {
  api.use([
    "coffeescript@1.0.5",
    "kevohagan:ramda@0.13.0",
    "stevezhu:lodash@3.7.0"
  ]);
  // api.imply([
  //   // "grove:react",
  //   // "meteorhacks:flow-router"
  // ], 'client');

  api.addFiles([
    "src/transitioner.coffee",
  ], 'client');

  api.export('Transitioner')
});