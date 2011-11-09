
	Application = MITHGrid.namespace 'Application'
	Application.initApp = (klass, container, options) ->		
		[ klass, container, options ] = MITHGrid.normalizeArgs "MITHGrid.Application", klass, container, options
		that = MITHGrid.initView(klass, container, options)
		onReady = []
		
		that.presentation = {}
		that.facet = {}
		that.dataStore = {}
		that.dataView = {}
		that.controller = {}
		
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
				initFn = viewConfig.init || MITHGrid.Data.initView
				viewOptions =
					dataStore: that.dataStore[viewConfig.dataStore]
					label: viewName
			
				if !that.dataView[viewName]?				
					viewOptions.collection = viewConfig.collection if viewConfig.collection?
					viewOptions.types = viewConfig.types if viewConfig.types?
					viewOptions.filters = viewConfig.filters if viewConfig.filters?
					viewOptions.expressions = viewConfig.expressions if viewConfig.expressions?
					
					view = initFn viewOptions
					that.dataView[viewName] = view
#				else
#					view = that.dataView[viewName]

		if options?.controllers?
			that.ready () ->
				for cName, cconfig of options.controllers
					coptions = $.extend(true, {}, cconfig)
					coptions.application = that
					controller = cconfig.type.initController coptions
					that.controller[cName] = controller

		if options?.viewSetup?
			if $.isFunction(options.viewSetup)
				that.ready () -> options.viewSetup $(container)
			else
				that.ready () -> $(container).append options.viewSetup
		
		if options?.facets?
			that.ready () ->
				for fName, fconfig of options.facets
					foptions = $.extend(true, {}, fconfig)
					fcontainer = $(container).find(fconfig.container)
					fcontainer = fcontainer[0] if $.isArray(fcontainer)
					
					foptions.dataView = that.dataView[fconfig.dataView]
					foptions.application = that
					
					facet = fconfig.type.initFacet fcontainer, foptions
					that.facet[fName] = facet
					facet.selfRender()
					
		if options?.presentations?
			that.ready () ->
				for pName, pconfig of options.presentations
					poptions = $.extend(true, {}, pconfig)
					pcontainer = $(container).find(poptions.container)
					#pcontainer = $('#' + $(container).attr('id') + ' > ' + poptions.container)
					pcontainer = pcontainer[0] if $.isArray(pcontainer)
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
							pcontainer = $(container).find(prconfig.container)
							#pcontainer = $("#" + $(container).attr('id') + ' > ' + prconfig.container)
							pcontainer = pcontainer[0] if $.isArray(pcontainer)

							proptions.lenses = prconfig.lenses if prconfig?.lenses?
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