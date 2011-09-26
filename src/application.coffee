
	Application = MITHGrid.namespace 'Application'
	Application.initApp = (klass, container, options) ->
		that = fluid.initView(klass, container, options)
		onReady = []
		
		that.presentation = {}
		that.dataStore = {}
		that.dataView = {}
		
		options = that.options
		
		that.ready = (fn) -> onReady.push fn

		if options?.dataStores?
			for storeName, config of options.dataStores
				if !that.dataStore[storeName]?
					store = MITHGrid.Data.initStore()
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

				if config?.types?
					store.addType type for type, typeInfo of config.types

				if config?.properties?
					store.addProperty prop, propOptions for prop, propOptions of config.properties

		if options?.dataViews?
			for viewName, viewConfig of options.dataViews
				viewOptions =
					dataStore: that.dataStore[viewConfig.dataStore]
					label: viewName
			
				if !that.dataView[viewName]?				
					viewOptions.collection = viewConfig.collection if viewConfig.collection?
					viewOptions.types = viewConfig.types if viewConfig.types?
					viewOptions.filters = viewConfig.filters if viewConfig.filters?
					
					view = MITHGrid.Data.initView viewOptions
					that.dataView[viewName] = view
#				else
#					view = that.dataView[viewName]

		if options?.viewSetup?
			if $.isFunction(options.viewSetup)
				that.ready () -> options.viewSetup $(container)
			else
				that.ready () -> $(container).append options.viewSetup
				
		if options?.presentations?
			that.ready () ->
				for pName, pconfig of options.presentations
					poptions = $.extend(true, {}, pconfig)
					pcontainer = $('#' + $(container).attr('id') + ' > ' + pconfig.container)
					pcontainer = pcontainer[0] if $.isArray(container)
					poptions.dataView = that.dataView[pconfig.dataView]
					poptions.application = that
					
					presentation = pconfig.type.initPresentation pcontainer, poptions
					that.presentation[pName] = presentation
					presentation.selfRender()
		
		if options?.plugins?
			that.ready () ->
				for pconfig in options.plugins
					plugin = pconfig.type.initPlugin(pconfig)
					if plugin?
						if pconfig?.dataView?
							# hook plugin up with dataView requested by app configuration
							plugin.dataView = that.dataView[pconfig.dataView]
							# add
							plugin.dataView.addType type for type, typeInfo of plugin.getTypes()

							plugin.dataView.addProperty prop, propOptions for prop, propOptions of plugin.getProperties()

						for pname, prconfig of plugin.getPresentations()
							proptions = $.extend(true, {}, prconfig.options)
							pcontainer = $("#" + $(container).attr('id') + ' > ' + prconfig.container)

							proptions.lenses = prconfig.lenses if prconfig?.lenses?
							pcontainer = pcontainer[0] if $.isArray(pcontainer)
							if prconfig.dataView?
								proptions.dataView = that.dataView[prconfig.dataView] 
							else if pconfig.dataView?
								proptions.dataView = that.dataView[pconfig.dataView]
							proptions.application = that
							presentation = prconfig.type.initPresentation pcontainer, proptions
							plugin.presentation[pname] = presentation
							presentation.selfRender()

		that.run = () ->
			$(document).ready () ->
				fn() for fn in onReady
				onReady = []
				that.ready = (fn) -> setTimeout fn, 0
		that