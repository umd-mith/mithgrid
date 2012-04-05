# # Plugins
#
MITHGrid.namespace "Plugin", (exports) ->
	#
	# This is the base of a plugin, which can package together various things that augment
	# an application.
	#
    #
    #  MITHGrid.Plugin.MyPlugin = function(options) {
    #    var that = MITHGrid.Plugin.initPlugin('MyPlugin', options, { ... })
    #  };
    #
    #  var myApp = MITHGrid.Application({
    #    plugins: [ { name: 'MyPlugin', ... } ]
    #  });
	#
	
	exports.initPlugin = (klass, options) ->
		that = { options: options, presentation: { } }
		readyFns = [ ]
	
		that.getTypes = () ->
			if options?.types?
				options.types
			else
				[ ]
	
		that.getProperties = () ->
			if options?.properties?
				options.properties
			else
				[ ]
				
		that.getComponents = () ->
			if options?.components?
				options.components
			else
				[ ]
	
		that.getPresentations = () ->
			if options?.presentations?
				options.presentations
			else
				[ ]
	
		that.ready = readyFns.push
	
		that.eventReady = (app) ->
			for fn in readyFns
				fn app
			readyFns = []
			that.ready = (fn) ->
				fn app
	
		that