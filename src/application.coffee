# # Applications
#
# ## MITHGrid.Application.initInstance
#
# Initializes an application instance.
#
# Parameters:
#
# * klass -
#
# * container -
#
# * options -
#
# 
MITHGrid.namespace 'Application', (Application) ->
	Application.initInstance = (args...) ->		
		MITHGrid.initInstance "MITHGrid.Application", args..., (that, container) ->
			onReady = []
	
			that.presentation = {}
			that.facet = {}
			that.component = {}
			that.dataStore = {}
			that.dataView = {}
			that.controller = {}
	
			options = that.options
		
			configureInstance = ->
				# The following configuration options are available:
				#
				# ### variables
				#
				# See the section on #addVariable.
				#
				#if options?.variables?
				#	for varName, config of options.variables
				#		that.addVariable varName, config

				# ### dataStores
				#
				# See the section on #addDataStore.
				#
				if options?.dataStores?
					for storeName, config of options.dataStores
						that.addDataStore storeName, config

				# ### dataViews
				#
				# See the section on #addDataView.
				#
				if options?.dataViews?
					for viewName, viewConfig of options.dataViews
						that.addDataView viewName, viewConfig

				# ### controllers
				#
				# See the section on #addController.
				#
				if options?.controllers?
					for cName, cconfig of options.controllers
						that.addController cName, cconfig
	
				# ### facets
				#
				# See the section on #addFacet.
				#
				if options?.facets?
					for fName, fconfig of options.facets
						that.addFacet fName, fconfig
				
				# ### components
				#
				# See the section on #addComponent
				#
				if options?.components?
					for cName, cconfig of options.components
						that.addComponent cName, cconfig
					
				# ### presentations
				#
				# See the section on #addPresentation.
				#
				if options?.presentations?
					for pName, pconfig of options.presentations
						that.addPresentation pName, pconfig
	
				# ### plugins
				#
				# See the section on #addPlugin.
				#
				if options?.plugins?
					for pconfig in options.plugins
						that.addPlugin pconfig
			
			that.ready = (fn) -> onReady.push fn
	
			# ### #addVariable
			#
			# Adds a managed variable to the application object.
			#
			# Parameters:
			#
			# * varName - the name of the variable
			#
			# * config - object holding configuration options
			#
			# Returns: Nothing.
			#
			# Configuration:
			#
			# * **is** - the mutability of the variable is one of the following:
			# 	* 'rw' for read-write
			# 	* 'r' for read-only
			# 	* 'w' for write-only.
			#
			# * **event** - the name of the event associated with this variable. This event will fire when the value of the variable changes.
			#           This defaults to 'on' + varName + 'Change'.
			#
			# * **setter** - the name of the method that will be used to set the variable. This defaults to 'set' + varName.
			#
			# * **getter** - the name of the method that will be used to retrieve the variable. This defaults to 'get' + varName.
			#
			# * **validate** - a function that will be called to validate the value the variable is being set to. This function
			#              should expect the new value and return "true" or "false".
			#
			# * **filter** - a function that will be called to filter the value the variable is being set to. This function
			#            should expect the new value and return the filtered value. If both the filter and validate
			#            options are set, the filter will be run before the validate function.
			#
			###
			that.addVariable = (varName, config) ->
				value = config.default
				config.is or= 'rw'
				if config.is in ['rw', 'w']
					filter = config.filter
					validate = config.validate
					eventName = config.event || ('on' + varName + 'Change')
					setName = config.setter || ('set' + varName)
					that.events[eventName] = MITHGrid.initEventFirer()
					if filter?
						if validate?
							that[setName] = (v) ->
								v = validate filter v
								if value != v
									value = v
									that.events[eventName].fire(value)
						else
							that[setName] = (v) ->
								v = filter v
								if value != v
									value = v
									that.events[eventName].fire(value)
					else
						if validate?
							that[setName] = (v) ->
								v = validate v
								if value != v
									value = v
									that.events[eventName].fire(value)
						else
							that[setName] = (v) ->
								if value != v
									value = v
									that.events[eventName].fire(value)
				if config.is in ['r', 'rw']
					getName = config.getter || ('get' + varName)
					that[getName] = () -> value
			###
			
			# ### #addDataStore
			#
			# Adds a data store to the application.
			#
			# Parameters:
			#
			# * storeName - name for the data store
			#
			# * config - object holding configuration options
			#
			# Returns: Nothing.
			#

			that.addDataStore = (storeName, config) ->
				#
				# The data store automatically has an "Item" type and the "label", "type", and "id" properties.
				#
				if !that.dataStore[storeName]?
					store = MITHGrid.Data.Store.initInstance()
					that.dataStore[storeName] = store
					store.addType 'Item'
					store.addProperty 'label',
						valueType: 'text'
					store.addProperty 'type',
						valueType: 'text'
					store.addProperty 'id',
						valueType: 'text'
				else
					store = that.dataStore[storeName]

				# Configuration:
				#

				# * **types** - object having the types as keys. Types do not have configurations yet.
				#
				if config?.types?
					store.addType type for type, typeInfo of config.types

				# * **properties** - object having the properties as keys. Properties have the following options:
				#    * valueType - the type of value associated with the property. Value types should be one of the following:
				#        * text - plain text strings (default)
				#        * item - the id of an item in the data store
				#        * numeric - an integer or floating point number
				#        * date -
				#        * url -
				if config?.properties?
					store.addProperty prop, propOptions for prop, propOptions of config.properties
	
			# ### #addDataView
			#
			# Adds a data view to the application.
			#
			# Parameters:
			#
			# * viewName - name for the data view
			#
			# * viewConfig - object holding configuration options
			#
			# Returns: Nothing.
			#
			# Configuration:
			#
			# * type - the namespace holding the #initInstance function for the particular data view type for this data view.
			#          Defaults to MITHGrid.Data.View.
			#
			# * dataStore - the name of the already configured data store.
			#
			# See the documentation for the particular data view type for other configuration options.
			#
			that.addDataView = (viewName, viewConfig) ->
				if viewConfig.type? and viewConfig.type.initInstance?
					initFn = viewConfig.type.initInstance
				else
					initFn = MITHGrid.Data.View.initInstance
				viewOptions =
					dataStore: that.dataStore[viewConfig.dataStore] || that.dataView[viewConfig.dataStore]
	
				if !that.dataView[viewName]?
					for k,v of viewConfig
						if k != "type" && !viewOptions[k]
							viewOptions[k] = v
			
					view = initFn viewOptions
					that.dataView[viewName] = view
	
			# ### #addController
			#
			# Adds a controller to the application.
			#
			# Parameters:
			#
			# * cName - name for the controller
			#
			# * cconfig - object holding configuration options
			#
			# Returns: Nothing.
			#
			that.addController = (cName, cconfig) ->
				coptions = $.extend(true, {}, cconfig)

				coptions.application = that
				controller = cconfig.type.initInstance coptions
				that.controller[cName] = controller
	
			# ### #addFacet
			#
			# Adds a facet to the application.
			#
			# Parameters:
			#
			# * fName - name of the facet
			#
			# * fconfig - object holding configuration options
			#
			# Returns: Nothing.
			#
			that.addFacet = (fName, fconfig) ->
				foptions = $.extend(true, {}, fconfig)
				that.ready () ->
					fcontainer = $(container).find(fconfig.container)
					fcontainer = fcontainer[0] if $.isArray(fcontainer)
			
					foptions.dataView = that.dataView[fconfig.dataView]
					foptions.application = that
			
					facet = fconfig.type.initFacet fcontainer, foptions
					that.facet[fName] = facet
					facet.selfRender()
	
			# ### #addComponent
			#
			# Adds a component to the application. Components tie together renderings with controllers, but do not base
			# their DOM content on data. Components are good for things like bounding boxes used by a presentation, menus,
			# or other UI elements that might be considered chrome.
			#
			# Parameters:
			#
			# * cName - name of the component
			#
			# * cconfig - object holding configuration options
			#
			# Returns: Nothing.
			#
			that.addComponent = (cName, pconfig) ->
				coptions = $.extend(true, {}, cconfig)
				that.ready () ->
					ccontainer = $(container).find(coptions.container)
					ccontainer = ccontainer[0] if $.isArray(ccontainer)
					coptions.application = that
					if cconfig.components?
						coptions.components = {}
						for ccName, cconfig of cconfig.components
							if typeof cconfig == "string"
								coptions.components[ccName] = that.component[ccName]
							else
								ccoptions = $.extend(true, {}, ccconfig)
								ccoptions.application = that
								coptions.components[ccName] = cconfig.type.initInstance ccoptions
					if cconfig.controllers?
						coptions.controllers = {}
						for ccName, cconfig of pconfig.controllers
							if typeof cconfig == "string"
								coptions.controllers[ccName] = that.controller[ccName]
							else
								ccoptions = $.extend(true, {}, ccconfig)
								ccoptions.application = that
								coptions.controllers[ccName] = cconfig.type.initInstance ccoptions

					that.component[cName] = cconfig.type.initInstance ccontainer, coptions
				
			# ### #addPresentation
			#
			# Adds a presentation to the application.
			#
			# Parameters:
			#
			# * pName - name of the presentation
			#
			# * pconfig - object holding configuration options
			#
			# Returns: Nothing.
			#
			that.addPresentation = (pName, pconfig) ->
				poptions = $.extend(true, {}, pconfig)
				that.ready () ->
					pcontainer = $(container).find(poptions.container)
					pcontainer = pcontainer[0] if $.isArray(pcontainer)
					poptions.dataView = that.dataView[pconfig.dataView]
					poptions.application = that
					if pconfig.components?
						poptions.components = {}
						for ccName, cconfig of pconfig.components
							if typeof cconfig == "string"
								poptions.components[ccName] = that.component[ccName]
							else
								ccoptions = $.extend(true, {}, ccconfig)
								ccoptions.application = that
								poptions.components[ccName] = cconfig.type.initInstance ccoptions
					if pconfig.controllers?
						poptions.controllers = {}
						for cName, cconfig of pconfig.controllers
							if typeof cconfig == "string"
								poptions.controllers[cName] = that.controller[cName]
							else
								coptions = $.extend(true, {}, cconfig)
								coptions.application = that
								poptions.controllers[cName] = cconfig.type.initInstance coptions
		
					presentation = pconfig.type.initInstance pcontainer, poptions
					that.presentation[pName] = presentation
					presentation.selfRender()
			
			# ### #addPlugin
			#
			# Adds a plugin to the application.
			#
			# Parameters:
			#
			# * pconf - object holding configuration options
			#
			# Returns: Nothing.
			#
			that.addPlugin = (pconf) ->
				pconfig = $.extend(true, {}, pconf)
				pconfig.application = that

				plugin = pconfig.type.initPlugin(pconfig)
				if plugin?
					if pconfig?.dataView?
						# hook plugin up with dataView requested by app configuration
						plugin.dataView = that.dataView[pconfig.dataView]
						# add
						plugin.dataView.addType type for type, typeInfo of plugin.getTypes()

						plugin.dataView.addProperty prop, propOptions for prop, propOptions of plugin.getProperties()

					for pname, prconfig of plugin.getPresentations()
						(pname, prconfig) ->
							that.ready ->
								proptions = $.extend(true, {}, prconfig.options)
								pcontainer = $(container).find(prconfig.container)
								#pcontainer = $("#" + $(container).attr('id') + ' > ' + prconfig.container)
								pcontainer = pcontainer[0] if $.isArray(pcontainer)

								proptions.lenses = prconfig.lenses if prconfig?.lenses?
								if prconfig.dataView?
									proptions.dataView = that.dataView[prconfig.dataView] 
								else if pconfig.dataView?
									proptions.dataView = that.dataView[pconfig.dataView]
								proptions.application = that
								presentation = prconfig.type.initInstance pcontainer, proptions
								plugin.presentation[pname] = presentation
								presentation.selfRender()
	
	
			configureInstance()

			# ### #run
			#
			# Finishes configuring the application by running all queued or pending functions registered through
			# the #ready() method. The #ready() method will be redefined to run functions after the current thread
			# finishes.
			that.run = () ->
				$(document).ready () ->
					fn() for fn in onReady						
					onReady = []
					that.ready = (fn) -> fn()