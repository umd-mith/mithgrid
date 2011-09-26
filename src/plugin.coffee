(function() {
  (function($, MITHGrid) {
    MITHGrid.namespace("Plugin");
    /*
    	 * This is the base of a plugin, which can package together various things that augment
    	 * an application.
    	 *
         *
         *  MITHGrid.Plugin.MyPlugin = function(options) {
         *    var that = MITHGrid.Plugin.initPlugin('MyPlugin', options, { ... })
         *  };
         *
         *  var myApp = MITHGrid.Application({
         *    plugins: [ { name: 'MyPlugin', ... } ]
         *  });
    	*/
    return MITHGrid.Plugin.initPlugin = function(klass, options) {
      var readyFns, that;
      that = {
        options: options,
        presentation: {}
      };
      readyFns = [];
      that.getTypes = function() {
        if ((options != null ? options.types : void 0) != null) {
          return options.types;
        } else {
          return [];
        }
      };
      that.getProperties = function() {
        if ((options != null ? options.properties : void 0) != null) {
          return options.properties;
        } else {
          return [];
        }
      };
      that.getPresentations = function() {
        if ((options != null ? options.presentations : void 0) != null) {
          return options.presentations;
        } else {
          return [];
        }
      };
      that.ready = readyFns.push;
      that.eventReady = function(app) {
        var fn, _i, _len;
        for (_i = 0, _len = readyFns.length; _i < _len; _i++) {
          fn = readyFns[_i];
          fn(app);
        }
        readyFns = [];
        return that.ready = function(fn) {
          return fn(app);
        };
      };
      return that;
    };
  })(jQuery, MITHGrid);
}).call(this);
