var Search = Class({
  initialize: function() {
    localSearchHighlight('Stadtwerke');
  }
});

document.on('ready', function() {
  new Search().initialize;
});
