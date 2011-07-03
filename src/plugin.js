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
		
	MITHGrid.Plugin.initPlugin = function(klass, options) {
		var that = { options: options, presentation: { } }, readyFns = [ ];
		
		that.types = function() {
			if('types' in options) {
				return options.types;
			}
			else {
				return [ ];
			}
		};
		
		that.properties = function() {
			if('properties' in options) {
				return options.properties;
			}
			else {
				return [ ];
			}
		};
		
		that.presentations = function() {
			if('presentations' in options) {
				return options.presentations;
			}
			else {
				return [ ];
			}
		};
		
		that.ready = function(fn) {
			readyFns.push(fn);
		};
		
		that.eventReady = function(app) {
			$.each(readyFns, function(idx, fn) {
				fn(app);
			});
			that.ready = function(fn) {
				fn(app);
			};
		};
		
		return that;
	};
	
})(jQuery, MITHGrid);